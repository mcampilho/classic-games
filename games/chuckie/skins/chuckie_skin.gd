class_name ChuckieSkin
extends Node2D
## Base dos estilos do Chuckie Egg: desenhos originais (agricultor, galinhas, pato, ovos e grão),
## cenário estático gravado numa textura a cada nível, sons e pequenas animações.
## Os estilos escolhem as cores, o cenário (_draw_static) e o HUD.

const S := ChuckieGame.SCALE
const T := ChuckieGame.TILE

# Agricultor de chapéu de palha (8 x 16), virado para a direita.
const FARMER_HEAD := [
	"..HHHH..",
	".HbbbbH.",
	"HHHHHHHH",
	"..SSSE..",
	"..SSSS..",
	"...SS...",
	".BBBBBB.",
	"BBOBBOBB",
	"SBOOOOBS",
	"S.OOOO.S",
	"..OOOO..",
	"..OooO..",
]
const FARMER_LEGS := {
	"stand": ["..OO.OO.", "..OO.OO.", "..OO.OO.", ".KKK.KKK"],
	"walk0": ["..OOOO..", ".OO..OO.", "OO....OO", "KK....KK"],
	"walk1": ["..OOO...", "...OO...", "...OO...", "..KKKK.."],
	"jump": ["..OOOOO.", ".OO...OO", ".KK..KK.", "........"],
}
const FARMER_CLIMB := [
	"..HHHH..",
	".HbbbbH.",
	"HHHHHHHH",
	"S.SSSS..",
	"S.SSSS..",
	"SB.SS...",
	".BBBBBBS",
	".BOBBOBS",
	"..OOOO..",
	"..OOOO..",
	"..OOOO..",
	"..OooO..",
	"..OO.OO.",
	"..OO.OO.",
	"..OO.KKK",
	".KKK....",
]
# Galinha (8 x 12), virada para a direita.
const HEN := {
	"walk0": [
		".....C..",
		"....CWW.",
		"....WEWY",
		"....WWWY",
		"T...WWW.",
		"TT.WWWW.",
		"TWWWWWW.",
		"WWWwwWW.",
		"WWwwwWW.",
		".WWWWW..",
		"..Y..Y..",
		".YY..YY.",
	],
	"walk1": [
		".....C..",
		"....CWW.",
		"....WEWY",
		"....WWWY",
		"T...WWW.",
		"TT.WWWW.",
		"TWWWWWW.",
		"WWWwwWW.",
		"WWwwwWW.",
		".WWWWW..",
		"...YY...",
		"..YYY...",
	],
	"peck": [
		"........",
		"........",
		"........",
		"T.......",
		"TT......",
		"TWWWWW..",
		"WWWWWWWC",
		"WWwwwWEW",
		"WWwwwWWY",
		".WWWWW.Y",
		"..Y..Y..",
		".YY..YY.",
	],
	"climb": [
		"...CC...",
		"..CWWC..",
		"..WWWW..",
		"..WWWW..",
		".WWWWWW.",
		"WWWwwWWW",
		"WWwwwwWW",
		"WWWwwWWW",
		".WWWWWW.",
		"..WWWW..",
		"..Y..Y..",
		".YY..YY.",
	],
}
# Pato gigante (16 x 16) a voar, virado para a direita.
const DUCK := [
	[
		"..........DDD...",
		".........DDDDD..",
		".........DDEDDYY",
		".........DDDDYYY",
		"..........DDD...",
		"...........DD...",
		"..WW......DDD...",
		".WWWW....DDDD...",
		"WWWWWW..DDDDD...",
		".WWWWWWDDDDDD...",
		"..DDDDDDDDDDD...",
		".DDdddddDDDD....",
		"DDdddddddDD.....",
		".DDDDDDDDD......",
		"....O..O........",
		"...OO.OO........",
	],
	[
		"..........DDD...",
		".........DDDDD..",
		".........DDEDDYY",
		".........DDDDYYY",
		"..........DDD...",
		"...........DD...",
		"..........DDD...",
		".........DDDD...",
		"........DDDDD...",
		".......DDDDDD...",
		"..DDDDDDDDDDD...",
		".DWWWWWDDDDD....",
		"DWWWWWWWdDD.....",
		".DWWWWWDDD......",
		"..WWW..O........",
		"...OO.OO........",
	],
]
const EGG := [".EE.", "EEEE", "EEWE", "EEEE", ".EE."]
const GRAIN := ["..GG..", ".GgGG.", "GGGgGG"]

