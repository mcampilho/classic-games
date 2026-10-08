extends Node
## Rebanho: menu (com demonstração ao fundo), avisos, pausa, fim de jogo e troca de estilo.

signal exit_requested

const SKINS := [
	{"name": "Clássico 1991", "script": preload("res://games/flock/skins/classic_skin.gd")},
	{"name": "Plasticina", "script": preload("res://games/flock/skins/clay_skin.gd")},
	{"name": "Bloco de Notas", "script": preload("res://games/flock/skins/notebook_skin.gd")},
]
const SPEEDS := ["Normal", "Rápida"]

var style_idx := 0
var speed_idx := 0
var playing := false
var _prewarm_task := -1
var _msg := ""
var _msg_t := 0.0

var game: FlockGame
var ui: CanvasLayer
var ui_root: Control
var menu := {}
var pause_menu := {}
var over_menu := {}
var hud: Control
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
	style_idx = Settings.get_value("flock", "style", 0)
	speed_idx = Settings.get_value("flock", "speed", 0)

	game = FlockGame.new()
	game.best = Settings.get_value("flock", "best", 0)
	add_child(game)
	game.game_over.connect(_on_game_over)
	game.won.connect(func() -> void: get_tree().create_timer(4.0).timeout.connect(_on_game_over))
	game.level_started.connect(func(l: int) -> void:
		_say(I18n.t("NÍVEL %d: %s\nSALVA %d DE %d OVELHAS") % [l + 1, I18n.t(String(game.data().name)).to_upper(), int(game.data().need), int(game.data().count)], 3.0))
	game.level_ended.connect(_on_level_ended)
	game.won.connect(func() -> void: _say(I18n.t("O REBANHO ESTÁ TODO EM CASA!"), 6.0))
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


func _on_level_ended(ok: bool) -> void:
	if not playing:
		return
	if game.state == FlockGame.State.WON:
		return
	if ok:
		_say(I18n.t("MUITO BEM! %d OVELHAS SALVAS") % game.saved_n, 2.6)
	else:
		_say(I18n.t("SÓ %d DE %d... TENTA OUTRA VEZ") % [game.saved_n, int(game.data().need)], 2.6)
	get_tree().create_timer(2.8).timeout.connect(func() -> void:
		if playing and game.state == FlockGame.State.END:
			game.continue_after_end())


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
	prompt.position.y -= 240
	prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	prompt.add_theme_constant_override("outline_size", 10)
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(prompt)
	if DisplayServer.is_touchscreen_available():
		var pause_btn := UI.button("II", _set_paused.bind(true))
		pause_btn.focus_mode = Control.FOCUS_NONE
		pause_btn.add_theme_font_size_override("font_size", 20)
		pause_btn.modulate.a = 0.6
		pause_btn.custom_minimum_size = Vector2(68, 48)
		pause_btn.position = Vector2(1204, 34)
		hud.add_child(pause_btn)

	menu = UI.overlay(ui_root)
	var box: VBoxContainer = menu.box
	title_label = UI.label(I18n.t("REBANHO"), 70)
	box.add_child(title_label)
	box.add_child(UI.label(I18n.t("puzzle ao estilo de 1991: leva as ovelhas até ao celeiro"), 20))
	var speed_btn := CycleButton.new().setup(I18n.t("Velocidade inicial"), SPEEDS, speed_idx)
	speed_btn.value_changed.connect(func(i: int) -> void:
		speed_idx = i
		Settings.set_value("flock", "speed", i))
	box.add_child(speed_btn)
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
	var hint := UI.label(I18n.t("Escolhe uma função no painel (teclas 1-7 ou Q/E) e clica/toca numa ovelha para a atribuir\nCursor também com setas/WASD e Espaço   ·   F: rapidez   ·   R: recomeçar o nível   ·   Esc: pausa"), 15)
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
	Settings.set_value("flock", "style", style_idx)


func _say(text: String, secs: float) -> void:
	_msg = text
	_msg_t = secs


func _process(delta: float) -> void:
	_msg_t = maxf(_msg_t - delta, 0.0)
	if not playing or game.paused:
		prompt.text = ""
		return
	prompt.text = _msg if _msg_t > 0.0 else ""


# ---------------------------------------------------------------- fluxo

func _show_screen(which: Dictionary, focus: Button) -> void:
	for o: Dictionary in [menu, pause_menu, over_menu]:
		o.root.visible = o == which
	hud.visible = which.is_empty()
	if focus:
		focus.grab_focus()


func _show_menu() -> void:
	playing = false
	best_label.text = I18n.t("Recorde: %d") % game.best if game.best > 0 else ""
	game.start(FlockGame.Mode.DEMO)
	_show_screen(menu, play_button)


func _start_match() -> void:
	playing = true
	game.start(FlockGame.Mode.PLAY)
	game.fast = speed_idx == 1
	_show_screen({}, null)
	get_viewport().gui_release_focus()


func _set_paused(on: bool) -> void:
	if not playing or game.state == FlockGame.State.WON:
		return
	game.paused = on
	if on:
		_show_screen(pause_menu, resume_button)
	else:
		_show_screen({}, null)
		get_viewport().gui_release_focus()


func _on_game_over() -> void:
	if not playing:
		return
	over_title.text = I18n.t("REBANHO SALVO!")
	over_score.text = I18n.t("%d pontos  ·  %d níveis") % [game.score, FlockGame.LEVELS.size()]
	if game.score > Settings.get_value("flock", "best", 0):
		Settings.set_value("flock", "best", game.score)
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
			_set_paused(not pause_menu.root.visible)


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
