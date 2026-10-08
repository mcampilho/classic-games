class_name JetpacGame
extends Node2D
## Lógica do Jetpac (1983): um astronauta com mochila-foguete monta o foguete (3 peças),
## abastece-o com 6 cápsulas de combustível e descola para o planeta seguinte, enquanto
## enfrenta vagas de alienígenas com o laser. O ecrã dá a volta nas laterais.
## Unidades: campo de 320 x 180 (x4 = 1280 x 720).

signal match_started
signal level_started(level: int)
signal fired(pos: Vector2, dir: int)
signal alien_killed(pos: Vector2, kind: String, points: int)
signal alien_crashed(pos: Vector2)
signal picked(kind: String, pos: Vector2)
signal dropped(kind: String)
signal part_placed(stage: int)
signal fuel_added(level: int)
signal player_died(pos: Vector2)
signal takeoff
signal extra_life
signal game_over

enum Mode { DEMO, PLAY }
enum State { READY, PLAY, DYING, TAKEOFF, LANDING, OVER }

const FIELD := Vector2(320, 180)
const SCALE := 4.0
const HUD_H := 14.0
const GROUND_Y := 172.0
const PLATFORMS := [Rect2(32, 74, 56, 6), Rect2(120, 98, 32, 6), Rect2(204, 54, 64, 6)]
const ROCKET_X := 176.0
const PLAYER_SIZE := Vector2(10, 16)
const GRAVITY := 70.0
const THRUST := 170.0
const MAX_VY := 60.0
const FLY_VX := 72.0
const WALK_VX := 40.0
const LASER_SPEED := 420.0
const LASER_LEN := 90.0
const FUEL_NEEDED := 6
const ALIEN_KINDS := ["meteor", "fuzz", "bubble", "jet", "cross", "saucer", "hopper", "blob"]
const ALIEN_POINTS := {"meteor": 25, "fuzz": 80, "bubble": 40, "jet": 55, "cross": 50, "saucer": 60, "hopper": 45, "blob": 70}
const EXTRA_LIFE_EVERY := 10000

var mode := Mode.DEMO
var state := State.READY
var paused := false
var skin: JetpacSkin
var best := 0

var score := 0
var lives := 4
var level := 1
var next_extra := EXTRA_LIFE_EVERY
var timer := 0.0
var pos := Vector2(100, GROUND_Y)    # pés do astronauta
var vel := Vector2.ZERO
var facing := 1
var flying := false
var grounded := true
var anim := 0.0
var rocket_stage := 3                # 1..3 peças montadas
var fuel := 0
var rocket_y := 0.0                  # deslocamento do foguete (descolagem/aterragem)
var items: Array[Dictionary] = []    # kind (part2, part3, fuel, gem), pos, vy, held, settled, gem
var aliens: Array[Dictionary] = []   # kind, pos, vel, phase
var lasers: Array[Dictionary] = []   # y, x0, len, dir, life, hue
var carrying := -1                   # índice em items
var _laser_cool := 0.0
var _spawn_t := 0.0
var _item_t := 0.0
var _gem_t := 8.0
var _touch_index := -1
var _touch_origin := Vector2.ZERO
var _touch_dir := Vector2.ZERO
var _touch_fire := -1
var ai := {"x": 0.0, "up": false, "fire": false}


func _init() -> void:
	_ensure_inputs()


static func _ensure_inputs() -> void:
	var defs := {
		"jp_left": [_key(KEY_A), _key(KEY_LEFT), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"jp_right": [_key(KEY_D), _key(KEY_RIGHT), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)],
		"jp_up": [_key(KEY_W), _key(KEY_UP), _joy_button(JOY_BUTTON_DPAD_UP), _joy_button(JOY_BUTTON_B), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)],
		"jp_fire": [_key(KEY_SPACE), _key(KEY_J), _key(KEY_Z), _key(KEY_CTRL), _joy_button(JOY_BUTTON_A), _joy_button(JOY_BUTTON_X)],
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


func set_skin(new_skin: JetpacSkin) -> void:
	if skin:
		skin.queue_free()
	skin = new_skin
	add_child(skin)
	skin.attach(self)


func is_ai() -> bool:
	return mode == Mode.DEMO


func to_px(u: Vector2) -> Vector2:
	return u * SCALE


func alien_kind() -> String:
	return ALIEN_KINDS[(level - 1) % ALIEN_KINDS.size()]


## Modelo do foguete (muda a cada 4 níveis).
func rocket_model() -> int:
	return ((level - 1) / 4) % 4


