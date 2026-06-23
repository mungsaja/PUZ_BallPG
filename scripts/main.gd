extends Node3D

const BOARD_WIDTH := 10.0
const BOARD_HEIGHT := 17.78
const FRAME_WIDTH := BOARD_WIDTH + 1.6
const FRAME_HEIGHT := BOARD_HEIGHT + 1.6
const CAMERA_TILT_DEG := -63.0
const CAMERA_FOV_DEG := 46.0
const CAMERA_PADDING := 1.08
const BOARD_TOP := -8.2
const BOARD_BOTTOM := 8.0
const SHOOT_Z := 6.55
const PARTY_Z := 7.45
const BALL_RADIUS := 0.18
const BALL_SPEED := 12.0
const BLOCK_SIZE := Vector2(1.18, 0.82)
const AIM_DOTS := 10
const PARTY_IDLE_X := [-1.45, 0.0, 1.45]
const LEVEL_DROP := 1.28
const SPAWN_ROW_Z := -6.95
const DANGER_Z := 5.25
const ROW_X := [-3.75, -2.25, -0.75, 0.75, 2.25, 3.75]

const BLOCK_DATA := [
	{"pos": Vector2(-3.75, -6.8), "hp": 5, "rank": "circle", "icon": 0},
	{"pos": Vector2(-2.25, -6.8), "hp": 5, "rank": "circle", "icon": 6},
	{"pos": Vector2(-0.75, -6.8), "hp": 5, "rank": "circle", "icon": 0},
	{"pos": Vector2(0.75, -6.8), "hp": 5, "rank": "circle", "icon": 6},
	{"pos": Vector2(2.25, -6.8), "hp": 5, "rank": "circle", "icon": 0},
	{"pos": Vector2(3.75, -6.8), "hp": 5, "rank": "circle", "icon": 6},
	{"pos": Vector2(-3.75, -5.55), "hp": 12, "rank": "square", "icon": 1},
	{"pos": Vector2(-2.25, -5.55), "hp": 20, "rank": "triangle", "icon": 2},
	{"pos": Vector2(-0.75, -5.55), "hp": 20, "rank": "triangle", "icon": 2},
	{"pos": Vector2(0.75, -5.55), "hp": 55, "rank": "chest", "icon": 3},
	{"pos": Vector2(2.25, -5.55), "hp": 20, "rank": "triangle", "icon": 2},
	{"pos": Vector2(3.75, -5.55), "hp": 12, "rank": "square", "icon": 1},
	{"pos": Vector2(-3.0, -4.25), "hp": 333, "rank": "boss", "icon": 4},
	{"pos": Vector2(0.0, -4.25), "hp": 55, "rank": "diamond", "icon": 11},
	{"pos": Vector2(3.0, -4.25), "hp": 333, "rank": "boss", "icon": 4},
	{"pos": Vector2(-3.75, -2.95), "hp": 8, "rank": "square", "icon": 5},
	{"pos": Vector2(-2.25, -2.95), "hp": 8, "rank": "square", "icon": 5},
	{"pos": Vector2(-0.75, -2.95), "hp": 14, "rank": "diamond", "icon": 9},
	{"pos": Vector2(0.75, -2.95), "hp": 14, "rank": "diamond", "icon": 9},
	{"pos": Vector2(2.25, -2.95), "hp": 8, "rank": "square", "icon": 5},
	{"pos": Vector2(3.75, -2.95), "hp": 8, "rank": "square", "icon": 5},
	{"pos": Vector2(-3.0, -1.65), "hp": 3, "rank": "circle", "icon": 6},
	{"pos": Vector2(-1.5, -1.65), "hp": 6, "rank": "square", "icon": 0},
	{"pos": Vector2(0.0, -1.65), "hp": 100, "rank": "diamond", "icon": 7},
	{"pos": Vector2(1.5, -1.65), "hp": 6, "rank": "square", "icon": 0},
	{"pos": Vector2(3.0, -1.65), "hp": 3, "rank": "circle", "icon": 6},
]

