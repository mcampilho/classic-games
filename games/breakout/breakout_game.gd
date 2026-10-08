class_name BreakoutGame
extends Node2D
## Lógica do Breakout (Atari, 1976), independente do visual.
## O desenho e os sons ficam a cargo de um BreakoutSkin, que reage aos sinais abaixo.
##
## Regras do original:
##  - 8 filas de tijolos: 2 vermelhas (7 pts), 2 laranja (5), 2 verdes (3), 2 amarelas (1)
##  - a bola acelera aos 4 e aos 12 toques na raquete e ao tocar pela 1.ª vez nas filas laranja e vermelhas
##  - a raquete encolhe para metade quando a bola atravessa a parede e bate no topo
##  - 3 bolas por jogo (5 como opção), 1 ou 2 jogadores à vez

signal match_started
signal turn_started(player: int)
signal served
signal paddle_hit(pos: Vector2)
signal wall_hit(pos: Vector2)
signal brick_broken(row: int, col: int, pos: Vector2, points: int)
signal speed_changed(level: int)
signal paddle_shrunk
signal ball_lost(player: int)
signal wall_cleared(player: int)
signal game_over

enum Mode { DEMO, ONE, TWO }
enum State { READY, PLAY, LOST, CLEARED, OVER }

const SCREEN := Vector2(1280, 720)
const COLS := 14
const ROWS := 8
const BRICK := Vector2(56, 24)
const INNER := Rect2(248, 40, 784, 680)   # área de jogo, por dentro das paredes
const WALL := 16.0                        # espessura das paredes (desenhadas por fora)
const BRICK_TOP := 136.0
const PADDLE_Y := 672.0
const PADDLE_H := 14.0
const PADDLE_W := 80.0
const BALL := 12.0
const ROW_POINTS := [7, 7, 5, 5, 3, 3, 1, 1]
const SPEEDS := [340.0, 400.0, 460.0, 530.0, 600.0]
# A raquete divide-se em 8 segmentos; cada um devolve a bola com um ângulo fixo (graus a partir da vertical).
const ANGLES := [-60.0, -45.0, -30.0, -15.0, 15.0, 30.0, 45.0, 60.0]
const KEY_SPEED := 900.0
const TOUCH_GAIN := 1.4
const AI_SPEED := 1100.0

var mode := Mode.DEMO
var start_balls := 3
var state := State.READY
var paused := false
var skin: BreakoutSkin
var best := 0                      # recorde (o menu lê/grava)

## Um dicionário por jogador: score, balls (restantes, incluindo a que está em jogo), bricks, wall, small
var players: Array[Dictionary] = []
var current := 0
var paddle_x := INNER.get_center().x
var ball_pos := Vector2.ZERO
var ball_vel := Vector2.ZERO
var hits := 0
var hit_orange := false
var hit_red := false
var speed_level := 0

var _timer := 0.0
var _target_x: Variant = null
var _ai_offset := 0.0


## Ações de input do Breakout (criadas em código para não mexer no project.godot).
static func _ensure_inputs() -> void:
	var defs := {
		"bk_left": [_key(KEY_A), _key(KEY_LEFT), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"bk_right": [_key(KEY_D), _key(KEY_RIGHT), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)],
		"bk_serve": [_key(KEY_SPACE), _key(KEY_ENTER), _key(KEY_W), _key(KEY_UP), _joy_button(JOY_BUTTON_A)],
	}
	for action: String in defs:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.3)
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


func _init() -> void:
	_ensure_inputs()


func start(p_mode: Mode, balls := 3) -> void:
	mode = p_mode
	start_balls = balls
	paused = false
	reset_match()


func reset_match() -> void:
	players.clear()
	for i in (2 if mode == Mode.TWO else 1):
		players.append({"score": 0, "balls": start_balls, "bricks": _full_wall(), "wall": 1, "small": false})
	current = 0
	paddle_x = INNER.get_center().x
	_target_x = null
	state = State.READY
	_timer = 0.9
	match_started.emit()
	turn_started.emit(0)


func _full_wall() -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(ROWS * COLS)
	b.fill(1)
	return b


func set_skin(new_skin: BreakoutSkin) -> void:
	if skin:
		skin.queue_free()
	skin = new_skin
	add_child(skin)
	skin.attach(self)


# ---------------------------------------------------------------- consultas (usadas pelos skins)

func player() -> Dictionary:
	return players[current]


func paddle_width() -> float:
	return PADDLE_W * (0.5 if player().small else 1.0)


func paddle_rect() -> Rect2:
	var w := paddle_width()
	return Rect2(paddle_x - w / 2, PADDLE_Y - PADDLE_H / 2, w, PADDLE_H)


func ball_rect() -> Rect2:
	return Rect2(ball_pos - Vector2.ONE * BALL / 2, Vector2.ONE * BALL)


