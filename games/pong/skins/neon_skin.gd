extends PongSkin
## Neon: luz brilhante sobre fundo escuro, rasto da bola, faíscas, ondas de choque,
## ecrã a tremer e sons sintetizados que sobem de tom à medida que a jogada aquece.

const BG_TOP := Color("0a0320")
const BG_BOTTOM := Color("1b0639")
const GRID := Color(0.55, 0.3, 1.0, 0.09)
const WALL := Color("7b4dff")
const NET := Color(0.75, 0.55, 1.0)
const COLORS := [Color("19f0ff"), Color("ff2bd6")]
const BALL_WHITE := Color("fff4d6")

var fx: Node2D            # camada com mistura aditiva para o brilho
var font: Font
var time := 0.0
var shake := 0.0
var flash := 0.0
var flash_color := Color.WHITE
var pulse := PackedFloat32Array([0.0, 0.0])
var wall_glow := PackedFloat32Array([0.0, 0.0])
var score_pop := PackedFloat32Array([0.0, 0.0])
var ball_color := BALL_WHITE
var trail: Array[Vector2] = []
var sparks: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var _sb_cache := {}


func _setup() -> void:
	font = ThemeDB.fallback_font
	fx = Node2D.new()
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = m
	add_child(fx)
	fx.draw.connect(_draw_fx)


func _build_sfx() -> void:
	sfx.paddle = Synth.tone(330.0, 0.11, {"wave": "square", "freq_end": 660.0, "volume": 0.22, "decay": 18.0, "lowpass": 0.5})
	sfx.wall = Synth.tone(880.0, 0.07, {"wave": "triangle", "freq_end": 520.0, "volume": 0.35, "decay": 22.0})
	sfx.serve = Synth.tone(220.0, 0.14, {"wave": "sine", "freq_end": 520.0, "volume": 0.3})
	var arp := []
	for f in [523.25, 659.25, 783.99]:
		arp.append(Synth.render(f, 0.07, {"wave": "saw", "volume": 0.18, "lowpass": 0.35}))
	arp.append(Synth.render(1046.5, 0.25, {"wave": "saw", "volume": 0.2, "decay": 9.0, "lowpass": 0.35}))
	sfx.score = Synth.concat(arp)
	var win := []
	for f in [523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5, 1318.5]:
		win.append(Synth.render(f, 0.1, {"wave": "square", "volume": 0.16, "lowpass": 0.3}))
	win.append(Synth.render(1568.0, 0.5, {"wave": "square", "volume": 0.16, "decay": 5.0, "lowpass": 0.3}))
	sfx.win = Synth.concat(win)


# ---------------------------------------------------------------- eventos

func _on_match_started() -> void:
	ball_color = BALL_WHITE
	sparks.clear()
	rings.clear()


func _on_served() -> void:
	ball_color = BALL_WHITE
	play("serve", 1.0, -4.0)
	rings.append({"pos": game.ball_pos, "radius": 4.0, "alpha": 0.7, "color": BALL_WHITE, "speed": 160.0})


func _on_paddle_hit(side: int, pos: Vector2, _rel: float) -> void:
	var c: Color = COLORS[side]
	play("paddle", 1.0 + minf(game.rally_hits, 14) * 0.035)
	pulse[side] = 1.0
	ball_color = c
	shake = maxf(shake, 3.0 + game.rally_hits * 0.35)
	rings.append({"pos": pos, "radius": 6.0, "alpha": 0.9, "color": c, "speed": 300.0})
	_burst(pos, Vector2(1.0 if side == 0 else -1.0, 0.0), c, 14 + game.rally_hits)


func _on_wall_hit(pos: Vector2) -> void:
	play("wall")
	wall_glow[0 if pos.y < 10.0 else 1] = 1.0
	_burst(pos, Vector2(0.0, 1.0 if pos.y < 10.0 else -1.0), ball_color, 8)


func _on_point_scored(side: int) -> void:
	play("score")
	flash = 1.0
	flash_color = COLORS[side]
	shake = 16.0
	score_pop[side] = 1.0
	var exit := Vector2(clampf(game.ball_pos.x, 0.0, PongGame.FIELD.x), game.ball_pos.y)
	rings.append({"pos": exit, "radius": 10.0, "alpha": 1.0, "color": COLORS[side], "speed": 700.0})
	_burst(exit, Vector2(1.0 if exit.x < 640.0 else -1.0, 0.0), COLORS[side], 40)
	trail.clear()


func _burst(pos: Vector2, dir: Vector2, c: Color, count: int) -> void:
	for i in count:
		var life := randf_range(0.25, 0.6)
		sparks.append({
			"pos": pos,
			"vel": dir.rotated(randf_range(-1.2, 1.2)) * randf_range(180.0, 700.0),
			"life": life, "max": life, "color": c,
		})


# ---------------------------------------------------------------- animação

