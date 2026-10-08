extends OutRunSkin
## Clássico 1986: céu azul de verão, cores saturadas, cenário em sprites que crescem em direção
## ao ecrã, bermas às riscas e o HUD amarelo dos arcades de condução.

const THEME_COLORS := {
	"costa": {"sky": [Color("1c6fe0"), Color("8fd3ff")], "far": Color("6f9fd8"), "near": Color("2f8f6f"),
		"grass": [Color("ecd9a0"), Color("e2cc8c")], "rumble": [Color("e03131"), Color("ffffff")], "road": [Color("8c8c8c"), Color("858585")], "leaf": Color("2f9e44"), "leaf2": Color("1f6f30")},
	"deserto": {"sky": [Color("e8662c"), Color("ffd68a")], "far": Color("b4532a"), "near": Color("d98b4f"),
		"grass": [Color("e3b26c"), Color("d9a45d")], "rumble": [Color("b03a2e"), Color("fff4e0")], "road": [Color("9a8b7a"), Color("938372")], "leaf": Color("5c940d"), "leaf2": Color("3b6d0a")},
	"floresta": {"sky": [Color("2f74d0"), Color("a5d8ff")], "far": Color("2b6a4f"), "near": Color("3c8c3c"),
		"grass": [Color("2f9e44"), Color("2b8a3e")], "rumble": [Color("e03131"), Color("ffffff")], "road": [Color("888888"), Color("808080")], "leaf": Color("2b8a3e"), "leaf2": Color("1b5e2a")},
	"alpes": {"sky": [Color("4c9be8"), Color("e3f2ff")], "far": Color("e9f0f8"), "near": Color("6f8fa6"),
		"grass": [Color("5fae52"), Color("56a149")], "rumble": [Color("1971c2"), Color("ffffff")], "road": [Color("8e8e96"), Color("86868e")], "leaf": Color("1f6f43"), "leaf2": Color("134a2c")},
	"cidade": {"sky": [Color("5560c8"), Color("f7b89a")], "far": Color("454a78"), "near": Color("6a6e92"),
		"grass": [Color("9a9a9a"), Color("909090")], "rumble": [Color("fab005"), Color("222222")], "road": [Color("5a5a5a"), Color("535353")], "leaf": Color("2f9e44"), "leaf2": Color("1f6f30")},
	"vinhas": {"sky": [Color("3d8fe0"), Color("ffe8b0")], "far": Color("8f9f6a"), "near": Color("6f9f4a"),
		"grass": [Color("86b442"), Color("7aa63a")], "rumble": [Color("e03131"), Color("ffffff")], "road": [Color("8a8a8a"), Color("838383")], "leaf": Color("5c940d"), "leaf2": Color("3b6d0a")},
}
const CAR_COLORS := [Color("e03131"), Color("1c7ed6"), Color("f8f9fa"), Color("fab005"), Color("37b24d"), Color("7048e8")]
const CLOUD := [
	"......WWWW..........",
	"....WWWWWWWW..WWW...",
	"..WWWWWWWWWWWWWWWWW.",
	".WWWWWWWWWWWWWWWWWWW",
	"WWWWWWWWWWWWWWWWWWWW",
	".ccccccccccccccccc..",
]
const YELLOW := Color("ffd43b")
const ORANGE := Color("ff922b")

var cloud_tex: Texture2D


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex.player = make_sprite(PLAYER_CAR, {"Y": Color("5c3a1e"), "y": Color("f2c14e"), "G": Color("ced4da"), "D": Color("343a40"),
		"B": Color("e03131"), "H": Color("ff8787"), "b": Color("a51111"), "R": Color("ff2a2a"), "r": Color("ffd8a8"), "P": Color("f8f9fa"), "K": Color("1a1a1a")})
	cloud_tex = make_sprite(CLOUD, {"W": Color("ffffff"), "c": Color("d0ebff")})


