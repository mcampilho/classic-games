extends PalaceSkin
## Iluminura Persa: o palácio pintado como uma miniatura persa — fundo lápis-lazúli com estrelas
## de oito pontas a ouro, paredes de azulejo turquesa com rosáceas, lajes de mármore debruadas
## a ouro, figuras de traje colorido com contorno escuro e uma moldura dourada à volta de tudo.

const LAPIS := Color("1f3a7a")
const LAPIS2 := Color("2a4a96")
const GOLD := Color("e0b04a")
const TURQ := Color("2aa8a0")
const TURQ2 := Color("1f7f7a")
const MARBLE := Color("f2ead8")
const MARBLE2 := Color("d8ccb0")
const INK := Color("2a1a14")
const RED := Color("b8322e")
const ROBES := [Color("2f8a4a"), Color("8a2a5a"), Color("c8642a")]

var star: Texture2D


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# azulejo de fundo: estrela de oito pontas a ouro sobre lápis-lazúli
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(LAPIS)
	for y in 64:
		for x in 64:
			var d := Vector2(x - 31.5, y - 31.5)
			var a := absf(d.x) + absf(d.y)
			var b := maxf(absf(d.x), absf(d.y))
			if minf(a / 1.414, b) < 12.0:
				img.set_pixel(x, y, GOLD if minf(a / 1.414, b) > 10.0 else LAPIS2)
			if (x + y) % 32 == 0 and minf(a / 1.414, b) > 14.0:
				img.set_pixel(x, y, Color(GOLD, 0.35))
	star = ImageTexture.create_from_image(img)


func _build_sfx() -> void:
	# alaúde (triângulo dedilhado) e tambor de mão
	sfx.step = Synth.tone(120.0, 0.05, {"wave": "sine", "volume": 0.12, "decay": 40.0})
	sfx.jump = Synth.tone(0.0, 0.08, {"wave": "noise", "volume": 0.06, "lowpass": 0.3, "decay": 30.0})
	sfx.land = Synth.tone(90.0, 0.15, {"wave": "sine", "volume": 0.3, "decay": 20.0})
	sfx.land_hard = Synth.tone(70.0, 0.3, {"wave": "sine", "volume": 0.4, "decay": 10.0})
	sfx.grab = Synth.tone(587.0, 0.12, {"wave": "triangle", "volume": 0.12, "decay": 15.0})
	sfx.bump = Synth.tone(80.0, 0.2, {"wave": "sine", "volume": 0.35, "decay": 15.0})
	var g := []
	for f in [294.0, 311.0, 370.0, 392.0]:
		g.append(Synth.render(f, 0.12, {"wave": "triangle", "volume": 0.2, "decay": 6.0}))
	sfx.gate = Synth.concat(g)
	var e := []
	for f in [294.0, 311.0, 370.0, 392.0, 440.0, 466.0, 554.0, 587.0]:
		e.append(Synth.render(f, 0.12, {"wave": "triangle", "volume": 0.2, "decay": 6.0}))
	sfx.exit_open = Synth.concat(e)
	sfx.spikes = Synth.tone(1400.0, 0.08, {"wave": "triangle", "volume": 0.1, "decay": 30.0})
	sfx.crumble = Synth.tone(0.0, 0.5, {"wave": "noise", "volume": 0.2, "lowpass": 0.15, "decay": 6.0})
	sfx.clash = Synth.to_stream(Synth.mix([
		Synth.render(2200.0, 0.3, {"wave": "triangle", "volume": 0.12, "decay": 14.0}),
		Synth.render(3300.0, 0.3, {"wave": "sine", "volume": 0.08, "decay": 16.0}),
	]))
	sfx.hit_guard = Synth.tone(150.0, 0.2, {"wave": "sine", "volume": 0.3, "decay": 12.0})
	sfx.hit_hero = Synth.tone(110.0, 0.25, {"wave": "sine", "volume": 0.35, "decay": 10.0})
	sfx.guard_die = Synth.concat([Synth.render(392.0, 0.2, {"wave": "triangle", "volume": 0.2, "decay": 5.0}), Synth.render(294.0, 0.5, {"wave": "triangle", "volume": 0.2, "decay": 3.0})])
	var d := []
	for f in [587.0, 554.0, 466.0, 440.0, 392.0, 311.0, 294.0]:
		d.append(Synth.render(f, 0.2, {"wave": "triangle", "volume": 0.2, "decay": 4.0}))
	sfx.die = Synth.concat(d)
	sfx.potion = Synth.concat([Synth.render(587.0, 0.1, {"wave": "triangle", "volume": 0.2, "decay": 8.0}), Synth.render(880.0, 0.25, {"wave": "triangle", "volume": 0.2, "decay": 6.0})])
	sfx.life = sfx.potion
	sfx.sword = sfx.exit_open
	sfx.level = sfx.exit_open
	sfx.win = sfx.exit_open


