extends FlockSkin
## Plasticina: tudo parece moldado à mão — terreno de barro cor de terracota com relva de
## plasticina verde e arestas macias, nuvens e sol de massa, ovelhas fofas feitas de bolinhas
## brancas com cabeça castanha e olhos redondos, e botões de plasticina no painel.

const SKY_TOP := Color("8ec8e8")
const SKY_BOT := Color("f4e8c8")
const CLAY := Color("d07a48")
const CLAY_DARK := Color("a85a34")
const GRASS := Color("6ab84a")
const GRASS_LIGHT := Color("94d86a")
const STEEL := Color("7088a0")
const BRICK := Color("f0c040")
const WOOL := Color("fbf6ee")
const WOOL_SH := Color("d8d0c4")
const HEAD := Color("5a3a2a")

var _clouds: Array[Vector3] = []


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for i in 5:
		_clouds.append(Vector3(rng.randf_range(0, 1280), rng.randf_range(50, 220), rng.randf_range(0.7, 1.3)))


func _build_sfx() -> void:
	sfx.start = Synth.concat([Synth.render(392.0, 0.12, {"wave": "triangle", "volume": 0.2}), Synth.render(523.0, 0.12, {"wave": "triangle", "volume": 0.2}), Synth.render(659.0, 0.25, {"wave": "triangle", "volume": 0.2})])
	# balido: onda triangular com vibrato
	var b := PackedFloat32Array()
	var n := int(0.35 * Synth.RATE)
	b.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / Synth.RATE
		var f := 420.0 + sin(t * TAU * 18.0) * 30.0 - t * 80.0
		ph += f / Synth.RATE
		var env := minf(t / 0.03, 1.0) * clampf((0.35 - t) / 0.1, 0.0, 1.0)
		b[i] = (absf(fmod(ph, 1.0) * 4.0 - 2.0) - 1.0) * 0.18 * env
	sfx.release = Synth.to_stream(b)
	sfx.assign = Synth.tone(300.0, 0.08, {"wave": "sine", "freq_end": 600.0, "volume": 0.25, "decay": 20.0})
	sfx.saved = Synth.concat([Synth.render(660.0, 0.08, {"wave": "sine", "volume": 0.2}), Synth.render(990.0, 0.14, {"wave": "sine", "volume": 0.2, "decay": 10.0})])
	sfx.splat = Synth.tone(160.0, 0.25, {"wave": "sine", "freq_end": 40.0, "volume": 0.4, "decay": 10.0})
	sfx.fall = Synth.tone(700.0, 0.6, {"wave": "sine", "freq_end": 150.0, "volume": 0.2})
	sfx.brick = Synth.tone(220.0, 0.06, {"wave": "sine", "freq_end": 140.0, "volume": 0.25, "decay": 30.0})
	var ok := []
	for f in [392.0, 494.0, 587.0, 784.0]:
		ok.append(Synth.render(f, 0.16, {"wave": "triangle", "volume": 0.2, "decay": 4.0}))
	sfx.success = Synth.concat(ok)
	sfx.fail = Synth.concat([Synth.render(330.0, 0.25, {"wave": "triangle", "volume": 0.2}), Synth.render(262.0, 0.45, {"wave": "triangle", "volume": 0.2, "freq_end": 240.0})])
	var w := []
	for f in [392.0, 494.0, 587.0, 784.0, 587.0, 784.0, 988.0]:
		w.append(Synth.render(f, 0.15, {"wave": "triangle", "volume": 0.2, "decay": 4.0}))
	sfx.win = Synth.concat(w)


func _draw_back() -> void:
	var cols := PackedColorArray([SKY_TOP, SKY_TOP, SKY_BOT, SKY_BOT])
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(1280, 0), Vector2(1280, 600), Vector2(0, 600)]), cols)
	draw_circle(Vector2(1120, 110), 52, Color("f0a830"))
	draw_circle(Vector2(1112, 100), 40, Color("f8c850"))
	draw_circle(Vector2(1100, 88), 12, Color(1, 1, 1, 0.35))
	for c in _clouds:
		var x := fmod(c.x + time * 8.0 * c.z, 1480.0) - 100.0
		_cloud(Vector2(x, c.y), c.z)


func _cloud(p: Vector2, s: float) -> void:
	for k in 2:
		var off := Vector2(0, 6) if k == 0 else Vector2.ZERO
		var col := Color("c8d8e4") if k == 0 else Color("ffffff")
		draw_circle(p + off + Vector2(-34, 6) * s, 22 * s, col)
		draw_circle(p + off + Vector2(0, -6) * s, 30 * s, col)
		draw_circle(p + off + Vector2(32, 4) * s, 24 * s, col)
		draw_circle(p + off + Vector2(0, 12) * s, 22 * s, col)


