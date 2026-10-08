extends InvadersSkin
## Azulejo (estilo próprio): a invasão pintada num painel de azulejos portugueses.
## Invasores a azul-cobalto com pinceladas irregulares, disco voador e canhão com ocre,
## azulejos que estalam a cada invasor abatido e lascas de cerâmica a cair.
## Sons de marimba, cerâmica e sinos.

const TILE := 16.0                       # 1 azulejo = 16 unidades (48 px)
const GLAZE := Color("f4f1e8")
const GROUT := Color("d6d0bf")
const COBALT := Color("1f3f9e")
const BLUE_MID := Color("3561c2")
const BLUE_LIGHT := Color("7c9ee0")
const OCHRE := Color("d39b1f")
const KIND_COLORS := [Color("1a3590"), Color("2a52b4"), Color("3c6bcc")]

var font: Font
var bg: Node2D
var bg_vp: SubViewport
var fx: Node2D
var tex := {}
var cracks: Array[Dictionary] = []       # {pos, lines: Array[PackedVector2Array], life}
var chips: Array[Dictionary] = []
var shake := 0.0


func _setup() -> void:
	font = ThemeDB.fallback_font
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Fundo estático (milhares de traços): desenhado uma única vez para uma textura.
	bg_vp = SubViewport.new()
	bg_vp.size = Vector2i(1280, 720)
	bg_vp.disable_3d = true
	bg_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(bg_vp)
	bg = Node2D.new()
	bg_vp.add_child(bg)
	bg.draw.connect(_draw_background)
	fx = Node2D.new()
	fx.z_index = 1
	add_child(fx)
	fx.draw.connect(_draw_fx)
	for kind in 3:
		for f in 2:
			tex["a%d%d" % [kind, f]] = InvaderSprites.texture(InvaderSprites.ALIENS[kind][f], KIND_COLORS[kind], 3, 0, _brush)
	tex.ufo = InvaderSprites.texture(InvaderSprites.UFO, OCHRE, 3, 0, func(x: int, y: int, c: Color) -> Color:
		return _brush(x, y, COBALT if y == 4 or y == 6 else c))
	tex.player = InvaderSprites.texture(InvaderSprites.PLAYER, COBALT, 3, 0, func(x: int, y: int, c: Color) -> Color:
		return _brush(x, y, OCHRE if y <= 2 else c))
	for k in 3:
		for f in 2:
			tex["b%d%d" % [k, f]] = InvaderSprites.texture(InvaderSprites.BOMBS[k][f], COBALT, 3, 0, _brush)


## Pincelada: cada ponto com uma variação ligeira de tom, como tinta à mão sobre o vidrado.
static func _brush(x: int, y: int, c: Color) -> Color:
	var h := hash(Vector2i(x * 31 + 7, y * 17 + 3))
	var v := float(h % 1000) / 1000.0
	return c.lightened((v - 0.5) * 0.28)


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
	var notes := [110.0, 98.0, 87.31, 82.41]
	for i in 4:
		sfx["march%d" % i] = Synth.to_stream(_bell(notes[i], 0.22, 0.6, [1.0, 4.0, 9.2]))   # marimba
	sfx.shoot = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.12, {"wave": "noise", "volume": 0.16, "lowpass": 0.25, "decay": 25.0}),
		Synth.render(700.0, 0.1, {"wave": "sine", "freq_end": 1500.0, "volume": 0.12, "decay": 22.0}),
	]))
	sfx.kill = Synth.to_stream(Synth.mix([
		_bell(1760.0, 0.25, 0.18),
		Synth.render(0.0, 0.09, {"wave": "noise", "volume": 0.25, "lowpass": 0.7, "decay": 45.0}),
	]))
	var flute := []
	for i in 3:
		flute.append(Synth.render(880.0, 0.08, {"wave": "sine", "freq_end": 940.0, "volume": 0.16, "attack": 0.0, "release": 0.0}))
		flute.append(Synth.render(940.0, 0.08, {"wave": "sine", "freq_end": 880.0, "volume": 0.16, "attack": 0.0, "release": 0.0}))
	sfx.ufo = Synth.concat(flute)
	var chime := []
	var ns := [1046.5, 1318.5, 1568.0, 2093.0]
	for i in ns.size():
		chime.append(_at(i * 0.09, _bell(ns[i], 0.6, 0.18)))
	sfx.ufo_hit = Synth.to_stream(Synth.mix(chime))
	var shatter := [Synth.render(0.0, 0.5, {"wave": "noise", "volume": 0.3, "lowpass": 0.8, "decay": 8.0}),
		Synth.render(0.0, 1.0, {"wave": "noise", "volume": 0.2, "lowpass": 0.08, "decay": 3.0})]
	for i in 5:
		shatter.append(_at(0.04 + i * 0.07, _bell(1400.0 + i * 310.0, 0.3, 0.12)))
	sfx.player_hit = Synth.to_stream(Synth.mix(shatter))
	sfx.extra = Synth.to_stream(Synth.mix([_bell(1318.5, 0.6, 0.2), _at(0.12, _bell(1760.0, 0.6, 0.2))]))
	sfx.bunker = Synth.tone(160.0, 0.08, {"wave": "sine", "volume": 0.3, "decay": 40.0})


