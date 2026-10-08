extends OutRunSkin
## Cartaz de Viagem: a estrada como um cartaz turístico Art Déco dos anos 30 — céu em faixas
## lisas, sol com raios, montanhas recortadas com traço a tinta, papel com grão e um HUD de
## placas, com velocímetro de mostrador.

const INK := Color("1d2b45")
const PAPER := Color("f3e9d2")
const RED := Color("c8553d")
const GOLD := Color("e0a33a")
const THEME_COLORS := {
	"costa": {"sky": [Color("2f7f9f"), Color("74b6c2"), Color("f2d8a2")], "far": Color("4f7f95"), "near": Color("2f6b6f"),
		"grass": [Color("ead4a1"), Color("e1c890")], "road": [Color("56646c"), Color("4f5d65")], "rumble": [RED, PAPER], "leaf": Color("3f7f5f"), "leaf2": Color("2c5a46")},
	"deserto": {"sky": [Color("b84a33"), Color("e3854c"), Color("f6cf8a")], "far": Color("8a3b2d"), "near": Color("c47548"),
		"grass": [Color("e5b678"), Color("dcaa69")], "road": [Color("6a5f5a"), Color("625752")], "rumble": [INK, PAPER], "leaf": Color("5f7f3a"), "leaf2": Color("3f5a27")},
	"floresta": {"sky": [Color("3a7686"), Color("8bbaa8"), Color("e8e0b4")], "far": Color("3f6f5a"), "near": Color("2f5a43"),
		"grass": [Color("5f8f4a"), Color("57843f")], "road": [Color("56646c"), Color("4f5d65")], "rumble": [RED, PAPER], "leaf": Color("2f6a43"), "leaf2": Color("1f4a2f")},
	"alpes": {"sky": [Color("3a6a9c"), Color("8cb1d1"), Color("eef0e6")], "far": Color("f3f1ea"), "near": Color("4f6f86"),
		"grass": [Color("7fa36a"), Color("76995f")], "road": [Color("5a6470"), Color("535d69")], "rumble": [RED, PAPER], "leaf": Color("2f5f4a"), "leaf2": Color("1f3f33")},
	"cidade": {"sky": [Color("2f3f6f"), Color("8a6c9c"), Color("f0b98f")], "far": Color("3a3f5f"), "near": Color("5a5f7f"),
		"grass": [Color("b8ad98"), Color("ada28c")], "road": [Color("4a4f57"), Color("444950")], "rumble": [GOLD, INK], "leaf": Color("3f7f5f"), "leaf2": Color("2c5a46")},
	"vinhas": {"sky": [Color("4c8aa9"), Color("a2c6c0"), Color("f5e1ae")], "far": Color("8a8a5c"), "near": Color("6a873c"),
		"grass": [Color("9fb35a"), Color("94a74f")], "road": [Color("5a6068"), Color("535961")], "rumble": [Color("8a2f4c"), PAPER], "leaf": Color("4f7a2a"), "leaf2": Color("355a1c")},
}
const CAR_COLORS := [Color("c8553d"), Color("2f6b8f"), Color("e0a33a"), Color("3f7f5f"), Color("f3e9d2"), Color("6f4f8f")]

var grain: Texture2D
var font: Font


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	font = ThemeDB.fallback_font
	tex.player = make_sprite(PLAYER_CAR, {"Y": Color("3a2a1f"), "y": GOLD, "G": PAPER, "D": INK,
		"B": Color("2f6b8f"), "H": Color("74a8c4"), "b": Color("1f4a63"), "R": RED, "r": Color("f6cf8a"), "P": PAPER, "K": INK}, INK)
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1934
	for i in 1400:
		var c := Color(INK, rng.randf_range(0.04, 0.12)) if rng.randf() < 0.6 else Color(PAPER, rng.randf_range(0.06, 0.16))
		img.set_pixel(rng.randi() % 128, rng.randi() % 128, c)
	grain = ImageTexture.create_from_image(img)


