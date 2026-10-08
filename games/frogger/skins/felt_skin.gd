extends FroggerSkin
## Feltro (estilo próprio): o jogo como um livro de atividades em feltro. Peças recortadas
## com pespontos à vista, botões a fazer de olhos e de rodas, um rio de feltro azul com
## ondas cosidas e painéis em retalhos. Sons de brinquedo: apitos, xilofone e caixa de música.

const SHADOW := Color(0.1, 0.06, 0.02, 0.28)
const THREAD := Color("fff8e7")
const FELT_GREEN := Color("4f9d4a")
const FELT_DGREEN := Color("2f6b33")
const FELT_BLUE := Color("3b6fb6")
const FELT_DBLUE := Color("234a85")
const FELT_GREY := Color("6b6f78")
const FELT_SAND := Color("e6b866")
const FELT_BROWN := Color("8a5a36")
const FELT_TURTLE := Color("6aa84f")
const FELT_TEXT := Color("3a2a1a")
const VEHICLE := {
	"car_a": {"body": Color("f2c94c"), "cabin": Color("fbe7a1"), "window": Color("a8d8f0")},
	"dozer": {"body": Color("e8833a"), "cabin": Color("f6c08f"), "window": Color("a8d8f0"), "blade": Color("9aa0a6")},
	"car_b": {"body": Color("e46c9a"), "cabin": Color("f7c1d6"), "window": Color("a8d8f0")},
	"racer": {"body": Color("d64545"), "cabin": Color("f3f3f3"), "window": Color("a8d8f0"), "light": Color("fff1a8")},
	"truck": {"body": Color("5aa9e6"), "cabin": Color("d64545"), "window": Color("a8d8f0")},
}

var font: Font
var bg_vp: SubViewport
var bg: Node2D


func _setup() -> void:
	font = ThemeDB.fallback_font
	bg_vp = SubViewport.new()
	bg_vp.size = Vector2i(1280, 720)
	bg_vp.disable_3d = true
	bg_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(bg_vp)
	bg = Node2D.new()
	bg_vp.add_child(bg)
	bg.draw.connect(_draw_background)


# ---------------------------------------------------------------- sons

static func _pluck(f: float, dur: float, vol: float) -> PackedFloat32Array:
	return Synth.mix([
		Synth.render(f, dur, {"wave": "triangle", "volume": vol, "decay": 6.0 / dur}),
		Synth.render(f * 3.0, dur * 0.4, {"wave": "sine", "volume": vol * 0.25, "decay": 14.0 / dur}),
	])


func _build_sfx() -> void:
	sfx.hop = Synth.tone(700.0, 0.09, {"wave": "sine", "freq_end": 1300.0, "volume": 0.3, "decay": 18.0})
	var xylo := []
	for f in [1046.5, 1318.5, 1568.0, 2093.0]:
		xylo.append(_pluck(f, 0.12, 0.2))
	sfx.home = Synth.concat(xylo)
	sfx.fly = Synth.to_stream(_pluck(2637.0, 0.4, 0.15))
	sfx.squash = Synth.to_stream(Synth.mix([
		Synth.render(1300.0, 0.35, {"wave": "sine", "freq_end": 280.0, "volume": 0.3, "decay": 5.0}),
		Synth.render(0.0, 0.12, {"wave": "noise", "volume": 0.2, "lowpass": 0.1, "decay": 30.0}),
	]))
	var plop := [Synth.render(0.0, 0.25, {"wave": "noise", "volume": 0.25, "lowpass": 0.15, "decay": 14.0})]
	for i in 4:
		var s := Synth.silence(0.1 + i * 0.07)
		s.append_array(Synth.render(500.0 + i * 160.0, 0.06, {"wave": "sine", "freq_end": 1000.0 + i * 200.0, "volume": 0.15, "decay": 30.0}))
		plop.append(s)
	sfx.splash = Synth.to_stream(Synth.mix(plop))
	var ticks := []
	for i in 4:
		ticks.append(Synth.render(1500.0 if i % 2 == 0 else 1100.0, 0.04, {"wave": "sine", "volume": 0.2, "decay": 60.0}))
		ticks.append(Synth.silence(0.14))
	sfx.warn = Synth.concat(ticks)
	sfx.extra = Synth.concat([_pluck(1568.0, 0.18, 0.2), _pluck(2093.0, 0.4, 0.2)])
	var piano := []
	for f in [523.3, 659.3, 784.0, 1046.5, 784.0, 1046.5, 1318.5]:
		piano.append(_pluck(f, 0.13, 0.2))
	sfx.clear = Synth.concat(piano)
	var box := []
	for f in [784.0, 659.3, 523.3, 659.3, 784.0, 784.0, 880.0, 784.0, 659.3, 587.3, 659.3, 523.3]:
		box.append(_pluck(f, 0.26, 0.07))
	sfx.music = Synth.concat(box)