# ---------------------------------------------------------------- eventos

func _on_match_started() -> void:
	super()
	cracks.clear()
	chips.clear()


func _on_turn_started(player: int) -> void:
	super(player)
	cracks.clear()


func _on_alien_killed(row: int, col: int, pos: Vector2, points: int, kind: int) -> void:
	super(row, col, pos, points, kind)
	_crack(pos, 5, 9.0)
	_chips(pos, 7, KIND_COLORS[kind])


func _on_player_hit(pos: Vector2) -> void:
	super(pos)
	_crack(pos, 9, 22.0)
	_chips(pos, 18, OCHRE)
	shake = 10.0


func _on_ufo_killed(pos: Vector2, points: int) -> void:
	super(pos, points)
	_crack(pos, 7, 14.0)
	_chips(pos, 12, OCHRE)


func _on_shot_blocked(pos: Vector2, by_bunker: bool) -> void:
	if by_bunker:
		play("bunker", randf_range(0.9, 1.1))
		_chips(pos, 3, BLUE_MID)


func _crack(pos: Vector2, n: int, size: float) -> void:
	var lines: Array[PackedVector2Array] = []
	for i in n:
		var pts := PackedVector2Array([pos])
		var a := randf() * TAU
		var p := pos
		for k in 3:
			a += randf_range(-0.6, 0.6)
			p += Vector2.from_angle(a) * size * randf_range(0.3, 0.5)
			pts.append(p)
		lines.append(pts)
	cracks.append({"lines": lines, "life": 0.7})


func _chips(pos: Vector2, n: int, c: Color) -> void:
	for i in n:
		chips.append({"pos": pos, "vel": Vector2(randf_range(-50, 50), randf_range(-70, -10)),
			"rot": randf() * TAU, "spin": randf_range(-10, 10), "size": randf_range(1.0, 2.4), "color": c})
	if chips.size() > 160:
		chips = chips.slice(chips.size() - 160)


# ---------------------------------------------------------------- animação

func _tick(dt: float) -> void:
	shake = move_toward(shake, 0.0, dt * 30.0)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	for c in cracks:
		c.life -= dt
	cracks = cracks.filter(func(c: Dictionary) -> bool: return c.life > 0.0)
	for c in chips:
		c.vel.y += 260.0 * dt
		c.pos += c.vel * dt
		c.rot += c.spin * dt
	chips = chips.filter(func(c: Dictionary) -> bool: return c.pos.y < InvadersGame.GROUND_Y + 4)
	fx.queue_redraw()


# ---------------------------------------------------------------- desenho

