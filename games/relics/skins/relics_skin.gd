class_name RelicsSkin
extends Node2D
## Base dos estilos da Torre das Relíquias: projeção isométrica, ordem de desenho (de trás para a
## frente), cubos, paredes com portas, desenhos originais (explorador, guarda, fantasma, relíquia,
## coração) e sons. Os estilos escolhem cores, faces dos cubos, chão, paredes e HUD.

const TW := 80.0
const TH := 40.0
const ZH := 44.0
const WALL_H := 2.6

const MAN := {
	"front0": [
		"....HHHH....",
		"...HHHHHH...",
		"..HHHHHHHH..",
		"....SSSS....",
		"....SEES....",
		"....SSSS....",
		"...BBBBBB...",
		"..BBBBBBBB..",
		".SBBBBBBBBS.",
		".S.BBbbBB.S.",
		"...BBBBBB...",
		"...BBBBBB...",
		"...LL..LL...",
		"...LL..LL...",
		"...LL..LL...",
		"..KKK..KKK..",
	],
	"front1": [
		"....HHHH....",
		"...HHHHHH...",
		"..HHHHHHHH..",
		"....SSSS....",
		"....SEES....",
		"....SSSS....",
		"...BBBBBB...",
		"..BBBBBBBB..",
		".SBBBBBBBBS.",
		"..SBBbbBBS..",
		"...BBBBBB...",
		"...BBBBBB...",
		"....LLLL....",
		"...LL..LL...",
		"..LL....LL..",
		"..KK....KK..",
	],
	"back0": [
		"....HHHH....",
		"...HHHHHH...",
		"..HHHHHHHH..",
		"....HHHH....",
		"....hhhh....",
		"....SSSS....",
		"...BBPPBB...",
		"..BBPPPPBB..",
		".SBBPPPPBBS.",
		".S.BPPPPB.S.",
		"...BBBBBB...",
		"...BBBBBB...",
		"...LL..LL...",
		"...LL..LL...",
		"...LL..LL...",
		"..KKK..KKK..",
	],
	"back1": [
		"....HHHH....",
		"...HHHHHH...",
		"..HHHHHHHH..",
		"....HHHH....",
		"....hhhh....",
		"....SSSS....",
		"...BBPPBB...",
		"..BBPPPPBB..",
		".SBBPPPPBBS.",
		"..SBPPPPBS..",
		"...BBBBBB...",
		"...BBBBBB...",
		"....LLLL....",
		"...LL..LL...",
		"..LL....LL..",
		"..KK....KK..",
	],
}
const GUARD := [
	"....AAAA....",
	"...AAAAAA...",
	"..AAAAAAAA..",
	"..AVVVVVVA..",
	"..AAAAAAAA..",
	"...AAAAAA...",
	"..aAAAAAAa..",
	".aaAAAAAAaa.",
	".a.AAAAAA.a.",
	".a.AAAAAA.a.",
	"...aaaaaa...",
	"...aa..aa...",
	"...aa..aa...",
	"..aaa..aaa..",
]
const GHOST := [
	"....GGGG....",
	"..GGGGGGGG..",
	".GGGGGGGGGG.",
	".GGEEGGEEGG.",
	".GGEEGGEEGG.",
	"GGGGGGGGGGGG",
	"GGGGGOOGGGGG",
	"GGGGGOOGGGGG",
	"GGGGGGGGGGGG",
	"GGGGGGGGGGGG",
	"GG.GGG.GGG.G",
	"G...G...G...",
]
const RELIC := ["..YYYY..", ".YyYYYY.", ".YYYYYY.", "..YYYY..", "...YY...", "...YY...", "..YYYY..", ".YYYYYY."]
const HEART := [".RR.RR.", "RRRRRRR", "RRWRRRR", "RRRRRRR", ".RRRRR.", "..RRR..", "...R..."]

var game: RelicsGame
var sfx := {}
var tex := {}
var time := 0.0
var origin := Vector2(640, 214)
var popups: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _step_t := 0.0


