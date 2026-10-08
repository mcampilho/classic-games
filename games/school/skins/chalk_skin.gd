extends SchoolSkin
## Giz no Quadro: a escola inteira desenhada a giz num quadro de ardósia verde — traços tremidos
## e falhados, giz branco, amarelo, cor-de-rosa e azul, marcas de apagador, bonecos de pauzinhos
## (o Zé a amarelo, os professores de beca a cor-de-rosa) e um parapeito de madeira com o painel.

const BOARD := Color("23382c")
const CHALK := Color("eef0e6")
const YELLOW := Color("f4e27a")
const PINK := Color("f2a0b8")
const BLUE := Color("9ccaf0")
const KID_COLS := {"hero": YELLOW, "bully": PINK, "swot": BLUE, "tearaway": Color("b8e88a"), "kid": CHALK, "teacher": PINK}

var font: Font


func _setup() -> void:
	font = ThemeDB.fallback_font


func _build_sfx() -> void:
	# guinchos de giz, toques de campainha e um apagador
	sfx.bell = Synth.tone(1300.0, 0.9, {"wave": "triangle", "volume": 0.2, "decay": 3.0})
	sfx.lines = Synth.tone(2600.0, 0.25, {"wave": "sine", "freq_end": 3200.0, "volume": 0.08, "decay": 6.0})
	sfx.shield = Synth.tone(0.0, 0.15, {"wave": "noise", "volume": 0.25, "lowpass": 0.7, "decay": 18.0})
	var a := []
	for f in [784.0, 988.0, 1175.0, 1568.0]:
		a.append(Synth.render(f, 0.1, {"wave": "triangle", "volume": 0.2, "decay": 8.0}))
	sfx.all = Synth.concat(a)
	sfx.letter = Synth.concat([Synth.render(1175.0, 0.1, {"wave": "triangle", "volume": 0.2}), Synth.render(1568.0, 0.2, {"wave": "triangle", "volume": 0.2, "decay": 6.0})])
	var s := []
	for f in [523.0, 659.0, 784.0, 1046.0, 784.0, 1046.0, 1318.0]:
		s.append(Synth.render(f, 0.12, {"wave": "triangle", "volume": 0.2, "decay": 5.0}))
	sfx.safe = Synth.concat(s)
	sfx.knock = Synth.tone(0.0, 0.25, {"wave": "noise", "volume": 0.3, "lowpass": 0.15, "decay": 12.0})
	sfx.fire = Synth.tone(0.0, 0.08, {"wave": "noise", "volume": 0.2, "lowpass": 0.9, "decay": 40.0})
	sfx.punch = Synth.tone(90.0, 0.1, {"wave": "sine", "volume": 0.4, "decay": 30.0})
	sfx.jump = Synth.tone(600.0, 0.15, {"wave": "sine", "freq_end": 1100.0, "volume": 0.15, "decay": 10.0})
	sfx.expelled = Synth.tone(3000.0, 0.9, {"wave": "sine", "freq_end": 1800.0, "volume": 0.08})


## Traço de giz: várias passagens, falhas e grão.
func chalk_line(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float, seed := 0) -> void:
	var n := maxi(int(a.distance_to(b) / 18.0), 1)
	for pass_i in 2:
		var off := Vector2(hash01(seed, pass_i, 1) - 0.5, hash01(seed, pass_i, 2) - 0.5) * 2.0
		for i in n:
			if hash01(seed + i, pass_i, 3) < 0.08:
				continue
			var p0 := a.lerp(b, float(i) / n) + off
			var p1 := a.lerp(b, float(i + 1) / n) + off
			ci.draw_line(p0, p1, Color(col, (0.75 if pass_i == 0 else 0.35) * (0.8 + hash01(seed + i, pass_i, 4) * 0.2)), w * (1.0 if pass_i == 0 else 0.6))


static func hash01(x: int, y: int, s: int) -> float:
	var h := (x * 374761393 + y * 668265263 + s * 974634187) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h & 0xffff) / 65535.0


