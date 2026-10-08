class_name JetpacSkin
extends Node2D
## Base dos estilos do Jetpac: desenhos originais (astronauta, foguetes, combustível, gemas e
## oito tipos de alienígenas), explosões e sons. Os estilos escolhem paletas, cenário e HUD.

const S := JetpacGame.SCALE

const MAN_TOP := [
	"...WWWW...",
	"..WWWWWW..",
	"..WWVVVV..",
	"..WWVVVV..",
	"...WWWW...",
	".PPWWWWW..",
	".PPWWWWWGG",
	".PPWWWW...",
	".PPWWWW...",
	".PPWWWW...",
	"...WWWW...",
]
const MAN_LEGS := {
	"stand": ["...WW.WW..", "...WW.WW..", "...WW.WW..", "..WWW.WWW.", ".........."],
	"walk0": ["...WW.WW..", "..WW...WW.", ".WW.....WW", "WWW....WWW", ".........."],
	"walk1": ["...WWWW...", "....WW....", "....WW....", "...WWWW...", ".........."],
	"fly": ["...WWWW...", "...WWWW...", "....WW....", "....WW....", "....WW...."],
}
const NOSE := [
	".......RR.......",
	"......RRRR......",
	"......RRRR......",
	".....RRRRRR.....",
	".....RRRRRR.....",
	"....RRRRRRRR....",
	"....RRRRRRRR....",
	"...BBBBBBBBBB...",
	"...BBBBBBBBBB...",
	"...BHBBBBBBBB...",
	"...BHBBBBBBBB...",
	"...BHBBBBBBBB...",
	"...BHBBBBBBBB...",
	"...BBBBBBBBBB...",
	"...BBBBBBBBBB...",
	"...bbbbbbbbbb...",
]
const MIDDLE := [
	"...BBBBBBBBBB...",
	"...BHBBBBBBBB...",
	"...BHBWWWWBBB...",
	"...BHWWCCWWBB...",
	"...BHWCCCCWBB...",
	"...BHWCCCCWBB...",
	"...BHWWCCWWBB...",
	"...BHBWWWWBBB...",
	"...BHBBBBBBBB...",
	"...BHBBBBBBBB...",
	"...BHBBBBBBBB...",
	"...BHBBBBBBBB...",
	"...BHBBBBBBBB...",
	"...BBBBBBBBBB...",
	"...BBBBBBBBBB...",
	"...bbbbbbbbbb...",
]
const BASE := [
	"...BBBBBBBBBB...",
	"...BHBBBBBBBB...",
	"...BHBBBBBBBB...",
	"...BHBBBBBBBB...",
	"...BHBBBBBBBB...",
	"...BHBBBBBBBB...",
	"..RBHBBBBBBBBR..",
	".RRBHBBBBBBBBRR.",
	"RRRBHBBBBBBBBRRR",
	"RRRBBBBBBBBBBRRR",
	"RRRbbbbbbbbbbRRR",
	"RR..KKKKKKKK..RR",
	"R....KKKKKK....R",
	"R.....KKKK.....R",
	"................",
	"................",
]
const FUEL := [
	".KKKKKKKK.",
	"KPPPPPPPPK",
	"KPWPPPPPPK",
	"KPPPPPPPPK",
	"KKKKKKKKKK",
	"KPPPPPPPPK",
	"KPPWWWPPPK",
	"KPPPPPPPPK",
	"KPPPPPPPPK",
	".KKKKKKKK.",
]
const GEM := ["..GGGG..", ".GgGGgG.", "GGGGGGGG", ".GGGGGG.", "..GGGG..", "...GG..."]
const ALIENS := {
	"meteor": ["........OO..", "......OOYYO.", "....OOYYWWYO", "..OOOYYWWWYO", "OOOOOYYWWWYO", "..OOOYYWWYO.", "....OOYYYO..", "......OOO..."],
	"fuzz": ["A...AA...A", ".A.AAAA.A.", "..AAAAAA..", ".AAEAAEAA.", "AAAAAAAAAA", ".AAAAAAAA.", "..AAaaAA..", ".A.AAAA.A.", "A...AA...A"],
	"bubble": ["...AAAA...", ".AA....AA.", "A..W.....A", "A.W......A", "A........A", "A........A", ".AA....AA.", "...AAAA..."],
	"jet": ["AA..........", "AAA...AA....", "AAAAAAAAAAW.", "AAAAAAAAAAAA", "AAA...AA....", "AA.........."],
	"cross": ["...AAA...", "...AWA...", "...AAA...", "AAAAAAAAA", "AWAAAAAWA", "AAAAAAAAA", "...AAA...", "...AWA...", "...AAA..."],
	"saucer": ["....WWWW....", "...WWWWWW...", "AAAAAAAAAAAA", "AEAAEAAEAAEA", ".aaaaaaaaaa.", "...aaaaaa..."],
	"hopper": ["..EE..EE..", ".AAAAAAAA.", "AAAAAAAAAA", "AAaaaaaaAA", ".AAAAAAAA.", "A.A....A.A", "A..A..A..A", "AA......AA"],
	"blob": ["...AAA....", ".AAAAAAA..", "AAEAAAEAA.", "AAAAAAAAAA", ".AAaaaAAAA", "AAAAAAAAA.", ".AA.AAA.AA", "..A..A...A"],
}