func rocket_ready() -> bool:
	return rocket_stage >= 3 and fuel >= FUEL_NEEDED


func surfaces() -> Array:
	var out: Array = PLATFORMS.duplicate()
	out.append(Rect2(-20, GROUND_Y, FIELD.x + 40, 8))
	return out


# ---------------------------------------------------------------- partida

func start(p_mode: Mode, p_lives := 4) -> void:
	mode = p_mode
	paused = false
	score = 0
	lives = p_lives
	level = 1
	next_extra = EXTRA_LIFE_EVERY
	match_started.emit()
	_begin_level(true)


func _begin_level(new_rocket: bool) -> void:
	items.clear()
	aliens.clear()
	lasers.clear()
	carrying = -1
	fuel = 0
	if new_rocket:
		rocket_stage = 1
		# as duas peças que faltam ficam nas plataformas
		items.append({"kind": "part2", "pos": Vector2(PLATFORMS[1].get_center().x, PLATFORMS[1].position.y), "vy": 0.0, "settled": true})
		items.append({"kind": "part3", "pos": Vector2(PLATFORMS[0].get_center().x, PLATFORMS[0].position.y), "vy": 0.0, "settled": true})
	else:
		rocket_stage = 3
	rocket_y = 0.0
	_item_t = 2.0
	_spawn_t = 1.0
	_gem_t = randf_range(8.0, 15.0)
	_respawn()
	level_started.emit(level)


func _respawn() -> void:
	pos = Vector2(ROCKET_X - 60.0, GROUND_Y)
	vel = Vector2.ZERO
	flying = false
	grounded = true
	facing = 1
	if carrying >= 0:
		items[carrying].held = false
		carrying = -1
	aliens.clear()
	lasers.clear()
	state = State.READY
	timer = 1.4 if mode == Mode.PLAY else 0.5


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
	anim += dt
	match state:
		State.READY:
			timer -= dt
			if timer <= 0.0:
				state = State.PLAY
		State.PLAY:
			_move_player(dt)
			_move_lasers(dt)
			_move_items(dt)
			_move_aliens(dt)
			_spawn(dt)
		State.DYING:
			timer -= dt
			_move_lasers(dt)
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
		State.TAKEOFF:
			timer -= dt
			rocket_y -= (40.0 + (2.5 - timer) * 60.0) * dt
			if timer <= 0.0:
				level += 1
				_add_points(1000)
				state = State.LANDING
				timer = 2.0
				rocket_y = -200.0
				var new_rocket := (level - 1) % 4 == 0
				_begin_level(new_rocket)
				if not new_rocket:
					state = State.LANDING
					timer = 2.0
					rocket_y = -200.0
		State.LANDING:
			timer -= dt
			rocket_y = minf(rocket_y + 110.0 * dt, 0.0)
			if timer <= 0.0 and rocket_y >= 0.0:
				state = State.PLAY
		State.OVER:
			if mode == Mode.DEMO:
				timer -= dt
				if timer <= 0.0:
					start(Mode.DEMO, 3)


# ---------------------------------------------------------------- astronauta

func _controls() -> Dictionary:
	if is_ai():
		return {"x": ai.x, "up": ai.up, "fire": ai.fire}
	var x := Input.get_axis("jp_left", "jp_right")
	var up := Input.is_action_pressed("jp_up")
	if _touch_index >= 0:
		if absf(_touch_dir.x) > 18.0:
			x = clampf(_touch_dir.x / 50.0, -1.0, 1.0)
		up = up or _touch_dir.y < -18.0
	return {"x": x, "up": up, "fire": Input.is_action_pressed("jp_fire") or _touch_fire >= 0}


func player_rect() -> Rect2:
	return Rect2(pos.x - PLAYER_SIZE.x / 2, pos.y - PLAYER_SIZE.y, PLAYER_SIZE.x, PLAYER_SIZE.y)


