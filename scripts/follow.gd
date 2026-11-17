extends Node3D

@export var target: NodePath
@export var offset := Vector3.ZERO

var _target: Node3D


func _ready() -> void:
	_target = get_node_or_null(target)


func _process(_delta: float) -> void:
	if _target:
		global_position = _target.global_position + offset
