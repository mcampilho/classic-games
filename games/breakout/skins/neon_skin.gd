extends BreakoutSkin
## Neon: tijolos de luz num arco-íris elétrico, faíscas, ondas de choque, pontos a flutuar
## e combos — cada tijolo seguido sem tocar na raquete soa meio tom acima.

const BG_TOP := Color("0a0320")
const BG_BOTTOM := Color("1b0639")
const GRID := Color(0.55, 0.3, 1.0, 0.08)
const WALL_C := Color("7b4dff")
const PADDLE_C := Color("19f0ff")
const BALL_C := Color("fff4d6")
const ROW_COLORS := [
	Color("ff2bd6"), Color("ff3f8e"), Color("ff7a3d"), Color("ffc53d"),
	Color("b6ff3d"), Color("3dffa0"), Color("19f0ff"), Color("5b7bff"),
]

var fx: Node2D
var font: Font
var time := 0.0
var shake := 0.0
var flash := 0.0
var flash_color := Color.WHITE
var combo := 0
var paddle_pulse := 0.0
var wall_glow := PackedFloat32Array([0.0, 0.0, 0.0])
var score_pop := 0.0
var ball_color := BALL_C
var trail: Array[Vector2] = []
var sparks: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var popups: Array[Dictionary] = []
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
	sfx.brick = Synth.to_stream(Synth.mix([
		Synth.render(523.25, 0.16, {"wave": "triangle", "volume": 0.35, "decay": 22.0}),
		Synth.render(1046.5, 0.08, {"wave": "sine", "volume": 0.12, "decay": 40.0}),
	]))
	sfx.paddle = Synth.tone(180.0, 0.12, {"wave": "square", "freq_end": 360.0, "volume": 0.2, "decay": 16.0, "lowpass": 0.4})
	sfx.wall = Synth.tone(1200.0, 0.05, {"wave": "triangle", "freq_end": 800.0, "volume": 0.22, "decay": 40.0})
	sfx.shrink = Synth.tone(880.0, 0.25, {"wave": "sine", "freq_end": 330.0, "volume": 0.3})
	sfx.lose = Synth.tone(420.0, 0.7, {"wave": "saw", "freq_end": 55.0, "volume": 0.28, "lowpass": 0.25, "decay": 2.0})
	var arp := []
	for f in [523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5, 1318.5]:
		arp.append(Synth.render(f, 0.09, {"wave": "square", "volume": 0.15, "lowpass": 0.3}))
	arp.append(Synth.render(1568.0, 0.5, {"wave": "square", "volume": 0.15, "decay": 5.0, "lowpass": 0.3}))
	sfx.clear = Synth.concat(arp)
	sfx.serve = Synth.tone(220.0, 0.14, {"wave": "sine", "freq_end": 520.0, "volume": 0.3})


# ---------------------------------------------------------------- eventos

func _on_match_started() -> void:
	sparks.clear()
	rings.clear()
	popups.clear()
	combo = 0


func _on_turn_started(_player: int) -> void:
	combo = 0
	trail.clear()


func _on_served() -> void:
	ball_color = BALL_C
	play("serve", 1.0, -4.0)
	rings.append({"pos": game.ball_pos, "radius": 4.0, "alpha": 0.7, "color": BALL_C, "speed": 180.0})


func _on_paddle_hit(pos: Vector2) -> void:
	combo = 0
	play("paddle", 1.0 + game.speed_level * 0.06)
	paddle_pulse = 1.0
	ball_color = PADDLE_C
	rings.append({"pos": pos, "radius": 6.0, "alpha": 0.8, "color": PADDLE_C, "speed": 260.0})
	_burst(pos, Vector2.UP, PADDLE_C, 8)


func _on_wall_hit(pos: Vector2) -> void:
	play("wall")
	var i := 1
	if pos.x <= BreakoutGame.INNER.position.x + 1.0:
		i = 0
	elif pos.x >= BreakoutGame.INNER.end.x - 1.0:
		i = 2
	wall_glow[i] = 1.0


func _on_brick_broken(row: int, _col: int, pos: Vector2, points: int) -> void:
	combo += 1
	play("brick", pow(2.0, minf(combo - 1, 15) / 12.0))
	var c: Color = ROW_COLORS[row]
	ball_color = c
	shake = maxf(shake, 2.0 + minf(combo, 10) * 0.5)
	score_pop = 1.0
	rings.append({"pos": pos, "radius": 8.0, "alpha": 0.8, "color": c, "speed": 220.0})
	_burst(pos, Vector2(0, 1 if game.ball_vel.y > 0 else -1), c, 12)
	var txt := "+%d" % points
	if combo >= 3:
		txt += "  x%d" % combo
	popups.append({"pos": pos, "text": txt, "life": 0.9, "color": c})


