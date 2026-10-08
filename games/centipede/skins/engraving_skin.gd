extends CentipedeSkin
## Gravura Naturalista (estilo próprio): o jogo como uma prancha de um caderno de campo do
## século XIX. Cogumelos em aguarela com tracejado a tinta sépia, uma centopeia gravada com
## patas a mexer, aranha, pulga e escorpião desenhados à pena, e um aparo que dispara gotas
## de tinta. Fichas de espécime nas laterais. Sons de pena, papel e cravo.

const PAPER := Color("efe4c8")
const PAPER_DARK := Color("d9c79c")
const INK := Color("3b2a1a")
const INK_BLUE := Color("1f2a44")
const WASH := [Color("c0392b"), Color("b9770e"), Color("d35400"), Color("8e6e53"), Color("a04000")]
const POISON := Color("6c3483")
const CENT := Color("b7950b")

var font: Font
var bg_vp: SubViewport
var bg: Node2D
var splats: Array[Dictionary] = []


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

static func _harpsichord(f: float, dur: float, vol: float) -> PackedFloat32Array:
	return Synth.mix([
		Synth.render(f, dur, {"wave": "saw", "volume": vol, "lowpass": 0.35, "decay": 7.0 / dur}),
		Synth.render(f * 2.0, dur * 0.5, {"wave": "square", "volume": vol * 0.25, "lowpass": 0.3, "decay": 14.0 / dur}),
	])


func _build_sfx() -> void:
	for i in 4:
		sfx["step%d" % i] = Synth.tone([1400.0, 1250.0, 1400.0, 1100.0][i], 0.025, {"wave": "sine", "volume": 0.12, "decay": 90.0})
	sfx.fire = Synth.tone(0.0, 0.05, {"wave": "noise", "volume": 0.12, "lowpass": 0.9, "decay": 50.0})       # pena a riscar
	sfx.kill = Synth.tone(900.0, 0.05, {"wave": "sine", "volume": 0.25, "decay": 70.0})
	sfx.kill_head = Synth.concat([Synth.render(1000.0, 0.04, {"wave": "sine", "volume": 0.25, "decay": 70.0}), Synth.silence(0.03),
		Synth.render(1300.0, 0.05, {"wave": "sine", "volume": 0.25, "decay": 70.0})])
	sfx.mushroom = Synth.tone(0.0, 0.1, {"wave": "noise", "volume": 0.15, "lowpass": 0.15, "decay": 25.0})   # papel
	var arp := []
	for f in [523.25, 659.25, 783.99, 1046.5]:
		arp.append(_harpsichord(f, 0.12, 0.12))
	sfx.creature = Synth.concat(arp)
	var tear := PackedFloat32Array()
	for k in 14:
		tear.append_array(Synth.render(0.0, 0.05, {"wave": "noise", "volume": 0.12 + k * 0.015, "lowpass": 0.1 + k * 0.05, "attack": 0.0, "release": 0.0}))
	tear.append_array(Synth.render(0.0, 0.4, {"wave": "noise", "volume": 0.3, "lowpass": 0.8, "decay": 8.0}))
	sfx.death = Synth.to_stream(tear)                                                                     # página a rasgar
	sfx.repair = Synth.tone(0.0, 0.03, {"wave": "noise", "volume": 0.1, "lowpass": 0.6, "decay": 80.0})
	sfx.extra = Synth.to_stream(Synth.mix([
		Synth.render(1568.0, 0.8, {"wave": "sine", "volume": 0.2, "decay": 4.0}),
		Synth.render(1568.0 * 2.76, 0.5, {"wave": "sine", "volume": 0.08, "decay": 8.0}),
	]))
	var flourish := []
	for f in [392.0, 493.9, 587.3, 784.0, 587.3, 784.0]:
		flourish.append(_harpsichord(f, 0.1, 0.13))
	sfx.wave = Synth.concat(flourish)
	var pizz := []
	for f in [196.0, 233.1, 261.6, 233.1]:
		pizz.append(Synth.render(f, 0.12, {"wave": "triangle", "volume": 0.2, "decay": 25.0}))
	sfx.spider = Synth.concat(pizz)


# ---------------------------------------------------------------- eventos

func _on_segment_killed(pos: Vector2, head: bool, points: int) -> void:
	super(pos, head, points)
	_splat(px(pos), 5 if head else 3)


func _on_creature_killed(kind: String, pos: Vector2, points: int) -> void:
	super(kind, pos, points)
	_splat(px(pos), 8)


func _on_player_hit(pos: Vector2) -> void:
	super(pos)
	_splat(px(pos), 12)