func chalk_rect(ci: CanvasItem, r: Rect2, col: Color, w: float, seed := 0) -> void:
	chalk_line(ci, r.position, Vector2(r.end.x, r.position.y), col, w, seed)
	chalk_line(ci, Vector2(r.end.x, r.position.y), r.end, col, w, seed + 1)
	chalk_line(ci, r.end, Vector2(r.position.x, r.end.y), col, w, seed + 2)
	chalk_line(ci, Vector2(r.position.x, r.end.y), r.position, col, w, seed + 3)


func chalk_text(ci: CanvasItem, text: String, c: Vector2, size: int, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := Vector2(c.x - w * 0.5, c.y + size * 0.35)
	ci.draw_string(font, p + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(col, 0.35))
	ci.draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(col, 0.85))


func _draw_back() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), BOARD)


func _paint_world(ci: CanvasItem) -> void:
	var W := SchoolGame.WORLD_W
	var BW := SchoolGame.BUILDING_W
	ci.draw_rect(Rect2(0, 0, W, 600), BOARD)
	# marcas de apagador
	for k in 40:
		var p := Vector2(hash01(k, 1, 5) * W, hash01(k, 2, 5) * 600.0)
		ci.draw_circle(p, 40.0 + hash01(k, 3, 5) * 70.0, Color(1, 1, 1, 0.014))
	# telhado
	chalk_line(ci, Vector2(0, 8), Vector2(BW / 2, -30), CHALK, 3.0, 1)
	chalk_line(ci, Vector2(BW / 2, -30), Vector2(BW, 8), CHALK, 3.0, 2)
	for f in 3:
		var y: float = SchoolGame.FLOOR_Y[f]
		chalk_line(ci, Vector2(0, y + 2), Vector2(BW if f < 2 else W, y + 2), CHALK, 4.0, 10 + f)
		chalk_line(ci, Vector2(0, floor_top(f) - 4), Vector2(BW, floor_top(f) - 4), CHALK, 3.0, 20 + f)
	chalk_line(ci, Vector2(6, 0), Vector2(6, 580), CHALK, 4.0, 30)
	chalk_line(ci, Vector2(BW, 0), Vector2(BW, SchoolGame.FLOOR_Y[1] + 4), CHALK, 4.0, 31)
	for r: Dictionary in SchoolGame.ROOMS:
		var f := int(r.floor)
		var top := floor_top(f)
		var col: Color = [YELLOW, PINK, BLUE][f]
		chalk_text(ci, I18n.t(String(r.name)), Vector2((float(r.x0) + float(r.x1)) * 0.5, top + 18), 20, col)
		var x := float(r.x0)
		if x > 0.0 and x < BW + 1.0:
			chalk_line(ci, Vector2(x, top), Vector2(x, float(SchoolGame.FLOOR_Y[f]) - 112.0), CHALK, 4.0, int(x) + f)
	# escadas em degraus
	for s: Dictionary in SchoolGame.STAIRS:
		var f := int(s.f)
		var a := Vector2(s.top, SchoolGame.FLOOR_Y[f])
		var b := Vector2(s.bottom, SchoolGame.FLOOR_Y[f + 1])
		for k in 11:
			var p := a.lerp(b, k / 10.0)
			var q := a.lerp(b, (k + 1) / 10.0)
			if k < 10:
				chalk_line(ci, p, Vector2(q.x, p.y), CHALK, 2.5, k * 3 + f)
				chalk_line(ci, Vector2(q.x, p.y), q, CHALK, 2.5, k * 3 + f + 1)
		chalk_line(ci, a + Vector2(0, -42), b + Vector2(0, -42), Color(CHALK, 0.7), 2.0, 77 + f)
	# quadros, carteiras, mesas
	for i in SchoolGame.ROOMS.size():
		var r: Dictionary = SchoolGame.ROOMS[i]
		var y: float = SchoolGame.FLOOR_Y[int(r.floor)]
		if r.board:
			var bx := game.board_x(i)
			chalk_rect(ci, Rect2(bx - 110, y - 140, 220, 70), CHALK, 3.0, i * 11)
			chalk_rect(ci, Rect2(bx - 102, y - 132, 204, 54), Color(CHALK, 0.5), 2.0, i * 13)
			for k in 8:
				var sx := game.seat_x(i, k)
				chalk_line(ci, Vector2(sx - 40, y - 30), Vector2(sx - 8, y - 30), Color("d8b48a"), 3.0, k + i * 9)
				chalk_line(ci, Vector2(sx - 36, y - 30), Vector2(sx - 36, y), Color("d8b48a"), 2.5, k + i * 9 + 1)
				chalk_line(ci, Vector2(sx - 12, y - 30), Vector2(sx - 12, y), Color("d8b48a"), 2.5, k + i * 9 + 2)
				chalk_line(ci, Vector2(sx - 6, y - 17), Vector2(sx + 8, y - 17), CHALK, 2.0, k + i * 9 + 3)
				chalk_line(ci, Vector2(sx + 8, y - 34), Vector2(sx + 8, y), CHALK, 2.0, k + i * 9 + 4)
		elif r.name == "Refeitório":
			for k in 3:
				var x0 := float(r.x0) + 260 + k * 250
				chalk_line(ci, Vector2(x0, y - 34), Vector2(x0 + 190, y - 34), Color("d8b48a"), 4.0, k)
				chalk_line(ci, Vector2(x0 + 12, y - 34), Vector2(x0 + 12, y), Color("d8b48a"), 3.0, k + 5)
				chalk_line(ci, Vector2(x0 + 178, y - 34), Vector2(x0 + 178, y), Color("d8b48a"), 3.0, k + 9)
				for t in 3:
					ci.draw_arc(Vector2(x0 + 40 + t * 55, y - 40), 9, PI, TAU, 8, Color(CHALK, 0.7), 2.0)
		elif r.name == "Gabinete do Diretor":
			chalk_line(ci, Vector2(1900, y - 40), Vector2(2060, y - 40), Color("d8b48a"), 4.0, 3)
			chalk_line(ci, Vector2(1914, y - 40), Vector2(1914, y), Color("d8b48a"), 3.0, 4)
			chalk_line(ci, Vector2(2046, y - 40), Vector2(2046, y), Color("d8b48a"), 3.0, 5)
			chalk_rect(ci, Rect2(2150, y - 150, 100, 70), YELLOW, 2.5, 6)
			chalk_text(ci, I18n.t("QUADRO DE HONRA"), Vector2(2200, y - 118), 13, YELLOW)
		elif r.name == "Átrio":
			for k in 8:
				chalk_rect(ci, Rect2(1500 + k * 46, y - 100, 40, 100), BLUE, 2.0, 40 + k)
	# recreio: árvore, sol, vedação, baliza
	var gy: float = SchoolGame.FLOOR_Y[2]
	for k in 26:
		var x := BW + 20.0 + k * 40.0
		chalk_line(ci, Vector2(x, gy - 60), Vector2(x, gy), Color(CHALK, 0.6), 2.5, 200 + k)
	chalk_line(ci, Vector2(BW, gy - 45), Vector2(W, gy - 45), Color(CHALK, 0.6), 2.5, 300)
	chalk_line(ci, Vector2(3310, gy), Vector2(3310, gy - 170), Color("d8b48a"), 6.0, 301)
	for k in 9:
		var a := k * TAU / 9.0
		ci.draw_arc(Vector2(3310, gy - 210) + Vector2.from_angle(a) * 46.0, 34, 0, TAU, 14, Color("b8e88a", 0.7), 3.0)
	ci.draw_arc(Vector2(3420, 90), 40, 0, TAU, 20, Color(YELLOW, 0.85), 3.0)
	for k in 10:
		var d := Vector2.from_angle(k * TAU / 10.0)
		chalk_line(ci, Vector2(3420, 90) + d * 52.0, Vector2(3420, 90) + d * 72.0, YELLOW, 2.5, 400 + k)
	chalk_rect(ci, Rect2(2880, gy - 120, 170, 120), CHALK, 3.0, 500)
	for k in 6:
		chalk_line(ci, Vector2(2890 + k * 28, gy - 116), Vector2(2890 + k * 28, gy - 4), Color(CHALK, 0.3), 1.5, 510 + k)


