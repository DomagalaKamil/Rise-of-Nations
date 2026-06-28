extends RefCounted

const MAX_LEVEL := 5
const BUILDING_UPGRADES := {
	"farm": {
		"water_supply": "Increase water supply",
		"tool_quality": "Increase tool quality",
		"workers_count": "Increase workers count",
		"farmland": "Increase farmland",
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


static func get_upgrade_cost(next_level: int) -> Dictionary:
	return {
		"wood": 25 + ((next_level - 2) * 10),
		"gold": 6 + ((next_level - 2) * 3),
	}


static func can_upgrade(current_level: int) -> bool:
	return current_level < MAX_LEVEL
