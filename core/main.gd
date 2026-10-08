extends Node
## Ecrã inicial do Arcade Clássico: lista de jogos.
## Cada jogo é um Node com o sinal `exit_requested` e o método `go_back()`.

const GAMES := [
	{"title": "Raquetes", "year": "1972", "arg": "pong", "script": "res://games/pong/pong_main.gd"},
	{"title": "Quebra-Tijolos", "year": "1976", "arg": "breakout", "script": "res://games/breakout/breakout_main.gd"},
	{"title": "Ataque Alienígena", "year": "1978", "arg": "invaders", "script": "res://games/invaders/invaders_main.gd"},
	{"title": "Meteoros", "year": "1979", "arg": "asteroids", "script": "res://games/asteroids/asteroids_main.gd"},
	{"title": "Enxame", "year": "1979", "arg": "galaxian", "script": "res://games/galaxian/galaxian_main.gd"},
	{"title": "Pirilampo", "year": "1980", "arg": "firefly", "script": "res://games/firefly/firefly_main.gd"},
	{"title": "Travessia", "year": "1981", "arg": "frogger", "script": "res://games/frogger/frogger_main.gd"},
	{"title": "Cogumelos", "year": "1981", "arg": "centipede", "script": "res://games/centipede/centipede_main.gd"},
	{"title": "Incursão", "year": "1982", "arg": "penetrator", "script": "res://games/penetrator/penetrator_main.gd"},
	{"title": "Galinheiro", "year": "1983", "arg": "chuckie", "script": "res://games/chuckie/chuckie_main.gd"},
	{"title": "Astronauta a Jato", "year": "1983", "arg": "jetpac", "script": "res://games/jetpac/jetpac_main.gd"},
	{"title": "Torre das Relíquias", "year": "1984", "arg": "relics", "script": "res://games/relics/relics_main.gd"},
	{"title": "Encaixe", "year": "1984", "arg": "blocks", "script": "res://games/blocks/blocks_main.gd"},
	{"title": "Sarilhos na Escola", "year": "1985", "arg": "school", "script": "res://games/school/school_main.gd"},
	{"title": "Estrada do Sol", "year": "1986", "arg": "outrun", "script": "res://games/outrun/outrun_main.gd"},
	{"title": "Espada do Vale", "year": "1986", "arg": "vale", "script": "res://games/vale/vale_main.gd"},
	{"title": "Fuga do Palácio", "year": "1989", "arg": "palace", "script": "res://games/palace/palace_main.gd"},
	{"title": "Rebanho", "year": "1991", "arg": "flock", "script": "res://games/flock/flock_main.gd"},
]

var ui: CanvasLayer
var root: Control
var first_button: Button
var current: Node
# rodapé "inspirado em"
var info_title: Label
var info_story: Label
var info_wiki: Button
var _info_game := {}
var _buttons := {}                     # arg -> botão do jogo
var _last_button: Button
var _touch := false


func _ready() -> void:
	var lang: String = Settings.get_value("general", "lang", "")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lang="):
			lang = a.get_slice("=", 1)
	I18n.setup(lang if lang != "" else I18n.system_lang())
	_build_ui()
	var args := OS.get_cmdline_user_args()
	# atalhos para desenvolvimento: abrir diretamente um jogo
	for g: Dictionary in GAMES:
		if "--" + String(g.arg) in args:
			_open(g)
			break


