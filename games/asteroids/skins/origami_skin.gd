extends AsteroidsSkin
## Origami (estilo próprio): asteroides de papel amarrotado e facetado, que mudam de sombra
## ao rodar; a nave é um avião de papel e o disco voador um barquinho de papel.
## O céu é uma cartolina azul-noite com estrelas recortadas, e tudo se desfaz em confettis.
## Sons de papel: amarrotar, estalar, folhear e um apito de papel.

const LIGHT := Vector2(-0.6, -0.8)
const SKY_TOP := Color("1b2440")
const SKY_BOTTOM := Color("2b3459")
const CREAM := Color("f4ead5")
const PAPER := Color("f7f2e6")
const INK := Color("2b2d42")
const TAPE := Color("e9dcc0")
const SHADOW := Color(0.02, 0.03, 0.08, 0.35)
const ROCK_COLORS := [Color("e76f51"), Color("f4a261"), Color("e9c46a"), Color("2a9d8f"), Color("8ab17d"), Color("d9c5a0")]
const BOAT_RED := Color("e63946")

var font: Font
var bg_vp: SubViewport
var bg: Node2D
var time := 0.0
var shake := 0.0
var confetti: Array[Dictionary] = []
var debris: Array[Dictionary] = []     # metades do avião
var floaters: Array[Dictionary] = []


func _setup() -> void:
	font = ThemeDB.fallback_font
	bg_vp = SubViewport.new()
	bg_vp.size = Vector2i(int(W), int(H))
	bg_vp.disable_3d = true
	bg_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(bg_vp)
	bg = Node2D.new()
	bg_vp.add_child(bg)
	bg.draw.connect(_draw_background)


# ---------------------------------------------------------------- sons

static func _bell(f: float, dur: float, vol: float) -> PackedFloat32Array:
	var parts := []
	var ratios := [1.0, 2.76, 5.4]
	var decays := [3.0, 6.0, 11.0]
	var vols := [1.0, 0.45, 0.22]
	for i in 3:
		parts.append(Synth.render(f * ratios[i], dur, {"wave": "sine", "volume": vol * vols[i], "decay": decays[i] * 2.4 / dur, "attack": 0.001}))
	return Synth.mix(parts)


## Amarrotar papel: muitos estalidos curtos de ruído com volumes e filtros ao acaso.
static func _crumple(dur: float, vol: float, seed_value: int, bright := 0.5) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out := PackedFloat32Array()
	while out.size() < int(dur * Synth.RATE):
		var t := float(out.size()) / (dur * Synth.RATE)
		var env := 1.0 - t * 0.8
		out.append_array(Synth.render(0.0, rng.randf_range(0.012, 0.05), {"wave": "noise",
			"volume": vol * env * rng.randf_range(0.3, 1.0), "lowpass": rng.randf_range(0.15, bright), "decay": 40.0}))
		if rng.randf() < 0.5:
			out.append_array(Synth.silence(rng.randf_range(0.0, 0.03)))
	return out


func _build_sfx() -> void:
	for i in 2:
		sfx["beat%d" % i] = Synth.to_stream(Synth.mix([
			Synth.render([70.0, 62.0][i], 0.14, {"wave": "sine", "volume": 0.6, "decay": 28.0}),
			Synth.render(0.0, 0.05, {"wave": "noise", "volume": 0.2, "lowpass": 0.12, "decay": 70.0}),
		]))
	sfx.fire = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.035, {"wave": "noise", "volume": 0.3, "lowpass": 0.9, "decay": 120.0}),
		Synth.render(1300.0, 0.035, {"wave": "sine", "volume": 0.15, "decay": 100.0}),
	]))
	sfx.saucer_fire = Synth.tone(0.0, 0.06, {"wave": "noise", "volume": 0.18, "lowpass": 0.3, "decay": 50.0})
	sfx.boom0 = Synth.to_stream(_crumple(0.7, 0.45, 11))
	sfx.boom1 = Synth.to_stream(_crumple(0.45, 0.4, 22))
	sfx.boom2 = Synth.to_stream(_crumple(0.25, 0.35, 33, 0.7))
	sfx.ship_boom = Synth.to_stream(Synth.mix([_crumple(1.2, 0.5, 44), _crumple(0.5, 0.3, 55, 0.9)]))
	sfx.thrust = Synth.to_stream(_crumple(0.6, 0.12, 66, 0.3))
	var big := []
	for i in 2:
		big.append(Synth.render(1100.0, 0.12, {"wave": "sine", "volume": 0.1, "attack": 0.0, "release": 0.0}))
		big.append(Synth.render(1180.0, 0.12, {"wave": "sine", "volume": 0.1, "attack": 0.0, "release": 0.0}))
	sfx.saucer_big = Synth.concat(big)
	var small := []
	for i in 4:
		small.append(Synth.render(1600.0, 0.06, {"wave": "sine", "volume": 0.09, "attack": 0.0, "release": 0.0}))
		small.append(Synth.render(1750.0, 0.06, {"wave": "sine", "volume": 0.09, "attack": 0.0, "release": 0.0}))
	sfx.saucer_small = Synth.concat(small)
	var whoosh := PackedFloat32Array()
	for k in 8:
		whoosh.append_array(Synth.render(0.0, 0.04, {"wave": "noise", "volume": 0.08 + k * 0.02, "lowpass": 0.05 + k * 0.08, "attack": 0.0, "release": 0.0}))
	sfx.hyper = Synth.to_stream(whoosh)
	var chimes := []
	var notes := [1568.0, 1975.5, 2349.3, 3136.0]
	for i in notes.size():
		var s := Synth.silence(i * 0.08)
		s.append_array(_bell(notes[i], 0.8, 0.14))
		chimes.append(s)
	sfx.extra = Synth.to_stream(Synth.mix(chimes))


