extends OutRunSkin
## Synthwave: noite eterna, sol às riscas no horizonte, montanhas de arame, chão em grelha
## néon e silhuetas com contorno brilhante. Cada tema muda o par de cores néon.

const THEME_COLORS := {
	"costa": {"sky": [Color("0b0326"), Color("5a0f6e")], "sun": [Color("ffd319"), Color("ff2975")], "neon": Color("ff2975"), "neon2": Color("00e5ff"), "ground": Color("3c3850")},
	"deserto": {"sky": [Color("1a0410"), Color("7a1f2c")], "sun": [Color("ffe08a"), Color("ff6a00")], "neon": Color("ff7b00"), "neon2": Color("ff3df2"), "ground": Color("443637")},
	"floresta": {"sky": [Color("020f1a"), Color("0f4a4f")], "sun": [Color("d8ff5a"), Color("16c79a")], "neon": Color("2bff88"), "neon2": Color("00e5ff"), "ground": Color("33433f")},
	"alpes": {"sky": [Color("040a24"), Color("2a3f8f")], "sun": [Color("ffffff"), Color("7aa2ff")], "neon": Color("8fb8ff"), "neon2": Color("ffffff"), "ground": Color("383f53")},
	"cidade": {"sky": [Color("0a0520"), Color("4b1a7a")], "sun": [Color("fff36b"), Color("ff3df2")], "neon": Color("ff3df2"), "neon2": Color("fff36b"), "ground": Color("3e374d")},
	"vinhas": {"sky": [Color("12041f"), Color("5b2a6e")], "sun": [Color("f6ff7a"), Color("b04aff")], "neon": Color("b04aff"), "neon2": Color("c6ff3d"), "ground": Color("3f3749")},
}
const GRID_X := [1.7, 2.6, 3.9, 6.0]

var sun_tex := {}
var _neon2 := Color.WHITE
var glow_tex: Texture2D
var scan_tex: Texture2D
var stars: Array[Vector3] = []


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	tex.player = make_sprite(PLAYER_CAR, {"Y": Color("1a1030"), "y": Color("ff8fd8"), "G": Color("00e5ff"), "D": Color("05010f"),
		"B": Color("2a0f4f"), "H": Color("ff2975"), "b": Color("170830"), "R": Color("ff2975"), "r": Color("ffd319"), "P": Color("00e5ff"), "K": Color("05010f")},
		Color("00e5ff"))
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 64
	gt.height = 64
	glow_tex = gt
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(0, 3, 4, 1), Color(0, 0, 0, 0.22))
	scan_tex = ImageTexture.create_from_image(img)
	var rng := RandomNumberGenerator.new()
	rng.seed = 86
	for i in 90:
		stars.append(Vector3(rng.randf() * W, rng.randf() * 300.0, rng.randf() * TAU))


func _sun(t: String) -> Texture2D:
	if sun_tex.has(t):
		return sun_tex[t]
	var tc: Dictionary = THEME_COLORS[t]
	var size := 300
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var r := size / 2.0
	for y in size:
		var k := float(y) / size
		# riscas que engrossam para baixo
		if k > 0.5:
			var band := fmod((k - 0.5) * 12.0, 1.0)
			if band < (k - 0.5) * 1.3:
				continue
		var dy := y - r + 0.5
		var hw := sqrt(maxf(r * r - dy * dy, 0.0))
		var c: Color = (tc.sun[0] as Color).lerp(tc.sun[1], k)
		for x in range(int(r - hw), int(r + hw)):
			img.set_pixel(x, y, c)
	var tx := ImageTexture.create_from_image(img)
	sun_tex[t] = tx
	return tx


