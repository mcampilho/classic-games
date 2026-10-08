extends FlockSkin
## Clássico 1991: o aspeto dos puzzles de computador de 16 bits — fundo negro, terra rosada e
## granulada com relva por cima, placas de aço rebitadas, ovelhas de poucos píxeis, um alçapão de
## madeira de onde caem e um celeiro vermelho com tochas. Painel azul com números verdes.

const EARTH_COLS := [Color("a0522d"), Color("b8653a"), Color("8a4628"), Color("c87a4a")]
const GRASS := [Color("3aa83a"), Color("2a8a2a")]
const STEEL_COLS := [Color("8a8aa0"), Color("6a6a80"), Color("b0b0c8")]
const BRICK := Color("e8c890")
const BRICK2 := Color("c8a060")


func _setup() -> void:
	make_frames({"W": Color("f0f0f0"), "w": Color("b8b8c8"), "F": Color("7a5440"), "E": Color("f0f0f0"), "L": Color("a0a0b0")}, Color(0, 0, 0, 0), 4)


func _build_sfx() -> void:
	sfx.start = Synth.concat([Synth.render(523.0, 0.1, {"wave": "square", "volume": 0.08}), Synth.render(659.0, 0.1, {"wave": "square", "volume": 0.08}), Synth.render(784.0, 0.2, {"wave": "square", "volume": 0.08})])
	sfx.release = Synth.tone(520.0, 0.18, {"wave": "square", "freq_end": 460.0, "volume": 0.05, "lowpass": 0.3})
	sfx.assign = Synth.tone(1200.0, 0.04, {"wave": "square", "volume": 0.07})
	sfx.saved = Synth.concat([Synth.render(880.0, 0.06, {"wave": "square", "volume": 0.06}), Synth.render(1320.0, 0.1, {"wave": "square", "volume": 0.06})])
	sfx.splat = Synth.tone(0.0, 0.2, {"wave": "noise", "volume": 0.25, "lowpass": 0.15, "decay": 15.0})
	sfx.fall = Synth.tone(900.0, 0.5, {"wave": "square", "freq_end": 120.0, "volume": 0.06})
	sfx.brick = Synth.tone(0.0, 0.03, {"wave": "noise", "volume": 0.1, "lowpass": 0.5, "decay": 60.0})
	var ok := []
	for f in [523.0, 659.0, 784.0, 1046.0]:
		ok.append(Synth.render(f, 0.14, {"wave": "square", "volume": 0.08, "lowpass": 0.5}))
	sfx.success = Synth.concat(ok)
	sfx.fail = Synth.concat([Synth.render(392.0, 0.2, {"wave": "square", "volume": 0.08, "lowpass": 0.4}), Synth.render(330.0, 0.2, {"wave": "square", "volume": 0.08, "lowpass": 0.4}), Synth.render(262.0, 0.4, {"wave": "square", "volume": 0.08, "lowpass": 0.4})])
	var w := []
	for f in [523.0, 659.0, 784.0, 659.0, 784.0, 1046.0]:
		w.append(Synth.render(f, 0.16, {"wave": "square", "volume": 0.08, "lowpass": 0.5}))
	sfx.win = Synth.concat(w)


func _draw_back() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color.BLACK)


func terrain_color(x: int, y: int, kind: int, top: int, edge: bool) -> Color:
	match kind:
		FlockGame.STEEL:
			var bx := x % 8
			var by := y % 8
			if bx == 0 or by == 0:
				return STEEL_COLS[1]
			if (bx == 2 and by == 2) or (bx == 6 and by == 6):
				return STEEL_COLS[2]
			return STEEL_COLS[0]
		FlockGame.BRICK:
			return BRICK2 if top == 0 or edge else BRICK
	if top <= 1:
		return GRASS[int(hash01(x, y) * 2.0) % 2]
	var n := hash01(x / 2, y / 2, 7)
	var c: Color = EARTH_COLS[int(n * 4.0) % 4]
	if edge:
		c = c.darkened(0.25)
	return c


func _draw_entrance(p: Vector2, open: float) -> void:
	var top := p.y - 70.0
	var r := Rect2(p.x - 48, top, 96, 26)
	draw_rect(r, Color("6a4428"))
	for k in 4:
		draw_line(Vector2(r.position.x, top + 6 + k * 6), Vector2(r.end.x, top + 6 + k * 6), Color("4a2e18"), 2.0)
	draw_rect(r, Color("a07040"), false, 3.0)
	# portas do alçapão a abrir para baixo
	var ang := open * PI * 0.45
	var hinge_l := Vector2(r.position.x + 8, r.end.y)
	var hinge_r := Vector2(r.end.x - 8, r.end.y)
	draw_line(hinge_l, hinge_l + Vector2.from_angle(ang) * 40, Color("c89050"), 6.0)
	draw_line(hinge_r, hinge_r + Vector2.from_angle(PI - ang) * 40, Color("c89050"), 6.0)


func _draw_exit_back(p: Vector2) -> void:
	var base := p + Vector2(2, 4)
	var body := PackedVector2Array([base + Vector2(-44, 0), base + Vector2(-44, -52), base + Vector2(0, -80), base + Vector2(44, -52), base + Vector2(44, 0)])
	draw_colored_polygon(body, Color("b02a2a"))
	for k in 6:
		var x := base.x - 40 + k * 16
		draw_line(Vector2(x, base.y - 50), Vector2(x, base.y), Color("8a1e1e"), 2.0)
	draw_rect(Rect2(base + Vector2(-16, -40), Vector2(32, 40)), Color("1a0a0a"))
	draw_line(base + Vector2(-16, -40), base + Vector2(16, 0), Color("f0f0f0"), 3.0)
	draw_line(base + Vector2(16, -40), base + Vector2(-16, 0), Color("f0f0f0"), 3.0)
	draw_rect(Rect2(base + Vector2(-16, -40), Vector2(32, 40)), Color("f0f0f0"), false, 3.0)
	var roof := PackedVector2Array([base + Vector2(-50, -50), base + Vector2(0, -84), base + Vector2(50, -50)])
	draw_polyline(roof, Color("5a3a2a"), 6.0)
	for k in 2:
		var tp := base + Vector2(-56 + k * 112, -30)
		draw_line(tp, tp + Vector2(0, 30), Color("6a4428"), 4.0)
		var fl := 6.0 + sin(time * 14.0 + k * 2.0) * 2.0
		draw_circle(tp + Vector2(0, -4), fl, Color("f0a020"))
		draw_circle(tp + Vector2(0, -3), fl * 0.5, Color("fff080"))


func wool_color() -> Color:
	return Color("f0f0f0")


func saved_colors() -> Array:
	return [Color("fff080"), Color("f0a020"), Color.WHITE]


func panel_palette() -> Dictionary:
	return {"bg": Color("10102a"), "button": Color("2a3060"), "button_on": Color("5060a8"), "border": Color("8090d0"),
		"icon": Color("e8e8f0"), "icon_dim": Color(0.6, 0.6, 0.75, 0.35), "count": Color("40e040"), "accent": Color("40e040"),
		"status_bg": Color(0, 0, 0, 0.0), "status_text": Color("40e040"), "cursor": Color.WHITE}


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0.04, 0.04, 0.12, 0.94),
		"border": Color("8090d0"),
		"text": Color("e8e8f0"),
		"accent": Color("40e040"),
		"button": Color("2a3060"),
		"button_hover": Color("3a4488"),
		"radius": 2,
		"dim": Color(0, 0, 0, 0.45),
	}
