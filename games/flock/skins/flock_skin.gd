class_name FlockSkin
extends Node2D
## Base dos estilos do Rebanho: o terreno é uma imagem de 320 x 150 píxeis (um por píxel lógico)
## atualizada só onde as ovelhas escavam ou constroem; ovelhas, curral, celeiro, partículas,
## a linha de estado e o painel de 12 botões. Os estilos escolhem cores e formas.

const SC := FlockGame.SCALE
const FIELD := Vector2(1280, 600)
const BUTTON_LABELS := ["-", "+", "1", "2", "3", "4", "5", "6", "7", "", "", ""]

## Ovelha de 8 x 9 pontos virada para a direita (pés na última linha).
## W lã, w lã à sombra, F cara, E olho, L patas.
const SHEEP := {
	"walk0": [
		"...WW...",
		"..WWWW..",
		".WWWWWFF",
		"WWWWWWFE",
		"WWwWWWFF",
		".WWWWWW.",
		"..wwww..",
		"..L..L..",
		".L....L.",
	],
	"walk1": [
		"........",
		"...WW...",
		"..WWWWFF",
		".WWWWWFE",
		"WWWwWWFF",
		"WWWWWWW.",
		".wwwww..",
		"..L.L...",
		"..L.L...",
	],
	"fall": [
		"..L..L..",
		"...WW...",
		"..WWWW..",
		".WWWWWFF",
		"WWWWWWFE",
		"WWwWWWFF",
		".WWWWWW.",
		"..wwww..",
		"..L..L..",
	],
	"block": [
		"..WWWW..",
		".WWWWWW.",
		"WWFFFFWW",
		"WWEFFEWW",
		".WFFFFW.",
		"LWWWWWWL",
		"L.wwww.L",
		"..L..L..",
		"..L..L..",
	],
	"work0": [
		"........",
		"...WW...",
		"..WWWW..",
		".WWWWWW.",
		"WWWWWWFF",
		"WWwWWWFE",
		".WWWWWFF",
		"..wwww..",
		"..L..L..",
	],
	"climb": [
		"....FF..",
		"...FEF..",
		"..WWFF..",
		".WWWW...",
		".WWWWW.L",
		".WwWWW..",
		".WWWWW.L",
		"..WWW...",
		"...L....",
	],
	"splat": [
		"........",
		"........",
		"........",
		"........",
		"........",
		"........",
		"..W.WW..",
		".WWWwWW.",
		"WWwWWWWW",
	],
}

var game: FlockGame
var sfx := {}
var time := 0.0
var parts: Array[Dictionary] = []
var smooth_terrain := false
var img: Image
var tex: ImageTexture
var frames := {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _open_t := 0.0


func attach(g: FlockGame) -> void:
	game = g
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	g.level_started.connect(func(_l: int) -> void:
		_open_t = 0.0
		parts.clear()
		rebuild_terrain()
		play("start"))
	g.released.connect(func() -> void: play("release", randf_range(0.9, 1.15), -6.0))
	g.assigned.connect(func(_k: String) -> void: play("assign"))
	g.saved.connect(func(p: Vector2) -> void:
		play("saved", randf_range(0.95, 1.1), -4.0)
		_burst(p * SC, saved_colors(), 10, 160.0))
	g.died.connect(func(p: Vector2, how: String) -> void:
		play("splat" if how == "splat" else "fall", 1.0, -3.0)
		if how == "splat":
			_burst(p * SC, [wool_color()], 14, 220.0))
	g.brick.connect(func() -> void: play("brick", randf_range(0.95, 1.05), -10.0))
	g.level_ended.connect(func(ok: bool) -> void: play("success" if ok else "fail"))
	g.won.connect(func() -> void: play("win"))
	var cached: Variant = Synth.cache_get(get_script().resource_path)
	if cached != null:
		sfx = cached
	else:
		_build_sfx()
		Synth.cache_set(get_script().resource_path, sfx)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_setup()
	img = Image.create(FlockGame.W, FlockGame.H, false, Image.FORMAT_RGBA8)
	tex = ImageTexture.create_from_image(img)
	rebuild_terrain()


func play(id: String, pitch := 1.0, volume_db := 0.0) -> void:
	if game == null or game.mode == FlockGame.Mode.DEMO or not sfx.has(id):
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = sfx[id]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


## Cria as texturas das ovelhas a partir dos desenhos em pontos (para estilos de píxeis).
func make_frames(palette: Dictionary, outline: Color, scale := 4) -> void:
	frames.clear()
	for k: String in SHEEP:
		frames[k] = PixelArt.outlined(SHEEP[k], palette, outline, scale)


# ---------------------------------------------------------------- terreno

## Ruído estável por píxel (0..1).
static func hash01(x: int, y: int, seed := 0) -> float:
	var h := (x * 374761393 + y * 668265263 + seed * 2246822519) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h & 0xffff) / 65535.0


