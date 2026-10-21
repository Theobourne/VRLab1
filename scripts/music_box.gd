extends AudioStreamPlayer3D

const RATE := 22050.0
const NOTES := [60, 64, 67, 72, 67, 64, 62, 65, 69, 74, 69, 65]
const NOTE_LEN := 0.25

var playback: AudioStreamGeneratorPlayback
var t := 0.0


func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.3
	stream = gen


func play_music() -> void:
	play()
	playback = get_stream_playback()


func _process(_delta: float) -> void:
	if not playing or playback == null:
		return
	for i in playback.get_frames_available():
		var step := int(t / NOTE_LEN)
		var note: int = NOTES[step % NOTES.size()]
		var freq := 440.0 * pow(2.0, (note - 69) / 12.0)
		var local := fmod(t, NOTE_LEN)
		var env := exp(-local * 6.0)
		var s := (sin(TAU * freq * t) + 0.3 * sin(TAU * freq * 2.0 * t)) * env * 0.25
		playback.push_frame(Vector2(s, s))
		t += 1.0 / RATE
