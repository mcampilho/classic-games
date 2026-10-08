class_name ChuckieGame
extends Node2D
## Lógica do Chuckie Egg (1983): o agricultor apanha os 12 ovos de cada nível, subindo escadas,
## saltando entre plataformas e apanhando elevadores, sem tocar nas galinhas.
## O grão dá pontos e para o relógio; as galinhas também o comem. A partir do nível 9 o pato
## gigante sai da gaiola e persegue o jogador. Os 8 níveis são originais.
## Unidades: 1 casa = 8 unidades; o campo tem 28 x 21 casas.

signal match_started
signal turn_started(player: int)
signal level_started(level: int)
signal egg_taken(pos: Vector2)
signal grain_taken(pos: Vector2, by_hen: bool)
signal jumped
signal landed
signal climbing(on: bool)
signal player_died(pos: Vector2)
signal level_cleared(bonus: int)
signal extra_life
signal game_over

enum Mode { DEMO, ONE, TWO }
enum State { READY, PLAY, DYING, CLEAR, OVER }
enum Move { WALK, AIR, CLIMB }

const COLS := 28
const ROWS := 21
const TILE := 8.0
const FIELD := Vector2(COLS * TILE, ROWS * TILE)
const SCALE := 4.0
const ORIGIN := Vector2(192, 24)
const WALK_V := 40.0
const CLIMB_V := 30.0
const JUMP_V := 100.0
const GRAVITY := 360.0
const FALL_MAX := 150.0
const LIFT_V := 16.0
const HEN_V := 17.0
const TIME_START := 900.0
const TIME_RATE := 6.0
const GRAIN_FREEZE := 3.0
const EGG_POINTS := 100
const GRAIN_POINTS := 50
const EXTRA_LIFE_EVERY := 10000
const LEVEL_NAMES := ["Galinheiro", "Celeiro", "Elevador", "Escadaria", "Escadas", "Dois Elevadores", "Ilhas", "Tudo Junto"]
## Níveis sem elevador (a demonstração só joga nestes).
const DEMO_LEVELS := [1, 2, 4, 5, 7, 8]
const T_EMPTY := 46    # "."
const T_FLOOR := 35    # "#"
const T_LADDER := 72   # "H"
const T_BOTH := 43     # "+"

