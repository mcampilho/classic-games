extends Node
## Pong: menu (com demonstração ao fundo), pausa, fim de jogo e troca de estilo em tempo real.

signal exit_requested

const SKINS := [
	{"name": "Clássico 1972", "script": preload("res://games/pong/skins/classic_skin.gd")},
	{"name": "Neon", "script": preload("res://games/pong/skins/neon_skin.gd")},
	{"name": "Papel & Tinta", "script": preload("res://games/pong/skins/paper_skin.gd")},
]
const MODES := ["1 Jogador vs CPU", "2 Jogadores"]
const DIFFS := ["Fácil", "Normal", "Difícil"]

var style_idx := 1
var mode_idx := 0
var diff_idx := 1
var playing := false

var game: PongGame
var ui: CanvasLayer
var ui_root: Control
var menu := {}
var pause_menu := {}
var over_menu := {}
var hud: Control
var title_label: Label
var over_title: Label
var over_score: Label
var diff_button: CycleButton
var play_button: Button
var resume_button: Button
var again_button: Button


func _ready() -> void:
	style_idx = Settings.get_value("pong", "style", 1)
	mode_idx = Settings.get_value("pong", "mode", 0)
	diff_idx = Settings.get_value("pong", "difficulty", 1)

	game = PongGame.new()
	add_child(game)
	game.game_over.connect(_on_game_over)
	_build_ui()
	_apply_style()
	_show_menu()

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

	# HUD: botão de pausa (útil no ecrã tátil)
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(hud)
	var pause_btn := UI.button("II", _set_paused.bind(true))
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.add_theme_font_size_override("font_size", 20)
	pause_btn.modulate.a = 0.6
	hud.add_child(pause_btn)
	pause_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 14)

	# Menu principal
	menu = UI.overlay(ui_root)
	var box: VBoxContainer = menu.box
	title_label = UI.label("PONG", 84)
	box.add_child(title_label)
	box.add_child(UI.label("1972  ·  versão modernizada", 20))
	var mode_btn := CycleButton.new().setup("Modo", MODES, mode_idx)
	mode_btn.value_changed.connect(_on_mode_changed)
	box.add_child(mode_btn)
	diff_button = CycleButton.new().setup("CPU", DIFFS, diff_idx)
	diff_button.value_changed.connect(func(i: int) -> void:
		diff_idx = i
		Settings.set_value("pong", "difficulty", i))
	box.add_child(diff_button)
	var style_btn := CycleButton.new().setup("Estilo", SKINS.map(func(s: Dictionary) -> String: return s.name), style_idx)
	style_btn.value_changed.connect(func(i: int) -> void:
		style_idx = i
		_apply_style())
	box.add_child(style_btn)
	play_button = UI.button("Jogar", _start_match)
	box.add_child(play_button)
	box.add_child(UI.button("Voltar ao arcade", func() -> void: exit_requested.emit()))
	var hint := UI.label("J1: W / S    J2: setas    Ecrã tátil: arrastar    Pausa: Esc", 16)
	hint.modulate.a = 0.6
	box.add_child(hint)
	diff_button.visible = mode_idx == 0

	# Pausa
	pause_menu = UI.overlay(ui_root, 420)
	pause_menu.box.add_child(UI.label("PAUSA", 52))
	resume_button = UI.button("Continuar", _set_paused.bind(false))
	pause_menu.box.add_child(resume_button)
	pause_menu.box.add_child(UI.button("Recomeçar", _start_match))
	pause_menu.box.add_child(UI.button("Menu", _show_menu))

	# Fim do jogo
	over_menu = UI.overlay(ui_root, 460)
	over_title = UI.label("", 48)
	over_menu.box.add_child(over_title)
	over_score = UI.label("", 30)
	over_menu.box.add_child(over_score)
	again_button = UI.button("Jogar de novo", _start_match)
	over_menu.box.add_child(again_button)
	over_menu.box.add_child(UI.button("Menu", _show_menu))


func _apply_style() -> void:
	game.set_skin(SKINS[style_idx].script.new())
	var pal := game.skin.ui_palette()
	ui_root.theme = UI.make_theme(pal)
	title_label.add_theme_color_override("font_color", pal.accent)
	for o: Dictionary in [menu, pause_menu, over_menu]:
		o.dim.color = pal.dim
	Settings.set_value("pong", "style", style_idx)


func _on_mode_changed(i: int) -> void:
	mode_idx = i
	diff_button.visible = i == 0
	Settings.set_value("pong", "mode", i)


# ---------------------------------------------------------------- fluxo

func _show_screen(which: Dictionary, focus: Button) -> void:
	for o: Dictionary in [menu, pause_menu, over_menu]:
		o.root.visible = o == which
	# o botão de pausa só aparece em ecrãs táteis (no PC usa-se Esc / P / Start)
	hud.visible = which.is_empty() and DisplayServer.is_touchscreen_available()
	if focus:
		focus.grab_focus()


func _show_menu() -> void:
	playing = false
	game.start(PongGame.Mode.DEMO)
	_show_screen(menu, play_button)


func _start_match() -> void:
	playing = true
	game.difficulty = diff_idx
	game.start(PongGame.Mode.VS_CPU if mode_idx == 0 else PongGame.Mode.VS_HUMAN)
	_show_screen({}, null)
	get_viewport().gui_release_focus()


func _set_paused(on: bool) -> void:
	if not playing or game.state == PongGame.State.OVER:
		return
	game.paused = on
	game.clear_touches()
	if on:
		_show_screen(pause_menu, resume_button)
	else:
		_show_screen({}, null)
		get_viewport().gui_release_focus()


func _on_game_over(winner: int) -> void:
	if not playing:
		return
	if game.mode == PongGame.Mode.VS_CPU:
		over_title.text = "VITÓRIA!" if winner == 0 else "A CPU GANHOU"
	else:
		over_title.text = "JOGADOR %d VENCE!" % (winner + 1)
	over_score.text = "%d  –  %d" % [game.scores[0], game.scores[1]]
	_show_screen(over_menu, again_button)


## Esc / P / Start do comando.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if menu.root.visible:
			exit_requested.emit()
		elif over_menu.root.visible:
			_show_menu()
		else:
			_set_paused(not game.paused)


## Botão "voltar" do Android.
func go_back() -> void:
	if menu.root.visible:
		exit_requested.emit()
	elif pause_menu.root.visible or over_menu.root.visible:
		_show_menu()
	else:
		_set_paused(true)
