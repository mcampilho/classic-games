class_name OutRunSkin
extends Node2D
## Base dos estilos visuais do OutRun: projeção pseudo-3D da estrada (segmentos desenhados de trás
## para a frente, com colinas a tapar o que está atrás), cenário, trânsito, carro do jogador,
## paisagem de fundo em paralaxe, motor, rádio e efeitos sonoros.
## Os estilos escolhem cores, desenhos e HUD.

const W := 1280.0
const H := 720.0
const LAYER_PERIOD := 2560.0
const LAYER_STEP := 20.0

# ---------------------------------------------------------------- desenhos (originais)
# Carro do jogador: descapotável genérico visto de trás, com dois ocupantes.
const PLAYER_CAR := [
	"........YYYY......yyyy........",
	".......YYYYYY....yyyyyy.......",
	"....GGGYYYYYYGGGGyyyyyyGGG....",
	"...GDDDYYYYYYDDDDyyyyyyDDDG...",
	"..BBBBBBBBBBBBBBBBBBBBBBBBBB..",
	".BHHHHHHHHHHHHHHHHHHHHHHHHHHB.",
	".BBBBBBBBBBBBBBBBBBBBBBBBBBBB.",
	"BRRRRBBBBBBBBBBBBBBBBBBBBRRRRB",
	"BRrrRBBBBBBBBPPPPBBBBBBBBRrrRB",
	"BbbbbbbbbbbbbPPPPbbbbbbbbbbbbB",
	"GGGGGGGGGGGGGGGGGGGGGGGGGGGGGG",
	".KKKKK..................KKKKK.",
	".KKKKK..................KKKKK.",
]
const TRAFFIC := {
	"car": [
		"......BBBBBBBBBBBBBB......",
		".....BWWWWWWWWWWWWWWB.....",
		"....BBWWWWWWWWWWWWWWBB....",
		"..BBBBBBBBBBBBBBBBBBBBBB..",
		".BHHHHHHHHHHHHHHHHHHHHHHB.",
		".BRRRBBBBBBBBBBBBBBBBRRRB.",
		".BRRRBBBBBBPPPPBBBBBBRRRB.",
		".bbbbbbbbbbPPPPbbbbbbbbbb.",
		".GGGGGGGGGGGGGGGGGGGGGGGG.",
		"..KKKK..............KKKK..",
	],
	"van": [
		"..BBBBBBBBBBBBBBBBBBBB..",
		".BHHHHHHHHHHHHHHHHHHHHB.",
		".BWWWWWWWWWBBWWWWWWWWWB.",
		".BWWWWWWWWWBBWWWWWWWWWB.",
		".BBBBBBBBBBBBBBBBBBBBBB.",
		".BBBBBBBBBBbbBBBBBBBBBB.",
		".BBBBBBBBBBbbBBBBBBBBBB.",
		".BRRBBBBBBBbbBBBBBBBRRB.",
		".BRRBBBBBPPPPPPBBBBBRRB.",
		".bbbbbbbbPPPPPPbbbbbbbb.",
		".GGGGGGGGGGGGGGGGGGGGGG.",
		"..KKKK............KKKK..",
	],
	"truck": [
		"HHHHHHHHHHHHHHHHHHHHHHHHHHHH",
		"BBBBBBBBBBBBBBBBBBBBBBBBBBBB",
		"BBBBBBBBBBBBbbBBBBBBBBBBBBBB",
		"BBBBBBBBBBBBbbBBBBBBBBBBBBBB",
		"BBBBBBBBBBBBbbBBBBBBBBBBBBBB",
		"BBBBBBBBBBGBbbBGBBBBBBBBBBBB",
		"BBBBBBBBBBGBbbBGBBBBBBBBBBBB",
		"BBBBBBBBBBBBbbBBBBBBBBBBBBBB",
		"BBBBBBBBBBBBbbBBBBBBBBBBBBBB",
		"BBBBBBBBBBBBbbBBBBBBBBBBBBBB",
		"bbbbbbbbbbbbbbbbbbbbbbbbbbbb",
		"GGGGGGGGGGGGGGGGGGGGGGGGGGGG",
		"RR.......GPPPPPPPPG.......RR",
		"..KKKKK..............KKKKK..",
	],
	"beetle": [
		"......BBBBBBBB......",
		"....BBWWWWWWWWBB....",
		"...BBWWWWWWWWWWBB...",
		"..BBBBBBBBBBBBBBBB..",
		".BBHHHHHHHHHHHHHHBB.",
		".BRRBBBBBBBBBBBBRRB.",
		".BRRBBBBPPPPBBBBRRB.",
		"..bbbbbbPPPPbbbbbb..",
		"..GGGGGGGGGGGGGGGG..",
		"..KKK..........KKK..",
	],
}