func _move_player(dt: float) -> void:
	var c := _controls()
	var cx: float = c.x
	if absf(cx) > 0.1:
		facing = 1 if cx > 0.0 else -1
	flying = c.up or not grounded
	var target_vx := cx * (FLY_VX if flying else WALK_VX)
	vel.x = move_toward(vel.x, target_vx, (240.0 if flying else 600.0) * dt)
	if c.up:
		vel.y -= THRUST * dt
	vel.y = clampf(vel.y + GRAVITY * dt, -MAX_VY, MAX_VY)
	# horizontal (com a volta ao ecrã)
	pos.x = fposmod(pos.x + vel.x * dt, FIELD.x)
	var r := player_rect()
	for s: Rect2 in PLATFORMS:
		if r.intersects(s) and r.end.y > s.position.y + 2.0 and r.position.y < s.end.y - 1.0:
			if vel.x > 0.0:
				pos.x = s.position.x - PLAYER_SIZE.x / 2 - 0.01
			elif vel.x < 0.0:
				pos.x = s.end.x + PLAYER_SIZE.x / 2 + 0.01
			vel.x = 0.0
			r = player_rect()
	# vertical
	var was_y := pos.y
	pos.y += vel.y * dt
	grounded = false
	r = player_rect()
	for s: Rect2 in surfaces():
		if r.position.x + 1.0 < s.end.x and r.end.x - 1.0 > s.position.x:
			if vel.y >= 0.0 and was_y <= s.position.y + 0.01 and pos.y >= s.position.y:
				pos.y = s.position.y
				vel.y = 0.0
				grounded = true
			elif vel.y < 0.0 and was_y - PLAYER_SIZE.y >= s.end.y - 0.01 and pos.y - PLAYER_SIZE.y < s.end.y:
				pos.y = s.end.y + PLAYER_SIZE.y
				vel.y = 0.0
	if pos.y - PLAYER_SIZE.y < HUD_H:
		pos.y = HUD_H + PLAYER_SIZE.y
		vel.y = maxf(vel.y, 0.0)
	if grounded and absf(vel.x) > 1.0:
		anim += dt
	_laser_cool -= dt
	if c.fire and _laser_cool <= 0.0 and lasers.size() < 4:
		_laser_cool = 0.22
		var gun := Vector2(pos.x + facing * 6.0, pos.y - 10.0)
		lasers.append({"y": gun.y, "x0": gun.x, "len": 0.0, "dir": facing, "life": 0.45, "hue": randf()})
		fired.emit(gun, facing)
	_pickups()


func _pickups() -> void:
	var r := player_rect().grow(2.0)
	# entregar no foguete: largar quando estiver por cima
	if carrying >= 0:
		var it: Dictionary = items[carrying]
		it.pos = pos + Vector2(0, 2)
		if absf(pos.x - ROCKET_X) < 5.0 and pos.y < rocket_top_y() - 4.0:
			it.held = false
			it.settled = false
			it.pos.x = ROCKET_X
			it.dropping = true
			carrying = -1
			dropped.emit(it.kind)
		return
	for i in items.size():
		var it: Dictionary = items[i]
		if it.get("held", false) or it.get("dropping", false):
			continue
		var ir := Rect2(it.pos - Vector2(6, 10), Vector2(12, 10))
		if r.intersects(ir):
			if it.kind == "gem":
				_add_points(250)
				picked.emit("gem", it.pos)
				items.remove_at(i)
				return
			if needed(it.kind):
				it.held = true
				carrying = i
				_add_points(100)
				picked.emit(it.kind, it.pos)
				return
	# entrar no foguete pronto
	if rocket_ready() and absf(pos.x - ROCKET_X) < 10.0 and pos.y > GROUND_Y - 30.0:
		state = State.TAKEOFF
		timer = 2.5
		takeoff.emit()


func needed(kind: String) -> bool:
	match kind:
		"part2":
			return rocket_stage == 1
		"part3":
			return rocket_stage == 2
		"fuel":
			return rocket_stage >= 3 and fuel < FUEL_NEEDED
	return false


## Altura (topo) do foguete montado até agora.
func rocket_top_y() -> float:
	return GROUND_Y - rocket_stage * 16.0


# ---------------------------------------------------------------- objetos

func _move_items(dt: float) -> void:
	for i in range(items.size() - 1, -1, -1):
		var it: Dictionary = items[i]
		if it.get("held", false):
			continue
		if it.get("dropping", false):
			it.pos.y += 60.0 * dt
			if it.pos.y >= rocket_top_y():
				items.remove_at(i)
				if carrying > i:
					carrying -= 1
				if it.kind == "fuel":
					fuel += 1
					fuel_added.emit(fuel)
				else:
					rocket_stage += 1
					part_placed.emit(rocket_stage)
			continue
		if it.settled:
			continue
		it.pos.y += 40.0 * dt
		for s: Rect2 in surfaces():
			if it.pos.x > s.position.x and it.pos.x < s.end.x and it.pos.y >= s.position.y and it.pos.y - 40.0 * dt <= s.position.y + 0.5:
				it.pos.y = s.position.y
				it.settled = true


