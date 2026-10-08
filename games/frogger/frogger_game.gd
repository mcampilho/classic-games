class_name FroggerGame
extends Node2D
## Lógica do Frogger (1981), independente do visual.
## Unidades do ecrã original (224 x 224), em casas de 16, desenhadas a SCALE píxeis por unidade.
##
## Regras do original:
##  - atravessar a estrada (5 faixas) e o rio (troncos e tartarugas) até às 5 tocas
##  - 10 pontos por cada salto para uma linha nova, 50 por rã em casa + 10 por cada
##    meio segundo que sobre no relógio; 1000 ao encher as 5 tocas (e sobe o nível)
##  - mosca numa toca: +200; a partir do nível 2 aparece um crocodilo nas tocas
##  - algumas tartarugas mergulham; cair à água, ser atropelado, sair do ecrã ou ficar
##    sem tempo custa uma vida; vida extra aos 10 000 pontos

signal match_started
signal turn_started(player: int)
signal hopped(pos: Vector2)
signal frog_home(bay: int, points: int, fly: bool)
signal frog_died(pos: Vector2, cause: String)     # "carro", "agua", "tempo", "toca"
signal time_warning
signal extra_life
signal level_cleared
signal game_over

enum Mode { DEMO, ONE, TWO }
enum State { READY, PLAY, DYING, CLEARED, OVER }

const SCALE := 3.0
const ORIGIN := Vector2(304, 24)
const CELL := 16.0
const W := 224.0
const ROWS := 13                       # 0 tocas, 1-5 rio, 6 margem, 7-11 estrada, 12 partida
const START := Vector2(112, 12)        # x em unidades, linha
const BAYS := [16.0, 64.0, 112.0, 160.0, 208.0]
const HOP_TIME := 0.12
const SPAN := 320.0                    # largura da volta dos objetos (campo + margem)
const MARGIN := 96.0
const EXTRA_LIFE_AT := 10000
const TOUCH_MIN := 22.0

## Faixas: linha -> [tipo, velocidade (u/s, + direita), comprimento (casas), posições iniciais, tartarugas que mergulham]
const LANES := {
	1: ["log", 28.0, 3, [0.0, 106.0, 212.0], []],
	2: ["turtle", -34.0, 2, [0.0, 64.0, 128.0, 192.0, 256.0], [2]],
	3: ["log", 46.0, 6, [0.0, 160.0], []],
	4: ["log", 22.0, 4, [0.0, 104.0, 208.0], []],
	5: ["turtle", -28.0, 3, [0.0, 80.0, 160.0, 240.0], [1]],
	7: ["truck", -30.0, 2, [0.0, 128.0], []],
	8: ["racer", 84.0, 1, [0.0], []],
	9: ["car_b", -42.0, 1, [0.0, 70.0, 140.0], []],
	10: ["dozer", 28.0, 1, [0.0, 80.0, 160.0], []],
	11: ["car_a", -24.0, 1, [0.0, 80.0, 160.0], []],
}

var mode := Mode.DEMO
var start_lives := 3
var state := State.READY
var paused := false
var skin: FroggerSkin
var best := 0

var players: Array[Dictionary] = []    # score, lives, level, extra, homes (Array[bool])
var current := 0
var objects: Array[Dictionary] = []    # row, x, len, kind, dive (bool), phase
var frog := Vector2(START)             # x em unidades, y = linha (fracionária durante o salto)
var frog_face := Vector2i.UP
var hop_t := -1.0
var hop_from := Vector2.ZERO
var hop_to := Vector2.ZERO
var best_row := 12
var time_left := 40.0
var homes: Array = [false, false, false, false, false]
var fly_bay := -1
var fly_t := 0.0
var croc_bay := -1
var croc_t := 0.0
var timer := 0.0
var death_cause := ""
var _queued := Vector2i.ZERO
var _warned := false
var _touch_start: Variant = null
var _ai_wait := 0.0


func _init() -> void:
	_ensure_inputs()


static func _ensure_inputs() -> void:
	var defs := {
		"fr_up": [_key(KEY_W), _key(KEY_UP), _joy_button(JOY_BUTTON_DPAD_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0), _joy_button(JOY_BUTTON_A)],
		"fr_down": [_key(KEY_S), _key(KEY_DOWN), _joy_button(JOY_BUTTON_DPAD_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)],
		"fr_left": [_key(KEY_A), _key(KEY_LEFT), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"fr_right": [_key(KEY_D), _key(KEY_RIGHT), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)],
	}
	for action: String in defs:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.5)
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


## Posição do centro da rã em unidades.
func frog_center() -> Vector2:
	return Vector2(frog.x, frog.y * CELL + CELL / 2)


