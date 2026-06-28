extends RefCounted

const GOLD_CAPACITY_BASE := 50
const WOOD_CAPACITY_BASE := 50
const ROCK_CAPACITY_BASE := 50
const IRON_CAPACITY_BASE := 50
const FOOD_CAPACITY_BASE := 50
const RESOURCE_COLLECTION_INTERVAL := 30.0
const FARM_BASE_PRODUCTION_TIME := 30.0
const FARM_MIN_PRODUCTION_TIME := 1.0
const TAX_GOLD_PER_5_POPULATION := 1
const GOLD_MINE_INCOME := 1
const ROCK_MINE_INCOME := 1
const IRON_MINE_INCOME := 1
const SAWMILL_WOOD_INCOME := 1
const FARM_BASE_FOOD_INCOME := 1
const FISHING_FOOD_INCOME := 1
const VILLAGE_POPULATION := 5
const CASTLE_POPULATION := 10

var gold := 0
var wood := 0
var rock := 0
var iron := 0
var food := 0
var population := 0
var gold_capacity := GOLD_CAPACITY_BASE
var wood_capacity := WOOD_CAPACITY_BASE
var rock_capacity := ROCK_CAPACITY_BASE
var iron_capacity := IRON_CAPACITY_BASE
var food_capacity := FOOD_CAPACITY_BASE
var gold_income := 0
var wood_income := 0
var rock_income := 0
var iron_income := 0
var food_income := 0
var resource_collection_progress := 0.0
var food_production_progress: Dictionary = {}


func recalculate_from_map(map_tiles: Dictionary) -> void:
	population = 0
	gold_capacity = GOLD_CAPACITY_BASE
	wood_capacity = WOOD_CAPACITY_BASE
	rock_capacity = ROCK_CAPACITY_BASE
	iron_capacity = IRON_CAPACITY_BASE
	food_capacity = FOOD_CAPACITY_BASE
	gold_income = 0
	wood_income = 0
	rock_income = 0
	iron_income = 0
	food_income = 0

	for cell_key in map_tiles.keys():
		var cell: Vector2i = cell_key
		var tile_data: Dictionary = map_tiles[cell]
		var terrain_type: String = str(tile_data.get("terrain_type", ""))
		var buildings: Array = tile_data.get("buildings", [])

		for building_value in buildings:
			var building_data: Dictionary = building_value
			var building_type: String = str(building_data.get("type", ""))
			_apply_building_economy(building_type, terrain_type, building_data)

	gold_income += int(population / 5) * TAX_GOLD_PER_5_POPULATION
	gold = clampi(gold, 0, gold_capacity)
	wood = clampi(wood, 0, wood_capacity)
	rock = clampi(rock, 0, rock_capacity)
	iron = clampi(iron, 0, iron_capacity)
	food = clampi(food, 0, food_capacity)


func collect_income(map_tiles: Dictionary, delta_seconds: float) -> void:
	_collect_timed_resources(delta_seconds)
	_collect_food_from_buildings(map_tiles, delta_seconds)


func can_afford_cost(cost: Dictionary) -> bool:
	var required_gold: int = int(cost.get("gold", 0))
	var required_wood: int = int(cost.get("wood", 0))
	var required_rock: int = int(cost.get("rock", 0))
	var required_iron: int = int(cost.get("iron", 0))
	var required_food: int = int(cost.get("food", 0))
	return gold >= required_gold and wood >= required_wood and rock >= required_rock and iron >= required_iron and food >= required_food


func spend_cost(cost: Dictionary) -> bool:
	if not can_afford_cost(cost):
		return false

	gold -= int(cost.get("gold", 0))
	wood -= int(cost.get("wood", 0))
	rock -= int(cost.get("rock", 0))
	iron -= int(cost.get("iron", 0))
	food -= int(cost.get("food", 0))
	return true

