class_name AsteroidsSkin
extends Node2D
## Base dos estilos visuais do Asteroids: desenha o estado do AsteroidsGame, gere os sons
## (incluindo os contínuos do motor e do disco voador) e ajuda a desenhar à volta do ecrã.

const W := AsteroidsGame.SCREEN.x
const H := AsteroidsGame.SCREEN.y

var game: AsteroidsGame
var sfx := {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _thrust_loop: AudioStreamPlayer
var _saucer_loop: AudioStreamPlayer
var _saucer_id := ""


func attach(g: AsteroidsGame) -> void:
	game = g
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_thrust_loop = AudioStreamPlayer.new()
	add_child(_thrust_loop)
	_saucer_loop = AudioStreamPlayer.new()
	add_child(_saucer_loop)
	g.match_started.connect(_on_match_started)
	g.turn_started.connect(_on_turn_started)
	g.fired.connect(_on_fired)
	g.asteroid_destroyed.connect(_on_asteroid_destroyed)
	g.ship_destroyed.connect(_on_ship_destroyed)
	g.hyperspace_jump.connect(_on_hyperspace)
	g.saucer_spawned.connect(_on_saucer_spawned)
	g.saucer_destroyed.connect(_on_saucer_destroyed)
	g.saucer_gone.connect(_on_saucer_gone)
	g.saucer_fired.connect(_on_saucer_fired)
	g.heartbeat.connect(_on_heartbeat)
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
	if game == null or game.mode == AsteroidsGame.Mode.DEMO or not sfx.has(id):
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = sfx[id]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


func _looped(id: String) -> AudioStreamWAV:
	var s: AudioStreamWAV = sfx[id]
	if s.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = s.data.size() / 2
	return s


func _update_loops() -> void:
	var silent := game.paused or game.mode == AsteroidsGame.Mode.DEMO
	var want_thrust := game.thrusting and not silent and sfx.has("thrust")
	if want_thrust and not _thrust_loop.playing:
		_thrust_loop.stream = _looped("thrust")
		_thrust_loop.play()
	elif not want_thrust and _thrust_loop.playing:
		_thrust_loop.stop()
	var sid := ""
	if game.saucer != null and not silent:
		sid = "saucer_small" if game.saucer.small else "saucer_big"
	if sid != _saucer_id:
		_saucer_id = sid
		if sid == "" or not sfx.has(sid):
			_saucer_loop.stop()
		else:
			_saucer_loop.stream = _looped(sid)
			_saucer_loop.play()


func _process(delta: float) -> void:
	if game == null:
		return
	_update_loops()
	if not game.paused:
		_tick(delta)
	queue_redraw()


func ui_palette() -> Dictionary:
	return UI.LAUNCHER_PALETTE


## Deslocamentos para desenhar cópias de um objeto que está a atravessar uma margem do ecrã.
func wrap_offsets(pos: Vector2, r: float) -> Array[Vector2]:
	var xs: Array[float] = [0.0]
	var ys: Array[float] = [0.0]
	if pos.x < r:
		xs.append(W)
	elif pos.x > W - r:
		xs.append(-W)
	if pos.y < r:
		ys.append(H)
	elif pos.y > H - r:
		ys.append(-H)
	var out: Array[Vector2] = []
	for x in xs:
		for y in ys:
			out.append(Vector2(x, y))
	return out


static func shifted(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(p + offset)
	return out


static func closed(points: PackedVector2Array) -> PackedVector2Array:
	var out := points.duplicate()
	out.append(points[0])
	return out


## Contorno genérico de disco voador (unidades de -20 a 20).
static func saucer_lines(pos: Vector2, small: bool) -> Array[PackedVector2Array]:
	var s := 0.55 if small else 1.0
	var shapes := [
		[Vector2(-20, 0), Vector2(-8, -6), Vector2(8, -6), Vector2(20, 0), Vector2(8, 7), Vector2(-8, 7), Vector2(-20, 0)],
		[Vector2(-20, 0), Vector2(20, 0)],
		[Vector2(-8, -6), Vector2(-4, -12), Vector2(4, -12), Vector2(8, -6)],
	]
	var out: Array[PackedVector2Array] = []
	for shape: Array in shapes:
		var line := PackedVector2Array()
		for p: Vector2 in shape:
			line.append(pos + p * s)
		out.append(line)
	return out


# ---------------------------------------------------------------- para os estilos reescreverem

func _setup() -> void:
	pass


func _build_sfx() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _on_match_started() -> void:
	pass


func _on_turn_started(_player: int) -> void:
	pass


func _on_fired(_pos: Vector2, _dir: Vector2) -> void:
	play("fire")


func _on_asteroid_destroyed(_pos: Vector2, size: int, _points: int, _rock: Dictionary) -> void:
	play("boom%d" % size)


func _on_ship_destroyed(_pos: Vector2) -> void:
	play("ship_boom")


func _on_hyperspace(_from: Vector2, _to: Vector2) -> void:
	play("hyper")


func _on_saucer_spawned(_small: bool) -> void:
	pass


func _on_saucer_destroyed(_pos: Vector2, _small: bool, _points: int) -> void:
	play("boom0")


func _on_saucer_gone() -> void:
	pass


func _on_saucer_fired(_pos: Vector2) -> void:
	play("saucer_fire")


func _on_heartbeat(note: int) -> void:
	play("beat%d" % note)


func _on_extra_life() -> void:
	play("extra")


func _on_wave_cleared() -> void:
	pass


func _on_game_over() -> void:
	pass
