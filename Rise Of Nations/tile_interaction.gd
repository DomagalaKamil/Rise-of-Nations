extends Node2D

const ICON_GRID_SIZE := Vector2i(3, 3)
const BUILDING_ICON_DISPLAY_SIZE := Vector2(64, 64)

const BUILDING_ICONS := {
	"castle": Vector2i(0, 0),
	"village": Vector2i(1, 0),
	"mine": Vector2i(2, 0),
	"farm": Vector2i(0, 1),
	"fishing": Vector2i(1, 1),
	"sawmill": Vector2i(2, 1),
}

const BUILDING_LABELS := {
	"castle": "Castle",
	"village": "Village",
	"mine": "Mine",
	"farm": "Farm",
	"fishing": "Fishing",
	"sawmill": "Sawmill",
}

const TERRAIN_BY_ATLAS_COORDS := {
	Vector2i(0, 0): "grass",
	Vector2i(1, 0): "forest",
	Vector2i(2, 0): "mountain",
	Vector2i(3, 0): "lake",
	Vector2i(0, 1): "desert",
	Vector2i(1, 1): "rocks",
	Vector2i(2, 1): "swamp",
	Vector2i(3, 1): "wheat",
	Vector2i(0, 2): "silver",
	Vector2i(1, 2): "gold",
}

const TERRAIN_LABELS := {
	"grass": "Field of grass",
	"wheat": "Field of wheat",
	"forest": "Field of forest",
	"rocks": "Field of rocks",
	"mountain": "Field of mountain",
	"lake": "Field of lake",
	"gold": "Field of gold",
	"silver": "Field of silver",
	"desert": "Field of desert",
	"swamp": "Field of swamp",
}

const ALLOWED_BUILDINGS_BY_TERRAIN := {
	"grass": ["village", "castle"],
	"wheat": ["farm"],
	"forest": ["sawmill"],
	"lake": ["fishing"],
	"gold": ["mine"],
	"silver": ["mine"],
	"swamp": [],
	"rocks": [],
	"mountain": [],
	"desert": [],
}

const MAX_BUILDINGS_BY_TERRAIN := {
	"grass": 3,
}

@onready var tile_map_layer: TileMapLayer = $Node2D/TileMapLayer

var building_icons_texture: Texture2D = preload("res://building_icons.png")
var selected_cell := Vector2i.ZERO
var selected_terrain := ""
var placed_buildings: Dictionary = {}
var menu_layer: CanvasLayer
var menu_panel: PanelContainer
var menu_title: Label
var menu_buttons: VBoxContainer
var marker_layer: Node2D
var camera: Camera2D


func _ready() -> void:
	_create_build_menu()
	_create_marker_layer()
	_center_camera_on_map()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var world_position := get_global_mouse_position()
			var cell := tile_map_layer.local_to_map(tile_map_layer.to_local(world_position))
			_try_show_build_menu(cell, get_viewport().get_mouse_position())
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_hide_build_menu()


