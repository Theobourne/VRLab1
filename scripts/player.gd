extends CharacterBody3D

@export var walk_speed := 3.0
@export var run_speed := 6.0
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.0025
@export var reach := 3.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var tasks: Node
var hand: Node3D
var held: Node3D
var held_layer := 0
var aimed: Object
var sitting := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hand = Node3D.new()
	hand.name = "Hand"
	hand.position = Vector3(0.3, -0.25, -0.6)
	camera.add_child(hand)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_E:
				interact()
			KEY_R:
				if tasks and tasks.finished:
					get_tree().reload_current_scene()
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if tasks == null:
		tasks = get_tree().get_first_node_in_group("task_manager")
		if tasks:
			tasks.player = self
	aimed = _raycast()
	if tasks:
		tasks.update_prompt(aimed)
	if sitting:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_physical_key_pressed(KEY_SPACE):
		velocity.y = jump_velocity

	var input := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W): input.y -= 1
	if Input.is_physical_key_pressed(KEY_S): input.y += 1
	if Input.is_physical_key_pressed(KEY_A): input.x -= 1
	if Input.is_physical_key_pressed(KEY_D): input.x += 1

	var speed := run_speed if Input.is_physical_key_pressed(KEY_SHIFT) else walk_speed
	var dir := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()


func interact() -> void:
	if tasks and aimed:
		tasks.try_interact(self, aimed)


func _raycast() -> Object:
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * reach
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	var exclude: Array[RID] = [get_rid()]
	if held is CollisionObject3D:
		exclude.append(held.get_rid())
	query.exclude = exclude
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.collider if hit else null


func pick_up(item: Node3D) -> void:
	held = item
	if item is CollisionObject3D:
		held_layer = item.collision_layer
		item.collision_layer = 0
	item.reparent(hand, false)
	item.transform = Transform3D.IDENTITY


func place(target: Node3D, parent: Node) -> void:
	put_down(release(), target, parent)


func release() -> Node3D:
	var item := held
	held = null
	return item


func put_down(item: Node3D, target: Node3D, parent: Node) -> void:
	item.reparent(parent, false)
	item.global_transform = target.global_transform
	if item is CollisionObject3D:
		item.collision_layer = held_layer


func sit(seat: Node3D) -> void:
	sitting = true
	velocity = Vector3.ZERO
	$Collision.disabled = true
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "global_position", seat.global_position, 0.8)
	tw.tween_property(self, "global_rotation:y", seat.global_rotation.y, 0.8)
	tw.tween_property(head, "position:y", 1.05, 0.8)
	tw.tween_property(head, "rotation:x", deg_to_rad(-8), 0.8)