func _build_sfx() -> void:
	sfx.engine = Synth.to_stream(Synth.mix([
		Synth.render(55.0, 1.0, {"wave": "saw", "volume": 0.22, "lowpass": 0.18, "attack": 0.0, "release": 0.0}),
		Synth.render(82.5, 1.0, {"wave": "saw", "volume": 0.12, "lowpass": 0.12, "attack": 0.0, "release": 0.0}),
		Synth.render(27.5, 1.0, {"wave": "sine", "volume": 0.2, "attack": 0.0, "release": 0.0}),
	]))
	sfx.skid = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.5, {"wave": "noise", "volume": 0.14, "lowpass": 0.5, "attack": 0.0, "release": 0.0}),
		Synth.render(2000.0, 0.5, {"wave": "sine", "volume": 0.05, "attack": 0.0, "release": 0.0}),
	]))
	sfx.beep = Synth.tone(659.0, 0.3, {"wave": "saw", "volume": 0.14, "lowpass": 0.25, "decay": 4.0})
	sfx.go = Synth.to_stream(Synth.mix([
		Synth.render(1318.0, 0.8, {"wave": "saw", "volume": 0.12, "lowpass": 0.25, "decay": 2.0}),
		Synth.render(659.0, 0.8, {"wave": "square", "volume": 0.08, "lowpass": 0.2, "decay": 2.0}),
	]))
	sfx.crash = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.4, {"wave": "noise", "volume": 0.4, "lowpass": 0.12, "decay": 2.5}),
		Synth.render(220.0, 1.0, {"wave": "saw", "freq_end": 30.0, "volume": 0.14, "lowpass": 0.15}),
	]))
	sfx.bump = Synth.tone(70.0, 0.25, {"wave": "sine", "freq_end": 40.0, "volume": 0.45, "decay": 10.0})
	sfx.gear = Synth.tone(1200.0, 0.06, {"wave": "saw", "freq_end": 400.0, "volume": 0.1, "lowpass": 0.4})
	var arp := []
	for f in [523.0, 659.0, 784.0, 1046.0, 1318.0, 1568.0]:
		arp.append(Synth.render(f, 0.08, {"wave": "saw", "volume": 0.1, "lowpass": 0.3}))
	sfx.checkpoint = Synth.concat(arp)
	var warn := []
	for i in 3:
		warn.append(Synth.render(988.0, 0.1, {"wave": "saw", "volume": 0.1, "lowpass": 0.3}))
		warn.append(Synth.silence(0.06))
	sfx.warning = Synth.concat(warn)
	var fan := []
	for n in [[392.0, 0.2], [523.0, 0.2], [659.0, 0.2], [784.0, 0.5], [659.0, 0.2], [1046.0, 0.8]]:
		fan.append(Synth.render(n[0], n[1], {"wave": "saw", "volume": 0.12, "lowpass": 0.25, "release": 0.05}))
	sfx.goal = Synth.concat(fan)
	sfx.time_up = Synth.tone(440.0, 1.2, {"wave": "saw", "freq_end": 110.0, "volume": 0.14, "lowpass": 0.2})


func col(key: String) -> Variant:
	var a: Dictionary = THEME_COLORS[prev_theme]
	var b: Dictionary = THEME_COLORS[theme]
	if theme_blend >= 1.0:
		return b[key]
	var va: Variant = a[key]
	var vb: Variant = b[key]
	if va is Array:
		return [(va[0] as Color).lerp(vb[0], theme_blend), (va[1] as Color).lerp(vb[1], theme_blend)]
	return (va as Color).lerp(vb, theme_blend)


func frame_colors() -> Dictionary:
	var sky: Array = col("sky")
	var neon: Color = col("neon")
	var ground: Color = col("ground")
	_neon2 = col("neon2")
	return {"grass": [ground, ground.darkened(0.1)], "rumble": [neon, neon.darkened(0.45)], "road": [Color("0b0712"), Color("08050e")],
		"lane": [_neon2, Color(0, 0, 0, 0)], "fog": sky[1]}


## Grelha néon no chão: linhas transversais a cada 4 segmentos e linhas a fugir para o horizonte.
func _draw_row_extra(r: Dictionary) -> void:
	var f: float = r.fog
	if f >= 0.95:
		return
	var gc := Color(_neon2, (1.0 - f) * 0.55)
	var y1: float = r.y1
	if int(r.i) % 4 < r.segs.size():
		var t := 2.0 if r.n < 40 else 1.0
		quad(Vector2(0, y1 - t), Vector2(W, y1 - t), Vector2(W, y1), Vector2(0, y1), gc)
	if r.n < 110:
		var c1: float = r.c1
		var c2: float = r.c2
		var x1: float = r.x1
		var x2: float = r.x2
		var w1: float = r.w1
		var w2: float = r.w2
		var y2: float = r.y2
		var t1 := w1 * 0.006
		var t2 := w2 * 0.006
		for k: float in GRID_X:
			for s: float in [-1.0, 1.0]:
				var a1 := x1 + w1 * s * (k + c1)
				var a2 := x2 + w2 * s * (k + c2)
				quad(Vector2(a1 - t1, y1), Vector2(a1 + t1, y1), Vector2(a2 + t2, y2), Vector2(a2 - t2, y2), gc)


