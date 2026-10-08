extends InvadersSkin
## Neon: invasores de luz que pulsam ao ritmo da marcha, faíscas, ondas de choque,
## pontos a flutuar e uma linha de baixo sintetizada no lugar das 4 notas originais.

const BG_TOP := Color("0a0320")
const BG_BOTTOM := Color("1b0639")
const GRID := Color(0.55, 0.3, 1.0, 0.08)
const ROW_COLORS := [Color("ff2bd6"), Color("ffb03d"), Color("ffb03d"), Color("19f0ff"), Color("19f0ff")]
const PLAYER_C := Color("3dffa0")
const UFO_C := Color("ff2b4f")
const BOMB_C := Color("ff5bd0")
const SHOT_C := Color("bfffe9")

var fx: Node2D
var font: Font
var time := 0.0
var beat := 0.0
var shake := 0.0
var flash := 0.0
var flash_color := Color.WHITE
var tex := {}        # texturas nítidas
var glow := {}       # texturas desfocadas (brilho)
var sparks: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var floaters: Array[Dictionary] = []
var shot_trail: Array[Vector2] = []


func _setup() -> void:
	font = ThemeDB.fallback_font
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx = Node2D.new()
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = m
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(fx)
	fx.draw.connect(_draw_fx)
	for kind in 3:
		var c: Color = ROW_COLORS[[0, 1, 3][kind]]
		for f in 2:
			var rows: Array = InvaderSprites.ALIENS[kind][f]
			tex["a%d%d" % [kind, f]] = InvaderSprites.texture(rows, c.lerp(Color.WHITE, 0.35))
			glow["a%d%d" % [kind, f]] = InvaderSprites.glow_texture(rows, c)
	tex.player = InvaderSprites.texture(InvaderSprites.PLAYER, PLAYER_C.lerp(Color.WHITE, 0.3))
	glow.player = InvaderSprites.glow_texture(InvaderSprites.PLAYER, PLAYER_C)
	tex.ufo = InvaderSprites.texture(InvaderSprites.UFO, UFO_C.lerp(Color.WHITE, 0.3))
	glow.ufo = InvaderSprites.glow_texture(InvaderSprites.UFO, UFO_C)
	for k in 3:
		for f in 2:
			tex["b%d%d" % [k, f]] = InvaderSprites.texture(InvaderSprites.BOMBS[k][f], BOMB_C.lerp(Color.WHITE, 0.4))
			glow["b%d%d" % [k, f]] = InvaderSprites.glow_texture(InvaderSprites.BOMBS[k][f], BOMB_C, 3, 2)


func _build_sfx() -> void:
	var notes := [55.0, 49.0, 43.65, 41.2]
	for i in 4:
		sfx["march%d" % i] = Synth.to_stream(Synth.mix([
			Synth.render(notes[i], 0.16, {"wave": "saw", "volume": 0.45, "lowpass": 0.12, "decay": 14.0}),
			Synth.render(notes[i] * 2.0, 0.05, {"wave": "square", "volume": 0.08, "lowpass": 0.3, "decay": 50.0}),
		]))
	sfx.shoot = Synth.tone(1800.0, 0.14, {"wave": "square", "freq_end": 260.0, "volume": 0.12, "lowpass": 0.35, "decay": 14.0})
	sfx.kill = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.2, {"wave": "noise", "volume": 0.22, "lowpass": 0.35, "decay": 16.0}),
		Synth.render(880.0, 0.18, {"wave": "triangle", "freq_end": 220.0, "volume": 0.25, "decay": 14.0}),
		Synth.render(1760.0, 0.1, {"wave": "sine", "volume": 0.1, "decay": 30.0}),
	]))
	var wob := []
	for i in 2:
		wob.append(Synth.render(520.0, 0.09, {"wave": "sine", "freq_end": 780.0, "volume": 0.2, "attack": 0.0, "release": 0.0}))
		wob.append(Synth.render(780.0, 0.09, {"wave": "sine", "freq_end": 520.0, "volume": 0.2, "attack": 0.0, "release": 0.0}))
	sfx.ufo = Synth.concat(wob)
	var arp := []
	for f in [523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0]:
		arp.append(Synth.render(f, 0.07, {"wave": "square", "volume": 0.14, "lowpass": 0.3}))
	sfx.ufo_hit = Synth.concat(arp)
	sfx.player_hit = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.4, {"wave": "noise", "volume": 0.35, "lowpass": 0.2, "decay": 2.5}),
		Synth.render(300.0, 1.2, {"wave": "saw", "freq_end": 40.0, "volume": 0.2, "lowpass": 0.2, "decay": 2.0}),
	]))
	var up := []
	for f in [659.25, 783.99, 987.77, 1318.5]:
		up.append(Synth.render(f, 0.08, {"wave": "triangle", "volume": 0.25}))
	sfx.extra = Synth.concat(up)