func brick_rect(row: int, col: int) -> Rect2:
	return Rect2(INNER.position.x + col * BRICK.x, BRICK_TOP + row * BRICK.y, BRICK.x, BRICK.y)


func brick_alive(row: int, col: int) -> bool:
	return player().bricks[row * COLS + col] == 1


func bricks_left() -> int:
	return player().bricks.count(1)


func ball_visible() -> bool:
	return state == State.PLAY


func waiting_serve() -> bool:
	return state == State.READY and mode != Mode.DEMO


# ---------------------------------------------------------------- ciclo

func _process(delta: float) -> void:
	if paused:
		return
	var steps := maxi(1, ceili(delta * 240.0))
	var dt := delta / steps
	for i in steps:
		_step(dt)


func _step(dt: float) -> void:
	_update_paddle(dt)
	match state:
		State.READY:
			if mode == Mode.DEMO:
				_timer -= dt
				if _timer <= 0.0:
					_serve()
		State.PLAY:
			_move_ball(dt)
		State.LOST:
			_timer -= dt
			if _timer <= 0.0:
				_next_turn()
		State.CLEARED:
			_timer -= dt
			if _timer <= 0.0:
				_new_wall()
		State.OVER:
			if mode == Mode.DEMO:
				_timer -= dt
				if _timer <= 0.0:
					reset_match()


func request_serve() -> void:
	if state == State.READY and not paused:
		_serve()


func _serve() -> void:
	state = State.PLAY
	hits = 0
	hit_orange = false
	hit_red = false
	speed_level = 0
	# Como no original, a bola surge por baixo da parede e desce em diagonal.
	ball_pos = Vector2(randf_range(INNER.position.x + 90.0, INNER.end.x - 90.0), BRICK_TOP + ROWS * BRICK.y + 50.0)
	var a := deg_to_rad(randf_range(25.0, 45.0)) * (1.0 if randf() < 0.5 else -1.0)
	ball_vel = Vector2(sin(a), cos(a)) * float(SPEEDS[0])
	_ai_offset = randf_range(-0.35, 0.35) * paddle_width()
	served.emit()


func _move_ball(dt: float) -> void:
	var prev := ball_pos
	var h := BALL / 2
	ball_pos += ball_vel * dt

	if ball_pos.x - h < INNER.position.x:
		ball_pos.x = INNER.position.x + h
		ball_vel.x = absf(ball_vel.x)
		wall_hit.emit(Vector2(INNER.position.x, ball_pos.y))
	elif ball_pos.x + h > INNER.end.x:
		ball_pos.x = INNER.end.x - h
		ball_vel.x = -absf(ball_vel.x)
		wall_hit.emit(Vector2(INNER.end.x, ball_pos.y))
	if ball_pos.y - h < INNER.position.y:
		ball_pos.y = INNER.position.y + h
		ball_vel.y = absf(ball_vel.y)
		wall_hit.emit(Vector2(ball_pos.x, INNER.position.y))
		# Só se chega ao topo depois de atravessar a parede: a raquete encolhe.
		if not player().small:
			player().small = true
			paddle_shrunk.emit()

	_check_bricks(prev)
	if state != State.PLAY:
		return
	_check_paddle(prev)
	if ball_pos.y > SCREEN.y + BALL * 2:
		_lose_ball()


func _check_bricks(prev: Vector2) -> void:
	var h := BALL / 2
	var r := ball_rect()
	var c0 := maxi(floori((r.position.x - INNER.position.x) / BRICK.x), 0)
	var c1 := mini(floori((r.end.x - INNER.position.x - 0.001) / BRICK.x), COLS - 1)
	var r0 := maxi(floori((r.position.y - BRICK_TOP) / BRICK.y), 0)
	var r1 := mini(floori((r.end.y - BRICK_TOP - 0.001) / BRICK.y), ROWS - 1)
	if r1 < 0 or r0 >= ROWS:
		return
	var bricks: PackedByteArray = player().bricks
	var best_i := -1
	var best_d := INF
	for row in range(r0, r1 + 1):
		for col in range(c0, c1 + 1):
			if bricks[row * COLS + col] == 1:
				var d := brick_rect(row, col).get_center().distance_squared_to(prev)
				if d < best_d:
					best_d = d
					best_i = row * COLS + col
	if best_i < 0:
		return

	var row := best_i / COLS
	var col := best_i % COLS
	var br := brick_rect(row, col)
	var pr := Rect2(prev - Vector2.ONE * h, Vector2.ONE * BALL)
	var overlap_y := pr.end.y > br.position.y and pr.position.y < br.end.y
	var overlap_x := pr.end.x > br.position.x and pr.position.x < br.end.x
	if overlap_y and not overlap_x:
		ball_vel.x = -ball_vel.x          # bateu de lado
		ball_pos.x = prev.x
	else:
		ball_vel.y = -ball_vel.y          # bateu por baixo / por cima (ou no canto)
		ball_pos.y = prev.y

	bricks[best_i] = 0
	player().bricks = bricks  # PackedByteArray é copiado por valor: guardar de volta
	var pts: int = ROW_POINTS[row]
	player().score += pts
	if row <= 1:
		hit_red = true
	elif row <= 3:
		hit_orange = true
	_update_speed()
	brick_broken.emit(row, col, br.get_center(), pts)

	if bricks.count(1) == 0:
		state = State.CLEARED
		_timer = 1.8
		wall_cleared.emit(current)


