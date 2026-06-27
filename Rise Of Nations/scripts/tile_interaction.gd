extends Node2D

const Defs = preload("res://scripts/definitions/game_definitions.gd")
const MapGenerator = preload("res://scripts/map/map_generator.gd")
const BuildingPlacement = preload("res://scripts/buildings/building_placement.gd")
const CameraController = preload("res://scripts/camera/camera_controller.gd")
const BuildMenu = preload("res://scripts/ui/build_menu.gd")

@onready var tile_map_layer: TileMapLayer = $Node2D/TileMapLayer

var selected_cell := Vector2i.ZERO
var selected_terrain := ""
var map_tiles: Dictionary = {}
var placed_buildings: Dictionary = {}
var marker_layer: Node2D
var map_generator
var building_placement
var camera_controller
var build_menu


func _ready() -> void:
	_create_marker_layer()
	_setup_systems()
	_generate_new_map()
	_place_starter_buildings()
	camera_controller.setup(self, tile_map_layer)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var world_position := get_global_mouse_position()
		var cell := tile_map_layer.local_to_map(tile_map_layer.to_local(world_position))
		_try_show_build_menu(cell, get_viewport().get_mouse_position())
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		build_menu.hide()

	camera_controller.handle_input(event)


func _create_marker_layer() -> void:
	marker_layer = Node2D.new()
	marker_layer.name = "BuildingMarkers"
	add_child(marker_layer)


func _setup_systems() -> void:
	map_generator = MapGenerator.new()

	building_placement = BuildingPlacement.new()
	building_placement.setup(tile_map_layer, marker_layer)

	camera_controller = CameraController.new()

	build_menu = BuildMenu.new()
	build_menu.setup(self)
	build_menu.building_selected.connect(_on_building_pressed)


func _generate_new_map() -> void:
	placed_buildings.clear()
	building_placement.clear_icons()
	map_tiles = map_generator.generate_map(tile_map_layer)
	map_generator.ensure_starter_grass_tiles(map_tiles, tile_map_layer)


func _place_starter_buildings() -> void:
	var starter_cells: Array[Vector2i] = map_generator.get_starter_cells(map_tiles)
	for i in range(Defs.STARTER_BUILDINGS.size()):
		if i >= starter_cells.size():
			return

		building_placement.place_building(
			map_tiles,
			placed_buildings,
			starter_cells[i],
			str(Defs.STARTER_BUILDINGS[i]),
			Defs.PLAYER_OWNER
		)


func _try_show_build_menu(cell: Vector2i, viewport_position: Vector2) -> void:
	if not map_tiles.has(cell):
		build_menu.hide()
		return

	selected_cell = cell
	selected_terrain = str(map_tiles[cell]["terrain_type"])
	_show_build_menu(viewport_position)


func _show_build_menu(viewport_position: Vector2) -> void:
	var existing_buildings: Array = building_placement.get_buildings_for_cell(map_tiles, selected_cell)
	var max_buildings: int = building_placement.get_max_buildings_for_terrain(selected_terrain)
	build_menu.show_for_tile(selected_terrain, existing_buildings, max_buildings, viewport_position)


func _refresh_build_menu_deferred() -> void:
	var existing_buildings: Array = building_placement.get_buildings_for_cell(map_tiles, selected_cell)
	var max_buildings: int = building_placement.get_max_buildings_for_terrain(selected_terrain)
	build_menu.refresh_deferred(selected_terrain, existing_buildings, max_buildings)


func _on_building_pressed(building_name: String) -> void:
	building_placement.place_building(
		map_tiles,
		placed_buildings,
		selected_cell,
		building_name,
		Defs.PLAYER_OWNER
	)
	_refresh_build_menu_deferred()