func attach(g: RelicsGame) -> void:
	game = g
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	g.match_started.connect(func() -> void:
		popups.clear()
		sparks.clear())
	g.room_entered.connect(func(_r: Vector2i) -> void: play("door", 1.0, -6.0))
	g.jumped.connect(func() -> void: play("jump"))
	g.landed.connect(func() -> void: play("land", 1.0, -8.0))
	g.picked.connect(func(_k: String) -> void: play("pick"))
	g.dropped.connect(func() -> void: play("drop"))
	g.pushed.connect(func() -> void: pass)
	g.relic_taken.connect(func(p: Vector3) -> void:
		_burst(p + Vector3(0, 0, 0.4), relic_color())
		play("relic"))
	g.heart_taken.connect(func() -> void: play("heart"))
	g.relics_deposited.connect(func(_c: int, _t: int) -> void:
		_burst(game.pos + Vector3(0, 0, 1.0), relic_color())
		play("deposit"))
	g.player_died.connect(func(p: Vector3) -> void:
		_burst(p + Vector3(0, 0, 0.6), Color.WHITE)
		play("die"))
	g.day_changed.connect(func(_d: int) -> void: play("day", 1.0, -6.0))
	g.won.connect(func() -> void: play("win"))
	var cached: Variant = Synth.cache_get(get_script().resource_path)
	if cached != null:
		sfx = cached
	else:
		_build_sfx()
		Synth.cache_set(get_script().resource_path, sfx)
	_setup()


func play(id: String, pitch := 1.0, volume_db := 0.0) -> void:
	if game == null or game.mode == RelicsGame.Mode.DEMO or not sfx.has(id):
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
		if game.state == RelicsGame.State.PLAY and game.moving and game.grounded:
			_step_t -= delta
			if _step_t <= 0.0:
				_step_t = 0.22
				play("step", randf_range(0.9, 1.1), -10.0)
		for s in sparks:
			s.life -= delta
			s.pos += s.vel * delta
		sparks = sparks.filter(func(s: Dictionary) -> bool: return s.life > 0.0)
		_tick(delta)
	queue_redraw()


func _burst(p: Vector3, c: Color) -> void:
	for i in 14:
		var a := i * TAU / 14
		sparks.append({"pos": iso(p), "vel": Vector2.from_angle(a) * randf_range(60, 160), "life": 0.6, "color": c})


func iso(p: Vector3) -> Vector2:
	return origin + Vector2((p.x - p.y) * TW / 2, (p.x + p.y) * TH / 2 - p.z * ZH)


# ---------------------------------------------------------------- cubos

## As três faces visíveis de uma caixa: topo, frente-esquerda (+y) e frente-direita (+x).
func box_faces(p: Vector3, s: Vector3) -> Array:
	var top := PackedVector2Array([iso(p + Vector3(0, 0, s.z)), iso(p + Vector3(s.x, 0, s.z)), iso(p + Vector3(s.x, s.y, s.z)), iso(p + Vector3(0, s.y, s.z))])
	var left := PackedVector2Array([iso(p + Vector3(0, s.y, s.z)), iso(p + Vector3(s.x, s.y, s.z)), iso(p + Vector3(s.x, s.y, 0)), iso(p + Vector3(0, s.y, 0))])
	var right := PackedVector2Array([iso(p + Vector3(s.x, 0, s.z)), iso(p + Vector3(s.x, s.y, s.z)), iso(p + Vector3(s.x, s.y, 0)), iso(p + Vector3(s.x, 0, 0))])
	return [top, left, right]


func draw_box(p: Vector3, s: Vector3, top: Color, left: Color, right: Color, line := Color(0, 0, 0, 0), lw := 2.0) -> void:
	var f := box_faces(p, s)
	draw_colored_polygon(f[1], left)
	draw_colored_polygon(f[2], right)
	draw_colored_polygon(f[0], top)
	if line.a > 0.0:
		for poly: PackedVector2Array in f:
			var q := poly.duplicate()
			q.append(q[0])
			draw_polyline(q, line, lw)


## Desenha uma textura de pé num ponto do mundo (centro da base).
func draw_sprite_at(t: Texture2D, feet: Vector3, scale := 3.0, flip := false, modulate_c := Color.WHITE) -> void:
	var size := t.get_size() * scale
	var p := iso(feet) - Vector2(size.x / 2, size.y - 6)
	if flip:
		draw_texture_rect(t, Rect2(p + Vector2(size.x, 0), Vector2(-size.x, size.y)), false, modulate_c)
	else:
		draw_texture_rect(t, Rect2(p, size), false, modulate_c)


