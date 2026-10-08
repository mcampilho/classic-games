extends FroggerSkin
## Neon: autoestrada de luz com rastos, rio de néon com ondulação, veículos em contornos
## brilhantes e uma rã verde-ácida; faíscas e anéis a cada toca e a cada acidente.

const BG_TOP := Color("0a0320")
const BG_BOTTOM := Color("1b0639")
const RIVER_C := Color("1f6bff")
const ROAD_C := Color("8a5cff")
const FROG_C := Color("3dffa0")
const LOG_C := Color("ffb03d")
const TURTLE_C := Color("19f0ff")
const CAR_C := {"car_a": Color("ffd43b"), "dozer": Color("3dffa0"), "car_b": Color("ff2bd6"), "racer": Color("ffffff"), "truck": Color("ff7a3d")}

var fx: Node2D
var cover: Node2D
var hud: Node2D
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
	add_child(fx)
	fx.draw.connect(_draw_fx)
	cover = Node2D.new()
	add_child(cover)
	cover.draw.connect(_draw_cover)
	hud = Node2D.new()
	hud.material = m
	add_child(hud)
	hud.draw.connect(_draw_hud)
	var pal := {"G": FROG_C.lerp(Color.WHITE, 0.3), "g": FROG_C, "Y": Color("e6fff0"), "W": Color.WHITE, "K": Color("0a0320")}
	for f in 2:
		tex["frog%d" % f] = PixelArt.texture(FROG[f], pal, 3)
		glow["frog%d" % f] = PixelArt.glow(FROG[f], FroggerSprites_mono(pal, FROG_C))
	tex.fly = PixelArt.texture(FLY, {"W": Color("a5d8ff"), "K": Color("fff3a0")}, 3)
	tex.croc = PixelArt.texture(CROC, {"G": Color("ff2b4f"), "W": Color.WHITE, "K": Color.BLACK}, 3)


static func FroggerSprites_mono(pal: Dictionary, c: Color) -> Dictionary:
	var out := {}
	for k in pal:
		out[k] = c
	return out


func _build_sfx() -> void:
	sfx.hop = Synth.tone(400.0, 0.07, {"wave": "triangle", "freq_end": 1100.0, "volume": 0.18, "decay": 20.0})
	var arp := []
	for f in [659.25, 783.99, 987.77, 1318.5]:
		arp.append(Synth.render(f, 0.07, {"wave": "square", "volume": 0.13, "lowpass": 0.3}))
	sfx.home = Synth.concat(arp)
	sfx.fly = Synth.tone(1500.0, 0.25, {"wave": "sine", "freq_end": 3000.0, "volume": 0.12})
	sfx.squash = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.6, {"wave": "noise", "volume": 0.3, "lowpass": 0.2, "decay": 6.0}),
		Synth.render(260.0, 0.6, {"wave": "saw", "freq_end": 40.0, "volume": 0.2, "lowpass": 0.2}),
	]))
	sfx.splash = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.8, {"wave": "noise", "volume": 0.25, "lowpass": 0.4, "decay": 4.0}),
		Synth.render(1200.0, 0.6, {"wave": "sine", "freq_end": 150.0, "volume": 0.15, "decay": 4.0}),
	]))
	sfx.warn = Synth.tone(880.0, 0.4, {"wave": "saw", "freq_end": 440.0, "volume": 0.12, "lowpass": 0.3})
	var up := []
	for f in [659.25, 783.99, 987.77, 1318.5]:
		up.append(Synth.render(f, 0.08, {"wave": "triangle", "volume": 0.25}))
	sfx.extra = Synth.concat(up)
	var fan := []
	for f in [523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0]:
		fan.append(Synth.render(f, 0.09, {"wave": "square", "volume": 0.13, "lowpass": 0.3}))
	sfx.clear = Synth.concat(fan)
	# baixo sintetizado em loop
	var groove := PackedFloat32Array()
	for f in [55.0, 55.0, 82.4, 55.0, 73.4, 73.4, 65.4, 49.0]:
		groove.append_array(Synth.render(f, 0.2, {"wave": "saw", "volume": 0.25, "lowpass": 0.08, "decay": 6.0}))
	sfx.music = Synth.to_stream(groove)


