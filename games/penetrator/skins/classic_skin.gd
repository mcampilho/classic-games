extends PenetratorSkin
## Clássico 1981: fundo preto e o terreno desenhado só com a linha de contorno, como nos micros
## de 8 bits, com uma cor por zona; sons de altifalante.

const ZONE_COLORS := [Color("ffffff"), Color("00ffff"), Color("ffff00"), Color("ff00ff"), Color("00ff00")]
const YELLOW := Color("ffff00")
const CYAN := Color("00ffff")
const RED := Color("ff0000")


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex.ship = PixelArt.texture(SHIP, {"B": Color.WHITE, "b": Color("d7d7d7"), "H": CYAN, "C": CYAN, "N": RED, "F": YELLOW, "K": Color("808080")}, 1)
	tex.missile = PixelArt.texture(MISSILE, {"W": Color.WHITE, "R": RED, "B": Color("0000ff")}, 1)
	tex.saucer = PixelArt.texture(SAUCER, {"C": CYAN, "B": Color("ff00ff"), "b": Color("d700d7"), "L": YELLOW}, 1)


func _build_sfx() -> void:
	sfx.engine = Synth.to_stream(Synth.render(55.0, 1.0, {"wave": "square", "volume": 0.08, "lowpass": 0.1, "attack": 0.0, "release": 0.0}))
	sfx.shot = Synth.tone(1800.0, 0.08, {"wave": "square", "freq_end": 600.0, "volume": 0.1})
	sfx.bomb = Synth.tone(1400.0, 0.5, {"wave": "square", "freq_end": 300.0, "volume": 0.06})
	sfx.boom = Synth.tone(0.0, 0.35, {"wave": "noise", "volume": 0.3, "lowpass": 0.35, "decay": 9.0})
	sfx.thud = Synth.tone(0.0, 0.18, {"wave": "noise", "volume": 0.2, "lowpass": 0.2, "decay": 18.0})
	sfx.launch = Synth.tone(200.0, 0.4, {"wave": "square", "freq_end": 1200.0, "volume": 0.07})
	sfx.store_hit = Synth.tone(0.0, 0.3, {"wave": "noise", "volume": 0.3, "lowpass": 0.25, "decay": 8.0})
	sfx.boom_big = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.8, {"wave": "noise", "volume": 0.4, "lowpass": 0.18, "decay": 2.0}),
		Synth.render(120.0, 1.2, {"wave": "square", "freq_end": 30.0, "volume": 0.1}),
	]))
	sfx.die = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.2, {"wave": "noise", "volume": 0.35, "lowpass": 0.25, "decay": 2.5}),
		Synth.render(900.0, 1.0, {"wave": "square", "freq_end": 50.0, "volume": 0.1}),
	]))
	var z := []
	for f in [523.0, 784.0, 1046.0]:
		z.append(Synth.render(f, 0.08, {"wave": "square", "volume": 0.1}))
	sfx.zone = Synth.concat(z)
	var c := []
	for f in [523.0, 659.0, 784.0, 1046.0, 784.0, 1046.0, 1318.0, 1568.0]:
		c.append(Synth.render(f, 0.11, {"wave": "square", "volume": 0.12}))
	sfx.complete = Synth.concat(c)
	var e := []
	for i in 6:
		e.append(Synth.render(1568.0, 0.05, {"wave": "square", "volume": 0.1}))
		e.append(Synth.silence(0.04))
	sfx.extra = Synth.concat(e)


func _draw_terrain() -> void:
	var col: Color = ZONE_COLORS[game.zone_of(game.cam_x + PenetratorGame.W / 2) % ZONE_COLORS.size()]
	draw_polyline(contour(false), col, 3.0)
	if has_ceiling():
		var top := contour(true)
		# só onde há teto
		var seg := PackedVector2Array()
		for p in top:
			if p.y > PenetratorGame.TOP + 0.5:
				seg.append(p)
			elif seg.size() > 1:
				draw_polyline(seg, col, 3.0)
				seg = PackedVector2Array()
			else:
				seg = PackedVector2Array()
		if seg.size() > 1:
			draw_polyline(seg, col, 3.0)


func _draw_enemy(e: Dictionary, p: Vector2) -> void:
	match e.kind:
		"missile":
			var t: Texture2D = tex.missile
			draw_tex_center(t, p - Vector2(0, t.get_height() * 1.5), 3.0)
			if e.flying and fmod(time, 0.1) < 0.05:
				draw_rect(Rect2(p + Vector2(-4, 0), Vector2(8, 14)), YELLOW)
		"radar":
			draw_radar(p, e.phase, Color.WHITE, CYAN)
		"saucer":
			draw_tex_center(tex.saucer, p, 3.0)
		"store":
			draw_store(p, Color("d7d7d7"), Color("0000d7"), RED, game.store_left)


func _draw_shot(p: Vector2) -> void:
	draw_rect(Rect2(p - Vector2(8, 1), Vector2(16, 3)), YELLOW)


func _draw_bomb(p: Vector2, _v: Vector2) -> void:
	draw_rect(Rect2(p - Vector2(4, 3), Vector2(8, 6)), Color.WHITE)


func _draw_ship(p: Vector2) -> void:
	draw_tex_center(tex.ship, p, 3.0, game.ship_tilt * 0.08)
	if fmod(time, 0.08) < 0.04:
		draw_rect(Rect2(p + Vector2(-40, 2), Vector2(8, 5)), YELLOW)


func _draw_hud() -> void:
	var g := game
	draw_rect(Rect2(0, 0, PenetratorGame.W, PenetratorGame.TOP - 4), Color.BLACK)
	draw_line(Vector2(0, PenetratorGame.TOP - 4), Vector2(PenetratorGame.W, PenetratorGame.TOP - 4), Color("0000d7"), 3.0)
	PixelFont.draw(self, I18n.t("PONTOS %06d") % g.score, 170, 12, 3, Color.WHITE)
	PixelFont.draw(self, I18n.t("REC %06d") % maxi(g.best, g.score), 170, 40, 2, CYAN)
	PixelFont.draw(self, I18n.t("MISSAO %d") % g.mission, 1120, 12, 3, YELLOW)
	for i in mini(g.lives - 1, 6):
		draw_tex_center(tex.ship, Vector2(1040 + i * 30, 46), 1.0)
	# mapa das zonas
	var x0 := 420.0
	var w := 440.0
	for z in PenetratorGame.ZONES:
		var r := Rect2(x0 + z * w / PenetratorGame.ZONES + 2, 14, w / PenetratorGame.ZONES - 4, 14)
		var c: Color = ZONE_COLORS[z]
		draw_rect(r, c if z < g.zone else Color(c, 0.25))
		if z == g.zone:
			draw_rect(Rect2(r.position, Vector2(r.size.x * g.zone_progress(), r.size.y)), c)
			draw_rect(r, c, false, 2.0)
	PixelFont.draw(self, I18n.t(PenetratorGame.ZONE_NAMES[g.zone]).to_upper(), x0 + w / 2, 38, 2, ZONE_COLORS[g.zone])
	for p in popups:
		PixelFont.draw(self, p.text, sx(p.pos.x), p.pos.y, 2, Color.WHITE)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0, 0, 0, 0.92),
		"border": CYAN,
		"text": Color.WHITE,
		"accent": YELLOW,
		"button": Color(0, 0, 0.5),
		"button_hover": Color(0, 0, 0.8),
		"radius": 0,
		"dim": Color(0, 0, 0, 0.4),
	}
