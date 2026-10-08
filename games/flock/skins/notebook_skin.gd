extends FlockSkin
## Bloco de Notas: o nível é um rabisco a lápis numa folha pautada — terreno sombreado com
## tracejado de grafite, aço riscado a esferográfica azul, tijolos a caneta vermelha, ovelhas
## desenhadas como nuvenzinhas com contorno tremido (a "ferver", como nos desenhos animados
## feitos à mão) e um painel de botões rabiscados, com a função escolhida rodeada a vermelho.

const PAPER := Color("f6f1e2")
const RULE := Color("9cc0e0")
const MARGIN := Color("e08080")
const PENCIL := Color("4a4a52")
const BLUE := Color("2a4ab0")
const RED := Color("c83030")


func _setup() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _build_sfx() -> void:
	# assobios (seno) e riscos de lápis (ruído filtrado)
	sfx.start = Synth.concat([Synth.render(784.0, 0.1, {"wave": "sine", "volume": 0.25}), Synth.render(988.0, 0.1, {"wave": "sine", "volume": 0.25}), Synth.render(1175.0, 0.2, {"wave": "sine", "volume": 0.25, "decay": 6.0})])
	sfx.release = Synth.tone(1400.0, 0.12, {"wave": "sine", "freq_end": 1000.0, "volume": 0.15})
	sfx.assign = Synth.tone(0.0, 0.07, {"wave": "noise", "volume": 0.25, "lowpass": 0.6, "decay": 30.0})
	sfx.saved = Synth.concat([Synth.render(1046.0, 0.07, {"wave": "sine", "volume": 0.22}), Synth.render(1568.0, 0.12, {"wave": "sine", "volume": 0.22, "decay": 10.0})])
	sfx.splat = Synth.tone(0.0, 0.3, {"wave": "noise", "volume": 0.35, "lowpass": 0.25, "decay": 10.0})
	sfx.fall = Synth.tone(1600.0, 0.6, {"wave": "sine", "freq_end": 300.0, "volume": 0.18})
	sfx.brick = Synth.tone(0.0, 0.05, {"wave": "noise", "volume": 0.15, "lowpass": 0.8, "decay": 40.0})
	var ok := []
	for f in [784.0, 988.0, 1175.0, 1568.0]:
		ok.append(Synth.render(f, 0.13, {"wave": "sine", "volume": 0.22, "decay": 5.0}))
	sfx.success = Synth.concat(ok)
	sfx.fail = Synth.concat([Synth.render(988.0, 0.2, {"wave": "sine", "volume": 0.2, "freq_end": 900.0}), Synth.render(740.0, 0.4, {"wave": "sine", "volume": 0.2, "freq_end": 620.0})])
	var w := []
	for f in [784.0, 988.0, 1175.0, 988.0, 1175.0, 1568.0]:
		w.append(Synth.render(f, 0.14, {"wave": "sine", "volume": 0.22, "decay": 4.0}))
	sfx.win = Synth.concat(w)


## Semente que muda algumas vezes por segundo: o traço "ferve".
func boil(id: int) -> int:
	return id * 31 + int(time * 6.0)


## Linha tremida a lápis (dois traços ligeiramente desencontrados).
func sk_line(a: Vector2, b: Vector2, col: Color, w: float, seed: int) -> void:
	for k in 2:
		var j1 := Vector2(hash01(seed, k, 1) - 0.5, hash01(seed, k, 2) - 0.5) * 3.0
		var j2 := Vector2(hash01(seed, k, 3) - 0.5, hash01(seed, k, 4) - 0.5) * 3.0
		var m := (a + b) * 0.5 + Vector2(hash01(seed, k, 5) - 0.5, hash01(seed, k, 6) - 0.5) * 3.0
		draw_polyline(PackedVector2Array([a + j1, m, b + j2]), Color(col, col.a * (1.0 if k == 0 else 0.5)), w if k == 0 else w * 0.6)


func sk_rect(r: Rect2, col: Color, w: float, seed: int) -> void:
	var p := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for k in 4:
		var a: Vector2 = p[k]
		var b: Vector2 = p[(k + 1) % 4]
		var d := (b - a).normalized() * 4.0
		sk_line(a - d, b + d, col, w, seed + k * 7)


