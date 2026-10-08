extends RelicsSkin
## Pastel Geométrico: a torre como uma ilustração geométrica suave — céu em degradê, chão em
## xadrez de tons pastel, cubos com três tons de luz, sombras macias e personagens contornados.
## O céu acompanha o dia: amanhecer, meio-dia, entardecer e noite.

const INK := Color("4a3f5c")
const SKY := [Color("ffd9c2"), Color("cfe6f5"), Color("ffc9b9"), Color("3c3a66")]
const SKY2 := [Color("f7c6d9"), Color("e8f2fb"), Color("d9b2e0"), Color("23224a")]
const FLOOR_A := Color("e9e1f2")
const FLOOR_B := Color("dcd2ea")
const WALL_L := Color("c9b8e3")
const WALL_R := Color("b4a2d6")
const STONE := [Color("d6cdf0"), Color("aa9ed1"), Color("8c80b8")]
const CRATE := [Color("ffd8a8"), Color("f0a96b"), Color("d98b52")]
const ALTAR := [Color("fffaf0"), Color("e6dccb"), Color("cdbfa8")]
const GOLD := Color("f2b630")
const CORAL := Color("f07f7f")

var font: Font


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	font = ThemeDB.fallback_font
	var pal := {"H": Color("6fa8dc"), "S": Color("ffd9c2"), "E": INK, "B": Color("f2a7c3"), "b": Color("d97fa3"), "L": Color("7b6fb0"), "K": INK, "P": Color("e3d27a"), "h": Color("5a8fc0")}
	for f: String in MAN:
		tex["man_" + f] = PixelArt.outlined(MAN[f], pal, INK, 1)
	tex.guard = PixelArt.outlined(GUARD, {"A": Color("9ec9b4"), "a": Color("6fa58e"), "V": INK}, INK, 1)
	tex.ghost = PixelArt.outlined(GHOST, {"G": Color("fdfcff"), "E": INK, "O": INK}, Color(INK, 0.5), 1)
	tex.relic = PixelArt.outlined(RELIC, {"Y": GOLD, "y": Color("fff3c4")}, INK, 1)
	tex.heart = PixelArt.outlined(HEART, {"R": CORAL, "W": Color.WHITE}, INK, 1)


func _build_sfx() -> void:
	sfx.step = Synth.tone(0.0, 0.03, {"wave": "noise", "volume": 0.06, "lowpass": 0.2, "decay": 60.0})
	sfx.jump = Synth.tone(523.0, 0.2, {"wave": "triangle", "freq_end": 784.0, "volume": 0.16})
	sfx.land = Synth.tone(200.0, 0.06, {"wave": "triangle", "volume": 0.14, "decay": 30.0})
	sfx.pick = Synth.tone(659.0, 0.15, {"wave": "triangle", "volume": 0.16, "decay": 10.0})
	sfx.drop = Synth.tone(392.0, 0.15, {"wave": "triangle", "volume": 0.16, "decay": 10.0})
	sfx.door = Synth.concat([Synth.render(587.0, 0.1, {"wave": "sine", "volume": 0.12, "decay": 8.0}), Synth.render(880.0, 0.2, {"wave": "sine", "volume": 0.12, "decay": 8.0})])
	var r := []
	for f in [784.0, 988.0, 1175.0, 1568.0]:
		r.append(Synth.render(f, 0.12, {"wave": "sine", "volume": 0.16, "decay": 6.0}))
	sfx.relic = Synth.concat(r)
	sfx.heart = Synth.concat([Synth.render(880.0, 0.12, {"wave": "sine", "volume": 0.16, "decay": 6.0}), Synth.render(1320.0, 0.25, {"wave": "sine", "volume": 0.16, "decay": 5.0})])
	var d := []
	for f in [523.0, 659.0, 784.0, 1046.0, 1318.0]:
		d.append(Synth.render(f, 0.16, {"wave": "sine", "volume": 0.18, "decay": 4.0}))
	sfx.deposit = Synth.concat(d)
	var dd := []
	for f in [659.0, 587.0, 523.0, 392.0]:
		dd.append(Synth.render(f, 0.2, {"wave": "triangle", "volume": 0.16, "decay": 4.0}))
	sfx.die = Synth.concat(dd)
	sfx.day = Synth.tone(1046.0, 0.6, {"wave": "sine", "volume": 0.1, "decay": 4.0})
	var w := []
	for f in [523.0, 659.0, 784.0, 1046.0, 784.0, 1046.0, 1318.0, 1568.0]:
		w.append(Synth.render(f, 0.18, {"wave": "sine", "volume": 0.18, "decay": 3.0}))
	sfx.win = Synth.concat(w)


