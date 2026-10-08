class_name ValeSkin
extends Node2D
## Base dos estilos da Espada do Vale: cada ecrã é pintado uma vez numa textura (e outra vez quando
## se corta um arbusto ou se abre uma porta), o deslizar entre ecrãs, desenhos originais do herói,
## inimigos e objetos, corações do HUD e sons.

const T := 64.0
const ORIGIN := Vector2(128, 80)
const FIELD := Vector2(1024, 640)

const HERO := {
	"down0": ["....HHHH....", "...HHHHHH...", "..HHSSSSHH..", "..HSESSESH..", "...SSSSSS...", "....RRRR....", "..BBRRRRBB..", ".SBBBBBBBBS.", ".SBBBBBBBBS.", "...BBYYBB...", "...BBBBBB...", "...LL..LL...", "...LL..LL...", "..KKK..KKK.."],
	"down1": ["....HHHH....", "...HHHHHH...", "..HHSSSSHH..", "..HSESSESH..", "...SSSSSS...", "....RRRR....", "..BBRRRRBB..", ".SBBBBBBBBS.", "..SBBBBBBS..", "...BBYYBB...", "...BBBBBB...", "....LLLL....", "...LL..LL...", "...KK..KK..."],
	"up0": ["....HHHH....", "...HHHHHH...", "..HHHHHHHH..", "..HHHHHHHH..", "...HHHHHH...", "....RRRR....", "..BBRRRRBB..", ".SBBBRRBBBS.", ".SBBBRRBBBS.", "...BBYYBB...", "...BBBBBB...", "...LL..LL...", "...LL..LL...", "..KKK..KKK.."],
	"up1": ["....HHHH....", "...HHHHHH...", "..HHHHHHHH..", "..HHHHHHHH..", "...HHHHHH...", "....RRRR....", "..BBRRRRBB..", ".SBBBRRBBBS.", "..SBBRRBBS..", "...BBYYBB...", "...BBBBBB...", "....LLLL....", "...LL..LL...", "...KK..KK..."],
	"side0": ["....HHHH....", "...HHHHHH...", "...HHSSSS...", "...HSSSES...", "....SSSSS...", "....RRRR....", "...RRBBBB...", "..RRBBBBBS..", "....BBBBBS..", "....BYYBB...", "....BBBBB...", "....LL.LL...", "...LL...LL..", "..KK....KK.."],
	"side1": ["....HHHH....", "...HHHHHH...", "...HHSSSS...", "...HSSSES...", "....SSSSS...", "....RRRR....", "...RRBBBB...", "..RRBBBBBS..", "....BBBBBS..", "....BYYBB...", "....BBBBB...", "....LLLL....", "....LLLL....", "....KKKK...."],
}
const SLIME := ["....GGGG....", "..GGGGGGGG..", ".GGgGGGGGGG.", ".GGGGGGGGGG.", "GGGEGGGGEGGG", "GGGEGGGGEGGG", "GGGGGGGGGGGG", "GGGGGGGGGGGG", ".GGGGGGGGGG.", "..gggggggg.."]
const BAT := [
	["W............W", "WW....AA....WW", "WWW..AAAA..WWW", ".WWWWAEEAWWWW.", "..WWWAAAAWWW..", "....W.AA.W....", ".............."],
	["..............", "......AA......", ".....AAAA.....", "...WWAEEAWW...", "..WWWAAAAWWW..", ".WWW..AA..WWW.", "WW..........WW"],
]
const GOBLIN := ["..A......A..", "..AAGGGGAA..", "...GGGGGG...", "...GEGGEG...", "...GGGGGG...", "....GGGG....", "..CCCCCCCC..", ".GCCCCCCCCG.", ".GCCCCCCCCG.", "...CCCCCC...", "...CC..CC...", "...GG..GG...", "...GG..GG...", "..KKK..KKK.."]
const KNIGHT := ["....MMMM....", "...MMMMMM...", "...MVVVVM...", "...MMMMMM...", "..MMMMMMMM..", "IIMMMMMMMMM.", "IIIMMMMMMMMM", "IIIMMMMMMMMM", "IIIMMMMMMM..", ".I.MMMMMM...", "...MM..MM...", "...MM..MM...", "...MM..MM...", "..MMM..MMM.."]
const COIN := ["..YY..", ".YyYY.", "YYyYYY", "YYyYYY", "YYyYYY", "YYYYYY", ".YYYY.", "..YY.."]
const HEART := [".RR.RR.", "RRRRRRR", "RWRRRRR", "RRRRRRR", ".RRRRR.", "..RRR..", "...R..."]
const KEY := ["..YYY..", ".Y...Y.", ".Y...Y.", "..YYY..", "...Y...", "...Y...", "...YY..", "...Y...", "...YY.."]
const CRYSTAL := ["....C....", "...CCC...", "..CcCCC..", ".CcCCCCC.", "CCCCCCCCC", ".CCCCCCC.", "..CCCCC..", "...CCC...", "....C...."]