## Níveis originais (28 x 21): # plataforma, H escada, + escada que chega a uma plataforma,
## o ovo, * grão, h galinha, P jogador, L poço de elevador (2 casas de largura).
const LEVELS := [
	[
		"............................",
		"............................",
		"............................",
		".......o.....*......o.....o.",
		".....####+##############+###",
		".........H..............H...",
		".........H..............H...",
		".o.....*.H........o..h..Ho..",
		"####+#######.....##+#######.",
		"....H..............H........",
		"....H..............H........",
		"...oH.....*...o....H......o.",
		"..######+######..######+####",
		"........H..............H....",
		"........H..............H....",
		"..o.*...H......o.......H...o",
		"#####+#####..#####+#########",
		".....H............H.........",
		".....H............H.........",
		"..P..H.....h......H...*.....",
		"############################",
	],
	[
		"............................",
		"............................",
		"............................",
		"........o..*.......o.......o",
		".....#+######...##########+#",
		"......H.......o...........H.",
		"......H......###..........H.",
		"o.....H.....*......h.....oH.",
		"###+###..####...##+##..#####",
		"...H..............H.........",
		"...H..............H.........",
		".o.H...*..........H.o..h...o",
		"##########+#....#########+##",
		"..........H..............H..",
		"..........H..............H..",
		"..o.......H..o...o.......H..",
		"..##+#########...#####+###..",
		"....H.................H.....",
		"....H.................H.....",
		".P..H....h..*.........H....*",
		"############################",
	],
	[
		"............L...............",
		"............................",
		"............................",
		"......o.*..o....o..........o",
		".....##+####....########+###",
		".......H................H...",
		".......H................H...",
		"o......H...o.........*..H...",
		"#########+##....##+#########",
		".........H........H.........",
		".........H........H.........",
		".....*h..H......o.H........o",
		"##+#########....#########+##",
		"..H......................H..",
		"..H......................H..",
		"..H..o.....o.........ho..H..",
		"########+###....###+########",
		"........H..........H........",
		"........H..........H........",
		".P......H..........H...*...o",
		"############....############",
	],
	[
		"............................",
		"............................",
		"............................",
		".......o...o.........o....o.",
		".....#+######....*.########+",
		"......H......o..##.........H",
		"......H......##............H",
		".o..*.H...##...............H",
		"##+####.o...............#+##",
		"..H.....##...............H..",
		"..H........##..o.........H..",
		"..H...........##......oh.H..",
		"..H...............*.######+#",
		"..H..............##.......H.",
		"..H.........o.##..........H.",
		".oH.h...*..##.............Ho",
		"###+######..........####+###",
		"...H....................H...",
		"...H....................H...",
		".P.H.......h......*.....H...",
		"############################",
	],
	[
		"............................",
		"............................",
		"............................",
		"..........o.......*.....ho..",
		".....##+######+#######+#####",
		".......H......H.......H.....",
		".......H......H.......H.....",
		".o...*.H....h.H.o.....H....o",
		"###+#######+######+#######+#",
		"...H.......H......H.......H.",
		"...H.......H......H.......H.",
		"*..H....o..H.*....H.ho....H.",
		"######+########+#######+####",
		"......H........H.......H....",
		"......H........H.......H....",
		"o...h.H......o.H.......H*..o",
		"##+#######+########+#####+##",
		"..H.......H........H.....H..",
		"..H.......H........H.....H..",
		"..H...o.P.H....*h..H..o..H..",
		"############################",
	],
	[
		".........L.........L........",
		"............................",
		"............................",
		".....o.......o.........*...o",
		".....###....##+###....######",
		"..............H.............",
		"..............H.............",
		"o......*......H..o....o.....",
		"##+#####....######....###+##",
		"..H......................H..",
		"..H......................H..",
		"..H...o.....o..*.......h.H.o",
		"########....####+#....######",
		"................H...........",
		"................H...........",
		".o..............Ho..........",
		"#####+##....#+####....##+###",
		".....H.......H..........H...",
		".....H.......H..........H...",
		"..*P.H.......Hh.........H.o.",
		"########....######....######",
	],
	[
		"............................",
		"............................",
		"............................",
		".........o...*.o.......o....",
		".....###+#..#####..######+##",
		"........H................H..",
		"........H................H..",
		".o......H.*o.....o.......H.o",
		"###+#..######..###+##..#####",
		"...H..............H.........",
		"...H..............H.........",
		"..oH........o.....Hh*.....o.",
		".####+#..#####..########+##.",
		".....H..................H...",
		".....H..................H...",
		".....H..o.......o....*.hH...",
		"###+#####..###+##..###+#####",
		"...H..........H.......H.....",
		"...H..........H.......H.....",
		".P.H.....h.*..H.......H.....",
		"############################",
	],
	[
		"............................",
		"............................",
		"............................",
		"..........o....*.h.........o",
		".....##+###...####+#######+#",
		".......H....o.....H.......H.",
		".......H...###....H.......H.",
		"o...*..H..........H.o.....H.",
		"##+######.....##+####...#+##",
		"..H.............H.....o..H..",
		"..H.............H....###.H..",
		"..H.....h.o...o.H.......*H..",
		"#####+#####...######+#######",
		".....H......o.......H.......",
		".....H.....###......H.......",
		"o....H.............*H.h....o",
		"###+####...####+##########+#",
		"...H.....o.....H..........H.",
		"...H....##.....H..........H.",
		".P.H.......h*..H......*...H.",
		"############################",
	],
]

var mode := Mode.DEMO
var state := State.READY
var paused := false
var skin: ChuckieSkin
var best := 0
var start_lives := 5

var players: Array[Dictionary] = []   # score, lives, level, next_extra, eggs, grain (guardados)
var current := 0
var tiles := PackedByteArray()
var eggs := {}            # Vector2i -> true
var grain := {}
var hens: Array[Dictionary] = []      # x, y, move, dir, vdir, target_y, peck, anim
var lifts: Array[Dictionary] = []     # x (centro), y (topo)
var duck := {"pos": Vector2(16, 18), "vel": Vector2.ZERO, "free": false, "anim": 0.0}
var start_pos := Vector2.ZERO

var px := 0.0
var py := 0.0
var vx := 0.0
var vy := 0.0
var move := Move.WALK
var facing := 1
var on_lift := -1
var anim := 0.0
var time_left := TIME_START
var freeze := 0.0
var timer := 0.0
var level_time := 0.0
var bonus_left := 0

