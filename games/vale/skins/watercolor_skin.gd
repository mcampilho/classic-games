extends ValeSkin
## Aguarela: cada ecrã é pintado como a ilustração de um livro de contos — manchas de aguarela
## sobre papel, árvores e rochas com traço a tinta castanha, água em camadas azuis — e um HUD
## escrito à mão na margem do papel.

const PAPER := Color("f4ecd8")
const INK := Color("4a3426")
const GREEN := [Color("8fbf6a"), Color("6fa858"), Color("a9cf7f"), Color("5e9450")]
const TREE := [Color("3f7f4a"), Color("5a9a52"), Color("2e6a40")]
const OCHRE := Color("d8b878")
const WATER := [Color("5f9fd0"), Color("86bce0"), Color("3f7fb8")]
const ROCK := [Color("9a96a8"), Color("b8b2c2"), Color("787488")]
const SEPIA := [Color("b89a78"), Color("a08060"), Color("cdb594")]
const RED := Color("c8464a")

var paper: Texture2D
var font: Font


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	font = ThemeDB.fallback_font
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.frequency = 0.08
	for y in 128:
		for x in 128:
			var n := noise.get_noise_2d(x, y) * 0.5 + 0.5
			var r := randf() * 0.04
			img.set_pixel(x, y, Color(0, 0, 0, n * 0.06 + r))
	paper = ImageTexture.create_from_image(img)
	build_sprites({"H": Color("7a5232"), "S": Color("f2c8a0"), "E": INK, "R": RED, "B": Color("4f7fbf"), "Y": Color("e0b040"), "L": Color("4a4a72"), "K": INK},
		{"slime": {"G": Color("8fd0c8"), "g": Color("5fa8a0"), "E": INK},
		"bat": {"W": Color("8a6aa8"), "A": Color("5a4278"), "E": Color("f0d060")},
		"goblin": {"A": Color("c8b060"), "G": Color("9ab860"), "E": RED, "C": Color("9a6a42"), "K": INK},
		"knight": {"M": Color("b8b4c4"), "V": INK, "I": RED},
		"coin": {"Y": Color("e0b040"), "y": Color("fff0c0")},
		"heart": {"R": RED, "W": Color("fff0e8")},
		"crystal": {"C": Color("8fd8f0"), "c": Color("ffffff")}}, Color(INK, 0.85))


func _build_sfx() -> void:
	# instrumentos suaves: flauta (seno) e harpa (triângulo com decaimento)
	sfx.step = Synth.tone(0.0, 0.03, {"wave": "noise", "volume": 0.04, "lowpass": 0.15, "decay": 60.0})
	sfx.swing = Synth.tone(0.0, 0.14, {"wave": "noise", "volume": 0.14, "lowpass": 0.35, "decay": 15.0})
	sfx.hit = Synth.tone(330.0, 0.12, {"wave": "triangle", "freq_end": 220.0, "volume": 0.2, "decay": 12.0})
	sfx.kill = Synth.concat([Synth.render(659.0, 0.08, {"wave": "triangle", "volume": 0.2, "decay": 10.0}), Synth.render(988.0, 0.16, {"wave": "triangle", "volume": 0.18, "decay": 8.0})])
	sfx.boss_die = Synth.to_stream(Synth.mix([
		Synth.render(110.0, 2.0, {"wave": "triangle", "freq_end": 40.0, "volume": 0.3}),
		Synth.render(0.0, 2.0, {"wave": "noise", "volume": 0.2, "lowpass": 0.1, "decay": 1.5}),
	]))
	sfx.bush = Synth.tone(0.0, 0.12, {"wave": "noise", "volume": 0.12, "lowpass": 0.3, "decay": 20.0})
	sfx.coin = Synth.concat([Synth.render(1318.0, 0.06, {"wave": "sine", "volume": 0.15, "decay": 10.0}), Synth.render(1760.0, 0.14, {"wave": "sine", "volume": 0.15, "decay": 8.0})])
	sfx.heart = Synth.concat([Synth.render(880.0, 0.08, {"wave": "sine", "volume": 0.15}), Synth.render(1175.0, 0.16, {"wave": "sine", "volume": 0.15, "decay": 6.0})])
	var c := []
	for f in [523.0, 659.0, 784.0, 1046.0, 1318.0]:
		c.append(Synth.render(f, 0.12, {"wave": "triangle", "volume": 0.2, "decay": 6.0}))
	sfx.container = Synth.concat(c)
	sfx.key = sfx.container
	sfx.unlock = Synth.tone(196.0, 0.4, {"wave": "triangle", "freq_end": 98.0, "volume": 0.2, "decay": 4.0})
	sfx.hurt = Synth.tone(220.0, 0.25, {"wave": "triangle", "freq_end": 110.0, "volume": 0.22})
	sfx.shoot = Synth.tone(0.0, 0.1, {"wave": "noise", "volume": 0.1, "lowpass": 0.5, "decay": 20.0})
	var s := []
	for f in [784.0, 988.0, 1175.0, 1568.0, 1976.0]:
		s.append(Synth.render(f, 0.12, {"wave": "sine", "volume": 0.14, "decay": 5.0}))
	sfx.secret = Synth.concat(s)
	sfx.door = Synth.tone(0.0, 0.05, {"wave": "noise", "volume": 0.04, "lowpass": 0.15})
	var d := []
	for f in [523.0, 494.0, 440.0, 392.0, 349.0]:
		d.append(Synth.render(f, 0.25, {"wave": "triangle", "volume": 0.2, "decay": 3.0}))
	sfx.die = Synth.concat(d)
	var w := []
	for f in [392.0, 523.0, 659.0, 784.0, 659.0, 784.0, 1046.0]:
		w.append(Synth.render(f, 0.22, {"wave": "sine", "volume": 0.2, "decay": 3.0}))
	sfx.win = Synth.concat(w)
	sfx.crystal = sfx.win


func sword_color() -> Color:
	return Color("dce6f0")


func hilt_color() -> Color:
	return Color("a07830")


func boss_color() -> Color:
	return Color("9a96a8")


func bush_color() -> Color:
	return GREEN[1]


func _draw_back() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), PAPER)
	draw_texture_rect(paper, Rect2(0, 0, 1280, 720), true)


## Mancha de aguarela: vários círculos sobrepostos com transparência e bordo mais escuro.
func _wash(ci: CanvasItem, c: Vector2, r: float, col: Color, rng: RandomNumberGenerator, a := 0.35) -> void:
	for i in 3:
		var o := Vector2(rng.randf_range(-r, r), rng.randf_range(-r, r)) * 0.25
		ci.draw_circle(c + o, r * rng.randf_range(0.75, 1.0), Color(col, a * 0.6))
	if a > 0.4:
		ci.draw_arc(c, r * 0.95, 0, TAU, 20, Color(col.darkened(0.2), a * 0.3), 1.5)


func _ink_arc(ci: CanvasItem, c: Vector2, r: float, rng: RandomNumberGenerator) -> void:
	var a0 := rng.randf() * TAU
	ci.draw_arc(c, r, a0, a0 + rng.randf_range(2.5, 4.5), 16, Color(INK, 0.75), 2.0)


func _paint_room(ci: CanvasItem, tl: Array[String], dungeon: bool) -> void:
	var rng := RandomNumberGenerator.new()
	ci.draw_rect(Rect2(Vector2.ZERO, FIELD), PAPER)
	ci.draw_texture_rect(paper, Rect2(Vector2.ZERO, FIELD), true)
	# fundo
	ci.draw_rect(Rect2(Vector2.ZERO, FIELD), Color(Color("e8dcc4") if dungeon else GREEN[2], 0.35))
	for y in tl.size():
		var row: String = tl[y]
		for x in row.length():
			var ch := row[x]
			var c := (Vector2(x, y) + Vector2(0.5, 0.5)) * T
			rng.seed = hash(Vector3i(x, y, ch.unicode_at(0)))
			if dungeon:
				if ch == "S" or ch == "L":
					_wash(ci, c, 40.0, SEPIA[rng.randi() % 3], rng, 0.55)
				else:
					_wash(ci, c, 38.0, Color("e8dcc4"), rng, 0.5)
			elif ch == "W":
				ci.draw_rect(Rect2(c - Vector2(32, 32), Vector2(64, 64)), Color(WATER[0], 0.55))
				_wash(ci, c, 40.0, WATER[rng.randi() % 3], rng, 0.35)
			elif ch == "," or ch == "D":
				ci.draw_rect(Rect2(c - Vector2(32, 32), Vector2(64, 64)), Color(OCHRE, 0.35))
				_wash(ci, c, 36.0, OCHRE, rng, 0.25)
			elif rng.randf() < 0.35:
				_wash(ci, c + Vector2(rng.randf_range(-20, 20), rng.randf_range(-20, 20)), 56.0, GREEN[rng.randi() % 4], rng, 0.18)
	# objetos
	for y in tl.size():
		var row: String = tl[y]
		for x in row.length():
			var ch := row[x]
			var c := (Vector2(x, y) + Vector2(0.5, 0.5)) * T
			rng.seed = hash(Vector3i(x, y, 7))
			match ch:
				"T":
					ci.draw_circle(c + Vector2(6, 22), 22, Color(INK, 0.12))
					ci.draw_rect(Rect2(c + Vector2(-5, 8), Vector2(10, 22)), Color("7a5232"))
					for k in 4:
						var o := Vector2(rng.randf_range(-12, 12), rng.randf_range(-16, 4))
						ci.draw_circle(c + o, rng.randf_range(16, 24), Color(TREE[k % 3], 0.55))
					_ink_arc(ci, c + Vector2(0, -6), 27.0, rng)
					_ink_arc(ci, c + Vector2(-6, -10), 18.0, rng)
				"R":
					ci.draw_circle(c + Vector2(6, 10), 24, Color(INK, 0.12))
					ci.draw_circle(c, 26, Color(ROCK[0], 0.85))
					ci.draw_circle(c + Vector2(-8, -8), 12, Color(ROCK[1], 0.7))
					ci.draw_circle(c + Vector2(8, 10), 12, Color(ROCK[2], 0.5))
					_ink_arc(ci, c, 27.0, rng)
				"B":
					for k in 3:
						ci.draw_circle(c + Vector2(rng.randf_range(-8, 8), rng.randf_range(-6, 6)), rng.randf_range(14, 20), Color(GREEN[k % 4].darkened(0.15), 0.6))
					_ink_arc(ci, c, 22.0, rng)
				"F":
					for k in 4:
						ci.draw_circle(c + Vector2(rng.randf_range(-22, 22), rng.randf_range(-22, 22)), 5, Color([Color("e888b0"), Color("f0d060"), Color("ffffff")][k % 3], 0.85))
				"W":
					for k in 2:
						var p := c + Vector2(rng.randf_range(-20, 10), rng.randf_range(-20, 20))
						ci.draw_arc(p, 14, PI * 1.15, PI * 1.85, 8, Color(Color.WHITE, 0.6), 2.0)
				"D":
					ci.draw_circle(c + Vector2(0, 10), 30, Color(INK, 0.85))
					_ink_arc(ci, c + Vector2(0, 10), 32.0, rng)
				"S":
					var r := Rect2(c - Vector2(28, 20), Vector2(56, 40))
					ci.draw_rect(r, Color(SEPIA[1], 0.35))
					ci.draw_rect(r, Color(INK, 0.4), false, 2.0)
				"L":
					var r := Rect2(c - Vector2(30, 30), Vector2(60, 60))
					ci.draw_rect(r, Color("8a5a32", 0.85))
					for k in 3:
						ci.draw_line(r.position + Vector2(15 + k * 15, 4), r.position + Vector2(15 + k * 15, 56), Color(INK, 0.6), 2.0)
					ci.draw_circle(c, 6, INK)
				"X":
					var r := Rect2(c - Vector2(26, 26), Vector2(52, 52))
					ci.draw_rect(r, Color(ROCK[0], 0.8))
					ci.draw_rect(r, Color(INK, 0.7), false, 2.0)
					ci.draw_line(r.position + Vector2(6, 6), r.end - Vector2(6, 6), Color(INK, 0.3), 1.5)
				"f":
					ci.draw_rect(Rect2(c - Vector2(32, 32), Vector2(64, 64)), Color(INK, 0.08), false, 1.0)


