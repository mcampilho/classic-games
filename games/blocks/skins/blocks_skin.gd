class_name BlocksSkin
extends Node2D
## Base dos estilos do Encaixe: poço, peças, sombra, peça guardada, próximas peças, marcadores,
## animação das linhas completas, partículas, avisos e música. Os estilos escolhem o aspeto.

const CELL := 30.0
const BX := 490.0
const BY := 60.0
const WELL := Rect2(BX, BY, CELL * BlocksGame.COLS, CELL * (BlocksGame.ROWS - BlocksGame.HIDDEN))
const HOLD_BOX := Rect2(286, 60, 170, 120)
const NEXT_BOX := Rect2(824, 60, 170, 120)
const CLEAR_NAMES := ["", "", "DUPLA", "TRIPLA", "QUATRO LINHAS!"]

var game: BlocksGame
var sfx := {}
var time := 0.0
var parts: Array[Dictionary] = []
var popups: Array[Dictionary] = []
var shake := 0.0
var music_on := true
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _music: AudioStreamPlayer


func attach(g: BlocksGame) -> void:
	game = g
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -6.0
	add_child(_music)
	g.moved.connect(func() -> void: play("move", 1.0, -8.0))
	g.rotated.connect(func() -> void: play("rotate", 1.0, -6.0))
	g.hard_dropped.connect(func(n: int) -> void:
		play("drop")
		shake = 0.12
		_drop_trail(n))
	g.locked.connect(func() -> void: play("lock", 1.0, -4.0))
	g.held.connect(func() -> void: play("hold", 1.0, -4.0))
	g.cleared.connect(func(rows: Array, n: int) -> void:
		play("quad" if n == 4 else "clear", 1.0 + (n - 1) * 0.08)
		for r: int in rows:
			_row_burst(r)
		var txt: String = I18n.t(CLEAR_NAMES[n]) if n > 1 else ""
		if game.last_b2b:
			txt = I18n.t("OUTRA VEZ ") + txt
		if game.combo > 0:
			txt += ("  " if txt != "" else "") + I18n.t("SEGUIDAS x%d") % (game.combo + 1)
		if txt != "":
			popups.append({"text": txt, "t": 0.0, "y": cell_rect(0, rows[0]).position.y}))
	g.level_up.connect(func(l: int) -> void:
		play("level")
		popups.append({"text": I18n.t("NÍVEL %d") % l, "t": 0.0, "y": WELL.position.y + 200.0}))
	g.game_over.connect(func() -> void: play("over"))
	var cached: Variant = Synth.cache_get(get_script().resource_path)
	if cached != null:
		sfx = cached
	else:
		_build_sfx()
		Synth.cache_set(get_script().resource_path, sfx)
	_setup()


func play(id: String, pitch := 1.0, volume_db := 0.0) -> void:
	if game == null or game.mode == BlocksGame.Mode.DEMO or not sfx.has(id):
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = sfx[id]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


## Retângulo no ecrã da casa (coluna, linha do tabuleiro).
func cell_rect(c: int, r: int) -> Rect2:
	return Rect2(BX + c * CELL, BY + (r - BlocksGame.HIDDEN) * CELL, CELL, CELL)


func _row_burst(r: int) -> void:
	for x in BlocksGame.COLS:
		var k := game.board[r * BlocksGame.COLS + x] - 1
		var c := cell_rect(x, r).get_center()
		for i in 2:
			parts.append({"pos": c, "vel": Vector2(randf_range(-260, 260), randf_range(-320, -60)), "life": randf_range(0.4, 0.8),
				"kind": maxi(k, 0), "size": randf_range(4.0, 9.0)})


func _drop_trail(n: int) -> void:
	if n <= 0:
		return
	for c in game.piece_cells():
		var r := cell_rect(c.x, c.y)
		parts.append({"pos": r.get_center(), "vel": Vector2(0, -40), "life": 0.25, "kind": game.kind, "size": 0.0,
			"trail": n * CELL})


func _process(delta: float) -> void:
	if game == null:
		return
	if not game.paused:
		time += delta
		shake = maxf(shake - delta, 0.0)
		for p in parts:
			p.life -= delta
			p.vel.y += 700.0 * delta
			p.pos += p.vel * delta
		parts = parts.filter(func(p: Dictionary) -> bool: return p.life > 0.0)
		for p in popups:
			p.t += delta
		popups = popups.filter(func(p: Dictionary) -> bool: return p.t < 1.4)
		_tick(delta)
	_update_music()
	queue_redraw()


