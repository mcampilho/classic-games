extends BlocksSkin
## Brinquedo de Madeira: peças de madeira pintada, com arestas boleadas e veios, a cair numa
## caixa de faia sobre uma mesa de quarto de brincar. A sombra é um contorno a lápis; as linhas
## completas saltam em lascas. Sons de madeira e marimba; música de caixinha de música.

const PAINT := [Color("d8584a"), Color("e8b84a"), Color("8a6ab0"), Color("6aa85a"), Color("e0803a"), Color("4a78b8"), Color("4aa8a8")]
const BEECH := Color("e2bc88")
const BEECH_DARK := Color("b88a58")
const INSIDE := Color("5a3e2a")
const INK := Color("4a3020")

var font: Font
var _boxes: Array[StyleBoxFlat] = []
var _shadow: StyleBoxFlat


func _setup() -> void:
	font = ThemeDB.fallback_font
	for c: Color in PAINT:
		var sb := StyleBoxFlat.new()
		sb.bg_color = c
		sb.set_corner_radius_all(5)
		sb.border_color = c.darkened(0.25)
		sb.set_border_width_all(0)
		sb.border_width_bottom = 3
		sb.border_width_right = 2
		_boxes.append(sb)
	_shadow = StyleBoxFlat.new()
	_shadow.bg_color = Color(0, 0, 0, 0.25)
	_shadow.set_corner_radius_all(5)


func _build_sfx() -> void:
	sfx.move = Synth.tone(700.0, 0.03, {"wave": "sine", "volume": 0.15, "decay": 80.0})
	sfx.rotate = Synth.tone(1100.0, 0.05, {"wave": "triangle", "volume": 0.15, "decay": 60.0})
	sfx.lock = Synth.to_stream(Synth.mix([Synth.render(220.0, 0.12, {"wave": "sine", "volume": 0.4, "decay": 35.0}), Synth.render(0.0, 0.05, {"wave": "noise", "volume": 0.12, "lowpass": 0.3, "decay": 60.0})]))
	sfx.drop = Synth.to_stream(Synth.mix([Synth.render(150.0, 0.2, {"wave": "sine", "volume": 0.5, "decay": 25.0}), Synth.render(0.0, 0.08, {"wave": "noise", "volume": 0.2, "lowpass": 0.25, "decay": 40.0})]))
	sfx.hold = Synth.tone(500.0, 0.08, {"wave": "sine", "freq_end": 800.0, "volume": 0.2, "decay": 30.0})
	var a := []
	for f in [523.0, 659.0, 784.0]:
		a.append(Synth.render(f, 0.09, {"wave": "sine", "volume": 0.25, "decay": 18.0}))
	sfx.clear = Synth.concat(a)
	var q := []
	for f in [523.0, 659.0, 784.0, 1046.0, 1318.0, 1568.0]:
		q.append(Synth.render(f, 0.08, {"wave": "sine", "volume": 0.25, "decay": 14.0}))
	sfx.quad = Synth.concat(q)
	sfx.level = Synth.concat([Synth.render(784.0, 0.1, {"wave": "sine", "volume": 0.25, "decay": 10.0}), Synth.render(1046.0, 0.2, {"wave": "sine", "volume": 0.25, "decay": 8.0})])
	var o := []
	for f in [392.0, 330.0, 262.0, 196.0]:
		o.append(Synth.render(f, 0.2, {"wave": "sine", "volume": 0.25, "decay": 6.0}))
	sfx.over = Synth.concat(o)


func music_variant() -> int:
	return 2


func piece_color(k: int) -> Color:
	return PAINT[k]


func _draw_back() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("f2e6cc"))
	# papel de parede às riscas com florzinhas
	for x in range(0, 1280, 64):
		draw_rect(Rect2(x, 0, 30, 720), Color("ecdcbc"))
	for y in range(40, 720, 120):
		for x in range(47, 1280, 128):
			var o := Vector2(x + (64 if (y / 120) % 2 == 1 else 0), y)
			for k in 5:
				draw_circle(o + Vector2.from_angle(k * TAU / 5.0) * 5.0, 3.5, Color("e8b8a0", 0.6))
			draw_circle(o, 2.5, Color("e8c870", 0.8))
	# tampo da mesa
	draw_rect(Rect2(0, 676, 1280, 44), Color("c08a5a"))
	for k in 5:
		draw_line(Vector2(0, 684 + k * 8), Vector2(1280, 682 + k * 8 + sin(k) * 3.0), Color("a87448", 0.6), 1.5)


