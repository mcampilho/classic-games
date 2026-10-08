class_name CentipedeGame
extends Node2D
## Lógica do Centipede (1981), independente do visual.
## Grelha de 28 x 30 casas de 8 unidades (224 x 240), desenhada a SCALE píxeis por unidade.
##
## Regras do original:
##  - a centopeia (12 segmentos) desce em zigue-zague: ao bater num cogumelo ou na margem
##    desce uma linha e inverte; cada segmento abatido vira cogumelo e o seguinte passa a cabeça
##  - cabeça 100, corpo 10; cogumelos aguentam 4 tiros (+1 ao destruir)
##  - pulga (200, 2 tiros): cai a semear cogumelos quando há poucos na zona do jogador
##  - aranha (300/600/900, conforme a distância): salta na zona do jogador e come cogumelos
##  - escorpião (1000): atravessa a parte de cima e envenena cogumelos — a centopeia que
##    toca num cogumelo envenenado mergulha a direito até ao fundo
##  - ao perder uma vida, os cogumelos danificados são reparados (+5 cada)
##  - vida extra a cada 12 000 pontos; a cada vaga a centopeia traz mais cabeças soltas

signal match_started
signal turn_started(player: int)
signal fired(pos: Vector2)
signal segment_killed(pos: Vector2, head: bool, points: int)
signal mushroom_hit(cell: Vector2i, destroyed: bool)
signal creature_spawned(kind: String)
signal creature_killed(kind: String, pos: Vector2, points: int)
signal creature_gone(kind: String)
signal player_hit(pos: Vector2)
signal mushroom_repaired(cell: Vector2i)
signal extra_life
signal wave_cleared
signal game_over

enum Mode { DEMO, ONE, TWO }
enum State { READY, PLAY, DYING, REPAIR, OVER }

const SCALE := 3.0
const ORIGIN := Vector2(304, 0)
const COLS := 28
const ROWS := 30
const CELL := 8.0
const W := 224.0
const H := 240.0
const ZONE_TOP := 24                  # primeira linha da zona do jogador
const PLAYER_SIZE := Vector2(7, 8)
const PLAYER_SPEED := 110.0
const SHOT_SPEED := 480.0
const EXTRA_LIFE_EVERY := 12000
const TOUCH_GAIN := 1.3

var mode := Mode.DEMO
var start_lives := 3
var state := State.READY
var paused := false
var skin: CentipedeSkin
var best := 0

var players: Array[Dictionary] = []   # score, lives, wave, next_extra, mushrooms (guardados)
var current := 0
var mushrooms := PackedByteArray()    # vida 0..4 por casa
var poisoned := PackedByteArray()     # 1 = envenenado
var segments: Array[Dictionary] = []  # cell, pos, dx, dy, head, dive
var player_pos := Vector2(W / 2, 228)
var shot: Variant = null
var flea: Variant = null              # {pos, hp}
var spider: Variant = null            # {pos, vel, t}
var scorpion: Variant = null          # {pos, dir}
var timer := 0.0
var anim := 0.0

var _seg_speed := 60.0
var _head_spawn_t := 4.0
var _spider_t := 5.0
var _scorpion_t := 12.0
var _repair_queue: Array[Vector2i] = []
var _repair_t := 0.0
var _target: Variant = null
var _touching := false
var _mouse_fire := false
var _ai_dodge := Vector2.ZERO


func _init() -> void:
	_ensure_inputs()


static func _ensure_inputs() -> void:
	var defs := {
		"ce_up": [_key(KEY_W), _key(KEY_UP), _joy_button(JOY_BUTTON_DPAD_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)],
		"ce_down": [_key(KEY_S), _key(KEY_DOWN), _joy_button(JOY_BUTTON_DPAD_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)],
		"ce_left": [_key(KEY_A), _key(KEY_LEFT), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"ce_right": [_key(KEY_D), _key(KEY_RIGHT), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)],
		"ce_fire": [_key(KEY_SPACE), _key(KEY_ENTER), _joy_button(JOY_BUTTON_A), _joy_button(JOY_BUTTON_X), _joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)],
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


# ---------------------------------------------------------------- consultas

func to_px(u: Vector2) -> Vector2:
	return ORIGIN + u * SCALE


static func cell_rect(c: Vector2i) -> Rect2:
	return Rect2(Vector2(c) * CELL, Vector2(CELL, CELL))


func mushroom_at(c: Vector2i) -> int:
	if c.x < 0 or c.x >= COLS or c.y < 0 or c.y >= ROWS:
		return 0
	return mushrooms[c.y * COLS + c.x]