func _update_music() -> void:
	var want := music_on and game.mode == BlocksGame.Mode.PLAY and game.state != BlocksGame.State.OVER
	if want:
		if not _music.playing:
			var s := BlocksMusic.stream(music_variant())
			if s != null:
				_music.stream = s
				_music.play()
		_music.stream_paused = game.paused
	elif _music.playing:
		_music.stop()


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	if game == null or game.board.is_empty():
		return
	var off := Vector2(randf_range(-3, 3), randf_range(-3, 3)) * (shake / 0.12) if shake > 0.0 else Vector2.ZERO
	_draw_back()
	draw_set_transform(off)
	_draw_well(WELL)
	var g := game
	var clearing := g.state == BlocksGame.State.CLEAR
	for r in range(BlocksGame.HIDDEN, BlocksGame.ROWS):
		if clearing and r in g.clear_rows:
			continue
		for c in BlocksGame.COLS:
			var k := g.board[r * BlocksGame.COLS + c]
			if k > 0:
				draw_block(cell_rect(c, r), k - 1, 0)
	if clearing:
		for r in g.clear_rows:
			_draw_clearing(r, clampf(g.clear_t / BlocksGame.CLEAR_TIME, 0.0, 1.0))
	if g.state == BlocksGame.State.PLAY:
		var gy := g.ghost_y()
		if gy != g.py:
			for c in BlocksGame.cells_of(g.kind, g.rot):
				if g.py + c.y >= BlocksGame.HIDDEN or gy + c.y >= BlocksGame.HIDDEN:
					draw_block(cell_rect(g.px + c.x, gy + c.y), g.kind, 1)
		for c in g.piece_cells():
			if c.y >= BlocksGame.HIDDEN - 1:
				draw_block(cell_rect(c.x, c.y), g.kind, 0)
	_draw_well_front(WELL)
	for p in parts:
		_draw_part(p)
	draw_set_transform(Vector2.ZERO)
	_draw_box(HOLD_BOX, I18n.t("GUARDADA"))
	if g.hold >= 0:
		draw_piece_preview(g.hold, HOLD_BOX.get_center() + Vector2(0, 12), 26.0, not g.can_hold)
	_draw_box(NEXT_BOX, I18n.t("A SEGUIR"))
	draw_piece_preview(g.next[0], NEXT_BOX.get_center() + Vector2(0, 12), 26.0, false)
	for i in range(1, 4):
		draw_piece_preview(g.next[i], Vector2(NEXT_BOX.get_center().x, NEXT_BOX.end.y + 30 + i * 62 - 40), 18.0, false)
	_draw_stats()
	for p in popups:
		_draw_popup(p.text, p.y - p.t * 60.0, 1.0 - clampf((p.t - 0.9) / 0.5, 0.0, 1.0))
	if g.state == BlocksGame.State.OVER:
		_draw_over()
	_draw_front()


## Peça pequena (pré-visualização) centrada em c, com casas de tamanho s.
func draw_piece_preview(k: int, c: Vector2, s: float, dim: bool) -> void:
	var cs := BlocksGame.cells_of(k, 0)
	var mn := Vector2(99, 99)
	var mx := Vector2(-99, -99)
	for v in cs:
		mn = Vector2(minf(mn.x, v.x), minf(mn.y, v.y))
		mx = Vector2(maxf(mx.x, v.x + 1), maxf(mx.y, v.y + 1))
	var o := c - (mx - mn) * s * 0.5 - mn * s
	for v in cs:
		draw_block(Rect2(o + Vector2(v) * s, Vector2(s, s)), k, 3 if dim else 2)


func _draw_stats() -> void:
	var g := game
	var x := HOLD_BOX.get_center().x
	var y := HOLD_BOX.end.y + 40.0
	for row: Array in [[I18n.t("PONTOS"), str(g.score)], [I18n.t("NÍVEL"), str(g.level)], [I18n.t("LINHAS"), str(g.lines)], [I18n.t("RECORDE"), str(maxi(g.best, g.score))]]:
		label(row[0], Vector2(x, y), 18.0, false)
		label(row[1], Vector2(x, y + 26.0), 30.0, true)
		y += 92.0


func _draw_popup(text: String, y: float, a: float) -> void:
	label(text, Vector2(WELL.get_center().x, y), 26.0, true, a)


func _draw_over() -> void:
	draw_rect(WELL, Color(0, 0, 0, 0.55))
	label(I18n.t("FIM"), Vector2(WELL.get_center().x, WELL.get_center().y - 30), 44.0, true)


func _draw_part(p: Dictionary) -> void:
	if p.has("trail"):
		var r := Rect2(p.pos.x - CELL * 0.5, p.pos.y - p.trail, CELL, p.trail)
		draw_rect(r, Color(piece_color(p.kind), p.life * 0.8))
		return
	draw_rect(Rect2(p.pos - Vector2.ONE * p.size * 0.5, Vector2.ONE * p.size), Color(piece_color(p.kind), clampf(p.life * 2.0, 0.0, 1.0)))


# ---------------------------------------------------------------- para os estilos

func _setup() -> void:
	pass


func _build_sfx() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func music_variant() -> int:
	return 0


func piece_color(_k: int) -> Color:
	return Color.WHITE


func _draw_back() -> void:
	pass


func _draw_well(_r: Rect2) -> void:
	pass


func _draw_well_front(_r: Rect2) -> void:
	pass


## Desenha uma casa: style 0 = peça/tabuleiro, 1 = sombra, 2 = pré-visualização, 3 = guardada inativa.
func draw_block(_r: Rect2, _k: int, _style: int) -> void:
	pass


## Linha a desaparecer (t de 0 a 1).
func _draw_clearing(r: int, t: float) -> void:
	for c in BlocksGame.COLS:
		var k := game.board[r * BlocksGame.COLS + c] - 1
		var rr := cell_rect(c, r)
		draw_block(rr.grow_individual(0, -rr.size.y * t * 0.5, 0, -rr.size.y * t * 0.5), maxi(k, 0), 0)
	draw_rect(Rect2(WELL.position.x, cell_rect(0, r).position.y, WELL.size.x, CELL), Color(1, 1, 1, (1.0 - t) * 0.7))


func _draw_box(_r: Rect2, _title: String) -> void:
	pass


## Texto centrado em p (p.y = topo). big = valor/destaque.
func label(_text: String, _p: Vector2, _size: float, _big: bool, _alpha := 1.0) -> void:
	pass


func _draw_front() -> void:
	pass


func ui_palette() -> Dictionary:
	return UI.LAUNCHER_PALETTE
