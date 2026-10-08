class_name FroggerSkin
extends Node2D
## Base dos estilos visuais do Frogger: desenho por partes (veículos, troncos, tartarugas),
## sons e uma pequena melodia de fundo.

const S := FroggerGame.SCALE
const C := FroggerGame.CELL

## Rã virada para cima: sentada e a saltar (desenho original).
const FROG := [
	[
		"..WW.....WW..",
		".WKKW...WKKW.",
		".WKKWGGGWKKW.",
		"..WWGGGGGWW..",
		"g.GGGGGGGGG.g",
		"gg.GGYYYGG.gg",
		".g.GYYYYYG.g.",
		"...GYYYYYG...",
		"gg.GGGGGGG.gg",
		"ggg.GGGGG.ggg",
		".g.........g.",
	],
	[
		"..WW.....WW..",
		".WKKW...WKKW.",
		".WKKWGGGWKKW.",
		"g.WWGGGGGWW.g",
		"gg.GGGGGGG.gg",
		".g.GGYYYGG.g.",
		"...GYYYYYG...",
		"...GYYYYYG...",
		"....GGGGG....",
		"...gg...gg...",
		"..gg.....gg..",
		".gg.......gg.",
	],
]
const FLY := ["W.....W", ".W...W.", "..WKW..", ".WKKKW.", "..KKK..", "...K..."]
const CROC := [
	"..GG.......GG...",
	".GWKG.....GKWG..",
	"GGGGGGGGGGGGGGG.",
	"GWGWGWGWGWGWGWGG",
	"G..............G",
	"GWGWGWGWGWGWGWGG",
	".GGGGGGGGGGGGGG.",
]

var game: FroggerGame
var sfx := {}
var popups: Array[Dictionary] = []       # {pos (px), text, life}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _music: AudioStreamPlayer
var time := 0.0


func attach(g: FroggerGame) -> void:
	game = g
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	g.match_started.connect(_on_match_started)
	g.turn_started.connect(_on_turn_started)
	g.hopped.connect(_on_hopped)
	g.frog_home.connect(_on_frog_home)
	g.frog_died.connect(_on_frog_died)
	g.time_warning.connect(_on_time_warning)
	g.extra_life.connect(_on_extra_life)
	g.level_cleared.connect(_on_level_cleared)
	g.game_over.connect(_on_game_over)
	var cached: Variant = Synth.cache_get(get_script().resource_path)
	if cached != null:
		sfx = cached
	else:
		_build_sfx()
		Synth.cache_set(get_script().resource_path, sfx)
	_setup()


func play(id: String, pitch := 1.0, volume_db := 0.0) -> void:
	if game == null or game.mode == FroggerGame.Mode.DEMO or not sfx.has(id):
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = sfx[id]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


func _update_music() -> void:
	var want := sfx.has("music") and not game.paused and game.mode != FroggerGame.Mode.DEMO \
		and game.state in [FroggerGame.State.PLAY, FroggerGame.State.READY]
	if want and not _music.playing:
		var s: AudioStreamWAV = sfx.music
		if s.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_end = s.data.size() / 2
		_music.stream = s
		_music.volume_db = -10.0
		_music.play()
	elif not want and _music.playing:
		_music.stop()


func _process(delta: float) -> void:
	if game == null:
		return
	_update_music()
	if not game.paused:
		time += delta
		for p in popups:
			p.life -= delta
			p.pos.y -= 16.0 * delta
		popups = popups.filter(func(p: Dictionary) -> bool: return p.life > 0.0)
		_tick(delta)
	queue_redraw()


func ui_palette() -> Dictionary:
	return UI.LAUNCHER_PALETTE


# ---------------------------------------------------------------- geometria (em píxeis)

func px(u: Vector2) -> Vector2:
	return game.to_px(u)


func row_rect(row: int) -> Rect2:
	return Rect2(px(Vector2(0, row * C)), Vector2(FroggerGame.W * S, C * S))


func field_rect() -> Rect2:
	return Rect2(FroggerGame.ORIGIN, Vector2(FroggerGame.W, 14 * C) * S)


func obj_rect(o: Dictionary) -> Rect2:
	var r := game.object_rect(o)
	return Rect2(px(r.position), r.size * S)


func bay_rect(i: int) -> Rect2:
	return Rect2(px(Vector2(FroggerGame.BAYS[i] - 10, 2)), Vector2(20, 14) * S)


