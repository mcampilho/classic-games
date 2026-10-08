class_name OutRunGame
extends Node2D
## Lógica do OutRun (1986): estrada pseudo-3D por segmentos (curvas e colinas), trânsito,
## cenário com colisões e contrarrelógio com pontos de controlo.
## O percurso tem 5 etapas; no fim de cada uma a estrada bifurca: quem segue pela esquerda
## ou pela direita escolhe a etapa seguinte (5 metas possíveis, como no original).

signal race_started
signal countdown(n: int)
signal stage_started(stage: int, theme: String)
signal checkpoint(stage: int, bonus: float)
signal crashed(pos: Vector2)
signal bumped
signal gear_changed(high: bool)
signal time_warning
signal goal(bonus: int)
signal time_up
signal game_over

enum Mode { DEMO, PLAY }
enum State { READY, PLAY, CRASH, OUT, GOAL, OVER }

const SCREEN := Vector2(1280, 720)
const SEG_LEN := 200.0
const ROAD_W := 2000.0               # meia-largura da estrada (unidades do mundo)
const LANES := 3
const FOV := 100.0
const CAM_HEIGHT := 1000.0
const DRAW_DIST := 220
const MAX_SPEED := SEG_LEN * 60.0     # 290 km/h
const ACCEL := MAX_SPEED / 5.0
const BRAKE := -MAX_SPEED
const DECEL := -MAX_SPEED / 5.0
const OFFROAD_DECEL := -MAX_SPEED / 2.0
const OFFROAD_LIMIT := MAX_SPEED / 4.0
const CENTRIFUGAL := 0.3
const PLAYER_W := 0.30                # largura do carro em meias-larguras de estrada
const START_TIME := 80.0
const CHECKPOINT_TIME := [0.0, 66.0, 64.0, 62.0, 60.0]
const STAGES := 5
const FORK_LEN := 170
const FORK_MAX := 3.4               # distância entre os centros das duas estradas (em meias-larguras) / 2
const THEMES := ["costa", "deserto", "floresta", "alpes", "cidade", "vinhas"]
## Pirâmide das etapas: em cada bifurcação, a esquerda mantém o índice e a direita soma 1.
const ROUTE_THEMES := [
	["costa"],
	["deserto", "floresta"],
	["cidade", "vinhas", "alpes"],
	["deserto", "floresta", "costa", "cidade"],
	["vinhas", "alpes", "deserto", "floresta", "costa"],
]
const THEME_NAMES := {"costa": "Costa", "deserto": "Deserto", "floresta": "Floresta", "alpes": "Alpes", "cidade": "Cidade", "vinhas": "Vinhas"}

## Cenário por tema: [tipo, largura, altura] (unidades do mundo)
const SCENERY := {
	"costa": [["palm", 700, 2200], ["palm2", 650, 1900], ["umbrella", 500, 600], ["sign", 900, 700]],
	"deserto": [["cactus", 400, 1000], ["rock", 900, 600], ["deadtree", 600, 1200], ["sign", 900, 700]],
	"floresta": [["pine", 700, 1800], ["oak", 900, 1500], ["bush", 600, 400], ["sign", 900, 700]],
	"alpes": [["snowpine", 700, 1900], ["rock", 900, 700], ["chalet", 1400, 1100], ["sign", 900, 700]],
	"cidade": [["building", 1600, 3000], ["lamp", 200, 1300], ["building2", 1400, 2400], ["sign", 900, 700]],
	"vinhas": [["cypress", 400, 1800], ["vine", 1000, 400], ["house", 1300, 1000], ["sign", 900, 700]],
}
const CAR_KINDS := [["car", 0.32, 0.55], ["van", 0.38, 0.45], ["truck", 0.42, 0.35], ["beetle", 0.28, 0.5]]   # tipo, largura, velocidade relativa

var mode := Mode.DEMO
var state := State.READY
var paused := false
var skin: OutRunSkin
var best := 0
var manual_gears := false