var game: ValeGame
var sfx := {}
var tex := {}
var time := 0.0
var sparks: Array[Dictionary] = []
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _step_t := 0.0
var vp_cur: SubViewport
var vp_prev: SubViewport
var _paint_cur: Node2D
var _paint_prev: Node2D
var _cur_tiles: Array[String] = []
var _prev_tiles: Array[String] = []


func attach(g: ValeGame) -> void:
	game = g
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	vp_cur = _make_vp()
	vp_prev = _make_vp()
	_paint_cur = vp_cur.get_child(0)
	_paint_prev = vp_prev.get_child(0)
	_paint_cur.draw.connect(func() -> void: _paint_room(_paint_cur, _cur_tiles, game.in_dungeon))
	_paint_prev.draw.connect(func() -> void: _paint_room(_paint_prev, _prev_tiles, game.in_dungeon))
	g.room_changed.connect(func(_d: bool, _r: Vector2i, _dir: Vector2i) -> void:
		_bake(true)
		play("door", 1.0, -8.0))
	g.match_started.connect(func() -> void: sparks.clear())
	g.swung.connect(func() -> void: play("swing", randf_range(0.95, 1.05), -2.0))
	g.hit_enemy.connect(func(p: Vector2) -> void:
		_burst(p, Color.WHITE, 6)
		play("hit"))
	g.enemy_killed.connect(func(p: Vector2, k: String) -> void:
		_burst(p, Color.WHITE, 14 if k != "boss" else 40)
		play("kill" if k != "boss" else "boss_die"))
	g.bush_cut.connect(func(p: Vector2) -> void:
		_burst(p, bush_color(), 10)
		_bake(false)
		play("bush"))
	g.door_opened.connect(func() -> void:
		_bake(false)
		play("unlock"))
	g.picked.connect(func(k: String, _p: Vector2) -> void: play(k if sfx.has(k) else "coin"))
	g.hurt.connect(func() -> void: play("hurt"))
	g.shot.connect(func(_p: Vector2) -> void: play("shoot", 1.0, -6.0))
	g.key_appeared.connect(func(p: Vector2) -> void:
		_burst(p, Color.YELLOW, 16)
		play("secret"))
	g.player_died.connect(func() -> void: play("die"))
	g.won.connect(func() -> void: play("win"))
	var cached: Variant = Synth.cache_get(get_script().resource_path)
	if cached != null:
		sfx = cached
	else:
		_build_sfx()
		Synth.cache_set(get_script().resource_path, sfx)
	_setup()
	_bake(true)


func _make_vp() -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(FIELD)
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	var n := Node2D.new()
	n.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vp.add_child(n)
	return vp


## Volta a pintar o ecrã atual (e o anterior, ao mudar de ecrã).
func _bake(both: bool) -> void:
	if vp_cur == null:
		return
	_cur_tiles = game.tiles.duplicate()
	vp_cur.render_target_update_mode = SubViewport.UPDATE_ONCE
	_paint_cur.queue_redraw()
	if both:
		_prev_tiles = game.prev_tiles.duplicate() if not game.prev_tiles.is_empty() else _cur_tiles
		vp_prev.render_target_update_mode = SubViewport.UPDATE_ONCE
		_paint_prev.queue_redraw()


