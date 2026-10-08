extends RelicsSkin
## Clássico 1984: como nos jogos "Filmation" dos micros de 8 bits — fundo preto e cada sala
## desenhada numa só cor (tinta) com contornos e tijolos a traço; sons de altifalante.

const INKS := [Color("ffff00"), Color("00ffff"), Color("ff00ff"), Color("00ff00"), Color("ffffff"), Color("ff8040")]

var ink := Color.YELLOW
var _sprites_for := Color(0, 0, 0, 0)


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_make_sprites()


func _tick(_d: float) -> void:
	ink = INKS[(game.room.x + game.room.y * 3) % INKS.size()]
	if ink != _sprites_for:
		_make_sprites()


func _make_sprites() -> void:
	_sprites_for = ink
	var pal := {"H": ink, "S": ink, "E": Color.BLACK, "B": ink, "b": Color.BLACK, "L": ink, "K": ink, "P": Color.BLACK, "h": ink}
	for f: String in MAN:
		tex["man_" + f] = PixelArt.texture(MAN[f], pal, 1)
	tex.guard = PixelArt.texture(GUARD, {"A": ink, "a": ink, "V": Color.BLACK}, 1)
	tex.ghost = PixelArt.texture(GHOST, {"G": ink, "E": Color.BLACK, "O": Color.BLACK}, 1)
	tex.relic = PixelArt.texture(RELIC, {"Y": Color.WHITE, "y": Color.BLACK}, 1)
	tex.heart = PixelArt.texture(HEART, {"R": ink, "W": Color.BLACK}, 1)


func _build_sfx() -> void:
	sfx.step = Synth.tone(160.0, 0.02, {"wave": "square", "volume": 0.08})
	sfx.jump = Synth.tone(300.0, 0.15, {"wave": "square", "freq_end": 700.0, "volume": 0.08})
	sfx.land = Synth.tone(120.0, 0.03, {"wave": "square", "volume": 0.1})
	sfx.pick = Synth.tone(600.0, 0.08, {"wave": "square", "freq_end": 900.0, "volume": 0.08})
	sfx.drop = Synth.tone(900.0, 0.08, {"wave": "square", "freq_end": 400.0, "volume": 0.08})
	sfx.door = Synth.tone(200.0, 0.1, {"wave": "square", "freq_end": 400.0, "volume": 0.08})
	var r := []
	for f in [784.0, 988.0, 1175.0, 1568.0]:
		r.append(Synth.render(f, 0.06, {"wave": "square", "volume": 0.1}))
	sfx.relic = Synth.concat(r)
	sfx.heart = Synth.concat([Synth.render(1046.0, 0.08, {"wave": "square", "volume": 0.1}), Synth.render(1568.0, 0.12, {"wave": "square", "volume": 0.1})])
	var d := []
	for f in [523.0, 659.0, 784.0, 1046.0, 784.0, 1046.0]:
		d.append(Synth.render(f, 0.1, {"wave": "square", "volume": 0.11}))
	sfx.deposit = Synth.concat(d)
	sfx.die = Synth.tone(1000.0, 1.0, {"wave": "square", "freq_end": 80.0, "volume": 0.12})
	sfx.day = Synth.concat([Synth.render(392.0, 0.12, {"wave": "square", "volume": 0.08}), Synth.render(523.0, 0.2, {"wave": "square", "volume": 0.08})])
	var w := []
	for f in [523.0, 659.0, 784.0, 1046.0, 1318.0, 1568.0, 2093.0, 1568.0, 2093.0]:
		w.append(Synth.render(f, 0.14, {"wave": "square", "volume": 0.12}))
	sfx.win = Synth.concat(w)


func _draw_floor() -> void:
	var n := float(RelicsGame.ROOM)
	for i in RelicsGame.ROOM + 1:
		draw_line(iso(Vector3(i, 0, 0)), iso(Vector3(i, n, 0)), Color(ink, 0.18), 1.0)
		draw_line(iso(Vector3(0, i, 0)), iso(Vector3(n, i, 0)), Color(ink, 0.18), 1.0)
	var q := PackedVector2Array([iso(Vector3(0, 0, 0)), iso(Vector3(n, 0, 0)), iso(Vector3(n, n, 0)), iso(Vector3(0, n, 0)), iso(Vector3(0, 0, 0))])
	draw_polyline(q, ink, 2.0)


func _wall_quad(_side: String, q: PackedVector2Array, z0: float, z1: float) -> void:
	draw_colored_polygon(q, Color.BLACK)
	# tijolos
	var rows := int(round((z1 - z0) / 0.4))
	for i in range(1, rows):
		var t := float(i) / rows
		draw_line(q[0].lerp(q[3], t), q[1].lerp(q[2], t), Color(ink, 0.45), 1.0)
		for k in range(1, 8):
			var u := (k + (0.5 if i % 2 else 0.0)) / 8.0
			if u >= 1.0:
				continue
			var a := q[0].lerp(q[1], u).lerp(q[3].lerp(q[2], u), t)
			var b := q[0].lerp(q[1], u).lerp(q[3].lerp(q[2], u), float(i + 1) / rows)
			draw_line(a, b, Color(ink, 0.3), 1.0)
	var o := q.duplicate()
	o.append(o[0])
	draw_polyline(o, ink, 2.0)