var segments: Array[Dictionary] = []     # p1y, p2y, curve, sprites, light, fork, index
var track_len := 0.0
var fork_start := 0
var stage_time := 0.0                     # tempo desde o início da etapa (para os estilos)
var cars: Array[Dictionary] = []          # z, offset, speed, kind, w, color
var position_z := 0.0                     # posição da câmara
var player_x := 0.0                       # -1..1 = estrada
var player_y := 0.0
var speed := 0.0
var high_gear := true
var steer := 0.0                          # -1..1 (para o desenho do carro)
var stage := 0
var branch := 0                           # posição no mapa de rotas (0..stage)
var route: Array[int] = [0]
var theme := "costa"
var time_left := START_TIME
var score := 0
var timer := 0.0
var crash_spin := 0.0
var _warned := false
var _touch_x: Variant = null
var _touch_count := 0
var _mouse_steer: Variant = null
var _mouse_gas := false
var _mouse_brake := false
var camera_depth := 1.0 / tan(deg_to_rad(FOV / 2.0))
var player_z := CAM_HEIGHT * camera_depth


func _init() -> void:
	_ensure_inputs()


static func _ensure_inputs() -> void:
	var defs := {
		"or_left": [_key(KEY_A), _key(KEY_LEFT), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"or_right": [_key(KEY_D), _key(KEY_RIGHT), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)],
		"or_gas": [_key(KEY_W), _key(KEY_UP), _joy_button(JOY_BUTTON_A), _joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)],
		"or_brake": [_key(KEY_S), _key(KEY_DOWN), _joy_button(JOY_BUTTON_B), _joy_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)],
		"or_gear": [_key(KEY_SPACE), _key(KEY_SHIFT), _joy_button(JOY_BUTTON_X), _joy_button(JOY_BUTTON_RIGHT_SHOULDER)],
	}
	for action: String in defs:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.25)
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


# ---------------------------------------------------------------- rotas e etapas

static func theme_for(s: int, b: int) -> String:
	return ROUTE_THEMES[s][b]


func kmh() -> int:
	return int(speed / MAX_SPEED * 290.0)


func segment_at(z: float) -> Dictionary:
	return seg(floori(z / SEG_LEN))


## Segmento i; depois do fim da etapa a estrada continua reta e plana (segmentos virtuais).
func seg(i: int) -> Dictionary:
	if i < segments.size():
		return segments[maxi(i, 0)]
	return {"index": i, "p1y": 0.0, "p2y": 0.0, "curve": 0.0, "sprites": [], "light": (i / 3) % 2 == 0, "fork": true}


## Afastamento de cada ramo da bifurcação no segmento i (0 = estrada única).
func fork_c(i: float) -> float:
	if stage >= STAGES - 1 or i < fork_start:
		return 0.0
	var p := clampf((i - fork_start) / 120.0, 0.0, 1.0)
	return _ease_in_out(0.0, FORK_MAX, p)


func on_road(x: float, i: float) -> bool:
	var c := fork_c(i)
	return absf(x) <= 1.0 + c and (c < 1.0 or absf(x) >= c - 1.0)


## Posição lateral de um carro (os carros seguem o seu ramo na bifurcação).
func car_x(car: Dictionary) -> float:
	var c := fork_c(car.z / SEG_LEN)
	return float(car.offset) + (c if car.offset >= 0.0 else -c)


func player_segment() -> Dictionary:
	return segment_at(position_z + player_z)


func stage_progress() -> float:
	return clampf((position_z + player_z) / track_len, 0.0, 1.0)


func is_ai() -> bool:
	return mode == Mode.DEMO


func set_skin(new_skin: OutRunSkin) -> void:
	if skin:
		skin.queue_free()
	skin = new_skin
	add_child(skin)
	skin.attach(self)


# ---------------------------------------------------------------- construção da estrada

static func _ease_in(a: float, b: float, p: float) -> float:
	return a + (b - a) * p * p


static func _ease_in_out(a: float, b: float, p: float) -> float:
	return a + (b - a) * (-cos(p * PI) / 2.0 + 0.5)


func _last_y() -> float:
	return 0.0 if segments.is_empty() else float(segments[-1].p2y)


func _add_segment(curve: float, y: float) -> void:
	var n := segments.size()
	segments.append({"index": n, "p1y": _last_y(), "p2y": y, "curve": curve, "sprites": [], "light": (n / 3) % 2 == 0, "fork": false})


