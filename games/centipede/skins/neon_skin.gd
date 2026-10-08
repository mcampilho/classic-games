extends CentipedeSkin
## Neon: cogumelos fosforescentes, centopeia de luz com rasto, aranha elétrica,
## faíscas e ondas de choque.

const BG_TOP := Color("0a0320")
const BG_BOTTOM := Color("1b0639")
const GRID := Color(0.55, 0.3, 1.0, 0.06)
const WAVE_COLORS := [
	[Color("ff2bd6"), Color("19f0ff")], [Color("3dffa0"), Color("ffb03d")], [Color("ffd43b"), Color("b46bff")],
	[Color("19f0ff"), Color("ff2b4f")], [Color("ff7a3d"), Color("3dffa0")], [Color("b46bff"), Color("ffd43b")],
]

var fx: Node2D
var font: Font
var tex := {}
var glow := {}
var sparks: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var shake := 0.0
var _wave_idx := -1


func _setup() -> void:
	font = ThemeDB.fallback_font
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx = Node2D.new()
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = m
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(fx)
	fx.draw.connect(_draw_fx)
	_make()


func colors() -> Array:
	return WAVE_COLORS[(game.wave() - 1) % WAVE_COLORS.size()]


func _make() -> void:
	var idx := (game.wave() - 1) % WAVE_COLORS.size()
	if idx == _wave_idx:
		return
	_wave_idx = idx
	var mush: Color = colors()[0]
	var cent: Color = colors()[1]
	for hp in range(1, 5):
		var rows := mushroom_rows(hp)
		tex["m%d" % hp] = PixelArt.texture(rows, {"C": mush.lerp(Color.WHITE, 0.2), "W": Color.WHITE, "S": mush.darkened(0.3)}, 3)
		tex["mp%d" % hp] = PixelArt.texture(rows, {"C": Color("ff2b4f"), "W": Color("ffd43b"), "S": Color("8a1030")}, 3)
	for f in 2:
		tex["body%d" % f] = PixelArt.texture(BODY[f], {"B": cent.lerp(Color.WHITE, 0.3), "D": cent.darkened(0.3), "L": cent}, 3)
		tex["head%d" % f] = PixelArt.texture(HEAD[f], {"B": Color.WHITE.lerp(cent, 0.3), "E": Color("0a0320"), "A": cent, "L": cent}, 3)
		glow["seg%d" % f] = PixelArt.glow(BODY[f], {"B": cent, "D": cent, "L": cent})
		tex["spider%d" % f] = PixelArt.texture(SPIDER[f], {"B": Color("ff2b4f"), "E": Color.WHITE, "L": Color("ff7a9c")}, 3)
		glow["spider%d" % f] = PixelArt.glow(SPIDER[f], {"B": Color("ff2b4f"), "E": Color("ff2b4f"), "L": Color("ff2b4f")})
	glow.mush = PixelArt.glow(MUSHROOM, {"C": mush, "W": mush, "S": mush})
	tex.player = PixelArt.texture(SHOOTER, {"W": Color("e0ffff"), "R": Color("19f0ff")}, 3)
	glow.player = PixelArt.glow(SHOOTER, {"W": Color("19f0ff"), "R": Color("19f0ff")})
	tex.flea = PixelArt.texture(FLEA, {"B": Color("3dffa0"), "E": Color.WHITE, "L": Color("3dffa0")}, 3)
	tex.scorpion = PixelArt.texture(SCORPION, {"B": Color("ffb03d"), "P": Color("ffd43b"), "T": Color("ff7a3d"), "E": Color.WHITE, "L": Color("ffb03d")}, 3)


