class_name PongGame
extends Node2D
## Lógica do Pong, independente do visual.
## O desenho e os sons ficam a cargo de um "skin" (PongSkin), que reage aos sinais abaixo.
## Assim as três versões (Clássico, Neon, Papel & Tinta) partilham exatamente a mesma jogabilidade.

signal match_started
signal served
signal paddle_hit(side: int, pos: Vector2, rel: float)
signal wall_hit(pos: Vector2)
signal point_scored(side: int)
signal game_over(winner: int)

enum Mode { DEMO, VS_CPU, VS_HUMAN }
enum State { SERVE, PLAY, OVER }

const FIELD := Vector2(1280, 720)
const PADDLE_SIZE := Vector2(16, 96)
const PADDLE_X := 64.0          # distância do centro da raquete à margem
const BALL_SIZE := 16.0
const PADDLE_SPEED := 760.0     # teclado / comando (px/s)
const TOUCH_SPEED := 2600.0     # ecrã tátil segue o dedo (como o botão rotativo original)
const WIN_SCORE := 11           # como no original de 1972
const SERVE_DELAY := 1.0
# Tal como no Pong original, a bola acelera após 4 e 12 toques na mesma jogada.
const SPEEDS := [520.0, 680.0, 860.0]
# A raquete divide-se em 8 segmentos; cada um devolve a bola com um ângulo fixo.
const BOUNCE_ANGLES := [-55.0, -40.0, -25.0, -10.0, 10.0, 25.0, 40.0, 55.0]
# speed: velocidade da raquete · react: tempo de reação · error: imprecisão no alvo
# miss: probabilidade de, numa jogada, a CPU calcular mal e falhar a bola
const AI_PARAMS := [
	{"speed": 430.0, "react": 0.30, "error": 40.0, "miss": 0.22},   # Fácil
	{"speed": 600.0, "react": 0.16, "error": 30.0, "miss": 0.11},   # Normal
	{"speed": 820.0, "react": 0.07, "error": 18.0, "miss": 0.045},  # Difícil
]

var mode := Mode.DEMO
var difficulty := 1
var state := State.SERVE
var paused := false
var skin: PongSkin

var paddle_y := PackedFloat32Array([FIELD.y / 2, FIELD.y / 2])
var scores := PackedInt32Array([0, 0])
var ball_pos := FIELD / 2
var ball_vel := Vector2.ZERO
var rally_hits := 0
var winner := -1

var _serve_timer := 0.0
var _serve_dir := 1.0
var _over_timer := 0.0
var _touch_side := {}                 # índice do dedo -> lado
var _touch_target: Array = [null, null]
var _ai_goal := PackedFloat32Array([FIELD.y / 2, FIELD.y / 2])
var _ai_delay := PackedFloat32Array([0.0, 0.0])
var _ai_offset := PackedFloat32Array([0.0, 0.0])


func start(p_mode: Mode) -> void:
	mode = p_mode
	paused = false
	reset_match()


func reset_match() -> void:
	scores = PackedInt32Array([0, 0])
	paddle_y = PackedFloat32Array([FIELD.y / 2, FIELD.y / 2])
	winner = -1
	state = State.SERVE
	_serve_timer = SERVE_DELAY
	_serve_dir = 1.0 if randf() < 0.5 else -1.0
	clear_touches()
	match_started.emit()


func set_skin(new_skin: PongSkin) -> void:
	if skin:
		skin.queue_free()
	skin = new_skin
	add_child(skin)
	skin.attach(self)


func clear_touches() -> void:
	_touch_side.clear()
	_touch_target = [null, null]


func paddle_x(side: int) -> float:
	return PADDLE_X if side == 0 else FIELD.x - PADDLE_X


func paddle_rect(side: int) -> Rect2:
	return Rect2(Vector2(paddle_x(side), paddle_y[side]) - PADDLE_SIZE / 2, PADDLE_SIZE)


func ball_rect() -> Rect2:
	return Rect2(ball_pos - Vector2.ONE * BALL_SIZE / 2, Vector2.ONE * BALL_SIZE)


func is_ai(side: int) -> bool:
	return mode == Mode.DEMO or (mode == Mode.VS_CPU and side == 1)


# ---------------------------------------------------------------- ciclo

func _process(delta: float) -> void:
	if paused:
		return
	# Sub-passos fixos: colisões fiáveis mesmo com a bola rápida ou FPS baixos.
	var steps := maxi(1, ceili(delta * 240.0))
	var dt := delta / steps
	for i in steps:
		_step(dt)


func _step(dt: float) -> void:
	_update_paddles(dt)
	match state:
		State.SERVE:
			ball_pos = FIELD / 2
			_serve_timer -= dt
			if _serve_timer <= 0.0:
				_serve()
		State.PLAY:
			_move_ball(dt)
		State.OVER:
			if mode == Mode.DEMO:
				_over_timer -= dt
				if _over_timer <= 0.0:
					reset_match()


func _serve() -> void:
	state = State.PLAY
	rally_hits = 0
	ball_pos = Vector2(FIELD.x / 2, randf_range(FIELD.y * 0.3, FIELD.y * 0.7))
	var ang := deg_to_rad(randf_range(-30.0, 30.0))
	ball_vel = Vector2(_serve_dir * cos(ang), sin(ang)) * float(SPEEDS[0])
	_ai_on_ball_change()
	served.emit()


