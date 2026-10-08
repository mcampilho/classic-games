extends Node
## Chuckie Egg: menu (com demonstração ao fundo), avisos de nível, pausa, fim de jogo e troca de estilo.

signal exit_requested

const SKINS := [
	{"name": "Clássico 1983", "script": preload("res://games/chuckie/skins/classic_skin.gd")},
	{"name": "Neon", "script": preload("res://games/chuckie/skins/neon_skin.gd")},
	{"name": "Ponto de Cruz", "script": preload("res://games/chuckie/skins/stitch_skin.gd")},
]
const MODES := ["1 Jogador", "2 Jogadores (à vez)"]
const LIVES := [5, 3]

var style_idx := 1
var mode_idx := 0
var lives_idx := 0
var playing := false
var _prewarm_task := -1
var _msg := ""
var _msg_t := 0.0

var game: ChuckieGame
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
	style_idx = Settings.get_value("chuckie", "style", 1)
	mode_idx = Settings.get_value("chuckie", "mode", 0)
	lives_idx = Settings.get_value("chuckie", "lives", 0)

	game = ChuckieGame.new()
	game.best = Settings.get_value("chuckie", "best", 0)
	add_child(game)
	game.game_over.connect(_on_game_over)
	game.level_started.connect(func(_l: int) -> void: _say(I18n.t("NÍVEL %d  ·  %s") % [game.level(), game.level_name().to_upper()], 2.0))
	game.level_cleared.connect(func(bonus: int) -> void: _say(I18n.t("NÍVEL CONCLUÍDO!  BÓNUS %d") % bonus, 2.0))
	game.turn_started.connect(func(p: int) -> void:
		if game.mode == ChuckieGame.Mode.TWO:
			_say(I18n.t("JOGADOR %d  ·  NÍVEL %d") % [p + 1, game.level()], 2.0))
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
	prompt.position.y -= 150
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
		pause_btn.position = Vector2(1184 - 36, 640)   # no painel lateral direito, longe do campo
		hud.add_child(pause_btn)

	menu = UI.overlay(ui_root)
	var box: VBoxContainer = menu.box
	title_label = UI.label(I18n.t("GALINHEIRO"), 76)
	box.add_child(title_label)
	box.add_child(UI.label(I18n.t("plataformas e escadas, ao estilo de 1983"), 20))
	var mode_btn := CycleButton.new().setup(I18n.t("Modo"), MODES, mode_idx)
	mode_btn.value_changed.connect(func(i: int) -> void:
		mode_idx = i
		Settings.set_value("chuckie", "mode", i))
	box.add_child(mode_btn)
	var lives_btn := CycleButton.new().setup(I18n.t("Vidas"), LIVES.map(func(b: int) -> String: return str(b)), lives_idx)
	lives_btn.value_changed.connect(func(i: int) -> void:
		lives_idx = i
		Settings.set_value("chuckie", "lives", i))
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
	var hint := UI.label(I18n.t("Andar e subir escadas: setas / WASD / comando   ·   Saltar: Espaço, Z ou A\nTátil: arrastar na metade esquerda (andar/escadas), tocar na metade direita para saltar"), 15)
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
	Settings.set_value("chuckie", "style", style_idx)


func _say(text: String, secs: float) -> void:
	_msg = text
	_msg_t = secs


func _process(delta: float) -> void:
	_msg_t = maxf(_msg_t - delta, 0.0)
	if not playing or game.paused:
		prompt.text = ""
		return
	var txt := _msg if _msg_t > 0.0 else ""
	if txt == "" and game.state == ChuckieGame.State.PLAY and game.time_left < 100.0:
		txt = I18n.t("DEPRESSA!") if fmod(Time.get_ticks_msec() / 1000.0, 0.8) < 0.5 else ""
	prompt.text = txt


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
	game.start_demo()
	_show_screen(menu, play_button)


func _start_match() -> void:
	playing = true
	game.clear_input()
	game.start(ChuckieGame.Mode.ONE if mode_idx == 0 else ChuckieGame.Mode.TWO, LIVES[lives_idx])
	_show_screen({}, null)
	get_viewport().gui_release_focus()


func _set_paused(on: bool) -> void:
	if not playing or game.state == ChuckieGame.State.OVER:
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
		Settings.set_value("chuckie", "best", top)
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