func draw_shadow(p: Vector3, r: float, c: Color) -> void:
	var z := game.support_under(AABB(Vector3(p.x - 0.2, p.y - 0.2, p.z), Vector3(0.4, 0.4, 0.1)), p.z + 0.01)
	var c2 := iso(Vector3(p.x, p.y, z))
	draw_set_transform(c2, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, r, c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	if game == null:
		return
	_draw_back()
	_draw_room_shell()
	for c: Vector2i in game.spikes:
		_draw_spikes(c)
	# lista de tudo o que tem volume, ordenada de trás para a frente
	var list := []
	for b in game.blocks:
		var p: Vector3 = b.pos
		var s: Vector3 = b.size
		var levels := int(round(s.z)) if b.kind == "stone" else 1
		for k in levels:
			var pp := p + Vector3(0, 0, k)
			var ss := Vector3(s.x, s.y, 1.0 if b.kind == "stone" else s.z)
			list.append({"key": pp.x + ss.x / 2 + pp.y + ss.y / 2 + pp.z * 0.01, "type": "block", "b": b, "p": pp, "s": ss, "top": k == levels - 1})
	for it in game.items:
		var ip: Vector3 = it.pos
		list.append({"key": ip.x + ip.y + ip.z * 0.01 + 0.02, "type": "item", "it": it})
	for e in game.enemies:
		var ep: Vector3 = e.pos
		list.append({"key": ep.x + ep.y + game.enemy_z(e) * 0.01 + 0.03, "type": "enemy", "e": e})
	if _player_visible():
		list.append({"key": game.pos.x + game.pos.y + game.pos.z * 0.01 + 0.04, "type": "player"})
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.key < b.key)
	for d: Dictionary in list:
		match d.type:
			"block":
				_draw_block(d.b, d.p, d.s, d.top)
			"item":
				_draw_item(d.it)
			"enemy":
				_draw_enemy(d.e)
			"player":
				_draw_player()
	_draw_front_doors()
	for s in sparks:
		draw_rect(Rect2(s.pos - Vector2(3, 3), Vector2(6, 6)), Color(s.color, s.life / 0.6))
	_draw_hud()


func _player_visible() -> bool:
	var g := game
	if g.state == RelicsGame.State.OVER:
		return false
	if g.state == RelicsGame.State.DYING:
		return fmod(time, 0.16) < 0.08
	return not (g.state == RelicsGame.State.READY and fmod(time, 0.24) < 0.1)


func man_frame() -> Array:
	var f := game.facing
	var back := f.x + f.y < -0.1 or (absf(f.x + f.y) <= 0.1 and f.y < 0.0)
	# para a direita no ecrã: +x (frente) ou -y (costas)
	var right := f.x - f.y > 0.0
	var step := int(game.anim * 7.0) % 2 if game.moving and game.grounded else 0
	return [("back" if back else "front") + str(step), not right]


## Paredes do fundo (com portas), chão e os contornos.
func _draw_room_shell() -> void:
	var g := game
	var n := float(RelicsGame.ROOM)
	_draw_floor()
	# parede do lado W (x = 0) e N (y = 0)
	_draw_wall("W", Vector3(0, 0, 0), Vector3(0, n, 0), g.doors.get("W", -1))
	_draw_wall("N", Vector3(0, 0, 0), Vector3(n, 0, 0), g.doors.get("N", -1))