func terrain_color(x: int, y: int, kind: int, top: int, edge: bool) -> Color:
	var wob := sin(x * 0.21 + y * 0.13) * 0.5 + sin(x * 0.07 - y * 0.29) * 0.5
	match kind:
		FlockGame.STEEL:
			var c := STEEL.lightened(0.25) if top == 0 else STEEL
			return c.darkened(0.25) if edge else c.lightened(wob * 0.04)
		FlockGame.BRICK:
			var c := BRICK.lightened(0.3) if top == 0 else BRICK
			return c.darkened(0.2) if edge else c
	if top <= 2:
		var g := GRASS_LIGHT if top == 0 else GRASS
		return g.darkened(0.15) if edge else g.lightened(wob * 0.05)
	var c := CLAY.lightened(wob * 0.06 + hash01(x / 3, y / 3) * 0.05)
	if top == 3:
		c = CLAY_DARK
	if edge:
		c = CLAY_DARK.darkened(0.1)
	return c


func _draw_entrance(p: Vector2, open: float) -> void:
	var r := Rect2(p.x - 50, p.y - 78, 100, 34)
	_blob_rect(r, Color("b8784a"), 12)
	for k in 3:
		draw_line(Vector2(r.position.x + 12, r.position.y + 10 + k * 8), Vector2(r.end.x - 12, r.position.y + 10 + k * 8), Color("94603a"), 3.0)
	var ang := open * PI * 0.45
	for k in 2:
		var h := Vector2(r.position.x + 12, r.end.y - 4) if k == 0 else Vector2(r.end.x - 12, r.end.y - 4)
		var e := h + Vector2.from_angle(ang if k == 0 else PI - ang) * 38
		draw_line(h, e, Color("8a5434"), 9.0)
		draw_circle(e, 4.5, Color("8a5434"))
		draw_circle(h, 4.5, Color("8a5434"))


