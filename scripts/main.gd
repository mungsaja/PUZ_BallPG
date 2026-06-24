extends Node3D

const BOARD_WIDTH := 10.0
const BOARD_HEIGHT := 17.78
const FRAME_WIDTH := BOARD_WIDTH + 1.6
const FRAME_HEIGHT := BOARD_HEIGHT + 1.6
const DEFAULT_CAMERA_TILT_DEG := -63.0
const DEFAULT_CAMERA_YAW_DEG := 0.0
const DEFAULT_CAMERA_FOV_DEG := 46.0
const DEFAULT_CAMERA_PADDING := 1.08
const DEFAULT_ICON_HEIGHT := 0.78
const DEFAULT_BOSS_ICON_HEIGHT := 0.93
const DEFAULT_ICON_SCALE := 1.0
const DEBUG_CFG_PATH := "user://puz_ballpg_debug_camera.cfg"
const DEFAULT_DEBUG_CFG_PATH := "res://debug_defaults.cfg"
const DEBUG_SECTIONS := [
	{"key": "view", "title": "VIEW / CAMERA", "specs": [
		["camera_tilt_deg", "Cam Tilt", -78.0, -35.0, 0.5],
		["camera_yaw_deg", "Cam Yaw", -35.0, 35.0, 0.5],
		["camera_fov_deg", "Cam FOV", 34.0, 62.0, 0.5],
		["camera_padding", "Cam Pad", 0.92, 1.35, 0.01],
	]},
	{"key": "blocks", "title": "BLOCK ICONS", "specs": [
		["block_icon_height", "Icon Y", 0.52, 1.2, 0.01],
		["boss_icon_height", "Boss Icon Y", 0.64, 1.45, 0.01],
		["block_icon_scale", "Icon Scale", 0.65, 1.55, 0.01],
	]},
	{"key": "board", "title": "BOARD / BALL", "specs": [
		["ball_speed", "Orb Speed", 4.0, 24.0, 0.5],
		["ball_radius", "Orb Radius", 0.08, 0.4, 0.01],
		["shooter_limit", "Shooter X Lim", 2.0, 4.82, 0.02],
		["danger_z", "Player Line", 4.0, 7.5, 0.05],
		["gauge_height", "Gauge H", 0.05, 0.5, 0.01],
		["gauge_offset_y", "Gauge Y", -0.5, 1.5, 0.02],
		["number_size", "Num Size px", 8.0, 72.0, 1.0],
		["number_offset_y", "Num Y", -0.5, 1.5, 0.02],
		["wall_half_width", "Side Wall", 4.0, 6.0, 0.05],
		["top_pad", "Top Pad", 0.4, 5.0, 0.05],
		["wall_top_z", "Top Wall", -10.0, -5.0, 0.05],
	]},
	{"key": "mobsize", "title": "MOB SIZE (per shape)", "specs": [
		["scale_circle", "Circle", 0.4, 1.4, 0.01],
		["scale_square", "Square", 0.4, 1.4, 0.01],
		["scale_triangle", "Triangle", 0.4, 1.4, 0.01],
		["scale_diamond", "Diamond", 0.4, 1.4, 0.01],
		["scale_chest", "Chest", 0.4, 1.4, 0.01],
		["scale_boss", "Boss", 0.4, 1.4, 0.01],
	]},
	{"key": "stall", "title": "STALL (anti-loop)", "presets": [
		["off", "Off"],
		["standard", "Standard"],
		["fast", "Fast"],
		["soft", "Soft"],
	]},
	{"key": "rules", "title": "RULES", "toggles": [
		["game_over_enabled", "Block invade = Game Over", false],
	]},
]
const BOARD_FACTORY := {
	"ball_speed": 12.0,
	"ball_radius": 0.18,
	"shooter_limit": 4.2,
	"danger_z": 6.55,
	"gauge_height": 0.16,
	"gauge_offset_y": 0.34,
	"number_size": 28.0,
	"number_offset_y": 0.34,
	"top_pad": 1.25,
	"wall_half_width": 5.0,
	"wall_top_z": -8.2,
}
const BOARD_TOP := -8.2
const BOARD_BOTTOM := 8.0
const SHOOT_Z := 6.55
const PARTY_FRONT_Z := 7.0
const PARTY_BACK_Z := 7.85
const BALL_COLLISION_STEP := 0.12
# Anti-stall presets: {speed-up start (s), speed-up rate (per s, capped 4x),
# hard-cap force-land time (s; 0 = none)}.
const STALL_PRESETS := {
	"off": {"start": 0.0, "speedup": 0.0, "hardcap": 0.0},
	"standard": {"start": 3.0, "speedup": 1.0, "hardcap": 8.0},
	"fast": {"start": 2.0, "speedup": 2.0, "hardcap": 5.0},
	"soft": {"start": 4.0, "speedup": 0.5, "hardcap": 12.0},
}
const COLLISION_EPSILON := 0.001
const BLOCK_SIZE := Vector2(1.18, 0.82)
const BOSS_BLOCK_SIZE := Vector2(2.68, 1.05)
const AIM_DOTS := 10
const MIN_SHOT_DY := 0.2
const LEVEL_DROP := 1.28
const ROW_X := [-3.75, -2.25, -0.75, 0.75, 2.25, 3.75]
const BOSS_SPAN := 2
const GRID_COL_WIDTH := 1.5
const GRID_ROW_HEIGHT := LEVEL_DROP
const GRID_ROWS := 12

const BLOCK_DATA := [
	{"row": 0, "col": 0, "hp": 3, "rank": "circle", "icon": 0},
	{"row": 0, "col": 1, "hp": 4, "rank": "circle", "icon": 6},
	{"row": 0, "col": 2, "hp": 5, "rank": "square", "icon": 1},
	{"row": 0, "col": 3, "hp": 5, "rank": "square", "icon": 5},
	{"row": 0, "col": 4, "hp": 4, "rank": "circle", "icon": 0},
	{"row": 0, "col": 5, "hp": 3, "rank": "circle", "icon": 6},
	{"row": 1, "col": 0, "hp": 7, "rank": "square", "icon": 1},
	{"row": 1, "col": 1, "hp": 8, "rank": "triangle", "icon": 2},
	{"row": 1, "col": 2, "hp": 12, "rank": "chest", "icon": 3},
	{"row": 1, "col": 3, "hp": 8, "rank": "triangle", "icon": 2},
	{"row": 1, "col": 4, "hp": 7, "rank": "square", "icon": 5},
	{"row": 1, "col": 5, "hp": 7, "rank": "square", "icon": 1},
	{"row": 2, "col": 1, "hp": 12, "rank": "diamond", "icon": 9},
	{"row": 2, "col": 2, "hp": 16, "rank": "diamond", "icon": 11},
	{"row": 2, "col": 3, "hp": 16, "rank": "diamond", "icon": 7},
	{"row": 2, "col": 4, "hp": 12, "rank": "diamond", "icon": 9},
]

const GAUGE_SHADER_CODE := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled;

uniform float fill_ratio : hint_range(0.0, 1.0) = 1.0;
uniform vec4 fill_color : source_color = vec4(0.58, 0.12, 0.13, 1.0);
uniform vec4 bg_color : source_color = vec4(0.07, 0.05, 0.04, 0.85);
uniform float radius = 0.5;
uniform float aspect = 6.0;

