extends SceneTree

const P := "../../Environment/Props/"

var root3d: Node3D


func _initialize() -> void:
	root3d = Node3D.new()
	root3d.name = "Lab2"

	var env: Node3D = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	env.name = "Environment"
	_add(root3d, env)

	_add_toy_box()
	_add_table_spot()
	_marker("ToyCarStart", Vector3(1.2, 0.0, 0.7), 40.0)
	_marker("TeacupStart", Vector3(2.2, 0.0, 0.5), 0.0)
	_marker("BottleHome", Vector3(-0.5, 0.45, -0.95), 0.0)
	_marker("SofaSeat", Vector3(0.0, 0.05, -3.0), 180.0)
	_add_effects()
	_add_tasks()

	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(load("res://scripts/hud.gd"))
	_add(root3d, hud)

	var packed := PackedScene.new()
	packed.pack(root3d)
	print("Saved lab2.tscn: ", error_string(ResourceSaver.save(packed, "res://scenes/lab2.tscn")))
	quit()


func _add(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root3d


func _marker(n: String, pos: Vector3, rot_y: float) -> Marker3D:
	var m := Marker3D.new()
	m.name = n
	m.position = pos
	m.rotation_degrees.y = rot_y
	_add(root3d, m)
	return m


func _material(a: Color, b: Color, uv: Vector3) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.04
	var grad := Gradient.new()
	grad.set_color(0, a)
	grad.set_color(1, b)
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.noise = noise
	tex.color_ramp = grad
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_scale = uv
	m.roughness = 0.7
	return m


func _box(parent: Node, n: String, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.name = n
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = mat
	mi.mesh = bm
	mi.position = pos
	_add(parent, mi)


func _add_toy_box() -> void:
	var body := StaticBody3D.new()
	body.name = "ToyBox"
	body.position = Vector3(-3.6, 0.0, 2.9)
	body.rotation_degrees.y = 20.0
	_add(root3d, body)
	var mat := _material(Color(0.15, 0.3, 0.6), Color(0.25, 0.45, 0.8), Vector3(2, 2, 1))
	var w := 0.6
	var d := 0.45
	var h := 0.35
	var t := 0.03
	_box(body, "Bottom", Vector3(w, t, d), Vector3(0, t / 2, 0), mat)
	_box(body, "Front", Vector3(w, h, t), Vector3(0, h / 2, d / 2 - t / 2), mat)
	_box(body, "Back", Vector3(w, h, t), Vector3(0, h / 2, -d / 2 + t / 2), mat)
	_box(body, "Left", Vector3(t, h, d), Vector3(-w / 2 + t / 2, h / 2, 0), mat)
	_box(body, "Right", Vector3(t, h, d), Vector3(w / 2 - t / 2, h / 2, 0), mat)
	var cs := CollisionShape3D.new()
	cs.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = Vector3(w, h, d)
	cs.shape = shape
	cs.position.y = h / 2
	_add(body, cs)
	var slot := Marker3D.new()
	slot.name = "Slot"
	slot.position = Vector3(0, t, 0)
	_add(body, slot)


func _add_table_spot() -> void:
	var area := Area3D.new()
	area.name = "TableSpot"
	area.position = Vector3(-0.45, 0.45, -1.35)
	_add(root3d, area)
	var cs := CollisionShape3D.new()
	cs.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.25, 0.12, 0.25)
	cs.shape = shape
	cs.position.y = 0.06
	_add(area, cs)
	var mi := MeshInstance3D.new()
	mi.name = "Marker"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.1
	cyl.bottom_radius = 0.1
	cyl.height = 0.004
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.85, 0.3, 0.6)
	cyl.material = mat
	mi.mesh = cyl
	mi.position.y = 0.003
	mi.visible = false
	_add(area, mi)