func _draw_back() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), RED)
	draw_texture_rect(star, Rect2(0, OFF_Y, 1280, ROOM_H), true)


func _paint_room(ci: CanvasItem, room: Vector2i) -> void:
	ci.draw_texture_rect(star, Rect2(0, 0, ROOM_W, ROOM_H), true)
	each_tile(room, func(gc: int, gr: int, ch: String, r: Rect2) -> void: _paint_tile(ci, gc, gr, ch, r))


func _paint_tile(ci: CanvasItem, gc: int, _gr: int, ch: String, r: Rect2) -> void:
	if ch == "#":
		ci.draw_rect(r, TURQ2)
		for yy in 3:
			for xx in 2:
				var c := r.position + Vector2(32 + xx * 64, 35 + yy * 70)
				ci.draw_circle(c, 26, TURQ)
				ci.draw_arc(c, 26, 0, TAU, 24, MARBLE, 2.0)
				for k in 8:
					ci.draw_line(c, c + Vector2.from_angle(k * TAU / 8) * 22, Color(MARBLE, 0.7), 2.0)
				ci.draw_circle(c, 6, GOLD)
		ci.draw_rect(r, INK, false, 2.0)
		return
	if PalaceGame.FLOOR.contains(ch):
		# arco por cima de cada casa com chão
		if gc % 2 == 0:
			var top := r.position.y + 30
			ci.draw_arc(Vector2(r.end.x, top + 60), 58, PI, TAU, 20, Color(GOLD, 0.6), 4.0)
		var fy := r.end.y - 18.0
		var slab := Rect2(r.position.x, fy, r.size.x, 20)
		if ch == "~":
			slab = slab.grow_individual(-5, 0, -5, 0)
		ci.draw_rect(slab, MARBLE if ch != "~" else MARBLE2)
		ci.draw_rect(Rect2(slab.position.x, slab.position.y, slab.size.x, 4), GOLD)
		ci.draw_rect(Rect2(slab.position.x, slab.end.y - 3, slab.size.x, 3), INK)
		for k in 4:
			ci.draw_rect(Rect2(slab.position.x + 10 + k * 30, slab.position.y + 8, 10, 6), Color(RED, 0.7))
	if ch == "D":
		var d := Rect2(r.position.x + 14, r.position.y + 54, r.size.x - 28, r.size.y - 72)
		var pts := PackedVector2Array([d.position + Vector2(0, d.size.y), d.position + Vector2(0, 20), d.position + Vector2(d.size.x / 2, -24), d.position + Vector2(d.size.x, 20), d.end])
		ci.draw_colored_polygon(pts, INK)
		pts.append(pts[0])
		ci.draw_polyline(pts, GOLD, 5.0)


func _limb(a: Vector2, b: Vector2, c: Color, w: float) -> void:
	draw_line(a, b, INK, w + 4.0)
	draw_circle(a, w / 2 + 2, INK)
	draw_circle(b, w / 2 + 2, INK)
	draw_line(a, b, c, w)
	draw_circle(a, w / 2, c)
	draw_circle(b, w / 2, c)