func _draw_door(_side: String, q: PackedVector2Array, _dz: int) -> void:
	draw_colored_polygon(q, Color.BLACK)
	var o := q.duplicate()
	o.append(o[0])
	draw_polyline(o, ink, 3.0)


func _draw_front_door(_side: String, a: Vector3, b: Vector3, _dz: float) -> void:
	for p: Vector3 in [a, b]:
		draw_line(iso(p), iso(p + Vector3(0, 0, 0.5)), ink, 3.0)
	draw_line(iso(a), iso(b), Color(ink, 0.6), 2.0)


func _draw_spikes(c: Vector2i) -> void:
	for k in 4:
		var p := Vector3(c.x + 0.25 + (k % 2) * 0.5, c.y + 0.25 + (k / 2) * 0.5, 0)
		var base := iso(p)
		draw_colored_polygon(PackedVector2Array([base + Vector2(-7, 2), base + Vector2(7, 2), base + Vector2(0, -16)]), ink)


func _draw_block(b: Dictionary, p: Vector3, s: Vector3, _top: bool) -> void:
	match b.kind:
		"stone":
			draw_box(p, s, Color.BLACK, Color.BLACK, Color.BLACK, ink, 2.0)
			var f := box_faces(p + Vector3(0.2, 0.2, 0), Vector3(0.6, 0.6, s.z))
			var t: PackedVector2Array = f[0]
			t.append(t[0])
			draw_polyline(t, Color(ink, 0.5), 1.0)
		"crate":
			draw_box(p, s, Color(ink, 0.55), Color(ink, 0.3), Color(ink, 0.42), ink, 2.0)
			var f := box_faces(p, s)
			for face: PackedVector2Array in [f[1], f[2]]:
				draw_line(face[0], face[2], Color.BLACK, 2.0)
				draw_line(face[1], face[3], Color.BLACK, 2.0)
		"altar":
			draw_box(p, s, Color.BLACK, Color.BLACK, Color.BLACK, ink, 3.0)
			var c := iso(p + Vector3(0.5, 0.5, 1.0))
			for k in 3:
				var h := 18.0 + sin(time * 9.0 + k) * 5.0
				draw_colored_polygon(PackedVector2Array([c + Vector2(-8 + k * 8 - 5, 0), c + Vector2(-8 + k * 8 + 5, 0), c + Vector2(-8 + k * 8, -h)]), Color.WHITE if k == 1 else ink)
			for i in game.deposited:
				draw_texture_rect(tex.relic, Rect2(c + Vector2(-48 + i * 12, 6), Vector2(12, 12)), false)


func _draw_item(it: Dictionary) -> void:
	var p: Vector3 = it.pos + Vector3(0, 0, 0.15 + sin(float(it.phase) * 3.0) * 0.08)
	draw_sprite_at(tex.relic if it.kind == "relic" else tex.heart, p, 3.0, false, Color.WHITE if it.kind == "relic" else Color.WHITE)


func _draw_enemy(e: Dictionary) -> void:
	var p: Vector3 = e.pos
	match e.kind:
		"guard":
			draw_sprite_at(tex.guard, p, 3.0, (e.dir as Vector3).x - (e.dir as Vector3).y < 0.0)
		"ball":
			var c := iso(Vector3(p.x, p.y, game.enemy_z(e) + 0.35))
			draw_circle(c, 16, Color.BLACK)
			draw_arc(c, 16, 0, TAU, 24, ink, 2.0)
			draw_arc(c, 10, PI * 1.1, PI * 1.6, 8, ink, 2.0)
		"ghost":
			draw_sprite_at(tex.ghost, p, 3.0, false, Color(1, 1, 1, 0.75))


func _draw_player() -> void:
	var fr := man_frame()
	draw_sprite_at(tex["man_" + fr[0]], game.pos, 3.5, fr[1])
	if game.carrying != null:
		var top := game.pos + Vector3(-0.45, -0.45, RelicsGame.PLAYER_H + 0.05)
		draw_box(top, Vector3(0.9, 0.9, 0.9), Color(ink, 0.55), Color(ink, 0.3), Color(ink, 0.42), ink, 2.0)


func _draw_hud() -> void:
	var g := game
	_draw_hud_common(ink, ink, Color(ink, 0.18), func(t: String, p: Vector2) -> void: PixelFont.draw(self, t, p.x, p.y - 20, 3, ink))
	PixelFont.draw(self, I18n.t("PONTOS"), 120, 600, 2, ink)
	PixelFont.draw(self, "%06d" % g.score, 120, 622, 3, Color.WHITE)
	PixelFont.draw(self, I18n.t("VIDAS %d") % g.lives, 120, 670, 2, ink)
	# dia e noite
	var c := Vector2(120, 520)
	var night := g.day_phase() > 0.5
	draw_circle(c, 26, Color.WHITE if not night else ink)
	if night:
		draw_circle(c + Vector2(10, -6), 22, Color.BLACK)
	PixelFont.draw(self, I18n.t("DIA %d/%d") % [g.day(), RelicsGame.DAYS], 120, 556, 2, ink)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0, 0, 0, 0.92),
		"border": Color.YELLOW,
		"text": Color.WHITE,
		"accent": Color.YELLOW,
		"button": Color(0.15, 0.15, 0),
		"button_hover": Color(0.3, 0.3, 0),
		"radius": 0,
		"dim": Color(0, 0, 0, 0.4),
	}
