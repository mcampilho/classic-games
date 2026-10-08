extends ChuckieSkin
## Ponto de Cruz: o nível bordado num pano de linho como um "sampler" de quinta — cada píxel é um
## ponto em X com linhas de várias cores, o pano tem a trama à vista, as letras são bordadas e
## os sons lembram uma caixa de música.

const CLOTH := Color("efe6d2")
const CLOTH_DARK := Color("e2d6bc")
const HOLE := Color("cdbf9f")
const TERRACOTTA := Color("b5523b")
const BRICK_DARK := Color("8a3a2a")
const WOOD := Color("7a5230")
const WOOD_DARK := Color("5a3a20")
const NAVY := Color("2d3a5c")
const SAGE := Color("6b8f5e")
const GOLD := Color("d9a441")
const ROSE := Color("c95b6e")
const BRICK := [
	"GGGGGGGm",
	"gGGGGGGm",
	"mmmmmmmm",
	"GGGmGGGG",
	"gGGmgGGG",
	"mmmmmmmm",
	"........",
	"........",
]
const LADDER := [
	".L....L.",
	".LLLLLL.",
	".L....L.",
	".L....L.",
	".L....L.",
	".LLLLLL.",
	".L....L.",
	".L....L.",
]
const HEART := [".RR.RR.", "RRRRRRR", "RRRRRRR", ".RRRRR.", "..RRR..", "...R..."]

var cloth_tex: Texture2D
var _glyphs := {}


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	static_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	static_canvas.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	tex_scale = 4.0
	build_sprites(
		{"H": GOLD, "b": ROSE, "S": Color("e8b896"), "E": NAVY, "B": ROSE, "O": NAVY, "o": Color("1f2944"), "K": WOOD_DARK},
		{"C": Color("c0392b"), "W": Color("c77d3a"), "w": Color("9a5a26"), "E": NAVY, "Y": GOLD, "T": Color("7a4a20")},
		{"D": SAGE, "d": Color("4f6e45"), "E": NAVY, "Y": GOLD, "O": GOLD, "W": Color("a9c49a")},
		{"E": Color("d9a877"), "W": Color("f3dcc0")},
		{"G": GOLD, "g": Color("b07f2a")})
	tex.brick = make_tex(BRICK, {"G": TERRACOTTA, "g": BRICK_DARK, "m": Color("d9a48f")}, Color(0, 0, 0, 0))
	tex.ladder = make_tex(LADDER, {"L": WOOD}, Color(0, 0, 0, 0))
	tex.heart = make_tex(HEART, {"R": ROSE}, Color(0, 0, 0, 0))
	# a trama do linho: 4 x 4 com um furo
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(CLOTH)
	img.set_pixel(0, 0, HOLE)
	img.set_pixel(1, 0, CLOTH_DARK)
	img.set_pixel(0, 1, CLOTH_DARK)
	cloth_tex = ImageTexture.create_from_image(img)


