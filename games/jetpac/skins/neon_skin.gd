extends JetpacSkin
## Neon: espaço profundo com estrelas, plataformas em tubos de luz, astronauta, foguete e
## alienígenas com halo, e um laser às cores.

const BG := Color("04020c")
const CYAN := Color("19f5ff")
const MAGENTA := Color("ff3df2")
const YELLOW := Color("fff36b")
const WHITE := Color("ffffff")
const ROCKET_NEON := [Color("19f5ff"), Color("ff3df2"), Color("a6ff3d"), Color("ff9e2c")]

var stars: Array[Vector3] = []
var glow := {}


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	build_common({"W": Color("e8fbff"), "V": MAGENTA, "P": CYAN, "G": YELLOW},
		{"K": YELLOW, "P": Color("8a7a10"), "W": WHITE},
		[CYAN, MAGENTA, Color("a6ff3d"), YELLOW])
	var rng := RandomNumberGenerator.new()
	rng.seed = 83
	for i in 120:
		stars.append(Vector3(rng.randf() * 1280.0, rng.randf() * 680.0, rng.randf_range(0.2, 1.0)))


func make_tex(rows: Array, pal: Dictionary) -> Texture2D:
	var t := PixelArt.texture(rows, pal, 1)
	glow[t] = PixelArt.glow(rows, pal, 4, 3)
	return t


func draw_feet(t: Texture2D, feet: Vector2, flip := false, modulate_c := Color.WHITE) -> void:
	if glow.has(t):
		var gt: Texture2D = glow[t]
		var gs := gt.get_size() * S
		draw_texture_rect(gt, Rect2(px(feet) - Vector2(gs.x / 2, gs.y - 4 * S), gs), false, Color(1, 1, 1, 0.8))
	super(t, feet, flip, modulate_c)


func draw_center(t: Texture2D, c: Vector2, flip := false, modulate_c := Color.WHITE) -> void:
	if glow.has(t):
		var gt: Texture2D = glow[t]
		var gs := gt.get_size() * S
		draw_texture_rect(gt, Rect2(px(c) - gs / 2, gs), false, Color(1, 1, 1, 0.8))
	super(t, c, flip, modulate_c)


func _build_sfx() -> void:
	sfx.thrust = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.5, {"wave": "noise", "volume": 0.1, "lowpass": 0.1, "attack": 0.0, "release": 0.0}),
		Synth.render(110.0, 0.5, {"wave": "saw", "volume": 0.04, "lowpass": 0.1, "attack": 0.0, "release": 0.0}),
	]))
	sfx.laser = Synth.tone(1800.0, 0.18, {"wave": "saw", "freq_end": 500.0, "volume": 0.07, "lowpass": 0.4})
	sfx.kill = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.35, {"wave": "noise", "volume": 0.22, "lowpass": 0.3, "decay": 9.0}),
		Synth.render(600.0, 0.3, {"wave": "sine", "freq_end": 150.0, "volume": 0.15}),
	]))
	sfx.crash = Synth.tone(200.0, 0.2, {"wave": "sine", "freq_end": 60.0, "volume": 0.2})
	sfx.pick = Synth.tone(660.0, 0.15, {"wave": "sine", "freq_end": 1320.0, "volume": 0.18})
	sfx.drop = Synth.tone(1320.0, 0.25, {"wave": "sine", "freq_end": 440.0, "volume": 0.15})
	sfx.place = Synth.concat([Synth.render(784.0, 0.08, {"wave": "saw", "volume": 0.08, "lowpass": 0.3}), Synth.render(1175.0, 0.15, {"wave": "saw", "volume": 0.08, "lowpass": 0.3})])
	sfx.fuel = Synth.concat([Synth.render(523.0, 0.08, {"wave": "sine", "volume": 0.18}), Synth.render(1046.0, 0.15, {"wave": "sine", "volume": 0.18})])
	sfx.gem = Synth.concat([Synth.render(1318.0, 0.07, {"wave": "sine", "volume": 0.16}), Synth.render(1976.0, 0.2, {"wave": "sine", "volume": 0.16, "decay": 6.0})])
	sfx.die = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.2, {"wave": "noise", "volume": 0.3, "lowpass": 0.2, "decay": 2.5}),
		Synth.render(800.0, 1.1, {"wave": "saw", "freq_end": 50.0, "volume": 0.09, "lowpass": 0.3}),
	]))
	sfx.takeoff = Synth.to_stream(Synth.mix([
		Synth.render(60.0, 2.5, {"wave": "saw", "freq_end": 700.0, "volume": 0.07, "lowpass": 0.2}),
		Synth.render(0.0, 2.5, {"wave": "noise", "volume": 0.12, "lowpass": 0.1}),
	]))
	var e := []
	for f in [1046.0, 1318.0, 1568.0, 2093.0]:
		e.append(Synth.render(f, 0.07, {"wave": "sine", "volume": 0.15}))
	sfx.extra = Synth.concat(e)


