extends RelicsSkin
## Neon: a torre como uma maqueta de luz — chão em grelha, paredes de vidro, cubos em arame
## brilhante, caixotes cor de laranja e um altar dourado; tudo com halo.

const BG := Color("05030f")
const CYAN := Color("19f5ff")
const MAGENTA := Color("ff3df2")
const ORANGE := Color("ff9e2c")
const GOLD := Color("ffd84d")
const RED := Color("ff3b5c")
const WHITE := Color("ffffff")

var glow := {}


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var pal := {"H": GOLD, "S": Color("ffd0b0"), "E": BG, "B": CYAN, "b": Color("0fb5c0"), "L": Color("6a5cff"), "K": MAGENTA, "P": Color("0b6a74"), "h": Color("c9a020")}
	for f: String in MAN:
		_tex("man_" + f, MAN[f], pal)
	_tex("guard", GUARD, {"A": RED, "a": Color("b0203a"), "V": GOLD})
	_tex("ghost", GHOST, {"G": Color("c8b8ff"), "E": BG, "O": BG})
	_tex("relic", RELIC, {"Y": GOLD, "y": WHITE})
	_tex("heart", HEART, {"R": MAGENTA, "W": WHITE})


func _tex(key: String, rows: Array, pal: Dictionary) -> void:
	tex[key] = PixelArt.texture(rows, pal, 1)
	glow[key] = PixelArt.glow(rows, pal, 4, 3)


func _build_sfx() -> void:
	sfx.step = Synth.tone(140.0, 0.04, {"wave": "sine", "volume": 0.2, "decay": 40.0})
	sfx.jump = Synth.tone(330.0, 0.2, {"wave": "saw", "freq_end": 880.0, "volume": 0.07, "lowpass": 0.35})
	sfx.land = Synth.tone(90.0, 0.06, {"wave": "sine", "volume": 0.25, "decay": 30.0})
	sfx.pick = Synth.tone(660.0, 0.12, {"wave": "sine", "freq_end": 990.0, "volume": 0.16})
	sfx.drop = Synth.tone(990.0, 0.12, {"wave": "sine", "freq_end": 440.0, "volume": 0.16})
	sfx.door = Synth.tone(220.0, 0.25, {"wave": "saw", "freq_end": 660.0, "volume": 0.06, "lowpass": 0.3})
	var r := []
	for f in [1046.0, 1318.0, 1568.0, 2093.0]:
		r.append(Synth.render(f, 0.08, {"wave": "sine", "volume": 0.16}))
	sfx.relic = Synth.concat(r)
	sfx.heart = Synth.concat([Synth.render(784.0, 0.1, {"wave": "sine", "volume": 0.16}), Synth.render(1175.0, 0.2, {"wave": "sine", "volume": 0.16})])
	var d := []
	for f in [523.0, 659.0, 784.0, 1046.0, 1318.0, 1568.0]:
		d.append(Synth.render(f, 0.1, {"wave": "saw", "volume": 0.08, "lowpass": 0.3}))
	sfx.deposit = Synth.concat(d)
	sfx.die = Synth.to_stream(Synth.mix([
		Synth.render(880.0, 1.0, {"wave": "saw", "freq_end": 60.0, "volume": 0.09, "lowpass": 0.3}),
		Synth.render(0.0, 1.0, {"wave": "noise", "volume": 0.15, "lowpass": 0.15, "decay": 3.0}),
	]))
	sfx.day = Synth.tone(523.0, 0.4, {"wave": "sine", "volume": 0.12, "decay": 5.0})
	var w := []
	for f in [523.0, 659.0, 784.0, 1046.0, 1318.0, 1568.0, 2093.0]:
		w.append(Synth.render(f, 0.16, {"wave": "saw", "volume": 0.09, "lowpass": 0.3}))
	sfx.win = Synth.concat(w)


func relic_color() -> Color:
	return GOLD


func _draw_back() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), BG)


func glow_line(a: Vector2, b: Vector2, c: Color, w := 2.0) -> void:
	draw_line(a, b, Color(c, 0.18), w * 4.0)
	draw_line(a, b, c, w)


func glow_poly(q: PackedVector2Array, c: Color, w := 2.0) -> void:
	var o := q.duplicate()
	o.append(o[0])
	draw_polyline(o, Color(c, 0.18), w * 4.0)
	draw_polyline(o, c, w)


func _draw_floor() -> void:
	var n := float(RelicsGame.ROOM)
	var q := PackedVector2Array([iso(Vector3(0, 0, 0)), iso(Vector3(n, 0, 0)), iso(Vector3(n, n, 0)), iso(Vector3(0, n, 0))])
	draw_colored_polygon(q, Color("0c0620"))
	for i in RelicsGame.ROOM + 1:
		draw_line(iso(Vector3(i, 0, 0)), iso(Vector3(i, n, 0)), Color(MAGENTA, 0.25), 1.0)
		draw_line(iso(Vector3(0, i, 0)), iso(Vector3(n, i, 0)), Color(MAGENTA, 0.25), 1.0)
	glow_poly(q, MAGENTA, 2.0)


func _wall_quad(_side: String, q: PackedVector2Array, _z0: float, _z1: float) -> void:
	draw_colored_polygon(q, Color(CYAN, 0.07))
	glow_poly(q, CYAN, 1.5)


func _draw_door(_side: String, q: PackedVector2Array, _dz: int) -> void:
	draw_colored_polygon(q, Color(GOLD, 0.08))
	glow_poly(q, GOLD, 2.5)


func _draw_front_door(_side: String, a: Vector3, b: Vector3, _dz: float) -> void:
	for p: Vector3 in [a, b]:
		glow_line(iso(p), iso(p + Vector3(0, 0, 0.6)), GOLD, 2.0)
	glow_line(iso(a), iso(b), GOLD, 2.0)


