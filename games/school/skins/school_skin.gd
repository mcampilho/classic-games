class_name SchoolSkin
extends Node2D
## Base dos estilos dos Sarilhos na Escola: a escola inteira (3600 x 600) é pintada uma vez numa
## textura e a câmara mostra a parte onde está o Zé; por cima, quadros escritos à mão, escudos,
## cofre, personagens (um "esqueleto" simples animado por poses), fisgadas, balões de fala e o
## painel com o horário, as linhas e o segredo do cofre. Os estilos escolhem o aspeto.

const VIEW_H := 600.0
const LIMB := 13.0

var game: SchoolGame
var sfx := {}
var time := 0.0
var vp: SubViewport
var _paint: Node2D
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _flash := 0.0


func attach(g: SchoolGame) -> void:
	game = g
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	vp = SubViewport.new()
	vp.size = Vector2i(int(SchoolGame.WORLD_W), int(VIEW_H))
	vp.disable_3d = true
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	_paint = Node2D.new()
	vp.add_child(_paint)
	_paint.draw.connect(func() -> void: _paint_world(_paint))
	g.bell.connect(func(_p: Dictionary) -> void: play("bell"))
	g.lines_given.connect(func(_n: int, _w: String, _r: String) -> void: play("lines"))
	g.shield_hit.connect(func(_i: int) -> void: play("shield"))
	g.all_shields.connect(func() -> void: play("all"))
	g.letter_found.connect(func(_i: int, _l: String) -> void: play("letter"))
	g.safe_opened.connect(func() -> void:
		play("safe")
		_flash = 1.0)
	g.knocked.connect(func(_id: int) -> void: play("knock", randf_range(0.9, 1.1)))
	g.fired.connect(func(_h: bool) -> void: play("fire", randf_range(0.95, 1.05), -3.0))
	g.punched.connect(func() -> void: play("punch"))
	g.jumped.connect(func() -> void: play("jump", 1.0, -6.0))
	g.expelled.connect(func() -> void: play("expelled"))
	var cached: Variant = Synth.cache_get(get_script().resource_path)
	if cached != null:
		sfx = cached
	else:
		_build_sfx()
		Synth.cache_set(get_script().resource_path, sfx)
	_setup()


func play(id: String, pitch := 1.0, volume_db := 0.0) -> void:
	if game == null or game.mode == SchoolGame.Mode.DEMO or not sfx.has(id):
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = sfx[id]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


func _process(delta: float) -> void:
	if game == null:
		return
	if not game.paused:
		time += delta
		_flash = maxf(_flash - delta, 0.0)
		_tick(delta)
	queue_redraw()


## Posição no ecrã de um ponto do mundo.
func scr(p: Vector2) -> Vector2:
	return Vector2(p.x - game.cam_x, p.y)


func floor_top(f: int) -> float:
	return float(SchoolGame.FLOOR_Y[f]) - SchoolGame.ROOM_H


# ---------------------------------------------------------------- figura