# ---------------------------------------------------------------- ajudas de costura

func _stitch_line(ci: CanvasItem, a: Vector2, b: Vector2, c := THREAD, w := 1.6) -> void:
	ci.draw_dashed_line(a, b, c, w, 5.0)


func _stitch_rect(ci: CanvasItem, r: Rect2, c := THREAD, inset := 4.0) -> void:
	var q := r.grow(-inset)
	if q.size.x <= 2 or q.size.y <= 2:
		return
	_stitch_line(ci, q.position, Vector2(q.end.x, q.position.y), c)
	_stitch_line(ci, Vector2(q.end.x, q.position.y), q.end, c)
	_stitch_line(ci, q.end, Vector2(q.position.x, q.end.y), c)
	_stitch_line(ci, Vector2(q.position.x, q.end.y), q.position, c)


func _stitch_circle(ci: CanvasItem, center: Vector2, r: float, c := THREAD) -> void:
	var n := maxi(8, int(r * 0.9))
	for i in n:
		if i % 2 == 0:
			var a0 := TAU * i / n
			var a1 := TAU * (i + 1) / n
			ci.draw_line(center + Vector2.from_angle(a0) * r, center + Vector2.from_angle(a1) * r, c, 1.6, true)


func _button(ci: CanvasItem, center: Vector2, r: float, c: Color) -> void:
	ci.draw_circle(center + Vector2(1, 2), r, SHADOW, true, -1.0, true)
	ci.draw_circle(center, r, c, true, -1.0, true)
	ci.draw_arc(center, r * 0.75, 0, TAU, 16, c.darkened(0.25), 1.0, true)
	ci.draw_circle(center + Vector2(-r * 0.3, 0), r * 0.16, c.darkened(0.6), true, -1.0, true)
	ci.draw_circle(center + Vector2(r * 0.3, 0), r * 0.16, c.darkened(0.6), true, -1.0, true)


func _felt_rect(ci: CanvasItem, r: Rect2, c: Color, radius := 6, stitch := true) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	sb.bg_color = SHADOW
	ci.draw_style_box(sb, Rect2(r.position + Vector2(2, 3), r.size))
	sb.bg_color = c
	ci.draw_style_box(sb, r)
	if stitch:
		_stitch_rect(ci, r, c.lightened(0.45), 3.5)


# ---------------------------------------------------------------- fundo