var game: JetpacGame
var sfx := {}
var tex := {}
var time := 0.0
var booms: Array[Dictionary] = []      # pos (unidades), life, max, color, size
var popups: Array[Dictionary] = []
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _thrust: AudioStreamPlayer
var _rocket_model := -1
var _alien_level := -1


func attach(g: JetpacGame) -> void:
	game = g
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_thrust = AudioStreamPlayer.new()
	_thrust.volume_db = -12.0
	add_child(_thrust)
	g.match_started.connect(_on_match_started)
	g.level_started.connect(_on_level_started)
	g.fired.connect(func(_p: Vector2, _d: int) -> void: play("laser", randf_range(0.95, 1.05), -3.0))
	g.alien_killed.connect(_on_alien_killed)
	g.alien_crashed.connect(func(p: Vector2) -> void:
		boom(p, 0.4, 10.0, alien_color())
		play("crash", 1.0, -6.0))
	g.picked.connect(_on_picked)
	g.dropped.connect(func(_k: String) -> void: play("drop"))
	g.part_placed.connect(func(_s: int) -> void: play("place"))
	g.fuel_added.connect(func(_f: int) -> void: play("fuel"))
	g.player_died.connect(_on_player_died)
	g.takeoff.connect(func() -> void: play("takeoff"))
	g.extra_life.connect(func() -> void: play("extra"))
	var cached: Variant = Synth.cache_get(get_script().resource_path)
	if cached != null:
		sfx = cached
	else:
		_build_sfx()
		Synth.cache_set(get_script().resource_path, sfx)
	_setup()
	_refresh()


func play(id: String, pitch := 1.0, volume_db := 0.0) -> void:
	if game == null or game.mode == JetpacGame.Mode.DEMO or not sfx.has(id):
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = sfx[id]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


func _process(delta: float) -> void:
	if game == null:
		return
	var silent := game.paused or game.mode == JetpacGame.Mode.DEMO
	var want := not silent and (thrusting() or game.state == JetpacGame.State.TAKEOFF or game.state == JetpacGame.State.LANDING) and sfx.has("thrust")
	if want and not _thrust.playing:
		var s: AudioStreamWAV = sfx.thrust
		if s.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_end = s.data.size() / 2
		_thrust.stream = s
		_thrust.play()
	elif not want and _thrust.playing:
		_thrust.stop()
	if not game.paused:
		time += delta
		for b in booms:
			b.life -= delta
		booms = booms.filter(func(b: Dictionary) -> bool: return b.life > 0.0)
		for p in popups:
			p.life -= delta
			p.pos.y -= 6.0 * delta
		popups = popups.filter(func(p: Dictionary) -> bool: return p.life > 0.0)
		_refresh()
		_tick(delta)
	queue_redraw()


func thrusting() -> bool:
	return game.state == JetpacGame.State.PLAY and game.vel.y < -1.0


## Volta a criar as texturas que dependem do nível (foguete e alienígenas).
func _refresh() -> void:
	if game.rocket_model() != _rocket_model:
		_rocket_model = game.rocket_model()
		var pal := rocket_palette(_rocket_model)
		tex.nose = make_tex(NOSE, pal)
		tex.middle = make_tex(MIDDLE, pal)
		tex.base = make_tex(BASE, pal)
	if game.level != _alien_level:
		_alien_level = game.level
		var k := game.alien_kind()
		tex.alien = make_tex(ALIENS[k], alien_palette())


func boom(p: Vector2, life: float, size: float, color: Color) -> void:
	booms.append({"pos": p, "life": life, "max": life, "color": color, "size": size, "seed": randi()})


func px(u: Vector2) -> Vector2:
	return u * S


