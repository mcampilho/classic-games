class_name ValeGame
extends Node2D
## Espada do Vale — aventura original de vista aérea ao estilo de 1986: um vale de 4 x 3 ecrãs e
## uma masmorra de 6 salas. O herói luta com a espada, corta arbustos, junta moedas e chaves,
## abre portas trancadas e enfrenta o Guardião de Pedra para recuperar o Cristal do Vale.
## Coordenadas em casas (16 x 10 por ecrã).

signal match_started
signal room_changed(dungeon: bool, room: Vector2i, dir: Vector2i)
signal swung
signal hit_enemy(pos: Vector2)
signal enemy_killed(pos: Vector2, kind: String)
signal bush_cut(pos: Vector2)
signal picked(kind: String, pos: Vector2)
signal hurt
signal shot(pos: Vector2)
signal door_opened
signal key_appeared(pos: Vector2)
signal player_died
signal won
signal game_over

enum Mode { DEMO, PLAY }
enum State { READY, PLAY, SCROLL, DYING, WON, OVER }

const W := 16
const H := 10
const START_ROOM := Vector2i(1, 2)
const SPEED := 4.6
const SWING_TIME := 0.26
const SOLID := "TRWBSLX"
const ENEMY_HP := {"slime": 1, "bat": 1, "goblin": 2, "knight": 3, "boss": 12}
const ENEMY_SPEED := {"slime": 2.2, "bat": 3.0, "goblin": 1.8, "knight": 2.0, "boss": 1.6}
const POINTS := {"slime": 20, "bat": 30, "goblin": 50, "knight": 80, "boss": 1000}

