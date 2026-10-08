class_name RelicsGame
extends Node2D
## Torre das Relíquias — aventura isométrica original ao estilo dos jogos "Filmation" de 1984
## (Knight Lore): um castelo de 4 x 4 salas vistas em perspetiva isométrica. O explorador tem de
## recolher 8 relíquias e levá-las ao altar antes de acabarem os 30 dias. Há caixotes para
## empurrar, carregar e empilhar (larga-se um caixote debaixo dos pés a meio de um salto para
## subir), portas a várias alturas, espinhos, guardas, bolas saltitonas e fantasmas.
## Coordenadas: x e y em casas (0..8 por sala), z em alturas de bloco.

signal match_started
signal room_entered(room: Vector2i)
signal jumped
signal landed
signal picked(kind: String)
signal dropped
signal pushed
signal relic_taken(pos: Vector3)
signal heart_taken
signal relics_deposited(count: int, total: int)
signal player_died(pos: Vector3)
signal day_changed(day: int)
signal won
signal game_over

enum Mode { DEMO, PLAY }
enum State { READY, PLAY, DYING, WON, OVER }

const ROOM := 8
const MAP := Vector2i(4, 4)
const START_ROOM := Vector2i(1, 1)
const PLAYER_HALF := 0.28
const PLAYER_H := 1.3
const SPEED := 3.0
const JUMP_V := 6.6
const GRAVITY := 18.5
const DAY_SECONDS := 40.0
const DAYS := 30
const RELICS := 8
const DOOR_A := 3.0
const DOOR_B := 5.0
const ROOM_NAMES := {
	Vector2i(0, 0): "Sala das Armaduras", Vector2i(1, 0): "Corredor de Espinhos", Vector2i(2, 0): "Torre Alta", Vector2i(3, 0): "Sala das Bolas",
	Vector2i(0, 1): "Armazém", Vector2i(1, 1): "Capela do Altar", Vector2i(2, 1): "Escadaria", Vector2i(3, 1): "Labirinto de Espinhos",
	Vector2i(0, 2): "Salão de Jogos", Vector2i(1, 2): "Corredor da Guarda", Vector2i(2, 2): "Cripta", Vector2i(3, 2): "Cofre",
	Vector2i(0, 3): "Adega", Vector2i(1, 3): "Galeria", Vector2i(2, 3): "Patamar", Vector2i(3, 3): "Sótão",
}
## Salas (linhas = y, colunas = x): # bloco, 2/3 pilha de 2/3 blocos, * pilha de 2 com relíquia
## em cima, c caixote, ^ espinhos, r relíquia, v coração, g/G guarda (eixo x/y), b/B bola,
## h fantasma, A altar, P início.
const ROOMS := {
	Vector2i(0, 0): ["##......", "#r......", "........", "........", "........", "..g.....", "...#....", "........"],
	Vector2i(1, 0): ["........", ".^^^^^^.", ".^....^.", "...^^...", "...^^...", ".^....^.", ".^^^^^^.", "........"],
	Vector2i(2, 0): ["........", ".r......", "........", "...h....", ".....c..", "........", "........", "...22..."],
	Vector2i(3, 0): ["........", ".b......", "........", "...v....", "........", "......B.", "........", "........"],
	Vector2i(0, 1): ["........", ".*......", "........", "........", "....c...", "........", "........", "........"],
	Vector2i(1, 1): ["........", "........", "..#..#..", "........", "...A....", ".....P..", "..#..#..", "........"],
	Vector2i(2, 1): ["...##...", "........", "........", "..c.....", "........", "......g.", "........", "........"],
	Vector2i(3, 1): ["^^^..^^^", "^......^", "^.^^^^.^", "..^r.^..", "..^..^..", "^.^^.^.^", "^......^", "^^^..^^^"],
	Vector2i(0, 2): ["........", "..B.....", "........", "......r.", "........", ".b......", "........", "........"],
	Vector2i(1, 2): ["#......#", "........", "..g.....", "........", "........", ".....G..", "........", "#......#"],
	Vector2i(2, 2): ["........", ".#....#.", "........", "...hr...", "........", "........", ".#....#.", "........"],
	Vector2i(3, 2): [".....222", ".....2r2", ".....2c2", ".....222", "..c.....", "........", "........", "........"],
	Vector2i(0, 3): ["........", "........", "..v.....", "........", "........", "........", "....g...", "........"],
	Vector2i(1, 3): ["........", "..^^^^..", "........", "........", "........", "........", "..^^^^..", "........"],
	Vector2i(2, 3): ["........", "........", ".G......", ".......#", ".......#", "........", "........", "........"],
	Vector2i(3, 3): ["........", "........", "........", "#.......", "#....c..", "........", "......*.", "...b...."],
}
## Ligações: [sala A, sala B, altura da porta]. B fica a este (+x) ou a sul (+y) de A.
const LINKS := [
	[Vector2i(0, 0), Vector2i(1, 0), 0], [Vector2i(0, 0), Vector2i(0, 1), 0], [Vector2i(1, 0), Vector2i(1, 1), 0],
	[Vector2i(2, 0), Vector2i(2, 1), 2], [Vector2i(3, 0), Vector2i(3, 1), 0], [Vector2i(0, 1), Vector2i(1, 1), 0],
	[Vector2i(1, 1), Vector2i(2, 1), 0], [Vector2i(2, 1), Vector2i(3, 1), 0], [Vector2i(0, 1), Vector2i(0, 2), 0],
	[Vector2i(1, 1), Vector2i(1, 2), 0], [Vector2i(2, 1), Vector2i(2, 2), 0], [Vector2i(3, 1), Vector2i(3, 2), 0],
	[Vector2i(0, 2), Vector2i(1, 2), 0], [Vector2i(1, 2), Vector2i(2, 2), 0], [Vector2i(2, 2), Vector2i(3, 2), 0],
	[Vector2i(0, 2), Vector2i(0, 3), 0], [Vector2i(1, 2), Vector2i(1, 3), 0], [Vector2i(2, 2), Vector2i(2, 3), 0],
	[Vector2i(0, 3), Vector2i(1, 3), 0], [Vector2i(1, 3), Vector2i(2, 3), 0], [Vector2i(2, 3), Vector2i(3, 3), 1],
]

