extends AsteroidsSkin
## Clássico 1979: monitor vetorial — linhas brancas finas e brilhantes sobre preto, com um leve
## rasto de fósforo. Algarismos traçados a vetor, explosões em pontos e a nave a desfazer-se em segmentos.

const LINE := Color(0.88, 0.92, 1.0)
const GLOW := Color(0.6, 0.75, 1.0, 0.18)
const DIGITS := {
	"0": [[0, 0, 4, 0, 4, 6, 0, 6, 0, 0]],
	"1": [[2, 0, 2, 6]],
	"2": [[0, 0, 4, 0, 4, 3, 0, 3, 0, 6, 4, 6]],
	"3": [[0, 0, 4, 0, 4, 6, 0, 6], [0, 3, 4, 3]],
	"4": [[0, 0, 0, 3, 4, 3], [4, 0, 4, 6]],
	"5": [[4, 0, 0, 0, 0, 3, 4, 3, 4, 6, 0, 6]],
	"6": [[0, 0, 0, 6, 4, 6, 4, 3, 0, 3]],
	"7": [[0, 0, 4, 0, 4, 6]],
	"8": [[0, 0, 4, 0, 4, 6, 0, 6, 0, 0], [0, 3, 4, 3]],
	"9": [[4, 3, 0, 3, 0, 0, 4, 0, 4, 6]],
}

var fx: Node2D
var dots: Array[Dictionary] = []        # explosões em pontos
var segments: Array[Dictionary] = []    # nave desfeita
var flicker := false


func _setup() -> void:
	fx = Node2D.new()
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = m
	add_child(fx)
	fx.draw.connect(_draw_fx)


func _build_sfx() -> void:
	sfx.beat0 = Synth.tone(58.0, 0.11, {"wave": "square", "volume": 0.5, "lowpass": 0.15, "decay": 14.0})
	sfx.beat1 = Synth.tone(52.0, 0.11, {"wave": "square", "volume": 0.5, "lowpass": 0.15, "decay": 14.0})
	sfx.fire = Synth.tone(1700.0, 0.09, {"wave": "square", "freq_end": 380.0, "volume": 0.12, "lowpass": 0.5, "decay": 18.0})
	sfx.saucer_fire = Synth.tone(1200.0, 0.08, {"wave": "square", "freq_end": 500.0, "volume": 0.08, "lowpass": 0.5, "decay": 20.0})
	var sizes := [[0.75, 0.08, 5.0], [0.5, 0.14, 7.0], [0.3, 0.25, 11.0]]
	for i in 3:
		var s: Array = sizes[i]
		sfx["boom%d" % i] = Synth.tone(0.0, s[0], {"wave": "noise", "volume": 0.5, "lowpass": s[1], "decay": s[2]})
	sfx.ship_boom = Synth.to_stream(Synth.mix([
		Synth.render(0.0, 1.4, {"wave": "noise", "volume": 0.5, "lowpass": 0.1, "decay": 2.4}),
		Synth.render(0.0, 0.5, {"wave": "noise", "volume": 0.2, "lowpass": 0.5, "decay": 7.0}),
	]))
	sfx.thrust = Synth.tone(0.0, 0.5, {"wave": "noise", "volume": 0.22, "lowpass": 0.06, "attack": 0.0, "release": 0.0})
	var big := []
	for i in 2:
		big.append(Synth.render(330.0, 0.16, {"wave": "square", "freq_end": 440.0, "volume": 0.09, "lowpass": 0.4, "attack": 0.0, "release": 0.0}))
		big.append(Synth.render(440.0, 0.16, {"wave": "square", "freq_end": 330.0, "volume": 0.09, "lowpass": 0.4, "attack": 0.0, "release": 0.0}))
	sfx.saucer_big = Synth.concat(big)
	var small := []
	for i in 3:
		small.append(Synth.render(900.0, 0.07, {"wave": "square", "freq_end": 1250.0, "volume": 0.08, "lowpass": 0.5, "attack": 0.0, "release": 0.0}))
		small.append(Synth.render(1250.0, 0.07, {"wave": "square", "freq_end": 900.0, "volume": 0.08, "lowpass": 0.5, "attack": 0.0, "release": 0.0}))
	sfx.saucer_small = Synth.concat(small)
	var beeps := []
	for i in 10:
		beeps.append(Synth.render(2600.0, 0.04, {"wave": "square", "volume": 0.08}))
		beeps.append(Synth.silence(0.04))
	sfx.extra = Synth.concat(beeps)


# ---------------------------------------------------------------- eventos

func _on_match_started() -> void:
	dots.clear()
	segments.clear()


func _on_asteroid_destroyed(pos: Vector2, size: int, points: int, rock: Dictionary) -> void:
	super(pos, size, points, rock)
	_dots(pos, 10 - size * 2, 120.0 - size * 20.0)


func _on_saucer_destroyed(pos: Vector2, small: bool, points: int) -> void:
	super(pos, small, points)
	_dots(pos, 12, 140.0)


func _on_ship_destroyed(pos: Vector2) -> void:
	super(pos)
	var pts := game.ship_points(pos)
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		var mid := (a + b) / 2
		segments.append({"a": a - mid, "b": b - mid, "pos": mid, "vel": (mid - pos).normalized() * randf_range(20, 60) + game.ship_vel * 0.3,
			"rot": 0.0, "spin": randf_range(-3, 3), "life": 2.0})


