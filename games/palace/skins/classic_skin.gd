extends PalaceSkin
## Clássico 1989: as masmorras de pedra azulada dos jogos de computador da época — tijolos,
## lajes com aresta clara, tochas a tremeluzir — e um herói vestido de branco animado com
## suavidade. Guardas de turbante colorido.

const STONE := Color("3a4462")
const STONE2 := Color("2e3652")
const STONE3 := Color("4a5578")
const SLAB := Color("8a90a8")
const SLAB2 := Color("5a607a")
const SLAB3 := Color("c8ccdc")
const SKIN := Color("e8b48a")
const WHITE := Color("f0f0f0")
const WHITE2 := Color("b8bcc8")
const GUARD_COLS := [Color("c83a3a"), Color("3a8ac8"), Color("c8a03a")]


func _build_sfx() -> void:
	sfx.step = Synth.tone(0.0, 0.03, {"wave": "noise", "volume": 0.08, "lowpass": 0.2, "decay": 60.0})
	sfx.jump = Synth.tone(0.0, 0.08, {"wave": "noise", "volume": 0.08, "lowpass": 0.3, "decay": 30.0})
	sfx.land = Synth.tone(0.0, 0.1, {"wave": "noise", "volume": 0.18, "lowpass": 0.15, "decay": 30.0})
	sfx.land_hard = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 0.25, {"wave": "noise", "volume": 0.3, "lowpass": 0.12, "decay": 14.0}),
		Synth.render(300.0, 0.25, {"wave": "square", "freq_end": 150.0, "volume": 0.08}),
	]))
	sfx.grab = Synth.tone(0.0, 0.06, {"wave": "noise", "volume": 0.1, "lowpass": 0.4, "decay": 40.0})
	sfx.bump = Synth.tone(0.0, 0.15, {"wave": "noise", "volume": 0.2, "lowpass": 0.15, "decay": 20.0})
	sfx.gate = Synth.tone(90.0, 0.8, {"wave": "square", "volume": 0.06, "lowpass": 0.1})
	sfx.exit_open = Synth.tone(70.0, 1.6, {"wave": "square", "volume": 0.06, "lowpass": 0.08})
	sfx.spikes = Synth.tone(0.0, 0.08, {"wave": "noise", "volume": 0.15, "lowpass": 0.8, "decay": 30.0})
	sfx.crumble = Synth.tone(0.0, 0.5, {"wave": "noise", "volume": 0.25, "lowpass": 0.2, "decay": 6.0})
	sfx.clash = Synth.to_stream(Synth.mix([
		Synth.render(2400.0, 0.2, {"wave": "square", "volume": 0.06, "decay": 20.0}),
		Synth.render(3100.0, 0.2, {"wave": "square", "volume": 0.05, "decay": 25.0}),
	]))
	sfx.hit_guard = Synth.tone(200.0, 0.15, {"wave": "square", "freq_end": 90.0, "volume": 0.12})
	sfx.hit_hero = Synth.tone(160.0, 0.2, {"wave": "square", "freq_end": 70.0, "volume": 0.14})
	sfx.guard_die = Synth.tone(300.0, 0.6, {"wave": "square", "freq_end": 60.0, "volume": 0.1})
	var d := []
	for f in [392.0, 370.0, 330.0, 294.0, 262.0]:
		d.append(Synth.render(f, 0.22, {"wave": "square", "volume": 0.1, "lowpass": 0.4}))
	sfx.die = Synth.concat(d)
	sfx.potion = Synth.concat([Synth.render(523.0, 0.08, {"wave": "square", "volume": 0.08}), Synth.render(659.0, 0.08, {"wave": "square", "volume": 0.08}), Synth.render(784.0, 0.15, {"wave": "square", "volume": 0.08})])
	sfx.life = Synth.concat([Synth.render(523.0, 0.1, {"wave": "square", "volume": 0.1}), Synth.render(784.0, 0.1, {"wave": "square", "volume": 0.1}), Synth.render(1046.0, 0.25, {"wave": "square", "volume": 0.1})])
	sfx.sword = Synth.concat([Synth.render(659.0, 0.12, {"wave": "square", "volume": 0.1}), Synth.render(880.0, 0.12, {"wave": "square", "volume": 0.1}), Synth.render(1318.0, 0.3, {"wave": "square", "volume": 0.1})])
	var l := []
	for f in [523.0, 587.0, 622.0, 784.0, 698.0, 784.0]:
		l.append(Synth.render(f, 0.15, {"wave": "square", "volume": 0.1, "lowpass": 0.5}))
	sfx.level = Synth.concat(l)
	sfx.win = sfx.level