func rebuild_terrain() -> void:
	if game == null or img == null or game.terrain.is_empty():
		return
	for y in FlockGame.H:
		for x in FlockGame.W:
			img.set_pixel(x, y, _pixel(x, y))
	tex.update(img)
	game.changed.clear()


func _pixel(x: int, y: int) -> Color:
	var k := game.t_at(x, y)
	if k == FlockGame.EMPTY:
		return Color(0, 0, 0, 0)
	var top := 0
	while top < 6 and game.t_at(x, y - top - 1) != FlockGame.EMPTY:
		top += 1
	var edge := game.t_at(x - 1, y) == FlockGame.EMPTY or game.t_at(x + 1, y) == FlockGame.EMPTY or game.t_at(x, y + 1) == FlockGame.EMPTY
	return terrain_color(x, y, k, top, edge)


func _update_terrain() -> void:
	if game.changed.is_empty():
		return
	var done := {}
	for i in game.changed:
		var cx := i % FlockGame.W
		var cy := i / FlockGame.W
		for dy in range(-1, 7):
			for dx in range(-1, 2):
				var x := cx + dx
				var y := cy + dy
				if x < 0 or y < 0 or x >= FlockGame.W or y >= FlockGame.H:
					continue
				var j := y * FlockGame.W + x
				if done.has(j):
					continue
				done[j] = true
				img.set_pixel(x, y, _pixel(x, y))
	game.changed.clear()
	tex.update(img)


# ---------------------------------------------------------------- ciclo e desenho

func _process(delta: float) -> void:
	if game == null:
		return
	_update_terrain()
	if not game.paused:
		time += delta
		_open_t += delta
		for p in parts:
			p.life -= delta
			p.vel.y += 500.0 * delta
			p.pos += p.vel * delta
		parts = parts.filter(func(p: Dictionary) -> bool: return p.life > 0.0)
		_tick(delta)
	queue_redraw()


func _burst(p: Vector2, cols: Array, n: int, spd: float) -> void:
	for i in n:
		parts.append({"pos": p + Vector2(0, -16), "vel": Vector2.from_angle(randf_range(PI, TAU)) * randf_range(spd * 0.4, spd),
			"life": randf_range(0.4, 0.8), "color": cols[i % cols.size()], "size": randf_range(4.0, 8.0)})


func _draw() -> void:
	if game == null or game.terrain.is_empty():
		return
	_draw_back()
	var d := game.data()
	_draw_exit_back(Vector2(d.exit) * SC)
	draw_texture_rect(tex, Rect2(Vector2.ZERO, FIELD), false)
	_draw_entrance(Vector2(d.entrance) * SC, clampf(_open_t / 1.0, 0.0, 1.0))
	for i in game.sheep.size():
		var s: Dictionary = game.sheep[i]
		if s.job == FlockGame.Job.DEAD:
			continue
		_draw_sheep(s, Vector2(s.pos) * SC + Vector2(SC * 0.5, SC), i == game.hover and not game.is_ai())
	_draw_exit_front(Vector2(d.exit) * SC)
	for p in parts:
		_draw_part(p)
	_draw_front()
	_draw_status()
	_draw_panel()
	if not game.is_ai() and game.cursor.y < FlockGame.PANEL_Y:
		_draw_cursor(game.cursor, game.hover >= 0)


func _draw_part(p: Dictionary) -> void:
	draw_rect(Rect2(p.pos - Vector2.ONE * p.size * 0.5, Vector2.ONE * p.size), Color(p.color, clampf(p.life * 2.0, 0.0, 1.0)))


## Texto da linha de estado (função da ovelha sob o cursor, fora, salvas, tempo).
func status_parts() -> Array[String]:
	var g := game
	var what := ""
	if g.hover >= 0 and not g.is_ai():
		what = job_name(g.sheep[g.hover])
	var t := maxi(int(ceil(g.time_left)), 0)
	return [what, I18n.t("FORA %d") % g.alive_count(), I18n.t("SALVAS %d/%d") % [g.saved_n, int(g.data().need)], I18n.t("TEMPO %d:%02d") % [t / 60, t % 60]]