func _build_sfx() -> void:
	sfx.engine = Synth.to_stream(Synth.mix([
		Synth.render(55.0, 1.0, {"wave": "saw", "volume": 0.3, "lowpass": 0.12, "attack": 0.0, "release": 0.0}),
		Synth.render(110.0, 1.0, {"wave": "square", "volume": 0.08, "lowpass": 0.08, "attack": 0.0, "release": 0.0}),
	]))
	sfx.skid = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.5, {"wave": "noise", "volume": 0.18, "lowpass": 0.35, "attack": 0.0, "release": 0.0}),
		Synth.render(1400.0, 0.5, {"wave": "square", "volume": 0.03, "lowpass": 0.3, "attack": 0.0, "release": 0.0}),
	]))
	sfx.beep = Synth.tone(880.0, 0.25, {"wave": "square", "volume": 0.16, "lowpass": 0.5})
	sfx.go = Synth.tone(1760.0, 0.6, {"wave": "square", "volume": 0.16, "lowpass": 0.5, "decay": 2.0})
	sfx.crash = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.1, {"wave": "noise", "volume": 0.45, "lowpass": 0.2, "decay": 3.0}),
		Synth.render(160.0, 0.6, {"wave": "square", "freq_end": 40.0, "volume": 0.15, "lowpass": 0.2}),
	]))
	sfx.bump = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.2, {"wave": "noise", "volume": 0.3, "lowpass": 0.25, "decay": 18.0}),
		Synth.render(90.0, 0.2, {"wave": "sine", "freq_end": 50.0, "volume": 0.3}),
	]))
	sfx.gear = Synth.tone(0.0, 0.07, {"wave": "noise", "volume": 0.2, "lowpass": 0.5, "decay": 40.0})
	var arp := []
	for f in [784.0, 988.0, 1175.0, 1568.0, 1175.0, 1568.0]:
		arp.append(Synth.render(f, 0.09, {"wave": "square", "volume": 0.12, "lowpass": 0.45}))
	sfx.checkpoint = Synth.concat(arp)
	var warn := []
	for i in 3:
		warn.append(Synth.render(1320.0, 0.08, {"wave": "square", "volume": 0.12}))
		warn.append(Synth.silence(0.07))
	sfx.warning = Synth.concat(warn)
	var fan := []
	for n in [[523.0, 0.15], [659.0, 0.15], [784.0, 0.15], [1046.0, 0.3], [784.0, 0.15], [1046.0, 0.6]]:
		fan.append(Synth.render(n[0], n[1], {"wave": "square", "volume": 0.14, "lowpass": 0.4}))
	sfx.goal = Synth.concat(fan)
	var down := []
	for f in [660.0, 523.0, 440.0, 330.0]:
		down.append(Synth.render(f, 0.22, {"wave": "square", "volume": 0.12, "lowpass": 0.35}))
	sfx.time_up = Synth.concat(down)


func fog_at(d: float) -> float:
	return clampf((d - 0.72) * 3.0, 0.0, 1.0)


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
	return {"grass": col("grass"), "rumble": col("rumble"), "road": col("road"), "lane": [Color.WHITE, Color(0, 0, 0, 0)], "fog": sky[1]}


func _draw_background() -> void:
	var hy := horizon_y()
	var sky: Array = col("sky")
	var bands := 10
	for i in bands:
		var y0 := hy * i / bands
		draw_rect(Rect2(0, y0, W, hy / bands + 1), (sky[0] as Color).lerp(sky[1], float(i) / (bands - 1)))
	draw_rect(Rect2(0, hy, W, H - hy), sky[1])
	# nuvens
	for i in 5:
		var cx := fposmod(i * 300.0 + 80.0 - bg_scroll * 0.4 + time * 6.0, 1500.0) - 110.0
		var cy := 120.0 + float((i * 53) % 110)
		var sc := 4.0 + (i % 3)
		draw_texture_rect(cloud_tex, Rect2(cx, cy, 20 * sc, 6 * sc), false)
	for pass_i in 2:
		var t := prev_theme if pass_i == 0 else theme
		var a := 1.0 if pass_i == 0 else theme_blend
		if pass_i == 1 and theme == prev_theme and pass_i == 1:
			a = 1.0
		if pass_i == 0 and theme_blend >= 1.0:
			continue
		var tc: Dictionary = THEME_COLORS[t]
		draw_layer(t, 0, hy + 4, 120.0, 0.8, Color(tc.far, a), hy + 40)
		if t == "alpes":
			draw_layer(t, 0, hy + 4, 120.0, 0.8, Color(0, 0, 0, 0), H, Color(Color("8aa2bd"), a), 3.0)
		draw_layer(t, 1, hy + 6, 60.0, 2.0, Color(tc.near, a), H)
		if t == "costa":
			draw_rect(Rect2(0, hy - 2, W, 10), Color(Color("1971c2"), a))


func sprite_palette(kind: String, t: String) -> Dictionary:
	var tc: Dictionary = THEME_COLORS[t]
	var p := {"T": Color("8b5a2b"), "t": Color("5e3b1a"), "L": tc.leaf, "l": tc.leaf2, "F": Color("f06595"),
		"W": Color("ffffff"), "R": Color("e03131"), "Y": YELLOW, "K": Color("222222"), "G": Color("9aa0a6"),
		"S": Color("b0a595"), "s": Color("7d7468"), "D": Color("3b4a6b")}
	match kind:
		"palm", "palm2":
			p.F = Color("6b4423")
			p.L = Color("37b24d")
			p.l = Color("2b8a3e")
		"vine":
			p.F = Color("7b2f8e")
		"chalet":
			p.R = Color("8b2e1f")
			p.T = Color("b0703a")
			p.t = Color("7a4a22")
		"cactus":
			p.L = Color("40a040")
			p.l = Color("2b7a2b")
			p.s = Color("b98e58")
		"house":
			p.R = Color("d9480f")
		"lamp":
			p.G = Color("495057")
		"deadtree":
			p.T = Color("7a5a3a")
			p.t = Color("5a4028")
	return p