## Contorno tremido de uma elipse.
func sk_oval(c: Vector2, r: Vector2, col: Color, w: float, seed: int, fill := Color(0, 0, 0, 0)) -> void:
	var pts := PackedVector2Array()
	var n := 14
	for i in n:
		var a := TAU * i / n
		var j := 1.0 + (hash01(seed, i, 9) - 0.5) * 0.18
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y) * j)
	if fill.a > 0.0:
		draw_colored_polygon(pts, fill)
	pts.append(pts[0] + (pts[1] - pts[0]) * 0.4)
	draw_polyline(pts, col, w)


func _draw_back() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), PAPER)
	var y := 50.0
	while y < 600.0:
		draw_line(Vector2(0, y), Vector2(1280, y), RULE, 1.5)
		y += 26.0
	draw_line(Vector2(84, 0), Vector2(84, 600), MARGIN, 2.0)
	draw_line(Vector2(89, 0), Vector2(89, 600), Color(MARGIN, 0.5), 1.0)
	for k in 3:
		var hy := 120.0 + k * 180.0
		draw_circle(Vector2(36, hy), 13, Color("e4ddc8"))
		draw_arc(Vector2(36, hy), 13, 0, TAU, 20, Color("c8bea4"), 1.5)


func terrain_color(x: int, y: int, kind: int, top: int, edge: bool) -> Color:
	match kind:
		FlockGame.STEEL:
			if edge or top == 0:
				return Color(BLUE, 0.95)
			if (x + y) % 3 == 0 or (x - y + 300) % 3 == 0:
				return Color(BLUE, 0.6)
			return Color(BLUE, 0.1)
		FlockGame.BRICK:
			if edge or top == 0:
				return Color(RED, 0.95)
			return Color(RED, 0.35)
	if top == 0 or edge:
		return Color(PENCIL, 0.92)
	var n := hash01(x, y, 3)
	if (x + y) % 4 == 0:
		return Color(PENCIL, 0.45 + n * 0.2)
	if top <= 2:
		return Color(PENCIL, 0.3)
	return Color(PENCIL, 0.06 + n * 0.06)


func _draw_entrance(p: Vector2, open: float) -> void:
	var r := Rect2(p.x - 46, p.y - 76, 92, 30)
	draw_rect(r, Color(PAPER, 0.8))
	sk_rect(r, PENCIL, 2.0, 11)
	for k in 5:
		sk_line(Vector2(r.position.x + 10 + k * 18, r.position.y + 4), Vector2(r.position.x + 2 + k * 18, r.end.y - 4), Color(PENCIL, 0.5), 1.5, 40 + k)
	var ang := open * PI * 0.45
	sk_line(Vector2(r.position.x + 6, r.end.y), Vector2(r.position.x + 6, r.end.y) + Vector2.from_angle(ang) * 36, PENCIL, 2.5, 51)
	sk_line(Vector2(r.end.x - 6, r.end.y), Vector2(r.end.x - 6, r.end.y) + Vector2.from_angle(PI - ang) * 36, PENCIL, 2.5, 52)


func _draw_exit_back(p: Vector2) -> void:
	var b := p + Vector2(2, 4)
	var pts := PackedVector2Array([b + Vector2(-42, 0), b + Vector2(-42, -48), b + Vector2(0, -78), b + Vector2(42, -48), b + Vector2(42, 0)])
	draw_colored_polygon(pts, Color(PAPER, 0.9))
	for k in 4:
		sk_line(pts[k], pts[k + 1], PENCIL, 2.5, 60 + k)
	# telhado a vermelho
	sk_line(b + Vector2(-50, -42), b + Vector2(0, -84), RED, 3.0, 70)
	sk_line(b + Vector2(0, -84), b + Vector2(50, -42), RED, 3.0, 71)
	var door := Rect2(b + Vector2(-15, -38), Vector2(30, 38))
	draw_rect(door, Color(PENCIL, 0.75))
	sk_rect(door, PENCIL, 2.0, 72)
	# bandeirinha
	sk_line(b + Vector2(0, -84), b + Vector2(0, -112), PENCIL, 2.0, 73)
	var wave := sin(time * 5.0) * 3.0
	draw_colored_polygon(PackedVector2Array([b + Vector2(0, -112), b + Vector2(22, -106 + wave), b + Vector2(0, -98)]), Color(RED, 0.8))