func job_name(s: Dictionary) -> String:
	var n := ""
	match s.job:
		FlockGame.Job.CLIMB: n = I18n.t("TREPADORA")
		FlockGame.Job.FLOAT: n = I18n.t("GUARDA-CHUVA")
		FlockGame.Job.BLOCK: n = I18n.t("BLOQUEADORA")
		FlockGame.Job.BUILD: n = I18n.t("CONSTRUTORA")
		FlockGame.Job.BASH: n = I18n.t("ESCAVADORA")
		FlockGame.Job.MINE: n = I18n.t("MINEIRA")
		FlockGame.Job.DIG: n = I18n.t("CAVADORA")
		FlockGame.Job.FALL: n = I18n.t("A CAIR")
		_: n = I18n.t("OVELHA")
	if s.climber and s.job != FlockGame.Job.CLIMB:
		n += " +T"
	if s.floater and s.job != FlockGame.Job.FLOAT:
		n += " +G"
	return n


func _draw_status() -> void:
	var pal := panel_palette()
	var sp := status_parts()
	draw_rect(Rect2(0, 0, 1280, 26), pal.status_bg)
	var xs := [190, 520, 800, 1100]
	for i in 4:
		if sp[i] != "":
			PixelFont.draw(self, sp[i], xs[i], 6, 2, pal.status_text if i > 0 else pal.accent)


func _draw_panel() -> void:
	var g := game
	var pal := panel_palette()
	draw_rect(Rect2(0, FlockGame.PANEL_Y, 1280, 720 - FlockGame.PANEL_Y), pal.bg)
	for i in 12:
		var r := g.button_rect(i)
		var active := false
		var count := ""
		if i >= 2 and i <= 8:
			active = g.selected == i - 2
			count = str(int(g.skills[FlockGame.SKILLS[i - 2]]))
		elif i == 0:
			count = str(g.min_rate)
		elif i == 1:
			count = str(g.rate)
		elif i == 9:
			active = g.paused
		elif i == 10:
			active = g.fast
		_draw_button(i, r, count, active)


## Botão por omissão: caixa, número em cima, ícone em baixo.
func _draw_button(i: int, r: Rect2, count: String, active: bool) -> void:
	var pal := panel_palette()
	draw_rect(r, pal.button_on if active else pal.button)
	draw_rect(r, pal.border, false, 3.0 if active else 2.0)
	var dim := i >= 2 and i <= 8 and count == "0"
	var col: Color = pal.icon_dim if dim else pal.icon
	if count != "":
		PixelFont.draw(self, count, r.get_center().x, r.position.y + 8, 3, pal.count)
	draw_icon(i, r.get_center() + Vector2(0, 20), 30.0, col, 4.0)


