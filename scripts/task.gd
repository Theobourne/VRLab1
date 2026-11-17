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
@export var sound: AudioStream
@export var burst: NodePath
@export var starts: NodePath

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
			_switch_on(_effect)
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
	if sound and kind != Kind.WATER:
		play_at(sound, _target.global_position)
	if not burst.is_empty() and kind != Kind.WATER:
		var b: GPUParticles3D = get_node(burst)
		b.restart()
	if not starts.is_empty():
		get_node(starts).emitting = true
	done = true


func _scene_root() -> Node:
	return owner if owner else get_tree().current_scene


func play_at(stream: AudioStream, pos: Vector3) -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.unit_size = 3.0
	_scene_root().add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()


func _switch_on(light: Light3D) -> void:
	light.visible = true
	if light.get_script() != null:
		return
	var full := light.light_energy
	var tw := create_tween()
	for k in [0.1, 0.8, 0.05, 0.6, 0.2, 1.0]:
		tw.tween_property(light, "light_energy", full * k, 0.06)


func _water(player: Node) -> void:
	var bottle: Node3D = player.release()
	var home: Node3D = _effect
	var pour_at := _target.global_position + Vector3(0.0, 0.85, 0.25)
	bottle.reparent(_scene_root(), true)
	var tw := create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(bottle, "global_position", pour_at, 0.35)
	tw.parallel().tween_property(bottle, "global_rotation", Vector3.ZERO, 0.35)
	tw.tween_property(bottle, "rotation:x", deg_to_rad(-110), 0.25)
	tw.tween_callback(func():
		if sound:
			play_at(sound, pour_at)
		if not burst.is_empty():
			var drops: GPUParticles3D = get_node(burst)
			drops.global_position = pour_at + Vector3(0.0, -0.1, -0.24)
			drops.restart())
	tw.tween_interval(1.0)
	tw.tween_property(bottle, "rotation:x", 0.0, 0.2)
	tw.tween_property(bottle, "global_position", home.global_position, 0.5)
	tw.parallel().tween_property(bottle, "global_rotation", home.global_rotation, 0.5)
	tw.tween_callback(func(): player.put_down(bottle, home, home.get_parent()))
	var plant: Node3D = target_node().get_node("Model")
	var bounce := create_tween()
	bounce.tween_property(plant, "scale", Vector3(1.0, 1.08, 1.0), 0.5).set_delay(0.9)
	bounce.tween_property(plant, "scale", Vector3.ONE, 0.5)