## Pontos do corpo de uma personagem (no ecrã). Ângulos a partir da vertical, positivos para a frente.
func rig(c: Dictionary) -> Dictionary:
	var s := 1.22 if c.role == "teacher" else 1.0
	var f := float(c.facing)
	var feet := scr(Vector2(c.x, c.y))
	var lift := game.jump_height(c) + game.stand_height(c)
	var p := {"hip": -2.0 * LIMB, "lean": 0.0, "th_f": 0.06, "sh_f": 0.0, "th_b": -0.06, "sh_b": 0.0,
		"ua_f": 0.15, "fa_f": 0.25, "ua_b": -0.12, "fa_b": 0.15}
	var act := String(c.act)
	var at := float(c.act_t)
	if c.moving and int(c.stair) < 0:
		var w := sin(float(c.anim) * 11.0)
		p.th_f = 0.55 * w
		p.th_b = -0.55 * w
		p.sh_f = maxf(-w, 0.0) * 0.9 + 0.1
		p.sh_b = maxf(w, 0.0) * 0.9 + 0.1
		p.ua_f = -0.5 * w
		p.ua_b = 0.5 * w
		p.fa_f = 0.5
		p.fa_b = 0.5
		p.hip -= absf(w) * 1.5
	elif c.moving:
		# escadas: um pé acima do outro
		var w := sin(float(c.anim) * 9.0)
		p.th_f = 0.6 + 0.3 * w
		p.sh_f = 0.6 + 0.3 * w
		p.th_b = 0.1 - 0.3 * w
		p.sh_b = 0.3
	if c.sit:
		p.hip = -1.4 * LIMB
		p.th_f = PI / 2
		p.th_b = PI / 2 - 0.1
		p.sh_f = PI / 2
		p.sh_b = PI / 2 - 0.15
		p.ua_f = 0.6
		p.fa_f = 1.4
	if float(c.jump_t) >= 0.0:
		p.th_f = 0.9
		p.sh_f = 1.4
		p.th_b = 0.3
		p.sh_b = 1.0
		p.ua_f = 2.7
		p.ua_b = 2.4
		p.fa_f = 2.8
		p.fa_b = 2.5
	if act == "fire" and at < 0.35:
		p.ua_f = PI / 2
		p.fa_f = PI / 2
		p.ua_b = 1.2
		p.fa_b = 2.2
	elif act == "punch" and at < 0.3:
		var e := sin(clampf(at / 0.3, 0.0, 1.0) * PI)
		p.ua_f = 0.4 + 1.2 * e
		p.fa_f = 0.6 + 1.0 * e
		p.lean = 0.15 * e
	elif act == "write":
		p.ua_f = 2.3 + sin(time * 9.0) * 0.15
		p.fa_f = 2.6
	elif c.role == "teacher" and c.say_t > 0.0:
		p.ua_f = 1.2 + sin(time * 6.0) * 0.3
		p.fa_f = 1.9
	var dir := func(a: float) -> Vector2: return Vector2(sin(a) * f, cos(a))
	var L := LIMB * s
	var hip := Vector2(0, p.hip * s)
	var j := {}
	j.knee_f = hip + dir.call(p.th_f) * L
	j.foot_f = j.knee_f + dir.call(p.th_f - p.sh_f) * L
	j.knee_b = hip + dir.call(p.th_b) * L
	j.foot_b = j.knee_b + dir.call(p.th_b - p.sh_b) * L
	var neck: Vector2 = hip + dir.call(PI + p.lean) * 2.0 * L
	var sh: Vector2 = neck + Vector2(0, 2.0 * s)
	j.elbow_f = sh + dir.call(p.ua_f) * L * 0.95
	j.hand_f = j.elbow_f + dir.call(p.fa_f) * L * 0.9
	j.elbow_b = sh + dir.call(p.ua_b) * L * 0.95
	j.hand_b = j.elbow_b + dir.call(p.fa_b) * L * 0.9
	j.hip = hip
	j.neck = neck
	j.head = neck + dir.call(PI + p.lean) * 9.5 * s
	# deitado (caído): roda tudo 90 graus para trás, à volta dos pés
	var ang := 0.0
	if game.is_down(c):
		ang = -PI / 2 * f
	var base := feet + Vector2(0, -lift)
	var out := {"s": s, "f": f, "down": ang != 0.0, "feet": base}
	for k: String in j:
		var v: Vector2 = j[k]
		if ang != 0.0:
			v = v.rotated(ang) + Vector2(-f * 2.0 * L, -4.0)
		out[k] = base + v
	return out


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	if game == null or game.chars.is_empty():
		return
	var g := game
	_draw_back()
	draw_texture_rect_region(vp.get_texture(), Rect2(0, 0, 1280, VIEW_H), Rect2(g.cam_x, 0, 1280, VIEW_H))
	for room: int in g.boards:
		var r: Dictionary = SchoolGame.ROOMS[room]
		var bx := g.board_x(room)
		_draw_board_text(scr(Vector2(bx, float(SchoolGame.FLOOR_Y[int(r.floor)]) - 128.0)), String(g.boards[room]))
	for i in SchoolGame.SHIELDS.size():
		var p := scr(g.shield_pos(i))
		if p.x > -40 and p.x < 1320:
			_draw_shield(p, g.shields_hit[i], i)
	var sp := scr(Vector2(SchoolGame.SAFE_X, SchoolGame.FLOOR_Y[0]))
	if sp.x > -80 and sp.x < 1360:
		_draw_safe(sp, g.safe_open)
	# personagens: sentados/caídos atrás, depois os outros
	var order: Array[Dictionary] = []
	for c in g.chars:
		var x := float(c.x) - g.cam_x
		if x > -80 and x < 1360:
			order.append(c)
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _z(a) < _z(b))
	for c in order:
		_draw_person(c, rig(c))
	for p in g.pellets:
		_draw_pellet(scr(Vector2(p.x, p.y)), int(p.dir))
	for c in order:
		if float(c.say_t) > 0.0 and String(c.say) != "":
			var head: Vector2 = rig(c).head
			_draw_bubble(head + Vector2(0, -26), String(c.say), c.role == "teacher")
	_draw_front()
	_draw_hud()
	if _flash > 0.0:
		draw_rect(Rect2(0, 0, 1280, 720), Color(1, 1, 1, _flash * 0.6))
	var st: Variant = g.touch_stick()
	if st != null:
		draw_arc(st, 60, 0, TAU, 32, Color(1, 1, 1, 0.3), 3.0)