func sprite_colors(r: Dictionary) -> Dictionary:
	return {
		"sign_panel": Color("1864ab"), "sign_frame": Color.WHITE, "sign_ink": Color.WHITE, "leg": Color("495057"),
		"fork_panel": Color("2b8a3e"), "mid_panel": Color("f08c00"), "mid_ink": Color.BLACK,
		"pole": Color("dee2e6"), "band": Color("c92a2a"), "check": Color.WHITE, "band_ink": Color.WHITE,
		"building": Color("a5a9c9").lerp(Color("f7b89a"), float(r.fog) * 0.8), "building2": Color("d8b48a").lerp(Color("f7b89a"), float(r.fog) * 0.8),
		"window": Color("4a5a8a"), "lit": Color("ffe066"),
	}


func _car_tex(kind: String, ci: int) -> Texture2D:
	var key := "car_%s_%d" % [kind, ci]
	if not tex.has(key):
		var b: Color = CAR_COLORS[ci % CAR_COLORS.size()]
		tex[key] = make_sprite(TRAFFIC[kind], {"B": b, "H": b.lightened(0.35), "b": b.darkened(0.35), "W": Color("1c2b45"),
			"R": Color("ff3b3b"), "P": Color("f8f9fa"), "G": Color("adb5bd"), "K": Color("1a1a1a")})
	return tex[key]


func _draw_car(car: Dictionary, rect: Rect2, alpha: float, _r: Dictionary) -> void:
	var t := _car_tex(car.kind, car.color)
	var h := rect.size.x * t.get_height() / t.get_width()
	draw_tex(t, Rect2(rect.position.x, rect.position.y - h, rect.size.x, h), alpha)


func _draw_player() -> void:
	var t: Texture2D = tex.player
	var rect := player_rect(float(t.get_height()) / t.get_width())
	var c := rect.get_center()
	var flip := cos(game.crash_spin) if game.state == OutRunGame.State.CRASH else 1.0
	draw_set_transform(c, game.steer * 0.05, Vector2(flip, 1.0))
	# sombra
	draw_rect(Rect2(-rect.size.x / 2 + 6, rect.size.y / 2 - 10, rect.size.x - 12, 14), Color(0, 0, 0, 0.3))
	draw_texture_rect(t, Rect2(-rect.size / 2, rect.size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if flash > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(1, 1, 1, flash * 1.5))


func _draw_hud() -> void:
	var g := game
	PixelFont.draw(self, I18n.t("TEMPO"), W / 2, 18, 3, YELLOW)
	var secs := str(ceili(g.time_left))
	var warn := g.time_left < 10.0 and fmod(time, 0.5) < 0.25
	PixelFont.draw(self, secs, W / 2 + 3, 48, 9, Color.BLACK)
	PixelFont.draw(self, secs, W / 2, 45, 9, ORANGE if warn else YELLOW)
	PixelFont.draw(self, I18n.t("PONTOS"), 120, 18, 3, YELLOW)
	PixelFont.draw(self, "%d" % g.score, 120, 46, 4, Color.WHITE)
	PixelFont.draw(self, I18n.t("ETAPA %d") % (g.stage + 1), 1120, 18, 3, YELLOW)
	draw_route_map(Vector2(1040, 92), Vector2(40, 26), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.8), YELLOW, 2.0, 4.0)
	# velocímetro e conta-rotações
	var kmh := g.kmh()
	PixelFont.draw(self, "%3d" % kmh, 110, 640, 6, Color.WHITE)
	PixelFont.draw(self, "KM/H", 110, 690, 2, YELLOW)
	var bars := 16
	var lit := int(g.speed / OutRunGame.MAX_SPEED * bars + 0.5)
	for i in bars:
		var hgt := 6.0 + i * 2.2
		var c := Color("51cf66") if i < 10 else (YELLOW if i < 13 else Color("ff3b3b"))
		draw_rect(Rect2(212 + i * 12, 700 - hgt, 9, hgt), c if i < lit else Color(0, 0, 0, 0.35))
	if g.manual_gears:
		PixelFont.draw(self, I18n.t("ALTA") if g.high_gear else I18n.t("BAIXA"), 310, 600, 3, YELLOW)
	for p in popups:
		var a := clampf(float(p.life), 0.0, 1.0)
		PixelFont.draw(self, I18n.t("TEMPO EXTRA ") + str(p.text), W / 2, 180, 5, Color(YELLOW, a))


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.05, 0.12, 0.35, 0.92),
		"border": YELLOW,
		"text": Color.WHITE,
		"accent": YELLOW,
		"button": Color(0.08, 0.2, 0.5),
		"button_hover": Color(0.15, 0.3, 0.65),
		"radius": 4,
		"dim": Color(0, 0, 0, 0.35),
	}
