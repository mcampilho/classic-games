class_name SchoolGame
extends Node2D
## Sarilhos na Escola — aventura escolar original, ao estilo de 1985 (Skool Daze): o Zé tem de
## tirar o boletim do cofre do gabinete do diretor antes que o vejam. Primeiro acerta (aos
## saltos) em todos os escudos das paredes; depois, com a fisga, deita abaixo cada professor
## para que, ao levantar-se, diga a sua letra do segredo do cofre. Tudo isto sem faltar às aulas
## nem ser apanhado: cada asneira vista dá linhas de castigo, e com 10000 linhas és expulso.

signal bell(period: Dictionary)
signal lines_given(amount: int, who: String, reason: String)
signal said(who: String, text: String)
signal shield_hit(index: int)
signal all_shields
signal letter_found(index: int, letter: String)
signal safe_opened
signal knocked(id: int)
signal fired(by_hero: bool)
signal punched
signal jumped
signal expelled

enum Mode { DEMO, PLAY }
enum State { PLAY, LEVEL, OVER }

const WORLD_W := 3600.0
const BUILDING_W := 2560.0
const FLOOR_Y := [190.0, 380.0, 570.0]
const ROOM_H := 180.0
const MAX_LINES := 10000
const PERIOD := 70.0
const STEP := 1.0 / 60.0

## Salas: nome, piso, x inicial e final, se tem quadro (aula).
const ROOMS := [
	{"name": "Sala do Mapa", "floor": 0, "x0": 0.0, "x1": 860.0, "board": true},
	{"name": "Sala de Leitura", "floor": 0, "x0": 860.0, "x1": 1720.0, "board": true},
	{"name": "Gabinete do Diretor", "floor": 0, "x0": 1720.0, "x1": 2560.0, "board": false},
	{"name": "Sala Branca", "floor": 1, "x0": 0.0, "x1": 860.0, "board": true},
	{"name": "Sala de Exames", "floor": 1, "x0": 860.0, "x1": 1720.0, "board": true},
	{"name": "Laboratório", "floor": 1, "x0": 1720.0, "x1": 2560.0, "board": true},
	{"name": "Refeitório", "floor": 2, "x0": 0.0, "x1": 1100.0, "board": false},
	{"name": "Átrio", "floor": 2, "x0": 1100.0, "x1": 2560.0, "board": false},
	{"name": "Recreio", "floor": 2, "x0": 2560.0, "x1": 3600.0, "board": false},
]
## Escadas: piso de cima, x em cima, x em baixo (ligam o piso f ao f + 1).
const STAIRS := [
	{"f": 0, "top": 310.0, "bottom": 120.0},
	{"f": 1, "top": 120.0, "bottom": 310.0},
	{"f": 0, "top": 2250.0, "bottom": 2440.0},
	{"f": 1, "top": 2440.0, "bottom": 2250.0},
]
## Escudos: piso, x, altura acima do chão (os mais altos só se alcançam em cima de um colega caído).
const SHIELDS := [
	[0, 560.0, 108.0], [0, 1180.0, 108.0], [0, 1520.0, 140.0], [0, 2000.0, 108.0],
	[1, 520.0, 108.0], [1, 1060.0, 140.0], [1, 1560.0, 108.0], [1, 2080.0, 108.0],
	[2, 600.0, 108.0], [2, 920.0, 140.0], [2, 1400.0, 108.0], [2, 1900.0, 108.0],
]
const SAFE_X := 2420.0
const TEACHERS := [
	{"name": "Dr. Severino", "subject": "diretor"},
	{"name": "Prof.ª Matilde", "subject": "matematica"},
	{"name": "Prof. Faria", "subject": "ciencias"},
	{"name": "Prof. Carvalho", "subject": "historia"},
]
const KIDS := [
	{"name": "Zé", "role": "hero"},
	{"name": "Brutamontes", "role": "bully"},
	{"name": "Marrão", "role": "swot"},
	{"name": "Traquinas", "role": "tearaway"},
	{"name": "Rita", "role": "kid"},
	{"name": "Tó", "role": "kid"},
	{"name": "Inês", "role": "kid"},
	{"name": "Rui", "role": "kid"},
]
## Horário de um dia (repete-se): tipo, sala (índice), professor (índice).
const TIMETABLE := [
	{"kind": "aula", "room": 0, "teacher": 3},
	{"kind": "aula", "room": 5, "teacher": 2},
	{"kind": "recreio", "room": 8, "teacher": -1},
	{"kind": "aula", "room": 1, "teacher": 1},
	{"kind": "almoco", "room": 6, "teacher": 0},
	{"kind": "aula", "room": 3, "teacher": 3},
	{"kind": "aula", "room": 4, "teacher": 1},
	{"kind": "recreio", "room": 8, "teacher": -1},
	{"kind": "aula", "room": 5, "teacher": 2},
]
const LESSON_TALK := {
	"historia": ["EM 1143 NASCEU PORTUGAL.", "QUEM FOI D. AFONSO HENRIQUES?", "1498: VASCO DA GAMA CHEGA À ÍNDIA.", "1640: A RESTAURAÇÃO!"],
	"matematica": ["QUANTO É 7 x 8?", "A ÁREA DO CÍRCULO É PI R2.", "QUANTO É 144 / 12?", "UM MEIO MAIS UM QUARTO?"],
	"ciencias": ["A ÁGUA É H2O.", "AS PLANTAS FAZEM FOTOSSÍNTESE.", "O CORAÇÃO TEM 4 CAVIDADES.", "A LUZ É MUITO RÁPIDA!"],
	"diretor": ["SILÊNCIO NO REFEITÓRIO!", "COMAM A SOPA TODA!", "NADA DE CORRER!", "QUEM FEZ ESTE BARULHO?"],
}
const BOARD_TEXT := {
	"historia": ["1143", "D. AFONSO", "1498", "1640"],
	"matematica": ["7X8=56", "PI R2", "144/12=12", "1/2+1/4"],
	"ciencias": ["H2O", "CO2 + LUZ", "4 CAVIDADES", "300000 KM/S"],
	"diretor": ["", "", "", ""],
}
const LETTERS := "ABCDEFGHJKLMNPRSTUVWZ"

