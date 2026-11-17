extends SceneTree

const P := "../../Environment/Props/"
const SFX := "res://sounds/sfx/"
const AMB := "res://sounds/ambient/"

var root3d: Node3D


func _initialize() -> void:
	root3d = Node3D.new()
	root3d.name = "Lab3"

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
	_add_feedback()
	_add_ambience()
	_add_tasks()

	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(load("res://scripts/hud.gd"))
	_add(root3d, hud)

	var packed := PackedScene.new()
	packed.pack(root3d)
	print("Saved lab3.tscn: ", error_string(ResourceSaver.save(packed, "res://scenes/lab3.tscn")))
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
	lantern.set_script(load("res://scripts/flicker.gd"))
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
	manager.done_sound = load(SFX + "pluck_002.ogg")
	manager.error_sound = load(SFX + "dropLeather.ogg")
	_add(root3d, manager)

	var K = load("res://scripts/task.gd").Kind
	var list := [
		["TurnOnLamp", "Turn on the wall lamp", "Turn on lamp", K.SWITCH_ON, P + "AnisotropyBarnLamp", "", "../../Effects/WallLampLight", "", "switch_002.ogg", "", ""],
		["PickUpToyCar", "Pick up the toy car from the floor", "Pick up toy car", K.PICK_UP, P + "ToyCar", P + "ToyCar", "", "../../ToyCarStart", "cloth", "", ""],
		["PutCarInBox", "Put the toy car in the toy box", "Put toy car in box", K.PLACE, "../../ToyBox", P + "ToyCar", "../../ToyBox/Slot", "", "impactWood_medium_000.ogg", "../../Feedback/DustPuff", ""],
		["PickUpBottle", "Pick up the water bottle", "Pick up water bottle", K.PICK_UP, P + "WaterBottle", P + "WaterBottle", "", "", "cloth", "", ""],
		["WaterPlant", "Water the plant", "Water the plant", K.WATER, P + "DiffuseTransmissionPlant", P + "WaterBottle", "../../BottleHome", "", "water_pouring.mp3", "../../Feedback/WaterDrops", ""],
		["PickUpTeacup", "Pick up the teacup from the floor", "Pick up teacup", K.PICK_UP, P + "DiffuseTransmissionTeacup", P + "DiffuseTransmissionTeacup", "", "../../TeacupStart", "cloth", "", ""],
		["PutCupOnTable", "Put the teacup on the coffee table", "Put teacup here", K.PLACE, "../../TableSpot", P + "DiffuseTransmissionTeacup", "../../TableSpot", "", "impactPlate_light_000.ogg", "../../Feedback/TableSparkle", ""],
		["PlayMusic", "Turn on the boombox", "Turn on boombox", K.PLAY_MUSIC, P + "BoomBox", "", "../../Effects/Speaker", "", "toggle_001.ogg", "", "../../Feedback/MusicNotes"],
		["TurnOnLantern", "Turn on the street lantern", "Turn on lantern", K.SWITCH_ON, P + "Lantern", "", "../../Effects/LanternLight", "", "switch_002.ogg", "", "../../Feedback/Embers"],
		["SitDown", "Sit on the leather sofa", "Sit down", K.SIT, P + "SheenWoodLeatherSofa", "", "../../SofaSeat", "", "impactSoft_medium_000.ogg", "../../Feedback/CushionPuff", ""],
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
		t.sound = _cloth_sound() if row[8] == "cloth" else load(SFX + row[8])
		t.burst = NodePath(row[9])
		t.starts = NodePath(row[10])
		t.item_name = {"ToyCar": "toy car", "WaterBottle": "water bottle", "DiffuseTransmissionTeacup": "teacup"}.get(NodePath(row[5]).get_name(NodePath(row[5]).get_name_count() - 1) if row[5] != "" else "", "")
		_add(manager, t)


func _soft_dot() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	return tex


func _note_texture() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 64:
		for x in 64:
			var dx := (x - 22) / 12.0
			var dy := (y - 48) / 8.5
			var rx := dx * cos(0.4) + dy * sin(0.4)
			var ry := -dx * sin(0.4) + dy * cos(0.4)
			var head := rx * rx + ry * ry <= 1.0
			var stem := x >= 31 and x <= 35 and y >= 8 and y <= 46
			var flag := y >= 8 and y <= 24 and x >= 35 and x <= 35 + int((24 - y) * 0.9) + 3 and x <= 52
			if head or stem or flag:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)