# Cenário (letras: T tronco, t tronco escuro, L folhas, l folhas escuras, F flor/fruto,
# W branco/neve, R vermelho, Y amarelo, K escuro, G cinzento, S pedra, s pedra escura, D porta/janela)
const ART := {
	"palm": [
		"...LL......LLL....",
		"..LLLL...LLLLLL...",
		".LL..LL.LL...LLL..",
		"LL....LLLLL....LL.",
		"L...lLLFFLLl....L.",
		"...lL.LFFTLLl.....",
		"..lL..L.TT..Ll....",
		".lL....TT....Ll...",
		".L.....TT.....L...",
		"......TT..........",
		"......TT..........",
		"......Tt..........",
		".......TT.........",
		".......TT.........",
		".......tT.........",
		".......TT.........",
		"......TT..........",
		"......TT..........",
		"......Tt..........",
		"......TT..........",
		".......TT.........",
		".......TT.........",
		".......tT.........",
		"......TTTT........",
	],
	"umbrella": [
		"......RR......",
		"...RRWWRRWW...",
		".RRWWRRWWRRWW.",
		"RRWWRRWWRRWWRR",
		"......TT......",
		"......TT......",
		"......TT......",
		"......TT......",
		"...SSSSSSSS...",
		"..SSSSSSSSSS..",
	],
	"cactus": [
		".....LL.....",
		"....LLLl....",
		"....LLLl..L.",
		".L..LLLl.LLl",
		"LLl.LLLl.LLl",
		"LLl.LLLl.LLl",
		"LLl.LLLlLLLl",
		"LLLLLLLlLLl.",
		".LLLLLLll...",
		"....LLLl....",
		"....LLLl....",
		"....LLLl....",
		"....LLLl....",
		"....LLLl....",
		"...sLLLls...",
		"..ssssssss..",
	],
	"rock": [
		"......SSSS........",
		"....SSSSSSSs......",
		"...SSSSSSSSSs.....",
		"..SSSSSSSSSSSsSS..",
		".SSSSSSSSSSSSsSSs.",
		"SSSSSSSSSSSSSssSSs",
		"SSSSSSSSSSSSsssSss",
		"ssssssssssssssssss",
	],
	"deadtree": [
		"..T.......T.....",
		"..TT.....T...T..",
		"...T..T..T..T...",
		"...TT.T.TT.TT...",
		"....TTT.T.TT....",
		".T....TTTTT.....",
		"..TT...TTT......",
		"....TT.TTt......",
		"......TTTt......",
		".......TTt......",
		".......TTt......",
		".......TTt......",
		".......TTt......",
		".......TTt......",
		"......TTTtt.....",
		".....TTTTttt....",
	],
	"pine": [
		".......L......",
		"......LLl.....",
		".....LLLLl....",
		"....LLLLLLl...",
		"......LLl.....",
		".....LLLLl....",
		"....LLLLLLl...",
		"...LLLLLLLLl..",
		".....LLLLl....",
		"....LLLLLLl...",
		"...LLLLLLLLl..",
		"..LLLLLLLLLLl.",
		"....LLLLLLl...",
		"...LLLLLLLLl..",
		"..LLLLLLLLLLl.",
		".LLLLLLLLLLLLl",
		"......TT......",
		"......Tt......",
		"......TT......",
	],
	"snowpine": [
		".......W......",
		"......WWl.....",
		".....WLLLl....",
		"....WWLLLLl...",
		"......WWl.....",
		".....WWLLl....",
		"....WLLLLLl...",
		"...WWWLLLLLl..",
		".....WWLLl....",
		"....WWLLLLl...",
		"...WLLLLLLLl..",
		"..WWWWLLLLLLl.",
		"....WWLLLLl...",
		"...WWLLLLLLl..",
		"..WLLLLLLLLLl.",
		".WWWWWLLLLLLLl",
		"......TT......",
		"......Tt......",
		"......TT......",
	],
	"oak": [
		".....LLLLLL.......",
		"...LLLLLLLLLL.....",
		"..LLLLLLLLLLLLl...",
		".LLLLLLLLLLLLLLl..",
		"LLLLLLLLLLLLLLLLl.",
		"LLLLLLLLLLLLLLLLll",
		"LLLLLLLLLLLLLLLlll",
		".LLLLLLLLLLLLLllll",
		"..lLLLLLLLLLLlll..",
		"...llllTTlllll....",
		"......TTTt........",
		"......TTTt........",
		"......TTTt........",
		"......TTTt........",
		".....TTTTtt.......",
	],
	"bush": [
		"....LLLL..LLL.",
		"..LLLLLLLLLLLl",
		".LLLFLLLLLFLLl",
		"LLLLLLLLLLLLll",
		"LLLLLLLLLLLlll",
		".llllllllllll.",
	],
	"chalet": [
		".........RR.........",
		".......RRRRRR.......",
		".....RRRRRRRRRR.....",
		"...RRRRRRRRRRRRRR...",
		".RRRRRRRRRRRRRRRRRR.",
		"RRRRRRRRRRRRRRRRRRRR",
		"..TTTTTTTTTTTTTTTT..",
		"..TWWTTTTTTTTTTWWT..",
		"..TWWTTTTDDTTTTWWT..",
		"..TTTTTTTDDTTTTTTT..",
		"..ttttttttttttttttt.",
		"..TWWTTTTDDTTTTWWT..",
		"..TTTTTTTDDTTTTTTT..",
		"..SSSSSSSSSSSSSSSS..",
	],
	"house": [
		"........RRRR........",
		"......RRRRRRRR......",
		"....RRRRRRRRRRRR....",
		"..RRRRRRRRRRRRRRRR..",
		"RRRRRRRRRRRRRRRRRRRR",
		".WWWWWWWWWWWWWWWWWW.",
		".WWDDWWWWWWWWWWDDWW.",
		".WWDDWWWWWWWWWWDDWW.",
		".WWWWWWWWDDWWWWWWWW.",
		".WWWWWWWWDDWWWWWWWW.",
		".WWDDWWWWDDWWWWDDWW.",
		".WWWWWWWWDDWWWWWWWW.",
		".SSSSSSSSSSSSSSSSSS.",
	],
	"cypress": [
		"...L...",
		"..LLl..",
		"..LLl..",
		".LLLLl.",
		".LLLLl.",
		".LLLLl.",
		"LLLLLLl",
		"LLLLLLl",
		"LLLLLLl",
		"LLLLLLl",
		"LLLLLLl",
		"LLLLLll",
		".LLLll.",
		".LLLll.",
		"..lll..",
		"...T...",
		"...T...",
	],
	"vine": [
		"T.....T.....T.....T.",
		"TLLlLLTLLlLLTLLlLLT.",
		"LLFLLLLLFLLLLLFLLLLl",
		"LLLLlLLLLLlLLLLLlLLl",
		"lLFLLllLLFLlLLFLLll.",
		"T.....T.....T.....T.",
		"T.....T.....T.....T.",
	],
	"lamp": [
		"GGGGGG..",
		"OutRunGame...YYY.",
		"OutRunGame....Y..",
		"OutRunGame.......",
		"OutRunGame.......",
		"OutRunGame.......",
		"OutRunGame.......",
		"OutRunGame.......",
		"OutRunGame.......",
		"OutRunGame.......",
		"OutRunGame.......",
		"OutRunGame.......",
		"OutRunGame.......",
		"OutRunGame.......",
		"OutRunGame.......",
		"OutRunGame.......",
		"GG......",
	],
}
## Que desenho usa cada tipo de cenário (palm2 é a palmeira espelhada).
const ART_FOR := {"palm2": "palm"}

