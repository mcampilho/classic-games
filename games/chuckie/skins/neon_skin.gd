extends ChuckieSkin
## Neon: a quinta à noite em tubos de luz — plataformas ciano, escadas magenta, galinhas cor-de-rosa
## e ovos que brilham. Tudo com halo.

const BG := Color("05030f")
const CYAN := Color("19f5ff")
const MAGENTA := Color("ff3df2")
const PINK := Color("ff7ab8")
const YELLOW := Color("fff36b")
const LIME := Color("a6ff3d")
const WHITE := Color("ffffff")
const ORANGE := Color("ff9e2c")

func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glow_alpha = 0.9
	build_sprites(
		{"H": YELLOW, "b": MAGENTA, "S": Color("ffd0b0"), "E": BG, "B": MAGENTA, "O": CYAN, "o": Color("0fb5c0"), "K": Color("6a5cff")},
		{"C": Color("ff3b5c"), "W": PINK, "w": Color("d94a9a"), "E": BG, "Y": ORANGE, "T": Color("d94a9a")},
		{"D": LIME, "d": Color("6fd12a"), "E": BG, "Y": ORANGE, "O": ORANGE, "W": Color("e6ffb3")},
		{"E": WHITE, "W": Color("c8f8ff")},
		{"G": YELLOW, "g": ORANGE})
	glow_map.erase(tex.grain)


func make_tex(rows: Array, pal: Dictionary, outline: Color) -> Texture2D:
	var t := PixelArt.outlined(rows, pal, outline, 1)
	glow_map[t] = PixelArt.glow(rows, pal, glow_pad, 3)
	return t


func _build_sfx() -> void:
	sfx.step = Synth.tone(180.0, 0.03, {"wave": "sine", "volume": 0.2, "decay": 60.0})
	sfx.climb = Synth.tone(360.0, 0.03, {"wave": "triangle", "volume": 0.15, "decay": 50.0})
	sfx.jump = Synth.tone(260.0, 0.22, {"wave": "saw", "freq_end": 1040.0, "volume": 0.09, "lowpass": 0.35})
	sfx.land = Synth.tone(90.0, 0.06, {"wave": "sine", "volume": 0.25, "decay": 30.0})
	sfx.egg = Synth.to_stream(Synth.mix([
		Synth.render(1318.0, 0.25, {"wave": "sine", "volume": 0.18, "decay": 10.0}),
		Synth.render(1976.0, 0.25, {"wave": "sine", "volume": 0.1, "decay": 12.0}),
	]))
	sfx.grain = Synth.tone(660.0, 0.2, {"wave": "saw", "freq_end": 1320.0, "volume": 0.08, "lowpass": 0.3})
	sfx.peck = Synth.tone(1100.0, 0.04, {"wave": "sine", "volume": 0.12, "decay": 40.0})
	sfx.die = Synth.to_stream(Synth.mix([
		Synth.render(880.0, 1.3, {"wave": "saw", "freq_end": 55.0, "volume": 0.12, "lowpass": 0.25}),
		Synth.render(0.0, 1.3, {"wave": "noise", "volume": 0.15, "lowpass": 0.1, "decay": 3.0}),
	]))
	var j := []
	for f in [523.0, 659.0, 784.0, 1046.0, 1318.0, 1568.0, 2093.0]:
		j.append(Synth.render(f, 0.08, {"wave": "saw", "volume": 0.09, "lowpass": 0.3}))
	sfx.clear = Synth.concat(j)
	var e := []
	for f in [1046.0, 1318.0, 1568.0, 2093.0]:
		e.append(Synth.render(f, 0.07, {"wave": "sine", "volume": 0.16}))
	sfx.extra = Synth.concat(e)


## Corridas de casas seguidas com chão numa linha: [início, fim].
func floor_runs(r: int) -> Array:
	var out := []
	var c := 0
	while c < ChuckieGame.COLS:
		if game.is_floor(c, r):
			var a := c
			while c < ChuckieGame.COLS and game.is_floor(c, r):
				c += 1
			out.append([a, c - 1])
		else:
			c += 1
	return out