func _draw_board_text(p: Vector2, text: String) -> void:
	chalk_text(self, text, p + Vector2(0, 8), 26, YELLOW)


func _draw_shield(p: Vector2, hit: bool, i: int) -> void:
	var pts := PackedVector2Array([p + Vector2(-15, -17), p + Vector2(15, -17), p + Vector2(15, 2), p + Vector2(0, 19), p + Vector2(-15, 2)])
	if hit:
		var on := int(time * 3.0 + i) % 2 == 0
		draw_colored_polygon(pts, Color(YELLOW if on else PINK, 0.55))
	for k in 5:
		chalk_line(self, pts[k], pts[(k + 1) % 5], CHALK, 2.5, i * 7 + k)
	chalk_line(self, p + Vector2(0, -15), p + Vector2(0, 15), Color(CHALK, 0.6), 2.0, i * 7 + 6)


func _draw_safe(p: Vector2, open: bool) -> void:
	var r := Rect2(p.x - 34, p.y - 78, 68, 78)
	chalk_rect(self, r, CHALK, 3.0, 900)
	if open:
		chalk_rect(self, Rect2(r.position.x - 30, r.position.y + 8, 30, r.size.y - 16), CHALK, 2.5, 910)
		chalk_rect(self, Rect2(r.position.x + 18, r.position.y + 40, 30, 22), YELLOW, 2.5, 920)
	else:
		draw_arc(r.get_center(), 13, 0, TAU, 16, Color(CHALK, 0.8), 2.5)
		chalk_line(self, r.get_center(), r.get_center() + Vector2.from_angle(time * 0.7) * 10.0, YELLOW, 2.0, 930)
	chalk_text(self, I18n.t("COFRE"), Vector2(p.x, r.position.y - 14), 16, YELLOW)


