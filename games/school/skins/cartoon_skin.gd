extends SchoolSkin
## Desenho Animado: uma escola de desenho animado moderno — paredes lisas em tons pastel com
## lambrim, soalho de madeira, janelas com céu, cartazes, contornos escuros e grossos, e
## personagens de cabeça grande, roupa colorida e olhos expressivos. Recreio com relva e nuvens.

const INK := Color("2a2238")
const SKIN_TONES := [Color("f2c7a0"), Color("d9a07a"), Color("a8704a"), Color("f6d2b4")]
const WALLS := {
	"Sala do Mapa": Color("f6e3a8"), "Sala de Leitura": Color("bfe3dc"), "Gabinete do Diretor": Color("e8c4d4"),
	"Sala Branca": Color("eeeae4"), "Sala de Exames": Color("cde4b4"), "Laboratório": Color("c4d4f0"),
	"Refeitório": Color("f6d0a8"), "Átrio": Color("dcd4ec"),
}
## Roupa e cabelo por personagem (índice de chars).
const LOOK := [
	{"shirt": Color("e8483a"), "legs": Color("2a4a8a"), "hair": Color("4a2a18"), "skin": 0},   # Zé
	{"shirt": Color("6a5a4a"), "legs": Color("3a3a3a"), "hair": Color("1a1a1a"), "skin": 1},   # Brutamontes
	{"shirt": Color("f0f0f0"), "legs": Color("6a6a7a"), "hair": Color("c89a4a"), "skin": 3},   # Marrão
	{"shirt": Color("4ab86a"), "legs": Color("2a4a8a"), "hair": Color("c84a2a"), "skin": 0},   # Traquinas
	{"shirt": Color("e86aa8"), "legs": Color("4a3a6a"), "hair": Color("6a3a1a"), "skin": 2},
	{"shirt": Color("f0b43a"), "legs": Color("2a4a8a"), "hair": Color("1a1a1a"), "skin": 1},
	{"shirt": Color("6aa8e8"), "legs": Color("3a3a4a"), "hair": Color("e8c86a"), "skin": 3},
	{"shirt": Color("a86ae8"), "legs": Color("2a3a5a"), "hair": Color("3a2a1a"), "skin": 2},
	{"shirt": Color("3a3a5a"), "legs": Color("2a2a3a"), "hair": Color("d0d0d0"), "skin": 3},   # Dr. Severino
	{"shirt": Color("a83a5a"), "legs": Color("3a2a3a"), "hair": Color("8a4a2a"), "skin": 0},   # Prof.ª Matilde
	{"shirt": Color("3a7a6a"), "legs": Color("3a3a3a"), "hair": Color("2a2a2a"), "skin": 1},   # Prof. Faria
	{"shirt": Color("8a6a3a"), "legs": Color("4a3a2a"), "hair": Color("9a9a9a"), "skin": 3},   # Prof. Carvalho
]

var font: Font


func _setup() -> void:
	font = ThemeDB.fallback_font