func _draw_back() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color.BLACK)


func _paint_room(ci: CanvasItem, room: Vector2i) -> void:
	ci.draw_rect(Rect2(0, 0, ROOM_W, ROOM_H), STONE2)
	each_tile(room, func(gc: int, gr: int, ch: String, r: Rect2) -> void: _paint_tile(ci, gc, gr, ch, r))


func _paint_tile(ci: CanvasItem, gc: int, gr: int, ch: String, r: Rect2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = gc * 131 + gr * 17
	# tijolos ao fundo
	for row in 6:
		var y := r.position.y + row * 35.0
		var off := 0.0 if row % 2 == 0 else 32.0
		for k in 3:
			var x := r.position.x + off + k * 64.0 - 32.0
			var b := Rect2(x + 2, y + 2, 60, 31).intersection(r)
			if b.size.x > 4:
				ci.draw_rect(b, STONE.lerp(STONE3, rng.randf() * 0.4))
	if ch == "#":
		ci.draw_rect(r, STONE3)
		for row in 3:
			for k in 2:
				var b := Rect2(r.position + Vector2(4 + k * 62 - (31 if row % 2 else 0), 4 + row * 70), Vector2(58, 64)).intersection(r.grow(-2))
				ci.draw_rect(b, Color("6a7598").lerp(Color("5a6588"), rng.randf()))
				ci.draw_line(b.position, Vector2(b.end.x, b.position.y), Color("9aa4c4"), 2.0)
		return
	if PalaceGame.FLOOR.contains(ch):
		var fy := r.end.y - 18.0
		var slab := Rect2(r.position.x, fy, r.size.x, 18)
		if ch == "~":
			slab = slab.grow_individual(-4, 0, -4, 0)
		ci.draw_rect(slab, SLAB2 if ch != "~" else Color("6a6a82"))
		ci.draw_rect(Rect2(slab.position, Vector2(slab.size.x, 5)), SLAB3)
		ci.draw_rect(Rect2(slab.position.x, slab.end.y - 3, slab.size.x, 3), Color(0, 0, 0, 0.5))
		# sombra por baixo do chão
		ci.draw_rect(Rect2(r.position.x, r.end.y, r.size.x, 10).intersection(Rect2(0, 0, ROOM_W, ROOM_H)), Color(0, 0, 0, 0.35))
	if ch == "|":
		ci.draw_rect(Rect2(r.position.x + 52, r.position.y, 24, 18), Color("2a2a36"))
	if ch == "D":
		var d := Rect2(r.position.x + 10, r.position.y + 40, r.size.x - 20, r.size.y - 58)
		ci.draw_rect(d.grow(8), Color("6a7598"))
		ci.draw_rect(d, Color("101018"))
		ci.draw_rect(Rect2(d.position.x - 14, d.position.y - 20, d.size.x + 28, 14), Color("9aa4c4"))


func _draw_dynamic() -> void:
	super()
	# tochas nas paredes (nas casas com chão, de vez em quando)
	each_tile(game.room, _torch)


func _torch(gc: int, gr: int, ch: String, rect: Rect2) -> void:
	if (gc * 7 + gr * 3) % 5 != 0 or ch == "#" or ch == " ":
		return
	var p := rect.position + Vector2(rect.size.x / 2, OFF_Y + 70)
	draw_rect(Rect2(p + Vector2(-4, 0), Vector2(8, 26)), Color("6a4a2a"))
	var h := 18.0 + sin(time * 13.0 + gc) * 4.0 + sin(time * 7.0 + gr) * 3.0
	draw_circle(p + Vector2(0, -6), 26, Color(1.0, 0.6, 0.2, 0.12))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-8, 0), p + Vector2(8, 0), p + Vector2(sin(time * 9.0) * 3.0, -h)]), Color("ffb030"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(4, 0), p + Vector2(0, -h * 0.6)]), Color("fff0a0"))


