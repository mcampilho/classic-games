extends PenetratorSkin
## Mapa Topográfico: a missão vista numa carta militar em corte — papel com quadrícula, terreno
## pintado em tintas hipsométricas com curvas de nível, inimigos como símbolos de mapa, legenda
## em cartela e uma escala gráfica como barra de progresso.

const PAPER := Color("efe7d2")
const GRID := Color("d6ccb0")
const INK := Color("2b3348")
const RED := Color("b83a2e")
const BLUE := Color("3d6fa0")
const BANDS := [Color("b9cf9a"), Color("d4d896"), Color("e3c98b"), Color("d4a874"), Color("b88a62"), Color("9a7458")]
const CAVE_BANDS := [Color("c9c2b0"), Color("b7ae99"), Color("a49a84"), Color("918770"), Color("7f755f")]

var paper_tex: Texture2D
var font: Font


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	font = ThemeDB.fallback_font
	var pal := {"B": Color("f7f2e4"), "b": Color("d9d0bb"), "H": RED, "C": BLUE, "N": RED, "F": Color("e0a33a"), "K": INK}
	tex.ship = PixelArt.outlined(SHIP, pal, INK, 1)
	# papel: quadrícula de 40 px com linhas finas de 8 px
	var img := Image.create(40, 40, false, Image.FORMAT_RGBA8)
	img.fill(PAPER)
	for i in 40:
		for k in [0, 8, 16, 24, 32]:
			img.set_pixel(i, k, PAPER.darkened(0.03))
			img.set_pixel(k, i, PAPER.darkened(0.03))
		img.set_pixel(i, 0, GRID)
		img.set_pixel(0, i, GRID)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 60:
		img.set_pixel(rng.randi() % 40, rng.randi() % 40, PAPER.darkened(0.06))
	paper_tex = ImageTexture.create_from_image(img)


func _build_sfx() -> void:
	# sons "de secretária": lápis, carimbo, papel
	sfx.engine = Synth.to_stream(Synth.render(0.0, 1.0, {"wave": "noise", "volume": 0.05, "lowpass": 0.05, "attack": 0.0, "release": 0.0}))
	sfx.shot = Synth.tone(0.0, 0.06, {"wave": "noise", "volume": 0.12, "lowpass": 0.6, "decay": 50.0})
	sfx.bomb = Synth.tone(700.0, 0.4, {"wave": "triangle", "freq_end": 350.0, "volume": 0.12})
	sfx.boom = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.3, {"wave": "noise", "volume": 0.25, "lowpass": 0.2, "decay": 10.0}),
		Synth.render(110.0, 0.2, {"wave": "triangle", "freq_end": 50.0, "volume": 0.25}),
	]))
	sfx.thud = Synth.tone(70.0, 0.15, {"wave": "triangle", "volume": 0.3, "decay": 20.0})
	sfx.launch = Synth.tone(300.0, 0.35, {"wave": "triangle", "freq_end": 900.0, "volume": 0.1})
	sfx.store_hit = Synth.tone(0.0, 0.25, {"wave": "noise", "volume": 0.25, "lowpass": 0.15, "decay": 10.0})
	sfx.boom_big = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.8, {"wave": "noise", "volume": 0.35, "lowpass": 0.1, "decay": 2.0}),
		Synth.render(70.0, 1.5, {"wave": "triangle", "freq_end": 30.0, "volume": 0.3}),
	]))
	sfx.die = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.0, {"wave": "noise", "volume": 0.3, "lowpass": 0.2, "decay": 3.0}),
		Synth.render(500.0, 0.9, {"wave": "triangle", "freq_end": 60.0, "volume": 0.15}),
	]))
	var z := []
	for f in [784.0, 1046.0]:
		z.append(Synth.render(f, 0.14, {"wave": "triangle", "volume": 0.16, "decay": 8.0}))
	sfx.zone = Synth.concat(z)
	var c := []
	for f in [523.0, 659.0, 784.0, 1046.0, 1318.0]:
		c.append(Synth.render(f, 0.16, {"wave": "triangle", "volume": 0.18, "decay": 5.0}))
	sfx.complete = Synth.concat(c)
	var e := []
	for f in [1046.0, 1318.0, 1568.0]:
		e.append(Synth.render(f, 0.1, {"wave": "triangle", "volume": 0.16}))
	sfx.extra = Synth.concat(e)