func _spawn(dt: float) -> void:
	# combustível (um de cada vez) quando o foguete está montado
	if rocket_stage >= 3 and fuel < FUEL_NEEDED:
		var has_fuel := false
		for it in items:
			if it.kind == "fuel":
				has_fuel = true
		if not has_fuel:
			_item_t -= dt
			if _item_t <= 0.0:
				_item_t = 1.5
				items.append({"kind": "fuel", "pos": Vector2(randf_range(20.0, FIELD.x - 20.0), HUD_H + 4.0), "vy": 0.0, "settled": false})
	_gem_t -= dt
	if _gem_t <= 0.0:
		_gem_t = randf_range(12.0, 22.0)
		var has_gem := false
		for it in items:
			if it.kind == "gem":
				has_gem = true
		if not has_gem:
			items.append({"kind": "gem", "pos": Vector2(randf_range(20.0, FIELD.x - 20.0), HUD_H + 4.0), "vy": 0.0, "settled": false, "gem": randi() % 4})
	# alienígenas
	var want := mini(3 + level / 2, 7)
	_spawn_t -= dt
	if aliens.size() < want and _spawn_t <= 0.0:
		_spawn_t = randf_range(0.4, 1.0)
		var left := randf() < 0.5
		var k := alien_kind()
		var y := randf_range(HUD_H + 10.0, GROUND_Y - 20.0)
		var speed := 34.0 + level * 2.0
		var v := Vector2((1.0 if left else -1.0) * speed, 0.0)
		match k:
			"meteor":
				v.y = randf_range(10.0, 30.0)
			"fuzz", "bubble":
				v.y = randf_range(-1.0, 1.0) * speed * 0.8
			"hopper":
				v.y = -40.0
		aliens.append({"kind": k, "pos": Vector2(-8.0 if left else FIELD.x + 8.0, y), "vel": v, "phase": randf() * TAU, "age": 0.0})


func _move_aliens(dt: float) -> void:
	var pr := player_rect()
	var target := pos - Vector2(0, 8)
	for i in range(aliens.size() - 1, -1, -1):
		var a: Dictionary = aliens[i]
		a.phase += dt
		a.age += dt
		var p: Vector2 = a.pos
		var v: Vector2 = a.vel
		match a.kind:
			"cross", "saucer", "blob":
				var acc := 60.0 if a.kind == "cross" else (35.0 if a.kind == "saucer" else 20.0)
				var d := _wrap_delta(p, target)
				v += d.normalized() * acc * dt
				v = v.limit_length(44.0 + level * 1.5)
				if a.kind == "blob":
					v.y += sin(float(a.phase) * 4.0) * 30.0 * dt
			"jet":
				if a.age > 1.2 and absf(v.y) < 1.0:
					v.y = signf(target.y - p.y) * 30.0
			"hopper":
				v.y += 60.0 * dt
		var np := p + v * dt
		np.x = fposmod(np.x + 8.0, FIELD.x + 16.0) - 8.0 if a.age > 0.5 else np.x
		# superfícies
		var hit := false
		for s: Rect2 in surfaces():
			if s.grow(4.0).has_point(np):
				hit = true
				if a.kind == "meteor":
					break
				var from_above := p.y < s.position.y - 3.0
				var from_below := p.y > s.end.y + 3.0
				if from_above or from_below:
					v.y = -v.y
					if a.kind == "hopper" and from_above:
						v.y = -55.0
				else:
					v.x = -v.x
				np = p + v * dt
				break
		if np.y < HUD_H + 4.0:
			v.y = absf(v.y)
			np.y = HUD_H + 4.0
		if hit and a.kind == "meteor":
			aliens.remove_at(i)
			alien_crashed.emit(np)
			continue
		a.pos = np
		a.vel = v
		if pr.grow(-1.0).intersects(Rect2(np - Vector2(5, 4), Vector2(10, 8))):
			aliens.remove_at(i)
			_die()
			return


func _wrap_delta(a: Vector2, b: Vector2) -> Vector2:
	var dx := b.x - a.x
	if dx > FIELD.x / 2:
		dx -= FIELD.x
	elif dx < -FIELD.x / 2:
		dx += FIELD.x
	return Vector2(dx, b.y - a.y)