void fragment() {
	vec2 p = vec2((UV.x - 0.5) * aspect, UV.y - 0.5);
	vec2 b = vec2(aspect * 0.5, 0.5);
	float r = clamp(radius, 0.0, 0.5);
	vec2 q = abs(p) - (b - vec2(r));
	float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
	if (d > 0.0) {
		discard;
	}
	vec4 col = UV.x <= fill_ratio ? fill_color : bg_color;
	ALBEDO = col.rgb;
	ALPHA = col.a;
}
"""

var party := [
	{"name": "Aria", "class": "Mage", "color": Color("#5869ff")},
	{"name": "Bram", "class": "Knight", "color": Color("#d2a15d")},
	{"name": "Nia", "class": "Rogue", "color": Color("#5ed083")},
]

var blocks: Array[Dictionary] = []
var balls: Array[Dictionary] = []
var shooter_x := 0.0
var catch_active := false
var catch_target_x := 0.0
var resolving_shot := false
var shot_time := 0.0
var stall_preset := "standard"
var stall_start := 3.0
var stall_speedup := 1.0
var stall_hardcap := 8.0
var stall_preset_buttons := {}
var aiming := true
var score := 2057
var combo := 0
var active_party := 0
var level := 1
var game_over := false

var camera_3d: Camera3D
var gauge_layer: CanvasLayer
var gauge_shader: Shader
var ball_mesh: MeshInstance3D
var catch_marker: MeshInstance3D
var left_rail: MeshInstance3D
var right_rail: MeshInstance3D
var top_rail: MeshInstance3D
var board_tile_grid: Node3D
var aim_markers: Array[MeshInstance3D] = []
var party_nodes: Array[Node3D] = []
var score_label: Label
var level_label: Label
var combo_label: Label
var party_label: Label
var status_label: Label
var time_state_label: Label
var debug_panel: PanelContainer
var debug_value_inputs := {}
var debug_sliders := {}
var icon_texture: Texture2D
var camera_tilt_deg := DEFAULT_CAMERA_TILT_DEG
var camera_yaw_deg := DEFAULT_CAMERA_YAW_DEG
var camera_fov_deg := DEFAULT_CAMERA_FOV_DEG
var camera_padding := DEFAULT_CAMERA_PADDING
var block_icon_height := DEFAULT_ICON_HEIGHT
var boss_icon_height := DEFAULT_BOSS_ICON_HEIGHT
var block_icon_scale := DEFAULT_ICON_SCALE
var ball_radius := float(BOARD_FACTORY["ball_radius"])
var ball_speed := float(BOARD_FACTORY["ball_speed"])
var shooter_limit := float(BOARD_FACTORY["shooter_limit"])
var danger_z := float(BOARD_FACTORY["danger_z"])
var rank_scales := {"circle": 1.0, "square": 1.0, "triangle": 1.0, "diamond": 1.0, "chest": 1.0, "boss": 1.0}
var gauge_height := float(BOARD_FACTORY["gauge_height"])
var gauge_offset_y := float(BOARD_FACTORY["gauge_offset_y"])
var number_size := float(BOARD_FACTORY["number_size"])
var number_offset_y := float(BOARD_FACTORY["number_offset_y"])
var top_pad := float(BOARD_FACTORY["top_pad"])
var wall_half_width := BOARD_WIDTH * 0.5
var wall_top_z := BOARD_TOP
var metrics_panel: PanelContainer
var debug_metrics_label: Label
var debug_toggles := {}
var game_over_enabled := false
var debug_section_rows := {}
var debug_section_details := {}
var debug_section_open := {}


func _ready() -> void:
	icon_texture = load("res://assets/generated/quest_icons.png")
	_setup_world()
	_spawn_blocks()
	_setup_ui()
	_setup_debug_panel()
	_create_party_pawns()
	shooter_x = _party_home_x(active_party)
	_update_responsive_layout()
	_reset_ball()


func _process(delta: float) -> void:
	_update_shooter_from_input()
	_update_aim_line()
	_update_balls(delta)
	_update_party_visuals()
	_update_block_billboards()
	_update_ui()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_update_responsive_layout()


func _input(event: InputEvent) -> void:
	if _is_debug_panel_pointer_event(event):
		return
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
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_QUOTELEFT or event.keycode == KEY_F1):
		_toggle_debug_panel()


func _is_debug_panel_pointer_event(event: InputEvent) -> bool:
	if not is_instance_valid(debug_panel) or not debug_panel.visible:
		return false
	var pointer_pos := Vector2.INF
	if event is InputEventMouse:
		pointer_pos = event.position
	elif event is InputEventScreenTouch:
		pointer_pos = event.position
	elif event is InputEventScreenDrag:
		pointer_pos = event.position
	else:
		return false
	return debug_panel.get_global_rect().has_point(pointer_pos)


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
	camera_3d.fov = camera_fov_deg
	camera_3d.rotation_degrees = Vector3(camera_tilt_deg, camera_yaw_deg, 0.0)
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
	ball_mesh.name = "Orb"
	var sphere := SphereMesh.new()
	sphere.radius = ball_radius
	sphere.height = ball_radius * 2.0
	ball_mesh.mesh = sphere
	var ball_mat := StandardMaterial3D.new()
	ball_mat.albedo_color = Color("#40b8ff")
	ball_mat.emission_enabled = true
	ball_mat.emission = Color("#1c72ff")
	ball_mat.emission_energy_multiplier = 0.7
	ball_mesh.material_override = ball_mat
	add_child(ball_mesh)

	catch_marker = MeshInstance3D.new()
	catch_marker.name = "CatchMarker"
	var marker_disc := CylinderMesh.new()
	marker_disc.top_radius = 0.5
	marker_disc.bottom_radius = 0.5
	marker_disc.height = 0.04
	marker_disc.radial_segments = 28
	catch_marker.mesh = marker_disc
	var marker_mat := StandardMaterial3D.new()
	marker_mat.albedo_color = Color(1.0, 0.83, 0.35, 0.5)
	marker_mat.emission_enabled = true
	marker_mat.emission = Color("#ffba35")
	marker_mat.emission_energy_multiplier = 1.4
	marker_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	catch_marker.material_override = marker_mat
	catch_marker.visible = false
	add_child(catch_marker)

	gauge_layer = CanvasLayer.new()
	gauge_layer.name = "GaugeLayer"
	gauge_layer.layer = 5
	add_child(gauge_layer)


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

	# The tile grid (the blocks' "받침") lives in its own container anchored at the
	# row-0 line (_apply_grid_offset follows top_pad). Cell positions are fixed;
	# each tile is resized by _apply_spread so the gap tracks the platform size.
	board_tile_grid = Node3D.new()
	board_tile_grid.name = "TileGrid"
	map_root.add_child(board_tile_grid)
	for row in range(GRID_ROWS):
		for col in range(ROW_X.size()):
			var tile_color := Color("#5d4a3a").lightened(0.04) if (row + col) % 2 == 0 else Color("#5d4a3a").darkened(0.035)
			var tile := _make_box_node(
				"StoneTile_%02d_%02d" % [row, col],
				Vector3(GRID_COL_WIDTH - 0.045, 0.08, GRID_ROW_HEIGHT - 0.045),
				Vector3(float(ROW_X[col]), -0.16, float(row) * GRID_ROW_HEIGHT),
				tile_color
			)
			board_tile_grid.add_child(tile)
	_apply_grid_offset()
	_apply_spread()

	var rail_color := Color("#6b3f22")
	left_rail = _make_box_node("LeftWoodRail", Vector3(0.48, 0.72, BOARD_HEIGHT + 1.25), Vector3(-BOARD_WIDTH * 0.5 - 0.48, 0.06, 0.0), rail_color)
	map_root.add_child(left_rail)
	right_rail = _make_box_node("RightWoodRail", Vector3(0.48, 0.72, BOARD_HEIGHT + 1.25), Vector3(BOARD_WIDTH * 0.5 + 0.48, 0.06, 0.0), rail_color)
	map_root.add_child(right_rail)
	top_rail = _make_box_node("TopWoodRail", Vector3(BOARD_WIDTH + 1.45, 0.72, 0.5), Vector3(0.0, 0.06, BOARD_TOP - 0.48), rail_color.lightened(0.05))
	map_root.add_child(top_rail)
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
	level_label = _make_label(Vector2.ZERO, 32, Color.WHITE)
	combo_label = _make_label(Vector2.ZERO, 46, Color("#ffd34d"))
	party_label = _make_label(Vector2.ZERO, 26, Color.WHITE)
	status_label = _make_label(Vector2.ZERO, 18, Color("#e9d7b5"))
	time_state_label = _make_label(Vector2.ZERO, 30, Color("#7adfff"))
	time_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(score_label)
	root.add_child(level_label)
	root.add_child(combo_label)
	root.add_child(party_label)
	root.add_child(status_label)
	root.add_child(time_state_label)


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


func _setup_debug_panel() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "DebugLayer"
	canvas.layer = 20
	add_child(canvas)

	debug_panel = PanelContainer.new()
	debug_panel.name = "DebugCameraPanel"
	debug_panel.visible = false
	debug_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	# Bottom-left: anchor to the bottom edge so the panel hugs the lower-left corner.
	debug_panel.anchor_left = 0.0
	debug_panel.anchor_right = 0.0
	debug_panel.anchor_top = 1.0
	debug_panel.anchor_bottom = 1.0
	debug_panel.offset_left = 10.0
	debug_panel.offset_top = -430.0
	debug_panel.offset_right = 330.0
	debug_panel.offset_bottom = -10.0
	canvas.add_child(debug_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.015, 0.020, 0.028, 0.92)
	panel_style.border_color = Color(0.30, 0.78, 1.0, 0.45)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(0)
	debug_panel.add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	debug_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 5)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(layout)

	var title := Label.new()
	title.text = "DEBUG  ` toggle"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color("#7adfff"))
	layout.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	layout.add_child(scroll)

	var inner_margin := MarginContainer.new()
	inner_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_margin.add_theme_constant_override("margin_right", 12)
	scroll.add_child(inner_margin)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 3)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner_margin.add_child(body)

	for section in DEBUG_SECTIONS:
		_add_debug_section(body, section)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 5)
	layout.add_child(buttons)

	var save_button := _make_debug_button("SAVE")
	save_button.pressed.connect(_save_debug_defaults)
	buttons.add_child(save_button)
	var load_button := _make_debug_button("LOAD")
	load_button.pressed.connect(_load_debug_defaults)
	buttons.add_child(load_button)
	var reset_button := _make_debug_button("RESET")
	reset_button.pressed.connect(_reset_debug_defaults)
	buttons.add_child(reset_button)

	_build_metrics_panel(canvas)
	_load_debug_defaults()


func _build_metrics_panel(canvas: CanvasLayer) -> void:
	# Gap readout in its own small sub-window, pinned to the top-left corner.
	metrics_panel = PanelContainer.new()
	metrics_panel.name = "DebugMetricsPanel"
	metrics_panel.visible = false
	metrics_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	metrics_panel.offset_left = 10.0
	metrics_panel.offset_top = 10.0
	metrics_panel.offset_right = 220.0
	metrics_panel.offset_bottom = 150.0
	canvas.add_child(metrics_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.015, 0.020, 0.028, 0.92)
	panel_style.border_color = Color(0.40, 0.90, 0.62, 0.45)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(0)
	metrics_panel.add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	metrics_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "GAPS  vs Orb d"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color("#7adfff"))
	vbox.add_child(title)

	debug_metrics_label = Label.new()
	debug_metrics_label.add_theme_font_size_override("font_size", 12)
	debug_metrics_label.add_theme_color_override("font_color", Color("#bfe9c4"))
	vbox.add_child(debug_metrics_label)


func _add_debug_section(parent: VBoxContainer, section: Dictionary) -> void:
	var key := String(section["key"])
	if not debug_section_open.has(key):
		debug_section_open[key] = false

	var header := _make_debug_button("")
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.set_meta("section_title", String(section["title"]))
	header.pressed.connect(func() -> void:
		debug_section_open[key] = not bool(debug_section_open[key])
		_update_debug_sections()
	)
	parent.add_child(header)
	debug_section_rows[key] = header

	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 3)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(details)
	debug_section_details[key] = details

	for spec in section.get("specs", []):
		details.add_child(_make_debug_slider_row(spec))
	for toggle in section.get("toggles", []):
		details.add_child(_make_debug_toggle_row(toggle))
	if section.has("presets"):
		details.add_child(_make_debug_preset_row(section["presets"]))


func _make_debug_preset_row(presets: Array) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for preset in presets:
		var pkey := String(preset[0])
		var btn := _make_debug_button(String(preset[1]))
		btn.pressed.connect(func() -> void: _apply_stall_preset(pkey))
		stall_preset_buttons[pkey] = btn
		row.add_child(btn)
	return row


func _apply_stall_preset(key: String) -> void:
	if not STALL_PRESETS.has(key):
		return
	stall_preset = key
	var p: Dictionary = STALL_PRESETS[key]
	stall_start = float(p["start"])
	stall_speedup = float(p["speedup"])
	stall_hardcap = float(p["hardcap"])
	_update_stall_preset_buttons()


func _update_stall_preset_buttons() -> void:
	for pkey in stall_preset_buttons:
		var btn := stall_preset_buttons[pkey] as Button
		if is_instance_valid(btn):
			var active := String(pkey) == stall_preset
			btn.add_theme_color_override("font_color", Color("#ffe06a") if active else Color("#d8f4ff"))


func _make_debug_toggle_row(toggle: Array) -> Control:
	var key := String(toggle[0])
	var check := CheckButton.new()
	check.text = String(toggle[1])
	check.focus_mode = Control.FOCUS_NONE
	check.set_pressed_no_signal(_get_debug_bool(key))
	check.add_theme_font_size_override("font_size", 11)
	check.add_theme_color_override("font_color", Color("#d8f4ff"))
	check.add_theme_color_override("font_pressed_color", Color.WHITE)
	check.toggled.connect(func(pressed: bool) -> void:
		_set_debug_bool(key, pressed)
	)
	debug_toggles[key] = check
	return check


func _set_debug_bool(key: String, value: bool) -> void:
	match key:
		"game_over_enabled":
			game_over_enabled = value


func _get_debug_bool(key: String) -> bool:
	match key:
		"game_over_enabled":
			return game_over_enabled
	return false


func _update_debug_sections() -> void:
	for key in debug_section_rows:
		var header := debug_section_rows[key] as Button
		var details := debug_section_details[key] as Control
		var open := bool(debug_section_open[key])
		header.text = "%s %s" % ["v" if open else ">", str(header.get_meta("section_title"))]
		details.visible = open
	_update_metrics_panel_visibility()


func _make_debug_slider_row(spec: Array) -> Control:
	var key := String(spec[0])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = String(spec[1])
	label.custom_minimum_size = Vector2(92.0, 0.0)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("#d8f4ff"))
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = float(spec[2])
	slider.max_value = float(spec[3])
	slider.step = float(spec[4])
	slider.value = _get_debug_value(key)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.mouse_filter = Control.MOUSE_FILTER_PASS
	slider.value_changed.connect(_on_debug_slider_changed.bind(key))
	slider.gui_input.connect(_on_debug_slider_gui_input.bind(slider))
	row.add_child(slider)
	debug_sliders[key] = slider

	var value_input := LineEdit.new()
	value_input.custom_minimum_size = Vector2(54.0, 20.0)
	value_input.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_input.text = _format_debug_value(slider.value)
	value_input.add_theme_font_size_override("font_size", 11)
	value_input.text_submitted.connect(_on_debug_value_submitted.bind(key))
	value_input.focus_exited.connect(func() -> void:
		_on_debug_value_submitted(value_input.text, key)
	)
	row.add_child(value_input)
	debug_value_inputs[key] = value_input

	return row


func _make_debug_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 24.0
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color("#d8f4ff"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	return button


func _toggle_debug_panel() -> void:
	if is_instance_valid(debug_panel):
		debug_panel.visible = not debug_panel.visible
		_update_metrics_panel_visibility()


func _update_metrics_panel_visibility() -> void:
	# The gap sub-window (top-left) only appears while the BOARD folder is open.
	if not is_instance_valid(metrics_panel) or not is_instance_valid(debug_panel):
		return
	metrics_panel.visible = debug_panel.visible and bool(debug_section_open.get("board", false))


func _on_debug_slider_gui_input(event: InputEvent, slider: HSlider) -> void:
	# Wheel lock: swallow mouse-wheel events so scrolling the panel never nudges
	# a slider value. The wheel still scrolls the surrounding ScrollContainer.
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			slider.accept_event()


func _on_debug_slider_changed(value: float, key: String) -> void:
	_set_debug_value(key, value)
	_sync_debug_input(key)


func _on_debug_value_submitted(text: String, key: String) -> void:
	var slider := debug_sliders.get(key) as HSlider
	if not is_instance_valid(slider):
		return
	var value := clampf(text.to_float(), float(slider.min_value), float(slider.max_value))
	slider.set_value_no_signal(value)
	_set_debug_value(key, value)
	_sync_debug_input(key)


func _set_debug_value(key: String, value: float) -> void:
	if key.begins_with("scale_"):
		rank_scales[key.substr(6)] = value
		_apply_spread()
		_update_debug_metrics()
		return
	match key:
		"camera_tilt_deg":
			camera_tilt_deg = value
		"camera_yaw_deg":
			camera_yaw_deg = value
		"camera_fov_deg":
			camera_fov_deg = value
		"camera_padding":
			camera_padding = value
		"block_icon_height":
			block_icon_height = value
			_update_block_visual_layout()
		"boss_icon_height":
			boss_icon_height = value
			_update_block_visual_layout()
		"block_icon_scale":
			block_icon_scale = value
			_update_block_visual_layout()
		"ball_speed":
			ball_speed = value
		"ball_radius":
			ball_radius = value
			_apply_ball_radius()
		"shooter_limit":
			shooter_limit = value
		"danger_z":
			danger_z = value
		"gauge_height":
			gauge_height = value
		"gauge_offset_y":
			gauge_offset_y = value
		"number_size":
			number_size = value
		"number_offset_y":
			number_offset_y = value
		"wall_half_width":
			wall_half_width = value
			_apply_wall_width()
		"wall_top_z":
			wall_top_z = value
			_apply_wall_top()
		"top_pad":
			top_pad = value
			_reposition_blocks()
			_apply_grid_offset()
	if key.begins_with("camera_"):
		_update_responsive_layout()
	_update_debug_metrics()


func _get_debug_value(key: String) -> float:
	if key.begins_with("scale_"):
		return float(rank_scales.get(key.substr(6), 1.0))
	match key:
		"camera_tilt_deg":
			return camera_tilt_deg
		"camera_yaw_deg":
			return camera_yaw_deg
		"camera_fov_deg":
			return camera_fov_deg
		"camera_padding":
			return camera_padding
		"block_icon_height":
			return block_icon_height
		"boss_icon_height":
			return boss_icon_height
		"block_icon_scale":
			return block_icon_scale
		"ball_speed":
			return ball_speed
		"ball_radius":
			return ball_radius
		"shooter_limit":
			return shooter_limit
		"danger_z":
			return danger_z
		"gauge_height":
			return gauge_height
		"gauge_offset_y":
			return gauge_offset_y
		"number_size":
			return number_size
		"number_offset_y":
			return number_offset_y
		"wall_half_width":
			return wall_half_width
		"wall_top_z":
			return wall_top_z
		"top_pad":
			return top_pad
	return 0.0


func _apply_ball_radius() -> void:
	if is_instance_valid(ball_mesh) and ball_mesh.mesh is SphereMesh:
		var sphere := ball_mesh.mesh as SphereMesh
		sphere.radius = ball_radius
		sphere.height = ball_radius * 2.0


func _sync_debug_controls() -> void:
	for key in debug_sliders:
		var slider := debug_sliders[key] as HSlider
		if is_instance_valid(slider):
			slider.set_value_no_signal(_get_debug_value(String(key)))
		_sync_debug_input(String(key))
	for key in debug_toggles:
		var check := debug_toggles[key] as CheckButton
		if is_instance_valid(check):
			check.set_pressed_no_signal(_get_debug_bool(String(key)))
	_update_stall_preset_buttons()
	_update_debug_metrics()


func _sync_debug_input(key: String) -> void:
	var value_input := debug_value_inputs.get(key) as LineEdit
	if is_instance_valid(value_input):
		value_input.text = _format_debug_value(_get_debug_value(key))


func _format_debug_value(value: float) -> String:
	return "%0.2f" % value


func _save_debug_defaults() -> void:
	var cfg := ConfigFile.new()
	for section in DEBUG_SECTIONS:
		for spec in section.get("specs", []):
			var key := String(spec[0])
			cfg.set_value("angle", key, _get_debug_value(key))
		for toggle in section.get("toggles", []):
			var tkey := String(toggle[0])
			cfg.set_value("rules", tkey, _get_debug_bool(tkey))
	for key in debug_section_open:
		cfg.set_value("sections", key, bool(debug_section_open[key]))
	cfg.set_value("stall", "preset", stall_preset)
	cfg.save(DEBUG_CFG_PATH)


func _load_debug_defaults() -> void:
	var cfg := ConfigFile.new()
	# Prefer the user's saved tweaks; otherwise fall back to the defaults committed
	# to the project (debug_defaults.cfg).
	if cfg.load(DEBUG_CFG_PATH) != OK and cfg.load(DEFAULT_DEBUG_CFG_PATH) != OK:
		_sync_debug_controls()
		_update_debug_sections()
		return
	for section in DEBUG_SECTIONS:
		for spec in section.get("specs", []):
			var key := String(spec[0])
			if cfg.has_section_key("angle", key):
				_set_debug_value(key, float(cfg.get_value("angle", key)))
		for toggle in section.get("toggles", []):
			var tkey := String(toggle[0])
			_set_debug_bool(tkey, bool(cfg.get_value("rules", tkey, bool(toggle[2]))))
	for key in debug_section_open:
		debug_section_open[key] = bool(cfg.get_value("sections", key, debug_section_open[key]))
	_apply_stall_preset(String(cfg.get_value("stall", "preset", stall_preset)))
	_sync_debug_controls()
	_update_debug_sections()
	_update_responsive_layout()
	_update_block_visual_layout()


func _reset_debug_defaults() -> void:
	camera_tilt_deg = DEFAULT_CAMERA_TILT_DEG
	camera_yaw_deg = DEFAULT_CAMERA_YAW_DEG
	camera_fov_deg = DEFAULT_CAMERA_FOV_DEG
	camera_padding = DEFAULT_CAMERA_PADDING
	block_icon_height = DEFAULT_ICON_HEIGHT
	boss_icon_height = DEFAULT_BOSS_ICON_HEIGHT
	block_icon_scale = DEFAULT_ICON_SCALE
	ball_speed = float(BOARD_FACTORY["ball_speed"])
	ball_radius = float(BOARD_FACTORY["ball_radius"])
	shooter_limit = float(BOARD_FACTORY["shooter_limit"])
	danger_z = float(BOARD_FACTORY["danger_z"])
	for rank in rank_scales:
		rank_scales[rank] = 1.0
	gauge_height = float(BOARD_FACTORY["gauge_height"])
	gauge_offset_y = float(BOARD_FACTORY["gauge_offset_y"])
	number_size = float(BOARD_FACTORY["number_size"])
	number_offset_y = float(BOARD_FACTORY["number_offset_y"])
	top_pad = float(BOARD_FACTORY["top_pad"])
	wall_half_width = float(BOARD_FACTORY["wall_half_width"])
	wall_top_z = float(BOARD_FACTORY["wall_top_z"])
	_apply_ball_radius()
	_reposition_blocks()
	_apply_grid_offset()
	_apply_spread()
	_apply_wall_width()
	_apply_wall_top()
	for section in DEBUG_SECTIONS:
		for toggle in section.get("toggles", []):
			_set_debug_bool(String(toggle[0]), bool(toggle[2]))
	_apply_stall_preset("standard")
	_sync_debug_controls()
	_update_responsive_layout()
	_update_block_visual_layout()


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
	if level_label:
		level_label.size = Vector2(maxf(190.0, size.x * 0.42), 48.0)
		level_label.position = Vector2(size.x - level_label.size.x - pad, pad)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if time_state_label:
		time_state_label.size = Vector2(maxf(150.0, size.x * 0.42), 40.0)
		time_state_label.position = Vector2(size.x - time_state_label.size.x - pad, pad + 50.0)
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
	camera_3d.fov = camera_fov_deg
	camera_3d.rotation_degrees = Vector3(camera_tilt_deg, camera_yaw_deg, 0.0)

	var vertical_fov: float = deg_to_rad(camera_fov_deg)
	var horizontal_fov: float = 2.0 * atan(tan(vertical_fov * 0.5) * aspect)
	var tilt: float = deg_to_rad(absf(camera_tilt_deg))
	var half_depth: float = FRAME_HEIGHT * 0.5 * sin(tilt)
	var distance_for_height: float = (FRAME_HEIGHT * 0.5 * camera_padding) / tan(vertical_fov * 0.5) + half_depth
	var distance_for_width: float = (FRAME_WIDTH * 0.5 * camera_padding) / tan(horizontal_fov * 0.5)
	var distance: float = maxf(distance_for_height, distance_for_width)
	var yaw: float = deg_to_rad(camera_yaw_deg)
	var forward: Vector3 = Vector3(sin(yaw) * cos(tilt), -sin(tilt), -cos(yaw) * cos(tilt))
	camera_3d.position = -forward * distance
	camera_3d.look_at(Vector3.ZERO, Vector3.UP)


func _create_party_pawns() -> void:
	for i in range(party.size()):
		var member: Dictionary = party[i]
		var member_color: Color = member["color"]
		var pawn := Node3D.new()
		pawn.name = "PartyPawn_%s" % member["name"]
		add_child(pawn)
		pawn.position = Vector3(_party_home_x(i), 0.0, PARTY_FRONT_Z if i == active_party else PARTY_BACK_Z)

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
	# The firing member stands in the front row; everyone else waits in the back
	# row at their current x (no horizontal sliding). While the thrown ball drops
	# back, the NEXT member becomes the front member and runs out to the predicted
	# landing spot to catch it, so it steps up to the front row at the same moment
	# the thrower steps back to the rear row. The catch state is held until the
	# turn actually switches so the catcher does not snap back during the handoff.
	var catch_x := _ball_catch_x()
	if catch_x != INF:
		catch_active = true
		catch_target_x = catch_x
	_update_catch_marker()
	var front_index := active_party
	var front_x := shooter_x
	if catch_active:
		front_index = _next_party(active_party)
		front_x = catch_target_x
	for i in range(party_nodes.size()):
		var pawn := party_nodes[i]
		var target_x: float
		var target_z: float
		var target_scale: Vector3
		if i == front_index:
			target_x = front_x
			target_z = PARTY_FRONT_Z
			target_scale = Vector3.ONE
		else:
			target_x = pawn.position.x
			target_z = PARTY_BACK_Z
			target_scale = Vector3(0.82, 0.82, 0.82)
		pawn.position = pawn.position.lerp(Vector3(target_x, 0.0, target_z), 0.24)
		pawn.scale = pawn.scale.lerp(target_scale, 0.24)


func _next_party(index: int) -> int:
	return (index + 1) % party.size()


func _party_home_x(index: int) -> float:
	# Fixed starting slots, spread symmetrically across the back row.
	var count := party.size()
	if count <= 1:
		return 0.0
	return lerpf(-1.45, 1.45, float(index) / float(count - 1))


func _reset_party_positions() -> void:
	for i in range(party_nodes.size()):
		var z := PARTY_FRONT_Z if i == active_party else PARTY_BACK_Z
		party_nodes[i].position = Vector3(_party_home_x(i), 0.0, z)


func _update_catch_marker() -> void:
	# Show a pulsing landing marker at the predicted catch spot the moment the
	# catch is locked in, so the destination is telegraphed before/as the next
	# member runs over to it.
	if not is_instance_valid(catch_marker):
		return
	catch_marker.visible = catch_active
	if not catch_active:
		return
	catch_marker.position = Vector3(catch_target_x, 0.06, PARTY_FRONT_Z)
	var pulse := 1.0 + 0.12 * sin(Time.get_ticks_msec() * 0.012)
	catch_marker.scale = Vector3(pulse, 1.0, pulse)


func _ball_catch_x() -> float:
	# Lock the landing spot once the ball is on its final straight run down to the
	# player line: heading down, already below every block, AND its straight-line
	# path reaches the line without crossing a side wall (no bounce left). The
	# landing is where the ball's collision area just passes the player line.
	# INF means "not catching yet".
	if aiming or balls.is_empty():
		return INF
	var ball: Dictionary = balls[0]
	var pos: Vector2 = ball["pos"]
	var vel: Vector2 = ball["vel"]
	if vel.y <= 0.0 or pos.y < _frontmost_block_edge():
		return INF
	var landing_y := danger_z + ball_radius
	var time_to_line := maxf(0.0, (landing_y - pos.y) / vel.y)
	var raw_x := pos.x + vel.x * time_to_line
	if raw_x < -wall_half_width + ball_radius or raw_x > wall_half_width - ball_radius:
		return INF
	return raw_x


func _frontmost_block_edge() -> float:
	# The floor-facing edge of the block closest to the player (largest z),
	# inflated by the ball radius. A descending ball below this can hit no block.
	# Returns -INF when no blocks remain, so the path is considered clear.
	var edge := -INF
	for block in blocks:
		var half_y := Vector2(block["size"]).y * 0.5
		edge = maxf(edge, Vector2(block["pos"]).y + half_y + ball_radius)
	return edge


func _spawn_blocks() -> void:
	for block in blocks:
		_free_block_gauge(block)
	for child in get_tree().get_nodes_in_group("block_node"):
		child.queue_free()
	blocks.clear()

	for data in BLOCK_DATA:
		var hp: int = int(data["hp"])
		var block_pos := _grid_position(int(data["col"]), int(data["row"]), String(data["rank"]))
		var block: Dictionary = _create_block(block_pos, hp, String(data["rank"]), int(data["icon"]), int(data["col"]), int(data["row"]))
		blocks.append(block)


func _spawn_level_row(row_level: int) -> void:
	var slots := _get_row_slots(row_level)
	var occupied_slots := {}
	var new_blocks: Array[Dictionary] = []
	for i in slots:
		if occupied_slots.has(i):
			continue
		var rank := _get_level_rank(row_level, i)
		var hp := _get_level_hp(row_level, rank, i)
		var icon := _get_rank_icon(row_level, rank, i)
		var block: Dictionary = _create_block(_grid_position(i, 0, rank), hp, rank, icon, i, 0)
		blocks.append(block)
		new_blocks.append(block)
		for occupied in _get_occupied_columns(i, rank):
			occupied_slots[occupied] = true

	# Safety net: a boss span can still cover the only gap. If the row ended up
	# full, drop one of its blocks so an empty column always remains.
	if occupied_slots.size() >= ROW_X.size() and not new_blocks.is_empty():
		var doomed := new_blocks[row_level % new_blocks.size()]
		blocks.erase(doomed)
		_free_block_gauge(doomed)
		var node := doomed.get("node") as Node3D
		if is_instance_valid(node):
			node.queue_free()


func _grid_position(col: int, row: int, rank: String = "") -> Vector2:
	# Fixed grid: cell centers never move with the spread. The gap is changed by
	# resizing the platform (block footprint + tile) instead — see _apply_spread.
	return Vector2(_base_col_x(col, rank), BOARD_TOP + top_pad + float(row) * LEVEL_DROP)


func _base_col_x(col: int, rank: String) -> float:
	# Column x on the fixed grid (shape scaling never moves cell positions).
	var x := float(ROW_X[clampi(col, 0, ROW_X.size() - 1)])
	if rank == "boss" and col < ROW_X.size() - 1:
		x = (float(ROW_X[col]) + float(ROW_X[col + 1])) * 0.5
	return x


func _reposition_block(block: Dictionary) -> void:
	# Recompute world position from the block's logical column + row, so that
	# Col Spread / Row Spread / Top Pad changes apply live and consistently.
	var pos := _grid_position(int(block.get("col", 0)), int(block.get("row", 0)), String(block["rank"]))
	block["pos"] = pos
	var node := block.get("node") as Node3D
	if is_instance_valid(node):
		node.position = Vector3(pos.x, 0.0, pos.y)


func _reposition_blocks() -> void:
	for block in blocks:
		_reposition_block(block)


func _apply_grid_offset() -> void:
	# The tile grid keeps a fixed cell layout; only its row-0 anchor follows
	# top_pad. (Tile sizes are handled in _apply_spread.)
	if is_instance_valid(board_tile_grid):
		board_tile_grid.scale = Vector3.ONE
		board_tile_grid.position = Vector3(0.0, 0.0, BOARD_TOP + top_pad)


func _apply_spread() -> void:
	# Grid/cell positions and the floor tiles stay fixed. Only the monster's foot
	# pedestal — the block footprint (collision + body/cap visual) — is resized by
	# that shape's own scale (rank_scales), which is what changes the gap.
	for block in blocks:
		var s := _rank_scale(String(block["rank"]))
		var base: Vector2 = block.get("base_size", BLOCK_SIZE)
		block["size"] = Vector2(base.x * s, base.y * s)
		var body := block.get("body") as MeshInstance3D
		if is_instance_valid(body):
			body.scale = Vector3(s, 1.0, s)
		var cap := block.get("top_cap") as MeshInstance3D
		if is_instance_valid(cap):
			cap.scale = Vector3(s, 1.0, s)


func _rank_scale(rank: String) -> float:
	return float(rank_scales.get(rank, 1.0))


func _apply_wall_width() -> void:
	# Move only the side walls/rails; block columns keep their spacing, so just the
	# edge padding (gap from the outer columns to the walls) changes.
	if is_instance_valid(left_rail):
		left_rail.position.x = -wall_half_width - 0.48
	if is_instance_valid(right_rail):
		right_rail.position.x = wall_half_width + 0.48


func _apply_wall_top() -> void:
	# Move only the top wall/rail (the ball's top bounce line); blocks are unaffected.
	if is_instance_valid(top_rail):
		top_rail.position.z = wall_top_z - 0.48


func _update_debug_metrics() -> void:
	# Show the ball diameter next to every gap in the same world units so it is
	# obvious whether the ball can thread a gap (gap >= diameter) or will pinball.
	if not is_instance_valid(debug_metrics_label):
		return
	var ball_d := ball_radius * 2.0
	# Grid spacing is fixed; the gap depends on the platform footprint. Use the
	# largest non-boss shape scale (tightest gap) as the reference.
	var rep := 0.0
	for r in ["circle", "square", "triangle", "diamond", "chest"]:
		rep = maxf(rep, _rank_scale(r))
	var col_gap := absf(float(ROW_X[1]) - float(ROW_X[0])) - float(BLOCK_SIZE.x) * rep
	var row_gap := float(LEVEL_DROP) - float(BLOCK_SIZE.y) * rep
	var outer_edge := float(ROW_X[ROW_X.size() - 1]) + float(BLOCK_SIZE.x) * 0.5 * rep
	var side_gap := wall_half_width - outer_edge
	var top_gap := (BOARD_TOP + top_pad - float(BLOCK_SIZE.y) * 0.5 * rep) - wall_top_z
	debug_metrics_label.text = "Orb d %.2f\nCol gap %.2f (%s)\nRow gap %.2f (%s)\nSide gap %.2f (%s)\nTop gap %.2f (%s)" % [
		ball_d,
		col_gap, _gap_mark(col_gap, ball_d),
		row_gap, _gap_mark(row_gap, ball_d),
		side_gap, _gap_mark(side_gap, ball_d),
		top_gap, _gap_mark(top_gap, ball_d),
	]


func _gap_mark(gap: float, ball_d: float) -> String:
	return "pass" if gap >= ball_d else "TIGHT"


func _get_occupied_columns(col: int, rank: String) -> Array[int]:
	var result: Array[int] = []
	var span := BOSS_SPAN if rank == "boss" else 1
	for offset in range(span):
		var occupied_col := col + offset
		if occupied_col < ROW_X.size():
			result.append(occupied_col)
	return result


func _get_row_slots(row_level: int) -> Array[int]:
	var density := 4
	if row_level >= 5:
		density = 5
	# Never fill every column: a new row must always leave at least one empty slot
	# so the orb can pass through it.
	density = mini(density, ROW_X.size() - 1)

	var slots: Array[int] = []
	for i in range(ROW_X.size()):
		slots.append(i)
	while slots.size() > density:
		var remove_index := (row_level + slots.size() * 2) % slots.size()
		slots.remove_at(remove_index)
	if row_level >= 10 and row_level % 5 == 0:
		slots.erase(4)
	return slots


func _get_level_rank(row_level: int, slot_index: int) -> String:
	if row_level >= 10 and row_level % 5 == 0 and slot_index == 3:
		return "boss"
	if row_level >= 6 and row_level % 4 == 0 and (slot_index == 1 or slot_index == 4):
		return "diamond"
	if row_level >= 4 and row_level % 3 == 0 and (slot_index == 2 or slot_index == 3):
		return "triangle"
	if row_level >= 5 and row_level % 5 == 0 and slot_index == 3:
		return "chest"
	if (row_level + slot_index) % 2 == 0:
		return "circle"
	return "square"


func _get_level_hp(row_level: int, rank: String, slot_index: int) -> int:
	var base := 3 + row_level * 2 + (slot_index % 3)
	match rank:
		"circle":
			return base
		"square":
			return base + 2
		"triangle":
			return base + 5
		"diamond":
			return base + 9
		"chest":
			return base + 14
		"boss":
			return base * 2 + 18
		_:
			return base


func _get_rank_icon(row_level: int, rank: String, slot_index: int) -> int:
	match rank:
		"triangle":
			return 2
		"chest":
			return 3
		"boss":
			return 4
		"diamond":
			return 7 + ((row_level + slot_index) % 5)
		"circle":
			return 0 if slot_index % 2 == 0 else 6
		_:
			return 1 if slot_index % 2 == 0 else 5


func _advance_level() -> void:
	level += 1
	_drop_blocks()
	if game_over_enabled and _has_block_reached_player_area():
		game_over = true
		aiming = false
		balls.clear()
		ball_mesh.visible = false
		return
	# Rule off: blocks that breach the player area just vanish instead of ending it.
	_clear_blocks_past_player_area()
	_spawn_level_row(level)


func _clear_blocks_past_player_area() -> void:
	for block in blocks.duplicate():
		var pos: Vector2 = block["pos"]
		var half_height := float(Vector2(block["size"]).y) * 0.5
		if pos.y + half_height >= danger_z:
			blocks.erase(block)
			_free_block_gauge(block)
			var node := block.get("node") as Node3D
			if is_instance_valid(node):
				node.queue_free()


func _drop_blocks() -> void:
	for block in blocks:
		block["row"] = int(block.get("row", 0)) + 1
		_reposition_block(block)


func _has_block_reached_player_area() -> bool:
	# Game over only when a block's leading (player-facing) edge crosses into the
	# player area. danger_z defaults to the firing line (SHOOT_Z) = the player area.
	for block in blocks:
		var pos: Vector2 = block["pos"]
		var half_height := float(Vector2(block["size"]).y) * 0.5
		if pos.y + half_height >= danger_z:
			return true
	return false


func _create_block(pos_2d: Vector2, hp: int, rank: String, icon_frame: int, col: int = 0, row: int = 0) -> Dictionary:
	var root := Node3D.new()
	root.name = "QuestBlock_%s_%d" % [rank, hp]
	root.position = Vector3(pos_2d.x, 0.0, pos_2d.y)
	root.add_to_group("block_node")
	add_child(root)

	var s := _rank_scale(rank)
	var body := MeshInstance3D.new()
	body.mesh = _make_block_mesh(rank)
	body.material_override = _make_block_material(rank)
	body.position.y = _get_block_body_y(rank)
	body.rotation_degrees.y = _get_block_body_yaw(rank)
	body.scale = Vector3(s, 1.0, s)
	root.add_child(body)

	var top_cap := MeshInstance3D.new()
	top_cap.mesh = _make_block_top_cap_mesh(rank)
	top_cap.material_override = _make_block_top_cap_material(rank)
	top_cap.position.y = _get_block_top_cap_y(rank)
	top_cap.rotation_degrees.y = _get_block_body_yaw(rank)
	top_cap.scale = Vector3(s, 1.0, s)
	root.add_child(top_cap)

	var icon := Sprite3D.new()
	icon.texture = icon_texture
	icon.hframes = 4
	icon.vframes = 3
	icon.frame = icon_frame
	icon.pixel_size = _get_block_icon_pixel_size(rank)
	icon.position = _get_block_icon_position(rank)
	icon.no_depth_test = true
	icon.double_sided = true
	root.add_child(icon)

	# HP gauge bar is a 3D billboard; the number is a 2D canvas Label. Both are
	# placed/updated each frame in _update_one_gauge_2d.
	var base_size: Vector2 = BOSS_BLOCK_SIZE if rank == "boss" else BLOCK_SIZE
	var block := {
		"node": root,
		"body": body,
		"top_cap": top_cap,
		"icon": icon,
		"pos": pos_2d,
		"hp": hp,
		"max_hp": hp,
		"rank": rank,
		"col": col,
		"row": row,
		"base_size": base_size,
		"size": Vector2(base_size.x * s, base_size.y * s),
	}
	_attach_gauge_2d(block)
	_update_one_gauge_2d(block)
	return block


func _make_block_mesh(rank: String) -> Mesh:
	# Each rank gets a distinct shape so the visuals match the debug names.
	match rank:
		"circle":
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.55
			cyl.bottom_radius = 0.55
			cyl.height = 0.34
			cyl.radial_segments = 28
			return cyl
		"triangle":
			var tri := CylinderMesh.new()
			tri.top_radius = 0.66
			tri.bottom_radius = 0.66
			tri.height = 0.34
			tri.radial_segments = 3
			return tri
		"diamond":
			var dia := BoxMesh.new()
			dia.size = Vector3(1.0, 0.34, 1.0)
			return dia
		"chest":
			var chest := BoxMesh.new()
			chest.size = Vector3(1.0, 0.42, 0.78)
			return chest
		"boss":
			var boss := BoxMesh.new()
			boss.size = Vector3(2.68, 0.42, 1.04)
			return boss
		_:
			var box := BoxMesh.new()
			box.size = Vector3(1.12, 0.34, 0.86)
			return box


func _make_block_top_cap_mesh(rank: String) -> Mesh:
	# Cap follows the body shape (round/triangular cap for circle/triangle).
	match rank:
		"circle":
			var cap := CylinderMesh.new()
			cap.top_radius = 0.46
			cap.bottom_radius = 0.46
			cap.height = 0.08
			cap.radial_segments = 28
			return cap
		"triangle":
			var cap := CylinderMesh.new()
			cap.top_radius = 0.54
			cap.bottom_radius = 0.54
			cap.height = 0.08
			cap.radial_segments = 3
			return cap
		"boss":
			var cap := BoxMesh.new()
			cap.size = Vector3(2.42, 0.08, 0.86)
			return cap
		"diamond":
			var cap := BoxMesh.new()
			cap.size = Vector3(0.84, 0.08, 0.84)
			return cap
		"chest":
			var cap := BoxMesh.new()
			cap.size = Vector3(0.82, 0.08, 0.6)
			return cap
		_:
			var cap := BoxMesh.new()
			cap.size = Vector3(0.92, 0.08, 0.66)
			return cap


func _make_block_material(rank: String) -> Material:
	var mat := StandardMaterial3D.new()
	match rank:
		"circle":
			mat.albedo_color = Color("#b99a63")
		"triangle":
			mat.albedo_color = Color("#c5a973")
		"diamond":
			mat.albedo_color = Color("#b58cce")
		"boss":
			mat.albedo_color = Color("#d0b27a")
		"chest":
			mat.albedo_color = Color("#c79b58")
		_:
			mat.albedo_color = Color("#c2a56f")
	mat.metallic = 0.0
	mat.roughness = 0.9
	return mat


func _make_block_top_cap_material(rank: String) -> Material:
	var mat := StandardMaterial3D.new()
	match rank:
		"diamond":
			mat.albedo_color = Color("#d6b5ee")
		"boss":
			mat.albedo_color = Color("#e4cf9d")
		"chest":
			mat.albedo_color = Color("#e0ba76")
		_:
			mat.albedo_color = Color("#e0c68e")
	mat.roughness = 0.86
	return mat


func _gauge_color_for_ratio(ratio: float) -> Color:
	# Dark red, going a touch darker as HP drops.
	return Color(0.26, 0.05, 0.06).lerp(Color(0.58, 0.12, 0.13), clampf(ratio, 0.0, 1.0))


func _attach_gauge_2d(block: Dictionary) -> void:
	# Hybrid gauge: the BAR is a 3D billboard (perspective-correct, scales with
	# distance), the NUMBER is a 2D canvas Label (always crisp, constant size).
	if gauge_shader == null:
		gauge_shader = Shader.new()
		gauge_shader.code = GAUGE_SHADER_CODE

	# Parented to the scene root (NOT the block) so the block's hit-scale/yaw never
	# skews or tilts the gauge; it just tracks the block's world point each frame.
	var gauge := Node3D.new()
	gauge.name = "HpGauge"
	add_child(gauge)
	var bar := MeshInstance3D.new()
	bar.mesh = QuadMesh.new()
	var mat := ShaderMaterial.new()
	mat.shader = gauge_shader
	mat.set_shader_parameter("fill_ratio", 1.0)
	mat.set_shader_parameter("fill_color", _gauge_color_for_ratio(1.0))
	mat.set_shader_parameter("bg_color", Color(0.07, 0.05, 0.04, 0.85))
	mat.set_shader_parameter("radius", 0.5)
	bar.material_override = mat
	gauge.add_child(bar)
	block["gauge"] = gauge
	block["gauge_bar"] = bar
	block["gauge_mat"] = mat

	var number := Label.new()
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.add_theme_color_override("font_color", Color.WHITE)
	number.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	gauge_layer.add_child(number)
	block["gauge_number"] = number


func _update_one_gauge_2d(block: Dictionary) -> void:
	if not is_instance_valid(camera_3d):
		return
	var rank := String(block["rank"])
	var pos: Vector2 = block["pos"]
	var head_y := boss_icon_height if rank == "boss" else block_icon_height
	var ratio := clampf(float(int(block["hp"])) / float(maxi(1, int(block.get("max_hp", 1)))), 0.0, 1.0)

	# 3D billboard bar (perspective): sized in world units, faces the camera.
	var gauge := block.get("gauge") as Node3D
	if is_instance_valid(gauge):
		gauge.position = Vector3(pos.x, head_y + gauge_offset_y, pos.y)
		gauge.global_rotation = camera_3d.global_rotation
		var w := gauge_height * (7.0 if rank == "boss" else 4.5)
		var bar := block.get("gauge_bar") as MeshInstance3D
		(bar.mesh as QuadMesh).size = Vector2(w, gauge_height)
		var mat := block.get("gauge_mat") as ShaderMaterial
		mat.set_shader_parameter("aspect", w / gauge_height)
		mat.set_shader_parameter("fill_ratio", ratio)
		mat.set_shader_parameter("fill_color", _gauge_color_for_ratio(ratio))

	# 2D canvas number (constant pixel size, independent position).
	var number := block.get("gauge_number") as Label
	if is_instance_valid(number):
		var nworld := Vector3(pos.x, head_y + number_offset_y, pos.y)
		if camera_3d.is_position_behind(nworld):
			number.visible = false
		else:
			number.visible = true
			var box := Vector2(number_size * 4.0, number_size * 1.6)
			number.add_theme_font_size_override("font_size", int(number_size))
			number.add_theme_constant_override("outline_size", maxi(2, int(number_size * 0.18)))
			number.text = _format_hp(int(block["hp"]))
			number.size = box
			number.position = camera_3d.unproject_position(nworld) - box * 0.5


func _free_block_gauge(block: Dictionary) -> void:
	# Gauge bar and number are parented outside the block, so free them explicitly.
	var gauge := block.get("gauge") as Node3D
	if is_instance_valid(gauge):
		gauge.queue_free()
	var number := block.get("gauge_number") as Label
	if is_instance_valid(number):
		number.queue_free()


func _get_block_body_y(rank: String) -> float:
	return 0.21 if rank == "boss" else 0.17


func _get_block_body_yaw(rank: String) -> float:
	match rank:
		"diamond":
			return 45.0
		"triangle":
			return 180.0  # point a flat edge toward the player, vertex up-board
		_:
			return 0.0


func _get_block_top_cap_y(rank: String) -> float:
	return 0.46 if rank == "boss" else 0.38


func _get_block_icon_pixel_size(rank: String) -> float:
	var base_size := 0.0033 if rank == "boss" else 0.00255
	return base_size * block_icon_scale


func _get_block_icon_position(rank: String) -> Vector3:
	return Vector3(0.0, boss_icon_height if rank == "boss" else block_icon_height, 0.03)


func _update_block_visual_layout() -> void:
	for block in blocks:
		var rank := String(block["rank"])
		var icon := block.get("icon") as Sprite3D
		if is_instance_valid(icon):
			icon.pixel_size = _get_block_icon_pixel_size(rank)
			icon.position = _get_block_icon_position(rank)


func _update_block_billboards() -> void:
	if not is_instance_valid(camera_3d):
		return
	for block in blocks:
		var icon := block.get("icon") as Sprite3D
		if is_instance_valid(icon):
			_face_camera(icon)
		_update_one_gauge_2d(block)


func _face_camera(node: Node3D) -> void:
	var target := camera_3d.global_position
	if node.global_position.distance_squared_to(target) <= 0.0001:
		return
	node.look_at(target, Vector3.UP)


func _reset_ball() -> void:
	balls.clear()
	catch_active = false
	resolving_shot = false
	shot_time = 0.0
	aiming = not game_over
	ball_mesh.visible = aiming
	ball_mesh.position = Vector3(shooter_x, 0.45, SHOOT_Z)


func _update_shooter_from_input() -> void:
	var dir := Input.get_axis("ui_left", "ui_right")
	if absf(dir) > 0.01 and aiming:
		shooter_x = clampf(shooter_x + dir * 0.11, -shooter_limit, shooter_limit)
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
	return _clamp_shot_dir(dir)


func _clamp_shot_dir(dir: Vector2) -> Vector2:
	# Enforce a minimum upward component on the *normalized* vector so the
	# result is idempotent: re-clamping an already-clamped dir is a no-op.
	# This keeps the aim indicator and the fired ball perfectly in sync.
	dir = dir.normalized()
	if dir == Vector2.ZERO:
		return Vector2(0.0, -1.0)
	if dir.y > -MIN_SHOT_DY:
		var sign_x := signf(dir.x) if not is_zero_approx(dir.x) else 1.0
		dir = Vector2(sign_x * sqrt(1.0 - MIN_SHOT_DY * MIN_SHOT_DY), -MIN_SHOT_DY)
	return dir


func _fire_toward(dir: Vector2) -> void:
	if not aiming or game_over:
		return
	dir = _clamp_shot_dir(dir)
	aiming = false
	balls = [{"pos": Vector2(shooter_x, SHOOT_Z), "vel": dir * ball_speed}]
	resolving_shot = true
	shot_time = 0.0


func _update_balls(delta: float) -> void:
	if game_over:
		return
	if balls.is_empty():
		# Resolve a finished shot exactly once. Without this guard, an idle state
		# (out of shots / board cleared) keeps re-calling _finish_shot every frame,
		# which would advance the party turn endlessly.
		if resolving_shot:
			resolving_shot = false
			_finish_shot()
		return

	var ball := balls[0]
	var pos: Vector2 = ball["pos"]
	var vel: Vector2 = ball["vel"]

	# Anti-stall (preset-driven): after a while speed the orb up so slow bounce
	# loops resolve faster, and hard-cap the shot so any loop always terminates.
	shot_time += delta
	if stall_preset != "off":
		if stall_hardcap > 0.0 and shot_time >= stall_hardcap:
			shooter_x = clampf(pos.x, -wall_half_width + ball_radius, wall_half_width - ball_radius)
			balls.clear()
			return
		if shot_time > stall_start and vel.length() > 0.0:
			var target := ball_speed * clampf(1.0 + (shot_time - stall_start) * stall_speedup, 1.0, 4.0)
			if vel.length() < target:
				vel = vel.normalized() * target

	var step_count := maxi(1, ceili((vel.length() * delta) / BALL_COLLISION_STEP))
	var step_delta := delta / float(step_count)

	for _i in range(step_count):
		var previous_pos := pos
		pos += vel * step_delta

		if pos.x < -wall_half_width + ball_radius:
			pos.x = -wall_half_width + ball_radius
			vel.x = absf(vel.x)
		if pos.x > wall_half_width - ball_radius:
			pos.x = wall_half_width - ball_radius
			vel.x = -absf(vel.x)
		if pos.y < wall_top_z:
			pos.y = wall_top_z
			vel.y = absf(vel.y)
		# The ball "lands" the moment its collision area passes the player line
		# (danger_z), on the way down — not all the way at the floor. Record the
		# exact x at that crossing so the next shot / catcher line up with it.
		var landing_y := danger_z + ball_radius
		if vel.y > 0.0 and pos.y >= landing_y:
			var drop := pos.y - previous_pos.y
			var t := (landing_y - previous_pos.y) / drop if drop > 0.0 else 1.0
			shooter_x = lerpf(previous_pos.x, pos.x, t)
			balls.clear()
			return

		for block in blocks:
			var collision := _get_ball_block_collision(previous_pos, pos, block)
			if bool(collision["hit"]):
				var normal := Vector2(collision["normal"])
				pos = Vector2(collision["pos"])
				if absf(normal.x) > 0.0:
					vel.x *= -1.0
				if absf(normal.y) > 0.0:
					vel.y *= -1.0
				_damage_block(block)
				break

	ball["pos"] = pos
	ball["vel"] = vel
	balls[0] = ball
	ball_mesh.position = Vector3(pos.x, 0.52, pos.y)


func _get_ball_block_collision(previous_pos: Vector2, pos: Vector2, block: Dictionary) -> Dictionary:
	var half := Vector2(block["size"]) * 0.5 + Vector2(ball_radius, ball_radius)
	var block_pos := Vector2(block["pos"])
	var local := pos - block_pos
	var normal := _get_swept_block_normal(previous_pos - block_pos, local, half)
	if normal == Vector2.ZERO:
		if absf(local.x) > half.x or absf(local.y) > half.y:
			return {"hit": false}
		normal = _get_penetration_normal(local, half)

	var corrected_pos := pos
	if normal.x < 0.0:
		corrected_pos.x = block_pos.x - half.x - COLLISION_EPSILON
	elif normal.x > 0.0:
		corrected_pos.x = block_pos.x + half.x + COLLISION_EPSILON
	elif normal.y < 0.0:
		corrected_pos.y = block_pos.y - half.y - COLLISION_EPSILON
	elif normal.y > 0.0:
		corrected_pos.y = block_pos.y + half.y + COLLISION_EPSILON

	return {
		"hit": true,
		"normal": normal,
		"pos": corrected_pos,
	}


func _get_swept_block_normal(local_previous: Vector2, local_current: Vector2, half: Vector2) -> Vector2:
	var movement := local_current - local_previous
	if movement.length_squared() <= 0.0:
		return Vector2.ZERO

	var x_entry := -INF
	var y_entry := -INF
	var x_exit := INF
	var y_exit := INF

	if movement.x > 0.0:
		x_entry = (-half.x - local_previous.x) / movement.x
		x_exit = (half.x - local_previous.x) / movement.x
	elif movement.x < 0.0:
		x_entry = (half.x - local_previous.x) / movement.x
		x_exit = (-half.x - local_previous.x) / movement.x

	if movement.y > 0.0:
		y_entry = (-half.y - local_previous.y) / movement.y
		y_exit = (half.y - local_previous.y) / movement.y
	elif movement.y < 0.0:
		y_entry = (half.y - local_previous.y) / movement.y
		y_exit = (-half.y - local_previous.y) / movement.y

	var entry_time := maxf(x_entry, y_entry)
	var exit_time := minf(x_exit, y_exit)
	if entry_time > exit_time or entry_time < 0.0 or entry_time > 1.0:
		return Vector2.ZERO

	if x_entry > y_entry:
		return Vector2.LEFT if movement.x > 0.0 else Vector2.RIGHT
	return Vector2.UP if movement.y > 0.0 else Vector2.DOWN


func _get_penetration_normal(local: Vector2, half: Vector2) -> Vector2:
	var overlap_x := half.x - absf(local.x)
	var overlap_y := half.y - absf(local.y)
	if overlap_x < overlap_y:
		return Vector2.LEFT if local.x < 0.0 else Vector2.RIGHT
	return Vector2.UP if local.y < 0.0 else Vector2.DOWN


func _damage_block(block: Dictionary) -> void:
	var damage := _party_damage()
	block["hp"] = int(block["hp"]) - damage
	combo += 1
	score += 10 + combo * 3
	_spawn_damage_text(Vector2(block["pos"]), damage)
	if int(block["hp"]) <= 0:
		score += 100
		_spawn_break_burst(Vector2(block["pos"]), String(block["rank"]))
		blocks.erase(block)
		_free_block_gauge(block)
		var block_node: Node = block["node"]
		block_node.queue_free()
	else:
		_animate_block_hit(block)
		_update_one_gauge_2d(block)


func _spawn_damage_text(pos_2d: Vector2, damage: int) -> void:
	var damage_label := Label3D.new()
	damage_label.name = "DamageText"
	damage_label.text = "-%d" % damage
	damage_label.font_size = 74
	damage_label.outline_size = 8
	damage_label.modulate = Color("#fff2a8")
	damage_label.position = Vector3(pos_2d.x, 1.08, pos_2d.y + 0.12)
	damage_label.rotation_degrees.x = -90.0
	damage_label.no_depth_test = true
	add_child(damage_label)

	var target_pos := damage_label.position + Vector3(randf_range(-0.14, 0.14), 0.0, -0.45)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "position", target_pos, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(damage_label, "scale", Vector3(1.35, 1.35, 1.35), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(damage_label, "modulate:a", 0.0, 0.38).set_delay(0.12)

	get_tree().create_timer(0.55).timeout.connect(func() -> void:
		if is_instance_valid(damage_label):
			damage_label.queue_free()
	)


func _animate_block_hit(block: Dictionary) -> void:
	var block_node := block["node"] as Node3D
	var body := block["body"] as MeshInstance3D
	if block_node == null or body == null:
		return

	var flash := StandardMaterial3D.new()
	flash.albedo_color = Color("#fff2a8")
	flash.emission_enabled = true
	flash.emission = Color("#ffe06a")
	flash.emission_energy_multiplier = 1.6
	body.material_overlay = flash

	# Tweens are bound to their own nodes so that if the block is destroyed by a
	# later hit in the same shot, the tween is auto-killed (no "freed capture"/
	# freed-object errors from the deferred overlay clear).
	var tween := block_node.create_tween()
	tween.tween_property(block_node, "scale", Vector3(1.12, 1.0, 1.12), 0.045)
	tween.tween_property(block_node, "scale", Vector3.ONE, 0.09)

	var clear_tween := body.create_tween()
	clear_tween.tween_interval(0.08)
	clear_tween.tween_callback(func() -> void:
		body.material_overlay = null
	)


func _spawn_break_burst(pos_2d: Vector2, rank: String) -> void:
	var burst_root := Node3D.new()
	burst_root.name = "BreakBurst_%s" % rank
	burst_root.position = Vector3(pos_2d.x, 0.58, pos_2d.y)
	add_child(burst_root)

	var shard_mat := StandardMaterial3D.new()
	shard_mat.albedo_color = Color("#ffd166")
	shard_mat.emission_enabled = true
	shard_mat.emission = Color("#ff9f1c")
	shard_mat.emission_energy_multiplier = 0.9

	for i in range(8):
		var shard := MeshInstance3D.new()
		var shard_mesh := BoxMesh.new()
		shard_mesh.size = Vector3(0.12, 0.08, 0.12)
		shard.mesh = shard_mesh
		shard.material_override = shard_mat
		shard.position = Vector3.ZERO
		burst_root.add_child(shard)

		var angle := TAU * float(i) / 8.0 + randf_range(-0.18, 0.18)
		var distance := randf_range(0.42, 0.78)
		var target := Vector3(cos(angle) * distance, randf_range(0.15, 0.42), sin(angle) * distance)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(shard, "position", target, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(shard, "scale", Vector3.ZERO, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	get_tree().create_timer(0.36).timeout.connect(func() -> void:
		if is_instance_valid(burst_root):
			burst_root.queue_free()
	)


func _party_damage() -> int:
	match active_party:
		0:
			return 3
		1:
			return 5
		_:
			return 4


func _finish_shot() -> void:
	if game_over:
		return
	combo = 0
	# Hand the turn to the member that just caught the ball, even when the game
	# ends. Otherwise catch_active clears with active_party still on the thrower,
	# and the thrower snaps back to the front row (which looked like a reset).
	active_party = _next_party(active_party)
	catch_active = false
	# The orb never runs out — every shot advances a level and re-arms the next
	# party member, so play cycles endlessly (unless the Game Over rule is on).
	_advance_level()
	if game_over:
		return
	_reset_ball()


func _restart_board() -> void:
	score = 2057
	combo = 0
	active_party = 0
	level = 1
	game_over = false
	shooter_x = _party_home_x(active_party)
	_reset_party_positions()
	_spawn_blocks()
	_reset_ball()


func _update_aim_line() -> void:
	if not aiming:
		for marker in aim_markers:
			marker.visible = false
		return
	# Simulate with the SAME step size + collision/landing logic as the real ball
	# (_update_balls), so the indicator never shows passing a gap the ball can't.
	var dir := _screen_point_to_shot_dir(get_viewport().get_mouse_position())
	var pos := Vector2(shooter_x, SHOOT_Z)
	var vel := dir
	var landing_y := danger_z + ball_radius
	var marker_spacing := 0.55
	var dist_acc := 0.0
	var placed := 0
	var steps := 0
	while placed < aim_markers.size() and steps < 200:
		steps += 1
		var prev := pos
		pos += vel * BALL_COLLISION_STEP
		if pos.x < -wall_half_width + ball_radius:
			pos.x = -wall_half_width + ball_radius
			vel.x = absf(vel.x)
		if pos.x > wall_half_width - ball_radius:
			pos.x = wall_half_width - ball_radius
			vel.x = -absf(vel.x)
		if pos.y < wall_top_z:
			pos.y = wall_top_z
			vel.y = absf(vel.y)
		if vel.y > 0.0 and pos.y >= landing_y:
			break
		for block in blocks:
			var collision := _get_ball_block_collision(prev, pos, block)
			if bool(collision["hit"]):
				var normal := Vector2(collision["normal"])
				pos = Vector2(collision["pos"])
				if absf(normal.x) > 0.0:
					vel.x *= -1.0
				if absf(normal.y) > 0.0:
					vel.y *= -1.0
				break
		dist_acc += BALL_COLLISION_STEP
		if dist_acc >= marker_spacing:
			dist_acc -= marker_spacing
			var marker := aim_markers[placed]
			marker.visible = true
			marker.position = Vector3(pos.x, 0.64, pos.y)
			marker.scale = Vector3.ONE * (0.75 + float(placed) * 0.035)
			placed += 1
	for i in range(placed, aim_markers.size()):
		aim_markers[i].visible = false


func _update_ui() -> void:
	score_label.text = "STAR %d" % score
	level_label.text = "LV %d" % level
	combo_label.text = ("COMBO x%d" % combo) if combo > 1 else ""
	var member: Dictionary = party[active_party]
	party_label.text = "%s  /  %s TURN" % [member["name"], member["class"]]
	party_label.add_theme_color_override("font_color", member["color"])
	status_label.text = "Drag or click to throw the orb. Esc resets."
	if game_over:
		status_label.text = "Quest line reached the party. Esc resets."
	_update_time_state_label()


func _update_time_state_label() -> void:
	# Top-right time-state icon: shows the in-flight shot timer, and a fast-forward
	# icon once the anti-stall speed-up kicks in.
	if not is_instance_valid(time_state_label):
		return
	if balls.is_empty():
		time_state_label.visible = false
		return
	time_state_label.visible = true
	var sped_up := stall_preset != "off" and shot_time > stall_start
	if sped_up:
		var mult := clampf(1.0 + (shot_time - stall_start) * stall_speedup, 1.0, 4.0)
		time_state_label.add_theme_color_override("font_color", Color("#ffd34d"))
		time_state_label.text = ">>  x%.1f  %0.1fs" % [mult, shot_time]
	else:
		time_state_label.add_theme_color_override("font_color", Color("#7adfff"))
		time_state_label.text = "(>)  %0.1fs" % shot_time


func _format_hp(hp: int) -> String:
	if hp >= 1000000:
		return "%dM" % int(hp / 1000000.0)
	if hp >= 1000:
		return "%dK" % int(hp / 1000.0)
	return str(hp)
