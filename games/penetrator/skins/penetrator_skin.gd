class_name PenetratorSkin
extends Node2D
## Base dos estilos do Penetrator: desenhos originais (nave, mísseis, radares, discos e depósito),
## terreno, explosões e sons. Os estilos escolhem cores, fundo, terreno e HUD.


const SHIP := [
	"HH....................",
	"HHH...................",
	"HHHH.......CCC........",
	"BBBBBBBBBBCCCCCBB.....",
	"BBBBBBBBBBBBBBBBBBBB..",
	"bbbbbbbbbbbbbbbbbbbbbN",
	"FbbbbbbbbbbbbbbbbbbbN.",
	"FF....bbbbbbbb........",
	"........KKK...........",
]
const MISSILE := [
	"..R..",
	".RWR.",
	".WWW.",
	".WWW.",
	".WBW.",
	".WWW.",
	".WWW.",
	".WWW.",
	".WBW.",
	".WWW.",
	".WWW.",
	"RWWWR",
	"RWWWR",
	"R...R",
]
const SAUCER := [
	"......CCCC......",
	".....CCCCCC.....",
	"..BBBBBBBBBBBB..",
	"BBLBBLBBLBBLBBLB",
	"..bbbbbbbbbbbb..",
	"....bbbbbbbb....",
]

var game: PenetratorGame
var sfx := {}
var tex := {}
var time := 0.0
var booms: Array[Dictionary] = []     # pos (mundo), life, max, color, size
var popups: Array[Dictionary] = []    # pos (mundo), text, life
var flash := 0.0
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _engine: AudioStreamPlayer
var _qv := PackedVector2Array()
var _qc := PackedColorArray()
var _qi := PackedInt32Array()


func attach(g: PenetratorGame) -> void:
	game = g
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_engine = AudioStreamPlayer.new()
	_engine.volume_db = -14.0
	add_child(_engine)
	g.match_started.connect(_on_match_started)
	g.zone_started.connect(_on_zone_started)
	g.fired.connect(func() -> void: play("shot", 1.0, -4.0))
	g.bomb_dropped.connect(func() -> void: play("bomb"))
	g.enemy_killed.connect(_on_enemy_killed)
	g.missile_launched.connect(func(_p: Vector2) -> void: play("launch", 1.0, -3.0))
	g.bomb_hit_ground.connect(func(p: Vector2) -> void:
		boom(p, 0.35, 18.0, ground_boom_color())
		play("thud", randf_range(0.9, 1.1), -4.0))
	g.store_hit.connect(func(p: Vector2, _left: int) -> void:
		boom(p, 0.5, 40.0, Color.ORANGE)
		play("store_hit"))
	g.player_died.connect(_on_player_died)
	g.mission_complete.connect(_on_mission_complete)
	g.extra_life.connect(func() -> void: play("extra"))
	var cached: Variant = Synth.cache_get(get_script().resource_path)
	if cached != null:
		sfx = cached
	else:
		_build_sfx()
		Synth.cache_set(get_script().resource_path, sfx)
	_setup()


func play(id: String, pitch := 1.0, volume_db := 0.0) -> void:
	if game == null or game.mode == PenetratorGame.Mode.DEMO or not sfx.has(id):
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
	var silent := game.paused or game.mode == PenetratorGame.Mode.DEMO
	var want := not silent and game.state == PenetratorGame.State.PLAY and sfx.has("engine")
	if want and not _engine.playing:
		var s: AudioStreamWAV = sfx.engine
		if s.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_end = s.data.size() / 2
		_engine.stream = s
		_engine.play()
	elif not want and _engine.playing:
		_engine.stop()
	if _engine.playing:
		_engine.pitch_scale = 1.0 + (game.ship.x - 200.0) / 1500.0 - game.ship_tilt * 0.05
	if not game.paused:
		time += delta
		flash = maxf(flash - delta, 0.0)
		for b in booms:
			b.life -= delta
		booms = booms.filter(func(b: Dictionary) -> bool: return b.life > 0.0)
		for p in popups:
			p.life -= delta
			p.pos.y -= 20.0 * delta
		popups = popups.filter(func(p: Dictionary) -> bool: return p.life > 0.0)
		_tick(delta)
	queue_redraw()


## Explosão (posição no ecrã quando criada; guardada no mundo para acompanhar o scroll).
func boom(screen_pos: Vector2, life: float, size: float, color: Color) -> void:
	booms.append({"pos": screen_pos + Vector2(game.cam_x, 0), "life": life, "max": life, "color": color, "size": size, "seed": randi()})


func sx(world_x: float) -> float:
	return world_x - game.cam_x