# ---------------------------------------------------------------- eventos

func _on_match_started() -> void:
	super()
	sparks.clear()
	rings.clear()
	floaters.clear()


func _on_fleet_stepped(note: int) -> void:
	super(note)
	beat = 1.0


func _on_player_fired(pos: Vector2) -> void:
	super(pos)
	shot_trail.clear()


func _on_alien_killed(row: int, col: int, pos: Vector2, points: int, kind: int) -> void:
	super(row, col, pos, points, kind)
	var c: Color = ROW_COLORS[row]
	_burst(pos, c, 18)
	rings.append({"pos": pos, "radius": 4.0, "alpha": 0.9, "color": c, "speed": 70.0})
	floaters.append({"pos": pos, "text": "+%d" % points, "life": 0.8, "color": c})
	shake = maxf(shake, 2.5)


func _on_ufo_killed(pos: Vector2, points: int) -> void:
	super(pos, points)
	_burst(pos, UFO_C, 40)
	rings.append({"pos": pos, "radius": 6.0, "alpha": 1.0, "color": UFO_C, "speed": 120.0})
	flash = 0.6
	flash_color = UFO_C


func _on_player_hit(pos: Vector2) -> void:
	super(pos)
	_burst(pos, PLAYER_C, 60)
	rings.append({"pos": pos, "radius": 6.0, "alpha": 1.0, "color": PLAYER_C, "speed": 160.0})
	shake = 16.0
	flash = 0.8
	flash_color = Color("ff2b4f")


func _on_shot_blocked(pos: Vector2, by_bunker: bool) -> void:
	_burst(pos, PLAYER_C if by_bunker else SHOT_C, 6)


func _on_wave_cleared() -> void:
	super()
	flash = 0.9
	flash_color = Color("19f0ff")
	for i in 5:
		rings.append({"pos": Vector2(112, 100), "radius": 4.0 + i * 12.0, "alpha": 1.0, "color": ROW_COLORS[i], "speed": 200.0})


func _burst(pos: Vector2, c: Color, n: int) -> void:
	for i in n:
		var life := randf_range(0.25, 0.7)
		sparks.append({"pos": pos, "vel": Vector2.from_angle(randf() * TAU) * randf_range(30.0, 160.0), "life": life, "max": life, "color": c})


# ---------------------------------------------------------------- animação