func play(id: String, pitch := 1.0, volume_db := 0.0) -> void:
	if game == null or game.mode == ValeGame.Mode.DEMO or not sfx.has(id):
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
		if game.state == ValeGame.State.PLAY and game.moving:
			_step_t -= delta
			if _step_t <= 0.0:
				_step_t = 0.2
				play("step", randf_range(0.9, 1.1), -12.0)
		for s in sparks:
			s.life -= delta
			s.pos += s.vel * delta
		sparks = sparks.filter(func(s: Dictionary) -> bool: return s.life > 0.0)
		_tick(delta)
	queue_redraw()


func _burst(p: Vector2, c: Color, n: int) -> void:
	for i in n:
		sparks.append({"pos": px(p), "vel": Vector2.from_angle(randf() * TAU) * randf_range(60, 220), "life": randf_range(0.3, 0.6), "color": c})


func px(u: Vector2) -> Vector2:
	return ORIGIN + u * T


func scroll_offset() -> Vector2:
	if game.state != ValeGame.State.SCROLL:
		return Vector2.ZERO
	var k := 1.0 - game.scroll_t
	return Vector2(game.scroll_dir) * FIELD * k


## Desenha uma textura de pixel art centrada num ponto (unidades), com escala de 4.
func draw_sprite_c(t: Texture2D, c: Vector2, flip := false, modulate_c := Color.WHITE, scale := 4.0) -> void:
	var size := t.get_size() * scale
	var p := px(c) + scroll_offset() - size / 2
	if flip:
		draw_texture_rect(t, Rect2(p + Vector2(size.x, 0), Vector2(-size.x, size.y)), false, modulate_c)
	else:
		draw_texture_rect(t, Rect2(p, size), false, modulate_c)


func hero_frame() -> Array:
	var f := game.facing
	var step := int(game.anim * 7.0) % 2 if game.moving else 0
	if f.y > 0:
		return ["down%d" % step, false]
	if f.y < 0:
		return ["up%d" % step, false]
	return ["side%d" % step, f.x < 0]


func build_sprites(hero_pal: Dictionary, pals: Dictionary, outline := Color(0, 0, 0, 0)) -> void:
	for f: String in HERO:
		tex["hero_" + f] = PixelArt.outlined(HERO[f], hero_pal, outline, 1)
	tex.slime = PixelArt.outlined(SLIME, pals.slime, outline, 1)
	tex.bat0 = PixelArt.outlined(BAT[0], pals.bat, outline, 1)
	tex.bat1 = PixelArt.outlined(BAT[1], pals.bat, outline, 1)
	tex.goblin = PixelArt.outlined(GOBLIN, pals.goblin, outline, 1)
	tex.knight = PixelArt.outlined(KNIGHT, pals.knight, outline, 1)
	tex.coin = PixelArt.outlined(COIN, pals.coin, outline, 1)
	tex.heart = PixelArt.outlined(HEART, pals.heart, outline, 1)
	tex.key = PixelArt.outlined(KEY, pals.coin, outline, 1)
	tex.crystal = PixelArt.outlined(CRYSTAL, pals.crystal, outline, 1)


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	if game == null:
		return
	_draw_back()
	var off := scroll_offset()
	if game.state == ValeGame.State.SCROLL:
		draw_texture(vp_prev.get_texture(), ORIGIN + off - Vector2(game.scroll_dir) * FIELD)
	draw_texture(vp_cur.get_texture(), ORIGIN + off)
	_draw_dynamic_tiles(off)
	for d in game.drops:
		_draw_drop(d)
	for e in game.enemies:
		_draw_enemy(e)
	if _hero_visible():
		_draw_hero()
	for s in game.shots:
		_draw_shot(s)
	for s in sparks:
		draw_rect(Rect2(s.pos - Vector2(4, 4), Vector2(8, 8)), Color(s.color, s.life / 0.6))
	_draw_frame()
	_draw_hud()
	var st: Variant = game.touch_stick()
	if st != null:
		draw_arc(st, 60, 0, TAU, 32, Color(1, 1, 1, 0.3), 3.0)


func _hero_visible() -> bool:
	var g := game
	if g.state == ValeGame.State.OVER:
		return false
	if g.state == ValeGame.State.DYING:
		return true
	if g.invuln > 0.0 and fmod(time, 0.12) < 0.06:
		return false
	return true


