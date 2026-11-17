extends AudioStreamPlayer3D


func _ready() -> void:
	finished.connect(play)
	if autoplay and not playing:
		play()
