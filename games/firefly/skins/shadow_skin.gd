extends FireflySkin
## Teatro de Sombras (estilo próprio): o labirinto é um jardim recortado em silhueta contra
## um ecrã de papel iluminado por trás, emoldurado por cortinas de veludo. Tudo é sombra —
## menos a luz do pirilampo. Os morcegos só se distinguem pelos olhos; quando ficam
## encandeados passam a recortes de papel claro, a tremer.
## Sons de caixa de música, madeira e gongo.

const DARK := Color("1a0d07")
const PAPER_HI := Color("ffd58a")
const PAPER_LO := Color("7a3410")
const CURTAIN := Color("6e1020")
const GOLD := Color("e8b64c")
const LIGHT := Color("fff1b8")
const PAPER_CUT := Color("f5e6c8")
const EYE_COLORS := [Color("ff6b6b"), Color("ffc078"), Color("8ce99a"), Color("b197fc")]

var font: Font
var bg_vp: SubViewport
var bg: Node2D
var fx: Node2D
var tex := {}
var puffs: Array[Dictionary] = []


func _setup() -> void:
	font = ThemeDB.fallback_font
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg_vp = SubViewport.new()
	bg_vp.size = Vector2i(1280, 720)
	bg_vp.disable_3d = true
	bg_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(bg_vp)
	bg = Node2D.new()
	bg_vp.add_child(bg)
	bg.draw.connect(_draw_background)
	fx = Node2D.new()
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = m
	add_child(fx)
	fx.draw.connect(_draw_fx)
	for f in 2:
		tex["ff%d" % f] = PixelArt.texture(FireflySprites.FIREFLY[f], FireflySprites.mono(FireflySprites.FIREFLY_PALETTE, DARK), 3)
		tex["bat%d" % f] = PixelArt.texture(FireflySprites.BAT[f], {"B": DARK}, 3)
		tex["cut%d" % f] = PixelArt.texture(FireflySprites.BAT[f], {"B": PAPER_CUT, "E": DARK}, 3)
	tex.flower = PixelArt.texture(FireflySprites.FLOWER, FireflySprites.mono(FireflySprites.FLOWER_PALETTE, DARK), 3)
	for k in FireflySprites.BONUS.size():
		tex["bonus%d" % k] = PixelArt.texture(FireflySprites.BONUS[k], FireflySprites.mono(FireflySprites.BONUS_PALETTES[k], DARK), 3)


# ---------------------------------------------------------------- sons

static func _pluck(f: float, dur: float, vol: float) -> PackedFloat32Array:
	return Synth.mix([
		Synth.render(f, dur, {"wave": "triangle", "volume": vol, "decay": 6.0 / dur}),
		Synth.render(f * 2.0, dur * 0.5, {"wave": "sine", "volume": vol * 0.3, "decay": 12.0 / dur}),
	])


func _build_sfx() -> void:
	var box := []
	for f in [659.3, 784.0, 880.0, 784.0, 587.3, 659.3, 523.3, 587.3]:
		box.append(_pluck(f, 0.32, 0.09))
	sfx.ambient = Synth.concat(box)
	var fast := []
	for f in [1046.5, 1174.7, 1318.5, 1568.0, 1318.5, 1174.7]:
		fast.append(_pluck(f, 0.12, 0.08))
	sfx.power_loop = Synth.concat(fast)
	var woods := [900.0, 1000.0, 1120.0, 1250.0, 1400.0]
	for i in 5:
		sfx["eat%d" % i] = Synth.tone(woods[i], 0.05, {"wave": "sine", "volume": 0.18, "decay": 70.0})
	sfx.power = Synth.to_stream(Synth.mix([
		Synth.render(98.0, 1.4, {"wave": "sine", "volume": 0.4, "decay": 2.5}),
		Synth.render(98.0 * 2.76, 1.0, {"wave": "sine", "volume": 0.15, "decay": 4.0}),
		Synth.render(0.0, 0.05, {"wave": "noise", "volume": 0.2, "lowpass": 0.2, "decay": 60.0}),
	]))
	sfx.bat_eaten = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.35, {"wave": "noise", "volume": 0.25, "lowpass": 0.15, "decay": 9.0}),
		_pluck(1568.0, 0.3, 0.12),
	]))
	var chime := []
	for f in [1318.5, 1568.0, 2093.0]:
		chime.append(_pluck(f, 0.14, 0.15))
	sfx.bonus = Synth.concat(chime)
	var down := []
	for f in [784.0, 698.5, 659.3, 587.3, 523.3, 493.9, 440.0]:
		down.append(_pluck(f, 0.2, 0.14))
	sfx.death = Synth.concat(down)
	sfx.extra = Synth.concat([_pluck(1568.0, 0.2, 0.15), _pluck(2093.0, 0.4, 0.15)])
	var fan := []
	for f in [523.3, 659.3, 784.0, 1046.5, 784.0, 1046.5, 1318.5]:
		fan.append(_pluck(f, 0.12, 0.14))
	sfx.clear = Synth.concat(fan)