func _add_road(enter: int, hold: int, leave: int, curve: float, height: float) -> void:
	var start_y := _last_y()
	var end_y := start_y + height * SEG_LEN
	var total := float(enter + hold + leave)
	for n in enter:
		_add_segment(_ease_in(0.0, curve, float(n) / enter), _ease_in_out(start_y, end_y, float(n) / total))
	for n in hold:
		_add_segment(curve, _ease_in_out(start_y, end_y, float(enter + n) / total))
	for n in leave:
		_add_segment(_ease_in_out(curve, 0.0, float(n) / leave), _ease_in_out(start_y, end_y, float(enter + hold + n) / total))


func _build_stage() -> void:
	segments.clear()
	cars.clear()
	theme = theme_for(stage, branch)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1986 + stage * 31 + branch * 7
	var intensity := 1.0 + stage * 0.1
	_add_road(10, 40, 10, 0.0, 0.0)
	var flat_height := 0.0
	while segments.size() < 2900:
		var kind := rng.randi() % 6
		var len_ := rng.randi_range(25, 60)
		match kind:
			0:
				_add_road(len_, len_, len_, 0.0, rng.randf_range(-1, 1) * 30.0 * intensity)
			1, 2:
				var c := rng.randf_range(1.5, 4.2) * intensity * (1.0 if rng.randf() < 0.5 else -1.0)
				_add_road(len_, len_, len_, c, rng.randf_range(-20, 20))
			3:
				var c := rng.randf_range(1.5, 3.5) * intensity
				_add_road(len_ / 2, len_ / 2, len_ / 2, c, 0.0)
				_add_road(len_ / 2, len_ / 2, len_ / 2, -c, 0.0)
			4:
				_add_road(len_, len_ / 2, len_, 0.0, rng.randf_range(20, 50) * (1.0 if rng.randf() < 0.5 else -1.0))
				_add_road(len_, len_ / 2, len_, 0.0, -rng.randf_range(10, 40))
			_:
				_add_road(10, len_, 10, 0.0, 0.0)
	# volta à altura 0 e acaba numa reta (a etapa seguinte começa igual: a passagem não se nota)
	_add_road(40, 40, 40, 0.0, -_last_y() / SEG_LEN)
	fork_start = segments.size()
	_add_road(10, FORK_LEN - 20, 10, 0.0, 0.0)
	track_len = segments.size() * SEG_LEN
	_ai_side = -1.0 if randf() < 0.5 else 1.0
	# cenário
	var pool: Array = SCENERY[theme]
	for i in range(40, fork_start, 1):
		if rng.randf() < 0.22:
			var item: Array = pool[rng.randi() % (pool.size() - 1)]
			var side := -1.0 if rng.randf() < 0.5 else 1.0
			_add_sprite(i, item, side * rng.randf_range(1.35, 2.6))
		if i % 120 == 0:
			_add_sprite(i, pool[pool.size() - 1], -1.4 if (i / 120) % 2 == 0 else 1.4)
	# bifurcação: placas de direção dos dois lados (e marca de partida/chegada no início)
	if stage < STAGES - 1:
		var left_name: String = I18n.t(THEME_NAMES[theme_for(stage + 1, branch)])
		var right_name: String = I18n.t(THEME_NAMES[theme_for(stage + 1, branch + 1)])
		for i in range(fork_start, segments.size()):
			segments[i].fork = true
		for i in range(fork_start - 60, segments.size() - 10, 16):
			var c := fork_c(i)
			_add_sprite(i, ["fork_left", 1100, 900], -(1.0 + c) - 0.4, left_name)
			_add_sprite(i, ["fork_right", 1100, 900], (1.0 + c) + 0.4, right_name)
			if c > 1.6:
				_add_sprite(i, ["fork_mid", 1000, 900], 0.0)
	else:
		_add_sprite(segments.size() - 4, ["goal", ROAD_W * 2.7, 1700], 0.0)
	if stage == 0:
		_add_sprite(8, ["start", ROAD_W * 2.7, 1700], 0.0)
	# trânsito
	var n_cars := 40 + stage * 10
	for k in n_cars:
		var ck: Array = CAR_KINDS[rng.randi() % CAR_KINDS.size()]
		var lane := rng.randi() % LANES
		cars.append({"z": rng.randf_range(0.08, 0.95) * track_len, "offset": -0.66 + lane * 0.66 + rng.randf_range(-0.1, 0.1),
			"speed": MAX_SPEED * float(ck[2]) * rng.randf_range(0.8, 1.1), "kind": ck[0], "w": ck[1], "color": rng.randi() % 6})


