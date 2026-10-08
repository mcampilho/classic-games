extends CentipedeSkin
## Clássico 1981: fundo negro, pixel art e cores que mudam a cada vaga (como na máquina),
## cogumelos envenenados com as cores trocadas e a batida dos passos da centopeia.

const PALETTES := [
	{"cap": Color("e8590c"), "spot": Color("ffe8cc"), "stem": Color("37b24d"), "body": Color("f783ac"), "dark": Color("a61e4d"), "legs": Color("ffd43b")},
	{"cap": Color("4dabf7"), "spot": Color("e7f5ff"), "stem": Color("fab005"), "body": Color("51cf66"), "dark": Color("2b8a3e"), "legs": Color("ff6b6b")},
	{"cap": Color("ffd43b"), "spot": Color("fff9db"), "stem": Color("845ef7"), "body": Color("ff922b"), "dark": Color("d9480f"), "legs": Color("74c0fc")},
	{"cap": Color("51cf66"), "spot": Color("ebfbee"), "stem": Color("ff6b6b"), "body": Color("4dabf7"), "dark": Color("1864ab"), "legs": Color("ffd43b")},
	{"cap": Color("da77f2"), "spot": Color("f8f0fc"), "stem": Color("20c997"), "body": Color("ffd43b"), "dark": Color("e67700"), "legs": Color("ff6b6b")},
	{"cap": Color("ff6b6b"), "spot": Color("fff5f5"), "stem": Color("4dabf7"), "body": Color("94d82d"), "dark": Color("5c940d"), "legs": Color("f783ac")},
	{"cap": Color("20c997"), "spot": Color("e6fcf5"), "stem": Color("f783ac"), "body": Color("ff922b"), "dark": Color("d9480f"), "legs": Color("4dabf7")},
	{"cap": Color("ffa94d"), "spot": Color("fff4e6"), "stem": Color("748ffc"), "body": Color("e64980"), "dark": Color("a61e4d"), "legs": Color("69db7c")},
]
const TEXT_C := Color("ffffff")

var tex := {}
var _tex_wave := -1


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_make_textures()


func _make_textures() -> void:
	var w := (game.wave() - 1) % PALETTES.size()
	if w == _tex_wave:
		return
	_tex_wave = w
	var p: Dictionary = PALETTES[w]
	for hp in range(1, 5):
		var rows := mushroom_rows(hp)
		tex["m%d" % hp] = PixelArt.texture(rows, {"C": p.cap, "W": p.spot, "S": p.stem}, 3)
		tex["mp%d" % hp] = PixelArt.texture(rows, {"C": p.body, "W": p.legs, "S": p.dark}, 3)
	for f in 2:
		tex["body%d" % f] = PixelArt.texture(BODY[f], {"B": p.body, "D": p.dark, "L": p.legs}, 3)
		tex["head%d" % f] = PixelArt.texture(HEAD[f], {"B": p.body, "E": Color.WHITE, "A": p.legs, "L": p.legs}, 3)
		tex["spider%d" % f] = PixelArt.texture(SPIDER[f], {"B": p.cap, "E": Color.WHITE, "L": p.legs}, 3)
	tex.player = PixelArt.texture(SHOOTER, {"W": Color("f8f9fa"), "R": p.cap}, 3)
	tex.flea = PixelArt.texture(FLEA, {"B": p.stem, "E": Color.WHITE, "L": p.legs}, 3)
	tex.scorpion = PixelArt.texture(SCORPION, {"B": p.dark, "P": p.body, "T": p.legs, "E": Color.WHITE, "L": p.legs}, 3)


func _build_sfx() -> void:
	for i in 4:
		sfx["step%d" % i] = Synth.tone([110.0, 98.0, 87.3, 98.0][i], 0.05, {"wave": "square", "volume": 0.18, "lowpass": 0.2, "decay": 30.0})
	sfx.fire = Synth.tone(2200.0, 0.05, {"wave": "square", "freq_end": 900.0, "volume": 0.06, "lowpass": 0.5})
	sfx.kill = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.15, {"wave": "noise", "volume": 0.25, "lowpass": 0.4, "decay": 18.0}),
		Synth.render(600.0, 0.12, {"wave": "square", "freq_end": 200.0, "volume": 0.08}),
	]))
	sfx.kill_head = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.2, {"wave": "noise", "volume": 0.3, "lowpass": 0.4, "decay": 14.0}),
		Synth.render(1200.0, 0.18, {"wave": "square", "freq_end": 300.0, "volume": 0.1}),
	]))
	sfx.mushroom = Synth.tone(0.0, 0.06, {"wave": "noise", "volume": 0.18, "lowpass": 0.6, "decay": 40.0})
	var arp := []
	for f in [880.0, 1108.7, 1318.5, 1760.0]:
		arp.append(Synth.render(f, 0.06, {"wave": "square", "volume": 0.1, "lowpass": 0.4}))
	sfx.creature = Synth.concat(arp)
	sfx.death = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.2, {"wave": "noise", "volume": 0.35, "lowpass": 0.15, "decay": 2.5}),
		Synth.render(800.0, 1.2, {"wave": "square", "freq_end": 60.0, "volume": 0.1, "lowpass": 0.3}),
	]))
	sfx.repair = Synth.tone(1600.0, 0.03, {"wave": "square", "volume": 0.06})
	var beeps := []
	for i in 6:
		beeps.append(Synth.render(2093.0, 0.05, {"wave": "square", "volume": 0.1}))
		beeps.append(Synth.silence(0.04))
	sfx.extra = Synth.concat(beeps)
	var jingle := []
	for f in [523.25, 659.25, 783.99, 1046.5]:
		jingle.append(Synth.render(f, 0.08, {"wave": "square", "volume": 0.12, "lowpass": 0.4}))
	sfx.wave = Synth.concat(jingle)
	var warble := []
	for i in 3:
		warble.append(Synth.render(300.0, 0.06, {"wave": "square", "freq_end": 460.0, "volume": 0.07, "lowpass": 0.4, "attack": 0.0, "release": 0.0}))
		warble.append(Synth.render(460.0, 0.06, {"wave": "square", "freq_end": 300.0, "volume": 0.07, "lowpass": 0.4, "attack": 0.0, "release": 0.0}))
	sfx.spider = Synth.concat(warble)


