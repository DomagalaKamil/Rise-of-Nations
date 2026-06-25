extends Node2D

const MAP_WIDTH := 20
const MAP_HEIGHT := 10
const MAP_TILE_COUNT := MAP_WIDTH * MAP_HEIGHT
const TILE_SOURCE_ID := 0
const PLAYER_OWNER := "player"
const NEUTRAL_OWNER := "neutral"
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

const TERRAIN_ATLAS_COORDS := {
	"grass": Vector2i(0, 0),
	"forest": Vector2i(1, 0),
	"mountain": Vector2i(2, 0),
	"lake": Vector2i(3, 0),
	"desert": Vector2i(0, 1),
	"rocks": Vector2i(1, 1),
	"swamp": Vector2i(2, 1),
	"wheat": Vector2i(3, 1),
	"silver": Vector2i(0, 2),
	"gold": Vector2i(1, 2),
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

const TERRAIN_WEIGHTS := [
	{"terrain": "grass", "weight": 45},
	{"terrain": "forest", "weight": 15},
	{"terrain": "lake", "weight": 10},
	{"terrain": "wheat", "weight": 13},
	{"terrain": "swamp", "weight": 6},
	{"terrain": "rocks", "weight": 8},
	{"terrain": "mountain", "weight": 5},
	{"terrain": "silver", "weight": 4},
	{"terrain": "gold", "weight": 2},
]

const MINEABLE_TERRAINS := ["rocks", "silver", "gold"]
const RESOURCE_TERRAINS := ["rocks", "silver", "gold"]

const ALLOWED_BUILDINGS_BY_TERRAIN := {
	"grass": ["village", "castle"],
	"wheat": ["farm"],
	"forest": ["sawmill"],
	"lake": ["fishing"],
	"gold": ["mine"],
	"silver": ["mine"],
	"rocks": ["mine"],
	"swamp": [],
	"mountain": [],
	"desert": [],
}

const MAX_BUILDINGS_BY_TERRAIN := {
	"grass": 3,
}

const STARTER_BUILDINGS := ["castle", "village", "village"]

@onready var tile_map_layer: TileMapLayer = $Node2D/TileMapLayer

var building_icons_texture: Texture2D = preload("res://art/building_icons.png")
var rng := RandomNumberGenerator.new()
var selected_cell := Vector2i.ZERO
var selected_terrain := ""
var map_tiles: Dictionary = {}
var placed_buildings: Dictionary = {}
var menu_layer: CanvasLayer
var menu_panel: PanelContainer
var menu_title: Label
var menu_buttons: VBoxContainer
var marker_layer: Node2D
var camera: Camera2D


func _ready() -> void:
	rng.randomize()
	_create_build_menu()
	_create_marker_layer()
	_generate_map()
	_ensure_starter_grass_tiles()
	_place_starter_buildings()
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


func _generate_map() -> void:
	map_tiles.clear()
	placed_buildings.clear()
	tile_map_layer.clear()
	_clear_building_icons()

	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var cell := Vector2i(x, y)
			var terrain := _pick_weighted_terrain()
			map_tiles[cell] = _create_tile_data(terrain)
			tile_map_layer.set_cell(cell, TILE_SOURCE_ID, TERRAIN_ATLAS_COORDS[terrain])


func _ensure_starter_grass_tiles() -> void:
	var grass_count := 0
	for cell in map_tiles.keys():
		if map_tiles[cell]["terrain_type"] == "grass":
			grass_count += 1

	if grass_count >= STARTER_BUILDINGS.size():
		return

	var preferred_cells := [
		Vector2i(MAP_WIDTH / 2, MAP_HEIGHT / 2),
		Vector2i(MAP_WIDTH / 2 - 1, MAP_HEIGHT / 2),
		Vector2i(MAP_WIDTH / 2 + 1, MAP_HEIGHT / 2),
		Vector2i(MAP_WIDTH / 2, MAP_HEIGHT / 2 - 1),
		Vector2i(MAP_WIDTH / 2, MAP_HEIGHT / 2 + 1),
	]

	for cell in preferred_cells:
		if grass_count >= STARTER_BUILDINGS.size():
			return
		if map_tiles.has(cell) and map_tiles[cell]["terrain_type"] != "grass":
			_set_cell_terrain(cell, "grass")
			grass_count += 1


func _set_cell_terrain(cell: Vector2i, terrain: String) -> void:
	map_tiles[cell] = _create_tile_data(terrain)
	tile_map_layer.set_cell(cell, TILE_SOURCE_ID, TERRAIN_ATLAS_COORDS[terrain])


func _create_tile_data(terrain: String) -> Dictionary:
	var resource_type := ""
	if terrain in RESOURCE_TERRAINS:
		resource_type = terrain

	return {
		"terrain_type": terrain,
		"resource_type": resource_type,
		"building_type": "",
		"buildings": [],
		"tile_owner": NEUTRAL_OWNER,
		"movement_cost": 1,
		"mineable": terrain in MINEABLE_TERRAINS,
	}


func _pick_weighted_terrain() -> String:
	var total_weight := 0
	for entry in TERRAIN_WEIGHTS:
		total_weight += entry["weight"]

	var roll := rng.randi_range(1, total_weight)
	var running_total := 0
	for entry in TERRAIN_WEIGHTS:
		running_total += entry["weight"]
		if roll <= running_total:
			return entry["terrain"]

	return "grass"


func _place_starter_buildings() -> void:
	var starter_cells := _get_cells_for_starter_buildings()
	for i in range(STARTER_BUILDINGS.size()):
		if i >= starter_cells.size():
			return

		_place_building_on_cell(starter_cells[i], STARTER_BUILDINGS[i], PLAYER_OWNER)


func _get_cells_for_starter_buildings() -> Array[Vector2i]:
	var valid_cells: Array[Vector2i] = []
	var center := Vector2((MAP_WIDTH - 1) / 2.0, (MAP_HEIGHT - 1) / 2.0)

	for cell in map_tiles.keys():
		var tile_data: Dictionary = map_tiles[cell]
		if tile_data["terrain_type"] == "grass":
			valid_cells.append(cell)

	valid_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return Vector2(a.x, a.y).distance_squared_to(center) < Vector2(b.x, b.y).distance_squared_to(center)
	)

	var starter_cells: Array[Vector2i] = []
	for i in range(min(STARTER_BUILDINGS.size(), valid_cells.size())):
		starter_cells.append(valid_cells[i])
	return starter_cells