func _draw_person(c: Dictionary, j: Dictionary) -> void:
	var col: Color = KID_COLS.get(String(c.role), CHALK)
	if c.role == "teacher" and int(c.teacher) == 0:
		col = BLUE.lightened(0.3)
	var s: float = j.s
	var seed := int(c.id) * 31 + int(time * 5.0)
	var w := 3.5 * s
	for pair: Array in [["hip", "knee_b"], ["knee_b", "foot_b"], ["hip", "knee_f"], ["knee_f", "foot_f"], ["neck", "hip"],
			["neck", "elbow_b"], ["elbow_b", "hand_b"], ["neck", "elbow_f"], ["elbow_f", "hand_f"]]:
		chalk_line(self, j[pair[0]], j[pair[1]], col, w, seed)
		seed += 3
	var head: Vector2 = j.head
	draw_circle(head, 9.5 * s, BOARD)
	draw_arc(head, 9.5 * s, 0, TAU, 14, Color(col, 0.9), 2.5)
	draw_arc(head + Vector2(0.8, 0.6), 9.5 * s, 0.4, 3.0, 8, Color(col, 0.35), 1.5)
	var f: float = j.f
	draw_circle(head + Vector2(f * 3.5, -1.5), 1.6, col)
	if c.role == "teacher":
		var neck: Vector2 = j.neck
		var kn: Vector2 = (j.knee_f + j.knee_b) * 0.5
		var side := (neck - kn).orthogonal().normalized() * 12.0 * s
		chalk_line(self, neck + side * 0.5, kn + side, col, 2.5, seed)
		chalk_line(self, neck - side * 0.5, kn - side, col, 2.5, seed + 1)
		chalk_line(self, kn - side, kn + side, col, 2.5, seed + 2)
		var up := (head - neck).normalized()
		var t := head + up * 10.0 * s
		chalk_line(self, t - up.orthogonal() * 14.0, t + up.orthogonal() * 14.0, col, 3.0, seed + 3)
		chalk_line(self, t + up * 1.0, t + up * 1.0 + up.orthogonal() * -f * 4.0 - up * 0.0, col, 2.0, seed + 4)
	elif c.role == "hero":
		var up := (head - (j.neck as Vector2)).normalized()
		chalk_line(self, head + up * 8.0, head + up * 8.0 + up.orthogonal() * -f * 14.0, col, 3.0, seed + 5)
	elif c.role == "swot":
		draw_arc(head + Vector2(f * 3.5, -1.5), 4.0, 0, TAU, 10, Color(col, 0.8), 1.2)


