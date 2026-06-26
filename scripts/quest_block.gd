extends Node3D
class_name QuestBlock

const BLOCK_COLLISION_LAYER := 2
const BODY_Y := 0.17
const BOSS_BODY_Y := 0.21
const BODY_HEIGHT := 0.34
const CHEST_BODY_HEIGHT := 0.42
const BOSS_BODY_HEIGHT := 0.42

# Blockbench/GLB source for the block body shapes (assets/blockbench/quest_blocks.bbmodel
# is exported here). One mesh per rank, named by rank. Procedural fallback below keeps the
# game runnable if the GLB is missing or not yet imported.
const BLOCK_MODEL_PATH := "res://assets/models/quest_blocks.glb"
static var _model_meshes: Dictionary = {}
static var _model_loaded := false

var rank := "square"
var icon_frame := 0
var icon_texture: Texture2D
var body: MeshInstance3D
var top_cap: MeshInstance3D
var icon: Sprite3D
var collision_body: StaticBody3D
var collision_shape: CollisionShape3D


func setup(block_rank: String, frame: int, texture: Texture2D, visual_scale: float, icon_pixel_size: float, icon_height: float) -> void:
	rank = block_rank
	icon_frame = frame
	icon_texture = texture
	_clear_children()
	_create_visuals(visual_scale, icon_pixel_size, icon_height)
	_create_collision(visual_scale)


func set_visual_scale(visual_scale: float) -> void:
	if is_instance_valid(body):
		body.scale = Vector3(visual_scale, 1.0, visual_scale)
	if is_instance_valid(top_cap):
		top_cap.scale = Vector3(visual_scale, 1.0, visual_scale)
	_create_collision(visual_scale)


func update_icon_layout(icon_pixel_size: float, icon_height: float) -> void:
	if is_instance_valid(icon):
		icon.pixel_size = icon_pixel_size
		icon.position = Vector3(0.0, icon_height, 0.03)


func collision_front_extent(visual_scale: float) -> float:
	match rank:
		"circle":
			return 0.55 * visual_scale
		"triangle":
			return 0.33 * visual_scale
		"diamond":
			return sqrt(2.0) * 0.5 * visual_scale
		"chest":
			return 0.39 * visual_scale
		"boss":
			return 0.52 * visual_scale
		_:
			return 0.43 * visual_scale


func footprint_size(visual_scale: float) -> Vector2:
	match rank:
		"circle":
			return Vector2.ONE * 1.10 * visual_scale
		"triangle":
			var r := 0.66 * visual_scale
			return Vector2(sqrt(3.0) * r, 1.5 * r)
		"diamond":
			var d := sqrt(2.0) * visual_scale
			return Vector2(d, d)
		"chest":
			return Vector2(1.0, 0.78) * visual_scale
		"boss":
			return Vector2(2.68, 1.04) * visual_scale
		_:
			return Vector2(1.12, 0.86) * visual_scale


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()


func _create_visuals(visual_scale: float, icon_pixel_size: float, icon_height: float) -> void:
	body = MeshInstance3D.new()
	body.name = "StonePedestal"
	body.mesh = _make_block_mesh()
	body.material_override = _make_block_material()
	body.position.y = _body_center_y()
	body.rotation_degrees.y = _body_yaw()
	body.scale = Vector3(visual_scale, 1.0, visual_scale)
	add_child(body)

	top_cap = MeshInstance3D.new()
	top_cap.name = "PedestalTop"
	top_cap.mesh = _make_block_top_cap_mesh()
	top_cap.material_override = _make_block_top_cap_material()
	top_cap.position.y = 0.46 if rank == "boss" else 0.38
	top_cap.rotation_degrees.y = _body_yaw()
	top_cap.scale = Vector3(visual_scale, 1.0, visual_scale)
	add_child(top_cap)

	icon = Sprite3D.new()
	icon.name = "CharacterSprite"
	icon.texture = icon_texture
	icon.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.hframes = 4
	icon.vframes = 3
	icon.frame = icon_frame
	icon.pixel_size = icon_pixel_size
	icon.position = Vector3(0.0, icon_height, 0.03)
	icon.no_depth_test = false
	icon.double_sided = true
	add_child(icon)


