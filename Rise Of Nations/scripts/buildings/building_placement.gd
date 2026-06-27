extends RefCounted

const Defs = preload("res://scripts/definitions/game_definitions.gd")

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
	var terrain: String = tile_data["terrain_type"]
	var allowed_buildings: Array = Defs.ALLOWED_BUILDINGS_BY_TERRAIN.get(terrain, [])
	if not allowed_buildings.has(building_name):
		return false

	var buildings: Array = tile_data["buildings"]
	if buildings.size() >= get_max_buildings_for_terrain(terrain):
		return false

	buildings.append(building_name)
	tile_data["buildings"] = buildings
	tile_data["building_type"] = buildings[0]
	tile_data["tile_owner"] = owner
	map_tiles[cell] = tile_data
	placed_buildings[cell] = buildings
	_add_building_icon(cell, building_name, buildings.size() - 1)
	return true


func get_buildings_for_cell(map_tiles: Dictionary, cell: Vector2i) -> Array:
	if not map_tiles.has(cell):
		return []

	return map_tiles[cell]["buildings"]


func get_max_buildings_for_terrain(terrain: String) -> int:
	return Defs.MAX_BUILDINGS_BY_TERRAIN.get(terrain, 1)


func _add_building_icon(cell: Vector2i, building_name: String, index: int) -> void:
	var icon_coords: Vector2i = Defs.BUILDING_ICONS.get(building_name, Vector2i.ZERO)
	var texture_size := building_icons_texture.get_size()
	var icon_cell_size := Vector2(texture_size.x / Defs.ICON_GRID_SIZE.x, texture_size.y / Defs.ICON_GRID_SIZE.y)
	var icon_position := Vector2(icon_coords.x * icon_cell_size.x, icon_coords.y * icon_cell_size.y)

	var atlas := AtlasTexture.new()
	atlas.atlas = building_icons_texture
	atlas.region = Rect2(icon_position, icon_cell_size)

	var sprite := Sprite2D.new()
	sprite.name = "Building_%s_%s_%s" % [cell.x, cell.y, index]
	sprite.texture = atlas
	sprite.scale = Defs.BUILDING_ICON_DISPLAY_SIZE / icon_cell_size
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