func _build_sfx() -> void:
	sfx.bell = Synth.concat([Synth.render(988.0, 0.25, {"wave": "sine", "volume": 0.25, "decay": 4.0}), Synth.render(784.0, 0.25, {"wave": "sine", "volume": 0.25, "decay": 4.0}), Synth.render(988.0, 0.4, {"wave": "sine", "volume": 0.25, "decay": 3.0})])
	sfx.lines = Synth.concat([Synth.render(220.0, 0.15, {"wave": "triangle", "volume": 0.25}), Synth.render(165.0, 0.3, {"wave": "triangle", "volume": 0.25, "decay": 4.0})])
	sfx.shield = Synth.tone(660.0, 0.15, {"wave": "triangle", "freq_end": 1320.0, "volume": 0.2, "decay": 8.0})
	var a := []
	for f in [523.0, 659.0, 784.0, 1046.0, 1318.0]:
		a.append(Synth.render(f, 0.09, {"wave": "triangle", "volume": 0.2, "decay": 8.0}))
	sfx.all = Synth.concat(a)
	sfx.letter = Synth.concat([Synth.render(1046.0, 0.1, {"wave": "sine", "volume": 0.25}), Synth.render(1318.0, 0.2, {"wave": "sine", "volume": 0.25, "decay": 6.0})])
	var s := []
	for f in [392.0, 523.0, 659.0, 784.0, 659.0, 784.0, 1046.0]:
		s.append(Synth.render(f, 0.13, {"wave": "triangle", "volume": 0.22, "decay": 4.0}))
	sfx.safe = Synth.concat(s)
	sfx.knock = Synth.to_stream(Synth.mix([Synth.render(180.0, 0.25, {"wave": "sine", "freq_end": 60.0, "volume": 0.4, "decay": 10.0}), Synth.render(1400.0, 0.3, {"wave": "sine", "freq_end": 1800.0, "volume": 0.06, "decay": 8.0})]))
	sfx.fire = Synth.tone(500.0, 0.12, {"wave": "triangle", "freq_end": 1600.0, "volume": 0.18, "decay": 12.0})
	sfx.punch = Synth.to_stream(Synth.mix([Synth.render(0.0, 0.1, {"wave": "noise", "volume": 0.25, "lowpass": 0.3, "decay": 30.0}), Synth.render(120.0, 0.1, {"wave": "sine", "volume": 0.3, "decay": 30.0})]))
	sfx.jump = Synth.tone(300.0, 0.2, {"wave": "sine", "freq_end": 700.0, "volume": 0.2, "decay": 8.0})
	sfx.expelled = Synth.concat([Synth.render(392.0, 0.3, {"wave": "triangle", "volume": 0.25}), Synth.render(370.0, 0.3, {"wave": "triangle", "volume": 0.25}), Synth.render(349.0, 0.3, {"wave": "triangle", "volume": 0.25}), Synth.render(330.0, 0.8, {"wave": "triangle", "volume": 0.25, "decay": 2.0})])


func _draw_back() -> void:
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(1280, 0), Vector2(1280, 600), Vector2(0, 600)]),
		PackedColorArray([Color("7ec4f0"), Color("7ec4f0"), Color("d4eefa"), Color("d4eefa")]))