var _jump_buffer := 0.0
var _touch_stick: Variant = null      # origem do joystick tátil
var _touch_dir := Vector2.ZERO
var _touch_index := -1
var _touch_jump := false
var ai_cmd := {"x": 0, "y": 0, "jump": false}
var _ai_edge: Dictionary = {}
var _ai_timer := 0.0
var _demo_time := 0.0


func _init() -> void:
	_ensure_inputs()


static func _ensure_inputs() -> void:
	var defs := {
		"ce_left": [_key(KEY_A), _key(KEY_LEFT), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"ce_right": [_key(KEY_D), _key(KEY_RIGHT), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)],
		"ce_up": [_key(KEY_W), _key(KEY_UP), _joy_button(JOY_BUTTON_DPAD_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)],
		"ce_down": [_key(KEY_S), _key(KEY_DOWN), _joy_button(JOY_BUTTON_DPAD_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)],
		"ce_jump": [_key(KEY_SPACE), _key(KEY_Z), _key(KEY_J), _joy_button(JOY_BUTTON_A), _joy_button(JOY_BUTTON_B)],
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


# ---------------------------------------------------------------- consultas

func player() -> Dictionary:
	return players[current]


func level() -> int:
	return int(player().level)


func layout_index() -> int:
	return (level() - 1) % LEVELS.size()


func cycle() -> int:
	return (level() - 1) / LEVELS.size()


func level_name() -> String:
	return I18n.t(LEVEL_NAMES[layout_index()])


func tile(c: int, r: int) -> int:
	if c < 0 or c >= COLS or r < 0 or r >= ROWS:
		return T_EMPTY
	return tiles[r * COLS + c]


func is_floor(c: int, r: int) -> bool:
	var t := tile(c, r)
	return t == T_FLOOR or t == T_BOTH


func is_ladder(c: int, r: int) -> bool:
	var t := tile(c, r)
	return t == T_LADDER or t == T_BOTH


## Há chão debaixo dos pés (y tem de estar no topo de uma linha)?
func floor_under(x: float, y: float) -> bool:
	var r := roundi(y / TILE)
	if absf(y - r * TILE) > 0.01:
		return false
	return is_floor(floori((x - 2.5) / TILE), r) or is_floor(floori((x + 2.5) / TILE), r)


func lift_under(x: float, y: float) -> int:
	for i in lifts.size():
		var l: Dictionary = lifts[i]
		if absf(x - float(l.x)) <= 9.5 and absf(y - float(l.y)) < 0.75:
			return i
	return -1


func to_px(u: Vector2) -> Vector2:
	return ORIGIN + u * SCALE


func is_ai() -> bool:
	return mode == Mode.DEMO


func hen_speed() -> float:
	return HEN_V + layout_index() * 0.6 + cycle() * 5.0


func set_skin(new_skin: ChuckieSkin) -> void:
	if skin:
		skin.queue_free()
	skin = new_skin
	add_child(skin)
	skin.attach(self)


# ---------------------------------------------------------------- partida e níveis

func start(p_mode: Mode, lives := 5, first_level := 1) -> void:
	mode = p_mode
	start_lives = lives
	paused = false
	players.clear()
	for i in (2 if mode == Mode.TWO else 1):
		players.append({"score": 0, "lives": lives, "level": first_level, "next_extra": EXTRA_LIFE_EVERY, "eggs": null, "grain": null})
	current = 0
	_demo_time = 0.0
	match_started.emit()
	_begin_turn()


func _begin_turn() -> void:
	_load_level()
	turn_started.emit(current)
	level_started.emit(level())


func _load_level() -> void:
	var rows: Array = LEVELS[layout_index()]
	tiles.resize(COLS * ROWS)
	hens.clear()
	lifts.clear()
	var fresh_eggs := {}
	var fresh_grain := {}
	for r in ROWS:
		var row: String = rows[r]
		for c in COLS:
			var ch := row[c]
			var t := T_EMPTY
			match ch:
				"#":
					t = T_FLOOR
				"H":
					t = T_LADDER
				"+":
					t = T_BOTH
				"o":
					fresh_eggs[Vector2i(c, r)] = true
				"*":
					fresh_grain[Vector2i(c, r)] = true
				"h":
					hens.append({"x": c * TILE + 4.0, "y": (r + 1) * TILE, "move": Move.WALK, "dir": 1 if c < COLS / 2 else -1,
						"vdir": 0, "target_y": 0.0, "peck": 0.0, "anim": randf()})
				"P":
					start_pos = Vector2(c * TILE + 4.0, (r + 1) * TILE)
				"L":
					for k in 2:
						lifts.append({"x": (c + 1) * TILE, "y": FIELD.y * (0.35 + 0.5 * k)})
			tiles[r * COLS + c] = t
	# mais galinhas nos ciclos mais avançados (aparecem nas casas livres do topo)
	if cycle() >= 2:
		for c in range(COLS - 2, 0, -1):
			if floor_under(c * TILE + 4.0, 4 * TILE):
				hens.append({"x": c * TILE + 4.0, "y": 4 * TILE, "move": Move.WALK, "dir": -1, "vdir": 0, "target_y": 0.0, "peck": 0.0, "anim": 0.0})
				break
	var p := player()
	if p.eggs == null:
		p.eggs = fresh_eggs
		p.grain = fresh_grain
	eggs = p.eggs
	grain = p.grain
	_reset_life()


func _reset_life() -> void:
	px = start_pos.x
	py = start_pos.y
	vx = 0.0
	vy = 0.0
	move = Move.WALK
	facing = 1
	on_lift = -1
	time_left = TIME_START
	freeze = 0.0
	level_time = 0.0
	duck = {"pos": Vector2(16, 18), "vel": Vector2.ZERO, "free": cycle() >= 1, "anim": 0.0}
	_ai_edge = {}
	ai_cmd = {"x": 0, "y": 0, "jump": false}
	state = State.READY
	timer = 1.6 if mode != Mode.DEMO else 0.6


# ---------------------------------------------------------------- ciclo

func _process(delta: float) -> void:
	if paused:
		return
	delta = minf(delta, 0.1)
	if mode == Mode.DEMO:
		_demo_time += delta
	var steps := maxi(1, ceili(delta * 240.0))
	var dt := delta / steps
	if mode == Mode.DEMO and state == State.PLAY:
		_ai_think(delta)
	for i in steps:
		_step(dt)


func _step(dt: float) -> void:
	_jump_buffer = maxf(_jump_buffer - dt, 0.0)
	duck.anim += dt
	match state:
		State.READY:
			timer -= dt
			_move_lifts(dt)
			if timer <= 0.0:
				state = State.PLAY
		State.PLAY:
			level_time += dt
			_move_lifts(dt)
			_move_player(dt)
			if state != State.PLAY:
				return
			for h in hens:
				_move_hen(h, dt)
			_move_duck(dt)
			_check_hits()
			if freeze > 0.0:
				freeze -= dt
			else:
				time_left -= TIME_RATE * dt
				if time_left <= 0.0:
					time_left = 0.0
					_die()
			if mode == Mode.DEMO and _demo_time > 100.0 and state == State.PLAY:
				_die()
		State.DYING:
			timer -= dt
			if timer <= 0.0:
				_after_death()
		State.CLEAR:
			timer -= dt
			# o tempo restante passa para os pontos
			if bonus_left > 0:
				var k := mini(bonus_left, maxi(1, int(2000.0 * dt)))
				bonus_left -= k
				_add_points(k)
				time_left = float(bonus_left) / (cycle() + 1)
			elif timer <= 0.0:
				player().level += 1
				player().eggs = null
				player().grain = null
				_load_level()
				level_started.emit(level())
		State.OVER:
			if mode == Mode.DEMO:
				timer -= dt
				if timer <= 0.0:
					start_demo()


func start_demo() -> void:
	start(Mode.DEMO, 3, DEMO_LEVELS[randi() % DEMO_LEVELS.size()])


func _add_points(n: int) -> void:
	if n <= 0:
		return
	var p := player()
	p.score += n
	if p.score >= p.next_extra:
		p.next_extra += EXTRA_LIFE_EVERY
		p.lives += 1
		extra_life.emit()


# ---------------------------------------------------------------- jogador

func _input_vec() -> Dictionary:
	if is_ai():
		return ai_cmd
	var x := 0
	var y := 0
	if Input.is_action_pressed("ce_left"):
		x -= 1
	if Input.is_action_pressed("ce_right"):
		x += 1
	if Input.is_action_pressed("ce_up"):
		y -= 1
	if Input.is_action_pressed("ce_down"):
		y += 1
	if _touch_stick != null:
		if absf(_touch_dir.x) > 22.0 and absf(_touch_dir.x) > absf(_touch_dir.y) * 0.6:
			x = signi(int(_touch_dir.x))
		if absf(_touch_dir.y) > 22.0 and absf(_touch_dir.y) > absf(_touch_dir.x) * 0.6:
			y = signi(int(_touch_dir.y))
	return {"x": x, "y": y, "jump": _jump_buffer > 0.0}


func _move_player(dt: float) -> void:
	var inp := _input_vec()
	var ix: int = inp.x
	var iy: int = inp.y
	var want_jump: bool = inp.jump
	if is_ai():
		ai_cmd.jump = false
	match move:
		Move.WALK:
			if on_lift >= 0:
				py = lifts[on_lift].y
				if py - 15.0 < 0.0:
					_die()
					return
			if want_jump:
				_jump_buffer = 0.0
				move = Move.AIR
				vy = -JUMP_V
				vx = ix * WALK_V
				if ix != 0:
					facing = ix
				on_lift = -1
				jumped.emit()
				return
			if iy != 0 and _try_climb(iy):
				return
			if ix != 0:
				facing = ix
				px = clampf(px + ix * WALK_V * dt, 4.0, FIELD.x - 4.0)
				anim += dt
			if on_lift >= 0:
				if lift_under(px, py) != on_lift:
					on_lift = -1
					move = Move.AIR
					vx = 0.0
					vy = 0.0
			elif not floor_under(px, py):
				var l := lift_under(px, py)
				if l >= 0:
					on_lift = l
				else:
					move = Move.AIR
					vx = 0.0
					vy = 0.0
		Move.AIR:
			if iy != 0 and _try_grab(iy):
				return
			vy = minf(vy + GRAVITY * dt, FALL_MAX)
			var ny := py + vy * dt
			px += vx * dt
			if px < 4.0 or px > FIELD.x - 4.0:
				px = clampf(px, 4.0, FIELD.x - 4.0)
				vx = 0.0
			if vy > 0.0:
				var r_old := floori(py / TILE)
				var r_new := floori(ny / TILE)
				if r_new > r_old and floor_under(px, r_new * TILE):
					py = r_new * TILE
					_land()
					return
				for i in lifts.size():
					var l: Dictionary = lifts[i]
					if absf(px - float(l.x)) <= 9.5 and py <= float(l.y) + 0.6 and ny >= float(l.y):
						py = l.y
						on_lift = i
						_land()
						return
			py = ny
			if py > FIELD.y + 24.0:
				_die()
		Move.CLIMB:
			var col := floori(px / TILE)
			if ix != 0:
				var b := roundf(py / TILE) * TILE
				if absf(py - b) < 2.6 and (floor_under(px, b) or floor_under(px + ix * 5.0, b)):
					py = b
					move = Move.WALK
					climbing.emit(false)
					facing = ix
					return
			if iy != 0:
				var ny := py + iy * CLIMB_V * dt
				if is_ladder(col, floori(ny / TILE)):
					py = ny
				elif iy < 0:
					py = (floori(ny / TILE) + 1) * TILE
				else:
					py = floori(ny / TILE) * TILE
				anim += dt
	_collect()


func _land() -> void:
	move = Move.WALK
	vx = 0.0
	vy = 0.0
	landed.emit()


func _try_climb(iy: int) -> bool:
	var col := floori(px / TILE)
	var cx := col * TILE + 4.0
	if absf(px - cx) > 3.5:
		return false
	var ok := is_ladder(col, floori((py - 1.0) / TILE)) if iy < 0 else is_ladder(col, floori((py + 1.0) / TILE))
	if not ok:
		return false
	px = cx
	move = Move.CLIMB
	on_lift = -1
	climbing.emit(true)
	return true


## Agarrar uma escada no ar (a meio de um salto ou de uma queda).
func _try_grab(_iy: int) -> bool:
	var col := floori(px / TILE)
	var cx := col * TILE + 4.0
	if absf(px - cx) > 2.5 or not is_ladder(col, floori((py - 4.0) / TILE)):
		return false
	px = cx
	move = Move.CLIMB
	vx = 0.0
	vy = 0.0
	climbing.emit(true)
	return true


func _collect() -> void:
	var c0 := floori((px - 3.0) / TILE)
	var c1 := floori((px + 3.0) / TILE)
	var r0 := floori((py - 14.0) / TILE)
	var r1 := floori((py - 1.0) / TILE)
	for r in range(r0, r1 + 1):
		for c in range(c0, c1 + 1):
			var cell := Vector2i(c, r)
			if eggs.has(cell):
				eggs.erase(cell)
				_add_points(EGG_POINTS)
				egg_taken.emit(Vector2(c * TILE + 4, r * TILE + 4))
				if eggs.is_empty():
					state = State.CLEAR
					timer = 1.2
					bonus_left = int(time_left) * (cycle() + 1)
					level_cleared.emit(bonus_left)
					return
			elif grain.has(cell):
				grain.erase(cell)
				_add_points(GRAIN_POINTS)
				freeze = GRAIN_FREEZE
				grain_taken.emit(Vector2(c * TILE + 4, r * TILE + 4), false)


func _check_hits() -> void:
	for h in hens:
		if absf(float(h.x) - px) < 5.5 and absf((float(h.y) - 6.0) - (py - 7.0)) < 11.0:
			_die()
			return
	if duck.free and (duck.pos as Vector2).distance_to(Vector2(px, py - 8.0)) < 9.0:
		_die()


func _die() -> void:
	if state != State.PLAY:
		return
	state = State.DYING
	timer = 2.0
	player_died.emit(Vector2(px, py - 8.0))


func _after_death() -> void:
	var p := player()
	p.lives -= 1
	if mode == Mode.TWO and players[1 - current].lives > 0:
		current = 1 - current
		_begin_turn()
		return
	if p.lives <= 0:
		state = State.OVER
		timer = 3.0
		var top := 0
		for pl in players:
			top = maxi(top, int(pl.score))
		if mode != Mode.DEMO:
			best = maxi(best, top)
		game_over.emit()
		return
	_reset_life()


# ---------------------------------------------------------------- elevadores, galinhas e pato

func _move_lifts(dt: float) -> void:
	for l in lifts:
		l.y -= LIFT_V * dt
		if l.y < 0.0:
			l.y += FIELD.y + 10.0


func _move_hen(h: Dictionary, dt: float) -> void:
	h.anim += dt
	if h.peck > 0.0:
		h.peck -= dt
		return
	var d := hen_speed() * dt
	if h.move == Move.WALK:
		var col := floori(float(h.x) / TILE)
		var cx := col * TILE + 4.0
		var nx: float = h.x + h.dir * d
		if (float(h.x) - cx) * h.dir < 0.0 and (nx - cx) * h.dir >= 0.0:
			h.x = cx
			_hen_decide(h, col)
		else:
			h.x = nx
	else:
		var ny: float = h.y + h.vdir * d
		if (ny - float(h.target_y)) * h.vdir >= 0.0:
			h.y = h.target_y
			h.move = Move.WALK
			var col := floori(float(h.x) / TILE)
			var sides: Array[int] = []
			for s: int in [-1, 1]:
				if floor_under(h.x + s * TILE, h.y):
					sides.append(s)
			h.dir = sides[randi() % sides.size()] if not sides.is_empty() else 1
			_hen_eat(h, col)
		else:
			h.y = ny


func _hen_decide(h: Dictionary, col: int) -> void:
	_hen_eat(h, col)
	var y: float = h.y
	var ahead: bool = floor_under(col * TILE + 4.0 + h.dir * TILE, y) and col + h.dir >= 0 and col + h.dir < COLS
	var up := is_ladder(col, floori((y - 1.0) / TILE))
	var down := is_ladder(col, floori((y + 1.0) / TILE))
	var r := randf()
	if up and r < 0.35:
		_hen_climb(h, col, -1)
	elif down and (r > 0.65 or (not ahead and not up)):
		_hen_climb(h, col, 1)
	elif up and not ahead and r < 0.7:
		_hen_climb(h, col, -1)
	elif not ahead:
		h.dir = -h.dir


func _hen_climb(h: Dictionary, col: int, vdir: int) -> void:
	h.move = Move.CLIMB
	h.vdir = vdir
	var y: float = h.y
	if vdir < 0:
		var row := floori((y - 1.0) / TILE)
		while is_ladder(col, row - 1):
			row -= 1
		h.target_y = row * TILE
	else:
		var row := floori((y + 1.0) / TILE)
		while is_ladder(col, row + 1):
			row += 1
		h.target_y = (row + 1) * TILE


func _hen_eat(h: Dictionary, col: int) -> void:
	var cell := Vector2i(col, floori((float(h.y) - 1.0) / TILE))
	if grain.has(cell):
		grain.erase(cell)
		h.peck = 1.2
		grain_taken.emit(Vector2(cell.x * TILE + 4, cell.y * TILE + 4), true)


func _move_duck(dt: float) -> void:
	if not duck.free:
		return
	var target := Vector2(px, py - 8.0)
	var pos: Vector2 = duck.pos
	var vel: Vector2 = duck.vel
	vel += (target - pos).normalized() * 30.0 * dt
	var vmax := 20.0 + cycle() * 3.0
	if vel.length() > vmax:
		vel = vel.normalized() * vmax
	duck.vel = vel
	duck.pos = pos + vel * dt


# ---------------------------------------------------------------- entrada

func _unhandled_input(event: InputEvent) -> void:
	if paused or is_ai():
		return
	if event.is_action_pressed("ce_jump"):
		_jump_buffer = 0.12
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	# Tátil: metade esquerda = joystick (arrastar), metade direita = saltar.
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < 640.0:
				_touch_stick = event.position
				_touch_dir = Vector2.ZERO
				_touch_index = event.index
			else:
				_jump_buffer = 0.12
				_touch_jump = true
		else:
			if event.index == _touch_index:
				_touch_stick = null
				_touch_dir = Vector2.ZERO
				_touch_index = -1
			else:
				_touch_jump = false
	elif event is InputEventScreenDrag and event.index == _touch_index and _touch_stick != null:
		_touch_dir = event.position - (_touch_stick as Vector2)


func clear_input() -> void:
	_touch_stick = null
	_touch_dir = Vector2.ZERO
	_touch_index = -1
	_touch_jump = false
	_jump_buffer = 0.0


func touch_stick() -> Variant:
	return _touch_stick


# ---------------------------------------------------------------- CPU da demonstração

## Nós = casas onde se pode estar de pé; arestas = andar, escada, cair de uma borda ou saltar.
func _ai_node_ok(c: int, r: int) -> bool:
	return c >= 0 and c < COLS and floor_under(c * TILE + 4.0, r * TILE) and not is_floor(c, r - 1) and not is_floor(c, r - 2)


func _ai_edges(c: int, r: int) -> Array:
	var out := []
	var cx := c * TILE + 4.0
	var y := r * TILE
	for s: int in [-1, 1]:
		if _ai_node_ok(c + s, r):
			out.append({"kind": "walk", "to": Vector2i(c + s, r), "cost": 1.0})
		elif c + s >= 0 and c + s < COLS and not is_floor(c + s, r):
			# cair da borda: a queda é a direito, na coluna ao lado
			var fx := cx + s * 6.6
			var rr := r + 1
			while rr < ROWS and not floor_under(fx, rr * TILE):
				rr += 1
			if rr < ROWS and _ai_node_ok(floori(fx / TILE), rr):
				out.append({"kind": "drop", "to": Vector2i(floori(fx / TILE), rr), "dir": s, "cost": 2.0 + (rr - r) * 0.2})
		var land: Variant = _simulate_jump(cx, y, s)
		if land != null:
			var lc := Vector2i(floori((land as Vector2).x / TILE), roundi((land as Vector2).y / TILE))
			if lc != Vector2i(c, r) and _ai_node_ok(lc.x, lc.y) and absf((land as Vector2).x - (lc.x * TILE + 4.0)) < 3.4:
				out.append({"kind": "jump", "to": lc, "dir": s, "cost": 3.0})
	if is_ladder(c, floori((y - 1.0) / TILE)):
		var row := floori((y - 1.0) / TILE)
		while is_ladder(c, row - 1):
			row -= 1
		out.append({"kind": "ladder", "to": Vector2i(c, row), "dir": -1, "cost": 2.0})
	if is_ladder(c, floori((y + 1.0) / TILE)):
		var row := floori((y + 1.0) / TILE)
		while is_ladder(c, row + 1):
			row += 1
		out.append({"kind": "ladder", "to": Vector2i(c, row + 1), "dir": 1, "cost": 2.0})
	return out


## Onde aterra um salto a partir de (x, y) na direção s (null se cair para fora).
func _simulate_jump(x: float, y: float, s: int) -> Variant:
	var sx := x
	var sy := y
	var svy := -JUMP_V
	var dt := 1.0 / 240.0
	for i in 600:
		svy = minf(svy + GRAVITY * dt, FALL_MAX)
		var ny := sy + svy * dt
		sx = clampf(sx + s * WALK_V * dt, 4.0, FIELD.x - 4.0)
		if svy > 0.0:
			var r_old := floori(sy / TILE)
			var r_new := floori(ny / TILE)
			if r_new > r_old and floor_under(sx, r_new * TILE):
				return Vector2(sx, r_new * TILE)
		sy = ny
		if sy > FIELD.y:
			return null
	return null


func ai_plan_from(start: Vector2i) -> Dictionary:
	# Dijkstra simples (poucos nós)
	var dist := {start: 0.0}
	var prev := {}
	var open: Array[Vector2i] = [start]
	while not open.is_empty():
		var best_i := 0
		for i in open.size():
			if dist[open[i]] < dist[open[best_i]]:
				best_i = i
		var n: Vector2i = open[best_i]
		open.remove_at(best_i)
		for e: Dictionary in _ai_edges(n.x, n.y):
			var to: Vector2i = e.to
			var nd: float = dist[n] + float(e.cost)
			if not dist.has(to) or nd < dist[to]:
				dist[to] = nd
				prev[to] = [n, e]
				open.append(to)
	return {"dist": dist, "prev": prev}


func _ai_think(delta: float) -> void:
	ai_cmd.x = 0
	ai_cmd.y = 0
	if not _ai_edge.is_empty():
		_ai_edge.age += delta
		if _ai_edge.age > 4.0:
			_ai_edge = {}
	if move == Move.AIR:
		return
	var here := Vector2i(floori(px / TILE), roundi(py / TILE))
	var centered := absf(px - (here.x * TILE + 4.0)) < 1.0 and absf(py - here.y * TILE) < 0.5
	if not _ai_edge.is_empty():
		_ai_follow()
		return
	if move == Move.CLIMB:
		# acabou uma escada: sai para o lado
		ai_cmd.x = 1 if floor_under(px + 5.0, roundf(py / TILE) * TILE) else -1
		return
	if not centered:
		ai_cmd.x = signi(int(roundf((here.x * TILE + 4.0 - px) * 10.0)))
		return
	var plan := ai_plan_from(here)
	var dist: Dictionary = plan.dist
	var target := Vector2i(-1, -1)
	var best_d := INF
	for cell: Vector2i in eggs:
		var node := Vector2i(cell.x, cell.y + 1)
		if dist.has(node) and float(dist[node]) < best_d:
			best_d = dist[node]
			target = node
	if target.x < 0:
		for cell: Vector2i in grain:
			var node := Vector2i(cell.x, cell.y + 1)
			if dist.has(node) and float(dist[node]) < best_d:
				best_d = dist[node]
				target = node
	if target.x < 0 or target == here:
		return
	# primeiro passo do caminho
	var step := target
	var prev: Dictionary = plan.prev
	while prev.has(step) and prev[step][0] != here:
		step = prev[step][0]
	if not prev.has(step):
		return
	var edge: Dictionary = prev[step][1]
	# evita galinhas: espera se a próxima casa estiver ameaçada
	if _ai_danger(edge):
		_ai_timer += delta
		if _ai_timer < 1.5:
			return
	_ai_timer = 0.0
	_ai_edge = edge.duplicate()
	_ai_edge.from = here
	_ai_edge.started = false
	_ai_edge.age = 0.0
	_ai_follow()


func _ai_danger(edge: Dictionary) -> bool:
	var to: Vector2i = edge.to
	var tp := Vector2(to.x * TILE + 4.0, to.y * TILE)
	for h in hens:
		var hp := Vector2(h.x, h.y)
		if hp.distance_to(tp) < 22.0 or hp.distance_to(Vector2(px, py)) < 16.0:
			return true
	if duck.free and (duck.pos as Vector2).distance_to(tp) < 20.0:
		return true
	return false


func _ai_follow() -> void:
	var e := _ai_edge
	var to: Vector2i = e.to
	var tx := to.x * TILE + 4.0
	var ty := to.y * TILE
	match e.kind:
		"walk":
			if absf(px - tx) < 0.8:
				_ai_edge = {}
			else:
				ai_cmd.x = 1 if tx > px else -1
		"drop":
			if move == Move.WALK and e.started and absf(py - ty) < 0.5:
				_ai_edge = {}
			else:
				e.started = true
				ai_cmd.x = e.dir
		"ladder":
			if move == Move.CLIMB and absf(py - ty) < 0.3:
				_ai_edge = {}
				ai_cmd.x = 1 if floor_under(px + 5.0, ty) else -1
			else:
				ai_cmd.y = e.dir
		"jump":
			if not e.started:
				e.started = true
				ai_cmd.jump = true
				ai_cmd.x = e.dir
			elif move == Move.WALK:
				_ai_edge = {}
