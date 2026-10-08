class_name PalaceSkin
extends Node2D
## Base dos estilos da Fuga do Palácio: personagens como esqueletos animados por poses
## (interpoladas, para uma animação suave "cinemática"), o ecrã de 10 x 3 casas gravado numa
## textura, portões, espinhos, portas, poções e sons. Os estilos escolhem como desenhar.

const OFF_Y := 20.0
const ROOM_W := PalaceGame.TW * PalaceGame.ROOM_COLS
const ROOM_H := PalaceGame.RH * PalaceGame.ROOM_ROWS
const BONES := {"torso": 54.0, "thigh": 44.0, "shin": 44.0, "upper": 34.0, "fore": 32.0}

## Poses: lean (tronco), hip (descida da anca), th/sh (coxa e canela, f = da frente, b = de trás),
## ua/fa (braço e antebraço). Ângulos em radianos a partir da vertical, positivos para a frente.
const POSES := {
	"stand": {"lean": 0.05, "hip": 0.0, "th_f": 0.1, "sh_f": 0.05, "th_b": -0.08, "sh_b": 0.05, "ua_f": 0.12, "fa_f": 0.2, "ua_b": -0.12, "fa_b": 0.15},
	"run0": {"lean": 0.25, "hip": 6.0, "th_f": 0.7, "sh_f": 0.2, "th_b": -0.5, "sh_b": 0.9, "ua_f": -0.6, "fa_f": 0.8, "ua_b": 0.8, "fa_b": 0.9},
	"run1": {"lean": 0.25, "hip": 14.0, "th_f": 0.15, "sh_f": 1.5, "th_b": 0.2, "sh_b": 0.25, "ua_f": 0.1, "fa_f": 1.2, "ua_b": 0.0, "fa_b": 1.2},
	"run2": {"lean": 0.25, "hip": 6.0, "th_f": -0.5, "sh_f": 0.9, "th_b": 0.7, "sh_b": 0.2, "ua_f": 0.8, "fa_f": 0.9, "ua_b": -0.6, "fa_b": 0.8},
	"run3": {"lean": 0.25, "hip": 14.0, "th_f": 0.2, "sh_f": 0.25, "th_b": 0.15, "sh_b": 1.5, "ua_f": 0.0, "fa_f": 1.2, "ua_b": 0.1, "fa_b": 1.2},
	"step0": {"lean": 0.08, "hip": 2.0, "th_f": 0.35, "sh_f": 0.1, "th_b": -0.3, "sh_b": 0.3, "ua_f": -0.25, "fa_f": 0.3, "ua_b": 0.3, "fa_b": 0.3},
	"step1": {"lean": 0.08, "hip": 4.0, "th_f": 0.05, "sh_f": 0.6, "th_b": 0.05, "sh_b": 0.1, "ua_f": 0.0, "fa_f": 0.4, "ua_b": 0.0, "fa_b": 0.4},
	"crouch": {"lean": 0.5, "hip": 40.0, "th_f": 1.3, "sh_f": 1.9, "th_b": 1.0, "sh_b": 1.9, "ua_f": 0.9, "fa_f": 0.6, "ua_b": 0.6, "fa_b": 0.6},
	"jump": {"lean": 0.2, "hip": 10.0, "th_f": 1.1, "sh_f": 1.3, "th_b": -0.2, "sh_b": 1.0, "ua_f": 2.2, "fa_f": 0.2, "ua_b": 1.8, "fa_b": 0.3},
	"rjump": {"lean": 0.35, "hip": 4.0, "th_f": 1.0, "sh_f": 0.2, "th_b": -0.8, "sh_b": 0.6, "ua_f": 2.4, "fa_f": 0.0, "ua_b": -1.0, "fa_b": 0.3},
	"reach": {"lean": 0.0, "hip": 0.0, "th_f": 0.08, "sh_f": 0.0, "th_b": -0.08, "sh_b": 0.0, "ua_f": 2.95, "fa_f": 0.0, "ua_b": 2.95, "fa_b": 0.0},
	"hang": {"lean": -0.05, "hip": 0.0, "th_f": 0.15, "sh_f": 0.2, "th_b": -0.05, "sh_b": 0.1, "ua_f": 3.0, "fa_f": 0.0, "ua_b": 3.0, "fa_b": 0.0},
	"climb": {"lean": 0.7, "hip": 30.0, "th_f": 1.6, "sh_f": 2.2, "th_b": 0.3, "sh_b": 0.5, "ua_f": 0.3, "fa_f": 0.1, "ua_b": 0.2, "fa_b": 0.1},
	"fall": {"lean": -0.1, "hip": 4.0, "th_f": 0.5, "sh_f": 0.8, "th_b": -0.3, "sh_b": 0.6, "ua_f": 2.6, "fa_f": 0.4, "ua_b": 2.2, "fa_b": 0.6},
	"guard": {"lean": 0.1, "hip": 10.0, "th_f": 0.45, "sh_f": 0.3, "th_b": -0.45, "sh_b": 0.2, "ua_f": 1.1, "fa_f": 0.3, "ua_b": -0.6, "fa_b": 1.5},
	"strike": {"lean": 0.3, "hip": 14.0, "th_f": 0.75, "sh_f": 0.4, "th_b": -0.6, "sh_b": 0.1, "ua_f": 1.55, "fa_f": 0.0, "ua_b": -0.9, "fa_b": 1.2},
	"parry": {"lean": -0.05, "hip": 8.0, "th_f": 0.35, "sh_f": 0.3, "th_b": -0.45, "sh_b": 0.2, "ua_f": 2.3, "fa_f": 0.6, "ua_b": -0.6, "fa_b": 1.5},
	"dead": {"lean": 0.0, "hip": 0.0, "th_f": 0.2, "sh_f": 0.3, "th_b": -0.1, "sh_b": 0.2, "ua_f": 2.2, "fa_f": 0.4, "ua_b": 1.6, "fa_b": 0.2},
}