func _draw_hero() -> void:
	var g := game
	var fr := hero_frame()
	var mod := Color.WHITE
	if g.state == ValeGame.State.DYING:
		var k := clampf(1.0 - g.timer / 1.8, 0.0, 1.0)
		var dirs := ["down0", "side0", "up0", "side0"]
		fr = [dirs[int(k * 12.0) % 4], int(k * 12.0) % 4 == 3]
		mod = Color(1, 1, 1, 1.0 - k * 0.6)
	draw_sprite_c(tex["hero_" + fr[0]], g.pos - Vector2(0, 0.15), fr[1], mod)
	if g.swing > 0.0:
		_draw_sword()


func _draw_sword() -> void:
	var g := game
	var f := Vector2(g.facing)
	var k := 1.0 - g.swing / ValeGame.SWING_TIME
	var base := px(g.pos) + scroll_offset() + f * 22.0
	var reach := 44.0 * (0.6 + 0.4 * sin(k * PI))
	var perp := Vector2(-f.y, f.x)
	var tip := base + f * reach
	var c := sword_color()
	draw_line(base, tip, Color(0, 0, 0, 0.5), 12.0)
	draw_line(base, tip, c, 7.0)
	draw_line(base - perp * 12.0, base + perp * 12.0, hilt_color(), 6.0)
	# arco do golpe
	draw_arc(px(g.pos) + scroll_offset(), 60.0, f.angle() - 0.8, f.angle() + 0.8, 12, Color(c, 0.35 * (1.0 - k)), 10.0)


func _draw_enemy(e: Dictionary) -> void:
	var p: Vector2 = e.pos
	var mod := Color(1, 1, 1, 1) if e.hurt <= 0.0 or fmod(time, 0.1) < 0.05 else Color(3, 3, 3, 1)
	match e.kind:
		"slime":
			var sq := 1.0 + sin(float(e.anim) * 8.0) * 0.08
			var t: Texture2D = tex.slime
			var size := t.get_size() * 4.0 * Vector2(sq, 2.0 - sq)
			draw_texture_rect(t, Rect2(px(p) + scroll_offset() - Vector2(size.x / 2, size.y - 20), size), false, mod)
		"bat":
			draw_sprite_c(tex.bat0 if fmod(float(e.anim), 0.3) < 0.15 else tex.bat1, p, false, mod)
		"goblin":
			draw_sprite_c(tex.goblin, p - Vector2(0, 0.15), e.dir.x < 0, mod)
		"knight":
			draw_sprite_c(tex.knight, p - Vector2(0, 0.15), e.dir.x < 0, mod)
		"boss":
			_draw_boss(p, e, mod)


func _draw_boss(p: Vector2, e: Dictionary, mod: Color) -> void:
	var c := px(p) + scroll_offset()
	var r := Rect2(c - Vector2(58, 58), Vector2(116, 116))
	var body := boss_color()
	draw_rect(r, Color(body.darkened(0.4), mod.a))
	draw_rect(r.grow(-8), Color(body * mod, 1.0))
	draw_rect(Rect2(r.position + Vector2(16, 30), Vector2(30, 16)), Color.BLACK)
	draw_rect(Rect2(r.position + Vector2(70, 30), Vector2(30, 16)), Color.BLACK)
	var glow := Color(1.0, 0.4 + 0.3 * sin(time * 6.0), 0.1)
	draw_rect(Rect2(r.position + Vector2(24, 34), Vector2(14, 8)), glow)
	draw_rect(Rect2(r.position + Vector2(78, 34), Vector2(14, 8)), glow)
	draw_line(r.position + Vector2(20, 80), r.position + Vector2(96, 80), body.darkened(0.5), 6.0)
	draw_line(r.position + Vector2(56, 8), r.position + Vector2(48, 30), body.darkened(0.5), 3.0)
	# barra de vida
	var hp: float = float(e.hp) / ValeGame.ENEMY_HP.boss
	draw_rect(Rect2(r.position + Vector2(0, -16), Vector2(r.size.x, 8)), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(r.position + Vector2(0, -16), Vector2(r.size.x * hp, 8)), Color(0.9, 0.2, 0.2))


