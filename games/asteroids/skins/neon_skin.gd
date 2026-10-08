extends AsteroidsSkin
## Neon: asteroides de luz em cores elétricas, rasto do motor, tiros com cauda, faíscas,
## ondas de choque, ecrã a tremer e pontos a flutuar.

const BG_TOP := Color("0a0320")
const BG_BOTTOM := Color("1b0639")
const GRID := Color(0.55, 0.3, 1.0, 0.07)
const SHIP_C := Color("19f0ff")
const SAUCER_C := Color("ff2b4f")
const ROCK_COLORS := [Color("ff2bd6"), Color("b46bff"), Color("ffb03d"), Color("3dffa0"), Color("5b8bff")]

var fx: Node2D
var font: Font
var time := 0.0
var shake := 0.0
var flash := 0.0
var flash_color := Color.WHITE
var sparks: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var floaters: Array[Dictionary] = []
var exhaust: Array[Dictionary] = []
var stars: Array[Vector3] = []


func _setup() -> void:
	font = ThemeDB.fallback_font
	fx = Node2D.new()
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = m
	add_child(fx)
	fx.draw.connect(_draw_fx)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1979
	for i in 90:
		stars.append(Vector3(rng.randf() * W, rng.randf() * H, rng.randf_range(0.2, 1.0)))


func _build_sfx() -> void:
	sfx.beat0 = Synth.to_stream(Synth.mix([
		Synth.render(55.0, 0.18, {"wave": "saw", "volume": 0.45, "lowpass": 0.1, "decay": 12.0}),
		Synth.render(110.0, 0.04, {"wave": "square", "volume": 0.08, "lowpass": 0.3, "decay": 60.0})]))
	sfx.beat1 = Synth.to_stream(Synth.mix([
		Synth.render(49.0, 0.18, {"wave": "saw", "volume": 0.45, "lowpass": 0.1, "decay": 12.0}),
		Synth.render(98.0, 0.04, {"wave": "square", "volume": 0.08, "lowpass": 0.3, "decay": 60.0})]))
	sfx.fire = Synth.tone(2000.0, 0.12, {"wave": "square", "freq_end": 300.0, "volume": 0.1, "lowpass": 0.35, "decay": 16.0})
	sfx.saucer_fire = Synth.tone(900.0, 0.1, {"wave": "saw", "freq_end": 300.0, "volume": 0.08, "lowpass": 0.3, "decay": 18.0})
	var sizes := [[0.8, 0.12, 4.5, 70.0], [0.5, 0.2, 7.0, 110.0], [0.3, 0.35, 11.0, 180.0]]
	for i in 3:
		var s: Array = sizes[i]
		sfx["boom%d" % i] = Synth.to_stream(Synth.mix([
			Synth.render(0.0, s[0], {"wave": "noise", "volume": 0.4, "lowpass": s[1], "decay": s[2]}),
			Synth.render(s[3] * 2.0, s[0], {"wave": "sine", "freq_end": s[3] * 0.5, "volume": 0.35, "decay": s[2]}),
		]))
	sfx.ship_boom = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.5, {"wave": "noise", "volume": 0.4, "lowpass": 0.15, "decay": 2.2}),
		Synth.render(260.0, 1.3, {"wave": "saw", "freq_end": 35.0, "volume": 0.25, "lowpass": 0.2, "decay": 2.0}),
	]))
	sfx.thrust = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.6, {"wave": "noise", "volume": 0.16, "lowpass": 0.08, "attack": 0.0, "release": 0.0}),
		Synth.render(41.0, 0.6, {"wave": "saw", "volume": 0.12, "lowpass": 0.15, "attack": 0.0, "release": 0.0}),
	]))
	var big := []
	for i in 2:
		big.append(Synth.render(300.0, 0.18, {"wave": "sine", "freq_end": 420.0, "volume": 0.16, "attack": 0.0, "release": 0.0}))
		big.append(Synth.render(420.0, 0.18, {"wave": "sine", "freq_end": 300.0, "volume": 0.16, "attack": 0.0, "release": 0.0}))
	sfx.saucer_big = Synth.concat(big)
	var small := []
	for i in 3:
		small.append(Synth.render(880.0, 0.07, {"wave": "sine", "freq_end": 1320.0, "volume": 0.14, "attack": 0.0, "release": 0.0}))
		small.append(Synth.render(1320.0, 0.07, {"wave": "sine", "freq_end": 880.0, "volume": 0.14, "attack": 0.0, "release": 0.0}))
	sfx.saucer_small = Synth.concat(small)
	sfx.hyper = Synth.tone(200.0, 0.35, {"wave": "sine", "freq_end": 1600.0, "volume": 0.25})
	var up := []
	for f in [659.25, 783.99, 987.77, 1318.5, 1568.0]:
		up.append(Synth.render(f, 0.08, {"wave": "triangle", "volume": 0.25}))
	sfx.extra = Synth.concat(up)


