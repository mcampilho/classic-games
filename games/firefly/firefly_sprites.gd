class_name FireflySprites
extends RefCounted
## Desenhos originais do Pirilampo (pirilampo, morcegos e bónus do jardim).

## Pirilampo virado para a direita; 2 fotogramas (asas em cima / em baixo).
const FIREFLY := [
	[
		"...ww..ww..",
		"..w..ww..w.",
		"..w..ww..w.",
		"...wwBBww..",
		"LLLBBBBBHH.",
		"LLLLBBBBHHe",
		"LLLBBBBBHH.",
		"....B.B.B..",
		"...........",
	],
	[
		"...........",
		"...........",
		"....BBB....",
		"LLLBBBBBHH.",
		"LLLLBBBBHHe",
		"LLLBBBBBHH.",
		"..w..ww..w.",
		"..w..ww..w.",
		"...ww..ww..",
	],
]
const FIREFLY_PALETTE := {"L": Color("fff3a0"), "B": Color("6b4226"), "H": Color("e8590c"), "w": Color("a5d8ff"), "e": Color("343a40")}

const BAT := [
	[
		"B...........B",
		"BB.........BB",
		"BBB..B.B..BBB",
		"BBBB.BBB.BBBB",
		".BBBBEBEBBBB.",
		"..BBBBBBBBB..",
		"...B.BBB.B...",
		"......B......",
		".............",
	],
	[
		".............",
		".............",
		".....B.B.....",
		".....BBB.....",
		"..BBBEBEBBB..",
		".BBBBBBBBBBB.",
		"BBBB.BBB.BBBB",
		"BB....B....BB",
		"B...........B",
	],
]
const BAT_COLORS := [Color("e03131"), Color("f59f00"), Color("37b24d"), Color("7048e8")]

const FLOWER := [
	"..P.P..",
	".PPYPP.",
	"PPYYYPP",
	".PPYPP.",
	"..P.P..",
	"...G...",
	"..GG...",
]
const FLOWER_PALETTE := {"P": Color("ff8cc6"), "Y": Color("ffe066"), "G": Color("51cf66")}

const BONUS_NAMES := ["Gota de orvalho", "Bolota", "Cogumelo", "Trevo", "Girassol", "Pinha", "Lua", "Estrela"]
const BONUS := [
	["....W....", "...WBW...", "...BBB...", "..BBBBB..", ".BBBWBBB.", ".BBBBWBB.", ".BBBBBBB.", "..BBBBB..", "...BBB..."],
	["....s....", "..CCCCC..", ".CCCCCCC.", ".CCCCCCC.", "..NNNNN..", "..NNNNN..", "..NNNNN..", "...NNN...", "....N...."],
	["..RRRRR..", ".RRWRRRR.", "RRRRRWRRR", "RWRRRRRRR", "RRRRRRWRR", "...SSS...", "...SSS...", "...SSS...", "..SSSSS.."],
	["..GG.GG..", ".GGGGGGG.", ".GGGGGGG.", "..GGGGG..", ".GGGGGGG.", ".GGGGGGG.", "..GG.GG..", "....S....", "...S....."],
	["...YYY...", ".Y.YYY.Y.", "..YBBBY..", "YYBBBBBYY", "YYBBBBBYY", "..YBBBY..", ".Y.YYY.Y.", "...YYY...", "....G...."],
	["....G....", "...PPP...", "..PDPDP..", "..PPPPP..", ".PDPDPDP.", ".PPPPPPP.", "..PDPDP..", "...PPP...", "....P...."],
	["...MMM...", "..MM.....", ".MM......", ".MM......", ".MM......", ".MM......", "..MM.....", "...MMM...", "........."],
	["....X....", "....X....", "...XXX...", "XXXXXXXXX", ".XXXXXXX.", "..XXXXX..", "..XX.XX..", ".XX...XX.", "X.......X"],
]
const BONUS_PALETTES := [
	{"W": Color("ffffff"), "B": Color("74c0fc")},
	{"s": Color("5c3d1e"), "C": Color("7a5230"), "N": Color("c08a4a")},
	{"R": Color("e03131"), "W": Color("ffffff"), "S": Color("f1e3c8")},
	{"G": Color("40c057"), "S": Color("2b8a3e")},
	{"Y": Color("fcc419"), "B": Color("7a4b1f"), "G": Color("40c057")},
	{"G": Color("40c057"), "P": Color("a0522d"), "D": Color("5c2e12")},
	{"M": Color("fff3bf")},
	{"X": Color("ffd43b")},
]


## Uma paleta inteira numa só cor (silhuetas, brilhos).
static func mono(palette: Dictionary, c: Color) -> Dictionary:
	var out := {}
	for k in palette:
		out[k] = c
	return out