func _limb(a: Vector2, b: Vector2, c: Color, w: float) -> void:
	draw_line(a, b, c, w)
	draw_circle(a, w / 2, c)
	draw_circle(b, w / 2, c)


func _draw_figure(j: Dictionary, is_guard: bool, sword: bool, info: Dictionary) -> void:
	var alpha: float = info.get("alpha", 1.0)
	var body := WHITE
	var body2 := WHITE2
	if is_guard:
		var gc: Color = GUARD_COLS[(game.level + int(info.get("max_hp", 3))) % GUARD_COLS.size()]
		body = gc
		body2 = gc.darkened(0.35)
	body = Color(body, alpha)
	body2 = Color(body2, alpha)
	var skin := Color(SKIN, alpha)
	# membros de trás (mais escuros)
	_limb(j.hip, j.knee_b, body2, 13.0)
	_limb(j.knee_b, j.foot_b, body2, 11.0)
	_limb(j.sh_b, j.elbow_b, body2, 10.0)
	_limb(j.elbow_b, j.hand_b, Color(SKIN.darkened(0.2), alpha), 8.0)
	# tronco e cabeça
	_limb(j.hip, j.neck, body, 20.0)
	draw_circle(j.head, 13.0, skin)
	if is_guard:
		draw_circle(j.head + Vector2(0, -8), 13.0, body2)
		draw_circle(j.head + Vector2(0, -12), 9.0, body)
	else:
		draw_circle(j.head + Vector2(0, -6), 11.0, Color(Color("3a2a1a"), alpha))
	# membros da frente
	_limb(j.hip, j.knee_f, body, 13.0)
	_limb(j.knee_f, j.foot_f, body, 11.0)
	if sword:
		var tip: Vector2 = j.hand_f + j.sword_dir * 74.0
		draw_line(j.hand_f, tip, Color(Color("e0e8f0"), alpha), 4.0)
		draw_line(j.hand_f - j.sword_dir.orthogonal() * 8.0, j.hand_f + j.sword_dir.orthogonal() * 8.0, Color(Color("c8a03a"), alpha), 4.0)
	_limb(j.sh_f, j.elbow_f, body, 10.0)
	_limb(j.elbow_f, j.hand_f, skin, 8.0)


func _draw_gate(r: Rect2, floor_y: float, open: float) -> void:
	var bottom := lerpf(floor_y, r.position.y + 20.0, open)
	for k in 5:
		var x := r.position.x + 48 + k * 8
		draw_line(Vector2(x, r.position.y + 18), Vector2(x, bottom), Color("8a8aa0"), 3.0)
	for y in range(int(r.position.y + 40), int(bottom), 30):
		draw_line(Vector2(r.position.x + 46, y), Vector2(r.position.x + 82, y), Color("8a8aa0"), 3.0)


func _draw_spikes(r: Rect2, floor_y: float, out: float) -> void:
	for k in 5:
		var x := r.position.x + 16 + k * 24
		var h := 6.0 + 34.0 * out
		draw_colored_polygon(PackedVector2Array([Vector2(x - 6, floor_y), Vector2(x + 6, floor_y), Vector2(x, floor_y - h)]), Color("d8dce8"))


