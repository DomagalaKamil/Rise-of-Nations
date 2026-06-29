extends RefCounted

const MAX_LEVEL := 5
const BUILDING_UPGRADES := {
	"farm": {
		"water_supply": {
			"name": "Increase water supply",
			"description": "Increase food harvested",
		},
		"tool_quality": {
			"name": "Increase tool quality",
			"description": "Decrease production time",
		},
		"workers_count": {
			"name": "Increase workers count",
			"description": "Decrease production time",
		},
		"farmland": {
			"name": "Increase farmland",
			"description": "Increase food harvested",
		},
		"storage_barns": {
			"name": "Storage barns",
			"description": "Increase food storage capacity by 5",
		},
	},
	"sawmill": {
		"sharper_saws": {
			"name": "Sharper saws",
			"description": "Increase wood produced",
		},
		"better_workers": {
			"name": "Better workers",
			"description": "Decrease production time",
		},
		"logging_paths": {
			"name": "Logging paths",
			"description": "Decrease production time",
		},
		"tree_management": {
			"name": "Tree management",
			"description": "Increase wood produced",
		},
		"lumber_storage": {
			"name": "Lumber storage",
			"description": "Increase wood storage capacity by 5",
		},
	},
	"mine": {
		"better_pickaxes": {
			"name": "Better pickaxes",
			"description": "Increase mined resource amount",
		},
		"mine_carts": {
			"name": "Mine carts",
			"description": "Decrease production time",
		},
		"deeper_tunnels": {
			"name": "Deeper tunnels",
			"description": "Increase mined resource amount",
		},
		"worker_safety": {
			"name": "Worker safety",
			"description": "Decrease production time",
		},
		"ore_storage": {
			"name": "Ore storage",
			"description": "Increase mined resource storage capacity by 5",
		},
	},
	"fishing": {
		"better_nets": {
			"name": "Better nets",
			"description": "Increase food produced",
		},
		"larger_boats": {
			"name": "Larger boats",
			"description": "Increase food produced",
		},
		"skilled_fishermen": {
			"name": "Skilled fishermen",
			"description": "Decrease production time",
		},
		"fish_preservation": {
			"name": "Fish preservation",
			"description": "Increase food produced",
		},
		"fish_storage": {
			"name": "Fish storage",
			"description": "Increase food storage capacity by 5",
		},
	},
	"village": {
		"housing": {
			"name": "Housing",
			"description": "Increase population",
		},
		"marketplace": {
			"name": "Marketplace",
			"description": "Increase gold from taxes",
		},
		"roads": {
			"name": "Roads",
			"description": "Prepare movement bonuses for later",
		},
		"local_storage": {
			"name": "Local storage",
			"description": "Increase food and wood storage capacity by 5",
		},
		"town_watch": {
			"name": "Town watch",
			"description": "Increase defensive value for later",
		},
	},
	"castle": {
		"vault": {
			"name": "Vault",
			"description": "Increase gold storage capacity by 5",
		},
		"granary": {
			"name": "Granary",
			"description": "Increase food storage capacity by 5",
		},
		"barracks": {
			"name": "Barracks",
			"description": "Prepare army bonuses for later",
		},
		"stone_walls": {
			"name": "Stone walls",
			"description": "Increase defensive value for later",
		},
		"administration": {
			"name": "Administration",
			"description": "Increase gold from taxes",
		},
	},
}


static func has_upgrades(building_type: String) -> bool:
	return BUILDING_UPGRADES.has(building_type)


static func get_upgrade_categories(building_type: String) -> Dictionary:
	var categories: Dictionary = BUILDING_UPGRADES.get(building_type, {})
	return categories


static func create_default_upgrades(building_type: String) -> Dictionary:
	var upgrades: Dictionary = {}
	var categories: Dictionary = get_upgrade_categories(building_type)
	for category_id in categories.keys():
		upgrades[category_id] = 1
	return upgrades


static func get_upgrade_name(building_type: String, category_id: String) -> String:
	var categories: Dictionary = get_upgrade_categories(building_type)
	if not categories.has(category_id):
		return category_id.capitalize()

	var category_data: Dictionary = categories[category_id]
	return str(category_data.get("name", category_id.capitalize()))


static func get_upgrade_description(building_type: String, category_id: String) -> String:
	var categories: Dictionary = get_upgrade_categories(building_type)
	if not categories.has(category_id):
		return ""

	var category_data: Dictionary = categories[category_id]
	return str(category_data.get("description", ""))


static func get_upgrade_cost(next_level: int) -> Dictionary:
	return {
		"wood": 25 + ((next_level - 2) * 10),
		"gold": 6 + ((next_level - 2) * 3),
	}


static func can_upgrade(current_level: int) -> bool:
	return current_level < MAX_LEVEL
