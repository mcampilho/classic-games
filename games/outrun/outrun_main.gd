extends Node
## OutRun: menu (com demonstração ao fundo), contagem de partida, avisos de etapa, pausa,
## fim de corrida, rádio e troca de estilo.

signal exit_requested

const SKINS := [
	{"name": "Clássico 1986", "script": preload("res://games/outrun/skins/classic_skin.gd")},
	{"name": "Synthwave", "script": preload("res://games/outrun/skins/synthwave_skin.gd")},
	{"name": "Cartaz de Viagem", "script": preload("res://games/outrun/skins/poster_skin.gd")},
]
const GEARS := ["Automática", "Manual (Espaço)"]

var style_idx := 0
var gear_idx := 0
var radio_idx := 0
var playing := false
var _prewarm_task := -1
var _music_task := -1
var _msg := ""
var _msg_t := 0.0

var game: OutRunGame
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
	style_idx = Settings.get_value("outrun", "style", 0)
	gear_idx = Settings.get_value("outrun", "gears", 0)
	radio_idx = Settings.get_value("outrun", "radio", 0)

	game = OutRunGame.new()
	game.best = Settings.get_value("outrun", "best", 0)
	add_child(game)
	game.game_over.connect(_on_game_over)
	game.countdown.connect(_on_countdown)
	game.checkpoint.connect(func(_s: int, _bonus: float) -> void: _say(I18n.t("ETAPA %d  ·  %s") % [game.stage + 1, OutRunGame.THEME_NAMES[game.theme].to_upper()], 2.5))
	game.goal.connect(func(bonus: int) -> void: _say(I18n.t("META!  BÓNUS DE TEMPO %d") % bonus, 5.0))
	game.time_up.connect(func() -> void: _say(I18n.t("TEMPO ESGOTADO"), 3.0))
	_build_ui()
	_apply_style()
	_show_menu()
	# Sons dos outros estilos e músicas do rádio: gerados já, em segundo plano.
	_prewarm_task = Synth.prewarm(SKINS.map(func(s: Dictionary) -> Script: return s.script))
	_music_task = OutRunMusic.prewarm()

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
	prompt = UI.label("", 34)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	prompt.position.y -= 120
	prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	prompt.add_theme_constant_override("outline_size", 12)
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(prompt)
	if DisplayServer.is_touchscreen_available():
		var pause_btn := UI.button("II", _set_paused.bind(true))
		pause_btn.focus_mode = Control.FOCUS_NONE
		pause_btn.add_theme_font_size_override("font_size", 20)
		pause_btn.modulate.a = 0.6
		pause_btn.custom_minimum_size = Vector2(72, 60)
		pause_btn.position = Vector2(1180, 620)
		hud.add_child(pause_btn)

	menu = UI.overlay(ui_root)
	var box: VBoxContainer = menu.box
	title_label = UI.label(I18n.t("ESTRADA DO SOL"), 70)
	box.add_child(title_label)
	box.add_child(UI.label(I18n.t("corrida na estrada, ao estilo de 1986"), 20))
	var gear_btn := CycleButton.new().setup(I18n.t("Caixa"), GEARS, gear_idx)
	gear_btn.value_changed.connect(func(i: int) -> void:
		gear_idx = i
		Settings.set_value("outrun", "gears", i))
	box.add_child(gear_btn)
	var radios: Array = OutRunMusic.NAMES.duplicate()
	radios.append(I18n.t("Desligado"))
	var radio_btn := CycleButton.new().setup(I18n.t("Rádio"), radios, radio_idx)
	radio_btn.value_changed.connect(func(i: int) -> void:
		radio_idx = i
		Settings.set_value("outrun", "radio", i)
		game.skin.set_radio(_radio()))
	box.add_child(radio_btn)
	var style_btn := CycleButton.new().setup(I18n.t("Estilo"), SKINS.map(func(s: Dictionary) -> String: return s.name), style_idx)
	style_btn.value_changed.connect(func(i: int) -> void:
		style_idx = i
		_apply_style())
	box.add_child(style_btn)
	play_button = UI.button(I18n.t("Conduzir"), _start_match)
	box.add_child(play_button)
	box.add_child(UI.button(I18n.t("Voltar ao arcade"), func() -> void: exit_requested.emit()))
	best_label = UI.label("", 18)
	box.add_child(best_label)
	var hint := UI.label(I18n.t("Virar: setas / A D / rato / comando   ·   Acelerar: ↑ W ou clique   ·   Travar: ↓ S ou botão direito\nTátil: arrastar o dedo para os lados vira · 1 dedo acelera · 2 dedos travam   ·   Na bifurcação, escolhe o lado"), 15)
	hint.modulate.a = 0.6
	box.add_child(hint)

	pause_menu = UI.overlay(ui_root, 420)
	pause_menu.box.add_child(UI.label(I18n.t("PAUSA"), 52))
	resume_button = UI.button(I18n.t("Continuar"), _set_paused.bind(false))
	pause_menu.box.add_child(resume_button)
	pause_menu.box.add_child(UI.button(I18n.t("Recomeçar"), _start_match))
	pause_menu.box.add_child(UI.button(I18n.t("Menu"), _show_menu))

	over_menu = UI.overlay(ui_root, 520)
	over_title = UI.label(I18n.t("FIM DA VIAGEM"), 48)
	over_menu.box.add_child(over_title)
	over_score = UI.label("", 26)
	over_menu.box.add_child(over_score)
	over_record = UI.label("", 24)
	over_menu.box.add_child(over_record)
	again_button = UI.button(I18n.t("Conduzir de novo"), _start_match)
	over_menu.box.add_child(again_button)
	over_menu.box.add_child(UI.button(I18n.t("Menu"), _show_menu))