func _move_lasers(dt: float) -> void:
	for l in lasers:
		l.len = minf(l.len + LASER_SPEED * dt, LASER_LEN)
		l.life -= dt
	lasers = lasers.filter(func(l: Dictionary) -> bool: return l.life > 0.0)
	for l in lasers:
		var x0: float = l.x0
		var x1: float = x0 + l.dir * l.len
		var lo := minf(x0, x1)
		var hi := maxf(x0, x1)
		for i in range(aliens.size() - 1, -1, -1):
			var a: Dictionary = aliens[i]
			var ax := fposmod(float(a.pos.x) - lo, FIELD.x) + lo
			if absf(float(a.pos.y) - float(l.y)) < 5.0 and ax >= lo - 4.0 and ax <= hi + 4.0:
				var pts: int = ALIEN_POINTS[a.kind]
				_add_points(pts)
				alien_killed.emit(a.pos, a.kind, pts)
				aliens.remove_at(i)


func _die() -> void:
	if state != State.PLAY:
		return
	state = State.DYING
	timer = 1.8
	player_died.emit(pos - Vector2(0, 8))


# ---------------------------------------------------------------- entrada

func _unhandled_input(event: InputEvent) -> void:
	if paused or is_ai():
		return
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	# Tátil: metade esquerda = joystick (para cima = propulsor), metade direita = disparar.
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < 640.0:
				_touch_index = event.index
				_touch_origin = event.position
				_touch_dir = Vector2.ZERO
			else:
				_touch_fire = event.index
		else:
			if event.index == _touch_index:
				_touch_index = -1
				_touch_dir = Vector2.ZERO
			if event.index == _touch_fire:
				_touch_fire = -1
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_touch_dir = event.position - _touch_origin


func clear_input() -> void:
	_touch_index = -1
	_touch_fire = -1
	_touch_dir = Vector2.ZERO


func touch_stick() -> Variant:
	return _touch_origin if _touch_index >= 0 else null


# ---------------------------------------------------------------- CPU da demonstração

func _ai_think() -> void:
	var goal := Vector2(ROCKET_X, 30.0)
	if carrying >= 0:
		goal = Vector2(ROCKET_X, rocket_top_y() - 24.0)
	else:
		var best_d := INF
		for it in items:
			if it.get("dropping", false) or it.get("held", false):
				continue
			if it.kind == "gem" or needed(it.kind):
				var d := absf(_wrap_delta(pos, it.pos).x) + absf(float(it.pos.y) - pos.y)
				if d < best_d:
					best_d = d
					goal = it.pos
		if rocket_ready():
			goal = Vector2(ROCKET_X, GROUND_Y)
	var d := _wrap_delta(pos, goal)
	# voar alto para atravessar e descer a direito por cima do objetivo
	var cruise := 30.0
	var want_y := goal.y if absf(d.x) < 8.0 else minf(cruise, goal.y)
	if absf(d.x) < 8.0 and _blocked_below(goal):
		want_y = goal.y
	ai.x = clampf(d.x / 12.0, -1.0, 1.0)
	ai.up = pos.y > want_y + 2.0 or (vel.y > 20.0 and pos.y > want_y - 6.0)
	# por baixo de uma plataforma que tapa o caminho para cima: sair pela borda mais próxima
	for s: Rect2 in PLATFORMS:
		var head := pos.y - PLAYER_SIZE.y
		if want_y < pos.y - 4.0 and pos.x > s.position.x - 7.0 and pos.x < s.end.x + 7.0 and s.end.y <= head + 2.0 and s.position.y > want_y - 20.0:
			var left_edge := s.position.x - 10.0
			var right_edge := s.end.x + 10.0
			var gx := left_edge if absf(pos.x - left_edge) < absf(pos.x - right_edge) else right_edge
			ai.x = clampf((gx - pos.x) / 6.0, -1.0, 1.0)
			ai.up = head > s.end.y + 6.0 and vel.y > 0.0
			break
	# disparar contra o alienígena mais próximo à mesma altura
	ai.fire = false
	for a in aliens:
		var ad := _wrap_delta(pos, a.pos)
		if absf(ad.y + 8.0) < 10.0 and absf(ad.x) < 100.0:
			if signf(ad.x) != facing and absf(ad.x) > 6.0:
				ai.x = signf(ad.x) * 0.3
			ai.fire = true
		# fugir se estiver muito perto
		if ad.length() < 22.0:
			ai.up = ad.y > -8.0


func _blocked_below(goal: Vector2) -> bool:
	for s: Rect2 in PLATFORMS:
		if goal.x > s.position.x - 6.0 and goal.x < s.end.x + 6.0 and s.position.y > pos.y and s.position.y < goal.y:
			return true
	return false