func is_poisoned(c: Vector2i) -> bool:
	return poisoned[c.y * COLS + c.x] == 1


func player_rect() -> Rect2:
	return Rect2(player_pos - PLAYER_SIZE / 2, PLAYER_SIZE)


func seg_rect(s: Dictionary) -> Rect2:
	return Rect2(s.pos + Vector2(0.5, 0.5), Vector2(7, 7))


func player() -> Dictionary:
	return players[current]


func wave() -> int:
	return player().wave if not players.is_empty() else 1


func is_ai() -> bool:
	return mode == Mode.DEMO


static func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(clampi(floori(p.x / CELL), 0, COLS - 1), clampi(floori(p.y / CELL), 0, ROWS - 1))


# ---------------------------------------------------------------- partida

func start(p_mode: Mode, lives := 3) -> void:
	mode = p_mode
	start_lives = lives
	paused = false
	reset_match()


func reset_match() -> void:
	players.clear()
	for i in (2 if mode == Mode.TWO else 1):
		players.append({"score": 0, "lives": start_lives, "wave": 1, "next_extra": EXTRA_LIFE_EVERY, "mushrooms": null, "poisoned": null})
	current = 0
	_load_player()
	_new_centipede()
	_reset_turn()
	match_started.emit()
	turn_started.emit(0)


func set_skin(new_skin: CentipedeSkin) -> void:
	if skin:
		skin.queue_free()
	skin = new_skin
	add_child(skin)
	skin.attach(self)


func _random_field() -> PackedByteArray:
	var m := PackedByteArray()
	m.resize(COLS * ROWS)
	m.fill(0)
	var placed := 0
	while placed < 42:
		var c := Vector2i(randi() % COLS, 1 + randi() % (ROWS - 3))
		# menos cogumelos na zona do jogador
		if c.y >= ZONE_TOP and randf() < 0.7:
			continue
		if m[c.y * COLS + c.x] == 0:
			m[c.y * COLS + c.x] = 4
			placed += 1
	return m


func _load_player() -> void:
	var p := player()
	if p.mushrooms == null:
		p.mushrooms = _random_field()
		var z := PackedByteArray()
		z.resize(COLS * ROWS)
		z.fill(0)
		p.poisoned = z
	mushrooms = p.mushrooms
	poisoned = p.poisoned


func _save_player() -> void:
	player().mushrooms = mushrooms.duplicate()
	player().poisoned = poisoned.duplicate()


func _new_centipede() -> void:
	segments.clear()
	var w := wave()
	var loose := mini(w - 1, 6)           # cabeças soltas extra a cada vaga
	var chain := 12 - loose
	_seg_speed = minf(60.0 + (w - 1) * 4.0, 90.0) * (1.25 if w % 2 == 0 else 1.0)
	for i in chain:
		var c := Vector2i(14 + i, 0)
		segments.append({"cell": c, "pos": Vector2(c) * CELL, "dx": -1, "dy": 1, "head": i == 0, "dive": false, "next": c})
	for i in loose:
		var c := Vector2i(randi() % COLS, 0)
		segments.append({"cell": c, "pos": Vector2(c) * CELL, "dx": 1 if randf() < 0.5 else -1, "dy": 1, "head": true, "dive": false, "next": c})
	for s in segments:
		_choose_next(s)
	_head_spawn_t = 6.0


func _reset_turn() -> void:
	player_pos = Vector2(W / 2, 228)
	shot = null
	flea = null
	spider = null
	scorpion = null
	_target = null
	_spider_t = randf_range(4.0, 7.0)
	_scorpion_t = randf_range(10.0, 18.0)
	state = State.READY
	timer = 1.2


# ---------------------------------------------------------------- ciclo

func _process(delta: float) -> void:
	if paused:
		return
	var steps := maxi(1, ceili(delta * 240.0))
	var dt := delta / steps
	for i in steps:
		_step(dt)


func _step(dt: float) -> void:
	anim += dt
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
			_move_segments(dt)
			_creatures(dt)
			_check_player()
			if segments.is_empty() and state == State.PLAY:
				player().wave += 1
				wave_cleared.emit()
				_new_centipede()
		State.DYING:
			timer -= dt
			if timer <= 0.0:
				_start_repair()
		State.REPAIR:
			_repair_t -= dt
			if _repair_t <= 0.0:
				_repair_t = 0.06
				if _repair_queue.is_empty():
					_after_death()
				else:
					var c: Vector2i = _repair_queue.pop_front()
					var i := c.y * COLS + c.x
					mushrooms[i] = 4
					poisoned[i] = 0
					_add_score(5)
					mushroom_repaired.emit(c)
		State.OVER:
			if mode == Mode.DEMO:
				timer -= dt
				if timer <= 0.0:
					reset_match()


