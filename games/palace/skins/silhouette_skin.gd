extends PalaceSkin
## Silhueta: teatro de sombras ao pôr do sol — o palácio e as personagens a negro recortados
## contra um céu em degradê, arcos ao longe, tochas que são só luz e um lenço que esvoaça atrás
## do herói. Cada linha de ecrãs tem a sua hora do dia.

const BLACK := Color("08070c")
const SKIES := [[Color("2a1240"), Color("e8743b"), Color("ffd28a")], [Color("0e1a3a"), Color("3a6a9a"), Color("bfe0f0")]]
const SCARF := Color("ff6a3a")

var scarf: Array[Vector2] = []


func _build_sfx() -> void:
	sfx.step = Synth.tone(0.0, 0.03, {"wave": "noise", "volume": 0.06, "lowpass": 0.15, "decay": 60.0})
	sfx.jump = Synth.tone(0.0, 0.12, {"wave": "noise", "volume": 0.06, "lowpass": 0.25, "decay": 20.0})
	sfx.land = Synth.tone(70.0, 0.12, {"wave": "sine", "volume": 0.25, "decay": 25.0})
	sfx.land_hard = Synth.tone(55.0, 0.3, {"wave": "sine", "volume": 0.35, "decay": 10.0})
	sfx.grab = Synth.tone(0.0, 0.05, {"wave": "noise", "volume": 0.08, "lowpass": 0.3, "decay": 40.0})
	sfx.bump = Synth.tone(60.0, 0.2, {"wave": "sine", "volume": 0.3, "decay": 15.0})
	sfx.gate = Synth.tone(110.0, 1.0, {"wave": "triangle", "volume": 0.12, "decay": 2.0})
	sfx.exit_open = Synth.to_stream(Synth.mix([
		Synth.render(220.0, 2.0, {"wave": "sine", "volume": 0.12, "decay": 1.0}),
		Synth.render(330.0, 2.0, {"wave": "sine", "volume": 0.08, "decay": 1.0}),
	]))
	sfx.spikes = Synth.tone(1800.0, 0.06, {"wave": "sine", "volume": 0.1, "decay": 40.0})
	sfx.crumble = Synth.tone(0.0, 0.6, {"wave": "noise", "volume": 0.2, "lowpass": 0.1, "decay": 5.0})
	sfx.clash = Synth.to_stream(Synth.mix([
		Synth.render(1760.0, 0.4, {"wave": "sine", "volume": 0.12, "decay": 10.0}),
		Synth.render(2640.0, 0.4, {"wave": "sine", "volume": 0.08, "decay": 12.0}),
	]))
	sfx.hit_guard = Synth.tone(110.0, 0.2, {"wave": "sine", "volume": 0.3, "decay": 15.0})
	sfx.hit_hero = Synth.tone(82.0, 0.3, {"wave": "sine", "volume": 0.35, "decay": 10.0})
	sfx.guard_die = Synth.tone(196.0, 1.0, {"wave": "triangle", "freq_end": 98.0, "volume": 0.15, "decay": 2.0})
	var d := []
	for f in [440.0, 415.0, 392.0, 349.0, 330.0]:
		d.append(Synth.render(f, 0.35, {"wave": "sine", "volume": 0.18, "decay": 3.0}))
	sfx.die = Synth.concat(d)
	sfx.potion = Synth.concat([Synth.render(880.0, 0.12, {"wave": "sine", "volume": 0.14, "decay": 8.0}), Synth.render(1320.0, 0.25, {"wave": "sine", "volume": 0.14, "decay": 6.0})])
	sfx.life = sfx.potion
	sfx.sword = Synth.concat([Synth.render(1320.0, 0.15, {"wave": "sine", "volume": 0.16, "decay": 6.0}), Synth.render(1760.0, 0.4, {"wave": "sine", "volume": 0.16, "decay": 4.0})])
	var l := []
	for f in [294.0, 440.0, 392.0, 587.0]:
		l.append(Synth.render(f, 0.3, {"wave": "sine", "volume": 0.18, "decay": 2.5}))
	sfx.level = Synth.concat(l)
	sfx.win = sfx.level


func _sky() -> Array:
	return SKIES[game.room.y % SKIES.size()]