## Ecrãs (16 x 10): . relva, , caminho, F flores, T árvore, R rocha, W água, B arbusto,
## D gruta, S muro, f chão, L porta trancada, X bloco; s/b/g/k/O inimigos; C moeda; h coração.
const OVERWORLD := {
	Vector2i(0, 0): [
		"TTTTTTTTTTTTTTTT",
		"T....F.........T",
		"T.TT.......BBB.T",
		"T.TT.......BhB.T",
		"T..........BBB.,",
		"T...s..........,",
		"T.TT.....TT....T",
		"T.TT....FTT..s.T",
		"T.....,,,,.....T",
		"TTTTTT,,,,TTTTTT",
	],
	Vector2i(1, 0): [
		"TTTTTTTTTTTTTTTT",
		"T....RR........T",
		"T..g.RR....C...T",
		"T..........RR..T",
		",,,,,,,,,,,,,,,,",
		",,,,,,,,,,,,,,,,",
		"T.......s......T",
		"T.TT.........F.T",
		"T..............T",
		"TTTTTT,,,,TTTTTT",
	],
	Vector2i(2, 0): [
		"TTTTTTTTTTTTTTTT",
		"T..WWWW........T",
		"T..WWWW.....b..T",
		"T..WWWW.b......T",
		",,,,,,,,,,,,,,,,",
		",,,,,,,,,,,,,,,,",
		"T.........RRR..T",
		"T............C.T",
		"T..............T",
		"TTTTTT,,,,TTTTTT",
	],
	Vector2i(3, 0): [
		"RRRRRRRRRRRRRRRR",
		"RRRRRRRRRRRRRRRR",
		"RRRRRRRDDRRRRRRR",
		"RRRRR..,,..RRRRR",
		",......,,......R",
		",......,,......R",
		"R...g......g...R",
		"R............RRR",
		"R..............R",
		"RRRRRR,,,,RRRRRR",
	],
	Vector2i(0, 1): [
		"TTTTTT,,,,TTTTTT",
		"T.....,,,,.....T",
		"T.WWW......TT..T",
		"T.WWW...s..TT..T",
		"T.WWW..........,",
		"T.WWW..........,",
		"T.WWW..F....s..T",
		"T.WWW..........T",
		"T..............T",
		"TTTTTT,,,,TTTTTT",
	],
	Vector2i(1, 1): [
		"TTTTTT,,,,TTTTTT",
		"T..............T",
		"T..TT......TT..T",
		"T..TT......TT..T",
		",....s.C.......,",
		",.......C.b....,",
		"T..TT......TT..T",
		"T..TT......TT..T",
		"T..............T",
		"TTTTTT,,,,TTTTTT",
	],
	Vector2i(2, 1): [
		"TTTTTT,,,,TTTTTT",
		"T..............T",
		"T..WWWWWWWWWWg.T",
		"T..WWWWWWWWWW..T",
		",..,,,,,,,,,,..,",
		",..,,,,,,,,,,..,",
		"T..WWWWWWWWWW..T",
		"T..WWWWWWWWWW..T",
		"T.F............T",
		"TTTTTT,,,,TTTTTT",
	],
	Vector2i(3, 1): [
		"TTTTTT,,,,TTTTTT",
		"T......C.......T",
		"T.RRR..BB......T",
		"T.RRR..BB...g..T",
		",..............T",
		",..............T",
		"T.........RRR..T",
		"T....s....RRR..T",
		"T..............T",
		"TTTTTT,,,,TTTTTT",
	],
	Vector2i(0, 2): [
		"TTTTTT,,,,TTTTTT",
		"T..............T",
		"T.TTT.....s....T",
		"T..............T",
		"T.....s....C...,",
		"T........WWWWW.,",
		"T.TTT....WWWWW.T",
		"T........WWWWW.T",
		"T..............T",
		"TTTTTTTTTTTTTTTT",
	],
	Vector2i(1, 2): [
		"TTTTTT,,,,TTTTTT",
		"T..............T",
		"T...........BB.T",
		"T..F...........T",
		",..............,",
		",..............,",
		"T.BB........F..T",
		"T....FTTTT.....T",
		"T..............T",
		"TTTTTTTTTTTTTTTT",
	],
	Vector2i(2, 2): [
		"TTTTTT,,,,TTTTTT",
		"T..............T",
		"T.TT...........T",
		"T.TT......RRR..T",
		",.........RRR..,",
		",.........RRR..,",
		"T.....s........T",
		"T...........b..T",
		"T.............CT",
		"TTTTTTTTTTTTTTTT",
	],
	Vector2i(3, 2): [
		"TTTTTT,,,,TTTTTT",
		"T..............T",
		"T............C.T",
		"T..RR..g.......T",
		",..RR..........T",
		",..............T",
		"T........RR....T",
		"T.BBB....RR.g..T",
		"T..............T",
		"TTTTTTTTTTTTTTTT",
	],
}
const DUNGEON := {
	Vector2i(0, 0): [
		"SSSSSSSSSSSSSSSS",
		"SffffffffffffffS",
		"SffXffffffffXffS",
		"SffffffffffffffS",
		"SffffffOfffffffL",
		"SffffffffffffffL",
		"SffffffffffffffS",
		"SffXffffffffXffS",
		"SffffffffffffffS",
		"SSSSSSSSSSSSSSSS",
	],
	Vector2i(1, 0): [
		"SSSSSSSSSSSSSSSS",
		"SffffffffffffffS",
		"SffffffhfffffffS",
		"SffffffffffffffS",
		"LfffXXffffXXffff",
		"LfffXXffffXXffff",
		"SffffffkfffffffS",
		"SffffffffffffffS",
		"SffffffffffffffS",
		"SSSSSSffffSSSSSS",
	],
	Vector2i(2, 0): [
		"SSSSSSSSSSSSSSSS",
		"SffffffffffffffS",
		"SffffffffffffffS",
		"SfffgffffffgfffS",
		"fffffffXXffffffS",
		"fffffffffffffffS",
		"SffffffffffffffS",
		"SffffffgfffffffS",
		"SffffffffffffffS",
		"SSSSSSSSSSSSSSSS",
	],
	Vector2i(0, 1): [
		"SSSSSSSSSSSSSSSS",
		"SffffffffffffffS",
		"SfXffffffffffffS",
		"SfffsfffffsffffS",
		"Sfffffffffffffff",
		"Sfffffffffffffff",
		"SffffffsffffsffS",
		"SffffffffffffXfS",
		"SffffffffffffffS",
		"SSSSSSSSSSSSSSSS",
	],
	Vector2i(1, 1): [
		"SSSSSSLLLLSSSSSS",
		"SffffffffffffffS",
		"SffXffffffffXffS",
		"SffffffffffffffS",
		"fffffkffffffffff",
		"ffffffffffkfffff",
		"SffffffffffffffS",
		"SffffffffffffffS",
		"SffffffffffffffS",
		"SSSSSSffffSSSSSS",
	],
	Vector2i(2, 1): [
		"SSSSSSSSSSSSSSSS",
		"SffffffffffffffS",
		"SffffffffffXfffS",
		"SffffbfffffXfffS",
		"ffffffffbffffffS",
		"fffffffffffffffS",
		"SfffXfffffbffffS",
		"SfffXffffffffffS",
		"SffffffffffffffS",
		"SSSSSSSSSSSSSSSS",
	],
}