func _draw_background() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	# retalhos nas laterais
	var patches := [Color("c96f5b"), Color("e3b04b"), Color("7fb069"), Color("6c9bd2"), Color("b07cc6"), Color("e8a0a0")]
	for y in range(0, 720, 80):
		for x in range(0, 1280, 76):
			var r := Rect2(x, y, 76, 80)
			bg.draw_rect(r, patches[rng.randi() % patches.size()].darkened(rng.randf_range(0.0, 0.15)))
			_stitch_rect(bg, r, Color(THREAD, 0.7), 5.0)
	var f := field_rect()
	bg.draw_rect(f.grow(10), Color("3b2a1a"))
	# regiões do tabuleiro
	var fills := {0: FELT_DGREEN, 6: FELT_SAND, 12: FELT_SAND, 13: Color("4a3a2a")}
	for row in range(0, 14):
		var rr := row_rect(row)
		var c: Color = fills.get(row, FELT_BLUE if row <= 5 else FELT_GREY)
		bg.draw_rect(rr, c)
	# fibras do feltro
	for i in 4000:
		var p := Vector2(rng.randf_range(f.position.x, f.end.x), rng.randf_range(f.position.y, f.end.y))
		var col := Color(1, 1, 1, rng.randf_range(0.03, 0.08)) if rng.randf() < 0.5 else Color(0, 0, 0, rng.randf_range(0.03, 0.08))
		bg.draw_line(p, p + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(1.5, 4.0), col, 1.0)
	# ondas cosidas no rio
	for row in range(1, 6):
		var rr := row_rect(row)
		for k in 2:
			var y := rr.position.y + rr.size.y * (0.3 + 0.4 * k)
			var x := rr.position.x
			while x < rr.end.x:
				bg.draw_arc(Vector2(x + 10, y), 10.0, PI, TAU, 6, Color(THREAD, 0.35), 1.4, true)
				x += 32.0
	# estrada: traços a meio das faixas
	for row in range(7, 11):
		var y := row_rect(row).end.y
		_stitch_line(bg, Vector2(f.position.x, y), Vector2(f.end.x, y), Color("f2d16b"), 2.0)
	for row in [6, 12]:
		_stitch_rect(bg, row_rect(row), Color("8a5a36"), 4.0)
	# sebe com recortes ondulados e as 5 tocas
	var top := row_rect(0)
	for x in range(0, int(top.size.x), 24):
		bg.draw_circle(Vector2(top.position.x + x + 12, top.end.y), 12.0, FELT_DGREEN, true, -1.0, true)
	for i in 5:
		var br := bay_rect(i)
		bg.draw_circle(br.get_center() + Vector2(0, 4), 26.0, FELT_DBLUE, true, -1.0, true)
		_stitch_circle(bg, br.get_center() + Vector2(0, 4), 22.0, Color(THREAD, 0.8))
	_stitch_rect(bg, f.grow(6), Color(THREAD, 0.6), 0.0)
	# etiquetas para os textos
	for cx in [panel_left_x(), panel_right_x()]:
		var lab := Rect2(cx - 120, 40, 240, 290)
		bg.draw_rect(Rect2(lab.position + Vector2(4, 5), lab.size), SHADOW)
		bg.draw_rect(lab, Color("f6ecd6"))
		_stitch_rect(bg, lab, Color("b0453a"), 6.0)
	var lab2 := Rect2(panel_left_x() - 120, 480, 240, 170)
	bg.draw_rect(Rect2(lab2.position + Vector2(4, 5), lab2.size), SHADOW)
	bg.draw_rect(lab2, Color("f6ecd6"))
	_stitch_rect(bg, lab2, Color("b0453a"), 6.0)


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var g := game
	draw_texture(bg_vp.get_texture(), Vector2.ZERO)
	for o in g.objects:
		match o.kind:
			"log":
				var r := obj_rect(o).grow_individual(-1, -4, -1, -4)
				_felt_rect(self, r, FELT_BROWN, 12)
				for k in o.len:
					var cx: float = r.position.x + (k + 0.5) * r.size.x / o.len
					draw_arc(Vector2(cx, r.get_center().y), 6.0, 0, TAU, 12, FELT_BROWN.darkened(0.3), 1.4, true)
			"turtle":
				for sh in turtle_shells(o):
					var rad: float = sh[1]
					var c: Vector2 = sh[0]
					if rad <= 0.0:
						draw_circle(c, 6.0, Color(THREAD, 0.25), true, -1.0, true)
						continue
					var left: bool = g.lane_speed(o.row) < 0.0
					draw_circle(c + Vector2((-rad - 2) if left else (rad + 2), 0), 6.0, FELT_TURTLE.lightened(0.15), true, -1.0, true)
					draw_circle(c + Vector2(2, 3), rad, SHADOW, true, -1.0, true)
					draw_circle(c, rad, FELT_TURTLE, true, -1.0, true)
					_stitch_circle(self, c, rad * 0.62, FELT_TURTLE.lightened(0.5))
			_:
				_draw_vehicle(o)
	for i in 5:
		var c := bay_rect(i).get_center() + Vector2(0, 4)
		if g.homes[i]:
			_draw_frog(c, 0.0, 0.85, false)
		elif g.fly_bay == i:
			draw_ellipse_like(c + Vector2(-7, -4), Vector2(8, 5), Color("dcefff", 0.9))
			draw_ellipse_like(c + Vector2(7, -4), Vector2(8, 5), Color("dcefff", 0.9))
			draw_circle(c, 6.0, Color("2b2b2b"), true, -1.0, true)
		elif g.croc_bay == i:
			_draw_croc(c)
	if g.state == FroggerGame.State.DYING:
		_draw_death()
	elif g.state in [FroggerGame.State.PLAY, FroggerGame.State.READY]:
		var hop := 1.12 if g.hop_t >= 0.0 else 1.0
		_draw_frog(px(g.frog_center()), frog_angle(), hop, g.hop_t >= 0.0)
	for p in popups:
		_text(p.text, p.pos, 22, Color("fff8e7"), true)
	for r in side_rects():
		var rr := r.intersection(Rect2(0, 0, 1280, 720))
		draw_texture_rect_region(bg_vp.get_texture(), rr, rr)
	_draw_hud()


