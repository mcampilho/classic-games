extends BreakoutSkin
## Vitral (estilo próprio): a parede de tijolos é um vitral de catedral.
## A bola é uma esfera de luz que ilumina os vidros por onde passa; cada vidro partido
## cai em estilhaços e deixa só a moldura de chumbo. Sons de vidro, bronze, pedra e sinos.

const STONE := Color("2b2723")
const STONE_LINE := Color(0.08, 0.07, 0.06, 0.55)
const FRAME := Color("8a7f70")
const NIGHT_TOP := Color("0c1222")
const NIGHT_BOTTOM := Color("1b1a2c")
const LEAD := Color("17181b")
const GOLD := Color("e2b350")
const LIGHT := Color("ffd98a")
const ROW_COLORS := [
	Color("b3122e"), Color("c4283a"),    # rubi
	Color("d9821c"), Color("e3a21f"),    # âmbar
	Color("1c8a52"), Color("23a067"),    # esmeralda
	Color("1d4fa8"), Color("2a63c4"),    # safira
]

var font: Font
var fx: Node2D
var time := 0.0
var pane_colors := PackedColorArray()
var shards: Array[Dictionary] = []
var glitter: Array[Dictionary] = []
var trail: Array[Vector2] = []
var paddle_flash := 0.0
var shake := 0.0


func _setup() -> void:
	font = ThemeDB.fallback_font
	var rng := RandomNumberGenerator.new()
	rng.seed = 1976
	for row in BreakoutGame.ROWS:
		for col in BreakoutGame.COLS:
			var c: Color = ROW_COLORS[row]
			c.h = wrapf(c.h + rng.randf_range(-0.015, 0.015), 0.0, 1.0)
			c.v = clampf(c.v + rng.randf_range(-0.08, 0.06), 0.0, 1.0)
			pane_colors.append(c)
	fx = Node2D.new()
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = m
	add_child(fx)
	fx.draw.connect(_draw_fx)


# ---------------------------------------------------------------- sons

static func _bell(f: float, dur: float, vol: float, ratios := [1.0, 2.76, 5.4]) -> PackedFloat32Array:
	var parts := []
	var decays := [3.0, 6.0, 11.0]
	var vols := [1.0, 0.45, 0.22]
	for i in ratios.size():
		parts.append(Synth.render(f * ratios[i], dur, {"wave": "sine", "volume": vol * vols[i], "decay": decays[i] * 2.4 / dur, "attack": 0.001}))
	return Synth.mix(parts)


static func _at(t: float, s: PackedFloat32Array) -> PackedFloat32Array:
	var out := Synth.silence(t)
	out.append_array(s)
	return out


func _build_sfx() -> void:
	var tones := [1568.0, 1318.5, 1174.7, 987.8]
	for i in 4:
		sfx["brick%d" % i] = Synth.to_stream(Synth.mix([
			_bell(tones[i], 0.35, 0.22),
			Synth.render(0.0, 0.07, {"wave": "noise", "volume": 0.16, "decay": 55.0, "lowpass": 0.9}),
		]))
	sfx.paddle = Synth.to_stream(Synth.mix([
		_bell(262.0, 0.3, 0.32, [1.0, 2.0, 3.01]),
		Synth.render(0.0, 0.03, {"wave": "noise", "volume": 0.18, "decay": 90.0, "lowpass": 0.12}),
	]))
	sfx.wall = Synth.to_stream(Synth.mix([
		Synth.render(140.0, 0.08, {"wave": "sine", "volume": 0.4, "decay": 45.0}),
		Synth.render(0.0, 0.05, {"wave": "noise", "volume": 0.22, "decay": 70.0, "lowpass": 0.18}),
	]))
	sfx.lose = Synth.to_stream(_bell(110.0, 1.8, 0.45))
	sfx.shrink = Synth.to_stream(Synth.mix([_bell(659.3, 0.6, 0.25), _at(0.14, _bell(523.3, 0.6, 0.25))]))
	var chime := []
	var notes := [784.0, 987.8, 1174.7, 1568.0, 1174.7, 1568.0]
	for i in notes.size():
		chime.append(_at(i * 0.13, _bell(notes[i], 1.0, 0.2)))
	sfx.clear = Synth.to_stream(Synth.mix(chime))


