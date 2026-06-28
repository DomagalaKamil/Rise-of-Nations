extends RefCounted

const GOLD_CAPACITY_BASE := 50
const WOOD_CAPACITY_BASE := 50
const TAX_GOLD_PER_5_POPULATION := 1
const GOLD_MINE_INCOME := 1
const SAWMILL_WOOD_INCOME := 1
const VILLAGE_POPULATION := 5
const CASTLE_POPULATION := 10

var gold := 0
var wood := 0
var population := 0
var gold_capacity := GOLD_CAPACITY_BASE
var wood_capacity := WOOD_CAPACITY_BASE
var gold_income := 0
var wood_income := 0


func recalculate_from_map(map_tiles: Dictionary) -> void:
	population = 0
	gold_capacity = GOLD_CAPACITY_BASE
	wood_capacity = WOOD_CAPACITY_BASE
	gold_income = 0
	wood_income = 0

	for cell_key in map_tiles.keys():
		var cell: Vector2i = cell_key
		var tile_data: Dictionary = map_tiles[cell]
		var terrain_type: String = str(tile_data.get("terrain_type", ""))
		var buildings: Array = tile_data.get("buildings", [])

		for building_value in buildings:
			var building_data: Dictionary = building_value
			var building_type: String = str(building_data.get("type", ""))
			_apply_building_economy(building_type, terrain_type)

	gold_income += int(population / 5) * TAX_GOLD_PER_5_POPULATION
	gold = clampi(gold, 0, gold_capacity)
	wood = clampi(wood, 0, wood_capacity)


func collect_income() -> void:
	gold = clampi(gold + gold_income, 0, gold_capacity)
	wood = clampi(wood + wood_income, 0, wood_capacity)


func get_state() -> Dictionary:
	return {
		"gold": gold,
		"gold_capacity": gold_capacity,
		"wood": wood,
		"wood_capacity": wood_capacity,
		"population": population,
		"gold_income": gold_income,
		"wood_income": wood_income,
	}


func _apply_building_economy(building_type: String, terrain_type: String) -> void:
	match building_type:
		"village":
			population += VILLAGE_POPULATION
		"castle":
			population += CASTLE_POPULATION
		"mine":
			if terrain_type == "gold":
				gold_income += GOLD_MINE_INCOME
		"sawmill":
			wood_income += SAWMILL_WOOD_INCOME