var game: PalaceGame
var sfx := {}
var time := 0.0
var sparks: Array[Dictionary] = []
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var vp: SubViewport
var _paint: Node2D
var _painted_room := Vector2i(-1, -1)


func attach(g: PalaceGame) -> void:
	game = g
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	vp = SubViewport.new()
	vp.size = Vector2i(int(ROOM_W), int(ROOM_H))
	vp.disable_3d = true
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	_paint = Node2D.new()
	vp.add_child(_paint)
	_paint.draw.connect(func() -> void: _paint_room(_paint, _painted_room))
	g.room_changed.connect(func(_r: Vector2i) -> void: rebake())
	g.level_started.connect(func(_l: int) -> void: rebake())
	g.loose_fell.connect(func(_c: Vector2i) -> void:
		rebake()
		play("crumble"))
	g.picked.connect(func(k: String) -> void:
		rebake()
		play(k))
	g.step.connect(func() -> void: play("step", randf_range(0.9, 1.1), -10.0))
	g.jumped.connect(func() -> void: play("jump", 1.0, -4.0))
	g.landed.connect(func(hard: bool) -> void: play("land_hard" if hard else "land", 1.0, -2.0))
	g.grabbed.connect(func() -> void: play("grab", 1.0, -4.0))
	g.bumped.connect(func() -> void: play("bump"))
	g.gate_opened.connect(func() -> void: play("gate"))
	g.exit_opened.connect(func() -> void: play("exit_open"))
	g.spikes_out.connect(func(_c: Vector2i) -> void: play("spikes", 1.0, -6.0))
	g.sword_clash.connect(func() -> void:
		play("clash")
		_spark(game.pos + Vector2(game.facing * 70, -110), Color.WHITE))
	g.sword_hit.connect(func(who: String) -> void: play("hit_" + who))
	g.guard_died.connect(func() -> void: play("guard_die"))
	g.player_died.connect(func(_h: String) -> void: play("die"))
	g.level_done.connect(func() -> void: play("level"))
	g.won.connect(func() -> void: play("win"))
	var cached: Variant = Synth.cache_get(get_script().resource_path)
	if cached != null:
		sfx = cached
	else:
		_build_sfx()
		Synth.cache_set(get_script().resource_path, sfx)
	_setup()
	rebake()