# ---------------------------------------------------------------- eventos

func _on_match_started() -> void:
	shards.clear()
	glitter.clear()


func _on_turn_started(_player: int) -> void:
	trail.clear()


func _on_paddle_hit(_pos: Vector2) -> void:
	play("paddle", randf_range(0.97, 1.03))
	paddle_flash = 1.0


func _on_wall_hit(_pos: Vector2) -> void:
	play("wall", randf_range(0.9, 1.1))


func _on_brick_broken(row: int, col: int, pos: Vector2, _points: int) -> void:
	play("brick%d" % (row / 2), randf_range(0.96, 1.04))
	shake = maxf(shake, 2.0)
	var c := pane_colors[row * BreakoutGame.COLS + col]
	var down := game.ball_vel.y > 0.0
	for i in 8:
		var pts := PackedVector2Array()
		var base := randf() * TAU
		for k in 3:
			pts.append(Vector2.from_angle(base + k * TAU / 3 + randf_range(-0.6, 0.6)) * randf_range(5.0, 13.0))
		shards.append({
			"pos": pos + Vector2(randf_range(-22, 22), randf_range(-8, 8)),
			"vel": Vector2(randf_range(-170, 170), randf_range(-260, -40) if not down else randf_range(40, 200)),
			"rot": randf() * TAU, "spin": randf_range(-9, 9), "pts": pts, "color": c,
		})
	for i in 10:
		glitter.append({"pos": pos + Vector2(randf_range(-24, 24), randf_range(-10, 10)),
			"vel": Vector2(randf_range(-90, 90), randf_range(-120, 40)), "life": randf_range(0.3, 0.8)})
	if shards.size() > 220:
		shards = shards.slice(shards.size() - 220)


func _on_paddle_shrunk() -> void:
	play("shrink")
	paddle_flash = 1.0


func _on_ball_lost(_player: int) -> void:
	play("lose")
	shake = 9.0
	trail.clear()


# ---------------------------------------------------------------- animação