func _particle_mat(tex: Texture2D, billboard := BaseMaterial3D.BILLBOARD_PARTICLES) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = billboard
	m.albedo_texture = tex
	return m


func _fade(c: Color, fade_in := 0.1) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, fade_in, 1.0])
	g.colors = PackedColorArray([Color(c, 0.0), c, Color(c, 0.0)])
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


func _particles(parent: Node, n: String, pos: Vector3, amount: int, lifetime: float, size: float, tex: Texture2D, color: Color, setup: Callable, one_shot := false) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = n
	p.position = pos
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = one_shot
	p.emitting = not one_shot
	if one_shot:
		p.explosiveness = 0.9
	var pm := ParticleProcessMaterial.new()
	pm.color_ramp = _fade(color)
	pm.gravity = Vector3.ZERO
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	quad.material = _particle_mat(tex)
	p.draw_pass_1 = quad
	setup.call(pm, p)
	p.process_material = pm
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-6, -4, -6), Vector3(12, 8, 12))
	_add(parent, p)
	return p


func _add_feedback() -> void:
	var fb := Node3D.new()
	fb.name = "Feedback"
	_add(root3d, fb)
	var dot := _soft_dot()

	_particles(fb, "DustPuff", Vector3(-3.6, 0.3, 2.9), 24, 0.9, 0.12, dot, Color(0.75, 0.7, 0.6, 0.6), func(pm: ParticleProcessMaterial, _p):
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(0.25, 0.02, 0.2)
		pm.direction = Vector3(0, 1, 0)
		pm.spread = 70.0
		pm.initial_velocity_min = 0.3
		pm.initial_velocity_max = 0.7
		pm.damping_min = 1.0
		pm.damping_max = 2.0
		pm.scale_min = 0.6
		pm.scale_max = 1.6, true)

	_particles(fb, "WaterDrops", Vector3(-4.3, 0.8, -3.4), 70, 0.9, 0.05, dot, Color(0.55, 0.75, 1.0, 1.0), func(pm: ParticleProcessMaterial, p: GPUParticles3D):
		p.explosiveness = 0.0
		pm.direction = Vector3(0, -1, 0)
		pm.spread = 12.0
		pm.initial_velocity_min = 0.3
		pm.initial_velocity_max = 0.6
		pm.gravity = Vector3(0, -6.0, 0), true)

	_particles(fb, "TableSparkle", Vector3(-0.45, 0.5, -1.35), 14, 0.7, 0.04, dot, Color(1.0, 0.95, 0.7, 1.0), func(pm: ParticleProcessMaterial, _p):
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 0.08
		pm.direction = Vector3(0, 1, 0)
		pm.spread = 60.0
		pm.initial_velocity_min = 0.2
		pm.initial_velocity_max = 0.4, true)

	_particles(fb, "CushionPuff", Vector3(0.0, 0.5, -3.0), 20, 0.8, 0.1, dot, Color(0.8, 0.75, 0.65, 0.45), func(pm: ParticleProcessMaterial, _p):
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(0.4, 0.02, 0.2)
		pm.direction = Vector3(0, 1, 0)
		pm.spread = 80.0
		pm.initial_velocity_min = 0.2
		pm.initial_velocity_max = 0.5
		pm.damping_min = 0.8
		pm.damping_max = 1.5, true)

	var notes := _particles(fb, "MusicNotes", Vector3(1.9, 0.35, -3.4), 6, 2.5, 0.17, _note_texture(), Color(1.0, 0.85, 0.4, 1.0), func(pm: ParticleProcessMaterial, _p):
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 0.12
		pm.direction = Vector3(0, 1, 0)
		pm.spread = 25.0
		pm.initial_velocity_min = 0.25
		pm.initial_velocity_max = 0.4
		pm.angle_min = -20.0
		pm.angle_max = 20.0
		pm.scale_min = 0.8
		pm.scale_max = 1.3)
	notes.emitting = false

	var embers := _particles(fb, "Embers", Vector3(4.3, 1.53, -2.97), 18, 1.6, 0.07, dot, Color(1.0, 0.6, 0.25, 1.0), func(pm: ParticleProcessMaterial, p: GPUParticles3D):
		p.draw_pass_1.material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 0.04
		pm.direction = Vector3(0, 1, 0)
		pm.spread = 20.0
		pm.initial_velocity_min = 0.1
		pm.initial_velocity_max = 0.25
		pm.angular_velocity_min = -90.0
		pm.angular_velocity_max = 90.0
		pm.gravity = Vector3(0, 0.15, 0))
	embers.emitting = false