func _draw_back() -> void:
	var s := _sky()
	for i in 24:
		var t := i / 23.0
		var c: Color = (s[0] as Color).lerp(s[1], minf(t * 1.4, 1.0)) if t < 0.7 else (s[1] as Color).lerp(s[2], (t - 0.7) / 0.3)
		draw_rect(Rect2(0, OFF_Y + t * ROOM_H - 1, 1280, ROOM_H / 23.0 + 2), c)
	draw_circle(Vector2(900 - game.room.x * 140, OFF_Y + 430), 120, Color(s[2], 0.55))
	draw_circle(Vector2(900 - game.room.x * 140, OFF_Y + 430), 80, Color(s[2], 0.8))
	# arcos ao longe
	for k in 6:
		var x := fposmod(k * 260.0 - game.room.x * 90.0, 1560.0) - 140.0
		var base := OFF_Y + ROOM_H - 40
		var col := Color(BLACK, 0.25)
		draw_rect(Rect2(x, base - 260, 30, 260), col)
		draw_rect(Rect2(x + 150, base - 260, 30, 260), col)
		draw_arc(Vector2(x + 90, base - 260), 75, PI, TAU, 16, col, 30.0)


func _paint_room(ci: CanvasItem, room: Vector2i) -> void:
	each_tile(room, func(gc: int, gr: int, ch: String, r: Rect2) -> void: _paint_tile(ci, gc, gr, ch, r))


func _paint_tile(ci: CanvasItem, _gc: int, _gr: int, ch: String, r: Rect2) -> void:
	if ch == "#":
		ci.draw_rect(r, BLACK)
		return
	if PalaceGame.FLOOR.contains(ch):
		var fy := r.end.y - 18.0
		var slab := Rect2(r.position.x, fy, r.size.x, 22)
		if ch == "~":
			slab = slab.grow_individual(-5, 0, -5, 0)
		ci.draw_rect(slab, BLACK)
		# franjas decorativas penduradas
		for k in 4:
			ci.draw_circle(Vector2(r.position.x + 16 + k * 32, fy + 24), 5, BLACK)
	if ch == "D":
		var d := Rect2(r.position.x + 14, r.position.y + 50, r.size.x - 28, r.size.y - 68)
		ci.draw_rect(Rect2(d.position.x - 12, d.position.y, 12, d.size.y), BLACK)
		ci.draw_rect(Rect2(d.end.x, d.position.y, 12, d.size.y), BLACK)
		ci.draw_arc(Vector2(d.get_center().x, d.position.y), d.size.x / 2 + 6, PI, TAU, 16, BLACK, 12.0)


func _tick(_d: float) -> void:
	# o lenço segue o pescoço com atraso
	var j := joints(game.pos, game.facing, hero_pose())
	var neck: Vector2 = j.neck
	if scarf.is_empty() or scarf[0].distance_to(neck) > 200.0:
		scarf.clear()
		for i in 8:
			scarf.append(neck)
	scarf[0] = neck
	for i in range(1, scarf.size()):
		var target := scarf[i - 1] + Vector2(-game.facing * 9.0, 2.0 + sin(time * 8.0 + i) * 2.0)
		scarf[i] = scarf[i].lerp(target, 0.35)


func _limb(a: Vector2, b: Vector2, c: Color, w: float) -> void:
	draw_line(a, b, c, w)
	draw_circle(a, w / 2, c)
	draw_circle(b, w / 2, c)


func _draw_figure(j: Dictionary, is_guard: bool, sword: bool, info: Dictionary) -> void:
	var a: float = info.get("alpha", 1.0)
	var c := Color(BLACK, a)
	var rim := Color(_sky()[2], 0.5 * a)
	if not is_guard and scarf.size() > 1:
		draw_polyline(PackedVector2Array(scarf), Color(SCARF, a), 6.0)
	for pass_i in 2:
		var w := 3.0 if pass_i == 0 else 0.0
		var col := rim if pass_i == 0 else c
		_limb(j.hip, j.knee_b, col, 13.0 + w)
		_limb(j.knee_b, j.foot_b, col, 11.0 + w)
		_limb(j.sh_b, j.elbow_b, col, 10.0 + w)
		_limb(j.elbow_b, j.hand_b, col, 8.0 + w)
		_limb(j.hip, j.neck, col, 20.0 + w)
		draw_circle(j.head, 13.0 + w / 2, col)
		if is_guard:
			draw_circle(j.head + Vector2(0, -10), 14.0 + w / 2, col)
			draw_colored_polygon(PackedVector2Array([j.head + Vector2(-4, -22), j.head + Vector2(4, -22), j.head + Vector2(0, -36)]), col)
		_limb(j.hip, j.knee_f, col, 13.0 + w)
		_limb(j.knee_f, j.foot_f, col, 11.0 + w)
		_limb(j.sh_f, j.elbow_f, col, 10.0 + w)
		_limb(j.elbow_f, j.hand_f, col, 8.0 + w)
	if is_guard:
		var eye: Vector2 = j.head + Vector2(5 * (1 if j.hand_f.x > j.hip.x else -1), -2)
		draw_circle(eye, 2.5, Color(1.0, 0.5, 0.2, a))
	if sword:
		var tip: Vector2 = j.hand_f + j.sword_dir * 74.0
		draw_line(j.hand_f, tip, Color(BLACK, a), 4.0)
		draw_line(j.hand_f + j.sword_dir * 30.0, tip, Color(1, 1, 1, 0.5 * a), 1.5)