func _build_sfx() -> void:
	for i in 4:
		sfx["step%d" % i] = Synth.tone([55.0, 49.0, 43.65, 49.0][i], 0.1, {"wave": "saw", "volume": 0.3, "lowpass": 0.1, "decay": 20.0})
	sfx.fire = Synth.tone(2600.0, 0.05, {"wave": "triangle", "freq_end": 1200.0, "volume": 0.08})
	sfx.kill = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.18, {"wave": "noise", "volume": 0.2, "lowpass": 0.4, "decay": 16.0}),
		Synth.render(900.0, 0.15, {"wave": "triangle", "freq_end": 250.0, "volume": 0.2, "decay": 16.0}),
	]))
	sfx.kill_head = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.22, {"wave": "noise", "volume": 0.25, "lowpass": 0.4, "decay": 12.0}),
		Synth.render(1600.0, 0.2, {"wave": "triangle", "freq_end": 400.0, "volume": 0.22, "decay": 12.0}),
	]))
	sfx.mushroom = Synth.tone(0.0, 0.07, {"wave": "noise", "volume": 0.15, "lowpass": 0.7, "decay": 35.0})
	var arp := []
	for f in [1046.5, 1318.5, 1568.0, 2093.0]:
		arp.append(Synth.render(f, 0.06, {"wave": "square", "volume": 0.12, "lowpass": 0.3}))
	sfx.creature = Synth.concat(arp)
	sfx.death = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.3, {"wave": "noise", "volume": 0.35, "lowpass": 0.18, "decay": 2.5}),
		Synth.render(300.0, 1.2, {"wave": "saw", "freq_end": 40.0, "volume": 0.2, "lowpass": 0.2, "decay": 2.0}),
	]))
	sfx.repair = Synth.tone(2093.0, 0.04, {"wave": "triangle", "volume": 0.1, "decay": 40.0})
	var up := []
	for f in [659.25, 783.99, 987.77, 1318.5]:
		up.append(Synth.render(f, 0.08, {"wave": "triangle", "volume": 0.25}))
	sfx.extra = Synth.concat(up)
	var fan := []
	for f in [523.25, 659.25, 783.99, 1046.5, 1318.5]:
		fan.append(Synth.render(f, 0.08, {"wave": "square", "volume": 0.13, "lowpass": 0.3}))
	sfx.wave = Synth.concat(fan)
	var wob := []
	for i in 3:
		wob.append(Synth.render(220.0, 0.08, {"wave": "saw", "freq_end": 330.0, "volume": 0.1, "lowpass": 0.25, "attack": 0.0, "release": 0.0}))
		wob.append(Synth.render(330.0, 0.08, {"wave": "saw", "freq_end": 220.0, "volume": 0.1, "lowpass": 0.25, "attack": 0.0, "release": 0.0}))
	sfx.spider = Synth.concat(wob)


func _on_segment_killed(pos: Vector2, head: bool, points: int) -> void:
	super(pos, head, points)
	_burst(px(pos), colors()[1], 12 if head else 6)
	if head:
		rings.append({"pos": px(pos), "radius": 4.0, "alpha": 0.9, "color": colors()[1], "speed": 160.0})


func _on_creature_killed(kind: String, pos: Vector2, points: int) -> void:
	super(kind, pos, points)
	_burst(px(pos), Color("ff2b4f"), 30)
	rings.append({"pos": px(pos), "radius": 6.0, "alpha": 1.0, "color": Color("ff2b4f"), "speed": 240.0})
	shake = 6.0


func _on_player_hit(pos: Vector2) -> void:
	super(pos)
	_burst(px(pos), Color("19f0ff"), 60)
	shake = 14.0


func _burst(p: Vector2, c: Color, n: int) -> void:
	for i in n:
		var life := randf_range(0.3, 0.7)
		sparks.append({"pos": p, "vel": Vector2.from_angle(randf() * TAU) * randf_range(60, 260), "life": life, "max": life, "color": c})


func _tick(dt: float) -> void:
	_make()
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
		r.alpha -= 1.8 * dt
	rings = rings.filter(func(r: Dictionary) -> bool: return r.alpha > 0.0)
	fx.queue_redraw()


func _draw() -> void:
	var a := Vector2(-80, -80)
	var b := Vector2(1360, 800)
	draw_polygon(PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)]), PackedColorArray([BG_TOP, BG_TOP, BG_BOTTOM, BG_BOTTOM]))
	var fr := field_rect()
	draw_rect(fr, Color(0, 0, 0, 0.35))
	var zone_y := px(Vector2(0, CentipedeGame.ZONE_TOP * C)).y
	draw_line(Vector2(fr.position.x, zone_y), Vector2(fr.end.x, zone_y), Color(0.55, 0.3, 1.0, 0.25), 1.0)
	var g := game
	for y in CentipedeGame.ROWS:
		for x in CentipedeGame.COLS:
			var hp := g.mushrooms[y * CentipedeGame.COLS + x]
			if hp > 0:
				var key := ("mp%d" if g.poisoned[y * CentipedeGame.COLS + x] == 1 else "m%d") % hp
				draw_texture(tex[key], px(Vector2(x, y) * C))
	var f := frame()
	for s in g.segments:
		var t: Texture2D = tex[("head%d" if s.head else "body%d") % f]
		draw_set_transform(px(s.pos + Vector2(4, 4)), 0.0, Vector2(-1 if s.dx > 0 else 1, 1))
		draw_texture(t, -t.get_size() / 2)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if g.flea != null:
		draw_texture(tex.flea, px(g.flea.pos) - tex.flea.get_size() / 2)
	if g.spider != null:
		var st: Texture2D = tex["spider%d" % f]
		draw_texture(st, px(g.spider.pos) - st.get_size() / 2)
	if g.scorpion != null:
		draw_set_transform(px(g.scorpion.pos), 0.0, Vector2(-1 if g.scorpion.dir < 0 else 1, 1))
		draw_texture(tex.scorpion, -tex.scorpion.get_size() / 2)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not player_dying() and g.state != CentipedeGame.State.REPAIR and g.state != CentipedeGame.State.OVER:
		draw_texture(tex.player, px(g.player_pos) - tex.player.get_size() / 2)