func _tick(dt: float) -> void:
	time += dt
	paddle_flash = move_toward(paddle_flash, 0.0, dt * 3.0)
	shake = move_toward(shake, 0.0, dt * 30.0)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	for s in shards:
		s.vel.y += 1500.0 * dt
		s.pos += s.vel * dt
		s.rot += s.spin * dt
	shards = shards.filter(func(s: Dictionary) -> bool: return s.pos.y < 760.0)
	for gl in glitter:
		gl.pos += gl.vel * dt
		gl.life -= dt
	glitter = glitter.filter(func(gl: Dictionary) -> bool: return gl.life > 0.0)
	if game.ball_visible():
		trail.append(game.ball_pos)
		if trail.size() > 10:
			trail.pop_front()
	elif not trail.is_empty():
		trail.pop_front()
	fx.queue_redraw()


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var g := game
	var s := BreakoutGame.SCREEN
	var inner := BreakoutGame.INNER
	var w := BreakoutGame.WALL

	# parede de pedra
	draw_rect(Rect2(Vector2(-40, -40), s + Vector2(80, 80)), STONE)
	var rows := 0
	for y in range(-8, int(s.y) + 48, 48):
		draw_line(Vector2(-40, y), Vector2(s.x + 40, y), STONE_LINE, 2.0)
		var off := 0 if rows % 2 == 0 else 48
		for x in range(-96 + off, int(s.x) + 96, 96):
			draw_line(Vector2(x, y), Vector2(x, y + 48), STONE_LINE, 2.0)
		rows += 1

	# a janela: céu noturno com vidro simples em losangos
	draw_polygon(
		PackedVector2Array([inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]),
		PackedColorArray([NIGHT_TOP, NIGHT_TOP, NIGHT_BOTTOM, NIGHT_BOTTOM]))
	var q := Color(0.6, 0.65, 0.8, 0.07)
	for k in range(-int(inner.size.y), int(inner.size.x), 48):
		var x0 := inner.position.x + k
		draw_line(Vector2(x0, inner.position.y), Vector2(x0 + inner.size.y, inner.end.y), q, 1.5)
		draw_line(Vector2(x0 + inner.size.y, inner.position.y), Vector2(x0, inner.end.y), q, 1.5)
	# o chão de pedra por baixo da raquete apanha a luz
	draw_rect(Rect2(inner.position.x, BreakoutGame.PADDLE_Y + 22, inner.size.x, s.y), Color(0.05, 0.05, 0.07, 0.5))

	# moldura de pedra
	for r in [Rect2(inner.position.x - w, inner.position.y - w, w, s.y), Rect2(inner.end.x, inner.position.y - w, w, s.y),
			Rect2(inner.position.x - w, inner.position.y - w, inner.size.x + 2 * w, w)]:
		draw_rect(r, FRAME)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color(1, 1, 1, 0.18))
		draw_rect(Rect2(r.position, Vector2(2, r.size.y)), Color(1, 1, 1, 0.12))
	draw_rect(inner.grow(1.0), Color(0, 0, 0, 0.45), false, 2.0)

	# vitral
	var sweep := fmod(time * 0.16, 1.7) - 0.35
	for row in BreakoutGame.ROWS:
		for col in BreakoutGame.COLS:
			var r := g.brick_rect(row, col)
			if not g.brick_alive(row, col):
				draw_rect(r.grow(-1.5), Color(LEAD, 0.55), false, 3.0)   # fica a moldura de chumbo
				continue
			var c := pane_colors[row * BreakoutGame.COLS + col]
			var lit := 0.0
			if g.ball_visible():
				lit = pow(clampf(1.0 - r.get_center().distance_to(g.ball_pos) / 190.0, 0.0, 1.0), 2.0) * 0.55
			var u := (r.position.x - inner.position.x + (r.position.y - BreakoutGame.BRICK_TOP) * 1.6) / (inner.size.x + 320.0)
			var glint := clampf(1.0 - absf(u - sweep) * 9.0, 0.0, 1.0) * 0.3
			var fill := c.lightened(lit + glint)
			draw_rect(r, fill)
			# espessura do vidro: reflexo em cima, sombra em baixo, veio diagonal
			draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 5), Color(1, 1, 1, 0.14 + lit * 0.3))
			draw_rect(Rect2(r.position.x, r.end.y - 6, r.size.x, 6), Color(0, 0, 0, 0.18))
			var sx := r.position.x + fmod(col * 17.0 + row * 7.0, 30.0)
			draw_colored_polygon(PackedVector2Array([
				Vector2(sx, r.end.y - 2), Vector2(sx + 8, r.end.y - 2), Vector2(sx + 20, r.position.y + 2), Vector2(sx + 14, r.position.y + 2)]),
				Color(1, 1, 1, 0.1 + lit * 0.2))
			draw_rect(r.grow(-1.5), LEAD, false, 3.0)
			draw_line(r.position + Vector2(2, 3), Vector2(r.end.x - 2, r.position.y + 3), Color(0.55, 0.55, 0.6, 0.35), 1.0)

	# estilhaços
	for sh in shards:
		draw_set_transform(sh.pos, sh.rot, Vector2.ONE)
		draw_colored_polygon(sh.pts, Color(sh.color.lightened(0.15), 0.9))
		var outline: PackedVector2Array = sh.pts.duplicate()
		outline.append(sh.pts[0])
		draw_polyline(outline, Color(1, 1, 1, 0.35), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# raquete de bronze
	var pr := g.paddle_rect()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("a87436").lightened(paddle_flash * 0.3)
	sb.border_color = Color("4f3214")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(7)
	sb.anti_aliasing = true
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 3)
	draw_style_box(sb, pr)
	draw_line(pr.position + Vector2(6, 3.5), Vector2(pr.end.x - 6, pr.position.y + 3.5), Color("f1cf8a"), 2.0, true)

	_draw_panels()