func _move_ball(dt: float) -> void:
	var prev := ball_pos
	var half := BALL_SIZE / 2
	ball_pos += ball_vel * dt

	if ball_pos.y - half < 0.0:
		ball_pos.y = half
		ball_vel.y = absf(ball_vel.y)
		wall_hit.emit(Vector2(ball_pos.x, 0.0))
	elif ball_pos.y + half > FIELD.y:
		ball_pos.y = FIELD.y - half
		ball_vel.y = -absf(ball_vel.y)
		wall_hit.emit(Vector2(ball_pos.x, FIELD.y))

	for side in 2:
		var toward := ball_vel.x < 0.0 if side == 0 else ball_vel.x > 0.0
		if not toward:
			continue
		var r := paddle_rect(side)
		if not ball_rect().intersects(r):
			continue
		# Só conta se a bola vinha da frente da raquete (não por trás).
		var came_from_front := prev.x - half >= r.end.x - 2.0 if side == 0 else prev.x + half <= r.position.x + 2.0
		if came_from_front:
			_bounce(side, r)

	if ball_pos.x < -BALL_SIZE * 2:
		_score(1)
	elif ball_pos.x > FIELD.x + BALL_SIZE * 2:
		_score(0)


func _bounce(side: int, r: Rect2) -> void:
	var half := BALL_SIZE / 2
	var rel := clampf((ball_pos.y - r.get_center().y) / (r.size.y / 2 + half), -1.0, 1.0)
	var zone := clampi(int((rel + 1.0) * 0.5 * 8.0), 0, 7)
	var ang := deg_to_rad(BOUNCE_ANGLES[zone])
	rally_hits += 1
	var tier := 0 if rally_hits < 4 else (1 if rally_hits < 12 else 2)
	var dir := 1.0 if side == 0 else -1.0
	ball_vel = Vector2(dir * cos(ang), sin(ang)) * float(SPEEDS[tier])
	ball_pos.x = r.end.x + half if side == 0 else r.position.x - half
	_ai_on_ball_change()
	paddle_hit.emit(side, ball_pos, rel)


func _score(side: int) -> void:
	scores[side] += 1
	_serve_dir = -1.0 if side == 1 else 1.0  # serve para quem sofreu o ponto
	point_scored.emit(side)
	if scores[side] >= WIN_SCORE:
		state = State.OVER
		winner = side
		_over_timer = 3.0
		game_over.emit(side)
	else:
		state = State.SERVE
		_serve_timer = SERVE_DELAY


# ---------------------------------------------------------------- raquetes

func _update_paddles(dt: float) -> void:
	var limit := PADDLE_SIZE.y / 2
	for side in 2:
		var y := paddle_y[side]
		if is_ai(side):
			y += _ai_axis(side, dt) * float(AI_PARAMS[difficulty if mode == Mode.VS_CPU else 1].speed) * dt
		elif _touch_target[side] != null:
			y = move_toward(y, float(_touch_target[side]), TOUCH_SPEED * dt)
		else:
			var axis := Input.get_axis("p1_up", "p1_down") if side == 0 else Input.get_axis("p2_up", "p2_down")
			if mode == Mode.VS_CPU:  # sozinho, qualquer conjunto de teclas serve
				axis = clampf(axis + Input.get_axis("p2_up", "p2_down"), -1.0, 1.0)
			y += axis * PADDLE_SPEED * dt
		paddle_y[side] = clampf(y, limit, FIELD.y - limit)


func _unhandled_input(event: InputEvent) -> void:
	if paused or mode == Mode.DEMO:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			var side := _side_for_touch(event.position)
			if side >= 0:
				_touch_side[event.index] = side
				_touch_target[side] = event.position.y
		elif _touch_side.has(event.index):
			_touch_target[_touch_side[event.index]] = null
			_touch_side.erase(event.index)
	elif event is InputEventScreenDrag and _touch_side.has(event.index):
		_touch_target[_touch_side[event.index]] = event.position.y


func _side_for_touch(pos: Vector2) -> int:
	# Zona do botão de pausa (topo ao centro) não mexe nas raquetes.
	if absf(pos.x - FIELD.x / 2) < 60.0 and pos.y < 90.0:
		return -1
	if mode == Mode.VS_HUMAN:
		return 0 if pos.x < FIELD.x / 2 else 1
	return 0


# ---------------------------------------------------------------- CPU

func _ai_on_ball_change() -> void:
	for side in 2:
		var p: Dictionary = AI_PARAMS[difficulty if mode == Mode.VS_CPU else 1]
		_ai_delay[side] = p.react
		_ai_offset[side] = randf_range(-p.error, p.error)
		if randf() < p.miss:
			_ai_offset[side] = randf_range(64.0, 96.0) * (1.0 if randf() < 0.5 else -1.0)


func _ai_axis(side: int, dt: float) -> float:
	if _ai_delay[side] > 0.0:
		_ai_delay[side] -= dt
	else:
		var toward := ball_vel.x < 0.0 if side == 0 else ball_vel.x > 0.0
		if state == State.PLAY and toward:
			_ai_goal[side] = _predict_y(side) + _ai_offset[side]
		else:
			_ai_goal[side] = lerpf(FIELD.y / 2, ball_pos.y, 0.3)
	var diff := _ai_goal[side] - paddle_y[side]
	if absf(diff) < 6.0:
		return 0.0
	return clampf(diff / 30.0, -1.0, 1.0)


## Prevê onde a bola vai cruzar a raquete, contando com os ressaltos nas paredes.
func _predict_y(side: int) -> float:
	var half := BALL_SIZE / 2
	var target_x := paddle_x(side) + (PADDLE_SIZE.x / 2 + half) * (1.0 if side == 0 else -1.0)
	if is_zero_approx(ball_vel.x):
		return ball_pos.y
	var t := (target_x - ball_pos.x) / ball_vel.x
	if t < 0.0:
		return ball_pos.y
	var lo := half
	var span := FIELD.y - 2.0 * half
	var m := fposmod(ball_pos.y + ball_vel.y * t - lo, 2.0 * span)
	if m > span:
		m = 2.0 * span - m
	return lo + m
