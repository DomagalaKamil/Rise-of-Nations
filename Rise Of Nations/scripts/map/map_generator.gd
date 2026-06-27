extends RefCounted

const Defs = preload("res://scripts/definitions/game_definitions.gd")

var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()


func generate_map(tile_map_layer: TileMapLayer) -> Dictionary:
	var map_tiles: Dictionary = {}
	tile_map_layer.clear()

	for y in range(Defs.MAP_HEIGHT):
		for x in range(Defs.MAP_WIDTH):
			var cell := Vector2i(x, y)
			var terrain := _pick_weighted_terrain()
			map_tiles[cell] = create_tile_data(terrain)
			tile_map_layer.set_cell(cell, Defs.TILE_SOURCE_ID, Defs.TERRAIN_ATLAS_COORDS[terrain])

	return map_tiles


func ensure_starter_grass_tiles(map_tiles: Dictionary, tile_map_layer: TileMapLayer) -> void:
	var grass_count := 0
	for cell_key in map_tiles.keys():
		var cell: Vector2i = cell_key
		var tile_data: Dictionary = map_tiles[cell]
		if str(tile_data["terrain_type"]) == "grass":
			grass_count += 1

	if grass_count >= Defs.STARTER_BUILDINGS.size():
		return

	var center_x := int(Defs.MAP_WIDTH / 2)
	var center_y := int(Defs.MAP_HEIGHT / 2)
	var preferred_cells: Array[Vector2i] = [
		Vector2i(center_x, center_y),
		Vector2i(center_x - 1, center_y),
		Vector2i(center_x + 1, center_y),
		Vector2i(center_x, center_y - 1),
		Vector2i(center_x, center_y + 1),
	]

	for cell in preferred_cells:
		if grass_count >= Defs.STARTER_BUILDINGS.size():
			return
		if map_tiles.has(cell):
			var tile_data: Dictionary = map_tiles[cell]
			if str(tile_data["terrain_type"]) != "grass":
				set_cell_terrain(map_tiles, tile_map_layer, cell, "grass")
				grass_count += 1


func set_cell_terrain(map_tiles: Dictionary, tile_map_layer: TileMapLayer, cell: Vector2i, terrain: String) -> void:
	map_tiles[cell] = create_tile_data(terrain)
	tile_map_layer.set_cell(cell, Defs.TILE_SOURCE_ID, Defs.TERRAIN_ATLAS_COORDS[terrain])


func create_tile_data(terrain: String) -> Dictionary:
	var resource_type := ""
	if terrain in Defs.RESOURCE_TERRAINS:
		resource_type = terrain

	return {
		"terrain_type": terrain,
		"resource_type": resource_type,
		"building_type": "",
		"buildings": [],
		"tile_owner": Defs.NEUTRAL_OWNER,
		"movement_cost": 1,
		"mineable": terrain in Defs.MINEABLE_TERRAINS,
	}


func get_starter_cells(map_tiles: Dictionary) -> Array[Vector2i]:
	var valid_cells: Array[Vector2i] = []
	var center := Vector2((Defs.MAP_WIDTH - 1) / 2.0, (Defs.MAP_HEIGHT - 1) / 2.0)

	for cell_key in map_tiles.keys():
		var cell: Vector2i = cell_key
		var tile_data: Dictionary = map_tiles[cell]
		if str(tile_data["terrain_type"]) == "grass":
			valid_cells.append(cell)

	valid_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return Vector2(a.x, a.y).distance_squared_to(center) < Vector2(b.x, b.y).distance_squared_to(center)
	)

	var starter_cells: Array[Vector2i] = []
	for i in range(min(Defs.STARTER_BUILDINGS.size(), valid_cells.size())):
		starter_cells.append(valid_cells[i])
	return starter_cells


func _pick_weighted_terrain() -> String:
	var total_weight := 0
	for entry in Defs.TERRAIN_WEIGHTS:
		var entry_data: Dictionary = entry
		total_weight += int(entry_data["weight"])

	var roll := rng.randi_range(1, total_weight)
	var running_total := 0
	for entry in Defs.TERRAIN_WEIGHTS:
		var entry_data: Dictionary = entry
		running_total += int(entry_data["weight"])
		if roll <= running_total:
			return str(entry_data["terrain"])

	return "grass"
