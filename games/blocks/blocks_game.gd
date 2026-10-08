class_name BlocksGame
extends Node2D
## Encaixe — puzzle de peças que caem, ao estilo de 1984: peças de 4 quadrados caem num poço de
## 10 x 20; roda-as e encaixa-as para completar linhas, que desaparecem. Regras modernas:
## saco de 7 peças, rotação com "chutes" nas paredes, peça guardada, sombra da peça, espera
## antes de assentar, queda rápida e queda imediata.

signal spawned(kind: int)
signal moved
signal rotated
signal soft_dropped
signal hard_dropped(cells: int)
signal locked
signal held
signal cleared(rows: Array, count: int)
signal level_up(level: int)
signal game_over

enum Mode { DEMO, PLAY }
enum State { PLAY, CLEAR, OVER }

const COLS := 10
const ROWS := 22          # 2 linhas escondidas por cima
const HIDDEN := 2
const CLEAR_TIME := 0.32
const LOCK_DELAY := 0.5
const MAX_RESETS := 15
const DAS := 0.16
const ARR := 0.045
const NAMES := ["I", "O", "T", "S", "Z", "J", "L"]
## Peças (rotação 0) dentro de uma caixa de n x n.
const SHAPES := [
	[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
	[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
]
const BOX := [4, 4, 3, 3, 3, 3, 3]
## Chutes (x, y para baixo) por transição "de>para" das rotações 0, 1 (R), 2, 3 (L).
const KICKS := {
	"01": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	"10": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	"12": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	"21": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	"23": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
	"32": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	"30": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	"03": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
}
const KICKS_I := {
	"01": [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
	"10": [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
	"12": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)],
	"21": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)],
	"23": [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
	"32": [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
	"30": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)],
	"03": [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)],
}
const LINE_POINTS := [0, 100, 300, 500, 800]

var mode := Mode.DEMO
var state := State.PLAY
var paused := false
var skin: BlocksSkin
var best := 0
var start_level := 1

var board := PackedByteArray()         # 0 vazio, 1..7 peça
var kind := 0
var rot := 0
var px := 3
var py := 0
var next: Array[int] = []
var hold := -1
var can_hold := true
var score := 0
var lines := 0
var level := 1
var combo := -1
var b2b := false
var clear_rows: Array[int] = []
var clear_t := 0.0
var timer := 0.0
var last_clear := 0                    # n.º de linhas da última jogada (para os estilos)
var last_b2b := false

var _bag: Array[int] = []
var _fall_acc := 0.0
var _lock_t := 0.0
var _resets := 0
var _lowest := 0
var _das_dir := 0
var _das_t := 0.0
var _arr_t := 0.0
var _soft := false
var _ai_plan := {}
var _ai_t := 0.0
var _touch := {}


func _init() -> void:
	_ensure_inputs()