func _on_frog_home(bay: int, points: int, fly: bool) -> void:
	super(bay, points, fly)
	var c := bay_rect(bay).get_center()
	rings.append({"pos": c, "radius": 6.0, "alpha": 1.0, "color": FROG_C, "speed": 160.0})
	_burst(c, FROG_C, 20)


func _on_frog_died(pos: Vector2, cause: String) -> void:
	super(pos, cause)
	_burst(pos, RIVER_C if cause == "agua" else Color("ff2b4f"), 40)
	rings.append({"pos": pos, "radius": 6.0, "alpha": 1.0, "color": RIVER_C if cause == "agua" else Color("ff2b4f"), "speed": 200.0})
	shake = 10.0


func _burst(pos: Vector2, c: Color, n: int) -> void:
	for i in n:
		var life := randf_range(0.3, 0.8)
		sparks.append({"pos": pos, "vel": Vector2.from_angle(randf() * TAU) * randf_range(40, 240), "life": life, "max": life, "color": c})


func _tick(dt: float) -> void:
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
	hud.queue_redraw()


func _draw() -> void:
	var a := Vector2(-80, -80)
	var b := Vector2(1360, 800)
	draw_polygon(PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)]), PackedColorArray([BG_TOP, BG_TOP, BG_BOTTOM, BG_BOTTOM]))
	draw_rect(field_rect(), Color(0, 0, 0, 0.35))
	for r in range(1, 6):
		draw_rect(row_rect(r), Color(RIVER_C, 0.12))
	var g := game
	for i in 5:
		var c := bay_rect(i).get_center()
		if g.homes[i]:
			draw_texture(tex.frog0, c - tex.frog0.get_size() / 2)
		elif g.fly_bay == i:
			draw_texture(tex.fly, c - tex.fly.get_size() / 2)
		elif g.croc_bay == i:
			draw_texture(tex.croc, c - tex.croc.get_size() / 2)
	if g.state in [FroggerGame.State.PLAY, FroggerGame.State.READY]:
		var f := 1 if g.hop_t >= 0.0 else 0
		draw_set_transform(px(g.frog_center()), frog_angle(), Vector2.ONE)
		draw_texture(tex["frog%d" % f], -tex["frog%d" % f].get_size() / 2)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_fx() -> void:
	var g := game
	# ondulação do rio e linhas da estrada
	for r in range(1, 6):
		var rr := row_rect(r)
		var pts := PackedVector2Array()
		for x in range(0, int(rr.size.x) + 1, 24):
			pts.append(Vector2(rr.position.x + x, rr.get_center().y + sin(time * 2.0 + x * 0.05 + r) * 4.0))
		fx.draw_polyline(pts, Color(RIVER_C, 0.18), 2.0, true)
	for r in [6, 12]:
		var rr := row_rect(r)
		fx.draw_rect(rr.grow(-3), Color(ROAD_C, 0.45), false, 2.0)
	for r in range(7, 11):
		var y := row_rect(r).end.y
		for x in range(0, int(FroggerGame.W * S), 40):
			fx.draw_line(Vector2(FroggerGame.ORIGIN.x + x, y), Vector2(FroggerGame.ORIGIN.x + x + 20, y), Color(ROAD_C, 0.4), 2.0)
	for i in 5:
		fx.draw_rect(bay_rect(i), Color(FROG_C, 0.4), false, 2.0)
	fx.draw_line(row_rect(0).end - Vector2(row_rect(0).size.x, 0), row_rect(0).end, Color(FROG_C, 0.5), 2.0)
	# objetos
	for o in g.objects:
		if o.kind == "log":
			var r := obj_rect(o).grow_individual(-2, -5, -2, -5)
			fx.draw_rect(r, Color(LOG_C, 0.12))
			fx.draw_rect(r, Color(LOG_C, 0.9), false, 2.0)
		elif o.kind == "turtle":
			for sh in turtle_shells(o):
				if sh[1] > 0.0:
					fx.draw_circle(sh[0], sh[1] + 5.0, Color(TURTLE_C, 0.12), true, -1.0, true)
					fx.draw_arc(sh[0], sh[1], 0, TAU, 24, TURTLE_C, 2.0, true)
				else:
					fx.draw_arc(sh[0], 8.0, 0, TAU, 16, Color(TURTLE_C, 0.25), 1.0, true)
		else:
			var c: Color = CAR_C[o.kind]
			var r := obj_rect(o)
			fx.draw_rect(r.grow(4), Color(c, 0.08))
			for part in vehicle_parts(o):
				var role: String = part[1]
				if role == "wheel":
					fx.draw_rect(part[0], Color(c, 0.5))
				else:
					fx.draw_rect(part[0], Color(c, 0.9 if role != "window" else 0.4), false, 2.0)
			# rasto de luz atrás do veículo
			var left: bool = g.lane_speed(o.row) < 0.0
			var tail := r.end.x if left else r.position.x
			fx.draw_line(Vector2(tail, r.get_center().y), Vector2(tail + (40 if left else -40), r.get_center().y), Color(c, 0.25), 4.0)
	if g.state in [FroggerGame.State.PLAY, FroggerGame.State.READY]:
		var gt: Texture2D = glow["frog%d" % (1 if g.hop_t >= 0.0 else 0)]
		fx.draw_set_transform(px(g.frog_center()), frog_angle(), Vector2.ONE)
		fx.draw_texture_rect(gt, Rect2(-gt.get_size() * 1.5, gt.get_size() * 3), false, Color(1, 1, 1, 0.8))
		fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for r in rings:
		fx.draw_arc(r.pos, r.radius, 0.0, TAU, 40, Color(r.color, maxf(r.alpha, 0.0)), 3.0, true)
	for s in sparks:
		fx.draw_line(s.pos, s.pos - s.vel * 0.03, Color(s.color.lerp(Color.WHITE, 0.4), s.life / s.max), 2.0, true)
	for p in popups:
		_text(p.text, p.pos.x, p.pos.y, FROG_C, 22, clampf(p.life, 0.0, 1.0), fx)


