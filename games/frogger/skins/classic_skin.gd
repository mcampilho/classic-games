extends FroggerSkin
## Clássico 1981: rio azul-noite, estrada negra, passeios roxos, sebe verde com 5 tocas,
## veículos e rã em píxeis, barra de tempo e uma melodia de chip (original) em fundo.

const RIVER := Color("00104a")
const ROAD := Color.BLACK
const PURPLE := Color("5a189a")
const HEDGE := Color("2b8a3e")
const BAY := Color("001a5e")
const LOG := Color("8b5a2b")
const LOG_DARK := Color("5c3a1a")
const TURTLE := Color("e03131")
const TEXT_C := Color("ffffff")
const LABEL_C := Color("ffd43b")
const VEHICLE := {
	"car_a": {"body": Color("ffd43b"), "cabin": Color("f08c00"), "window": Color("74c0fc"), "wheel": Color("dee2e6"), "light": Color("fff"), "blade": Color("fff")},
	"dozer": {"body": Color("40c057"), "cabin": Color("ffffff"), "window": Color("74c0fc"), "wheel": Color("adb5bd"), "light": Color("fff"), "blade": Color("ced4da")},
	"car_b": {"body": Color("f783ac"), "cabin": Color("ffffff"), "window": Color("74c0fc"), "wheel": Color("dee2e6"), "light": Color("fff"), "blade": Color("fff")},
	"racer": {"body": Color("ffffff"), "cabin": Color("e03131"), "window": Color("74c0fc"), "wheel": Color("ffd43b"), "light": Color("ffd43b"), "blade": Color("fff")},
	"truck": {"body": Color("f8f9fa"), "cabin": Color("e03131"), "window": Color("74c0fc"), "wheel": Color("adb5bd"), "light": Color("fff"), "blade": Color("fff")},
}

var tex := {}


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var pal := {"G": Color("51cf66"), "g": Color("2f9e44"), "Y": Color("d8f5a2"), "W": Color.WHITE, "K": Color.BLACK}
	for f in 2:
		tex["frog%d" % f] = PixelArt.texture(FROG[f], pal, 3)
	tex.fly = PixelArt.texture(FLY, {"W": Color("a5d8ff"), "K": Color("fab005")}, 3)
	tex.croc = PixelArt.texture(CROC, {"G": Color("2f9e44"), "W": Color.WHITE, "K": Color.BLACK}, 3)


func _build_sfx() -> void:
	sfx.hop = Synth.tone(500.0, 0.06, {"wave": "square", "freq_end": 900.0, "volume": 0.1, "lowpass": 0.5})
	var home := []
	for f in [784.0, 988.0, 1175.0, 1568.0]:
		home.append(Synth.render(f, 0.08, {"wave": "square", "volume": 0.12, "lowpass": 0.4}))
	sfx.home = Synth.concat(home)
	sfx.fly = Synth.tone(1800.0, 0.2, {"wave": "square", "freq_end": 2600.0, "volume": 0.08})
	sfx.squash = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.5, {"wave": "noise", "volume": 0.35, "lowpass": 0.25, "decay": 6.0}),
		Synth.render(300.0, 0.4, {"wave": "square", "freq_end": 60.0, "volume": 0.15, "lowpass": 0.3}),
	]))
	sfx.splash = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.7, {"wave": "noise", "volume": 0.3, "lowpass": 0.5, "decay": 4.0}),
		Synth.render(900.0, 0.5, {"wave": "sine", "freq_end": 200.0, "volume": 0.15, "decay": 5.0}),
	]))
	var warn := []
	for i in 3:
		warn.append(Synth.render(1320.0, 0.08, {"wave": "square", "volume": 0.1}))
		warn.append(Synth.silence(0.08))
	sfx.warn = Synth.concat(warn)
	var beeps := []
	for i in 6:
		beeps.append(Synth.render(2093.0, 0.05, {"wave": "square", "volume": 0.1}))
		beeps.append(Synth.silence(0.04))
	sfx.extra = Synth.concat(beeps)
	var fan := []
	for f in [523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5, 1318.5]:
		fan.append(Synth.render(f, 0.11, {"wave": "square", "volume": 0.12, "lowpass": 0.35}))
	sfx.clear = Synth.concat(fan)
	# melodia original, saltitante, em dó maior
	var tune := [659.3, 784.0, 880.0, 784.0, 659.3, 587.3, 523.3, 587.3, 659.3, 659.3, 784.0, 659.3, 587.3, 523.3, 587.3, 523.3]
	var bass := [130.8, 130.8, 174.6, 174.6, 196.0, 196.0, 130.8, 130.8]
	var melody := PackedFloat32Array()
	for i in tune.size():
		melody.append_array(Synth.mix([
			Synth.render(tune[i], 0.17, {"wave": "square", "volume": 0.08, "lowpass": 0.3, "decay": 5.0}),
			Synth.render(bass[i / 2], 0.17, {"wave": "triangle", "volume": 0.12}),
		]))
	sfx.music = Synth.to_stream(melody)