var mode := Mode.DEMO
var state := State.PLAY
var paused := false
var skin: SchoolSkin
var best := 0
var strict := false                    # professores mais atentos

var chars: Array[Dictionary] = []      # 0 = Zé; depois os colegas; depois os professores
var pellets: Array[Dictionary] = []
var shields_hit: Array[bool] = []
var letters := ""
var known: Array[bool] = []
var safe_open := false
var score := 0
var lines := 0
var level := 1
var period := 0
var period_t := 0.0
var day := 1
var lesson := {}                       # aula em curso: arrived, phase, phase_t, talk, board, absent_t
var boards := {}                       # sala -> texto no quadro
var timer := 0.0
var cam_x := 0.0
var hero_cool := 0.0

var _acc := 0.0
var _in := {"x": 0, "y": 0, "jump": false, "fire": false, "punch": false}
var _buf := {"jump": 0.0, "fire": 0.0, "punch": 0.0}
var _touch_index := -1
var _touch_origin := Vector2.ZERO
var _touch_dir := Vector2.ZERO
var _ai := {}
var _report := []                      # queixas do Marrão: [tempo, motivo]


func _init() -> void:
	_ensure_inputs()


static func _ensure_inputs() -> void:
	var defs := {
		"sc_left": [_key(KEY_LEFT), _key(KEY_A), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"sc_right": [_key(KEY_RIGHT), _key(KEY_D), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)],
		"sc_up": [_key(KEY_UP), _key(KEY_W), _joy_button(JOY_BUTTON_DPAD_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)],
		"sc_down": [_key(KEY_DOWN), _key(KEY_S), _joy_button(JOY_BUTTON_DPAD_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)],
		"sc_jump": [_key(KEY_SPACE), _joy_button(JOY_BUTTON_A)],
		"sc_fire": [_key(KEY_X), _key(KEY_J), _joy_button(JOY_BUTTON_X)],
		"sc_punch": [_key(KEY_Z), _key(KEY_K), _joy_button(JOY_BUTTON_B)],
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


func set_skin(new_skin: SchoolSkin) -> void:
	if skin:
		skin.queue_free()
	skin = new_skin
	add_child(skin)
	skin.attach(self)


func is_ai() -> bool:
	return mode == Mode.DEMO


func hero() -> Dictionary:
	return chars[0]


func current_period() -> Dictionary:
	return TIMETABLE[period]


func room_at(fl: int, x: float) -> int:
	for i in ROOMS.size():
		var r: Dictionary = ROOMS[i]
		if int(r.floor) == fl and x >= float(r.x0) and x < float(r.x1):
			return i
	return -1


func board_x(room: int) -> float:
	return float(ROOMS[room].x0) + 190.0


func seat_x(room: int, i: int) -> float:
	return float(ROOMS[room].x0) + 360.0 + i * 62.0


func shield_pos(i: int) -> Vector2:
	var s: Array = SHIELDS[i]
	return Vector2(s[1], float(FLOOR_Y[int(s[0])]) - float(s[2]))


func shields_done() -> int:
	var n := 0
	for h in shields_hit:
		if h:
			n += 1
	return n


func all_known() -> bool:
	for k in known:
		if not k:
			return false
	return true


# ---------------------------------------------------------------- partida

func start(p_mode: Mode) -> void:
	mode = p_mode
	paused = false
	score = 0
	lines = 0
	level = 1
	day = 1
	chars.clear()
	var col := 0
	for k: Dictionary in KIDS:
		chars.append(_new_char(k.name, k.role, col))
		col += 1
	for i in TEACHERS.size():
		var c := _new_char(TEACHERS[i].name, "teacher", col)
		c.teacher = i
		c.subject = TEACHERS[i].subject
		c.speed = 120.0
		chars.append(c)
		col += 1
	# posições iniciais: todos no recreio e no átrio
	for c in chars:
		c.floor = 2
		c.x = randf_range(1500.0, 3300.0)
	hero().x = 2800.0
	hero().speed = 230.0
	_new_level()
	period = 0
	period_t = 0.0
	_start_period()
	state = State.PLAY
	cam_x = clampf(hero().x - 640.0, 0.0, WORLD_W - 1280.0)


func _new_char(n: String, role: String, idx: int) -> Dictionary:
	return {"id": idx, "name": n, "role": role, "x": 0.0, "y": 0.0, "floor": 2, "stair": -1, "st": 0.0, "facing": 1,
		"speed": randf_range(140.0, 175.0), "down_t": 0.0, "down_by_hero": false, "saw_hit": false, "jump_t": -1.0,
		"act": "", "act_t": 0.0, "anim": 0.0, "moving": false, "sit": false, "target": Vector3(-1, 0, 0),
		"wander_t": 0.0, "say": "", "say_t": 0.0, "cool": randf_range(2.0, 6.0), "seen_cool": 0.0, "teacher": -1, "subject": "",
		"standing_on": false, "blame": -1}


func _new_level() -> void:
	shields_hit.clear()
	for i in SHIELDS.size():
		shields_hit.append(false)
	letters = ""
	known.clear()
	for i in TEACHERS.size():
		letters += LETTERS[randi() % LETTERS.length()]
		known.append(false)
	safe_open = false


func _start_period() -> void:
	var p := current_period()
	lesson = {"arrived": false, "phase": "talk", "phase_t": 0.0, "talk": 0, "absent_t": 0.0, "since": 0.0}
	boards.clear()
	var seat := 0
	for c in chars:
		c.sit = false
		c.wander_t = 0.0
		if c.role == "teacher":
			if int(c.teacher) == int(p.teacher):
				c.target = Vector3(board_x(p.room) if p.kind == "aula" else float(ROOMS[p.room].x0) + 500.0, ROOMS[p.room].floor, 1)
			else:
				c.target = Vector3(-1, 0, 0)
		elif c.role != "hero":
			if p.kind == "aula":
				c.target = Vector3(seat_x(p.room, seat), ROOMS[p.room].floor, 1)
				seat += 1
			elif p.kind == "almoco":
				c.target = Vector3(float(ROOMS[p.room].x0) + 300.0 + seat * 70.0, 2, 1)
				seat += 1
			else:
				c.target = Vector3(-1, 0, 0)
	bell.emit(p)


# ---------------------------------------------------------------- ciclo

func _process(delta: float) -> void:
	if paused:
		return
	_acc += minf(delta, 0.1)
	while _acc >= STEP:
		_acc -= STEP
		_step(STEP)
	var h := hero()
	cam_x = lerpf(cam_x, clampf(h.x - 640.0, 0.0, WORLD_W - 1280.0), 1.0 - exp(-6.0 * delta))


func _step(dt: float) -> void:
	for k: String in _buf:
		_buf[k] = maxf(float(_buf[k]) - dt, 0.0)
	match state:
		State.LEVEL, State.OVER:
			timer -= dt
			for c in chars:
				_update_char(c, dt)
			if timer <= 0.0:
				if state == State.LEVEL:
					state = State.PLAY
					_new_level()
				elif mode == Mode.DEMO:
					start(Mode.DEMO)
			return
	period_t += dt
	if period_t >= PERIOD - level * 4.0:
		period_t = 0.0
		period = (period + 1) % TIMETABLE.size()
		if period == 0:
			day += 1
		_start_period()
	_read_input()
	hero_cool = maxf(hero_cool - dt, 0.0)
	for c in chars:
		c.say_t = maxf(float(c.say_t) - dt, 0.0)
		c.seen_cool = maxf(float(c.seen_cool) - dt, 0.0)
		if c.role == "hero":
			_update_hero(c, dt)
		else:
			_brain(c, dt)
		_update_char(c, dt)
	_update_pellets(dt)
	_lesson(dt)
	_watch(dt)
	for r: Array in _report:
		r[0] -= dt
		if r[0] <= 0.0:
			_give_lines(200, chars[2], I18n.t("O MARRÃO FOI CONTAR: ") + String(r[1]))
	_report = _report.filter(func(r: Array) -> bool: return float(r[0]) > 0.0)


# ---------------------------------------------------------------- movimento

## Atualiza a posição (x, y) a partir do piso/escada; anima.
func _update_char(c: Dictionary, dt: float) -> void:
	c.anim += dt * (1.0 if c.moving else 0.0)
	c.act_t += dt
	if float(c.down_t) > 0.0:
		c.down_t -= dt
		if float(c.down_t) <= 0.0:
			_got_up(c)
	if float(c.jump_t) >= 0.0:
		c.jump_t += dt
		if float(c.jump_t) > 0.5:
			c.jump_t = -1.0
	if int(c.stair) >= 0:
		var s: Dictionary = STAIRS[c.stair]
		c.x = lerpf(float(s.top), float(s.bottom), float(c.st))
		c.y = lerpf(float(FLOOR_Y[int(s.f)]), float(FLOOR_Y[int(s.f) + 1]), float(c.st))
	else:
		c.y = FLOOR_Y[int(c.floor)]


func jump_height(c: Dictionary) -> float:
	if float(c.jump_t) < 0.0:
		return 0.0
	var t := float(c.jump_t) / 0.5
	return 52.0 * 4.0 * t * (1.0 - t)


## Altura extra de estar em cima de um colega caído.
func stand_height(c: Dictionary) -> float:
	return 24.0 if c.standing_on else 0.0


func is_down(c: Dictionary) -> bool:
	return float(c.down_t) > 0.0


## Anda na direção de (x, piso). Devolve true quando chegou.
func walk_to(c: Dictionary, tx: float, tf: int, dt: float) -> bool:
	var spd := float(c.speed)
	c.moving = true
	if int(c.stair) >= 0:
		var s: Dictionary = STAIRS[c.stair]
		var down := tf > int(s.f)
		var slen := absf(float(s.bottom) - float(s.top)) * 1.414
		c.st = clampf(float(c.st) + (1.0 if down else -1.0) * spd * dt / slen, 0.0, 1.0)
		var to_x := float(s.bottom) if down else float(s.top)
		c.facing = 1 if to_x > float(c.x) else -1
		if float(c.st) >= 1.0:
			c.stair = -1
			c.floor = int(s.f) + 1
		elif float(c.st) <= 0.0:
			c.stair = -1
			c.floor = int(s.f)
		return false
	if int(c.floor) == tf:
		var dx := tx - float(c.x)
		if absf(dx) < 4.0:
			c.moving = false
			return true
		c.facing = 1 if dx > 0.0 else -1
		c.x = float(c.x) + clampf(dx, -spd * dt, spd * dt)
		return false
	# escolher escada
	var best_i := -1
	var best_d := INF
	var best_x := 0.0
	for i in STAIRS.size():
		var s: Dictionary = STAIRS[i]
		var ex := 0.0
		if tf > int(c.floor) and int(s.f) == int(c.floor):
			ex = s.top
		elif tf < int(c.floor) and int(s.f) == int(c.floor) - 1:
			ex = s.bottom
		else:
			continue
		var d := absf(ex - float(c.x)) + absf(ex - tx) * 0.3
		if d < best_d:
			best_d = d
			best_i = i
			best_x = ex
	if best_i < 0:
		c.moving = false
		return true
	var dx2 := best_x - float(c.x)
	if absf(dx2) < 5.0:
		c.x = best_x
		c.stair = best_i
		c.st = 0.0 if tf > int(c.floor) else 1.0
		return false
	c.facing = 1 if dx2 > 0.0 else -1
	c.x = float(c.x) + clampf(dx2, -spd * dt, spd * dt)
	return false


# ---------------------------------------------------------------- o Zé

func _read_input() -> void:
	if is_ai():
		_ai_think()
		return
	var x := 0
	var y := 0
	if Input.is_action_pressed("sc_left"):
		x -= 1
	if Input.is_action_pressed("sc_right"):
		x += 1
	if Input.is_action_pressed("sc_up"):
		y -= 1
	if Input.is_action_pressed("sc_down"):
		y += 1
	if _touch_index >= 0:
		if absf(_touch_dir.x) > 28.0:
			x = signi(int(_touch_dir.x))
		if absf(_touch_dir.y) > 36.0:
			y = signi(int(_touch_dir.y))
	_in = {"x": x, "y": y, "jump": _buf.jump > 0.0, "fire": _buf.fire > 0.0, "punch": _buf.punch > 0.0}


func _update_hero(h: Dictionary, dt: float) -> void:
	h.moving = false
	h.standing_on = false
	if is_down(h):
		return
	var busy := String(h.act) != "" and float(h.act_t) < 0.3
	if not busy:
		h.act = ""
	# escadas
	if int(h.stair) >= 0:
		var s: Dictionary = STAIRS[h.stair]
		var dir := 0.0
		var down_dx := signf(float(s.bottom) - float(s.top))
		if int(_in.y) != 0:
			dir = float(_in.y)
		elif int(_in.x) != 0:
			dir = float(_in.x) * down_dx
		if dir != 0.0:
			walk_to(h, 0.0, int(s.f) + (1 if dir > 0.0 else 0), dt)
		return
	if not busy:
		# entrar numa escada
		if int(_in.y) != 0:
			for i in STAIRS.size():
				var s: Dictionary = STAIRS[i]
				if int(_in.y) < 0 and int(s.f) == int(h.floor) - 1 and absf(float(s.bottom) - float(h.x)) < 26.0:
					h.stair = i
					h.st = 1.0
					return
				if int(_in.y) > 0 and int(s.f) == int(h.floor) and absf(float(s.top) - float(h.x)) < 26.0:
					h.stair = i
					h.st = 0.0
					return
			# abrir o cofre
			if int(_in.y) < 0 and int(h.floor) == 0 and absf(float(h.x) - SAFE_X) < 50.0:
				_try_safe()
		if int(_in.x) != 0:
			h.facing = int(_in.x)
			var lim := BUILDING_W - 20.0 if int(h.floor) < 2 else WORLD_W - 30.0
			h.x = clampf(float(h.x) + int(_in.x) * float(h.speed) * dt, 20.0, lim)
			h.moving = true
		if _in.jump and float(h.jump_t) < 0.0:
			h.jump_t = 0.0
			_buf.jump = 0.0
			jumped.emit()
		elif _in.fire and hero_cool <= 0.0 and float(h.jump_t) < 0.0:
			_buf.fire = 0.0
			hero_cool = 0.7
			h.act = "fire"
			h.act_t = 0.0
			_fire(h)
		elif _in.punch and float(h.jump_t) < 0.0:
			_buf.punch = 0.0
			h.act = "punch"
			h.act_t = 0.0
			_punch(h)
	# em cima de um colega caído?
	for c in chars:
		if c != h and is_down(c) and c.role != "teacher" and int(c.stair) < 0 and int(c.floor) == int(h.floor) and absf(float(c.x) - float(h.x)) < 24.0:
			h.standing_on = true
	# escudos
	if float(h.jump_t) >= 0.0:
		var top := float(h.y) - 74.0 - jump_height(h) - stand_height(h)
		for i in SHIELDS.size():
			if shields_hit[i]:
				continue
			var sp := shield_pos(i)
			if int(SHIELDS[i][0]) == int(h.floor) and absf(sp.x - float(h.x)) < 28.0 and top <= sp.y + 10.0:
				shields_hit[i] = true
				score += 100
				shield_hit.emit(i)
				if shields_done() == SHIELDS.size():
					all_shields.emit()


func _fire(c: Dictionary) -> void:
	pellets.append({"x": float(c.x) + int(c.facing) * 20.0, "y": float(c.y) - 46.0, "floor": int(c.floor), "dir": int(c.facing),
		"left": 620.0, "by": int(c.id)})
	fired.emit(c.role == "hero")
	if c.role == "hero":
		_witness("fire")


func _punch(c: Dictionary) -> void:
	punched.emit()
	for o in chars:
		if o == c or is_down(o) or o.role == "teacher" or int(o.stair) >= 0 or int(o.floor) != int(c.floor):
			continue
		var dx := float(o.x) - float(c.x)
		if signf(dx) == float(c.facing) and absf(dx) < 56.0:
			_knock(o, 2.5, c.role == "hero")
			break
	if c.role == "hero":
		_witness("punch")


func _knock(o: Dictionary, secs: float, by_hero: bool) -> void:
	o.down_t = secs
	o.stair = -1 if int(o.stair) < 0 else o.stair
	o.down_by_hero = by_hero
	o.sit = false
	o.jump_t = -1.0
	knocked.emit(int(o.id))
	if by_hero and o.role != "teacher":
		score += 10


func _update_pellets(dt: float) -> void:
	for p in pellets:
		var d := 900.0 * dt
		p.x += int(p.dir) * d
		p.left -= d
		for c in chars:
			if int(c.id) == int(p.by) or is_down(c) or int(c.stair) >= 0 or int(c.floor) != int(p.floor):
				continue
			if absf(float(c.x) - float(p.x)) < 14.0:
				var by_hero := int(p.by) == 0
				if c.role == "teacher":
					# viu quem foi se estava virado para o atirador
					var shooter: Dictionary = chars[int(p.by)]
					c.saw_hit = signf(float(shooter.x) - float(c.x)) == float(c.facing)
					c.blame = int(p.by)
					_knock(c, 3.0, by_hero)
				else:
					_knock(c, 2.5, by_hero)
				p.left = 0.0
				break
		if float(p.x) < 0.0 or float(p.x) > WORLD_W or (int(p.floor) < 2 and float(p.x) > BUILDING_W):
			p.left = 0.0
	pellets = pellets.filter(func(p: Dictionary) -> bool: return float(p.left) > 0.0)


func _got_up(c: Dictionary) -> void:
	if c.role != "teacher":
		return
	var h := hero()
	var who := int(c.get("blame", -1))
	if c.down_by_hero and c.saw_hit:
		_give_lines(500, c, I18n.t("FOSTE TU, ZÉ! %d LINHAS!"))
	elif who == 3 and absf(float(h.x) - float(c.x)) < 300.0 and int(h.floor) == int(c.floor) and randf() < 0.6:
		# o Traquinas atirou, mas o Zé estava ali ao lado...
		_give_lines(300, c, I18n.t("ZÉ, PARA COM ISSO! %d LINHAS!"))
	else:
		_say(c, I18n.t("AI! QUEM ME ATIROU ISTO?"))
	if c.down_by_hero and shields_done() == SHIELDS.size() and not known[int(c.teacher)]:
		known[int(c.teacher)] = true
		score += 200
		var ord := ["1ª", "2ª", "3ª", "4ª"]
		_say(c, I18n.t("A %s LETRA DO COFRE É %s!") % [I18n.t(ord[int(c.teacher)]), letters[int(c.teacher)]])
		letter_found.emit(int(c.teacher), letters[int(c.teacher)])
	c.down_by_hero = false
	c.saw_hit = false
	c.blame = -1


func _try_safe() -> void:
	if safe_open:
		return
	if shields_done() < SHIELDS.size():
		_say(hero(), I18n.t("O COFRE ESTÁ FECHADO..."))
		return
	if not all_known():
		_say(hero(), I18n.t("AINDA NÃO SEI O SEGREDO."))
		return
	safe_open = true
	score += 2000
	safe_opened.emit()
	state = State.LEVEL
	timer = 5.0
	level += 1


# ---------------------------------------------------------------- os outros

func _brain(c: Dictionary, dt: float) -> void:
	c.moving = false
	if is_down(c):
		return
	var p := current_period()
	var t: Vector3 = c.target
	if t.x < 0.0:
		# recreio, ou professor sem aula: passear
		c.wander_t -= dt
		if float(c.wander_t) <= 0.0:
			c.wander_t = randf_range(4.0, 9.0)
			if c.role == "teacher":
				var f := randi() % 3
				c.target = Vector3(-2, f, randf_range(150.0, BUILDING_W - 150.0))
			else:
				c.target = Vector3(-2, 2, randf_range(1300.0, WORLD_W - 100.0))
		t = c.target
		if t.x < -1.5:
			walk_to(c, t.z, int(t.y), dt)
	else:
		var arrived := walk_to(c, t.x, int(t.y), dt)
		if arrived:
			c.sit = c.role != "teacher" and p.kind != "recreio"
			if c.role == "teacher":
				if not (lesson.get("phase", "") == "write" and lesson.arrived):
					c.facing = 1
			elif p.kind == "aula":
				c.facing = -1
	# maldades
	c.cool -= dt
	match String(c.role):
		"bully":
			var h := hero()
			if float(c.cool) <= 0.0 and not c.sit:
				for o in chars:
					if o == c or is_down(o) or o.role == "teacher" or int(o.stair) >= 0 or int(o.floor) != int(c.floor) or int(c.stair) >= 0:
						continue
					if absf(float(o.x) - float(c.x)) < 50.0 and (o == h or randf() < 0.3):
						c.facing = 1 if float(o.x) > float(c.x) else -1
						c.act = "punch"
						c.act_t = 0.0
						_knock(o, 1.6, false)
						punched.emit()
						if o == h:
							_say(c, I18n.t("TOMA LÁ, ZÉ!"))
						c.cool = randf_range(5.0, 9.0)
						break
		"tearaway":
			if float(c.cool) <= 0.0 and int(c.stair) < 0:
				c.cool = randf_range(6.0, 11.0)
				c.act = "fire"
				c.act_t = 0.0
				_fire(c)


## Professores e o Marrão veem o Zé?
func sees(o: Dictionary, h: Dictionary, reach := 520.0) -> bool:
	if is_down(o) or int(o.stair) >= 0 or int(h.stair) >= 0 or int(o.floor) != int(h.floor):
		return false
	if o.role == "teacher" and lesson.get("phase", "") == "write" and _lesson_teacher() == o and lesson.arrived:
		return false
	var dx := float(h.x) - float(o.x)
	return (absf(dx) < reach + level * 30.0 + (160.0 if strict else 0.0) and signf(dx) == float(o.facing)) or absf(dx) < 60.0


func _witness(what: String) -> void:
	var h := hero()
	for o in chars:
		if o.role == "teacher" and sees(o, h):
			if what == "fire":
				_give_lines(300, o, I18n.t("NADA DE FISGAS, ZÉ! %d LINHAS!"))
			else:
				_give_lines(200, o, I18n.t("NADA DE ANDAR À PANCADA! %d LINHAS!"))
			return
	var sw: Dictionary = chars[2]
	if sees(sw, h, 400.0) and _report.is_empty():
		_say(sw, I18n.t("VOU CONTAR AO PROFESSOR!"))
		_report.append([4.0, I18n.t("ANDASTE COM A FISGA. %d LINHAS!") if what == "fire" else I18n.t("ANDASTE À PANCADA. %d LINHAS!")])


## Vigilância: o Zé fora da aula, no gabinete...
func _watch(_dt: float) -> void:
	var h := hero()
	var p := current_period()
	var in_place := _hero_in_place()
	for o in chars:
		if o.role != "teacher" or float(o.seen_cool) > 0.0 or not sees(o, h, 420.0):
			continue
		if not in_place and float(lesson.get("since", 0.0)) > 6.0 and p.kind != "recreio":
			_give_lines(100, o, I18n.t("JÁ PARA A %s, ZÉ! %%d LINHAS!") % I18n.t(String(ROOMS[p.room].name)).to_upper())
			o.seen_cool = 10.0
		elif int(h.floor) == 0 and room_at(0, float(h.x)) == 2 and int(o.teacher) == 0 and not safe_open:
			_give_lines(200, o, I18n.t("FORA DO MEU GABINETE! %d LINHAS!"))
			o.seen_cool = 10.0


func _hero_in_place() -> bool:
	var p := current_period()
	var h := hero()
	if p.kind == "recreio":
		return true
	return int(h.stair) < 0 and room_at(int(h.floor), float(h.x)) == int(p.room)


func _lesson_teacher() -> Dictionary:
	var p := current_period()
	if int(p.teacher) < 0:
		return {}
	return chars[KIDS.size() + int(p.teacher)]


func _lesson(dt: float) -> void:
	var p := current_period()
	if p.kind == "recreio":
		return
	var t := _lesson_teacher()
	if t.is_empty():
		return
	if not lesson.arrived:
		var tg: Vector3 = t.target
		if int(t.stair) < 0 and int(t.floor) == int(tg.y) and absf(float(t.x) - tg.x) < 6.0:
			lesson.arrived = true
			lesson.phase_t = 0.0
			lesson.since = 0.0
			_say(t, I18n.t("BOM DIA, MENINOS.") if p.kind == "aula" else I18n.t("BOM APETITE."))
		return
	lesson.since += dt
	lesson.phase_t += dt
	if is_down(t):
		return
	var subj := String(t.subject)
	if p.kind == "aula":
		if lesson.phase == "talk" and float(lesson.phase_t) > 6.0:
			lesson.phase = "write"
			lesson.phase_t = 0.0
			t.facing = -1
		elif lesson.phase == "write":
			var full: String = I18n.t(BOARD_TEXT[subj][int(lesson.talk) % 4])
			boards[int(p.room)] = full.substr(0, int(float(lesson.phase_t) * 3.0))
			t.act = "write"
			t.act_t = 0.0
			if float(lesson.phase_t) > 4.5:
				lesson.phase = "talk"
				lesson.phase_t = 0.0
				t.facing = 1
				t.act = ""
				_say(t, I18n.t(LESSON_TALK[subj][int(lesson.talk) % 4]))
				lesson.talk = int(lesson.talk) + 1
	elif float(lesson.phase_t) > 9.0:
		lesson.phase_t = 0.0
		_say(t, I18n.t(LESSON_TALK[subj][randi() % 4]))
	# falta à aula
	if not _hero_in_place() and float(lesson.since) > 8.0:
		lesson.absent_t += dt
		if float(lesson.absent_t) > 14.0:
			lesson.absent_t = 0.0
			_give_lines(200, t, I18n.t("ONDE ESTÁ O ZÉ? %d LINHAS!"))
	else:
		lesson.absent_t = 0.0


func _say(c: Dictionary, text: String) -> void:
	c.say = text
	c.say_t = 2.6
	said.emit(String(c.name), text)


func _give_lines(n: int, who: Dictionary, text: String) -> void:
	if state != State.PLAY:
		return
	n *= 1 + (level - 1) / 2
	lines += n
	_say(who, text % n if text.contains("%d") else text)
	lines_given.emit(n, String(who.name), text)
	if lines >= MAX_LINES:
		lines = MAX_LINES
		state = State.OVER
		timer = 5.0
		if mode == Mode.PLAY:
			best = maxi(best, score)
		expelled.emit()


# ---------------------------------------------------------------- entrada

func _unhandled_input(event: InputEvent) -> void:
	if paused or is_ai():
		return
	if event.is_action_pressed("sc_jump"):
		_buf.jump = 0.15
	if event.is_action_pressed("sc_fire"):
		_buf.fire = 0.15
	if event.is_action_pressed("sc_punch"):
		_buf.punch = 0.15
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	# Tátil: metade esquerda = joystick; à direita, de cima para baixo: saltar, fisga, murro.
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < 640.0:
				_touch_index = event.index
				_touch_origin = event.position
				_touch_dir = Vector2.ZERO
			elif event.position.y < 260.0:
				_buf.jump = 0.15
			elif event.position.y < 470.0:
				_buf.fire = 0.15
			else:
				_buf.punch = 0.15
		elif event.index == _touch_index:
			_touch_index = -1
			_touch_dir = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_touch_dir = event.position - _touch_origin


func clear_input() -> void:
	_touch_index = -1
	_touch_dir = Vector2.ZERO
	for k: String in _buf:
		_buf[k] = 0.0


func touch_stick() -> Variant:
	return _touch_origin if _touch_index >= 0 else null


# ---------------------------------------------------------------- CPU da demonstração

## A demonstração vai às aulas e, no recreio, salta aos escudos (quando ninguém está a ver).
func _ai_think() -> void:
	var h := hero()
	_in = {"x": 0, "y": 0, "jump": false, "fire": false, "punch": false}
	if is_down(h):
		return
	var p := current_period()
	var tx := 0.0
	var tf := 0
	if p.kind != "recreio":
		var r: Dictionary = ROOMS[p.room]
		tx = float(r.x0) + 330.0 if p.kind == "aula" else float(r.x0) + 250.0
		tf = int(r.floor)
	else:
		var bi := -1
		var bd := INF
		for i in SHIELDS.size():
			if shields_hit[i] or float(SHIELDS[i][2]) > 120.0:
				continue
			var sp := shield_pos(i)
			var d := absf(sp.x - float(h.x)) + absi(int(SHIELDS[i][0]) - int(h.floor)) * 600.0
			if d < bd:
				bd = d
				bi = i
		if bi < 0:
			tx = 3000.0
			tf = 2
		else:
			tx = shield_pos(bi).x
			tf = int(SHIELDS[bi][0])
	_ai_walk(h, tx, tf)
	if int(_in.x) == 0 and int(_in.y) == 0 and p.kind == "recreio":
		var watched := false
		for o in chars:
			if o.role == "teacher" and sees(o, h):
				watched = true
		_in.jump = not watched and randf() < 0.05
	if randf() < 0.004 and p.kind == "recreio":
		var seen := false
		for o in chars:
			if (o.role == "teacher" or o.role == "swot") and sees(o, h, 600.0):
				seen = true
		_in.fire = not seen


## Traduz "ir para (x, piso)" em direções de comando, como um jogador faria.
func _ai_walk(h: Dictionary, tx: float, tf: int) -> void:
	if int(h.stair) >= 0:
		var s: Dictionary = STAIRS[h.stair]
		_in.y = 1 if tf > int(s.f) else -1
		return
	if int(h.floor) == tf:
		if absf(tx - float(h.x)) > 8.0:
			_in.x = 1 if tx > float(h.x) else -1
		return
	var best_x := 0.0
	var best_d := INF
	for s: Dictionary in STAIRS:
		var ex := 0.0
		if tf > int(h.floor) and int(s.f) == int(h.floor):
			ex = s.top
		elif tf < int(h.floor) and int(s.f) == int(h.floor) - 1:
			ex = s.bottom
		else:
			continue
		var d := absf(ex - float(h.x))
		if d < best_d:
			best_d = d
			best_x = ex
	if absf(best_x - float(h.x)) < 14.0:
		_in.y = 1 if tf > int(h.floor) else -1
	else:
		_in.x = 1 if best_x > float(h.x) else -1