func _draw_cover() -> void:
	for r in side_rects():
		cover.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
			PackedColorArray([BG_TOP, BG_TOP, BG_BOTTOM, BG_BOTTOM]))


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
	_text(I18n.t("NÍVEL"), rx, 230, label_c, 20, 0.9)
	_text(str(g.level()), rx, 280, FROG_C, 38, 0.9)
	_text(I18n.t("VIDAS"), lx, 540, label_c, 20, 0.9)
	var n := mini(maxi(g.player().lives, 0), 6)
	for i in n:
		var c := Vector2(lx - (mini(n, 3) - 1) * 24.0 + (i % 3) * 48.0, 580 + (i / 3) * 44)
		hud.draw_texture_rect(glow.frog0, Rect2(c - glow.frog0.get_size() * 1.5, glow.frog0.get_size() * 3), false, Color(1, 1, 1, 0.6))
		hud.draw_texture(tex.frog0, c - tex.frog0.get_size() / 2)
	var hud_row := row_rect(13)
	var frac := clampf(g.time_left / g.time_limit(), 0.0, 1.0)
	var c := FROG_C if g.time_left > 8.0 else Color("ff2b4f")
	var bar := Rect2(hud_row.end.x - 12 - 440 * frac, hud_row.position.y + 16, 440 * frac, 14)
	hud.draw_rect(bar.grow(4), Color(c, 0.15))
	hud.draw_rect(bar, c)
	_text(I18n.t("TEMPO"), hud_row.end.x - 500, hud_row.position.y + 32, label_c, 18, 0.9)


func _text(text: String, center_x: float, baseline: float, c: Color, size: int, alpha: float, ci: CanvasItem = null) -> void:
	var target: CanvasItem = ci if ci else hud
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(center_x - w / 2, baseline)
	target.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 12, Color(c, 0.12 * alpha))
	target.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 5, Color(c, 0.28 * alpha))
	target.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(c.lerp(Color.WHITE, 0.45), alpha))


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.04, 0.02, 0.13, 0.88),
		"border": Color("8a5cff"),
		"text": Color("ece6ff"),
		"accent": FROG_C,
		"button": Color("170a36"),
		"button_hover": Color("2a1361"),
		"radius": 10,
		"dim": Color(0, 0, 0, 0.3),
	}
