extends FireflySkin
## Neon: labirinto de tubos de luz, pontos que pulsam, o pirilampo com um halo dourado,
## morcegos de néon e ondas de luz quando o pirilampo apanha uma flor.

const BG_TOP := Color("0a0320")
const BG_BOTTOM := Color("1b0639")
const WALL_C := Color("7b4dff")
const WALL_C2 := Color("19f0ff")
const DOT := Color("fff3a0")
const GLOW_C := Color("ffd43b")

var fx: Node2D
var walls: Node2D
var _flash_state := false
var font: Font
var tex := {}
var glow := {}
var sparks: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var shake := 0.0


func _setup() -> void:
	font = ThemeDB.fallback_font
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx = Node2D.new()
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = m
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# as paredes ficam num nó próprio, só redesenhado quando o labirinto pisca
	walls = Node2D.new()
	walls.material = m
	add_child(walls)
	walls.draw.connect(_draw_walls)
	add_child(fx)
	fx.draw.connect(_draw_fx)
	for f in 2:
		tex["ff%d" % f] = PixelArt.texture(FireflySprites.FIREFLY[f], FireflySprites.FIREFLY_PALETTE, 3)
		for i in 4:
			var c: Color = FireflySprites.BAT_COLORS[i].lerp(Color.WHITE, 0.25)
			tex["bat%d%d" % [i, f]] = PixelArt.texture(FireflySprites.BAT[f], {"B": c, "E": Color.WHITE}, 3)
			glow["bat%d%d" % [i, f]] = PixelArt.glow(FireflySprites.BAT[f], {"B": FireflySprites.BAT_COLORS[i], "E": Color.WHITE})
		tex["scared%d" % f] = PixelArt.texture(FireflySprites.BAT[f], {"B": Color("e7f5ff"), "E": Color("ff2bd6")}, 3)
		glow["scared%d" % f] = PixelArt.glow(FireflySprites.BAT[f], {"B": Color("74c0fc"), "E": Color("74c0fc")})
	for k in FireflySprites.BONUS.size():
		tex["bonus%d" % k] = PixelArt.texture(FireflySprites.BONUS[k], FireflySprites.BONUS_PALETTES[k], 3)


func _build_sfx() -> void:
	var pad := []
	for f in [110.0, 130.8, 98.0, 123.5]:
		pad.append(Synth.render(f, 0.5, {"wave": "saw", "volume": 0.07, "lowpass": 0.05, "attack": 0.1, "release": 0.1}))
	sfx.ambient = Synth.concat(pad)
	var pulse := []
	for i in 4:
		pulse.append(Synth.render(220.0, 0.08, {"wave": "saw", "volume": 0.08, "lowpass": 0.2, "decay": 10.0}))
		pulse.append(Synth.render(330.0, 0.08, {"wave": "saw", "volume": 0.08, "lowpass": 0.2, "decay": 10.0}))
	sfx.power_loop = Synth.concat(pulse)
	var scale := [1318.5, 1568.0, 1760.0, 2093.0, 2349.3]
	for i in 5:
		sfx["eat%d" % i] = Synth.tone(scale[i], 0.06, {"wave": "triangle", "volume": 0.08, "decay": 35.0})
	sfx.power = Synth.tone(200.0, 0.5, {"wave": "saw", "freq_end": 1200.0, "volume": 0.15, "lowpass": 0.3})
	sfx.bat_eaten = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.3, {"wave": "noise", "volume": 0.2, "lowpass": 0.35, "decay": 12.0}),
		Synth.render(400.0, 0.3, {"wave": "square", "freq_end": 1800.0, "volume": 0.1, "lowpass": 0.35}),
	]))
	var arp := []
	for f in [1046.5, 1318.5, 1568.0, 2093.0]:
		arp.append(Synth.render(f, 0.06, {"wave": "square", "volume": 0.12, "lowpass": 0.3}))
	sfx.bonus = Synth.concat(arp)
	sfx.death = Synth.to_stream(Synth.mix([
		Synth.render(900.0, 1.4, {"wave": "saw", "freq_end": 60.0, "volume": 0.18, "lowpass": 0.25, "decay": 1.5}),
		Synth.render(0.0, 1.0, {"wave": "noise", "volume": 0.15, "lowpass": 0.15, "decay": 3.0}),
	]))
	var up := []
	for f in [659.25, 783.99, 987.77, 1318.5]:
		up.append(Synth.render(f, 0.08, {"wave": "triangle", "volume": 0.25}))
	sfx.extra = Synth.concat(up)
	var fan := []
	for f in [523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0]:
		fan.append(Synth.render(f, 0.09, {"wave": "square", "volume": 0.13, "lowpass": 0.3}))
	sfx.clear = Synth.concat(fan)