func _tick(dt: float) -> void:
	time += dt
	beat = move_toward(beat, 0.0, dt * 5.0)
	shake = move_toward(shake, 0.0, dt * 40.0)
	flash = move_toward(flash, 0.0, dt * 2.5)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	var drag := pow(0.05, dt)
	for s in sparks:
		s.pos += s.vel * dt
		s.vel *= drag
		s.life -= dt
	sparks = sparks.filter(func(s: Dictionary) -> bool: return s.life > 0.0)
	for r in rings:
		r.radius += r.speed * dt
		r.alpha -= 1.8 * dt
	rings = rings.filter(func(r: Dictionary) -> bool: return r.alpha > 0.0)
	for f in floaters:
		f.pos.y -= 20.0 * dt
		f.life -= dt
	floaters = floaters.filter(func(f: Dictionary) -> bool: return f.life > 0.0)
	if game.shot != null:
		shot_trail.append(game.shot)
		if shot_trail.size() > 6:
			shot_trail.pop_front()
	else:
		shot_trail.clear()
	fx.queue_redraw()


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var a := Vector2(-80, -80)
	var b := Vector2(1360, 800)
	draw_polygon(PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)]),
		PackedColorArray([BG_TOP, BG_TOP, BG_BOTTOM, BG_BOTTOM]))
	var off := fmod(time * 10.0, 64.0)
	for x in range(-64, 1344, 64):
		draw_line(Vector2(x, -80), Vector2(x, 800), GRID, 1.0)
	for y in range(-64, 784, 64):
		draw_line(Vector2(-80, y + off), Vector2(1360, y + off), GRID, 1.0)
	var field := Rect2(InvadersGame.ORIGIN, InvadersGame.FIELD * S)
	draw_rect(field, Color(0, 0, 0, 0.35))
	_draw_sprites(self, false)


## Os sprites são desenhados duas vezes: nítidos na camada normal e desfocados na camada aditiva.
func _draw_sprites(ci: CanvasItem, glowing: bool) -> void:
	var g := game
	var k := 1.0 + beat * 0.6
	for row in InvadersGame.ROWS:
		var kind: int = InvadersGame.ROW_KIND[row]
		var key := "a%d%d" % [kind, g.anim_frame]
		for col in InvadersGame.COLS:
			if g.alien_alive(row, col):
				_sprite(ci, glowing, key, g.alien_rect(row, col).position, 0.55 * k if glowing else 1.0)
	if g.ufo != null:
		_sprite(ci, glowing, "ufo", Vector2(g.ufo.x, InvadersGame.UFO_Y), 0.8 + 0.3 * sin(time * 12.0) if glowing else 1.0)
	if not player_dying() and g.state != InvadersGame.State.OVER:
		_sprite(ci, glowing, "player", g.player_rect().position, 0.8 if glowing else 1.0)
	for b in g.bombs:
		_sprite(ci, glowing, "b%d%d" % [b.kind, int(b.frame) % 2], b.pos - Vector2(1.5, 0), 0.9 if glowing else 1.0)


func _sprite(ci: CanvasItem, glowing: bool, key: String, u: Vector2, alpha: float) -> void:
	if glowing:
		var t: Texture2D = glow[key]
		var pad := 4.0 if key.begins_with("a") or key == "player" or key == "ufo" else 3.0
		ci.draw_texture_rect(t, Rect2(px(u - Vector2(pad, pad)), t.get_size() * S), false, Color(1, 1, 1, alpha))
	else:
		var t: Texture2D = tex[key]
		ci.draw_texture(t, px(u))