func draw_ellipse_like(c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		pts.append(c + Vector2(cos(TAU * i / 16) * r.x, sin(TAU * i / 16) * r.y))
	draw_colored_polygon(pts, col)


func _draw_vehicle(o: Dictionary) -> void:
	var pal: Dictionary = VEHICLE[o.kind]
	var parts := vehicle_parts(o)
	var r := obj_rect(o)
	draw_rect(Rect2(r.position + Vector2(3, 5), r.size - Vector2(0, 2)), SHADOW)
	for part in parts:
		var role: String = part[1]
		var pr: Rect2 = part[0]
		match role:
			"wheel":
				_button(self, pr.get_center(), 6.0, Color("3a3a3a"))
			"body", "cabin":
				_felt_rect(self, pr, pal[role], 5, role == "body")
			"window":
				_felt_rect(self, pr, pal.window, 2, false)
			"blade":
				_felt_rect(self, pr, pal.get("blade", Color.GRAY), 2, false)
			"light":
				draw_circle(pr.get_center(), 4.0, pal.get("light", Color.WHITE), true, -1.0, true)


func _draw_frog(c: Vector2, angle: float, scale: float, jumping: bool) -> void:
	draw_set_transform(c, angle, Vector2.ONE * scale)
	var legs := 9.0 if jumping else 6.0
	for s in [-1.0, 1.0]:
		draw_circle(Vector2(s * 12, legs), 6.0, FELT_GREEN.darkened(0.2), true, -1.0, true)
		draw_circle(Vector2(s * 11, -8), 4.5, FELT_GREEN.darkened(0.2), true, -1.0, true)
	draw_circle(Vector2(2, 3), 13.0, SHADOW, true, -1.0, true)
	draw_circle(Vector2.ZERO, 13.0, Color("63b84f"), true, -1.0, true)
	draw_circle(Vector2(0, 4), 7.0, Color("c7e59a"), true, -1.0, true)
	_stitch_circle(self, Vector2.ZERO, 10.5, Color("c7e59a"))
	for s in [-1.0, 1.0]:
		draw_circle(Vector2(s * 6, -10), 5.0, Color.WHITE, true, -1.0, true)
		draw_circle(Vector2(s * 6, -11), 2.3, Color("1b1b1b"), true, -1.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_croc(c: Vector2) -> void:
	var pts := PackedVector2Array([c + Vector2(-20, 10), c + Vector2(-20, -6), c + Vector2(-10, -14), c + Vector2(18, -8), c + Vector2(22, 10)])
	draw_colored_polygon(shifted(pts, Vector2(2, 3)), SHADOW)
	draw_colored_polygon(pts, Color("3f7f3a"))
	for k in 5:
		var x := -14.0 + k * 7.0
		draw_colored_polygon(PackedVector2Array([c + Vector2(x, 2), c + Vector2(x + 3.5, 8), c + Vector2(x + 7, 2)]), Color.WHITE)
	_button(self, c + Vector2(-8, -7), 4.0, Color("f2c94c"))


static func shifted(pts: PackedVector2Array, d: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p + d)
	return out


func _draw_death() -> void:
	var c := px(game.frog_center())
	var k := 1.0 - game.timer / 1.6
	if game.death_cause == "agua":
		for i in 3:
			var t := fmod(k + i * 0.33, 1.0)
			_stitch_circle(self, c, 6.0 + 24.0 * t, Color(THREAD, 1.0 - t))
	else:
		# rã de feltro achatada, com olhos em cruz
		draw_set_transform(c, 0.0, Vector2(1.5, 0.5))
		draw_circle(Vector2.ZERO, 13.0, Color("63b84f"), true, -1.0, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for s in [-1.0, 1.0]:
			var e := c + Vector2(s * 9, -2)
			draw_line(e - Vector2(3, 3), e + Vector2(3, 3), Color("1b1b1b"), 2.0)
			draw_line(e - Vector2(3, -3), e + Vector2(3, -3), Color("1b1b1b"), 2.0)


func _draw_hud() -> void:
	var g := game
	draw_rect(field_rect().grow(5), Color("3b2a1a"), false, 10.0)
	_stitch_rect(self, field_rect().grow(6), Color(THREAD, 0.6), 0.0)
	var lx := panel_left_x()
	var rx := panel_right_x()
	var a0 := 1.0 if (g.current == 0 or g.players.size() == 1) else 0.45
	_text(I18n.t("JOGADOR 1"), Vector2(lx, 90), 20, Color(FELT_TEXT, a0))
	_text(str(g.players[0].score), Vector2(lx, 146), 46, Color("b0453a", a0))
	_text(I18n.t("RECORDE"), Vector2(lx, 222), 18, FELT_TEXT)
	_text(str(maxi(g.best, g.player().score)), Vector2(lx, 270), 34, Color("3b6fb6"))
	if g.players.size() > 1:
		_text(I18n.t("JOGADOR 2"), Vector2(rx, 90), 20, Color(FELT_TEXT, 1.0 if g.current == 1 else 0.45))
		_text(str(g.players[1].score), Vector2(rx, 146), 46, Color("b0453a", 1.0 if g.current == 1 else 0.45))
		_text(I18n.t("NÍVEL %d") % g.level(), Vector2(rx, 250), 26, FELT_TEXT)
	else:
		_text(I18n.t("NÍVEL"), Vector2(rx, 110), 20, FELT_TEXT)
		_text(str(g.level()), Vector2(rx, 186), 64, Color("4f9d4a"))
	_text(I18n.t("VIDAS"), Vector2(lx, 520), 18, FELT_TEXT)
	var n := mini(maxi(g.player().lives, 0), 6)
	for i in n:
		_draw_frog(Vector2(lx - (mini(n, 3) - 1) * 30.0 + (i % 3) * 60.0, 566 + (i / 3) * 52), 0.0, 0.8, false)
	# tempo: fita de feltro
	var hud := row_rect(13)
	var frac := clampf(g.time_left / g.time_limit(), 0.0, 1.0)
	var bar := Rect2(hud.end.x - 16 - 430 * frac, hud.position.y + 12, 430 * frac, 22)
	if bar.size.x > 6:
		_felt_rect(self, bar, Color("7fb069") if g.time_left > 8.0 else Color("d64545"), 4)
	_text(I18n.t("TEMPO"), Vector2(hud.end.x - 500, hud.position.y + 31), 18, Color("f6ecd6"))


func _text(text: String, pos: Vector2, size: int, c: Color, outline := false) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := Vector2(pos.x - w / 2, pos.y)
	if outline:
		draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color(FELT_TEXT, 0.8 * c.a))
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)


func ui_palette() -> Dictionary:
	return {
		"panel": Color("f6ecd6"),
		"border": Color("b0453a"),
		"text": FELT_TEXT,
		"accent": Color("b0453a"),
		"button": Color("efe0bf"),
		"button_hover": Color("f3d0a8"),
		"radius": 12,
		"dim": Color(0.2, 0.1, 0.05, 0.25),
	}
