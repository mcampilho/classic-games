class_name CycleButton
extends Button
## Botão de opções cíclicas ("Estilo   <  Neon  >").
## Toque/clique avança; setas esquerda/direita (teclado ou comando) mudam quando focado.

signal value_changed(index: int)

var title := ""
var options: Array = []
var index := 0


func setup(p_title: String, p_options: Array, p_index: int) -> CycleButton:
	title = p_title
	options = p_options
	index = clampi(p_index, 0, options.size() - 1)
	_refresh()
	return self


func _ready() -> void:
	pressed.connect(step.bind(1))


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		step(-1)
		accept_event()
	elif event.is_action_pressed("ui_right"):
		step(1)
		accept_event()


func step(delta: int) -> void:
	index = wrapi(index + delta, 0, options.size())
	_refresh()
	value_changed.emit(index)


func _refresh() -> void:
	text = "%s:   <  %s  >" % [title, options[index]]