func _tick(_dt: float) -> void:
	_make_textures()


func _draw() -> void:
	var g := game
	draw_rect(Rect2(0, 0, 1280, 720), Color.BLACK)
	for y in CentipedeGame.ROWS:
		for x in CentipedeGame.COLS:
			var hp := g.mushrooms[y * CentipedeGame.COLS + x]
			if hp > 0:
				var key := ("mp%d" if g.poisoned[y * CentipedeGame.COLS + x] == 1 else "m%d") % hp
				draw_texture(tex[key], px(Vector2(x, y) * C))
	var f := frame()
	for s in g.segments:
		var t: Texture2D = tex[("head%d" if s.head else "body%d") % f]
		var flip: bool = s.dx > 0
		draw_set_transform(px(s.pos + Vector2(4, 4)), 0.0, Vector2(-1 if flip else 1, 1))
		draw_texture(t, -t.get_size() / 2)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if g.flea != null:
		draw_texture(tex.flea, px(g.flea.pos) - tex.flea.get_size() / 2)
	if g.spider != null:
		var st: Texture2D = tex["spider%d" % f]
		draw_texture(st, px(g.spider.pos) - st.get_size() / 2)
	if g.scorpion != null:
		draw_set_transform(px(g.scorpion.pos), 0.0, Vector2(-1 if g.scorpion.dir < 0 else 1, 1))
		draw_texture(tex.scorpion, -tex.scorpion.get_size() / 2)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if g.shot != null:
		draw_rect(Rect2(px(g.shot - Vector2(0.5, 0)), Vector2(S, 4 * S)), Color.WHITE)
	if player_dying() or g.state == CentipedeGame.State.REPAIR:
		var k := clampf(1.0 - g.timer / 1.6, 0.0, 1.0) if player_dying() else 1.0
		for i in 10:
			var d := Vector2.from_angle(i * TAU / 10 + k) * (6.0 + 50.0 * k)
			draw_rect(Rect2(px(g.player_pos) + d - Vector2(3, 3), Vector2(6, 6)), Color(PALETTES[_tex_wave].cap, 1.0 - k * 0.8))
	elif g.state != CentipedeGame.State.OVER:
		draw_texture(tex.player, px(g.player_pos) - tex.player.get_size() / 2)
	for b in booms:
		var c := px(b.pos)
		var r: float = 14.0 * (1.0 - b.life / 0.4) + 4.0
		for i in 6:
			draw_rect(Rect2(c + Vector2.from_angle(i * TAU / 6) * r - Vector2(2, 2), Vector2(4, 4)), Color.WHITE)
	for p in popups:
		PixelFont.draw(self, p.text, px(p.pos).x, px(p.pos).y - 8, 2, TEXT_C)
	_draw_hud()


func _draw_hud() -> void:
	var g := game
	var p: Dictionary = PALETTES[_tex_wave]
	var lx := panel_left_x()
	var rx := panel_right_x()
	PixelFont.draw(self, I18n.t("PONTOS<1>"), lx, 40, 3, Color(p.cap, 1.0 if (g.current == 0 or g.players.size() == 1) else 0.4))
	PixelFont.draw(self, "%06d" % g.players[0].score, lx, 80, 4, TEXT_C)
	PixelFont.draw(self, I18n.t("RECORDE"), lx, 160, 3, p.cap)
	PixelFont.draw(self, "%06d" % maxi(g.best, g.player().score), lx, 200, 4, TEXT_C)
	if g.players.size() > 1:
		PixelFont.draw(self, I18n.t("PONTOS<2>"), rx, 40, 3, Color(p.cap, 1.0 if g.current == 1 else 0.4))
		PixelFont.draw(self, "%06d" % g.players[1].score, rx, 80, 4, TEXT_C)
	PixelFont.draw(self, I18n.t("VAGA %d") % g.wave(), rx, 160, 3, p.body)
	for i in mini(maxi(g.player().lives - 1, 0), 6):
		draw_texture(tex.player, Vector2(lx - 100 + i * 36, 640))


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0, 0, 0, 0.92),
		"border": Color("f783ac"),
		"text": TEXT_C,
		"accent": Color("ffd43b"),
		"button": Color.BLACK,
		"button_hover": Color(1, 1, 1, 0.14),
		"radius": 0,
		"dim": Color(0, 0, 0, 0.4),
	}