# ---------------------------------------------------------------- centopeia

func _blocked(c: Vector2i, s: Dictionary) -> bool:
	if c.x < 0 or c.x >= COLS:
		return true
	return mushroom_at(c) > 0


func _choose_next(s: Dictionary) -> void:
	var c: Vector2i = s.cell
	if s.dive:
		if c.y >= ROWS - 1:
			s.dive = false
			s.dy = -1
		else:
			s.next = c + Vector2i(0, 1)
			return
	var ahead := c + Vector2i(s.dx, 0)
	if not _blocked(ahead, s):
		s.next = ahead
		return
	# bateu: desce (ou sobe, na zona do jogador) e inverte
	if c.x >= 0 and c.x < COLS and mushroom_at(ahead) > 0 and is_poisoned(ahead):
		s.dive = true
	var ny: int = c.y + s.dy
	if ny >= ROWS:
		s.dy = -1
		ny = c.y - 1
	elif s.dy < 0 and ny < ZONE_TOP:
		s.dy = 1
		ny = c.y + 1
	s.dx = -s.dx
	s.next = Vector2i(c.x, ny)


func _move_segments(dt: float) -> void:
	var step := _seg_speed * dt
	for s in segments:
		var target := Vector2(s.next) * CELL
		var d: float = (s.pos as Vector2).distance_to(target)
		if d <= step:
			s.pos = target
			s.cell = s.next
			_choose_next(s)
		else:
			s.pos += (target - s.pos).normalized() * step
	# cabeças novas entram pelas laterais quando a centopeia chega à zona do jogador
	var in_zone := false
	for s in segments:
		if s.cell.y >= ZONE_TOP:
			in_zone = true
			break
	if in_zone:
		_head_spawn_t -= dt
		if _head_spawn_t <= 0.0:
			_head_spawn_t = maxf(2.5, 5.0 - wave() * 0.3)
			if segments.size() < 16:
				var left := randf() < 0.5
				var c := Vector2i(0 if left else COLS - 1, ZONE_TOP)
				var s := {"cell": c, "pos": Vector2(c) * CELL, "dx": 1 if left else -1, "dy": 1, "head": true, "dive": false, "next": c}
				_choose_next(s)
				segments.append(s)


# ---------------------------------------------------------------- jogador

func _move_player(dt: float) -> void:
	var move := Vector2.ZERO
	if is_ai():
		move = _ai_move(dt)
	else:
		var axis := Vector2(Input.get_axis("ce_left", "ce_right"), Input.get_axis("ce_up", "ce_down"))
		if axis.length() > 0.1:
			_target = null
			move = axis.limit_length(1.0) * PLAYER_SPEED * dt
		elif _target != null:
			var to: Vector2 = (_target as Vector2) - player_pos
			move = to.limit_length(PLAYER_SPEED * 2.0 * dt)
	_try_move(move)


func _try_move(move: Vector2) -> void:
	var lo := Vector2(PLAYER_SIZE.x / 2 + 1, ZONE_TOP * CELL + PLAYER_SIZE.y / 2)
	var hi := Vector2(W - PLAYER_SIZE.x / 2 - 1, H - PLAYER_SIZE.y / 2)
	for axis: Vector2 in [Vector2(move.x, 0), Vector2(0, move.y)]:
		var np := (player_pos + axis).clamp(lo, hi)
		var r := Rect2(np - PLAYER_SIZE / 2, PLAYER_SIZE).grow(-0.5)
		var hit := false
		var c0 := cell_of(r.position)
		var c1 := cell_of(r.end)
		for y in range(c0.y, c1.y + 1):
			for x in range(c0.x, c1.x + 1):
				if mushroom_at(Vector2i(x, y)) > 0 and cell_rect(Vector2i(x, y)).intersects(r):
					hit = true
		if not hit:
			player_pos = np


func _try_fire() -> void:
	if shot != null:
		return
	var want := false
	if is_ai():
		want = true
	else:
		want = Input.is_action_pressed("ce_fire") or _touching or _mouse_fire
	if want:
		shot = player_pos - Vector2(0, 4)
		fired.emit(shot)


func _unhandled_input(event: InputEvent) -> void:
	if paused or is_ai():
		return
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventMouseMotion:
		_target = (event.position - ORIGIN) / SCALE
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_fire = event.pressed
	elif event is InputEventScreenTouch:
		_touching = event.pressed
	elif event is InputEventScreenDrag:
		_target = null
		_try_move(event.relative / SCALE * TOUCH_GAIN)


