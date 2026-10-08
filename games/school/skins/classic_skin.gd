extends SchoolSkin
## Clássico 1985: as cores fortes dos computadores de 8 bits — cada sala pintada numa cor
## "de atributo" (ciano, amarelo, verde, magenta...), pisos e paredes grossos, escadas em degraus,
## e as personagens desenhadas só a tinta preta por cima, como nos jogos da época. Professores
## de beca e barrete; letras de píxeis; sons de altifalante.

const BLACK := Color("000000")
const WHITE := Color("ffffff")
const PAPER := {
	"Sala do Mapa": Color("d7d700"), "Sala de Leitura": Color("00d7d7"), "Gabinete do Diretor": Color("d700d7"),
	"Sala Branca": Color("d7d7d7"), "Sala de Exames": Color("00d700"), "Laboratório": Color("d7d700"),
	"Refeitório": Color("00d7d7"), "Átrio": Color("d7d7d7"), "Recreio": Color("00d7d7"),
}
const BRICK := Color("d70000")
const FLOOR := Color("0000d7")


func _build_sfx() -> void:
	var b := []
	for i in 14:
		b.append(Synth.render(1800.0 if i % 2 == 0 else 1500.0, 0.04, {"wave": "square", "volume": 0.07}))
	sfx.bell = Synth.concat(b)
	sfx.lines = Synth.tone(110.0, 0.35, {"wave": "square", "volume": 0.09})
	sfx.shield = Synth.concat([Synth.render(1046.0, 0.05, {"wave": "square", "volume": 0.07}), Synth.render(1568.0, 0.08, {"wave": "square", "volume": 0.07})])
	var a := []
	for f in [523.0, 659.0, 784.0, 1046.0, 784.0, 1046.0]:
		a.append(Synth.render(f, 0.08, {"wave": "square", "volume": 0.07}))
	sfx.all = Synth.concat(a)
	sfx.letter = Synth.concat([Synth.render(880.0, 0.08, {"wave": "square", "volume": 0.07}), Synth.render(660.0, 0.08, {"wave": "square", "volume": 0.07}), Synth.render(1320.0, 0.15, {"wave": "square", "volume": 0.07})])
	var s := []
	for f in [523.0, 523.0, 784.0, 784.0, 880.0, 880.0, 784.0, 0.0, 698.0, 659.0, 587.0, 523.0]:
		s.append(Synth.render(f, 0.11, {"wave": "square", "volume": 0.07 if f > 0.0 else 0.0}))
	sfx.safe = Synth.concat(s)
	sfx.knock = Synth.tone(0.0, 0.12, {"wave": "noise", "volume": 0.2, "lowpass": 0.3, "decay": 25.0})
	sfx.fire = Synth.tone(300.0, 0.1, {"wave": "square", "freq_end": 1500.0, "volume": 0.06})
	sfx.punch = Synth.tone(0.0, 0.07, {"wave": "noise", "volume": 0.2, "lowpass": 0.5, "decay": 40.0})
	sfx.jump = Synth.tone(400.0, 0.12, {"wave": "square", "freq_end": 900.0, "volume": 0.05})
	var e := []
	for f in [392.0, 370.0, 349.0, 330.0, 311.0, 294.0, 262.0]:
		e.append(Synth.render(f, 0.15, {"wave": "square", "volume": 0.08}))
	sfx.expelled = Synth.concat(e)


func _draw_back() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), BLACK)


