extends Node
## Asteroids: menu (com demonstração ao fundo), avisos de jogo, pausa, fim de jogo e troca de estilo.

signal exit_requested

const SKINS := [
	{"name": "Clássico 1979", "script": preload("res://games/asteroids/skins/classic_skin.gd")},
	{"name": "Neon", "script": preload("res://games/asteroids/skins/neon_skin.gd")},
	{"name": "Origami", "script": preload("res://games/asteroids/skins/origami_skin.gd")},
]
const MODES := ["1 Jogador", "2 Jogadores (à vez)"]
const LIVES := [3, 5]

var style_idx := 1
var mode_idx := 0
var lives_idx := 0
var playing := false
var _prewarm_task := -1
var _cleared_msg := 0.0

var game: AsteroidsGame
var ui: CanvasLayer
var ui_root: Control
var menu := {}
var pause_menu := {}
var over_menu := {}
var hud: Control
var touch_overlay: Control
var prompt: Label
var title_label: Label
var best_label: Label
var over_title: Label
var over_score: Label
var over_record: Label
var play_button: Button
var resume_button: Button
var again_button: Button


func _ready() -> void:
	style_idx = Settings.get_value("asteroids", "style", 1)
	mode_idx = Settings.get_value("asteroids", "mode", 0)
	lives_idx = Settings.get_value("asteroids", "lives", 0)

	game = AsteroidsGame.new()
	game.best = Settings.get_value("asteroids", "best", 0)
	add_child(game)
	game.game_over.connect(_on_game_over)
	game.wave_cleared.connect(func() -> void: _cleared_msg = 1.8)
	_build_ui()
	_apply_style()
	_show_menu()
	# Prepara já os sons dos outros estilos, em segundo plano.
	_prewarm_task = Synth.prewarm(SKINS.map(func(s: Dictionary) -> Script: return s.script))

	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--style="):
			style_idx = clampi(int(a.get_slice("=", 1)), 0, SKINS.size() - 1)
			_apply_style()
	if "--play" in args:
		_start_match()


# ---------------------------------------------------------------- interface

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(ui_root)

	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(hud)
	prompt = UI.label("", 30)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	prompt.position.y += 150
	prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	prompt.add_theme_constant_override("outline_size", 10)
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(prompt)
	if DisplayServer.is_touchscreen_available():
		var pause_btn := UI.button("II", _set_paused.bind(true))
		pause_btn.focus_mode = Control.FOCUS_NONE
		pause_btn.add_theme_font_size_override("font_size", 20)
		pause_btn.modulate.a = 0.6
		pause_btn.custom_minimum_size = Vector2(72, 60)
		pause_btn.position = Vector2(640 - 36, 120)
		hud.add_child(pause_btn)
		# joystick virtual e botões táteis
		touch_overlay = Control.new()
		touch_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		touch_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		touch_overlay.draw.connect(_draw_touch_overlay)
		hud.add_child(touch_overlay)

	menu = UI.overlay(ui_root)
	var box: VBoxContainer = menu.box
	title_label = UI.label(I18n.t("METEOROS"), 76)
	box.add_child(title_label)
	box.add_child(UI.label(I18n.t("tiro no espaço com inércia, ao estilo de 1979"), 20))
	var mode_btn := CycleButton.new().setup(I18n.t("Modo"), MODES, mode_idx)
	mode_btn.value_changed.connect(func(i: int) -> void:
		mode_idx = i
		Settings.set_value("asteroids", "mode", i))
	box.add_child(mode_btn)
	var lives_btn := CycleButton.new().setup(I18n.t("Vidas"), LIVES.map(func(b: int) -> String: return str(b)), lives_idx)
	lives_btn.value_changed.connect(func(i: int) -> void:
		lives_idx = i
		Settings.set_value("asteroids", "lives", i))
	box.add_child(lives_btn)
	var style_btn := CycleButton.new().setup(I18n.t("Estilo"), SKINS.map(func(s: Dictionary) -> String: return s.name), style_idx)
	style_btn.value_changed.connect(func(i: int) -> void:
		style_idx = i
		_apply_style())
	box.add_child(style_btn)
	play_button = UI.button(I18n.t("Jogar"), _start_match)
	box.add_child(play_button)
	box.add_child(UI.button(I18n.t("Voltar ao arcade"), func() -> void: exit_requested.emit()))
	best_label = UI.label("", 18)
	box.add_child(best_label)
	var hint := UI.label(I18n.t("Rodar ← →  ·  Acelerar ↑  ·  Disparar Espaço  ·  Hiperespaço ↓ / Shift\nRato: apontar, clique dispara, botão direito acelera  ·  Tátil: joystick à esquerda, disparo à direita"), 15)
	hint.modulate.a = 0.6
	box.add_child(hint)

	pause_menu = UI.overlay(ui_root, 420)
	pause_menu.box.add_child(UI.label(I18n.t("PAUSA"), 52))
	resume_button = UI.button(I18n.t("Continuar"), _set_paused.bind(false))
	pause_menu.box.add_child(resume_button)
	pause_menu.box.add_child(UI.button(I18n.t("Recomeçar"), _start_match))
	pause_menu.box.add_child(UI.button(I18n.t("Menu"), _show_menu))

	over_menu = UI.overlay(ui_root, 480)
	over_title = UI.label(I18n.t("FIM DE JOGO"), 48)
	over_menu.box.add_child(over_title)
	over_score = UI.label("", 28)
	over_menu.box.add_child(over_score)
	over_record = UI.label("", 24)
	over_menu.box.add_child(over_record)
	again_button = UI.button(I18n.t("Jogar de novo"), _start_match)
	over_menu.box.add_child(again_button)
	over_menu.box.add_child(UI.button(I18n.t("Menu"), _show_menu))


