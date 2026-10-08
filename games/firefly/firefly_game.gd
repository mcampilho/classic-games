class_name FireflyGame
extends Node2D
## Lógica do Pirilampo: um jogo original de perseguição em labirinto, ao estilo dos arcades de 1980.
## Um pirilampo recolhe pontos de luz num jardim-labirinto, perseguido por 4 morcegos.
## As flores de luz fazem-no brilhar: os morcegos ficam encandeados, fogem, e podem ser apanhados.
##
## Regras:
##  - pontos de luz 10, flores 50; morcegos encandeados 200, 400, 800, 1600 (em sequência)
##  - cada morcego tem a sua maneira de caçar: o Caçador vai direito a ti, o Emboscador
##    tenta pôr-se à tua frente, o Cercador fecha-te pelo lado oposto ao Caçador e o Errante
##    aproxima-se mas foge quando fica perto
##  - os morcegos alternam entre "dispersar" (cada um para o seu canto) e "caçar"
##  - túneis nas laterais (os morcegos abrandam lá dentro); bónus do jardim 2x por nível
##  - vida extra aos 10 000 pontos

signal match_started
signal turn_started(player: int)
signal pellet_eaten(tile: Vector2i, power: bool)
signal bat_eaten(pos: Vector2, points: int)
signal power_started
signal power_ending
signal bonus_spawned
signal bonus_eaten(pos: Vector2, points: int)
signal player_hit(pos: Vector2)
signal extra_life
signal level_cleared
signal game_over

enum Mode { DEMO, ONE, TWO }
enum State { READY, PLAY, DYING, CLEARED, OVER }
enum Bat { CAVE, LEAVING, ACTIVE, EATEN }

const MAZE := [
	"###########################",
	"#o..#...#.........#...#..o#",
	"#.#.#.#.#.#.###.#.#.#.#.#.#",
	"#.....#...#.....#...#.....#",
	"#####.###############.#####",
	"#...#.#.............#.#...#",
	"#.#.#.#.#####.#####.#.#.#.#",
	"#.#...#..         ..#...#.#",
	"#.#######.###-###.#######.#",
	"      ....#CCCCC#....      ",
	"#########.#CCCCC#.#########",
	"#.......#.#CCCCC#.#.......#",
	"#.#####.#.#######.#.#####.#",
	"#.#...#.............#...#.#",
	"#.#.#.#######.#######.#.#.#",
	"#...#........ ........#...#",
	"###.###################.###",
	"#...#.....#.....#.....#...#",
	"#.###.#.#.#.###.#.#.#.###.#",
	"#o....#.............#....o#",
	"###########################",
]
const W := 27
const H := 21
const TILE := 30.0
const ORIGIN := Vector2(235, 75)          # canto do labirinto no ecrã 1280x720
const TUNNEL_ROW := 9
const DOOR := Vector2i(13, 8)
const CAVE_EXIT := Vector2i(13, 7)
const CAVE_CENTER := Vector2i(13, 10)
const START := Vector2i(13, 15)
const BONUS_TILE := Vector2i(13, 15)
const DIRS := [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]
const BAT_NAMES := ["Caçador", "Emboscador", "Cercador", "Errante"]
const BAT_START := [Vector2i(13, 7), Vector2i(13, 10), Vector2i(12, 10), Vector2i(14, 10)]
const BAT_CORNER := [Vector2i(25, -2), Vector2i(1, -2), Vector2i(26, 22), Vector2i(0, 22)]
const BAT_RELEASE := [0.0, 2.0, 5.0, 8.0]
const SCHEDULE := [7.0, 20.0, 7.0, 20.0, 5.0, 20.0, 5.0]      # dispersar / caçar alternados; depois sempre caçar
const BONUS_POINTS := [100, 300, 500, 700, 1000, 2000, 3000, 5000]
const EXTRA_LIFE_AT := 10000

var mode := Mode.DEMO
var start_lives := 3
var state := State.READY
var paused := false
var skin: FireflySkin
var best := 0

var players: Array[Dictionary] = []       # score, lives, level, extra, pellets (guardados)
var current := 0
var pellets := PackedByteArray()          # 0 nada, 1 ponto, 2 flor
var pellets_total := 0
var pellets_eaten := 0

var player_pos := Vector2(START)
var player_tile := START
var player_dir := Vector2i.LEFT
var player_face := Vector2i.LEFT
var _wanted := Vector2i.LEFT
var bats: Array[Dictionary] = []          # id, state, pos, tile, dir, fright, release, flash
var fright_time := 0.0
var fright_chain := 0
var bonus: Variant = null                 # {kind, time}
var bonus_count := 0
var timer := 0.0
var mode_index := 0
var mode_timer := 0.0
var chasing := false