## Cada ponto do desenho vira um X bordado de 4 x 4 píxeis (a linha de cima um pouco mais clara).
func make_tex(rows: Array, pal: Dictionary, _outline: Color) -> Texture2D:
	var w: int = (rows[0] as String).length()
	var h := rows.size()
	var img := Image.create(w * 4, h * 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		var row: String = rows[y]
		for x in w:
			var ch := row[x]
			if ch == "." or not pal.has(ch):
				continue
			var c: Color = pal[ch]
			var under := c.darkened(0.18)
			var over := c.lightened(0.08)
			for k in 4:
				img.set_pixel(x * 4 + k, y * 4 + k, under)
			for k in 4:
				img.set_pixel(x * 4 + 3 - k, y * 4 + k, over)
			img.set_pixel(x * 4 + 1, y * 4 + 1, over)
			img.set_pixel(x * 4 + 2, y * 4 + 2, over)
	return ImageTexture.create_from_image(img)


func _build_sfx() -> void:
	# caixa de música: notas de seno com decaimento
	sfx.step = Synth.tone(0.0, 0.02, {"wave": "noise", "volume": 0.06, "lowpass": 0.3, "decay": 80.0})
	sfx.climb = Synth.tone(0.0, 0.03, {"wave": "noise", "volume": 0.05, "lowpass": 0.2, "decay": 60.0})
	sfx.jump = Synth.to_stream(Synth.mix([
		Synth.render(784.0, 0.25, {"wave": "sine", "volume": 0.14, "decay": 9.0}),
		Synth.render(1175.0, 0.25, {"wave": "sine", "volume": 0.06, "decay": 12.0}),
	]))
	sfx.land = Synth.tone(0.0, 0.05, {"wave": "noise", "volume": 0.08, "lowpass": 0.15, "decay": 40.0})
	sfx.egg = Synth.concat([
		Synth.render(1568.0, 0.08, {"wave": "sine", "volume": 0.16, "decay": 12.0}),
		Synth.render(2093.0, 0.25, {"wave": "sine", "volume": 0.16, "decay": 10.0}),
	])
	sfx.grain = Synth.tone(1046.0, 0.3, {"wave": "triangle", "volume": 0.14, "decay": 8.0})
	sfx.peck = Synth.tone(1400.0, 0.03, {"wave": "triangle", "volume": 0.08, "decay": 40.0})
	var d := []
	for f in [784.0, 740.0, 698.0, 659.0, 523.0]:
		d.append(Synth.render(f, 0.22, {"wave": "sine", "volume": 0.16, "decay": 4.0}))
	sfx.die = Synth.concat(d)
	var j := []
	for f in [1046.0, 1318.0, 1568.0, 2093.0, 1568.0, 2093.0, 2637.0]:
		j.append(Synth.render(f, 0.12, {"wave": "sine", "volume": 0.15, "decay": 6.0}))
	sfx.clear = Synth.concat(j)
	var e := []
	for f in [1568.0, 2093.0, 2637.0]:
		e.append(Synth.render(f, 0.1, {"wave": "sine", "volume": 0.15, "decay": 8.0}))
	sfx.extra = Synth.concat(e)


func _draw_static(ci: CanvasItem) -> void:
	ci.draw_texture_rect(cloth_tex, Rect2(0, 0, 1280, 720), true)
	var f := field_rect()
	# moldura em ponto atrás (tracejado)
	var dash := 12.0
	for pass_i in 2:
		var rr := f.grow(10 if pass_i == 0 else 16)
		var col := NAVY if pass_i == 0 else ROSE
		var x := rr.position.x
		while x < rr.end.x:
			ci.draw_line(Vector2(x, rr.position.y), Vector2(minf(x + dash, rr.end.x), rr.position.y), col, 3.0)
			ci.draw_line(Vector2(x, rr.end.y), Vector2(minf(x + dash, rr.end.x), rr.end.y), col, 3.0)
			x += dash * 2
		var y := rr.position.y
		while y < rr.end.y:
			ci.draw_line(Vector2(rr.position.x, y), Vector2(rr.position.x, minf(y + dash, rr.end.y)), col, 3.0)
			ci.draw_line(Vector2(rr.end.x, y), Vector2(rr.end.x, minf(y + dash, rr.end.y)), col, 3.0)
			y += dash * 2
	for r in ChuckieGame.ROWS:
		for c in ChuckieGame.COLS:
			var rect := tile_rect(c, r)
			if game.is_floor(c, r):
				ci.draw_texture_rect(tex.brick, rect, false)
			if game.is_ladder(c, r):
				ci.draw_texture_rect(tex.ladder, rect, false)
				if not game.is_ladder(c, r - 1) and game.is_floor(c, r):
					ci.draw_texture_rect(tex.ladder, Rect2(rect.position - Vector2(0, 4 * S), Vector2(rect.size.x, 4 * S)), false)
	# divisa bordada no painel esquerdo
	_stitch_text_on(ci, I18n.t("LAR"), panel_left_x(), 590, NAVY)
	_stitch_text_on(ci, I18n.t("DOCE"), panel_left_x(), 628, NAVY)
	_stitch_text_on(ci, I18n.t("LAR"), panel_left_x(), 666, NAVY)
	ci.draw_texture_rect(tex.heart, Rect2(panel_left_x() - 70, 668, 28, 24), false)
	ci.draw_texture_rect(tex.heart, Rect2(panel_left_x() + 42, 668, 28, 24), false)


## Letra bordada (cada carácter é uma textura em ponto de cruz, guardada por cor).
func glyph(ch: String, color: Color) -> Texture2D:
	var key := ch + color.to_html()
	if not _glyphs.has(key):
		var g: Array = PixelFont.GLYPHS.get(PixelFont.ACCENTS.get(ch, ch), PixelFont.GLYPHS[" "])
		var rows := []
		for row: String in g:
			rows.append(row.replace("#", "X"))
		_glyphs[key] = make_tex(rows, {"X": color}, Color(0, 0, 0, 0))
	return _glyphs[key]


func _stitch_text_on(ci: CanvasItem, text: String, cx: float, top: float, color: Color) -> void:
	var w := text.length() * 24 - 4
	var x := cx - w / 2.0
	for ch in text.to_upper():
		if ch != " ":
			ci.draw_texture_rect(glyph(ch, color), Rect2(x, top, 20, 28), false)
		x += 24


func stitch_text(text: String, cx: float, top: float, color: Color) -> void:
	_stitch_text_on(self, text, cx, top, color)


func cage_color() -> Color:
	return WOOD


func _draw_cage() -> void:
	var r := Rect2(px(Vector2(0, 0)), Vector2(32, 32) * S)
	for i in 9:
		var x := r.position.x + i * r.size.x / 8
		var y := r.position.y
		while y < r.end.y:
			draw_line(Vector2(x - 3, y), Vector2(x + 3, y + 6), WOOD, 2.0)
			draw_line(Vector2(x + 3, y), Vector2(x - 3, y + 6), WOOD.lightened(0.1), 2.0)
			y += 8
	draw_rect(Rect2(r.position, Vector2(r.size.x, 6)), WOOD)
	draw_rect(Rect2(r.position + Vector2(0, r.size.y - 6), Vector2(r.size.x, 6)), WOOD)


func _draw_lifts() -> void:
	for l in game.lifts:
		var p := px(Vector2(float(l.x) - 8.0, float(l.y)))
		for k in 16:
			var x := p.x + k * S
			draw_line(Vector2(x, p.y), Vector2(x + S, p.y + S * 2), WOOD, 2.0)
			draw_line(Vector2(x + S, p.y), Vector2(x, p.y + S * 2), WOOD.lightened(0.15), 2.0)


func _draw_effects() -> void:
	for b in bursts:
		var k: float = 1.0 - float(b.life) / 0.4
		var c := px(b.pos)
		for i in 8:
			var d := Vector2.from_angle(i * TAU / 8) * (6.0 + 30.0 * k)
			var q := c + d
			var col := Color(ROSE if i % 2 == 0 else GOLD, 1.0 - k)
			draw_line(q - Vector2(4, 4), q + Vector2(4, 4), col, 2.0)
			draw_line(q + Vector2(4, -4), q + Vector2(-4, 4), col, 2.0)
	var st: Variant = game.touch_stick()
	if st != null:
		draw_arc(st, 60, 0, TAU, 32, Color(NAVY, 0.3), 3.0)
		draw_circle((st as Vector2) + game._touch_dir.limit_length(60), 18, Color(NAVY, 0.25))


func _on_egg_taken(pos: Vector2) -> void:
	super(pos)
	bursts[-1].color = ROSE


func _draw_hud() -> void:
	var g := game
	var lx := panel_left_x()
	var rx := panel_right_x()
	var two := g.players.size() > 1
	stitch_text(I18n.t("PONTOS") if not two else I18n.t("JOG 1"), lx, 40, Color(ROSE, 1.0 if g.current == 0 else 0.45))
	stitch_text("%06d" % g.players[0].score, lx, 80, NAVY)
	if two:
		stitch_text(I18n.t("JOG 2"), lx, 140, Color(ROSE, 1.0 if g.current == 1 else 0.45))
		stitch_text("%06d" % g.players[1].score, lx, 180, NAVY)
	stitch_text(I18n.t("MELHOR"), lx, 250, SAGE)
	stitch_text("%06d" % maxi(g.best, g.player().score), lx, 290, NAVY)
	stitch_text(I18n.t("VIDAS"), lx, 400, SAGE)
	for i in mini(g.player().lives, 4):
		draw_texture_rect(tex.farmer_stand, Rect2(lx - 66 + i * 34, 440, 32, 64), false)
	stitch_text(I18n.t("NIVEL"), rx, 40, SAGE)
	stitch_text(str(g.level()), rx, 80, NAVY)
	stitch_text(I18n.t("TEMPO"), rx, 160, SAGE)
	var low := g.time_left < 150.0 and fmod(time, 0.4) < 0.2
	stitch_text("%03d" % int(g.time_left), rx, 200, ROSE if low else NAVY)
	if g.freeze > 0.0:
		stitch_text(I18n.t("PARADO"), rx, 244, GOLD)
	stitch_text(I18n.t("OVOS"), rx, 320, SAGE)
	stitch_text(str(g.eggs.size()), rx, 360, NAVY)
	for p in popups:
		stitch_text(p.text, px(p.pos).x, px(p.pos).y - 34, ROSE)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(CLOTH, 0.97),
		"border": ROSE,
		"text": NAVY,
		"accent": ROSE,
		"button": Color("e6dac0"),
		"button_hover": Color("dccaa6"),
		"radius": 4,
		"dim": Color(NAVY, 0.2),
	}