func _draw_sheep(s: Dictionary, p: Vector2, hov: bool) -> void:
	var job: int = s.job
	var d := float(s.dir)
	var id: int = s.id
	var sd := boil(id)
	var a := 1.0
	if job == FlockGame.Job.EXIT:
		a = 1.0 - clampf(float(s.t) / 8.0, 0.0, 1.0)
	var ink := Color(PENCIL, a)
	var fill := Color(PAPER, a)
	if job == FlockGame.Job.SPLAT:
		sk_oval(p + Vector2(0, -3), Vector2(18, 4), ink, 2.0, sd, fill)
		for k in 3:
			sk_line(p + Vector2(-14 + k * 14, -8), p + Vector2(-18 + k * 18, -16), ink, 1.5, sd + k)
		return
	if job == FlockGame.Job.FLOAT:
		_draw_umbrella(p + Vector2(0, -48), int(s.anim))
	var rot := 0.0
	var origin := p
	if job == FlockGame.Job.CLIMB:
		rot = -PI / 2 * d
		origin = p + Vector2(-d * 4, -6)
	draw_set_transform(origin, rot, Vector2.ONE)
	var ph := float(s.anim) * 0.8
	var bob := absf(sin(ph)) * 2.0 if job == FlockGame.Job.WALK else 0.0
	if job == FlockGame.Job.BLOCK:
		sk_line(Vector2(-5, -10), Vector2(-11, 0), ink, 2.0, sd + 1)
		sk_line(Vector2(5, -10), Vector2(11, 0), ink, 2.0, sd + 2)
		sk_line(Vector2(-12, -24), Vector2(-26, -30), ink, 2.0, sd + 3)
		sk_line(Vector2(12, -24), Vector2(26, -30), ink, 2.0, sd + 4)
		sk_oval(Vector2(0, -20), Vector2(14, 11), ink, 2.0, sd, fill)
		sk_oval(Vector2(0, -24), Vector2(7, 8), ink, 1.5, sd + 5, Color(PENCIL, a * 0.9))
		draw_circle(Vector2(-3, -26), 1.8, fill)
		draw_circle(Vector2(3, -26), 1.8, fill)
	else:
		var falling := job == FlockGame.Job.FALL or job == FlockGame.Job.FLOAT
		for k in 2:
			var lx := (-6.0 + k * 10.0) * d
			if falling:
				sk_line(Vector2(lx, -14), Vector2(lx - d * 5, -2), ink, 2.0, sd + 10 + k)
			else:
				var sw := sin(ph + k * PI) * 4.0 if job == FlockGame.Job.WALK else 0.0
				sk_line(Vector2(lx, -12 - bob), Vector2(lx + sw * d, 0), ink, 2.0, sd + 10 + k)
		sk_oval(Vector2(0, -20 - bob), Vector2(15, 10), ink, 2.0, sd, fill)
		# caracóis da lã
		for k in 3:
			draw_arc(Vector2(-7 + k * 6, -21 - bob), 3.0, PI * 0.2, PI * 1.6, 6, Color(PENCIL, a * 0.6), 1.2)
		var hp := Vector2(d * 15, -24 - bob)
		sk_oval(hp, Vector2(6, 5), ink, 1.5, sd + 6, Color(PENCIL, a * 0.9))
		draw_circle(hp + Vector2(d * 2.5, -1.5), 1.6, fill)
		sk_line(hp + Vector2(-d * 3, -4), hp + Vector2(-d * 7, -8), ink, 1.5, sd + 7)
	draw_set_transform(Vector2.ZERO)
	_draw_tool(s, p)
	if hov:
		sk_oval(p + Vector2(0, -18), Vector2(30, 26), RED, 2.5, boil(999))