func lane_speed(row: int) -> float:
	return LANES[row][1] * minf(1.0 + (level() - 1) * 0.15, 2.0)


func object_rect(o: Dictionary) -> Rect2:
	return Rect2(o.x, o.row * CELL + 1, o.len * CELL, CELL - 2)


## Tartarugas: 0 à tona, 1 a afundar, 2 submersas, 3 a subir.
func turtle_stage(o: Dictionary) -> int:
	if not o.dive:
		return 0
	var t := fmod(o.phase, 5.0)
	if t < 3.0:
		return 0
	if t < 3.5:
		return 1
	if t < 4.6:
		return 2
	return 3


func player() -> Dictionary:
	return players[current]


func level() -> int:
	return player().level if not players.is_empty() else 1


func is_ai() -> bool:
	return mode == Mode.DEMO


func time_limit() -> float:
	return maxf(25.0, 40.0 - (level() - 1) * 2.0)


# ---------------------------------------------------------------- partida

func start(p_mode: Mode, lives := 3) -> void:
	mode = p_mode
	start_lives = lives
	paused = false
	reset_match()


func reset_match() -> void:
	players.clear()
	for i in (2 if mode == Mode.TWO else 1):
		players.append({"score": 0, "lives": start_lives, "level": 1, "extra": false, "homes": [false, false, false, false, false]})
	current = 0
	_build_objects()
	_load_player()
	_reset_frog()
	match_started.emit()
	turn_started.emit(0)


func set_skin(new_skin: FroggerSkin) -> void:
	if skin:
		skin.queue_free()
	skin = new_skin
	add_child(skin)
	skin.attach(self)


func _build_objects() -> void:
	objects.clear()
	for row: int in LANES:
		var lane: Array = LANES[row]
		var xs: Array = lane[3]
		var divers: Array = lane[4]
		for i in xs.size():
			# mais tartarugas mergulham nos níveis mais altos
			var dive: bool = i in divers or (lane[0] == "turtle" and level() >= 3 and i % 2 == 0)
			objects.append({"row": row, "x": xs[i], "len": lane[2], "kind": lane[0], "dive": dive, "phase": randf() * 5.0})


func _load_player() -> void:
	homes = player().homes.duplicate()
	fly_bay = -1
	croc_bay = -1
	fly_t = 6.0
	croc_t = 8.0


func _reset_frog() -> void:
	frog = START
	frog_face = Vector2i.UP
	hop_t = -1.0
	best_row = 12
	time_left = time_limit()
	_warned = false
	_queued = Vector2i.ZERO
	state = State.READY
	timer = 0.8


# ---------------------------------------------------------------- ciclo

func _process(delta: float) -> void:
	if paused:
		return
	var steps := maxi(1, ceili(delta * 240.0))
	var dt := delta / steps
	for i in steps:
		_step(dt)


func _step(dt: float) -> void:
	_move_objects(dt)
	_update_bays(dt)
	match state:
		State.READY:
			timer -= dt
			if timer <= 0.0:
				state = State.PLAY
		State.PLAY:
			_frog_update(dt)
		State.DYING:
			timer -= dt
			if timer <= 0.0:
				_after_death()
		State.CLEARED:
			timer -= dt
			if timer <= 0.0:
				player().level += 1
				player().homes = [false, false, false, false, false]
				_build_objects()
				_load_player()
				_reset_frog()
				turn_started.emit(current)
		State.OVER:
			if mode == Mode.DEMO:
				timer -= dt
				if timer <= 0.0:
					reset_match()


func _move_objects(dt: float) -> void:
	for o in objects:
		o.x = fposmod(o.x + lane_speed(o.row) * dt + MARGIN, SPAN) - MARGIN
		o.phase += dt


func _update_bays(dt: float) -> void:
	if state != State.PLAY and state != State.READY:
		return
	fly_t -= dt
	if fly_t <= 0.0:
		if fly_bay >= 0:
			fly_bay = -1
			fly_t = randf_range(4.0, 8.0)
		else:
			var free := _free_bays([croc_bay])
			if not free.is_empty():
				fly_bay = free.pick_random()
			fly_t = 4.5
	if level() >= 2:
		croc_t -= dt
		if croc_t <= 0.0:
			if croc_bay >= 0:
				croc_bay = -1
				croc_t = randf_range(5.0, 9.0)
			else:
				var free := _free_bays([fly_bay])
				if not free.is_empty():
					croc_bay = free.pick_random()
				croc_t = 3.5


func _free_bays(exclude: Array) -> Array:
	var out := []
	for i in 5:
		if not homes[i] and not (i in exclude):
			out.append(i)
	return out


# ---------------------------------------------------------------- rã