func _on_paddle_shrunk() -> void:
	play("shrink")
	paddle_pulse = 1.0
	flash = 0.6
	flash_color = ROW_COLORS[0]


func _on_ball_lost(_player: int) -> void:
	play("lose")
	shake = 14.0
	flash = 0.9
	flash_color = Color("ff2b4f")
	var p := Vector2(clampf(game.ball_pos.x, 260.0, 1020.0), BreakoutGame.SCREEN.y)
	_burst(p, Vector2.UP, Color("ff2b4f"), 36)
	trail.clear()


func _on_wall_cleared(_player: int) -> void:
	play("clear")
	flash = 1.0
	flash_color = PADDLE_C
	shake = 10.0
	for i in 6:
		rings.append({"pos": BreakoutGame.INNER.get_center(), "radius": 10.0 + i * 30.0, "alpha": 1.0, "color": ROW_COLORS[i], "speed": 600.0})


func _burst(pos: Vector2, dir: Vector2, c: Color, count: int) -> void:
	for i in count:
		var life := randf_range(0.25, 0.65)
		sparks.append({
			"pos": pos,
			"vel": dir.rotated(randf_range(-1.4, 1.4)) * randf_range(140.0, 620.0),
			"life": life, "max": life, "color": c,
		})


# ---------------------------------------------------------------- animação

func _tick(dt: float) -> void:
	time += dt
	shake = move_toward(shake, 0.0, dt * 45.0)
	flash = move_toward(flash, 0.0, dt * 2.5)
	paddle_pulse = move_toward(paddle_pulse, 0.0, dt * 4.0)
	score_pop = move_toward(score_pop, 0.0, dt * 4.0)
	for i in 3:
		wall_glow[i] = move_toward(wall_glow[i], 0.0, dt * 3.5)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake

	if game.ball_visible():
		trail.append(game.ball_pos)
		if trail.size() > 16:
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
	for p in popups:
		p.pos.y -= 60.0 * dt
		p.life -= dt
	popups = popups.filter(func(p: Dictionary) -> bool: return p.life > 0.0)
	fx.queue_redraw()


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var s := BreakoutGame.SCREEN
	var a := Vector2(-80, -80)
	var b := s + Vector2(80, 80)
	draw_polygon(
		PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)]),
		PackedColorArray([BG_TOP, BG_TOP, BG_BOTTOM, BG_BOTTOM]))
	var off := fmod(time * 12.0, 64.0)
	for x in range(-64, int(s.x) + 64, 64):
		draw_line(Vector2(x, -80), Vector2(x, s.y + 80), GRID, 1.0)
	for y in range(-64, int(s.y) + 64, 64):
		draw_line(Vector2(-80, y + off), Vector2(s.x + 80, y + off), GRID, 1.0)
	# o campo é ligeiramente mais escuro que as laterais
	draw_rect(BreakoutGame.INNER, Color(0, 0, 0, 0.35))