# ---------------------------------------------------------------- eventos

func _on_bat_eaten(pos: Vector2, points: int) -> void:
	super(pos, points)
	for i in 8:
		puffs.append({"pos": pos + Vector2(randf_range(-8, 8), randf_range(-8, 8)), "r": randf_range(4, 9), "life": 0.8})


func _tick(dt: float) -> void:
	for p in puffs:
		p.r += 14.0 * dt
		p.pos.y -= 10.0 * dt
		p.life -= dt
	puffs = puffs.filter(func(p: Dictionary) -> bool: return p.life > 0.0)
	fx.queue_redraw()


# ---------------------------------------------------------------- desenho

func _draw_background() -> void:
	var maze := maze_rect()
	bg.draw_rect(Rect2(0, 0, 1280, 720), PAPER_LO)
	# ecrã de papel iluminado por trás: mais claro no centro
	var c := maze.get_center()
	for i in 40:
		var k := float(i) / 39.0
		bg.draw_circle(c, lerpf(720.0, 60.0, k), PAPER_LO.lerp(PAPER_HI, pow(k, 0.8)), true, -1.0, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 1500:
		var p := Vector2(rng.randf() * 1280, rng.randf() * 720)
		bg.draw_line(p, p + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(2, 6), Color(0.4, 0.15, 0.0, rng.randf_range(0.03, 0.08)), 1.0)
	# sebes recortadas, com folhas nas bordas
	for y in FireflyGame.H:
		for x in FireflyGame.W:
			var t := Vector2i(x, y)
			if FireflyGame.is_wall(t):
				bg.draw_rect(tile_rect(t).grow(0.5), DARK)
	for e in wall_edges:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var n := (b - a).orthogonal().normalized()
		var mid := (a + b) / 2
		# a folha cresce para o lado do corredor
		var probe := mid + n * 4.0
		var probe_tile := Vector2i(((probe - FireflyGame.ORIGIN) / T).floor())
		if FireflyGame.is_wall(probe_tile):
			n = -n
		for k in 3:
			var p := a.lerp(b, (k + 0.5) / 3.0)
			bg.draw_circle(p + n * 1.0, 3.2 + rng.randf() * 1.6, DARK, true, -1.0, true)
	# moldura de madeira e cortinas
	bg.draw_rect(maze.grow(10), Color("3b1d0e"), false, 12.0)
	bg.draw_rect(maze.grow(4), GOLD.darkened(0.3), false, 2.0)
	for side in [0, 1]:
		var x0 := 0.0 if side == 0 else maze.end.x + 16.0
		var w := maze.position.x - 16.0
		var folds := 9
		for k in folds:
			var fw := w / folds
			var r := Rect2(x0 + k * fw, 0, fw + 1, 720)
			bg.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, 0), r.end, Vector2(r.position.x, 720)]),
				PackedColorArray([CURTAIN.darkened(0.35), CURTAIN.lightened(0.12), CURTAIN.lightened(0.12), CURTAIN.darkened(0.35)]))
		bg.draw_rect(Rect2(x0, 0, w, 26), GOLD.darkened(0.2))
		for k in 12:
			bg.draw_circle(Vector2(x0 + (k + 0.5) * w / 12, 30), 5.0, GOLD, true, -1.0, true)


func _draw() -> void:
	var g := game
	draw_texture(bg_vp.get_texture(), Vector2.ZERO)
	if g.state == FireflyGame.State.CLEARED and fmod(g.timer, 0.5) < 0.25:
		draw_rect(maze_rect(), Color(1, 1, 0.9, 0.35))
	draw_rect(Rect2(tile_rect(FireflyGame.DOOR).position + Vector2(2, T / 2 - 2), Vector2(T - 4, 4)), Color(DARK, 0.6))
	# sementes e flores
	for y in FireflyGame.H:
		for x in FireflyGame.W:
			var p := pellet_at(x, y)
			if p == 1:
				draw_circle(px(Vector2(x, y)), 3.0, Color(DARK, 0.85), true, -1.0, true)
			elif p == 2:
				var c := px(Vector2(x, y))
				draw_set_transform(c, sin(time * 3.0 + x) * 0.15, Vector2.ONE)
				draw_texture(tex.flower, -tex.flower.get_size() / 2)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if g.bonus != null:
		var bt: Texture2D = tex["bonus%d" % g.bonus.kind]
		draw_texture(bt, px(Vector2(FireflyGame.BONUS_TILE)) - bt.get_size() / 2)
	for p in puffs:
		draw_circle(p.pos, p.r, Color(DARK, 0.35 * p.life), true, -1.0, true)
	# morcegos
	var fr := int(time * 8.0) % 2
	for b in g.bats:
		if not bat_visible(b):
			continue
		var c := px(b.pos)
		if b.state == FireflyGame.Bat.EATEN:
			draw_circle(c, 5.0, Color(DARK, 0.5), true, -1.0, true)
			continue
		if b.fright:
			var jitter := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * (2.0 if fright_flash() else 0.8)
			var t: Texture2D = tex["cut%d" % fr]
			draw_texture(t, c - t.get_size() / 2 + jitter)
		else:
			var t: Texture2D = tex["bat%d" % fr]
			draw_texture(t, c - t.get_size() / 2)
	# pirilampo (a silhueta; a luz vai na camada aditiva)
	if player_visible():
		var c := px(g.player_pos)
		var ft := face_transform()
		var angle: float = ft[0]
		if g.state == FireflyGame.State.DYING:
			angle += (2.0 - g.timer) * 2.0
			c.y += (2.0 - g.timer) * 6.0
		var moving := g.player_dir != Vector2i.ZERO and g.state == FireflyGame.State.PLAY
		var t: Texture2D = tex["ff%d" % (int(time * 12.0) % 2 if moving else 0)]
		draw_set_transform(c, angle, ft[1])
		draw_texture(t, -t.get_size() / 2)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for p in popups:
		_text(p.text, p.pos, 22, DARK)
	_draw_panels()