func _frog_update(dt: float) -> void:
	time_left -= dt
	if time_left <= 8.0 and not _warned:
		_warned = true
		time_warning.emit()
	if time_left <= 0.0:
		_die("tempo")
		return
	if hop_t >= 0.0:
		hop_t += dt
		var k := minf(hop_t / HOP_TIME, 1.0)
		frog = hop_from.lerp(hop_to, k)
		_ride(dt)
		if k >= 1.0:
			hop_t = -1.0
			frog = Vector2(frog.x, hop_to.y)
			_landed()
			if state != State.PLAY:
				return
	else:
		_ride(dt)
		var dir := _ai_dir(dt) if is_ai() else _input_dir()
		if dir != Vector2i.ZERO:
			_hop(dir)
	_check_death()


func _input_dir() -> Vector2i:
	if _queued != Vector2i.ZERO:
		var q := _queued
		_queued = Vector2i.ZERO
		return q
	if Input.is_action_pressed("fr_up"):
		return Vector2i.UP
	if Input.is_action_pressed("fr_down"):
		return Vector2i.DOWN
	if Input.is_action_pressed("fr_left"):
		return Vector2i.LEFT
	if Input.is_action_pressed("fr_right"):
		return Vector2i.RIGHT
	return Vector2i.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if paused or is_ai():
		return
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	# Toque: deslizar = saltar nessa direção; tocar sem deslizar = saltar em frente.
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start = event.position
		elif _touch_start != null:
			var d: Vector2 = event.position - _touch_start
			_queued = Vector2i.UP if d.length() < TOUCH_MIN else _vec_to_dir(d)
			_touch_start = null
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_queued = _vec_to_dir(event.position - to_px(frog_center()))


static func _vec_to_dir(d: Vector2) -> Vector2i:
	if absf(d.x) > absf(d.y):
		return Vector2i.RIGHT if d.x > 0.0 else Vector2i.LEFT
	return Vector2i.DOWN if d.y > 0.0 else Vector2i.UP


func _hop(dir: Vector2i) -> void:
	var to := frog + Vector2(dir.x * CELL, dir.y)
	if to.y > 12 or to.x < CELL / 2 or to.x > W - CELL / 2:
		return
	frog_face = dir
	hop_from = frog
	hop_to = to
	hop_t = 0.0
	hopped.emit(to_px(Vector2(to.x, to.y * CELL + CELL / 2)))


func _landed() -> void:
	var row := int(frog.y)
	if row < best_row:
		best_row = row
		_add_score(10)
	if row == 0:
		_reach_bay()


func _reach_bay() -> void:
	for i in 5:
		if absf(frog.x - BAYS[i]) <= 7.0:
			if homes[i] or croc_bay == i:
				_die("toca")
				return
			homes[i] = true
			var pts := 50 + int(time_left * 2.0) * 10
			var got_fly := fly_bay == i
			if got_fly:
				pts += 200
				fly_bay = -1
			_add_score(pts)
			frog_home.emit(i, pts, got_fly)
			if not homes.has(false):
				_add_score(1000)
				player().homes = homes.duplicate()
				state = State.CLEARED
				timer = 2.5
				level_cleared.emit()
			else:
				player().homes = homes.duplicate()
				frog = START
				hop_t = -1.0
				best_row = 12
				time_left = time_limit()
				_warned = false
			return
	_die("toca")


## No rio, a rã é levada pelo tronco ou pelas tartarugas.
func _ride(dt: float) -> void:
	var row := int(round(frog.y))
	if row < 1 or row > 5 or hop_t >= 0.0 and hop_t < HOP_TIME * 0.5:
		return
	var o: Variant = _platform_under()
	if o != null:
		frog.x += lane_speed(row) * dt
		if hop_t >= 0.0:
			hop_from.x += lane_speed(row) * dt
			hop_to.x += lane_speed(row) * dt


func _platform_under() -> Variant:
	var row := int(round(frog.y))
	for o in objects:
		if o.row == row and o.kind in ["log", "turtle"]:
			if frog.x >= o.x - 2.0 and frog.x <= o.x + o.len * CELL + 2.0 and turtle_stage(o) != 2:
				return o
	return null


func _check_death() -> void:
	if hop_t >= 0.0:
		return     # a meio do salto só se morre na estrada (ver abaixo)
	var row := int(frog.y)
	if row >= 1 and row <= 5:
		if frog.x < 0.0 or frog.x > W:
			_die("agua")
			return
		if _platform_under() == null:
			_die("agua")
			return
	_check_road()


func _check_road() -> void:
	var c := frog_center()
	var r := Rect2(c - Vector2(5.5, 5.5), Vector2(11, 11))
	for o in objects:
		if o.row >= 7 and o.row <= 11 and object_rect(o).intersects(r):
			_die("carro")
			return


