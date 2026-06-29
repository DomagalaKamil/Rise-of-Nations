extends RefCounted

const GOLD_CAPACITY_BASE := 50
const WOOD_CAPACITY_BASE := 50
const ROCK_CAPACITY_BASE := 50
const IRON_CAPACITY_BASE := 50
const FOOD_CAPACITY_BASE := 50
const RESOURCE_COLLECTION_INTERVAL := 30.0
const BASE_PRODUCTION_TIME := 30.0
const MIN_PRODUCTION_TIME := 1.0
const STORAGE_CAPACITY_PER_LEVEL := 5
const TAX_GOLD_PER_5_POPULATION := 1
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
var defense_value := 0
var movement_bonus := 0
var army_bonus := 0
var tax_gold_income := 0
var resource_collection_progress := 0.0
var production_progress: Dictionary = {}


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
	defense_value = 0
	movement_bonus = 0
	army_bonus = 0
	tax_gold_income = 0

	for cell_key in map_tiles.keys():
		var cell: Vector2i = cell_key
		var tile_data: Dictionary = map_tiles[cell]
		var terrain_type: String = str(tile_data.get("terrain_type", ""))
		var buildings: Array = tile_data.get("buildings", [])

		for building_value in buildings:
			var building_data: Dictionary = building_value
			var building_type: String = str(building_data.get("type", ""))
			_apply_building_economy(building_type, terrain_type, building_data)

	tax_gold_income += int(population / 5) * TAX_GOLD_PER_5_POPULATION
	gold_income += tax_gold_income
	gold = clampi(gold, 0, gold_capacity)
	wood = clampi(wood, 0, wood_capacity)
	rock = clampi(rock, 0, rock_capacity)
	iron = clampi(iron, 0, iron_capacity)
	food = clampi(food, 0, food_capacity)


func collect_income(map_tiles: Dictionary, delta_seconds: float) -> void:
	_collect_tax_income(delta_seconds)
	_collect_building_resources(map_tiles, delta_seconds)


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
		"defense_value": defense_value,
		"movement_bonus": movement_bonus,
		"army_bonus": army_bonus,
	}


func _collect_tax_income(delta_seconds: float) -> void:
	resource_collection_progress += delta_seconds
	while resource_collection_progress >= RESOURCE_COLLECTION_INTERVAL:
		resource_collection_progress -= RESOURCE_COLLECTION_INTERVAL
		gold = clampi(gold + tax_gold_income, 0, gold_capacity)


func _collect_building_resources(map_tiles: Dictionary, delta_seconds: float) -> void:
	var active_producers: Dictionary = {}

	for cell_key in map_tiles.keys():
		var cell: Vector2i = cell_key
		var tile_data: Dictionary = map_tiles[cell]
		var terrain_type: String = str(tile_data.get("terrain_type", ""))
		var buildings: Array = tile_data.get("buildings", [])

		for building_index in range(buildings.size()):
			var building_data: Dictionary = buildings[building_index]
			var building_type: String = str(building_data.get("type", ""))
			var resource_type: String = _get_produced_resource_type(building_type, terrain_type)
			if resource_type == "":
				continue

			var production_key: String = _get_building_key(cell, building_index)
			active_producers[production_key] = true
			var production_time: float = _get_production_time(building_type, building_data)
			var harvest_amount: int = _get_harvest_amount(building_type, building_data)
			var progress: float = float(production_progress.get(production_key, 0.0)) + delta_seconds

			while progress >= production_time:
				progress -= production_time
				_add_resource_amount(resource_type, harvest_amount)

			production_progress[production_key] = progress

	for production_key_value in production_progress.keys():
		var production_key: String = str(production_key_value)
		if not active_producers.has(production_key):
			production_progress.erase(production_key)


