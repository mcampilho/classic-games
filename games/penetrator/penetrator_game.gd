class_name PenetratorGame
extends Node2D
## Lógica do Penetrator (1981): a nave avança por um terreno com scroll horizontal, dispara em
## frente e larga bombas. Cinco zonas por missão — montanhas, cavernas, base de radares, túneis
## estreitos e o arsenal, onde é preciso destruir o depósito de bombas no fundo da caverna.
## Mísseis saem do chão quando a nave se aproxima; nas cavernas há discos voadores.

signal match_started
signal zone_started(zone: int)
signal fired
signal bomb_dropped
signal enemy_killed(pos: Vector2, kind: String, points: int)
signal missile_launched(pos: Vector2)
signal bomb_hit_ground(pos: Vector2)
signal store_hit(pos: Vector2, left: int)
signal player_died(pos: Vector2)
signal mission_complete(mission: int)
signal extra_life
signal game_over

enum Mode { DEMO, PLAY }
enum State { READY, PLAY, DYING, COMPLETE, OVER }

const W := 1280.0
const H := 720.0
const TOP := 70.0                 # topo do campo (por baixo do HUD)
const BOTTOM := 712.0
const CW := 8.0                   # largura de uma coluna de terreno
const ZONE_COLS := 560
const ZONES := 5
const ZONE_NAMES := ["Montanhas", "Cavernas", "Base de Radares", "Túneis", "Arsenal"]
const SHIP_SIZE := Vector2(62, 24)
const SHIP_SPEED := 280.0
const SHOT_SPEED := 760.0
const MAX_SHOTS := 3
const MAX_BOMBS := 2
const GRAVITY := 420.0
const STORE_HITS := 6
const EXTRA_LIFE_EVERY := 10000
const POINTS := {"missile": 50, "missile_air": 80, "radar": 100, "saucer": 150, "store": 1000}

var mode := Mode.DEMO
var state := State.READY
var paused := false
var skin: PenetratorSkin
var best := 0
var start_lives := 5

var floor_y := PackedFloat32Array()     # topo do chão por coluna
var ceil_y := PackedFloat32Array()      # fundo do teto por coluna (TOP = sem teto)
var zone_start := PackedInt32Array()    # coluna onde começa cada zona
var enemies: Array[Dictionary] = []     # kind, x, y, vy, alive, zone, phase, base_y
var shots: Array[Dictionary] = []       # x, y (mundo)
var bombs: Array[Dictionary] = []       # x, y, vx, vy
var cam_x := 0.0
var scroll_speed := 130.0
var ship := Vector2(200, 300)           # posição no ecrã
var ship_tilt := 0.0
var score := 0
var lives := 5
var mission := 1
var zone := 0
var timer := 0.0
var store_left := STORE_HITS
var next_extra := EXTRA_LIFE_EVERY
var _fire_cool := 0.0
var _bomb_cool := 0.0
var _touch_move: Variant = null          # dedo do lado esquerdo: origem
var _touch_ship: Vector2 = Vector2.ZERO
var _touch_index := -1
var _touch_fire := -1
var _touch_bomb_pending := false
var ai := {"dir": Vector2.ZERO, "fire": false, "bomb": false}


func _init() -> void:
	_ensure_inputs()