var game: OutRunGame
var sfx := {}
var tex := {}
var time := 0.0
var radio := 0                    # índice da música; -1 = rádio desligado
var bg_scroll := 0.0              # deslocação da paisagem (acumula as curvas percorridas)
var theme := "costa"
var prev_theme := "costa"
var theme_blend := 1.0
var rows: Array[Dictionary] = []  # segmentos projetados (do mais próximo para o mais distante)
var popups: Array[Dictionary] = []   # {text, life, color}
var flash := 0.0
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _engine: AudioStreamPlayer
var _skid: AudioStreamPlayer
var _music: AudioStreamPlayer
var _last_z := 0.0
var _layers := {}                 # paisagens geradas, por tema
var _sprite_cache := {}
var _fc := {}
var _qv := PackedVector2Array()
var _qc := PackedColorArray()
var _qi := PackedInt32Array()


func attach(g: OutRunGame) -> void:
	game = g
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_engine = AudioStreamPlayer.new()
	add_child(_engine)
	_skid = AudioStreamPlayer.new()
	add_child(_skid)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -5.0
	add_child(_music)
	g.race_started.connect(_on_race_started)
	g.countdown.connect(_on_countdown)
	g.stage_started.connect(_on_stage_started)
	g.checkpoint.connect(_on_checkpoint)
	g.crashed.connect(_on_crashed)
	g.bumped.connect(_on_bumped)
	g.gear_changed.connect(_on_gear_changed)
	g.time_warning.connect(_on_time_warning)
	g.goal.connect(_on_goal)
	g.time_up.connect(_on_time_up)
	g.game_over.connect(_on_game_over)
	var cached: Variant = Synth.cache_get(get_script().resource_path)
	if cached != null:
		sfx = cached
	else:
		_build_sfx()
		Synth.cache_set(get_script().resource_path, sfx)
	theme = g.theme
	prev_theme = g.theme
	_setup()


func play(id: String, pitch := 1.0, volume_db := 0.0) -> void:
	if game == null or game.mode == OutRunGame.Mode.DEMO or not sfx.has(id):
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = sfx[id]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


static func _looped(s: AudioStreamWAV) -> AudioStreamWAV:
	if s.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = s.data.size() / 2
	return s


func _process(delta: float) -> void:
	if game == null:
		return
	var silent := game.paused or game.mode == OutRunGame.Mode.DEMO
	_update_audio(silent)
	if not game.paused:
		time += delta
		var dz := game.position_z - _last_z
		if dz > 0.0 and dz < OutRunGame.SEG_LEN * 20:
			bg_scroll += float(game.player_segment().curve) * dz / OutRunGame.SEG_LEN
		_last_z = game.position_z
		theme_blend = minf(theme_blend + delta / 2.5, 1.0)
		flash = maxf(flash - delta, 0.0)
		for p in popups:
			p.life -= delta
		popups = popups.filter(func(p: Dictionary) -> bool: return p.life > 0.0)
		_tick(delta)
	queue_redraw()