func _draw_fx() -> void:
	var g := game
	var inner := BreakoutGame.INNER
	if flash > 0.0:
		fx.draw_rect(Rect2(Vector2(-80, -80), BreakoutGame.SCREEN + Vector2(160, 160)), Color(flash_color, flash * 0.14))

	# paredes
	var walls := [
		Rect2(inner.position.x - 6, inner.position.y, 4, inner.size.y),
		Rect2(inner.position.x - 6, inner.position.y - 6, inner.size.x + 12, 4),
		Rect2(inner.end.x + 2, inner.position.y, 4, inner.size.y),
	]
	for i in 3:
		var k := snappedf(wall_glow[i], 0.1)
		_glow(walls[i], WALL_C.lerp(Color.WHITE, k * 0.6), 8 + int(14 * k), 2, 0.6 + 0.4 * k)

	# tijolos
	for row in BreakoutGame.ROWS:
		var c: Color = ROW_COLORS[row]
		for col in BreakoutGame.COLS:
			if g.brick_alive(row, col):
				var k := snappedf(0.8 + 0.2 * sin(time * 2.2 - col * 0.45 + row * 0.5), 0.05)
				_glow(g.brick_rect(row, col).grow(-4.0), c, 7, 4, k)

	# rasto, anéis, faíscas
	for i in trail.size():
		var t := float(i + 1) / trail.size()
		fx.draw_circle(trail[i], BreakoutGame.BALL * 0.5 * t, Color(ball_color, 0.3 * t), true, -1.0, true)
	for r in rings:
		fx.draw_arc(r.pos, r.radius, 0.0, TAU, 48, Color(r.color, maxf(r.alpha, 0.0)), 3.0, true)
	for s in sparks:
		fx.draw_line(s.pos, s.pos - s.vel * 0.025, Color(s.color.lerp(Color.WHITE, 0.4), s.life / s.max), 2.0, true)

	var p := snappedf(paddle_pulse, 0.1)
	_glow(g.paddle_rect().grow(2.0 * p), PADDLE_C.lerp(ROW_COLORS[0], p if g.player().small else 0.0), 16 + int(22 * p), 7, 1.0)
	if g.ball_visible():
		_glow(g.ball_rect(), ball_color.lerp(Color.WHITE, 0.6), 20, 6, 1.0)

	for pp in popups:
		var a := clampf(pp.life / 0.5, 0.0, 1.0)
		_text(pp.text, pp.pos.x, pp.pos.y, pp.color, 22, a)

	_draw_panels()


func _draw_panels() -> void:
	var g := game
	var inner := BreakoutGame.INNER
	var lx := (inner.position.x - 10) / 2
	var rx := inner.end.x + 10 + (BreakoutGame.SCREEN.x - inner.end.x - 10) / 2
	_draw_player_panel(0, lx)
	if g.players.size() > 1:
		_draw_player_panel(1, rx)
	else:
		_text(I18n.t("RECORDE"), rx, 92, WALL_C.lerp(Color.WHITE, 0.3), 20, 0.9)
		_text(str(maxi(g.best, g.players[0].score)), rx, 150, ROW_COLORS[3], 48, 0.9)
		_text(I18n.t("PAREDE"), rx, 250, WALL_C.lerp(Color.WHITE, 0.3), 20, 0.9)
		_text(str(g.players[0].wall), rx, 308, ROW_COLORS[5], 48, 0.9)


func _draw_player_panel(i: int, cx: float) -> void:
	var g := game
	var pl: Dictionary = g.players[i]
	var active := i == g.current
	var a := 1.0 if active else 0.4
	var c: Color = PADDLE_C if i == 0 else ROW_COLORS[0]
	_text(I18n.t("JOGADOR %d") % (i + 1), cx, 92, WALL_C.lerp(Color.WHITE, 0.3), 20, a)
	var size := int(56 + (14 * score_pop if active else 0.0))
	_text(str(pl.score), cx, 158, c, size, a)
	_text(I18n.t("BOLAS"), cx, 250, WALL_C.lerp(Color.WHITE, 0.3), 20, a)
	var n: int = pl.balls
	for k in g.start_balls:
		var pos := Vector2(cx - (g.start_balls - 1) * 14.0 + k * 28.0, 284)
		if k < n:
			_glow(Rect2(pos - Vector2(6, 6), Vector2(12, 12)), BALL_C, 8, 6, a)
		else:
			fx.draw_arc(pos, 6, 0, TAU, 20, Color(BALL_C, 0.15 * a), 1.5, true)
	if g.players.size() > 1:
		_text(I18n.t("PAREDE %d") % pl.wall, cx, 340, WALL_C.lerp(Color.WHITE, 0.3), 18, a)


func _glow(r: Rect2, c: Color, size: int, radius: int, k: float) -> void:
	var key := "%s|%d|%d|%.2f" % [c.to_html(), size, radius, k]
	var sb: StyleBoxFlat = _sb_cache.get(key)
	if sb == null:
		sb = StyleBoxFlat.new()
		sb.bg_color = Color(c.lerp(Color.WHITE, 0.18), k)
		sb.shadow_color = Color(c, 0.6 * k)
		sb.shadow_size = size
		sb.set_corner_radius_all(radius)
		sb.anti_aliasing = true
		_sb_cache[key] = sb
	sb.draw(fx.get_canvas_item(), r)


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
		"accent": PADDLE_C,
		"button": Color("170a36"),
		"button_hover": Color("2a1361"),
		"radius": 10,
		"dim": Color(0, 0, 0, 0.3),
	}