var mode := Mode.DEMO
var state := State.READY
var paused := false
var skin: ValeSkin
var best := 0

var in_dungeon := false
var room := START_ROOM
var tiles: Array[String] = []          # cópia editável da sala atual
var prev_tiles: Array[String] = []     # sala anterior (para o deslizar do ecrã)
var scroll_dir := Vector2i.ZERO
var scroll_t := 0.0
var enemies: Array[Dictionary] = []    # kind, pos, dir, hp, t, hurt, cool
var shots: Array[Dictionary] = []      # pos, vel, kind
var drops: Array[Dictionary] = []      # pos, kind, life
var pos := Vector2(7.5, 6.5)
var facing := Vector2i(0, 1)
var moving := false
var anim := 0.0
var swing := 0.0
var hearts := 6                         # meios-corações
var max_hearts := 6
var coins := 0
var keys := 0
var lives := 3
var score := 0
var invuln := 0.0
var knock := Vector2.ZERO
var timer := 0.0
var taken := {}                         # objetos únicos já apanhados / portas abertas / salas limpas
var crystal := false
var _attack_buffer := 0.0
var _touch_index := -1
var _touch_origin := Vector2.ZERO
var _touch_dir := Vector2.ZERO
var ai := {"dir": Vector2i.ZERO, "attack": false}
var _ai_t := 0.0
var _ai_wander := Vector2i(1, 0)


func _init() -> void:
	_ensure_inputs()