func _update_audio(silent: bool) -> void:
	var racing := game.state != OutRunGame.State.OVER
	# motor: o tom sobe com a velocidade (e cai ao meter a mudança alta)
	if sfx.has("engine"):
		if silent or not racing:
			if _engine.playing:
				_engine.stop()
		else:
			if not _engine.playing:
				_engine.stream = _looped(sfx.engine)
				_engine.play()
			var pct := game.speed / OutRunGame.MAX_SPEED
			var rev := pct
			if game.manual_gears:
				rev = pct / 0.6 if not game.high_gear else 0.35 + pct * 0.65
			_engine.pitch_scale = 0.55 + rev * 1.6
			_engine.volume_db = -12.0 + pct * 6.0
	# pneus a chiar nas curvas fortes ou fora de estrada
	if sfx.has("skid"):
		var seg := game.player_segment()
		var pct := game.speed / OutRunGame.MAX_SPEED
		var want := not silent and game.state == OutRunGame.State.PLAY and (
			(absf(float(seg.curve)) > 3.0 and pct > 0.7) or (not game.on_road(game.player_x, seg.index) and pct > 0.3))
		if want and not _skid.playing:
			_skid.stream = _looped(sfx.skid)
			_skid.volume_db = -10.0
			_skid.play()
		elif not want and _skid.playing:
			_skid.stop()
	# rádio
	var want_music := not silent and radio >= 0 and racing
	if want_music:
		if not _music.playing:
			var s := OutRunMusic.stream(radio)
			if s != null:
				_music.stream = s
				_music.play()
	elif _music.playing:
		if game.paused:
			_music.stream_paused = true
		else:
			_music.stop()
	if not game.paused and _music.stream_paused:
		_music.stream_paused = false


func set_radio(i: int) -> void:
	radio = i
	if _music:
		_music.stop()


func ui_palette() -> Dictionary:
	return UI.LAUNCHER_PALETTE


# ---------------------------------------------------------------- projeção

func horizon_y() -> float:
	return H * 0.5 + clampf(game.player_y * 0.004, -40.0, 40.0)


func _project() -> void:
	rows.clear()
	var g := game
	var base := g.segment_at(g.position_z)
	var base_i: int = base.index
	var base_pct := fmod(g.position_z, OutRunGame.SEG_LEN) / OutRunGame.SEG_LEN
	var cam_y := g.player_y + OutRunGame.CAM_HEIGHT
	var cam_x := g.player_x * OutRunGame.ROAD_W
	var depth := g.camera_depth
	var half_w := W / 2
	var half_h := H / 2
	var x := 0.0
	var dx := -float(base.curve) * base_pct
	var maxy := H
	var pending := {}
	for n in OutRunGame.DRAW_DIST:
		var i := base_i + n
		var s := g.seg(i)
		var z1 := i * OutRunGame.SEG_LEN - g.position_z
		var curve := float(s.curve)
		if z1 <= depth:
			x += dx
			dx += curve
			continue
		if pending.is_empty():
			var sc1 := depth / z1
			pending = {"i": i, "seg": s, "n": n, "segs": [s],
				"x1": half_w + sc1 * (x - cam_x) * half_w, "y1": half_h - sc1 * (float(s.p1y) - cam_y) * half_h,
				"w1": sc1 * OutRunGame.ROAD_W * half_w, "s1": sc1, "c1": g.fork_c(i)}
		else:
			pending.segs.append(s)
		# ao longe, juntam-se 2 ou 3 segmentos numa só faixa (menos trabalho, a diferença não se vê)
		var group := 1 if n < 70 else (2 if n < 140 else 3)
		if pending.segs.size() >= group:
			var sc2 := depth / (z1 + OutRunGame.SEG_LEN)
			pending.x2 = half_w + sc2 * (x + dx - cam_x) * half_w
			pending.y2 = half_h - sc2 * (float(s.p2y) - cam_y) * half_h
			pending.w2 = sc2 * OutRunGame.ROAD_W * half_w
			pending.s2 = sc2
			pending.c2 = g.fork_c(i + 1)
			pending.fog = fog_at(float(pending.n) / OutRunGame.DRAW_DIST)
			var vis: bool = pending.y2 < pending.y1 and pending.y2 < maxy
			pending.visible = vis
			if vis:
				maxy = pending.y2
			rows.append(pending)
			pending = {}
		x += dx
		dx += curve


## 0 = sem nevoeiro, 1 = totalmente coberto (os estilos podem mudar a curva).
func fog_at(d: float) -> float:
	return clampf(pow(d, 2.2) * 1.3 - 0.15, 0.0, 1.0)


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	if game == null or game.segments.is_empty():
		return
	_fc = frame_colors()
	_project()
	_draw_background()
	# bucket dos carros por segmento
	var by_seg := {}
	for car in game.cars:
		var i := floori(float(car.z) / OutRunGame.SEG_LEN)
		if not by_seg.has(i):
			by_seg[i] = []
		by_seg[i].append(car)
	var fade := clampf(game.stage_time / 1.2, 0.0, 1.0)
	for k in range(rows.size() - 1, -1, -1):
		var r: Dictionary = rows[k]
		if r.visible:
			_draw_row(r)
		for sg: Dictionary in r.segs:
			var sprites: Array = sg.sprites
			if not sprites.is_empty():
				flush_quads()
				for sp: Dictionary in sprites:
					_place_sprite(r, sp, fade)
			if by_seg.has(sg.index):
				flush_quads()
				for car: Dictionary in by_seg[sg.index]:
					_place_car(r, car, fade)
	flush_quads()
	_draw_player()
	_draw_hud()


