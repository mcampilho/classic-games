extends PongSkin
## Papel & Tinta (estilo próprio): um Pong jogado na margem de um caderno.
## Raquetes e bola desenhadas a tinta com traço "a ferver" (animação a 9 fps, como desenho à mão),
## salpicos de tinta que ficam no papel a cada toque, marcador a caneta com círculo vermelho nos pontos
## e sons acústicos: madeira, lápis a riscar e um sino.

const PAPER := Color("f3ebd3")
const PAPER_EDGE := Color(0.83, 0.75, 0.56, 0.0)
const PAPER_EDGE_DARK := Color(0.78, 0.68, 0.48, 0.35)
const RULE := Color(0.36, 0.55, 0.82, 0.26)
const MARGIN := Color(0.86, 0.33, 0.30, 0.5)
const INK := Color("1d2748")
const GRAPHITE := Color(0.24, 0.24, 0.27, 0.55)
const RED := Color("c8372d")
const COFFEE := Color(0.55, 0.35, 0.15, 0.10)

var font: Font
var boil := 0
var _boil_t := 0.0
var grain := PackedVector2Array()
var stains: Array[Dictionary] = []
var trail: Array[Vector2] = []
var circle_t := PackedFloat32Array([-1.0, -1.0])


func _setup() -> void:
	font = ThemeDB.fallback_font
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 1200:
		grain.append(Vector2(rng.randf() * PongGame.FIELD.x, rng.randf() * PongGame.FIELD.y))


func _build_sfx() -> void:
	sfx.paddle = Synth.to_stream(Synth.mix([
		Synth.render(640.0, 0.12, {"wave": "sine", "volume": 0.6, "decay": 42.0}),
		Synth.render(0.0, 0.03, {"wave": "noise", "volume": 0.35, "decay": 110.0, "lowpass": 0.45}),
	]))
	sfx.wall = Synth.to_stream(Synth.mix([
		Synth.render(360.0, 0.1, {"wave": "sine", "volume": 0.45, "decay": 50.0}),
		Synth.render(0.0, 0.025, {"wave": "noise", "volume": 0.2, "decay": 140.0, "lowpass": 0.35}),
	]))
	var scribble := {"wave": "noise", "volume": 0.22, "lowpass": 0.18, "attack": 0.02, "release": 0.03}
	sfx.score = Synth.concat([
		Synth.render(0.0, 0.08, scribble), Synth.silence(0.03),
		Synth.render(0.0, 0.07, scribble), Synth.silence(0.03),
		Synth.render(0.0, 0.11, scribble),
		Synth.render(987.8, 0.45, {"wave": "triangle", "volume": 0.32, "decay": 7.0}),
	])
	var notes := []
	for f in [659.3, 784.0, 987.8]:
		notes.append(Synth.render(f, 0.15, {"wave": "triangle", "volume": 0.3, "decay": 9.0}))
	notes.append(Synth.render(1318.5, 0.7, {"wave": "triangle", "volume": 0.32, "decay": 4.0}))
	sfx.win = Synth.concat(notes)


# ---------------------------------------------------------------- eventos

func _on_match_started() -> void:
	stains.clear()
	circle_t = PackedFloat32Array([-1.0, -1.0])


func _on_paddle_hit(side: int, pos: Vector2, _rel: float) -> void:
	play("paddle", randf_range(0.9, 1.12))
	var dir := 1.0 if side == 0 else -1.0
	for i in randi_range(2, 5):
		var off := Vector2(dir * randf_range(8.0, 46.0), randf_range(-34.0, 34.0))
		stains.append({
			"pts": _blot_points(pos + off, randf_range(1.8, 6.5), randi()),
			"color": Color(INK, randf_range(0.45, 0.8)),
		})
	if stains.size() > 90:
		stains = stains.slice(stains.size() - 90)


func _on_wall_hit(_pos: Vector2) -> void:
	play("wall", randf_range(0.92, 1.08))


func _on_point_scored(side: int) -> void:
	play("score")
	circle_t[side] = 0.0
	trail.clear()


# ---------------------------------------------------------------- animação

