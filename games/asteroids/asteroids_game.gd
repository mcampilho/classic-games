class_name AsteroidsGame
extends Node2D
## Lógica do Asteroids (Atari, 1979), independente do visual.
##
## Regras do original:
##  - a nave roda, acelera com inércia e "flutua"; tudo dá a volta ao ecrã
##  - até 4 tiros no ecrã; hiperespaço (com risco de explodir ao reaparecer)
##  - asteroides grandes (20 pts) partem-se em 2 médios (50), que se partem em 2 pequenos (100)
##  - disco voador grande (200 pts, dispara ao acaso) e pequeno (1000 pts, aponta à nave)
##  - a "batida" de 2 notas acelera ao longo da vaga; vida extra a cada 10 000 pontos
##  - cada vaga começa com mais asteroides (4, 6, 8... até 11)

signal match_started
signal turn_started(player: int)
signal fired(pos: Vector2, dir: Vector2)
signal asteroid_destroyed(pos: Vector2, size: int, points: int, rock: Dictionary)
signal ship_destroyed(pos: Vector2)
signal hyperspace_jump(from: Vector2, to: Vector2)
signal saucer_spawned(small: bool)
signal saucer_destroyed(pos: Vector2, small: bool, points: int)
signal saucer_gone
signal saucer_fired(pos: Vector2)
signal heartbeat(note: int)
signal extra_life
signal wave_cleared
signal game_over

enum Mode { DEMO, ONE, TWO }
enum State { PLAY, OVER }
enum Ship { ALIVE, DEAD, HYPER, WAITING }

const SCREEN := Vector2(1280, 720)
const ROCK_RADIUS := [48.0, 24.0, 12.0]
const ROCK_POINTS := [20, 50, 100]
const ROCK_SPEED := [Vector2(40, 90), Vector2(70, 140), Vector2(100, 190)]
const SHIP_RADIUS := 12.0
const SHIP_SHAPE := [Vector2(16, 0), Vector2(-11, -10), Vector2(-6, 0), Vector2(-11, 10)]
const TURN_SPEED := 4.6
const THRUST := 480.0
const MAX_SPEED := 560.0
const DAMPING := 0.45
const BULLET_SPEED := 760.0
const BULLET_LIFE := 0.85
const MAX_BULLETS := 4
const AUTOFIRE := 0.22
const SAUCER_RADIUS := [20.0, 11.0]          # grande, pequeno
const SAUCER_POINTS := [200, 1000]
const SAUCER_SPEED := 150.0
const SAUCER_BULLET_SPEED := 420.0
const SAUCER_BULLET_LIFE := 1.1
const EXTRA_LIFE_EVERY := 10000
const SAFE_RADIUS := 150.0
const HYPER_BUTTON := Vector2(1180, 600)      # botão tátil de hiperespaço
const HYPER_BUTTON_R := 58.0

var mode := Mode.DEMO
var start_lives := 3
var state := State.PLAY
var paused := false
var skin: AsteroidsSkin
var best := 0

var players: Array[Dictionary] = []          # score, lives, wave, next_extra, rocks (guardados)
var current := 0

var rocks: Array[Dictionary] = []            # pos, vel, size, r, angle, spin, shape, tint
var bullets: Array[Dictionary] = []          # pos, vel, life
var saucer_bullets: Array[Dictionary] = []
var saucer: Variant = null                   # {pos, vel, small, fire_t, turn_t, dir}

var ship_state := Ship.WAITING
var ship_pos := SCREEN / 2
var ship_vel := Vector2.ZERO
var ship_angle := -PI / 2
var ship_timer := 0.0
var thrusting := false
var over_timer := 0.0

# controlos táteis (lidos também pelo desenho do joystick)
var touch_stick_origin: Variant = null
var touch_stick_vec := Vector2.ZERO
var touch_firing := false