func _add_ambience() -> void:
	var amb := Node3D.new()
	amb.name = "Ambience"
	_add(root3d, amb)
	var dot := _soft_dot()

	_particles(amb, "DustMotes", Vector3(0, 1.4, 0), 220, 14.0, 0.025, dot, Color(1.0, 0.95, 0.85, 0.35), func(pm: ParticleProcessMaterial, p: GPUParticles3D):
		p.preprocess = 14.0
		p.draw_pass_1.material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(4.6, 1.3, 3.7)
		pm.direction = Vector3(0, 1, 0)
		pm.spread = 180.0
		pm.initial_velocity_min = 0.01
		pm.initial_velocity_max = 0.04
		pm.scale_min = 0.6
		pm.scale_max = 1.4)

	var steam := _particles(amb, "TeaSteam", Vector3.ZERO, 18, 2.4, 0.1, dot, Color(1, 1, 1, 0.4), func(pm: ParticleProcessMaterial, p: GPUParticles3D):
		p.preprocess = 2.4
		p.local_coords = false
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 0.025
		pm.direction = Vector3(0, 1, 0)
		pm.spread = 10.0
		pm.initial_velocity_min = 0.06
		pm.initial_velocity_max = 0.1
		pm.spread = 18.0
		var grow := Curve.new()
		grow.add_point(Vector2(0, 0.4))
		grow.add_point(Vector2(1, 1.6))
		var ct := CurveTexture.new()
		ct.curve = grow
		pm.scale_curve = ct)
	steam.set_script(load("res://scripts/follow.gd"))
	steam.target = NodePath("../../Environment/Props/DiffuseTransmissionTeacup")
	steam.offset = Vector3(0, 0.07, 0)

	var rain_tex := GradientTexture2D.new()
	var rg := Gradient.new()
	rg.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	rg.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	rain_tex.gradient = rg
	rain_tex.width = 8
	rain_tex.height = 8
	var rain := GPUParticles3D.new()
	rain.name = "Rain"
	rain.position = Vector3(6.2, 3.2, 0.5)
	rain.amount = 700
	rain.lifetime = 0.45
	rain.preprocess = 1.0
	var rpm := ParticleProcessMaterial.new()
	rpm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	rpm.emission_box_extents = Vector3(0.9, 0.1, 2.2)
	rpm.direction = Vector3(-0.05, -1, 0)
	rpm.spread = 2.0
	rpm.initial_velocity_min = 7.0
	rpm.initial_velocity_max = 9.0
	rpm.gravity = Vector3(0, -2, 0)
	rpm.color = Color(0.75, 0.8, 0.9, 0.45)
	rain.process_material = rpm
	var streak := QuadMesh.new()
	streak.size = Vector2(0.012, 0.35)
	streak.material = _particle_mat(rain_tex, BaseMaterial3D.BILLBOARD_FIXED_Y)
	rain.draw_pass_1 = streak
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rain.visibility_aabb = AABB(Vector3(-2, -5, -3), Vector3(4, 6, 6))
	_add(amb, rain)

	var rain_audio := AudioStreamPlayer3D.new()
	rain_audio.name = "RainSound"
	rain_audio.position = Vector3(5.2, 1.5, 0.5)
	rain_audio.stream = load(AMB + "rain_window.mp3")
	rain_audio.unit_size = 5.0
	rain_audio.volume_db = -4.0
	rain_audio.autoplay = true
	rain_audio.set_script(load("res://scripts/loop_audio.gd"))
	_add(amb, rain_audio)

	var flash := OmniLight3D.new()
	flash.name = "LightningFlash"
	flash.position = Vector3(6.6, 2.2, 0.5)
	flash.light_color = Color(0.8, 0.85, 1.0)
	flash.light_energy = 0.0
	flash.omni_range = 9.0
	flash.shadow_enabled = true
	_add(amb, flash)
	var thunder := AudioStreamPlayer.new()
	thunder.name = "Thunder"
	thunder.stream = load(AMB + "thunder.mp3")
	thunder.volume_db = -5.0
	_add(amb, thunder)
	var weather := Node3D.new()
	weather.name = "Weather"
	weather.set_script(load("res://scripts/weather.gd"))
	weather.flash_light = NodePath("../LightningFlash")
	weather.night_sky = NodePath("../../Environment/Room/Outside/NightSky")
	weather.thunder = NodePath("../Thunder")
	_add(amb, weather)

	_add_clock(amb)

	var hum := AudioStreamPlayer.new()
	hum.name = "RoomHum"
	hum.volume_db = -28.0
	hum.set_script(load("res://scripts/room_hum.gd"))
	_add(amb, hum)