func _draw_fx() -> void:
	var g := game
	var inner := BreakoutGame.INNER
	# raios de luz que atravessam a janela
	for i in 3:
		var x := inner.position.x + 120.0 + i * 250.0 + sin(time * 0.3 + i) * 20.0
		var a := 0.035 + 0.015 * sin(time * 0.7 + i * 2.0)
		fx.draw_colored_polygon(PackedVector2Array([
			Vector2(x, inner.position.y), Vector2(x + 70, inner.position.y),
			Vector2(x + 250, inner.end.y), Vector2(x + 110, inner.end.y)]), Color(LIGHT, a))

	for i in trail.size():
		var t := float(i + 1) / trail.size()
		fx.draw_circle(trail[i], 7.0 * t, Color(LIGHT, 0.12 * t), true, -1.0, true)
	if g.ball_visible():
		var p := g.ball_pos
		for layer in [[46.0, 0.05], [28.0, 0.09], [16.0, 0.18], [9.0, 0.35]]:
			fx.draw_circle(p, layer[0], Color(LIGHT, layer[1]), true, -1.0, true)
		fx.draw_circle(p, 6.0, Color("fff6e0"), true, -1.0, true)
		# a luz da bola reflete-se no chão
		fx.draw_circle(Vector2(p.x, BreakoutGame.PADDLE_Y + 34), 40.0, Color(LIGHT, 0.04 * clampf(p.y / 700.0, 0.0, 1.0)), true, -1.0, true)
	for gl in glitter:
		fx.draw_rect(Rect2(gl.pos - Vector2(1.5, 1.5), Vector2(3, 3)), Color(1, 0.95, 0.8, clampf(gl.life * 2.0, 0.0, 1.0)))


func _draw_panels() -> void:
	var g := game
	var inner := BreakoutGame.INNER
	var w := BreakoutGame.WALL
	var lx := (inner.position.x - w) / 2
	var rx := inner.end.x + w + (BreakoutGame.SCREEN.x - inner.end.x - w) / 2
	_tablet(lx)
	_tablet(rx)
	_draw_player(0, lx)
	if g.players.size() > 1:
		_draw_player(1, rx)
	else:
		_carve(I18n.t("RECORDE"), rx, 104, 18, 1.0)
		_carve(str(maxi(g.best, g.players[0].score)), rx, 160, 46, 1.0)
		_carve(I18n.t("VITRAL"), rx, 250, 18, 1.0)
		_carve(_roman(g.players[0].wall), rx, 304, 40, 1.0)


func _draw_player(i: int, cx: float) -> void:
	var g := game
	var pl: Dictionary = g.players[i]
	var a := 1.0 if (i == g.current or g.players.size() == 1) else 0.45
	_carve(I18n.t("JOGADOR ") + _roman(i + 1), cx, 104, 18, a)
	_carve(str(pl.score), cx, 160, 46, a)
	_carve(I18n.t("BOLAS"), cx, 250, 18, a)
	for k in g.start_balls:
		var pos := Vector2(cx - (g.start_balls - 1) * 14.0 + k * 28.0, 280)
		if k < pl.balls:
			draw_circle(pos, 8.0, Color(LIGHT, 0.25 * a), true, -1.0, true)
			draw_circle(pos, 5.0, Color(Color("fff6e0"), a), true, -1.0, true)
		else:
			draw_arc(pos, 5.0, 0, TAU, 20, Color(0, 0, 0, 0.5 * a), 2.0, true)
	if g.players.size() > 1:
		_carve(I18n.t("VITRAL ") + _roman(pl.wall), cx, 336, 16, a)


func _tablet(cx: float) -> void:
	var r := Rect2(cx - 94, 56, 188, 310)
	draw_rect(r, Color("3a342e"))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), Color(0, 0, 0, 0.4))
	draw_rect(Rect2(r.position.x, r.end.y - 2, r.size.x, 2), Color(1, 1, 1, 0.12))
	draw_rect(r, Color("8a7f70"), false, 2.0)


## Letras em folha de ouro gravadas na pedra.
func _carve(text: String, cx: float, baseline: float, size: int, alpha: float) -> void:
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(cx - tw / 2, baseline)
	draw_string(font, pos + Vector2(0, -1.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.6 * alpha))
	draw_string(font, pos + Vector2(0, 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(1, 1, 1, 0.12 * alpha))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(GOLD, alpha))


static func _roman(n: int) -> String:
	var vals := [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"],
		[50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]
	var out := ""
	for v in vals:
		while n >= v[0]:
			out += v[1]
			n -= v[0]
	return out


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.13, 0.115, 0.1, 0.95),
		"border": Color("b8913f"),
		"text": Color("f1e6c8"),
		"accent": GOLD,
		"button": Color("2a2520"),
		"button_hover": Color("3d342a"),
		"radius": 6,
		"dim": Color(0, 0, 0, 0.3),
	}
