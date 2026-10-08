class_name GalaxianGame
extends Node2D
## Lógica do Galaxian (Namco, 1979), independente do visual.
## Unidades do ecrã original (224x240), desenhadas a SCALE píxeis por unidade.
##
## Regras do original:
##  - formação de 46 naves que balança de um lado para o outro: 2 almirantes, 6 escoltas,
##    8 emissários e 30 zangões
##  - as naves descolam da formação em arco e mergulham sobre o jogador a disparar;
##    se não forem abatidas, saem por baixo e regressam ao lugar
##  - o almirante pode mergulhar com até 2 escoltas: vale 150 sozinho, 200/300 com escolta,
##    e 800 se as escoltas forem abatidas antes dele
##  - em formação valem metade; 1 míssil de cada vez; vida extra aos 7000 pontos
##  - quando restam poucas naves, atacam sem parar

signal match_started
signal turn_started(player: int)
signal fired(pos: Vector2)
signal dive_started(kind: int)
signal alien_killed(pos: Vector2, kind: int, points: int, diving: bool)
signal bomb_dropped(pos: Vector2)
signal player_hit(pos: Vector2)
signal extra_life
signal wave_cleared
signal game_over

enum Mode { DEMO, ONE, TWO }
enum State { READY, PLAY, DYING, CLEARED, OVER }
enum Fly { FORM, DIVE, RETURN }

const SCALE := 3.0
const ORIGIN := Vector2(304, 0)
const FIELD := Vector2(224, 240)
const COLS := 10
const CELL := Vector2(16, 12)
const FORMATION_TOP := 34.0
const SWAY_MIN := 8.0
const SWAY_MAX := 56.0
const SWAY_SPEED := 9.0
const KIND_SIZE := [Vector2(13, 10), Vector2(11, 8), Vector2(11, 8), Vector2(11, 8)]
const POINTS_FORM := [60, 50, 40, 30]
const POINTS_DIVE := [150, 100, 80, 60]
const PLAYER_Y := 212.0
const PLAYER_W := 13.0
const PLAYER_H := 10.0
const PLAYER_SPEED := 80.0
const MISSILE_SPEED := 300.0
const BOMB_SPEED := 110.0
const PEEL_TIME := 0.55
const PEEL_RADIUS := 14.0
const EXTRA_LIFE_AT := 7000
const TOUCH_GAIN := 1.4

var mode := Mode.DEMO
var start_lives := 3
var state := State.READY
var paused := false
var skin: GalaxianSkin
var best := 0

var players: Array[Dictionary] = []      # score, lives, wave, extra, alive (Array[bool] por lugar)
var current := 0

var aliens: Array[Dictionary] = []       # slot, kind, alive, fly, pos, vel, t, side, center, leader, escorts...
var form_x := SWAY_MIN
var form_dir := 1.0
var anim_frame := 0
var player_x := FIELD.x / 2
var missile: Variant = null              # Vector2 ou null
var bombs: Array[Dictionary] = []        # pos, vel
var timer := 0.0

var _anim_t := 0.0
var _attack_t := 3.0
var _target_x: Variant = null
var _touching := false
var _ai_target := FIELD.x / 2
var _ai_think := 0.0


func _init() -> void:
	_ensure_inputs()