func rock_color(r: Dictionary) -> Color:
	return ROCK_COLORS[int(r.tint * ROCK_COLORS.size()) % ROCK_COLORS.size()]


# ---------------------------------------------------------------- eventos

func _on_match_started() -> void:
	sparks.clear()
	rings.clear()
	floaters.clear()


func _on_asteroid_destroyed(pos: Vector2, size: int, points: int, rock: Dictionary) -> void:
	super(pos, size, points, rock)
	var c := rock_color(rock)
	_burst(pos, c, 24 - size * 6, 260.0 - size * 40.0)
	rings.append({"pos": pos, "radius": rock.r * 0.5, "alpha": 0.9, "color": c, "speed": 220.0 - size * 40.0})
	shake = maxf(shake, 6.0 - size * 2.0)
	if points > 0:
		floaters.append({"pos": pos, "text": "+%d" % points, "life": 0.8, "color": c})


func _on_saucer_destroyed(pos: Vector2, small: bool, points: int) -> void:
	super(pos, small, points)
	_burst(pos, SAUCER_C, 40, 300.0)
	rings.append({"pos": pos, "radius": 10.0, "alpha": 1.0, "color": SAUCER_C, "speed": 320.0})
	flash = 0.5
	flash_color = SAUCER_C
	if points > 0:
		floaters.append({"pos": pos, "text": "+%d" % points, "life": 1.2, "color": SAUCER_C})


func _on_ship_destroyed(pos: Vector2) -> void:
	super(pos)
	_burst(pos, SHIP_C, 70, 360.0)
	rings.append({"pos": pos, "radius": 8.0, "alpha": 1.0, "color": SHIP_C, "speed": 420.0})
	shake = 18.0
	flash = 0.8
	flash_color = Color("ff2b4f")


func _on_hyperspace(from: Vector2, to: Vector2) -> void:
	super(from, to)
	rings.append({"pos": from, "radius": 30.0, "alpha": 1.0, "color": SHIP_C, "speed": -50.0})
	rings.append({"pos": to, "radius": 4.0, "alpha": 1.0, "color": SHIP_C, "speed": 120.0})


func _on_extra_life() -> void:
	super()
	flash = 0.5
	flash_color = Color("3dffa0")


func _burst(pos: Vector2, c: Color, n: int, speed: float) -> void:
	for i in n:
		var life := randf_range(0.3, 0.8)
		sparks.append({"pos": pos, "vel": Vector2.from_angle(randf() * TAU) * randf_range(speed * 0.2, speed), "life": life, "max": life, "color": c})


# ---------------------------------------------------------------- animação

func _tick(dt: float) -> void:
	time += dt
	shake = move_toward(shake, 0.0, dt * 40.0)
	flash = move_toward(flash, 0.0, dt * 2.5)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	var drag := pow(0.08, dt)
	for s in sparks:
		s.pos += s.vel * dt
		s.vel *= drag
		s.life -= dt
	sparks = sparks.filter(func(s: Dictionary) -> bool: return s.life > 0.0)
	for r in rings:
		r.radius = maxf(r.radius + r.speed * dt, 0.0)
		r.alpha -= 1.8 * dt
	rings = rings.filter(func(r: Dictionary) -> bool: return r.alpha > 0.0)
	for f in floaters:
		f.pos.y -= 40.0 * dt
		f.life -= dt
	floaters = floaters.filter(func(f: Dictionary) -> bool: return f.life > 0.0)
	if game.thrusting:
		var back := game.ship_pos + Vector2(-8, 0).rotated(game.ship_angle)
		for i in 2:
			var life := randf_range(0.2, 0.4)
			exhaust.append({"pos": back, "vel": Vector2(-1, 0).rotated(game.ship_angle + randf_range(-0.35, 0.35)) * randf_range(140, 260) + game.ship_vel,
				"life": life, "max": life})
	for e in exhaust:
		e.pos += e.vel * dt
		e.life -= dt
	exhaust = exhaust.filter(func(e: Dictionary) -> bool: return e.life > 0.0)
	fx.queue_redraw()


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var a := Vector2(-80, -80)
	var b := Vector2(W + 80, H + 80)
	draw_polygon(PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)]),
		PackedColorArray([BG_TOP, BG_TOP, BG_BOTTOM, BG_BOTTOM]))
	for x in range(-64, int(W) + 64, 64):
		draw_line(Vector2(x, -80), Vector2(x, H + 80), GRID, 1.0)
	for y in range(-64, int(H) + 64, 64):
		draw_line(Vector2(-80, y), Vector2(W + 80, y), GRID, 1.0)
	for s in stars:
		var tw := 0.5 + 0.5 * sin(time * 2.0 + s.x)
		draw_rect(Rect2(s.x, s.y, 2, 2), Color(0.8, 0.85, 1.0, s.z * (0.3 + 0.4 * tw)))
	# interior escuro dos asteroides (o contorno brilhante é desenhado na camada aditiva)
	for r in game.rocks:
		for off in wrap_offsets(r.pos, r.r):
			draw_colored_polygon(game.rock_points(r, off), Color(rock_color(r).darkened(0.75), 0.85))