var _touch_start: Variant = null
var _ai_t := 0.0


func _init() -> void:
	_ensure_inputs()


static func _ensure_inputs() -> void:
	var defs := {
		"ff_up": [_key(KEY_W), _key(KEY_UP), _joy_button(JOY_BUTTON_DPAD_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)],
		"ff_down": [_key(KEY_S), _key(KEY_DOWN), _joy_button(JOY_BUTTON_DPAD_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)],
		"ff_left": [_key(KEY_A), _key(KEY_LEFT), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"ff_right": [_key(KEY_D), _key(KEY_RIGHT), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)],
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


# ---------------------------------------------------------------- labirinto

static func cell(t: Vector2i) -> String:
	if t.y < 0 or t.y >= H:
		return "#"
	if t.x < 0 or t.x >= W:
		return " " if t.y == TUNNEL_ROW else "#"
	return MAZE[t.y][t.x]


static func is_wall(t: Vector2i) -> bool:
	return cell(t) == "#"


## O jogador só anda nos corredores; os morcegos também podem usar a porta e a gruta.
static func passable(t: Vector2i, bat_door := false) -> bool:
	var c := cell(t)
	if c == "#":
		return false
	if c == "-" or c == "C":
		return bat_door
	return true


func to_px(tile_pos: Vector2) -> Vector2:
	return ORIGIN + (tile_pos + Vector2(0.5, 0.5)) * TILE


func player() -> Dictionary:
	return players[current]


func level() -> int:
	return player().level


func is_ai() -> bool:
	return mode == Mode.DEMO


func _full_pellets() -> PackedByteArray:
	var p := PackedByteArray()
	p.resize(W * H)
	for y in H:
		for x in W:
			var c: String = MAZE[y][x]
			p[y * W + x] = 1 if c == "." else (2 if c == "o" else 0)
	return p


# ---------------------------------------------------------------- partida

func start(p_mode: Mode, lives := 3) -> void:
	mode = p_mode
	start_lives = lives
	paused = false
	reset_match()


func reset_match() -> void:
	players.clear()
	for i in (2 if mode == Mode.TWO else 1):
		players.append({"score": 0, "lives": start_lives, "level": 1, "extra": false, "pellets": null})
	current = 0
	_load_level()
	_reset_turn()
	match_started.emit()
	turn_started.emit(0)


func set_skin(new_skin: FireflySkin) -> void:
	if skin:
		skin.queue_free()
	skin = new_skin
	add_child(skin)
	skin.attach(self)


func _load_level() -> void:
	var saved: Variant = player().pellets
	pellets = saved if saved != null else _full_pellets()
	pellets_total = _full_pellets().count(1) + _full_pellets().count(2)
	pellets_eaten = pellets_total - (pellets.count(1) + pellets.count(2))
	bonus_count = 0 if pellets_eaten < 70 else (1 if pellets_eaten < 170 else 2)


func _reset_turn() -> void:
	player_tile = START
	player_pos = Vector2(START)
	player_dir = Vector2i.LEFT
	player_face = Vector2i.LEFT
	_wanted = Vector2i.LEFT
	bats.clear()
	for i in 4:
		bats.append({"id": i, "state": Bat.ACTIVE if i == 0 else Bat.CAVE, "tile": BAT_START[i], "pos": Vector2(BAT_START[i]),
			"dir": Vector2i.LEFT if i == 0 else Vector2i.UP, "fright": false, "release": BAT_RELEASE[i] * maxf(0.4, 1.0 - (level() - 1) * 0.15),
			"wander_t": 0.0})
	fright_time = 0.0
	bonus = null
	mode_index = 0
	mode_timer = SCHEDULE[0]
	chasing = false
	_touch_start = null
	state = State.READY
	timer = 2.0


# ---------------------------------------------------------------- velocidades

func player_speed() -> float:
	var base := minf(6.0 + (level() - 1) * 0.25, 7.2)
	return base * (1.12 if fright_time > 0.0 else 1.0)


func bat_speed(b: Dictionary) -> float:
	if b.state == Bat.EATEN:
		return 12.0
	if b.state != Bat.ACTIVE:
		return 3.5
	var t: Vector2i = b.tile
	if t.y == TUNNEL_ROW and (t.x <= 5 or t.x >= W - 6):
		return 3.0
	if b.fright:
		return 3.2
	var base := minf(5.4 + (level() - 1) * 0.3, 6.9)
	# o Caçador acelera quando restam poucos pontos
	if b.id == 0 and pellets_total - pellets_eaten < 30:
		base += 0.5
	return base


func fright_duration() -> float:
	return maxf(1.2, 6.5 - (level() - 1) * 0.8)


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
			timer -= dt
			if timer <= 0.0:
				state = State.PLAY
		State.PLAY:
			_read_input()
			_move_player(dt)
			if state != State.PLAY:
				return
			_update_modes(dt)
			_move_bats(dt)
			_check_collisions()
			_update_bonus(dt)
		State.DYING:
			timer -= dt
			if timer <= 0.0:
				_after_death()
		State.CLEARED:
			timer -= dt
			if timer <= 0.0:
				player().level += 1
				player().pellets = null
				_load_level()
				_reset_turn()
				turn_started.emit(current)
		State.OVER:
			if mode == Mode.DEMO:
				timer -= dt
				if timer <= 0.0:
					reset_match()


func _update_modes(dt: float) -> void:
	if fright_time > 0.0:
		var before := fright_time
		fright_time -= dt
		if before > 2.0 and fright_time <= 2.0:
			power_ending.emit()
		if fright_time <= 0.0:
			fright_time = 0.0
			for b in bats:
				b.fright = false
		return   # o relógio de dispersar/caçar pára durante o encandeamento
	if mode_index < SCHEDULE.size():
		mode_timer -= dt
		if mode_timer <= 0.0:
			mode_index += 1
			chasing = not chasing
			mode_timer = SCHEDULE[mode_index] if mode_index < SCHEDULE.size() else INF
			for b in bats:
				if b.state == Bat.ACTIVE:
					_reverse(b)        # mudança de modo: todos dão meia-volta


# ---------------------------------------------------------------- jogador

func _read_input() -> void:
	if is_ai():
		return
	if Input.is_action_pressed("ff_up"):
		_wanted = Vector2i.UP
	elif Input.is_action_pressed("ff_down"):
		_wanted = Vector2i.DOWN
	elif Input.is_action_pressed("ff_left"):
		_wanted = Vector2i.LEFT
	elif Input.is_action_pressed("ff_right"):
		_wanted = Vector2i.RIGHT


func _unhandled_input(event: InputEvent) -> void:
	if paused or is_ai():
		return
	var emulated := event.device == InputEvent.DEVICE_ID_EMULATION
	if emulated:
		return
	# Toque: deslizar o dedo na direção pretendida (em qualquer sítio do ecrã).
	if event is InputEventScreenTouch:
		_touch_start = event.position if event.pressed else null
	elif event is InputEventScreenDrag and _touch_start != null:
		var d: Vector2 = event.position - _touch_start
		if d.length() > 24.0:
			_wanted = _vec_to_dir(d)
			_touch_start = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Rato: clicar num ponto do ecrã escolhe a direção a partir do pirilampo.
		_wanted = _vec_to_dir(event.position - to_px(player_pos))


static func _vec_to_dir(d: Vector2) -> Vector2i:
	if absf(d.x) > absf(d.y):
		return Vector2i.RIGHT if d.x > 0.0 else Vector2i.LEFT
	return Vector2i.DOWN if d.y > 0.0 else Vector2i.UP


func _move_player(dt: float) -> void:
	if is_ai():
		_ai(dt)
	# meia-volta imediata a meio de um corredor
	if player_dir != Vector2i.ZERO and _wanted == -player_dir:
		player_tile += player_dir
		player_dir = _wanted
	if player_dir == Vector2i.ZERO and passable(player_tile + _wanted):
		player_dir = _wanted
	if player_dir != Vector2i.ZERO:
		player_face = player_dir
	var remaining := player_speed() * dt
	while remaining > 0.0 and player_dir != Vector2i.ZERO:
		var target := Vector2(player_tile + player_dir)
		var d := player_pos.distance_to(target)
		if d > remaining:
			player_pos += (target - player_pos).normalized() * remaining
			remaining = 0.0
		else:
			player_pos = target
			remaining -= d
			player_tile += player_dir
			_wrap_player()
			_eat()
			if state != State.PLAY:
				return
			if passable(player_tile + _wanted):
				player_dir = _wanted
			elif not passable(player_tile + player_dir):
				player_dir = Vector2i.ZERO


func _wrap_player() -> void:
	if player_tile.x < 0:
		player_tile.x = W - 1
		player_pos.x = W - 1
	elif player_tile.x >= W:
		player_tile.x = 0
		player_pos.x = 0


func _eat() -> void:
	if player_tile.x < 0 or player_tile.x >= W:
		return
	var i := player_tile.y * W + player_tile.x
	var p := pellets[i]
	if p == 0:
		return
	pellets[i] = 0
	pellets_eaten += 1
	_add_score(10 if p == 1 else 50)
	pellet_eaten.emit(player_tile, p == 2)
	if p == 2:
		fright_time = fright_duration()
		fright_chain = 0
		for b in bats:
			if b.state == Bat.ACTIVE:
				b.fright = true
				_reverse(b)
		power_started.emit()
	if (pellets_eaten == 70 or pellets_eaten == 170) and bonus == null:
		bonus = {"kind": mini(level() - 1, BONUS_POINTS.size() - 1), "time": 9.5}
		bonus_count += 1
		bonus_spawned.emit()
	if pellets_eaten >= pellets_total:
		state = State.CLEARED
		timer = 2.4
		bonus = null
		level_cleared.emit()


func _add_score(pts: int) -> void:
	var p := player()
	p.score += pts
	if not p.extra and p.score >= EXTRA_LIFE_AT:
		p.extra = true
		p.lives += 1
		extra_life.emit()


func _update_bonus(dt: float) -> void:
	if bonus == null:
		return
	bonus.time -= dt
	if bonus.time <= 0.0:
		bonus = null
	elif player_pos.distance_to(Vector2(BONUS_TILE)) < 0.6:
		var pts: int = BONUS_POINTS[bonus.kind]
		bonus = null
		_add_score(pts)
		bonus_eaten.emit(to_px(Vector2(BONUS_TILE)), pts)


# ---------------------------------------------------------------- morcegos

func _move_bats(dt: float) -> void:
	for b in bats:
		match b.state:
			Bat.CAVE:
				b.release -= dt
				# esvoaça para cima e para baixo dentro da gruta
				b.pos.y = BAT_START[b.id].y + sin(Time.get_ticks_msec() / 250.0 + b.id) * 0.3
				if b.release <= 0.0:
					b.state = Bat.LEAVING
					b.pos = Vector2(BAT_START[b.id])
					b.tile = BAT_START[b.id]
					b.dir = Vector2i.ZERO
			_:
				_advance_bat(b, bat_speed(b) * dt)


func _advance_bat(b: Dictionary, dist: float) -> void:
	var remaining := dist
	var guard := 0
	while remaining > 0.0 and guard < 8:
		guard += 1
		if b.dir == Vector2i.ZERO:
			_choose_dir(b)
			if b.dir == Vector2i.ZERO:
				return
		var target := Vector2(b.tile + b.dir)
		var d: float = b.pos.distance_to(target)
		if d > remaining:
			b.pos += (target - b.pos).normalized() * remaining
			return
		b.pos = target
		remaining -= d
		b.tile += b.dir
		if b.tile.x < 0:
			b.tile.x = W - 1
			b.pos.x = W - 1
		elif b.tile.x >= W:
			b.tile.x = 0
			b.pos.x = 0
		_on_bat_arrive(b)
		_choose_dir(b)


func _on_bat_arrive(b: Dictionary) -> void:
	if b.state == Bat.LEAVING and b.tile == CAVE_EXIT:
		b.state = Bat.ACTIVE
		b.dir = Vector2i.LEFT if b.id % 2 == 0 else Vector2i.RIGHT
		b.fright = false
	elif b.state == Bat.EATEN and b.tile == CAVE_CENTER:
		b.state = Bat.LEAVING
		b.fright = false


func _reverse(b: Dictionary) -> void:
	if b.dir == Vector2i.ZERO:
		return
	if (b.pos as Vector2).distance_to(Vector2(b.tile)) > 0.01:
		b.tile += b.dir          # já ia a caminho da casa seguinte: volta para trás
		b.dir = -b.dir
	elif passable(b.tile - b.dir):
		b.dir = -b.dir


func _bat_target(b: Dictionary) -> Vector2i:
	if b.state == Bat.LEAVING:
		return CAVE_EXIT if b.tile.y > DOOR.y or b.tile.x == DOOR.x else Vector2i(DOOR.x, b.tile.y)
	if b.state == Bat.EATEN:
		return CAVE_CENTER
	if not chasing:
		return BAT_CORNER[b.id]
	match b.id:
		0:  # Caçador: direito ao pirilampo
			return player_tile
		1:  # Emboscador: 4 casas à frente do pirilampo
			return player_tile + player_face * 4
		2:  # Cercador: do lado oposto ao Caçador, em relação ao pirilampo
			var hunter: Vector2i = bats[0].tile
			var ahead := player_tile + player_face * 2
			return ahead + (ahead - hunter)
		_:  # Errante: aproxima-se, mas foge para o seu canto quando está perto
			var d := Vector2(b.tile).distance_to(Vector2(player_tile))
			return player_tile if d > 7.0 else BAT_CORNER[3]


func _choose_dir(b: Dictionary) -> void:
	var door_ok: bool = b.state == Bat.LEAVING or b.state == Bat.EATEN
	var options: Array[Vector2i] = []
	for d: Vector2i in DIRS:
		if d == -b.dir and b.dir != Vector2i.ZERO:
			continue
		var t: Vector2i = b.tile + d
		if passable(t, door_ok):
			# fora da gruta, um morcego ativo não volta a entrar pela porta
			if not door_ok and cell(t) in ["-", "C"]:
				continue
			options.append(d)
	if options.is_empty():
		var back: Vector2i = -b.dir
		b.dir = back if passable(b.tile + back, door_ok) else Vector2i.ZERO
		return
	if b.fright and b.state == Bat.ACTIVE:
		b.dir = options.pick_random()
		return
	var target := _bat_target(b)
	var best_d := INF
	for d in options:
		var dist := Vector2(b.tile + d).distance_squared_to(Vector2(target))
		if dist < best_d:
			best_d = dist
			b.dir = d


func _check_collisions() -> void:
	for b in bats:
		if b.state != Bat.ACTIVE:
			continue
		var dp: Vector2 = b.pos - player_pos
		if absf(dp.x) > W / 2.0:
			continue
		if dp.length() < 0.6:
			if b.fright:
				b.state = Bat.EATEN
				b.fright = false
				var pts := 200 * int(pow(2, fright_chain))
				fright_chain = mini(fright_chain + 1, 3)
				_add_score(pts)
				bat_eaten.emit(to_px(b.pos), pts)
			else:
				_kill_player()
				return


func _kill_player() -> void:
	player().lives -= 1
	state = State.DYING
	timer = 2.0
	bonus = null
	fright_time = 0.0
	player_hit.emit(to_px(player_pos))


func _after_death() -> void:
	player().pellets = pellets.duplicate()
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
		_load_level()
	_reset_turn()
	turn_started.emit(current)


# ---------------------------------------------------------------- CPU da demonstração

func _ai(_dt: float) -> void:
	# Só decide nos centros das casas (ou quando parado).
	var at_center := player_pos.distance_to(Vector2(player_tile)) < 0.05
	if not at_center and player_dir != Vector2i.ZERO:
		return
	var danger := {}
	for b in bats:
		if b.state == Bat.ACTIVE and not b.fright:
			var t: Vector2i = b.tile
			danger[t] = true
			for d: Vector2i in DIRS:
				danger[t + d] = true
				danger[t + d * 2] = true
	# procura em largura o objetivo mais próximo (morcego encandeado ou ponto de luz) evitando o perigo
	var start := player_tile
	var first := {start: Vector2i.ZERO}
	var queue: Array[Vector2i] = [start]
	var goal_dir := Vector2i.ZERO
	while not queue.is_empty():
		var t: Vector2i = queue.pop_front()
		var is_goal := false
		if t != start:
			var wx := posmod(t.x, W)
			if pellets[t.y * W + wx] > 0:
				is_goal = true
			for b in bats:
				if b.fright and b.state == Bat.ACTIVE and b.tile == t:
					is_goal = true
		if is_goal:
			goal_dir = first[t]
			break
		for d: Vector2i in DIRS:
			var n := t + d
			n.x = posmod(n.x, W)
			if first.has(n) or not passable(n) or danger.has(n):
				continue
			first[n] = d if t == start else first[t]
			queue.append(n)
	if goal_dir == Vector2i.ZERO:
		# encurralado: escolhe a saída mais afastada do morcego mais próximo
		var best_score := -INF
		for d: Vector2i in DIRS:
			if passable(player_tile + d):
				var s := 0.0
				for b in bats:
					if b.state == Bat.ACTIVE and not b.fright:
						s += minf(Vector2(player_tile + d).distance_to(b.pos), 8.0)
				if s > best_score:
					best_score = s
					goal_dir = d
	if goal_dir != Vector2i.ZERO:
		_wanted = goal_dir
