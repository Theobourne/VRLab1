extends SceneTree
## Generates res://scenes/main.tscn: a textured room, 13 unique props with
## collision shapes, lighting and a first-person player.
## Run from the project folder:  godot --headless --script res://tools/build_scene.gd
## (You don't need to run this again unless you want to regenerate the scene.)

# [file, position, y-rotation (deg), target height (0 = keep original size), collision type]
const PROPS := [
	["SheenWoodLeatherSofa",      Vector3( 0.0, 0.0, -3.3),   0.0, 0.0,  "trimesh"],
	["GlamVelvetSofa",            Vector3(-4.2, 0.0, -0.3),  90.0, 0.0,  "trimesh"],
	["SheenChair",                Vector3( 3.0, 0.0, -0.6), -110.0, 0.0, "convex"],
	["DiffuseTransmissionPlant",  Vector3(-4.3, 0.0, -3.4),   0.0, 0.0,  "convex"],
	["Lantern",                   Vector3( 4.3, 0.0, -3.4), -90.0, 1.9,  "trimesh"],
	["AntiqueCamera",             Vector3( 3.6, 0.0,  2.6), -135.0, 1.5, "trimesh"],
	["BoomBox",                   Vector3( 1.9, 0.0, -3.4), -15.0, 0.3,  "convex"],
	["AnisotropyBarnLamp",        Vector3( 2.2, 2.0, -3.95),  0.0, 0.5,  "convex"],
	# small items on the coffee table (table top is at y = 0.45)
	["IridescentDishWithOlives",  Vector3( 0.0, 0.45, -1.25),  0.0, 0.0, "convex"],
	["DiffuseTransmissionTeacup", Vector3(-0.45, 0.45, -1.35), 0.0, 0.0, "convex"],
	["GlassVaseFlowers",          Vector3( 0.5, 0.45, -1.0),   0.0, 0.0, "convex"],
	["ToyCar",                    Vector3( 0.45, 0.45, -1.45), 30.0, 0.06, "convex"],
	["WaterBottle",               Vector3(-0.5, 0.45, -0.95),  0.0, 0.0, "convex"],
]

const ROOM_W := 10.0   # x
const ROOM_D := 8.0    # z
const WALL_H := 2.8

var root3d: Node3D


func _initialize() -> void:
	root3d = Node3D.new()
	root3d.name = "Main"
	_add_environment()
	_add_room()
	_add_table()
	var props := Node3D.new()
	props.name = "Props"
	_add(root3d, props)
	for p in PROPS:
		_add_prop(props, p[0], p[1], p[2], p[3], p[4])
	_add_player()

	var packed := PackedScene.new()
	var err := packed.pack(root3d)
	assert(err == OK)
	err = ResourceSaver.save(packed, "res://scenes/main.tscn")
	print("Saved main.tscn: ", error_string(err))
	quit()