func _check_paddle(prev: Vector2) -> void:
	if ball_vel.y <= 0.0:
		return
	var h := BALL / 2
	var pr := paddle_rect()
	if not ball_rect().intersects(pr):
		return
	if prev.y + h > pr.position.y + 3.0:
		return  # já estava abaixo do topo da raquete: passou ao lado
	var rel := clampf((ball_pos.x - paddle_x) / (pr.size.x / 2 + h), -1.0, 1.0)
	var zone := clampi(int((rel + 1.0) * 0.5 * 8.0), 0, 7)
	var a := deg_to_rad(ANGLES[zone])
	hits += 1
	_update_speed()
	ball_vel = Vector2(sin(a), -cos(a)) * float(SPEEDS[speed_level])
	ball_pos.y = pr.position.y - h
	_ai_offset = randf_range(-0.38, 0.38) * paddle_width()
	paddle_hit.emit(ball_pos)


func _update_speed() -> void:
	var lvl := int(hits >= 4) + int(hits >= 12) + int(hit_orange) + int(hit_red)
	if lvl != speed_level:
		speed_level = lvl
		ball_vel = ball_vel.normalized() * float(SPEEDS[lvl])
		speed_changed.emit(lvl)


func _lose_ball() -> void:
	state = State.LOST
	_timer = 1.3
	player().balls -= 1
	ball_lost.emit(current)


func _next_turn() -> void:
	var next := current
	if mode == Mode.TWO and players[1 - current].balls > 0:
		next = 1 - current
	if players[next].balls <= 0:
		state = State.OVER
		_timer = 3.0
		game_over.emit()
		return
	current = next
	state = State.READY
	_timer = 0.9
	turn_started.emit(current)


func _new_wall() -> void:
	var p := player()
	p.wall += 1
	p.bricks = _full_wall()
	p.small = false
	state = State.READY
	_timer = 0.9
	turn_started.emit(current)


# ---------------------------------------------------------------- raquete

func _update_paddle(dt: float) -> void:
	if mode == Mode.DEMO:
		paddle_x = move_toward(paddle_x, _ai_target(), AI_SPEED * dt)
	else:
		var axis := Input.get_axis("bk_left", "bk_right")
		if not is_zero_approx(axis):
			_target_x = null
			paddle_x += axis * KEY_SPEED * dt
		elif _target_x != null:
			paddle_x = move_toward(paddle_x, float(_target_x), 5000.0 * dt)
	var half := paddle_width() / 2
	paddle_x = clampf(paddle_x, INNER.position.x + half, INNER.end.x - half)


func _unhandled_input(event: InputEvent) -> void:
	if paused or mode == Mode.DEMO:
		return
	var emulated := event.device == InputEvent.DEVICE_ID_EMULATION
	if event.is_action_pressed("bk_serve"):
		request_serve()
	elif event is InputEventMouseMotion and not emulated:
		_target_x = event.position.x                       # rato: posição absoluta
	elif event is InputEventMouseButton and not emulated and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_target_x = event.position.x
		request_serve()
	elif event is InputEventScreenTouch and not emulated and event.pressed:
		request_serve()
	elif event is InputEventScreenDrag and not emulated:
		_target_x = null                                   # toque: arrastar em qualquer sítio (relativo)
		paddle_x += event.relative.x * TOUCH_GAIN


## A CPU da demonstração prevê onde a bola vai chegar (com ressaltos nas paredes laterais).
func _ai_target() -> float:
	if state != State.PLAY:
		return INNER.get_center().x
	if ball_vel.y <= 0.0:
		return lerpf(INNER.get_center().x, ball_pos.x, 0.7)
	var h := BALL / 2
	var t := (PADDLE_Y - PADDLE_H / 2 - h - ball_pos.y) / ball_vel.y
	var lo := INNER.position.x + h
	var span := INNER.size.x - BALL
	var m := fposmod(ball_pos.x + ball_vel.x * t - lo, 2.0 * span)
	if m > span:
		m = 2.0 * span - m
	return lo + m + _ai_offset