func _radio() -> int:
	return radio_idx if radio_idx < OutRunMusic.NAMES.size() else -1


func _apply_style() -> void:
	game.set_skin(SKINS[style_idx].script.new())
	game.skin.set_radio(_radio())
	var pal := game.skin.ui_palette()
	ui_root.theme = UI.make_theme(pal)
	title_label.add_theme_color_override("font_color", pal.accent)
	over_record.add_theme_color_override("font_color", pal.accent)
	prompt.add_theme_color_override("font_color", pal.accent)
	prompt.add_theme_color_override("font_outline_color", Color(pal.panel, 0.95))
	for o: Dictionary in [menu, pause_menu, over_menu]:
		o.dim.color = pal.dim
	Settings.set_value("outrun", "style", style_idx)


func _say(text: String, secs: float) -> void:
	_msg = text
	_msg_t = secs


func _on_countdown(n: int) -> void:
	if game.mode == OutRunGame.Mode.DEMO:
		return
	_say(str(n) if n > 0 else I18n.t("PARTIDA!"), 0.9 if n > 0 else 1.2)


func _process(delta: float) -> void:
	_msg_t = maxf(_msg_t - delta, 0.0)
	if not playing or game.paused:
		prompt.text = ""
		return
	var txt := _msg if _msg_t > 0.0 else ""
	if txt == "" and game.state == OutRunGame.State.PLAY and game.stage < OutRunGame.STAGES - 1:
		var i: int = game.player_segment().index
		if i > game.fork_start - 70 and i < game.fork_start + 40:
			txt = I18n.t("<  ESCOLHE O CAMINHO  >")
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
	game.manual_gears = false
	game.start(OutRunGame.Mode.DEMO)
	_show_screen(menu, play_button)


func _start_match() -> void:
	playing = true
	_msg_t = 0.0
	game.manual_gears = gear_idx == 1
	game.clear_input()
	game.start(OutRunGame.Mode.PLAY)
	_show_screen({}, null)
	get_viewport().gui_release_focus()


func _set_paused(on: bool) -> void:
	if not playing or game.state == OutRunGame.State.OVER:
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
	var reached := game.state == OutRunGame.State.OVER and game.stage >= OutRunGame.STAGES - 1 and game.time_left > 0.0
	over_title.text = I18n.t("CHEGASTE À META!") if reached else I18n.t("FIM DA VIAGEM")
	var path := []
	for s in game.route.size():
		path.append(I18n.t(OutRunGame.THEME_NAMES[OutRunGame.theme_for(s, game.route[s])]))
	over_score.text = I18n.t("%d pontos\n%s") % [game.score, " → ".join(path)]
	if game.score > game.best:
		game.best = game.score
		Settings.set_value("outrun", "best", game.score)
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
	for t in [_prewarm_task, _music_task]:
		if t >= 0:
			WorkerThreadPool.wait_for_task_completion(t)