func _on_power_started() -> void:
	rings.append({"pos": px(game.player_pos), "radius": 10.0, "alpha": 1.0, "color": Color("ff8cc6"), "speed": 600.0})


func _on_bat_eaten(pos: Vector2, points: int) -> void:
	super(pos, points)
	for i in 30:
		var life := randf_range(0.3, 0.7)
		sparks.append({"pos": pos, "vel": Vector2.from_angle(randf() * TAU) * randf_range(60, 260), "life": life, "max": life, "color": Color("74c0fc")})
	rings.append({"pos": pos, "radius": 6.0, "alpha": 1.0, "color": Color("74c0fc"), "speed": 220.0})
	shake = 6.0


func _on_player_hit(pos: Vector2) -> void:
	super(pos)
	for i in 50:
		var life := randf_range(0.5, 1.2)
		sparks.append({"pos": pos, "vel": Vector2.from_angle(randf() * TAU) * randf_range(40, 220), "life": life, "max": life, "color": GLOW_C})
	shake = 12.0


func _tick(dt: float) -> void:
	var flashing := game.state == FireflyGame.State.CLEARED and fmod(game.timer, 0.5) < 0.25
	if flashing != _flash_state:
		_flash_state = flashing
		walls.queue_redraw()
	shake = move_toward(shake, 0.0, dt * 35.0)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	var drag := pow(0.05, dt)
	for s in sparks:
		s.pos += s.vel * dt
		s.vel *= drag
		s.life -= dt
	sparks = sparks.filter(func(s: Dictionary) -> bool: return s.life > 0.0)
	for r in rings:
		r.radius += r.speed * dt
		r.alpha -= 1.6 * dt
	rings = rings.filter(func(r: Dictionary) -> bool: return r.alpha > 0.0)
	fx.queue_redraw()


func _draw() -> void:
	var a := Vector2(-80, -80)
	var b := Vector2(1360, 800)
	draw_polygon(PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)]), PackedColorArray([BG_TOP, BG_TOP, BG_BOTTOM, BG_BOTTOM]))
	draw_rect(maze_rect(), Color(0, 0, 0, 0.3))
	var g := game
	if g.bonus != null:
		var bt: Texture2D = tex["bonus%d" % g.bonus.kind]
		draw_texture(bt, px(Vector2(FireflyGame.BONUS_TILE)) - bt.get_size() / 2)
	var fr := int(time * 8.0) % 2
	for bat in g.bats:
		if not bat_visible(bat) or bat.state == FireflyGame.Bat.EATEN:
			continue
		var t: Texture2D = tex[("scared%d" % fr) if bat.fright else ("bat%d%d" % [bat.id, fr])]
		if bat.fright and fright_flash():
			continue
		draw_texture(t, px(bat.pos) - t.get_size() / 2)
	if player_visible() and g.state != FireflyGame.State.DYING:
		var ft := face_transform()
		var moving := g.player_dir != Vector2i.ZERO and g.state == FireflyGame.State.PLAY
		var t: Texture2D = tex["ff%d" % (int(time * 12.0) % 2 if moving else 0)]
		draw_set_transform(px(g.player_pos), ft[0], ft[1])
		draw_texture(t, -t.get_size() / 2)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_walls() -> void:
	var wc := Color.WHITE if _flash_state else WALL_C
	for e in wall_edges:
		walls.draw_line(e[0], e[1], Color(wc, 0.12), 8.0)
	for e in wall_edges:
		walls.draw_line(e[0], e[1], Color(wc.lerp(WALL_C2, 0.3), 0.9), 2.0)
	walls.draw_line(tile_rect(FireflyGame.DOOR).get_center() - Vector2(T / 2, 0), tile_rect(FireflyGame.DOOR).get_center() + Vector2(T / 2, 0), Color("ff2bd6"), 3.0)


