extends CanvasLayer

const DONE_COLOR := Color(0.55, 0.9, 0.55)
const TODO_COLOR := Color(1, 1, 1, 0.9)
const LOCKED_COLOR := Color(1, 1, 1, 0.4)

var rows: Array[Label] = []
var labels: Array[String] = []
var title: Label
var prompt: Label
var hint: Label
var intro: Control
var start_time := 0
var end_shown := false
var hint_tween: Tween


func _ready() -> void:
	add_to_group("hud")

	var dot := ColorRect.new()
	dot.color = Color(1, 1, 1, 0.8)
	dot.size = Vector2(6, 6)
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.position -= Vector2(3, 3)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dot)

	prompt = _centered_label(40, 22)
	hint = _centered_label(80, 18)
	hint.modulate = Color(1, 0.6, 0.5)

	start_time = Time.get_ticks_msec()
	intro = _popup("Get the room ready", "Friends are coming over – tidy up and get the living room ready.", "")
	var tw := create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(intro, "modulate:a", 0.0, 0.8)
	tw.tween_callback(intro.queue_free)


func setup(task_labels: Array[String]) -> void:
	labels = task_labels
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 20)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.55)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	if is_instance_valid(intro):
		move_child(intro, -1)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	title = Label.new()
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	box.add_child(HSeparator.new())
	for l in labels:
		var row := Label.new()
		row.add_theme_font_size_override("font_size", 16)
		box.add_child(row)
		rows.append(row)


func set_states(states: Array[int]) -> void:
	if rows.is_empty():
		return
	var total := rows.size()
	var done := states.count(0)
	if done >= total:
		title.text = "All done!   %d / %d   –   press R to restart" % [total, total]
		title.add_theme_color_override("font_color", DONE_COLOR)
		if not end_shown:
			end_shown = true
			get_tree().create_timer(1.2).timeout.connect(_show_end)
	else:
		title.text = "Get the room ready      %d / %d" % [done, total]
	for i in total:
		var row := rows[i]
		match states[i]:
			0:
				row.text = "✓  " + labels[i]
				row.add_theme_color_override("font_color", DONE_COLOR)
			1:
				row.text = "•  " + labels[i]
				row.add_theme_color_override("font_color", TODO_COLOR)
			_:
				row.text = "•  " + labels[i] + "  (last)"
				row.add_theme_color_override("font_color", LOCKED_COLOR)


func show_prompt(text: String) -> void:
	prompt.text = text


func show_hint(text: String) -> void:
	hint.text = text
	hint.modulate.a = 1.0
	if hint_tween:
		hint_tween.kill()
	hint_tween = create_tween()
	hint_tween.tween_interval(1.5)
	hint_tween.tween_property(hint, "modulate:a", 0.0, 0.5)


func _centered_label(offset_y: float, size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_constant_override("outline_size", 5)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.position.y += offset_y
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _show_end() -> void:
	var secs := (Time.get_ticks_msec() - start_time) / 1000
	var popup := _popup("All done!", "The living room is ready for your friends.\nTime: %d:%02d" % [secs / 60, secs % 60], "Press R to play again")
	popup.modulate.a = 0.0
	create_tween().tween_property(popup, "modulate:a", 1.0, 0.8)
	var notes := ["res://sounds/sfx/pluck_001.ogg", "res://sounds/sfx/pluck_002.ogg"]
	for i in notes.size():
		if not ResourceLoader.exists(notes[i]):
			continue
		var p := AudioStreamPlayer.new()
		p.stream = load(notes[i])
		p.volume_db = -8.0
		p.pitch_scale = 0.85
		add_child(p)
		get_tree().create_timer(0.25 * i).timeout.connect(p.play)


func _popup(heading: String, body: String, footer: String) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.08, 0.92)
	style.border_color = Color(0.85, 0.7, 0.45)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 48
	style.content_margin_right = 48
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	for part in [[heading, 44, Color(1.0, 0.88, 0.6)], [body, 20, Color(1, 1, 1, 0.9)], [footer, 16, Color(1, 1, 1, 0.6)]]:
		if part[0] == "":
			continue
		var l := Label.new()
		l.text = part[0]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", part[1])
		l.add_theme_color_override("font_color", part[2])
		box.add_child(l)
	return root