func _txt(ci: CanvasItem, text: String, c: Vector2, size: int, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	ci.draw_string(font, Vector2(c.x - w * 0.5, c.y + size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _rrect(ci: CanvasItem, r: Rect2, col: Color, radius: int, border := 0.0, bcol := INK) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(radius)
	if border > 0.0:
		sb.border_color = bcol
		sb.set_border_width_all(int(border))
	ci.draw_style_box(sb, r)


func _paint_world(ci: CanvasItem) -> void:
	var W := SchoolGame.WORLD_W
	var BW := SchoolGame.BUILDING_W
	# nuvens e recreio
	for k in 6:
		var p := Vector2(BW + 120.0 + k * 170.0, 60.0 + (k % 3) * 40.0)
		for d: Vector3 in [Vector3(-30, 6, 26), Vector3(0, -6, 34), Vector3(32, 4, 26)]:
			ci.draw_circle(p + Vector2(d.x, d.y), d.z, Color(1, 1, 1, 0.9))
	var gy: float = SchoolGame.FLOOR_Y[2]
	ci.draw_rect(Rect2(BW, gy - 70, W - BW, 80), Color("8ad06a"))
	ci.draw_rect(Rect2(BW, gy - 70, W - BW, 8), Color("a8e488"))
	ci.draw_rect(Rect2(3300, gy - 200, 26, 200), Color("8a5a3a"))
	for d: Vector3 in [Vector3(3313, gy - 230, 70), Vector3(3260, gy - 190, 48), Vector3(3370, gy - 190, 48)]:
		ci.draw_circle(Vector2(d.x, d.y) + Vector2(4, 6), d.z, Color("3a8a3a"))
		ci.draw_circle(Vector2(d.x, d.y), d.z, Color("5ab84a"))
	ci.draw_rect(Rect2(2950, gy - 230, 10, 230), Color("6a6a7a"))
	ci.draw_rect(Rect2(2930, gy - 250, 60, 40), Color("f0f0f0"))
	ci.draw_rect(Rect2(2930, gy - 250, 60, 40), INK, false, 3.0)
	ci.draw_arc(Vector2(2990, gy - 206), 18, 0, PI, 10, Color("e8483a"), 4.0)
	# telhado
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-30, 14), Vector2(BW + 40, 14), Vector2(BW + 10, -30), Vector2(0, -30)]), Color("c8584a"))
	for r: Dictionary in SchoolGame.ROOMS:
		if r.name == "Recreio":
			continue
		var f := int(r.floor)
		var top := floor_top(f)
		var x0 := float(r.x0)
		var x1 := float(r.x1)
		var y: float = SchoolGame.FLOOR_Y[f]
		var wall: Color = WALLS[r.name]
		ci.draw_rect(Rect2(x0, top, x1 - x0, SchoolGame.ROOM_H), wall)
		ci.draw_rect(Rect2(x0, y - 46, x1 - x0, 46), wall.darkened(0.12))
		ci.draw_rect(Rect2(x0, y - 50, x1 - x0, 5), wall.darkened(0.25))
		# janelas
		var nw := int((x1 - x0) / 300.0)
		for k in nw:
			var wx := x0 + 420.0 + k * 300.0
			if wx + 90 > x1 - 20 or (wx > x0 + 60 and wx < x0 + 330):
				continue
			_rrect(ci, Rect2(wx, top + 34, 90, 70), Color("a8dcf8"), 6, 4.0, Color("ffffff"))
			ci.draw_line(Vector2(wx + 45, top + 34), Vector2(wx + 45, top + 104), Color("ffffff"), 4.0)
		_txt(ci, I18n.t(String(r.name)), Vector2((x0 + x1) * 0.5, top + 18), 18, wall.darkened(0.55))
	# soalho
	for f in 3:
		var y: float = SchoolGame.FLOOR_Y[f]
		ci.draw_rect(Rect2(0, y, BW, 12), Color("b07a4a"))
		for x in range(0, int(BW), 60):
			ci.draw_line(Vector2(x, y), Vector2(x, y + 12), Color("8a5a34"), 2.0)
		ci.draw_rect(Rect2(0, floor_top(f) - 8, BW, 8), Color("e8e0d4"))
	ci.draw_rect(Rect2(BW, gy, W - BW, 30), Color("6aa84a"))
	ci.draw_rect(Rect2(0, gy + 12, BW, 18), Color("8a8a9a"))
	# paredes
	for r: Dictionary in SchoolGame.ROOMS:
		var f := int(r.floor)
		var x := float(r.x0)
		if x <= 0.0 or x > BW:
			continue
		var top := floor_top(f)
		ci.draw_rect(Rect2(x - 9, top, 18, float(SchoolGame.FLOOR_Y[f]) - 112.0 - top), Color("f4ece0"))
		ci.draw_rect(Rect2(x - 9, top, 18, float(SchoolGame.FLOOR_Y[f]) - 112.0 - top), INK, false, 3.0)
	ci.draw_rect(Rect2(-6, -30, 14, 630), Color("c8584a"))
	ci.draw_rect(Rect2(BW - 8, -30, 16, SchoolGame.FLOOR_Y[1] + 42.0), Color("c8584a"))
	# escadas
	for s: Dictionary in SchoolGame.STAIRS:
		var f := int(s.f)
		var a := Vector2(s.top, SchoolGame.FLOOR_Y[f])
		var b := Vector2(s.bottom, SchoolGame.FLOOR_Y[f + 1])
		for k in 10:
			var p := a.lerp(b, k / 10.0)
			var q := a.lerp(b, (k + 1) / 10.0)
			var r := Rect2(minf(p.x, q.x), p.y, absf(q.x - p.x) + 2, 8)
			ci.draw_rect(r, Color("b07a4a"))
			ci.draw_rect(r, INK, false, 2.0)
		ci.draw_line(a + Vector2(0, -44), b + Vector2(0, -44), Color("8a5a34"), 5.0)
	# mobília
	for i in SchoolGame.ROOMS.size():
		var r: Dictionary = SchoolGame.ROOMS[i]
		var y: float = SchoolGame.FLOOR_Y[int(r.floor)]
		if r.board:
			var bx := game.board_x(i)
			_rrect(ci, Rect2(bx - 114, y - 144, 228, 78), Color("b07a4a"), 6, 3.0)
			ci.draw_rect(Rect2(bx - 104, y - 134, 208, 58), Color("2e5a46"))
			for k in 8:
				var sx := game.seat_x(i, k)
				_rrect(ci, Rect2(sx - 42, y - 32, 36, 8), Color("d8a060"), 3, 2.0)
				ci.draw_rect(Rect2(sx - 38, y - 24, 5, 24), INK)
				ci.draw_rect(Rect2(sx - 15, y - 24, 5, 24), INK)
				_rrect(ci, Rect2(sx - 4, y - 19, 16, 6), Color("e8483a"), 3, 2.0)
				ci.draw_rect(Rect2(sx + 8, y - 36, 5, 36), INK)
		elif r.name == "Refeitório":
			for k in 3:
				var x0 := float(r.x0) + 260 + k * 250
				_rrect(ci, Rect2(x0, y - 38, 190, 10), Color("d8a060"), 4, 2.0)
				ci.draw_rect(Rect2(x0 + 12, y - 28, 6, 28), INK)
				ci.draw_rect(Rect2(x0 + 172, y - 28, 6, 28), INK)
				for t in 3:
					ci.draw_circle(Vector2(x0 + 40 + t * 55, y - 42), 9, Color("ffffff"))
					ci.draw_arc(Vector2(x0 + 40 + t * 55, y - 42), 9, 0, TAU, 12, INK, 2.0)
		elif r.name == "Gabinete do Diretor":
			_rrect(ci, Rect2(1900, y - 44, 160, 12), Color("8a5a34"), 3, 2.0)
			ci.draw_rect(Rect2(1912, y - 32, 8, 32), INK)
			ci.draw_rect(Rect2(2040, y - 32, 8, 32), INK)
			_rrect(ci, Rect2(2150, y - 150, 100, 70), Color("f6e3a8"), 4, 3.0)
			ci.draw_circle(Vector2(2200, y - 115), 18, Color("e8b83a"))
			_rrect(ci, Rect2(1780, y - 150, 60, 80), Color("ffffff"), 3, 3.0)
		elif r.name == "Átrio":
			for k in 8:
				var lx := 1500.0 + k * 46.0
				_rrect(ci, Rect2(lx, y - 104, 42, 104), Color("6a9ad8") if k % 2 == 0 else Color("e8a84a"), 4, 2.0)
				ci.draw_rect(Rect2(lx + 30, y - 64, 5, 12), INK)