func _draw_gate(r: Rect2, floor_y: float, open: float) -> void:
	var bottom := lerpf(floor_y, r.position.y + 20.0, open)
	for k in 5:
		var x := r.position.x + 48 + k * 8
		draw_line(Vector2(x, r.position.y), Vector2(x, bottom), BLACK, 4.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 3, bottom), Vector2(x + 3, bottom), Vector2(x, bottom + 8)]), BLACK)


func _draw_spikes(r: Rect2, floor_y: float, out: float) -> void:
	for k in 5:
		var x := r.position.x + 16 + k * 24
		var h := 4.0 + 34.0 * out
		draw_colored_polygon(PackedVector2Array([Vector2(x - 5, floor_y), Vector2(x + 5, floor_y), Vector2(x, floor_y - h)]), BLACK)


func _draw_door(r: Rect2, floor_y: float, open: float) -> void:
	var d := Rect2(r.position.x + 14, r.position.y + 50, r.size.x - 28, floor_y - r.position.y - 50)
	if open > 0.0:
		draw_rect(Rect2(d.position.x, d.end.y - d.size.y * open, d.size.x, d.size.y * open), Color(1.0, 0.95, 0.75, 0.9 * open))
	draw_rect(Rect2(d.position, Vector2(d.size.x, d.size.y * (1.0 - open))), BLACK)


func _draw_potion(p: Vector2, big: bool) -> void:
	var s := 1.4 if big else 1.0
	draw_circle(p + Vector2(0, -12 * s), 10 * s, BLACK)
	draw_rect(Rect2(p + Vector2(-3, -30) * s, Vector2(6, 10) * s), BLACK)
	draw_circle(p + Vector2(0, -12 * s), 5 * s + sin(time * 5.0), Color("ff4a5a") if not big else Color("5aff8a"))


func _draw_sword_item(p: Vector2) -> void:
	draw_line(p + Vector2(-34, -4), p + Vector2(30, -4), BLACK, 4.0)
	draw_line(p + Vector2(-26, -12), p + Vector2(-26, 4), BLACK, 4.0)
	draw_line(p + Vector2(-10, -5), p + Vector2(28, -5), Color(1, 1, 1, 0.5 + 0.3 * sin(time * 4.0)), 1.5)


func _draw_loose_shake(r: Rect2, floor_y: float, t: float) -> void:
	var dx := sin(time * 60.0) * 3.0 * t
	draw_rect(Rect2(r.position.x + 5 + dx, floor_y, r.size.x - 10, 22), BLACK)


func _draw_plate(r: Rect2, on: bool) -> void:
	draw_rect(r.grow_individual(0, -3 if on else 0, 0, 0), BLACK)
	if on:
		draw_rect(Rect2(r.position.x, r.position.y + 5, r.size.x, 2), SCARF)


func _draw_debris(p: Vector2) -> void:
	for k in 4:
		draw_rect(Rect2(p + Vector2(-40 + k * 22, -10), Vector2(18, 12)), BLACK)


func _draw_hud() -> void:
	var g := game
	draw_rect(Rect2(0, 650, 1280, 70), BLACK)
	for i in g.max_hp:
		draw_rect(Rect2(30 + i * 26, 680, 20, 8), SCARF if i < g.hp else Color(SCARF, 0.2))
	var foe: Variant = g._nearest_guard()
	if foe != null:
		for i in int(foe.max_hp):
			draw_rect(Rect2(1150 - i * 26, 680, 20, 8), Color(1, 1, 1, 0.8) if i < int(foe.hp) else Color(1, 1, 1, 0.15))
	PixelFont.draw(self, I18n.t("%d MIN") % g.minutes_left(), 640, 674, 3, Color(1, 1, 1, 0.85))


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.03, 0.03, 0.05, 0.9),
		"border": SCARF,
		"text": Color("f4ece0"),
		"accent": SCARF,
		"button": Color(0.08, 0.07, 0.1),
		"button_hover": Color(0.16, 0.12, 0.14),
		"radius": 0,
		"dim": Color(0, 0, 0, 0.3),
	}
