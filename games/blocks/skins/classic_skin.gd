extends BlocksSkin
## Clássico 1984: o ecrã de texto verde dos terminais dos anos 80 — o poço desenhado com
## caracteres "<!" e "!>", peças feitas de pares de parênteses retos "[ ]", pontinhos nas casas
## vazias, letras de terminal, linhas de varrimento e o brilho do fósforo. Sons de altifalante.

const GREEN := Color("39ff6a")
const DIM := Color("1a7a34")
const DARK := Color("0b2412")


func _build_sfx() -> void:
	sfx.move = Synth.tone(1800.0, 0.012, {"wave": "square", "volume": 0.05})
	sfx.rotate = Synth.tone(2400.0, 0.018, {"wave": "square", "volume": 0.05})
	sfx.lock = Synth.tone(300.0, 0.04, {"wave": "square", "volume": 0.08})
	sfx.drop = Synth.tone(600.0, 0.08, {"wave": "square", "freq_end": 150.0, "volume": 0.08})
	sfx.hold = Synth.tone(1200.0, 0.05, {"wave": "square", "freq_end": 1600.0, "volume": 0.06})
	sfx.clear = Synth.concat([Synth.render(880.0, 0.05, {"wave": "square", "volume": 0.07}), Synth.render(1320.0, 0.05, {"wave": "square", "volume": 0.07}), Synth.render(1760.0, 0.08, {"wave": "square", "volume": 0.07})])
	var q := []
	for f in [880.0, 1108.0, 1320.0, 1760.0, 1320.0, 1760.0]:
		q.append(Synth.render(f, 0.06, {"wave": "square", "volume": 0.07}))
	sfx.quad = Synth.concat(q)
	sfx.level = Synth.concat([Synth.render(660.0, 0.08, {"wave": "square", "volume": 0.07}), Synth.render(990.0, 0.12, {"wave": "square", "volume": 0.07})])
	var o := []
	for f in [440.0, 392.0, 349.0, 330.0, 220.0]:
		o.append(Synth.render(f, 0.14, {"wave": "square", "volume": 0.07}))
	sfx.over = Synth.concat(o)


func music_variant() -> int:
	return 0


func piece_color(_k: int) -> Color:
	return GREEN


func _draw_back() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("030a05"))


func _txt(text: String, x: float, y: float, cell: float, c: Color) -> void:
	PixelFont.draw(self, text, x, y, cell, Color(c, c.a * 0.25))
	PixelFont.draw(self, text, x + 0.5, y + 0.5, cell, c)


func _draw_well(r: Rect2) -> void:
	for row in BlocksGame.ROWS - BlocksGame.HIDDEN:
		var y := r.position.y + row * CELL + 4
		_txt("<!", r.position.x - 22, y, 3.0, GREEN)
		_txt("!>", r.end.x + 22, y, 3.0, GREEN)
		for c in BlocksGame.COLS:
			draw_rect(Rect2(r.position.x + c * CELL + 18, y + 16, 3, 3), DIM)
	var by := r.end.y + 4
	_txt("<!" + "=".repeat(20) + "!>", r.get_center().x, by, 3.0, GREEN)
	# \/\/\/\/
	for k in 10:
		var x := r.position.x + k * CELL + 4
		draw_line(Vector2(x, by + 28), Vector2(x + 11, by + 50), GREEN, 3.0)
		draw_line(Vector2(x + 11, by + 50), Vector2(x + 22, by + 28), GREEN, 3.0)


func draw_block(r: Rect2, _k: int, style: int) -> void:
	var c := GREEN
	match style:
		1:
			c = Color(GREEN, 0.28)
		3:
			c = DIM
	var w := maxf(r.size.x * 0.1, 2.0)
	var h := r.size.y
	var top := r.position.y + h * 0.12
	var hh := h * 0.76
	# "["
	var lx := r.position.x + r.size.x * 0.1
	draw_rect(Rect2(lx, top, w, hh), c)
	draw_rect(Rect2(lx, top, w * 2.2, w), c)
	draw_rect(Rect2(lx, top + hh - w, w * 2.2, w), c)
	# "]"
	var rx := r.end.x - r.size.x * 0.1 - w
	draw_rect(Rect2(rx, top, w, hh), c)
	draw_rect(Rect2(rx - w * 1.2, top, w * 2.2, w), c)
	draw_rect(Rect2(rx - w * 1.2, top + hh - w, w * 2.2, w), c)
	if style == 0:
		draw_rect(r.grow(-1), Color(GREEN, 0.06))


func _draw_clearing(r: int, t: float) -> void:
	var on := int(t * 8.0) % 2 == 0
	var rr := Rect2(WELL.position.x, cell_rect(0, r).position.y, WELL.size.x, CELL)
	if on:
		draw_rect(rr, Color(GREEN, 0.85))
	else:
		for c in BlocksGame.COLS:
			draw_block(cell_rect(c, r), 0, 0)


func _draw_box(r: Rect2, title: String) -> void:
	_txt(title, r.get_center().x, r.position.y - 4, 2.5, GREEN)
	var y := r.position.y + 18
	var rr := r.grow(-12)
	for k in int((rr.size.x) / 14.0) + 1:
		draw_rect(Rect2(rr.position.x + k * 14, y, 8, 2), DIM)
		draw_rect(Rect2(rr.position.x + k * 14, r.end.y, 8, 2), DIM)


func label(text: String, p: Vector2, size: float, big: bool, alpha := 1.0) -> void:
	_txt(text, p.x, p.y, size / 7.0, Color(GREEN if big else DIM.lightened(0.3), alpha))


func _draw_part(p: Dictionary) -> void:
	if p.has("trail"):
		draw_rect(Rect2(p.pos.x - 2, p.pos.y - p.trail, 4, p.trail), Color(GREEN, p.life))
		return
	PixelFont.draw(self, "*", p.pos.x, p.pos.y, 2.0, Color(GREEN, clampf(p.life * 2.0, 0.0, 1.0)))


func _draw_over() -> void:
	draw_rect(WELL, Color(0, 0, 0, 0.7))
	_txt(I18n.t("FIM DO JOGO"), WELL.get_center().x, WELL.get_center().y - 20, 3.5, GREEN)


func _draw_front() -> void:
	var y := 0.0
	while y < 720.0:
		draw_line(Vector2(0, y), Vector2(1280, y), Color(0, 0, 0, 0.22), 1.0)
		y += 3.0
	# borda arredondada do ecrã de tubo
	for k in 6:
		draw_rect(Rect2(k * 4, k * 4, 1280 - k * 8, 720 - k * 8), Color(0, 0, 0, 0.12), false, 8.0)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.01, 0.05, 0.02, 0.95),
		"border": GREEN,
		"text": GREEN,
		"accent": GREEN,
		"button": Color("0b2412"),
		"button_hover": Color("17482a"),
		"radius": 0,
		"dim": Color(0, 0, 0, 0.5),
	}