func _create_build_menu() -> void:
	menu_layer = CanvasLayer.new()
	add_child(menu_layer)

	menu_panel = PanelContainer.new()
	menu_panel.visible = false
	menu_panel.custom_minimum_size = Vector2(210, 0)
	menu_layer.add_child(menu_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	menu_panel.add_child(margin)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	margin.add_child(list)

	menu_title = Label.new()
	menu_title.text = "Build"
	list.add_child(menu_title)

	menu_buttons = VBoxContainer.new()
	menu_buttons.add_theme_constant_override("separation", 4)
	list.add_child(menu_buttons)

	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(_hide_build_menu)
	list.add_child(cancel_button)


func _create_marker_layer() -> void:
	marker_layer = Node2D.new()
	marker_layer.name = "BuildingMarkers"
	add_child(marker_layer)


func _center_camera_on_map() -> void:
	camera = Camera2D.new()
	camera.name = "Camera2D"
	add_child(camera)

	var used_cells := tile_map_layer.get_used_cells()
	if used_cells.is_empty():
		camera.global_position = Vector2.ZERO
	else:
		var min_position := Vector2(INF, INF)
		var max_position := Vector2(-INF, -INF)

		for cell in used_cells:
			var tile_position := tile_map_layer.to_global(tile_map_layer.map_to_local(cell))
			min_position = min_position.min(tile_position)
			max_position = max_position.max(tile_position)

		camera.global_position = (min_position + max_position) / 2.0

	camera.enabled = true
	camera.make_current()


func _try_show_build_menu(cell: Vector2i, viewport_position: Vector2) -> void:
	var terrain := _get_terrain_for_cell(cell)
	if terrain == "":
		_hide_build_menu()
		return

	selected_cell = cell
	selected_terrain = terrain
	call_deferred("_refresh_build_menu")
	menu_panel.position = viewport_position + Vector2(12, 12)
	menu_panel.visible = true


func _refresh_build_menu() -> void:
	for child in menu_buttons.get_children():
		child.queue_free()

	var terrain_label: String = TERRAIN_LABELS.get(selected_terrain, selected_terrain.capitalize())
	menu_title.text = terrain_label

	var existing_buildings: Array = placed_buildings.get(selected_cell, [])
	var max_buildings := _get_max_buildings_for_terrain(selected_terrain)
	var allowed_buildings: Array = ALLOWED_BUILDINGS_BY_TERRAIN.get(selected_terrain, [])

	if allowed_buildings.is_empty():
		_add_disabled_menu_label("No buildings available")
		return

	if existing_buildings.size() >= max_buildings:
		_add_disabled_menu_label("Building limit reached")
		return

	for building_name in allowed_buildings:
		var button := Button.new()
		button.text = BUILDING_LABELS.get(building_name, building_name.capitalize())
		button.pressed.connect(_on_building_pressed.bind(building_name))
		menu_buttons.add_child(button)


func _add_disabled_menu_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = Color(1.0, 1.0, 1.0, 0.65)
	menu_buttons.add_child(label)


func _hide_build_menu() -> void:
	menu_panel.visible = false


func _on_building_pressed(building_name: String) -> void:
	var existing_buildings: Array = placed_buildings.get(selected_cell, [])
	var max_buildings := _get_max_buildings_for_terrain(selected_terrain)

	if existing_buildings.size() >= max_buildings:
		call_deferred("_refresh_build_menu")
		return

	existing_buildings.append(building_name)
	placed_buildings[selected_cell] = existing_buildings
	_add_building_icon(selected_cell, building_name, existing_buildings.size() - 1)
	call_deferred("_refresh_build_menu")


func _add_building_icon(cell: Vector2i, building_name: String, index: int) -> void:
	var icon_coords: Vector2i = BUILDING_ICONS.get(building_name, Vector2i.ZERO)
	var texture_size := building_icons_texture.get_size()
	var icon_cell_size := Vector2(texture_size.x / ICON_GRID_SIZE.x, texture_size.y / ICON_GRID_SIZE.y)
	var icon_position := Vector2(icon_coords.x * icon_cell_size.x, icon_coords.y * icon_cell_size.y)

	var atlas := AtlasTexture.new()
	atlas.atlas = building_icons_texture
	atlas.region = Rect2(icon_position, icon_cell_size)

	var sprite := Sprite2D.new()
	sprite.name = "Building_%s_%s_%s" % [cell.x, cell.y, index]
	sprite.texture = atlas
	sprite.scale = BUILDING_ICON_DISPLAY_SIZE / icon_cell_size
	sprite.centered = true

	var tile_center := tile_map_layer.to_global(tile_map_layer.map_to_local(cell))
	sprite.global_position = tile_center + _get_building_icon_offset(index)
	marker_layer.add_child(sprite)


func _get_building_icon_offset(index: int) -> Vector2:
	var spacing := 70.0
	match index:
		0:
			return Vector2.ZERO
		1:
			return Vector2(-spacing, 28)
		2:
			return Vector2(spacing, 28)
		_:
			return Vector2.ZERO


func _get_terrain_for_cell(cell: Vector2i) -> String:
	if tile_map_layer.get_cell_source_id(cell) == -1:
		return ""

	var atlas_coords := tile_map_layer.get_cell_atlas_coords(cell)
	return TERRAIN_BY_ATLAS_COORDS.get(atlas_coords, "")


func _get_max_buildings_for_terrain(terrain: String) -> int:
	return MAX_BUILDINGS_BY_TERRAIN.get(terrain, 1)
