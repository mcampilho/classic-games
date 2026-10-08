extends ValeSkin
## Clássico 1986: casas de 16 x 16 píxeis desenhadas como nas consolas de 8 bits — relva, árvores
## redondas, rochas, água com ondas, masmorra de tijolo — e um HUD preto por cima.

var P := {
	"grass": Color("5cb83c"), "grass2": Color("3f962c"), "path": Color("e8c88a"), "path2": Color("c9a468"),
	"tree": Color("2f8a2f"), "tree2": Color("58b848"), "tree3": Color("1d5e22"), "trunk": Color("7a4a22"),
	"rock": Color("a08c74"), "rock2": Color("c8b496"), "rock3": Color("6e5c48"), "ink": Color("201810"),
	"water": Color("3a78d8"), "water2": Color("8cc0ff"), "bush": Color("3fa34d"), "bush2": Color("7ccf6a"),
	"flower": Color("ff6ea8"), "flower2": Color("fff07a"), "cave": Color("100808"),
	"wall": Color("6a5a8a"), "wall2": Color("4a3e64"), "floor": Color("9a8a6a"), "floor2": Color("847454"),
	"door": Color("8a5a2a"), "door2": Color("5a3a1a"), "block": Color("8a8aa0"), "block2": Color("b4b4c8"), "block3": Color("5a5a70"),
	"hud": Color("000000"), "hud_text": Color("ffffff"), "accent": Color("fcd34d"),
}
var tiles_tex := {}


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_make_tiles()
	build_sprites({"H": Color("7a4a22"), "S": Color("ffc89a"), "E": Color("201810"), "R": Color("e83c3c"), "B": Color("3c6ad8"), "Y": Color("fcd34d"), "L": Color("2a3a7a"), "K": Color("5a3a1a")},
		{"slime": {"G": Color("6ad0e8"), "g": Color("3a98b8"), "E": Color("102030")},
		"bat": {"W": Color("7a3aa8"), "A": Color("4a2070"), "E": Color("ffde3a")},
		"goblin": {"A": Color("c8b040"), "G": Color("8ab83a"), "E": Color("ff3030"), "C": Color("8a4a2a"), "K": Color("3a2a1a")},
		"knight": {"M": Color("b8bcc8"), "V": Color("101018"), "I": Color("c83a3a")},
		"coin": {"Y": Color("fcd34d"), "y": Color("fff6c0")},
		"heart": {"R": Color("e83c3c"), "W": Color("ffffff")},
		"crystal": {"C": Color("7ae0ff"), "c": Color("ffffff")}})


func _make_tiles() -> void:
	for ch: String in [".", ",", "F", "T", "R", "W", "B", "D", "S", "f", "L", "X", "w"]:
		tiles_tex[ch] = ImageTexture.create_from_image(tile_image(ch))