func _draw_back() -> void:
	var off := fposmod(game.cam_x, 40.0)
	draw_texture_rect(paper_tex, Rect2(-off, 0, PenetratorGame.W + 40, PenetratorGame.H), true)


func _draw_terrain() -> void:
	var bands := []
	for i in BANDS.size():
		bands.append([16.0, BANDS[i]])
	fill_terrain(bands, false)
	# teto das cavernas em cinzentos (rocha)
	if has_ceiling():
		var v := visible_cols()
		for c in range(v.x, v.y):
			var c0 := game.ceil_y[c]
			var c1 := game.ceil_y[c + 1]
			if c0 <= PenetratorGame.TOP + 0.5 and c1 <= PenetratorGame.TOP + 0.5:
				continue
			var x0 := c * PenetratorGame.CW - game.cam_x
			var d := 0.0
			for i in CAVE_BANDS.size():
				var t := 16.0 if i < CAVE_BANDS.size() - 1 else 1000.0
				_quad(Vector2(x0, maxf(c0 - d - t, PenetratorGame.TOP)), Vector2(x0 + PenetratorGame.CW, maxf(c1 - d - t, PenetratorGame.TOP)),
					Vector2(x0 + PenetratorGame.CW, maxf(c1 - d, PenetratorGame.TOP)), Vector2(x0, maxf(c0 - d, PenetratorGame.TOP)), CAVE_BANDS[i])
				d += t
		_flush()
	# curvas de nível
	var base := contour(false)
	for k in BANDS.size():
		var pts := PackedVector2Array()
		for p in base:
			pts.append(p + Vector2(0, k * 16.0))
		draw_polyline(pts, Color(INK, 0.9 if k == 0 else 0.35), 2.5 if k == 0 else 1.0)
	if has_ceiling():
		var top := contour(true)
		for k in 3:
			var seg := PackedVector2Array()
			for p in top:
				var y := p.y - k * 16.0
				if y > PenetratorGame.TOP + 0.5:
					seg.append(Vector2(p.x, y))
				elif seg.size() > 1:
					draw_polyline(seg, Color(INK, 0.9 if k == 0 else 0.35), 2.5 if k == 0 else 1.0)
					seg = PackedVector2Array()
				else:
					seg = PackedVector2Array()
			if seg.size() > 1:
				draw_polyline(seg, Color(INK, 0.9 if k == 0 else 0.35), 2.5 if k == 0 else 1.0)


func _draw_enemy(e: Dictionary, p: Vector2) -> void:
	match e.kind:
		"missile":
			# símbolo de míssil: triângulo vermelho com haste
			var c := p - Vector2(0, 20)
			draw_line(p, c + Vector2(0, 6), INK, 3.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -20), c + Vector2(-9, 8), c + Vector2(9, 8)]), RED)
			draw_polyline(PackedVector2Array([c + Vector2(0, -20), c + Vector2(-9, 8), c + Vector2(9, 8), c + Vector2(0, -20)]), INK, 2.0)
			if e.flying:
				for k in 4:
					draw_circle(p + Vector2(0, 8 + k * 9), 3.0 - k * 0.5, Color(INK, 0.5 - k * 0.1))
		"radar":
			draw_radar(p, e.phase, INK, BLUE, 3.0)
		"saucer":
			draw_set_transform(p, 0.0, Vector2(1.0, 0.45))
			draw_circle(Vector2.ZERO, 26, Color(BLUE, 0.85))
			draw_arc(Vector2.ZERO, 26, 0, TAU, 32, INK, 4.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_circle(p + Vector2(0, -6), 8, PAPER)
			draw_arc(p + Vector2(0, -6), 8, PI, TAU, 16, INK, 2.0)
		"store":
			# símbolo de depósito: quadrado com X
			var r := Rect2(p + Vector2(-45, -70), Vector2(90, 70))
			draw_rect(r, Color(RED, 0.2))
			draw_rect(r, INK, false, 3.0)
			draw_line(r.position, r.end, INK, 3.0)
			draw_line(Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), INK, 3.0)
			for i in game.store_left:
				draw_rect(Rect2(p + Vector2(-40 + i * 14, -82), Vector2(10, 6)), RED)