func man_rows(frame: String) -> Array:
	return MAN_TOP + MAN_LEGS[frame]


func man_frame() -> String:
	var g := game
	if not g.grounded:
		return "fly"
	if absf(g.vel.x) > 1.0:
		return "walk0" if int(g.anim * 8.0) % 2 == 0 else "walk1"
	return "stand"


## Desenha uma textura com a base em `feet` (unidades), centrada.
func draw_feet(t: Texture2D, feet: Vector2, flip := false, modulate_c := Color.WHITE) -> void:
	var size := t.get_size() * S / tex_scale()
	var pos := px(feet) - Vector2(size.x / 2, size.y)
	if flip:
		draw_texture_rect(t, Rect2(pos + Vector2(size.x, 0), Vector2(-size.x, size.y)), false, modulate_c)
	else:
		draw_texture_rect(t, Rect2(pos, size), false, modulate_c)


func draw_center(t: Texture2D, c: Vector2, flip := false, modulate_c := Color.WHITE) -> void:
	var size := t.get_size() * S / tex_scale()
	var pos := px(c) - size / 2
	if flip:
		draw_texture_rect(t, Rect2(pos + Vector2(size.x, 0), Vector2(-size.x, size.y)), false, modulate_c)
	else:
		draw_texture_rect(t, Rect2(pos, size), false, modulate_c)


## Texturas do astronauta, do combustível e das gemas.
func build_common(man_pal: Dictionary, fuel_pal: Dictionary, gem_cols: Array) -> void:
	for f: String in MAN_LEGS:
		tex["man_" + f] = make_tex(man_rows(f), man_pal)
	tex.fuel = make_tex(FUEL, fuel_pal)
	var gems := []
	for c: Color in gem_cols:
		gems.append(make_tex(GEM, {"G": c, "g": c.lightened(0.6)}))
	tex.gems = gems


func tex_scale() -> float:
	return 1.0


func make_tex(rows: Array, pal: Dictionary) -> Texture2D:
	return PixelArt.texture(rows, pal, 1)


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	if game == null:
		return
	_draw_back()
	_draw_platforms()
	_draw_rocket()
	_draw_items()
	for a in game.aliens:
		_draw_alien(a)
	_draw_lasers()
	_draw_player()
	_draw_booms()
	_draw_hud()


func _draw_rocket() -> void:
	var g := game
	var base := Vector2(JetpacGame.ROCKET_X, JetpacGame.GROUND_Y + g.rocket_y)
	var parts: Array = [tex.base, tex.middle, tex.nose]
	var n := g.rocket_stage if g.state != JetpacGame.State.TAKEOFF and g.state != JetpacGame.State.LANDING else 3
	for i in n:
		draw_feet(parts[i], base - Vector2(0, i * 16))
	# combustível: o foguete enche-se de cor de baixo para cima
	if g.rocket_stage >= 3 and g.fuel > 0 and g.state == JetpacGame.State.PLAY:
		var h := 48.0 * g.fuel / JetpacGame.FUEL_NEEDED
		var r := Rect2(px(base + Vector2(-5, -h - 2)), Vector2(10, h) * S)
		draw_rect(r, fuel_color())
	if g.state == JetpacGame.State.TAKEOFF or g.state == JetpacGame.State.LANDING:
		_draw_exhaust(base)


func _draw_exhaust(base: Vector2) -> void:
	for i in 6:
		var p := base + Vector2(randf_range(-4, 4), randf_range(0, 14))
		draw_rect(Rect2(px(p), Vector2(8, 8)), [Color.YELLOW, Color.ORANGE, Color.RED][i % 3])


func _draw_items() -> void:
	for it in game.items:
		var p: Vector2 = it.pos
		match it.kind:
			"part2":
				draw_feet(tex.middle, p)
			"part3":
				draw_feet(tex.nose, p)
			"fuel":
				draw_feet(tex.fuel, p)
			"gem":
				var gems: Array = tex.gems
				draw_feet(gems[int(it.get("gem", 0)) % gems.size()], p)


func _draw_alien(a: Dictionary) -> void:
	var flip: bool = float(a.vel.x) < 0.0
	draw_center(tex.alien, a.pos, flip and a.kind in ["meteor", "jet"])


func _draw_lasers() -> void:
	for l in game.lasers:
		var x0: float = l.x0
		var x1: float = x0 + float(l.dir) * float(l.len)
		var cols := laser_colors()
		var c: Color = cols[int(float(l.hue) * cols.size() + time * 12.0) % cols.size()]
		var a := clampf(float(l.life) / 0.2, 0.0, 1.0)
		_hline(x0, x1, l.y, Color(c, a))