func _apply_style() -> void:
	game.set_skin(SKINS[style_idx].script.new())
	var pal := game.skin.ui_palette()
	ui_root.theme = UI.make_theme(pal)
	title_label.add_theme_color_override("font_color", pal.accent)
	over_record.add_theme_color_override("font_color", pal.accent)
	prompt.add_theme_color_override("font_outline_color", Color(pal.panel, 0.9))
	for o: Dictionary in [menu, pause_menu, over_menu]:
		o.dim.color = pal.dim
	Settings.set_value("asteroids", "style", style_idx)


func _process(delta: float) -> void:
	_cleared_msg = maxf(_cleared_msg - delta, 0.0)
	if not playing or game.paused:
		prompt.text = ""
		return
	var txt := ""
	if _cleared_msg > 0.0:
		txt = I18n.t("VAGA %d") % (game.player().wave + 1)
	elif game.ship_waiting() and game.mode == AsteroidsGame.Mode.TWO:
		txt = I18n.t("JOGADOR %d") % (game.current + 1)
	if touch_overlay:
		touch_overlay.queue_redraw()
	prompt.text = txt


# ---------------------------------------------------------------- fluxo

func _show_screen(which: Dictionary, focus: Button) -> void:
	for o: Dictionary in [menu, pause_menu, over_menu]:
		o.root.visible = o == which
	hud.visible = which.is_empty()
	# Durante o jogo o cursor passa a mira (o rato pode apontar a nave).
	Input.set_default_cursor_shape(Input.CURSOR_CROSS if which.is_empty() else Input.CURSOR_ARROW)
	if focus:
		focus.grab_focus()


func _show_menu() -> void:
	playing = false
	best_label.text = I18n.t("Recorde: %d") % game.best if game.best > 0 else ""
	game.start(AsteroidsGame.Mode.DEMO, 3)
	_show_screen(menu, play_button)


func _start_match() -> void:
	playing = true
	game.start(AsteroidsGame.Mode.ONE if mode_idx == 0 else AsteroidsGame.Mode.TWO, LIVES[lives_idx])
	_show_screen({}, null)
	get_viewport().gui_release_focus()


func _set_paused(on: bool) -> void:
	if not playing or game.state == AsteroidsGame.State.OVER:
		return
	game.paused = on
	game.clear_input()
	if on:
		_show_screen(pause_menu, resume_button)
	else:
		_show_screen({}, null)
		get_viewport().gui_release_focus()


func _on_game_over() -> void:
	if not playing:
		return
	var top := 0
	if game.players.size() == 1:
		top = game.players[0].score
		over_score.text = I18n.t("%d pontos") % top
	else:
		var a: int = game.players[0].score
		var b: int = game.players[1].score
		top = maxi(a, b)
		over_score.text = I18n.t("Jogador 1: %d   ·   Jogador 2: %d") % [a, b]
		over_title.text = I18n.t("EMPATE!") if a == b else I18n.t("JOGADOR %d VENCE!") % (1 if a > b else 2)
	if game.players.size() == 1:
		over_title.text = I18n.t("FIM DE JOGO")
	if top > game.best:
		game.best = top
		Settings.set_value("asteroids", "best", top)
		over_record.text = I18n.t("Novo recorde!")
	else:
		over_record.text = I18n.t("Recorde: %d") % game.best
	_show_screen(over_menu, again_button)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if menu.root.visible:
			exit_requested.emit()
		elif over_menu.root.visible:
			_show_menu()
		else:
			_set_paused(not game.paused)


func _notification(what: int) -> void:
	# Se a janela perde o foco a meio do jogo, pausa.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and playing and not game.paused:
		_set_paused(true)


## Botão "voltar" do Android.
func go_back() -> void:
	if menu.root.visible:
		exit_requested.emit()
	elif pause_menu.root.visible or over_menu.root.visible:
		_show_menu()
	else:
		_set_paused(true)


func _exit_tree() -> void:
	if _prewarm_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_prewarm_task)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


## Joystick virtual (metade esquerda) e botão de hiperespaço, só em ecrãs táteis.
func _draw_touch_overlay() -> void:
	if not playing or game.paused:
		return
	var c := Color(1, 1, 1, 0.5)
	if game.touch_stick_origin != null:
		var o: Vector2 = game.touch_stick_origin
		touch_overlay.draw_circle(o, 90.0, Color(1, 1, 1, 0.08), true, -1.0, true)
		touch_overlay.draw_arc(o, 90.0, 0, TAU, 48, Color(1, 1, 1, 0.3), 2.0, true)
		touch_overlay.draw_circle(o + game.touch_stick_vec, 32.0, Color(1, 1, 1, 0.3), true, -1.0, true)
	else:
		touch_overlay.draw_arc(Vector2(170, 560), 90.0, 0, TAU, 48, Color(1, 1, 1, 0.12), 2.0, true)
	var h := AsteroidsGame.HYPER_BUTTON
	touch_overlay.draw_circle(h, AsteroidsGame.HYPER_BUTTON_R, Color(1, 1, 1, 0.08), true, -1.0, true)
	touch_overlay.draw_arc(h, AsteroidsGame.HYPER_BUTTON_R, 0, TAU, 48, Color(1, 1, 1, 0.3), 2.0, true)
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(I18n.t("HIPER"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	touch_overlay.draw_string(font, h + Vector2(-w / 2, 6), I18n.t("HIPER"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, c)
	if game.touch_firing:
		touch_overlay.draw_circle(Vector2(980, 560), 70.0, Color(1, 1, 1, 0.1), true, -1.0, true)
