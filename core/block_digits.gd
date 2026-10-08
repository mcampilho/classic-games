class_name BlockDigits
extends RefCounted
## Algarismos em blocos (3x5), como nos marcadores das primeiras máquinas arcade.

const GLYPHS := {
	"0": ["111", "101", "101", "101", "111"],
	"1": ["001", "001", "001", "001", "001"],
	"2": ["111", "001", "111", "100", "111"],
	"3": ["111", "001", "111", "001", "111"],
	"4": ["101", "101", "111", "001", "001"],
	"5": ["111", "100", "111", "001", "111"],
	"6": ["100", "100", "111", "101", "111"],
	"7": ["111", "001", "001", "001", "001"],
	"8": ["111", "101", "111", "101", "111"],
	"9": ["111", "101", "111", "001", "001"],
}


static func width(text: String, cell: float) -> float:
	return text.length() * 4 * cell - cell


## Desenha `text` (só algarismos) centrado em center_x, a partir de `top`.
static func draw(ci: CanvasItem, text: String, center_x: float, top: float, cell: float, color: Color) -> void:
	var x := center_x - width(text, cell) / 2
	for ch in text:
		var rows: Array = GLYPHS.get(ch, GLYPHS["0"])
		for r in 5:
			var row: String = rows[r]
			for c in 3:
				if row[c] == "1":
					ci.draw_rect(Rect2(x + c * cell, top + r * cell, cell, cell), color)
		x += 4 * cell