func _draw_static(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1280, 720), BG)
	var f := field_rect()
	# grelha discreta
	for c in ChuckieGame.COLS + 1:
		ci.draw_line(Vector2(f.position.x + c * T * S, f.position.y), Vector2(f.position.x + c * T * S, f.end.y), Color(CYAN, 0.04), 1.0)
	for r in ChuckieGame.ROWS + 1:
		ci.draw_line(Vector2(f.position.x, f.position.y + r * T * S), Vector2(f.end.x, f.position.y + r * T * S), Color(CYAN, 0.04), 1.0)
	ci.draw_rect(f.grow(6), Color(MAGENTA, 0.25), false, 6.0)
	ci.draw_rect(f.grow(4), MAGENTA, false, 2.0)
	# escadas
	for c in ChuckieGame.COLS:
		var r := 0
		while r < ChuckieGame.ROWS:
			if game.is_ladder(c, r):
				var a := r
				while r < ChuckieGame.ROWS and game.is_ladder(c, r):
					r += 1
				var top := tile_rect(c, a).position.y - 6 * S
				var bottom := tile_rect(c, r - 1).end.y
				var x0 := tile_rect(c, a).position.x + 1.5 * S
				var x1 := tile_rect(c, a).position.x + 6.5 * S
				for pass_i in 2:
					var w := 10.0 if pass_i == 0 else 3.0
					var col := Color(MAGENTA, 0.18) if pass_i == 0 else MAGENTA
					ci.draw_line(Vector2(x0, top), Vector2(x0, bottom), col, w)
					ci.draw_line(Vector2(x1, top), Vector2(x1, bottom), col, w)
					var y := top + 3 * S
					while y < bottom:
						ci.draw_line(Vector2(x0, y), Vector2(x1, y), col, w * 0.8)
						y += 4 * S
			else:
				r += 1
	# plataformas
	for r in ChuckieGame.ROWS:
		for run: Array in floor_runs(r):
			var rect := Rect2(tile_rect(run[0], r).position + Vector2(0, 2 * S), Vector2((int(run[1]) - int(run[0]) + 1) * T * S, 4 * S))
			ci.draw_rect(rect.grow(8), Color(CYAN, 0.08))
			ci.draw_rect(rect.grow(4), Color(CYAN, 0.14))
			ci.draw_rect(rect, Color(CYAN, 0.22))
			ci.draw_rect(rect, CYAN, false, 3.0)
			ci.draw_line(rect.position + Vector2(6, rect.size.y / 2), Vector2(rect.end.x - 6, rect.position.y + rect.size.y / 2), Color(WHITE, 0.5), 1.0)


func _draw_lifts() -> void:
	for l in game.lifts:
		var p := px(Vector2(float(l.x) - 8.0, float(l.y)))
		var r := Rect2(p, Vector2(16 * S, 2 * S))
		draw_rect(r.grow(5), Color(WHITE, 0.15))
		draw_rect(r, YELLOW)


func _draw_cage() -> void:
	var r := Rect2(px(Vector2(0, 0)), Vector2(32, 32) * S)
	for i in 9:
		var x := r.position.x + i * r.size.x / 8
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color(LIME, 0.25), 8.0)
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), LIME, 2.0)
	draw_rect(r, LIME, false, 3.0)


func neon_text(text: String, x: float, y: float, cell: float, c: Color) -> void:
	PixelFont.draw(self, text, x + 2, y + 2, cell, Color(c, 0.25))
	PixelFont.draw(self, text, x, y, cell, c)


func _draw_hud() -> void:
	var g := game
	var lx := panel_left_x()
	var rx := panel_right_x()
	var two := g.players.size() > 1
	neon_text(I18n.t("PONTOS") if not two else I18n.t("JOG. 1"), lx, 40, 3, Color(MAGENTA, 1.0 if g.current == 0 else 0.4))
	neon_text("%06d" % g.players[0].score, lx, 76, 4, WHITE)
	if two:
		neon_text(I18n.t("JOG. 2"), lx, 140, 3, Color(MAGENTA, 1.0 if g.current == 1 else 0.4))
		neon_text("%06d" % g.players[1].score, lx, 176, 4, WHITE)
	neon_text(I18n.t("RECORDE"), lx, 260, 3, CYAN)
	neon_text("%06d" % maxi(g.best, g.player().score), lx, 296, 4, WHITE)
	neon_text(I18n.t("VIDAS"), lx, 560, 3, CYAN)
	for i in mini(g.player().lives, 6):
		draw_texture_rect(tex.farmer_stand, Rect2(lx - 84 + i * 28, 600, 24, 48), false)
	neon_text(I18n.t("NIVEL"), rx, 40, 3, CYAN)
	neon_text(str(g.level()), rx, 76, 5, WHITE)
	neon_text(I18n.t("TEMPO"), rx, 160, 3, CYAN)
	var low := g.time_left < 150.0 and fmod(time, 0.4) < 0.2
	neon_text("%03d" % int(g.time_left), rx, 196, 5, MAGENTA if low else WHITE)
	if g.freeze > 0.0:
		neon_text(I18n.t("PARADO"), rx, 250, 2, YELLOW)
	neon_text(I18n.t("OVOS"), rx, 320, 3, CYAN)
	neon_text(str(g.eggs.size()), rx, 356, 5, WHITE)
	for p in popups:
		neon_text(p.text, px(p.pos).x, px(p.pos).y - 20, 2, YELLOW)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.02, 0.01, 0.06, 0.92),
		"border": CYAN,
		"text": Color("e8fbff"),
		"accent": MAGENTA,
		"button": Color(0.05, 0.03, 0.12),
		"button_hover": Color(0.12, 0.06, 0.25),
		"radius": 6,
		"dim": Color(0, 0, 0, 0.35),
	}