## Parede plana entre a e b (no chão), com a porta (altura dz) ao meio, se houver.
func _draw_wall(side: String, a: Vector3, b: Vector3, dz: int) -> void:
	var segs := []
	if dz >= 0:
		var t0 := RelicsGame.DOOR_A / RelicsGame.ROOM
		var t1 := RelicsGame.DOOR_B / RelicsGame.ROOM
		segs.append([0.0, t0, 0.0, WALL_H])
		segs.append([t1, 1.0, 0.0, WALL_H])
		if dz > 0:
			segs.append([t0, t1, 0.0, float(dz)])
		if dz + 2.0 < WALL_H:
			segs.append([t0, t1, dz + 2.0, WALL_H])
	else:
		segs.append([0.0, 1.0, 0.0, WALL_H])
	for s: Array in segs:
		var p0 := a.lerp(b, s[0])
		var p1 := a.lerp(b, s[1])
		var z0: float = s[2]
		var z1: float = s[3]
		_wall_quad(side, PackedVector2Array([iso(p0 + Vector3(0, 0, z0)), iso(p1 + Vector3(0, 0, z0)), iso(p1 + Vector3(0, 0, z1)), iso(p0 + Vector3(0, 0, z1))]), z0, z1)
	if dz >= 0:
		var t0 := RelicsGame.DOOR_A / RelicsGame.ROOM
		var t1 := RelicsGame.DOOR_B / RelicsGame.ROOM
		var d0 := a.lerp(b, t0) + Vector3(0, 0, dz)
		var d1 := a.lerp(b, t1) + Vector3(0, 0, dz)
		_draw_door(side, PackedVector2Array([iso(d0), iso(d1), iso(d1 + Vector3(0, 0, 2.0)), iso(d0 + Vector3(0, 0, 2.0))]), dz)


## Marcas das portas da frente (lados S e E), que não têm parede desenhada.
func _draw_front_doors() -> void:
	var n := float(RelicsGame.ROOM)
	for side: String in ["S", "E"]:
		if not game.doors.has(side):
			continue
		var dz: float = game.doors[side]
		var a := Vector3(RelicsGame.DOOR_A, n, dz) if side == "S" else Vector3(n, RelicsGame.DOOR_A, dz)
		var b := Vector3(RelicsGame.DOOR_B, n, dz) if side == "S" else Vector3(n, RelicsGame.DOOR_B, dz)
		_draw_front_door(side, a, b, dz)


func _draw_hud_common(ink: Color, accent: Color, dim: Color, font_draw: Callable) -> void:
	var g := game
	# relíquias: 8 casas (entregues cheias, levadas a meio)
	for i in RelicsGame.RELICS:
		var r := Rect2(470 + i * 44, 664, 36, 36)
		var t: Texture2D = tex.relic
		var c := dim
		if i < g.deposited:
			c = accent
		elif i < g.deposited + g.carried_relics:
			c = Color(accent, 0.55)
		draw_texture_rect(t, r, false, c)
	# mapa
	for y in RelicsGame.MAP.y:
		for x in RelicsGame.MAP.x:
			var v := Vector2i(x, y)
			var r := Rect2(1120 + x * 34, 560 + y * 34, 30, 30)
			if v == g.room:
				draw_rect(r, accent)
			elif g.visited.has(v):
				draw_rect(r, Color(ink, 0.45))
			else:
				draw_rect(r, Color(ink, 0.8), false, 1.5)
			if v == RelicsGame.START_ROOM:
				draw_circle(r.get_center(), 4, ink if v != g.room else dim)
	font_draw.call(g.room_name().to_upper(), Vector2(640, 40))


# ---------------------------------------------------------------- para os estilos reescreverem

func _setup() -> void:
	pass


func _build_sfx() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _draw_back() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color.BLACK)


func _draw_floor() -> void:
	pass


func _wall_quad(_side: String, _q: PackedVector2Array, _z0: float, _z1: float) -> void:
	pass


func _draw_door(_side: String, _q: PackedVector2Array, _dz: int) -> void:
	pass


func _draw_front_door(_side: String, _a: Vector3, _b: Vector3, _dz: float) -> void:
	pass


func _draw_spikes(_c: Vector2i) -> void:
	pass


func _draw_block(_b: Dictionary, _p: Vector3, _s: Vector3, _top: bool) -> void:
	pass


func _draw_item(_it: Dictionary) -> void:
	pass


func _draw_enemy(_e: Dictionary) -> void:
	pass


func _draw_player() -> void:
	pass


func _draw_hud() -> void:
	pass


func relic_color() -> Color:
	return Color.GOLD


func ui_palette() -> Dictionary:
	return UI.LAUNCHER_PALETTE