func _draw_fx() -> void:
	var g := game
	for y in CentipedeGame.ROWS:
		for x in CentipedeGame.COLS:
			if g.mushrooms[y * CentipedeGame.COLS + x] > 0:
				fx.draw_texture_rect(glow.mush, Rect2(px(Vector2(x, y) * C - Vector2(4, 4)), glow.mush.get_size() * S), false, Color(1, 1, 1, 0.35))
	var f := frame()
	for s in g.segments:
		var gt: Texture2D = glow["seg%d" % f]
		fx.draw_texture_rect(gt, Rect2(px(s.pos - Vector2(4, 4)), gt.get_size() * S), false, Color(1, 1, 1, 0.8 if s.head else 0.5))
	if g.spider != null:
		var gs: Texture2D = glow["spider%d" % f]
		fx.draw_texture_rect(gs, Rect2(px(g.spider.pos) - gs.get_size() * S / 2, gs.get_size() * S), false, Color(1, 1, 1, 0.8))
	if not player_dying() and g.state != CentipedeGame.State.REPAIR and g.state != CentipedeGame.State.OVER:
		fx.draw_texture_rect(glow.player, Rect2(px(g.player_pos) - glow.player.get_size() * S / 2, glow.player.get_size() * S), false, Color(1, 1, 1, 0.8))
	if g.shot != null:
		var p := px(g.shot)
		fx.draw_rect(Rect2(p - Vector2(4, 2), Vector2(8, 16)), Color("19f0ff", 0.25))
		fx.draw_rect(Rect2(p - Vector2(1.5, 0), Vector2(3, 12)), Color("e0ffff"))
	for r in rings:
		fx.draw_arc(r.pos, r.radius, 0.0, TAU, 40, Color(r.color, maxf(r.alpha, 0.0)), 3.0, true)
	for s in sparks:
		fx.draw_line(s.pos, s.pos - s.vel * 0.03, Color(s.color.lerp(Color.WHITE, 0.4), s.life / s.max), 2.0, true)
	for p in popups:
		_text(p.text, px(p.pos).x, px(p.pos).y, Color("ffd43b"), 22, clampf(p.life, 0.0, 1.0))
	_draw_hud()


func _draw_hud() -> void:
	var g := game
	var lx := panel_left_x()
	var rx := panel_right_x()
	var label_c := Color("8a5cff").lerp(Color.WHITE, 0.3)
	var a0 := 1.0 if (g.current == 0 or g.players.size() == 1) else 0.4
	_text(I18n.t("JOGADOR 1"), lx, 80, label_c, 20, a0)
	_text(str(g.players[0].score), lx, 140, Color("19f0ff"), 50, a0)
	_text(I18n.t("RECORDE"), lx, 230, label_c, 20, 0.9)
	_text(str(maxi(g.best, g.player().score)), lx, 280, Color("ffd43b"), 38, 0.9)
	if g.players.size() > 1:
		_text(I18n.t("JOGADOR 2"), rx, 80, label_c, 20, 1.0 if g.current == 1 else 0.4)
		_text(str(g.players[1].score), rx, 140, Color("ff2bd6"), 50, 1.0 if g.current == 1 else 0.4)
	_text(I18n.t("VAGA"), rx, 230, label_c, 20, 0.9)
	_text(str(g.wave()), rx, 280, colors()[1], 38, 0.9)
	_text(I18n.t("VIDAS"), lx, 560, label_c, 20, 0.9)
	var n := mini(maxi(g.player().lives, 0), 6)
	for i in n:
		var c := Vector2(lx - (n - 1) * 18.0 + i * 36.0, 600)
		fx.draw_texture(tex.player, c - tex.player.get_size() / 2)


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
		"accent": Color("3dffa0"),
		"button": Color("170a36"),
		"button_hover": Color("2a1361"),
		"radius": 10,
		"dim": Color(0, 0, 0, 0.3),
	}