func _paint_world(ci: CanvasItem) -> void:
	var W := SchoolGame.WORLD_W
	var BW := SchoolGame.BUILDING_W
	# céu e recreio
	ci.draw_rect(Rect2(BW, 0, W - BW, 600), Color("0000d7"))
	for k in 30:
		var x := BW + 40.0 + (k * 97) % int(W - BW - 60.0)
		var y := 30.0 + (k * 53) % 200
		ci.draw_rect(Rect2(x, y, 4, 4), WHITE)
	ci.draw_rect(Rect2(BW, 390, W - BW, 180), PAPER["Recreio"])
	# muro do recreio, árvore e baliza
	for x in range(int(BW), int(W), 40):
		ci.draw_rect(Rect2(x, 470, 38, 18), BRICK)
		ci.draw_rect(Rect2(x + 20, 490, 38, 18), BRICK)
	ci.draw_rect(Rect2(3300, 330, 26, 140), Color("d70000"))
	ci.draw_circle(Vector2(3313, 320), 70, Color("00d700"))
	ci.draw_circle(Vector2(3270, 350), 46, Color("00d700"))
	ci.draw_circle(Vector2(3360, 350), 46, Color("00d700"))
	ci.draw_rect(Rect2(2900, 450, 6, 120), WHITE)
	ci.draw_rect(Rect2(3060, 450, 6, 120), WHITE)
	ci.draw_rect(Rect2(2900, 450, 166, 6), WHITE)
	# salas
	for r: Dictionary in SchoolGame.ROOMS:
		if r.name == "Recreio":
			continue
		var f := int(r.floor)
		var top := floor_top(f)
		ci.draw_rect(Rect2(r.x0, top, float(r.x1) - float(r.x0), SchoolGame.ROOM_H), PAPER[r.name])
		PixelFont.draw(ci, I18n.t(String(r.name)).to_upper(), (float(r.x0) + float(r.x1)) * 0.5, top + 14, 2, BLACK)
	# telhado
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-20, 10), Vector2(BW + 30, 10), Vector2(BW + 30, -40), Vector2(-20, -40)]), BRICK)
	# pisos (lajes)
	for f in 3:
		var y: float = SchoolGame.FLOOR_Y[f]
		ci.draw_rect(Rect2(0, y, BW if f < 2 else W, 10), FLOOR)
		ci.draw_rect(Rect2(0, floor_top(f) - 10, BW, 10), FLOOR)
	ci.draw_rect(Rect2(0, 580, W, 20), BLACK)
	# paredes entre salas (com passagem por baixo)
	for r: Dictionary in SchoolGame.ROOMS:
		var f := int(r.floor)
		for x: float in [float(r.x0), float(r.x1)]:
			if x <= 0.0 or x > SchoolGame.BUILDING_W:
				continue
			var top := floor_top(f)
			var door_top := float(SchoolGame.FLOOR_Y[f]) - 112.0
			ci.draw_rect(Rect2(x - 8, top, 16, door_top - top), BRICK)
			if x >= SchoolGame.BUILDING_W and f < 2:
				ci.draw_rect(Rect2(x - 8, top, 16, SchoolGame.ROOM_H), BRICK)
	ci.draw_rect(Rect2(-4, 0, 14, 600), BRICK)
	ci.draw_rect(Rect2(BW - 8, floor_top(0) - 10, 16, 2 * SchoolGame.ROOM_H + 10), BRICK)
	# escadas
	for s: Dictionary in SchoolGame.STAIRS:
		var f := int(s.f)
		var a := Vector2(s.top, SchoolGame.FLOOR_Y[f])
		var b := Vector2(s.bottom, SchoolGame.FLOOR_Y[f + 1])
		for k in 12:
			var p := a.lerp(b, (k + 0.5) / 12.0)
			var w := 16.0
			ci.draw_rect(Rect2(p.x - w * 0.5, p.y, w, 6), BLACK)
		ci.draw_line(a + Vector2(0, -44), b + Vector2(0, -44), BLACK, 3.0)
	# quadros e carteiras
	for i in SchoolGame.ROOMS.size():
		var r: Dictionary = SchoolGame.ROOMS[i]
		var y: float = SchoolGame.FLOOR_Y[int(r.floor)]
		if r.board:
			var bx := game.board_x(i)
			ci.draw_rect(Rect2(bx - 110, y - 140, 220, 70), Color("d70000"))
			ci.draw_rect(Rect2(bx - 104, y - 134, 208, 58), BLACK)
			for k in 8:
				var sx := game.seat_x(i, k)
				ci.draw_rect(Rect2(sx - 38, y - 30, 30, 6), Color("d70000"))
				ci.draw_rect(Rect2(sx - 36, y - 24, 4, 24), Color("d70000"))
				ci.draw_rect(Rect2(sx - 6, y - 18, 14, 4), BLACK)
				ci.draw_rect(Rect2(sx + 5, y - 18, 3, 18), BLACK)
		elif r.name == "Refeitório":
			for k in 3:
				ci.draw_rect(Rect2(float(r.x0) + 260 + k * 250, y - 34, 190, 8), Color("d70000"))
				ci.draw_rect(Rect2(float(r.x0) + 270 + k * 250, y - 26, 6, 26), Color("d70000"))
				ci.draw_rect(Rect2(float(r.x0) + 434 + k * 250, y - 26, 6, 26), Color("d70000"))
		elif r.name == "Gabinete do Diretor":
			ci.draw_rect(Rect2(1900, y - 40, 160, 10), Color("d7d700"))
			ci.draw_rect(Rect2(1910, y - 30, 8, 30), Color("d7d700"))
			ci.draw_rect(Rect2(2042, y - 30, 8, 30), Color("d7d700"))
			ci.draw_rect(Rect2(2160, y - 150, 90, 70), WHITE)
			ci.draw_rect(Rect2(2166, y - 144, 78, 58), Color("0000d7"))
		elif r.name == "Átrio":
			for k in 8:
				ci.draw_rect(Rect2(1500 + k * 44, y - 100, 40, 100), Color("0000d7"))
				ci.draw_rect(Rect2(1500 + k * 44 + 30, y - 60, 4, 10), WHITE)
	# janelas nas paredes de fora
	for f in 2:
		var y := floor_top(f) + 40
		ci.draw_rect(Rect2(BW - 4, y, 8, 70), Color("0000d7"))