func _draw_figure(j: Dictionary, is_guard: bool, sword: bool, info: Dictionary) -> void:
	var a: float = info.get("alpha", 1.0)
	var robe := Color("e8823a") if not is_guard else (ROBES[(game.level + int(info.get("max_hp", 3))) % ROBES.size()] as Color)
	robe = Color(robe, a)
	var robe2 := Color(robe.darkened(0.3), a)
	var skin := Color(Color("d89a6a"), a)
	var trousers := Color(Color("f2ead8") if not is_guard else Color("3a2a5a"), a)
	_limb(j.hip, j.knee_b, trousers.darkened(0.15), 13.0)
	_limb(j.knee_b, j.foot_b, trousers.darkened(0.15), 11.0)
	_limb(j.sh_b, j.elbow_b, robe2, 10.0)
	_limb(j.elbow_b, j.hand_b, skin.darkened(0.15), 8.0)
	# túnica: tronco largo com aba
	_limb(j.hip, j.neck, robe, 22.0)
	draw_colored_polygon(PackedVector2Array([j.hip + Vector2(-16, -6), j.hip + Vector2(16, -6), j.hip + Vector2(20, 26), j.hip + Vector2(-20, 26)]), robe)
	draw_line(j.hip + Vector2(-14, -8), j.hip + Vector2(14, -8), Color(GOLD, a), 4.0)
	draw_circle(j.head, 15.0, INK)
	draw_circle(j.head, 13.0, skin)
	# turbante
	var turban := Color(Color.WHITE if not is_guard else RED, a)
	draw_circle(j.head + Vector2(0, -10), 15.0, INK)
	draw_circle(j.head + Vector2(0, -10), 13.0, turban)
	draw_circle(j.head + Vector2(0, -16), 4.0, Color(GOLD, a))
	if is_guard:
		draw_circle(j.head + Vector2(0, 8), 8.0, Color(INK, a))
	_limb(j.hip, j.knee_f, trousers, 13.0)
	_limb(j.knee_f, j.foot_f, trousers, 11.0)
	if sword:
		# cimitarra curva
		var dirv: Vector2 = j.sword_dir
		var pts := PackedVector2Array()
		for k in 8:
			var t := k / 7.0
			pts.append(j.hand_f + dirv * 72.0 * t + dirv.orthogonal() * sin(t * PI * 0.9) * 10.0 * (1.0 if j.hand_f.x > j.hip.x else -1.0))
		draw_polyline(pts, Color(INK, a), 6.0)
		draw_polyline(pts, Color(Color("e8eef4"), a), 3.0)
		draw_line(j.hand_f - dirv.orthogonal() * 9.0, j.hand_f + dirv.orthogonal() * 9.0, Color(GOLD, a), 5.0)
	_limb(j.sh_f, j.elbow_f, robe, 10.0)
	_limb(j.elbow_f, j.hand_f, skin, 8.0)


func _draw_gate(r: Rect2, floor_y: float, open: float) -> void:
	var bottom := lerpf(floor_y, r.position.y + 20.0, open)
	var g := Rect2(r.position.x + 40, r.position.y + 20, 48, bottom - r.position.y - 20)
	if g.size.y > 4:
		for y in range(int(g.position.y), int(g.end.y), 16):
			for x in range(int(g.position.x), int(g.end.x), 16):
				draw_circle(Vector2(x + 8, y + 8), 6, Color(GOLD, 0.9))
				draw_circle(Vector2(x + 8, y + 8), 3, INK)
		draw_rect(g, INK, false, 2.0)


func _draw_spikes(r: Rect2, floor_y: float, out: float) -> void:
	for k in 5:
		var x := r.position.x + 16 + k * 24
		var h := 4.0 + 34.0 * out
		var tri := PackedVector2Array([Vector2(x - 6, floor_y), Vector2(x + 6, floor_y), Vector2(x, floor_y - h)])
		draw_colored_polygon(tri, Color("dfe4ec"))
		tri.append(tri[0])
		draw_polyline(tri, INK, 1.5)


