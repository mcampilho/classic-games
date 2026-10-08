class_name OutRunMusic
extends RefCounted
## Rádio do OutRun: três músicas originais, compostas para este projeto e sintetizadas em código.
## Notação: cada compasso tem 8 colcheias; "-" prolonga a nota anterior e "." é pausa.

const NAMES := ["Onda Atlântica", "Estrada Mágica", "Pôr do Sol"]
const QUALITIES := {"": [0, 4, 7], "m": [0, 3, 7], "7": [0, 4, 7, 10], "m7": [0, 3, 7, 10], "maj7": [0, 4, 7, 11]}

const SONGS := [
	{
		"bpm": 150.0,
		"chords": "A F#m D E A F#m Bm E D E C#m F#m D E A A",
		"melody": [
			"E5 - C#5 E5 A5 - G#5 A5", "F#5 - C#5 - A4 - - -", "D5 - F#5 A5 - F#5 D5 F#5", "E5 - - B4 E5 - G#5 -",
			"A5 - G#5 A5 E5 - C#5 E5", "F#5 - E5 - C#5 - A4 -", "B4 - D5 F#5 B5 - A5 F#5", "G#5 - - - E5 - . .",
			"F#5 - A5 - D6 - A5 -", "G#5 - B5 - E6 - B5 -", "G#5 - E5 - C#5 - E5 G#5", "A5 - - F#5 - - C#5 -",
			"D5 E5 F#5 - A5 - F#5 E5", "E5 - G#5 - B5 - G#5 E5", "A5 - - - E5 - C#5 -", "A5 - - - . . . .",
		],
		"bass": "0 . 0 12 . 0 7 .",
		"arp": [0, 1, 2, 1],
		"kick": "x...x...x...x...",
		"snare": "....x.......x..x",
		"hat": "..x...x...x...x.",
		"lead": {"wave": "square", "volume": 0.11, "lowpass": 0.3, "decay": 2.0, "release": 0.02},
		"bass_opts": {"wave": "square", "volume": 0.16, "lowpass": 0.08, "release": 0.02},
		"arp_opts": {"wave": "triangle", "volume": 0.045, "decay": 12.0},
	},
	{
		"bpm": 120.0,
		"chords": "Em7 Em7 A7 A7 Cmaj7 D Em7 B7 Am7 D7 Gmaj7 Cmaj7 Am7 B7 Em7 B7",
		"melody": [
			"B4 - E5 - G5 - F#5 E5", "D5 - E5 - . B4 D5 E5", "C#5 - E5 - G5 - E5 C#5", "E5 - - - . . A4 B4",
			"C5 - E5 G5 B5 - G5 E5", "F#5 - A5 - F#5 - D5 -", "E5 G5 B5 - A5 G5 F#5 E5", "D#5 - - - F#5 - B4 -",
			"A5 - G5 - E5 - C5 -", "D5 - F#5 - A5 - C6 -", "B5 - - A5 G5 - D5 -", "E5 - G5 - C5 - E5 -",
			"C5 - E5 - A5 - G5 E5", "F#5 - A5 - D#5 - B4 -", "E5 - - - G5 - B5 -", "A5 - F#5 - D#5 - B4 -",
		],
		"bass": "0 . 12 0 . 0 10 12",
		"arp": [0, 2, 1, 3],
		"kick": "x.....x...x.....",
		"snare": "....x.......x...",
		"hat": "x.xxx.xxx.xxx.xx",
		"lead": {"wave": "saw", "volume": 0.09, "lowpass": 0.22, "decay": 1.5, "release": 0.03},
		"bass_opts": {"wave": "saw", "volume": 0.17, "lowpass": 0.07, "decay": 5.0, "release": 0.02},
		"arp_opts": {"wave": "square", "volume": 0.03, "lowpass": 0.2, "decay": 14.0},
	},
	{
		"bpm": 100.0,
		"chords": "Dm Bb F C Dm Bb Gm A Bb C Am Dm Bb C Dm A",
		"melody": [
			"A4 - - D5 - - F5 -", "F5 - - E5 - D5 - -", "C5 - - F5 - - A5 -", "G5 - - - E5 - - -",
			"D5 - F5 - A5 - D6 -", "C6 - - A5 - - F5 -", "G5 - - A#5 - - D5 -", "E5 - - - C#5 - - -",
			"D5 - F5 - A#5 - - -", "C6 - - A#5 A5 - G5 -", "A5 - - E5 - - C5 -", "D5 - - - - - . .",
			"F5 - G5 - A5 - A#5 -", "C6 - - - G5 - E5 -", "F5 - E5 - D5 - A4 -", "C#5 - - - E5 - - -",
		],
		"bass": "0 - - 0 - - 7 -",
		"arp": [0, 1, 2, 3, 2, 1, 0, 2],
		"kick": "x.......x.x.....",
		"snare": "....x.......x...",
		"hat": "x...x...x...x...",
		"lead": {"wave": "triangle", "volume": 0.2, "lowpass": 0.6, "attack": 0.02, "release": 0.08, "decay": 0.8},
		"bass_opts": {"wave": "triangle", "volume": 0.22, "lowpass": 0.4, "release": 0.04},
		"arp_opts": {"wave": "sine", "volume": 0.05, "decay": 4.0},
	},
]


static func cache_key(i: int) -> String:
	return "outrun_song_%d" % i


