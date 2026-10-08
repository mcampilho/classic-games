class_name InvadersSkin
extends Node2D
## Base dos estilos visuais do Space Invaders: desenha o estado do InvadersGame,
## gere os sons (incluindo o som contínuo do disco voador) e as explosões.

const S := InvadersGame.SCALE

var game: InvadersGame
var sfx := {}
var booms: Array[Dictionary] = []      # explosões de invasores {pos (unidades), life, kind}
var popups: Array[Dictionary] = []     # pontos do disco voador {pos, text, life}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _loop: AudioStreamPlayer


func attach(g: InvadersGame) -> void:
	game = g
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_loop = AudioStreamPlayer.new()
	add_child(_loop)
	g.match_started.connect(_on_match_started)
	g.turn_started.connect(_on_turn_started)
	g.player_fired.connect(_on_player_fired)
	g.alien_fired.connect(_on_alien_fired)
	g.alien_killed.connect(_on_alien_killed)
	g.fleet_stepped.connect(_on_fleet_stepped)
	g.ufo_spawned.connect(_on_ufo_spawned)
	g.ufo_killed.connect(_on_ufo_killed)
	g.ufo_gone.connect(_on_ufo_gone)
	g.player_hit.connect(_on_player_hit)
	g.shot_blocked.connect(_on_shot_blocked)
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
	if game == null or game.mode == InvadersGame.Mode.DEMO or not sfx.has(id):
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = sfx[id]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


func start_loop(id: String) -> void:
	if game.mode == InvadersGame.Mode.DEMO or not sfx.has(id):
		return
	var s: AudioStreamWAV = sfx[id]
	if s.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = s.data.size() / 2
	_loop.stream = s
	_loop.play()


func stop_loop() -> void:
	_loop.stop()


func _process(delta: float) -> void:
	if game == null:
		return
	_loop.stream_paused = game.paused
	if not game.paused:
		for b in booms:
			b.life -= delta
		booms = booms.filter(func(b: Dictionary) -> bool: return b.life > 0.0)
		for p in popups:
			p.life -= delta
		popups = popups.filter(func(p: Dictionary) -> bool: return p.life > 0.0)
		_tick(delta)
	queue_redraw()


func ui_palette() -> Dictionary:
	return UI.LAUNCHER_PALETTE


# ---------------------------------------------------------------- ajudas de desenho

func px(u: Vector2) -> Vector2:
	return game.to_px(u)


## Desenha um desenho de píxeis (lista de strings) no ponto `u` (unidades do jogo).
func draw_bits(rows: Array, u: Vector2, color: Color, ci: CanvasItem = null) -> void:
	var target: CanvasItem = ci if ci else self
	var o := px(u)
	for y in rows.size():
		var row: String = rows[y]
		var x := 0
		while x < row.length():
			if row[x] == "#":
				var start := x
				while x < row.length() and row[x] == "#":
					x += 1
				target.draw_rect(Rect2(o.x + start * S, o.y + y * S, (x - start) * S, S), color)
			else:
				x += 1


## Desenha um abrigo linha a linha. `color_for_row` (opcional): Callable(y_unidades) -> Color.
func draw_bunker(i: int, color: Color, ci: CanvasItem = null, color_for_row := Callable()) -> void:
	var target: CanvasItem = ci if ci else self
	var bk: PackedByteArray = game.bunkers[i]
	var o := game.bunker_origin(i)
	for y in InvadersGame.BUNKER_H:
		var c: Color = color if not color_for_row.is_valid() else color_for_row.call(o.y + y)
		var x := 0
		while x < InvadersGame.BUNKER_W:
			if bk[y * InvadersGame.BUNKER_W + x] == 1:
				var start := x
				while x < InvadersGame.BUNKER_W and bk[y * InvadersGame.BUNKER_W + x] == 1:
					x += 1
				var p := px(o + Vector2(start, y))
				target.draw_rect(Rect2(p, Vector2((x - start) * S, S)), c)
			else:
				x += 1


func alien_frame(row: int) -> Array:
	return InvaderSprites.ALIENS[InvadersGame.ROW_KIND[row]][game.anim_frame]


func bomb_frame(b: Dictionary) -> Array:
	return InvaderSprites.BOMBS[b.kind][int(b.frame) % 2]


## Mostra a explosão do jogador (2 fotogramas a alternar) durante a animação de morte.
func player_dying() -> bool:
	return game.state == InvadersGame.State.DYING


func dying_frame() -> int:
	return int(game.timer * 10.0) % 2


func panel_left_x() -> float:
	return InvadersGame.ORIGIN.x / 2


func panel_right_x() -> float:
	var r := InvadersGame.ORIGIN.x + InvadersGame.FIELD.x * S
	return r + (1280.0 - r) / 2


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
	stop_loop()


func _on_turn_started(_player: int) -> void:
	booms.clear()
	stop_loop()


func _on_player_fired(_pos: Vector2) -> void:
	play("shoot")


func _on_alien_fired(_pos: Vector2, _kind: int) -> void:
	pass


func _on_alien_killed(_row: int, _col: int, pos: Vector2, _points: int, kind: int) -> void:
	booms.append({"pos": pos, "life": 0.28, "kind": kind})
	play("kill")


func _on_fleet_stepped(note: int) -> void:
	play("march%d" % note)


func _on_ufo_spawned() -> void:
	start_loop("ufo")


func _on_ufo_killed(pos: Vector2, points: int) -> void:
	stop_loop()
	play("ufo_hit")
	popups.append({"pos": pos, "text": str(points), "life": 1.4})


func _on_ufo_gone() -> void:
	stop_loop()


func _on_player_hit(_pos: Vector2) -> void:
	play("player_hit")


func _on_shot_blocked(_pos: Vector2, _by_bunker: bool) -> void:
	pass


func _on_extra_life() -> void:
	play("extra")


func _on_wave_cleared() -> void:
	stop_loop()


func _on_game_over() -> void:
	stop_loop()