func _draw_background() -> void:
	var hy := horizon_y()
	var sky: Array = col("sky")
	var bands := 24
	for i in bands:
		var y0 := hy * i / bands
		draw_rect(Rect2(0, y0, W, hy / bands + 1), (sky[0] as Color).lerp(sky[1], pow(float(i) / (bands - 1), 1.6)))
	draw_rect(Rect2(0, hy, W, H - hy), sky[1])
	for s in stars:
		var tw := 0.5 + 0.5 * sin(time * 2.0 + s.z)
		draw_rect(Rect2(fposmod(s.x - bg_scroll * 0.3, W), s.y, 2, 2), Color(1, 1, 1, 0.25 + 0.6 * tw * (1.0 - s.y / 320.0)))
	# sol (troca suavemente de cor com o tema)
	var sun_x := W / 2 - fposmod(bg_scroll * 0.5 + 640.0, 2400.0) + 640.0
	var sun_rect := Rect2(sun_x - 150, hy - 230, 300, 300)
	if theme_blend < 1.0:
		draw_texture_rect(_sun(prev_theme), sun_rect, false, Color(1, 1, 1, 1.0 - theme_blend))
	draw_texture_rect(_sun(theme), sun_rect, false, Color(1, 1, 1, theme_blend))
	draw_texture_rect(glow_tex, sun_rect.grow(120), false, Color(col("sun")[1], 0.18))
	for pass_i in 2:
		if pass_i == 0 and theme_blend >= 1.0:
			continue
		var t := prev_theme if pass_i == 0 else theme
		var a := (1.0 - theme_blend) if pass_i == 0 else theme_blend
		var tc: Dictionary = THEME_COLORS[t]
		draw_layer(t, 0, hy + 4, 130.0, 0.8, Color(Color("12042a"), a), hy + 40, Color(tc.neon2, a * 0.9), 2.0)
		draw_layer(t, 1, hy + 6, 60.0, 2.0, Color(tc.ground, a), H, Color(tc.neon, a), 2.0)


func sprite_palette(kind: String, t: String) -> Dictionary:
	var tc: Dictionary = THEME_COLORS[t]
	var dark := Color("0e0420")
	var dark2 := Color("1d0b3a")
	var p := {"T": dark2, "t": dark, "L": dark2, "l": dark, "F": tc.neon, "W": tc.neon2, "R": tc.neon,
		"Y": Color("ffd319"), "K": dark, "G": dark2, "S": dark2, "s": dark, "D": tc.neon2}
	if kind == "lamp":
		p.Y = Color("fff36b")
	return p


func sprite_outline(t: String) -> Color:
	return THEME_COLORS[t].neon


func sprite_colors(r: Dictionary) -> Dictionary:
	var neon: Color = col("neon")
	var neon2: Color = col("neon2")
	var a := 1.0 - float(r.fog) * 0.6
	return {
		"sign_panel": Color("0e0420"), "sign_frame": Color(neon, a), "sign_ink": Color(neon2, a), "leg": Color(neon, 0.6 * a),
		"fork_panel": Color("0e0420"), "mid_panel": Color(neon2, a), "mid_ink": Color("0e0420"),
		"pole": neon2, "band": Color("0e0420"), "check": neon, "band_ink": neon2,
		"building": Color("0e0420"), "building2": Color("140630"), "window": Color("1d0b3a"), "lit": neon2, "outline": neon,
	}


func _car_tex(kind: String, ci: int) -> Texture2D:
	var key := "car_%s_%d" % [kind, ci]
	if not tex.has(key):
		var neon_cols := [Color("00e5ff"), Color("ff2975"), Color("fff36b"), Color("2bff88"), Color("b04aff"), Color("ff7b00")]
		var n: Color = neon_cols[ci % neon_cols.size()]
		tex[key] = make_sprite(TRAFFIC[kind], {"B": Color("140630"), "H": n, "b": Color("0a0318"), "W": Color("1d0b3a"),
			"R": Color("ff2975"), "P": n, "G": Color("2a1450"), "K": Color("05010f")}, n)
	return tex[key]