func _draw_background() -> void:
	var field := Rect2(InvadersGame.ORIGIN, InvadersGame.FIELD * S)
	var t := TILE * S
	var x0 := InvadersGame.ORIGIN.x - ceilf(InvadersGame.ORIGIN.x / t) * t
	var rng := RandomNumberGenerator.new()
	rng.seed = 1755
	var y := 0.0
	while y < 720.0:
		var x := x0
		while x < 1280.0:
			var r := Rect2(x, y, t, t)
			var inside := field.encloses(r)
			bg.draw_rect(r, GLAZE.darkened(rng.randf_range(0.0, 0.04)))
			if inside:
				_tile_pattern(r, 0.10)
			else:
				_tile_pattern(r, 1.0)
			bg.draw_rect(r, GROUT, false, 2.0)
			x += t
		y += t
	# moldura (barra) à volta do campo
	bg.draw_rect(field.grow(10), COBALT, false, 8.0)
	bg.draw_rect(field.grow(4), BLUE_LIGHT, false, 2.0)
	# cartelas para os textos dos painéis
	for cx in [panel_left_x(), panel_right_x()]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = GLAZE
		sb.border_color = COBALT
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(18)
		sb.anti_aliasing = true
		bg.draw_style_box(sb, Rect2(cx - 120, 40, 240, 300))
		bg.draw_style_box(sb, Rect2(cx - 120, 520, 240, 190))


## Padrão clássico de azulejo: quartos de círculo nos cantos e uma flor ao centro.
func _tile_pattern(r: Rect2, alpha: float) -> void:
	var c := Color(COBALT, 0.85 * alpha)
	var l := Color(BLUE_LIGHT, 0.7 * alpha)
	var s := r.size.x
	for corner: Vector2 in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var start := (r.get_center() - corner).angle() - PI / 4
		bg.draw_arc(corner, s * 0.32, start, start + PI / 2, 10, c, 3.0, true)
		bg.draw_arc(corner, s * 0.2, start, start + PI / 2, 8, l, 2.0, true)
	var m := r.get_center()
	for k in 4:
		var d := Vector2.from_angle(k * PI / 2) * s * 0.17
		bg.draw_circle(m + d, s * 0.08, l, true, -1.0, true)
	bg.draw_circle(m, s * 0.07, c, true, -1.0, true)


func _draw() -> void:
	var g := game
	draw_texture(bg_vp.get_texture(), Vector2.ZERO)
	# chão: faixa de azulejos de barra
	var gy := px(Vector2(0, InvadersGame.GROUND_Y))
	draw_rect(Rect2(gy, Vector2(InvadersGame.FIELD.x * S, 4)), COBALT)
	for i in 4:
		draw_bunker(i, BLUE_MID, self, func(yu: float) -> Color: return BLUE_MID.lightened((yu - InvadersGame.BUNKER_Y) * 0.012))

	for row in InvadersGame.ROWS:
		var kind: int = InvadersGame.ROW_KIND[row]
		var t: Texture2D = tex["a%d%d" % [kind, g.anim_frame]]
		for col in InvadersGame.COLS:
			if g.alien_alive(row, col):
				draw_texture(t, px(g.alien_rect(row, col).position))
	if g.ufo != null:
		draw_texture(tex.ufo, px(Vector2(g.ufo.x, InvadersGame.UFO_Y)))
	if not player_dying() and g.state != InvadersGame.State.OVER:
		draw_texture(tex.player, px(g.player_rect().position))
	if g.shot != null:
		var p := px(g.shot)
		draw_line(p, p + Vector2(0, 12), OCHRE, 3.0, true)
	for b in g.bombs:
		draw_texture(tex["b%d%d" % [b.kind, int(b.frame) % 2]], px(b.pos - Vector2(1.5, 0)))