func _die(cause: String) -> void:
	if state != State.PLAY:
		return
	player().lives -= 1
	death_cause = cause
	state = State.DYING
	timer = 1.6
	hop_t = -1.0
	frog_died.emit(to_px(frog_center()), cause)


func _after_death() -> void:
	player().homes = homes.duplicate()
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
	_reset_frog()
	turn_started.emit(current)


func _add_score(pts: int) -> void:
	var p := player()
	p.score += pts
	if not p.extra and p.score >= EXTRA_LIFE_AT:
		p.extra = true
		p.lives += 1
		extra_life.emit()


# ---------------------------------------------------------------- CPU da demonstração

## Prevê se a rã estará segura em (x, linha) daqui a `t` segundos e durante `hold` segundos.
func _safe_at(x: float, row: int, t: float, hold := 0.35) -> bool:
	if row == 0:
		for i in 5:
			if absf(x - BAYS[i]) <= 4.0 and not homes[i] and croc_bay != i:
				return true
		return false
	if row == 6 or row == 12:
		return true
	var samples := 4
	for k in samples + 1:
		var tt := t + hold * k / samples
		if row >= 7:
			var r := Rect2(Vector2(x, row * CELL + CELL / 2) - Vector2(8, 6), Vector2(16, 12))
			for o in objects:
				if o.row == row:
					var ox := fposmod(o.x + lane_speed(row) * tt + MARGIN, SPAN) - MARGIN
					if Rect2(ox, row * CELL + 1, o.len * CELL, CELL - 2).intersects(r):
						return false
		else:
			var fx := x + lane_speed(row) * (tt - t)
			if fx < 6.0 or fx > W - 6.0:
				return false
			var ok := false
			for o in objects:
				if o.row == row:
					var ox := fposmod(o.x + lane_speed(row) * tt + MARGIN, SPAN) - MARGIN
					var stage := turtle_stage({"dive": o.dive, "phase": o.phase + tt})
					if fx >= ox + 3.0 and fx <= ox + o.len * CELL - 3.0 and stage < 2 and not (stage == 1 and o.kind == "turtle" and tt > 0.3):
						ok = true
			if not ok:
				return false
	return true


func _ai_dir(dt: float) -> Vector2i:
	_ai_wait -= dt
	if _ai_wait > 0.0:
		return Vector2i.ZERO
	_ai_wait = 0.08
	var row := int(frog.y)
	var here_safe := _safe_at(frog.x, row, 0.0, 0.4)
	# na margem de cima do rio, alinha-se com uma toca livre antes de saltar
	if row == 1:
		var target := -1.0
		for i in 5:
			if not homes[i] and croc_bay != i and (target < 0.0 or absf(BAYS[i] - frog.x) < absf(target - frog.x)):
				target = BAYS[i]
		if target >= 0.0 and absf(target - frog.x) <= 4.0 and _safe_at(frog.x, 0, HOP_TIME):
			return Vector2i.UP
		# aproxima-se da toca saltando ao longo do tronco
		if target >= 0.0 and absf(target - frog.x) > 10.0:
			var step := Vector2i.RIGHT if target > frog.x else Vector2i.LEFT
			if _safe_at(frog.x + step.x * CELL, 1, HOP_TIME):
				return step
	var can_up := _safe_at(frog.x, row - 1, HOP_TIME)
	if row == 2 and can_up:
		# a corrente da última linha leva para a direita: só sobe se houver uma toca livre à frente
		can_up = false
		for i in 5:
			if not homes[i] and croc_bay != i and BAYS[i] >= frog.x - 4.0 and BAYS[i] - frog.x < 70.0:
				can_up = true
	if can_up:
		return Vector2i.UP
	# no rio, afasta-se da margem para onde a corrente o leva
	if row >= 1 and row <= 5:
		var drift := signf(lane_speed(row))
		var edge_dist := (W - frog.x) if drift > 0.0 else frog.x
		if edge_dist < 40.0:
			var back := Vector2i(-int(drift), 0)
			if _safe_at(frog.x + back.x * CELL, row, HOP_TIME):
				return back
	if here_safe:
		return Vector2i.ZERO
	var sides := [Vector2i.LEFT, Vector2i.RIGHT] if randf() < 0.5 else [Vector2i.RIGHT, Vector2i.LEFT]
	for d: Vector2i in sides:
		var nx: float = frog.x + d.x * CELL
		if nx > CELL / 2 and nx < W - CELL / 2 and _safe_at(nx, row, HOP_TIME):
			return d
	if row < 12 and _safe_at(frog.x, row + 1, HOP_TIME):
		return Vector2i.DOWN
	return Vector2i.ZERO