## Desenha uma faixa da estrada (relva, bermas, asfalto e linhas), incluindo a bifurcação.
func _draw_row(r: Dictionary) -> void:
	var k := 0 if r.seg.light else 1
	var f: float = r.fog
	var grass: Color = _fc.grass[k]
	var rumble: Color = _fc.rumble[k]
	var road: Color = _fc.road[k]
	var lane: Color = _fc.lane[k]
	if f > 0.0:
		var fog: Color = _fc.fog
		grass = grass.lerp(fog, f)
		rumble = rumble.lerp(fog, f)
		road = road.lerp(fog, f)
		lane.a *= 1.0 - f
	var y1: float = r.y1
	var y2: float = r.y2
	var x1: float = r.x1
	var x2: float = r.x2
	var w1: float = r.w1
	var w2: float = r.w2
	quad(Vector2(0, y2), Vector2(W, y2), Vector2(W, y1 + 1), Vector2(0, y1 + 1), grass)
	var c1: float = r.c1
	var c2: float = r.c2
	if c1 <= 0.0 and c2 <= 0.0:
		# estrada única (o caso habitual): berma por baixo, asfalto e duas linhas
		var e1 := w1 * 1.16
		var e2 := w2 * 1.16
		quad(Vector2(x1 - e1, y1), Vector2(x1 + e1, y1), Vector2(x2 + e2, y2), Vector2(x2 - e2, y2), rumble)
		quad(Vector2(x1 - w1, y1), Vector2(x1 + w1, y1), Vector2(x2 + w2, y2), Vector2(x2 - w2, y2), road)
		if lane.a > 0.0:
			var l1 := w1 / 3.0
			var l2 := w2 / 3.0
			var t1 := w1 * 0.025
			var t2 := w2 * 0.025
			quad(Vector2(x1 - l1 - t1, y1), Vector2(x1 - l1 + t1, y1), Vector2(x2 - l2 + t2, y2), Vector2(x2 - l2 - t2, y2), lane)
			quad(Vector2(x1 + l1 - t1, y1), Vector2(x1 + l1 + t1, y1), Vector2(x2 + l2 + t2, y2), Vector2(x2 + l2 - t2, y2), lane)
		_draw_row_extra(r)
		return
	var rw := 0.16
	for s: float in [-1.0, 1.0]:
		strip(r, s * c1 - 1.0 - rw, s * c1 + 1.0 + rw, s * c2 - 1.0 - rw, s * c2 + 1.0 + rw, rumble)
	for s: float in [-1.0, 1.0]:
		strip(r, s * c1 - 1.0, s * c1 + 1.0, s * c2 - 1.0, s * c2 + 1.0, road)
	if lane.a > 0.0:
		var lw := 0.025
		var lanes: Array[Vector2] = []    # (posição em baixo, posição em cima)
		if c1 < 1.0:
			lanes = [Vector2(-c1 - 1.0 / 3.0, -c2 - 1.0 / 3.0), Vector2(0, 0), Vector2(c1 + 1.0 / 3.0, c2 + 1.0 / 3.0)]
		else:
			for s: float in [-1.0, 1.0]:
				lanes.append(Vector2(s * c1 - 1.0 / 3.0, s * c2 - 1.0 / 3.0))
				lanes.append(Vector2(s * c1 + 1.0 / 3.0, s * c2 + 1.0 / 3.0))
		for l in lanes:
			strip(r, l.x - lw, l.x + lw, l.y - lw, l.y + lw, lane)
	_draw_row_extra(r)


## Trapézio entre duas posições laterais (em meias-larguras de estrada), em baixo e em cima.
func strip(r: Dictionary, a1: float, b1: float, a2: float, b2: float, color: Color) -> void:
	var x1: float = r.x1
	var x2: float = r.x2
	var w1: float = r.w1
	var w2: float = r.w2
	quad(Vector2(x1 + w1 * a1, r.y1), Vector2(x1 + w1 * b1, r.y1), Vector2(x2 + w2 * b2, r.y2), Vector2(x2 + w2 * a2, r.y2), color)


## Quadriláteros da estrada: juntam-se num só lote e são enviados de uma vez (flush_quads),
## o que é muito mais rápido do que um polígono de cada vez.
func quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> void:
	var n := _qv.size()
	_qv.append(a)
	_qv.append(b)
	_qv.append(c)
	_qv.append(d)
	_qc.append(color)
	_qc.append(color)
	_qc.append(color)
	_qc.append(color)
	_qi.append(n)
	_qi.append(n + 1)
	_qi.append(n + 2)
	_qi.append(n)
	_qi.append(n + 2)
	_qi.append(n + 3)


func quad_rect(r: Rect2, color: Color) -> void:
	quad(r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), color)


func flush_quads() -> void:
	if _qv.is_empty():
		return
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _qi, _qv, _qc)
	_qv = PackedVector2Array()
	_qc = PackedColorArray()
	_qi = PackedInt32Array()


func _place_sprite(r: Dictionary, sp: Dictionary, fade: float) -> void:
	var sc: float = r.s1
	var dw: float = float(sp.w) * sc * W / 2
	if dw < 1.0:
		return
	var off: float = sp.offset
	var cx: float = r.x1 + sc * off * OutRunGame.ROAD_W * W / 2
	var left := cx - dw if off < 0.0 else (cx if off > 0.0 else cx - dw / 2)
	var alpha := (1.0 - float(r.fog) * 0.85) * (fade if r.i > 30 else 1.0)
	if alpha <= 0.02:
		return
	_draw_sprite(sp, Rect2(left, r.y1, dw, float(sp.h) * sc * W / 2), alpha, r)