func _add_clock(parent: Node3D) -> void:
	var clock := Node3D.new()
	clock.name = "WallClock"
	clock.position = Vector3(-4.97, 2.0, -0.3)
	clock.rotation_degrees.y = 90.0
	clock.set_script(load("res://scripts/clock.gd"))
	_add(parent, clock)
	var face_mat := StandardMaterial3D.new()
	face_mat.albedo_color = Color(0.95, 0.93, 0.88)
	face_mat.roughness = 0.6
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.1, 0.09)
	dark.roughness = 0.4
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(0.75, 0.1, 0.08)

	var face := MeshInstance3D.new()
	face.name = "Face"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.22
	cyl.height = 0.03
	cyl.material = face_mat
	face.mesh = cyl
	face.rotation_degrees.x = 90.0
	face.position.z = 0.015
	_add(clock, face)
	var rim := MeshInstance3D.new()
	rim.name = "Rim"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.215
	torus.outer_radius = 0.245
	torus.material = dark
	rim.mesh = torus
	rim.rotation_degrees.x = 90.0
	rim.position.z = 0.03
	_add(clock, rim)
	for i in 12:
		var a := TAU * i / 12.0
		var tick := MeshInstance3D.new()
		tick.name = "Mark%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(0.012, 0.04 if i % 3 == 0 else 0.025, 0.004)
		bm.material = dark
		tick.mesh = bm
		tick.position = Vector3(sin(a) * 0.18, cos(a) * 0.18, 0.033)
		tick.rotation.z = -a
		_add(clock, tick)
	_hand(clock, "HourHand", 0.11, 0.018, dark, 0.036)
	_hand(clock, "MinuteHand", 0.16, 0.012, dark, 0.04)
	_hand(clock, "SecondHand", 0.17, 0.005, red, 0.044)

	var tick_audio := AudioStreamPlayer3D.new()
	tick_audio.name = "TickSound"
	tick_audio.stream = load(AMB + "clock_ticking.mp3")
	tick_audio.unit_size = 1.5
	tick_audio.volume_db = -6.0
	tick_audio.autoplay = true
	tick_audio.set_script(load("res://scripts/loop_audio.gd"))
	_add(clock, tick_audio)


func _hand(clock: Node3D, n: String, length: float, width: float, mat: Material, z: float) -> void:
	var pivot := Node3D.new()
	pivot.name = n
	pivot.position.z = z
	_add(clock, pivot)
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var bm := BoxMesh.new()
	bm.size = Vector3(width, length, 0.004)
	bm.material = mat
	mi.mesh = bm
	mi.position.y = length / 2 - 0.02
	_add(pivot, mi)


func _cloth_sound() -> AudioStreamRandomizer:
	var r := AudioStreamRandomizer.new()
	for i in range(1, 5):
		r.add_stream(-1, load(SFX + "cloth%d.ogg" % i))
	r.random_pitch = 1.1
	r.random_volume_offset_db = 2.0
	return r