## Ícones simples dos botões (centro c, meia-largura h).
func draw_icon(i: int, c: Vector2, h: float, col: Color, w: float) -> void:
	match i:
		0:
			draw_line(c + Vector2(-h * 0.6, 0), c + Vector2(h * 0.6, 0), col, w * 1.5)
		1:
			draw_line(c + Vector2(-h * 0.6, 0), c + Vector2(h * 0.6, 0), col, w * 1.5)
			draw_line(c + Vector2(0, -h * 0.6), c + Vector2(0, h * 0.6), col, w * 1.5)
		2:   # trepar: escada com seta
			draw_line(c + Vector2(-h * 0.4, h * 0.7), c + Vector2(-h * 0.4, -h * 0.7), col, w)
			draw_line(c + Vector2(h * 0.4, h * 0.7), c + Vector2(h * 0.4, -h * 0.7), col, w)
			for k in 3:
				var y := -h * 0.4 + k * h * 0.4
				draw_line(c + Vector2(-h * 0.4, y), c + Vector2(h * 0.4, y), col, w * 0.7)
		3:   # guarda-chuva
			var pts := PackedVector2Array()
			for k in 9:
				pts.append(c + Vector2(0, -h * 0.1) + Vector2.from_angle(PI + PI * k / 8.0) * h * 0.8)
			draw_colored_polygon(pts, col)
			draw_line(c + Vector2(0, -h * 0.1), c + Vector2(0, h * 0.7), col, w * 0.8)
			draw_arc(c + Vector2(-h * 0.15, h * 0.7), h * 0.15, 0, PI, 6, col, w * 0.8)
		4:   # bloquear: braços abertos
			draw_circle(c + Vector2(0, -h * 0.5), h * 0.22, col)
			draw_line(c + Vector2(0, -h * 0.3), c + Vector2(0, h * 0.3), col, w)
			draw_line(c + Vector2(-h * 0.8, -h * 0.1), c + Vector2(h * 0.8, -h * 0.1), col, w)
			draw_line(c + Vector2(0, h * 0.3), c + Vector2(-h * 0.4, h * 0.8), col, w)
			draw_line(c + Vector2(0, h * 0.3), c + Vector2(h * 0.4, h * 0.8), col, w)
		5:   # construir: degraus
			for k in 3:
				draw_rect(Rect2(c + Vector2(-h * 0.8 + k * h * 0.5, h * 0.5 - k * h * 0.45), Vector2(h * 0.5, h * 0.3)), col)
		6:   # escavar em frente
			draw_rect(Rect2(c + Vector2(h * 0.2, -h * 0.8), Vector2(h * 0.5, h * 1.6)), Color(col, 0.45))
			draw_line(c + Vector2(-h * 0.8, 0), c + Vector2(h * 0.6, 0), col, w)
			draw_colored_polygon(PackedVector2Array([c + Vector2(h * 0.8, 0), c + Vector2(h * 0.4, -h * 0.35), c + Vector2(h * 0.4, h * 0.35)]), col)
		7:   # minar na diagonal
			draw_line(c + Vector2(-h * 0.7, -h * 0.7), c + Vector2(h * 0.4, h * 0.4), col, w)
			draw_colored_polygon(PackedVector2Array([c + Vector2(h * 0.75, h * 0.75), c + Vector2(h * 0.1, h * 0.6), c + Vector2(h * 0.6, h * 0.1)]), col)
		8:   # cavar para baixo
			draw_rect(Rect2(c + Vector2(-h * 0.8, h * 0.2), Vector2(h * 1.6, h * 0.5)), Color(col, 0.45))
			draw_line(c + Vector2(0, -h * 0.8), c + Vector2(0, h * 0.5), col, w)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, h * 0.85), c + Vector2(-h * 0.35, h * 0.4), c + Vector2(h * 0.35, h * 0.4)]), col)
		9:   # pausa
			draw_rect(Rect2(c + Vector2(-h * 0.5, -h * 0.6), Vector2(h * 0.35, h * 1.2)), col)
			draw_rect(Rect2(c + Vector2(h * 0.15, -h * 0.6), Vector2(h * 0.35, h * 1.2)), col)
		10:  # rapidez
			for k in 2:
				var o := c + Vector2(-h * 0.6 + k * h * 0.6, 0)
				draw_colored_polygon(PackedVector2Array([o + Vector2(0, -h * 0.55), o + Vector2(h * 0.6, 0), o + Vector2(0, h * 0.55)]), col)
		11:  # recomeçar
			draw_arc(c, h * 0.55, -PI * 0.3, PI * 1.4, 16, col, w)
			var e := c + Vector2.from_angle(-PI * 0.3) * h * 0.55
			draw_colored_polygon(PackedVector2Array([e + Vector2(-h * 0.35, -h * 0.15), e + Vector2(h * 0.2, -h * 0.3), e + Vector2(h * 0.05, h * 0.25)]), col)


func _draw_cursor(p: Vector2, on: bool) -> void:
	var c := panel_palette().cursor as Color
	var r := 26.0 if on else 18.0
	var w := 3.0
	for k in 4:
		var a := Vector2.from_angle(k * PI / 2)
		draw_line(p + a * r * 0.4, p + a * r, c, w)
	if on:
		draw_rect(Rect2(p - Vector2(r, r), Vector2(r, r) * 2), c, false, 2.0)


## Desenho por omissão de uma ovelha com as texturas em pontos (pés em p).
func _draw_sheep(s: Dictionary, p: Vector2, hov: bool) -> void:
	var key := sheep_frame(s)
	var t: Texture2D = frames.get(key, frames.get("walk0"))
	if t == null:
		return
	var sz := t.get_size()
	var a := 1.0
	if s.job == FlockGame.Job.EXIT:
		a = 1.0 - clampf(float(s.t) / 8.0, 0.0, 1.0)
	var flip: float = -1.0 if s.dir < 0 and key != "block" else 1.0
	if s.job == FlockGame.Job.FLOAT:
		_draw_umbrella(p + Vector2(0, -sz.y - 4), int(s.anim))
	draw_set_transform(p, 0.0, Vector2(flip, 1.0))
	draw_texture(t, Vector2(-sz.x * 0.5, -sz.y), Color(1, 1, 1, a))
	draw_set_transform(Vector2.ZERO)
	_draw_tool(s, p)
	if hov:
		draw_rect(Rect2(p + Vector2(-sz.x * 0.5 - 4, -sz.y - 4), sz + Vector2(8, 8)), panel_palette().cursor, false, 2.0)