func relic_color() -> Color:
	return GOLD


func _sky(arr: Array) -> Color:
	var ph := game.day_phase() * 4.0
	var i := int(ph) % 4
	return (arr[i] as Color).lerp(arr[(i + 1) % 4], ph - floorf(ph))


func _draw_back() -> void:
	var top := _sky(SKY)
	var bot := _sky(SKY2)
	for i in 16:
		draw_rect(Rect2(0, 45.0 * i, 1280, 46), top.lerp(bot, i / 15.0))
	# a torre "flutua": base em forma de ilha
	var n := float(RelicsGame.ROOM)
	draw_colored_polygon(PackedVector2Array([iso(Vector3(0, n, 0)), iso(Vector3(n, n, 0)), iso(Vector3(n, n, -1.6)), iso(Vector3(0, n, -0.8))]), Color("b4a2d6"))
	draw_colored_polygon(PackedVector2Array([iso(Vector3(n, n, 0)), iso(Vector3(n, 0, 0)), iso(Vector3(n, 0, -0.8)), iso(Vector3(n, n, -1.6))]), Color("9a88c2"))


func _draw_floor() -> void:
	for y in RelicsGame.ROOM:
		for x in RelicsGame.ROOM:
			var q := PackedVector2Array([iso(Vector3(x, y, 0)), iso(Vector3(x + 1, y, 0)), iso(Vector3(x + 1, y + 1, 0)), iso(Vector3(x, y + 1, 0))])
			draw_colored_polygon(q, FLOOR_A if (x + y) % 2 == 0 else FLOOR_B)
	# sombras macias dos blocos no chão
	for b in game.blocks:
		var p: Vector3 = b.pos
		var s: Vector3 = b.size
		if p.z > 0.01:
			continue
		var q := PackedVector2Array([iso(Vector3(p.x + s.x, p.y, 0)), iso(Vector3(p.x + s.x + 0.35, p.y + 0.2, 0)), iso(Vector3(p.x + s.x + 0.35, p.y + s.y + 0.2, 0)), iso(Vector3(p.x + s.x, p.y + s.y, 0))])
		draw_colored_polygon(q, Color(INK, 0.12))


func _wall_quad(side: String, q: PackedVector2Array, _z0: float, _z1: float) -> void:
	draw_colored_polygon(q, WALL_L if side == "W" else WALL_R)
	# faixa decorativa
	var t0 := 0.78
	var t1 := 0.86
	draw_colored_polygon(PackedVector2Array([q[0].lerp(q[3], t0), q[1].lerp(q[2], t0), q[1].lerp(q[2], t1), q[0].lerp(q[3], t1)]), Color(Color.WHITE, 0.3))


func _draw_door(side: String, q: PackedVector2Array, _dz: int) -> void:
	var c := (WALL_L if side == "W" else WALL_R).darkened(0.45)
	var mid := (q[2] + q[3]) / 2
	var arch := PackedVector2Array([q[0], q[1], q[2].lerp(q[1], 0.25), mid + (q[3] - q[0]) * 0.08, q[3].lerp(q[0], 0.25)])
	draw_colored_polygon(arch, c)


func _draw_front_door(_side: String, a: Vector3, b: Vector3, _dz: float) -> void:
	draw_line(iso(a), iso(b), Color(GOLD, 0.8), 6.0)


func _draw_spikes(c: Vector2i) -> void:
	for k in 4:
		var base := iso(Vector3(c.x + 0.25 + (k % 2) * 0.5, c.y + 0.25 + (k / 2) * 0.5, 0))
		draw_colored_polygon(PackedVector2Array([base + Vector2(-8, 2), base + Vector2(0, 5), base + Vector2(0, -18)]), CORAL.darkened(0.15))
		draw_colored_polygon(PackedVector2Array([base + Vector2(0, 5), base + Vector2(8, 2), base + Vector2(0, -18)]), CORAL)