func _draw_pellet(p: Vector2, dir: int) -> void:
	draw_circle(p, 3.5, Color(CHALK, 0.95))
	draw_line(p, p - Vector2(dir * 14, 0), Color(CHALK, 0.3), 2.0)


func _draw_bubble(p: Vector2, text: String, teacher: bool) -> void:
	var ls := wrap_text(text, 24)
	var w := 0.0
	for l in ls:
		w = maxf(w, font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x)
	var h := ls.size() * 21.0 + 14.0
	var r := Rect2(p.x - w * 0.5 - 12, p.y - h, w + 24, h)
	r.position.x = clampf(r.position.x, 4, 1276 - r.size.x)
	r.position.y = maxf(r.position.y, 4)
	draw_rect(r, Color(BOARD, 0.9))
	var col := PINK if teacher else CHALK
	chalk_rect(self, r, col, 2.5, int(r.position.x))
	chalk_line(self, Vector2(p.x - 6, r.end.y), Vector2(p.x, r.end.y + 12), col, 2.5, 3)
	chalk_line(self, Vector2(p.x + 6, r.end.y), Vector2(p.x, r.end.y + 12), col, 2.5, 4)
	for i in ls.size():
		chalk_text(self, ls[i], Vector2(r.get_center().x, r.position.y + 15 + i * 21.0), 17, CHALK)


func _draw_hud() -> void:
	var g := game
	# parapeito de madeira com pauzinhos de giz
	draw_rect(Rect2(0, 600, 1280, 120), Color("6a4628"))
	draw_rect(Rect2(0, 600, 1280, 10), Color("8a6038"))
	for k in 3:
		draw_rect(Rect2(1180 + k * 26, 604, 20, 6), [CHALK, YELLOW, PINK][k])
	chalk_text(self, period_text(), Vector2(400, 628), 22, YELLOW)
	draw_rect(Rect2(110, 648, 580, 8), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(110, 648, 580 * period_left(), 8), Color(CHALK, 0.8))
	chalk_text(self, I18n.t("DIA %d") % g.day, Vector2(56, 652), 16, CHALK)
	chalk_text(self, I18n.t("ESCUDOS %d/%d") % [g.shields_done(), SchoolGame.SHIELDS.size()], Vector2(220, 686), 22, BLUE)
	chalk_text(self, I18n.t("COFRE:  ") + code_text(), Vector2(560, 686), 22, CHALK)
	chalk_text(self, I18n.t("LINHAS %d") % g.lines, Vector2(960, 626), 24, PINK)
	draw_rect(Rect2(820, 648, 280, 8), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(820, 648, 280.0 * g.lines / SchoolGame.MAX_LINES, 8), PINK)
	chalk_text(self, I18n.t("PONTOS %d   RECORDE %d") % [g.score, maxi(g.best, g.score)], Vector2(960, 686), 20, CHALK)
	if g.state == SchoolGame.State.OVER:
		chalk_text(self, I18n.t("EXPULSO!"), Vector2(640, 290), 90, PINK)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(BOARD, 0.96),
		"border": CHALK,
		"text": CHALK,
		"accent": YELLOW,
		"button": Color("2e4a3a"),
		"button_hover": Color("3e5e4a"),
		"radius": 4,
		"dim": Color(0, 0, 0, 0.4),
	}