func _add_sprite(i: int, item: Array, offset: float, text := "") -> void:
	segments[i].sprites.append({"kind": item[0], "w": float(item[1]), "h": float(item[2]), "offset": offset, "text": text})


# ---------------------------------------------------------------- partida

func start(p_mode: Mode) -> void:
	mode = p_mode
	paused = false
	stage = 0
	branch = 0
	route = [0]
	score = 0
	time_left = START_TIME
	_warned = false
	_build_stage()
	stage_time = 0.0
	position_z = 0.0
	player_x = 0.0
	speed = 0.0
	high_gear = not manual_gears
	crash_spin = 0.0
	state = State.READY
	timer = 3.0 if mode == Mode.PLAY else 0.5
	race_started.emit()
	stage_started.emit(stage, theme)


# ---------------------------------------------------------------- ciclo

func _process(delta: float) -> void:
	if paused:
		return
	delta = minf(delta, 0.1)
	var steps := maxi(1, ceili(delta * 120.0))
	var dt := delta / steps
	for i in steps:
		_step(dt)


func _step(dt: float) -> void:
	_move_cars(dt)
	stage_time += dt
	match state:
		State.READY:
			var before := ceili(timer)
			timer -= dt
			if ceili(timer) != before and timer > 0.0:
				countdown.emit(ceili(timer))
			if timer <= 0.0:
				state = State.PLAY
				countdown.emit(0)
		State.PLAY:
			_drive(dt, true)
			_tick_time(dt)
		State.CRASH:
			timer -= dt
			crash_spin += dt * 9.0
			speed = move_toward(speed, 0.0, MAX_SPEED * 1.5 * dt)
			_advance(dt)
			_tick_time(dt)
			if timer <= 0.0 and state == State.CRASH:
				state = State.PLAY
				crash_spin = 0.0
				# volta para a estrada (na bifurcação, para o ramo mais próximo)
				var c := fork_c(player_segment().index)
				if c >= 1.0:
					var side := 1.0 if player_x >= 0.0 else -1.0
					player_x = side * clampf(absf(player_x), c - 0.7, c + 0.7)
				else:
					player_x = clampf(player_x, -0.7 - c, 0.7 + c)
				speed = 0.0
		State.OUT:
			speed = move_toward(speed, 0.0, MAX_SPEED * 0.35 * dt)
			_advance(dt)
			timer -= dt
			if timer <= 0.0:
				_finish()
		State.GOAL:
			speed = move_toward(speed, MAX_SPEED * 0.25, MAX_SPEED * 0.4 * dt)
			_drive(dt, false)
			timer -= dt
			if timer <= 0.0:
				_finish()
		State.OVER:
			if mode == Mode.DEMO:
				timer -= dt
				if timer <= 0.0:
					start(Mode.DEMO)


func _tick_time(dt: float) -> void:
	if mode == Mode.DEMO:
		time_left = maxf(time_left, 30.0)   # a demonstração não acaba por falta de tempo
	time_left -= dt
	if time_left <= 10.0 and not _warned:
		_warned = true
		time_warning.emit()
	if time_left <= 0.0:
		time_left = 0.0
		state = State.OUT
		timer = 3.0
		time_up.emit()


func _finish() -> void:
	state = State.OVER
	timer = 3.0
	game_over.emit()


# ---------------------------------------------------------------- condução

func _controls() -> Dictionary:
	if is_ai():
		return _ai()
	var c := {"steer": Input.get_axis("or_left", "or_right"), "gas": Input.is_action_pressed("or_gas"), "brake": Input.is_action_pressed("or_brake")}
	if _touch_x != null:
		c.steer = clampf(float(_touch_x) / 120.0, -1.0, 1.0)
		c.gas = _touch_count == 1
		c.brake = _touch_count >= 2
	elif _mouse_steer != null and (_mouse_gas or _mouse_brake) and is_zero_approx(c.steer):
		c.steer = clampf(float(_mouse_steer), -1.0, 1.0)
	c.gas = c.gas or _mouse_gas
	c.brake = c.brake or _mouse_brake
	return c


func _drive(dt: float, controlled: bool) -> void:
	var seg := player_segment()
	var pct := speed / MAX_SPEED
	var dx := dt * 2.0 * pct
	var c: Dictionary = _controls() if controlled else {"steer": 0.0, "gas": false, "brake": false}
	if not controlled:
		c.steer = clampf(-player_x * 2.0, -1.0, 1.0)
	steer = move_toward(steer, c.steer, dt * 6.0)
	player_x += dx * c.steer
	player_x -= dx * pct * seg.curve * CENTRIFUGAL
	if controlled:
		var accel := ACCEL
		var top := MAX_SPEED
		if manual_gears:
			# mudança baixa: arranca bem mas não passa dos 60%; alta: lenta a arrancar
			if high_gear:
				accel = ACCEL * (0.35 if pct < 0.45 else 1.0)
			else:
				top = MAX_SPEED * 0.6
				accel = ACCEL * 1.4
		if c.brake:
			speed += BRAKE * dt
		elif c.gas:
			speed = speed + accel * dt if speed < top else move_toward(speed, top, MAX_SPEED * 0.4 * dt)
		else:
			speed += DECEL * dt
	if not on_road(player_x, seg.index) and speed > OFFROAD_LIMIT:
		speed += OFFROAD_DECEL * dt
	var lim := 3.0 + fork_c(seg.index)
	player_x = clampf(player_x, -lim, lim)
	speed = clampf(speed, 0.0, MAX_SPEED)
	_advance(dt)
	if controlled:
		_collisions(seg)


func _advance(dt: float) -> void:
	var before := position_z
	position_z += speed * dt
	score += int(speed * dt * 0.5)
	var seg := player_segment()
	var pct := fmod(position_z + player_z, SEG_LEN) / SEG_LEN
	player_y = lerpf(float(seg.p1y), float(seg.p2y), pct)
	if position_z + player_z >= track_len - SEG_LEN * 2 and before + player_z < track_len - SEG_LEN * 2:
		_end_of_stage()


func _end_of_stage() -> void:
	if stage >= STAGES - 1:
		var bonus := int(time_left * 1000.0) * 10
		score += bonus
		state = State.GOAL
		timer = 5.0
		goal.emit(bonus)
		return
	# a escolha da bifurcação: lado da estrada em que o carro vai
	var side := 1.0 if player_x >= 0.0 else -1.0
	var c_end := fork_c(segments.size())
	if side > 0.0:
		branch += 1
	stage += 1
	route.append(branch)
	var bonus: float = CHECKPOINT_TIME[stage]
	time_left += bonus
	_warned = false
	var keep_x := player_x - side * c_end
	_build_stage()
	stage_time = 0.0
	position_z = 0.0
	player_x = keep_x
	checkpoint.emit(stage, bonus)
	stage_started.emit(stage, theme)


func _collisions(seg: Dictionary) -> void:
	# cenário (fora da estrada)
	if not on_road(player_x, seg.index) or absf(player_x) < 0.5:
		for i in range(seg.index - 1, mini(seg.index + 2, segments.size())):
			if i < 0:
				continue
			for sp: Dictionary in segments[i].sprites:
				if sp.kind == "start" or sp.kind == "goal":
					continue
				var sw: float = sp.w / ROAD_W
				var sx: float = sp.offset + (sw / 2.0 if sp.offset > 0.0 else (-sw / 2.0 if sp.offset < 0.0 else 0.0))
				if absf(player_x - sx) < (PLAYER_W + sw) / 2.0 * 0.8:
					_crash()
					return
	# trânsito
	var pz := position_z + player_z
	for car in cars:
		if car.speed < speed and absf(car.z - pz) < SEG_LEN * 1.2 and car.z > pz - SEG_LEN * 0.5:
			if absf(player_x - car_x(car)) < (PLAYER_W + car.w) / 2.0 * 0.85:
				if speed > MAX_SPEED * 0.55:
					_crash()
				else:
					speed = car.speed * 0.6
					position_z = car.z - player_z - SEG_LEN * 0.6
					bumped.emit()
				return


