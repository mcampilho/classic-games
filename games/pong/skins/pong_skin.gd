class_name PongSkin
extends Node2D
## Base dos estilos visuais do Pong. Um skin desenha o estado do PongGame em _draw(),
## cria os seus sons em _build_sfx() e reage aos eventos (toques, pontos, etc.).
## Para criar um estilo novo basta estender esta classe.

var game: PongGame
var sfx := {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0


func attach(g: PongGame) -> void:
	game = g
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	g.match_started.connect(_on_match_started)
	g.served.connect(_on_served)
	g.paddle_hit.connect(_on_paddle_hit)
	g.wall_hit.connect(_on_wall_hit)
	g.point_scored.connect(_on_point_scored)
	g.game_over.connect(_on_game_over)
	_build_sfx()
	_setup()


func play(id: String, pitch := 1.0, volume_db := 0.0) -> void:
	# O modo demonstração (fundo do menu) é silencioso, como nas máquinas de 1972.
	if game == null or game.mode == PongGame.Mode.DEMO or not sfx.has(id):
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


## Cores para os menus deste estilo (ver UI.make_theme).
func ui_palette() -> Dictionary:
	return UI.LAUNCHER_PALETTE


# ---- métodos para os estilos reescreverem ----

func _setup() -> void:
	pass


func _build_sfx() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _on_match_started() -> void:
	pass


func _on_served() -> void:
	pass


func _on_paddle_hit(_side: int, _pos: Vector2, _rel: float) -> void:
	play("paddle")


func _on_wall_hit(_pos: Vector2) -> void:
	play("wall")


func _on_point_scored(_side: int) -> void:
	play("score")


func _on_game_over(_winner: int) -> void:
	play("win")