func _tick(dt: float) -> void:
	time += dt
	shake = move_toward(shake, 0.0, dt * 45.0)
	flash = move_toward(flash, 0.0, dt * 2.5)
	for i in 2:
		pulse[i] = move_toward(pulse[i], 0.0, dt * 4.0)
		wall_glow[i] = move_toward(wall_glow[i], 0.0, dt * 3.5)
		score_pop[i] = move_toward(score_pop[i], 0.0, dt * 2.5)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake

	if game.state == PongGame.State.PLAY:
		trail.append(game.ball_pos)
		if trail.size() > 18:
			trail.pop_front()
	elif not trail.is_empty():
		trail.pop_front()

	var drag := pow(0.04, dt)
	for s in sparks:
		s.pos += s.vel * dt
		s.vel *= drag
		s.life -= dt
	sparks = sparks.filter(func(s: Dictionary) -> bool: return s.life > 0.0)
	for r in rings:
		r.radius += r.speed * dt
		r.alpha -= 1.8 * dt
	rings = rings.filter(func(r: Dictionary) -> bool: return r.alpha > 0.0)
	fx.queue_redraw()


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var f := PongGame.FIELD
	var a := Vector2(-80, -80)
	var b := f + Vector2(80, 80)
	draw_polygon(
		PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)]),
		PackedColorArray([BG_TOP, BG_TOP, BG_BOTTOM, BG_BOTTOM]))
	var off := fmod(time * 10.0, 64.0)
	for x in range(-64, int(f.x) + 64, 64):
		draw_line(Vector2(x + off, -80), Vector2(x + off, f.y + 80), GRID, 1.0)
	for y in range(0, int(f.y) + 1, 64):
		draw_line(Vector2(-80, y), Vector2(f.x + 80, y), GRID, 1.0)


func _draw_fx() -> void:
	var f := PongGame.FIELD
	if flash > 0.0:
		fx.draw_rect(Rect2(Vector2(-80, -80), f + Vector2(160, 160)), Color(flash_color, flash * 0.16))

	# paredes e rede
	for i in 2:
		var y := 0.0 if i == 0 else f.y - 4.0
		var k := snappedf(wall_glow[i], 0.05)
		_glow(fx, Rect2(0, y, f.x, 4), WALL.lerp(Color.WHITE, k * 0.6), 8 + int(16 * k), 2, 0.55 + 0.45 * k)
	var ny := 6.0
	while ny < f.y:
		_glow(fx, Rect2(f.x / 2 - 3, ny, 6, 18), NET, 8, 3, 0.45)
		ny += 34.0

	# marcador
	for side in 2:
		var size := int(110 + 30 * score_pop[side])
		_glow_text(str(game.scores[side]), f.x / 2 + (-170.0 if side == 0 else 170.0), 130.0, COLORS[side], size)

	# rasto
	for i in trail.size():
		var t := float(i + 1) / trail.size()
		fx.draw_circle(trail[i], game.BALL_SIZE * 0.55 * t, Color(ball_color, 0.28 * t), true, -1.0, true)

	for r in rings:
		fx.draw_arc(r.pos, r.radius, 0.0, TAU, 48, Color(r.color, maxf(r.alpha, 0.0)), 3.0, true)
	for s in sparks:
		var c: Color = s.color
		fx.draw_line(s.pos, s.pos - s.vel * 0.025, Color(c.lerp(Color.WHITE, 0.4), s.life / s.max), 2.0, true)

	for side in 2:
		var p := snappedf(pulse[side], 0.05)
		_glow(fx, game.paddle_rect(side).grow(2.0 * p), COLORS[side], 16 + int(26 * p), 6, 1.0)

	if game.state == PongGame.State.PLAY:
		_glow(fx, game.ball_rect(), ball_color, 22, 8, 1.0)


func _glow(n: CanvasItem, r: Rect2, c: Color, size: int, radius: int, k: float) -> void:
	var key := "%s|%d|%d|%.2f" % [c.to_html(), size, radius, k]
	var sb: StyleBoxFlat = _sb_cache.get(key)
	if sb == null:
		sb = StyleBoxFlat.new()
		sb.bg_color = Color(c.lerp(Color.WHITE, 0.55), k)
		sb.shadow_color = Color(c, 0.7 * k)
		sb.shadow_size = size
		sb.set_corner_radius_all(radius)
		sb.anti_aliasing = true
		_sb_cache[key] = sb
	sb.draw(n.get_canvas_item(), r)


func _glow_text(text: String, center_x: float, baseline: float, c: Color, size: int) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(center_x - w / 2, baseline)
	for layer in [[26, 0.07], [14, 0.14], [6, 0.3]]:
		fx.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, layer[0], Color(c, layer[1]))
	fx.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c.lerp(Color.WHITE, 0.45))


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.04, 0.02, 0.13, 0.88),
		"border": Color("8a5cff"),
		"text": Color("ece6ff"),
		"accent": COLORS[0],
		"button": Color("170a36"),
		"button_hover": Color("2a1361"),
		"radius": 10,
		"dim": Color(0, 0, 0, 0.25),
	}
