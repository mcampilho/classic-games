extends JetpacSkin
## Banda Desenhada: uma revista de ficção científica dos anos 50 — céu em degradê com retícula de
## pontos, planeta com anéis, rochas com traço grosso, tudo contornado a preto, onomatopeias
## ("ZAP!", "BUM!") e legendas em caixas amarelas.

const INK := Color("16121e")
const SKY_TOP := Color("2b1b5e")
const SKY_BOTTOM := Color("e8743b")
const ROCK := Color("8a5a9e")
const ROCK_DARK := Color("5e3a72")
const CAPTION := Color("ffe14d")
const RED := Color("e8323c")
const ROCKET_COLS := [Color("e8323c"), Color("2f8fd8"), Color("f2b630"), Color("3fb07a")]
const WORDS := ["ZAP!", "POW!", "BUM!", "ZOK!", "PAF!"]

var font: Font
var dots: Texture2D
var bubbles: Array[Dictionary] = []    # pos (unidades), text, life, color


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	font = ThemeDB.fallback_font
	build_common({"W": Color("f4f1ea"), "V": Color("2f8fd8"), "P": RED, "G": INK},
		{"K": INK, "P": Color("3fb07a"), "W": Color("c8f0d8")},
		[Color("2f8fd8"), RED, Color("3fb07a"), CAPTION])
	# retícula de pontos (Ben-Day)
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 12:
		for x in 12:
			var d := Vector2(x - 2.5, y - 2.5).length()
			var d2 := Vector2(x - 8.5, y - 8.5).length()
			if d < 2.2 or d2 < 2.2:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	dots = ImageTexture.create_from_image(img)


func make_tex(rows: Array, pal: Dictionary) -> Texture2D:
	return PixelArt.outlined(rows, pal, INK, 1)


func _build_sfx() -> void:
	sfx.thrust = Synth.to_stream(Synth.render(0.0, 0.5, {"wave": "noise", "volume": 0.12, "lowpass": 0.2, "attack": 0.0, "release": 0.0}))
	sfx.laser = Synth.to_stream(Synth.mix([
		Synth.render(1200.0, 0.2, {"wave": "square", "freq_end": 2400.0, "volume": 0.06, "lowpass": 0.5}),
		Synth.render(600.0, 0.2, {"wave": "triangle", "freq_end": 1200.0, "volume": 0.1}),
	]))
	sfx.kill = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.4, {"wave": "noise", "volume": 0.3, "lowpass": 0.25, "decay": 8.0}),
		Synth.render(220.0, 0.3, {"wave": "triangle", "freq_end": 70.0, "volume": 0.3}),
	]))
	sfx.crash = Synth.tone(0.0, 0.2, {"wave": "noise", "volume": 0.2, "lowpass": 0.2, "decay": 14.0})
	sfx.pick = Synth.concat([Synth.render(523.0, 0.06, {"wave": "triangle", "volume": 0.2}), Synth.render(784.0, 0.1, {"wave": "triangle", "volume": 0.2})])
	sfx.drop = Synth.tone(900.0, 0.3, {"wave": "triangle", "freq_end": 300.0, "volume": 0.18})
	sfx.place = Synth.concat([Synth.render(392.0, 0.08, {"wave": "triangle", "volume": 0.22}), Synth.render(587.0, 0.08, {"wave": "triangle", "volume": 0.22}), Synth.render(784.0, 0.16, {"wave": "triangle", "volume": 0.22})])
	sfx.fuel = Synth.concat([Synth.render(330.0, 0.06, {"wave": "triangle", "volume": 0.2}), Synth.render(660.0, 0.12, {"wave": "triangle", "volume": 0.2})])
	sfx.gem = Synth.concat([Synth.render(1046.0, 0.06, {"wave": "triangle", "volume": 0.2}), Synth.render(1568.0, 0.18, {"wave": "triangle", "volume": 0.2, "decay": 6.0})])
	sfx.die = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.0, {"wave": "noise", "volume": 0.3, "lowpass": 0.2, "decay": 3.0}),
		Synth.render(600.0, 1.0, {"wave": "triangle", "freq_end": 80.0, "volume": 0.2}),
	]))
	sfx.takeoff = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 2.5, {"wave": "noise", "volume": 0.2, "lowpass": 0.15}),
		Synth.render(90.0, 2.5, {"wave": "triangle", "freq_end": 500.0, "volume": 0.15}),
	]))
	var e := []
	for f in [784.0, 988.0, 1175.0, 1568.0]:
		e.append(Synth.render(f, 0.08, {"wave": "triangle", "volume": 0.2}))
	sfx.extra = Synth.concat(e)


func rocket_palette(model: int) -> Dictionary:
	var c: Color = ROCKET_COLS[model % ROCKET_COLS.size()]
	return {"R": INK.lightened(0.15) if model % 2 == 0 else RED, "B": Color("e6e1d6"), "b": Color("a8a297"), "H": Color("ffffff"), "W": c, "C": Color("8fd0ff"), "K": CAPTION}


func fuel_color() -> Color:
	return Color(Color("3fb07a"), 0.55)


func flame_color() -> Color:
	return CAPTION if fmod(time, 0.1) < 0.05 else Color("ff8a2a")


func laser_colors() -> Array:
	return [CAPTION, Color("ff8a2a"), Color("ffffff")]


func alien_palette() -> Dictionary:
	var c := alien_color()
	return {"A": c, "a": c.darkened(0.35), "E": INK, "W": Color.WHITE, "O": RED, "Y": CAPTION}


func alien_color() -> Color:
	return Color.from_hsv(fmod(0.35 + game.level * 0.17, 1.0), 0.65, 0.9)