var game: ChuckieGame
var sfx := {}
var tex := {}
var time := 0.0
var popups: Array[Dictionary] = []    # pos (unidades), text, life
var bursts: Array[Dictionary] = []    # pos, life, color
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _step_t := 0.0
var sprite_pad := 0              # 1 quando os desenhos têm contorno
var tex_scale := 1.0             # píxeis da textura por ponto do desenho
var glow_map := {}               # textura -> brilho (estilos com néon)
var glow_pad := 4
var glow_alpha := 0.85
var static_vp: SubViewport
var static_canvas: Node2D


func attach(g: ChuckieGame) -> void:
	game = g
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	static_vp = SubViewport.new()
	static_vp.size = Vector2i(1280, 720)
	static_vp.disable_3d = true
	static_vp.transparent_bg = true
	static_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(static_vp)
	static_canvas = Node2D.new()
	static_vp.add_child(static_canvas)
	static_canvas.draw.connect(func() -> void: _draw_static(static_canvas))
	g.match_started.connect(_on_match_started)
	g.level_started.connect(_on_level_started)
	g.turn_started.connect(_on_turn_started)
	g.egg_taken.connect(_on_egg_taken)
	g.grain_taken.connect(_on_grain_taken)
	g.jumped.connect(_on_jumped)
	g.landed.connect(_on_landed)
	g.player_died.connect(_on_player_died)
	g.level_cleared.connect(_on_level_cleared)
	g.extra_life.connect(_on_extra_life)
	g.game_over.connect(_on_game_over)
	var cached: Variant = Synth.cache_get(get_script().resource_path)
	if cached != null:
		sfx = cached
	else:
		_build_sfx()
		Synth.cache_set(get_script().resource_path, sfx)
	_setup()
	rebake()


## Volta a gravar o cenário estático (plataformas e escadas) na textura.
func rebake() -> void:
	if static_vp == null:
		return
	static_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	static_canvas.queue_redraw()


func play(id: String, pitch := 1.0, volume_db := 0.0) -> void:
	if game == null or game.mode == ChuckieGame.Mode.DEMO or not sfx.has(id):
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
	if not game.paused:
		time += delta
		if game.state == ChuckieGame.State.PLAY:
			# passos e degraus
			var walking := game.move == ChuckieGame.Move.WALK and _moving()
			var climbing := game.move == ChuckieGame.Move.CLIMB and _moving()
			if walking or climbing:
				_step_t -= delta
				if _step_t <= 0.0:
					_step_t = 0.16 if walking else 0.2
					play("step" if walking else "climb", randf_range(0.95, 1.05), -8.0)
		for p in popups:
			p.life -= delta
			p.pos.y -= 8.0 * delta
		popups = popups.filter(func(p: Dictionary) -> bool: return p.life > 0.0)
		for b in bursts:
			b.life -= delta
		bursts = bursts.filter(func(b: Dictionary) -> bool: return b.life > 0.0)
		_tick(delta)
	queue_redraw()


var _last := Vector2.ZERO


func _moving() -> bool:
	var p := Vector2(game.px, game.py)
	var m := p.distance_to(_last) > 0.01
	_last = p
	return m


# ---------------------------------------------------------------- ajudas

func px(u: Vector2) -> Vector2:
	return game.to_px(u)


func field_rect() -> Rect2:
	return Rect2(ChuckieGame.ORIGIN, ChuckieGame.FIELD * S)


func tile_rect(c: int, r: int) -> Rect2:
	return Rect2(ChuckieGame.ORIGIN + Vector2(c, r) * T * S, Vector2(T, T) * S)


func panel_left_x() -> float:
	return ChuckieGame.ORIGIN.x / 2


func panel_right_x() -> float:
	var r := ChuckieGame.ORIGIN.x + ChuckieGame.FIELD.x * S
	return r + (1280.0 - r) / 2


func farmer_rows(frame: String) -> Array:
	return FARMER_HEAD + FARMER_LEGS[frame]


## Nome do desenho atual do agricultor e se está espelhado.
func farmer_frame() -> Array:
	var g := game
	if g.move == ChuckieGame.Move.CLIMB:
		return ["climb", int(g.anim * 8.0) % 2 == 1]
	if g.move == ChuckieGame.Move.AIR:
		return ["jump", g.facing < 0]
	var f := "stand"
	if g.state == ChuckieGame.State.PLAY and _walking_now():
		f = "walk0" if int(g.anim * 9.0) % 2 == 0 else "walk1"
	return [f, g.facing < 0]


