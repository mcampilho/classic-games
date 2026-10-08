class_name InvadersGame
extends Node2D
## Lógica do Space Invaders (Taito, 1978), independente do visual.
## Tudo é calculado em "unidades" do ecrã original (224x240) e desenhado a SCALE píxeis por unidade.
##
## Regras do original:
##  - 5 filas x 11 invasores: cima 30 pts, meio 20, baixo 10
##  - a frota marcha em bloco; quanto menos invasores, mais depressa (e mais rápida a "batida")
##  - ao tocar na margem, desce uma linha e inverte; se chegar ao chão, é o fim
##  - 1 tiro do jogador de cada vez, até 3 bombas inimigas, 4 abrigos que se desfazem
##  - disco voador com pontos "misteriosos" (dependem do número de tiros disparados)
##  - vida extra aos 1500 pontos; cada onda nova começa mais abaixo

signal match_started
signal turn_started(player: int)
signal player_fired(pos: Vector2)
signal alien_fired(pos: Vector2, kind: int)
signal alien_killed(row: int, col: int, pos: Vector2, points: int, kind: int)
signal fleet_stepped(note: int)
signal ufo_spawned
signal ufo_killed(pos: Vector2, points: int)
signal ufo_gone
signal player_hit(pos: Vector2)
signal shot_blocked(pos: Vector2, by_bunker: bool)
signal extra_life
signal wave_cleared
signal game_over

enum Mode { DEMO, ONE, TWO }
enum State { READY, PLAY, DYING, CLEARED, OVER }

const SCALE := 3.0
const ORIGIN := Vector2(304, 0)          # canto do campo no ecrã 1280x720
const FIELD := Vector2(224, 240)
const COLS := 11
const ROWS := 5
const CELL := 16.0
const ROW_KIND := [0, 1, 1, 2, 2]
const KIND_POINTS := [30, 20, 10]
const KIND_WIDTH := [8, 11, 12]
const ALIEN_H := 8.0
const FLEET_START := Vector2(24, 48)
const PLAYER_Y := 208.0
const PLAYER_W := 13.0
const PLAYER_H := 8.0
const GROUND_Y := 224.0
const PLAYER_SPEED := 72.0
const SHOT_SPEED := 240.0
const BUNKER_Y := 184.0
const BUNKER_W := 22
const BUNKER_H := 16
const BUNKER_X := [32, 77, 122, 167]
const UFO_Y := 26.0
const UFO_W := 16.0
const UFO_SPEED := 48.0
const UFO_POINTS := [100, 50, 50, 100, 150, 100, 100, 50, 300, 100, 100, 100, 50, 150, 100]
const EXTRA_LIFE_AT := 1500
const TOUCH_GAIN := 1.4

var mode := Mode.DEMO
var start_lives := 3
var state := State.READY
var paused := false
var skin: InvadersSkin
var best := 0

## Pontuação e vidas por jogador; o estado da onda (frota, abrigos) é guardado à parte em `wave_state`.
var players: Array[Dictionary] = []
var current := 0

# Onda em curso (do jogador atual)
var aliens := PackedByteArray()
var fleet_pos := FLEET_START
var fleet_dir := 1.0
var bunkers: Array = []                  # 4 x PackedByteArray(22*16)
var anim_frame := 0
var march_note := 0

var player_x := FIELD.x / 2
var shot: Variant = null                 # Vector2 (topo do tiro) ou null
var bombs: Array[Dictionary] = []        # {pos, kind, frame}
var ufo: Variant = null                  # {x, dir} ou null
var timer := 0.0                         # usado por READY / DYING / CLEARED / OVER

var _step_timer := 0.0
var _bomb_timer := 1.0
var _bomb_kind := 0
var _ufo_timer := 25.0
var _target_x: Variant = null
var _touching := false
var _ai_target := FIELD.x / 2
var _ai_think := 0.0


func _init() -> void:
	_ensure_inputs()


static func _ensure_inputs() -> void:
	var defs := {
		"si_left": [_key(KEY_A), _key(KEY_LEFT), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"si_right": [_key(KEY_D), _key(KEY_RIGHT), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)],
		"si_fire": [_key(KEY_SPACE), _key(KEY_W), _key(KEY_UP), _key(KEY_ENTER), _joy_button(JOY_BUTTON_A), _joy_button(JOY_BUTTON_X)],
	}
	for action: String in defs:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.3)
		for ev: InputEvent in defs[action]:
			InputMap.action_add_event(action, ev)