static func _ensure_inputs() -> void:
	var defs := {
		"ga_left": [_key(KEY_A), _key(KEY_LEFT), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"ga_right": [_key(KEY_D), _key(KEY_RIGHT), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)],
		"ga_fire": [_key(KEY_SPACE), _key(KEY_W), _key(KEY_UP), _key(KEY_ENTER), _joy_button(JOY_BUTTON_A), _joy_button(JOY_BUTTON_X)],
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


# ---------------------------------------------------------------- formação

## Lugares da formação: [coluna, linha, tipo].
static func layout() -> Array:
	var out := []
	for c in [3, 6]:
		out.append([c, 0, 0])
	for c in range(2, 8):
		out.append([c, 1, 1])
	for c in range(1, 9):
		out.append([c, 2, 2])
	for r in range(3, 6):
		for c in range(0, 10):
			out.append([c, r, 3])
	return out


func _build_aliens(alive: Array) -> void:
	aliens.clear()
	var lay := layout()
	for i in lay.size():
		var l: Array = lay[i]
		var a := {"slot": Vector2i(l[0], l[1]), "kind": l[2], "alive": bool(alive[i]), "fly": Fly.FORM,
			"pos": Vector2.ZERO, "vel": Vector2.ZERO, "t": 0.0, "side": 1.0, "center": Vector2.ZERO, "theta0": 0.0,
			"leader": -1, "offset": Vector2.ZERO, "escorts": 0, "escorts_lost": 0, "bombs": 0, "bomb_t": 0.0}
		a.pos = slot_pos(a)
		aliens.append(a)


func slot_pos(a: Dictionary) -> Vector2:
	var size: Vector2 = KIND_SIZE[a.kind]
	var slot: Vector2i = a.slot
	return Vector2(form_x + slot.x * CELL.x + (CELL.x - size.x) / 2.0, FORMATION_TOP + slot.y * CELL.y)


func alien_rect(a: Dictionary) -> Rect2:
	return Rect2(a.pos, KIND_SIZE[a.kind])


func alive_count() -> int:
	var n := 0
	for a in aliens:
		if a.alive:
			n += 1
	return n


func player_rect() -> Rect2:
	return Rect2(player_x - PLAYER_W / 2, PLAYER_Y, PLAYER_W, PLAYER_H)


func to_px(u: Vector2) -> Vector2:
	return ORIGIN + u * SCALE


func player() -> Dictionary:
	return players[current]


func is_ai() -> bool:
	return mode == Mode.DEMO


# ---------------------------------------------------------------- partida

func start(p_mode: Mode, lives := 3) -> void:
	mode = p_mode
	start_lives = lives
	paused = false
	reset_match()


func reset_match() -> void:
	players.clear()
	var full := []
	full.resize(layout().size())
	full.fill(true)
	for i in (2 if mode == Mode.TWO else 1):
		players.append({"score": 0, "lives": start_lives, "wave": 1, "extra": false, "alive": full.duplicate()})
	current = 0
	_load_player()
	_reset_turn()
	match_started.emit()
	turn_started.emit(0)


func set_skin(new_skin: GalaxianSkin) -> void:
	if skin:
		skin.queue_free()
	skin = new_skin
	add_child(skin)
	skin.attach(self)


func _load_player() -> void:
	form_x = SWAY_MIN
	form_dir = 1.0
	_build_aliens(player().alive)


func _save_player() -> void:
	var alive := []
	for a in aliens:
		alive.append(a.alive)
	player().alive = alive


func _reset_turn() -> void:
	player_x = FIELD.x / 2
	missile = null
	bombs.clear()
	_target_x = null
	for a in aliens:
		a.fly = Fly.FORM
		a.leader = -1
		a.pos = slot_pos(a)
	_attack_t = 2.5
	state = State.READY
	timer = 1.6


# ---------------------------------------------------------------- ciclo

func _process(delta: float) -> void:
	if paused:
		return
	var steps := maxi(1, ceili(delta * 240.0))
	var dt := delta / steps
	for i in steps:
		_step(dt)


func _step(dt: float) -> void:
	_sway(dt)
	_anim_t += dt
	if _anim_t > 0.25:
		_anim_t = 0.0
		anim_frame = 1 - anim_frame
	_fly(dt)
	match state:
		State.READY:
			_move_player(dt)
			timer -= dt
			if timer <= 0.0:
				state = State.PLAY
		State.PLAY:
			_move_player(dt)
			_try_fire()
			_move_missile(dt)
			if state != State.PLAY:
				return
			_move_bombs(dt)
			if state != State.PLAY:
				return
			_attacks(dt)
			_divers_hit_player()
		State.DYING:
			_move_bombs(dt)
			timer -= dt
			if timer <= 0.0:
				_after_death()
		State.CLEARED:
			timer -= dt
			if timer <= 0.0:
				player().wave += 1
				var full := []
				full.resize(layout().size())
				full.fill(true)
				player().alive = full
				_load_player()
				_reset_turn()
				turn_started.emit(current)
		State.OVER:
			if mode == Mode.DEMO:
				timer -= dt
				if timer <= 0.0:
					reset_match()


func _sway(dt: float) -> void:
	form_x += form_dir * SWAY_SPEED * dt
	if form_x > SWAY_MAX:
		form_x = SWAY_MAX
		form_dir = -1.0
	elif form_x < SWAY_MIN:
		form_x = SWAY_MIN
		form_dir = 1.0


# ---------------------------------------------------------------- voo das naves

func _fly(dt: float) -> void:
	var wave: int = player().wave
	for a in aliens:
		if not a.alive:
			continue
		match a.fly:
			Fly.FORM:
				a.pos = slot_pos(a)
			Fly.DIVE:
				a.t += dt
				if a.leader >= 0 and aliens[a.leader].alive and aliens[a.leader].fly == Fly.DIVE:
					# escolta: acompanha o almirante
					var lead: Dictionary = aliens[a.leader]
					a.pos = lead.pos + a.offset
					a.vel = lead.vel
				elif a.t < PEEL_TIME:
					var th: float = a.theta0 + a.side * PI * (a.t / PEEL_TIME)
					a.pos = a.center + Vector2(cos(th), sin(th)) * PEEL_RADIUS
					a.vel = Vector2(0, 60)
				else:
					a.leader = -1
					var speed_y := minf(80.0 + wave * 6.0, 140.0)
					var tx := clampf((player_x - (a.pos.x + 6.0)) * 1.6, -75.0, 75.0)
					a.vel.x = move_toward(a.vel.x, tx, 170.0 * dt)
					a.vel.y = move_toward(a.vel.y, speed_y, 120.0 * dt)
					a.pos += a.vel * dt
				_maybe_bomb(a, dt)
				if a.pos.y > FIELD.y + 12.0:
					a.fly = Fly.RETURN
					a.leader = -1
					a.pos = Vector2(slot_pos(a).x, -14.0)
			Fly.RETURN:
				var target := slot_pos(a)
				a.pos = a.pos.move_toward(target, 100.0 * dt)
				if a.pos.distance_to(target) < 1.5:
					a.fly = Fly.FORM


func _maybe_bomb(a: Dictionary, dt: float) -> void:
	if state != State.PLAY or a.bombs >= 2 or a.pos.y < 70.0 or a.pos.y > 170.0:
		return
	a.bomb_t -= dt
	if a.bomb_t > 0.0:
		return
	a.bomb_t = 0.35
	if randf() < 0.55:
		a.bombs += 1
		var p: Vector2 = a.pos + Vector2(KIND_SIZE[a.kind].x / 2.0, KIND_SIZE[a.kind].y)
		bombs.append({"pos": p, "vel": Vector2(clampf((player_x - p.x) * 0.35, -35.0, 35.0), BOMB_SPEED)})
		bomb_dropped.emit(p)


func _attacks(dt: float) -> void:
	var wave: int = player().wave
	var n := alive_count()
	_attack_t -= dt
	if _attack_t > 0.0:
		return
	var rush := n <= 6
	_attack_t = (0.45 if rush else maxf(0.9, 2.4 - wave * 0.2)) * randf_range(0.7, 1.3)
	var divers := 0
	for a in aliens:
		if a.alive and a.fly != Fly.FORM:
			divers += 1
	var max_divers := n if rush else mini(2 + wave / 2, 6)
	if divers >= max_divers:
		return
	var in_form := aliens.filter(func(a: Dictionary) -> bool: return a.alive and a.fly == Fly.FORM)
	if in_form.is_empty():
		return
	var flags := in_form.filter(func(a: Dictionary) -> bool: return a.kind == 0)
	if not flags.is_empty() and randf() < 0.3:
		_launch_flagship(flags.pick_random())
		return
	# uma nave de uma das colunas das pontas
	var side := 1 if randf() < 0.5 else -1
	var edge_col := -1
	for a in in_form:
		var c: int = a.slot.x
		if edge_col < 0 or (side < 0 and c < edge_col) or (side > 0 and c > edge_col):
			edge_col = c
	var cands := in_form.filter(func(a: Dictionary) -> bool: return absi(a.slot.x - edge_col) <= 1 and a.kind != 0)
	if cands.is_empty():
		cands = in_form
	_launch(cands.pick_random())


func _launch(a: Dictionary) -> void:
	a.fly = Fly.DIVE
	a.t = 0.0
	a.bombs = 0
	a.bomb_t = 0.2
	a.leader = -1
	a.escorts = 0
	a.escorts_lost = 0
	a.side = -1.0 if a.slot.x < 5 else 1.0
	a.center = a.pos + Vector2(a.side * PEEL_RADIUS, 0)
	a.theta0 = PI if a.side > 0.0 else 0.0
	a.vel = Vector2.ZERO
	dive_started.emit(a.kind)


func _launch_flagship(f: Dictionary) -> void:
	_launch(f)
	var fi := aliens.find(f)
	var col: int = f.slot.x
	var escorts := aliens.filter(func(a: Dictionary) -> bool:
		return a.alive and a.fly == Fly.FORM and a.kind == 1 and absi(a.slot.x - col) <= 1)
	escorts.shuffle()
	var k := 0
	for e in escorts.slice(0, 2):
		e.fly = Fly.DIVE
		e.t = 0.0
		e.bombs = 0
		e.bomb_t = 0.3
		e.leader = fi
		e.offset = Vector2(-13.0 if k == 0 else 13.0, -9.0)
		e.side = f.side
		k += 1
	f.escorts = k


# ---------------------------------------------------------------- jogador

func _move_player(dt: float) -> void:
	if is_ai():
		_ai(dt)
	else:
		var axis := Input.get_axis("ga_left", "ga_right")
		if not is_zero_approx(axis):
			_target_x = null
			player_x += axis * PLAYER_SPEED * dt
		elif _target_x != null:
			player_x = move_toward(player_x, float(_target_x), PLAYER_SPEED * 3.0 * dt)
	player_x = clampf(player_x, PLAYER_W / 2 + 2, FIELD.x - PLAYER_W / 2 - 2)


func _try_fire() -> void:
	if missile != null:
		return
	var want := false
	if is_ai():
		want = absf(player_x - _ai_target) < 3.0
	else:
		want = Input.is_action_pressed("ga_fire") or _touching or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if want:
		missile = Vector2(player_x, PLAYER_Y - 2)
		fired.emit(missile)


func _unhandled_input(event: InputEvent) -> void:
	if paused or is_ai():
		return
	var emulated := event.device == InputEvent.DEVICE_ID_EMULATION
	if event is InputEventMouseMotion and not emulated:
		_target_x = (event.position.x - ORIGIN.x) / SCALE
	elif event is InputEventScreenTouch and not emulated:
		_touching = event.pressed
	elif event is InputEventScreenDrag and not emulated:
		_target_x = null
		player_x += event.relative.x / SCALE * TOUCH_GAIN


func _move_missile(dt: float) -> void:
	if missile == null:
		return
	missile.y -= MISSILE_SPEED * dt
	var r := Rect2(missile.x - 0.5, missile.y, 1, 4)
	for a in aliens:
		if a.alive and alien_rect(a).intersects(r):
			_kill(a)
			missile = null
			return
	if missile.y < 6.0:
		missile = null


func _kill(a: Dictionary) -> void:
	a.alive = false
	var diving: bool = a.fly == Fly.DIVE
	var pts: int = POINTS_DIVE[a.kind] if diving else POINTS_FORM[a.kind]
	var idx := aliens.find(a)
	if a.kind == 0 and diving:
		# bónus do almirante, conforme a escolta
		var alive_escorts := 0
		for e in aliens:
			if e.alive and e.leader == idx and e.fly == Fly.DIVE:
				alive_escorts += 1
		if a.escorts > 0 and alive_escorts == 0 and a.escorts_lost >= a.escorts:
			pts = 800
		elif alive_escorts == 2:
			pts = 300
		elif alive_escorts == 1:
			pts = 200
	if a.kind == 1 and a.leader >= 0:
		aliens[a.leader].escorts_lost += 1
	_add_score(pts)
	alien_killed.emit(alien_rect(a).get_center(), a.kind, pts, diving)
	if alive_count() == 0:
		state = State.CLEARED
		timer = 2.0
		bombs.clear()
		wave_cleared.emit()


func _add_score(pts: int) -> void:
	var p := player()
	p.score += pts
	if not p.extra and p.score >= EXTRA_LIFE_AT:
		p.extra = true
		p.lives += 1
		extra_life.emit()


func _move_bombs(dt: float) -> void:
	for b in bombs.duplicate():
		b.pos += b.vel * dt
		if state == State.PLAY and Rect2(b.pos - Vector2(0.5, 0), Vector2(1, 3)).intersects(player_rect().grow(-1.0)):
			bombs.erase(b)
			_kill_player()
			return
		if b.pos.y > FIELD.y:
			bombs.erase(b)


func _divers_hit_player() -> void:
	var pr := player_rect().grow(-1.5)
	for a in aliens:
		if a.alive and a.fly == Fly.DIVE and alien_rect(a).intersects(pr):
			_kill(a)
			_kill_player()
			return


func _kill_player() -> void:
	if state != State.PLAY:
		return
	player().lives -= 1
	state = State.DYING
	timer = 2.2
	missile = null
	for a in aliens:
		if a.alive and a.fly == Fly.DIVE:
			a.fly = Fly.RETURN
			a.leader = -1
	player_hit.emit(Vector2(player_x, PLAYER_Y + PLAYER_H / 2))


func _after_death() -> void:
	bombs.clear()
	_save_player()
	var next := current
	if mode == Mode.TWO and players[1 - current].lives > 0:
		next = 1 - current
	if players[next].lives <= 0:
		state = State.OVER
		timer = 3.0
		game_over.emit()
		return
	if next != current:
		current = next
		_load_player()
	_reset_turn()
	turn_started.emit(current)


# ---------------------------------------------------------------- CPU da demonstração

func _ai(dt: float) -> void:
	_ai_think -= dt
	if _ai_think <= 0.0:
		_ai_think = 0.2
		var best_y := -INF
		var found := false
		for a in aliens:
			if a.alive and a.fly == Fly.DIVE and a.pos.y > best_y and a.pos.y < PLAYER_Y - 20.0:
				best_y = a.pos.y
				_ai_target = alien_rect(a).get_center().x
				found = true
		if not found:
			var form := aliens.filter(func(a: Dictionary) -> bool: return a.alive and a.fly == Fly.FORM)
			if not form.is_empty():
				var closest: Dictionary = form[0]
				for a in form:
					if absf(alien_rect(a).get_center().x - player_x) < absf(alien_rect(closest).get_center().x - player_x):
						closest = a
				_ai_target = alien_rect(closest).get_center().x
	var target := _ai_target
	for b in bombs:
		if b.pos.y > PLAYER_Y - 60.0 and absf(b.pos.x - player_x) < 9.0:
			target = player_x + (16.0 if b.pos.x <= player_x else -16.0)
	player_x = move_toward(player_x, target, PLAYER_SPEED * dt)
