extends GalaxianSkin
## Neon: naves de luz com rasto nos mergulhos, estrelas em riscos de velocidade, faíscas,
## ondas de choque e pontos a flutuar, sobre a grelha roxa da coleção.

const BG_TOP := Color("0a0320")
const BG_BOTTOM := Color("1b0639")
const GRID := Color(0.55, 0.3, 1.0, 0.07)
const PLAYER_C := Color("19f0ff")
const KIND_C := [Color("ffd43b"), Color("ff2b4f"), Color("d65bff"), Color("3d9bff")]

var fx: Node2D
var font: Font
var time := 0.0
var shake := 0.0
var flash := 0.0
var flash_color := Color.WHITE
var tex := {}
var glow := {}
var trails := {}       # índice da nave -> Array[Vector2]
var sparks: Array[Dictionary] = []
var rings: Array[Dictionary] = []


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
	make_stars(110, [Color("8a5cff"), Color("19f0ff"), Color("ff2bd6"), Color.WHITE], 60.0, 220.0)
	for kind in 4:
		var pal := {}
		var base: Dictionary = GalaxianSprites.PALETTES[kind]
		for k in base:
			pal[k] = (base[k] as Color).lerp(Color.WHITE, 0.25)
		for fr in 2:
			var rows := GalaxianSprites.frame(kind, fr)
			tex["a%d%d" % [kind, fr]] = PixelArt.texture(rows, pal)
			glow["a%d%d" % [kind, fr]] = PixelArt.glow(rows, {"B": KIND_C[kind], "C": KIND_C[kind], "Y": KIND_C[kind], "R": KIND_C[kind]})
	var ppal := {"W": PLAYER_C.lerp(Color.WHITE, 0.5), "R": Color("ff2bd6"), "B": PLAYER_C}
	tex.player = PixelArt.texture(GalaxianSprites.PLAYER, ppal)
	glow.player = PixelArt.glow(GalaxianSprites.PLAYER, {"W": PLAYER_C, "R": PLAYER_C, "B": PLAYER_C})


func _build_sfx() -> void:
	var hum := []
	for f in [55.0, 55.0, 65.4, 49.0]:
		hum.append(Synth.render(f, 0.2, {"wave": "saw", "volume": 0.16, "lowpass": 0.06, "attack": 0.03, "release": 0.03}))
	sfx.hum = Synth.concat(hum)
	sfx.dive = Synth.tone(1800.0, 0.8, {"wave": "triangle", "freq_end": 300.0, "volume": 0.12, "decay": 1.5})
	sfx.fire = Synth.tone(400.0, 0.12, {"wave": "square", "freq_end": 2000.0, "volume": 0.09, "lowpass": 0.35, "decay": 12.0})
	sfx.kill = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.25, {"wave": "noise", "volume": 0.22, "lowpass": 0.35, "decay": 12.0}),
		Synth.render(900.0, 0.2, {"wave": "triangle", "freq_end": 200.0, "volume": 0.25, "decay": 12.0}),
	]))
	var arp := []
	for f in [523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0]:
		arp.append(Synth.render(f, 0.07, {"wave": "square", "volume": 0.14, "lowpass": 0.3}))
	sfx.flag_kill = Synth.concat(arp)
	sfx.player_hit = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.4, {"wave": "noise", "volume": 0.35, "lowpass": 0.2, "decay": 2.5}),
		Synth.render(300.0, 1.2, {"wave": "saw", "freq_end": 40.0, "volume": 0.2, "lowpass": 0.2, "decay": 2.0}),
	]))
	var up := []
	for f in [659.25, 783.99, 987.77, 1318.5]:
		up.append(Synth.render(f, 0.08, {"wave": "triangle", "volume": 0.25}))
	sfx.extra = Synth.concat(up)


func _on_alien_killed(pos: Vector2, kind: int, points: int, diving: bool) -> void:
	super(pos, kind, points, diving)
	var c: Color = KIND_C[kind]
	for i in 18 + (20 if kind == 0 else 0):
		var life := randf_range(0.3, 0.7)
		sparks.append({"pos": pos, "vel": Vector2.from_angle(randf() * TAU) * randf_range(30.0, 150.0), "life": life, "max": life, "color": c})
	rings.append({"pos": pos, "radius": 3.0, "alpha": 0.9, "color": c, "speed": 70.0 if kind else 120.0})
	shake = maxf(shake, 7.0 if kind == 0 else 2.0)


func _on_player_hit(pos: Vector2) -> void:
	super(pos)
	for i in 60:
		var life := randf_range(0.4, 1.0)
		sparks.append({"pos": pos, "vel": Vector2.from_angle(randf() * TAU) * randf_range(40.0, 180.0), "life": life, "max": life, "color": PLAYER_C})
	shake = 16.0
	flash = 0.8
	flash_color = Color("ff2b4f")


func _on_wave_cleared() -> void:
	flash = 0.8
	flash_color = PLAYER_C


func _tick(dt: float) -> void:
	time += dt
	shake = move_toward(shake, 0.0, dt * 40.0)
	flash = move_toward(flash, 0.0, dt * 2.5)
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
	for i in game.aliens.size():
		var a: Dictionary = game.aliens[i]
		if a.alive and a.fly != GalaxianGame.Fly.FORM:
			var t: Array = trails.get(i, [])
			t.append(GalaxianGame.KIND_SIZE[a.kind] / 2.0 + a.pos)
			if t.size() > 12:
				t.pop_front()
			trails[i] = t
		elif trails.has(i):
			trails.erase(i)
	fx.queue_redraw()


