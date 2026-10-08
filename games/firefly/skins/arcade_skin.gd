extends FireflySkin
## Arcade 1980: ecrã negro, sebes do jardim com contorno verde, pontos de luz em píxeis,
## flores a piscar, personagens em pixel art e sons de chip (grilos a cantar ao fundo).

const HEDGE := Color("1f5f2e")
const HEDGE_EDGE := Color("69db7c")
const DOT := Color("fff3bf")
const DOOR_C := Color("f783ac")
const TEXT_C := Color("ffffff")
const LABEL_C := Color("ff6b6b")

var tex := {}


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for f in 2:
		tex["ff%d" % f] = PixelArt.texture(FireflySprites.FIREFLY[f], FireflySprites.FIREFLY_PALETTE, 3)
		for i in 4:
			tex["bat%d%d" % [i, f]] = PixelArt.texture(FireflySprites.BAT[f], {"B": FireflySprites.BAT_COLORS[i], "E": Color.WHITE}, 3)
		tex["scared%d" % f] = PixelArt.texture(FireflySprites.BAT[f], {"B": Color("dee2e6"), "E": Color("c2255c")}, 3)
		tex["scared_flash%d" % f] = PixelArt.texture(FireflySprites.BAT[f], {"B": Color("ffc9c9"), "E": Color("1971c2")}, 3)
	tex.flower = PixelArt.texture(FireflySprites.FLOWER, FireflySprites.FLOWER_PALETTE, 3)
	for k in FireflySprites.BONUS.size():
		tex["bonus%d" % k] = PixelArt.texture(FireflySprites.BONUS[k], FireflySprites.BONUS_PALETTES[k], 3)


func _build_sfx() -> void:
	# grilos: trios de chilreios agudos
	var cricket := []
	for i in 3:
		cricket.append(Synth.render(4200.0, 0.025, {"wave": "sine", "volume": 0.05}))
		cricket.append(Synth.silence(0.03))
	cricket.append(Synth.silence(0.45))
	sfx.ambient = Synth.concat(cricket)
	var warble := []
	for i in 4:
		warble.append(Synth.render(330.0, 0.07, {"wave": "square", "freq_end": 440.0, "volume": 0.06, "lowpass": 0.4, "attack": 0.0, "release": 0.0}))
		warble.append(Synth.render(440.0, 0.07, {"wave": "square", "freq_end": 330.0, "volume": 0.06, "lowpass": 0.4, "attack": 0.0, "release": 0.0}))
	sfx.power_loop = Synth.concat(warble)
	var scale := [1046.5, 1174.7, 1318.5, 1568.0, 1760.0]
	for i in 5:
		sfx["eat%d" % i] = Synth.tone(scale[i], 0.045, {"wave": "square", "volume": 0.07, "lowpass": 0.5, "decay": 40.0})
	var up := []
	for f in [523.25, 659.25, 783.99, 1046.5]:
		up.append(Synth.render(f, 0.06, {"wave": "square", "volume": 0.12, "lowpass": 0.4}))
	sfx.power = Synth.concat(up)
	sfx.bat_eaten = Synth.tone(300.0, 0.35, {"wave": "square", "freq_end": 1600.0, "volume": 0.12, "lowpass": 0.4})
	var chime := []
	for f in [1568.0, 2093.0, 2637.0]:
		chime.append(Synth.render(f, 0.07, {"wave": "triangle", "volume": 0.2}))
	sfx.bonus = Synth.concat(chime)
	var down := []
	for f in [988.0, 880.0, 784.0, 698.5, 587.3, 523.3, 440.0, 392.0]:
		down.append(Synth.render(f, 0.13, {"wave": "square", "volume": 0.12, "lowpass": 0.4, "decay": 6.0}))
	sfx.death = Synth.concat(down)
	var beeps := []
	for i in 6:
		beeps.append(Synth.render(2093.0, 0.05, {"wave": "square", "volume": 0.1}))
		beeps.append(Synth.silence(0.04))
	sfx.extra = Synth.concat(beeps)
	var fan := []
	for f in [523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5]:
		fan.append(Synth.render(f, 0.1, {"wave": "square", "volume": 0.12, "lowpass": 0.35}))
	sfx.clear = Synth.concat(fan)