func _z(c: Dictionary) -> float:
	var z := float(c.y)
	if game.is_down(c) or c.sit:
		z -= 1000.0
	if c.role == "hero":
		z += 0.5
	return z


## Textos do painel.
func period_text() -> String:
	var p := game.current_period()
	match String(p.kind):
		"aula":
			var t: Dictionary = SchoolGame.TEACHERS[int(p.teacher)]
			return "%s  -  %s" % [I18n.t(String(SchoolGame.ROOMS[p.room].name)).to_upper(), I18n.t(String(t.name)).to_upper()]
		"almoco":
			return I18n.t("ALMOÇO NO REFEITÓRIO")
	return I18n.t("RECREIO")


func period_left() -> float:
	return clampf(1.0 - game.period_t / (SchoolGame.PERIOD - game.level * 4.0), 0.0, 1.0)


func code_text() -> String:
	var s := ""
	for i in game.known.size():
		s += (game.letters[i] if game.known[i] else "?") + " "
	return s.strip_edges()


## Divide um texto em linhas de até n caracteres.
static func wrap_text(text: String, n: int) -> PackedStringArray:
	var out := PackedStringArray()
	var line := ""
	for w in text.split(" "):
		if line.length() + w.length() + 1 > n and line != "":
			out.append(line)
			line = w
		else:
			line = w if line == "" else line + " " + w
	if line != "":
		out.append(line)
	return out


# ---------------------------------------------------------------- para os estilos

func _setup() -> void:
	pass


func _build_sfx() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _draw_back() -> void:
	pass


## Pinta a escola toda (coordenadas do mundo) — só uma vez.
func _paint_world(_ci: CanvasItem) -> void:
	pass


func _draw_board_text(_p: Vector2, _text: String) -> void:
	pass


func _draw_shield(_p: Vector2, _hit: bool, _i: int) -> void:
	pass


func _draw_safe(_p: Vector2, _open: bool) -> void:
	pass


func _draw_person(_c: Dictionary, _j: Dictionary) -> void:
	pass


func _draw_pellet(p: Vector2, _dir: int) -> void:
	draw_circle(p, 3.0, Color.WHITE)


func _draw_bubble(_p: Vector2, _text: String, _teacher: bool) -> void:
	pass


func _draw_front() -> void:
	pass


func _draw_hud() -> void:
	pass


func ui_palette() -> Dictionary:
	return UI.LAUNCHER_PALETTE