func rock_color(r: Dictionary) -> Color:
	return ROCK_COLORS[int(r.tint * ROCK_COLORS.size()) % ROCK_COLORS.size()]


# ---------------------------------------------------------------- eventos

func _on_match_started() -> void:
	confetti.clear()
	debris.clear()
	floaters.clear()


func _on_asteroid_destroyed(pos: Vector2, size: int, points: int, rock: Dictionary) -> void:
	super(pos, size, points, rock)
	var c := rock_color(rock)
	_confetti(pos, 18 - size * 5, c, 200.0 - size * 30.0)
	shake = maxf(shake, 4.0 - size)
	if points > 0:
		floaters.append({"pos": pos, "text": "+%d" % points, "life": 0.9})


func _on_saucer_destroyed(pos: Vector2, small: bool, points: int) -> void:
	super(pos, small, points)
	_confetti(pos, 26, BOAT_RED, 240.0)
	_confetti(pos, 10, PAPER, 200.0)
	if points > 0:
		floaters.append({"pos": pos, "text": "+%d" % points, "life": 1.3})


func _on_ship_destroyed(pos: Vector2) -> void:
	super(pos)
	shake = 12.0
	for half in _plane_halves(pos, game.ship_angle):
		debris.append({"pts": shifted(half.pts, -pos), "pos": pos, "vel": game.ship_vel * 0.4 + Vector2.from_angle(randf() * TAU) * 60.0,
			"rot": 0.0, "spin": randf_range(-3, 3), "color": half.color, "life": 2.2})
	_confetti(pos, 24, PAPER, 220.0)


func _on_hyperspace(from: Vector2, to: Vector2) -> void:
	super(from, to)
	_confetti(from, 10, PAPER, 120.0)
	_confetti(to, 10, PAPER, 120.0)


func _confetti(pos: Vector2, n: int, c: Color, speed: float) -> void:
	for i in n:
		confetti.append({"pos": pos, "vel": Vector2.from_angle(randf() * TAU) * randf_range(speed * 0.2, speed),
			"rot": randf() * TAU, "spin": randf_range(-12, 12), "size": Vector2(randf_range(3, 8), randf_range(2, 4)),
			"color": c.lightened(randf_range(-0.1, 0.25)), "life": randf_range(0.7, 1.4)})
	if confetti.size() > 400:
		confetti = confetti.slice(confetti.size() - 400)


# ---------------------------------------------------------------- animação

func _tick(dt: float) -> void:
	time += dt
	shake = move_toward(shake, 0.0, dt * 30.0)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	var drag := pow(0.15, dt)
	for c in confetti:
		c.vel = c.vel * drag + Vector2(0, 60.0 * dt)
		c.pos += c.vel * dt
		c.rot += c.spin * dt
		c.life -= dt
	confetti = confetti.filter(func(c: Dictionary) -> bool: return c.life > 0.0)
	for d in debris:
		d.pos += d.vel * dt
		d.rot += d.spin * dt
		d.life -= dt
	debris = debris.filter(func(d: Dictionary) -> bool: return d.life > 0.0)
	for f in floaters:
		f.pos.y -= 35.0 * dt
		f.life -= dt
	floaters = floaters.filter(func(f: Dictionary) -> bool: return f.life > 0.0)


# ---------------------------------------------------------------- desenho