func _draw() -> void:
	var a := Vector2(-80, -80)
	var b := Vector2(1360, 800)
	draw_polygon(PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)]), PackedColorArray([BG_TOP, BG_TOP, BG_BOTTOM, BG_BOTTOM]))
	for x in range(-64, 1344, 64):
		draw_line(Vector2(x, -80), Vector2(x, 800), GRID, 1.0)
	draw_rect(field_rect(), Color(0, 0, 0, 0.35))
	var g := game
	for al in g.aliens:
		if al.alive:
			draw_texture(tex["a%d%d" % [al.kind, g.anim_frame]], px(al.pos))
	if not player_dying() and g.state != GalaxianGame.State.OVER:
		draw_texture(tex.player, px(g.player_rect().position))


func _draw_fx() -> void:
	var g := game
	if flash > 0.0:
		fx.draw_rect(Rect2(-80, -80, 1440, 880), Color(flash_color, flash * 0.14))
	for s in stars:
		fx.draw_line(s.pos, s.pos - Vector2(0, s.speed * 0.06), Color(s.color, 0.5), 1.5)
	for i in trails:
		var t: Array = trails[i]
		var c: Color = KIND_C[g.aliens[i].kind]
		for k in t.size():
			fx.draw_circle(px(t[k]), 2.0 + k * 0.4, Color(c, 0.04 * k), true, -1.0, true)
	for al in g.aliens:
		if al.alive:
			var gt: Texture2D = glow["a%d%d" % [al.kind, g.anim_frame]]
			fx.draw_texture_rect(gt, Rect2(px(al.pos - Vector2(4, 4)), gt.get_size() * S), false, Color(1, 1, 1, 0.7 if al.fly == GalaxianGame.Fly.FORM else 1.0))
	if not player_dying() and g.state != GalaxianGame.State.OVER:
		fx.draw_texture_rect(glow.player, Rect2(px(g.player_rect().position - Vector2(4, 4)), glow.player.get_size() * S), false, Color(1, 1, 1, 0.8))
		if g.missile == null:
			_beam(Vector2(g.player_x, GalaxianGame.PLAYER_Y - 4))
	if g.missile != null:
		_beam(g.missile)
	for b in g.bombs:
		var p := px(b.pos)
		fx.draw_circle(p, 7.0, Color("ff2bd6", 0.25), true, -1.0, true)
		fx.draw_rect(Rect2(p - Vector2(1.5, 0), Vector2(3, 9)), Color("ffc0f0"))
	for b in booms:
		fx.draw_circle(px(b.pos), 30.0 * (1.0 - b.life / 0.35) + 4.0, Color(1, 1, 1, b.life * 1.4), true, -1.0, true)
	for r in rings:
		fx.draw_arc(px(r.pos), r.radius * S, 0.0, TAU, 40, Color(r.color, maxf(r.alpha, 0.0)), 3.0, true)
	for s in sparks:
		var p := px(s.pos)
		fx.draw_line(p, p - s.vel * 0.06, Color(s.color.lerp(Color.WHITE, 0.4), s.life / s.max), 2.0, true)
	for p in popups:
		_text(p.text, px(p.pos).x, px(p.pos).y, Color("ffd43b"), 30, clampf(p.life, 0.0, 1.0))
	_draw_panels()


func _beam(u: Vector2) -> void:
	var p := px(u)
	fx.draw_rect(Rect2(p - Vector2(4, 3), Vector2(8, 18)), Color(PLAYER_C, 0.2))
	fx.draw_rect(Rect2(p - Vector2(1.5, 0), Vector2(3, 12)), Color("e0ffff"))


func _draw_panels() -> void:
	var g := game
	var lx := panel_left_x()
	var rx := panel_right_x()
	var label_c := Color("8a5cff").lerp(Color.WHITE, 0.3)
	_text(I18n.t("JOGADOR 1"), lx, 80, label_c, 20, 1.0 if (g.current == 0 or g.players.size() == 1) else 0.4)
	_text(str(g.players[0].score), lx, 140, PLAYER_C, 52, 1.0 if (g.current == 0 or g.players.size() == 1) else 0.4)
	_text(I18n.t("RECORDE"), lx, 230, label_c, 20, 0.9)
	_text(str(maxi(g.best, g.player().score)), lx, 280, Color("ffd43b"), 40, 0.9)
	if g.players.size() > 1:
		_text(I18n.t("JOGADOR 2"), rx, 80, label_c, 20, 1.0 if g.current == 1 else 0.4)
		_text(str(g.players[1].score), rx, 140, Color("ff2bd6"), 52, 1.0 if g.current == 1 else 0.4)
	_text(I18n.t("VAGA"), rx, 230, label_c, 20, 0.9)
	_text(str(g.player().wave), rx, 280, Color("3dffa0"), 40, 0.9)
	_text(I18n.t("VIDAS"), lx, 560, label_c, 20, 0.9)
	var n := mini(maxi(g.player().lives, 0), 6)
	for i in n:
		var pos := Vector2(lx - (n - 1) * 24.0 + i * 48.0 - 19.5, 590)
		fx.draw_texture_rect(glow.player, Rect2(pos - Vector2(12, 12), glow.player.get_size() * S), false, Color(1, 1, 1, 0.6))
		fx.draw_texture(tex.player, pos)


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
		"accent": PLAYER_C,
		"button": Color("170a36"),
		"button_hover": Color("2a1361"),
		"radius": 10,
		"dim": Color(0, 0, 0, 0.3),
	}