var mode := Mode.DEMO
var state := State.READY
var paused := false
var skin: RelicsSkin
var best := 0

var room := START_ROOM
var blocks: Array[Dictionary] = []    # pos (canto mínimo), size, kind (stone/crate/altar), vz
var items: Array[Dictionary] = []     # pos (centro da base), kind (relic/heart), id
var enemies: Array[Dictionary] = []   # kind, pos, dir, speed, phase
var spikes := {}                      # Vector2i -> true
var doors := {}                       # "N"/"S"/"W"/"E" -> altura
var pos := Vector3(5.5, 5.5, 0.0)     # centro da base do explorador
var vz := 0.0
var grounded := true
var facing := Vector2(1, 0)
var anim := 0.0
var moving := false
var carrying: Variant = null          # caixote ao colo
var entry := Vector3(5.5, 5.5, 0.0)
var entry_facing := Vector2(1, 0)
var lives := 5
var score := 0
var carried_relics := 0
var deposited := 0
var collected := {}                   # id -> true (relíquias e corações já apanhados)
var visited := {}
var clock := 0.0
var safe_t := 0.0                     # invulnerável logo depois de entrar numa sala
var timer := 0.0
var _jump_buffer := 0.0
var _action_buffer := 0.0
var _touch_index := -1
var _touch_origin := Vector2.ZERO
var _touch_dir := Vector2.ZERO
var ai := {"dir": Vector2.ZERO, "jump": false}
var _ai_path: Array[Vector2i] = []
var _ai_goal := Vector2i(-1, -1)
var _ai_t := 0.0


func _init() -> void:
	_ensure_inputs()


