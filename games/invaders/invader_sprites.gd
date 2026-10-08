class_name InvaderSprites
extends RefCounted
## Desenhos em píxeis (originais) usados por todos os estilos do Space Invaders.
## "#" = píxel aceso. Cada invasor tem 2 fotogramas que alternam a cada passo da marcha.

const ALIENS := [
	[   # tipo 0 — "olho" (fila de cima, 30 pts)
		["..####..", ".#....#.", "#..##..#", "#.#..#.#", "#..##..#", ".#....#.", "..#..#..", ".#....#."],
		["..####..", ".#....#.", "#..##..#", "#.#..#.#", "#..##..#", ".#....#.", ".#....#.", "..#..#.."],
	],
	[   # tipo 1 — "cúpula" (20 pts)
		[".....#.....", "....###....", "..#######..", ".##.###.##.", "###########", "..#.#.#.#..", ".#.......#.", ".#.......#."],
		[".....#.....", "....###....", "..#######..", ".##.###.##.", "###########", "..#.#.#.#..", "..#.....#..", "#.........#"],
	],
	[   # tipo 2 — "medusa" (fila de baixo, 10 pts)
		["....####....", "..########..", ".#.#.##.#.#.", "############", "#.########.#", "#..#....#..#", "...##..##...", "..#......#.."],
		["....####....", "..########..", ".#.#.##.#.#.", "############", "#.########.#", "...#....#...", "..##....##..", ".#........#."],
	],
]

const UFO := [
	".......##.......",
	".....######.....",
	"...##########...",
	".##############.",
	"#.#.#.#..#.#.#.#",
	".##############.",
	"....#......#....",
]

const PLAYER := [
	"......#......",
	"......#......",
	".....###.....",
	"..#.#####.#..",
	".###########.",
	"#############",
	"##.#######.##",
	"#...........#",
]

const ALIEN_BOOM := [
	"...#..#..#...",
	"#...#...#...#",
	".#.........#.",
	"...#.....#...",
	"##.........##",
	"...#.....#...",
	".#...#.#...#.",
	"#...#...#...#",
]

const PLAYER_BOOM := [
	["......#.........", "...#......#..#..", "......#.#.......", ".#..#####...#...", "...########.....", "..###########.#.", ".#############..", "################"],
	["..#.......#.....", "......#.........", "#...#....#...#..", "......##.....#..", "..#.#####.#.....", ".###.#####.##...", "#############.#.", "################"],
]

## Bombas dos invasores: 3 tipos, 2 fotogramas cada (3x7).
const BOMBS := [
	[[".#.", "#..", ".#.", "..#", ".#.", "#..", ".#."], [".#.", "..#", ".#.", "#..", ".#.", "..#", ".#."]],
	[[".#.", ".#.", ".#.", ".#.", ".#.", "###", ".#."], [".#.", "###", ".#.", ".#.", ".#.", ".#.", ".#."]],
	[[".#.", ".##", ".#.", "##.", ".#.", ".##", ".#."], [".#.", "##.", ".#.", ".##", ".#.", "##.", ".#."]],
]


## Abrigo (22x16): octógono com uma abertura em V por baixo.
static func bunker_shape() -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(22 * 16)
	for y in 16:
		for x in 22:
			var on := true
			if y < 4 and (x < 4 - y or x > 21 - (4 - y)):
				on = false
			if y >= 10 and absf(x - 10.5) < (y - 9) * 1.15:
				on = false
			b[y * 22 + x] = 1 if on else 0
	return b


## Converte um desenho em segmentos horizontais [x, y, comprimento] (desenho rápido).
static func runs(rows: Array) -> Array:
	var out := []
	for y in rows.size():
		var row: String = rows[y]
		var x := 0
		while x < row.length():
			if row[x] == "#":
				var start := x
				while x < row.length() and row[x] == "#":
					x += 1
				out.append(Vector3i(start, y, x - start))
			else:
				x += 1
	return out


## Cria uma textura a partir de um desenho, com `scale` píxeis por ponto.
## `pixel_color` é um Callable(x, y, cor_base) -> Color opcional para pintar ponto a ponto.
static func texture(rows: Array, color: Color, scale := 3, pad := 0, pixel_color := Callable()) -> ImageTexture:
	var w: int = (rows[0] as String).length()
	var h := rows.size()
	var img := Image.create((w + pad * 2) * scale, (h + pad * 2) * scale, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		var row: String = rows[y]
		for x in w:
			if row[x] == "#":
				var c: Color = color if not pixel_color.is_valid() else pixel_color.call(x, y, color)
				img.fill_rect(Rect2i((x + pad) * scale, (y + pad) * scale, scale, scale), c)
	return ImageTexture.create_from_image(img)


## Versão desfocada (para brilhos): desenha com margem e aplica um desfoque simples.
static func glow_texture(rows: Array, color: Color, pad := 4, passes := 3) -> ImageTexture:
	var w: int = (rows[0] as String).length() + pad * 2
	var h: int = rows.size() + pad * 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(color, 0))
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == "#":
				img.set_pixel(x + pad, y + pad, color)
	for p in passes:
		var src := img.duplicate() as Image
		for y in h:
			for x in w:
				var a := 0.0
				var n := 0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var sx := x + dx
						var sy := y + dy
						if sx >= 0 and sy >= 0 and sx < w and sy < h:
							a += src.get_pixel(sx, sy).a
							n += 1
				img.set_pixel(x, y, Color(color, a / n))
	return ImageTexture.create_from_image(img)