func rocket_palette(model: int) -> Dictionary:
	var c: Color = ROCKET_NEON[model % ROCKET_NEON.size()]
	return {"R": MAGENTA if model != 1 else CYAN, "B": c.darkened(0.2), "b": c.darkened(0.5), "H": WHITE, "W": WHITE, "C": BG, "K": YELLOW}


func fuel_color() -> Color:
	return Color(YELLOW, 0.45)


func laser_colors() -> Array:
	return [CYAN, MAGENTA, YELLOW, Color("a6ff3d"), WHITE]


func _draw_back() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), BG)
	for s in stars:
		var tw := 0.5 + 0.5 * sin(time * 2.0 * s.z + s.x)
		draw_rect(Rect2(s.x, s.y, 2, 2), Color(1, 1, 1, 0.2 + 0.6 * tw * s.z))


func _draw_platforms() -> void:
	for r: Rect2 in JetpacGame.PLATFORMS:
		var pr := Rect2(px(r.position), r.size * S)
		draw_rect(pr.grow(8), Color(CYAN, 0.08))
		draw_rect(pr.grow(4), Color(CYAN, 0.14))
		draw_rect(pr, Color(CYAN, 0.2))
		draw_rect(pr, CYAN, false, 3.0)
	var gy := JetpacGame.GROUND_Y * S
	draw_rect(Rect2(0, gy, 1280, 720 - gy), Color("12061f"))
	draw_rect(Rect2(0, gy - 6, 1280, 12), Color(MAGENTA, 0.2))
	draw_line(Vector2(0, gy), Vector2(1280, gy), MAGENTA, 3.0)


func _hline(x0: float, x1: float, y: float, c: Color, _w := 1.0) -> void:
	super(x0, x1, y, Color(c, c.a * 0.25), 3.0)
	super(x0, x1, y, c, 1.0)


func neon_text(text: String, x: float, y: float, cell: float, c: Color) -> void:
	PixelFont.draw(self, text, x + 2, y + 2, cell, Color(c, 0.25))
	PixelFont.draw(self, text, x, y, cell, c)


func _draw_hud() -> void:
	var g := game
	neon_text("1UP", 120, 8, 2, MAGENTA)
	neon_text("%06d" % g.score, 120, 28, 3, WHITE)
	neon_text("HI", 640, 8, 2, CYAN)
	neon_text("%06d" % maxi(g.best, g.score), 640, 28, 3, WHITE)
	neon_text(I18n.t("NIVEL %d") % g.level, 1120, 8, 2, YELLOW)
	for i in mini(g.lives - 1, 6):
		draw_texture_rect(tex.man_stand, Rect2(1060 + i * 26, 26, 20, 32), false)
	for p in popups:
		neon_text(p.text, px(p.pos).x, px(p.pos).y - 30, 2, YELLOW)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.02, 0.01, 0.06, 0.92),
		"border": CYAN,
		"text": Color("e8fbff"),
		"accent": MAGENTA,
		"button": Color(0.05, 0.03, 0.12),
		"button_hover": Color(0.12, 0.06, 0.25),
		"radius": 6,
		"dim": Color(0, 0, 0, 0.35),
	}