static func _ensure_inputs() -> void:
	var defs := {
		"va_left": [_key(KEY_A), _key(KEY_LEFT), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"va_right": [_key(KEY_D), _key(KEY_RIGHT), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)],
		"va_up": [_key(KEY_W), _key(KEY_UP), _joy_button(JOY_BUTTON_DPAD_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)],
		"va_down": [_key(KEY_S), _key(KEY_DOWN), _joy_button(JOY_BUTTON_DPAD_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)],
		"va_attack": [_key(KEY_SPACE), _key(KEY_J), _key(KEY_Z), _key(KEY_X), _joy_button(JOY_BUTTON_A), _joy_button(JOY_BUTTON_B)],
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


func set_skin(new_skin: ValeSkin) -> void:
	if skin:
		skin.queue_free()
	skin = new_skin
	add_child(skin)
	skin.attach(self)


func is_ai() -> bool:
	return mode == Mode.DEMO


func room_key(d := in_dungeon, r := room) -> String:
	return "%s%d,%d" % ["d" if d else "o", r.x, r.y]


func tile(x: int, y: int) -> String:
	if y < 0 or y >= H or x < 0 or x >= W:
		return "."
	return tiles[y][x]


func solid_at(x: int, y: int) -> bool:
	if y < 0 or y >= H or x < 0 or x >= W:
		return false
	return SOLID.contains(tiles[y][x])


static func _world(d: bool) -> Dictionary:
	return DUNGEON if d else OVERWORLD


# ---------------------------------------------------------------- partida e salas

func start(p_mode: Mode, p_lives := 3) -> void:
	mode = p_mode
	paused = false
	lives = p_lives
	score = 0
	coins = 0
	keys = 0
	max_hearts = 6
	hearts = max_hearts
	taken.clear()
	crystal = false
	in_dungeon = false
	room = START_ROOM
	_load_room()
	pos = Vector2(7.5, 5.5)
	facing = Vector2i(0, 1)
	state = State.READY
	timer = 0.8 if mode == Mode.PLAY else 0.3
	match_started.emit()
	room_changed.emit(in_dungeon, room, Vector2i.ZERO)


func _load_room() -> void:
	var rows: Array = _world(in_dungeon)[room]
	tiles.clear()
	enemies.clear()
	_populated = false
	shots.clear()
	drops.clear()
	var key := room_key()
	var cleared := taken.has("clear " + key)
	for y in H:
		var row: String = rows[y]
		var out := ""
		for x in W:
			var ch := row[x]
			var center := Vector2(x + 0.5, y + 0.5)
			var floor_ch := "f" if in_dungeon else "."
			match ch:
				"s", "b", "g", "k", "O":
					if not cleared:
						var kind: String = {"s": "slime", "b": "bat", "g": "goblin", "k": "knight", "O": "boss"}[ch]
						enemies.append({"kind": kind, "pos": center, "dir": Vector2i(0, 1), "hp": ENEMY_HP[kind], "t": randf() * 1.5, "hurt": 0.0, "cool": randf_range(1.0, 2.5), "anim": randf()})
					out += floor_ch
				"C":
					if not taken.has("C%s %d,%d" % [key, x, y]):
						drops.append({"pos": center, "kind": "coin", "life": -1.0, "id": "C%s %d,%d" % [key, x, y]})
					out += floor_ch
				"h":
					if not taken.has("h" + key):
						drops.append({"pos": center, "kind": "container", "life": -1.0, "id": "h" + key})
					out += floor_ch
				"L":
					out += floor_ch if taken.has("L%s %d,%d" % [key, x, y]) else "L"
				_:
					out += ch
		tiles.append(out)
	# a chave aparece quando a sala fica limpa (salas com chave)
	if cleared and _room_has_key() and not taken.has("K" + key):
		drops.append({"pos": Vector2(7.5, 5.0), "kind": "key", "life": -1.0, "id": "K" + key})
	if cleared and in_dungeon and room == Vector2i(0, 0) and not crystal:
		drops.append({"pos": Vector2(7.5, 4.5), "kind": "crystal", "life": -1.0, "id": "crystal"})


func _room_has_key() -> bool:
	return in_dungeon and (room == Vector2i(0, 1) or room == Vector2i(2, 0))


func _go(dir: Vector2i) -> void:
	prev_tiles = tiles.duplicate()
	room += dir
	_load_room()
	scroll_dir = dir
	scroll_t = 0.0
	state = State.SCROLL
	if dir.x != 0:
		pos.x = 0.45 if dir.x > 0 else W - 0.45
	else:
		pos.y = 0.45 if dir.y > 0 else H - 0.45
	_ai_path.clear()
	room_changed.emit(in_dungeon, room, dir)


func _enter_dungeon(on: bool) -> void:
	prev_tiles = tiles.duplicate()
	in_dungeon = on
	room = Vector2i(1, 1) if on else Vector2i(3, 0)
	_load_room()
	pos = Vector2(7.5, 8.3) if on else Vector2(7.5, 3.7)
	facing = Vector2i(0, -1) if on else Vector2i(0, 1)
	scroll_dir = Vector2i.ZERO
	state = State.READY
	timer = 0.6
	room_changed.emit(in_dungeon, room, Vector2i.ZERO)


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
	_attack_buffer = maxf(_attack_buffer - dt, 0.0)
	match state:
		State.READY:
			timer -= dt
			if timer <= 0.0:
				state = State.PLAY
		State.SCROLL:
			scroll_t += dt / 0.55
			if scroll_t >= 1.0:
				scroll_t = 1.0
				state = State.PLAY
		State.PLAY:
			_move_hero(dt)
			if state != State.PLAY:
				return
			_move_enemies(dt)
			_move_shots(dt)
			_drops(dt)
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
					hearts = max_hearts
					in_dungeon = in_dungeon
					if in_dungeon:
						room = Vector2i(1, 1)
						_load_room()
						pos = Vector2(7.5, 8.3)
					else:
						room = START_ROOM
						_load_room()
						pos = Vector2(7.5, 5.5)
					invuln = 1.5
					state = State.READY
					timer = 0.8
					room_changed.emit(in_dungeon, room, Vector2i.ZERO)
		State.WON:
			timer -= dt
		State.OVER:
			if mode == Mode.DEMO:
				timer -= dt
				if timer <= 0.0:
					start(Mode.DEMO, 2)


# ---------------------------------------------------------------- herói

func _input_dir() -> Vector2i:
	if is_ai():
		return ai.dir
	var x := Input.get_axis("va_left", "va_right")
	var y := Input.get_axis("va_up", "va_down")
	if _touch_index >= 0 and _touch_dir.length() > 20.0:
		x = _touch_dir.x
		y = _touch_dir.y
	if absf(x) < 0.3 and absf(y) < 0.3:
		return Vector2i.ZERO
	# quatro direções, como no original
	if absf(x) > absf(y):
		return Vector2i(signi(int(signf(x))), 0)
	return Vector2i(0, signi(int(signf(y))))


func _box_free(p: Vector2, half := 0.34) -> bool:
	for c in [Vector2(-half, -half), Vector2(half, -half), Vector2(-half, half), Vector2(half, half)]:
		var q: Vector2 = p + c
		if solid_at(floori(q.x), floori(q.y)):
			return false
	return true


func _move_hero(dt: float) -> void:
	invuln = maxf(invuln - dt, 0.0)
	if swing > 0.0:
		swing -= dt
	var want_attack: bool = _attack_buffer > 0.0 or (is_ai() and ai.attack)
	if is_ai():
		ai.attack = false
	if want_attack and swing <= 0.0:
		_attack_buffer = 0.0
		swing = SWING_TIME
		swung.emit()
		_sword_hits()
	# recuo ao ser atingido
	if knock.length() > 0.01:
		var np := pos + knock * dt
		if _box_free(np):
			pos = np
		knock = knock.move_toward(Vector2.ZERO, 30.0 * dt)
	var d := _input_dir()
	moving = d != Vector2i.ZERO and swing <= 0.0
	if moving:
		facing = d
		anim += dt
		var v := Vector2(d) * SPEED * dt
		# alinhar ao meio-caminho no eixo perpendicular (ajuda a passar entre obstáculos)
		if d.x != 0:
			var target := roundf(pos.y * 2.0) / 2.0
			pos.y = move_toward(pos.y, target, SPEED * dt * 0.6)
		else:
			var target := roundf(pos.x * 2.0) / 2.0
			pos.x = move_toward(pos.x, target, SPEED * dt * 0.6)
		var np := pos + v
		if _box_free(np):
			pos = np
	# saídas do ecrã
	if pos.x < 0.0:
		_leave(Vector2i(-1, 0))
	elif pos.x > W:
		_leave(Vector2i(1, 0))
	elif pos.y < 0.0:
		_leave(Vector2i(0, -1))
	elif pos.y > H:
		_leave(Vector2i(0, 1))
	if state != State.PLAY:
		return
	# gruta da masmorra e portas trancadas
	var cell := Vector2i(floori(pos.x), floori(pos.y))
	if not in_dungeon and tile(cell.x, cell.y) == "D":
		_enter_dungeon(true)
		return
	if keys > 0:
		var ahead := Vector2i(floori(pos.x + facing.x * 0.6), floori(pos.y + facing.y * 0.6))
		if tile(ahead.x, ahead.y) == "L":
			keys -= 1
			_unlock(ahead)
	_touch_hazards()


func _leave(dir: Vector2i) -> void:
	if in_dungeon and room == Vector2i(1, 1) and dir == Vector2i(0, 1):
		_enter_dungeon(false)
		return
	var nxt := room + dir
	if _world(in_dungeon).has(nxt):
		_go(dir)
	else:
		pos = pos.clamp(Vector2(0.4, 0.4), Vector2(W - 0.4, H - 0.4))


func _unlock(c: Vector2i) -> void:
	# abre a porta inteira (todas as casas "L" ligadas)
	var key := room_key()
	for y in H:
		for x in W:
			if tiles[y][x] == "L" and Vector2i(x, y).distance_to(c) < 4.0:
				taken["L%s %d,%d" % [key, x, y]] = true
				var row := tiles[y]
				tiles[y] = row.substr(0, x) + "f" + row.substr(x + 1)
	door_opened.emit()


func sword_box() -> Rect2:
	var f := Vector2(facing)
	var c := pos + f * 0.85
	var size := Vector2(1.1, 0.7) if facing.x != 0 else Vector2(0.7, 1.1)
	return Rect2(c - size / 2, size)


func _sword_hits() -> void:
	var r := sword_box()
	for e in enemies:
		if e.hurt > 0.0:
			continue
		var er := Rect2((e.pos as Vector2) - enemy_size(e.kind) / 2, enemy_size(e.kind))
		if r.intersects(er):
			e.hp -= 1
			e.hurt = 0.35
			e.knock = Vector2(facing) * 8.0
			hit_enemy.emit(e.pos)
			if e.hp <= 0:
				_kill(e)
	# arbustos
	for y in range(floori(r.position.y), floori(r.end.y) + 1):
		for x in range(floori(r.position.x), floori(r.end.x) + 1):
			if tile(x, y) == "B":
				var row := tiles[y]
				tiles[y] = row.substr(0, x) + "." + row.substr(x + 1)
				bush_cut.emit(Vector2(x + 0.5, y + 0.5))
				var r2 := randf()
				if r2 < 0.25:
					drops.append({"pos": Vector2(x + 0.5, y + 0.5), "kind": "coin", "life": 8.0, "id": ""})
				elif r2 < 0.38:
					drops.append({"pos": Vector2(x + 0.5, y + 0.5), "kind": "heart", "life": 8.0, "id": ""})
	enemies = enemies.filter(func(e: Dictionary) -> bool: return e.hp > 0)
	if enemies.is_empty() and _room_was_populated():
		_room_cleared()


var _populated := false


func _room_was_populated() -> bool:
	return _populated


func _kill(e: Dictionary) -> void:
	score += POINTS[e.kind]
	enemy_killed.emit(e.pos, e.kind)
	if e.kind == "boss":
		return
	var r := randf()
	if r < 0.35:
		drops.append({"pos": e.pos, "kind": "coin", "life": 8.0, "id": ""})
	elif r < 0.55:
		drops.append({"pos": e.pos, "kind": "heart", "life": 8.0, "id": ""})


func _room_cleared() -> void:
	_populated = false
	var key := room_key()
	if in_dungeon:
		taken["clear " + key] = true
		if _room_has_key() and not taken.has("K" + key):
			drops.append({"pos": Vector2(7.5, 5.0), "kind": "key", "life": -1.0, "id": "K" + key})
			key_appeared.emit(Vector2(7.5, 5.0))
		if room == Vector2i(0, 0):
			drops.append({"pos": Vector2(7.5, 4.5), "kind": "crystal", "life": -1.0, "id": "crystal"})
			key_appeared.emit(Vector2(7.5, 4.5))


func _touch_hazards() -> void:
	if invuln > 0.0:
		return
	var me := Rect2(pos - Vector2(0.32, 0.32), Vector2(0.64, 0.64))
	for e in enemies:
		var s := enemy_size(e.kind) * 0.8
		if me.intersects(Rect2((e.pos as Vector2) - s / 2, s)):
			_damage(2 if e.kind == "boss" or e.kind == "knight" else 1, (pos - (e.pos as Vector2)).normalized())
			return
	for s in shots:
		if me.has_point(s.pos):
			shots.erase(s)
			_damage(1, (s.vel as Vector2).normalized())
			return


func _damage(n: int, from_dir: Vector2) -> void:
	hearts -= n
	invuln = 1.0
	knock = from_dir * 10.0
	hurt.emit()
	if hearts <= 0:
		hearts = 0
		state = State.DYING
		timer = 1.8
		player_died.emit()


func _drops(dt: float) -> void:
	var me := Rect2(pos - Vector2(0.4, 0.4), Vector2(0.8, 0.8))
	for i in range(drops.size() - 1, -1, -1):
		var d: Dictionary = drops[i]
		if d.life > 0.0:
			d.life -= dt
			if d.life <= 0.0:
				drops.remove_at(i)
				continue
		if me.has_point(d.pos):
			if d.id != "":
				taken[d.id] = true
			match d.kind:
				"coin":
					coins += 1
					score += 10
				"heart":
					hearts = mini(hearts + 2, max_hearts)
				"container":
					max_hearts += 2
					hearts = max_hearts
					score += 200
				"key":
					keys += 1
					score += 100
				"crystal":
					crystal = true
					score += 5000 + lives * 1000
					state = State.WON
					timer = 6.0
					if mode == Mode.PLAY:
						best = maxi(best, score)
					picked.emit(d.kind, d.pos)
					drops.remove_at(i)
					won.emit()
					return
			picked.emit(d.kind, d.pos)
			drops.remove_at(i)


# ---------------------------------------------------------------- inimigos

static func enemy_size(kind: String) -> Vector2:
	match kind:
		"boss":
			return Vector2(1.8, 1.8)
		"bat":
			return Vector2(0.7, 0.5)
	return Vector2(0.8, 0.8)


func _move_enemies(dt: float) -> void:
	if not enemies.is_empty():
		_populated = true
	for e in enemies:
		e.anim += dt
		e.hurt = maxf(float(e.hurt) - dt, 0.0)
		var p: Vector2 = e.pos
		if e.has("knock") and (e.knock as Vector2).length() > 0.1:
			var np: Vector2 = p + (e.knock as Vector2) * dt
			if e.kind == "bat" or _box_free(np, 0.36):
				p = np
			e.knock = (e.knock as Vector2).move_toward(Vector2.ZERO, 40.0 * dt)
			e.pos = p
			continue
		e.t -= dt
		var spd: float = ENEMY_SPEED[e.kind]
		match e.kind:
			"slime":
				if e.t <= 0.0:
					e.t = randf_range(0.6, 1.6)
					e.dir = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i.ZERO][randi() % 5]
				var hop := 0.5 + 0.5 * sin(float(e.anim) * 8.0)
				p = _try_move(p, Vector2(e.dir) * spd * hop * dt, 0.36)
			"bat":
				if e.t <= 0.0:
					e.t = randf_range(0.3, 0.9)
					e.vel = Vector2.from_angle(randf() * TAU) * spd
				var v: Vector2 = e.get("vel", Vector2.ZERO)
				p += v * dt
				if p.x < 1.0 or p.x > W - 1.0:
					e.vel = Vector2(-v.x, v.y)
				if p.y < 1.0 or p.y > H - 1.0:
					e.vel = Vector2(v.x, -v.y)
				p = p.clamp(Vector2(0.8, 0.8), Vector2(W - 0.8, H - 0.8))
			"goblin", "knight":
				if e.t <= 0.0:
					e.t = randf_range(0.8, 2.0)
					var to := pos - p
					if e.kind == "knight" or randf() < 0.4:
						e.dir = Vector2i(signi(int(signf(to.x))), 0) if absf(to.x) > absf(to.y) else Vector2i(0, signi(int(signf(to.y))))
					else:
						e.dir = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)][randi() % 4]
				var np := _try_move(p, Vector2(e.dir) * spd * dt, 0.36)
				if np == p:
					e.t = 0.0
				p = np
				if e.kind == "goblin":
					e.cool -= dt
					var to := pos - p
					var aligned: bool = (absf(to.x) < 0.5 and signi(int(signf(to.y))) == e.dir.y) or (absf(to.y) < 0.5 and signi(int(signf(to.x))) == e.dir.x)
					if e.cool <= 0.0 and aligned:
						e.cool = randf_range(1.6, 2.6)
						shots.append({"pos": p, "vel": Vector2(e.dir) * 7.0, "kind": "arrow"})
						shot.emit(p)
			"boss":
				if e.t <= 0.0:
					e.t = randf_range(1.0, 2.0)
					e.dir = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)][randi() % 4]
				p = _try_move(p, Vector2(e.dir) * spd * dt, 0.9)
				e.cool -= dt
				if e.cool <= 0.0:
					e.cool = 1.6 if e.hp > 5 else 1.0
					var to := (pos - p).normalized()
					for k in [-0.35, 0.0, 0.35]:
						shots.append({"pos": p, "vel": to.rotated(k) * 5.5, "kind": "fire"})
					shot.emit(p)
		e.pos = p