static func _ensure_inputs() -> void:
	var defs := {
		"rl_left": [_key(KEY_A), _key(KEY_LEFT), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"rl_right": [_key(KEY_D), _key(KEY_RIGHT), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)],
		"rl_up": [_key(KEY_W), _key(KEY_UP), _joy_button(JOY_BUTTON_DPAD_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)],
		"rl_down": [_key(KEY_S), _key(KEY_DOWN), _joy_button(JOY_BUTTON_DPAD_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)],
		"rl_jump": [_key(KEY_SPACE), _key(KEY_Z), _joy_button(JOY_BUTTON_A)],
		"rl_action": [_key(KEY_E), _key(KEY_X), _key(KEY_ENTER), _joy_button(JOY_BUTTON_X), _joy_button(JOY_BUTTON_B)],
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


func set_skin(new_skin: RelicsSkin) -> void:
	if skin:
		skin.queue_free()
	skin = new_skin
	add_child(skin)
	skin.attach(self)


func is_ai() -> bool:
	return mode == Mode.DEMO


func day() -> int:
	return mini(1 + int(clock / DAY_SECONDS), DAYS)


## 0..1 ao longo do dia (0 = madrugada, 0.5 = meio-dia).
func day_phase() -> float:
	return fmod(clock / DAY_SECONDS, 1.0)


func room_name() -> String:
	return I18n.t(ROOM_NAMES.get(room, ""))


static func link_height(a: Vector2i, b: Vector2i) -> int:
	for l: Array in LINKS:
		if (l[0] == a and l[1] == b) or (l[0] == b and l[1] == a):
			return l[2]
	return -1


# ---------------------------------------------------------------- partida e salas

func start(p_mode: Mode, p_lives := 5) -> void:
	mode = p_mode
	paused = false
	lives = p_lives
	score = 0
	carried_relics = 0
	deposited = 0
	collected.clear()
	visited.clear()
	clock = 0.0
	carrying = null
	room = START_ROOM
	match_started.emit()
	_load_room()
	var p: Vector2 = _find_char(ROOMS[room], "P")
	pos = Vector3(p.x + 0.5, p.y + 0.5, 0.0)
	entry = pos
	entry_facing = Vector2(-1, 0)
	facing = entry_facing
	state = State.READY
	timer = 1.0 if mode == Mode.PLAY else 0.3
	room_entered.emit(room)


static func _find_char(rows: Array, ch: String) -> Vector2:
	for y in rows.size():
		var x := (rows[y] as String).find(ch)
		if x >= 0:
			return Vector2(x, y)
	return Vector2(4, 4)


func _load_room() -> void:
	blocks.clear()
	items.clear()
	enemies.clear()
	spikes.clear()
	doors.clear()
	visited[room] = true
	var rows: Array = ROOMS[room]
	for y in ROOM:
		var row: String = rows[y]
		for x in ROOM:
			var ch := row[x]
			var cell := Vector3(x, y, 0)
			var center := Vector3(x + 0.5, y + 0.5, 0.0)
			match ch:
				"#", "2", "3", "*":
					var h := 1 if ch == "#" else (3 if ch == "3" else 2)
					blocks.append({"pos": cell, "size": Vector3(1, 1, h), "kind": "stone", "vz": 0.0})
					if ch == "*":
						_add_item("relic", center + Vector3(0, 0, h), "%d,%d" % [room.x, room.y])
				"c":
					blocks.append({"pos": cell + Vector3(0.05, 0.05, 0), "size": Vector3(0.9, 0.9, 1.0), "kind": "crate", "vz": 0.0})
				"A":
					blocks.append({"pos": cell, "size": Vector3(1, 1, 1), "kind": "altar", "vz": 0.0})
				"^":
					spikes[Vector2i(x, y)] = true
				"r":
					_add_item("relic", center, "%d,%d" % [room.x, room.y])
				"v":
					_add_item("heart", center, "v%d,%d" % [room.x, room.y])
				"g", "G", "b", "B":
					var d := Vector3(1, 0, 0) if ch == "g" or ch == "b" else Vector3(0, 1, 0)
					var k := "guard" if ch == "g" or ch == "G" else "ball"
					enemies.append({"kind": k, "pos": center, "dir": d, "speed": 1.6 if k == "guard" else 2.6, "phase": randf() * TAU})
				"h":
					enemies.append({"kind": "ghost", "pos": center + Vector3(0, 0, 0.3), "dir": Vector3.ZERO, "speed": 0.8, "phase": 0.0})
	for side: String in ["N", "S", "W", "E"]:
		var other: Vector2i = room + {"N": Vector2i(0, -1), "S": Vector2i(0, 1), "W": Vector2i(-1, 0), "E": Vector2i(1, 0)}[side]
		var h := link_height(room, other)
		if h >= 0:
			doors[side] = h


func _add_item(kind: String, p: Vector3, id: String) -> void:
	if collected.has(id):
		return
	items.append({"pos": p, "kind": kind, "id": id, "phase": randf() * TAU})


## Caixas sólidas das paredes (com as aberturas das portas).
func wall_boxes() -> Array:
	var out := []
	var big := 20.0
	for side: String in ["N", "S", "W", "E"]:
		var horiz := side == "N" or side == "S"
		var fixed := -1.0 if side == "N" or side == "W" else float(ROOM)
		var segs := []
		if doors.has(side):
			var dz: float = doors[side]
			segs.append([-1.0, DOOR_A, 0.0, big])
			segs.append([DOOR_B, ROOM + 1.0, 0.0, big])
			if dz > 0.0:
				segs.append([DOOR_A, DOOR_B, 0.0, dz])
			segs.append([DOOR_A, DOOR_B, dz + 2.0, big])
		else:
			segs.append([-1.0, ROOM + 1.0, 0.0, big])
		for s: Array in segs:
			var a: float = s[0]
			var b: float = s[1]
			if horiz:
				out.append(AABB(Vector3(a, fixed, s[2]), Vector3(b - a, 1.0, float(s[3]) - float(s[2]))))
			else:
				out.append(AABB(Vector3(fixed, a, s[2]), Vector3(1.0, b - a, float(s[3]) - float(s[2]))))
	return out


func block_aabb(b: Dictionary) -> AABB:
	return AABB(b.pos, b.size)


func player_aabb(p := pos) -> AABB:
	return AABB(Vector3(p.x - PLAYER_HALF, p.y - PLAYER_HALF, p.z), Vector3(PLAYER_HALF * 2, PLAYER_HALF * 2, PLAYER_H))


static func _overlap(a: AABB, b: AABB, eps := 0.001) -> bool:
	return a.position.x < b.end.x - eps and a.end.x > b.position.x + eps \
		and a.position.y < b.end.y - eps and a.end.y > b.position.y + eps \
		and a.position.z < b.end.z - eps and a.end.z > b.position.z + eps


## Altura da superfície mais alta debaixo de uma caixa (que não esteja acima de `max_z`).
func support_under(box: AABB, max_z: float, ignore: Variant = null) -> float:
	var best_z := 0.0
	for b in blocks:
		if ignore != null and b == ignore:
			continue
		var bb := block_aabb(b)
		if bb.end.z <= max_z + 0.02 and box.position.x < bb.end.x - 0.02 and box.end.x > bb.position.x + 0.02 \
				and box.position.y < bb.end.y - 0.02 and box.end.y > bb.position.y + 0.02:
			best_z = maxf(best_z, bb.end.z)
	for w: AABB in wall_boxes():
		if w.end.z <= max_z + 0.02 and box.position.x < w.end.x and box.end.x > w.position.x and box.position.y < w.end.y and box.end.y > w.position.y:
			best_z = maxf(best_z, w.end.z)
	return best_z


func _blocked(box: AABB, ignore: Variant = null) -> Variant:
	for b in blocks:
		if ignore != null and b == ignore:
			continue
		if _overlap(box, block_aabb(b)):
			return b
	for w: AABB in wall_boxes():
		if _overlap(box, w):
			return w
	return null


# ---------------------------------------------------------------- ciclo

func _process(delta: float) -> void:
	if paused:
		return
	delta = minf(delta, 0.1)
	if is_ai() and state == State.PLAY:
		_ai_think(delta)
	var steps := maxi(1, ceili(delta * 240.0))
	var dt := delta / steps
	for i in steps:
		_step(dt)


func _step(dt: float) -> void:
	_jump_buffer = maxf(_jump_buffer - dt, 0.0)
	_action_buffer = maxf(_action_buffer - dt, 0.0)
	for e in enemies:
		e.phase += dt
	for it in items:
		it.phase += dt
	match state:
		State.READY:
			timer -= dt
			if timer <= 0.0:
				state = State.PLAY
		State.PLAY:
			var d0 := day()
			clock += dt
			if day() != d0:
				day_changed.emit(day())
			if clock >= DAY_SECONDS * DAYS:
				state = State.OVER
				timer = 3.0
				game_over.emit()
				return
			safe_t = maxf(safe_t - dt, 0.0)
			_move_player(dt)
			if state != State.PLAY:
				return
			_move_crates(dt)
			_move_enemies(dt)
			_check_hazards()
		State.DYING:
			timer -= dt
			if timer <= 0.0:
				lives -= 1
				if lives <= 0:
					state = State.OVER
					timer = 3.0
					if mode == Mode.PLAY:
						best = maxi(best, score)
					game_over.emit()
				else:
					_load_room()
					pos = entry
					facing = entry_facing
					vz = 0.0
					carrying = null
					safe_t = 1.5
					state = State.READY
					timer = 0.8
		State.WON:
			timer -= dt
		State.OVER:
			if mode == Mode.DEMO:
				timer -= dt
				if timer <= 0.0:
					start(Mode.DEMO, 3)


# ---------------------------------------------------------------- explorador

## Direção pedida, já convertida para o chão isométrico (cima no ecrã = -x -y).
func _input_dir() -> Vector2:
	if is_ai():
		return ai.dir
	var sx := Input.get_axis("rl_left", "rl_right")
	var sy := Input.get_axis("rl_up", "rl_down")
	if _touch_index >= 0 and _touch_dir.length() > 20.0:
		sx = _touch_dir.x
		sy = _touch_dir.y
	var v := Vector2(sx, sy)
	if v.length() < 0.3:
		return Vector2.ZERO
	# 8 direções no ecrã -> eixos do mundo (as diagonais do ecrã são os eixos do mundo)
	var a := snappedf(v.angle(), PI / 4)
	var s := Vector2.from_angle(a)
	return Vector2(s.x + s.y, s.y - s.x).normalized()


func _move_player(dt: float) -> void:
	var d := _input_dir()
	moving = d.length() > 0.1
	if moving:
		facing = d
		anim += dt
		_move_axis(0, d.x * SPEED * dt)
		_move_axis(1, d.y * SPEED * dt)
	var want_jump: bool = _jump_buffer > 0.0 or (is_ai() and ai.jump)
	if is_ai():
		ai.jump = false
	if want_jump and grounded:
		_jump_buffer = 0.0
		vz = JUMP_V
		grounded = false
		jumped.emit()
	if _action_buffer > 0.0:
		_action_buffer = 0.0
		_action()
	# vertical
	var was := grounded
	vz -= GRAVITY * dt
	var nz := pos.z + vz * dt
	var box := player_aabb()
	if vz <= 0.0:
		var sup := support_under(box, pos.z)
		if nz <= sup:
			nz = sup
			vz = 0.0
			grounded = true
			if not was:
				landed.emit()
		else:
			grounded = false
	else:
		var test := player_aabb(Vector3(pos.x, pos.y, nz))
		if _blocked(test) != null:
			nz = pos.z
			vz = 0.0
		grounded = false
	pos.z = nz
	_check_exit()
	_pickups()


func _move_axis(axis: int, delta: float) -> void:
	if absf(delta) < 0.00001:
		return
	var np := pos
	np[axis] += delta
	var box := player_aabb(np)
	var hit: Variant = _blocked(box)
	if hit == null:
		pos = np
		return
	# degrau baixo: sobe sozinho
	if hit is Dictionary:
		var top: float = (hit.pos as Vector3).z + (hit.size as Vector3).z
		if top - pos.z <= 0.3 and _blocked(player_aabb(Vector3(np.x, np.y, top))) == null:
			pos = Vector3(np.x, np.y, top)
			return
		# empurrar caixotes
		if hit.kind == "crate" and grounded:
			var cp: Vector3 = hit.pos
			cp[axis] += delta
			var cb := AABB(cp, hit.size)
			if _blocked(cb, hit) == null and not _player_on(hit):
				hit.pos = cp
				pos = np
				pushed.emit()
				return


func _player_on(b: Dictionary) -> bool:
	var bb := block_aabb(b)
	var pb := player_aabb()
	return absf(pos.z - bb.end.z) < 0.05 and pb.position.x < bb.end.x and pb.end.x > bb.position.x and pb.position.y < bb.end.y and pb.end.y > bb.position.y


func _action() -> void:
	if carrying == null:
		# apanhar o caixote à frente (ou debaixo dos pés não)
		var probe := Vector3(pos.x + facing.x * 0.7, pos.y + facing.y * 0.7, pos.z + 0.3)
		for b in blocks:
			if b.kind != "crate":
				continue
			var bb := block_aabb(b).grow(0.15)
			if bb.has_point(probe) and _nothing_on(b):
				blocks.erase(b)
				carrying = b
				picked.emit("crate")
				return
		return
	var crate: Dictionary = carrying
	var size: Vector3 = crate.size
	# a meio de um salto, bem acima do chão: larga debaixo dos pés
	var under := support_under(player_aabb(), pos.z)
	if not grounded and pos.z - under >= size.z - 0.02:
		var cell := Vector2(floorf(pos.x) + 0.05, floorf(pos.y) + 0.05)
		var cb := AABB(Vector3(cell.x, cell.y, under), size)
		if _blocked(cb) == null:
			crate.pos = cb.position
			blocks.append(crate)
			carrying = null
			pos.z = maxf(pos.z, cb.end.z)
			vz = 0.0
			dropped.emit()
			return
	# senão, à frente
	var fc := Vector2(floorf(pos.x + facing.x * 0.9), floorf(pos.y + facing.y * 0.9))
	if fc.x < 0 or fc.y < 0 or fc.x >= ROOM or fc.y >= ROOM:
		return
	var probe_box := AABB(Vector3(fc.x + 0.05, fc.y + 0.05, 0.0), Vector3(size.x, size.y, 0.1))
	var z := support_under(probe_box, pos.z + 1.05)
	var cb2 := AABB(Vector3(fc.x + 0.05, fc.y + 0.05, z), size)
	if _blocked(cb2) == null and not _overlap(cb2, player_aabb()):
		crate.pos = cb2.position
		crate.vz = 0.0
		blocks.append(crate)
		carrying = null
		dropped.emit()


func _nothing_on(b: Dictionary) -> bool:
	var bb := block_aabb(b)
	var above := AABB(Vector3(bb.position.x, bb.position.y, bb.end.z), Vector3(bb.size.x, bb.size.y, 0.2))
	for o in blocks:
		if o != b and _overlap(above, block_aabb(o)):
			return false
	return not _player_on(b)


func _move_crates(dt: float) -> void:
	for b in blocks:
		if b.kind != "crate":
			continue
		var bb := block_aabb(b)
		var sup := support_under(bb, bb.position.z, b)
		if bb.position.z > sup + 0.001:
			b.vz -= GRAVITY * dt
			var nz := maxf(bb.position.z + b.vz * dt, sup)
			b.pos = Vector3(bb.position.x, bb.position.y, nz)
			if nz <= sup:
				b.vz = 0.0
		else:
			b.vz = 0.0


func _check_exit() -> void:
	var side := ""
	var next := room
	if pos.x < 0.0:
		side = "W"
		next += Vector2i(-1, 0)
	elif pos.x > ROOM:
		side = "E"
		next += Vector2i(1, 0)
	elif pos.y < 0.0:
		side = "N"
		next += Vector2i(0, -1)
	elif pos.y > ROOM:
		side = "S"
		next += Vector2i(0, 1)
	if side == "":
		return
	room = next
	_load_room()
	match side:
		"W":
			pos.x = ROOM - 0.35
		"E":
			pos.x = 0.35
		"N":
			pos.y = ROOM - 0.35
		"S":
			pos.y = 0.35
	# chegar acima do chão: assenta na superfície que houver
	var sup := support_under(player_aabb(Vector3(pos.x, pos.y, pos.z + 0.01)), pos.z + 0.01)
	pos.z = maxf(sup, 0.0) if pos.z - sup < 0.05 else pos.z
	entry = pos
	entry_facing = facing
	safe_t = 1.2
	_ai_path.clear()
	_ai_goal = Vector2i(-1, -1)
	room_entered.emit(room)


func _pickups() -> void:
	var pb := player_aabb()
	for i in range(items.size() - 1, -1, -1):
		var it: Dictionary = items[i]
		var ib := AABB(it.pos - Vector3(0.3, 0.3, 0.0), Vector3(0.6, 0.6, 0.6))
		if _overlap(pb, ib, 0.0):
			collected[it.id] = true
			items.remove_at(i)
			if it.kind == "relic":
				carried_relics += 1
				score += 500
				relic_taken.emit(it.pos)
			else:
				lives += 1
				heart_taken.emit()
	# entregar as relíquias no altar
	if carried_relics > 0:
		for b in blocks:
			if b.kind == "altar" and block_aabb(b).grow(0.25).intersects(pb):
				deposited += carried_relics
				score += 1000 * carried_relics
				carried_relics = 0
				relics_deposited.emit(deposited, RELICS)
				if deposited >= RELICS:
					score += (DAYS - day() + 1) * 1000
					state = State.WON
					timer = 6.0
					if mode == Mode.PLAY:
						best = maxi(best, score)
					won.emit()
				break


# ---------------------------------------------------------------- perigos

func _move_enemies(dt: float) -> void:
	for e in enemies:
		var p: Vector3 = e.pos
		match e.kind:
			"ghost":
				var to := Vector3(pos.x, pos.y, pos.z + 0.3) - p
				p += to.normalized() * float(e.speed) * dt if to.length() > 0.05 else Vector3.ZERO
				e.pos = p
			_:
				var d: Vector3 = e.dir
				var np := p + d * float(e.speed) * dt
				var half := 0.3
				var box := AABB(Vector3(np.x - half, np.y - half, 0.0), Vector3(half * 2, half * 2, 1.0))
				var out := np.x < 0.3 or np.y < 0.3 or np.x > ROOM - 0.3 or np.y > ROOM - 0.3
				if out or _blocked(box) != null or (e.kind == "guard" and spikes.has(Vector2i(floori(np.x), floori(np.y)))):
					e.dir = -d
				else:
					e.pos = np


func enemy_z(e: Dictionary) -> float:
	if e.kind == "ball":
		return absf(sin(float(e.phase) * 5.0)) * 0.8
	return float(e.pos.z)


func _check_hazards() -> void:
	if safe_t > 0.0:
		return
	var pb := player_aabb().grow(-0.05)
	for e in enemies:
		var p: Vector3 = e.pos
		var z := enemy_z(e)
		var eb := AABB(Vector3(p.x - 0.3, p.y - 0.3, z), Vector3(0.6, 0.6, 0.9))
		if _overlap(pb, eb):
			_die()
			return
	if grounded and pos.z < 0.05 and spikes.has(Vector2i(floori(pos.x), floori(pos.y))):
		_die()


func _die() -> void:
	if state != State.PLAY:
		return
	state = State.DYING
	timer = 1.6
	player_died.emit(pos)


# ---------------------------------------------------------------- entrada

func _unhandled_input(event: InputEvent) -> void:
	if paused or is_ai():
		return
	if event.is_action_pressed("rl_jump"):
		_jump_buffer = 0.15
	if event.is_action_pressed("rl_action"):
		_action_buffer = 0.15
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	# Tátil: metade esquerda = joystick; metade direita: em cima salta, em baixo pega/larga.
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < 640.0:
				_touch_index = event.index
				_touch_origin = event.position
				_touch_dir = Vector2.ZERO
			elif event.position.y < 400.0:
				_jump_buffer = 0.15
			else:
				_action_buffer = 0.15
		elif event.index == _touch_index:
			_touch_index = -1
			_touch_dir = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_touch_dir = event.position - _touch_origin


func clear_input() -> void:
	_touch_index = -1
	_touch_dir = Vector2.ZERO
	_jump_buffer = 0.0
	_action_buffer = 0.0


func touch_stick() -> Variant:
	return _touch_origin if _touch_index >= 0 else null


# ---------------------------------------------------------------- CPU da demonstração

## A demonstração passeia pelo chão: vai buscar relíquias ao nível do chão e muda de sala.
func _ai_think(delta: float) -> void:
	_ai_t -= delta
	ai.dir = Vector2.ZERO
	if not grounded:
		return
	var here := Vector2i(floori(pos.x), floori(pos.y))
	if _ai_path.is_empty() or _ai_t <= 0.0:
		_ai_t = 1.0
		_ai_plan(here)
	if _ai_path.is_empty():
		return
	var nxt := _ai_path[0]
	var target := Vector2(nxt.x + 0.5, nxt.y + 0.5)
	if nxt.x < 0 or nxt.y < 0 or nxt.x >= ROOM or nxt.y >= ROOM:
		target = Vector2(clampf(nxt.x + 0.5, -1.0, ROOM + 1.0), clampf(nxt.y + 0.5, -1.0, ROOM + 1.0))
	var to := target - Vector2(pos.x, pos.y)
	if to.length() < 0.1:
		_ai_path.remove_at(0)
		return
	# perigo por perto: esperar
	for e in enemies:
		var ep: Vector3 = e.pos
		if Vector2(ep.x, ep.y).distance_to(target) < 1.0 and e.kind != "ghost":
			return
	ai.dir = to.normalized()


func _ai_free(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= ROOM or c.y >= ROOM:
		return false
	if spikes.has(c):
		return false
	var box := AABB(Vector3(c.x + 0.2, c.y + 0.2, 0.0), Vector3(0.6, 0.6, 1.0))
	return _blocked(box) == null


func _ai_plan(here: Vector2i) -> void:
	_ai_path.clear()
	var prev := {here: here}
	var queue: Array[Vector2i] = [here]
	var goals := {}
	for it in items:
		var ip: Vector3 = it.pos
		if ip.z < 0.1:
			goals[Vector2i(floori(ip.x), floori(ip.y))] = 3
	# portas ao nível do chão (a sala seguinte é escolhida ao acaso)
	var door_cells := {"N": Vector2i(3 + randi() % 2, 0), "S": Vector2i(3 + randi() % 2, 7), "W": Vector2i(0, 3 + randi() % 2), "E": Vector2i(7, 3 + randi() % 2)}
	var sides: Array = doors.keys()
	sides.shuffle()
	var exit_side := ""
	for s: String in sides:
		if doors[s] == 0:
			exit_side = s
			goals[door_cells[s]] = 1
			break
	var found := Vector2i(-1, -1)
	var best_score := -1
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		if goals.has(c) and int(goals[c]) > best_score:
			best_score = goals[c]
			found = c
			if best_score >= 3:
				break
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + d
			if not prev.has(n) and _ai_free(n):
				prev[n] = c
				queue.append(n)
	if found.x < 0:
		return
	var c2 := found
	while c2 != here:
		_ai_path.push_front(c2)
		c2 = prev[c2]
	if best_score == 1 and exit_side != "":
		var out: Vector2i = found + {"N": Vector2i(0, -1), "S": Vector2i(0, 1), "W": Vector2i(-1, 0), "E": Vector2i(1, 0)}[exit_side]
		_ai_path.append(out)