static func _key(k: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = k
	return e


static func _joy_button(b: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	e.device = -1
	return e


static func _joy_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	e.device = -1
	return e


# ---------------------------------------------------------------- partida

func start(p_mode: Mode, lives := 3) -> void:
	mode = p_mode
	start_lives = lives
	paused = false
	reset_match()


func reset_match() -> void:
	players.clear()
	for i in (2 if mode == Mode.TWO else 1):
		players.append({"score": 0, "lives": start_lives, "wave": 1, "extra": false, "shots": 0, "wave_state": null})
	current = 0
	_new_wave_state()
	_reset_turn()
	match_started.emit()
	turn_started.emit(0)


func set_skin(new_skin: InvadersSkin) -> void:
	if skin:
		skin.queue_free()
	skin = new_skin
	add_child(skin)
	skin.attach(self)


func player() -> Dictionary:
	return players[current]


func _new_wave_state() -> void:
	aliens = PackedByteArray()
	aliens.resize(ROWS * COLS)
	aliens.fill(1)
	var drop := mini(player().wave - 1, 4) * 8.0
	fleet_pos = FLEET_START + Vector2(0, drop)
	fleet_dir = 1.0
	bunkers = []
	for i in 4:
		bunkers.append(InvaderSprites.bunker_shape())
	anim_frame = 0
	march_note = 0


func _save_wave_state() -> void:
	player().wave_state = {
		"aliens": aliens.duplicate(), "fleet_pos": fleet_pos, "fleet_dir": fleet_dir,
		"bunkers": bunkers.duplicate(true), "anim": anim_frame, "note": march_note,
	}


func _load_wave_state() -> void:
	var s: Variant = player().wave_state
	if s == null:
		_new_wave_state()
		return
	aliens = s.aliens
	fleet_pos = s.fleet_pos
	fleet_dir = s.fleet_dir
	bunkers = s.bunkers
	anim_frame = s.anim
	march_note = s.note


func _reset_turn() -> void:
	player_x = FIELD.x / 2
	shot = null
	bombs.clear()
	ufo = null
	_target_x = null
	_step_timer = 0.0
	_bomb_timer = 1.5
	_ufo_timer = 25.0
	state = State.READY
	timer = 1.4


# ---------------------------------------------------------------- consultas (para os skins)

func to_px(u: Vector2) -> Vector2:
	return ORIGIN + u * SCALE


func alive_count() -> int:
	return aliens.count(1)


func alien_alive(row: int, col: int) -> bool:
	return aliens[row * COLS + col] == 1


func alien_rect(row: int, col: int) -> Rect2:
	var kind: int = ROW_KIND[row]
	var w: float = KIND_WIDTH[kind]
	var x := fleet_pos.x + col * CELL + floorf((CELL - w) / 2.0)
	return Rect2(x, fleet_pos.y + row * CELL, w, ALIEN_H)


func player_rect() -> Rect2:
	return Rect2(player_x - PLAYER_W / 2, PLAYER_Y, PLAYER_W, PLAYER_H)


func shot_rect() -> Rect2:
	return Rect2(shot.x - 0.5, shot.y, 1, 4) if shot != null else Rect2()


func bomb_rect(b: Dictionary) -> Rect2:
	return Rect2(b.pos.x - 1.5, b.pos.y, 3, 7)


func ufo_rect() -> Rect2:
	return Rect2(ufo.x, UFO_Y, UFO_W, 7) if ufo != null else Rect2()


func bunker_origin(i: int) -> Vector2:
	return Vector2(BUNKER_X[i], BUNKER_Y)


func ufo_points_next() -> int:
	return UFO_POINTS[player().shots % UFO_POINTS.size()]


func is_ai() -> bool:
	return mode == Mode.DEMO


# ---------------------------------------------------------------- ciclo

func _process(delta: float) -> void:
	if paused:
		return
	var steps := maxi(1, ceili(delta * 240.0))
	var dt := delta / steps
	for i in steps:
		_step(dt)


func _step(dt: float) -> void:
	match state:
		State.READY:
			_move_player(dt)
			timer -= dt
			if timer <= 0.0:
				state = State.PLAY
		State.PLAY:
			_move_player(dt)
			_try_fire()
			_move_shot(dt)
			if state != State.PLAY:
				return
			_move_bombs(dt)
			if state != State.PLAY:
				return
			_move_ufo(dt)
			_march(dt)
			_drop_bombs(dt)
		State.DYING:
			timer -= dt
			if timer <= 0.0:
				_after_death()
		State.CLEARED:
			_move_shot(dt)
			timer -= dt
			if timer <= 0.0:
				player().wave += 1
				_new_wave_state()
				_reset_turn()
				turn_started.emit(current)
		State.OVER:
			if mode == Mode.DEMO:
				timer -= dt
				if timer <= 0.0:
					reset_match()


# ---------------------------------------------------------------- jogador

func _move_player(dt: float) -> void:
	if is_ai():
		_ai(dt)
	else:
		var axis := Input.get_axis("si_left", "si_right")
		if not is_zero_approx(axis):
			_target_x = null
			player_x += axis * PLAYER_SPEED * dt
		elif _target_x != null:
			player_x = move_toward(player_x, float(_target_x), PLAYER_SPEED * 3.0 * dt)
	player_x = clampf(player_x, PLAYER_W / 2 + 2, FIELD.x - PLAYER_W / 2 - 2)


func _try_fire() -> void:
	if shot != null:
		return
	var want := false
	if is_ai():
		# A CPU da demonstração não dispara contra os próprios abrigos.
		var blocked: Variant = _bunker_hit(Rect2(player_x - 0.5, BUNKER_Y, 1, BUNKER_H), true)
		want = absf(player_x - _ai_target) < 2.5 and blocked == null
	else:
		want = Input.is_action_pressed("si_fire") or _touching or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if want:
		shot = Vector2(player_x, PLAYER_Y - 4)
		player().shots += 1
		player_fired.emit(shot)


func _unhandled_input(event: InputEvent) -> void:
	if paused or is_ai():
		return
	var emulated := event.device == InputEvent.DEVICE_ID_EMULATION
	if event is InputEventMouseMotion and not emulated:
		_target_x = (event.position.x - ORIGIN.x) / SCALE
	elif event is InputEventScreenTouch and not emulated:
		_touching = event.pressed                          # dedo no ecrã = disparo automático
	elif event is InputEventScreenDrag and not emulated:
		_target_x = null
		player_x += event.relative.x / SCALE * TOUCH_GAIN


func _move_shot(dt: float) -> void:
	if shot == null:
		return
	shot.y -= SHOT_SPEED * dt
	var r := shot_rect()
	# invasores
	for row in ROWS:
		for col in COLS:
			if aliens[row * COLS + col] == 1 and alien_rect(row, col).intersects(r):
				_kill_alien(row, col)
				shot = null
				return
	# disco voador
	if ufo != null and ufo_rect().intersects(r):
		var pts: int = UFO_POINTS[(player().shots - 1) % UFO_POINTS.size()]
		var pos := ufo_rect().get_center()
		ufo = null
		shot = null
		_add_score(pts)
		ufo_killed.emit(pos, pts)
		return
	# bombas
	for b in bombs:
		if bomb_rect(b).intersects(r):
			bombs.erase(b)
			var p := Vector2(shot.x, shot.y)
			shot = null
			shot_blocked.emit(p, false)
			return
	# abrigos
	var hit: Variant = _bunker_hit(r, true)
	if hit != null:
		_erode(hit[0], hit[1], hit[2])
		shot_blocked.emit(Vector2(shot.x, shot.y), true)
		shot = null
		return
	if shot.y < 16.0:
		shot_blocked.emit(Vector2(shot.x, 16.0), false)
		shot = null


func _kill_alien(row: int, col: int) -> void:
	aliens[row * COLS + col] = 0
	var kind: int = ROW_KIND[row]
	var pts: int = KIND_POINTS[kind]
	_add_score(pts)
	alien_killed.emit(row, col, alien_rect(row, col).get_center(), pts, kind)
	if alive_count() == 0:
		state = State.CLEARED
		timer = 2.0
		bombs.clear()
		ufo = null
		wave_cleared.emit()


func _add_score(pts: int) -> void:
	var p := player()
	p.score += pts
	if not p.extra and p.score >= EXTRA_LIFE_AT:
		p.extra = true
		p.lives += 1
		extra_life.emit()


# ---------------------------------------------------------------- frota

func _march(dt: float) -> void:
	_step_timer -= dt
	if _step_timer > 0.0:
		return
	var n := alive_count()
	# No original move-se um invasor por fotograma: a frota inteira demora tantos fotogramas
	# quantos invasores houver. Por isso acelera à medida que vão caindo.
	_step_timer = maxf(n, 1) / 60.0
	var dx := 3.0 if n == 1 else 2.0
	var bounds := _fleet_bounds()
	var will_hit := (fleet_dir > 0.0 and bounds.y + dx > FIELD.x - 6.0) or (fleet_dir < 0.0 and bounds.x - dx < 6.0)
	if will_hit:
		fleet_pos.y += 8.0
		fleet_dir = -fleet_dir
	else:
		fleet_pos.x += dx * fleet_dir
	anim_frame = 1 - anim_frame
	fleet_stepped.emit(march_note)
	march_note = (march_note + 1) % 4
	_aliens_crush_bunkers()
	if _fleet_bottom() >= PLAYER_Y:
		# Invasão: o jogador perde todas as vidas.
		player().lives = 1
		_kill_player()


func _fleet_bounds() -> Vector2:
	var lo := INF
	var hi := -INF
	for row in ROWS:
		for col in COLS:
			if aliens[row * COLS + col] == 1:
				var r := alien_rect(row, col)
				lo = minf(lo, r.position.x)
				hi = maxf(hi, r.end.x)
	return Vector2(lo, hi)


func _fleet_bottom() -> float:
	for row in range(ROWS - 1, -1, -1):
		for col in COLS:
			if aliens[row * COLS + col] == 1:
				return alien_rect(row, col).end.y
	return 0.0


func _aliens_crush_bunkers() -> void:
	if _fleet_bottom() < BUNKER_Y:
		return
	for row in ROWS:
		for col in COLS:
			if aliens[row * COLS + col] == 0:
				continue
			var r := alien_rect(row, col)
			for i in 4:
				var o := bunker_origin(i)
				var br := Rect2(o, Vector2(BUNKER_W, BUNKER_H))
				if not br.intersects(r):
					continue
				var bk: PackedByteArray = bunkers[i]
				for y in range(maxi(0, int(r.position.y - o.y)), mini(BUNKER_H, int(ceilf(r.end.y - o.y)))):
					for x in range(maxi(0, int(r.position.x - o.x)), mini(BUNKER_W, int(ceilf(r.end.x - o.x)))):
						bk[y * BUNKER_W + x] = 0
				bunkers[i] = bk


# ---------------------------------------------------------------- bombas

func _drop_bombs(dt: float) -> void:
	_bomb_timer -= dt
	if _bomb_timer > 0.0 or bombs.size() >= 3:
		return
	var n := alive_count()
	var progress := 1.0 - float(n) / (ROWS * COLS)
	_bomb_timer = lerpf(1.1, 0.45, progress) * randf_range(0.7, 1.3)
	# Uma bomba em cada três é apontada à coluna do jogador; as outras saem de colunas ao acaso.
	var col := -1
	if _bomb_kind == 0:
		var best_d := INF
		for c in COLS:
			if _bottom_alien(c) >= 0:
				var d := absf(alien_rect(0, c).get_center().x - player_x)
				if d < best_d:
					best_d = d
					col = c
	else:
		var cols := []
		for c in COLS:
			if _bottom_alien(c) >= 0:
				cols.append(c)
		if not cols.is_empty():
			col = cols.pick_random()
	if col < 0:
		return
	var row := _bottom_alien(col)
	var r := alien_rect(row, col)
	var b := {"pos": Vector2(r.get_center().x, r.end.y), "kind": _bomb_kind, "frame": 0.0}
	bombs.append(b)
	alien_fired.emit(b.pos, _bomb_kind)
	_bomb_kind = (_bomb_kind + 1) % 3


func _bottom_alien(col: int) -> int:
	for row in range(ROWS - 1, -1, -1):
		if aliens[row * COLS + col] == 1:
			return row
	return -1


func _move_bombs(dt: float) -> void:
	var speed := 100.0 if alive_count() <= 8 else 80.0
	for b in bombs.duplicate():
		b.pos.y += speed * dt
		b.frame += dt * 10.0
		var r := bomb_rect(b)
		if r.intersects(player_rect()):
			bombs.erase(b)
			_kill_player()
			return
		var hit: Variant = _bunker_hit(r, false)
		if hit != null:
			_erode(hit[0], hit[1], hit[2])
			bombs.erase(b)
			shot_blocked.emit(Vector2(b.pos.x, b.pos.y + 7), true)
		elif b.pos.y + 7 >= GROUND_Y:
			bombs.erase(b)
			shot_blocked.emit(Vector2(b.pos.x, GROUND_Y), false)


# ---------------------------------------------------------------- abrigos

## Procura o primeiro ponto aceso de um abrigo dentro de `r` (a subir: o mais de baixo; a descer: o mais de cima).
func _bunker_hit(r: Rect2, going_up: bool) -> Variant:
	for i in 4:
		var o := bunker_origin(i)
		if not Rect2(o, Vector2(BUNKER_W, BUNKER_H)).intersects(r):
			continue
		var bk: PackedByteArray = bunkers[i]
		var y0 := maxi(0, floori(r.position.y - o.y))
		var y1 := mini(BUNKER_H - 1, floori(r.end.y - o.y))
		var x0 := maxi(0, floori(r.position.x - o.x))
		var x1 := mini(BUNKER_W - 1, floori(r.end.x - o.x - 0.01))
		var ys := range(y1, y0 - 1, -1) if going_up else range(y0, y1 + 1)
		for y in ys:
			for x in range(x0, x1 + 1):
				if bk[y * BUNKER_W + x] == 1:
					return [i, x, y]
	return null


func _erode(i: int, cx: int, cy: int) -> void:
	var bk: PackedByteArray = bunkers[i]
	for dy in range(-3, 4):
		for dx in range(-2, 3):
			var x := cx + dx
			var y := cy + dy
			if x < 0 or y < 0 or x >= BUNKER_W or y >= BUNKER_H:
				continue
			var d := dx * dx + dy * dy * 0.6
			if d <= 2.0 or (d <= 5.0 and randf() < 0.6):
				bk[y * BUNKER_W + x] = 0
	bunkers[i] = bk


# ---------------------------------------------------------------- disco voador

func _move_ufo(dt: float) -> void:
	if ufo == null:
		_ufo_timer -= dt
		if _ufo_timer <= 0.0:
			_ufo_timer = 25.0
			if alive_count() >= 8:
				var dir := 1.0 if player().shots % 2 == 0 else -1.0
				ufo = {"x": -UFO_W if dir > 0.0 else FIELD.x, "dir": dir}
				ufo_spawned.emit()
		return
	ufo.x += ufo.dir * UFO_SPEED * dt
	if ufo.x < -UFO_W - 2 or ufo.x > FIELD.x + 2:
		ufo = null
		ufo_gone.emit()


# ---------------------------------------------------------------- morte / vez

func _kill_player() -> void:
	if state != State.PLAY:
		return
	player().lives -= 1
	state = State.DYING
	timer = 2.0
	bombs.clear()
	shot = null
	if ufo != null:
		ufo = null
		ufo_gone.emit()
	player_hit.emit(Vector2(player_x, PLAYER_Y + PLAYER_H / 2))


func _after_death() -> void:
	var lost_wave := _fleet_bottom() >= PLAYER_Y
	_save_wave_state()
	if lost_wave:
		player().wave_state = null
	var next := current
	if mode == Mode.TWO and players[1 - current].lives > 0:
		next = 1 - current
	if players[next].lives <= 0:
		state = State.OVER
		timer = 3.0
		game_over.emit()
		return
	current = next
	_load_wave_state()
	_reset_turn()
	turn_started.emit(current)


# ---------------------------------------------------------------- CPU da demonstração

func _ai(dt: float) -> void:
	_ai_think -= dt
	if _ai_think <= 0.0:
		_ai_think = 0.25
		# Escolhe a coluna com o invasor mais baixo mais próximo.
		var best_d := INF
		for c in COLS:
			var row := _bottom_alien(c)
			if row < 0:
				continue
			var x := alien_rect(row, c).get_center().x
			var d := absf(x - player_x) - row * 6.0
			if d < best_d:
				best_d = d
				_ai_target = x
	var target := _ai_target
	# Foge das bombas que vêm direitas a ele.
	for b in bombs:
		if b.pos.y > PLAYER_Y - 70.0 and absf(b.pos.x - player_x) < 10.0:
			target = player_x + (14.0 if b.pos.x <= player_x else -14.0)
	player_x = move_toward(player_x, target, PLAYER_SPEED * dt)
