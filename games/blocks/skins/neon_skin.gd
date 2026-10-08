extends BlocksSkin
## Neon: tubos de luz sobre um fundo escuro com uma grelha em perspetiva a correr ao fundo;
## cada peça brilha na sua cor, a sombra é só um contorno, e as linhas completas explodem em
## faíscas. Música de sintetizador com bateria.

const COLS := [Color("ff3ea5"), Color("ffe14d"), Color("a46bff"), Color("3effa0"), Color("ff6a3e"), Color("3e8bff"), Color("3ef0ff")]
const FRAME := Color("3ef0ff")

var font: Font


func _setup() -> void:
	font = ThemeDB.fallback_font


func _build_sfx() -> void:
	sfx.move = Synth.tone(900.0, 0.02, {"wave": "sine", "volume": 0.12, "decay": 60.0})
	sfx.rotate = Synth.tone(1400.0, 0.04, {"wave": "triangle", "freq_end": 1900.0, "volume": 0.12, "decay": 30.0})
	sfx.lock = Synth.tone(160.0, 0.08, {"wave": "sine", "freq_end": 90.0, "volume": 0.35, "decay": 25.0})
	sfx.drop = Synth.to_stream(Synth.mix([Synth.render(0.0, 0.15, {"wave": "noise", "volume": 0.18, "lowpass": 0.3, "decay": 20.0}), Synth.render(120.0, 0.15, {"wave": "sine", "freq_end": 50.0, "volume": 0.4, "decay": 14.0})]))
	sfx.hold = Synth.tone(600.0, 0.1, {"wave": "saw", "freq_end": 1200.0, "volume": 0.08, "lowpass": 0.3})
	sfx.clear = Synth.tone(400.0, 0.35, {"wave": "saw", "freq_end": 1600.0, "volume": 0.1, "lowpass": 0.35, "decay": 5.0})
	sfx.quad = Synth.to_stream(Synth.mix([Synth.render(300.0, 0.8, {"wave": "saw", "freq_end": 2400.0, "volume": 0.1, "lowpass": 0.35, "decay": 3.0}), Synth.render(0.0, 0.6, {"wave": "noise", "volume": 0.12, "lowpass": 0.5, "decay": 5.0})]))
	sfx.level = Synth.concat([Synth.render(523.0, 0.1, {"wave": "saw", "volume": 0.08, "lowpass": 0.3}), Synth.render(784.0, 0.1, {"wave": "saw", "volume": 0.08, "lowpass": 0.3}), Synth.render(1046.0, 0.25, {"wave": "saw", "volume": 0.08, "lowpass": 0.3, "decay": 4.0})])
	sfx.over = Synth.tone(600.0, 1.2, {"wave": "saw", "freq_end": 60.0, "volume": 0.12, "lowpass": 0.25})


func music_variant() -> int:
	return 1


func piece_color(k: int) -> Color:
	return COLS[k]


func _draw_back() -> void:
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)]),
		PackedColorArray([Color("0a0618"), Color("0a0618"), Color("1e0a30"), Color("1e0a30")]))
	# grelha em perspetiva no chão
	var hz := 470.0
	var c := Color("ff3ea5", 0.25)
	for k in 13:
		var x := -600.0 + k * 210.0
		draw_line(Vector2(640 + (x - 640) * 0.15, hz), Vector2(x, 720), c, 1.5)
	var f := fmod(time * 0.6, 1.0)
	for k in 8:
		var t := (k + f) / 8.0
		var y := hz + (720.0 - hz) * t * t
		draw_line(Vector2(0, y), Vector2(1280, y), Color(c, c.a * t), 1.5)
	draw_line(Vector2(0, hz), Vector2(1280, hz), Color("ff3ea5", 0.5), 2.0)


func _glow_rect(r: Rect2, c: Color, w: float) -> void:
	for k in 3:
		draw_rect(r.grow(k * 2.5), Color(c, 0.18 - k * 0.05), false, w + k * 3.0)
	draw_rect(r, c, false, w)