func _draw_block(b: Dictionary, p: Vector3, s: Vector3, _top: bool) -> void:
	var cols: Array = STONE
	match b.kind:
		"crate":
			cols = CRATE
		"altar":
			cols = ALTAR
	draw_box(p, s, cols[0], cols[1], cols[2])
	var f := box_faces(p, s)
	if b.kind == "crate":
		for face: PackedVector2Array in [f[1], f[2]]:
			var inner := PackedVector2Array()
			var c := (face[0] + face[2]) / 2
			for v in face:
				inner.append(c + (v - c) * 0.7)
			inner.append(inner[0])
			draw_polyline(inner, Color(INK, 0.25), 2.0)
	if b.kind == "stone":
		draw_line(f[0][1], f[0][2], Color.WHITE, 1.5)
		draw_line(f[0][2], f[0][3], Color(Color.WHITE, 0.6), 1.5)
	if b.kind == "altar":
		var top := iso(p + Vector3(0.5, 0.5, 1.0))
		draw_circle(top + Vector2(0, -26), 16 + sin(time * 4.0) * 2, Color(GOLD, 0.35))
		draw_circle(top + Vector2(0, -26), 9, GOLD)
		for i in game.deposited:
			draw_texture_rect(tex.relic, Rect2(top + Vector2(-48 + i * 12, 6), Vector2(12, 14)), false)


func _draw_item(it: Dictionary) -> void:
	var p: Vector3 = it.pos + Vector3(0, 0, 0.15 + sin(float(it.phase) * 3.0) * 0.08)
	draw_shadow(it.pos, 10.0, Color(INK, 0.15))
	draw_sprite_at(tex.relic if it.kind == "relic" else tex.heart, p, 3.0)


func _draw_enemy(e: Dictionary) -> void:
	var p: Vector3 = e.pos
	match e.kind:
		"guard":
			draw_shadow(p, 14.0, Color(INK, 0.18))
			draw_sprite_at(tex.guard, p, 3.0, (e.dir as Vector3).x - (e.dir as Vector3).y < 0.0)
		"ball":
			draw_shadow(Vector3(p.x, p.y, 0), 14.0, Color(INK, 0.18))
			var c := iso(Vector3(p.x, p.y, game.enemy_z(e) + 0.35))
			draw_circle(c, 17, Color("8fb7e8"))
			draw_circle(c + Vector2(4, 4), 12, Color("6f97c8"))
			draw_circle(c + Vector2(-5, -6), 5, Color("e8f2fb"))
		"ghost":
			draw_sprite_at(tex.ghost, p, 3.0, false, Color(1, 1, 1, 0.75))


func _draw_player() -> void:
	var fr := man_frame()
	draw_shadow(game.pos, 14.0, Color(INK, 0.2))
	draw_sprite_at(tex["man_" + fr[0]], game.pos, 3.5, fr[1])
	if game.carrying != null:
		var top := game.pos + Vector3(-0.45, -0.45, RelicsGame.PLAYER_H + 0.05)
		draw_box(top, Vector3(0.9, 0.9, 0.9), CRATE[0], CRATE[1], CRATE[2])


func label(text: String, pos: Vector2, size: int, color: Color) -> void:
	draw_string(font, pos - Vector2(300, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 600, size, color)


func pill(r: Rect2, c: Color) -> void:
	draw_rect(Rect2(r.position + Vector2(r.size.y / 2, 0), Vector2(r.size.x - r.size.y, r.size.y)), c)
	draw_circle(r.position + Vector2(r.size.y / 2, r.size.y / 2), r.size.y / 2, c)
	draw_circle(r.position + Vector2(r.size.x - r.size.y / 2, r.size.y / 2), r.size.y / 2, c)


func _draw_hud() -> void:
	var g := game
	var night := g.day_phase() > 0.7 or g.day_phase() < 0.05
	var ink := Color.WHITE if night else INK
	pill(Rect2(460, 652, 360, 60), Color(Color.WHITE, 0.45))
	_draw_hud_common(ink, GOLD, Color(INK, 0.18), func(t: String, p: Vector2) -> void: label(t, p + Vector2(0, -4), 26, ink))
	pill(Rect2(20, 590, 200, 110), Color(Color.WHITE, 0.45))
	label(I18n.t("PONTOS %06d") % g.score, Vector2(120, 626), 20, INK)
	label(I18n.t("vidas %d") % g.lives, Vector2(120, 656), 18, INK)
	label(I18n.t("dia %d de %d") % [g.day(), RelicsGame.DAYS], Vector2(120, 686), 18, INK)
	var c := Vector2(120, 520)
	var a := g.day_phase() * TAU - PI / 2
	draw_arc(c, 40, PI, TAU, 24, Color(ink, 0.4), 2.0)
	draw_circle(c + Vector2.from_angle(a) * 40, 11, GOLD if g.day_phase() < 0.5 else Color("e8f2fb"))


func ui_palette() -> Dictionary:
	return {
		"panel": Color(Color("fbf7ff"), 0.96),
		"border": Color("b4a2d6"),
		"text": INK,
		"accent": Color("d97fa3"),
		"button": Color("eee6f7"),
		"button_hover": Color("e0d2f2"),
		"radius": 18,
		"dim": Color(INK, 0.2),
	}