func _apply_building_economy(building_type: String, terrain_type: String, building_data: Dictionary) -> void:
	var upgrades: Dictionary = building_data.get("upgrades", {})

	match building_type:
		"village":
			population += VILLAGE_POPULATION + (_get_upgrade_bonus(upgrades, "housing") * 5)
			tax_gold_income += _get_upgrade_bonus(upgrades, "marketplace")
			movement_bonus += _get_upgrade_bonus(upgrades, "roads")
			var village_storage_bonus: int = _get_storage_bonus(upgrades, "local_storage")
			food_capacity += village_storage_bonus
			wood_capacity += village_storage_bonus
			defense_value += _get_upgrade_bonus(upgrades, "town_watch")
		"castle":
			population += CASTLE_POPULATION
			gold_capacity += _get_storage_bonus(upgrades, "vault")
			food_capacity += _get_storage_bonus(upgrades, "granary")
			army_bonus += _get_upgrade_bonus(upgrades, "barracks")
			defense_value += _get_upgrade_bonus(upgrades, "stone_walls")
			tax_gold_income += _get_upgrade_bonus(upgrades, "administration")
		"farm":
			food_capacity += _get_storage_bonus(upgrades, "storage_barns")
			food_income += _get_harvest_amount(building_type, building_data)
		"fishing":
			food_capacity += _get_storage_bonus(upgrades, "fish_storage")
			food_income += _get_harvest_amount(building_type, building_data)
		"sawmill":
			wood_capacity += _get_storage_bonus(upgrades, "lumber_storage")
			wood_income += _get_harvest_amount(building_type, building_data)
		"mine":
			var storage_bonus: int = _get_storage_bonus(upgrades, "ore_storage")
			if terrain_type == "gold":
				gold_capacity += storage_bonus
				gold_income += _get_harvest_amount(building_type, building_data)
			elif terrain_type == "rocks":
				rock_capacity += storage_bonus
				rock_income += _get_harvest_amount(building_type, building_data)
			elif terrain_type == "iron":
				iron_capacity += storage_bonus
				iron_income += _get_harvest_amount(building_type, building_data)


func _get_produced_resource_type(building_type: String, terrain_type: String) -> String:
	match building_type:
		"farm", "fishing":
			return "food"
		"sawmill":
			return "wood"
		"mine":
			if terrain_type == "gold":
				return "gold"
			elif terrain_type == "rocks":
				return "rock"
			elif terrain_type == "iron":
				return "iron"
	return ""


func _get_harvest_amount(building_type: String, building_data: Dictionary) -> int:
	var upgrades: Dictionary = building_data.get("upgrades", {})
	match building_type:
		"farm":
			return 1 + _get_upgrade_bonus(upgrades, "water_supply") + _get_upgrade_bonus(upgrades, "farmland")
		"fishing":
			return 1 + _get_upgrade_bonus(upgrades, "better_nets") + _get_upgrade_bonus(upgrades, "larger_boats") + _get_upgrade_bonus(upgrades, "fish_preservation")
		"sawmill":
			return 1 + _get_upgrade_bonus(upgrades, "sharper_saws") + _get_upgrade_bonus(upgrades, "tree_management")
		"mine":
			return 1 + _get_upgrade_bonus(upgrades, "better_pickaxes") + _get_upgrade_bonus(upgrades, "deeper_tunnels")
	return 0


func _get_production_time(building_type: String, building_data: Dictionary) -> float:
	var upgrades: Dictionary = building_data.get("upgrades", {})
	var production_time_reduction := 0
	match building_type:
		"farm":
			production_time_reduction = _get_upgrade_bonus(upgrades, "tool_quality") + _get_upgrade_bonus(upgrades, "workers_count")
		"fishing":
			production_time_reduction = _get_upgrade_bonus(upgrades, "skilled_fishermen")
		"sawmill":
			production_time_reduction = _get_upgrade_bonus(upgrades, "better_workers") + _get_upgrade_bonus(upgrades, "logging_paths")
		"mine":
			production_time_reduction = _get_upgrade_bonus(upgrades, "mine_carts") + _get_upgrade_bonus(upgrades, "worker_safety")
	return maxf(MIN_PRODUCTION_TIME, BASE_PRODUCTION_TIME - float(production_time_reduction))


func _add_resource_amount(resource_type: String, amount: int) -> void:
	match resource_type:
		"gold":
			gold = clampi(gold + amount, 0, gold_capacity)
		"wood":
			wood = clampi(wood + amount, 0, wood_capacity)
		"rock":
			rock = clampi(rock + amount, 0, rock_capacity)
		"iron":
			iron = clampi(iron + amount, 0, iron_capacity)
		"food":
			food = clampi(food + amount, 0, food_capacity)


func _get_upgrade_bonus(upgrades: Dictionary, category_id: String) -> int:
	return maxi(0, int(upgrades.get(category_id, 1)) - 1)


func _get_storage_bonus(upgrades: Dictionary, category_id: String) -> int:
	return _get_upgrade_bonus(upgrades, category_id) * STORAGE_CAPACITY_PER_LEVEL


func _get_building_key(cell: Vector2i, building_index: int) -> String:
	return "%s:%s:%s" % [cell.x, cell.y, building_index]