## Linha horizontal com a volta ao ecrã.
func _hline(x0: float, x1: float, y: float, c: Color, w := 1.0) -> void:
	var lo := minf(x0, x1)
	var hi := maxf(x0, x1)
	var r := Rect2(px(Vector2(lo, y - w / 2)), Vector2(hi - lo, w) * S)
	draw_rect(r, c)
	if r.position.x < 0.0:
		draw_rect(Rect2(r.position + Vector2(1280, 0), r.size), c)
	if r.end.x > 1280.0:
		draw_rect(Rect2(r.position - Vector2(1280, 0), r.size), c)


func _draw_player() -> void:
	var g := game
	if g.state in [JetpacGame.State.DYING, JetpacGame.State.OVER, JetpacGame.State.TAKEOFF, JetpacGame.State.LANDING]:
		return
	if g.state == JetpacGame.State.READY and fmod(time, 0.24) < 0.1:
		return
	var t: Texture2D = tex["man_" + man_frame()]
	var flip := g.facing < 0
	_draw_flame()
	draw_feet(t, g.pos, flip)
	if g.pos.x < 8.0:
		draw_feet(t, g.pos + Vector2(JetpacGame.FIELD.x, 0), flip)
	elif g.pos.x > JetpacGame.FIELD.x - 8.0:
		draw_feet(t, g.pos - Vector2(JetpacGame.FIELD.x, 0), flip)


func _draw_flame() -> void:
	if not thrusting():
		return
	var g := game
	var p := g.pos + Vector2(-g.facing * 3.0, -6.0)
	var l := 4.0 + randf() * 4.0
	draw_rect(Rect2(px(p + Vector2(-1.5, 0)), Vector2(3, l) * S), flame_color())


func _draw_booms() -> void:
	for b in booms:
		var k: float = 1.0 - float(b.life) / float(b.max)
		var c := px(b.pos)
		var rng := RandomNumberGenerator.new()
		rng.seed = b.seed
		for i in 10:
			var d := Vector2.from_angle(rng.randf() * TAU) * float(b.size) * S * (0.3 + k * rng.randf_range(0.7, 1.4))
			var s := maxf(4.0, 10.0 * (1.0 - k))
			draw_rect(Rect2(c + d - Vector2(s, s) / 2, Vector2(s, s)), Color(b.color, 1.0 - k))


# ---------------------------------------------------------------- para os estilos reescreverem

func _setup() -> void:
	pass


func _build_sfx() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _draw_back() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color.BLACK)


func _draw_platforms() -> void:
	pass


func _draw_hud() -> void:
	pass


func rocket_palette(_model: int) -> Dictionary:
	return {"R": Color.RED, "B": Color.WHITE, "b": Color.GRAY, "H": Color.WHITE, "W": Color.WHITE, "C": Color.CYAN, "K": Color.DARK_GRAY}


func alien_palette() -> Dictionary:
	var c := alien_color()
	return {"A": c, "a": c.darkened(0.3), "E": Color.BLACK, "W": Color.WHITE, "O": Color.RED, "Y": Color.YELLOW}


func alien_color() -> Color:
	return Color.from_hsv(fmod(game.level * 0.13, 1.0), 0.7, 1.0)


func fuel_color() -> Color:
	return Color(0.8, 0.2, 0.9, 0.7)


func flame_color() -> Color:
	return Color.ORANGE if fmod(time, 0.1) < 0.05 else Color.YELLOW


func laser_colors() -> Array:
	return [Color.WHITE, Color.CYAN, Color.YELLOW, Color.MAGENTA]


func ui_palette() -> Dictionary:
	return UI.LAUNCHER_PALETTE


func _on_match_started() -> void:
	booms.clear()
	popups.clear()


func _on_level_started(_l: int) -> void:
	_refresh()


func _on_alien_killed(pos: Vector2, _kind: String, points: int) -> void:
	boom(pos, 0.45, 9.0, alien_color())
	popups.append({"pos": pos, "text": str(points), "life": 0.7})
	play("kill", randf_range(0.9, 1.1))


func _on_picked(kind: String, pos: Vector2) -> void:
	if kind == "gem":
		popups.append({"pos": pos, "text": "250", "life": 0.9})
		play("gem")
	else:
		play("pick")


func _on_player_died(pos: Vector2) -> void:
	boom(pos, 1.2, 22.0, Color.WHITE)
	boom(pos, 0.9, 14.0, alien_color())
	play("die")