# ---------------------------------------------------------------- terreno

## Primeira e última coluna visíveis.
func visible_cols() -> Vector2i:
	var a := maxi(0, floori(game.cam_x / PenetratorGame.CW) - 1)
	var b := mini(game.cols() - 1, a + int(PenetratorGame.W / PenetratorGame.CW) + 3)
	return Vector2i(a, b)


## Linha do chão (ou do teto) no ecrã.
func contour(top: bool) -> PackedVector2Array:
	var v := visible_cols()
	var pts := PackedVector2Array()
	for c in range(v.x, v.y + 1):
		pts.append(Vector2(c * PenetratorGame.CW - game.cam_x, game.ceil_y[c] if top else game.floor_y[c]))
	return pts


func has_ceiling() -> bool:
	var v := visible_cols()
	for c in range(v.x, v.y + 1, 4):
		if game.ceil_y[c] > PenetratorGame.TOP + 1.0:
			return true
	return false


## Enche o terreno (chão e teto) em faixas verticais, num só lote.
## `bands`: lista de [espessura, cor] a partir da superfície (a última vai até ao fim).
func fill_terrain(bands: Array, top_too := true) -> void:
	var v := visible_cols()
	for c in range(v.x, v.y):
		var x0 := c * PenetratorGame.CW - game.cam_x
		var x1 := x0 + PenetratorGame.CW
		var f0 := game.floor_y[c]
		var f1 := game.floor_y[c + 1]
		var d := 0.0
		for i in bands.size():
			var band: Array = bands[i]
			var t: float = band[0] if i < bands.size() - 1 else 2000.0
			var col: Color = band[1]
			_quad(Vector2(x0, f0 + d), Vector2(x1, f1 + d), Vector2(x1, minf(f1 + d + t, PenetratorGame.H)), Vector2(x0, minf(f0 + d + t, PenetratorGame.H)), col)
			d += t
			if f0 + d > PenetratorGame.H and f1 + d > PenetratorGame.H:
				break
		if top_too:
			var c0 := game.ceil_y[c]
			var c1 := game.ceil_y[c + 1]
			if c0 > PenetratorGame.TOP + 0.5 or c1 > PenetratorGame.TOP + 0.5:
				d = 0.0
				for i in bands.size():
					var band: Array = bands[i]
					var t: float = band[0] if i < bands.size() - 1 else 2000.0
					var col: Color = band[1]
					_quad(Vector2(x0, maxf(c0 - d - t, PenetratorGame.TOP)), Vector2(x1, maxf(c1 - d - t, PenetratorGame.TOP)), Vector2(x1, c1 - d), Vector2(x0, c0 - d), col)
					d += t
					if c0 - d < PenetratorGame.TOP and c1 - d < PenetratorGame.TOP:
						break
	_flush()


func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> void:
	var n := _qv.size()
	_qv.append(a)
	_qv.append(b)
	_qv.append(c)
	_qv.append(d)
	for k in 4:
		_qc.append(color)
	_qi.append(n)
	_qi.append(n + 1)
	_qi.append(n + 2)
	_qi.append(n)
	_qi.append(n + 2)
	_qi.append(n + 3)


func _flush() -> void:
	if _qv.is_empty():
		return
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _qi, _qv, _qc)
	_qv = PackedVector2Array()
	_qc = PackedColorArray()
	_qi = PackedInt32Array()


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	if game == null or game.cols() == 0:
		return
	_draw_back()
	_draw_terrain()
	for e in game.enemies:
		if not e.alive:
			continue
		var x := sx(e.x)
		if x < -80.0 or x > PenetratorGame.W + 80.0:
			continue
		_draw_enemy(e, Vector2(x, e.y))
	for s in game.shots:
		_draw_shot(Vector2(sx(s.x), s.y))
	for b in game.bombs:
		_draw_bomb(Vector2(sx(b.x), b.y), Vector2(b.vx - game.scroll_speed, b.vy))
	if _ship_visible():
		_draw_ship(game.ship)
	_draw_booms()
	_draw_hud()
	if flash > 0.0:
		draw_rect(Rect2(0, 0, PenetratorGame.W, PenetratorGame.H), Color(1, 1, 1, flash * 2.0))


func _ship_visible() -> bool:
	if game.state == PenetratorGame.State.DYING or game.state == PenetratorGame.State.OVER:
		return false
	return not (game.state == PenetratorGame.State.READY and fmod(time, 0.24) < 0.1)


