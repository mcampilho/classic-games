class_name PalaceGame
extends Node2D
## Fuga do Palácio — plataformas "cinemático" original ao estilo de 1989: o herói corre, trava,
## salta a correr, agarra-se a beirais, sobe e desce, evita espinhos e chãos soltos, abre portões
## com placas de pressão e luta à espada com os guardas — tudo contra o relógio (20 minutos).
## As personagens são esqueletos animados por poses (animação suave, sem folhas de sprites).
## Coordenadas em píxeis do nível: casas de 128 de largura e linhas de 210 de altura;
## cada ecrã mostra 10 casas x 3 linhas.

signal match_started
signal level_started(level: int)
signal room_changed(room: Vector2i)
signal step
signal jumped
signal landed(hard: bool)
signal grabbed
signal bumped
signal picked(kind: String)
signal gate_opened
signal exit_opened
signal loose_fell(cell: Vector2i)
signal spikes_out(cell: Vector2i)
signal sword_clash
signal sword_hit(who: String)
signal guard_died
signal player_died(how: String)
signal level_done
signal won
signal game_over

enum Mode { DEMO, PLAY }
enum State { READY, PLAY, DYING, EXIT, WON, OVER }
enum Act { STAND, RUN, STOP, TURN, STEP, CROUCH, JUMP, RJUMP, JUMPUP, HANG, CLIMB, FALL, LAND, SWORD, STRIKE, PARRY, DEAD, EXIT }

const TW := 128.0
const RH := 210.0
const ROOM_COLS := 10
const ROOM_ROWS := 3
const RUN_V := 280.0
const ACCEL := 1500.0
const GRAVITY := 1150.0
const TIME_LIMIT := 20.0 * 60.0
const GATE_TIME := 12.0
const FLOOR := "_|^~oeDhHSgP"
const HALF := 18.0

## Níveis originais: _ chão, # parede, espaço = buraco, | portão, ^ espinhos, ~ chão solto,
## o placa (abre os portões por 12 s), e placa da saída, D porta de saída, h poção, H poção de vida,
## S espada, g guarda, P início.
const LEVELS := [
	[
		"########################################",
		"_S___   _____~~___h_____________   __e_#",
		"P_________________g____  _^o___|____D__#",
	],
	[
		"_____ ___________________ ___#",
		"P___  ____^^__~~___  ___g____#",
		"___   ___   _____h__  __   __#",
		"_____ ___g______  ___  _____e#",
		"__ ___H______  _o___  ___|_D_#",
		"_____________________________#",
	],
]


var mode := Mode.DEMO
var state := State.READY
var paused := false
var skin: PalaceSkin
var best := 0

var level := 0
var tiles: Array[String] = []
var room := Vector2i.ZERO
var lives := 3
var score := 0
var clock := 0.0
var timer := 0.0

# herói
var pos := Vector2.ZERO           # pés
var vel := Vector2.ZERO
var facing := 1
var act := Act.STAND
var act_t := 0.0                  # tempo no estado atual
var hp := 3
var max_hp := 3
var has_sword := false
var fall_from := 0.0
var hang_edge := Vector2.ZERO     # ponto do beiral (x da aresta, y do chão de cima)
var parry_t := 0.0
var hit_done := false
var anim := 0.0
var start_pos := Vector2.ZERO

# mundo
var guards: Array[Dictionary] = []    # pos, facing, hp, max_hp, act, act_t, cool, hit_done, parry_t, alive, anim
var gate_t := 0.0                     # portões abertos enquanto > 0
var gate_h := 0.0                     # 0 = fechado, 1 = aberto (animação)
var exit_open := false
var exit_h := 0.0
var loose := {}                       # Vector2i -> tempo a tremer
var spikes := {}                      # Vector2i -> 0..1 (saída dos espinhos)
var debris: Array[Dictionary] = []    # pos, vy
var _in := {"x": 0, "up": false, "down": false, "jump": false, "attack": false, "careful": false}
var _jump_buffer := 0.0
var _attack_buffer := 0.0
var _touch_index := -1
var _touch_origin := Vector2.ZERO
var _touch_dir := Vector2.ZERO
var _touch_buttons := {}
var ai := {"x": 0, "up": false, "down": false, "jump": false, "attack": false, "careful": false}
var _ai_t := 0.0