func _draw_tool(s: Dictionary, p: Vector2) -> void:
	var d := float(s.dir)
	var sw := sin(float(s.anim) * 1.2)
	var sd := boil(int(s.id) + 500)
	match s.job:
		FlockGame.Job.BUILD:
			var r := Rect2(p + Vector2(d * 14 - 6, -20 + sw * 2), Vector2(12, 6))
			draw_rect(r, Color(RED, 0.4))
			sk_rect(r, RED, 1.5, sd)
		FlockGame.Job.BASH:
			var h := p + Vector2(d * 10, -18)
			var tip := h + Vector2(d * 14, -10 + sw * 12)
			sk_line(h, tip, PENCIL, 2.0, sd)
			sk_line(tip + Vector2(-d * 4, -6), tip + Vector2(d * 6, 6), PENCIL, 3.0, sd + 1)
		FlockGame.Job.MINE:
			var h := p + Vector2(d * 8, -22)
			var tip := h + Vector2(d * 12, 4 + sw * 10)
			sk_line(h, tip, PENCIL, 2.0, sd)
			sk_line(tip + Vector2(-d * 6, 2), tip + Vector2(d * 4, 8), PENCIL, 3.0, sd + 1)
		FlockGame.Job.DIG:
			var h := p + Vector2(d * 6, -28 + sw * 4)
			sk_line(h, h + Vector2(0, 22), PENCIL, 2.0, sd)
			sk_oval(h + Vector2(0, 24), Vector2(5, 4), PENCIL, 1.5, sd + 1, Color(PENCIL, 0.5))


func _draw_umbrella(c: Vector2, anim: int) -> void:
	var sway := sin(anim * 0.3) * 0.12
	var pts := PackedVector2Array()
	for k in 9:
		pts.append(c + Vector2.from_angle(PI + PI * k / 8.0 + sway) * 22.0)
	draw_colored_polygon(pts, Color(RED, 0.35))
	pts.append(pts[0])
	draw_polyline(pts, RED, 2.0)
	sk_line(c, c + Vector2(0, 18), PENCIL, 1.5, anim / 3)


func _draw_part(p: Dictionary) -> void:
	var a := clampf(p.life * 2.0, 0.0, 1.0)
	var v: Vector2 = p.vel.normalized() * p.size
	draw_line(p.pos - v, p.pos + v, Color(p.color, a), 2.0)


func _draw_status() -> void:
	var sp := status_parts()
	var xs := [190, 520, 800, 1100]
	for i in 4:
		if sp[i] != "":
			PixelFont.draw(self, sp[i], xs[i], 10, 2, BLUE if i > 0 else RED)


func _draw_panel() -> void:
	draw_rect(Rect2(0, FlockGame.PANEL_Y, 1280, 720 - FlockGame.PANEL_Y), Color("ece5d0"))
	sk_line(Vector2(0, FlockGame.PANEL_Y + 1), Vector2(1280, FlockGame.PANEL_Y + 1), PENCIL, 2.0, 3)
	super._draw_panel()


func _draw_button(i: int, r: Rect2, count: String, active: bool) -> void:
	var rr := r.grow(-4)
	sk_rect(rr, PENCIL, 2.0, 200 + i * 9)
	var dim := i >= 2 and i <= 8 and count == "0"
	var col := Color(PENCIL, 0.3) if dim else PENCIL
	if count != "":
		PixelFont.draw(self, count, rr.get_center().x, rr.position.y + 8, 3, BLUE)
	draw_icon(i, rr.get_center() + Vector2(0, 18), 26.0, col, 3.0)
	if active:
		sk_oval(rr.get_center(), rr.size * 0.56, RED, 3.0, 300 + i + int(time * 3.0))


func _draw_cursor(p: Vector2, on: bool) -> void:
	var r := 22.0 if on else 16.0
	sk_line(p + Vector2(-r, 0), p + Vector2(r, 0), RED, 2.0, 7)
	sk_line(p + Vector2(0, -r), p + Vector2(0, r), RED, 2.0, 8)


func wool_color() -> Color:
	return PENCIL


func saved_colors() -> Array:
	return [BLUE, RED, PENCIL]


func panel_palette() -> Dictionary:
	return {"bg": Color("ece5d0"), "button": PAPER, "button_on": PAPER, "border": PENCIL,
		"icon": PENCIL, "icon_dim": Color(PENCIL, 0.3), "count": BLUE, "accent": RED,
		"status_bg": Color(0, 0, 0, 0), "status_text": BLUE, "cursor": RED}


func ui_palette() -> Dictionary:
	return {
		"panel": Color(PAPER, 0.97),
		"border": PENCIL,
		"text": PENCIL,
		"accent": RED,
		"button": Color("ece5d0"),
		"button_hover": Color("f8e8a0"),
		"radius": 4,
		"dim": Color(0.3, 0.3, 0.3, 0.25),
	}