static func _ensure_inputs() -> void:
	var defs := {
		"pe_left": [_key(KEY_A), _key(KEY_LEFT), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"pe_right": [_key(KEY_D), _key(KEY_RIGHT), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)],
		"pe_up": [_key(KEY_W), _key(KEY_UP), _joy_button(JOY_BUTTON_DPAD_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)],
		"pe_down": [_key(KEY_S), _key(KEY_DOWN), _joy_button(JOY_BUTTON_DPAD_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)],
		"pe_fire": [_key(KEY_SPACE), _key(KEY_J), _key(KEY_Z), _joy_button(JOY_BUTTON_A)],
		"pe_bomb": [_key(KEY_B), _key(KEY_K), _key(KEY_X), _key(KEY_CTRL), _joy_button(JOY_BUTTON_B), _joy_button(JOY_BUTTON_X)],
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


func set_skin(new_skin: PenetratorSkin) -> void:
	if skin:
		skin.queue_free()
	skin = new_skin
	add_child(skin)
	skin.attach(self)


func is_ai() -> bool:
	return mode == Mode.DEMO


# ---------------------------------------------------------------- terreno

func cols() -> int:
	return floor_y.size()


func col_at(world_x: float) -> int:
	return clampi(floori(world_x / CW), 0, cols() - 1)


## Altura do chão / teto numa posição do mundo (interpolada entre colunas).
func floor_at(world_x: float) -> float:
	var f := world_x / CW
	var c := clampi(floori(f), 0, cols() - 2)
	return lerpf(floor_y[c], floor_y[c + 1], clampf(f - c, 0.0, 1.0))


func ceil_at(world_x: float) -> float:
	var f := world_x / CW
	var c := clampi(floori(f), 0, cols() - 2)
	return lerpf(ceil_y[c], ceil_y[c + 1], clampf(f - c, 0.0, 1.0))


func end_x() -> float:
	return (cols() - 1) * CW


func zone_of(world_x: float) -> int:
	var c := floori(world_x / CW)
	var z := 0
	for i in ZONES:
		if c >= zone_start[i]:
			z = i
	return z


func zone_progress() -> float:
	var a := zone_start[zone] * CW
	var b := (zone_start[zone + 1] if zone + 1 < ZONES else cols()) * CW
	return clampf((cam_x + ship.x - a) / (b - a), 0.0, 1.0)


func _build_mission() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1981 + mission * 17
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.03
	var noise2 := FastNoiseLite.new()
	noise2.seed = rng.randi()
	noise2.frequency = 0.05
	var n := ZONES * ZONE_COLS + 40
	floor_y.resize(n)
	ceil_y.resize(n)
	zone_start.resize(ZONES)
	var squeeze := minf((mission - 1) * 12.0, 50.0)
	for c in n:
		var z := mini(c / ZONE_COLS, ZONES - 1)
		var lc := c - z * ZONE_COLS
		var a := noise.get_noise_1d(c) * 0.5 + 0.5
		var b := noise2.get_noise_1d(c) * 0.5 + 0.5
		var f := 640.0
		var ce := TOP
		match z:
			0:
				f = 690.0 - pow(a, 1.4) * 360.0 - absf(sin(c * 0.11)) * 60.0 * b
			1:
				ce = TOP + 30.0 + a * 190.0
				f = BOTTOM - 30.0 - b * 190.0
			2:
				f = 640.0 - floorf(a * 4.0) * 45.0
			3:
				var mid := 390.0 + sin(c * 0.035) * 150.0 + (a - 0.5) * 80.0
				var gap := 190.0 - squeeze * 0.6 + b * 40.0
				ce = mid - gap / 2.0
				f = mid + gap / 2.0
			4:
				ce = TOP + 20.0 + a * 120.0
				f = BOTTOM - 40.0 - b * 140.0
				if lc > ZONE_COLS - 80:
					f = 640.0
					ce = TOP
		# transição suave entre zonas (a zona anterior abre ou fecha aos poucos)
		floor_y[c] = clampf(f, TOP + 120.0, BOTTOM)
		ceil_y[c] = clampf(ce, TOP, BOTTOM - 120.0)
	# parede no fim do arsenal
	for c in range(n - 6, n):
		floor_y[c] = TOP
		ceil_y[c] = TOP
	for z in ZONES:
		zone_start[z] = z * ZONE_COLS
	# suavizar fronteiras entre zonas
	for z in range(1, ZONES):
		var c0 := z * ZONE_COLS - 30
		var fa := floor_y[c0]
		var ca := ceil_y[c0]
		var fb := floor_y[c0 + 60]
		var cb := ceil_y[c0 + 60]
		for k in 60:
			var t := k / 60.0
			floor_y[c0 + k] = lerpf(fa, fb, t)
			ceil_y[c0 + k] = lerpf(ca, cb, t)
	# garantir passagem
	for c in n - 6:
		if floor_y[c] - ceil_y[c] < 150.0:
			var mid := (floor_y[c] + ceil_y[c]) / 2.0
			floor_y[c] = mid + 75.0
			ceil_y[c] = mid - 75.0
	_place_enemies(rng)


func _place_enemies(rng: RandomNumberGenerator) -> void:
	enemies.clear()
	for z in ZONES:
		var c0 := zone_start[z] + 40
		var c1 := zone_start[z] + ZONE_COLS - (90 if z == ZONES - 1 else 20)
		var c := c0
		var density: float = [0.55, 0.45, 0.8, 0.4, 0.55][z] * (1.0 + (mission - 1) * 0.15)
		while c < c1:
			c += rng.randi_range(10, 26)
			if rng.randf() > density:
				continue
			var slope := absf(floor_y[c] - floor_y[mini(c + 3, cols() - 1)])
			var kind := "missile"
			if z == 2 and rng.randf() < 0.45:
				kind = "radar"
			elif z == 0 and rng.randf() < 0.2:
				kind = "radar"
			elif (z == 1 or z == 3 or z == 4) and rng.randf() < 0.35:
				kind = "saucer"
			if kind != "saucer" and slope > 10.0:
				continue
			var x := c * CW + 12.0
			if kind == "saucer":
				var mid := (floor_at(x) + ceil_at(x)) / 2.0
				enemies.append({"kind": kind, "x": x, "y": mid, "base_y": mid, "vy": 0.0, "alive": true, "zone": z, "phase": rng.randf() * TAU, "flying": false})
			else:
				enemies.append({"kind": kind, "x": x, "y": floor_at(x), "base_y": floor_at(x), "vy": 0.0, "alive": true, "zone": z, "phase": rng.randf() * TAU, "flying": false})
	# o depósito de bombas, no fundo do arsenal
	var sx := end_x() - 560.0
	enemies.append({"kind": "store", "x": sx, "y": floor_at(sx), "base_y": floor_at(sx), "vy": 0.0, "alive": true, "zone": ZONES - 1, "phase": 0.0, "flying": false})


func _reset_zone_enemies(z: int) -> void:
	for e in enemies:
		if e.zone == z:
			e.alive = true
			e.flying = false
			e.vy = 0.0
			e.y = e.base_y
	if z == ZONES - 1:
		store_left = STORE_HITS


# ---------------------------------------------------------------- partida

func start(p_mode: Mode, p_lives := 5) -> void:
	mode = p_mode
	start_lives = p_lives
	paused = false
	score = 0
	lives = p_lives
	mission = 1
	next_extra = EXTRA_LIFE_EVERY
	_begin_mission()
	match_started.emit()


func _begin_mission() -> void:
	scroll_speed = 130.0 + (mission - 1) * 15.0
	_build_mission()
	store_left = STORE_HITS
	zone = 0
	_respawn()


func _respawn() -> void:
	cam_x = zone_start[zone] * CW
	var wx := cam_x + 200.0
	ship = Vector2(200.0, (floor_at(wx) + ceil_at(wx)) / 2.0 - 20.0)
	ship.y = clampf(ship.y, TOP + 30.0, BOTTOM - 30.0)
	if zone == 0:
		ship.y = minf(ship.y, 300.0)
	shots.clear()
	bombs.clear()
	_reset_zone_enemies(zone)
	state = State.READY
	timer = 1.5 if mode == Mode.PLAY else 0.5
	zone_started.emit(zone)


func _add_points(n: int) -> void:
	score += n
	if score >= next_extra:
		next_extra += EXTRA_LIFE_EVERY
		lives += 1
		extra_life.emit()


# ---------------------------------------------------------------- ciclo

func _process(delta: float) -> void:
	if paused:
		return
	delta = minf(delta, 0.1)
	if is_ai() and state == State.PLAY:
		_ai_think()
	var steps := maxi(1, ceili(delta * 240.0))
	var dt := delta / steps
	for i in steps:
		_step(dt)


func _step(dt: float) -> void:
	match state:
		State.READY:
			timer -= dt
			if timer <= 0.0:
				state = State.PLAY
		State.PLAY:
			_play(dt)
		State.DYING:
			timer -= dt
			_move_projectiles(dt)
			if timer <= 0.0:
				lives -= 1
				if lives <= 0:
					state = State.OVER
					timer = 3.0
					if mode == Mode.PLAY:
						best = maxi(best, score)
					game_over.emit()
				else:
					_respawn()
		State.COMPLETE:
			timer -= dt
			_move_projectiles(dt)
			if timer <= 0.0:
				mission += 1
				_begin_mission()
		State.OVER:
			if mode == Mode.DEMO:
				timer -= dt
				if timer <= 0.0:
					start(Mode.DEMO, 3)


func _play(dt: float) -> void:
	# scroll (para no fim do arsenal)
	cam_x = minf(cam_x + scroll_speed * dt, end_x() - W + 40.0)
	var z := zone_of(cam_x + ship.x)
	if z != zone:
		zone = z
		zone_started.emit(zone)
	# nave
	var c := _controls()
	var d: Vector2 = c.dir
	ship += d * SHIP_SPEED * dt
	ship.x = clampf(ship.x, 40.0, 700.0)
	ship.y = clampf(ship.y, TOP + 12.0, BOTTOM - 10.0)
	ship_tilt = move_toward(ship_tilt, d.y, dt * 6.0)
	_fire_cool -= dt
	_bomb_cool -= dt
	if c.fire and _fire_cool <= 0.0 and shots.size() < MAX_SHOTS:
		_fire_cool = 0.16
		shots.append({"x": cam_x + ship.x + SHIP_SIZE.x / 2, "y": ship.y + 2.0})
		fired.emit()
	if c.bomb and _bomb_cool <= 0.0 and bombs.size() < MAX_BOMBS:
		_bomb_cool = 0.35
		bombs.append({"x": cam_x + ship.x, "y": ship.y + 10.0, "vx": scroll_speed + 70.0, "vy": 40.0})
		bomb_dropped.emit()
	_move_projectiles(dt)
	_move_enemies(dt)
	if state != State.PLAY:
		return
	# colisão com o terreno
	var wx := cam_x + ship.x
	for k in 5:
		var x := wx - SHIP_SIZE.x / 2 + k * SHIP_SIZE.x / 4
		var hh := SHIP_SIZE.y / 2 * (1.0 if k in [1, 2, 3] else 0.5)
		if ship.y + hh > floor_at(x) or ship.y - hh < ceil_at(x):
			_die()
			return


func _controls() -> Dictionary:
	if is_ai():
		var a: Dictionary = ai.duplicate()
		ai.bomb = false
		return a
	var d := Vector2(Input.get_axis("pe_left", "pe_right"), Input.get_axis("pe_up", "pe_down"))
	if _touch_move != null:
		var to := (_touch_ship - ship)
		d = to / 40.0 if to.length() > 4.0 else Vector2.ZERO
		d = d.limit_length(1.0)
	var bomb := Input.is_action_pressed("pe_bomb") or _touch_bomb_pending
	_touch_bomb_pending = false
	return {"dir": d.limit_length(1.0), "fire": Input.is_action_pressed("pe_fire") or _touch_fire >= 0, "bomb": bomb}


func _move_projectiles(dt: float) -> void:
	for s in shots:
		s.x += SHOT_SPEED * dt
	shots = shots.filter(func(s: Dictionary) -> bool:
		if s.x > cam_x + W + 20.0:
			return false
		if s.y > floor_at(s.x) or s.y < ceil_at(s.x):
			return false
		for e in enemies:
			if e.alive and e.kind != "store" and _hits(e, Vector2(s.x, s.y), 6.0):
				_kill(e)
				return false
		return true)
	for b in bombs:
		b.vy += GRAVITY * dt
		b.x += b.vx * dt
		b.y += b.vy * dt
		b.vx = move_toward(b.vx, scroll_speed * 0.6, dt * 40.0)
	bombs = bombs.filter(func(b: Dictionary) -> bool:
		var p := Vector2(b.x, b.y)
		for e in enemies:
			if e.alive and _hits(e, p, 8.0):
				if e.kind == "store":
					_hit_store(e)
				else:
					_kill(e)
				return false
		if b.y > floor_at(b.x) or b.y < ceil_at(b.x):
			# a explosão no chão também apanha o que estiver perto
			for e in enemies:
				if e.alive and e.kind != "saucer" and e.kind != "store" and absf(e.x - b.x) < 26.0 and absf(e.y - b.y) < 30.0:
					_kill(e)
			bomb_hit_ground.emit(Vector2(b.x - cam_x, b.y))
			return false
		return b.x < cam_x + W + 40.0)


func _hits(e: Dictionary, p: Vector2, r: float) -> bool:
	var size := enemy_size(e.kind)
	var c := Vector2(e.x, float(e.y) - (0.0 if e.kind == "saucer" or e.flying else size.y / 2))
	return absf(p.x - c.x) < size.x / 2 + r and absf(p.y - c.y) < size.y / 2 + r


static func enemy_size(kind: String) -> Vector2:
	match kind:
		"missile":
			return Vector2(14, 42)
		"radar":
			return Vector2(38, 40)
		"saucer":
			return Vector2(46, 20)
		"store":
			return Vector2(90, 70)
	return Vector2(20, 20)


func _kill(e: Dictionary) -> void:
	e.alive = false
	var key: String = e.kind
	if e.kind == "missile" and e.flying:
		key = "missile_air"
	var pts: int = POINTS[key]
	_add_points(pts)
	var size := enemy_size(e.kind)
	enemy_killed.emit(Vector2(float(e.x) - cam_x, float(e.y) - (0.0 if e.kind == "saucer" or e.flying else size.y / 2)), e.kind, pts)


func _hit_store(e: Dictionary) -> void:
	store_left -= 1
	store_hit.emit(Vector2(float(e.x) - cam_x, float(e.y) - 35.0), store_left)
	if store_left <= 0:
		_kill(e)
		state = State.COMPLETE
		timer = 4.0
		_add_points(2000 * mission)
		mission_complete.emit(mission)


func _move_enemies(dt: float) -> void:
	var wx := cam_x + ship.x
	for e in enemies:
		if not e.alive:
			continue
		var on_screen: bool = e.x > cam_x - 60.0 and e.x < cam_x + W + 60.0
		if not on_screen:
			continue
		e.phase += dt
		match e.kind:
			"missile":
				if not e.flying:
					var dx: float = e.x - wx
					if dx < 260.0 + (mission - 1) * 30.0 and dx > -40.0 and fmod(float(e.phase) * 7.3, 1.0) < 0.02 + mission * 0.004:
						e.flying = true
						e.vy = -60.0
						missile_launched.emit(Vector2(float(e.x) - cam_x, e.y))
				else:
					e.vy -= 260.0 * dt
					e.y += e.vy * dt
					if e.y < ceil_at(e.x) + 4.0 or e.y < TOP:
						e.alive = false
			"saucer":
				e.x -= 50.0 * dt
				e.y = float(e.base_y) + sin(float(e.phase) * 2.2) * 50.0
				var lo := ceil_at(e.x) + 14.0
				var hi := floor_at(e.x) - 14.0
				e.y = clampf(e.y, lo, hi)
		# colisão com a nave
		if _hits(e, Vector2(wx, ship.y), 14.0) and absf(float(e.x) - wx) < enemy_size(e.kind).x / 2 + SHIP_SIZE.x / 2 - 6.0:
			if e.kind == "store":
				continue
			_kill(e)
			_die()
			return


func _die() -> void:
	if state != State.PLAY:
		return
	state = State.DYING
	timer = 2.0
	player_died.emit(ship)


# ---------------------------------------------------------------- entrada

func _unhandled_input(event: InputEvent) -> void:
	if paused or is_ai():
		return
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	# Tátil: metade esquerda = arrastar para mover a nave (como um rato relativo);
	# metade direita: em cima dispara (manter), em baixo larga bombas.
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < 640.0:
				_touch_move = event.position
				_touch_ship = ship
				_touch_index = event.index
			elif event.position.y < 400.0:
				_touch_fire = event.index
			else:
				_touch_bomb_pending = true
		else:
			if event.index == _touch_index:
				_touch_move = null
				_touch_index = -1
			if event.index == _touch_fire:
				_touch_fire = -1
	elif event is InputEventScreenDrag and event.index == _touch_index and _touch_move != null:
		_touch_ship += event.relative * 1.3
		_touch_ship.x = clampf(_touch_ship.x, 40.0, 700.0)
		_touch_ship.y = clampf(_touch_ship.y, TOP + 12.0, BOTTOM - 10.0)


func clear_input() -> void:
	_touch_move = null
	_touch_index = -1
	_touch_fire = -1
	_touch_bomb_pending = false


# ---------------------------------------------------------------- CPU da demonstração

func _ai_think() -> void:
	var wx := cam_x + ship.x
	# meio da passagem um pouco à frente
	var lo := TOP
	var hi := BOTTOM
	for k in 12:
		var x := wx + k * 18.0
		lo = maxf(lo, ceil_at(x))
		hi = minf(hi, floor_at(x))
	var target := Vector2(220.0, (lo + hi) / 2.0)
	if hi - lo > 260.0:
		target.y = hi - 110.0          # perto do chão para bombardear
	# fugir de mísseis no ar
	for e in enemies:
		if e.alive and e.flying and absf(float(e.x) - wx) < 90.0 and float(e.y) > ship.y:
			target.x = ship.x - 80.0 if float(e.x) > wx else ship.x + 80.0
	var d := (target - ship) / 30.0
	ai.dir = d.limit_length(1.0)
	ai.fire = true
	ai.bomb = false
	for e in enemies:
		if not e.alive or e.kind == "saucer" or e.flying:
			continue
		var dx: float = e.x - wx
		if dx < -40.0 or dx > 1100.0:
			continue
		var h: float = float(e.y) - 10.0 - ship.y
		if h <= 0.0:
			continue
		var t := (-40.0 + sqrt(1600.0 + 4.0 * 210.0 * h)) / 420.0
		var disp := (scroll_speed + 70.0) * t - 20.0 * t * t
		if e.kind == "store":
			# o depósito: alinhar a nave para o bombardear
			target = Vector2(clampf(float(e.x) - cam_x - disp, 60.0, 650.0), clampf(float(e.y) - 170.0, lo + 30.0, hi - 40.0))
			ai.dir = ((target - ship) / 30.0).limit_length(1.0)
		if absf(dx - disp) < 14.0:
			ai.bomb = true
