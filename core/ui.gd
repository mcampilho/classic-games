class_name UI
extends RefCounted
## Utilitários de interface partilhados por todos os jogos.
## Cada estilo visual fornece uma "palete" (Dictionary) e o tema é gerado a partir dela.

const LAUNCHER_PALETTE := {
	"panel": Color(0.07, 0.08, 0.11, 0.96),
	"border": Color(0.35, 0.38, 0.48),
	"text": Color(0.93, 0.94, 0.97),
	"accent": Color(1.0, 0.78, 0.28),
	"button": Color(0.12, 0.13, 0.18),
	"button_hover": Color(0.19, 0.21, 0.28),
	"radius": 10,
	"dim": Color(0, 0, 0, 0),
}


static func make_theme(p: Dictionary) -> Theme:
	var t := Theme.new()
	t.default_font_size = 26
	var radius: int = p.get("radius", 8)
	var text: Color = p.text
	var accent: Color = p.accent

	var normal := StyleBoxFlat.new()
	normal.bg_color = p.button
	normal.border_color = p.border
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(radius)
	normal.content_margin_left = 28
	normal.content_margin_right = 28
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = p.button_hover
	hover.border_color = accent

	var pressed: StyleBoxFlat = hover.duplicate()
	pressed.bg_color = Color(accent, 0.35)

	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = accent
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(radius + 3)
	focus.set_expand_margin_all(4)

	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(p.button, 0.4)
	disabled.border_color = Color(p.border, 0.35)

	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("hover_pressed", "Button", pressed)
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("disabled", "Button", disabled)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", text)
	t.set_color("font_disabled_color", "Button", Color(text, 0.35))
	t.set_color("font_color", "Label", text)

	var panel := StyleBoxFlat.new()
	panel.bg_color = p.panel
	panel.border_color = p.border
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(radius + 6 if radius > 0 else 0)
	panel.set_content_margin_all(36)
	panel.shadow_color = Color(0, 0, 0, 0.35)
	panel.shadow_size = 18
	t.set_stylebox("panel", "PanelContainer", panel)
	return t


static func label(text: String, size := 26, color := Color(0, 0, 0, 0)) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	if color.a > 0.0:
		l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(callback)
	return b


## Cria um ecrã sobreposto: escurecimento opcional + painel centrado com uma coluna.
## Devolve {"root": Control, "box": VBoxContainer, "dim": ColorRect}.
static func overlay(parent: Node, min_width := 560.0) -> Dictionary:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = min_width
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	return {"root": root, "box": box, "dim": dim}