func _try_move(p: Vector2, v: Vector2, half: float) -> Vector2:
	var np := p + v
	if np.x < 1.0 or np.y < 1.0 or np.x > W - 1.0 or np.y > H - 1.0:
		return p
	return np if _box_free(np, half) else p


func _move_shots(dt: float) -> void:
	for s in shots:
		s.pos += s.vel * dt
	shots = shots.filter(func(s: Dictionary) -> bool:
		var p: Vector2 = s.pos
		if p.x < 0.0 or p.y < 0.0 or p.x > W or p.y > H:
			return false
		return s.kind == "fire" or not solid_at(floori(p.x), floori(p.y)))


# ---------------------------------------------------------------- entrada

func _unhandled_input(event: InputEvent) -> void:
	if paused or is_ai():
		return
	if event.is_action_pressed("va_attack"):
		_attack_buffer = 0.15
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	# Tátil: metade esquerda = joystick, metade direita = espada.
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < 640.0:
				_touch_index = event.index
				_touch_origin = event.position
				_touch_dir = Vector2.ZERO
			else:
				_attack_buffer = 0.15
		elif event.index == _touch_index:
			_touch_index = -1
			_touch_dir = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_touch_dir = event.position - _touch_origin


func clear_input() -> void:
	_touch_index = -1
	_touch_dir = Vector2.ZERO
	_attack_buffer = 0.0