func _add(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root3d


# ---------------------------------------------------------------- props
func _add_prop(parent: Node3D, file: String, pos: Vector3, rot_deg: float, target_h: float, col: String) -> void:
	var scene: PackedScene = load("res://models/%s.glb" % file)
	var model: Node3D = scene.instantiate()

	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	var box := AABB()
	for i in meshes.size():
		var b: AABB = _rel_xform(meshes[i], model) * meshes[i].get_aabb()
		box = b if i == 0 else box.merge(b)

	var s := 1.0 if target_h <= 0.0 else target_h / box.size.y
	# centre the model on x/z and put its bottom on the ground
	var offset := Vector3(-(box.position.x + box.size.x * 0.5), -box.position.y, -(box.position.z + box.size.z * 0.5)) * s

	var body := StaticBody3D.new()
	body.name = file
	body.position = pos
	body.rotation_degrees.y = rot_deg
	_add(parent, body)

	model.name = "Model"
	model.scale = Vector3.ONE * s
	model.position = offset
	body.add_child(model)
	model.owner = root3d

	# One collision shape per mesh, with the scale baked into the points
	# (physics bodies/shapes shouldn't be scaled in Godot 4).
	var model_xf := Transform3D(Basis.from_scale(Vector3.ONE * s), offset)
	for i in meshes.size():
		var mi: MeshInstance3D = meshes[i]
		var xf: Transform3D = model_xf * _rel_xform(mi, model)
		var cs := CollisionShape3D.new()
		cs.name = "Collision%d" % i
		if col == "trimesh":
			var tri: ConcavePolygonShape3D = mi.mesh.create_trimesh_shape()
			var faces := tri.get_faces()
			for k in faces.size():
				faces[k] = xf * faces[k]
			tri.set_faces(faces)
			cs.shape = tri
		else:
			var cvx: ConvexPolygonShape3D = mi.mesh.create_convex_shape(true, true)
			var pts := cvx.points
			for k in pts.size():
				pts[k] = xf * pts[k]
			cvx.points = pts
			cs.shape = cvx
		_add(body, cs)
	print("  %-26s scale %.3f  meshes %d  collision %s" % [file, s, meshes.size(), col])


func _rel_xform(n: Node, stop_at: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	var p := n
	while p != null and p != stop_at:
		if p is Node3D:
			t = p.transform * t
		p = p.get_parent()
	return t


# ---------------------------------------------------------------- room
func _noise_tex(freq: float, col_a: Color, col_b: Color, seamless := true) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.frequency = freq
	noise.fractal_octaves = 4
	var grad := Gradient.new()
	grad.set_color(0, col_a)
	grad.set_color(1, col_b)
	var tex := NoiseTexture2D.new()
	tex.width = 512
	tex.height = 512
	tex.seamless = seamless
	tex.noise = noise
	tex.color_ramp = grad
	return tex


func _material(tex: Texture2D, uv: Vector3, rough := 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_scale = uv
	m.roughness = rough
	return m


func _box_body(parent: Node, name: String, size: Vector3, pos: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos
	_add(parent, body)
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = mat
	mi.mesh = bm
	_add(body, mi)
	var cs := CollisionShape3D.new()
	cs.name = "Collision"
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	_add(body, cs)


func _add_room() -> void:
	var room := Node3D.new()
	room.name = "Room"
	_add(root3d, room)
	# wood-like floor: stretched noise
	var floor_tex := _noise_tex(0.02, Color(0.36, 0.23, 0.13), Color(0.55, 0.37, 0.22))
	var floor_mat := _material(floor_tex, Vector3(2, 12, 1), 0.6)
	_box_body(room, "Floor", Vector3(ROOM_W, 0.2, ROOM_D), Vector3(0, -0.1, 0), floor_mat)

	var wall_tex := _noise_tex(0.05, Color(0.80, 0.77, 0.70), Color(0.90, 0.88, 0.82))
	var wall_mat := _material(wall_tex, Vector3(4, 2, 1), 0.95)
	var t := 0.2
	_box_body(room, "WallBack",  Vector3(ROOM_W, WALL_H, t), Vector3(0, WALL_H / 2, -ROOM_D / 2 - t / 2), wall_mat)
	_box_body(room, "WallFront", Vector3(ROOM_W, WALL_H, t), Vector3(0, WALL_H / 2,  ROOM_D / 2 + t / 2), wall_mat)
	_box_body(room, "WallLeft",  Vector3(t, WALL_H, ROOM_D), Vector3(-ROOM_W / 2 - t / 2, WALL_H / 2, 0), wall_mat)
	_box_body(room, "WallRight", Vector3(t, WALL_H, ROOM_D), Vector3( ROOM_W / 2 + t / 2, WALL_H / 2, 0), wall_mat)

	# rug
	var rug_tex := _noise_tex(0.08, Color(0.45, 0.12, 0.12), Color(0.70, 0.35, 0.20))
	_box_body(room, "Rug", Vector3(3.2, 0.01, 2.2), Vector3(0, 0.005, -1.3), _material(rug_tex, Vector3(1, 1, 1), 1.0))


func _add_table() -> void:
	var table := Node3D.new()
	table.name = "CoffeeTable"
	table.position = Vector3(0, 0, -1.2)
	_add(root3d, table)
	var wood := _material(_noise_tex(0.03, Color(0.25, 0.15, 0.08), Color(0.42, 0.27, 0.15)), Vector3(1, 4, 1), 0.5)
	_box_body(table, "Top", Vector3(1.4, 0.05, 0.8), Vector3(0, 0.425, 0), wood)
	for x in [-0.62, 0.62]:
		for z in [-0.32, 0.32]:
			_box_body(table, "Leg", Vector3(0.06, 0.4, 0.06), Vector3(x, 0.2, z), wood)


# ---------------------------------------------------------------- lights, sky, player
func _add_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.ambient_light_energy = 0.6
	env.tonemap_exposure = 0.85
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	_add(root3d, we)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.shadow_enabled = true
	sun.light_energy = 0.6
	_add(root3d, sun)

	var lamp := OmniLight3D.new()
	lamp.name = "RoomLight"
	lamp.position = Vector3(0, 2.4, -0.5)
	lamp.omni_range = 8.0
	lamp.light_energy = 0.5
	lamp.light_color = Color(1.0, 0.9, 0.75)
	lamp.shadow_enabled = true
	_add(root3d, lamp)


func _add_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 0.1, 2.8)
	player.set_script(load("res://scripts/player.gd"))
	_add(root3d, player)

	var cs := CollisionShape3D.new()
	cs.name = "Collision"
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.7
	cs.shape = cap
	cs.position.y = 0.85
	_add(player, cs)

	var head := Node3D.new()
	head.name = "Head"
	head.position.y = 1.6
	_add(player, head)

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.current = true
	_add(head, cam)