## Desenha uma casa de 16 x 16 com formas simples (círculos, retângulos) e a paleta P.
func tile_image(ch: String) -> Image:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(ch)
	var base_grass := func() -> void:
		img.fill(P.grass)
		for i in 7:
			var x := rng.randi() % 15
			var y := rng.randi() % 15
			img.set_pixel(x, y, P.grass2)
			img.set_pixel(x + 1, y, P.grass2)
			img.set_pixel(x, y + 1, P.grass2)
	match ch:
		".":
			base_grass.call()
		",":
			img.fill(P.path)
			for i in 8:
				img.set_pixel(rng.randi() % 16, rng.randi() % 16, P.path2)
		"F":
			base_grass.call()
			for c: Vector2i in [Vector2i(4, 4), Vector2i(11, 9), Vector2i(5, 12)]:
				for d: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					img.set_pixelv(c + d, P.flower)
				img.set_pixelv(c, P.flower2)
		"T":
			base_grass.call()
			_disc(img, Vector2(8, 7), 7.2, P.tree3)
			_disc(img, Vector2(7.5, 6.5), 6.4, P.tree)
			_disc(img, Vector2(5.5, 4.5), 2.6, P.tree2)
			img.fill_rect(Rect2i(7, 13, 3, 3), P.trunk)
		"R":
			base_grass.call()
			_ellipse(img, Vector2(8, 9), Vector2(7.4, 6.4), P.ink)
			_ellipse(img, Vector2(8, 9), Vector2(6.6, 5.6), P.rock)
			_ellipse(img, Vector2(6, 7), Vector2(3, 2), P.rock2)
			_ellipse(img, Vector2(10, 12), Vector2(3.5, 1.5), P.rock3)
		"W", "w":
			img.fill(P.water)
			var off := 0 if ch == "W" else 4
			for y in [3, 9]:
				for x in 16:
					var yy: int = y + int(round(sin((x + off) * 0.8) * 1.2))
					img.set_pixel(x, clampi(yy, 0, 15), P.water2)
		"B":
			base_grass.call()
			_disc(img, Vector2(8, 9), 6.4, P.ink)
			_disc(img, Vector2(8, 9), 5.6, P.bush)
			for p: Vector2i in [Vector2i(6, 7), Vector2i(10, 8), Vector2i(7, 11), Vector2i(9, 6)]:
				img.set_pixelv(p, P.bush2)
		"D":
			img.fill(P.rock)
			_ellipse(img, Vector2(8, 16), Vector2(7, 12), P.cave)
		"S":
			img.fill(P.wall)
			for y in [0, 5, 10, 15]:
				img.fill_rect(Rect2i(0, y, 16, 1), P.wall2)
			for y in 3:
				var x0 := 4 if y % 2 == 0 else 10
				img.fill_rect(Rect2i(x0, y * 5, 1, 5), P.wall2)
		"f":
			img.fill(P.floor)
			img.fill_rect(Rect2i(0, 0, 16, 1), P.floor2)
			img.fill_rect(Rect2i(0, 0, 1, 16), P.floor2)
		"L":
			img.fill(P.wall2)
			img.fill_rect(Rect2i(1, 1, 14, 15), P.door)
			for x in [5, 10]:
				img.fill_rect(Rect2i(x, 1, 1, 15), P.door2)
			_disc(img, Vector2(8, 7), 2.0, P.ink)
			img.fill_rect(Rect2i(7, 8, 2, 4), P.ink)
		"X":
			img.fill(P.floor)
			img.fill_rect(Rect2i(1, 1, 14, 14), P.block3)
			img.fill_rect(Rect2i(1, 1, 13, 13), P.block2)
			img.fill_rect(Rect2i(3, 3, 10, 10), P.block)
	return img


static func _disc(img: Image, c: Vector2, r: float, col: Color) -> void:
	for y in 16:
		for x in 16:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				img.set_pixel(x, y, col)


static func _ellipse(img: Image, c: Vector2, r: Vector2, col: Color) -> void:
	for y in 16:
		for x in 16:
			var d := (Vector2(x + 0.5, y + 0.5) - c) / r
			if d.length() <= 1.0:
				img.set_pixel(x, y, col)


func _build_sfx() -> void:
	sfx.step = Synth.tone(0.0, 0.02, {"wave": "noise", "volume": 0.05, "lowpass": 0.3, "decay": 80.0})
	sfx.swing = Synth.tone(0.0, 0.12, {"wave": "noise", "volume": 0.18, "lowpass": 0.7, "decay": 20.0})
	sfx.hit = Synth.tone(300.0, 0.08, {"wave": "square", "freq_end": 150.0, "volume": 0.12})
	sfx.kill = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.25, {"wave": "noise", "volume": 0.25, "lowpass": 0.4, "decay": 12.0}),
		Synth.render(600.0, 0.2, {"wave": "square", "freq_end": 100.0, "volume": 0.08}),
	]))
	sfx.boss_die = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 2.0, {"wave": "noise", "volume": 0.35, "lowpass": 0.15, "decay": 1.5}),
		Synth.render(200.0, 2.0, {"wave": "square", "freq_end": 30.0, "volume": 0.1}),
	]))
	sfx.bush = Synth.tone(0.0, 0.1, {"wave": "noise", "volume": 0.15, "lowpass": 0.5, "decay": 25.0})
	sfx.coin = Synth.concat([Synth.render(988.0, 0.05, {"wave": "square", "volume": 0.1}), Synth.render(1318.0, 0.12, {"wave": "square", "volume": 0.1})])
	sfx.heart = Synth.concat([Synth.render(784.0, 0.06, {"wave": "square", "volume": 0.1}), Synth.render(1046.0, 0.1, {"wave": "square", "volume": 0.1})])
	var c := []
	for f in [523.0, 659.0, 784.0, 1046.0]:
		c.append(Synth.render(f, 0.1, {"wave": "square", "volume": 0.12}))
	sfx.container = Synth.concat(c)
	sfx.key = sfx.container
	sfx.unlock = Synth.tone(200.0, 0.3, {"wave": "square", "freq_end": 100.0, "volume": 0.1, "lowpass": 0.4})
	sfx.hurt = Synth.tone(400.0, 0.2, {"wave": "square", "freq_end": 120.0, "volume": 0.12})
	sfx.shoot = Synth.tone(900.0, 0.08, {"wave": "square", "freq_end": 400.0, "volume": 0.06})
	var s := []
	for f in [784.0, 740.0, 622.0, 440.0, 415.0, 659.0, 831.0, 1046.0]:
		s.append(Synth.render(f, 0.1, {"wave": "square", "volume": 0.1}))
	sfx.secret = Synth.concat(s)
	sfx.door = Synth.tone(0.0, 0.05, {"wave": "noise", "volume": 0.05, "lowpass": 0.2})
	sfx.die = Synth.tone(600.0, 1.4, {"wave": "square", "freq_end": 80.0, "volume": 0.1, "lowpass": 0.5})
	var w := []
	for f in [523.0, 523.0, 523.0, 659.0, 587.0, 523.0, 784.0, 1046.0]:
		w.append(Synth.render(f, 0.16, {"wave": "square", "volume": 0.12}))
	sfx.win = Synth.concat(w)
	sfx.crystal = sfx.win