func touch_stick() -> Variant:
	return _touch_origin if _touch_index >= 0 else null


# ---------------------------------------------------------------- CPU da demonstração

func _ai_think(delta: float) -> void:
	_ai_t -= delta
	ai.dir = Vector2i.ZERO
	# atacar o inimigo mais próximo, alinhando-se com ele
	var target: Variant = null
	var best_d := INF
	for e in enemies:
		var d := (e.pos as Vector2).distance_to(pos)
		if d < best_d:
			best_d = d
			target = e
	if target != null and best_d < 6.0:
		var to: Vector2 = (target.pos as Vector2) - pos
		if best_d < 1.3:
			facing = Vector2i(signi(int(signf(to.x))), 0) if absf(to.x) > absf(to.y) else Vector2i(0, signi(int(signf(to.y))))
			ai.attack = true
			if best_d < 0.8:
				ai.dir = -facing
			return
		ai.dir = Vector2i(signi(int(signf(to.x))), 0) if absf(to.x) > absf(to.y) else Vector2i(0, signi(int(signf(to.y))))
		var np := pos + Vector2(ai.dir) * 0.6
		if not _box_free(np):
			ai.dir = Vector2i(ai.dir.y, ai.dir.x)
		return
	# passear para outra sala (caminho mais curto até uma saída)
	if _ai_t <= 0.0 or _ai_path.is_empty():
		_ai_t = randf_range(4.0, 7.0)
		_ai_plan()
	if _ai_path.is_empty():
		return
	var nxt: Vector2i = _ai_path[0]
	var goal := Vector2(nxt) + Vector2(0.5, 0.5)
	var to2 := goal - pos
	if to2.length() < 0.2:
		_ai_path.remove_at(0)
		return
	ai.dir = Vector2i(signi(int(signf(to2.x))), 0) if absf(to2.x) > absf(to2.y) else Vector2i(0, signi(int(signf(to2.y))))


