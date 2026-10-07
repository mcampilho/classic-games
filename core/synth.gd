class_name Synth
extends RefCounted
## Sintetizador minimalista: gera efeitos sonoros em código (sem ficheiros de áudio).
## Cada jogo/estilo pode criar os seus sons com tone()/render()/mix()/concat().

const RATE := 22050


## Gera um som simples e devolve-o pronto a tocar.
static func tone(freq: float, dur: float, opts := {}) -> AudioStreamWAV:
	return to_stream(render(freq, dur, opts))


## Gera amostras (-1..1). Opções:
##  wave: "square" | "sine" | "saw" | "triangle" | "noise"
##  volume, freq_end (varrimento de frequência), decay (decaimento exponencial /s),
##  attack, release (segundos), lowpass (0..1, suaviza o som; 1 = sem filtro)
static func render(freq: float, dur: float, opts := {}) -> PackedFloat32Array:
	var wave: String = opts.get("wave", "square")
	var vol: float = opts.get("volume", 0.5)
	var freq_end: float = opts.get("freq_end", freq)
	var decay: float = opts.get("decay", 0.0)
	var attack: float = opts.get("attack", 0.002)
	var release: float = opts.get("release", 0.004)
	var lp: float = opts.get("lowpass", 1.0)
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1972
	var phase := 0.0
	var y := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := lerpf(freq, freq_end, float(i) / maxf(n - 1, 1))
		phase = fmod(phase + f / RATE, 1.0)
		var s := 0.0
		match wave:
			"square":
				s = 1.0 if phase < 0.5 else -1.0
			"sine":
				s = sin(phase * TAU)
			"saw":
				s = phase * 2.0 - 1.0
			"triangle":
				s = 1.0 - 4.0 * absf(phase - 0.5)
			"noise":
				s = rng.randf_range(-1.0, 1.0)
		y += lp * (s - y)
		var env := 1.0
		if decay > 0.0:
			env *= exp(-decay * t)
		if t < attack:
			env *= t / attack
		var rem := dur - t
		if rem < release:
			env *= rem / release
		out[i] = y * env * vol
	return out


static func silence(dur: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(dur * RATE))
	out.fill(0.0)
	return out


## Sobrepõe vários sons (soma amostra a amostra).
static func mix(parts: Array) -> PackedFloat32Array:
	var size := 0
	for p: PackedFloat32Array in parts:
		size = maxi(size, p.size())
	var out := PackedFloat32Array()
	out.resize(size)
	out.fill(0.0)
	for p: PackedFloat32Array in parts:
		for i in p.size():
			out[i] += p[i]
	return out


## Coloca vários sons em sequência.
static func concat(parts: Array) -> AudioStreamWAV:
	var all := PackedFloat32Array()
	for p: PackedFloat32Array in parts:
		all.append_array(p)
	return to_stream(all)


static func to_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s