func get_state() -> Dictionary:
	return {
		"gold": gold,
		"gold_capacity": gold_capacity,
		"wood": wood,
		"wood_capacity": wood_capacity,
		"rock": rock,
		"rock_capacity": rock_capacity,
		"iron": iron,
		"iron_capacity": iron_capacity,
		"food": food,
		"food_capacity": food_capacity,
		"population": population,
		"gold_income": gold_income,
		"wood_income": wood_income,
		"rock_income": rock_income,
		"iron_income": iron_income,
		"food_income": food_income,
	}


func _collect_timed_resources(delta_seconds: float) -> void:
	resource_collection_progress += delta_seconds
	while resource_collection_progress >= RESOURCE_COLLECTION_INTERVAL:
		resource_collection_progress -= RESOURCE_COLLECTION_INTERVAL
		gold = clampi(gold + gold_income, 0, gold_capacity)
		wood = clampi(wood + wood_income, 0, wood_capacity)
		rock = clampi(rock + rock_income, 0, rock_capacity)
		iron = clampi(iron + iron_income, 0, iron_capacity)


func _collect_food_from_buildings(map_tiles: Dictionary, delta_seconds: float) -> void:
	var active_producers: Dictionary = {}

	for cell_key in map_tiles.keys():
		var cell: Vector2i = cell_key
		var tile_data: Dictionary = map_tiles[cell]
		var buildings: Array = tile_data.get("buildings", [])

		for building_index in range(buildings.size()):
			var building_data: Dictionary = buildings[building_index]
			var building_type: String = str(building_data.get("type", ""))
			if building_type != "farm" and building_type != "fishing":
				continue

			var production_key: String = _get_building_key(cell, building_index)
			active_producers[production_key] = true
			var production_time: float = _get_food_production_time(building_type, building_data)
			var harvest_amount: int = _get_food_harvest_amount(building_type, building_data)
			var progress: float = float(food_production_progress.get(production_key, 0.0)) + delta_seconds

			while progress >= production_time:
				progress -= production_time
				food = clampi(food + harvest_amount, 0, food_capacity)

			food_production_progress[production_key] = progress

	for production_key_value in food_production_progress.keys():
		var production_key: String = str(production_key_value)
		if not active_producers.has(production_key):
			food_production_progress.erase(production_key)


func _apply_building_economy(building_type: String, terrain_type: String, building_data: Dictionary) -> void:
	match building_type:
		"village":
			population += VILLAGE_POPULATION
		"castle":
			population += CASTLE_POPULATION
		"mine":
			if terrain_type == "gold":
				gold_income += GOLD_MINE_INCOME
			elif terrain_type == "rocks":
				rock_income += ROCK_MINE_INCOME
			elif terrain_type == "iron":
				iron_income += IRON_MINE_INCOME
		"sawmill":
			wood_income += SAWMILL_WOOD_INCOME
		"farm", "fishing":
			food_income += _get_food_harvest_amount(building_type, building_data)


func _get_food_harvest_amount(building_type: String, building_data: Dictionary) -> int:
	if building_type == "fishing":
		return FISHING_FOOD_INCOME

	var upgrades: Dictionary = building_data.get("upgrades", {})
	var water_supply_level: int = int(upgrades.get("water_supply", 1))
	var farmland_level: int = int(upgrades.get("farmland", 1))
	return FARM_BASE_FOOD_INCOME + max(0, water_supply_level - 1) + max(0, farmland_level - 1)


func _get_food_production_time(building_type: String, building_data: Dictionary) -> float:
	if building_type == "fishing":
		return RESOURCE_COLLECTION_INTERVAL

	var upgrades: Dictionary = building_data.get("upgrades", {})
	var tool_quality_level: int = int(upgrades.get("tool_quality", 1))
	var workers_count_level: int = int(upgrades.get("workers_count", 1))
	var production_time_reduction: int = max(0, tool_quality_level - 1) + max(0, workers_count_level - 1)
	return maxf(FARM_MIN_PRODUCTION_TIME, FARM_BASE_PRODUCTION_TIME - float(production_time_reduction))


func _get_building_key(cell: Vector2i, building_index: int) -> String:
	return "%s:%s:%s" % [cell.x, cell.y, building_index]
