extends JetpacSkin
## Clássico 1983: fundo preto, plataformas verdes, chão amarelo, cores puras dos micros de 8 bits
## (o foguete muda de cor a cada modelo) e sons de altifalante.

const GREEN := Color("00d700")
const YELLOW := Color("ffff00")
const WHITE := Color("ffffff")
const MAGENTA := Color("ff00ff")
const CYAN := Color("00ffff")
const ROCKET_COLS := [Color("ffffff"), Color("00ffff"), Color("ffff00"), Color("ff00ff")]


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	build_common({"W": WHITE, "V": CYAN, "P": Color("d7d7d7"), "G": YELLOW},
		{"K": MAGENTA, "P": Color("d700d7"), "W": WHITE},
		[Color("00ffff"), Color("ff0000"), Color("00ff00"), Color("ffff00")])


func _build_sfx() -> void:
	sfx.thrust = Synth.to_stream(Synth.render(0.0, 0.5, {"wave": "noise", "volume": 0.12, "lowpass": 0.15, "attack": 0.0, "release": 0.0}))
	sfx.laser = Synth.tone(2400.0, 0.12, {"wave": "square", "freq_end": 800.0, "volume": 0.08})
	sfx.kill = Synth.tone(0.0, 0.25, {"wave": "noise", "volume": 0.25, "lowpass": 0.4, "decay": 12.0})
	sfx.crash = Synth.tone(0.0, 0.15, {"wave": "noise", "volume": 0.15, "lowpass": 0.3, "decay": 18.0})
	sfx.pick = Synth.tone(880.0, 0.1, {"wave": "square", "freq_end": 1760.0, "volume": 0.1})
	sfx.drop = Synth.tone(1200.0, 0.2, {"wave": "square", "freq_end": 400.0, "volume": 0.08})
	sfx.place = Synth.concat([Synth.render(660.0, 0.06, {"wave": "square", "volume": 0.1}), Synth.render(990.0, 0.1, {"wave": "square", "volume": 0.1})])
	sfx.fuel = Synth.concat([Synth.render(440.0, 0.06, {"wave": "square", "volume": 0.1}), Synth.render(880.0, 0.1, {"wave": "square", "volume": 0.1})])
	sfx.gem = Synth.concat([Synth.render(1568.0, 0.05, {"wave": "square", "volume": 0.1}), Synth.render(2093.0, 0.12, {"wave": "square", "volume": 0.1})])
	sfx.die = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.0, {"wave": "noise", "volume": 0.3, "lowpass": 0.3, "decay": 3.0}),
		Synth.render(1000.0, 0.9, {"wave": "square", "freq_end": 80.0, "volume": 0.08}),
	]))
	sfx.takeoff = Synth.tone(80.0, 2.5, {"wave": "square", "freq_end": 900.0, "volume": 0.07, "lowpass": 0.3})
	var e := []
	for i in 6:
		e.append(Synth.render(1568.0, 0.05, {"wave": "square", "volume": 0.1}))
		e.append(Synth.silence(0.04))
	sfx.extra = Synth.concat(e)


func rocket_palette(model: int) -> Dictionary:
	var c: Color = ROCKET_COLS[model % ROCKET_COLS.size()]
	return {"R": MAGENTA if model % 2 == 0 else Color("ff0000"), "B": c, "b": c.darkened(0.3), "H": c.lightened(0.5), "W": WHITE, "C": Color("0000ff"), "K": Color("ff8000")}


func _draw_platforms() -> void:
	for r: Rect2 in JetpacGame.PLATFORMS:
		var pr := Rect2(px(r.position), r.size * S)
		draw_rect(pr, GREEN)
		draw_rect(Rect2(pr.position, Vector2(pr.size.x, 4)), Color("80ff80"))
		var x := pr.position.x + 4
		while x < pr.end.x - 4:
			draw_rect(Rect2(x, pr.position.y + 10, 4, 4), Color("008000"))
			x += 12
	var g := Rect2(0, JetpacGame.GROUND_Y * S, 1280, 720 - JetpacGame.GROUND_Y * S)
	draw_rect(g, YELLOW)
	draw_rect(Rect2(g.position, Vector2(1280, 4)), Color("ffff99"))


func _draw_hud() -> void:
	var g := game
	PixelFont.draw(self, "1UP", 120, 8, 2, WHITE)
	PixelFont.draw(self, "%06d" % g.score, 120, 28, 3, YELLOW)
	PixelFont.draw(self, "HI", 640, 8, 2, WHITE)
	PixelFont.draw(self, "%06d" % maxi(g.best, g.score), 640, 28, 3, CYAN)
	PixelFont.draw(self, I18n.t("NIVEL %d") % g.level, 1120, 8, 2, WHITE)
	for i in mini(g.lives - 1, 6):
		draw_texture_rect(tex.man_stand, Rect2(1060 + i * 26, 26, 20, 32), false)
	for p in popups:
		PixelFont.draw(self, p.text, px(p.pos).x, px(p.pos).y - 30, 2, WHITE)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0, 0, 0, 0.92),
		"border": GREEN,
		"text": WHITE,
		"accent": YELLOW,
		"button": Color(0, 0.25, 0),
		"button_hover": Color(0, 0.4, 0),
		"radius": 0,
		"dim": Color(0, 0, 0, 0.4),
	}
