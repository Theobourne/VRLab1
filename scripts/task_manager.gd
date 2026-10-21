extends Node

signal progressed(done_count: int)

enum State { DONE, AVAILABLE, LOCKED }

var tasks: Array[Task] = []
var finished := false
var hud: Node
var player: Node
var glow := StandardMaterial3D.new()
var glowing: Array[MeshInstance3D] = []


func _ready() -> void:
	add_to_group("task_manager")
	for c in get_children():
		if c is Task:
			tasks.append(c)
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(1.0, 0.85, 0.3, 0.25)
	glow.cull_mode = BaseMaterial3D.CULL_DISABLED
	var pulse := create_tween().set_loops()
	pulse.tween_property(glow, "albedo_color:a", 0.05, 0.7)
	pulse.tween_property(glow, "albedo_color:a", 0.3, 0.7)
	await get_tree().process_frame
	hud = get_tree().get_first_node_in_group("hud")
	if hud:
		var labels: Array[String] = []
		for t in tasks:
			labels.append(t.label)
		hud.setup(labels)
	_refresh()


func state_of(t: Task) -> State:
	if t.done:
		return State.DONE
	if t.kind == Task.Kind.SIT:
		for other in tasks:
			if other != t and not other.done:
				return State.LOCKED
	return State.AVAILABLE


func done_count() -> int:
	return tasks.filter(func(t): return t.done).size()


func _task_for(aimed: Object) -> Task:
	var fallback: Task = null
	for t in tasks:
		if t.done or not t.matches(aimed):
			continue
		if state_of(t) == State.AVAILABLE and player and t.can_do(player) == "":
			return t
		if fallback == null:
			fallback = t
	return fallback


func update_prompt(aimed: Object) -> void:
	if not hud:
		return
	var t := _task_for(aimed) if aimed else null
	if t and state_of(t) == State.AVAILABLE and t.can_do(player) == "":
		hud.show_prompt("E – " + t.prompt)
	else:
		hud.show_prompt("")


func try_interact(p: Node, aimed: Object) -> void:
	player = p
	if finished:
		return
	var t := _task_for(aimed)
	if t == null:
		return
	if state_of(t) == State.LOCKED:
		_hint("Finish the other tasks first")
		return
	var problem := t.can_do(p)
	if problem != "":
		_hint(problem)
		return
	t.perform(p)
	finished = done_count() == tasks.size()
	_refresh()
	progressed.emit(done_count())


func notify_hands_changed() -> void:
	_refresh()


func _hint(text: String) -> void:
	if hud:
		hud.show_hint(text)


func _refresh() -> void:
	for m in glowing:
		if is_instance_valid(m):
			m.material_overlay = null
	glowing.clear()
	for t in tasks:
		var marker := t.target_node().get_node_or_null("Marker")
		if marker:
			marker.visible = false

	var held: Node = player.held if player else null
	for t in tasks:
		if state_of(t) != State.AVAILABLE:
			continue
		var needs_item := t.kind == Task.Kind.PLACE or t.kind == Task.Kind.WATER
		if held:
			if not (needs_item and held == t._item):
				continue
		elif needs_item:
			continue
		_highlight(t.target_node())

	if hud:
		var states: Array[int] = []
		for t in tasks:
			states.append(state_of(t))
		hud.set_states(states)


func _highlight(target: Node3D) -> void:
	var marker := target.get_node_or_null("Marker")
	if marker:
		marker.visible = true
	for m in target.find_children("*", "MeshInstance3D", true, false):
		if m.name == "Marker":
			continue
		m.material_overlay = glow
		glowing.append(m)