var _stick_index := -1
var _fire_index := -1
var _fire_request := false
var _hyper_request := false
var _fire_cd := 0.0
var _mouse_aim: Variant = null
var _mouse_t := 0.0
var _mouse_fire := false
var _mouse_thrust := false
var _beat_t := 1.0
var _beat_interval := 1.0
var _beat_note := 0
var _saucer_t := 15.0
var _clear_t := -1.0
var _ai_hyper_cd := 0.0


func _init() -> void:
	_ensure_inputs()


static func _ensure_inputs() -> void:
	var defs := {
		"as_left": [_key(KEY_A), _key(KEY_LEFT), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"as_right": [_key(KEY_D), _key(KEY_RIGHT), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)],
		"as_thrust": [_key(KEY_W), _key(KEY_UP), _joy_button(JOY_BUTTON_DPAD_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0),
			_joy_button(JOY_BUTTON_RIGHT_SHOULDER), _joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)],
		"as_fire": [_key(KEY_SPACE), _key(KEY_ENTER), _joy_button(JOY_BUTTON_A), _joy_button(JOY_BUTTON_X)],
		"as_hyper": [_key(KEY_S), _key(KEY_DOWN), _key(KEY_SHIFT), _joy_button(JOY_BUTTON_Y), _joy_button(JOY_BUTTON_LEFT_SHOULDER)],
	}
	for action: String in defs:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.4)
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
		players.append({"score": 0, "lives": start_lives, "wave": 1, "next_extra": EXTRA_LIFE_EVERY, "rocks": null})
	current = 0
	state = State.PLAY
	bullets.clear()
	saucer_bullets.clear()
	saucer = null
	_clear_t = -1.0
	_new_wave()
	_respawn()
	match_started.emit()
	turn_started.emit(0)


func set_skin(new_skin: AsteroidsSkin) -> void:
	if skin:
		skin.queue_free()
	skin = new_skin
	add_child(skin)
	skin.attach(self)


func player() -> Dictionary:
	return players[current]


func _new_wave() -> void:
	rocks.clear()
	var n := mini(4 + (player().wave - 1) * 2, 11)
	for i in n:
		var pos := Vector2.ZERO
		# nasce junto às margens, longe do centro
		while true:
			pos = Vector2(randf() * SCREEN.x, randf() * SCREEN.y)
			if pos.distance_to(SCREEN / 2) > 260.0:
				break
		_spawn_rock(pos, 0)
	_beat_interval = 1.0
	_beat_t = 1.0
	_saucer_t = randf_range(14.0, 22.0)


func _spawn_rock(pos: Vector2, size: int, vel: Variant = null, tint := -1.0) -> Dictionary:
	var shape := PackedVector2Array()
	var n := 11 if size == 0 else (10 if size == 1 else 8)
	for i in n:
		var a := TAU * i / n + randf_range(-0.12, 0.12)
		shape.append(Vector2.from_angle(a) * randf_range(0.72, 1.08))
	var spd: Vector2 = ROCK_SPEED[size]
	var v: Vector2 = vel if vel != null else Vector2.from_angle(randf() * TAU) * randf_range(spd.x, spd.y)
	var r := {
		"pos": pos, "vel": v, "size": size, "r": ROCK_RADIUS[size],
		"angle": randf() * TAU, "spin": randf_range(-1.2, 1.2) * (1.0 + size * 0.5),
		"shape": shape, "tint": tint if tint >= 0.0 else randf(),
	}
	rocks.append(r)
	return r


func _respawn() -> void:
	ship_state = Ship.WAITING
	ship_pos = SCREEN / 2
	ship_vel = Vector2.ZERO
	ship_angle = -PI / 2
	thrusting = false


# ---------------------------------------------------------------- consultas (para os skins)

## Diferença mais curta entre dois pontos num ecrã que dá a volta.
static func wrap_delta(a: Vector2, b: Vector2) -> Vector2:
	var d := a - b
	d.x = wrapf(d.x, -SCREEN.x / 2, SCREEN.x / 2)
	d.y = wrapf(d.y, -SCREEN.y / 2, SCREEN.y / 2)
	return d