func _draw_spikes(c: Vector2i) -> void:
	for k in 4:
		var base := iso(Vector3(c.x + 0.25 + (k % 2) * 0.5, c.y + 0.25 + (k / 2) * 0.5, 0))
		var tri := PackedVector2Array([base + Vector2(-7, 2), base + Vector2(7, 2), base + Vector2(0, -16)])
		draw_colored_polygon(tri, Color(RED, 0.35))
		glow_poly(tri, RED, 1.5)


func _draw_block(b: Dictionary, p: Vector3, s: Vector3, _top: bool) -> void:
	var c := CYAN
	match b.kind:
		"crate":
			c = ORANGE
		"altar":
			c = GOLD
	var f := box_faces(p, s)
	draw_colored_polygon(f[1], Color(BG.lerp(c, 0.12), 0.95))
	draw_colored_polygon(f[2], Color(BG.lerp(c, 0.18), 0.95))
	draw_colored_polygon(f[0], Color(BG.lerp(c, 0.25), 0.95))
	for q: PackedVector2Array in f:
		glow_poly(q, c, 2.0)
	if b.kind == "crate":
		for face: PackedVector2Array in [f[1], f[2]]:
			draw_line(face[0], face[2], Color(c, 0.7), 1.5)
	if b.kind == "altar":
		var top := iso(p + Vector3(0.5, 0.5, 1.0))
		for k in 3:
			var h := 22.0 + sin(time * 8.0 + k * 2.0) * 6.0
			draw_circle(top + Vector2(-10 + k * 10, -h * 0.5), 9, Color(GOLD, 0.2))
			draw_colored_polygon(PackedVector2Array([top + Vector2(-15 + k * 10, 0), top + Vector2(-5 + k * 10, 0), top + Vector2(-10 + k * 10, -h)]), [ORANGE, GOLD, ORANGE][k])
		for i in game.deposited:
			draw_texture_rect(tex.relic, Rect2(top + Vector2(-48 + i * 12, 8), Vector2(12, 12)), false)


func _glow_sprite(key: String, feet: Vector3, scale: float, flip := false, mod := Color.WHITE) -> void:
	var g: Texture2D = glow[key]
	var gs := g.get_size() * scale
	draw_texture_rect(g, Rect2(iso(feet) - Vector2(gs.x / 2, gs.y - 6 - 4 * scale), gs), false, Color(mod, mod.a * 0.8))
	draw_sprite_at(tex[key], feet, scale, flip, mod)


func _draw_item(it: Dictionary) -> void:
	var p: Vector3 = it.pos + Vector3(0, 0, 0.15 + sin(float(it.phase) * 3.0) * 0.08)
	_glow_sprite("relic" if it.kind == "relic" else "heart", p, 3.0)


func _draw_enemy(e: Dictionary) -> void:
	var p: Vector3 = e.pos
	match e.kind:
		"guard":
			_glow_sprite("guard", p, 3.0, (e.dir as Vector3).x - (e.dir as Vector3).y < 0.0)
		"ball":
			var c := iso(Vector3(p.x, p.y, game.enemy_z(e) + 0.35))
			draw_circle(c, 24, Color(MAGENTA, 0.15))
			draw_circle(c, 16, Color("2a0a33"))
			draw_arc(c, 16, 0, TAU, 24, MAGENTA, 2.5)
			draw_arc(c, 10, PI * 1.1, PI * 1.6, 8, WHITE, 2.0)
		"ghost":
			_glow_sprite("ghost", p, 3.0, false, Color(1, 1, 1, 0.7))


func _draw_player() -> void:
	var fr := man_frame()
	draw_shadow(game.pos, 14.0, Color(CYAN, 0.25))
	_glow_sprite("man_" + fr[0], game.pos, 3.5, fr[1])
	if game.carrying != null:
		var top := game.pos + Vector3(-0.45, -0.45, RelicsGame.PLAYER_H + 0.05)
		for q: PackedVector2Array in box_faces(top, Vector3(0.9, 0.9, 0.9)):
			draw_colored_polygon(q, Color("1a0f05"))
			glow_poly(q, ORANGE, 2.0)


func neon_text(text: String, x: float, y: float, cell: float, c: Color) -> void:
	PixelFont.draw(self, text, x + 2, y + 2, cell, Color(c, 0.25))
	PixelFont.draw(self, text, x, y, cell, c)


func _draw_hud() -> void:
	var g := game
	_draw_hud_common(CYAN, GOLD, Color(CYAN, 0.15), func(t: String, p: Vector2) -> void: neon_text(t, p.x, p.y - 20, 3, CYAN))
	neon_text(I18n.t("PONTOS"), 120, 600, 2, MAGENTA)
	neon_text("%06d" % g.score, 120, 622, 3, WHITE)
	neon_text(I18n.t("VIDAS %d") % g.lives, 120, 670, 2, MAGENTA)
	var c := Vector2(120, 500)
	var a := g.day_phase() * TAU
	draw_arc(c, 34, 0, TAU, 40, Color(CYAN, 0.3), 2.0)
	var sun := c + Vector2.from_angle(a - PI / 2) * 34
	draw_circle(sun, 10, GOLD if g.day_phase() < 0.5 else Color("c8b8ff"))
	neon_text(I18n.t("DIA %d/%d") % [g.day(), RelicsGame.DAYS], 120, 552, 2, CYAN)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.02, 0.01, 0.06, 0.92),
		"border": CYAN,
		"text": Color("e8fbff"),
		"accent": GOLD,
		"button": Color(0.05, 0.03, 0.12),
		"button_hover": Color(0.12, 0.06, 0.25),
		"radius": 6,
		"dim": Color(0, 0, 0, 0.35),
	}