func _paint_room(ci: CanvasItem, tl: Array[String], _dungeon: bool) -> void:
	for y in tl.size():
		var row: String = tl[y]
		for x in row.length():
			var t: Texture2D = tiles_tex.get(row[x], tiles_tex["."])
			ci.draw_texture_rect(t, Rect2(Vector2(x, y) * T, Vector2(T, T)), false)


func _draw_dynamic_tiles(off: Vector2) -> void:
	# a água mexe-se
	if fmod(time, 1.0) < 0.5:
		return
	for y in game.tiles.size():
		var row: String = game.tiles[y]
		for x in row.length():
			if row[x] == "W":
				draw_texture_rect(tiles_tex.w, Rect2(ORIGIN + off + Vector2(x, y) * T, Vector2(T, T)), false)


func _draw_frame() -> void:
	draw_rect(Rect2(0, 0, ORIGIN.x, 720), P.hud)
	draw_rect(Rect2(ORIGIN.x + FIELD.x, 0, 1280 - ORIGIN.x - FIELD.x, 720), P.hud)
	draw_rect(Rect2(0, 0, 1280, ORIGIN.y), P.hud)


func _draw_hud() -> void:
	var g := game
	draw_minimap(Vector2(150, 12), Vector2(22, 18), Color("5a5a5a"), Color("303030"), P.accent)
	draw_texture_rect(tex.coin, Rect2(300, 14, 18, 24), false)
	PixelFont.draw(self, "X%d" % g.coins, 350, 18, 3, P.hud_text)
	draw_texture_rect(tex.key, Rect2(300, 46, 18, 26), false)
	PixelFont.draw(self, "X%d" % g.keys, 350, 50, 3, P.hud_text)
	PixelFont.draw(self, I18n.t("-VIDA-"), 840, 10, 3, Color("e83c3c"))
	draw_hearts(Vector2(760, 40), Color.WHITE, Color(0.3, 0.3, 0.3), 28.0)
	PixelFont.draw(self, "%06d" % g.score, 560, 18, 3, P.hud_text)
	PixelFont.draw(self, I18n.t("MASMORRA") if g.in_dungeon else I18n.t("VALE"), 560, 50, 2, P.accent)
	for i in mini(g.lives - 1, 4):
		draw_texture_rect(tex.hero_down0, Rect2(1172, 110 + i * 40, 30, 35), false)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0, 0, 0, 0.92),
		"border": Color("fcd34d"),
		"text": Color.WHITE,
		"accent": Color("fcd34d"),
		"button": Color(0.12, 0.12, 0.2),
		"button_hover": Color(0.2, 0.2, 0.32),
		"radius": 0,
		"dim": Color(0, 0, 0, 0.35),
	}