var _anim_seen := 0.0
var _anim_changed := 0.0


func _walking_now() -> bool:
	if game.anim != _anim_seen:
		_anim_seen = game.anim
		_anim_changed = time
	return time - _anim_changed < 0.06


func hen_frame(h: Dictionary) -> String:
	if h.peck > 0.0:
		return "peck"
	if h.move == ChuckieGame.Move.CLIMB:
		return "climb"
	return "walk0" if int(float(h.anim) * 6.0) % 2 == 0 else "walk1"


## Cria as texturas dos desenhos com as paletes do estilo (podem ter contorno).
func build_sprites(farmer_pal: Dictionary, hen_pal: Dictionary, duck_pal: Dictionary, egg_pal: Dictionary, grain_pal: Dictionary, outline := Color(0, 0, 0, 0)) -> void:
	for f: String in FARMER_LEGS:
		tex["farmer_" + f] = make_tex(farmer_rows(f), farmer_pal, outline)
	tex.farmer_climb = make_tex(FARMER_CLIMB, farmer_pal, outline)
	for f: String in HEN:
		tex["hen_" + f] = make_tex(HEN[f], hen_pal, outline)
	tex.duck0 = make_tex(DUCK[0], duck_pal, outline)
	tex.duck1 = make_tex(DUCK[1], duck_pal, outline)
	tex.egg = make_tex(EGG, egg_pal, outline)
	tex.grain = make_tex(GRAIN, grain_pal, outline)
	sprite_pad = 1 if outline.a > 0.0 else 0


## Os estilos podem trocar a forma de fazer as texturas (ex.: ponto de cruz).
func make_tex(rows: Array, pal: Dictionary, outline: Color) -> Texture2D:
	return PixelArt.outlined(rows, pal, outline, 1)


## Desenha uma textura com a base (pés) em `feet` (unidades), centrada em x.
func draw_feet(t: Texture2D, feet: Vector2, flip := false, modulate_c := Color.WHITE, scale_k := 1.0) -> void:
	var size := t.get_size() * S * scale_k / tex_scale
	var pos := px(feet) - Vector2(size.x / 2, size.y - sprite_pad * S * scale_k)
	if glow_map.has(t):
		var gl: Texture2D = glow_map[t]
		var gs := gl.get_size() * S * scale_k
		var gp := pos - Vector2(glow_pad, glow_pad) * S * scale_k + Vector2(sprite_pad, sprite_pad) * S * scale_k
		var gc := Color(modulate_c, modulate_c.a * glow_alpha)
		if flip:
			draw_texture_rect(gl, Rect2(gp + Vector2(gs.x, 0), Vector2(-gs.x, gs.y)), false, gc)
		else:
			draw_texture_rect(gl, Rect2(gp, gs), false, gc)
	if flip:
		draw_texture_rect(t, Rect2(pos + Vector2(size.x, 0), Vector2(-size.x, size.y)), false, modulate_c)
	else:
		draw_texture_rect(t, Rect2(pos, size), false, modulate_c)


# ---------------------------------------------------------------- desenho por omissão

func _draw() -> void:
	if game == null:
		return
	_draw_back()
	draw_texture(static_vp.get_texture(), Vector2.ZERO)
	_draw_items()
	_draw_lifts()
	for h in game.hens:
		_draw_hen(h)
	_draw_player()
	_draw_duck()
	_draw_effects()
	_draw_hud()


func _draw_items() -> void:
	for cell: Vector2i in game.eggs:
		draw_feet(tex.egg, Vector2(cell.x * T + 4, (cell.y + 1) * T))
	for cell: Vector2i in game.grain:
		draw_feet(tex.grain, Vector2(cell.x * T + 4, (cell.y + 1) * T))


func _draw_hen(h: Dictionary) -> void:
	var f := hen_frame(h)
	draw_feet(tex["hen_" + f], Vector2(h.x, h.y), f != "climb" and h.dir < 0)