func _add_effects() -> void:
	var fx := Node3D.new()
	fx.name = "Effects"
	_add(root3d, fx)

	var lamp := SpotLight3D.new()
	lamp.name = "WallLampLight"
	lamp.position = Vector3(2.2, 2.08, -3.9)
	lamp.rotation_degrees = Vector3(-70.0, 180.0, 0.0)
	lamp.light_color = Color(1.0, 0.85, 0.6)
	lamp.light_energy = 4.0
	lamp.spot_range = 5.0
	lamp.spot_angle = 50.0
	lamp.shadow_enabled = true
	lamp.visible = false
	_add(fx, lamp)
	_bulb(lamp, 0.035)

	var lantern := OmniLight3D.new()
	lantern.name = "LanternLight"
	lantern.position = Vector3(4.3, 1.32, -2.97)
	lantern.light_color = Color(1.0, 0.75, 0.4)
	lantern.light_energy = 2.0
	lantern.omni_range = 3.0
	lantern.visible = false
	_add(fx, lantern)
	_bulb(lantern, 0.05)

	var speaker := AudioStreamPlayer3D.new()
	speaker.name = "Speaker"
	speaker.position = Vector3(1.9, 0.15, -3.4)
	speaker.set_script(load("res://scripts/music_box.gd"))
	_add(fx, speaker)


func _bulb(light: Light3D, radius: float) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Bulb"
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.9, 0.6)
	sphere.material = mat
	mi.mesh = sphere
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(light, mi)


func _add_tasks() -> void:
	var manager := Node.new()
	manager.name = "Tasks"
	manager.set_script(load("res://scripts/task_manager.gd"))
	_add(root3d, manager)

	var K = load("res://scripts/task.gd").Kind
	var list := [
		["TurnOnLamp", "Turn on the wall lamp", "Turn on lamp", K.SWITCH_ON, P + "AnisotropyBarnLamp", "", "../../Effects/WallLampLight", ""],
		["PickUpToyCar", "Pick up the toy car from the floor", "Pick up toy car", K.PICK_UP, P + "ToyCar", P + "ToyCar", "", "../../ToyCarStart"],
		["PutCarInBox", "Put the toy car in the toy box", "Put toy car in box", K.PLACE, "../../ToyBox", P + "ToyCar", "../../ToyBox/Slot", ""],
		["PickUpBottle", "Pick up the water bottle", "Pick up water bottle", K.PICK_UP, P + "WaterBottle", P + "WaterBottle", "", ""],
		["WaterPlant", "Water the plant", "Water the plant", K.WATER, P + "DiffuseTransmissionPlant", P + "WaterBottle", "../../BottleHome", ""],
		["PickUpTeacup", "Pick up the teacup from the floor", "Pick up teacup", K.PICK_UP, P + "DiffuseTransmissionTeacup", P + "DiffuseTransmissionTeacup", "", "../../TeacupStart"],
		["PutCupOnTable", "Put the teacup on the coffee table", "Put teacup here", K.PLACE, "../../TableSpot", P + "DiffuseTransmissionTeacup", "../../TableSpot", ""],
		["PlayMusic", "Turn on the boombox", "Turn on boombox", K.PLAY_MUSIC, P + "BoomBox", "", "../../Effects/Speaker", ""],
		["TurnOnLantern", "Turn on the street lantern", "Turn on lantern", K.SWITCH_ON, P + "Lantern", "", "../../Effects/LanternLight", ""],
		["SitDown", "Sit on the leather sofa", "Sit down", K.SIT, P + "SheenWoodLeatherSofa", "", "../../SofaSeat", ""],
	]
	for row in list:
		var t := Node.new()
		t.name = row[0]
		t.set_script(load("res://scripts/task.gd"))
		t.label = row[1]
		t.prompt = row[2]
		t.kind = row[3]
		t.target = NodePath(row[4])
		t.item = NodePath(row[5])
		t.effect = NodePath(row[6])
		t.start_at = NodePath(row[7])
		t.item_name = {"ToyCar": "toy car", "WaterBottle": "water bottle", "DiffuseTransmissionTeacup": "teacup"}.get(NodePath(row[5]).get_name(NodePath(row[5]).get_name_count() - 1) if row[5] != "" else "", "")
		_add(manager, t)