func _place_car(r: Dictionary, car: Dictionary, fade: float) -> void:
	var z: float = float(car.z) - game.position_z
	if z <= game.camera_depth * 50.0:
		return
	var sc := game.camera_depth / z
	var pct: float = (float(car.z) - r.i * OutRunGame.SEG_LEN) / (OutRunGame.SEG_LEN * r.segs.size())
	var cx: float = lerpf(r.x1, r.x2, pct) + sc * game.car_x(car) * OutRunGame.ROAD_W * W / 2
	var y: float = lerpf(r.y1, r.y2, pct)
	var dw: float = float(car.w) * OutRunGame.ROAD_W * sc * W / 2
	if dw < 1.5:
		return
	var alpha := (1.0 - float(r.fog) * 0.85) * fade
	_draw_car(car, Rect2(cx - dw / 2, y, dw, 0.0), alpha, r)


## Retângulo do carro do jogador no ecrã (base ao centro, em baixo).
func player_rect(aspect: float) -> Rect2:
	var w := OutRunGame.PLAYER_W * OutRunGame.ROAD_W / OutRunGame.CAM_HEIGHT * W / 2
	var h := w * aspect
	var bounce := 0.0
	var pct := game.speed / OutRunGame.MAX_SPEED
	if game.state == OutRunGame.State.PLAY:
		var off := not game.on_road(game.player_x, game.player_segment().index)
		bounce = sin(time * (40.0 if off else 25.0)) * pct * (5.0 if off else 1.5)
	var hop := absf(sin(game.crash_spin * 0.5)) * 70.0 if game.state == OutRunGame.State.CRASH else 0.0
	return Rect2(W / 2 - w / 2, H - 12 - h + bounce - hop, w, h)


## Desenha uma textura cortando a parte de baixo abaixo de clip_y (se houver).
func draw_tex(t: Texture2D, rect: Rect2, alpha := 1.0, flip := false, modulate_c := Color.WHITE) -> void:
	var m := Color(modulate_c, modulate_c.a * alpha)
	if flip:
		draw_texture_rect(t, Rect2(rect.position + Vector2(rect.size.x, 0), Vector2(-rect.size.x, rect.size.y)), false, m)
	else:
		draw_texture_rect(t, rect, false, m)


## Textura de cenário (criada a pedido, por estilo e tema).
func sprite_texture(kind: String) -> Texture2D:
	var key := "%s/%s" % [theme_of_sprites(), kind]
	if _sprite_cache.has(key):
		return _sprite_cache[key]
	var art_name: String = ART_FOR.get(kind, kind)
	var t: Texture2D = null
	if ART.has(art_name):
		t = make_sprite(ART[art_name], sprite_palette(kind, theme_of_sprites()), sprite_outline(theme_of_sprites()))
	_sprite_cache[key] = t
	return t


const SIGN_TEXTS := ["ARCADE", "SOL", "PRAIA", "GELADOS", "1986", "TURBO", "CAFE", "RADIO"]


## Cenário: placas, pórticos e prédios são desenhados aqui com as cores do estilo;
## o resto usa as texturas de pixel art.
func _draw_sprite(sp: Dictionary, rect: Rect2, alpha: float, r: Dictionary) -> void:
	var kind: String = sp.kind
	var bottom := rect.position.y
	match kind:
		"sign", "fork_left", "fork_right", "fork_mid":
			var c := sprite_colors(r)
			var text := ""
			var panel: Color = c.sign_panel
			var ink: Color = c.sign_ink
			match kind:
				"sign":
					text = I18n.t(SIGN_TEXTS[int(r.i / 120) % SIGN_TEXTS.size()])
				"fork_left":
					text = "< " + str(sp.text)
					panel = c.fork_panel
				"fork_right":
					text = str(sp.text) + " >"
					panel = c.fork_panel
				"fork_mid":
					text = "<  >"
					panel = c.mid_panel
					ink = c.mid_ink
			billboard(rect, bottom, text, c.sign_frame, panel, ink, c.leg, alpha)
		"start", "goal":
			var c := sprite_colors(r)
			gantry(rect, bottom, I18n.t("PARTIDA") if kind == "start" else I18n.t("META"), c, alpha)
		"building", "building2":
			var c := sprite_colors(r)
			building(rect, bottom, c[kind], c.window, c.lit, alpha, r.i, c.get("outline", Color(0, 0, 0, 0)))
		_:
			var t := sprite_texture(kind)
			if t == null:
				return
			var h := rect.size.x * t.get_height() / t.get_width()
			draw_tex(t, Rect2(rect.position.x, bottom - h, rect.size.x, h), alpha, kind == "palm2")


## Texto ajustado a um retângulo (os estilos podem usar outra letra).
func fit_text(text: String, box: Rect2, color: Color) -> void:
	var cell := minf(box.size.x * 0.88 / maxf(PixelFont.width(text, 1.0), 1.0), box.size.y * 0.6 / 7.0)
	if cell >= 0.6:
		PixelFont.draw(self, text, box.get_center().x, box.get_center().y - cell * 3.5, cell, color)


func billboard(rect: Rect2, bottom: float, text: String, frame: Color, panel: Color, ink: Color, leg: Color, alpha: float) -> void:
	var w := rect.size.x
	var h := rect.size.y
	var lc := Color(leg, leg.a * alpha)
	draw_rect(Rect2(rect.position.x + w * 0.2, bottom - h * 0.45, w * 0.06, h * 0.45), lc)
	draw_rect(Rect2(rect.position.x + w * 0.74, bottom - h * 0.45, w * 0.06, h * 0.45), lc)
	var pr := Rect2(rect.position.x, bottom - h, w, h * 0.6)
	draw_rect(pr, Color(frame, frame.a * alpha))
	draw_rect(pr.grow(-maxf(w * 0.03, 1.0)), Color(panel, panel.a * alpha))
	fit_text(text, pr, Color(ink, ink.a * alpha))