func _draw_board_text(p: Vector2, text: String) -> void:
	PixelFont.draw(self, text, p.x, p.y - 4, 3, WHITE)


func _draw_shield(p: Vector2, hit: bool, i: int) -> void:
	var on := hit and int(time * 4.0 + i) % 2 == 0
	var body := Color("d70000") if not on else Color("ffff00")
	var pts := PackedVector2Array([p + Vector2(-14, -16), p + Vector2(14, -16), p + Vector2(14, 2), p + Vector2(0, 18), p + Vector2(-14, 2)])
	draw_colored_polygon(pts, body)
	pts.append(pts[0])
	draw_polyline(pts, BLACK, 3.0)
	draw_line(p + Vector2(0, -16), p + Vector2(0, 16), Color("0000d7") if not on else BLACK, 4.0)
	draw_line(p + Vector2(-14, -4), p + Vector2(14, -4), Color("0000d7") if not on else BLACK, 4.0)


func _draw_safe(p: Vector2, open: bool) -> void:
	var r := Rect2(p.x - 34, p.y - 78, 68, 78)
	draw_rect(r, Color("0000d7"))
	draw_rect(r, BLACK, false, 3.0)
	if open:
		draw_rect(r.grow(-8), BLACK)
		draw_rect(Rect2(r.position.x - 30, r.position.y + 8, 30, r.size.y - 16), Color("0000d7"))
		draw_rect(Rect2(r.position.x + 18, r.position.y + 40, 30, 22), WHITE)
	else:
		draw_circle(r.get_center(), 14, WHITE)
		draw_circle(r.get_center(), 9, BLACK)
		draw_line(r.get_center(), r.get_center() + Vector2.from_angle(time * 0.7) * 9.0, WHITE, 2.0)
	PixelFont.draw(self, I18n.t("COFRE"), p.x, r.position.y - 16, 2, BLACK)


func _limb(a: Vector2, b: Vector2, w: float) -> void:
	draw_line(a, b, BLACK, w)


func _draw_person(c: Dictionary, j: Dictionary) -> void:
	var s: float = j.s
	var f: float = j.f
	var w := 5.0 * s
	_limb(j.hip, j.knee_b, w)
	_limb(j.knee_b, j.foot_b, w)
	_limb(j.neck, j.elbow_b, w * 0.8)
	_limb(j.elbow_b, j.hand_b, w * 0.8)
	var hip: Vector2 = j.hip
	var neck: Vector2 = j.neck
	var side := (neck - hip).orthogonal().normalized()
	if c.role == "teacher":
		# beca
		var knee: Vector2 = (j.knee_f + j.knee_b) * 0.5
		var kside := side * 13.0 * s
		draw_colored_polygon(PackedVector2Array([neck + side * 9.0 * s, neck - side * 9.0 * s, knee - kside + (knee - neck) * 0.15, knee + kside + (knee - neck) * 0.15]), BLACK)
	else:
		draw_colored_polygon(PackedVector2Array([neck + side * 7.0 * s, neck - side * 7.0 * s, hip - side * 7.0 * s, hip + side * 7.0 * s]), BLACK)
	_limb(j.hip, j.knee_f, w)
	_limb(j.knee_f, j.foot_f, w)
	_limb(j.foot_f, j.foot_f + Vector2(f * 6, 0).rotated(0.0), w)
	_limb(j.neck, j.elbow_f, w * 0.8)
	_limb(j.elbow_f, j.hand_f, w * 0.8)
	var head: Vector2 = j.head
	draw_circle(head, 9.5 * s, BLACK)
	draw_circle(head + Vector2(f * 3.0, -1.0), 2.2 * s, WHITE)
	if c.role == "teacher":
		# barrete
		var up := (head - neck).normalized()
		var t := head + up * 9.0 * s
		var sd := up.orthogonal() * 14.0 * s
		draw_line(t - sd, t + sd, BLACK, 5.0)
		draw_rect(Rect2(t - Vector2(5, 5) * s, Vector2(10, 7) * s), BLACK)
	elif c.role == "hero":
		# boné com pala
		var up := (head - neck).normalized()
		draw_line(head + up * 8.0 * s, head + up * 8.0 * s + up.orthogonal() * -f * 13.0, BLACK, 4.0)
	elif c.role == "swot":
		draw_arc(head + Vector2(f * 3.0, -1.0), 4.5, 0, TAU, 10, WHITE, 1.5)
	if c.role == "hero" and game.is_down(c) == false and fmod(time, 1.0) < 0.5 and game.state == SchoolGame.State.LEVEL:
		draw_circle(head, 14, Color(1, 1, 0, 0.4))