func _splat(p: Vector2, n: int) -> void:
	var blobs := []
	for i in n:
		blobs.append([Vector2.from_angle(randf() * TAU) * randf_range(0, 14.0 + n), randf_range(2.0, 6.0)])
	splats.append({"pos": p, "blobs": blobs, "life": 1.2})


func _tick(dt: float) -> void:
	for s in splats:
		s.life -= dt
	splats = splats.filter(func(s: Dictionary) -> bool: return s.life > 0.0)


# ---------------------------------------------------------------- fundo

func _draw_background() -> void:
	bg.draw_rect(Rect2(0, 0, 1280, 720), PAPER_DARK)
	var c := Vector2(640, 360)
	for i in 30:
		var k := float(i) / 29.0
		bg.draw_circle(c, lerpf(820.0, 120.0, k), PAPER_DARK.lerp(PAPER, pow(k, 0.6)), true, -1.0, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1859
	# manchas do tempo
	for i in 14:
		var p := Vector2(rng.randf() * 1280, rng.randf() * 720)
		bg.draw_circle(p, rng.randf_range(20, 70), Color(0.55, 0.4, 0.2, rng.randf_range(0.03, 0.07)), true, -1.0, true)
	for i in 2500:
		var p := Vector2(rng.randf() * 1280, rng.randf() * 720)
		bg.draw_line(p, p + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(1, 4), Color(0.4, 0.3, 0.15, rng.randf_range(0.03, 0.08)), 1.0)
	var f := field_rect()
	# quadrícula ténue do caderno
	for x in range(0, int(f.size.x) + 1, 24):
		bg.draw_line(Vector2(f.position.x + x, f.position.y), Vector2(f.position.x + x, f.end.y), Color(0.3, 0.45, 0.6, 0.07), 1.0)
	for y in range(0, int(f.size.y) + 1, 24):
		bg.draw_line(Vector2(f.position.x, f.position.y + y), Vector2(f.end.x, f.position.y + y), Color(0.3, 0.45, 0.6, 0.07), 1.0)
	var zy := f.position.y + CentipedeGame.ZONE_TOP * C * S
	bg.draw_dashed_line(Vector2(f.position.x, zy), Vector2(f.end.x, zy), Color(INK, 0.25), 1.0, 6.0)
	bg.draw_rect(f.grow(6), Color(INK, 0.8), false, 1.5)
	bg.draw_rect(f.grow(10), Color(INK, 0.5), false, 1.0)
	# fichas de espécime
	for cx in [panel_left_x(), panel_right_x()]:
		for card in [Rect2(cx - 120, 40, 240, 280), Rect2(cx - 120, 470, 240, 200)]:
			bg.draw_rect(Rect2(card.position + Vector2(3, 4), card.size), Color(0.3, 0.2, 0.1, 0.18))
			bg.draw_rect(card, Color("f8f1de"))
			bg.draw_rect(card.grow(-6), Color(INK, 0.5), false, 1.0)
			bg.draw_circle(card.position + Vector2(card.size.x / 2, 0), 5.0, Color("8b0000"), true, -1.0, true)   # alfinete


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var g := game
	draw_texture(bg_vp.get_texture(), Vector2.ZERO)
	for y in CentipedeGame.ROWS:
		for x in CentipedeGame.COLS:
			var i := y * CentipedeGame.COLS + x
			var hp := g.mushrooms[i]
			if hp > 0:
				_mushroom(px(Vector2(x, y) * C + Vector2(4, 4)), hp, g.poisoned[i] == 1, hash(Vector2i(x, y)))
	for s in splats:
		for b in s.blobs:
			draw_circle(s.pos + b[0], b[1], Color(INK_BLUE, 0.7 * clampf(s.life, 0.0, 1.0)), true, -1.0, true)
	for i in g.segments.size():
		var s: Dictionary = g.segments[i]
		_segment(px(s.pos + Vector2(4, 4)), s.head, s.dx, i)
	if g.flea != null:
		_flea(px(g.flea.pos))
	if g.spider != null:
		_spider(px(g.spider.pos))
	if g.scorpion != null:
		_scorpion(px(g.scorpion.pos), g.scorpion.dir)
	if g.shot != null:
		var p := px(g.shot)
		draw_circle(p + Vector2(0, 6), 3.0, INK_BLUE, true, -1.0, true)
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(-3, 6), p + Vector2(3, 6)]), INK_BLUE)
	if not player_dying() and g.state != CentipedeGame.State.REPAIR and g.state != CentipedeGame.State.OVER:
		_nib(px(g.player_pos))
	for p in popups:
		_text(p.text, px(p.pos), 20, Color(INK, clampf(p.life, 0.0, 1.0)))
	_draw_hud()