func gantry(rect: Rect2, bottom: float, text: String, c: Dictionary, alpha: float) -> void:
	var w := rect.size.x
	var h := rect.size.y
	var pole := Color(c.pole, alpha)
	var pw := maxf(w * 0.012, 1.0)
	draw_rect(Rect2(rect.position.x, bottom - h, pw, h), pole)
	draw_rect(Rect2(rect.end.x - pw, bottom - h, pw, h), pole)
	var band := Rect2(rect.position.x, bottom - h, w, h * 0.22)
	draw_rect(band, Color(c.band, alpha))
	var sq := band.size.y / 2
	if sq >= 2.0:
		for k in 6:
			for j in 2:
				if (k + j) % 2 == 0:
					draw_rect(Rect2(band.position.x + k * sq, band.position.y + j * sq, sq, sq), Color(c.check, alpha))
					draw_rect(Rect2(band.end.x - (k + 1) * sq, band.position.y + j * sq, sq, sq), Color(c.check, alpha))
	fit_text(text, Rect2(band.position.x + band.size.x * 0.25, band.position.y, band.size.x * 0.5, band.size.y), Color(c.band_ink, alpha))


func building(rect: Rect2, bottom: float, body: Color, win: Color, lit_c: Color, alpha: float, seed_i: int, outline := Color(0, 0, 0, 0)) -> void:
	var w := rect.size.x
	var h := rect.size.y * (0.7 + float(seed_i % 5) * 0.08)
	var r := Rect2(rect.position.x, bottom - h, w, h)
	draw_rect(r, Color(body, alpha))
	if outline.a > 0.0:
		draw_rect(r, Color(outline, alpha), false, maxf(w * 0.02, 1.0))
	else:
		draw_rect(Rect2(r.position, Vector2(w, maxf(h * 0.03, 1.0))), Color(body.darkened(0.3), alpha))
	if w < 24.0:
		return
	var cols := 4
	var nrows := 9
	var cw := w / (cols * 2 + 1)
	var rh := h / (nrows * 2 + 1)
	for cx in cols:
		for cy in nrows:
			var lit := ((seed_i * 7 + cx * 3 + cy * 5) % 7) == 0
			draw_rect(Rect2(r.position.x + cw * (cx * 2 + 1), r.position.y + rh * (cy * 2 + 1), cw, rh), Color(lit_c if lit else win, alpha))


func sprite_colors(_r: Dictionary) -> Dictionary:
	return {}


## Cor do contorno das texturas de cenário (transparente = sem contorno).
func sprite_outline(_theme: String) -> Color:
	return Color(0, 0, 0, 0)


func theme_of_sprites() -> String:
	return game.theme


# ---------------------------------------------------------------- paisagem

## Alturas (0..1) de uma camada de paisagem, para o tema e plano (0 = longe, 1 = perto).
func layer_heights(t: String, plane: int) -> PackedFloat32Array:
	var key := "%s%d" % [t, plane]
	if _layers.has(key):
		return _layers[key]
	var n := int(LAYER_PERIOD / LAYER_STEP)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.05 if plane == 0 else 0.08
	for i in n:
		var a := float(i) / n * TAU
		# amostra num círculo para a paisagem dar a volta sem costura
		var v := noise.get_noise_2d(cos(a) * n / TAU, sin(a) * n / TAU) * 0.5 + 0.5
		var h := 0.0
		match t:
			"costa":
				h = (v * 0.5 if plane == 0 else maxf(v - 0.45, 0.0) * 1.2)
			"deserto":
				h = (1.0 if v > 0.55 else v * 0.4) if plane == 0 else v * 0.35
			"floresta":
				h = v * 0.7 + (rng.randf() * 0.12 if plane == 1 else 0.0)
			"alpes":
				h = pow(v, 1.6) * 1.2 + absf(fmod(i * 0.37, 1.0) - 0.5) * (0.35 if plane == 0 else 0.1)
			"cidade":
				if plane == 0:
					var b := int(i / 3)
					rng.seed = hash(key + str(b))
					h = 0.2 + rng.randf() * 0.8
				else:
					h = v * 0.3
			"vinhas":
				h = v * 0.55
		out[i] = clampf(h, 0.0, 1.2)
	_layers[key] = out
	return out


## Desenha uma camada de paisagem: linha superior em base_y - altura*amp, preenchida até bottom_y.
func draw_layer(t: String, plane: int, base_y: float, amp: float, speed: float, color: Color, bottom_y := H, outline := Color(0, 0, 0, 0), outline_w := 2.0) -> void:
	var hts := layer_heights(t, plane)
	var n := hts.size()
	var off := fposmod(bg_scroll * speed, LAYER_PERIOD)
	var first := int(off / LAYER_STEP)
	var sub := fmod(off, LAYER_STEP)
	var pts := PackedVector2Array()
	var count := int(W / LAYER_STEP) + 2
	for k in count:
		var hv := hts[(first + k) % n]
		if t == "cidade" and plane == 0:
			pts.append(Vector2(k * LAYER_STEP - sub, base_y - hv * amp))
			pts.append(Vector2((k + 1) * LAYER_STEP - sub, base_y - hv * amp))
		else:
			pts.append(Vector2(k * LAYER_STEP - sub, base_y - hv * amp))
	if color.a > 0.0:
		var poly := pts.duplicate()
		poly.append(Vector2(pts[pts.size() - 1].x, bottom_y))
		poly.append(Vector2(pts[0].x, bottom_y))
		draw_colored_polygon(poly, color)
	if outline.a > 0.0:
		draw_polyline(pts, outline, outline_w)