func _draw_well(r: Rect2) -> void:
	draw_rect(r, Color(0.02, 0.01, 0.06, 0.85))
	for x in range(1, BlocksGame.COLS):
		draw_line(Vector2(r.position.x + x * CELL, r.position.y), Vector2(r.position.x + x * CELL, r.end.y), Color(FRAME, 0.05), 1.0)
	for y in range(1, BlocksGame.ROWS - BlocksGame.HIDDEN):
		draw_line(Vector2(r.position.x, r.position.y + y * CELL), Vector2(r.end.x, r.position.y + y * CELL), Color(FRAME, 0.05), 1.0)


func _draw_well_front(r: Rect2) -> void:
	_glow_rect(r.grow(3), FRAME, 2.5)


func draw_block(r: Rect2, k: int, style: int) -> void:
	var c: Color = COLS[k]
	var rr := r.grow(-2)
	match style:
		1:
			draw_rect(rr.grow(-2), Color(c, 0.5), false, 2.0)
			return
		3:
			c = Color(c.darkened(0.5), 0.6)
	draw_rect(rr.grow(3), Color(c, 0.12))
	draw_rect(rr, Color(c.darkened(0.55), 0.9))
	draw_rect(rr.grow(-3), Color(c, 0.35))
	draw_rect(rr, c, false, 2.0)
	draw_rect(Rect2(rr.position + Vector2(3, 3), Vector2(rr.size.x * 0.35, 3)), Color(1, 1, 1, 0.6))


func _draw_clearing(r: int, t: float) -> void:
	var y := cell_rect(0, r).position.y
	var w := WELL.size.x * (1.0 - t)
	var rr := Rect2(WELL.get_center().x - w * 0.5, y + 2, w, CELL - 4)
	draw_rect(rr.grow(4), Color(1, 1, 1, 0.2 * (1.0 - t)))
	draw_rect(rr, Color(1, 1, 1, 0.9 * (1.0 - t)))


func _draw_box(r: Rect2, title: String) -> void:
	draw_rect(r, Color(0.02, 0.01, 0.06, 0.8))
	_glow_rect(r, Color("ff3ea5"), 2.0)
	label(title, Vector2(r.get_center().x, r.position.y + 6), 16.0, false)


func label(text: String, p: Vector2, size: float, big: bool, alpha := 1.0) -> void:
	var s := int(size)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x
	var pos := Vector2(p.x - w * 0.5, p.y + s)
	var c := Color("ffffff") if big else Color("3ef0ff")
	if big:
		for o: Vector2 in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
			draw_string(font, pos + o, text, HORIZONTAL_ALIGNMENT_LEFT, -1, s, Color("ff3ea5", 0.35 * alpha))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, s, Color(c, alpha))


func _draw_part(p: Dictionary) -> void:
	if p.has("trail"):
		var r := Rect2(p.pos.x - CELL * 0.4, p.pos.y - p.trail, CELL * 0.8, p.trail)
		draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
			PackedColorArray([Color(COLS[p.kind], 0.0), Color(COLS[p.kind], 0.0), Color(COLS[p.kind], p.life * 1.6), Color(COLS[p.kind], p.life * 1.6)]))
		return
	var a := clampf(p.life * 2.0, 0.0, 1.0)
	var c: Color = COLS[p.kind]
	draw_line(p.pos, p.pos - p.vel * 0.03, Color(c, a), 3.0)
	draw_circle(p.pos, 2.5, Color(1, 1, 1, a))


func _draw_over() -> void:
	draw_rect(WELL, Color(0, 0, 0, 0.6))
	label(I18n.t("FIM DE JOGO"), Vector2(WELL.get_center().x, WELL.get_center().y - 30), 40.0, true)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.04, 0.02, 0.1, 0.94),
		"border": Color("ff3ea5"),
		"text": Color("e8f8ff"),
		"accent": Color("3ef0ff"),
		"button": Color(0.12, 0.05, 0.2),
		"button_hover": Color(0.25, 0.08, 0.35),
		"radius": 6,
		"dim": Color(0, 0, 0, 0.45),
	}