func _blob_rect(r: Rect2, c: Color, radius: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c.darkened(0.2)
	sb.set_corner_radius_all(radius)
	draw_style_box(sb, Rect2(r.position + Vector2(0, 4), r.size))
	sb.bg_color = c
	draw_style_box(sb, r)
	sb.bg_color = Color(1, 1, 1, 0.18)
	draw_style_box(sb, Rect2(r.position + Vector2(6, 4), Vector2(r.size.x - 12, r.size.y * 0.3)))


func _draw_exit_back(p: Vector2) -> void:
	var base := p + Vector2(2, 6)
	var body := PackedVector2Array()
	body.append(base + Vector2(-46, 0))
	body.append(base + Vector2(-46, -50))
	for k in 9:
		body.append(base + Vector2(0, -50) + Vector2.from_angle(PI + PI * k / 8.0) * Vector2(46, 34))
	body.append(base + Vector2(46, 0))
	var shade := PackedVector2Array()
	for v in body:
		shade.append(v + Vector2(4, 4))
	draw_colored_polygon(shade, Color("8a2a20"))
	draw_colored_polygon(body, Color("d0483a"))
	draw_arc(base + Vector2(0, -50), 38, PI * 1.15, PI * 1.6, 10, Color(1, 1, 1, 0.3), 6.0)
	_blob_rect(Rect2(base + Vector2(-18, -44), Vector2(36, 44)), Color("fbf6ee"), 10)
	draw_rect(Rect2(base + Vector2(-12, -38), Vector2(24, 38)), Color("3a2018"))
	draw_circle(base + Vector2(0, -66), 7, Color("fbf6ee"))


func _draw_sheep(s: Dictionary, p: Vector2, hov: bool) -> void:
	var job: int = s.job
	var d := float(s.dir)
	var a := 1.0
	if job == FlockGame.Job.EXIT:
		a = 1.0 - clampf(float(s.t) / 8.0, 0.0, 1.0)
	if job == FlockGame.Job.SPLAT:
		draw_set_transform(p, 0.0, Vector2(1.6, 0.35))
		_wool(Vector2(0, -8), 1.0, a)
		draw_set_transform(Vector2.ZERO)
		return
	if job == FlockGame.Job.FLOAT:
		_draw_umbrella(p + Vector2(0, -50), int(s.anim))
	var rot := 0.0
	var origin := p
	if job == FlockGame.Job.CLIMB:
		rot = -PI / 2 * d
		origin = p + Vector2(-d * 4, -6)
	draw_set_transform(origin, rot, Vector2.ONE)
	var bob := absf(sin(float(s.anim) * 0.8)) * 2.0 if job == FlockGame.Job.WALK else 0.0
	var ph := float(s.anim) * 0.8
	var lc := HEAD.darkened(0.2)
	if job == FlockGame.Job.BLOCK:
		for k: float in [-1.0, 1.0]:
			draw_line(Vector2(k * 6, -10), Vector2(k * 12, 0), lc, 5.0)
			draw_line(Vector2(k * 13, -24), Vector2(k * 24, -28), lc, 5.0)
		_wool(Vector2(0, -20), 1.05, a)
		draw_circle(Vector2(0, -24), 8.5, Color(HEAD, a))
		draw_circle(Vector2(-3.5, -26), 2.6, Color(1, 1, 1, a))
		draw_circle(Vector2(3.5, -26), 2.6, Color(1, 1, 1, a))
		draw_circle(Vector2(-3.5, -26), 1.2, Color(0, 0, 0, a))
		draw_circle(Vector2(3.5, -26), 1.2, Color(0, 0, 0, a))
	else:
		var falling := job == FlockGame.Job.FALL or job == FlockGame.Job.FLOAT
		for k in 2:
			var lx := (-6.0 + k * 10.0) * d
			var sw := sin(ph + k * PI) * 4.0 if job == FlockGame.Job.WALK else 0.0
			if falling:
				draw_line(Vector2(lx, -14), Vector2(lx - d * 4, -4), Color(lc, a), 5.0)
			else:
				draw_line(Vector2(lx, -12 - bob), Vector2(lx + sw * d, 0), Color(lc, a), 5.0)
		_wool(Vector2(0, -20 - bob), 1.0, a)
		var hp := Vector2(d * 14, -24 - bob)
		draw_circle(hp, 7.5, Color(HEAD, a))
		draw_circle(hp + Vector2(d * 4, -1), 5.0, Color(HEAD.lightened(0.1), a))
		draw_circle(hp + Vector2(-d * 3, -7), 3.0, Color(HEAD, a))
		draw_circle(hp + Vector2(d * 2.5, -2.5), 2.4, Color(1, 1, 1, a))
		draw_circle(hp + Vector2(d * 3.2, -2.5), 1.1, Color(0, 0, 0, a))
	draw_set_transform(Vector2.ZERO)
	_draw_tool(s, p)
	if hov:
		draw_arc(p + Vector2(0, -18), 30, 0, TAU, 28, Color("ffffff"), 3.0)
		draw_arc(p + Vector2(0, -18), 33, 0, TAU, 28, Color("d0483a"), 2.0)


func _wool(c: Vector2, s: float, a: float) -> void:
	var puffs := [Vector2(-9, 2), Vector2(0, 4), Vector2(9, 2), Vector2(-6, -5), Vector2(5, -6), Vector2(0, 0)]
	for v: Vector2 in puffs:
		draw_circle(c + v * s + Vector2(1, 3), 7.5 * s, Color(WOOL_SH, a))
	for v: Vector2 in puffs:
		draw_circle(c + v * s, 7.0 * s, Color(WOOL, a))
	draw_circle(c + Vector2(-4, -6) * s, 2.5 * s, Color(1, 1, 1, a))


func _draw_part(p: Dictionary) -> void:
	var a := clampf(p.life * 2.0, 0.0, 1.0)
	draw_circle(p.pos + Vector2(1, 2), p.size * 0.6, Color(0, 0, 0, a * 0.15))
	draw_circle(p.pos, p.size * 0.6, Color(p.color, a))


func _draw_button(i: int, r: Rect2, count: String, active: bool) -> void:
	var pal := panel_palette()
	var base: Color = pal.button_on if active else pal.button
	var rr := r.grow(-2)
	if active:
		rr.position.y += 3
	_blob_rect(rr, base, 16)
	var dim := i >= 2 and i <= 8 and count == "0"
	var col: Color = pal.icon_dim if dim else pal.icon
	if count != "":
		PixelFont.draw(self, count, rr.get_center().x, rr.position.y + 9, 3, pal.count)
	draw_icon(i, rr.get_center() + Vector2(0, 20), 28.0, col, 5.0)


func wool_color() -> Color:
	return WOOL


func saved_colors() -> Array:
	return [Color("f8c850"), Color("6ab84a"), Color("d0483a"), Color("8ec8e8")]


func tool_color() -> Color:
	return Color("6a4a3a")


func brick_color() -> Color:
	return BRICK


func umbrella_color() -> Color:
	return Color("e05aa0")


func panel_palette() -> Dictionary:
	return {"bg": Color("6a9a4a"), "button": Color("f0dcb8"), "button_on": Color("f8c850"), "border": Color("8a6a4a"),
		"icon": Color("5a3a2a"), "icon_dim": Color(0.35, 0.23, 0.16, 0.3), "count": Color("d0483a"), "accent": Color("ffffff"),
		"status_bg": Color(0.3, 0.2, 0.1, 0.35), "status_text": Color("ffffff"), "cursor": Color("ffffff")}


func ui_palette() -> Dictionary:
	return {
		"panel": Color("f4e8c8", 0.96),
		"border": Color("d0483a"),
		"text": Color("5a3a2a"),
		"accent": Color("d0483a"),
		"button": Color("f0dcb8"),
		"button_hover": Color("f8c850"),
		"radius": 18,
		"dim": Color(0.2, 0.3, 0.4, 0.35),
	}