static func _ensure_inputs() -> void:
	var defs := {
		"bl_left": [_key(KEY_LEFT), _key(KEY_A), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"bl_right": [_key(KEY_RIGHT), _key(KEY_D), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)],
		"bl_soft": [_key(KEY_DOWN), _key(KEY_S), _joy_button(JOY_BUTTON_DPAD_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)],
		"bl_hard": [_key(KEY_SPACE), _joy_button(JOY_BUTTON_DPAD_UP)],
		"bl_cw": [_key(KEY_UP), _key(KEY_X), _key(KEY_W), _joy_button(JOY_BUTTON_A)],
		"bl_ccw": [_key(KEY_Z), _key(KEY_CTRL), _key(KEY_Q), _joy_button(JOY_BUTTON_B)],
		"bl_hold": [_key(KEY_C), _key(KEY_SHIFT), _key(KEY_E), _joy_button(JOY_BUTTON_LEFT_SHOULDER), _joy_button(JOY_BUTTON_RIGHT_SHOULDER)],
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


func set_skin(new_skin: BlocksSkin) -> void:
	if skin:
		skin.queue_free()
	skin = new_skin
	add_child(skin)
	skin.attach(self)


func is_ai() -> bool:
	return mode == Mode.DEMO


# ---------------------------------------------------------------- peças e tabuleiro

static func cells_of(k: int, r: int) -> Array[Vector2i]:
	var n: int = BOX[k]
	var out: Array[Vector2i] = []
	for c: Vector2i in SHAPES[k]:
		var v := c
		for i in r:
			v = Vector2i(n - 1 - v.y, v.x)
		out.append(v)
	return out


func cell(x: int, y: int) -> int:
	if x < 0 or x >= COLS or y >= ROWS:
		return 8
	if y < 0:
		return 0
	return board[y * COLS + x]


func fits(k: int, r: int, x: int, y: int) -> bool:
	for c in cells_of(k, r):
		if cell(x + c.x, y + c.y) != 0:
			return false
	return true


## Células da peça em jogo (coordenadas do tabuleiro).
func piece_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in cells_of(kind, rot):
		out.append(Vector2i(px + c.x, py + c.y))
	return out


## Linha onde a peça assentaria (para a sombra).
func ghost_y() -> int:
	var y := py
	while fits(kind, rot, px, y + 1):
		y += 1
	return y


func gravity() -> float:
	var l := mini(level, 20) - 1
	return pow(0.8 - l * 0.007, l)


# ---------------------------------------------------------------- partida

func start(p_mode: Mode, p_level := 1) -> void:
	mode = p_mode
	start_level = p_level
	paused = false
	board.resize(COLS * ROWS)
	board.fill(0)
	score = 0
	lines = 0
	level = p_level
	combo = -1
	b2b = false
	hold = -1
	_bag.clear()
	next.clear()
	for i in 5:
		next.append(_from_bag())
	clear_rows.clear()
	state = State.PLAY
	_touch.clear()
	_spawn(_take_next())


func _from_bag() -> int:
	if _bag.is_empty():
		_bag = [0, 1, 2, 3, 4, 5, 6]
		_bag.shuffle()
	return _bag.pop_back()


func _take_next() -> int:
	var k: int = next.pop_front()
	next.append(_from_bag())
	return k


func _spawn(k: int) -> void:
	kind = k
	rot = 0
	px = 3
	py = 0
	_fall_acc = 0.0
	_lock_t = 0.0
	_resets = 0
	if not fits(kind, rot, px, py):
		_top_out()
		return
	if fits(kind, rot, px, py + 1):
		py += 1
	_lowest = py
	_ai_plan = {}
	spawned.emit(kind)


func _top_out() -> void:
	state = State.OVER
	timer = 4.0
	if mode == Mode.PLAY:
		best = maxi(best, score)
	game_over.emit()


# ---------------------------------------------------------------- ações

func try_move(dx: int) -> bool:
	if state != State.PLAY or not fits(kind, rot, px + dx, py):
		return false
	px += dx
	_after_action()
	moved.emit()
	return true


func try_rotate(dir: int) -> bool:
	if state != State.PLAY or kind == 1:
		return false
	var nr := (rot + dir + 4) % 4
	var key := "%d%d" % [rot, nr]
	var table: Dictionary = KICKS_I if kind == 0 else KICKS
	for k: Vector2i in table[key]:
		if fits(kind, nr, px + k.x, py + k.y):
			px += k.x
			py += k.y
			rot = nr
			_after_action()
			rotated.emit()
			return true
	return false


func _after_action() -> void:
	# reinicia a espera para assentar (com limite), como nas regras modernas
	if not fits(kind, rot, px, py + 1) and _resets < MAX_RESETS:
		_lock_t = 0.0
		_resets += 1


func hard_drop() -> void:
	if state != State.PLAY:
		return
	var d := 0
	while fits(kind, rot, px, py + 1):
		py += 1
		d += 1
	score += d * 2
	hard_dropped.emit(d)
	_lock()


func do_hold() -> void:
	if state != State.PLAY or not can_hold:
		return
	var k := kind
	if hold < 0:
		hold = k
		_spawn(_take_next())
	else:
		var h := hold
		hold = k
		_spawn(h)
	can_hold = false
	held.emit()


func _lock() -> void:
	var above := true
	for c in piece_cells():
		board[c.y * COLS + c.x] = kind + 1
		if c.y >= HIDDEN:
			above = false
	can_hold = true
	locked.emit()
	if above:
		_top_out()
		return
	clear_rows.clear()
	for y in ROWS:
		var full := true
		for x in COLS:
			if board[y * COLS + x] == 0:
				full = false
				break
		if full:
			clear_rows.append(y)
	var n := clear_rows.size()
	last_clear = n
	if n > 0:
		combo += 1
		var pts: int = LINE_POINTS[n] * level
		last_b2b = n == 4 and b2b
		if last_b2b:
			pts = pts * 3 / 2
		b2b = n == 4
		score += pts + 50 * combo * level
		lines += n
		state = State.CLEAR
		clear_t = 0.0
		cleared.emit(clear_rows.duplicate(), n)
		var nl := maxi(start_level, start_level + lines / 10)
		if nl > level:
			level = nl
			level_up.emit(level)
	else:
		combo = -1
		_spawn(_take_next())


func _collapse() -> void:
	for y in clear_rows:
		for yy in range(y, 0, -1):
			for x in COLS:
				board[yy * COLS + x] = board[(yy - 1) * COLS + x]
		for x in COLS:
			board[x] = 0
	clear_rows.clear()
	state = State.PLAY
	_spawn(_take_next())


# ---------------------------------------------------------------- ciclo

func _process(delta: float) -> void:
	if paused:
		return
	delta = minf(delta, 0.1)
	match state:
		State.CLEAR:
			clear_t += delta
			if clear_t >= CLEAR_TIME:
				_collapse()
		State.OVER:
			timer -= delta
			if timer <= 0.0 and mode == Mode.DEMO:
				start(Mode.DEMO, 1)
		State.PLAY:
			if is_ai():
				_ai(delta)
			else:
				_input_repeat(delta)
			_gravity(delta)


func _gravity(delta: float) -> void:
	if state != State.PLAY:
		return
	var g := gravity()
	if _soft:
		g = minf(g / 20.0, 0.05)
	_fall_acc += delta
	while _fall_acc >= g and state == State.PLAY:
		_fall_acc -= g
		if fits(kind, rot, px, py + 1):
			py += 1
			if _soft:
				score += 1
				soft_dropped.emit()
			if py > _lowest:
				_lowest = py
				_lock_t = 0.0
				_resets = 0
		else:
			_fall_acc = 0.0
			break
	if state == State.PLAY and not fits(kind, rot, px, py + 1):
		_lock_t += delta
		if _lock_t >= LOCK_DELAY:
			_lock()


func _input_repeat(delta: float) -> void:
	var dir := 0
	if Input.is_action_pressed("bl_left"):
		dir -= 1
	if Input.is_action_pressed("bl_right"):
		dir += 1
	if _touch.get("soft", false):
		_soft = true
	else:
		_soft = Input.is_action_pressed("bl_soft")
	if dir != _das_dir:
		_das_dir = dir
		_das_t = 0.0
		_arr_t = 0.0
		if dir != 0:
			try_move(dir)
	elif dir != 0:
		_das_t += delta
		if _das_t >= DAS:
			_arr_t += delta
			while _arr_t >= ARR:
				_arr_t -= ARR
				if not try_move(dir):
					break


func _unhandled_input(event: InputEvent) -> void:
	if is_ai() or paused or state == State.OVER:
		return
	if event.is_action_pressed("bl_cw"):
		try_rotate(1)
	elif event.is_action_pressed("bl_ccw"):
		try_rotate(-1)
	elif event.is_action_pressed("bl_hard"):
		hard_drop()
	elif event.is_action_pressed("bl_hold"):
		do_hold()
	# Tátil (e rato): arrastar para os lados move, arrastar para baixo desce, um gesto rápido
	# para baixo deixa cair, para cima guarda; um toque roda (metade esquerda: ao contrário).
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch = {"index": event.index, "start": event.position, "last": event.position, "t": Time.get_ticks_msec(), "moved": false, "soft": false, "acc": Vector2.ZERO}
		elif not _touch.is_empty() and event.index == _touch.index:
			var dt := (Time.get_ticks_msec() - int(_touch.t)) / 1000.0
			var total: Vector2 = event.position - _touch.start
			if not _touch.moved and total.length() < 24.0 and dt < 0.35:
				try_rotate(1 if event.position.x >= 640.0 else -1)
			elif total.y > 90.0 and dt < 0.3 and absf(total.x) < total.y:
				hard_drop()
			elif total.y < -90.0 and dt < 0.4 and absf(total.x) < -total.y:
				do_hold()
			_touch.clear()
	elif event is InputEventScreenDrag and not _touch.is_empty() and event.index == _touch.index:
		var acc: Vector2 = _touch.acc + event.relative
		var step := 36.0
		while acc.x >= step:
			acc.x -= step
			try_move(1)
			_touch.moved = true
		while acc.x <= -step:
			acc.x += step
			try_move(-1)
			_touch.moved = true
		var dt := (Time.get_ticks_msec() - int(_touch.t)) / 1000.0
		_touch.soft = acc.y > 50.0 and dt > 0.25
		if acc.y > 60.0:
			_touch.moved = true
		if acc.y < 0.0 and acc.y > -1.0:
			acc.y = 0.0
		_touch.acc = Vector2(acc.x, maxf(acc.y, -200.0))


# ---------------------------------------------------------------- CPU da demonstração

func _ai(delta: float) -> void:
	_soft = false
	if _ai_plan.is_empty():
		_ai_plan = best_placement(board, kind)
		_ai_t = 0.25
	_ai_t -= delta
	if _ai_t > 0.0:
		return
	_ai_t = 0.07
	if rot != int(_ai_plan.rot):
		if not try_rotate(1):
			_ai_plan.rot = rot
		return
	if px != int(_ai_plan.x):
		if not try_move(signi(int(_ai_plan.x) - px)):
			_ai_plan.x = px
		return
	if py < 6:
		_soft = true
	else:
		hard_drop()


## Melhor posição (rotação, x) para a peça k, avaliando o tabuleiro resultante.
static func best_placement(b: PackedByteArray, k: int) -> Dictionary:
	var best_v := -INF
	var best := {"rot": 0, "x": 3}
	for r in (1 if k == 1 else 4):
		var cs := cells_of(k, r)
		for x in range(-3, COLS):
			if not _fits_on(b, cs, x, 0):
				continue
			var y := 0
			while _fits_on(b, cs, x, y + 1):
				y += 1
			var nb := b.duplicate()
			for c in cs:
				nb[(y + c.y) * COLS + x + c.x] = 1
			var v := _evaluate(nb)
			if v > best_v:
				best_v = v
				best = {"rot": r, "x": x}
	return best


static func _fits_on(b: PackedByteArray, cs: Array[Vector2i], x: int, y: int) -> bool:
	for c in cs:
		var cx := x + c.x
		var cy := y + c.y
		if cx < 0 or cx >= COLS or cy >= ROWS:
			return false
		if cy >= 0 and b[cy * COLS + cx] != 0:
			return false
	return true


static func _evaluate(b: PackedByteArray) -> float:
	var full := 0
	for y in ROWS:
		var f := true
		for x in COLS:
			if b[y * COLS + x] == 0:
				f = false
				break
		if f:
			full += 1
	var heights: Array[int] = []
	var holes := 0
	for x in COLS:
		var h := 0
		var seen := false
		for y in ROWS:
			if b[y * COLS + x] != 0:
				if not seen:
					h = ROWS - y
					seen = true
			elif seen:
				holes += 1
		heights.append(h)
	var agg := 0
	var bump := 0
	var maxh := 0
	for x in COLS:
		agg += heights[x]
		maxh = maxi(maxh, heights[x])
		if x > 0:
			bump += absi(heights[x] - heights[x - 1])
	return -0.51 * agg + 0.76 * full * COLS / 10.0 - 0.36 * holes * 2.0 - 0.18 * bump - 0.2 * maxi(maxh - 12, 0)