# ---------------------------------------------------------------- mapa das rotas

## Mapa das 5 etapas (pirâmide de bifurcações), com o caminho já percorrido destacado.
func draw_route_map(origin: Vector2, cell: Vector2, line_c: Color, node_c: Color, active_c: Color, width := 2.0, node_r := 4.0) -> void:
	var pos := func(s: int, b: int) -> Vector2: return origin + Vector2(s * cell.x, (b - s / 2.0) * cell.y)
	for s in OutRunGame.STAGES - 1:
		for b in s + 1:
			for nb: int in [b, b + 1]:
				var on := s + 1 < game.route.size() and game.route[s] == b and game.route[s + 1] == nb
				draw_line(pos.call(s, b), pos.call(s + 1, nb), active_c if on else line_c, width * (1.6 if on else 1.0))
	for s in OutRunGame.STAGES:
		for b in s + 1:
			var on := s < game.route.size() and game.route[s] == b
			var here := on and s == game.stage
			var r := node_r * (1.6 if here else 1.0)
			draw_circle(pos.call(s, b), r, active_c if on else node_c)
	# progresso dentro da etapa
	if game.stage < OutRunGame.STAGES - 1:
		var a: Vector2 = pos.call(game.stage, game.route[game.stage])
		var p := game.stage_progress()
		var b2: Vector2 = pos.call(game.stage + 1, game.route[game.stage] + (1 if game.player_x >= 0.0 else 0))
		draw_circle(a.lerp(b2, p), node_r * 0.9, Color.WHITE)


# ---------------------------------------------------------------- pixel art com contorno

## Textura de pixel art; com `outline` desenha um contorno de 1 ponto à volta da figura.
static func make_sprite(art: Array, palette: Dictionary, outline := Color(0, 0, 0, 0), scale := 1) -> ImageTexture:
	var w: int = (art[0] as String).length()
	var h := art.size()
	var pad := 1 if outline.a > 0.0 else 0
	var img := Image.create((w + pad * 2) * scale, (h + pad * 2) * scale, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var solid := func(x: int, y: int) -> bool:
		if x < 0 or y < 0 or y >= h or x >= (art[y] as String).length():
			return false
		var ch := (art[y] as String)[x]
		return ch != "." and palette.has(ch)
	for y in range(-pad, h + pad):
		for x in range(-pad, w + pad):
			var c := Color(0, 0, 0, 0)
			if solid.call(x, y):
				c = palette[(art[y] as String)[x]]
			elif pad > 0 and (solid.call(x - 1, y) or solid.call(x + 1, y) or solid.call(x, y - 1) or solid.call(x, y + 1)):
				c = outline
			if c.a > 0.0:
				img.fill_rect(Rect2i((x + pad) * scale, (y + pad) * scale, scale, scale), c)
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------- para os estilos reescreverem

func _setup() -> void:
	pass


func _build_sfx() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


## Cores da estrada para este frame: pares [clara, escura] e a cor do nevoeiro.
func frame_colors() -> Dictionary:
	return {"grass": [Color.DARK_GREEN, Color.DARK_GREEN], "rumble": [Color.RED, Color.WHITE], "road": [Color.DIM_GRAY, Color.DIM_GRAY],
		"lane": [Color.WHITE, Color(0, 0, 0, 0)], "fog": Color.WHITE}


func _draw_row_extra(_r: Dictionary) -> void:
	pass


func sprite_palette(_kind: String, _theme: String) -> Dictionary:
	return {}


func _draw_background() -> void:
	draw_rect(Rect2(0, 0, W, H), Color.SKY_BLUE)


func _draw_car(_car: Dictionary, _rect: Rect2, _alpha: float, _r: Dictionary) -> void:
	pass


func _draw_player() -> void:
	pass


func _draw_hud() -> void:
	pass


func _on_race_started() -> void:
	popups.clear()
	flash = 0.0
	_last_z = 0.0


func _on_countdown(n: int) -> void:
	if n > 0:
		play("beep")
	else:
		play("go")


func _on_stage_started(_stage: int, t: String) -> void:
	if t != theme:
		prev_theme = theme
		theme = t
		theme_blend = 0.0 if game.stage > 0 else 1.0
	if game.stage == 0:
		prev_theme = t
		theme_blend = 1.0


func _on_checkpoint(_stage: int, bonus: float) -> void:
	play("checkpoint")
	popups.append({"text": "+%d" % int(bonus), "life": 2.5})


func _on_crashed(_pos: Vector2) -> void:
	play("crash")
	flash = 0.25


func _on_bumped() -> void:
	play("bump")


func _on_gear_changed(_high: bool) -> void:
	play("gear")


func _on_time_warning() -> void:
	play("warning")


func _on_goal(_bonus: int) -> void:
	play("goal")


func _on_time_up() -> void:
	play("time_up")


func _on_game_over() -> void:
	pass