func _mushroom(c: Vector2, hp: int, poison: bool, h: int) -> void:
	var k := 0.45 + 0.55 * hp / 4.0
	var wash: Color = POISON if poison else WASH[absi(h) % WASH.size()]
	# pé
	var stem := Rect2(c + Vector2(-3.5, -1) * k, Vector2(7, 11) * k)
	draw_rect(stem, Color("f3ead2"))
	draw_line(stem.position, Vector2(stem.position.x, stem.end.y), INK, 1.0, true)
	draw_line(Vector2(stem.end.x, stem.position.y), stem.end, INK, 1.0, true)
	for t in 3:
		var y := stem.position.y + (t + 1) * stem.size.y / 4
		draw_line(Vector2(stem.end.x - 3, y), Vector2(stem.end.x, y - 1), Color(INK, 0.5), 1.0)
	# chapéu em aguarela + contorno a tinta
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		pts.append(c + Vector2(cos(a) * 11.0, sin(a) * 9.0 - 1.0) * k)
	draw_colored_polygon(pts, Color(wash, 0.75))
	pts.append(pts[0])
	draw_polyline(pts, INK, 1.2, true)
	for i in 3:
		var a := PI + PI * (i + 1) / 4.0
		draw_line(c + Vector2(cos(a) * 9.0, sin(a) * 7.0 - 1.0) * k, c + Vector2(cos(a) * 5.0, sin(a) * 4.0 - 1.0) * k, Color(INK, 0.45), 1.0)
	if not poison and absi(h) % 3 == 0:
		draw_circle(c + Vector2(-3, -5) * k, 1.6 * k, Color("fff8e7"), true, -1.0, true)
		draw_circle(c + Vector2(3, -4) * k, 1.3 * k, Color("fff8e7"), true, -1.0, true)


func _segment(c: Vector2, head: bool, dx: int, idx: int) -> void:
	var phase := time * 14.0 + idx * 0.9
	for s in [-1.0, 1.0]:
		for l in 2:
			var base := c + Vector2(-4 + l * 8, 0)
			var swing := sin(phase + l * PI) * 4.0
			draw_line(base, base + Vector2(swing, s * 13.0), INK, 1.2, true)
	draw_set_transform(c, 0.0, Vector2(1.0, 0.8))
	draw_circle(Vector2.ZERO, 11.0, Color(CENT, 0.8), true, -1.0, true)
	draw_arc(Vector2.ZERO, 11.0, 0, TAU, 20, INK, 1.4, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for t in 3:
		var x := -5.0 + t * 5.0
		draw_line(c + Vector2(x, -7), c + Vector2(x + 2, 7), Color(INK, 0.45), 1.0)
	if head:
		var fwd := Vector2(-1 if dx < 0 else 1, 0)
		for s in [-1.0, 1.0]:
			var a := c + fwd * 9.0 + Vector2(0, s * 4.0)
			var pts := PackedVector2Array([a, a + fwd * 6.0 + Vector2(0, s * 4.0), a + fwd * 9.0 + Vector2(0, s * 10.0)])
			draw_polyline(pts, INK, 1.2, true)
		draw_circle(c + fwd * 5.0 + Vector2(0, -3), 1.8, INK, true, -1.0, true)
		draw_circle(c + fwd * 5.0 + Vector2(0, 3), 1.8, INK, true, -1.0, true)


func _nib(c: Vector2) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -13), c + Vector2(-8, 4), c + Vector2(-5, 12), c + Vector2(5, 12), c + Vector2(8, 4)])
	draw_colored_polygon(pts, Color("b8860b"))
	pts.append(pts[0])
	draw_polyline(pts, INK, 1.4, true)
	draw_line(c + Vector2(0, -12), c + Vector2(0, 2), INK, 1.2)
	draw_circle(c + Vector2(0, 3), 2.2, INK, true, -1.0, true)


func _spider(c: Vector2) -> void:
	var ph := time * 12.0
	for s in [-1.0, 1.0]:
		for l in 4:
			var ang := (-0.9 + l * 0.6) + sin(ph + l) * 0.15
			var knee := c + Vector2(s * cos(ang) * 14.0, sin(ang) * 10.0 - 6.0)
			var foot := knee + Vector2(s * 8.0, 12.0)
			draw_polyline(PackedVector2Array([c, knee, foot]), INK, 1.3, true)
	draw_circle(c + Vector2(0, 2), 8.0, Color("2b1d12"), true, -1.0, true)
	draw_circle(c + Vector2(0, -6), 5.0, Color("2b1d12"), true, -1.0, true)
	draw_circle(c + Vector2(-2, -7), 1.2, Color("f8f1de"), true, -1.0, true)
	draw_circle(c + Vector2(2, -7), 1.2, Color("f8f1de"), true, -1.0, true)