func sheep_frame(s: Dictionary) -> String:
	match s.job:
		FlockGame.Job.FALL, FlockGame.Job.FLOAT:
			return "fall"
		FlockGame.Job.CLIMB:
			return "climb"
		FlockGame.Job.BLOCK:
			return "block"
		FlockGame.Job.BUILD, FlockGame.Job.BASH, FlockGame.Job.MINE, FlockGame.Job.DIG:
			return "work0" if (int(s.anim) / 3) % 2 == 0 else "walk0"
		FlockGame.Job.SPLAT:
			return "splat"
	return "walk0" if (int(s.anim) / 2) % 2 == 0 else "walk1"


## Ferramenta da função (picareta, pá, tijolo) — por omissão, traços simples.
func _draw_tool(s: Dictionary, p: Vector2) -> void:
	var col := tool_color()
	var d := float(s.dir)
	var sw := sin(float(s.anim) * 1.2)
	match s.job:
		FlockGame.Job.BUILD:
			draw_rect(Rect2(p + Vector2(d * 14 - 6, -20 + sw * 2), Vector2(12, 6)), brick_color())
		FlockGame.Job.BASH:
			var h := p + Vector2(d * 10, -18)
			var tip := h + Vector2(d * 14, -10 + sw * 12)
			draw_line(h, tip, col, 3.0)
			draw_line(tip + Vector2(-d * 4, -6), tip + Vector2(d * 6, 6), col, 4.0)
		FlockGame.Job.MINE:
			var h := p + Vector2(d * 8, -22)
			var tip := h + Vector2(d * 12, 4 + sw * 10)
			draw_line(h, tip, col, 3.0)
			draw_line(tip + Vector2(-d * 6, 2), tip + Vector2(d * 4, 8), col, 4.0)
		FlockGame.Job.DIG:
			var h := p + Vector2(d * 6, -28 + sw * 4)
			draw_line(h, h + Vector2(0, 22), col, 3.0)
			draw_rect(Rect2(h + Vector2(-5, 20), Vector2(10, 8)), col)


func _draw_umbrella(c: Vector2, anim: int) -> void:
	var col := umbrella_color()
	var sway := sin(anim * 0.3) * 0.12
	var pts := PackedVector2Array()
	for k in 9:
		pts.append(c + Vector2.from_angle(PI + PI * k / 8.0 + sway) * 22.0)
	draw_colored_polygon(pts, col)
	draw_line(c, c + Vector2(0, 18), tool_color(), 2.0)


# ---------------------------------------------------------------- para os estilos

func _setup() -> void:
	pass


func _build_sfx() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _draw_back() -> void:
	pass


func _draw_front() -> void:
	pass


## Cor de um píxel de terreno. kind: EARTH/STEEL/BRICK; top: píxeis de terreno acima (0 = superfície,
## até 6); edge: tem vazio à esquerda, à direita ou por baixo.
func terrain_color(_x: int, _y: int, _kind: int, _top: int, _edge: bool) -> Color:
	return Color.WHITE


## Curral de onde saem as ovelhas (p = ponto de saída), open = abertura (0..1).
func _draw_entrance(_p: Vector2, _open: float) -> void:
	pass


## Celeiro (p = pés da ovelha ao entrar): parte de trás (antes do terreno) e da frente.
func _draw_exit_back(_p: Vector2) -> void:
	pass


func _draw_exit_front(_p: Vector2) -> void:
	pass


func wool_color() -> Color:
	return Color.WHITE


func saved_colors() -> Array:
	return [Color.YELLOW, Color.WHITE]


func tool_color() -> Color:
	return Color("8a6a4a")


func brick_color() -> Color:
	return Color("c86a3a")


func umbrella_color() -> Color:
	return Color("e04848")


func panel_palette() -> Dictionary:
	return {"bg": Color("202030"), "button": Color("303048"), "button_on": Color("505078"), "border": Color("8080b0"),
		"icon": Color.WHITE, "icon_dim": Color(1, 1, 1, 0.3), "count": Color.WHITE, "accent": Color.YELLOW,
		"status_bg": Color(0, 0, 0, 0.5), "status_text": Color.WHITE, "cursor": Color.WHITE}


func ui_palette() -> Dictionary:
	return UI.LAUNCHER_PALETTE