var _ai_path: Array[Vector2i] = []


func _ai_plan() -> void:
	_ai_path.clear()
	var here := Vector2i(clampi(floori(pos.x), 0, W - 1), clampi(floori(pos.y), 0, H - 1))
	var exits: Array[Vector2i] = []
	for x in W:
		for y in [0, H - 1]:
			if not solid_at(x, y):
				exits.append(Vector2i(x, y))
	for y in H:
		for x in [0, W - 1]:
			if not solid_at(x, y):
				exits.append(Vector2i(x, y))
	if exits.is_empty():
		return
	var goal := exits[randi() % exits.size()]
	var prev := {here: here}
	var q: Array[Vector2i] = [here]
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		if c == goal:
			break
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + d
			if n.x >= 0 and n.y >= 0 and n.x < W and n.y < H and not prev.has(n) and not solid_at(n.x, n.y):
				prev[n] = c
				q.append(n)
	if not prev.has(goal):
		return
	var c2 := goal
	while c2 != here:
		_ai_path.push_front(c2)
		c2 = prev[c2]
	# sair mesmo do ecrã
	var out := goal + (Vector2i(-1, 0) if goal.x == 0 else (Vector2i(1, 0) if goal.x == W - 1 else (Vector2i(0, -1) if goal.y == 0 else Vector2i(0, 1))))
	_ai_path.append(out)
