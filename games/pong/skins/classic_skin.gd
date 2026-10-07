extends PongSkin
## Clássico 1972: fundo preto, tudo branco, bola quadrada, rede tracejada,
## marcador em blocos e os três "bips" de onda quadrada da máquina original.

const WHITE := Color(0.96, 0.96, 0.96)
const CELL := 14.0
const DIGITS := {
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


func _build_sfx() -> void:
	# Frequências e durações aproximadas dos sons do circuito original.
	sfx.paddle = Synth.tone(459.0, 0.096, {"wave": "square", "volume": 0.3})
	sfx.wall = Synth.tone(226.0, 0.016, {"wave": "square", "volume": 0.3})
	sfx.score = Synth.tone(490.0, 0.257, {"wave": "square", "volume": 0.3})


func _on_game_over(_winner: int) -> void:
	pass  # o original não tinha som de vitória


func _draw() -> void:
	var f := PongGame.FIELD
	draw_rect(Rect2(Vector2.ZERO, f), Color.BLACK)
	var y := 0.0
	while y < f.y:
		draw_rect(Rect2(f.x / 2 - 4, y + 4, 8, 16), WHITE)
		y += 32.0
	_draw_number(game.scores[0], f.x / 2 - 170, 36)
	_draw_number(game.scores[1], f.x / 2 + 170, 36)
	for side in 2:
		draw_rect(game.paddle_rect(side), WHITE)
	if game.state == PongGame.State.PLAY:
		draw_rect(game.ball_rect(), WHITE)


func _draw_number(n: int, center_x: float, top: float) -> void:
	var s := str(n)
	var total := s.length() * 3 * CELL + (s.length() - 1) * CELL
	var x := center_x - total / 2
	for ch in s:
		var rows: Array = DIGITS[ch]
		for r in 5:
			var row: String = rows[r]
			for c in 3:
				if row[c] == "1":
					draw_rect(Rect2(x + c * CELL, top + r * CELL, CELL, CELL), WHITE)
		x += 4 * CELL


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0, 0, 0, 0.92),
		"border": WHITE,
		"text": WHITE,
		"accent": WHITE,
		"button": Color.BLACK,
		"button_hover": Color(1, 1, 1, 0.16),
		"radius": 0,
		"dim": Color(0, 0, 0, 0.35),
	}