var party := [
	{"name": "Aria", "class": "Mage", "color": Color("#5869ff")},
	{"name": "Bram", "class": "Knight", "color": Color("#d2a15d")},
	{"name": "Nia", "class": "Rogue", "color": Color("#5ed083")},
]

var blocks: Array[Dictionary] = []
var balls: Array[Dictionary] = []
var shooter_x := 0.0
var aiming := true
var shots_left := 9
var score := 2057
var combo := 0
var active_party := 0
var level := 1
var game_over := false

var camera_3d: Camera3D
var ball_mesh: MeshInstance3D
var aim_markers: Array[MeshInstance3D] = []
var party_nodes: Array[Node3D] = []
var score_label: Label
var shots_label: Label
var combo_label: Label
var party_label: Label
var status_label: Label
var icon_texture: Texture2D


func _ready() -> void:
	icon_texture = load("res://assets/generated/quest_icons.png")
	_setup_world()
	_spawn_blocks()
	_setup_ui()
	_create_party_pawns()
	_update_responsive_layout()
	_reset_ball()


func _process(delta: float) -> void:
	_update_shooter_from_input()
	_update_aim_line()
	_update_balls(delta)
	_update_party_visuals()
	_update_ui()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_update_responsive_layout()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_fire_at_screen_point(event.position)
		get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch and event.pressed:
		_fire_at_screen_point(event.position)
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_accept"):
		_fire_toward(Vector2(0.0, -1.0))
	if event.is_action_pressed("ui_cancel"):
		_restart_board()


func _setup_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#150f0c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#f7d59a")
	env.ambient_light_energy = 0.55
	environment.environment = env
	add_child(environment)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-58.0, -18.0, 0.0)
	light.light_energy = 2.2
	add_child(light)

	camera_3d = Camera3D.new()
	camera_3d.name = "Camera"
	camera_3d.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera_3d.fov = CAMERA_FOV_DEG
	camera_3d.rotation_degrees = Vector3(CAMERA_TILT_DEG, 0.0, 0.0)
	add_child(camera_3d)
	camera_3d.current = true

	_create_3d_board_map()

	for i in range(AIM_DOTS):
		var marker := MeshInstance3D.new()
		marker.name = "AimDot_%02d" % i
		var dot_mesh := SphereMesh.new()
		dot_mesh.radius = 0.07
		dot_mesh.height = 0.14
		marker.mesh = dot_mesh
		var dot_mat := StandardMaterial3D.new()
		dot_mat.albedo_color = Color("#ffd45a")
		dot_mat.emission_enabled = true
		dot_mat.emission = Color("#ffba35")
		dot_mat.emission_energy_multiplier = 1.4
		marker.material_override = dot_mat
		add_child(marker)
		aim_markers.append(marker)

	ball_mesh = MeshInstance3D.new()
	ball_mesh.name = "Ball"
	var sphere := SphereMesh.new()
	sphere.radius = BALL_RADIUS
	sphere.height = BALL_RADIUS * 2.0
	ball_mesh.mesh = sphere
	var ball_mat := StandardMaterial3D.new()
	ball_mat.albedo_color = Color("#40b8ff")
	ball_mat.emission_enabled = true
	ball_mat.emission = Color("#1c72ff")
	ball_mat.emission_energy_multiplier = 0.7
	ball_mesh.material_override = ball_mat
	add_child(ball_mesh)