## Partes de um veículo: [[Rect2, papel], ...]; papel: body, cabin, window, wheel, light, blade
func vehicle_parts(o: Dictionary) -> Array:
	var r := obj_rect(o)
	var left: bool = game.lane_speed(o.row) < 0.0
	var parts := []
	var wh := Vector2(r.size.x * 0.18 if o.len == 1 else 10.0, 6.0)
	for wx in [r.position.x + r.size.x * 0.12, r.end.x - r.size.x * 0.12 - wh.x]:
		parts.append([Rect2(Vector2(wx, r.position.y - 1), wh), "wheel"])
		parts.append([Rect2(Vector2(wx, r.end.y - wh.y + 1), wh), "wheel"])
	match o.kind:
		"truck":
			var cab_w := r.size.x * 0.28
			var cab := Rect2(r.position.x if left else r.end.x - cab_w, r.position.y + 4, cab_w, r.size.y - 8)
			var box := Rect2(r.position.x + (cab_w + 3 if left else 0), r.position.y + 2, r.size.x - cab_w - 3, r.size.y - 4)
			parts.append([box, "body"])
			parts.append([cab, "cabin"])
			parts.append([Rect2(cab.position + Vector2(4 if left else cab.size.x - 10, 4), Vector2(6, cab.size.y - 8)), "window"])
		"dozer":
			parts.append([Rect2(r.position + Vector2(4, 4), r.size - Vector2(8, 8)), "body"])
			var bx := r.end.x - 2 if not left else r.position.x - 4
			parts.append([Rect2(bx, r.position.y, 6, r.size.y), "blade"])
			parts.append([Rect2(r.get_center() - Vector2(7, 7), Vector2(14, 14)), "cabin"])
		"racer":
			parts.append([Rect2(r.position + Vector2(2, 8), r.size - Vector2(4, 16)), "body"])
			parts.append([Rect2(r.get_center() - Vector2(6, 6), Vector2(12, 12)), "cabin"])
			var fx := r.position.x - 2 if left else r.end.x - 6
			parts.append([Rect2(fx, r.position.y + 4, 8, r.size.y - 8), "light"])
		_:
			parts.append([Rect2(r.position + Vector2(2, 4), r.size - Vector2(4, 8)), "body"])
			parts.append([Rect2(r.get_center() - Vector2(9, 9), Vector2(18, 18)), "cabin"])
			var wx2 := r.position.x + 6 if left else r.end.x - 12
			parts.append([Rect2(wx2, r.position.y + 10, 6, r.size.y - 20), "window"])
	return parts


## Tartarugas de um grupo: lista de [centro, raio] (já com o efeito de mergulho).
func turtle_shells(o: Dictionary) -> Array:
	var r := obj_rect(o)
	var stage := game.turtle_stage(o)
	var k := 1.0 if stage == 0 else (0.7 if stage in [1, 3] else 0.0)
	var out := []
	for i in o.len:
		var c := Vector2(r.position.x + (i + 0.5) * C * S, r.get_center().y)
		out.append([c, C * S * 0.42 * k])
	return out


func frog_frame() -> Array:
	return FROG[1] if game.hop_t >= 0.0 else FROG[0]


func frog_angle() -> float:
	match game.frog_face:
		Vector2i.DOWN:
			return PI
		Vector2i.LEFT:
			return -PI / 2
		Vector2i.RIGHT:
			return PI / 2
	return 0.0


## Zonas fora do campo (tapadas depois de desenhar os objetos que estão a "dar a volta").
func side_rects() -> Array[Rect2]:
	var f := field_rect()
	return [Rect2(-40, -40, f.position.x + 40, 800), Rect2(f.end.x, -40, 1320 - f.end.x, 800)]


func panel_left_x() -> float:
	return FroggerGame.ORIGIN.x / 2


func panel_right_x() -> float:
	var r := FroggerGame.ORIGIN.x + FroggerGame.W * S
	return r + (1280.0 - r) / 2


# ---------------------------------------------------------------- para os estilos reescreverem

func _setup() -> void:
	pass


func _build_sfx() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _on_match_started() -> void:
	popups.clear()


func _on_turn_started(_player: int) -> void:
	pass


func _on_hopped(_pos: Vector2) -> void:
	play("hop", randf_range(0.97, 1.03))


func _on_frog_home(bay: int, points: int, fly: bool) -> void:
	play("home")
	if fly:
		play("fly", 1.0, -2.0)
	popups.append({"pos": bay_rect(bay).get_center(), "text": str(points), "life": 1.4})


func _on_frog_died(_pos: Vector2, cause: String) -> void:
	play("splash" if cause == "agua" else "squash")


func _on_time_warning() -> void:
	play("warn")


func _on_extra_life() -> void:
	play("extra")


func _on_level_cleared() -> void:
	play("clear")


func _on_game_over() -> void:
	pass