func clear_input() -> void:
	_touching = false
	_mouse_fire = false


func _move_shot(dt: float) -> void:
	if shot == null:
		return
	var travel := SHOT_SPEED * dt
	var from: Vector2 = shot
	shot = from - Vector2(0, travel)
	var r := Rect2(Vector2(shot.x - 0.5, shot.y), Vector2(1, travel + 4))
	# segmentos
	for i in segments.size():
		var s: Dictionary = segments[i]
		if seg_rect(s).intersects(r):
			_kill_segment(i)
			shot = null
			return
	# criaturas
	if flea != null and Rect2(flea.pos - Vector2(4, 4), Vector2(8, 8)).intersects(r):
		flea.hp -= 1
		shot = null
		if flea.hp <= 0:
			var p: Vector2 = flea.pos
			flea = null
			_add_score(200)
			creature_killed.emit("pulga", p, 200)
		return
	if spider != null and Rect2(spider.pos - Vector2(7, 4), Vector2(14, 8)).intersects(r):
		var p: Vector2 = spider.pos
		var d := p.distance_to(player_pos)
		var pts := 900 if d < 16.0 else (600 if d < 32.0 else 300)
		spider = null
		shot = null
		_add_score(pts)
		creature_killed.emit("aranha", p, pts)
		return
	if scorpion != null and Rect2(scorpion.pos - Vector2(8, 4), Vector2(16, 8)).intersects(r):
		var p: Vector2 = scorpion.pos
		scorpion = null
		shot = null
		_add_score(1000)
		creature_killed.emit("escorpiao", p, 1000)
		return
	# cogumelos (o primeiro no caminho do tiro, de baixo para cima)
	var c_from := cell_of(from)
	var c_to := cell_of(shot)
	for y in range(c_from.y, c_to.y - 1, -1):
		var c := Vector2i(c_from.x, y)
		if mushroom_at(c) > 0:
			var i := c.y * COLS + c.x
			mushrooms[i] -= 1
			var destroyed := mushrooms[i] == 0
			if destroyed:
				poisoned[i] = 0
				_add_score(1)
			mushroom_hit.emit(c, destroyed)
			shot = null
			return
	if shot.y < 0.0:
		shot = null


func _kill_segment(i: int) -> void:
	var s: Dictionary = segments[i]
	var head: bool = s.head
	var pts := 100 if head else 10
	var c: Vector2i = cell_of((s.pos as Vector2) + Vector2(4, 4))
	mushrooms[c.y * COLS + c.x] = 4
	if i + 1 < segments.size():
		segments[i + 1].head = true
	segments.remove_at(i)
	_add_score(pts)
	segment_killed.emit(Vector2(c) * CELL + Vector2(4, 4), head, pts)


func _add_score(pts: int) -> void:
	var p := player()
	p.score += pts
	while p.score >= p.next_extra:
		p.next_extra += EXTRA_LIFE_EVERY
		p.lives += 1
		extra_life.emit()


# ---------------------------------------------------------------- criaturas

