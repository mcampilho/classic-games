class_name PixelArt
extends RefCounted
## Desenhos em píxeis multicolores: cada letra corresponde a uma cor da paleta ("." = transparente).


## Cria uma textura (scale píxeis por ponto). `palette`: {"B": Color, ...}.
static func texture(rows: Array, palette: Dictionary, scale := 3) -> ImageTexture:
	var w: int = (rows[0] as String).length()
	var h := rows.size()
	var img := Image.create(w * scale, h * scale, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch != "." and palette.has(ch):
				img.fill_rect(Rect2i(x * scale, y * scale, scale, scale), palette[ch])
	return ImageTexture.create_from_image(img)


## Brilho desfocado (1 píxel por ponto, com margem `pad`), na cor de cada ponto.
static func glow(rows: Array, palette: Dictionary, pad := 4, passes := 3) -> ImageTexture:
	var w: int = (rows[0] as String).length() + pad * 2
	var h: int = rows.size() + pad * 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch != "." and palette.has(ch):
				img.set_pixel(x + pad, y + pad, palette[ch])
	for p in passes:
		var src := img.duplicate() as Image
		for y in h:
			for x in w:
				var acc := Color(0, 0, 0, 0)
				var n := 0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var sx := x + dx
						var sy := y + dy
						if sx >= 0 and sy >= 0 and sx < w and sy < h:
							var c := src.get_pixel(sx, sy)
							acc += Color(c.r * c.a, c.g * c.a, c.b * c.a, c.a)
							n += 1
				var a := acc.a / n
				if a > 0.0:
					img.set_pixel(x, y, Color(acc.r / acc.a, acc.g / acc.a, acc.b / acc.a, a))
				else:
					img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


static func size(rows: Array) -> Vector2:
	return Vector2((rows[0] as String).length(), rows.size())


## Como texture(), com um contorno de 1 ponto à volta da figura (outline transparente = sem contorno).
static func outlined(rows: Array, palette: Dictionary, outline: Color, scale := 1) -> ImageTexture:
	var w: int = (rows[0] as String).length()
	var h := rows.size()
	var pad := 1 if outline.a > 0.0 else 0
	var img := Image.create((w + pad * 2) * scale, (h + pad * 2) * scale, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var solid := func(x: int, y: int) -> bool:
		if x < 0 or y < 0 or y >= h or x >= w:
			return false
		var ch := (rows[y] as String)[x]
		return ch != "." and palette.has(ch)
	for y in range(-pad, h + pad):
		for x in range(-pad, w + pad):
			var c := Color(0, 0, 0, 0)
			if solid.call(x, y):
				c = palette[(rows[y] as String)[x]]
			elif pad > 0 and (solid.call(x - 1, y) or solid.call(x + 1, y) or solid.call(x, y - 1) or solid.call(x, y + 1)):
				c = outline
			if c.a > 0.0:
				img.fill_rect(Rect2i((x + pad) * scale, (y + pad) * scale, scale, scale), c)
	return ImageTexture.create_from_image(img)
