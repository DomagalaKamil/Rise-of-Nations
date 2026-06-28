extends RefCounted

signal building_clicked(cell: Vector2i, building_index: int, viewport_position: Vector2)

const Defs = preload("res://scripts/definitions/game_definitions.gd")
const BuildingUpgrades = preload("res://scripts/definitions/building_upgrade_definitions.gd")

var building_icons_texture: Texture2D = preload("res://art/building_icons.png")
var tile_map_layer: TileMapLayer
var marker_layer: Node2D


func setup(new_tile_map_layer: TileMapLayer, new_marker_layer: Node2D) -> void:
	tile_map_layer = new_tile_map_layer
	marker_layer = new_marker_layer


func clear_icons() -> void:
	if marker_layer == null:
		return

	for child in marker_layer.get_children():
		child.queue_free()


func place_building(map_tiles: Dictionary, placed_buildings: Dictionary, cell: Vector2i, building_name: String, owner: String) -> bool:
	if not map_tiles.has(cell):
		return false

	var tile_data: Dictionary = map_tiles[cell]
	var terrain: String = str(tile_data["terrain_type"])
	var allowed_buildings: Array = Defs.ALLOWED_BUILDINGS_BY_TERRAIN.get(terrain, [])
	if not allowed_buildings.has(building_name):
		return false

	var buildings: Array = tile_data["buildings"]
	if buildings.size() >= get_max_buildings_for_terrain(terrain):
		return false

	var building_data: Dictionary = _create_building_data(building_name, owner)
	buildings.append(building_data)
	tile_data["buildings"] = buildings
	var first_building: Dictionary = buildings[0]
	tile_data["building_type"] = str(first_building["type"])
	tile_data["tile_owner"] = owner
	map_tiles[cell] = tile_data
	placed_buildings[cell] = buildings
	_add_building_icon(cell, building_name, buildings.size() - 1)
	return true


func get_buildings_for_cell(map_tiles: Dictionary, cell: Vector2i) -> Array:
	if not map_tiles.has(cell):
		return []

	return map_tiles[cell]["buildings"]


func get_building_data(map_tiles: Dictionary, cell: Vector2i, building_index: int) -> Dictionary:
	var buildings: Array = get_buildings_for_cell(map_tiles, cell)
	if building_index < 0 or building_index >= buildings.size():
		return {}

	return buildings[building_index] as Dictionary


func apply_building_upgrade(map_tiles: Dictionary, cell: Vector2i, building_index: int, category_id: String) -> bool:
	var building_data: Dictionary = get_building_data(map_tiles, cell, building_index)
	if building_data.is_empty():
		return false

	var building_type: String = str(building_data.get("type", ""))
	if not BuildingUpgrades.has_upgrades(building_type):
		return false

	var upgrades: Dictionary = building_data.get("upgrades", {})
	var current_level: int = int(upgrades.get(category_id, 1))
	if not BuildingUpgrades.can_upgrade(current_level):
		return false

	upgrades[category_id] = current_level + 1
	building_data["upgrades"] = upgrades
	_set_building_data(map_tiles, cell, building_index, building_data)
	return true


func get_max_buildings_for_terrain(terrain: String) -> int:
	return Defs.MAX_BUILDINGS_BY_TERRAIN.get(terrain, 1)


func _create_building_data(building_name: String, owner: String) -> Dictionary:
	var building_data: Dictionary = {
		"type": building_name,
		"owner": owner,
		"level": 1,
		"upgrades": {},
	}

	if BuildingUpgrades.has_upgrades(building_name):
		building_data["upgrades"] = BuildingUpgrades.create_default_upgrades(building_name)

	return building_data


func _set_building_data(map_tiles: Dictionary, cell: Vector2i, building_index: int, building_data: Dictionary) -> void:
	var tile_data: Dictionary = map_tiles[cell]
	var buildings: Array = tile_data["buildings"]
	buildings[building_index] = building_data
	tile_data["buildings"] = buildings
	map_tiles[cell] = tile_data


func _add_building_icon(cell: Vector2i, building_name: String, index: int) -> void:
	var icon_coords: Vector2i = Defs.BUILDING_ICONS.get(building_name, Vector2i.ZERO)
	var texture_size: Vector2 = building_icons_texture.get_size()
	var icon_cell_size: Vector2 = Vector2(texture_size.x / Defs.ICON_GRID_SIZE.x, texture_size.y / Defs.ICON_GRID_SIZE.y)
	var icon_position: Vector2 = Vector2(icon_coords.x * icon_cell_size.x, icon_coords.y * icon_cell_size.y)

	var atlas := AtlasTexture.new()
	atlas.atlas = building_icons_texture
	atlas.region = Rect2(icon_position, icon_cell_size)

	var area := Area2D.new()
	area.name = "Building_%s_%s_%s" % [cell.x, cell.y, index]
	area.input_pickable = true
	area.global_position = tile_map_layer.to_global(tile_map_layer.map_to_local(cell)) + _get_building_icon_offset(index)
	area.input_event.connect(_on_building_icon_input_event.bind(cell, index))
	marker_layer.add_child(area)

	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.scale = Defs.BUILDING_ICON_DISPLAY_SIZE / icon_cell_size
	sprite.centered = true
	area.add_child(sprite)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Defs.BUILDING_ICON_DISPLAY_SIZE
	collision.shape = shape
	area.add_child(collision)


func _on_building_icon_input_event(viewport: Viewport, event: InputEvent, _shape_idx: int, cell: Vector2i, building_index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		viewport.set_input_as_handled()
		building_clicked.emit(cell, building_index, event.position)


func _get_building_icon_offset(index: int) -> Vector2:
	var spacing: float = 70.0
	match index:
		0:
			return Vector2(0, -60)
		1:
			return Vector2(-spacing, 40)
		2:
			return Vector2(spacing, 40)
		_:
			return Vector2.ZERO
