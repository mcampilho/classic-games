class_name GalaxianSprites
extends RefCounted
## Desenhos originais (multicolores) para o Galaxian. Letras = cores da paleta de cada tipo.

## Tipos: 0 almirante, 1 escolta (vermelho), 2 emissário (roxo), 3 zangão (azul)
const ALIEN := [
	[   # asas em baixo
		"..C.....C..",
		"...C...C...",
		"..BBBBBBB..",
		".BBYYBYYBB.",
		"BBBBBBBBBBB",
		"B.CCBBBCC.B",
		"B..B...B..B",
		"...C...C...",
	],
	[   # asas em cima
		"..C.....C..",
		"...C...C...",
		"B.BBBBBBB.B",
		"BBBYYBYYBBB",
		".BBBBBBBBB.",
		"..CCBBBCC..",
		"...B...B...",
		"..C.....C..",
	],
]

const FLAGSHIP := [
	[
		"......Y......",
		".....YYY.....",
		"..R..YYY..R..",
		".RR.YYYYY.RR.",
		"RRRYYRYRYYRRR",
		"RRYYYYYYYYYRR",
		".R.YYYYYYY.R.",
		"...Y.YYY.Y...",
		"..Y...Y...Y..",
		".Y.........Y.",
	],
	[
		"......Y......",
		".....YYY.....",
		".R...YYY...R.",
		"RR..YYYYY..RR",
		"RRRYYRYRYYRRR",
		".RYYYYYYYYYR.",
		"..RYYYYYYYR..",
		"...Y.YYY.Y...",
		"...Y..Y..Y...",
		"..Y.......Y..",
	],
]

const PLAYER := [
	"......W......",
	"......W......",
	".....RWR.....",
	".....WWW.....",
	"..R..WWW..R..",
	"..W.WWBWW.W..",
	".WWWWBBBWWWW.",
	"WWWWWWBWWWWWW",
	"WW.RR.W.RR.WW",
	"W..R.....R..W",
]

const BOOM := [
	["....Y....", "..Y.R.Y..", "...RRR...", "YRRWWWRRY", "...RRR...", "..Y.R.Y..", "....Y...."],
	["Y...R...Y", ".R..Y..R.", "...W.W...", "RY.....YR", "...W.W...", ".R..Y..R.", "Y...R...Y"],
]

const PALETTES := [
	{"R": Color("e03131"), "Y": Color("ffd43b"), "B": Color("ffd43b"), "C": Color("e03131")},   # almirante
	{"B": Color("e03131"), "C": Color("ffd43b"), "Y": Color("f8f9fa")},                         # escolta
	{"B": Color("ae3ec9"), "C": Color("f06595"), "Y": Color("f8f9fa")},                         # emissário
	{"B": Color("1c7ed6"), "C": Color("3bc9db"), "Y": Color("ffe066")},                         # zangão
]
const PLAYER_PALETTE := {"W": Color("f1f3f5"), "R": Color("f03e3e"), "B": Color("339af0")}
const BOOM_PALETTE := {"Y": Color("ffd43b"), "R": Color("ff6b6b"), "W": Color("ffffff")}


static func frame(kind: int, f: int) -> Array:
	return FLAGSHIP[f] if kind == 0 else ALIEN[f]
