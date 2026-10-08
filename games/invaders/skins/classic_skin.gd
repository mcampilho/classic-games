extends InvadersSkin
## Clássico 1978: monitor a preto e branco com tiras de celofane no vidro — vermelha em cima
## (zona do disco voador) e verde em baixo (abrigos e canhão). A marcha de 4 notas graves
## acelera à medida que a frota encolhe.

const WHITE := Color(0.94, 0.94, 0.94)
const RED := Color("e8463c")
const GREEN := Color("3ee05a")
const SHOT_BOOM := ["#...#.#.", "..#....#", ".######.", "#######.", ".#####..", "#.####.#", ".#.##...", "#..#..#."]

var shot_booms: Array[Dictionary] = []


func _build_sfx() -> void:
	var notes := [98.0, 87.3, 77.8, 73.4]
	for i in 4:
		sfx["march%d" % i] = Synth.tone(notes[i], 0.1, {"wave": "square", "volume": 0.5, "lowpass": 0.25, "decay": 12.0})
	sfx.shoot = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.22, {"wave": "noise", "volume": 0.22, "lowpass": 0.5, "decay": 10.0}),
		Synth.render(1400.0, 0.22, {"wave": "square", "freq_end": 300.0, "volume": 0.08, "decay": 10.0}),
	]))
	sfx.kill = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.3, {"wave": "noise", "volume": 0.3, "lowpass": 0.3, "decay": 9.0}),
		Synth.render(500.0, 0.3, {"wave": "square", "freq_end": 90.0, "volume": 0.12, "decay": 8.0}),
	]))
	var warble := []
	for i in 2:
		warble.append(Synth.render(700.0, 0.06, {"wave": "square", "freq_end": 1100.0, "volume": 0.12, "lowpass": 0.5, "attack": 0.0, "release": 0.0}))
		warble.append(Synth.render(1100.0, 0.06, {"wave": "square", "freq_end": 700.0, "volume": 0.12, "lowpass": 0.5, "attack": 0.0, "release": 0.0}))
	sfx.ufo = Synth.concat(warble)
	var hit := []
	for i in 6:
		hit.append(Synth.render(300.0 + i * 90.0, 0.07, {"wave": "square", "freq_end": 1400.0, "volume": 0.14, "lowpass": 0.5}))
	sfx.ufo_hit = Synth.concat(hit)
	sfx.player_hit = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.3, {"wave": "noise", "volume": 0.4, "lowpass": 0.15, "decay": 2.6}),
		Synth.render(0.0, 1.3, {"wave": "noise", "volume": 0.12, "lowpass": 0.8, "decay": 6.0}),
	]))
	var beeps := []
	for i in 6:
		beeps.append(Synth.render(1200.0, 0.05, {"wave": "square", "volume": 0.12}))
		beeps.append(Synth.silence(0.04))
	sfx.extra = Synth.concat(beeps)


func color_at(y_units: float) -> Color:
	if y_units >= 16.0 and y_units < 40.0:
		return RED
	if y_units >= 176.0:
		return GREEN
	return WHITE


func _on_shot_blocked(pos: Vector2, _by_bunker: bool) -> void:
	shot_booms.append({"pos": pos, "life": 0.18})


func _on_turn_started(player: int) -> void:
	super(player)
	shot_booms.clear()


func _tick(delta: float) -> void:
	for b in shot_booms:
		b.life -= delta
	shot_booms = shot_booms.filter(func(b: Dictionary) -> bool: return b.life > 0.0)


func _draw() -> void:
	var g := game
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color.BLACK)

	# chão
	draw_rect(Rect2(px(Vector2(0, InvadersGame.GROUND_Y)), Vector2(InvadersGame.FIELD.x * S, S)), GREEN)

	# abrigos
	for i in 4:
		draw_bunker(i, GREEN)

	# frota
	if g.state != InvadersGame.State.OVER or g.mode == InvadersGame.Mode.DEMO:
		for row in InvadersGame.ROWS:
			for col in InvadersGame.COLS:
				if g.alien_alive(row, col):
					var r := g.alien_rect(row, col)
					draw_bits(alien_frame(row), r.position, color_at(r.get_center().y))
	for b in booms:
		var p: Vector2 = b.pos - Vector2(6.5, 4)
		draw_bits(InvaderSprites.ALIEN_BOOM, p, color_at(b.pos.y))

	if g.ufo != null:
		draw_bits(InvaderSprites.UFO, Vector2(g.ufo.x, InvadersGame.UFO_Y), RED)
	for p in popups:
		var c := px(p.pos)
		PixelFont.draw(self, p.text, c.x, c.y - 10, 3, RED)

	# canhão
	var pr := g.player_rect()
	if player_dying():
		draw_bits(InvaderSprites.PLAYER_BOOM[dying_frame()], pr.position - Vector2(1.5, 0), GREEN)
	elif g.state != InvadersGame.State.OVER:
		draw_bits(InvaderSprites.PLAYER, pr.position, GREEN)

	# tiros
	if g.shot != null:
		var sr := g.shot_rect()
		draw_rect(Rect2(px(sr.position), sr.size * S), color_at(sr.position.y))
	for b in g.bombs:
		draw_bits(bomb_frame(b), b.pos - Vector2(1.5, 0), color_at(b.pos.y))
	for b in shot_booms:
		draw_bits(SHOT_BOOM, b.pos - Vector2(4, 4), color_at(b.pos.y))

	_draw_panels()


func _draw_panels() -> void:
	var g := game
	var lx := panel_left_x()
	var rx := panel_right_x()
	_score_block(I18n.t("PONTOS<1>"), g.players[0].score, lx, 40, g.current == 0 or g.players.size() == 1)
	_score_block(I18n.t("RECORDE"), maxi(g.best, g.players[0].score), lx, 150, true)
	if g.players.size() > 1:
		_score_block(I18n.t("PONTOS<2>"), g.players[1].score, rx, 40, g.current == 1)
	_score_block(I18n.t("VAGA"), g.player().wave, rx, 150, true)
	# vidas, como no original: número + canhões de reserva
	var lives: int = g.player().lives
	var shown := lives if player_dying() or g.state == InvadersGame.State.OVER else lives
	PixelFont.draw(self, str(maxi(shown, 0)), lx - 90, 640, 4, GREEN)
	for i in mini(maxi(shown - 1, 0), 4):
		draw_bits(InvaderSprites.PLAYER, (Vector2(lx - 60 + i * 48, 640) - InvadersGame.ORIGIN) / S, GREEN)


func _score_block(label: String, value: int, cx: float, top: float, bright: bool) -> void:
	var c := WHITE if bright else Color(WHITE, 0.4)
	PixelFont.draw(self, label, cx, top, 3, c)
	PixelFont.draw(self, "%04d" % value, cx, top + 40, 4, c)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0, 0, 0, 0.92),
		"border": WHITE,
		"text": WHITE,
		"accent": GREEN,
		"button": Color.BLACK,
		"button_hover": Color(1, 1, 1, 0.16),
		"radius": 0,
		"dim": Color(0, 0, 0, 0.45),
	}