func _build_sfx() -> void:
	sfx.engine = Synth.to_stream(Synth.mix([
		Synth.render(55.0, 1.0, {"wave": "triangle", "volume": 0.35, "attack": 0.0, "release": 0.0}),
		Synth.render(110.0, 1.0, {"wave": "saw", "volume": 0.08, "lowpass": 0.06, "attack": 0.0, "release": 0.0}),
		Synth.render(0.0, 1.0, {"wave": "noise", "volume": 0.04, "lowpass": 0.05, "attack": 0.0, "release": 0.0}),
	]))
	sfx.skid = Synth.to_stream(Synth.render(0.0, 0.5, {"wave": "noise", "volume": 0.15, "lowpass": 0.3, "attack": 0.0, "release": 0.0}))
	# buzina de época para a partida
	sfx.beep = Synth.to_stream(Synth.mix([
		Synth.render(440.0, 0.25, {"wave": "saw", "volume": 0.08, "lowpass": 0.2}),
		Synth.render(554.0, 0.25, {"wave": "saw", "volume": 0.08, "lowpass": 0.2}),
	]))
	sfx.go = Synth.to_stream(Synth.mix([
		Synth.render(587.0, 0.7, {"wave": "saw", "volume": 0.08, "lowpass": 0.2, "decay": 1.5}),
		Synth.render(740.0, 0.7, {"wave": "saw", "volume": 0.08, "lowpass": 0.2, "decay": 1.5}),
		Synth.render(880.0, 0.7, {"wave": "saw", "volume": 0.06, "lowpass": 0.2, "decay": 1.5}),
	]))
	sfx.crash = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.0, {"wave": "noise", "volume": 0.4, "lowpass": 0.15, "decay": 3.5}),
		Synth.render(120.0, 0.5, {"wave": "triangle", "freq_end": 40.0, "volume": 0.3}),
	]))
	sfx.bump = Synth.tone(0.0, 0.18, {"wave": "noise", "volume": 0.3, "lowpass": 0.15, "decay": 20.0})
	sfx.gear = Synth.tone(0.0, 0.06, {"wave": "noise", "volume": 0.18, "lowpass": 0.3, "decay": 50.0})
	# campainha de chegada à etapa
	var bell := []
	for f in [1046.0, 1318.0, 1568.0]:
		bell.append(Synth.render(f, 0.35, {"wave": "sine", "volume": 0.18, "decay": 6.0}))
	sfx.checkpoint = Synth.concat(bell)
	var warn := []
	for i in 3:
		warn.append(Synth.render(1568.0, 0.12, {"wave": "sine", "volume": 0.16, "decay": 15.0}))
		warn.append(Synth.silence(0.05))
	sfx.warning = Synth.concat(warn)
	var fan := []
	for n in [[523.0, 0.18], [659.0, 0.18], [784.0, 0.18], [1046.0, 0.7]]:
		fan.append(Synth.render(n[0], n[1], {"wave": "triangle", "volume": 0.2, "release": 0.04}))
	sfx.goal = Synth.concat(fan)
	sfx.time_up = Synth.to_stream(Synth.mix([
		Synth.render(392.0, 1.0, {"wave": "saw", "volume": 0.08, "lowpass": 0.15, "decay": 1.5}),
		Synth.render(466.0, 1.0, {"wave": "saw", "volume": 0.08, "lowpass": 0.15, "decay": 1.5}),
	]))


func col(key: String) -> Variant:
	var a: Dictionary = THEME_COLORS[prev_theme]
	var b: Dictionary = THEME_COLORS[theme]
	if theme_blend >= 1.0:
		return b[key]
	var va: Variant = a[key]
	var vb: Variant = b[key]
	if va is Array:
		var out := []
		for i in (va as Array).size():
			out.append((va[i] as Color).lerp(vb[i], theme_blend))
		return out
	return (va as Color).lerp(vb, theme_blend)


func fog_at(d: float) -> float:
	return clampf((d - 0.45) * 1.4, 0.0, 0.85)


func frame_colors() -> Dictionary:
	var sky: Array = col("sky")
	return {"grass": col("grass"), "rumble": col("rumble"), "road": col("road"), "lane": [PAPER, Color(0, 0, 0, 0)], "fog": sky[2]}


