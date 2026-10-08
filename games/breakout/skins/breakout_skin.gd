class_name BreakoutSkin
extends Node2D
## Base dos estilos visuais do Breakout: desenha o estado do BreakoutGame em _draw(),
## cria os sons em _build_sfx() e reage aos eventos do jogo.

var game: BreakoutGame
var sfx := {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0


func attach(g: BreakoutGame) -> void:
	game = g
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	g.match_started.connect(_on_match_started)
	g.turn_started.connect(_on_turn_started)
	g.served.connect(_on_served)
	g.paddle_hit.connect(_on_paddle_hit)
	g.wall_hit.connect(_on_wall_hit)
	g.brick_broken.connect(_on_brick_broken)
	g.speed_changed.connect(_on_speed_changed)
	g.paddle_shrunk.connect(_on_paddle_shrunk)
	g.ball_lost.connect(_on_ball_lost)
	g.wall_cleared.connect(_on_wall_cleared)
	g.game_over.connect(_on_game_over)
	# Os sons de cada estilo só são gerados uma vez (ou já vêm prontos do Synth.prewarm).
	var cached: Variant = Synth.cache_get(get_script().resource_path)
	if cached != null:
		sfx = cached
	else:
		_build_sfx()
		Synth.cache_set(get_script().resource_path, sfx)
	_setup()


func play(id: String, pitch := 1.0, volume_db := 0.0) -> void:
	# A demonstração do menu é silenciosa.
	if game == null or game.mode == BreakoutGame.Mode.DEMO or not sfx.has(id):
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
		_tick(delta)
	queue_redraw()


func ui_palette() -> Dictionary:
	return UI.LAUNCHER_PALETTE


## Texto do marcador: pontuação com 3 algarismos, como no original.
func score_text(score: int) -> String:
	return "%03d" % score


# ---- para os estilos reescreverem ----

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


func _on_served() -> void:
	pass


func _on_paddle_hit(_pos: Vector2) -> void:
	play("paddle")


func _on_wall_hit(_pos: Vector2) -> void:
	play("wall")


func _on_brick_broken(row: int, _col: int, _pos: Vector2, _points: int) -> void:
	play("brick%d" % (row / 2))


func _on_speed_changed(_level: int) -> void:
	pass


func _on_paddle_shrunk() -> void:
	pass


func _on_ball_lost(_player: int) -> void:
	play("lose")


func _on_wall_cleared(_player: int) -> void:
	play("clear")


func _on_game_over() -> void:
	pass
