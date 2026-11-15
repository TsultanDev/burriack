extends Node
## Tiny procedural sound bank so the game needs no external audio assets.

const RATE := 22050
const VOICES := 10

var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _bank: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		voice.bus = "Master"
		add_child(voice)
		_voices.append(voice)

	_bank["shoot"] = _tone(1200.0, 320.0, 0.075, 0.22, true)
	_bank["jump"] = _tone(260.0, 620.0, 0.09, 0.16)
	_bank["pickup"] = _arp([740.0, 1110.0, 1480.0], 0.05, 0.30)
	_bank["hurt"] = _tone(180.0, 70.0, 0.22, 0.35, true)
	_bank["enemy_hit"] = _tone(520.0, 260.0, 0.06, 0.18, true)
	_bank["enemy_die"] = _noise_burst(0.28, 0.35)
	_bank["win"] = _arp([523.25, 659.25, 783.99, 1046.5], 0.12, 0.35)
	_bank["lose"] = _arp([392.0, 329.63, 261.63, 196.0], 0.16, 0.35)


func play(sound: String, pitch: float = 1.0, volume_db: float = -4.0) -> void:
	if not _bank.has(sound):
		return
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = _bank[sound]
	voice.pitch_scale = clampf(pitch, 0.5, 2.0)
	voice.volume_db = volume_db
	voice.play()


func _tone(start_freq: float, end_freq: float, duration: float, volume: float, square: bool = false) -> AudioStreamWAV:
	var count := maxi(1, int(RATE * duration))
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	for i in count:
		var t := float(i) / float(count)
		var freq := lerpf(start_freq, end_freq, t)
		phase += TAU * freq / float(RATE)
		var sample := sin(phase)
		if square:
			sample = signf(sample) * 0.55
		var env := pow(1.0 - t, 2.2) * minf(1.0, float(i) / 48.0)
		data.encode_s16(i * 2, int(clampf(sample * env * volume, -1.0, 1.0) * 32767.0))
	return _wav(data)


func _arp(freqs: Array, segment: float, volume: float) -> AudioStreamWAV:
	var total := int(RATE * segment * freqs.size())
	var data := PackedByteArray()
	data.resize(total * 2)
	var phase := 0.0
	var seg_count := maxi(1, int(RATE * segment))
	for i in total:
		var seg := mini(freqs.size() - 1, int(floor(float(i) / float(seg_count))))
		var local := float(i % seg_count) / float(seg_count)
		var freq: float = freqs[seg]
		phase += TAU * freq / float(RATE)
		var env := pow(1.0 - local, 1.6) * 0.8
		var sample := sin(phase) * env * volume
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _wav(data)


func _noise_burst(duration: float, volume: float) -> AudioStreamWAV:
	var count := maxi(1, int(RATE * duration))
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var low := 0.0
	for i in count:
		var t := float(i) / float(count)
		low = lerpf(low, rng.randf_range(-1.0, 1.0), 0.25)
		var env := pow(1.0 - t, 2.0)
		data.encode_s16(i * 2, int(clampf(low * env * volume, -1.0, 1.0) * 32767.0))
	return _wav(data)


func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream
