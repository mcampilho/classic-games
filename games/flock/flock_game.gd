class_name FlockGame
extends Node2D
## Rebanho — puzzle original ao estilo de 1991 (Lemmings): as ovelhas saem do curral e caminham
## sozinhas; dá-lhes funções para que cheguem ao celeiro. O terreno é um mapa de píxeis que se
## pode escavar e construir. Ovelhas: trepadora, guarda-chuva, bloqueadora, construtora,
## escavadora (em frente), mineira (na diagonal) e cavadora (para baixo).
## Campo lógico de 320 x 150 píxeis (x4 no ecrã).

signal level_started(level: int)
signal released
signal assigned(skill: String)
signal saved(pos: Vector2)
signal died(pos: Vector2, how: String)
signal brick
signal level_ended(success: bool)
signal won
signal game_over

enum Mode { DEMO, PLAY }
enum State { PLAY, END, WON, OVER }
enum Job { WALK, FALL, FLOAT, CLIMB, BLOCK, BUILD, BASH, MINE, DIG, SPLAT, EXIT, DEAD }

const W := 320
const H := 150
const SCALE := 4.0
const TICK := 1.0 / 18.0
const SKILLS := ["climber", "floater", "blocker", "builder", "basher", "miner", "digger"]
const SKILL_NAMES := {"climber": "Trepadora", "floater": "Guarda-chuva", "blocker": "Bloqueadora", "builder": "Construtora", "basher": "Escavadora", "miner": "Mineira", "digger": "Cavadora"}
const EMPTY := 0
const EARTH := 1
const STEEL := 2
const BRICK := 3
const SPLAT_FALL := 56
## Botões do painel (no ecrã): taxa -, taxa +, 7 funções, pausa, rapidez, recomeçar.
const PANEL_Y := 604.0
const BTN_W := 98.0

## Níveis: formas do terreno (rect/oval/steel/hole), curral, celeiro, ovelhas, quantas salvar,
## funções disponíveis, tempo (minutos) e a solução usada na demonstração e nos testes.
const LEVELS := [
	{"name": "Basta andar", "shapes": [["rect", 0, 110, 320, 40], ["oval", 160, 112, 60, 14], ["rect", 0, 0, 6, 150], ["rect", 314, 0, 6, 150]],
		"entrance": Vector2(40, 60), "exit": Vector2(280, 109), "count": 10, "need": 8, "rate": 50, "time": 3,
		"skills": {"climber": 0, "floater": 0, "blocker": 0, "builder": 0, "basher": 0, "miner": 0, "digger": 0}, "solution": []},
	{"name": "Uma ponte", "shapes": [["rect", 0, 110, 152, 40], ["rect", 170, 110, 150, 40], ["rect", 0, 0, 6, 150], ["rect", 314, 0, 6, 150]],
		"entrance": Vector2(40, 60), "exit": Vector2(280, 109), "count": 10, "need": 7, "rate": 20, "time": 4,
		"skills": {"climber": 0, "floater": 0, "blocker": 1, "builder": 3, "basher": 0, "miner": 0, "digger": 0},
		"solution": [["builder", 147, 151, 0]]},
	{"name": "A colina", "shapes": [["rect", 0, 110, 320, 40], ["oval", 170, 110, 40, 58], ["rect", 0, 0, 6, 150], ["rect", 314, 0, 6, 150]],
		"entrance": Vector2(40, 60), "exit": Vector2(285, 109), "count": 12, "need": 9, "rate": 40, "time": 4,
		"skills": {"climber": 2, "floater": 0, "blocker": 0, "builder": 0, "basher": 3, "miner": 2, "digger": 0},
		"solution": [["basher", 124, 129, 0]]},
	{"name": "Por baixo do chão", "shapes": [["rect", 0, 70, 320, 12], ["rect", 0, 120, 320, 30], ["rect", 0, 0, 6, 150], ["rect", 314, 0, 6, 150], ["steel", 300, 40, 14, 42]],
		"entrance": Vector2(30, 30), "exit": Vector2(160, 119), "count": 12, "need": 9, "rate": 50, "time": 4,
		"skills": {"climber": 0, "floater": 0, "blocker": 0, "builder": 0, "basher": 0, "miner": 0, "digger": 2},
		"solution": [["digger", 150, 170, 0]]},
	{"name": "Precipício", "shapes": [["rect", 0, 40, 120, 110], ["rect", 120, 132, 200, 18], ["rect", 0, 0, 6, 150], ["rect", 314, 0, 6, 150]],
		"entrance": Vector2(30, 28), "exit": Vector2(270, 131), "count": 12, "need": 10, "rate": 50, "time": 4,
		"skills": {"climber": 0, "floater": 14, "blocker": 1, "builder": 0, "basher": 0, "miner": 2, "digger": 0},
		"solution": [["floater_all", 0, 120, 0]]},
	{"name": "Tudo junto", "shapes": [["rect", 0, 60, 120, 10], ["rect", 0, 128, 320, 22], ["rect", 200, 70, 14, 58], ["rect", 0, 0, 6, 150], ["rect", 314, 0, 6, 150], ["steel", 120, 60, 6, 10]],
		"entrance": Vector2(30, 30), "exit": Vector2(290, 127), "count": 14, "need": 10, "rate": 40, "time": 5,
		"skills": {"climber": 2, "floater": 14, "blocker": 2, "builder": 2, "basher": 2, "miner": 2, "digger": 2},
		"solution": [["digger", 40, 100, 0], ["floater_all", 0, 120, 0], ["basher", 191, 199, 0]]},
]

var mode := Mode.DEMO
var state := State.PLAY
var paused := false
var fast := false
var skin: FlockSkin
var best := 0

var level := 0
var terrain := PackedByteArray()
var changed := PackedInt32Array()      # índices de píxeis alterados (para o desenho)
var sheep: Array[Dictionary] = []      # pos (Vector2i), dir, job, fall, t, bricks, climber, floater, anim
var skills := {}
var selected := 3
var rate := 50
var min_rate := 50
var to_release := 0
var released_n := 0
var saved_n := 0
var lost_n := 0
var time_left := 0.0
var score := 0
var timer := 0.0
var cursor := Vector2(640, 300)        # ecrã
var hover := -1
var _acc := 0.0
var _release_t := 0
var _sol_done := {}
var _pad_dir := Vector2.ZERO


func _init() -> void:
	_ensure_inputs()


static func _ensure_inputs() -> void:
	var defs := {
		"fl_left": [_key(KEY_A), _key(KEY_LEFT), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"fl_right": [_key(KEY_D), _key(KEY_RIGHT), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)],
		"fl_up": [_key(KEY_W), _key(KEY_UP), _joy_button(JOY_BUTTON_DPAD_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)],
		"fl_down": [_key(KEY_S), _key(KEY_DOWN), _joy_button(JOY_BUTTON_DPAD_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)],
		"fl_assign": [_key(KEY_SPACE), _key(KEY_ENTER), _joy_button(JOY_BUTTON_A)],
		"fl_next": [_key(KEY_E), _key(KEY_TAB), _joy_button(JOY_BUTTON_RIGHT_SHOULDER)],
		"fl_prev": [_key(KEY_Q), _joy_button(JOY_BUTTON_LEFT_SHOULDER)],
		"fl_fast": [_key(KEY_F), _joy_button(JOY_BUTTON_Y)],
		"fl_restart": [_key(KEY_R), _joy_button(JOY_BUTTON_BACK)],
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


func set_skin(new_skin: FlockSkin) -> void:
	if skin:
		skin.queue_free()
	skin = new_skin
	add_child(skin)
	skin.attach(self)


func is_ai() -> bool:
	return mode == Mode.DEMO


func data() -> Dictionary:
	return LEVELS[level]


func to_px(p: Vector2) -> Vector2:
	return p * SCALE


# ---------------------------------------------------------------- terreno

func t_at(x: int, y: int) -> int:
	if x < 0 or x >= W or y < 0:
		return EMPTY
	if y >= H:
		return EMPTY
	return terrain[y * W + x]


func solid(x: int, y: int) -> bool:
	return t_at(x, y) != EMPTY


func _put(x: int, y: int, v: int) -> void:
	if x < 0 or x >= W or y < 0 or y >= H:
		return
	var i := y * W + x
	if terrain[i] == v:
		return
	terrain[i] = v
	changed.append(i)


## Remove terreno (não o aço). Devolve true se tocou em aço.
func carve(x0: int, y0: int, x1: int, y1: int) -> bool:
	var steel := false
	for y in range(mini(y0, y1), maxi(y0, y1) + 1):
		for x in range(mini(x0, x1), maxi(x0, x1) + 1):
			var t := t_at(x, y)
			if t == STEEL:
				steel = true
			elif t != EMPTY:
				_put(x, y, EMPTY)
	return steel


func _build_terrain() -> void:
	terrain.resize(W * H)
	terrain.fill(EMPTY)
	for s: Array in data().shapes:
		var kind: String = s[0]
		match kind:
			"rect", "steel":
				for y in range(int(s[2]), mini(int(s[2]) + int(s[4]), H)):
					for x in range(int(s[1]), mini(int(s[1]) + int(s[3]), W)):
						terrain[y * W + x] = STEEL if kind == "steel" else EARTH
			"oval":
				var c := Vector2(s[1], s[2])
				var r := Vector2(s[3], s[4])
				for y in range(maxi(0, int(c.y - r.y)), mini(H, int(c.y + r.y) + 1)):
					for x in range(maxi(0, int(c.x - r.x)), mini(W, int(c.x + r.x) + 1)):
						if ((Vector2(x, y) - c) / r).length() <= 1.0:
							terrain[y * W + x] = EARTH
	changed.clear()


# ---------------------------------------------------------------- partida e níveis

func start(p_mode: Mode, first := 0) -> void:
	mode = p_mode
	paused = false
	fast = false
	score = 0
	level = first
	_load_level()


func _load_level() -> void:
	var d := data()
	_build_terrain()
	sheep.clear()
	skills = (d.skills as Dictionary).duplicate()
	rate = d.rate
	min_rate = d.rate
	to_release = d.count
	released_n = 0
	saved_n = 0
	lost_n = 0
	time_left = float(d.time) * 60.0
	_release_t = 20
	_sol_done.clear()
	state = State.PLAY
	selected = 3
	for i in SKILLS.size():
		if int(skills[SKILLS[i]]) > 0:
			selected = i
			break
	level_started.emit(level)


func restart_level() -> void:
	_load_level()


func alive_count() -> int:
	var n := 0
	for s in sheep:
		if s.job != Job.DEAD and s.job != Job.EXIT:
			n += 1
	return n


# ---------------------------------------------------------------- ciclo

func _process(delta: float) -> void:
	if paused:
		return
	delta = minf(delta, 0.1)
	_move_cursor(delta)
	if state == State.PLAY:
		_acc += delta * (3.0 if fast else 1.0)
		while _acc >= TICK:
			_acc -= TICK
			_tick()
			if state != State.PLAY:
				break
	else:
		timer -= delta
		if timer <= 0.0:
			if state == State.END:
				if is_ai():
					level = (level + 1) % 2
					_load_level()
			elif mode == Mode.DEMO:
				start(Mode.DEMO)


func _tick() -> void:
	time_left -= TICK
	if is_ai():
		_ai()
	# soltar ovelhas
	if to_release > 0:
		_release_t -= 1
		if _release_t <= 0:
			_release_t = 4 + (99 - rate) / 2
			var e: Vector2 = data().entrance
			sheep.append({"pos": Vector2i(int(e.x), int(e.y)), "dir": 1, "job": Job.FALL, "fall": 0, "t": 0, "bricks": 0,
				"climber": false, "floater": false, "anim": 0, "id": released_n})
			to_release -= 1
			released_n += 1
			released.emit()
	for s in sheep:
		_update(s)
	_update_hover()
	if (to_release == 0 and alive_count() == 0) or time_left <= 0.0:
		_end_level()


func _end_level() -> void:
	var ok := saved_n >= int(data().need)
	if ok:
		score += saved_n * 100 + maxi(int(time_left), 0)
	state = State.END
	timer = 3.0
	level_ended.emit(ok)
	if not ok and mode == Mode.PLAY:
		best = maxi(best, score)
	if ok and level + 1 >= LEVELS.size() and mode == Mode.PLAY:
		state = State.WON
		timer = 6.0
		best = maxi(best, score)
		won.emit()


## Avança para o nível seguinte (se o atual foi superado) ou repete-o.
func continue_after_end() -> void:
	if saved_n >= int(data().need):
		level = (level + 1) % LEVELS.size()
	_load_level()


# ---------------------------------------------------------------- ovelhas

func _update(s: Dictionary) -> void:
	s.anim += 1
	s.t += 1
	var p: Vector2i = s.pos
	match s.job:
		Job.WALK:
			_walk(s)
		Job.FALL, Job.FLOAT:
			var spd := 1 if s.job == Job.FLOAT else 3
			for k in spd:
				if solid(p.x, p.y + 1):
					if s.fall > SPLAT_FALL and s.job != Job.FLOAT:
						s.job = Job.SPLAT
						s.t = 0
						died.emit(Vector2(p), "splat")
					else:
						s.job = Job.WALK
					s.fall = 0
					s.pos = p
					return
				p.y += 1
				s.fall += 1
			if s.floater and s.job == Job.FALL and s.fall > 14:
				s.job = Job.FLOAT
			s.pos = p
			if p.y > H + 8:
				_lose(s, "fall")
		Job.CLIMB:
			if solid(p.x, p.y - 9):
				# bateu no teto: cai para trás
				s.dir = -s.dir
				s.pos = Vector2i(p.x + s.dir, p.y)
				s.job = Job.FALL
				s.fall = 0
				return
			if solid(p.x + s.dir, p.y - 7):
				p.y -= 1
			else:
				p.y -= 1
				p.x += s.dir
				s.job = Job.WALK
			s.pos = p
		Job.BLOCK:
			if not solid(p.x, p.y + 1):
				s.job = Job.FALL
		Job.BUILD:
			if s.t % 5 == 0:
				# um tijolo de 6 píxeis à frente, ao nível dos pés
				for k in range(1, 7):
					var bx: int = p.x + s.dir * k
					if t_at(bx, p.y) == EMPTY:
						_put(bx, p.y, BRICK)
				brick.emit()
				s.bricks += 1
				if solid(p.x + s.dir * 2, p.y - 1) or solid(p.x + s.dir * 2, p.y - 8):
					s.dir = -s.dir
					s.job = Job.WALK
					return
				s.pos = Vector2i(p.x + s.dir * 2, p.y - 1)
				if s.bricks >= 12:
					s.job = Job.WALK
		Job.BASH:
			if s.t % 2 == 0:
				var steel := carve(p.x + s.dir, p.y - 8, p.x + s.dir * 5, p.y)
				if steel:
					s.dir = -s.dir
					s.job = Job.WALK
					return
				var more := false
				for k in range(1, 10):
					for yy in range(p.y - 6, p.y + 1):
						if solid(p.x + s.dir * k, yy):
							more = true
				if not more:
					s.job = Job.WALK
					return
				p.x += s.dir
				if not solid(p.x, p.y + 1):
					s.job = Job.FALL
					s.fall = 0
				s.pos = p
		Job.MINE:
			if s.t % 3 == 0:
				var steel := carve(p.x + s.dir * 1, p.y - 7, p.x + s.dir * 5, p.y + 1)
				if steel:
					s.job = Job.WALK
					return
				p.x += s.dir
				p.y += 1
				if not solid(p.x, p.y + 2) and not solid(p.x + s.dir, p.y + 2):
					s.job = Job.FALL
					s.fall = 0
				s.pos = p
		Job.DIG:
			if s.t % 3 == 0:
				var any := false
				for x in range(p.x - 4, p.x + 5):
					if t_at(x, p.y + 1) == STEEL:
						s.job = Job.WALK
						return
					if solid(x, p.y + 1):
						any = true
				carve(p.x - 4, p.y + 1, p.x + 4, p.y + 1)
				if not any:
					s.job = Job.FALL
					s.fall = 0
					return
				p.y += 1
				s.pos = p
		Job.SPLAT:
			if s.t > 10:
				_lose(s, "splat")
		Job.EXIT:
			if s.t > 8:
				s.job = Job.DEAD
	# chegou ao celeiro?
	if s.job in [Job.WALK, Job.FALL, Job.FLOAT, Job.BUILD, Job.BASH]:
		var e: Vector2 = data().exit
		if absf(s.pos.x - e.x) <= 3 and absf(s.pos.y - e.y) <= 6:
			s.job = Job.EXIT
			s.t = 0
			saved_n += 1
			saved.emit(Vector2(s.pos))


func _walk(s: Dictionary) -> void:
	var p: Vector2i = s.pos
	if not solid(p.x, p.y + 1):
		s.job = Job.FALL
		s.fall = 0
		return
	var nx: int = p.x + s.dir
	# bloqueadoras viram quem lhes toca
	for o in sheep:
		if o.job == Job.BLOCK and o != s:
			var op: Vector2i = o.pos
			if absi(op.x - nx) <= 2 and absi(op.y - p.y) <= 6:
				s.dir = -s.dir
				return
	if nx < 0 or nx >= W:
		s.dir = -s.dir
		return
	var ny := p.y
	if solid(nx, ny):
		var up := 0
		while up <= 6 and solid(nx, ny - up):
			up += 1
		if up > 6:
			if s.climber:
				s.job = Job.CLIMB
				return
			s.dir = -s.dir
			return
		ny -= up
	else:
		var down := 0
		while down < 3 and not solid(nx, ny + 1 + down):
			down += 1
		if down < 3:
			ny += down
		else:
			s.pos = Vector2i(nx, ny)
			s.job = Job.FALL
			s.fall = 0
			return
	s.pos = Vector2i(nx, ny)


func _lose(s: Dictionary, how: String) -> void:
	if s.job == Job.DEAD:
		return
	if how != "splat":
		died.emit(Vector2(s.pos), how)
	s.job = Job.DEAD
	lost_n += 1


## Dá a função escolhida a uma ovelha. Devolve true se resultou.
func assign(i: int, skill: String) -> bool:
	if i < 0 or i >= sheep.size() or int(skills.get(skill, 0)) <= 0:
		return false
	var s: Dictionary = sheep[i]
	var ok := false
	match skill:
		"climber":
			ok = not s.climber and s.job in [Job.WALK, Job.FALL, Job.FLOAT, Job.BUILD, Job.BASH, Job.MINE, Job.DIG]
			if ok:
				s.climber = true
		"floater":
			ok = not s.floater and s.job in [Job.WALK, Job.FALL, Job.CLIMB, Job.BUILD, Job.BASH, Job.MINE, Job.DIG]
			if ok:
				s.floater = true
		"blocker":
			ok = s.job in [Job.WALK, Job.BUILD, Job.BASH, Job.MINE, Job.DIG]
			if ok:
				s.job = Job.BLOCK
		"builder", "basher", "miner", "digger":
			ok = s.job in [Job.WALK, Job.BUILD, Job.BASH, Job.MINE, Job.DIG] and s.job != {"builder": Job.BUILD, "basher": Job.BASH, "miner": Job.MINE, "digger": Job.DIG}[skill]
			if ok:
				s.job = {"builder": Job.BUILD, "basher": Job.BASH, "miner": Job.MINE, "digger": Job.DIG}[skill]
				s.t = 0
				s.bricks = 0
	if ok:
		skills[skill] = int(skills[skill]) - 1
		assigned.emit(skill)
	return ok


# ---------------------------------------------------------------- cursor e entrada

func _update_hover() -> void:
	var c := cursor / SCALE
	hover = -1
	var best_d := 9.0
	for i in sheep.size():
		var s: Dictionary = sheep[i]
		if s.job == Job.DEAD or s.job == Job.EXIT or s.job == Job.SPLAT:
			continue
		var d := (Vector2(s.pos) + Vector2(0, -4)).distance_to(c)
		if d < best_d:
			best_d = d
			hover = i


func _move_cursor(delta: float) -> void:
	if is_ai():
		return
	var v := Vector2(Input.get_axis("fl_left", "fl_right"), Input.get_axis("fl_up", "fl_down"))
	if v.length() > 0.2:
		cursor = (cursor + v * 420.0 * delta).clamp(Vector2.ZERO, Vector2(1279, PANEL_Y - 1))
		_update_hover()


func button_rect(i: int) -> Rect2:
	return Rect2(6 + i * (BTN_W + 6), PANEL_Y + 8, BTN_W, 104)


## Botões: 0 taxa-, 1 taxa+, 2..8 funções, 9 pausa, 10 rapidez, 11 recomeçar.
func press_button(i: int) -> void:
	match i:
		0:
			rate = maxi(min_rate, rate - 10)
		1:
			rate = mini(99, rate + 10)
		9:
			paused = not paused
		10:
			fast = not fast
		11:
			restart_level()
		_:
			if i >= 2 and i <= 8:
				selected = i - 2


func _unhandled_input(event: InputEvent) -> void:
	if is_ai():
		return
	if event.is_action_pressed("fl_next"):
		selected = (selected + 1) % SKILLS.size()
	elif event.is_action_pressed("fl_prev"):
		selected = (selected + SKILLS.size() - 1) % SKILLS.size()
	elif event.is_action_pressed("fl_fast"):
		fast = not fast
	elif event.is_action_pressed("fl_restart") and state == State.PLAY:
		restart_level()
	elif event.is_action_pressed("fl_assign"):
		assign(hover, SKILLS[selected])
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.physical_keycode - KEY_1
		if k >= 0 and k < SKILLS.size():
			selected = k
	if paused and not event is InputEventScreenTouch:
		return
	var pos := Vector2(-1, -1)
	var click := false
	if event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		cursor = event.position
		_update_hover()
	elif event is InputEventScreenTouch and event.pressed:
		# (o projeto emula toques a partir do rato: um clique chega aqui como toque)
		pos = event.position
		click = true
	if click:
		if pos.y >= PANEL_Y:
			for i in 12:
				if button_rect(i).has_point(pos):
					press_button(i)
					return
		elif state == State.PLAY and not paused:
			cursor = pos
			_update_hover()
			assign(hover, SKILLS[selected])


# ---------------------------------------------------------------- CPU da demonstração (a solução)

## A demonstração segue a solução do nível: ["função", x mínimo, x máximo, n.º de vezes].
func _ai() -> void:
	var sol: Array = data().solution
	for k in sol.size():
		var step: Array = sol[k]
		var skill: String = step[0]
		if skill == "floater_all":
			for i in sheep.size():
				if not sheep[i].floater and sheep[i].job in [Job.WALK, Job.FALL]:
					assign(i, "floater")
			continue
		if _sol_done.has(k):
			continue
		for i in sheep.size():
			var s: Dictionary = sheep[i]
			if s.job == Job.WALK and s.pos.x >= int(step[1]) and s.pos.x <= int(step[2]) and s.dir > 0:
				if assign(i, skill):
					_sol_done[k] = true
					break