func _draw_door(r: Rect2, floor_y: float, open: float) -> void:
	var d := Rect2(r.position.x + 14, r.position.y + 74, r.size.x - 28, floor_y - r.position.y - 74)
	var h := d.size.y * (1.0 - open)
	draw_rect(Rect2(d.position, Vector2(d.size.x, h)), Color("7a4a2a"))
	for k in 3:
		draw_line(Vector2(d.position.x + 12 + k * 26, d.position.y), Vector2(d.position.x + 12 + k * 26, d.position.y + h), GOLD, 2.0)
	if open > 0.9:
		draw_rect(d.grow(-8), Color(1.0, 0.95, 0.7, 0.25 + 0.1 * sin(time * 3.0)))


func _draw_potion(p: Vector2, big: bool) -> void:
	var s := 1.4 if big else 1.0
	draw_circle(p + Vector2(0, -12 * s), 11 * s, INK)
	draw_circle(p + Vector2(0, -12 * s), 9 * s, RED if not big else Color("2f8a4a"))
	draw_rect(Rect2(p + Vector2(-3, -30) * s, Vector2(6, 10) * s), GOLD)


func _draw_sword_item(p: Vector2) -> void:
	var pts := PackedVector2Array()
	for k in 8:
		var t := k / 7.0
		pts.append(p + Vector2(-30 + 62 * t, -6 - sin(t * PI) * 8.0))
	draw_polyline(pts, INK, 6.0)
	draw_polyline(pts, Color("e8eef4"), 3.0)
	draw_line(p + Vector2(-30, -16), p + Vector2(-30, 2), GOLD, 5.0)


func _draw_loose_shake(r: Rect2, floor_y: float, t: float) -> void:
	var dx := sin(time * 60.0) * 3.0 * t
	draw_rect(Rect2(r.position.x + 5 + dx, floor_y, r.size.x - 10, 20), MARBLE2)


func _draw_plate(r: Rect2, on: bool) -> void:
	draw_rect(r.grow_individual(0, -3 if on else 0, 0, 0), GOLD if not on else GOLD.darkened(0.3))


func _draw_debris(p: Vector2) -> void:
	for k in 4:
		draw_rect(Rect2(p + Vector2(-40 + k * 22, -10), Vector2(18, 12)), MARBLE2)


func _draw_front() -> void:
	# moldura dourada da iluminura
	draw_rect(Rect2(4, OFF_Y - 4, 1272, ROOM_H + 8), GOLD, false, 6.0)
	draw_rect(Rect2(12, OFF_Y + 4, 1256, ROOM_H - 8), Color(INK, 0.8), false, 2.0)


func _draw_hud() -> void:
	var g := game
	draw_rect(Rect2(0, 652, 1280, 68), RED)
	draw_rect(Rect2(8, 658, 1264, 56), GOLD, false, 3.0)
	for i in g.max_hp:
		var c := Vector2(40 + i * 34, 686)
		draw_circle(c, 12, INK)
		draw_circle(c, 10, Color("ffd36e") if i < g.hp else Color("5a2a1a"))
	var foe: Variant = g._nearest_guard()
	if foe != null:
		for i in int(foe.max_hp):
			var c := Vector2(1150 - i * 34, 686)
			draw_circle(c, 12, INK)
			draw_circle(c, 10, Color("8ad0c8") if i < int(foe.hp) else Color("1f3a3a"))
	PixelFont.draw(self, I18n.t("%d MINUTOS") % g.minutes_left(), 640, 674, 3, MARBLE)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(LAPIS, 0.96),
		"border": GOLD,
		"text": MARBLE,
		"accent": GOLD,
		"button": Color("2a4a96"),
		"button_hover": Color("3a5ab0"),
		"radius": 6,
		"dim": Color(0, 0, 0, 0.3),
	}