func _create_3d_board_map() -> void:
	var map_root := Node3D.new()
	map_root.name = "BoardGameTable3D"
	add_child(map_root)

	var base := _make_box_node(
		"WoodenTrayBase",
		Vector3(BOARD_WIDTH + 1.2, 0.42, BOARD_HEIGHT + 1.1),
		Vector3(0.0, -0.42, 0.0),
		Color("#3b2418")
	)
	map_root.add_child(base)

	var tile_cols := 8
	var tile_rows := 13
	var tile_w := BOARD_WIDTH / float(tile_cols)
	var tile_h := BOARD_HEIGHT / float(tile_rows)
	for row in range(tile_rows):
		for col in range(tile_cols):
			var x := -BOARD_WIDTH * 0.5 + tile_w * (float(col) + 0.5)
			var z := -BOARD_HEIGHT * 0.5 + tile_h * (float(row) + 0.5)
			var tile_color := Color("#5d4a3a").lightened(0.04) if (row + col) % 2 == 0 else Color("#5d4a3a").darkened(0.035)
			var tile := _make_box_node(
				"StoneTile_%02d_%02d" % [row, col],
				Vector3(tile_w - 0.045, 0.08, tile_h - 0.045),
				Vector3(x, -0.16, z),
				tile_color
			)
			map_root.add_child(tile)

	var rail_color := Color("#6b3f22")
	map_root.add_child(_make_box_node("LeftWoodRail", Vector3(0.48, 0.72, BOARD_HEIGHT + 1.25), Vector3(-BOARD_WIDTH * 0.5 - 0.48, 0.06, 0.0), rail_color))
	map_root.add_child(_make_box_node("RightWoodRail", Vector3(0.48, 0.72, BOARD_HEIGHT + 1.25), Vector3(BOARD_WIDTH * 0.5 + 0.48, 0.06, 0.0), rail_color))
	map_root.add_child(_make_box_node("TopWoodRail", Vector3(BOARD_WIDTH + 1.45, 0.72, 0.5), Vector3(0.0, 0.06, BOARD_TOP - 0.48), rail_color.lightened(0.05)))
	map_root.add_child(_make_box_node("BottomWoodRail", Vector3(BOARD_WIDTH + 1.45, 0.72, 0.5), Vector3(0.0, 0.06, BOARD_BOTTOM + 0.48), rail_color.lightened(0.05)))

	var metal_color := Color("#b77934")
	for corner in [
		Vector2(-BOARD_WIDTH * 0.5 - 0.48, BOARD_TOP - 0.48),
		Vector2(BOARD_WIDTH * 0.5 + 0.48, BOARD_TOP - 0.48),
		Vector2(-BOARD_WIDTH * 0.5 - 0.48, BOARD_BOTTOM + 0.48),
		Vector2(BOARD_WIDTH * 0.5 + 0.48, BOARD_BOTTOM + 0.48),
	]:
		var cap := _make_cylinder_node("BrassCornerCap", 0.28, 0.16, Vector3(corner.x, 0.52, corner.y), metal_color)
		map_root.add_child(cap)

	for x in [-4.2, 4.2]:
		for z in [-6.9, 7.1]:
			var leaf := _make_cylinder_node("MossPatch", 0.18, 0.035, Vector3(x, 0.56, z), Color("#355f2b"))
			leaf.scale.x = 1.7
			leaf.scale.z = 0.7
			map_root.add_child(leaf)


