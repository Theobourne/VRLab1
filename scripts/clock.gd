extends Node3D

@onready var hour_hand: Node3D = $HourHand
@onready var minute_hand: Node3D = $MinuteHand
@onready var second_hand: Node3D = $SecondHand


func _process(_delta: float) -> void:
	var now := Time.get_time_dict_from_system()
	var s: float = now.second
	var m: float = now.minute + s / 60.0
	var h: float = fmod(now.hour, 12.0) + m / 60.0
	second_hand.rotation.z = -TAU * s / 60.0
	minute_hand.rotation.z = -TAU * m / 60.0
	hour_hand.rotation.z = -TAU * h / 12.0
