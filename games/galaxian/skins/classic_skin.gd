extends GalaxianSkin
## Clássico 1979: fundo negro com um campo de estrelas coloridas a cair e a piscar, naves em píxeis
## multicolores, o míssil pousado na ponta da nave, bandeiras de vaga e o zumbido contínuo da formação.

const WHITE := Color(0.95, 0.95, 0.95)
const MISSILE_C := Color("ffd43b")
const STAR_COLORS := [Color("ff6b6b"), Color("ffd43b"), Color("69db7c"), Color("4dabf7"), Color("da77f2"), Color("f8f9fa")]

var tex := {}


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var f := field_rect()
	make_stars(70, STAR_COLORS, 25.0, 60.0, Vector2(f.position.x, f.end.x))
	for kind in 4:
		for fr in 2:
			tex["a%d%d" % [kind, fr]] = PixelArt.texture(GalaxianSprites.frame(kind, fr), GalaxianSprites.PALETTES[kind])
	tex.player = PixelArt.texture(GalaxianSprites.PLAYER, GalaxianSprites.PLAYER_PALETTE)
	for fr in 2:
		tex["boom%d" % fr] = PixelArt.texture(GalaxianSprites.BOOM[fr], GalaxianSprites.BOOM_PALETTE)


func _build_sfx() -> void:
	var hum := []
	for i in 2:
		hum.append(Synth.render(110.0, 0.14, {"wave": "square", "volume": 0.14, "lowpass": 0.08, "attack": 0.02, "release": 0.02}))
		hum.append(Synth.render(98.0, 0.14, {"wave": "square", "volume": 0.1, "lowpass": 0.08, "attack": 0.02, "release": 0.02}))
	sfx.hum = Synth.concat(hum)
	sfx.dive = Synth.tone(1500.0, 0.9, {"wave": "sine", "freq_end": 450.0, "volume": 0.12})
	sfx.fire = Synth.tone(600.0, 0.13, {"wave": "square", "freq_end": 1700.0, "volume": 0.1, "lowpass": 0.4, "decay": 12.0})
	sfx.kill = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.3, {"wave": "noise", "volume": 0.3, "lowpass": 0.3, "decay": 9.0}),
		Synth.render(700.0, 0.25, {"wave": "square", "freq_end": 120.0, "volume": 0.1, "decay": 9.0}),
	]))
	var flag := [Synth.render(0.0, 0.25, {"wave": "noise", "volume": 0.3, "lowpass": 0.3, "decay": 9.0})]
	for f in [784.0, 988.0, 1175.0, 1568.0]:
		flag.append(Synth.render(f, 0.07, {"wave": "square", "volume": 0.12, "lowpass": 0.5}))
	sfx.flag_kill = Synth.concat(flag)
	sfx.player_hit = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.5, {"wave": "noise", "volume": 0.45, "lowpass": 0.12, "decay": 2.3}),
		Synth.render(400.0, 1.2, {"wave": "square", "freq_end": 50.0, "volume": 0.1, "lowpass": 0.3, "decay": 2.5}),
	]))
	var beeps := []
	for i in 8:
		beeps.append(Synth.render(1760.0, 0.05, {"wave": "square", "volume": 0.1}))
		beeps.append(Synth.silence(0.04))
	sfx.extra = Synth.concat(beeps)


func _draw() -> void:
	var g := game
	draw_rect(Rect2(0, 0, 1280, 720), Color.BLACK)
	for s in stars:
		if fmod(s.phase, 1.6) < 1.1:
			draw_rect(Rect2(s.pos, Vector2(3, 3)), s.color)

	for a in g.aliens:
		if a.alive:
			draw_texture(tex["a%d%d" % [a.kind, g.anim_frame if a.fly == GalaxianGame.Fly.FORM else 1]], px(a.pos))
	for b in booms:
		var t: Texture2D = tex["boom%d" % (0 if b.life > 0.18 else 1)]
		draw_texture(t, px(b.pos) - t.get_size() / 2)
	for p in popups:
		var c := px(p.pos)
		PixelFont.draw(self, p.text, c.x, c.y - 12, 3, Color("4dabf7"))

	var pr := g.player_rect()
	if player_dying():
		var k := int(g.timer * 8.0) % 2
		var t: Texture2D = tex["boom%d" % k]
		draw_texture_rect(t, Rect2(px(pr.get_center()) - t.get_size(), t.get_size() * 2), false)
	elif g.state != GalaxianGame.State.OVER:
		draw_texture(tex.player, px(pr.position))
		if g.missile == null:
			draw_rect(Rect2(px(Vector2(g.player_x - 0.5, GalaxianGame.PLAYER_Y - 4)), Vector2(S, 4 * S)), MISSILE_C)
	if g.missile != null:
		draw_rect(Rect2(px(g.missile - Vector2(0.5, 0)), Vector2(S, 4 * S)), MISSILE_C)
	for b in g.bombs:
		draw_rect(Rect2(px(b.pos - Vector2(0.5, 0)), Vector2(S, 3 * S)), WHITE)
	_draw_panels()


func _draw_panels() -> void:
	var g := game
	var lx := panel_left_x()
	var rx := panel_right_x()
	var c0 := Color("ff6b6b") if (g.current == 0 or g.players.size() == 1) else Color("ff6b6b", 0.4)
	PixelFont.draw(self, I18n.t("PONTOS<1>"), lx, 40, 3, c0)
	PixelFont.draw(self, "%05d" % g.players[0].score, lx, 80, 4, WHITE)
	PixelFont.draw(self, I18n.t("RECORDE"), lx, 150, 3, Color("ff6b6b"))
	PixelFont.draw(self, "%05d" % maxi(g.best, g.player().score), lx, 190, 4, WHITE)
	if g.players.size() > 1:
		PixelFont.draw(self, I18n.t("PONTOS<2>"), rx, 40, 3, Color("ff6b6b", 1.0 if g.current == 1 else 0.4))
		PixelFont.draw(self, "%05d" % g.players[1].score, rx, 80, 4, WHITE)
	# vidas (naves de reserva) e bandeiras das vagas
	for i in mini(maxi(g.player().lives - 1, 0), 5):
		draw_texture(tex.player, Vector2(lx - 100 + i * 46, 650))
	var wave: int = g.player().wave
	for i in mini(wave, 10):
		var p := Vector2(rx - 90 + (i % 5) * 40, 620 + (i / 5) * 46)
		draw_rect(Rect2(p, Vector2(3, 30)), Color("ffd43b"))
		draw_colored_polygon(PackedVector2Array([p + Vector2(3, 0), p + Vector2(24, 7), p + Vector2(3, 14)]), Color("e03131"))


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0, 0, 0, 0.92),
		"border": WHITE,
		"text": WHITE,
		"accent": Color("ffd43b"),
		"button": Color.BLACK,
		"button_hover": Color(1, 1, 1, 0.16),
		"radius": 0,
		"dim": Color(0, 0, 0, 0.4),
	}