func _make_box_node(node_name: String, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _solid_material(color)
	return mesh_instance


func _make_cylinder_node(node_name: String, radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 18
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _solid_material(color)
	return mesh_instance


func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	score_label = _make_label(Vector2.ZERO, 32, Color.WHITE)
	shots_label = _make_label(Vector2.ZERO, 32, Color.WHITE)
	combo_label = _make_label(Vector2.ZERO, 46, Color("#ffd34d"))
	party_label = _make_label(Vector2.ZERO, 26, Color.WHITE)
	status_label = _make_label(Vector2.ZERO, 18, Color("#e9d7b5"))
	root.add_child(score_label)
	root.add_child(shots_label)
	root.add_child(combo_label)
	root.add_child(party_label)
	root.add_child(status_label)


func _make_label(pos: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("#000000cc"))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	return label


func _update_responsive_layout() -> void:
	if camera_3d:
		var viewport_size: Vector2 = get_viewport().get_visible_rect().size
		var aspect: float = maxf(viewport_size.x / maxf(viewport_size.y, 1.0), 0.1)
		_fit_camera_to_board(aspect)

	var size: Vector2 = get_viewport().get_visible_rect().size
	var pad: float = maxf(14.0, size.x * 0.035)
	if score_label:
		score_label.position = Vector2(pad, pad)
		score_label.size = Vector2(maxf(160.0, size.x * 0.42), 48.0)
	if shots_label:
		shots_label.size = Vector2(maxf(190.0, size.x * 0.42), 48.0)
		shots_label.position = Vector2(size.x - shots_label.size.x - pad, pad)
		shots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if combo_label:
		combo_label.size = Vector2(280.0, 70.0)
		combo_label.position = Vector2(size.x * 0.5 - 130.0, size.y * 0.52)
	if party_label:
		party_label.size = Vector2(maxf(260.0, size.x - pad * 2.0), 42.0)
		party_label.position = Vector2(pad, size.y - 88.0)
	if status_label:
		status_label.size = Vector2(maxf(300.0, size.x - pad * 2.0), 34.0)
		status_label.position = Vector2(pad, size.y - 42.0)


func _fit_camera_to_board(aspect: float) -> void:
	camera_3d.fov = CAMERA_FOV_DEG
	camera_3d.rotation_degrees = Vector3(CAMERA_TILT_DEG, 0.0, 0.0)

	var vertical_fov: float = deg_to_rad(CAMERA_FOV_DEG)
	var horizontal_fov: float = 2.0 * atan(tan(vertical_fov * 0.5) * aspect)
	var tilt: float = deg_to_rad(absf(CAMERA_TILT_DEG))
	var half_depth: float = FRAME_HEIGHT * 0.5 * sin(tilt)
	var distance_for_height: float = (FRAME_HEIGHT * 0.5 * CAMERA_PADDING) / tan(vertical_fov * 0.5) + half_depth
	var distance_for_width: float = (FRAME_WIDTH * 0.5 * CAMERA_PADDING) / tan(horizontal_fov * 0.5)
	var distance: float = maxf(distance_for_height, distance_for_width)
	var forward: Vector3 = Vector3(0.0, -sin(tilt), -cos(tilt))
	camera_3d.position = -forward * distance
	camera_3d.look_at(Vector3.ZERO, Vector3.UP)


func _create_party_pawns() -> void:
	for i in range(party.size()):
		var member: Dictionary = party[i]
		var member_color: Color = member["color"]
		var pawn := Node3D.new()
		pawn.name = "PartyPawn_%s" % member["name"]
		add_child(pawn)

		var base := MeshInstance3D.new()
		var base_mesh := CylinderMesh.new()
		base_mesh.top_radius = 0.36
		base_mesh.bottom_radius = 0.42
		base_mesh.height = 0.16
		base_mesh.radial_segments = 24
		base.mesh = base_mesh
		base.position.y = 0.08
		base.material_override = _solid_material(Color("#3a2c24"))
		pawn.add_child(base)

		var body := MeshInstance3D.new()
		var body_mesh := CapsuleMesh.new()
		body_mesh.radius = 0.22
		body_mesh.height = 0.72
		body.mesh = body_mesh
		body.position.y = 0.52
		body.material_override = _solid_material(member_color)
		pawn.add_child(body)

		var head := MeshInstance3D.new()
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.18
		head_mesh.height = 0.36
		head.mesh = head_mesh
		head.position.y = 0.96
		head.material_override = _solid_material(Color("#ffd7a0"))
		pawn.add_child(head)

		var hat := MeshInstance3D.new()
		hat.mesh = _party_hat_mesh(i)
		hat.position.y = 1.17
		hat.material_override = _solid_material(member_color.lightened(0.12))
		pawn.add_child(hat)

		party_nodes.append(pawn)


func _solid_material(color: Color) -> Material:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	return mat


func _party_hat_mesh(index: int) -> Mesh:
	if index == 0:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.02
		cone.bottom_radius = 0.22
		cone.height = 0.36
		cone.radial_segments = 20
		return cone
	if index == 1:
		var helm := BoxMesh.new()
		helm.size = Vector3(0.42, 0.18, 0.32)
		return helm
	var hood := CylinderMesh.new()
	hood.top_radius = 0.12
	hood.bottom_radius = 0.2
	hood.height = 0.26
	hood.radial_segments = 3
	return hood


func _update_party_visuals() -> void:
	for i in range(party_nodes.size()):
		var pawn := party_nodes[i]
		var target_x: float = PARTY_IDLE_X[i]
		var target_z := PARTY_Z
		var target_scale := Vector3(0.78, 0.78, 0.78)
		if i == active_party:
			target_x = shooter_x
			target_z = PARTY_Z - 0.12
			target_scale = Vector3.ONE
		pawn.position = pawn.position.lerp(Vector3(target_x, 0.0, target_z), 0.24)
		pawn.scale = pawn.scale.lerp(target_scale, 0.24)


func _spawn_blocks() -> void:
	for child in get_tree().get_nodes_in_group("block_node"):
		child.queue_free()
	blocks.clear()

	for data in BLOCK_DATA:
		var hp: int = int(data["hp"])
		var block_pos: Vector2 = Vector2(data["pos"])
		var block: Dictionary = _create_block(block_pos, hp, String(data["rank"]), int(data["icon"]))
		blocks.append(block)


func _spawn_level_row(row_level: int) -> void:
	for i in range(ROW_X.size()):
		if (i + row_level) % 5 == 0:
			continue
		var hp: int = maxi(3, row_level * 2 + (i % 3) * 2)
		var rank: String = "square"
		var icon: int = (i + row_level) % 12
		if row_level % 4 == 0 and (i == 1 or i == 4):
			rank = "diamond"
			hp += 8
		elif row_level % 3 == 0 and (i == 2 or i == 3):
			rank = "triangle"
			hp += 4
		elif row_level % 5 == 0 and i == 3:
			rank = "chest"
			hp += 18
			icon = 3
		elif row_level % 2 == 0:
			rank = "circle"
		var block: Dictionary = _create_block(Vector2(float(ROW_X[i]), SPAWN_ROW_Z), hp, rank, icon)
		blocks.append(block)


func _advance_level() -> void:
	level += 1
	_drop_blocks()
	if _has_block_reached_danger_zone():
		game_over = true
		aiming = false
		balls.clear()
		ball_mesh.visible = false
		return
	_spawn_level_row(level)


func _drop_blocks() -> void:
	for block in blocks:
		var pos: Vector2 = block["pos"]
		pos.y += LEVEL_DROP
		block["pos"] = pos
		var block_node: Node3D = block["node"]
		block_node.position = Vector3(pos.x, 0.0, pos.y)


func _has_block_reached_danger_zone() -> bool:
	for block in blocks:
		var pos: Vector2 = block["pos"]
		var half_height := float(Vector2(block["size"]).y) * 0.5
		if pos.y + half_height >= DANGER_Z:
			return true
	return false


func _create_block(pos_2d: Vector2, hp: int, rank: String, icon_frame: int) -> Dictionary:
	var root := Node3D.new()
	root.name = "QuestBlock_%s_%d" % [rank, hp]
	root.position = Vector3(pos_2d.x, 0.0, pos_2d.y)
	root.add_to_group("block_node")
	add_child(root)

	var body := MeshInstance3D.new()
	body.mesh = _make_block_mesh(rank)
	body.material_override = _make_block_material(rank)
	body.position.y = 0.24
	root.add_child(body)

	var icon := Sprite3D.new()
	icon.texture = icon_texture
	icon.hframes = 4
	icon.vframes = 3
	icon.frame = icon_frame
	icon.pixel_size = 0.0027
	icon.position = Vector3(0.0, 0.83, -0.03)
	icon.rotation_degrees.x = -90.0
	icon.no_depth_test = true
	root.add_child(icon)

	var hp_label := Label3D.new()
	hp_label.text = _format_hp(hp)
	hp_label.font_size = 80
	hp_label.outline_size = 10
	hp_label.modulate = Color.WHITE
	hp_label.position = Vector3(0.0, 0.86, 0.31)
	hp_label.rotation_degrees.x = -90.0
	root.add_child(hp_label)

	return {
		"node": root,
		"hp_label": hp_label,
		"pos": pos_2d,
		"hp": hp,
		"rank": rank,
		"size": BLOCK_SIZE if rank != "boss" else Vector2(1.65, 1.05),
	}


func _make_block_mesh(rank: String) -> Mesh:
	match rank:
		"circle":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.58
			cylinder.bottom_radius = 0.62
			cylinder.height = 0.48
			cylinder.radial_segments = 24
			return cylinder
		"triangle":
			var tri := CylinderMesh.new()
			tri.top_radius = 0.7
			tri.bottom_radius = 0.74
			tri.height = 0.5
			tri.radial_segments = 3
			return tri
		"diamond":
			var dia := CylinderMesh.new()
			dia.top_radius = 0.68
			dia.bottom_radius = 0.72
			dia.height = 0.5
			dia.radial_segments = 4
			return dia
		"boss":
			var boss := BoxMesh.new()
			boss.size = Vector3(1.6, 0.56, 1.0)
			return boss
		_:
			var box := BoxMesh.new()
			box.size = Vector3(1.12, 0.5, 0.82)
			return box


func _make_block_material(rank: String) -> Material:
	var mat := StandardMaterial3D.new()
	match rank:
		"circle":
			mat.albedo_color = Color("#8d7a5a")
		"triangle":
			mat.albedo_color = Color("#9a7645")
		"diamond":
			mat.albedo_color = Color("#756a64")
		"boss":
			mat.albedo_color = Color("#6c6f61")
		"chest":
			mat.albedo_color = Color("#725034")
		_:
			mat.albedo_color = Color("#887761")
	mat.roughness = 0.9
	return mat


func _reset_ball() -> void:
	balls.clear()
	aiming = shots_left > 0 and not game_over
	ball_mesh.visible = aiming
	ball_mesh.position = Vector3(shooter_x, 0.45, SHOOT_Z)


func _update_shooter_from_input() -> void:
	var dir := Input.get_axis("ui_left", "ui_right")
	if absf(dir) > 0.01 and aiming:
		shooter_x = clampf(shooter_x + dir * 0.11, -4.2, 4.2)
		ball_mesh.position.x = shooter_x


func _fire_at_screen_point(screen_point: Vector2) -> void:
	if not aiming:
		return
	var dir := _screen_point_to_shot_dir(screen_point)
	_fire_toward(dir)


func _screen_point_to_shot_dir(screen_point: Vector2) -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector2(0.0, -1.0)
	var from := camera.project_ray_origin(screen_point)
	var ray := camera.project_ray_normal(screen_point)
	if absf(ray.y) < 0.001:
		return Vector2(0.0, -1.0)
	var t := -from.y / ray.y
	var world := from + ray * t
	var dir := Vector2(world.x - shooter_x, world.z - SHOOT_Z)
	if dir.length() < 0.01:
		dir = Vector2(0.0, -1.0)
	if dir.y > -0.18:
		dir.y = -0.65
	return dir.normalized()


func _fire_toward(dir: Vector2) -> void:
	if not aiming or shots_left <= 0 or game_over:
		return
	if dir.y > -0.18:
		dir.y = -0.65
	dir = dir.normalized()
	aiming = false
	shots_left -= 1
	balls = [{"pos": Vector2(shooter_x, SHOOT_Z), "vel": dir * BALL_SPEED}]


func _update_balls(delta: float) -> void:
	if game_over:
		return
	if balls.is_empty():
		if not aiming:
			_finish_shot()
		return

	var ball := balls[0]
	var pos: Vector2 = ball["pos"]
	var vel: Vector2 = ball["vel"]
	pos += vel * delta

	if pos.x < -BOARD_WIDTH * 0.5 + BALL_RADIUS:
		pos.x = -BOARD_WIDTH * 0.5 + BALL_RADIUS
		vel.x = absf(vel.x)
	if pos.x > BOARD_WIDTH * 0.5 - BALL_RADIUS:
		pos.x = BOARD_WIDTH * 0.5 - BALL_RADIUS
		vel.x = -absf(vel.x)
	if pos.y < BOARD_TOP:
		pos.y = BOARD_TOP
		vel.y = absf(vel.y)
	if pos.y > BOARD_BOTTOM:
		balls.clear()
		return

	for block in blocks:
		if _ball_hits_block(pos, block):
			var delta_vec := (pos - Vector2(block["pos"])).normalized()
			if absf(delta_vec.x) > absf(delta_vec.y):
				vel.x *= -1.0
			else:
				vel.y *= -1.0
			_damage_block(block)
			break

	ball["pos"] = pos
	ball["vel"] = vel
	balls[0] = ball
	ball_mesh.position = Vector3(pos.x, 0.52, pos.y)


func _ball_hits_block(pos: Vector2, block: Dictionary) -> bool:
	var half := Vector2(block["size"]) * 0.5 + Vector2(BALL_RADIUS, BALL_RADIUS)
	var local := pos - Vector2(block["pos"])
	return absf(local.x) <= half.x and absf(local.y) <= half.y


func _damage_block(block: Dictionary) -> void:
	block["hp"] = int(block["hp"]) - _party_damage()
	combo += 1
	score += 10 + combo * 3
	if int(block["hp"]) <= 0:
		score += 100
		blocks.erase(block)
		var block_node: Node = block["node"]
		block_node.queue_free()
	else:
		var hp_label_3d: Label3D = block["hp_label"]
		hp_label_3d.text = _format_hp(int(block["hp"]))


func _party_damage() -> int:
	match active_party:
		0:
			return 3
		1:
			return 5
		_:
			return 4


func _next_turn() -> void:
	combo = 0
	active_party = (active_party + 1) % party.size()
	_reset_ball()


func _finish_shot() -> void:
	if game_over:
		return
	combo = 0
	if shots_left <= 0 or blocks.is_empty():
		aiming = false
		ball_mesh.visible = false
		return
	_advance_level()
	if game_over:
		return
	_next_turn()


func _restart_board() -> void:
	score = 2057
	shots_left = 9
	combo = 0
	active_party = 0
	level = 1
	game_over = false
	shooter_x = 0.0
	_spawn_blocks()
	_reset_ball()


func _update_aim_line() -> void:
	if not aiming:
		for marker in aim_markers:
			marker.visible = false
		return
	var dir := _screen_point_to_shot_dir(get_viewport().get_mouse_position())
	var preview_pos := Vector2(shooter_x, SHOOT_Z)
	var preview_vel := dir
	for i in range(aim_markers.size()):
		preview_pos += preview_vel * 0.55
		if preview_pos.x < -BOARD_WIDTH * 0.5 + BALL_RADIUS:
			preview_pos.x = -BOARD_WIDTH * 0.5 + BALL_RADIUS
			preview_vel.x = absf(preview_vel.x)
		if preview_pos.x > BOARD_WIDTH * 0.5 - BALL_RADIUS:
			preview_pos.x = BOARD_WIDTH * 0.5 - BALL_RADIUS
			preview_vel.x = -absf(preview_vel.x)
		var marker := aim_markers[i]
		marker.visible = true
		marker.position = Vector3(preview_pos.x, 0.64, preview_pos.y)
		var pulse := 0.75 + float(i) * 0.035
		marker.scale = Vector3.ONE * pulse


func _update_ui() -> void:
	score_label.text = "STAR %d" % score
	shots_label.text = "LV %d  SHOTS %d" % [level, shots_left]
	combo_label.text = ("COMBO x%d" % combo) if combo > 1 else ""
	var member: Dictionary = party[active_party]
	party_label.text = "%s  /  %s TURN" % [member["name"], member["class"]]
	party_label.add_theme_color_override("font_color", member["color"])
	status_label.text = "Drag or click to throw. Blocks drop every level. Esc resets."
	if game_over:
		status_label.text = "Quest line reached the party. Esc resets."
	elif blocks.is_empty():
		status_label.text = "Board cleared. Esc resets the prototype."
	elif shots_left <= 0 and balls.is_empty():
		status_label.text = "No shots left. Esc resets the prototype."


func _format_hp(hp: int) -> String:
	if hp >= 1000000:
		return "%dM" % int(hp / 1000000)
	if hp >= 1000:
		return "%dK" % int(hp / 1000)
	return str(hp)