func _wood_frame(r: Rect2, t: float) -> void:
	var outer := r.grow(t)
	draw_rect(Rect2(outer.position + Vector2(6, 8), outer.size), Color(0, 0, 0, 0.18))
	draw_rect(outer, BEECH)
	for k in int(outer.size.y / 9.0):
		var y := outer.position.y + k * 9.0 + 4.0
		draw_line(Vector2(outer.position.x + 2, y), Vector2(outer.position.x + t - 2, y + 3), Color(BEECH_DARK, 0.35), 1.0)
		draw_line(Vector2(outer.end.x - t + 2, y), Vector2(outer.end.x - 2, y + 3), Color(BEECH_DARK, 0.35), 1.0)
	for k in int(outer.size.x / 11.0):
		var x := outer.position.x + k * 11.0
		draw_line(Vector2(x, outer.end.y - t + 3), Vector2(x + 6, outer.end.y - 3), Color(BEECH_DARK, 0.3), 1.0)
	draw_rect(outer, BEECH_DARK, false, 2.0)
	draw_rect(r, INSIDE)
	draw_rect(r, BEECH_DARK.darkened(0.3), false, 2.0)


func _draw_well(r: Rect2) -> void:
	_wood_frame(r, 16.0)
	for k in 12:
		var y := r.position.y + k * 52.0 + 10.0
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y + 8), Color(0, 0, 0, 0.08), 3.0)


func draw_block(r: Rect2, k: int, style: int) -> void:
	var rr := r.grow(-1.5)
	if style == 1:
		# contorno a lápis
		draw_rect(rr.grow(-2), Color("f2e6cc", 0.55), false, 2.0)
		return
	var sb: StyleBoxFlat = _boxes[k]
	if style == 3:
		sb = sb.duplicate()
		sb.bg_color = sb.bg_color.lerp(Color("9a8a78"), 0.7)
	if style != 2 and style != 3:
		draw_style_box(_shadow, Rect2(rr.position + Vector2(2, 3), rr.size))
	draw_style_box(sb, rr)
	# brilho e veios
	draw_rect(Rect2(rr.position + Vector2(4, 3), Vector2(rr.size.x - 8, 3)), Color(1, 1, 1, 0.3))
	var seed := int(r.position.x * 7 + r.position.y * 13) % 5
	for g in 2:
		var y := rr.position.y + rr.size.y * (0.35 + g * 0.3) + seed - 2
		draw_line(Vector2(rr.position.x + 4, y), Vector2(rr.end.x - 5, y + 1.5), Color(0, 0, 0, 0.12), 1.0)


func _draw_clearing(r: int, t: float) -> void:
	for c in BlocksGame.COLS:
		var k := game.board[r * BlocksGame.COLS + c] - 1
		var rr := cell_rect(c, r)
		var bounce := sin(t * PI) * 10.0 * (1.0 if c % 2 == 0 else 0.6)
		var s := 1.0 - t * 0.6
		var cr := Rect2(rr.get_center() - rr.size * s * 0.5 - Vector2(0, bounce), rr.size * s)
		draw_block(cr, maxi(k, 0), 0)


func _draw_box(r: Rect2, title: String) -> void:
	_wood_frame(r.grow(-8), 8.0)
	draw_rect(r.grow(-8), Color("6a4a32"))
	label(title, Vector2(r.get_center().x, r.position.y - 26), 17.0, false)


func label(text: String, p: Vector2, size: float, big: bool, alpha := 1.0) -> void:
	var s := int(size)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x
	var pos := Vector2(p.x - w * 0.5, p.y + s)
	if big:
		draw_string(font, pos + Vector2(1, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, s, Color(1, 1, 1, 0.6 * alpha))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, s, Color(INK if big else INK.lightened(0.25), alpha))


func _draw_popup(text: String, y: float, a: float) -> void:
	var s := 26
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x
	var r := Rect2(WELL.get_center().x - w * 0.5 - 12, y - 4, w + 24, 40)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fff4dc", a * 0.95)
	sb.set_corner_radius_all(10)
	draw_style_box(sb, r)
	label(text, Vector2(WELL.get_center().x, y - 2), 26.0, true, a)


func _draw_part(p: Dictionary) -> void:
	if p.has("trail"):
		return
	var a := clampf(p.life * 2.0, 0.0, 1.0)
	var c: Color = PAINT[p.kind]
	var d: Vector2 = p.vel.normalized() * p.size
	draw_line(p.pos - d, p.pos + d, Color(c, a), 4.0)
	draw_line(p.pos - d * 0.6, p.pos + d * 0.6, Color(BEECH, a), 1.5)


func _draw_over() -> void:
	draw_rect(WELL, Color("2a1a10", 0.6))
	_draw_popup(I18n.t("FIM DE JOGO"), WELL.get_center().y - 30, 1.0)


func ui_palette() -> Dictionary:
	return {
		"panel": Color("f6ead2", 0.97),
		"border": BEECH_DARK,
		"text": INK,
		"accent": Color("d8584a"),
		"button": Color("ecd6b0"),
		"button_hover": Color("e8c890"),
		"radius": 10,
		"dim": Color(0.2, 0.12, 0.05, 0.35),
	}