func _crash() -> void:
	state = State.CRASH
	timer = 2.2
	crash_spin = 0.0
	crashed.emit(Vector2(SCREEN.x / 2, SCREEN.y - 90))


func _move_cars(dt: float) -> void:
	for car in cars:
		car.z = fposmod(car.z + car.speed * dt, track_len)
		# os carros desviam-se suavemente do jogador quando vão à frente dele
		var pz := position_z + player_z
		var ahead: float = car.z - pz
		var cx := car_x(car)
		if ahead > 0.0 and ahead < SEG_LEN * 20 and absf(cx - player_x) < 0.5:
			var lo := 0.05 if car.offset >= 0.0 and fork_c(car.z / SEG_LEN) > 0.0 else -0.8
			var hi := -0.05 if car.offset < 0.0 and fork_c(car.z / SEG_LEN) > 0.0 else 0.8
			car.offset = move_toward(car.offset, clampf(car.offset + (0.4 if cx > player_x else -0.4), lo, hi), dt * 0.3)


# ---------------------------------------------------------------- entrada

func _unhandled_input(event: InputEvent) -> void:
	if paused or is_ai():
		return
	if event.is_action_pressed("or_gear") and manual_gears:
		high_gear = not high_gear
		gear_changed.emit(high_gear)
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	# Toque: arrastar para os lados vira (volante virtual); 1 dedo acelera, 2 dedos travam.
	if event is InputEventScreenTouch:
		_touch_count = maxi(0, _touch_count + (1 if event.pressed else -1))
		if event.pressed and _touch_count == 1:
			_touch_origin = event.position.x
			_touch_x = 0.0
		elif _touch_count == 0:
			_touch_x = null
	elif event is InputEventScreenDrag and _touch_x != null and event.index == 0:
		_touch_x = event.position.x - _touch_origin
	elif event is InputEventMouseMotion:
		_mouse_steer = (event.position.x - SCREEN.x / 2) / (SCREEN.x / 3)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_mouse_gas = event.pressed
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_mouse_brake = event.pressed


var _touch_origin := 0.0
var _ai_side := 1.0


func clear_input() -> void:
	_touch_x = null
	_touch_count = 0
	_mouse_gas = false
	_mouse_brake = false


# ---------------------------------------------------------------- CPU da demonstração

func _ai() -> Dictionary:
	var seg := player_segment()
	var target := 0.0
	# escolhe a faixa com menos trânsito à frente
	var pz := position_z + player_z
	var best_lane := 0.0
	var best_gap := -INF
	for lane: float in [-0.66, 0.0, 0.66]:
		var gap := SEG_LEN * 40.0
		for car in cars:
			var d: float = car.z - pz
			if d > 0.0 and d < gap and absf(car_x(car) - lane) < 0.45:
				gap = d
		gap -= absf(lane - player_x) * 300.0
		if gap > best_gap:
			best_gap = gap
			best_lane = lane
	target = best_lane
	# nas bifurcações, alterna entre esquerda e direita
	if seg.index >= fork_start - 40 and stage < STAGES - 1:
		var side := _ai_side
		target = side * fork_c(seg.index + 25) + side * 0.2
	# compensa a curva
	var look := segment_at(pz + SEG_LEN * 12)
	var curve := maxf(absf(float(look.curve)), absf(float(seg.curve)))
	target += float(look.curve) * 0.04
	var pct := speed / MAX_SPEED
	var steer_cmd := clampf((target - player_x) * 3.0 + float(seg.curve) * CENTRIFUGAL * pct, -1.0, 1.0)
	# trânsito à frente na faixa atual
	var gap_here := INF
	for car in cars:
		var d: float = car.z - pz
		if d > 0.0 and d < gap_here and absf(car_x(car) - player_x) < 0.4:
			gap_here = d
	var need := curve * CENTRIFUGAL * pct
	var brake := (gap_here < SEG_LEN * 6 and pct > 0.5) or need > 1.3
	var lift := need > 0.95 or (gap_here < SEG_LEN * 14 and pct > 0.6)
	return {"steer": steer_cmd, "gas": not brake and not lift, "brake": brake}
