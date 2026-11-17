extends AudioStreamPlayer

const RATE := 22050.0

var playback: AudioStreamGeneratorPlayback
var t := 0.0
var noise := 0.0


func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.3
	stream = gen
	play()
	playback = get_stream_playback()


func _process(_delta: float) -> void:
	if playback == null:
		return
	for i in playback.get_frames_available():
		noise = noise * 0.995 + randf_range(-1.0, 1.0) * 0.005
		var swell := 0.8 + 0.2 * sin(TAU * 0.07 * t)
		var s := (sin(TAU * 50.0 * t) * 0.5 + sin(TAU * 100.0 * t) * 0.25 + noise * 6.0) * swell * 0.2
		playback.push_frame(Vector2(s, s))
		t += 1.0 / RATE
