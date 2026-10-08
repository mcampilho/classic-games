extends PenetratorSkin
## Neon: céu estrelado em paralaxe, terreno escuro com contornos de luz (um par de cores por zona),
## nave, mísseis e discos com halo.

const ZONE_NEON := [
	[Color("19f5ff"), Color("0a2a40")],
	[Color("ff3df2"), Color("2a0a33")],
	[Color("fff36b"), Color("2e2a0a")],
	[Color("2bff88"), Color("0a2e1c")],
	[Color("ff7b2c"), Color("33140a")],
]
const BG := Color("04020c")
const WHITE := Color("ffffff")

var stars: Array[Vector3] = []


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var ship_pal := {"B": Color("dff9ff"), "b": Color("19f5ff"), "H": Color("ff3df2"), "C": Color("ff3df2"), "N": Color("fff36b"), "F": Color("ff7b2c"), "K": Color("6a5cff")}
	tex.ship = PixelArt.texture(SHIP, ship_pal, 1)
	tex.ship_glow = PixelArt.glow(SHIP, ship_pal, 4, 3)
	var mpal := {"W": Color("ffd0f0"), "R": Color("ff3d6e"), "B": Color("19f5ff")}
	tex.missile = PixelArt.texture(MISSILE, mpal, 1)
	tex.missile_glow = PixelArt.glow(MISSILE, mpal, 4, 3)
	var spal := {"C": Color("19f5ff"), "B": Color("a6ff3d"), "b": Color("4f9a1a"), "L": Color("fff36b")}
	tex.saucer = PixelArt.texture(SAUCER, spal, 1)
	tex.saucer_glow = PixelArt.glow(SAUCER, spal, 4, 3)
	var rng := RandomNumberGenerator.new()
	rng.seed = 81
	for i in 140:
		stars.append(Vector3(rng.randf() * 1280.0, rng.randf_range(PenetratorGame.TOP, 700.0), rng.randf_range(0.1, 0.6)))


func _build_sfx() -> void:
	sfx.engine = Synth.to_stream(Synth.mix([
		Synth.render(55.0, 1.0, {"wave": "saw", "volume": 0.08, "lowpass": 0.08, "attack": 0.0, "release": 0.0}),
		Synth.render(82.5, 1.0, {"wave": "sine", "volume": 0.06, "attack": 0.0, "release": 0.0}),
	]))
	sfx.shot = Synth.tone(1600.0, 0.12, {"wave": "saw", "freq_end": 400.0, "volume": 0.08, "lowpass": 0.4})
	sfx.bomb = Synth.tone(900.0, 0.6, {"wave": "sine", "freq_end": 200.0, "volume": 0.12})
	sfx.boom = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.5, {"wave": "noise", "volume": 0.3, "lowpass": 0.25, "decay": 7.0}),
		Synth.render(160.0, 0.4, {"wave": "sine", "freq_end": 40.0, "volume": 0.25}),
	]))
	sfx.thud = Synth.tone(80.0, 0.2, {"wave": "sine", "freq_end": 35.0, "volume": 0.3, "decay": 12.0})
	sfx.launch = Synth.tone(150.0, 0.5, {"wave": "saw", "freq_end": 900.0, "volume": 0.07, "lowpass": 0.3})
	sfx.store_hit = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.4, {"wave": "noise", "volume": 0.3, "lowpass": 0.2, "decay": 8.0}),
		Synth.render(110.0, 0.4, {"wave": "saw", "freq_end": 50.0, "volume": 0.1, "lowpass": 0.2}),
	]))
	sfx.boom_big = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 2.2, {"wave": "noise", "volume": 0.4, "lowpass": 0.12, "decay": 1.6}),
		Synth.render(90.0, 2.0, {"wave": "sine", "freq_end": 25.0, "volume": 0.3}),
	]))
	sfx.die = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.4, {"wave": "noise", "volume": 0.3, "lowpass": 0.2, "decay": 2.2}),
		Synth.render(700.0, 1.2, {"wave": "saw", "freq_end": 40.0, "volume": 0.1, "lowpass": 0.3}),
	]))
	var z := []
	for f in [659.0, 988.0, 1318.0]:
		z.append(Synth.render(f, 0.1, {"wave": "saw", "volume": 0.08, "lowpass": 0.3}))
	sfx.zone = Synth.concat(z)
	var c := []
	for f in [523.0, 659.0, 784.0, 1046.0, 1318.0, 1568.0, 2093.0]:
		c.append(Synth.render(f, 0.12, {"wave": "saw", "volume": 0.09, "lowpass": 0.3}))
	sfx.complete = Synth.concat(c)
	var e := []
	for f in [1046.0, 1318.0, 1568.0, 2093.0]:
		e.append(Synth.render(f, 0.07, {"wave": "sine", "volume": 0.15}))
	sfx.extra = Synth.concat(e)


func zone_colors() -> Array:
	return ZONE_NEON[game.zone_of(game.cam_x + PenetratorGame.W / 2) % ZONE_NEON.size()]


func _draw_back() -> void:
	draw_rect(Rect2(0, 0, PenetratorGame.W, PenetratorGame.H), BG)
	for s in stars:
		var x := fposmod(s.x - game.cam_x * s.z, 1280.0)
		draw_rect(Rect2(x, s.y, 2, 2), Color(1, 1, 1, s.z * 1.2))