func _draw_player() -> void:
	var g := game
	if g.state == ChuckieGame.State.OVER:
		return
	var fr := farmer_frame()
	var t: Texture2D = tex["farmer_" + fr[0]]
	if g.state == ChuckieGame.State.DYING:
		# rodopia e afunda
		var k := clampf(1.0 - g.timer / 2.0, 0.0, 1.0)
		var c := px(Vector2(g.px, g.py - 8.0))
		draw_set_transform(c, k * TAU * 2.0, Vector2.ONE * (1.0 - k * 0.6))
		var ts := t.get_size() * S / tex_scale
		draw_texture_rect(t, Rect2(-ts / 2, ts), false, Color(1, 1, 1, 1.0 - k * 0.5))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	if g.state == ChuckieGame.State.READY and fmod(time, 0.3) < 0.12:
		return
	draw_feet(t, Vector2(g.px, g.py), fr[1])


func _draw_duck() -> void:
	var t: Texture2D = tex.duck0 if fmod(time, 0.5) < 0.25 or not game.duck.free else tex.duck1
	var pos: Vector2 = game.duck.pos
	var flip: bool = game.duck.free and float(game.duck.vel.x) < 0.0
	var size := t.get_size() * S / tex_scale
	var p := px(pos) - size / 2
	if glow_map.has(t):
		var gl: Texture2D = glow_map[t]
		var gs := gl.get_size() * S
		draw_texture_rect(gl, Rect2(px(pos) - gs / 2, gs), false, Color(1, 1, 1, glow_alpha))
	if flip:
		draw_texture_rect(t, Rect2(p + Vector2(size.x, 0), Vector2(-size.x, size.y)), false)
	else:
		draw_texture_rect(t, Rect2(p, size), false)
	if not game.duck.free:
		_draw_cage()


func _draw_cage() -> void:
	var r := Rect2(px(Vector2(0, 0)), Vector2(32, 32) * S)
	for i in 9:
		draw_rect(Rect2(r.position.x + i * r.size.x / 8 - 2, r.position.y, 4, r.size.y), cage_color())
	draw_rect(Rect2(r.position, Vector2(r.size.x, 6)), cage_color())
	draw_rect(Rect2(r.position + Vector2(0, r.size.y - 6), Vector2(r.size.x, 6)), cage_color())


func cage_color() -> Color:
	return Color.GREEN


func _draw_lifts() -> void:
	for l in game.lifts:
		var p := px(Vector2(float(l.x) - 8.0, float(l.y)))
		draw_rect(Rect2(p, Vector2(16 * S, 2 * S)), lift_color())


func lift_color() -> Color:
	return Color.WHITE


func _draw_effects() -> void:
	var st: Variant = game.touch_stick()
	if st != null:
		draw_arc(st, 60, 0, TAU, 32, Color(1, 1, 1, 0.25), 3.0)
		draw_circle((st as Vector2) + game._touch_dir.limit_length(60), 18, Color(1, 1, 1, 0.25))
	for b in bursts:
		var k: float = 1.0 - float(b.life) / 0.4
		var c := px(b.pos)
		for i in 8:
			var d := Vector2.from_angle(i * TAU / 8) * (6.0 + 30.0 * k)
			draw_rect(Rect2(c + d - Vector2(3, 3), Vector2(6, 6)), Color(b.color, 1.0 - k))


func _draw_back() -> void:
	pass


# ---------------------------------------------------------------- para os estilos reescreverem

func _setup() -> void:
	pass


func _build_sfx() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _draw_static(_ci: CanvasItem) -> void:
	pass


func _draw_hud() -> void:
	pass


func ui_palette() -> Dictionary:
	return UI.LAUNCHER_PALETTE


func _on_match_started() -> void:
	popups.clear()
	bursts.clear()


func _on_level_started(_level: int) -> void:
	rebake()


func _on_turn_started(_player: int) -> void:
	rebake()


func _on_egg_taken(pos: Vector2) -> void:
	popups.append({"pos": pos, "text": str(ChuckieGame.EGG_POINTS), "life": 0.8})
	bursts.append({"pos": pos, "life": 0.4, "color": Color.WHITE})
	play("egg")


func _on_grain_taken(pos: Vector2, by_hen: bool) -> void:
	if by_hen:
		play("peck", 1.0, -6.0)
	else:
		popups.append({"pos": pos, "text": str(ChuckieGame.GRAIN_POINTS), "life": 0.8})
		play("grain")


func _on_jumped() -> void:
	play("jump")


func _on_landed() -> void:
	play("land", 1.0, -6.0)


func _on_player_died(_pos: Vector2) -> void:
	play("die")


func _on_level_cleared(_bonus: int) -> void:
	play("clear")


func _on_extra_life() -> void:
	play("extra")


func _on_game_over() -> void:
	pass