func _tick(dt: float) -> void:
	_boil_t += dt
	if _boil_t > 0.11:
		_boil_t = 0.0
		boil += 1
	for i in 2:
		if circle_t[i] >= 0.0:
			circle_t[i] += dt
			if circle_t[i] > 2.6:
				circle_t[i] = -1.0
	if game.state == PongGame.State.PLAY:
		trail.append(game.ball_pos)
		if trail.size() > 10:
			trail.pop_front()
	elif not trail.is_empty():
		trail.pop_front()


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var f := PongGame.FIELD
	draw_rect(Rect2(Vector2(-40, -40), f + Vector2(80, 80)), PAPER)
	_draw_edges(f)
	for p in grain:
		draw_rect(Rect2(p, Vector2(1.6, 1.6)), Color(0.3, 0.24, 0.12, 0.07))
	for y in range(64, int(f.y), 40):
		draw_line(Vector2(0, y), Vector2(f.x, y), RULE, 1.5)
	for x in [34.0, 40.0, f.x - 40.0, f.x - 34.0]:
		draw_line(Vector2(x, 0), Vector2(x, f.y), MARGIN, 1.5)
	# mancha de café (porque todo o caderno tem uma)
	draw_arc(Vector2(f.x - 190, f.y - 120), 64, 0.0, TAU, 72, COFFEE, 7.0, true)
	draw_arc(Vector2(f.x - 186, f.y - 117), 59, 0.4, 5.6, 64, Color(COFFEE, 0.06), 4.0, true)

	for s in stains:
		draw_colored_polygon(s.pts, s.color)

	# rede a lápis
	var rng := _rng(1000)
	var ny := 10.0
	while ny < f.y:
		var x := f.x / 2 + rng.randf_range(-1.5, 1.5)
		draw_line(Vector2(x, ny), Vector2(x + rng.randf_range(-2.0, 2.0), ny + 20.0), GRAPHITE, 3.0, true)
		ny += 36.0

	_draw_score(0)
	_draw_score(1)

	for i in trail.size():
		var k := float(i + 1) / trail.size()
		draw_circle(trail[i], 2.0 + 5.0 * k, Color(GRAPHITE, 0.10 * k), true, -1.0, true)

	for side in 2:
		_ink_rect(game.paddle_rect(side), side)
	if game.state == PongGame.State.PLAY:
		draw_colored_polygon(_blot_points(game.ball_pos, 10.0, boil * 31 + 5), INK)


func _draw_edges(f: Vector2) -> void:
	# escurece ligeiramente as margens da folha
	var e := 70.0
	var c0 := PAPER_EDGE_DARK
	var c1 := PAPER_EDGE
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(f.x, 0), Vector2(f.x, e), Vector2(0, e)]), PackedColorArray([c0, c0, c1, c1]))
	draw_polygon(PackedVector2Array([Vector2(0, f.y - e), Vector2(f.x, f.y - e), Vector2(f.x, f.y), Vector2(0, f.y)]), PackedColorArray([c1, c1, c0, c0]))
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(e, 0), Vector2(e, f.y), Vector2(0, f.y)]), PackedColorArray([c0, c1, c1, c0]))
	draw_polygon(PackedVector2Array([Vector2(f.x - e, 0), Vector2(f.x, 0), Vector2(f.x, f.y), Vector2(f.x - e, f.y)]), PackedColorArray([c1, c0, c0, c1]))


func _draw_score(side: int) -> void:
	var f := PongGame.FIELD
	var text := str(game.scores[side])
	var size := 104
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var rng := _rng(side * 77)
	var center := Vector2(f.x / 2 + (-170.0 if side == 0 else 170.0), 126)
	draw_set_transform(center, deg_to_rad((-4.0 if side == 0 else 3.0) + rng.randf_range(-0.6, 0.6)), Vector2.ONE)
	draw_string(font, Vector2(-w / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, INK)
	draw_string(font, Vector2(-w / 2 + 1.5, 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(INK, 0.45))
	var t := circle_t[side]
	if t >= 0.0:
		var prog := clampf(t / 0.45, 0.0, 1.0)
		var alpha := clampf(2.4 - t, 0.0, 1.0)
		var start := -PI * 0.65
		draw_arc(Vector2(0, -38), 76.0 + w * 0.15, start, start + TAU * 1.08 * prog, 56, Color(RED, 0.85 * alpha), 4.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ink_rect(r: Rect2, side: int) -> void:
	var rng := _rng(side * 100 + 1)
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	var pts := PackedVector2Array()
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		for j in 4:
			pts.append(a.lerp(b, j / 4.0) + Vector2(rng.randf_range(-1.4, 1.4), rng.randf_range(-1.4, 1.4)))
	draw_colored_polygon(pts, Color(INK, 0.92))
	# tracejado de luz para parecer preenchido à mão
	var yy := r.position.y + 12.0
	while yy < r.end.y - 4.0:
		draw_line(Vector2(r.position.x + 3, yy + 5), Vector2(r.end.x - 3, yy), Color(1, 1, 1, 0.13), 1.5)
		yy += 17.0
	var outline := pts.duplicate()
	outline.append(pts[0] + Vector2(rng.randf_range(-3, 3), rng.randf_range(2, 6)))
	draw_polyline(outline, INK, 2.0, true)


func _blot_points(center: Vector2, radius: float, seed_value: int) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pts := PackedVector2Array()
	var n := 14
	for i in n:
		pts.append(center + Vector2.from_angle(TAU * i / n) * radius * rng.randf_range(0.8, 1.16))
	return pts


func _rng(salt: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(boil * 7919 + salt)
	return rng


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.985, 0.965, 0.9, 0.96),
		"border": INK,
		"text": INK,
		"accent": RED,
		"button": Color("efe5c8"),
		"button_hover": Color("e4d4a8"),
		"radius": 4,
		"dim": Color(0.95, 0.92, 0.84, 0.2),
	}