func _draw_fx() -> void:
	var g := game
	var pulse := 0.6 + 0.4 * sin(time * 6.0)
	for y in FireflyGame.H:
		for x in FireflyGame.W:
			var p := pellet_at(x, y)
			if p == 1:
				fx.draw_circle(px(Vector2(x, y)), 3.0, DOT)
				fx.draw_circle(px(Vector2(x, y)), 6.0, Color(DOT, 0.15))
			elif p == 2:
				fx.draw_circle(px(Vector2(x, y)), 14.0 * pulse, Color("ff8cc6", 0.25), true, -1.0, true)
				fx.draw_circle(px(Vector2(x, y)), 7.0, Color("ffc9e3"), true, -1.0, true)
	var fr := int(time * 8.0) % 2
	for bat in g.bats:
		if not bat_visible(bat):
			continue
		var c := px(bat.pos)
		if bat.state == FireflyGame.Bat.EATEN:
			fx.draw_circle(c, 6.0, Color("74c0fc", 0.6), true, -1.0, true)
			continue
		if bat.fright and fright_flash():
			continue
		var gt: Texture2D = glow[("scared%d" % fr) if bat.fright else ("bat%d%d" % [bat.id, fr])]
		fx.draw_texture_rect(gt, Rect2(c - gt.get_size() * 1.5, gt.get_size() * 3), false, Color(1, 1, 1, 0.8))
	if player_visible():
		var c := px(g.player_pos)
		var k := clampf(g.timer / 2.0, 0.0, 1.0) if g.state == FireflyGame.State.DYING else 1.0
		var halo := (34.0 + 6.0 * sin(time * 5.0)) * (1.6 if g.fright_time > 0.0 else 1.0)
		fx.draw_circle(c, halo * k, Color(GLOW_C, 0.12 * k), true, -1.0, true)
		fx.draw_circle(c, halo * 0.5 * k, Color(GLOW_C, 0.2 * k), true, -1.0, true)
	for r in rings:
		fx.draw_arc(r.pos, r.radius, 0.0, TAU, 48, Color(r.color, maxf(r.alpha, 0.0)), 3.0, true)
	for s in sparks:
		fx.draw_line(s.pos, s.pos - s.vel * 0.03, Color(s.color.lerp(Color.WHITE, 0.4), s.life / s.max), 2.0, true)
	for p in popups:
		_text(p.text, p.pos.x, p.pos.y, Color("74c0fc"), 22, clampf(p.life * 2.0, 0.0, 1.0))
	_draw_panels()


func _draw_panels() -> void:
	var g := game
	var lx := 117.0
	var rx := 1162.0
	var label_c := Color("8a5cff").lerp(Color.WHITE, 0.3)
	var a0 := 1.0 if (g.current == 0 or g.players.size() == 1) else 0.4
	_text(I18n.t("JOGADOR 1"), lx, 100, label_c, 20, a0)
	_text(str(g.players[0].score), lx, 156, Color("19f0ff"), 44, a0)
	_text(I18n.t("RECORDE"), lx, 240, label_c, 20, 0.9)
	_text(str(maxi(g.best, g.player().score)), lx, 286, GLOW_C, 34, 0.9)
	if g.players.size() > 1:
		_text(I18n.t("JOGADOR 2"), rx, 100, label_c, 20, 1.0 if g.current == 1 else 0.4)
		_text(str(g.players[1].score), rx, 156, Color("ff2bd6"), 44, 1.0 if g.current == 1 else 0.4)
	_text(I18n.t("NÍVEL"), rx, 240, label_c, 20, 0.9)
	_text(str(g.level()), rx, 286, Color("3dffa0"), 34, 0.9)
	_text(I18n.t("VIDAS"), lx, 570, label_c, 20, 0.9)
	var n := mini(maxi(g.player().lives, 0), 5)
	for i in n:
		var c := Vector2(lx - (n - 1) * 20.0 + i * 40.0, 610)
		fx.draw_circle(c, 14.0, Color(GLOW_C, 0.15), true, -1.0, true)
		fx.draw_texture(tex.ff0, c - tex.ff0.get_size() / 2)


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
		"accent": GLOW_C,
		"button": Color("170a36"),
		"button_hover": Color("2a1361"),
		"radius": 10,
		"dim": Color(0, 0, 0, 0.3),
	}