func _draw_fx() -> void:
	var g := game
	for c in cracks:
		var a := clampf(c.life / 0.4, 0.0, 1.0)
		for line: PackedVector2Array in c.lines:
			var pts := PackedVector2Array()
			for p in line:
				pts.append(px(p))
			fx.draw_polyline(pts, Color(COBALT, 0.8 * a), 2.0, true)
	for b in booms:
		var k: float = 1.0 - b.life / 0.28
		fx.draw_circle(px(b.pos), 6.0 + 16.0 * k, Color(BLUE_LIGHT, 0.5 * (1.0 - k)), true, -1.0, true)
	for c in chips:
		var p := px(c.pos)
		var sz: float = c.size * S
		fx.draw_set_transform(p, c.rot, Vector2.ONE)
		fx.draw_rect(Rect2(-sz / 2, -sz / 2, sz, sz), GLAZE)
		fx.draw_rect(Rect2(-sz / 2, -sz / 2, sz, sz * 0.35), c.color)
		fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if player_dying():
		var f: Array = InvaderSprites.PLAYER_BOOM[dying_frame()]
		draw_bits(f, g.player_rect().position - Vector2(1.5, 0), OCHRE if dying_frame() == 0 else COBALT, fx)
	for p in popups:
		_text(p.text, px(p.pos).x, px(p.pos).y + 10, OCHRE.darkened(0.2), 32)
	_draw_panels()


func _draw_panels() -> void:
	var g := game
	var lx := panel_left_x()
	var rx := panel_right_x()
	var a0 := 1.0 if (g.current == 0 or g.players.size() == 1) else 0.45
	_text(I18n.t("JOGADOR 1"), lx, 84, Color(BLUE_MID, a0), 20)
	_text(str(g.players[0].score), lx, 146, Color(COBALT, a0), 50)
	_text(I18n.t("RECORDE"), lx, 222, BLUE_MID, 20)
	_text(str(maxi(g.best, g.players[0].score)), lx, 276, OCHRE.darkened(0.25), 40)
	if g.players.size() > 1:
		var a1 := 1.0 if g.current == 1 else 0.45
		_text(I18n.t("JOGADOR 2"), rx, 84, Color(BLUE_MID, a1), 20)
		_text(str(g.players[1].score), rx, 146, Color(COBALT, a1), 50)
		_text(I18n.t("VAGA"), rx, 222, BLUE_MID, 20)
		_text(str(g.player().wave), rx, 276, COBALT, 40)
	else:
		_text(I18n.t("VAGA"), rx, 84, BLUE_MID, 20)
		_text(str(g.player().wave), rx, 146, COBALT, 50)
		_text(I18n.t("VIDA EXTRA"), rx, 222, BLUE_MID, 20)
		var got: bool = g.player().extra
		_text(I18n.t("obtida") if got else str(InvadersGame.EXTRA_LIFE_AT), rx, 270, OCHRE.darkened(0.25), 32 if got else 40)
	_text(I18n.t("VIDAS"), lx, 566, BLUE_MID, 20)
	var lives: int = maxi(g.player().lives, 0)
	var n := mini(lives, 4)
	for i in n:
		fx.draw_texture(tex.player, Vector2(lx - (n - 1) * 26.0 + i * 52.0 - 19.5, 600))
	# tabela de pontos, como no ecrã de apresentação das máquinas
	for k in 3:
		var y := 548.0 + k * 40.0
		fx.draw_texture(tex["a%d0" % k], Vector2(rx - 70, y))
		_text("= %d" % InvadersGame.KIND_POINTS[k], rx + 30, y + 22, COBALT, 22)
	fx.draw_texture(tex.ufo, Vector2(rx - 82, 668))
	_text("= ?", rx + 30, 688, OCHRE.darkened(0.25), 22)


func _text(text: String, center_x: float, baseline: float, c: Color, size: int) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(center_x - w / 2, baseline)
	fx.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color(GLAZE, c.a))
	fx.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(GLAZE, 0.97),
		"border": COBALT,
		"text": COBALT,
		"accent": COBALT,
		"button": Color("e9e4d6"),
		"button_hover": Color("d9e2f5"),
		"radius": 14,
		"dim": Color(0.95, 0.94, 0.9, 0.25),
	}