func _init() -> void:
	_ensure_inputs()


static func _ensure_inputs() -> void:
	var defs := {
		"pa_left": [_key(KEY_A), _key(KEY_LEFT), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"pa_right": [_key(KEY_D), _key(KEY_RIGHT), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)],
		"pa_up": [_key(KEY_W), _key(KEY_UP), _joy_button(JOY_BUTTON_DPAD_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)],
		"pa_down": [_key(KEY_S), _key(KEY_DOWN), _joy_button(JOY_BUTTON_DPAD_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)],
		"pa_jump": [_key(KEY_SPACE), _key(KEY_Z), _joy_button(JOY_BUTTON_A)],
		"pa_attack": [_key(KEY_X), _key(KEY_J), _key(KEY_CTRL), _joy_button(JOY_BUTTON_X)],
		"pa_careful": [_key(KEY_SHIFT), _joy_button(JOY_BUTTON_B), _joy_button(JOY_BUTTON_RIGHT_SHOULDER)],
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


func set_skin(new_skin: PalaceSkin) -> void:
	if skin:
		skin.queue_free()
	skin = new_skin
	add_child(skin)
	skin.attach(self)


func is_ai() -> bool:
	return mode == Mode.DEMO


# ---------------------------------------------------------------- casas

func cols() -> int:
	return tiles[0].length()


func rows() -> int:
	return tiles.size()


func tile(c: int, r: int) -> String:
	if r < 0:
		return "#"
	if r >= rows():
		return " "
	if c < 0 or c >= cols():
		return "#"
	return tiles[r][c]


func is_floor(c: int, r: int) -> bool:
	return FLOOR.contains(tile(c, r))


func blocks(c: int, r: int) -> bool:
	var t := tile(c, r)
	return t == "#" or (t == "|" and gate_h < 0.8)


func floor_y(r: int) -> float:
	return (r + 1) * RH - 18.0


func col_of(x: float) -> int:
	return floori(x / TW)


func row_of(y: float) -> int:
	return clampi(floori((y - 1.0) / RH), 0, rows() - 1)


func set_tile(c: int, r: int, ch: String) -> void:
	var row := tiles[r]
	tiles[r] = row.substr(0, c) + ch + row.substr(c + 1)


func room_of(p: Vector2) -> Vector2i:
	return Vector2i(clampi(floori(p.x / (TW * ROOM_COLS)), 0, (cols() - 1) / ROOM_COLS), clampi(floori((p.y - 1.0) / (RH * ROOM_ROWS)), 0, (rows() - 1) / ROOM_ROWS))


func minutes_left() -> int:
	return ceili((TIME_LIMIT - clock) / 60.0)


# ---------------------------------------------------------------- partida e níveis

func start(p_mode: Mode, p_lives := 3) -> void:
	mode = p_mode
	paused = false
	lives = p_lives
	score = 0
	clock = 0.0
	max_hp = 3
	level = 0
	has_sword = false
	match_started.emit()
	_load_level()


func _load_level() -> void:
	tiles.clear()
	for r: String in LEVELS[level]:
		tiles.append(r)
	guards.clear()
	loose.clear()
	spikes.clear()
	debris.clear()
	gate_t = 0.0
	gate_h = 0.0
	exit_open = false
	exit_h = 0.0
	for r in rows():
		for c in cols():
			var t := tiles[r][c]
			match t:
				"P":
					start_pos = Vector2(c * TW + TW / 2, floor_y(r))
				"g":
					var ghp := 3 + level
					guards.append({"pos": Vector2(c * TW + TW / 2, floor_y(r)), "facing": -1, "hp": ghp, "max_hp": ghp, "act": Act.STAND,
						"act_t": 0.0, "cool": 1.0, "hit_done": false, "parry_t": 0.0, "alive": true, "anim": 0.0, "engaged": false})
				"^":
					spikes[Vector2i(c, r)] = 0.0
	_respawn()
	level_started.emit(level)


func _respawn() -> void:
	pos = start_pos
	vel = Vector2.ZERO
	facing = 1
	hp = max_hp
	_set_act(Act.STAND)
	room = room_of(pos)
	state = State.READY
	timer = 1.0 if mode == Mode.PLAY else 0.3
	for g in guards:
		if g.alive:
			g.hp = g.max_hp
	room_changed.emit(room)


func _set_act(a: Act) -> void:
	act = a
	act_t = 0.0
	hit_done = false


# ---------------------------------------------------------------- ciclo

func _process(delta: float) -> void:
	if paused:
		return
	delta = minf(delta, 0.1)
	if is_ai() and state == State.PLAY:
		_ai_think(delta)
	_read_input()
	var steps := maxi(1, ceili(delta * 240.0))
	var dt := delta / steps
	for i in steps:
		_step(dt)


func _read_input() -> void:
	if is_ai():
		_in = ai.duplicate()
		ai.jump = false
		ai.attack = false
		return
	var x := 0
	if Input.is_action_pressed("pa_left"):
		x -= 1
	if Input.is_action_pressed("pa_right"):
		x += 1
	var up := Input.is_action_pressed("pa_up")
	var down := Input.is_action_pressed("pa_down")
	if _touch_index >= 0:
		if absf(_touch_dir.x) > 30.0:
			x = signi(int(_touch_dir.x))
		up = up or _touch_dir.y < -40.0
		down = down or _touch_dir.y > 40.0
	_in = {"x": x, "up": up, "down": down, "jump": _jump_buffer > 0.0, "attack": _attack_buffer > 0.0,
		"careful": Input.is_action_pressed("pa_careful") or _touch_buttons.has("careful")}


func _step(dt: float) -> void:
	_jump_buffer = maxf(_jump_buffer - dt, 0.0)
	_attack_buffer = maxf(_attack_buffer - dt, 0.0)
	anim += dt
	_world(dt)
	match state:
		State.READY:
			timer -= dt
			if timer <= 0.0:
				state = State.PLAY
		State.PLAY:
			clock += dt
			if clock >= TIME_LIMIT:
				state = State.OVER
				timer = 3.0
				game_over.emit()
				return
			_hero(dt)
			for g in guards:
				_guard(g, dt)
			var r := room_of(pos - Vector2(0, 40))
			if r != room:
				room = r
				room_changed.emit(room)
		State.DYING:
			timer -= dt
			act_t += dt
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
		State.EXIT:
			timer -= dt
			act_t += dt
			if timer <= 0.0:
				score += 1000 + minutes_left() * 50
				if level + 1 >= LEVELS.size():
					state = State.WON
					timer = 6.0
					score += lives * 1000
					if mode == Mode.PLAY:
						best = maxi(best, score)
					won.emit()
				else:
					level += 1
					level_done.emit()
					_load_level()
		State.OVER, State.WON:
			if mode == Mode.DEMO:
				timer -= dt
				if timer <= 0.0:
					start(Mode.DEMO, 2)


func _world(dt: float) -> void:
	gate_t = maxf(gate_t - dt, 0.0)
	gate_h = move_toward(gate_h, 1.0 if gate_t > 0.0 else 0.0, dt * (1.5 if gate_t > 0.0 else 0.5))
	exit_h = move_toward(exit_h, 1.0 if exit_open else 0.0, dt * 0.8)
	# espinhos saem quando o herói se aproxima
	var hc := col_of(pos.x)
	var hr := row_of(pos.y)
	for k: Vector2i in spikes:
		var near := k.y == hr and absi(k.x - hc) <= 1
		spikes[k] = move_toward(spikes[k], 1.0 if near else 0.0, dt * (8.0 if near else 1.0))
		if near and spikes[k] > 0.0 and spikes[k] < 0.15:
			spikes_out.emit(k)
	# chão solto
	for k: Vector2i in loose.keys():
		loose[k] += dt
		if loose[k] > 0.55:
			loose.erase(k)
			set_tile(k.x, k.y, " ")
			debris.append({"pos": Vector2(k.x * TW + TW / 2, floor_y(k.y)), "vy": 0.0})
			loose_fell.emit(k)
	for d in debris:
		d.vy += GRAVITY * dt
		var y0: float = d.pos.y
		d.pos.y += d.vy * dt
		var c := col_of(d.pos.x)
		var r := row_of(d.pos.y)
		if d.pos.y >= floor_y(r) and y0 < floor_y(r) and is_floor(c, r):
			d.vy = -1.0
			# cai em cima do herói?
			if state == State.PLAY and absf(pos.x - d.pos.x) < 60.0 and row_of(pos.y) == r:
				_hurt(1, "debris")
	debris = debris.filter(func(d: Dictionary) -> bool: return d.vy >= 0.0 and d.pos.y < rows() * RH + 100.0)


# ---------------------------------------------------------------- herói

func _hero(dt: float) -> void:
	act_t += dt
	parry_t = maxf(parry_t - dt, 0.0)
	var x: int = _in.x
	var on_ground := act in [Act.STAND, Act.RUN, Act.STOP, Act.TURN, Act.STEP, Act.CROUCH, Act.LAND, Act.SWORD, Act.STRIKE, Act.PARRY]
	if on_ground and not _supported(pos.x):
		fall_from = pos.y
		vel = Vector2(vel.x * 0.5, 0.0)
		_set_act(Act.FALL)
	# luta: entra em guarda quando há um guarda perto
	var foe: Variant = _nearest_guard()
	match act:
		Act.STAND:
			vel.x = 0.0
			if foe != null and has_sword:
				_set_act(Act.SWORD)
				facing = signi(int(foe.pos.x - pos.x)) if foe.pos.x != pos.x else facing
				return
			if _in.jump:
				_jump_buffer = 0.0
				_start_jump(false)
			elif _in.up:
				_try_door_or_jumpup()
			elif _in.down:
				if not _try_climb_down():
					_set_act(Act.CROUCH)
			elif x != 0:
				if x != facing:
					facing = x
					_set_act(Act.TURN)
				elif _in.careful:
					_set_act(Act.STEP)
				else:
					_set_act(Act.RUN)
		Act.TURN:
			if act_t > 0.18:
				_set_act((Act.STEP if _in.careful else Act.RUN) if x == facing else Act.STAND)
		Act.STEP:
			# passo cuidadoso: meia casa, devagar, não cai nem é apanhado pelos espinhos
			var spd := 70.0
			var nx := pos.x + facing * spd * dt
			if not _supported(nx + facing * 8.0) or _wall_ahead(nx):
				_set_act(Act.STAND)
			else:
				pos.x = nx
			if act_t > 0.7:
				_set_act(Act.STAND)
		Act.RUN:
			if x == facing:
				vel.x = move_toward(vel.x, facing * RUN_V, ACCEL * dt)
			else:
				_set_act(Act.STOP)
			if _in.jump:
				_jump_buffer = 0.0
				_start_jump(absf(vel.x) > RUN_V * 0.6)
				return
			_move_x(dt)
			if int(anim * 3.6) != int((anim - dt) * 3.6):
				step.emit()
			_check_spikes(true)
		Act.STOP:
			vel.x = move_toward(vel.x, 0.0, ACCEL * 1.2 * dt)
			_move_x(dt)
			if absf(vel.x) < 5.0:
				_set_act(Act.STAND)
				if x != 0 and x != facing:
					facing = x
					_set_act(Act.TURN)
		Act.CROUCH:
			if not _in.down:
				_set_act(Act.STAND)
		Act.LAND:
			vel.x = move_toward(vel.x, 0.0, ACCEL * dt)
			_move_x(dt)
			if act_t > 0.32:
				_set_act(Act.STAND)
		Act.JUMP, Act.RJUMP, Act.FALL:
			_air(dt)
		Act.JUMPUP:
			# subida até ao beiral (ou um pulinho, se não houver onde agarrar)
			if hang_edge != Vector2.ZERO:
				var k := clampf(act_t / 0.32, 0.0, 1.0)
				pos.y = lerpf(fall_from, hang_edge.y + 200.0, k)
				if k >= 1.0:
					_set_act(Act.HANG)
					grabbed.emit()
			else:
				pos.y = fall_from - sin(clampf(act_t / 0.4, 0.0, 1.0) * PI) * 40.0
				if act_t > 0.4:
					pos.y = fall_from
					_set_act(Act.STAND)
		Act.HANG:
			pos = Vector2(hang_edge.x - facing * 26.0, hang_edge.y + 200.0)
			if _in.up and act_t > 0.15:
				_set_act(Act.CLIMB)
			elif _in.down and act_t > 0.15:
				fall_from = hang_edge.y
				vel = Vector2.ZERO
				pos.x = hang_edge.x - facing * 30.0
				_set_act(Act.FALL)
		Act.CLIMB:
			var k := clampf(act_t / 0.6, 0.0, 1.0)
			pos = Vector2(hang_edge.x - facing * 26.0, hang_edge.y + 200.0).lerp(Vector2(hang_edge.x + facing * 34.0, hang_edge.y), k)
			if k >= 1.0:
				pos = Vector2(hang_edge.x + facing * 34.0, hang_edge.y)
				_set_act(Act.STAND)
		Act.SWORD, Act.STRIKE, Act.PARRY:
			_fight(dt, foe, x)
	if act in [Act.STAND, Act.RUN, Act.STOP, Act.STEP, Act.LAND, Act.SWORD]:
		_floor_effects()


func _supported(x: float) -> bool:
	var r := row_of(pos.y)
	if absf(pos.y - floor_y(r)) > 2.0:
		return false
	return is_floor(col_of(x), r)


func _wall_ahead(nx: float) -> bool:
	var r := row_of(pos.y)
	return blocks(col_of(nx + facing * HALF), r)


func _move_x(dt: float) -> void:
	var nx := pos.x + vel.x * dt
	var r := row_of(pos.y)
	var edge_c := col_of(nx + signf(vel.x) * HALF)
	if vel.x != 0.0 and blocks(edge_c, r):
		# bater na parede
		pos.x = (edge_c * TW - HALF - 0.1) if vel.x > 0.0 else ((edge_c + 1) * TW + HALF + 0.1)
		if absf(vel.x) > RUN_V * 0.7:
			bumped.emit()
		vel.x = 0.0
		if act == Act.RUN:
			_set_act(Act.STAND)
		return
	pos.x = nx


func _start_jump(running: bool) -> void:
	fall_from = pos.y
	if running:
		vel = Vector2(facing * 390.0, -380.0)
		_set_act(Act.RJUMP)
	else:
		vel = Vector2(facing * 215.0, -330.0)
		_set_act(Act.JUMP)
	jumped.emit()


func _air(dt: float) -> void:
	var y0 := pos.y
	vel.y = minf(vel.y + GRAVITY * dt, 900.0)
	pos.y += vel.y * dt
	_move_x(dt)
	if vel.y < 0.0:
		fall_from = minf(fall_from, pos.y)
	var c := col_of(pos.x)
	# agarrar um beiral a cair (com ↑ ou cuidado premido)
	if vel.y > 0.0 and (_in.up or _in.careful):
		var hands0 := y0 - 200.0
		var hands1 := pos.y - 200.0
		for d: int in [facing, -facing]:
			var r := row_of(hands1 + 2.0)
			var fy := floor_y(r)
			var edge_x := (c + (1 if d > 0 else 0)) * TW
			if hands0 <= fy and hands1 >= fy and is_floor(c + d, r) and not is_floor(c, r) and absf(pos.x - edge_x) < 60.0:
				facing = d
				hang_edge = Vector2(edge_x, fy)
				vel = Vector2.ZERO
				_set_act(Act.HANG)
				grabbed.emit()
				return
	# aterrar
	if vel.y > 0.0:
		var r := row_of(pos.y)
		var fy := floor_y(r)
		if y0 <= fy and pos.y >= fy and is_floor(c, r):
			pos.y = fy
			var rows_fallen := roundi((fy - fall_from) / RH)
			vel.y = 0.0
			if rows_fallen >= 3:
				_die("fall")
				return
			_set_act(Act.LAND)
			if rows_fallen == 2:
				landed.emit(true)
				_hurt(1, "fall")
			else:
				landed.emit(false)
			vel.x *= 0.4
			_check_spikes(false, true)
			return
	if pos.y > rows() * RH + 60.0:
		_die("pit")


func _try_door_or_jumpup() -> void:
	var c := col_of(pos.x)
	var r := row_of(pos.y)
	if tile(c, r) == "D" and exit_h > 0.9:
		state = State.EXIT
		timer = 2.0
		_set_act(Act.EXIT)
		return
	# beiral por cima, à frente ou atrás
	hang_edge = Vector2.ZERO
	fall_from = pos.y
	if not is_floor(c, r - 1):
		for d: int in [facing, -facing]:
			var edge_x := (c + (1 if d > 0 else 0)) * TW
			if is_floor(c + d, r - 1) and absf(pos.x - edge_x) < 70.0:
				facing = d
				hang_edge = Vector2(edge_x, floor_y(r - 1))
				break
	_set_act(Act.JUMPUP)


func _try_climb_down() -> bool:
	var c := col_of(pos.x)
	var r := row_of(pos.y)
	for d: int in [facing, -facing]:
		var edge_x := (c + (1 if d > 0 else 0)) * TW
		if not is_floor(c + d, r) and not blocks(c + d, r) and absf(pos.x - edge_x) < 60.0 and r + 1 < rows():
			# vira-se para o chão e pendura-se no beiral
			facing = -d
			hang_edge = Vector2(edge_x, floor_y(r))
			_set_act(Act.HANG)
			act_t = 0.0
			grabbed.emit()
			return true
	return false


func _check_spikes(running: bool, landing := false) -> void:
	var k := Vector2i(col_of(pos.x), row_of(pos.y))
	if spikes.has(k) and (landing or (running and absf(vel.x) > 150.0)):
		_die("spikes")


func _floor_effects() -> void:
	var c := col_of(pos.x)
	var r := row_of(pos.y)
	var k := Vector2i(c, r)
	match tile(c, r):
		"~":
			if not loose.has(k):
				loose[k] = 0.0
		"o":
			if gate_t <= 0.0:
				gate_opened.emit()
			gate_t = GATE_TIME
		"e":
			if not exit_open:
				exit_open = true
				exit_opened.emit()
		"h":
			hp = mini(hp + 1, max_hp)
			set_tile(c, r, "_")
			picked.emit("potion")
		"H":
			max_hp += 1
			hp = max_hp
			set_tile(c, r, "_")
			picked.emit("life")
		"S":
			has_sword = true
			score += 500
			set_tile(c, r, "_")
			picked.emit("sword")


func _hurt(n: int, how: String) -> void:
	hp -= n
	if hp <= 0:
		hp = 0
		_die(how)


func _die(how: String) -> void:
	if state != State.PLAY:
		return
	hp = 0
	state = State.DYING
	timer = 2.4
	_set_act(Act.DEAD)
	player_died.emit(how)


# ---------------------------------------------------------------- espadas

func _nearest_guard() -> Variant:
	var best_g: Variant = null
	var best_d := 3.2 * TW
	for g in guards:
		if not g.alive:
			continue
		if row_of((g.pos as Vector2).y) != row_of(pos.y):
			continue
		var d := absf(float(g.pos.x) - pos.x)
		if d < best_d:
			best_d = d
			best_g = g
	return best_g


func _fight(dt: float, foe: Variant, x: int) -> void:
	if foe == null:
		_set_act(Act.STAND)
		return
	facing = 1 if float(foe.pos.x) > pos.x else -1
	match act:
		Act.SWORD:
			if _in.attack:
				_attack_buffer = 0.0
				_set_act(Act.STRIKE)
				return
			if _in.up:
				_set_act(Act.PARRY)
				parry_t = 0.35
				return
			if x != 0:
				var nx := pos.x + x * 90.0 * dt
				var dist := absf(float(foe.pos.x) - nx)
				if dist > 70.0 and _supported(nx) and not _wall_ahead(nx):
					pos.x = nx
			if _in.jump:
				_jump_buffer = 0.0
				_set_act(Act.STAND)
		Act.STRIKE:
			if act_t > 0.18 and not hit_done:
				hit_done = true
				var d := absf(float(foe.pos.x) - pos.x)
				if d < 150.0:
					if foe.parry_t > 0.0:
						sword_clash.emit()
						foe.act = Act.SWORD
					else:
						foe.hp -= 1
						foe.pos.x += facing * 20.0
						sword_hit.emit("guard")
						if foe.hp <= 0:
							foe.alive = false
							foe.act = Act.DEAD
							foe.act_t = 0.0
							score += 300
							guard_died.emit()
			if act_t > 0.42:
				_set_act(Act.SWORD)
		Act.PARRY:
			if act_t > 0.35:
				_set_act(Act.SWORD)


func _guard(g: Dictionary, dt: float) -> void:
	g.anim += dt
	g.act_t += dt
	g.parry_t = maxf(float(g.parry_t) - dt, 0.0)
	if not g.alive:
		return
	var p: Vector2 = g.pos
	var same_row := row_of(p.y) == row_of(pos.y) and state == State.PLAY and act != Act.DEAD
	var dx := pos.x - p.x
	var dist := absf(dx)
	g.engaged = same_row and dist < 3.4 * TW
	if not g.engaged:
		g.act = Act.STAND
		return
	g.facing = 1 if dx > 0.0 else -1
	g.cool -= dt
	match g.act:
		Act.STAND, Act.SWORD:
			g.act = Act.SWORD
			# aproximar ou afastar
			var want := 110.0
			var mv := 0.0
			if dist > want + 30.0:
				mv = 1.0
			elif dist < want - 30.0:
				mv = -1.0
			var nx: float = p.x + mv * g.facing * 80.0 * dt
			var r := row_of(p.y)
			if is_floor(col_of(nx + g.facing * HALF), r) and not blocks(col_of(nx + g.facing * HALF), r):
				p.x = nx
			# defender quando o herói ataca
			if act == Act.STRIKE and act_t < 0.15 and dist < 170.0 and randf() < (0.012 + level * 0.004) and g.parry_t <= 0.0:
				g.act = Act.PARRY
				g.act_t = 0.0
				g.parry_t = 0.35
			elif g.cool <= 0.0 and dist < 160.0:
				g.cool = randf_range(0.9, 1.7) - level * 0.15
				g.act = Act.STRIKE
				g.act_t = 0.0
				g.hit_done = false
		Act.STRIKE:
			if g.act_t > 0.22 and not g.hit_done:
				g.hit_done = true
				if dist < 150.0:
					if parry_t > 0.0:
						sword_clash.emit()
					else:
						pos.x += g.facing * 24.0
						sword_hit.emit("hero")
						_hurt(1, "sword")
			if g.act_t > 0.5:
				g.act = Act.SWORD
		Act.PARRY:
			if g.act_t > 0.35:
				g.act = Act.SWORD
	g.pos = p


# ---------------------------------------------------------------- entrada

func _unhandled_input(event: InputEvent) -> void:
	if paused or is_ai():
		return
	if event.is_action_pressed("pa_jump"):
		_jump_buffer = 0.15
	if event.is_action_pressed("pa_attack"):
		_attack_buffer = 0.15
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	# Tátil: metade esquerda = joystick (cima/baixo = agarrar/subir, descer); metade direita:
	# em cima saltar, em baixo espada; a faixa do meio à direita é o passo cuidadoso.
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < 640.0:
				_touch_index = event.index
				_touch_origin = event.position
				_touch_dir = Vector2.ZERO
			elif event.position.y < 300.0:
				_jump_buffer = 0.15
			elif event.position.y < 500.0:
				_touch_buttons["careful"] = event.index
			else:
				_attack_buffer = 0.15
		else:
			if event.index == _touch_index:
				_touch_index = -1
				_touch_dir = Vector2.ZERO
			if _touch_buttons.get("careful", -9) == event.index:
				_touch_buttons.erase("careful")
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_touch_dir = event.position - _touch_origin


func clear_input() -> void:
	_touch_index = -1
	_touch_dir = Vector2.ZERO
	_touch_buttons.clear()
	_jump_buffer = 0.0
	_attack_buffer = 0.0


func touch_stick() -> Variant:
	return _touch_origin if _touch_index >= 0 else null


# ---------------------------------------------------------------- CPU da demonstração

## A demonstração corre pelo palácio: salta buracos, sobe beirais, apanha a espada e luta.
func _ai_think(delta: float) -> void:
	_ai_t -= delta
	ai = {"x": 0, "up": false, "down": false, "jump": false, "attack": false, "careful": false}
	var c := col_of(pos.x)
	var r := row_of(pos.y)
	if act == Act.HANG:
		ai.up = true
		return
	if act in [Act.SWORD, Act.STRIKE, Act.PARRY]:
		ai.attack = randf() < 0.05
		ai.up = act == Act.SWORD and randf() < 0.03
		return
	if not (act in [Act.STAND, Act.RUN, Act.STOP]):
		return
	var dir := facing
	if _ai_t <= 0.0:
		_ai_t = randf_range(4.0, 9.0)
		if randf() < 0.25:
			facing = -facing
			dir = facing
	# parede ou fim: tentar subir, senão voltar para trás
	var ahead := c + dir
	if blocks(ahead, r):
		if not is_floor(c, r - 1) and is_floor(ahead, r - 1):
			ai.up = true
		else:
			ai.x = -dir
		return
	if not is_floor(ahead, r):
		# buraco: saltar se houver chão do outro lado, senão descer
		if is_floor(c + dir * 2, r) or is_floor(c + dir * 3, r):
			if act == Act.RUN and absf(vel.x) > RUN_V * 0.8 and absf(pos.x - (c + (1 if dir > 0 else 0)) * TW) < 70.0:
				ai.jump = true
			ai.x = dir
			return
		var rr := r + 1
		while rr < rows() and not is_floor(ahead, rr):
			rr += 1
		if rr < rows() and rr - r <= 1:
			ai.x = dir
			return
		ai.x = -dir
		return
	# subir quando há um beiral por cima
	if not is_floor(c, r - 1) and (is_floor(c + 1, r - 1) or is_floor(c - 1, r - 1)) and randf() < 0.02:
		ai.up = true
		return
	ai.x = dir
	if tile(c, r) == "D" and exit_h > 0.9:
		ai.up = true