func rebake() -> void:
	if vp == null or game == null or game.tiles.is_empty():
		return
	_painted_room = game.room
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	_paint.queue_redraw()


func play(id: String, pitch := 1.0, volume_db := 0.0) -> void:
	if game == null or game.mode == PalaceGame.Mode.DEMO or not sfx.has(id):
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
		for s in sparks:
			s.life -= delta
			s.pos += s.vel * delta
		sparks = sparks.filter(func(s: Dictionary) -> bool: return s.life > 0.0)
		_tick(delta)
	queue_redraw()


func _spark(p: Vector2, c: Color) -> void:
	for i in 10:
		sparks.append({"pos": scr(p), "vel": Vector2.from_angle(randf() * TAU) * randf_range(80, 260), "life": 0.3, "color": c})


## Posição no ecrã de um ponto do nível.
func scr(p: Vector2) -> Vector2:
	return p - Vector2(game.room.x * ROOM_W, game.room.y * ROOM_H) + Vector2(0, OFF_Y)


## Retângulo (no referencial do ecrã gravado) de uma casa do ecrã atual.
func cell_rect(c: int, r: int) -> Rect2:
	return Rect2(c * PalaceGame.TW, r * PalaceGame.RH, PalaceGame.TW, PalaceGame.RH)


# ---------------------------------------------------------------- esqueleto

