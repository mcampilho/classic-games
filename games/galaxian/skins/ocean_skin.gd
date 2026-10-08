extends GalaxianSkin
## Oceano (estilo próprio): a batalha passa-se no fundo do mar. A formação é um cardume —
## peixes, medusas, caranguejos e um tamboril com a sua lanterna — e o jogador pilota um
## pequeno submarino que dispara torpedos. Bolhas, raios de luz, tinta e sons de sonar.

const DEEP_TOP := Color("0b4f6c")
const DEEP_BOTTOM := Color("051a2e")
const SAND := Color("c2a878")
const BRASS := Color("c99a3b")
const INK := Color("2a1033")
const BUBBLE := Color("cdeffd")

const CREATURES := [
	[   # 0 tamboril (almirante)
		["......L......", ".....L.......", "....C........", "...BBBBBBB...", "..BBEBBBEBB..", ".BBBBBBBBBBB.", "BBWBWBWBWBWBB", ".BBBBBBBBBBB.", "..BBBBBBBBB..", "...C.....C..."],
		["......L......", ".......L.....", "........C....", "...BBBBBBB...", "..BBEBBBEBB..", ".BBBBBBBBBBB.", "BBWBWBWBWBWBB", ".BBBBBBBBBBB.", "..BBBBBBBBB..", "..C.......C.."],
	],
	[   # 1 caranguejo (escolta)
		["B.........B", "BB.......BB", ".B.BBBBB.B.", "..BBEBEBB..", ".BBBBBBBBB.", "B.BBBBBBB.B", "..C.C.C.C..", ".C.......C."],
		[".B.......B.", "BB.......BB", "B..BBBBB..B", "..BBEBEBB..", ".BBBBBBBBB.", ".BBBBBBBBB.", ".C.C...C.C.", "C.........C"],
	],
	[   # 2 medusa (emissário)
		["...BBBBB...", "..BBBBBBB..", ".BBEBBBEBB.", ".BBBBBBBBB.", ".C.C.C.C.C.", ".C.C.C.C.C.", "C.C.C.C.C..", "..C...C...."],
		["...BBBBB...", "..BBBBBBB..", ".BBEBBBEBB.", ".BBBBBBBBB.", "..C.C.C.C..", ".C.C.C.C.C.", "..C.C.C.C.C", "....C...C.."],
	],
	[   # 3 peixe (zangão)
		["....CCC....", ".....C.....", "....BBB....", "...BBBBB...", "..BBBBBBB..", "..BEBBBEB..", "...BBBBB...", "....BBB...."],
		["...CCC.....", "....C......", "....BBB....", "...BBBBB...", "..BBBBBBB..", "..BEBBBEB..", "...BBBBB...", "....BBB...."],
	],
]
const PALETTES := [
	{"B": Color("3b2a4d"), "C": Color("5e4a73"), "E": Color("fff3b0"), "W": Color("f1f1f1"), "L": Color("fff59d")},
	{"B": Color("e8590c"), "C": Color("ffa94d"), "E": Color("1b1b1b")},
	{"B": Color("e599f7"), "C": Color("f3d9fa"), "E": Color("5f3dc4")},
	{"B": Color("ffd43b"), "C": Color("74c0fc"), "E": Color("1b1b1b")},
]
const SUB := [
	"......P......",
	"......P......",
	".....SSS.....",
	"....SSWSS....",
	"...SSSSSSS...",
	"..SSWSSSWSS..",
	"..SSSSSSSSS..",
	"..SSWSSSWSS..",
	".SS.SSSSS.SS.",
	"S...S...S...S",
]
const SUB_PAL := {"S": Color("ff6b35"), "W": Color("a5f3fc"), "P": Color("495057")}

var font: Font
var bg_vp: SubViewport
var bg: Node2D
var fx: Node2D
var tex := {}
var time := 0.0
var bubbles: Array[Dictionary] = []
var inks: Array[Dictionary] = []
var torpedo_trail: Array[Vector2] = []
var shake := 0.0


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
	for kind in 4:
		for fr in 2:
			tex["a%d%d" % [kind, fr]] = PixelArt.texture(CREATURES[kind][fr], PALETTES[kind])
	tex.sub = PixelArt.texture(SUB, SUB_PAL)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 40:
		bubbles.append({"pos": Vector2(rng.randf() * 1280, rng.randf() * 720), "r": rng.randf_range(1.5, 5.0),
			"speed": rng.randf_range(20, 60), "wob": rng.randf() * TAU, "life": -1.0})


