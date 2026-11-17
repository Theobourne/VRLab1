extends Light3D

@export var amount := 0.25
@export var speed := 9.0

var base := 1.0
var noise := FastNoiseLite.new()
var t := 0.0


func _ready() -> void:
	base = light_energy
	noise.frequency = 1.0
	noise.seed = randi()


func _process(delta: float) -> void:
	if not visible:
		return
	t += delta * speed
	light_energy = base * (1.0 - amount + amount * 2.0 * (noise.get_noise_1d(t) * 0.5 + 0.5))