## A música i, se já estiver pronta (gerada em segundo plano por prewarm()).
static func stream(i: int) -> AudioStreamWAV:
	var d: Variant = Synth.cache_get(cache_key(i))
	if d == null:
		return null
	return (d as Dictionary).stream


static func prewarm() -> int:
	return WorkerThreadPool.add_task(func() -> void:
		for i in NAMES.size():
			if Synth.cache_get(cache_key(i)) == null:
				Synth.cache_set(cache_key(i), {"stream": build(i)}))


static func midi(note: String) -> int:
	var base := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
	var n: int = base[note[0]]
	var i := 1
	if note[i] == "#":
		n += 1
		i += 1
	elif note[i] == "b":
		n -= 1
		i += 1
	return n + (int(note.substr(i)) + 1) * 12


static func freq(m: int) -> float:
	return 440.0 * pow(2.0, (m - 69) / 12.0)


## "F#m7" -> [raiz MIDI na oitava 2, intervalos]
static func chord(sym: String) -> Array:
	var root := sym[0]
	var rest := sym.substr(1)
	if rest.begins_with("#") or rest.begins_with("b"):
		root += rest[0]
		rest = rest.substr(1)
	return [midi(root + "2"), QUALITIES.get(rest, QUALITIES[""])]


static func build(index: int) -> AudioStreamWAV:
	return build_song(SONGS[index])


## Sintetiza uma música descrita nesta notação (também usado por outros jogos).
static func build_song(song: Dictionary) -> AudioStreamWAV:
	var eighth: float = 60.0 / float(song.bpm) / 2.0
	var bars: int = song.melody.size()
	var step_n := int(eighth * Synth.RATE)
	var total := bars * 8 * step_n
	var buf := PackedFloat32Array()
	buf.resize(total)
	buf.fill(0.0)
	var notes := {}
	var chords: PackedStringArray = (song.chords as String).split(" ", false)

	# melodia
	for b in bars:
		var tokens: PackedStringArray = (song.melody[b] as String).split(" ", false)
		for k in tokens.size():
			var t := tokens[k]
			if t == "-" or t == ".":
				continue
			var length := 1
			while k + length < tokens.size() and tokens[k + length] == "-":
				length += 1
			var m := midi(t)
			_add(buf, _note(notes, "lead", m, length * eighth * 0.95, song.lead), (b * 8 + k) * step_n)

	# baixo e arpejo, a partir dos acordes
	var bass: PackedStringArray = (song.bass as String).split(" ", false)
	var arp: Array = song.arp
	for b in bars:
		var ch := chord(chords[b % chords.size()])
		var root: int = ch[0]
		var iv: Array = ch[1]
		for k in 8:
			var t := bass[k]
			if t == "-" or t == ".":
				continue
			var length := 1
			while k + length < 8 and bass[k + length] == "-":
				length += 1
			_add(buf, _note(notes, "bass", root + int(t), length * eighth * 0.9, song.bass_opts), (b * 8 + k) * step_n)
		for k in 16:
			var deg: int = arp[k % arp.size()]
			var m: int = root + 24 + int(iv[deg % iv.size()]) + (12 if deg >= iv.size() else 0)
			_add(buf, _note(notes, "arp", m, eighth * 0.45, song.arp_opts), b * 8 * step_n + k * step_n / 2)

	# bateria
	var kick := Synth.render(120.0, 0.16, {"wave": "sine", "freq_end": 42.0, "volume": 0.45, "decay": 16.0})
	var snare := Synth.mix([
		Synth.render(0.0, 0.14, {"wave": "noise", "volume": 0.2, "lowpass": 0.55, "decay": 24.0}),
		Synth.render(190.0, 0.08, {"wave": "sine", "volume": 0.14, "decay": 30.0}),
	])
	var hat := Synth.render(0.0, 0.04, {"wave": "noise", "volume": 0.06, "decay": 70.0})
	for b in bars:
		for k in 16:
			var at := b * 8 * step_n + k * step_n / 2
			if (song.get("kick", "") as String).length() > k and (song.kick as String)[k] == "x":
				_add(buf, kick, at)
			if (song.get("snare", "") as String).length() > k and (song.snare as String)[k] == "x":
				_add(buf, snare, at)
			if (song.get("hat", "") as String).length() > k and (song.hat as String)[k] == "x":
				_add(buf, hat, at)

	var peak := 0.0
	for i in total:
		peak = maxf(peak, absf(buf[i]))
	if peak > 0.8:
		var g := 0.8 / peak
		for i in total:
			buf[i] *= g
	var s := Synth.to_stream(buf)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = total
	return s


static func _note(cache: Dictionary, voice: String, m: int, dur: float, opts: Dictionary) -> PackedFloat32Array:
	var key := "%s%d_%d" % [voice, m, int(dur * 1000.0)]
	if not cache.has(key):
		cache[key] = Synth.render(freq(m), dur, opts)
	return cache[key]


## Soma um som ao buffer; o que passar do fim continua no início (a música dá a volta sem cortes).
static func _add(buf: PackedFloat32Array, s: PackedFloat32Array, at: int) -> void:
	var total := buf.size()
	var n := s.size()
	var end := mini(at + n, total)
	var j := 0
	for i in range(at, end):
		buf[i] += s[j]
		j += 1
	for i in range(0, n - j):
		buf[i] += s[j + i]