func _build_sfx() -> void:
	var hum := []
	for i in 2:
		hum.append(Synth.render(55.0, 0.4, {"wave": "sine", "volume": 0.25, "attack": 0.15, "release": 0.15}))
		hum.append(Synth.render(49.0, 0.4, {"wave": "sine", "volume": 0.18, "attack": 0.15, "release": 0.15}))
	sfx.hum = Synth.concat(hum)
	sfx.dive = Synth.tone(1250.0, 0.9, {"wave": "sine", "freq_end": 1150.0, "volume": 0.16, "decay": 4.0})   # sonar
	sfx.fire = Synth.tone(260.0, 0.12, {"wave": "sine", "freq_end": 900.0, "volume": 0.3, "decay": 14.0})    # bloop
	var pops := [Synth.render(0.0, 0.3, {"wave": "noise", "volume": 0.18, "lowpass": 0.06, "decay": 10.0})]
	for i in 4:
		var s := Synth.silence(i * 0.04)
		s.append_array(Synth.render(500.0 + i * 220.0, 0.06, {"wave": "sine", "freq_end": 1100.0 + i * 260.0, "volume": 0.18, "decay": 30.0}))
		pops.append(s)
	sfx.kill = Synth.to_stream(Synth.mix(pops))
	var song := []
	for f in [392.0, 523.25, 659.25, 783.99, 1046.5]:
		song.append(Synth.render(f, 0.09, {"wave": "sine", "volume": 0.25, "decay": 10.0}))
	sfx.flag_kill = Synth.concat(song)
	sfx.player_hit = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.6, {"wave": "noise", "volume": 0.5, "lowpass": 0.04, "decay": 2.0}),
		Synth.render(70.0, 1.2, {"wave": "sine", "freq_end": 30.0, "volume": 0.4, "decay": 2.5}),
	]))
	var up := []
	for f in [523.25, 783.99, 1046.5, 1568.0]:
		up.append(Synth.render(f, 0.07, {"wave": "sine", "freq_end": f * 1.5, "volume": 0.2, "decay": 20.0}))
	sfx.extra = Synth.concat(up)


func _on_alien_killed(pos: Vector2, kind: int, points: int, diving: bool) -> void:
	super(pos, kind, points, diving)
	var p := px(pos)
	for i in 10 + (10 if kind == 0 else 0):
		bubbles.append({"pos": p + Vector2(randf_range(-14, 14), randf_range(-10, 10)), "r": randf_range(2.0, 6.0),
			"speed": randf_range(60, 140), "wob": randf() * TAU, "life": randf_range(0.8, 1.6)})
	if kind == 2 or kind == 0:
		inks.append({"pos": p, "r": 6.0, "life": 1.0})


func _on_player_hit(pos: Vector2) -> void:
	super(pos)
	shake = 12.0
	var p := px(pos)
	inks.append({"pos": p, "r": 10.0, "life": 1.6})
	for i in 30:
		bubbles.append({"pos": p + Vector2(randf_range(-20, 20), randf_range(-10, 10)), "r": randf_range(2.0, 8.0),
			"speed": randf_range(60, 180), "wob": randf() * TAU, "life": randf_range(1.0, 2.0)})


func _tick(dt: float) -> void:
	time += dt
	shake = move_toward(shake, 0.0, dt * 30.0)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	for b in bubbles:
		b.pos.y -= b.speed * dt
		b.pos.x += sin(time * 3.0 + b.wob) * 12.0 * dt
		if b.life >= 0.0:
			b.life -= dt
		elif b.pos.y < -10.0:
			b.pos.y = 730.0
	bubbles = bubbles.filter(func(b: Dictionary) -> bool: return b.life == -1.0 or b.life > 0.0)
	for k in inks:
		k.r += 40.0 * dt
		k.life -= dt
	inks = inks.filter(func(k: Dictionary) -> bool: return k.life > 0.0)
	if game.missile != null:
		torpedo_trail.append(px(game.missile) + Vector2(0, 14))
		if torpedo_trail.size() > 10:
			torpedo_trail.pop_front()
	else:
		torpedo_trail.clear()
	fx.queue_redraw()


# ---------------------------------------------------------------- desenho