func _draw_shot(p: Vector2) -> void:
	draw_line(p - Vector2(10, 0), p + Vector2(10, 0), RED, 3.0)
	draw_line(p + Vector2(4, -4), p + Vector2(10, 0), RED, 2.0)
	draw_line(p + Vector2(4, 4), p + Vector2(10, 0), RED, 2.0)


func _draw_bomb(p: Vector2, v: Vector2) -> void:
	draw_circle(p, 5, INK)
	draw_line(p, p - v.normalized() * 14.0, Color(INK, 0.5), 2.0)


func _draw_ship(p: Vector2) -> void:
	draw_tex_center(tex.ship, p, 3.0, game.ship_tilt * 0.08)
	# rasto tracejado
	for k in 6:
		draw_line(p + Vector2(-44 - k * 18, 2), p + Vector2(-52 - k * 18, 2), Color(RED, 0.7 - k * 0.1), 2.0)


func ground_boom_color() -> Color:
	return INK


func _draw_booms() -> void:
	for b in booms:
		var k: float = 1.0 - float(b.life) / float(b.max)
		var c := Vector2(sx(b.pos.x), b.pos.y)
		var r: float = float(b.size) * (0.4 + k)
		# estrela de explosão desenhada a tinta
		var pts := PackedVector2Array()
		for i in 16:
			var a := i * TAU / 16
			pts.append(c + Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.5))
		draw_colored_polygon(pts, Color(Color("e0a33a"), (1.0 - k) * 0.8))
		pts.append(pts[0])
		draw_polyline(pts, Color(INK, 1.0 - k), 2.0)


func label(text: String, pos: Vector2, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	draw_string(font, pos, text, align, width, size, color)


func _draw_hud() -> void:
	var g := game
	var top := PenetratorGame.TOP - 4
	draw_rect(Rect2(0, 0, PenetratorGame.W, top), PAPER)
	draw_line(Vector2(0, top), Vector2(PenetratorGame.W, top), INK, 3.0)
	draw_line(Vector2(0, top - 5), Vector2(PenetratorGame.W, top - 5), INK, 1.0)
	label(I18n.t("CARTA MILITAR  ·  MISSÃO %d") % g.mission, Vector2(24, 26), 18, INK)
	label(I18n.t("Folha %d — %s") % [g.zone + 1, I18n.t(PenetratorGame.ZONE_NAMES[g.zone])], Vector2(24, 52), 16, RED)
	label(I18n.t("PONTOS %06d") % g.score, Vector2(1000, 26), 20, INK)
	label(I18n.t("recorde %06d   naves %d") % [maxi(g.best, g.score), g.lives], Vector2(1000, 52), 14, INK)
	# escala gráfica = progresso das 5 folhas
	var x0 := 440.0
	var w := 420.0
	for z in PenetratorGame.ZONES:
		var r := Rect2(x0 + z * w / PenetratorGame.ZONES, 22, w / PenetratorGame.ZONES, 10)
		draw_rect(r, INK if z % 2 == 0 else PAPER)
		if z == g.zone:
			draw_rect(Rect2(r.position, Vector2(r.size.x * g.zone_progress(), r.size.y)), RED)
	draw_rect(Rect2(x0, 22, w, 10), INK, false, 2.0)
	for z in PenetratorGame.ZONES + 1:
		label(str(z * 5), Vector2(x0 + z * w / PenetratorGame.ZONES - 8, 50), 12, INK)
	label("km", Vector2(x0 + w + 14, 32), 12, INK)
	for p in popups:
		label(p.text, Vector2(sx(p.pos.x) - 20, p.pos.y), 18, RED)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(PAPER, 0.97),
		"border": INK,
		"text": INK,
		"accent": RED,
		"button": Color("e2d8bd"),
		"button_hover": Color("d4c7a5"),
		"radius": 2,
		"dim": Color(INK, 0.2),
	}