func _draw_terrain() -> void:
	var zc := zone_colors()
	var neon: Color = zc[0]
	var dark: Color = zc[1]
	fill_terrain([[6.0, neon.darkened(0.55)], [30.0, dark], [1.0, dark.darkened(0.5)]])
	for top: bool in [false, true]:
		if top and not has_ceiling():
			continue
		var pts := contour(top)
		draw_polyline(pts, Color(neon, 0.15), 12.0)
		draw_polyline(pts, Color(neon, 0.3), 6.0)
		draw_polyline(pts, neon.lightened(0.3), 2.0)


func _glow(t: Texture2D, c: Vector2, scale: float, rot := 0.0) -> void:
	draw_set_transform(c, rot, Vector2(scale, scale))
	draw_texture(t, -t.get_size() / 2, Color(1, 1, 1, 0.8))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_enemy(e: Dictionary, p: Vector2) -> void:
	match e.kind:
		"missile":
			var t: Texture2D = tex.missile
			var c := p - Vector2(0, t.get_height() * 1.5)
			_glow(tex.missile_glow, c, 3.0)
			draw_tex_center(t, c, 3.0)
			if e.flying:
				draw_circle(p + Vector2(0, 8), 7 + sin(time * 40.0) * 2, Color("ff7b2c"))
		"radar":
			var zc := zone_colors()
			draw_radar(p, e.phase, Color(zc[0], 0.4), Color.WHITE, 6.0)
			draw_radar(p, e.phase, zc[0], Color.WHITE, 2.5)
		"saucer":
			_glow(tex.saucer_glow, p, 3.0)
			draw_tex_center(tex.saucer, p, 3.0)
		"store":
			var zc := zone_colors()
			draw_rect(Rect2(p + Vector2(-56, -74), Vector2(112, 80)), Color(zc[0], 0.12))
			draw_store(p, Color("1a0f2e"), Color("ff3df2"), Color("fff36b"), game.store_left)


func _draw_shot(p: Vector2) -> void:
	draw_rect(Rect2(p - Vector2(12, 4), Vector2(24, 8)), Color(1.0, 0.95, 0.4, 0.25))
	draw_rect(Rect2(p - Vector2(10, 1.5), Vector2(20, 3)), Color("fff36b"))


func _draw_bomb(p: Vector2, _v: Vector2) -> void:
	draw_circle(p, 9, Color(1, 0.3, 0.9, 0.25))
	draw_circle(p, 4, Color("ff3df2"))


func _draw_ship(p: Vector2) -> void:
	_glow(tex.ship_glow, p, 3.0, game.ship_tilt * 0.08)
	draw_tex_center(tex.ship, p, 3.0, game.ship_tilt * 0.08)
	var fl := 10.0 + sin(time * 50.0) * 4.0
	draw_colored_polygon(PackedVector2Array([p + Vector2(-32, -1), p + Vector2(-32 - fl * 2, 4), p + Vector2(-32, 8)]), Color("ff7b2c"))


func ground_boom_color() -> Color:
	return Color("ff3df2")


func neon_text(text: String, x: float, y: float, cell: float, c: Color) -> void:
	PixelFont.draw(self, text, x + 2, y + 2, cell, Color(c, 0.25))
	PixelFont.draw(self, text, x, y, cell, c)


func _draw_hud() -> void:
	var g := game
	draw_rect(Rect2(0, 0, PenetratorGame.W, PenetratorGame.TOP - 4), BG)
	var zc := zone_colors()
	draw_line(Vector2(0, PenetratorGame.TOP - 4), Vector2(PenetratorGame.W, PenetratorGame.TOP - 4), Color(zc[0], 0.6), 2.0)
	neon_text(I18n.t("PONTOS %06d") % g.score, 170, 12, 3, WHITE)
	neon_text(I18n.t("REC %06d") % maxi(g.best, g.score), 170, 40, 2, Color("19f5ff"))
	neon_text(I18n.t("MISSAO %d") % g.mission, 1120, 12, 3, Color("ff3df2"))
	for i in mini(g.lives - 1, 6):
		draw_tex_center(tex.ship, Vector2(1040 + i * 30, 46), 1.0)
	var x0 := 420.0
	var w := 440.0
	for z in PenetratorGame.ZONES:
		var c: Color = ZONE_NEON[z][0]
		var r := Rect2(x0 + z * w / PenetratorGame.ZONES + 3, 14, w / PenetratorGame.ZONES - 6, 12)
		draw_rect(r, c if z < g.zone else Color(c, 0.18))
		if z == g.zone:
			draw_rect(Rect2(r.position, Vector2(r.size.x * g.zone_progress(), r.size.y)), c)
			draw_rect(r.grow(3), Color(c, 0.4), false, 2.0)
	neon_text(I18n.t(PenetratorGame.ZONE_NAMES[g.zone]).to_upper(), x0 + w / 2, 38, 2, ZONE_NEON[g.zone][0])
	for p in popups:
		neon_text(p.text, sx(p.pos.x), p.pos.y, 2, Color("fff36b"))


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.02, 0.01, 0.06, 0.92),
		"border": Color("19f5ff"),
		"text": Color("e8fbff"),
		"accent": Color("ff3df2"),
		"button": Color(0.05, 0.03, 0.12),
		"button_hover": Color(0.12, 0.06, 0.25),
		"radius": 6,
		"dim": Color(0, 0, 0, 0.35),
	}