func _draw_fx() -> void:
	var g := game
	if flash > 0.0:
		fx.draw_rect(Rect2(-80, -80, 1440, 880), Color(flash_color, flash * 0.14))
	# chão
	var gy := px(Vector2(0, InvadersGame.GROUND_Y))
	fx.draw_rect(Rect2(gy, Vector2(InvadersGame.FIELD.x * S, 3)), Color(PLAYER_C, 0.7))
	fx.draw_rect(Rect2(gy - Vector2(0, 3), Vector2(InvadersGame.FIELD.x * S, 9)), Color(PLAYER_C, 0.12))
	for i in 4:
		draw_bunker(i, Color(PLAYER_C.lerp(Color.WHITE, 0.2), 0.9), fx)
	_draw_sprites(fx, true)

	for i in shot_trail.size():
		var p := px(shot_trail[i])
		fx.draw_rect(Rect2(p - Vector2(1.5, 0), Vector2(3, 12)), Color(SHOT_C, 0.12 * (i + 1)))
	if g.shot != null:
		var p := px(g.shot)
		fx.draw_rect(Rect2(p - Vector2(1.5, 0), Vector2(3, 12)), SHOT_C)
		fx.draw_rect(Rect2(p - Vector2(5, 3), Vector2(10, 18)), Color(PLAYER_C, 0.18))

	for b in booms:
		fx.draw_circle(px(b.pos), 26.0 * (1.0 - b.life / 0.28) + 4.0, Color(1, 1, 1, b.life * 1.5), true, -1.0, true)
	if player_dying():
		var c := px(g.player_rect().get_center())
		var a := clampf(g.timer / 2.0, 0.0, 1.0)
		fx.draw_circle(c, 30.0 + 20.0 * sin(time * 30.0), Color(PLAYER_C, 0.25 * a), true, -1.0, true)
		_sprite(fx, true, "player", g.player_rect().position + Vector2(randf_range(-1, 1), randf_range(-1, 1)), a)
	for r in rings:
		fx.draw_arc(px(r.pos), r.radius * S, 0.0, TAU, 48, Color(r.color, maxf(r.alpha, 0.0)), 3.0, true)
	for s in sparks:
		var p := px(s.pos)
		fx.draw_line(p, p - s.vel * 0.06, Color(s.color.lerp(Color.WHITE, 0.4), s.life / s.max), 2.0, true)
	for f in floaters:
		_text(f.text, px(f.pos).x, px(f.pos).y, f.color, 20, clampf(f.life * 2.0, 0.0, 1.0))
	for p in popups:
		_text(p.text, px(p.pos).x, px(p.pos).y + 8, UFO_C, 34, clampf(p.life, 0.0, 1.0))
	_draw_panels()


func _draw_panels() -> void:
	var g := game
	var lx := panel_left_x()
	var rx := panel_right_x()
	var label_c := Color("8a5cff").lerp(Color.WHITE, 0.3)
	var a0 := 1.0 if (g.current == 0 or g.players.size() == 1) else 0.4
	_text(I18n.t("JOGADOR 1"), lx, 80, label_c, 20, a0)
	_text(str(g.players[0].score), lx, 140, Color("19f0ff"), 52, a0)
	_text(I18n.t("RECORDE"), lx, 230, label_c, 20, 0.9)
	_text(str(maxi(g.best, g.players[0].score)), lx, 280, Color("ffc53d"), 40, 0.9)
	if g.players.size() > 1:
		var a1 := 1.0 if g.current == 1 else 0.4
		_text(I18n.t("JOGADOR 2"), rx, 80, label_c, 20, a1)
		_text(str(g.players[1].score), rx, 140, Color("ff2bd6"), 52, a1)
	_text(I18n.t("VAGA"), rx, 230, label_c, 20, 0.9)
	_text(str(g.player().wave), rx, 280, Color("3dffa0"), 40, 0.9)
	_text(I18n.t("VIDAS"), lx, 560, label_c, 20, 0.9)
	var lives: int = maxi(g.player().lives, 0)
	for i in mini(lives, 6):
		var u := (Vector2(lx - (mini(lives, 6) - 1) * 24.0 + i * 48.0 - 19.5, 590) - InvadersGame.ORIGIN) / S
		_sprite(fx, true, "player", u, 0.7)
		_sprite(fx, false, "player", u, 1.0)


func _text(text: String, center_x: float, baseline: float, c: Color, size: int, alpha: float) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(center_x - w / 2, baseline)
	fx.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 12, Color(c, 0.12 * alpha))
	fx.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 5, Color(c, 0.28 * alpha))
	fx.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(c.lerp(Color.WHITE, 0.45), alpha))


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.04, 0.02, 0.13, 0.88),
		"border": Color("8a5cff"),
		"text": Color("ece6ff"),
		"accent": Color("3dffa0"),
		"button": Color("170a36"),
		"button_hover": Color("2a1361"),
		"radius": 10,
		"dim": Color(0, 0, 0, 0.3),
	}