static func wrap_pos(p: Vector2) -> Vector2:
	return Vector2(fposmod(p.x, SCREEN.x), fposmod(p.y, SCREEN.y))


func ship_visible() -> bool:
	return ship_state == Ship.ALIVE


func ship_waiting() -> bool:
	return ship_state == Ship.WAITING and state == State.PLAY


func ship_points(pos := ship_pos, angle := ship_angle, scale := 1.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in SHIP_SHAPE:
		out.append(pos + p.rotated(angle) * scale)
	return out


func rock_points(r: Dictionary, offset := Vector2.ZERO) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in r.shape:
		out.append(r.pos + offset + p.rotated(r.angle) * r.r)
	return out


func saucer_radius() -> float:
	return SAUCER_RADIUS[1 if saucer.small else 0] if saucer != null else 0.0


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
	_fire_request = false
	_hyper_request = false


func _step(dt: float) -> void:
	_move_rocks(dt)
	if state == State.OVER:
		_move_bullets(dt)
		if mode == Mode.DEMO:
			over_timer -= dt
			if over_timer <= 0.0:
				reset_match()
		return
	_update_ship(dt)
	_move_bullets(dt)
	_update_saucer(dt)
	_collisions()
	_heartbeat(dt)
	_check_wave(dt)


# ---------------------------------------------------------------- nave

func _update_ship(dt: float) -> void:
	match ship_state:
		Ship.WAITING:
			if _is_safe(SCREEN / 2):
				ship_state = Ship.ALIVE
		Ship.DEAD:
			ship_timer -= dt
			if ship_timer <= 0.0:
				_after_death()
		Ship.HYPER:
			ship_timer -= dt
			if ship_timer <= 0.0:
				ship_state = Ship.ALIVE
				ship_vel = Vector2.ZERO
				# Como no original, o regresso do hiperespaço nem sempre corre bem.
				if randf() < 0.125 and not rocks.is_empty():
					_kill_ship()
		Ship.ALIVE:
			_ship_controls(dt)
	if ship_state == Ship.ALIVE:
		if thrusting:
			ship_vel += Vector2.from_angle(ship_angle) * THRUST * dt
			ship_vel = ship_vel.limit_length(MAX_SPEED)
		ship_vel *= exp(-DAMPING * dt)
		ship_pos = wrap_pos(ship_pos + ship_vel * dt)
	else:
		thrusting = false


func _ship_controls(dt: float) -> void:
	_fire_cd -= dt
	var turn := 0.0
	var want_thrust := false
	var want_fire := false
	var hyper := false
	if is_ai():
		var ai := _ai()
		turn = ai.turn
		want_thrust = ai.thrust
		want_fire = ai.fire
		hyper = ai.hyper
	else:
		turn = Input.get_axis("as_left", "as_right")
		want_thrust = Input.is_action_pressed("as_thrust") or _mouse_thrust
		var holding := Input.is_action_pressed("as_fire") or _mouse_fire or touch_firing
		want_fire = _fire_request or (holding and _fire_cd <= 0.0)
		hyper = _hyper_request
		if is_zero_approx(turn):
			var aim: Variant = null
			if touch_stick_origin != null and touch_stick_vec.length() > 18.0:
				aim = touch_stick_vec.angle()
				want_thrust = want_thrust or touch_stick_vec.length() > 55.0
			elif _mouse_aim != null and _mouse_t > 0.0:
				aim = (_mouse_aim - ship_pos).angle()
			if aim != null:
				var diff := angle_difference(ship_angle, float(aim))
				turn = clampf(diff * 6.0, -1.0, 1.0)
		else:
			_mouse_t = 0.0
		_mouse_t -= dt
	ship_angle = wrapf(ship_angle + turn * TURN_SPEED * dt, -PI, PI)
	thrusting = want_thrust
	if want_fire and _fire_cd <= 0.0:
		_fire()
		_fire_request = false
	if hyper:
		_hyper_request = false
		_hyperspace()


func _fire() -> void:
	_fire_cd = AUTOFIRE
	if bullets.size() >= MAX_BULLETS:
		return
	var dir := Vector2.from_angle(ship_angle)
	var pos := wrap_pos(ship_pos + dir * 16.0)
	bullets.append({"pos": pos, "vel": dir * BULLET_SPEED + ship_vel * 0.5, "life": BULLET_LIFE})
	fired.emit(pos, dir)


func _hyperspace() -> void:
	var from := ship_pos
	ship_state = Ship.HYPER
	ship_timer = 0.6
	thrusting = false
	ship_pos = Vector2(randf_range(60.0, SCREEN.x - 60.0), randf_range(60.0, SCREEN.y - 60.0))
	hyperspace_jump.emit(from, ship_pos)


func _is_safe(p: Vector2) -> bool:
	for r in rocks:
		if wrap_delta(r.pos, p).length() < SAFE_RADIUS + r.r:
			return false
	for b in saucer_bullets:
		if wrap_delta(b.pos, p).length() < 80.0:
			return false
	if saucer != null and wrap_delta(saucer.pos, p).length() < SAFE_RADIUS:
		return false
	return true


func _kill_ship() -> void:
	if ship_state == Ship.DEAD:
		return
	ship_state = Ship.DEAD
	ship_timer = 2.4
	thrusting = false
	player().lives -= 1
	ship_destroyed.emit(ship_pos)


func _after_death() -> void:
	player().rocks = rocks.duplicate(true)
	var next := current
	if mode == Mode.TWO and players[1 - current].lives > 0:
		next = 1 - current
	if players[next].lives <= 0:
		state = State.OVER
		over_timer = 4.0
		if saucer != null:
			saucer = null
			saucer_gone.emit()
		game_over.emit()
		return
	if next != current:
		current = next
		var saved: Variant = player().rocks
		if saved == null:
			_new_wave()
		else:
			rocks.assign(saved)
		bullets.clear()
		saucer_bullets.clear()
		if saucer != null:
			saucer = null
			saucer_gone.emit()
		_clear_t = -1.0
	_respawn()
	turn_started.emit(current)


# ---------------------------------------------------------------- entrada

func _unhandled_input(event: InputEvent) -> void:
	if paused or is_ai():
		return
	if event.is_action_pressed("as_fire"):
		_fire_request = true
	elif event.is_action_pressed("as_hyper"):
		_hyper_request = true
	var emulated := event.device == InputEvent.DEVICE_ID_EMULATION
	if emulated:
		return
	if event is InputEventMouseMotion:
		_mouse_aim = event.position
		_mouse_t = 2.0
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_mouse_fire = event.pressed
			if event.pressed:
				_fire_request = true
				_mouse_aim = event.position
				_mouse_t = 2.0
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_mouse_thrust = event.pressed
		elif event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			_hyper_request = true
	elif event is InputEventScreenTouch:
		# Metade esquerda: joystick virtual (rodar + acelerar). Metade direita: disparar / hiperespaço.
		if event.pressed:
			if event.position.x < SCREEN.x / 2:
				_stick_index = event.index
				touch_stick_origin = event.position
				touch_stick_vec = Vector2.ZERO
			elif event.position.distance_to(HYPER_BUTTON) < HYPER_BUTTON_R:
				_hyper_request = true
			else:
				_fire_index = event.index
				touch_firing = true
				_fire_request = true
		else:
			if event.index == _stick_index:
				_stick_index = -1
				touch_stick_origin = null
				touch_stick_vec = Vector2.ZERO
			elif event.index == _fire_index:
				_fire_index = -1
				touch_firing = false
	elif event is InputEventScreenDrag and event.index == _stick_index:
		touch_stick_vec = (event.position - touch_stick_origin).limit_length(90.0)


func clear_input() -> void:
	touch_stick_origin = null
	touch_stick_vec = Vector2.ZERO
	touch_firing = false
	_stick_index = -1
	_fire_index = -1
	_mouse_fire = false
	_mouse_thrust = false


# ---------------------------------------------------------------- mundo

func _move_rocks(dt: float) -> void:
	for r in rocks:
		r.pos = wrap_pos(r.pos + r.vel * dt)
		r.angle += r.spin * dt


func _move_bullets(dt: float) -> void:
	for list: Array[Dictionary] in [bullets, saucer_bullets]:
		for b in list:
			b.pos = wrap_pos(b.pos + b.vel * dt)
			b.life -= dt
		var alive := list.filter(func(b: Dictionary) -> bool: return b.life > 0.0)
		list.assign(alive)


func _update_saucer(dt: float) -> void:
	if saucer == null:
		if ship_state == Ship.ALIVE and not rocks.is_empty():
			_saucer_t -= dt
			if _saucer_t <= 0.0:
				_spawn_saucer()
		return
	saucer.pos.x += saucer.vel.x * dt
	saucer.pos.y = fposmod(saucer.pos.y + saucer.vel.y * dt, SCREEN.y)
	saucer.turn_t -= dt
	if saucer.turn_t <= 0.0:
		saucer.turn_t = randf_range(0.8, 1.6)
		saucer.vel.y = [-1.0, 0.0, 1.0].pick_random() * SAUCER_SPEED * 0.6
	saucer.fire_t -= dt
	if saucer.fire_t <= 0.0:
		saucer.fire_t = 0.8 if saucer.small else 1.0
		_saucer_fire()
	if (saucer.dir > 0.0 and saucer.pos.x > SCREEN.x + 40.0) or (saucer.dir < 0.0 and saucer.pos.x < -40.0):
		saucer = null
		_saucer_t = randf_range(10.0, 18.0)
		saucer_gone.emit()


func _spawn_saucer() -> void:
	var score: int = player().score
	var small_chance := 0.2 if score < 10000 else 0.6
	var small := randf() < small_chance
	var dir := 1.0 if randf() < 0.5 else -1.0
	saucer = {
		"pos": Vector2(-30.0 if dir > 0.0 else SCREEN.x + 30.0, randf_range(80.0, SCREEN.y - 80.0)),
		"vel": Vector2(dir * SAUCER_SPEED * (1.25 if small else 1.0), 0.0),
		"small": small, "dir": dir, "turn_t": 1.0, "fire_t": 0.9,
	}
	saucer_spawned.emit(small)


func _saucer_fire() -> void:
	var a := randf() * TAU
	if saucer.small and ship_state == Ship.ALIVE:
		# O disco pequeno aponta; fica mais certeiro com a pontuação.
		var err := lerpf(0.35, 0.06, clampf(player().score / 40000.0, 0.0, 1.0))
		a = (-wrap_delta(saucer.pos, ship_pos)).angle() + randf_range(-err, err)
	var pos: Vector2 = saucer.pos
	saucer_bullets.append({"pos": pos, "vel": Vector2.from_angle(a) * SAUCER_BULLET_SPEED, "life": SAUCER_BULLET_LIFE})
	saucer_fired.emit(pos)


# ---------------------------------------------------------------- colisões

func _collisions() -> void:
	# tiros do jogador
	for b in bullets.duplicate():
		var hit := false
		for r in rocks.duplicate():
			if wrap_delta(b.pos, r.pos).length() < r.r:
				_hit_rock(r, true)
				hit = true
				break
		if not hit and saucer != null and wrap_delta(b.pos, saucer.pos).length() < saucer_radius() + 2.0:
			_destroy_saucer(true)
			hit = true
		if hit:
			bullets.erase(b)
	# tiros do disco voador
	for b in saucer_bullets.duplicate():
		var hit := false
		for r in rocks.duplicate():
			if wrap_delta(b.pos, r.pos).length() < r.r:
				_hit_rock(r, false)
				hit = true
				break
		if not hit and ship_state == Ship.ALIVE and wrap_delta(b.pos, ship_pos).length() < SHIP_RADIUS:
			_kill_ship()
			hit = true
		if hit:
			saucer_bullets.erase(b)
	# nave contra asteroides e disco
	if ship_state == Ship.ALIVE:
		for r in rocks.duplicate():
			if wrap_delta(ship_pos, r.pos).length() < r.r + SHIP_RADIUS * 0.75:
				_hit_rock(r, true)
				_kill_ship()
				break
	if ship_state == Ship.ALIVE and saucer != null and wrap_delta(ship_pos, saucer.pos).length() < saucer_radius() + SHIP_RADIUS:
		_destroy_saucer(true)
		_kill_ship()
	# disco contra asteroides
	if saucer != null:
		for r in rocks.duplicate():
			if wrap_delta(saucer.pos, r.pos).length() < r.r + saucer_radius():
				_hit_rock(r, false)
				_destroy_saucer(false)
				break


func _hit_rock(r: Dictionary, award: bool) -> void:
	rocks.erase(r)
	var pts: int = ROCK_POINTS[r.size]
	if award:
		_add_score(pts)
	if r.size < 2:
		var size: int = r.size + 1
		var spd: Vector2 = ROCK_SPEED[size]
		for s in [-1.0, 1.0]:
			var v: Vector2 = r.vel.rotated(s * randf_range(0.3, 0.9)) * randf_range(1.1, 1.6)
			v = v.normalized() * clampf(v.length(), spd.x, spd.y)
			_spawn_rock(r.pos, size, v, r.tint)
	asteroid_destroyed.emit(r.pos, r.size, pts if award else 0, r)


func _destroy_saucer(award: bool) -> void:
	var small: bool = saucer.small
	var pos: Vector2 = saucer.pos
	var pts: int = SAUCER_POINTS[1 if small else 0]
	if award:
		_add_score(pts)
	saucer = null
	_saucer_t = randf_range(10.0, 18.0)
	saucer_destroyed.emit(pos, small, pts if award else 0)


func _add_score(pts: int) -> void:
	var p := player()
	p.score += pts
	while p.score >= p.next_extra:
		p.next_extra += EXTRA_LIFE_EVERY
		p.lives += 1
		extra_life.emit()


# ---------------------------------------------------------------- batida e vagas

func _heartbeat(dt: float) -> void:
	if rocks.is_empty() or ship_state == Ship.DEAD:
		return
	_beat_t -= dt
	if _beat_t <= 0.0:
		heartbeat.emit(_beat_note)
		_beat_note = 1 - _beat_note
		_beat_interval = maxf(0.22, _beat_interval - 0.015)
		_beat_t = _beat_interval


func _check_wave(dt: float) -> void:
	if not rocks.is_empty():
		return
	if _clear_t < 0.0:
		_clear_t = 2.0
		wave_cleared.emit()
		return
	_clear_t -= dt
	if _clear_t <= 0.0:
		_clear_t = -1.0
		player().wave += 1
		_new_wave()


# ---------------------------------------------------------------- CPU da demonstração

func _ai() -> Dictionary:
	var out := {"turn": 0.0, "thrust": false, "fire": false, "hyper": false}
	var target: Variant = null
	var best_d := INF
	for r in rocks:
		var d: float = wrap_delta(r.pos, ship_pos).length() - r.r
		if d < best_d:
			best_d = d
			target = r
	if saucer != null and wrap_delta(saucer.pos, ship_pos).length() < best_d + 200.0:
		target = saucer
	if target == null:
		return out
	var rel: Vector2 = wrap_delta(target.pos, ship_pos)
	var t := rel.length() / BULLET_SPEED
	var aim := rel + (target.vel as Vector2) * t
	var diff := angle_difference(ship_angle, aim.angle())
	out.turn = clampf(diff * 5.0, -1.0, 1.0)
	out.fire = absf(diff) < 0.12 and rel.length() < 620.0 and _fire_cd <= 0.0
	out.thrust = best_d > 330.0 and absf(diff) < 0.4 and ship_vel.length() < 140.0
	_ai_hyper_cd -= 1.0 / 240.0   # chamado a cada sub-passo (240 por segundo)
	if best_d < 14.0 and _ai_hyper_cd <= 0.0:
		out.hyper = true
		_ai_hyper_cd = 3.0
	return out
