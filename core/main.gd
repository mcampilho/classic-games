extends Node
## Ecrã inicial do Arcade Clássico: lista de jogos.
## Cada jogo é um Node com o sinal `exit_requested` e o método `go_back()`.

const GAMES := [
	{"title": "Pong", "year": "1972", "script": "res://games/pong/pong_main.gd"},
	{"title": "Breakout", "year": "1976", "script": ""},
	{"title": "Space Invaders", "year": "1978", "script": ""},
	{"title": "Asteroids", "year": "1979", "script": ""},
]

var ui: CanvasLayer
var root: Control
var first_button: Button
var current: Node


func _ready() -> void:
	_build_ui()
	var args := OS.get_cmdline_user_args()
	if "--pong" in args:  # atalho para desenvolvimento: abre diretamente o Pong
		_open(GAMES[0])


func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UI.make_theme(UI.LAUNCHER_PALETTE)
	ui.add_child(root)

	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.04, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.custom_minimum_size.x = 520
	center.add_child(box)

	box.add_child(UI.label("ARCADE CLÁSSICO", 64, UI.LAUNCHER_PALETTE.accent))
	box.add_child(UI.label("os clássicos, modernizados", 22, Color(1, 1, 1, 0.55)))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 18
	box.add_child(spacer)

	for g: Dictionary in GAMES:
		var available: bool = g.script != ""
		var txt := "%s  ·  %s" % [g.title, g.year]
		if not available:
			txt += "   (em breve)"
		var b := UI.button(txt, _open.bind(g))
		b.disabled = not available
		box.add_child(b)
		if available and first_button == null:
			first_button = b

	if OS.get_name() != "Web":
		var quit := UI.button("Sair", get_tree().quit)
		box.add_child(quit)
	box.add_child(UI.label("F11: ecrã inteiro", 16, Color(1, 1, 1, 0.35)))
	first_button.call_deferred("grab_focus")


func _open(g: Dictionary) -> void:
	root.hide()
	current = load(g.script).new()
	add_child(current)
	current.exit_requested.connect(_close_game)


func _close_game() -> void:
	if current:
		current.queue_free()
		current = null
	root.show()
	first_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		var w := get_window()
		w.mode = Window.MODE_WINDOWED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN


func _notification(what: int) -> void:
	# Botão "voltar" do Android
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if current:
			current.go_back()
		else:
			get_tree().quit()