func _creatures(dt: float) -> void:
	var w := wave()
	# pulga: quando há poucos cogumelos na zona do jogador (a partir da vaga 2)
	if flea == null and w >= 2:
		var count := 0
		for y in range(ZONE_TOP, ROWS):
			for x in COLS:
				if mushrooms[y * COLS + x] > 0:
					count += 1
		if count < 5 and randf() < dt * 0.6:
			flea = {"pos": Vector2((randi() % COLS) * CELL + 4, -4), "hp": 2, "last": -1}
			creature_spawned.emit("pulga")
	if flea != null:
		var speed := 110.0 if flea.hp == 2 else 200.0
		flea.pos.y += speed * dt
		var c := cell_of(flea.pos)
		if c.y != flea.last:
			flea.last = c.y
			if c.y < ROWS - 2 and mushroom_at(c) == 0 and randf() < 0.3:
				mushrooms[c.y * COLS + c.x] = 4
		if flea.pos.y > H + 4:
			flea = null
			creature_gone.emit("pulga")
	# aranha
	if spider == null:
		_spider_t -= dt
		if _spider_t <= 0.0:
			var left := randf() < 0.5
			spider = {"pos": Vector2(-8 if left else W + 8, (ZONE_TOP - 4) * CELL), "vel": Vector2((50.0 + w * 4.0) * (1 if left else -1), 60.0), "t": 0.6}
			creature_spawned.emit("aranha")
	else:
		spider.t -= dt
		if spider.t <= 0.0:
			spider.t = randf_range(0.3, 0.9)
			spider.vel.y = (60.0 + randf() * 50.0) * (1 if randf() < 0.5 else -1)
			# por vezes pára de avançar e só salta
			spider.vel.x = signf(spider.vel.x) * (0.0 if randf() < 0.2 else 50.0 + w * 4.0)
			if is_zero_approx(spider.vel.x):
				spider.vel.x = 0.0001 * (1 if spider.pos.x < W / 2 else -1)
		spider.pos += spider.vel * dt
		var top := (ZONE_TOP - 4) * CELL
		if spider.pos.y < top:
			spider.pos.y = top
			spider.vel.y = absf(spider.vel.y)
		elif spider.pos.y > H - 4:
			spider.pos.y = H - 4
			spider.vel.y = -absf(spider.vel.y)
		var c := cell_of(spider.pos)
		if mushroom_at(c) > 0 and randf() < dt * 4.0:
			mushrooms[c.y * COLS + c.x] = 0
			poisoned[c.y * COLS + c.x] = 0
		if spider.pos.x < -12 or spider.pos.x > W + 12:
			spider = null
			_spider_t = randf_range(3.0, 7.0)
			creature_gone.emit("aranha")
	# escorpião (a partir da vaga 3)
	if scorpion == null and w >= 3:
		_scorpion_t -= dt
		if _scorpion_t <= 0.0:
			_scorpion_t = randf_range(14.0, 24.0)
			var left := randf() < 0.5
			var row := 3 + randi() % 14
			scorpion = {"pos": Vector2(-8 if left else W + 8, row * CELL + 4), "dir": 1.0 if left else -1.0}
			creature_spawned.emit("escorpiao")
	elif scorpion != null:
		scorpion.pos.x += scorpion.dir * 45.0 * dt
		var c := cell_of(scorpion.pos)
		if mushroom_at(c) > 0:
			poisoned[c.y * COLS + c.x] = 1
		if scorpion.pos.x < -12 or scorpion.pos.x > W + 12:
			scorpion = null
			creature_gone.emit("escorpiao")


func _check_player() -> void:
	var pr := player_rect().grow(-1.0)
	for s in segments:
		if seg_rect(s).intersects(pr):
			_kill_player()
			return
	if spider != null and Rect2(spider.pos - Vector2(6, 3), Vector2(12, 6)).intersects(pr):
		_kill_player()
		return
	if flea != null and Rect2(flea.pos - Vector2(3, 3), Vector2(6, 6)).intersects(pr):
		_kill_player()


func _kill_player() -> void:
	if state != State.PLAY:
		return
	player().lives -= 1
	state = State.DYING
	timer = 1.6
	shot = null
	player_hit.emit(player_pos)


func _start_repair() -> void:
	flea = null
	spider = null
	scorpion = null
	_repair_queue.clear()
	for y in ROWS:
		for x in COLS:
			var i := y * COLS + x
			if (mushrooms[i] > 0 and mushrooms[i] < 4) or poisoned[i] == 1:
				_repair_queue.append(Vector2i(x, y))
	state = State.REPAIR
	_repair_t = 0.3


func _after_death() -> void:
	_save_player()
	var next := current
	if mode == Mode.TWO and players[1 - current].lives > 0:
		next = 1 - current
	if players[next].lives <= 0:
		state = State.OVER
		timer = 3.0
		game_over.emit()
		return
	current = next
	_load_player()
	_new_centipede()
	_reset_turn()
	turn_started.emit(current)


# ---------------------------------------------------------------- CPU da demonstração

func _ai_move(dt: float) -> Vector2:
	var target_x := player_pos.x
	var lowest := -1.0
	for s in segments:
		if s.pos.y > lowest:
			lowest = s.pos.y
			target_x = s.pos.x + 4.0 + s.dx * 10.0
	var target := Vector2(target_x, H - 6)
	var danger := Vector2.ZERO
	if spider != null:
		var d: Vector2 = player_pos - spider.pos
		if d.length() < 40.0:
			danger += d.normalized() * 60.0
	for s in segments:
		var d: Vector2 = player_pos - ((s.pos as Vector2) + Vector2(4, 4))
		if d.length() < 22.0:
			danger += d.normalized() * 40.0
	if flea != null and absf(flea.pos.x - player_pos.x) < 10.0:
		danger.x += 40.0 * signf(player_pos.x - flea.pos.x + 0.01)
	target += danger
	return (target - player_pos).limit_length(PLAYER_SPEED * dt)