func _build_ui() -> void:
	_touch = DisplayServer.is_touchscreen_available() and not "--mouse" in OS.get_cmdline_user_args()
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
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size.x = 1212
	center.add_child(box)

	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 22)
	head.add_child(UI.label(I18n.t("ARCADE CLÁSSICO"), 46, UI.LAUNCHER_PALETTE.accent))
	var sub := UI.label(I18n.t("os clássicos, modernizados"), 20, Color(1, 1, 1, 0.55))
	sub.size_flags_vertical = Control.SIZE_SHRINK_END
	head.add_child(sub)
	box.add_child(head)

	# os jogos numa grelha de 3 colunas
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	for g: Dictionary in GAMES:
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 4)
		var b := UI.button("%s  ·  %s" % [I18n.t(g.title), g.year], _open.bind(g))
		b.custom_minimum_size = Vector2(344 if _touch else 396, 46)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 19)
		cell.add_child(b)
		# no ecrã tátil, tocar no jogo abre-o logo: o "i" mostra a informação
		if _touch:
			var i := UI.button("i", func() -> void: _show_info(g))
			i.custom_minimum_size = Vector2(48, 46)
			i.focus_mode = Control.FOCUS_NONE
			i.add_theme_font_size_override("font_size", 19)
			cell.add_child(i)
		grid.add_child(cell)
		_buttons[g.arg] = b
		b.focus_entered.connect(_show_info.bind(g))
		# o rato dá o foco ao botão: só um botão fica realçado de cada vez
		b.mouse_entered.connect(func() -> void:
			if b.has_focus():
				_show_info(g)
			else:
				b.grab_focus())
		if first_button == null:
			first_button = b

	box.add_child(_build_info())

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 16)
	box.add_child(bottom)
	var hint := UI.label(I18n.t("F11: ecrã inteiro"), 16, Color(1, 1, 1, 0.35))
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if OS.get_name() != "Web":
		var quit := UI.button(I18n.t("Sair"), get_tree().quit)
		quit.custom_minimum_size = Vector2(220, 44)
		quit.mouse_entered.connect(func() -> void: quit.grab_focus())
		bottom.add_child(quit)
	bottom.add_child(hint)
	var lang_btn := CycleButton.new().setup("Idioma / Language", I18n.LANG_NAMES, I18n.LANGS.find(I18n.lang))
	lang_btn.custom_minimum_size = Vector2(400, 44)
	lang_btn.mouse_entered.connect(func() -> void: lang_btn.grab_focus())
	lang_btn.value_changed.connect(_set_lang)
	bottom.add_child(lang_btn)
	first_button.call_deferred("grab_focus")


# ---------------------------------------------------------------- rodapé "inspirado em"

func _build_info() -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.11)
	sb.border_color = Color(UI.LAUNCHER_PALETTE.accent, 0.5)
	sb.border_width_top = 2
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size.y = 150
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	info_title = UI.label("", 20, UI.LAUNCHER_PALETTE.accent)
	info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info_title)
	info_wiki = UI.button("", func() -> void:
		if not _info_game.is_empty():
			OS.shell_open(_wiki_url(Inspirations.INFO[_info_game.arg])))
	info_wiki.add_theme_font_size_override("font_size", 15)
	info_wiki.custom_minimum_size.y = 34
	info_wiki.visible = false
	info_wiki.mouse_entered.connect(func() -> void: info_wiki.grab_focus())
	row.add_child(info_wiki)
	info_story = UI.label("", 16, Color(1, 1, 1, 0.82))
	info_story.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_story.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_story.custom_minimum_size.x = 1170
	v.add_child(info_story)
	info_title.text = I18n.t("Os clássicos que inspiraram estes jogos")
	info_story.text = (I18n.t("Toca no botão i ao lado de um jogo") if _touch else I18n.t("Passa o rato ou o foco por um jogo")) + I18n.t(" para veres o clássico em que foi inspirado, uma breve história e a ligação para a Wikipédia.")
	return panel


func _show_info(g: Dictionary) -> void:
	var info: Dictionary = Inspirations.INFO.get(g.arg, {})
	if info.is_empty() or g == _info_game:
		return
	_info_game = g
	info_title.text = I18n.t("%s  —  inspirado em %s (%s)") % [I18n.t(g.title), info.name, info.by]
	info_story.text = I18n.t(info.story)
	var other := not _wiki_url(info).contains(I18n.lang + ".wikipedia")
	info_wiki.text = I18n.t("Wikipédia (em inglês) ↗") if other else I18n.t("Wikipédia ↗")
	info_wiki.visible = true


## Página da Wikipédia no idioma escolhido (ou em inglês, quando não existe).
func _wiki_url(info: Dictionary) -> String:
	if I18n.lang == "pt":
		return info.wiki
	return info.get("wiki_" + I18n.lang, info.wiki)


func _set_lang(i: int) -> void:
	I18n.setup(I18n.LANGS[i])
	Settings.set_value("general", "lang", I18n.lang)
	# reconstrói o ecrã inicial no novo idioma, mantendo o foco no seletor
	ui.queue_free()
	_buttons.clear()
	first_button = null
	_info_game = {}
	_build_ui()
	await get_tree().process_frame
	for c in root.find_children("*", "CycleButton", true, false):
		(c as Control).grab_focus()


func _open(g: Dictionary) -> void:
	_last_button = _buttons.get(g.arg)
	root.hide()
	current = load(g.script).new()
	add_child(current)
	current.exit_requested.connect(_close_game)


func _close_game() -> void:
	if current:
		current.queue_free()
		current = null
	root.show()
	(_last_button if _last_button else first_button).grab_focus()


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