func _draw_car(car: Dictionary, rect: Rect2, alpha: float, _r: Dictionary) -> void:
	var t := _car_tex(car.kind, car.color)
	var h := rect.size.x * t.get_height() / t.get_width()
	var r := Rect2(rect.position.x, rect.position.y - h, rect.size.x, h)
	# farolins a brilhar
	var gw := rect.size.x * 0.5
	for fx: float in [0.13, 0.87]:
		draw_texture_rect(glow_tex, Rect2(r.position.x + r.size.x * fx - gw / 2, r.position.y + h * 0.6 - gw / 2, gw, gw), false, Color(1.0, 0.16, 0.46, 0.5 * alpha))
	draw_tex(t, r, alpha)


func _draw_player() -> void:
	var t: Texture2D = tex.player
	var rect := player_rect(float(t.get_height()) / t.get_width())
	var c := rect.get_center()
	var flip := cos(game.crash_spin) if game.state == OutRunGame.State.CRASH else 1.0
	draw_set_transform(c, game.steer * 0.05, Vector2(flip, 1.0))
	var gw := rect.size.x * 0.45
	for fx: float in [-0.4, 0.4]:
		draw_texture_rect(glow_tex, Rect2(rect.size.x * fx - gw / 2, rect.size.y * 0.15 - gw / 2, gw, gw), false, Color(1.0, 0.16, 0.46, 0.55))
	draw_texture_rect(glow_tex, Rect2(-rect.size.x * 0.7, rect.size.y * 0.3, rect.size.x * 1.4, rect.size.y * 0.5), false, Color(0, 0.9, 1, 0.18))
	draw_texture_rect(t, Rect2(-rect.size / 2, rect.size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if flash > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(1, 0.16, 0.46, flash * 1.6))


func neon_text(text: String, x: float, y: float, cell: float, c: Color) -> void:
	PixelFont.draw(self, text, x, y, cell, Color(c, 0.18))
	PixelFont.draw(self, text, x + 1.5, y + 1.5, cell, Color(c, 0.25))
	PixelFont.draw(self, text, x, y, cell, c.lightened(0.35))


func _draw_hud() -> void:
	var g := game
	var neon: Color = col("neon")
	var neon2: Color = col("neon2")
	draw_texture_rect(scan_tex, Rect2(0, 0, W, H), true)
	neon_text(I18n.t("TEMPO"), W / 2, 16, 3, neon2)
	var secs := str(ceili(g.time_left))
	var warn := g.time_left < 10.0 and fmod(time, 0.5) < 0.25
	PixelFont.draw(self, secs, W / 2 - 4, 44, 9, Color(neon2, 0.7))
	PixelFont.draw(self, secs, W / 2 + 4, 44, 9, Color(neon, 0.8))
	PixelFont.draw(self, secs, W / 2, 44, 9, Color.WHITE if not warn else neon)
	neon_text(I18n.t("PONTOS"), 130, 16, 3, neon)
	neon_text("%d" % g.score, 130, 44, 4, Color.WHITE)
	neon_text(I18n.t("ETAPA %d") % (g.stage + 1), 1120, 16, 3, neon)
	draw_route_map(Vector2(1040, 92), Vector2(40, 26), Color(neon2, 0.35), Color(neon2, 0.7), neon, 2.0, 4.0)
	# velocidade: barra em leque
	var kmh := g.kmh()
	neon_text("%3d" % kmh, 120, 630, 6, neon2)
	neon_text("KM/H", 120, 684, 2, neon)
	var pct := g.speed / OutRunGame.MAX_SPEED
	var center := Vector2(330, 700)
	for i in 20:
		var a := PI + PI * 0.5 * (i / 19.0)
		var on := i / 19.0 <= pct
		var cc := neon2.lerp(neon, i / 19.0)
		draw_line(center + Vector2.from_angle(a) * 70, center + Vector2.from_angle(a) * 100, cc if on else Color(cc, 0.15), 5.0)
	if g.manual_gears:
		neon_text(I18n.t("ALTA") if g.high_gear else I18n.t("BAIXA"), 330, 600, 3, neon2)
	for p in popups:
		var a := clampf(float(p.life), 0.0, 1.0)
		neon_text(I18n.t("TEMPO EXTRA ") + str(p.text), W / 2, 150, 5, Color(neon2, a))


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.04, 0.0, 0.1, 0.9),
		"border": Color("ff2975"),
		"text": Color("f2e9ff"),
		"accent": Color("00e5ff"),
		"button": Color(0.1, 0.02, 0.2),
		"button_hover": Color(0.3, 0.05, 0.35),
		"radius": 2,
		"dim": Color(0.05, 0, 0.1, 0.35),
	}