func _draw_door(r: Rect2, floor_y: float, open: float) -> void:
	var d := Rect2(r.position.x + 10, r.position.y + 40, r.size.x - 20, floor_y - r.position.y - 40)
	var h := d.size.y * (1.0 - open)
	draw_rect(Rect2(d.position, Vector2(d.size.x, h)), Color("4a4a5a"))
	for y in range(int(d.position.y), int(d.position.y + h), 14):
		draw_line(Vector2(d.position.x, y), Vector2(d.end.x, y), Color("2a2a36"), 2.0)
	if open > 0.9:
		draw_rect(d.grow(-10), Color(1.0, 0.9, 0.5, 0.1 + 0.05 * sin(time * 3.0)))


func _draw_potion(p: Vector2, big: bool) -> void:
	var s := 1.4 if big else 1.0
	var c := Color("3ad070") if big else Color("e03a4a")
	draw_circle(p + Vector2(0, -12 * s), 10 * s, c)
	draw_rect(Rect2(p + Vector2(-3, -30) * s, Vector2(6, 10) * s), Color("c8c8d8"))
	draw_circle(p + Vector2(-3, -15 * s), 2 + sin(time * 6.0), Color(1, 1, 1, 0.7))


func _draw_sword_item(p: Vector2) -> void:
	draw_line(p + Vector2(-34, -4), p + Vector2(30, -4), Color("e0e8f0"), 4.0)
	draw_line(p + Vector2(-26, -12), p + Vector2(-26, 4), Color("c8a03a"), 4.0)
	draw_circle(p + Vector2(0, -6), 20 + sin(time * 4.0) * 3, Color(1, 1, 1, 0.08))


func _draw_loose_shake(r: Rect2, floor_y: float, t: float) -> void:
	var dx := sin(time * 60.0) * 3.0 * t
	draw_rect(Rect2(r.position.x + 4 + dx, floor_y, r.size.x - 8, 18), Color("7a7a92"))


func _draw_plate(r: Rect2, on: bool) -> void:
	draw_rect(r.grow_individual(0, -3 if on else 0, 0, 0), Color("c8ccdc") if not on else Color("8a90a8"))


func _draw_debris(p: Vector2) -> void:
	for k in 4:
		draw_rect(Rect2(p + Vector2(-40 + k * 22, -10), Vector2(18, 12)), Color("8a90a8"))


func _draw_hud() -> void:
	var g := game
	draw_rect(Rect2(0, 650, 1280, 70), Color.BLACK)
	for i in g.max_hp:
		var x := 30 + i * 30
		var c := Color("e03a3a") if i < g.hp else Color("4a1a1a")
		draw_colored_polygon(PackedVector2Array([Vector2(x, 700), Vector2(x + 22, 700), Vector2(x + 11, 676)]), c)
	var foe: Variant = g._nearest_guard()
	if foe != null:
		for i in int(foe.max_hp):
			var x := 1170 - i * 30
			var c := Color("3a8ac8") if i < int(foe.hp) else Color("1a2a3a")
			draw_colored_polygon(PackedVector2Array([Vector2(x - 22, 700), Vector2(x, 700), Vector2(x - 11, 676)]), c)
	PixelFont.draw(self, I18n.t("%d MINUTOS") % g.minutes_left(), 640, 672, 3, WHITE)
	PixelFont.draw(self, I18n.t("NIVEL %d") % (g.level + 1), 400, 680, 2, WHITE2)
	PixelFont.draw(self, I18n.t("VIDAS %d") % g.lives, 880, 680, 2, WHITE2)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.05, 0.06, 0.1, 0.94),
		"border": Color("c8a03a"),
		"text": WHITE,
		"accent": Color("e8c050"),
		"button": Color(0.12, 0.14, 0.22),
		"button_hover": Color(0.2, 0.22, 0.34),
		"radius": 2,
		"dim": Color(0, 0, 0, 0.4),
	}