static func lerp_pose(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var out := {}
	for k: String in a:
		out[k] = lerpf(a[k], b[k], t)
	return out


func cycle(names: Array, speed: float, t: float) -> Dictionary:
	var ph := fmod(t * speed, float(names.size()))
	var i := int(ph)
	return lerp_pose(POSES[names[i]], POSES[names[(i + 1) % names.size()]], ph - i)


## Pose do herói conforme o estado.
func hero_pose() -> Dictionary:
	var g := game
	var A := PalaceGame.Act
	var t := g.act_t
	match g.act:
		A.RUN, A.STOP:
			var p := cycle(["run0", "run1", "run2", "run3"], 7.0 * clampf(absf(g.vel.x) / PalaceGame.RUN_V, 0.4, 1.0), g.anim)
			if g.act == A.STOP:
				p = lerp_pose(p, POSES.crouch, 0.35)
			return p
		A.STEP:
			return cycle(["step0", "step1"], 3.0, t)
		A.TURN:
			return lerp_pose(POSES.stand, POSES.crouch, 0.25)
		A.CROUCH:
			return lerp_pose(POSES.stand, POSES.crouch, clampf(t / 0.15, 0.0, 1.0))
		A.LAND:
			return lerp_pose(POSES.crouch, POSES.stand, clampf((t - 0.1) / 0.22, 0.0, 1.0))
		A.JUMP:
			return lerp_pose(POSES.crouch, POSES.jump, clampf(t / 0.15, 0.0, 1.0))
		A.RJUMP:
			return lerp_pose(POSES.run0, POSES.rjump, clampf(t / 0.12, 0.0, 1.0))
		A.JUMPUP:
			return lerp_pose(POSES.crouch, POSES.reach, clampf(t / 0.2, 0.0, 1.0))
		A.HANG:
			var p := POSES.hang.duplicate()
			p.th_f += sin(time * 3.0) * 0.08
			return p
		A.CLIMB:
			var k := clampf(t / 0.6, 0.0, 1.0)
			if k < 0.5:
				return lerp_pose(POSES.hang, POSES.climb, k * 2.0)
			return lerp_pose(POSES.climb, POSES.stand, (k - 0.5) * 2.0)
		A.FALL:
			var p := POSES.fall.duplicate()
			p.ua_f += sin(time * 14.0) * 0.3
			p.ua_b += cos(time * 14.0) * 0.3
			return p
		A.SWORD:
			return POSES.guard
		A.STRIKE:
			return lerp_pose(POSES.guard, POSES.strike, sin(clampf(t / 0.42, 0.0, 1.0) * PI))
		A.PARRY:
			return lerp_pose(POSES.guard, POSES.parry, sin(clampf(t / 0.35, 0.0, 1.0) * PI))
		A.DEAD:
			return POSES.dead
		A.EXIT:
			return cycle(["step0", "step1"], 3.0, t)
	return POSES.stand


func guard_pose(gd: Dictionary) -> Dictionary:
	var A := PalaceGame.Act
	var t: float = gd.act_t
	match gd.act:
		A.SWORD:
			var p := POSES.guard.duplicate()
			p.hip += sin(float(gd.anim) * 4.0) * 2.0
			return p
		A.STRIKE:
			return lerp_pose(POSES.guard, POSES.strike, sin(clampf(t / 0.5, 0.0, 1.0) * PI))
		A.PARRY:
			return lerp_pose(POSES.guard, POSES.parry, sin(clampf(t / 0.35, 0.0, 1.0) * PI))
		A.DEAD:
			return POSES.dead
	return POSES.stand


## Articulações (no ecrã) de uma pose: anca, pescoço, cabeça, joelhos, pés, ombro, cotovelos, mãos.
func joints(feet: Vector2, facing: int, pose: Dictionary, lying := 0.0) -> Dictionary:
	var f := float(facing)
	var hip := Vector2(0, -(BONES.thigh + BONES.shin) + float(pose.hip))
	var dir := func(a: float) -> Vector2: return Vector2(sin(a) * f, cos(a))
	var neck: Vector2 = hip + Vector2(sin(float(pose.lean)) * f, -cos(float(pose.lean))) * BONES.torso
	var head := neck + Vector2(sin(float(pose.lean)) * f, -cos(float(pose.lean))) * 16.0
	var j := {"hip": hip, "neck": neck, "head": head}
	for s: String in ["f", "b"]:
		var a: float = pose["th_" + s]
		var knee: Vector2 = hip + (dir.call(a) as Vector2) * BONES.thigh
		var foot: Vector2 = knee + (dir.call(a - float(pose["sh_" + s])) as Vector2) * BONES.shin
		var sh := neck + Vector2(0, 6)
		var u: float = pose["ua_" + s]
		var elbow: Vector2 = sh + (dir.call(u) as Vector2) * BONES.upper
		var hand: Vector2 = elbow + (dir.call(u + float(pose["fa_" + s])) as Vector2) * BONES.fore
		j["knee_" + s] = knee
		j["foot_" + s] = foot
		j["sh_" + s] = sh
		j["elbow_" + s] = elbow
		j["hand_" + s] = hand
	# deitado (morto): roda tudo à volta dos pés
	var base := scr(feet)
	for k: String in j.keys():
		var v: Vector2 = j[k]
		if lying != 0.0:
			v = v.rotated(-lying * f)
		j[k] = base + v
	j["sword_dir"] = (j.hand_f - j.elbow_f).normalized().rotated(-0.25 * f)
	return j


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	if game == null or game.tiles.is_empty():
		return
	if _painted_room != game.room:
		rebake()
	_draw_back()
	draw_texture(vp.get_texture(), Vector2(0, OFF_Y))
	_draw_dynamic()
	for gd in game.guards:
		var gp: Vector2 = gd.pos
		if game.room_of(gp - Vector2(0, 40)) != game.room:
			continue
		var lying := clampf(float(gd.act_t) / 0.5, 0.0, 1.0) * PI / 2 if not gd.alive else 0.0
		_draw_figure(joints(gp, gd.facing, guard_pose(gd), lying), true, true, gd)
	if _hero_visible():
		var lying := 0.0
		if game.act == PalaceGame.Act.DEAD:
			lying = clampf(game.act_t / 0.5, 0.0, 1.0) * PI / 2
		var mod_a := 1.0 - clampf(game.act_t / 1.6, 0.0, 1.0) if game.act == PalaceGame.Act.EXIT else 1.0
		var show_sword := game.has_sword and game.act in [PalaceGame.Act.SWORD, PalaceGame.Act.STRIKE, PalaceGame.Act.PARRY]
		_draw_figure(joints(game.pos, game.facing, hero_pose(), lying), false, show_sword, {"alpha": mod_a})
	for d in game.debris:
		_draw_debris(scr(d.pos))
	_draw_front()
	for s in sparks:
		draw_rect(Rect2(s.pos - Vector2(3, 3), Vector2(6, 6)), Color(s.color, s.life / 0.3))
	_draw_hud()
	var st: Variant = game.touch_stick()
	if st != null:
		draw_arc(st, 60, 0, TAU, 32, Color(1, 1, 1, 0.3), 3.0)


func _hero_visible() -> bool:
	if game.state == PalaceGame.State.READY:
		return fmod(time, 0.3) < 0.2
	return game.state != PalaceGame.State.OVER


## Percorre as casas visíveis (do ecrã atual) chamando f(c, r, ch, rect).
func each_tile(room: Vector2i, f: Callable) -> void:
	for r in PalaceGame.ROOM_ROWS:
		for c in PalaceGame.ROOM_COLS:
			var gc := room.x * PalaceGame.ROOM_COLS + c
			var gr := room.y * PalaceGame.ROOM_ROWS + r
			f.call(gc, gr, game.tile(gc, gr), cell_rect(c, r))


## Objetos que mudam (portões, espinhos, porta, poções, espada) desenhados por cima do ecrã gravado.
func _draw_dynamic() -> void:
	var g := game
	each_tile(g.room, _dyn_tile)


func _dyn_tile(gc: int, gr: int, ch: String, rect: Rect2) -> void:
	var g := game
	var r := Rect2(rect.position + Vector2(0, OFF_Y), rect.size)
	var floor_y := r.end.y - 18.0
	match ch:
		"|":
			_draw_gate(r, floor_y, g.gate_h)
		"^":
			_draw_spikes(r, floor_y, float(g.spikes.get(Vector2i(gc, gr), 0.0)))
		"D":
			_draw_door(r, floor_y, g.exit_h)
		"h", "H":
			_draw_potion(Vector2(r.get_center().x, floor_y), ch == "H")
		"S":
			_draw_sword_item(Vector2(r.get_center().x, floor_y))
		"~":
			var shake := float(g.loose.get(Vector2i(gc, gr), -1.0))
			if shake >= 0.0:
				_draw_loose_shake(r, floor_y, shake)
		"o", "e":
			var on := (ch == "o" and g.gate_t > 0.0) or (ch == "e" and g.exit_open)
			_draw_plate(Rect2(r.position.x + 24, floor_y - 6, r.size.x - 48, 8), on)


# ---------------------------------------------------------------- para os estilos reescreverem

func _setup() -> void:
	pass


func _build_sfx() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _draw_back() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color.BLACK)


func _paint_room(_ci: CanvasItem, _room: Vector2i) -> void:
	pass


func _draw_figure(_j: Dictionary, _is_guard: bool, _sword: bool, _info: Dictionary) -> void:
	pass


func _draw_gate(_r: Rect2, _floor_y: float, _open: float) -> void:
	pass


func _draw_spikes(_r: Rect2, _floor_y: float, _out: float) -> void:
	pass


func _draw_door(_r: Rect2, _floor_y: float, _open: float) -> void:
	pass


func _draw_potion(_p: Vector2, _big: bool) -> void:
	pass


func _draw_sword_item(_p: Vector2) -> void:
	pass


func _draw_loose_shake(_r: Rect2, _floor_y: float, _t: float) -> void:
	pass


func _draw_plate(_r: Rect2, _on: bool) -> void:
	pass


func _draw_debris(_p: Vector2) -> void:
	pass


func _draw_front() -> void:
	pass


func _draw_hud() -> void:
	pass


func ui_palette() -> Dictionary:
	return UI.LAUNCHER_PALETTE