func _draw_background() -> void:
	var hy := horizon_y()
	var sky: Array = col("sky")
	# céu em três faixas lisas
	draw_rect(Rect2(0, 0, W, hy * 0.42), sky[0])
	draw_rect(Rect2(0, hy * 0.42, W, hy * 0.33), sky[1])
	draw_rect(Rect2(0, hy * 0.75, W, H - hy * 0.75), sky[2])
	# sol com raios
	var sun := Vector2(fposmod(W * 0.62 - bg_scroll * 0.4 + 400.0, 2000.0) - 400.0, hy - 70)
	var rays := 22
	for i in rays:
		if i % 2 == 0:
			var a0 := TAU * i / rays + time * 0.02
			var a1 := TAU * (i + 1) / rays + time * 0.02
			draw_colored_polygon(PackedVector2Array([sun, sun + Vector2.from_angle(a0) * 1600, sun + Vector2.from_angle(a1) * 1600]), Color(PAPER, 0.13))
	draw_circle(sun, 92, INK)
	draw_circle(sun, 88, PAPER)
	draw_circle(sun, 70, Color(GOLD, 0.35))
	# nuvens Déco
	for i in 3:
		var cx := fposmod(i * 520.0 + 150.0 - bg_scroll * 0.6 + time * 4.0, 1700.0) - 200.0
		_cloud(Vector2(cx, 110.0 + i * 38.0), 1.0 - i * 0.18)
	for pass_i in 2:
		if pass_i == 0 and theme_blend >= 1.0:
			continue
		var t := prev_theme if pass_i == 0 else theme
		var a := (1.0 - theme_blend) if pass_i == 0 else theme_blend
		var tc: Dictionary = THEME_COLORS[t]
		draw_layer(t, 0, hy + 4, 140.0, 0.8, Color(tc.far, a), hy + 40, Color(INK, a), 2.5)
		draw_layer(t, 1, hy + 6, 60.0, 2.0, Color(tc.near, a), H, Color(INK, a), 2.5)


func _cloud(p: Vector2, s: float) -> void:
	for pass_i in 2:
		var g := 3.0 if pass_i == 0 else 0.0
		var c := INK if pass_i == 0 else PAPER
		draw_circle(p + Vector2(-40, 0) * s, 26 * s + g, c)
		draw_circle(p + Vector2(0, -14) * s, 34 * s + g, c)
		draw_circle(p + Vector2(42, 0) * s, 24 * s + g, c)
		draw_rect(Rect2(p + Vector2(-66, 0) * s - Vector2(g, 0), Vector2(132 * s + g * 2, 26 * s + g)), c)


func sprite_palette(kind: String, t: String) -> Dictionary:
	var tc: Dictionary = THEME_COLORS[t]
	var p := {"T": Color("7a4a2a"), "t": Color("4f2f1f"), "L": tc.leaf, "l": tc.leaf2, "F": RED,
		"W": PAPER, "R": RED, "Y": GOLD, "K": INK, "G": Color("8f9aa0"), "S": Color("c9bda5"), "s": Color("9a8f78"), "D": INK}
	match kind:
		"palm", "palm2":
			p.F = Color("5a3a22")
		"vine":
			p.F = Color("6f2f5f")
		"cactus":
			p.L = Color("5f8f4a")
			p.l = Color("3f6a33")
		"chalet":
			p.T = Color("a8683a")
			p.t = Color("7a4a2a")
	return p


func sprite_outline(_t: String) -> Color:
	return INK


func fit_text(text: String, box: Rect2, color: Color) -> void:
	var size := int(box.size.y * 0.55)
	if size < 5:
		return
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if w > box.size.x * 0.88:
		size = int(size * box.size.x * 0.88 / w)
	if size < 5:
		return
	draw_string(font, Vector2(box.position.x, box.get_center().y + size * 0.36), text, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, size, color)


func sprite_colors(r: Dictionary) -> Dictionary:
	var haze: Color = col("sky")[2]
	var f := float(r.fog) * 0.7
	return {
		"sign_panel": RED.lerp(haze, f), "sign_frame": INK, "sign_ink": PAPER, "leg": INK,
		"fork_panel": Color("2f6b8f").lerp(haze, f), "mid_panel": GOLD.lerp(haze, f), "mid_ink": INK,
		"pole": INK, "band": PAPER, "check": INK, "band_ink": RED,
		"building": PAPER.darkened(0.08).lerp(haze, f), "building2": Color("e2c99a").lerp(haze, f), "window": Color("5a6a86"), "lit": GOLD, "outline": INK,
	}