func _draw_board_text(p: Vector2, text: String) -> void:
	_txt(self, text, p + Vector2(0, 8), 24, Color("f4f4e8"))


func _draw_shield(p: Vector2, hit: bool, i: int) -> void:
	var pts := PackedVector2Array([p + Vector2(-16, -18), p + Vector2(16, -18), p + Vector2(16, 2), p + Vector2(0, 20), p + Vector2(-16, 2)])
	var on := hit and int(time * 4.0 + i) % 2 == 0
	draw_colored_polygon(pts, Color("f6c83a") if on else (Color("8ad06a") if hit else Color("4a7ac8")))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-16, -18), p + Vector2(0, -18), p + Vector2(0, 20), p + Vector2(-16, 2)]), Color(1, 1, 1, 0.18))
	pts.append(pts[0])
	draw_polyline(pts, INK, 3.0)
	if hit:
		draw_polyline(PackedVector2Array([p + Vector2(-7, 0), p + Vector2(-1, 6), p + Vector2(8, -6)]), INK, 3.0)
	else:
		draw_circle(p + Vector2(0, -2), 5, Color("f6c83a"))


func _draw_safe(p: Vector2, open: bool) -> void:
	var r := Rect2(p.x - 36, p.y - 80, 72, 80)
	_rrect(self, r, Color("7a8494"), 6, 3.0)
	if open:
		_rrect(self, r.grow(-8), Color("2a2a34"), 3)
		_rrect(self, Rect2(r.position.x - 34, r.position.y + 6, 34, r.size.y - 12), Color("8a94a4"), 4, 3.0)
		_rrect(self, Rect2(r.position.x + 18, r.position.y + 42, 34, 24), Color("ffffff"), 2, 2.0)
		draw_line(Vector2(r.position.x + 22, r.position.y + 50), Vector2(r.position.x + 46, r.position.y + 50), Color("e8483a"), 2.0)
	else:
		draw_circle(r.get_center(), 15, Color("c8ccd4"))
		draw_arc(r.get_center(), 15, 0, TAU, 20, INK, 3.0)
		draw_line(r.get_center(), r.get_center() + Vector2.from_angle(time * 0.7) * 11.0, INK, 3.0)
	_txt(self, I18n.t("COFRE"), Vector2(p.x, r.position.y - 14), 16, INK)