func _neon_line(points: PackedVector2Array, c: Color, k := 1.0) -> void:
	fx.draw_polyline(points, Color(c, 0.08 * k), 12.0, true)
	fx.draw_polyline(points, Color(c, 0.22 * k), 5.0, true)
	fx.draw_polyline(points, Color(c.lerp(Color.WHITE, 0.5), k), 2.0, true)


func _draw_fx() -> void:
	var g := game
	if flash > 0.0:
		fx.draw_rect(Rect2(-80, -80, W + 160, H + 160), Color(flash_color, flash * 0.14))
	for r in g.rocks:
		var c := rock_color(r)
		for off in wrap_offsets(r.pos, r.r):
			_neon_line(closed(g.rock_points(r, off)), c)
	if g.saucer != null:
		var k := 0.8 + 0.2 * sin(time * 14.0)
		for line in saucer_lines(g.saucer.pos, g.saucer.small):
			_neon_line(line, SAUCER_C, k)
	for e in exhaust:
		var t: float = e.life / e.max
		fx.draw_circle(e.pos, 2.0 + 4.0 * t, Color(Color("ff7a3d").lerp(Color("ff2bd6"), 1.0 - t), 0.5 * t), true, -1.0, true)
	if g.ship_visible() or (g.ship_waiting() and fmod(time, 0.5) < 0.3):
		for off in wrap_offsets(g.ship_pos, 20.0):
			var pts := closed(shifted(g.ship_points(), off))
			_neon_line(pts, SHIP_C)
	for b in g.bullets:
		fx.draw_line(b.pos, b.pos - (b.vel as Vector2).normalized() * 14.0, Color(SHIP_C, 0.4), 3.0, true)
		fx.draw_circle(b.pos, 6.0, Color(SHIP_C, 0.25), true, -1.0, true)
		fx.draw_circle(b.pos, 2.2, Color.WHITE, true, -1.0, true)
	for b in g.saucer_bullets:
		fx.draw_circle(b.pos, 6.0, Color(SAUCER_C, 0.3), true, -1.0, true)
		fx.draw_circle(b.pos, 2.2, Color(1, 0.8, 0.8), true, -1.0, true)
	for r in rings:
		fx.draw_arc(r.pos, r.radius, 0.0, TAU, 48, Color(r.color, maxf(r.alpha, 0.0)), 3.0, true)
	for s in sparks:
		fx.draw_line(s.pos, s.pos - s.vel * 0.03, Color(s.color.lerp(Color.WHITE, 0.4), s.life / s.max), 2.0, true)
	for f in floaters:
		_text(f.text, f.pos.x, f.pos.y, f.color, 22, clampf(f.life * 2.0, 0.0, 1.0))
	_draw_hud()


func _draw_hud() -> void:
	var g := game
	var a0 := 1.0 if g.current == 0 else 0.4
	_text(str(g.players[0].score), 150, 66, SHIP_C, 44, a0)
	_text(str(maxi(g.best, g.player().score)), W / 2, 50, Color("ffc53d"), 24, 0.8)
	if g.players.size() > 1:
		_text(str(g.players[1].score), W - 150, 66, Color("ff2bd6"), 44, 1.0 if g.current == 1 else 0.4)
	var x0 := 92.0 if g.current == 0 else W - 208.0
	for i in mini(g.player().lives, 8):
		var pts := closed(g.ship_points(Vector2(x0 + i * 24.0, 98), -PI / 2, 0.7))
		fx.draw_polyline(pts, Color(SHIP_C, 0.25), 5.0, true)
		fx.draw_polyline(pts, SHIP_C, 1.6, true)


func _text(text: String, center_x: float, baseline: float, c: Color, size: int, alpha: float) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(center_x - w / 2, baseline)
	fx.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 12, Color(c, 0.12 * alpha))
	fx.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 5, Color(c, 0.28 * alpha))
	fx.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(c.lerp(Color.WHITE, 0.45), alpha))


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.04, 0.02, 0.13, 0.88),
		"border": Color("8a5cff"),
		"text": Color("ece6ff"),
		"accent": SHIP_C,
		"button": Color("170a36"),
		"button_hover": Color("2a1361"),
		"radius": 10,
		"dim": Color(0, 0, 0, 0.3),
	}