func _dots(pos: Vector2, n: int, speed: float) -> void:
	for i in n:
		dots.append({"pos": pos, "vel": Vector2.from_angle(randf() * TAU) * randf_range(speed * 0.3, speed), "life": randf_range(0.4, 0.9)})


func _tick(dt: float) -> void:
	flicker = not flicker
	for d in dots:
		d.pos += d.vel * dt
		d.life -= dt
	dots = dots.filter(func(d: Dictionary) -> bool: return d.life > 0.0)
	for s in segments:
		s.pos += s.vel * dt
		s.rot += s.spin * dt
		s.life -= dt
	segments = segments.filter(func(s: Dictionary) -> bool: return s.life > 0.0)
	fx.queue_redraw()


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color.BLACK)
	_draw_world(self, LINE, 1.6)


func _draw_fx() -> void:
	_draw_world(fx, GLOW, 5.0)


## O mundo é traçado duas vezes: linhas finas e nítidas + linhas largas e ténues (o brilho do fósforo).
func _draw_world(ci: CanvasItem, c: Color, width: float) -> void:
	var g := game
	for r in g.rocks:
		for off in wrap_offsets(r.pos, r.r):
			ci.draw_polyline(closed(g.rock_points(r, off)), c, width, true)
	if g.saucer != null:
		for line in saucer_lines(g.saucer.pos, g.saucer.small):
			ci.draw_polyline(line, c, width, true)
	if g.ship_visible() or (g.ship_waiting() and fmod(Time.get_ticks_msec() / 1000.0, 0.5) < 0.3):
		for off in wrap_offsets(g.ship_pos, 20.0):
			ci.draw_polyline(closed(shifted(g.ship_points(), off)), c, width, true)
		if g.thrusting and flicker:
			var back := g.ship_pos + Vector2(-7, 0).rotated(g.ship_angle)
			var flame := PackedVector2Array([
				back + Vector2(0, -5).rotated(g.ship_angle),
				back + Vector2(-14, 0).rotated(g.ship_angle),
				back + Vector2(0, 5).rotated(g.ship_angle)])
			ci.draw_polyline(flame, c, width, true)
	for b in g.bullets:
		ci.draw_rect(Rect2(b.pos - Vector2(1.5, 1.5), Vector2(3, 3)) if width < 3 else Rect2(b.pos - Vector2(3, 3), Vector2(6, 6)), c)
	for b in g.saucer_bullets:
		ci.draw_rect(Rect2(b.pos - Vector2(1.5, 1.5), Vector2(3, 3)) if width < 3 else Rect2(b.pos - Vector2(3, 3), Vector2(6, 6)), c)
	for d in dots:
		var a := clampf(d.life * 2.0, 0.0, 1.0)
		ci.draw_rect(Rect2(d.pos - Vector2(1, 1), Vector2(2, 2)), Color(c, c.a * a))
	for s in segments:
		var a := clampf(s.life, 0.0, 1.0)
		ci.draw_line(s.pos + (s.a as Vector2).rotated(s.rot), s.pos + (s.b as Vector2).rotated(s.rot), Color(c, c.a * a), width, true)
	_draw_hud(ci, c, width)


func _draw_hud(ci: CanvasItem, c: Color, width: float) -> void:
	var g := game
	_number(ci, g.players[0].score, Vector2(250, 30), 6.0, Color(c, c.a * (1.0 if g.current == 0 else 0.5)), width, true)
	_number(ci, maxi(g.best, g.player().score), Vector2(W / 2, 30), 3.5, c, width * 0.8, false)
	if g.players.size() > 1:
		_number(ci, g.players[1].score, Vector2(W - 40, 30), 6.0, Color(c, c.a * (1.0 if g.current == 1 else 0.5)), width, true)
	# vidas: naves pequenas por baixo da pontuação do jogador atual
	var x0 := 110.0 if g.current == 0 else W - 200.0
	for i in mini(g.player().lives, 8):
		var pts := g.ship_points(Vector2(x0 + i * 22.0, 92), -PI / 2, 0.75)
		ci.draw_polyline(closed(pts), c, width * 0.8, true)


## Escreve um número a vetor. right_align: alinha à direita de `pos`.
func _number(ci: CanvasItem, n: int, pos: Vector2, cell: float, c: Color, width: float, right_align: bool) -> void:
	var text := "%02d" % n
	var adv := cell * 6.0
	var x := pos.x - text.length() * adv if right_align else pos.x - (text.length() * adv - cell * 2) / 2
	for ch in text:
		for stroke: Array in DIGITS[ch]:
			var line := PackedVector2Array()
			for k in range(0, stroke.size(), 2):
				line.append(Vector2(x + stroke[k] * cell, pos.y + stroke[k + 1] * cell))
			ci.draw_polyline(line, c, width, true)
		x += adv


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0, 0, 0, 0.9),
		"border": LINE,
		"text": LINE,
		"accent": LINE,
		"button": Color.BLACK,
		"button_hover": Color(1, 1, 1, 0.14),
		"radius": 0,
		"dim": Color(0, 0, 0, 0.35),
	}
