extends Node3D

@export var flash_light: NodePath
@export var night_sky: NodePath
@export var thunder: NodePath
@export var min_gap := 12.0
@export var max_gap := 25.0

var _light: Light3D
var _sky_mat: StandardMaterial3D
var _thunder: AudioStreamPlayer
var _sky_color: Color


func _ready() -> void:
	_light = get_node(flash_light)
	_thunder = get_node(thunder)
	var sky: MeshInstance3D = get_node(night_sky)
	_sky_mat = (sky.mesh as QuadMesh).material
	_sky_color = _sky_mat.albedo_color
	_light.light_energy = 0.0
	_schedule(randf_range(5.0, 9.0))


func _schedule(wait: float) -> void:
	get_tree().create_timer(wait).timeout.connect(strike)


func strike() -> void:
	var bright := Color(0.75, 0.8, 0.95)
	var tw := create_tween()
	for flash in [[1.0, 0.06], [0.2, 0.08], [0.8, 0.05], [0.0, 0.35]]:
		var k: float = flash[0]
		tw.tween_property(_light, "light_energy", 6.0 * k, flash[1])
		tw.parallel().tween_property(_sky_mat, "albedo_color", _sky_color.lerp(bright, k), flash[1])
	get_tree().create_timer(randf_range(0.4, 1.4)).timeout.connect(_thunder.play)
	_schedule(randf_range(min_gap, max_gap))