func _limb(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	draw_line(a, b, INK, w + 4.0)
	draw_circle(a, (w + 4.0) * 0.5, INK)
	draw_circle(b, (w + 4.0) * 0.5, INK)
	draw_line(a, b, col, w)
	draw_circle(a, w * 0.5, col)
	draw_circle(b, w * 0.5, col)


func _draw_person(c: Dictionary, j: Dictionary) -> void:
	var look: Dictionary = LOOK[mini(int(c.id), LOOK.size() - 1)]
	var s: float = j.s
	var f: float = j.f
	var skin: Color = SKIN_TONES[int(look.skin)]
	var w := 6.0 * s
	var big: bool = c.role == "bully"
	_limb(j.hip, j.knee_b, (look.legs as Color).darkened(0.15), w)
	_limb(j.knee_b, j.foot_b, (look.legs as Color).darkened(0.15), w)
	_limb(j.neck, j.elbow_b, (look.shirt as Color).darkened(0.15), w * 0.85)
	_limb(j.elbow_b, j.hand_b, skin.darkened(0.1), w * 0.75)
	_limb(j.hip, j.knee_f, look.legs, w)
	_limb(j.knee_f, j.foot_f, look.legs, w)
	# tronco
	var hip: Vector2 = j.hip
	var neck: Vector2 = j.neck
	var side := (neck - hip).orthogonal().normalized() * (9.0 if big else 7.5) * s
	var torso := PackedVector2Array([neck + side, neck - side, hip - side * 1.1, hip + side * 1.1])
	if c.role == "teacher":
		var kn: Vector2 = (j.knee_f + j.knee_b) * 0.5
		torso = PackedVector2Array([neck + side, neck - side, kn - side * 1.3, kn + side * 1.3])
	var outl := PackedVector2Array()
	for v in torso:
		outl.append(v + (v - (neck + hip) * 0.5).normalized() * 2.5)
	draw_colored_polygon(outl, INK)
	draw_colored_polygon(torso, look.shirt)
	_limb(j.neck, j.elbow_f, look.shirt, w * 0.85)
	_limb(j.elbow_f, j.hand_f, skin, w * 0.75)
	# cabeça grande
	var head: Vector2 = j.head
	var hr := 13.0 * s
	draw_circle(head, hr + 2.5, INK)
	draw_circle(head, hr, skin)
	var up := (head - neck).normalized()
	var hair: Color = look.hair
	if c.role == "teacher" and int(c.teacher) == 0:
		draw_arc(head, hr - 1.0, up.angle() + 1.2, up.angle() + 2.4, 8, hair, 4.0)
		draw_arc(head, hr - 1.0, up.angle() - 2.4, up.angle() - 1.2, 8, hair, 4.0)
		draw_line(head + up.rotated(PI) * 5.0 + Vector2(f * 3.0, 0) - up.orthogonal() * 5.0, head + up.rotated(PI) * 5.0 + Vector2(f * 3.0, 0) + up.orthogonal() * 5.0, hair, 3.0)
	else:
		draw_arc(head, hr - 2.0, up.angle() - 1.4, up.angle() + 1.4, 12, hair, 7.0)
	if c.role == "hero":
		draw_arc(head, hr, up.angle() - 1.3, up.angle() + 1.3, 12, Color("e8483a"), 5.0)
		draw_line(head + up * hr * 0.75, head + up * hr * 0.75 + up.orthogonal() * -f * 14.0, Color("e8483a"), 5.0)
	if game.is_down(c):
		var e := head + up.orthogonal() * -f * 4.0
		draw_line(e - Vector2(3, 3), e + Vector2(3, 3), INK, 2.0)
		draw_line(e - Vector2(3, -3), e + Vector2(3, -3), INK, 2.0)
		for k in 3:
			var a := time * 4.0 + k * TAU / 3.0
			draw_circle(head + up * (hr + 8.0) + Vector2(cos(a) * 12.0, sin(a) * 4.0), 3.0, Color("f6c83a"))
	else:
		var e := head + Vector2(f * 5.0 * s, -1.0)
		draw_circle(e, 4.0 * s, Color.WHITE)
		draw_circle(e + Vector2(f * 1.5, 0), 2.0 * s, INK)
		if c.role == "swot" or (c.role == "teacher" and int(c.teacher) == 1):
			draw_arc(e, 5.5 * s, 0, TAU, 12, INK, 1.5)
		draw_arc(head + Vector2(f * 6.0 * s, 6.0 * s), 3.5 * s, 0.2, PI - 0.2, 6, INK, 1.5)
	if c.role == "teacher" and int(c.teacher) == 3:
		draw_line(head + Vector2(f * 3.0, 4.0), head + Vector2(f * 12.0, 4.0), Color("9a9a9a"), 3.0)


func _draw_pellet(p: Vector2, dir: int) -> void:
	draw_line(p, p - Vector2(dir * 16, 0), Color(1, 1, 1, 0.6), 3.0)
	draw_circle(p, 4.0, INK)
	draw_circle(p, 2.5, Color("f6c83a"))


func _draw_bubble(p: Vector2, text: String, teacher: bool) -> void:
	var ls := wrap_text(text, 24)
	var w := 0.0
	for l in ls:
		w = maxf(w, font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x)
	var h := ls.size() * 20.0 + 14.0
	var r := Rect2(p.x - w * 0.5 - 12, p.y - h, w + 24, h)
	r.position.x = clampf(r.position.x, 4, 1276 - r.size.x)
	r.position.y = maxf(r.position.y, 4)
	draw_colored_polygon(PackedVector2Array([Vector2(p.x - 8, r.end.y - 3), Vector2(p.x + 8, r.end.y - 3), Vector2(p.x, r.end.y + 12)]), INK)
	_rrect(self, r, Color("fff8e8") if teacher else Color("ffffff"), 12, 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(p.x - 5, r.end.y - 4), Vector2(p.x + 5, r.end.y - 4), Vector2(p.x, r.end.y + 7)]), Color("fff8e8") if teacher else Color("ffffff"))
	for i in ls.size():
		_txt(self, ls[i], Vector2(r.get_center().x, r.position.y + 16 + i * 20.0), 16, INK)