func _car_tex(kind: String, ci: int) -> Texture2D:
	var key := "car_%s_%d" % [kind, ci]
	if not tex.has(key):
		var b: Color = CAR_COLORS[ci % CAR_COLORS.size()]
		tex[key] = make_sprite(TRAFFIC[kind], {"B": b, "H": b.lightened(0.3), "b": b.darkened(0.3), "W": Color("4a5a76"),
			"R": RED, "P": PAPER, "G": Color("c9bda5"), "K": INK}, INK)
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
	draw_rect(Rect2(-rect.size.x / 2 + 4, rect.size.y / 2 - 12, rect.size.x - 8, 16), Color(INK, 0.35))
	draw_texture_rect(t, Rect2(-rect.size / 2, rect.size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if flash > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(PAPER, flash * 2.0))


# ---------------------------------------------------------------- HUD de placas

func plaque(r: Rect2) -> void:
	var n := 10.0
	var pts := PackedVector2Array([r.position + Vector2(n, 0), Vector2(r.end.x - n, r.position.y), Vector2(r.end.x, r.position.y + n),
		Vector2(r.end.x, r.end.y - n), Vector2(r.end.x - n, r.end.y), Vector2(r.position.x + n, r.end.y), Vector2(r.position.x, r.end.y - n), r.position + Vector2(0, n)])
	draw_colored_polygon(pts, Color(PAPER, 0.94))
	pts.append(pts[0])
	draw_polyline(pts, INK, 3.0)
	var inner := PackedVector2Array()
	for p in pts:
		inner.append(p + (r.get_center() - p).normalized() * 6.0)
	draw_polyline(inner, Color(INK, 0.5), 1.0)


func deco_text(text: String, cx: float, baseline: float, size: int, color: Color) -> void:
	draw_string(font, Vector2(cx - 300, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, 600, size, color)


func spaced(text: String) -> String:
	return " ".join(text.split(""))


func _draw_hud() -> void:
	var g := game
	# moldura do cartaz
	draw_texture_rect(grain, Rect2(0, 0, W, H), true)
	var m := 10.0
	draw_rect(Rect2(0, 0, W, m), PAPER)
	draw_rect(Rect2(0, H - m, W, m), PAPER)
	draw_rect(Rect2(0, 0, m, H), PAPER)
	draw_rect(Rect2(W - m, 0, m, H), PAPER)
	draw_rect(Rect2(m, m, W - m * 2, H - m * 2), INK, false, 3.0)
	# tempo
	plaque(Rect2(W / 2 - 95, 22, 190, 104))
	deco_text(spaced(I18n.t("TEMPO")), W / 2, 48, 16, INK)
	var warn := g.time_left < 10.0 and fmod(time, 0.5) < 0.25
	deco_text(str(ceili(g.time_left)), W / 2, 112, 62, RED if not warn else GOLD)
	# pontos
	plaque(Rect2(34, 22, 240, 78))
	deco_text(spaced(I18n.t("PONTOS")), 154, 48, 15, INK)
	deco_text("%d" % g.score, 154, 86, 32, INK)
	# etapa e mapa
	plaque(Rect2(W - 284, 22, 250, 150))
	deco_text(I18n.t("ETAPA %d · %s") % [g.stage + 1, I18n.t(OutRunGame.THEME_NAMES[g.theme]).to_upper()], W - 159, 48, 16, INK)
	draw_route_map(Vector2(W - 240, 110), Vector2(40, 22), Color(INK, 0.35), Color(INK, 0.6), RED, 2.0, 4.0)
	# velocímetro de mostrador
	var c := Vector2(120, H - 112)
	draw_circle(c, 88, INK)
	draw_circle(c, 83, PAPER)
	var a0 := PI * 0.75
	var span := PI * 1.5
	for i in 16:
		var a := a0 + span * i / 15.0
		var major := i % 3 == 0
		draw_line(c + Vector2.from_angle(a) * (66 if major else 72), c + Vector2.from_angle(a) * 79, INK, 3.0 if major else 1.5)
	var pct := g.speed / OutRunGame.MAX_SPEED
	draw_arc(c, 58, a0, a0 + span * pct, 32, Color(RED, 0.35), 8.0)
	var na := a0 + span * pct
	draw_line(c, c + Vector2.from_angle(na) * 70, RED, 4.0)
	draw_circle(c, 8, INK)
	deco_text("%d" % g.kmh(), c.x, c.y + 42, 24, INK)
	deco_text("km/h", c.x, c.y + 60, 13, INK)
	if g.manual_gears:
		plaque(Rect2(222, H - 70, 130, 44))
		deco_text(I18n.t("ALTA") if g.high_gear else I18n.t("BAIXA"), 287, H - 40, 20, INK)
	for p in popups:
		var a := clampf(float(p.life), 0.0, 1.0)
		var rr := Rect2(W / 2 - 170, 140, 340, 46)
		draw_rect(rr, Color(RED, a))
		draw_rect(rr, Color(INK, a), false, 3.0)
		deco_text(I18n.t("TEMPO EXTRA ") + str(p.text) + " s", W / 2, 172, 24, Color(PAPER, a))


func ui_palette() -> Dictionary:
	return {
		"panel": Color(PAPER, 0.97),
		"border": INK,
		"text": INK,
		"accent": RED,
		"button": Color("e6d8b8"),
		"button_hover": Color("d8c49a"),
		"radius": 2,
		"dim": Color(INK, 0.25),
	}
