extends "res://games/vale/skins/classic_skin.gd"
## Consola Portátil: os mesmos desenhos em apenas 4 tons de verde, com a grelha de píxeis do ecrã
## de cristal líquido e a moldura cinzenta das consolas portáteis de 1989.

const C0 := Color("0f380f")
const C1 := Color("306230")
const C2 := Color("8bac0f")
const C3 := Color("9bbc0f")

var lcd: Texture2D


func _setup() -> void:
	P = {
		"grass": C3, "grass2": C2, "path": C3, "path2": C2,
		"tree": C1, "tree2": C2, "tree3": C0, "trunk": C0,
		"rock": C2, "rock2": C3, "rock3": C1, "ink": C0,
		"water": C1, "water2": C2, "bush": C1, "bush2": C2,
		"flower": C1, "flower2": C0, "cave": C0,
		"wall": C1, "wall2": C0, "floor": C2, "floor2": C1,
		"door": C1, "door2": C0, "block": C2, "block2": C3, "block3": C0,
		"hud": Color("c4c0b8"), "hud_text": C0, "accent": C0,
	}
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_make_tiles()
	build_sprites({"H": C0, "S": C3, "E": C0, "R": C1, "B": C1, "Y": C2, "L": C0, "K": C0},
		{"slime": {"G": C2, "g": C1, "E": C0},
		"bat": {"W": C1, "A": C0, "E": C3},
		"goblin": {"A": C2, "G": C1, "E": C3, "C": C0, "K": C0},
		"knight": {"M": C2, "V": C0, "I": C1},
		"coin": {"Y": C2, "y": C3},
		"heart": {"R": C0, "W": C2},
		"crystal": {"C": C2, "c": C3}}, C0)
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(0, 3, 4, 1), Color(C0, 0.12))
	img.fill_rect(Rect2i(3, 0, 1, 4), Color(C0, 0.12))
	lcd = ImageTexture.create_from_image(img)


func sword_color() -> Color:
	return C3


func hilt_color() -> Color:
	return C0


func boss_color() -> Color:
	return C1


func bush_color() -> Color:
	return C1


func _draw_back() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("c4c0b8"))


func _draw_shot(s: Dictionary) -> void:
	var c := px(s.pos) + scroll_offset()
	draw_circle(c, 10, C0)
	draw_circle(c, 5, C3)


func _draw_frame() -> void:
	draw_texture_rect(lcd, Rect2(ORIGIN, FIELD), true)
	var body := Color("c4c0b8")
	draw_rect(Rect2(0, 0, ORIGIN.x, 720), body)
	draw_rect(Rect2(ORIGIN.x + FIELD.x, 0, 1280 - ORIGIN.x - FIELD.x, 720), body)
	draw_rect(Rect2(0, 0, 1280, ORIGIN.y), body)
	draw_rect(Rect2(ORIGIN - Vector2(6, 6), FIELD + Vector2(12, 12)), Color("5a5a6a"), false, 6.0)
	# botões decorativos
	draw_circle(Vector2(1215, 300), 22, Color("8a2a5a"))
	draw_circle(Vector2(1240, 250), 22, Color("8a2a5a"))
	draw_rect(Rect2(30, 290, 60, 20), Color("2a2a32"))
	draw_rect(Rect2(50, 270, 20, 60), Color("2a2a32"))


func _draw_hud() -> void:
	var g := game
	draw_minimap(Vector2(150, 12), Vector2(22, 18), C1, Color(C1, 0.35), C0)
	draw_texture_rect(tex.coin, Rect2(300, 14, 18, 24), false)
	PixelFont.draw(self, "X%d" % g.coins, 350, 18, 3, C0)
	draw_texture_rect(tex.key, Rect2(300, 46, 18, 26), false)
	PixelFont.draw(self, "X%d" % g.keys, 350, 50, 3, C0)
	PixelFont.draw(self, I18n.t("-VIDA-"), 840, 10, 3, C0)
	draw_hearts(Vector2(760, 40), Color.WHITE, Color(1, 1, 1, 0.3), 28.0)
	PixelFont.draw(self, "%06d" % g.score, 560, 18, 3, C0)
	PixelFont.draw(self, I18n.t("MASMORRA") if g.in_dungeon else I18n.t("VALE"), 560, 50, 2, C1)
	for i in mini(g.lives - 1, 4):
		draw_texture_rect(tex.hero_down0, Rect2(1172, 110 + i * 40, 30, 35), false)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(C3, 0.97),
		"border": C0,
		"text": C0,
		"accent": C1,
		"button": C2,
		"button_hover": Color("a8c838"),
		"radius": 4,
		"dim": Color(C0, 0.25),
	}
