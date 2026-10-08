class_name GalaxianSkin
extends Node2D
## Base dos estilos visuais do Galaxian: desenho, sons (incluindo o zumbido contínuo da formação),
## explosões e um campo de estrelas reutilizável.

const S := GalaxianGame.SCALE

var game: GalaxianGame
var sfx := {}
var booms: Array[Dictionary] = []          # {pos (unidades), life, kind}
var popups: Array[Dictionary] = []         # {pos, text, life}
var stars: Array[Dictionary] = []          # {pos (px), speed, color, phase}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _loop: AudioStreamPlayer


func attach(g: GalaxianGame) -> void:
	game = g
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_loop = AudioStreamPlayer.new()
	add_child(_loop)
	g.match_started.connect(_on_match_started)
	g.turn_started.connect(_on_turn_started)
	g.fired.connect(_on_fired)
	g.dive_started.connect(_on_dive_started)
	g.alien_killed.connect(_on_alien_killed)
	g.bomb_dropped.connect(_on_bomb_dropped)
	g.player_hit.connect(_on_player_hit)
	g.extra_life.connect(_on_extra_life)
	g.wave_cleared.connect(_on_wave_cleared)
	g.game_over.connect(_on_game_over)
	var cached: Variant = Synth.cache_get(get_script().resource_path)
	if cached != null:
		sfx = cached
	else:
		_build_sfx()
		Synth.cache_set(get_script().resource_path, sfx)
	_setup()


func play(id: String, pitch := 1.0, volume_db := 0.0) -> void:
	if game == null or game.mode == GalaxianGame.Mode.DEMO or not sfx.has(id):
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = sfx[id]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


func _update_loop() -> void:
	var want := sfx.has("hum") and not game.paused and game.mode != GalaxianGame.Mode.DEMO \
		and game.state in [GalaxianGame.State.PLAY, GalaxianGame.State.READY]
	if want and not _loop.playing:
		var s: AudioStreamWAV = sfx.hum
		if s.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_end = s.data.size() / 2
		_loop.stream = s
		_loop.volume_db = -6.0
		_loop.play()
	elif not want and _loop.playing:
		_loop.stop()


func _process(delta: float) -> void:
	if game == null:
		return
	_update_loop()
	if not game.paused:
		for b in booms:
			b.life -= delta
		booms = booms.filter(func(b: Dictionary) -> bool: return b.life > 0.0)
		for p in popups:
			p.life -= delta
		popups = popups.filter(func(p: Dictionary) -> bool: return p.life > 0.0)
		for s in stars:
			s.pos.y = fposmod(s.pos.y + s.speed * delta, 720.0)
			s.phase += delta
		_tick(delta)
	queue_redraw()


func ui_palette() -> Dictionary:
	return UI.LAUNCHER_PALETTE


# ---------------------------------------------------------------- ajudas

func px(u: Vector2) -> Vector2:
	return game.to_px(u)


func make_stars(n: int, colors: Array, min_speed := 20.0, max_speed := 70.0, x_range := Vector2(0, 1280)) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1979
	stars.clear()
	for i in n:
		stars.append({"pos": Vector2(rng.randf_range(x_range.x, x_range.y), rng.randf() * 720.0),
			"speed": rng.randf_range(min_speed, max_speed), "color": colors[rng.randi() % colors.size()], "phase": rng.randf() * 10.0})


func field_rect() -> Rect2:
	return Rect2(GalaxianGame.ORIGIN, GalaxianGame.FIELD * S)


func panel_left_x() -> float:
	return GalaxianGame.ORIGIN.x / 2


func panel_right_x() -> float:
	var r := GalaxianGame.ORIGIN.x + GalaxianGame.FIELD.x * S
	return r + (1280.0 - r) / 2


func player_dying() -> bool:
	return game.state == GalaxianGame.State.DYING


# ---------------------------------------------------------------- para os estilos reescreverem

func _setup() -> void:
	pass


func _build_sfx() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _on_match_started() -> void:
	booms.clear()
	popups.clear()


func _on_turn_started(_player: int) -> void:
	pass


func _on_fired(_pos: Vector2) -> void:
	play("fire")


func _on_dive_started(kind: int) -> void:
	play("dive", 1.0 + (3 - kind) * 0.04)


func _on_alien_killed(pos: Vector2, kind: int, points: int, diving: bool) -> void:
	booms.append({"pos": pos, "life": 0.35, "kind": kind})
	if kind == 0:
		play("flag_kill")
	else:
		play("kill", randf_range(0.95, 1.05))
	if diving and points >= 150:
		popups.append({"pos": pos, "text": str(points), "life": 1.2})


func _on_bomb_dropped(_pos: Vector2) -> void:
	pass


func _on_player_hit(_pos: Vector2) -> void:
	play("player_hit")


func _on_extra_life() -> void:
	play("extra")


func _on_wave_cleared() -> void:
	pass


func _on_game_over() -> void:
	pass