func _clear_building_icons() -> void:
	if marker_layer == null:
		return

	for child in marker_layer.get_children():
		child.queue_free()


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
	if not map_tiles.has(cell):
		_hide_build_menu()
		return

	selected_cell = cell
	selected_terrain = map_tiles[cell]["terrain_type"]
	call_deferred("_refresh_build_menu")
	menu_panel.position = viewport_position + Vector2(12, 12)
	menu_panel.visible = true


func _refresh_build_menu() -> void:
	for child in menu_buttons.get_children():
		child.queue_free()

	var terrain_label: String = TERRAIN_LABELS.get(selected_terrain, selected_terrain.capitalize())
	menu_title.text = terrain_label

	var existing_buildings: Array = _get_buildings_for_cell(selected_cell)
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
	_place_building_on_cell(selected_cell, building_name, PLAYER_OWNER)
	call_deferred("_refresh_build_menu")


func _place_building_on_cell(cell: Vector2i, building_name: String, owner: String) -> bool:
	if not map_tiles.has(cell):
		return false

	var tile_data: Dictionary = map_tiles[cell]
	var terrain: String = tile_data["terrain_type"]
	var allowed_buildings: Array = ALLOWED_BUILDINGS_BY_TERRAIN.get(terrain, [])
	if not allowed_buildings.has(building_name):
		return false

	var buildings: Array = tile_data["buildings"]
	if buildings.size() >= _get_max_buildings_for_terrain(terrain):
		return false

	buildings.append(building_name)
	tile_data["buildings"] = buildings
	tile_data["building_type"] = buildings[0]
	tile_data["tile_owner"] = owner
	map_tiles[cell] = tile_data
	placed_buildings[cell] = buildings
	_add_building_icon(cell, building_name, buildings.size() - 1)
	return true


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


func _get_buildings_for_cell(cell: Vector2i) -> Array:
	if not map_tiles.has(cell):
		return []

	return map_tiles[cell]["buildings"]


func _get_max_buildings_for_terrain(terrain: String) -> int:
	return MAX_BUILDINGS_BY_TERRAIN.get(terrain, 1)