func _draw() -> void:
	var g := game
	draw_rect(Rect2(0, 0, 1280, 720), Color.BLACK)
	# cenário
	draw_rect(row_rect(0), HEDGE)
	for i in 5:
		draw_rect(bay_rect(i), BAY)
	for r in range(1, 6):
		draw_rect(row_rect(r), RIVER)
	draw_rect(row_rect(6), PURPLE)
	for r in range(7, 12):
		draw_rect(row_rect(r), ROAD)
	draw_rect(row_rect(12), PURPLE)
	for r in [6, 12]:
		var rr := row_rect(r)
		for x in range(0, int(rr.size.x), 24):
			draw_rect(Rect2(rr.position + Vector2(x + 2, 2), Vector2(20, rr.size.y - 4)), PURPLE.lightened(0.15), false, 2.0)
	# objetos
	for o in g.objects:
		if o.kind == "log":
			var r := obj_rect(o)
			draw_rect(r.grow_individual(0, -4, 0, -4), LOG)
			for k in range(1, o.len):
				draw_line(Vector2(r.position.x + k * C * S, r.position.y + 6), Vector2(r.position.x + k * C * S, r.end.y - 6), LOG_DARK, 2.0)
			draw_rect(Rect2(r.end.x - 8, r.position.y + 4, 8, r.size.y - 8), Color("c08a4a"))
		elif o.kind == "turtle":
			for sh in turtle_shells(o):
				if sh[1] > 0.0:
					draw_circle(sh[0], sh[1], TURTLE)
					draw_circle(sh[0], sh[1] * 0.55, TURTLE.darkened(0.35))
					draw_circle(sh[0] + Vector2(-sh[1] - 3, 0), 5.0, Color("40c057"))
		else:
			var pal: Dictionary = VEHICLE[o.kind]
			for part in vehicle_parts(o):
				draw_rect(part[0], pal[part[1]])
	# tocas
	for i in 5:
		var c := bay_rect(i).get_center()
		if g.homes[i]:
			draw_texture(tex.frog0, c - tex.frog0.get_size() / 2)
		elif g.fly_bay == i:
			draw_texture(tex.fly, c - tex.fly.get_size() / 2)
		elif g.croc_bay == i:
			draw_texture(tex.croc, c - tex.croc.get_size() / 2)
	# rã
	if g.state == FroggerGame.State.DYING:
		_draw_death()
	elif g.state != FroggerGame.State.OVER and g.state != FroggerGame.State.CLEARED:
		var t: Texture2D = tex["frog%d" % (1 if g.hop_t >= 0.0 else 0)]
		draw_set_transform(px(g.frog_center()), frog_angle(), Vector2.ONE)
		draw_texture(t, -t.get_size() / 2)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for p in popups:
		PixelFont.draw(self, p.text, p.pos.x, p.pos.y - 8, 2, TEXT_C)
	for r in side_rects():
		draw_rect(r, Color.BLACK)
	_draw_hud()


func _draw_death() -> void:
	var c := px(game.frog_center())
	var k := 1.0 - game.timer / 1.6
	if game.death_cause == "agua":
		for i in 3:
			draw_arc(c, 6.0 + 26.0 * fmod(k + i * 0.33, 1.0), 0, TAU, 24, Color(0.6, 0.8, 1.0, 1.0 - fmod(k + i * 0.33, 1.0)), 2.0)
	else:
		for i in 8:
			var d := Vector2.from_angle(i * TAU / 8) * (8.0 + 10.0 * k)
			draw_rect(Rect2(c + d - Vector2(3, 3), Vector2(6, 6)), Color("ff6b6b") if i % 2 == 0 else Color.WHITE)
		draw_rect(Rect2(c - Vector2(6, 6), Vector2(12, 12)), Color("e03131"))


func _draw_hud() -> void:
	var g := game
	var lx := panel_left_x()
	var rx := panel_right_x()
	PixelFont.draw(self, I18n.t("PONTOS<1>"), lx, 60, 3, Color(LABEL_C, 1.0 if (g.current == 0 or g.players.size() == 1) else 0.4))
	PixelFont.draw(self, "%05d" % g.players[0].score, lx, 100, 4, TEXT_C)
	PixelFont.draw(self, I18n.t("RECORDE"), lx, 180, 3, LABEL_C)
	PixelFont.draw(self, "%05d" % maxi(g.best, g.player().score), lx, 220, 4, TEXT_C)
	if g.players.size() > 1:
		PixelFont.draw(self, I18n.t("PONTOS<2>"), rx, 60, 3, Color(LABEL_C, 1.0 if g.current == 1 else 0.4))
		PixelFont.draw(self, "%05d" % g.players[1].score, rx, 100, 4, TEXT_C)
	PixelFont.draw(self, I18n.t("NIVEL %d") % g.level(), rx, 180, 3, LABEL_C)
	for i in mini(maxi(g.player().lives - 1, 0), 6):
		draw_texture(tex.frog0, Vector2(lx - 110 + (i % 3) * 50, 560 + (i / 3) * 44))
	# barra de tempo na faixa de baixo
	var hud := row_rect(13)
	var frac := clampf(g.time_left / g.time_limit(), 0.0, 1.0)
	var bar_c := Color("51cf66") if g.time_left > 8.0 else Color("ff6b6b")
	draw_rect(Rect2(hud.end.x - 12 - 420 * frac, hud.position.y + 14, 420 * frac, 20), bar_c)
	PixelFont.draw(self, I18n.t("TEMPO"), hud.end.x - 470 - 60, hud.position.y + 14, 3, LABEL_C)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0, 0, 0, 0.92),
		"border": Color("51cf66"),
		"text": TEXT_C,
		"accent": LABEL_C,
		"button": Color.BLACK,
		"button_hover": Color(1, 1, 1, 0.14),
		"radius": 0,
		"dim": Color(0, 0, 0, 0.4),
	}