func _draw_background() -> void:
	bg.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)]),
		PackedColorArray([DEEP_TOP, DEEP_TOP, DEEP_BOTTOM, DEEP_BOTTOM]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	# areia e algas nas laterais
	for side in [0, 1]:
		var x0 := 0.0 if side == 0 else 976.0
		bg.draw_rect(Rect2(x0, 680, 304, 40), SAND.darkened(0.45))
		for k in 7:
			var base := Vector2(x0 + 20 + rng.randf() * 264, 690)
			var pts := PackedVector2Array()
			var h := rng.randf_range(80, 220)
			for t in 12:
				pts.append(base + Vector2(sin(t * 0.7 + k) * 8.0, -h * t / 11.0))
			bg.draw_polyline(pts, Color("2f9e44", 0.5).darkened(rng.randf() * 0.4), rng.randf_range(4, 9), true)
	bg.draw_rect(Rect2(304, 708, 672, 12), SAND.darkened(0.3))
	# vigias de latão para os painéis
	for cx in [152.0, 1128.0]:
		bg.draw_circle(Vector2(cx, 190), 128.0, BRASS.darkened(0.35), true, -1.0, true)
		bg.draw_circle(Vector2(cx, 190), 118.0, BRASS, true, -1.0, true)
		bg.draw_circle(Vector2(cx, 190), 100.0, Color("082c44"), true, -1.0, true)
		for k in 8:
			bg.draw_circle(Vector2(cx, 190) + Vector2.from_angle(k * TAU / 8) * 109.0, 4.0, BRASS.darkened(0.45), true, -1.0, true)


func _draw() -> void:
	var g := game
	draw_texture(bg_vp.get_texture(), Vector2.ZERO)
	for k in inks:
		draw_circle(k.pos, k.r, Color(INK, 0.5 * k.life), true, -1.0, true)
	for a in g.aliens:
		if a.alive:
			draw_texture(tex["a%d%d" % [a.kind, g.anim_frame]], px(a.pos))
	for b in g.bombs:
		var p := px(b.pos)
		draw_circle(p + Vector2(0, 6), 4.0, Color("6741d9"), true, -1.0, true)
		draw_circle(p + Vector2(-1, 4), 1.5, Color(1, 1, 1, 0.5), true, -1.0, true)
	if g.missile != null:
		_torpedo(px(g.missile))
	if not player_dying() and g.state != GalaxianGame.State.OVER:
		draw_texture(tex.sub, px(g.player_rect().position))
	for p in popups:
		_text(p.text, px(p.pos), 26, Color("fff59d"))
	_draw_panels()


func _torpedo(p: Vector2) -> void:
	draw_rect(Rect2(p - Vector2(2.5, 0), Vector2(5, 14)), Color("adb5bd"))
	draw_circle(p + Vector2(0, 1), 2.5, Color("dee2e6"), true, -1.0, true)


func _draw_fx() -> void:
	# raios de luz vindos da superfície
	for i in 4:
		var x := 340.0 + i * 170.0 + sin(time * 0.4 + i) * 30.0
		fx.draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 60, 0), Vector2(x + 180, 720), Vector2(x + 90, 720)]),
			Color(0.6, 0.9, 1.0, 0.03 + 0.015 * sin(time * 0.9 + i * 1.7)))
	# lanterna dos tamboris
	for a in game.aliens:
		if a.alive and a.kind == 0:
			fx.draw_circle(px(a.pos + Vector2(6.5, 0.5)), 14.0 + 3.0 * sin(time * 5.0), Color(1.0, 0.95, 0.5, 0.18), true, -1.0, true)
	for t in torpedo_trail.size():
		fx.draw_circle(torpedo_trail[t] + Vector2(sin(t + time * 10.0) * 2.0, 0), 1.5 + t * 0.2, Color(BUBBLE, 0.05 * t), true, -1.0, true)
	for b in bubbles:
		var a := 0.35 if b.life < 0.0 else clampf(b.life, 0.0, 1.0) * 0.6
		fx.draw_arc(b.pos, b.r, 0, TAU, 14, Color(BUBBLE, a), 1.2, true)
		fx.draw_circle(b.pos - Vector2(b.r, b.r) * 0.35, b.r * 0.25, Color(1, 1, 1, a), true, -1.0, true)
	if player_dying():
		var c := px(game.player_rect().get_center())
		fx.draw_circle(c, 40.0 * (1.0 - game.timer / 2.2) + 10.0, Color(1.0, 0.6, 0.3, 0.3 * game.timer / 2.2), true, -1.0, true)


func _draw_panels() -> void:
	var g := game
	var lx := 152.0
	var rx := 1128.0
	_text(I18n.t("JOGADOR 1"), Vector2(lx, 140), 18, Color(BUBBLE, 1.0 if (g.current == 0 or g.players.size() == 1) else 0.45))
	_text(str(g.players[0].score), Vector2(lx, 192), 44, Color("ffd43b", 1.0 if (g.current == 0 or g.players.size() == 1) else 0.45))
	_text(I18n.t("RECORDE ") + str(maxi(g.best, g.player().score)), Vector2(lx, 240), 16, Color(BUBBLE, 0.8))
	if g.players.size() > 1:
		_text(I18n.t("JOGADOR 2"), Vector2(rx, 140), 18, Color(BUBBLE, 1.0 if g.current == 1 else 0.45))
		_text(str(g.players[1].score), Vector2(rx, 192), 44, Color("ffd43b", 1.0 if g.current == 1 else 0.45))
		_text(I18n.t("VAGA %d") % g.player().wave, Vector2(rx, 240), 16, Color(BUBBLE, 0.8))
	else:
		_text(I18n.t("VAGA"), Vector2(rx, 150), 18, BUBBLE)
		_text(str(g.player().wave), Vector2(rx, 210), 52, Color("ffd43b"))
	var n := mini(maxi(g.player().lives, 0), 5)
	_text(I18n.t("SUBMARINOS"), Vector2(lx, 420), 16, Color(BUBBLE, 0.8))
	for i in n:
		draw_texture(tex.sub, Vector2(lx - (n - 1) * 24.0 + i * 48.0 - 19.5, 440))


func _text(text: String, pos: Vector2, size: int, c: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := Vector2(pos.x - w / 2, pos.y)
	draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color(0.02, 0.1, 0.18, 0.8 * c.a))
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.02, 0.12, 0.2, 0.92),
		"border": BRASS,
		"text": Color("e3f6fd"),
		"accent": Color("ffd43b"),
		"button": Color("0b3a55"),
		"button_hover": Color("125a80"),
		"radius": 18,
		"dim": Color(0, 0.05, 0.1, 0.3),
	}