func _draw_background() -> void:
	bg.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(W, 0), Vector2(W, H), Vector2(0, H)]),
		PackedColorArray([SKY_TOP, SKY_TOP, SKY_BOTTOM, SKY_BOTTOM]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# fibras do papel
	for i in 1800:
		var p := Vector2(rng.randf() * W, rng.randf() * H)
		var c := Color(1, 1, 1, rng.randf_range(0.02, 0.06)) if rng.randf() < 0.6 else Color(0, 0, 0, rng.randf_range(0.03, 0.08))
		bg.draw_line(p, p + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(2, 7), c, 1.0)
	# estrelas recortadas
	for i in 30:
		var p := Vector2(rng.randf() * W, rng.randf() * H)
		var s := rng.randf_range(5.0, 13.0)
		var rot := rng.randf() * TAU
		var star := PackedVector2Array()
		for k in 10:
			star.append(p + Vector2.from_angle(rot + k * TAU / 10) * (s if k % 2 == 0 else s * 0.45))
		bg.draw_colored_polygon(shifted(star, Vector2(2, 3)), SHADOW)
		bg.draw_colored_polygon(star, CREAM.darkened(rng.randf_range(0.0, 0.15)))


func _draw() -> void:
	var g := game
	draw_texture(bg_vp.get_texture(), Vector2.ZERO)
	# sombras primeiro (tudo "flutua" um pouco acima da cartolina)
	for r in g.rocks:
		for off in wrap_offsets(r.pos, r.r):
			draw_colored_polygon(shifted(g.rock_points(r, off), Vector2(6, 8) * (0.5 + r.r / 96.0)), SHADOW)
	for r in g.rocks:
		for off in wrap_offsets(r.pos, r.r):
			_draw_rock(r, off)
	if g.saucer != null:
		_draw_boat(g.saucer.pos, g.saucer.small)
	for b in g.saucer_bullets:
		draw_circle(b.pos + Vector2(2, 3), 3.5, SHADOW, true, -1.0, true)
		draw_circle(b.pos, 3.5, BOAT_RED, true, -1.0, true)
	for b in g.bullets:
		draw_circle(b.pos + Vector2(2, 3), 3.0, SHADOW, true, -1.0, true)
		draw_circle(b.pos, 3.0, PAPER, true, -1.0, true)
	if g.ship_visible() or (g.ship_waiting() and fmod(time, 0.5) < 0.3):
		for off in wrap_offsets(g.ship_pos, 20.0):
			_draw_plane(g.ship_pos + off, g.ship_angle, 1.0, g.thrusting)
	for d in debris:
		var pts := PackedVector2Array()
		for p: Vector2 in d.pts:
			pts.append(d.pos + p.rotated(d.rot))
		draw_colored_polygon(pts, Color(d.color, clampf(d.life, 0.0, 1.0)))
	for c in confetti:
		draw_set_transform(c.pos, c.rot, Vector2.ONE)
		var sz: Vector2 = c.size
		draw_rect(Rect2(-sz / 2, sz), Color(c.color, clampf(c.life * 2.0, 0.0, 1.0)))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for f in floaters:
		_label(f.text, f.pos, 20, clampf(f.life * 2.0, 0.0, 1.0))
	_draw_hud()


func _draw_rock(r: Dictionary, off: Vector2) -> void:
	var pts := game.rock_points(r, off)
	var base := rock_color(r)
	var apex: Vector2 = r.pos + off + Vector2.from_angle(r.angle + r.tint * TAU) * r.r * 0.2
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		var n := ((a + b) / 2 - apex).normalized()
		var k := n.dot(LIGHT)
		var col := base.lightened(k * 0.25) if k > 0.0 else base.darkened(-k * 0.3)
		draw_colored_polygon(PackedVector2Array([apex, a, b]), col)
	for p in pts:
		draw_line(apex, p, Color(base.darkened(0.45), 0.35), 1.0, true)
	draw_polyline(closed(pts), base.darkened(0.4), 1.5, true)


func _plane_halves(pos: Vector2, angle: float, scale := 1.0) -> Array[Dictionary]:
	var nose := pos + Vector2(18, 0).rotated(angle) * scale
	var lw := pos + Vector2(-12, -13).rotated(angle) * scale
	var tail := pos + Vector2(-7, 0).rotated(angle) * scale
	var rw := pos + Vector2(-12, 13).rotated(angle) * scale
	var out: Array[Dictionary] = []
	for side in [-1.0, 1.0]:
		var nrm := Vector2(0, side).rotated(angle)
		var k := nrm.dot(LIGHT)
		var col := PAPER.lightened(k * 0.05) if k > 0.0 else PAPER.darkened(-k * 0.18)
		out.append({"pts": PackedVector2Array([nose, lw if side < 0 else rw, tail]), "color": col})
	return out


func _draw_plane(pos: Vector2, angle: float, scale: float, thrust: bool) -> void:
	var halves := _plane_halves(pos, angle, scale)
	for h in halves:
		draw_colored_polygon(shifted(h.pts, Vector2(7, 10) * scale), SHADOW)
	if thrust:
		for side in [-1.0, 1.0]:
			var line := PackedVector2Array()
			for k in 6:
				var t := k / 5.0
				line.append(pos + Vector2(-8 - t * 22, side * 4 + sin(time * 30.0 + t * 6.0 + side) * 3.0 * t).rotated(angle))
			draw_polyline(line, Color("e63946") if side < 0 else Color("f4a261"), 2.5, true)
	for h in halves:
		draw_colored_polygon(h.pts, h.color)
	var nose := pos + Vector2(18, 0).rotated(angle) * scale
	var tail := pos + Vector2(-7, 0).rotated(angle) * scale
	draw_line(nose, tail, Color(INK, 0.35), 1.2, true)
	for h in halves:
		draw_polyline(closed(h.pts), Color(INK, 0.25), 1.0, true)


func _draw_boat(pos: Vector2, small: bool) -> void:
	var s := 0.6 if small else 1.0
	var rot := sin(time * 3.0) * 0.08
	var hull := [Vector2(-22, 0), Vector2(22, 0), Vector2(15, 10), Vector2(-15, 10)]
	var sail := [Vector2(0, -18), Vector2(0, 0), Vector2(14, 0)]
	var back := [Vector2(-12, 0), Vector2(0, -18), Vector2(0, 0)]
	var parts := [[hull, BOAT_RED if not small else Color("f4a261")], [back, PAPER.darkened(0.15)], [sail, PAPER]]
	for part in parts:
		var pts := PackedVector2Array()
		for p: Vector2 in part[0]:
			pts.append(pos + (p * s).rotated(rot))
		draw_colored_polygon(shifted(pts, Vector2(6, 8) * s), SHADOW)
	for part in parts:
		var pts := PackedVector2Array()
		for p: Vector2 in part[0]:
			pts.append(pos + (p * s).rotated(rot))
		draw_colored_polygon(pts, part[1])
		draw_polyline(closed(pts), Color(INK, 0.3), 1.0, true)


func _draw_hud() -> void:
	var g := game
	_tape(Vector2(150, 50), Vector2(210, 56), -0.04)
	_text(str(g.players[0].score), Vector2(150, 66), 36, Color(INK, 1.0 if g.current == 0 else 0.45))
	_tape(Vector2(W / 2, 36), Vector2(130, 36), 0.03)
	_text(str(maxi(g.best, g.player().score)), Vector2(W / 2, 46), 22, Color(INK, 0.8))
	if g.players.size() > 1:
		_tape(Vector2(W - 150, 50), Vector2(210, 56), 0.05)
		_text(str(g.players[1].score), Vector2(W - 150, 66), 36, Color(INK, 1.0 if g.current == 1 else 0.45))
	var x0 := 70.0 if g.current == 0 else W - 230.0
	for i in mini(g.player().lives, 8):
		_draw_plane(Vector2(x0 + i * 26.0, 104), -PI / 2, 0.55, false)


## Fita-cola de papel com as pontas rasgadas.
func _tape(center: Vector2, size: Vector2, rot: float) -> void:
	var pts := PackedVector2Array()
	var hw := size.x / 2
	var hh := size.y / 2
	pts.append(Vector2(-hw, -hh))
	pts.append(Vector2(hw, -hh))
	for k in 6:
		pts.append(Vector2(hw + (4.0 if k % 2 == 0 else -2.0), -hh + size.y * (k + 1) / 7.0))
	pts.append(Vector2(hw, hh))
	pts.append(Vector2(-hw, hh))
	for k in 6:
		pts.append(Vector2(-hw + (-4.0 if k % 2 == 0 else 2.0), hh - size.y * (k + 1) / 7.0))
	var out := PackedVector2Array()
	for p in pts:
		out.append(center + p.rotated(rot))
	draw_colored_polygon(shifted(out, Vector2(3, 4)), SHADOW)
	draw_colored_polygon(out, Color(TAPE, 0.94))


func _text(text: String, pos: Vector2, size: int, c: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(pos.x - w / 2, pos.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)


func _label(text: String, pos: Vector2, size: int, alpha: float) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := Vector2(pos.x - w / 2, pos.y)
	draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color(INK, 0.8 * alpha))
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(CREAM, alpha))


func ui_palette() -> Dictionary:
	return {
		"panel": Color(CREAM, 0.97),
		"border": INK,
		"text": INK,
		"accent": Color("e76f51"),
		"button": Color("efe3c8"),
		"button_hover": Color("f6d9b8"),
		"radius": 6,
		"dim": Color(0.1, 0.12, 0.2, 0.3),
	}