func _tick(delta: float) -> void:
	for b in bubbles:
		b.life -= delta
	bubbles = bubbles.filter(func(b: Dictionary) -> bool: return b.life > 0.0)


func _draw_back() -> void:
	var bands := 18
	for i in bands:
		draw_rect(Rect2(0, 720.0 * i / bands, 1280, 720.0 / bands + 1), SKY_TOP.lerp(SKY_BOTTOM, float(i) / (bands - 1)))
	draw_texture_rect(dots, Rect2(0, 0, 1280, 720), true, Color(1, 0.85, 0.6, 0.12))
	# planeta com anéis
	var c := Vector2(980, 230)
	draw_circle(c, 112, INK)
	draw_circle(c, 106, Color("f2b630"))
	draw_circle(c + Vector2(-24, -20), 70, Color("ffd36e"))
	draw_texture_rect(dots, Rect2(c - Vector2(106, 106), Vector2(212, 212)), true, Color(0.85, 0.4, 0.1, 0.25))
	draw_set_transform(c, -0.25, Vector2(1.0, 0.28))
	draw_arc(Vector2.ZERO, 190, PI * 0.05, PI * 0.95, 40, INK, 26.0)
	draw_arc(Vector2.ZERO, 190, PI * 0.05, PI * 0.95, 40, Color("e8c48a"), 16.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(240, 140), 26, INK)
	draw_circle(Vector2(240, 140), 22, Color("d9d4ea"))
	draw_circle(Vector2(232, 134), 6, Color("b8b0d0"))


func _draw_platforms() -> void:
	for r: Rect2 in JetpacGame.PLATFORMS:
		_rock(Rect2(px(r.position), r.size * S))
	var gy := JetpacGame.GROUND_Y * S
	var pts := PackedVector2Array([Vector2(0, 720)])
	for i in 33:
		pts.append(Vector2(i * 40.0, gy + (sin(i * 1.7) * 3.0 if i % 3 else 0.0)))
	pts.append(Vector2(1280, 720))
	draw_colored_polygon(pts, ROCK_DARK)
	draw_texture_rect(dots, Rect2(0, gy + 6, 1280, 720 - gy), true, Color(0, 0, 0, 0.25))
	var top := pts.slice(1, pts.size() - 1)
	draw_polyline(top, INK, 5.0)


func _rock(r: Rect2) -> void:
	var p := PackedVector2Array([
		r.position + Vector2(6, 0), Vector2(r.end.x - 4, r.position.y), Vector2(r.end.x, r.position.y + 8),
		Vector2(r.end.x - 10, r.end.y + 6), Vector2(r.position.x + 12, r.end.y + 10), r.position + Vector2(0, 10)])
	draw_colored_polygon(p, ROCK)
	draw_line(p[4] + Vector2(4, -4), p[3] + Vector2(-2, -4), ROCK_DARK, 6.0)
	p.append(p[0])
	draw_polyline(p, INK, 5.0)
	draw_line(r.position + Vector2(10, 4), Vector2(r.end.x - 10, r.position.y + 4), Color(1, 1, 1, 0.35), 3.0)


func _hline(x0: float, x1: float, y: float, c: Color, _w := 1.0) -> void:
	super(x0, x1, y, Color(INK, c.a), 2.2)
	super(x0, x1, y, c, 1.2)


func _on_alien_killed(pos: Vector2, kind: String, points: int) -> void:
	super(pos, kind, points)
	bubbles.append({"pos": pos, "text": WORDS[randi() % WORDS.size()], "life": 0.6, "color": CAPTION})


func _on_player_died(pos: Vector2) -> void:
	super(pos)
	bubbles.append({"pos": pos, "text": I18n.t("KABUM!"), "life": 1.2, "color": RED})


func _draw_booms() -> void:
	super()
	for b in bubbles:
		var c := px(b.pos)
		var k: float = 1.0 - float(b.life) / 0.6
		var r := 44.0 + k * 10.0
		var pts := PackedVector2Array()
		for i in 20:
			var a := i * TAU / 20
			pts.append(c + Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.62) * Vector2(1.3, 1.0))
		draw_colored_polygon(pts, b.color)
		pts.append(pts[0])
		draw_polyline(pts, INK, 4.0)
		draw_string(font, c + Vector2(-60, 9), b.text, HORIZONTAL_ALIGNMENT_CENTER, 120, 26, INK)


func caption(r: Rect2, text: String, size: int) -> void:
	draw_rect(r.grow(3), INK)
	draw_rect(r, CAPTION)
	draw_string(font, Vector2(r.position.x, r.position.y + r.size.y / 2 + size * 0.36), text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, size, INK)


func _draw_hud() -> void:
	var g := game
	caption(Rect2(16, 10, 230, 40), I18n.t("PONTOS  %06d") % g.score, 22)
	caption(Rect2(525, 10, 230, 40), I18n.t("RECORDE  %06d") % maxi(g.best, g.score), 22)
	caption(Rect2(1034, 10, 230, 40), I18n.t("PLANETA %d") % g.level, 22)
	for i in mini(g.lives - 1, 6):
		draw_texture_rect(tex.man_stand, Rect2(1034 + i * 28, 58, 24, 36), false)
	for p in popups:
		draw_string(font, px(p.pos) + Vector2(-40, -44), p.text, HORIZONTAL_ALIGNMENT_CENTER, 80, 22, Color.WHITE)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(CAPTION, 0.97),
		"border": INK,
		"text": INK,
		"accent": RED,
		"button": Color("fff3b0"),
		"button_hover": Color("ffd84d"),
		"radius": 2,
		"dim": Color(SKY_TOP, 0.35),
	}