func _draw_drop(d: Dictionary) -> void:
	if d.life > 0.0 and d.life < 2.0 and fmod(time, 0.2) < 0.1:
		return
	var bob := sin(time * 4.0) * 0.06
	match d.kind:
		"coin":
			draw_sprite_c(tex.coin, d.pos + Vector2(0, bob))
		"heart":
			draw_sprite_c(tex.heart, d.pos + Vector2(0, bob))
		"container":
			draw_sprite_c(tex.heart, d.pos + Vector2(0, bob), false, Color.WHITE, 6.0)
		"key":
			draw_sprite_c(tex.key, d.pos + Vector2(0, bob))
		"crystal":
			var c := px(d.pos) + scroll_offset()
			draw_circle(c, 40 + sin(time * 3.0) * 6, Color(0.6, 0.9, 1.0, 0.25))
			draw_sprite_c(tex.crystal, d.pos + Vector2(0, bob), false, Color.WHITE, 5.0)


func _draw_shot(s: Dictionary) -> void:
	var c := px(s.pos) + scroll_offset()
	if s.kind == "arrow":
		var v: Vector2 = (s.vel as Vector2).normalized()
		draw_line(c - v * 18, c + v * 18, Color("6b4a2a"), 4.0)
		draw_line(c + v * 18, c + v * 10 + Vector2(-v.y, v.x) * 6, Color.WHITE, 3.0)
		draw_line(c + v * 18, c + v * 10 - Vector2(-v.y, v.x) * 6, Color.WHITE, 3.0)
	else:
		draw_circle(c, 14, Color(1, 0.5, 0.1, 0.4))
		draw_circle(c, 9, Color(1, 0.8, 0.3))


## Corações em meios: `hearts` cheios de `max_hearts`.
func draw_hearts(p: Vector2, full: Color, empty: Color, size := 24.0) -> void:
	var g := game
	for i in g.max_hearts / 2:
		var c := p + Vector2(i * (size + 6), 0)
		var v := g.hearts - i * 2
		var t: Texture2D = tex.heart
		var r := Rect2(c, Vector2(size, size * 6.0 / 7.0))
		draw_texture_rect(t, r, false, empty)
		if v >= 2:
			draw_texture_rect(t, r, false, full)
		elif v == 1:
			draw_texture_rect_region(t, Rect2(c, Vector2(size / 2, size * 6.0 / 7.0)), Rect2(Vector2.ZERO, Vector2(t.get_width() / 2.0, t.get_height())), full)


func draw_minimap(p: Vector2, cell: Vector2, on: Color, off: Color, here: Color) -> void:
	var g := game
	var world := ValeGame.DUNGEON if g.in_dungeon else ValeGame.OVERWORLD
	var dims := Vector2i(3, 2) if g.in_dungeon else Vector2i(4, 3)
	for y in dims.y:
		for x in dims.x:
			var r := Rect2(p + Vector2(x, y) * cell, cell - Vector2(3, 3))
			if not world.has(Vector2i(x, y)):
				continue
			draw_rect(r, here if Vector2i(x, y) == g.room else (on if g.taken.has("clear " + g.room_key(g.in_dungeon, Vector2i(x, y))) else off))


# ---------------------------------------------------------------- para os estilos reescreverem

func _setup() -> void:
	pass


func _build_sfx() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _draw_back() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color.BLACK)


func _paint_room(_ci: CanvasItem, _tiles: Array[String], _dungeon: bool) -> void:
	pass


func _draw_dynamic_tiles(_off: Vector2) -> void:
	pass


func _draw_frame() -> void:
	draw_rect(Rect2(0, 0, ORIGIN.x, 720), Color.BLACK)
	draw_rect(Rect2(ORIGIN.x + FIELD.x, 0, 1280 - ORIGIN.x - FIELD.x, 720), Color.BLACK)
	draw_rect(Rect2(0, 0, 1280, ORIGIN.y), Color.BLACK)


func _draw_hud() -> void:
	pass


func sword_color() -> Color:
	return Color("e8f0ff")


func hilt_color() -> Color:
	return Color("b08a3a")


func boss_color() -> Color:
	return Color("8a8a96")


func bush_color() -> Color:
	return Color("3fa34d")


func ui_palette() -> Dictionary:
	return UI.LAUNCHER_PALETTE