func _draw_dynamic_tiles(off: Vector2) -> void:
	for y in game.tiles.size():
		var row: String = game.tiles[y]
		for x in row.length():
			if row[x] == "W":
				var c := ORIGIN + off + (Vector2(x, y) + Vector2(0.5, 0.5)) * T
				var a := time * 1.5 + x * 0.7 + y
				draw_arc(c + Vector2(sin(a) * 10, 6), 10, PI * 1.2, PI * 1.8, 6, Color(1, 1, 1, 0.35), 2.0)


func _draw_frame() -> void:
	var col := PAPER
	draw_rect(Rect2(0, 0, ORIGIN.x, 720), col)
	draw_rect(Rect2(ORIGIN.x + FIELD.x, 0, 1280 - ORIGIN.x - FIELD.x, 720), col)
	draw_rect(Rect2(0, 0, 1280, ORIGIN.y), col)
	draw_texture_rect(paper, Rect2(0, 0, ORIGIN.x, 720), true)
	draw_texture_rect(paper, Rect2(ORIGIN.x + FIELD.x, 0, 1280 - ORIGIN.x - FIELD.x, 720), true)
	draw_texture_rect(paper, Rect2(0, 0, 1280, ORIGIN.y), true)
	# moldura de traço à mão
	var r := Rect2(ORIGIN, FIELD).grow(4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var pts := PackedVector2Array()
	for i in 41:
		var t := i / 40.0
		pts.append(r.position + Vector2(r.size.x * t, rng.randf_range(-2, 2)))
	draw_polyline(pts, Color(INK, 0.8), 2.5)
	pts.clear()
	for i in 41:
		var t := i / 40.0
		pts.append(Vector2(r.position.x + r.size.x * t, r.end.y + rng.randf_range(-2, 2)))
	draw_polyline(pts, Color(INK, 0.8), 2.5)
	draw_line(r.position, Vector2(r.position.x, r.end.y), Color(INK, 0.8), 2.5)
	draw_line(Vector2(r.end.x, r.position.y), r.end, Color(INK, 0.8), 2.5)


func label(text: String, p: Vector2, size: int, c: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(font, p, text, align, 300 if align != HORIZONTAL_ALIGNMENT_LEFT else -1, size, c)


func _draw_hud() -> void:
	var g := game
	label(I18n.t("Espada do Vale"), Vector2(132, 32), 26, INK)
	label(I18n.t("a masmorra do guardião") if g.in_dungeon else I18n.t("o vale"), Vector2(132, 62), 18, Color(INK, 0.7))
	draw_hearts(Vector2(470, 22), Color.WHITE, Color(1, 1, 1, 0.25), 30.0)
	draw_texture_rect(tex.coin, Rect2(760, 18, 18, 24), false)
	label("%d" % g.coins, Vector2(786, 40), 22, INK)
	draw_texture_rect(tex.key, Rect2(840, 16, 18, 26), false)
	label("%d" % g.keys, Vector2(866, 40), 22, INK)
	label(I18n.t("%d pontos") % g.score, Vector2(930, 40), 20, INK)
	draw_minimap(Vector2(1160, 100), Vector2(26, 20), Color(GREEN[3], 0.6), Color(INK, 0.15), RED)
	for i in mini(g.lives - 1, 4):
		draw_texture_rect(tex.hero_down0, Rect2(1166 + i * 26, 190, 24, 28), false)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(PAPER, 0.97),
		"border": INK,
		"text": INK,
		"accent": RED,
		"button": Color("ebe0c8"),
		"button_hover": Color("e0d0b0"),
		"radius": 10,
		"dim": Color(INK, 0.2),
	}