func draw_tex_center(t: Texture2D, c: Vector2, scale := 2.0, rot := 0.0, modulate_c := Color.WHITE) -> void:
	draw_set_transform(c, rot, Vector2(scale, scale))
	draw_texture(t, -t.get_size() / 2, modulate_c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_booms() -> void:
	for b in booms:
		var k: float = 1.0 - float(b.life) / float(b.max)
		var c := Vector2(sx(b.pos.x), b.pos.y)
		var rng := RandomNumberGenerator.new()
		rng.seed = b.seed
		var size: float = b.size
		for i in 10:
			var a := rng.randf() * TAU
			var d := Vector2.from_angle(a) * size * (0.3 + k * rng.randf_range(0.8, 1.6))
			var s := maxf(2.0, size * 0.16 * (1.0 - k))
			draw_rect(Rect2(c + d - Vector2(s, s) / 2, Vector2(s, s)), Color(b.color, 1.0 - k))


func ground_boom_color() -> Color:
	return Color.YELLOW


## Radar: mastro e prato que roda (largura do prato muda com o ângulo).
func draw_radar(base: Vector2, phase: float, mast: Color, dish: Color, line_w := 3.0) -> void:
	draw_set_transform(base, 0.0, Vector2(1.5, 1.5))
	base = Vector2.ZERO
	draw_line(base, base + Vector2(0, -18), mast, line_w)
	draw_line(base + Vector2(-10, 0), base + Vector2(10, 0), mast, line_w)
	var w := absf(cos(phase * 2.5)) * 14.0 + 2.0
	var c := base + Vector2(0, -22)
	draw_line(c + Vector2(-w, -6), c + Vector2(0, 2), dish, line_w)
	draw_line(c + Vector2(w, -6), c + Vector2(0, 2), dish, line_w)
	draw_line(c, c + Vector2(cos(phase * 2.5) * 6.0, -10), dish, line_w * 0.7)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Depósito de bombas: casamata com portas e o símbolo de perigo.
func draw_store(base: Vector2, body: Color, dark: Color, mark: Color, left: int) -> void:
	var r := Rect2(base + Vector2(-45, -60), Vector2(90, 60))
	draw_rect(r, body)
	draw_colored_polygon(PackedVector2Array([r.position, r.position + Vector2(45, -18), Vector2(r.end.x, r.position.y)]), dark)
	draw_rect(Rect2(base + Vector2(-14, -30), Vector2(28, 30)), dark)
	draw_circle(base + Vector2(0, -44), 9, mark)
	for i in 3:
		var a := i * TAU / 3 - PI / 2
		draw_colored_polygon(PackedVector2Array([base + Vector2(0, -44), base + Vector2(0, -44) + Vector2.from_angle(a - 0.4) * 8, base + Vector2(0, -44) + Vector2.from_angle(a + 0.4) * 8]), dark)
	for i in left:
		draw_rect(Rect2(base + Vector2(-40 + i * 14, -8), Vector2(10, 4)), mark)


# ---------------------------------------------------------------- para os estilos reescreverem

func _setup() -> void:
	pass


func _build_sfx() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _draw_back() -> void:
	draw_rect(Rect2(0, 0, PenetratorGame.W, PenetratorGame.H), Color.BLACK)


func _draw_terrain() -> void:
	pass


func _draw_enemy(_e: Dictionary, _p: Vector2) -> void:
	pass


func _draw_shot(p: Vector2) -> void:
	draw_rect(Rect2(p - Vector2(8, 1.5), Vector2(16, 3)), Color.WHITE)


func _draw_bomb(p: Vector2, _v: Vector2) -> void:
	draw_circle(p, 4, Color.WHITE)


func _draw_ship(_p: Vector2) -> void:
	pass


func _draw_hud() -> void:
	pass


func ui_palette() -> Dictionary:
	return UI.LAUNCHER_PALETTE


func _on_match_started() -> void:
	booms.clear()
	popups.clear()


func _on_zone_started(_zone: int) -> void:
	if game.state == PenetratorGame.State.PLAY:
		play("zone")


func _on_enemy_killed(pos: Vector2, kind: String, points: int) -> void:
	boom(pos, 0.6 if kind == "store" else 0.45, 60.0 if kind == "store" else 26.0, Color.ORANGE)
	popups.append({"pos": pos + Vector2(game.cam_x, -20), "text": str(points), "life": 0.9})
	play("boom_big" if kind == "store" else "boom", randf_range(0.9, 1.1))


func _on_player_died(pos: Vector2) -> void:
	boom(pos, 1.2, 70.0, Color.WHITE)
	boom(pos, 0.9, 40.0, Color.ORANGE)
	flash = 0.15
	play("die")


func _on_mission_complete(_m: int) -> void:
	flash = 0.3
	play("complete")