func _create_collision(visual_scale: float) -> void:
	if is_instance_valid(collision_body):
		remove_child(collision_body)
		collision_body.queue_free()

	collision_body = StaticBody3D.new()
	collision_body.name = "CollisionBody"
	collision_body.collision_layer = BLOCK_COLLISION_LAYER
	collision_body.collision_mask = 0
	collision_body.set_meta("quest_block", self)
	add_child(collision_body)

	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape"
	collision_shape.shape = _make_collision_shape(visual_scale)
	collision_shape.position.y = _body_center_y()
	if rank == "diamond":
		collision_shape.rotation_degrees.y = 45.0
	collision_body.add_child(collision_shape)


func _make_collision_shape(visual_scale: float) -> Shape3D:
	match rank:
		"circle":
			var shape := CylinderShape3D.new()
			shape.radius = 0.55 * visual_scale
			shape.height = _body_height()
			return shape
		"triangle":
			return _make_triangular_prism_shape(0.66 * visual_scale)
		"chest":
			var shape := BoxShape3D.new()
			shape.size = Vector3(1.0 * visual_scale, _body_height(), 0.78 * visual_scale)
			return shape
		"boss":
			var shape := BoxShape3D.new()
			shape.size = Vector3(2.68 * visual_scale, _body_height(), 1.04 * visual_scale)
			return shape
		_:
			var shape := BoxShape3D.new()
			shape.size = Vector3(1.0 if rank == "diamond" else 1.12, _body_height(), 1.0 if rank == "diamond" else 0.86) * Vector3(visual_scale, 1.0, visual_scale)
			return shape


func _make_triangular_prism_shape(radius: float) -> ConvexPolygonShape3D:
	var shape := ConvexPolygonShape3D.new()
	var base_x := sqrt(3.0) * 0.5 * radius
	var half_height := _body_height() * 0.5
	var y0 := -half_height
	var y1 := half_height
	var points := PackedVector3Array([
		Vector3(0.0, y0, -radius),
		Vector3(base_x, y0, radius * 0.5),
		Vector3(-base_x, y0, radius * 0.5),
		Vector3(0.0, y1, -radius),
		Vector3(base_x, y1, radius * 0.5),
		Vector3(-base_x, y1, radius * 0.5),
	])
	shape.points = points
	return shape


static func _ensure_model_loaded() -> void:
	if _model_loaded:
		return
	_model_loaded = true
	if not ResourceLoader.exists(BLOCK_MODEL_PATH):
		return
	var packed: PackedScene = load(BLOCK_MODEL_PATH)
	if packed == null:
		return
	var inst := packed.instantiate()
	for child in inst.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := child as MeshInstance3D
		if mesh_node.mesh != null:
			_model_meshes[String(mesh_node.name).to_lower()] = mesh_node.mesh
	inst.free()


func _model_mesh_for_rank() -> Mesh:
	_ensure_model_loaded()
	if _model_meshes.is_empty():
		return null
	if _model_meshes.has(rank):
		return _model_meshes[rank]
	for key in _model_meshes.keys():
		if String(key).contains(rank):
			return _model_meshes[key]
	return null


func _make_block_mesh() -> Mesh:
	var model_mesh := _model_mesh_for_rank()
	if model_mesh != null:
		return model_mesh
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


func _make_block_top_cap_mesh() -> Mesh:
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


func _make_block_material() -> Material:
	var mat := StandardMaterial3D.new()
	match rank:
		"circle":
			mat.albedo_color = Color("#756a55")
		"triangle":
			mat.albedo_color = Color("#8a6a35")
		"diamond":
			mat.albedo_color = Color("#756b72")
		"boss":
			mat.albedo_color = Color("#74634b")
		"chest":
			mat.albedo_color = Color("#6a4322")
		_:
			mat.albedo_color = Color("#7b684e")
	mat.metallic = 0.0
	mat.roughness = 0.96
	return mat


func _make_block_top_cap_material() -> Material:
	var mat := StandardMaterial3D.new()
	match rank:
		"diamond":
			mat.albedo_color = Color("#9a8f7e")
		"boss":
			mat.albedo_color = Color("#97866a")
		"chest":
			mat.albedo_color = Color("#8a5528")
		_:
			mat.albedo_color = Color("#9a8562")
	mat.roughness = 0.92
	return mat


func _body_yaw() -> float:
	match rank:
		"diamond":
			return 45.0
		"triangle":
			return 180.0
		_:
			return 0.0


func _body_center_y() -> float:
	return BOSS_BODY_Y if rank == "boss" else BODY_Y


func _body_height() -> float:
	match rank:
		"boss":
			return BOSS_BODY_HEIGHT
		"chest":
			return CHEST_BODY_HEIGHT
		_:
			return BODY_HEIGHT