func _flea(c: Vector2) -> void:
	draw_set_transform(c, 0.3, Vector2(1.0, 1.3))
	draw_circle(Vector2.ZERO, 7.0, Color("8e5b2a"), true, -1.0, true)
	draw_arc(Vector2.ZERO, 7.0, 0, TAU, 16, INK, 1.2, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for s in [-1.0, 1.0]:
		draw_polyline(PackedVector2Array([c, c + Vector2(s * 9, 4), c + Vector2(s * 6, 13)]), INK, 1.2, true)


func _scorpion(c: Vector2, dir: float) -> void:
	var f := Vector2(dir, 0)
	draw_set_transform(c, 0.0, Vector2(1.4, 0.8))
	draw_circle(Vector2.ZERO, 8.0, Color("a0522d"), true, -1.0, true)
	draw_arc(Vector2.ZERO, 8.0, 0, TAU, 16, INK, 1.2, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var tail := PackedVector2Array()
	for k in 6:
		var t := k / 5.0
		tail.append(c - f * (10.0 + 10.0 * t) + Vector2(0, -16.0 * sin(t * PI * 0.8)))
	draw_polyline(tail, INK, 3.0, true)
	draw_circle(tail[tail.size() - 1], 2.5, Color("8b0000"), true, -1.0, true)
	for s in [-1.0, 1.0]:
		var arm := c + f * 10.0 + Vector2(0, s * 4.0)
		draw_polyline(PackedVector2Array([c + f * 6.0, arm, arm + f * 5.0 + Vector2(0, s * 4.0)]), INK, 1.6, true)


func _draw_hud() -> void:
	var g := game
	var lx := panel_left_x()
	var rx := panel_right_x()
	var a0 := 1.0 if (g.current == 0 or g.players.size() == 1) else 0.45
	_text(I18n.t("Espécime n.º 1"), Vector2(lx, 90), 18, Color(INK, a0))
	_text(str(g.players[0].score), Vector2(lx, 150), 46, Color("8b0000", a0))
	_text(I18n.t("recorde"), Vector2(lx, 220), 16, INK)
	_text(str(maxi(g.best, g.player().score)), Vector2(lx, 268), 32, INK_BLUE)
	if g.players.size() > 1:
		_text(I18n.t("Espécime n.º 2"), Vector2(rx, 90), 18, Color(INK, 1.0 if g.current == 1 else 0.45))
		_text(str(g.players[1].score), Vector2(rx, 150), 46, Color("8b0000", 1.0 if g.current == 1 else 0.45))
		_text(I18n.t("Prancha %s") % _roman(g.wave()), Vector2(rx, 250), 22, INK)
	else:
		_text("Scolopendra arcadia", Vector2(rx, 100), 18, Color(INK, 0.8))
		_text(I18n.t("Prancha"), Vector2(rx, 170), 18, INK)
		_text(_roman(g.wave()), Vector2(rx, 240), 50, Color("8b0000"))
	_text(I18n.t("vidas"), Vector2(lx, 510), 16, INK)
	var n := mini(maxi(g.player().lives, 0), 6)
	for i in n:
		_nib(Vector2(lx - (n - 1) * 17.0 + i * 34.0, 560))
	_text(I18n.t("cogumelos:  4 tiros"), Vector2(rx, 520), 15, Color(INK, 0.8))
	_text(I18n.t("aranha  300 · 600 · 900"), Vector2(rx, 552), 15, Color(INK, 0.8))
	_text(I18n.t("pulga  200   escorpião  1000"), Vector2(rx, 584), 15, Color(INK, 0.8))
	_text(I18n.t("cabeça  100   corpo  10"), Vector2(rx, 616), 15, Color(INK, 0.8))


static func _roman(n: int) -> String:
	var vals := [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"],
		[50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]
	var out := ""
	for v in vals:
		while n >= v[0]:
			out += v[1]
			n -= v[0]
	return out


func _text(text: String, pos: Vector2, size: int, c: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(pos.x - w / 2, pos.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)


func ui_palette() -> Dictionary:
	return {
		"panel": Color("f8f1de"),
		"border": INK,
		"text": INK,
		"accent": Color("8b0000"),
		"button": Color("efe4c8"),
		"button_hover": Color("e6d3a8"),
		"radius": 4,
		"dim": Color(0.3, 0.2, 0.1, 0.2),
	}
