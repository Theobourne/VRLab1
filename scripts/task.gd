class_name Task
extends Node

enum Kind { SWITCH_ON, PICK_UP, PLACE, WATER, PLAY_MUSIC, SIT }

@export var label := ""
@export var prompt := ""
@export var kind := Kind.SWITCH_ON
@export var target: NodePath
@export var item: NodePath
@export var effect: NodePath
@export var start_at: NodePath
@export var item_name := ""

var done := false
var _target: Node3D
var _item: Node3D
var _effect: Node


func _ready() -> void:
	_target = get_node(target)
	_item = get_node_or_null(item)
	_effect = get_node_or_null(effect)
	if not start_at.is_empty() and _item:
		_item.global_transform = (get_node(start_at) as Node3D).global_transform


func target_node() -> Node3D:
	return _target


func matches(collider: Object) -> bool:
	var t := target_node()
	return collider == t or (collider is Node and t.is_ancestor_of(collider))


func can_do(player: Node) -> String:
	match kind:
		Kind.PLACE, Kind.WATER:
			if player.held != _item:
				return "You need to hold the %s first" % item_name
		_:
			if player.held:
				return "Your hands are full"
	return ""


func perform(player: Node) -> void:
	match kind:
		Kind.SWITCH_ON:
			_effect.visible = true
		Kind.PICK_UP:
			player.pick_up(_item)
		Kind.PLACE:
			player.place(_effect, _effect.get_parent())
		Kind.WATER:
			_water(player)
		Kind.PLAY_MUSIC:
			_effect.play_music()
		Kind.SIT:
			player.sit(_effect)
	done = true


func _water(player: Node) -> void:
	var bottle: Node3D = player.release()
	var home: Node3D = _effect
	var tw := create_tween()
	tw.tween_property(bottle, "rotation:z", deg_to_rad(80), 0.3)
	tw.tween_interval(0.4)
	tw.tween_callback(func(): player.put_down(bottle, home, home.get_parent()))
	var plant: Node3D = target_node().get_node("Model")
	var bounce := create_tween()
	bounce.tween_property(plant, "scale", Vector3(1.0, 1.08, 1.0), 0.5).set_delay(0.4)
	bounce.tween_property(plant, "scale", Vector3.ONE, 0.5)