func _draw_hud() -> void:
	var g := game
	draw_rect(Rect2(0, 600, 1280, 120), Color("3a3250"))
	_rrect(self, Rect2(12, 610, 700, 100), Color("4a4266"), 14)
	_rrect(self, Rect2(724, 610, 544, 100), Color("4a4266"), 14)
	_txt(self, period_text(), Vector2(380, 630), 20, Color("f6e3a8"))
	_rrect(self, Rect2(110, 648, 540, 12), Color("2a2238"), 6)
	_rrect(self, Rect2(110, 648, 540 * period_left(), 12), Color("8ad06a"), 6)
	_txt(self, I18n.t("Dia %d") % g.day, Vector2(60, 654), 15, Color("dcd4ec"))
	_txt(self, I18n.t("Escudos %d/%d") % [g.shields_done(), SchoolGame.SHIELDS.size()], Vector2(200, 688), 20, Color("8ac8f8"))
	_txt(self, I18n.t("Cofre:  ") + code_text(), Vector2(520, 688), 20, Color("ffffff"))
	_txt(self, I18n.t("Linhas  %d / %d") % [g.lines, SchoolGame.MAX_LINES], Vector2(996, 630), 20, Color("f89a8a"))
	_rrect(self, Rect2(760, 648, 472, 12), Color("2a2238"), 6)
	if g.lines > 0:
		_rrect(self, Rect2(760, 648, maxf(472.0 * g.lines / SchoolGame.MAX_LINES, 12.0), 12), Color("e8483a"), 6)
	_txt(self, I18n.t("Pontos %d     Recorde %d") % [g.score, maxi(g.best, g.score)], Vector2(996, 688), 18, Color("ffffff"))
	if g.state == SchoolGame.State.OVER:
		_rrect(self, Rect2(380, 220, 520, 140), Color("ffffff"), 20, 5.0)
		_txt(self, I18n.t("EXPULSO!"), Vector2(640, 280), 72, Color("e8483a"))


func ui_palette() -> Dictionary:
	return {
		"panel": Color("fff8e8", 0.97),
		"border": INK,
		"text": INK,
		"accent": Color("e8483a"),
		"button": Color("f6e3a8"),
		"button_hover": Color("f6c83a"),
		"radius": 14,
		"dim": Color(0.1, 0.1, 0.2, 0.35),
	}