func _draw_fx() -> void:
	var g := game
	# olhos dos morcegos
	for b in g.bats:
		if not bat_visible(b) or b.fright or b.state == FireflyGame.Bat.EATEN:
			continue
		var c := px(b.pos)
		var up := 0.0 if int(time * 8.0) % 2 == 0 else 6.0
		for s in [-1.0, 1.0]:
			var e := c + Vector2(s * 3.0, -1.5 + up - 3.0)
			fx.draw_circle(e, 4.0, Color(EYE_COLORS[b.id], 0.35), true, -1.0, true)
			fx.draw_circle(e, 1.6, EYE_COLORS[b.id], true, -1.0, true)
	if not player_visible():
		return
	# a luz do pirilampo
	var c := px(g.player_pos)
	var k := 1.0
	if g.state == FireflyGame.State.DYING:
		k = clampf(g.timer / 2.0, 0.0, 1.0) * (0.6 + 0.4 * sin(time * 40.0))
	var big := 1.7 if g.fright_time > 0.0 else 1.0
	var ft := face_transform()
	var flip: Vector2 = ft[1]
	var tail: Vector2 = c + Vector2(-12, 0).rotated(ft[0]) * Vector2(flip.x, 1)
	fx.draw_circle(tail, 90.0 * big * k, Color(LIGHT, 0.06 * k), true, -1.0, true)
	fx.draw_circle(tail, 40.0 * big * k, Color(LIGHT, 0.12 * k), true, -1.0, true)
	fx.draw_circle(tail, 9.0 * k, Color(LIGHT, 0.7 * k), true, -1.0, true)


func _draw_panels() -> void:
	var g := game
	var lx := 110.0
	var rx := 1170.0
	var a0 := 1.0 if (g.current == 0 or g.players.size() == 1) else 0.45
	_text(I18n.t("JOGADOR 1"), Vector2(lx, 110), 20, Color(GOLD, a0))
	_text(str(g.players[0].score), Vector2(lx, 162), 42, Color(PAPER_CUT, a0))
	_text(I18n.t("RECORDE"), Vector2(lx, 240), 18, GOLD)
	_text(str(maxi(g.best, g.player().score)), Vector2(lx, 280), 30, PAPER_CUT)
	if g.players.size() > 1:
		_text(I18n.t("JOGADOR 2"), Vector2(rx, 110), 20, Color(GOLD, 1.0 if g.current == 1 else 0.45))
		_text(str(g.players[1].score), Vector2(rx, 162), 42, Color(PAPER_CUT, 1.0 if g.current == 1 else 0.45))
	_text(I18n.t("ATO %d") % g.level(), Vector2(rx, 260), 26, GOLD)
	_text(I18n.t("VIDAS"), Vector2(lx, 560), 18, GOLD)
	var n := mini(maxi(g.player().lives, 0), 5)
	for i in n:
		var p := Vector2(lx - (n - 1) * 20.0 + i * 40.0, 600)
		draw_circle(p + Vector2(-8, 0), 8.0, Color(LIGHT, 0.6), true, -1.0, true)
		draw_texture(tex.ff0, p - tex.ff0.get_size() / 2)


func _text(text: String, pos: Vector2, size: int, c: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(pos.x - w / 2, pos.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.12, 0.05, 0.02, 0.92),
		"border": GOLD,
		"text": PAPER_CUT,
		"accent": GOLD,
		"button": Color("2a1209"),
		"button_hover": Color("4a2112"),
		"radius": 8,
		"dim": Color(0.1, 0.03, 0.0, 0.25),
	}