func _draw_pellet(p: Vector2, _dir: int) -> void:
	draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), BLACK)


func _draw_bubble(p: Vector2, text: String, _teacher: bool) -> void:
	var ls := wrap_text(text, 20)
	var w := 0.0
	for l in ls:
		w = maxf(w, PixelFont.width(l, 2.0))
	var h := ls.size() * 18.0 + 10.0
	var r := Rect2(p.x - w * 0.5 - 8, p.y - h, w + 16, h)
	r.position.x = clampf(r.position.x, 4, 1276 - r.size.x)
	r.position.y = maxf(r.position.y, 4)
	draw_rect(r, WHITE)
	draw_rect(r, BLACK, false, 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(p.x - 6, r.end.y - 2), Vector2(p.x + 6, r.end.y - 2), Vector2(p.x, r.end.y + 10)]), WHITE)
	for i in ls.size():
		PixelFont.draw(self, ls[i], r.get_center().x, r.position.y + 6 + i * 18.0, 2, BLACK)


func _draw_hud() -> void:
	var g := game
	draw_rect(Rect2(0, 600, 1280, 120), BLACK)
	PixelFont.draw(self, period_text(), 400, 612, 3, Color("ffff00"))
	draw_rect(Rect2(110, 642, 580, 10), Color("0000d7"))
	draw_rect(Rect2(110, 642, 580 * period_left(), 10), Color("00ffff"))
	PixelFont.draw(self, I18n.t("DIA %d") % g.day, 60, 640, 2, WHITE)
	PixelFont.draw(self, I18n.t("ESCUDOS %d/%d") % [g.shields_done(), SchoolGame.SHIELDS.size()], 200, 668, 3, Color("00ffff"))
	PixelFont.draw(self, I18n.t("COFRE  ") + code_text(), 560, 668, 3, WHITE)
	PixelFont.draw(self, I18n.t("LINHAS %d") % g.lines, 960, 612, 3, Color("ff0000"))
	draw_rect(Rect2(820, 642, 280, 10), Color("5a0000"))
	draw_rect(Rect2(820, 642, 280.0 * g.lines / SchoolGame.MAX_LINES, 10), Color("ff0000"))
	PixelFont.draw(self, I18n.t("PONTOS %d") % g.score, 960, 668, 3, Color("00ff00"))
	PixelFont.draw(self, I18n.t("RECORDE %d") % maxi(g.best, g.score), 960, 698, 2, Color("d7d7d7"))
	if g.state == SchoolGame.State.OVER:
		draw_rect(Rect2(340, 230, 600, 120), BLACK)
		draw_rect(Rect2(340, 230, 600, 120), Color("ff0000"), false, 4.0)
		PixelFont.draw(self, I18n.t("EXPULSO!"), 640, 262, 7, Color("ff0000"))


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0, 0, 0, 0.95),
		"border": Color("ffff00"),
		"text": Color("ffffff"),
		"accent": Color("00ffff"),
		"button": Color("0000d7"),
		"button_hover": Color("d700d7"),
		"radius": 0,
		"dim": Color(0, 0, 0, 0.45),
	}
