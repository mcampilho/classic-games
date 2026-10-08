extends ChuckieSkin
## Clássico 1983: a paleta de 8 cores dos micros de 8 bits (fundo preto, cores puras e brilhantes),
## tijolos verdes, escadas magenta e os "bips" do altifalante interno.

const BLACK := Color("000000")
const GREEN := Color("00d700")
const BGREEN := Color("00ff00")
const MAGENTA := Color("ff00ff")
const YELLOW := Color("ffff00")
const CYAN := Color("00ffff")
const WHITE := Color("ffffff")
const RED := Color("ff0000")
const BLUE := Color("0000d7")
const BRICK := [
	"GGGGGGGm",
	"gGGGGGGm",
	"ggggggmm",
	"mmmmmmmm",
	"GGGmGGGG",
	"gGGmgGGG",
	"ggmmgggg",
	"mmmmmmmm",
]
const LADDER := [
	".L....L.",
	".LLLLLL.",
	".L....L.",
	".L....L.",
	".L....L.",
	".LLLLLL.",
	".L....L.",
	".L....L.",
]


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	static_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	build_sprites(
		{"H": YELLOW, "b": RED, "S": Color("ffd7a8"), "E": BLACK, "B": RED, "O": Color("4060ff"), "o": BLUE, "K": Color("a05000")},
		{"C": RED, "W": YELLOW, "w": Color("d7d700"), "E": BLACK, "Y": Color("ff8000"), "T": Color("d7d700")},
		{"D": CYAN, "d": Color("00d7d7"), "E": BLACK, "Y": YELLOW, "O": Color("ff8000"), "W": WHITE},
		{"E": WHITE, "W": Color("d7d7d7")},
		{"G": YELLOW, "g": Color("d7d700")})
	tex.brick = PixelArt.texture(BRICK, {"G": GREEN, "g": Color("00a000"), "m": BLACK}, 1)
	tex.ladder = PixelArt.texture(LADDER, {"L": MAGENTA}, 1)


func _build_sfx() -> void:
	sfx.step = Synth.tone(220.0, 0.02, {"wave": "square", "volume": 0.12})
	sfx.climb = Synth.tone(330.0, 0.02, {"wave": "square", "volume": 0.1})
	sfx.jump = Synth.tone(300.0, 0.18, {"wave": "square", "freq_end": 900.0, "volume": 0.12})
	sfx.land = Synth.tone(110.0, 0.03, {"wave": "square", "volume": 0.12})
	sfx.egg = Synth.tone(1200.0, 0.08, {"wave": "square", "freq_end": 1800.0, "volume": 0.12})
	sfx.grain = Synth.tone(600.0, 0.1, {"wave": "square", "freq_end": 1200.0, "volume": 0.1})
	sfx.peck = Synth.tone(900.0, 0.03, {"wave": "square", "volume": 0.08})
	sfx.die = Synth.tone(800.0, 1.2, {"wave": "square", "freq_end": 60.0, "volume": 0.14})
	var j := []
	for f in [523.0, 659.0, 784.0, 1046.0, 784.0, 1046.0, 1318.0]:
		j.append(Synth.render(f, 0.09, {"wave": "square", "volume": 0.12}))
	sfx.clear = Synth.concat(j)
	var e := []
	for i in 6:
		e.append(Synth.render(1568.0, 0.05, {"wave": "square", "volume": 0.1}))
		e.append(Synth.silence(0.04))
	sfx.extra = Synth.concat(e)


func _draw_static(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1280, 720), BLACK)
	for r in ChuckieGame.ROWS:
		for c in ChuckieGame.COLS:
			var rect := tile_rect(c, r)
			if game.is_floor(c, r):
				ci.draw_texture_rect(tex.brick, rect, false)
			if game.is_ladder(c, r):
				ci.draw_texture_rect(tex.ladder, rect, false)
				# as calhas da escada passam um pouco acima da plataforma
				if not game.is_ladder(c, r - 1) and game.is_floor(c, r):
					ci.draw_rect(Rect2(rect.position + Vector2(1 * S, -6 * S), Vector2(S, 6 * S)), MAGENTA)
					ci.draw_rect(Rect2(rect.position + Vector2(6 * S, -6 * S), Vector2(S, 6 * S)), MAGENTA)
					ci.draw_rect(Rect2(rect.position + Vector2(1 * S, -3 * S), Vector2(6 * S, S)), MAGENTA)
	# moldura do campo
	ci.draw_rect(field_rect().grow(4), BLUE, false, 4.0)


func cage_color() -> Color:
	return BGREEN


func lift_color() -> Color:
	return CYAN


func _draw_hud() -> void:
	var g := game
	var lx := panel_left_x()
	var rx := panel_right_x()
	var two := g.players.size() > 1
	PixelFont.draw(self, I18n.t("PONTOS") if not two else I18n.t("JOG. 1"), lx, 40, 3, Color(YELLOW, 1.0 if g.current == 0 else 0.4))
	PixelFont.draw(self, "%06d" % g.players[0].score, lx, 76, 4, WHITE)
	if two:
		PixelFont.draw(self, I18n.t("JOG. 2"), lx, 140, 3, Color(YELLOW, 1.0 if g.current == 1 else 0.4))
		PixelFont.draw(self, "%06d" % g.players[1].score, lx, 176, 4, WHITE)
	PixelFont.draw(self, I18n.t("RECORDE"), lx, 260, 3, CYAN)
	PixelFont.draw(self, "%06d" % maxi(g.best, g.player().score), lx, 296, 4, WHITE)
	PixelFont.draw(self, I18n.t("VIDAS"), lx, 560, 3, CYAN)
	for i in mini(g.player().lives, 6):
		draw_texture_rect(tex.farmer_stand, Rect2(lx - 84 + i * 28, 600, 24, 48), false)
	PixelFont.draw(self, I18n.t("NIVEL"), rx, 40, 3, CYAN)
	PixelFont.draw(self, str(g.level()), rx, 76, 5, WHITE)
	PixelFont.draw(self, I18n.t("TEMPO"), rx, 160, 3, CYAN)
	var low := g.time_left < 150.0 and fmod(time, 0.4) < 0.2
	PixelFont.draw(self, "%03d" % int(g.time_left), rx, 196, 5, RED if low else WHITE)
	if g.freeze > 0.0:
		PixelFont.draw(self, I18n.t("PARADO"), rx, 250, 2, YELLOW)
	PixelFont.draw(self, I18n.t("OVOS"), rx, 320, 3, CYAN)
	PixelFont.draw(self, str(g.eggs.size()), rx, 356, 5, WHITE)
	for p in popups:
		PixelFont.draw(self, p.text, px(p.pos).x, px(p.pos).y - 20, 2, WHITE)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0, 0, 0, 0.92),
		"border": MAGENTA,
		"text": WHITE,
		"accent": YELLOW,
		"button": Color(0, 0, 0.5),
		"button_hover": Color(0, 0, 0.8),
		"radius": 0,
		"dim": Color(0, 0, 0, 0.4),
	}