func _draw() -> void:
	var g := game
	draw_rect(Rect2(0, 0, 1280, 720), Color.BLACK)
	var flashing := g.state == FireflyGame.State.CLEARED and fmod(g.timer, 0.5) < 0.25
	# sebes
	for y in FireflyGame.H:
		for x in FireflyGame.W:
			var t := Vector2i(x, y)
			if FireflyGame.is_wall(t):
				draw_rect(tile_rect(t), Color.WHITE if flashing else HEDGE)
	for e in wall_edges:
		draw_line(e[0], e[1], HEDGE_EDGE, 2.0)
	draw_rect(Rect2(tile_rect(FireflyGame.DOOR).position + Vector2(0, T / 2 - 2), Vector2(T, 4)), DOOR_C)
	# pontos e flores
	for y in FireflyGame.H:
		for x in FireflyGame.W:
			var p := pellet_at(x, y)
			if p == 1:
				draw_rect(Rect2(px(Vector2(x, y)) - Vector2(3, 3), Vector2(6, 6)), DOT)
			elif p == 2 and fmod(time, 0.4) < 0.25:
				draw_texture(tex.flower, px(Vector2(x, y)) - tex.flower.get_size() / 2)
	if g.bonus != null:
		var bt: Texture2D = tex["bonus%d" % g.bonus.kind]
		draw_texture(bt, px(Vector2(FireflyGame.BONUS_TILE)) - bt.get_size() / 2)
	# morcegos
	var fr := int(time * 8.0) % 2
	for b in g.bats:
		if not bat_visible(b):
			continue
		var c := px(b.pos)
		if b.state == FireflyGame.Bat.EATEN:
			for k in 3:
				draw_circle(c + Vector2.from_angle(time * 6.0 + k * TAU / 3) * 5.0, 4.0, Color(0.85, 0.85, 0.85, 0.8))
			continue
		var t: Texture2D
		if b.fright:
			t = tex[("scared_flash%d" if fright_flash() else "scared%d") % fr]
		else:
			t = tex["bat%d%d" % [b.id, fr]]
		draw_texture(t, c - t.get_size() / 2)
	# pirilampo
	if player_visible():
		_draw_firefly()
	for p in popups:
		PixelFont.draw(self, p.text, p.pos.x, p.pos.y - 10, 2, Color("74c0fc"))
	_draw_panels()


func _draw_firefly() -> void:
	var g := game
	var c := px(g.player_pos)
	if g.state == FireflyGame.State.DYING:
		# a luz vai-se apagando
		var k := clampf(g.timer / 2.0, 0.0, 1.0)
		draw_circle(c, 13.0 * k, Color(DOT, k))
		for i in 8:
			var a := i * TAU / 8 + (1.0 - k) * 2.0
			draw_rect(Rect2(c + Vector2.from_angle(a) * (18.0 * (1.0 - k) + 6.0) - Vector2(2, 2), Vector2(4, 4)), Color(DOT, k))
		return
	var ft := face_transform()
	var moving := g.player_dir != Vector2i.ZERO and g.state == FireflyGame.State.PLAY
	var t: Texture2D = tex["ff%d" % (int(time * 12.0) % 2 if moving else 0)]
	draw_set_transform(c, ft[0], ft[1])
	draw_texture(t, -t.get_size() / 2)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_panels() -> void:
	var g := game
	var lx := 117.0
	var rx := 1162.0
	PixelFont.draw(self, I18n.t("PONTOS<1>"), lx, 90, 3, Color(LABEL_C, 1.0 if (g.current == 0 or g.players.size() == 1) else 0.4))
	PixelFont.draw(self, "%06d" % g.players[0].score, lx, 128, 3, TEXT_C)
	PixelFont.draw(self, I18n.t("RECORDE"), lx, 200, 3, LABEL_C)
	PixelFont.draw(self, "%06d" % maxi(g.best, g.player().score), lx, 238, 3, TEXT_C)
	if g.players.size() > 1:
		PixelFont.draw(self, I18n.t("PONTOS<2>"), rx, 90, 3, Color(LABEL_C, 1.0 if g.current == 1 else 0.4))
		PixelFont.draw(self, "%06d" % g.players[1].score, rx, 128, 3, TEXT_C)
	PixelFont.draw(self, I18n.t("NIVEL %d") % g.level(), rx, 200, 3, LABEL_C)
	# vidas (pirilampos de reserva) e bónus dos níveis já jogados
	for i in mini(maxi(g.player().lives - 1, 0), 5):
		draw_texture(tex.ff0, Vector2(lx - 90 + i * 40, 620))
	var n := mini(g.level(), FireflySprites.BONUS.size())
	for k in n:
		draw_texture(tex["bonus%d" % k], Vector2(rx - 70 + (k % 4) * 36, 600 + (k / 4) * 40))


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0, 0, 0, 0.92),
		"border": HEDGE_EDGE,
		"text": TEXT_C,
		"accent": Color("fff3a0"),
		"button": Color.BLACK,
		"button_hover": Color(1, 1, 1, 0.14),
		"radius": 0,
		"dim": Color(0, 0, 0, 0.45),
	}
