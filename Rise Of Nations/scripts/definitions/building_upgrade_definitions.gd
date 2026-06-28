extends RefCounted

const MAX_LEVEL := 5
const BUILDING_UPGRADES := {
	"farm": {
		"water_supply": {
			"name": "Increase water supply",
			"description": "Increase plant collections",
		},
		"tool_quality": {
			"name": "Increase tool quality",
			"description": "Increase production time",
		},
		"workers_count": {
			"name": "Increase workers count",
			"description": "Increase production time",
		},
		"farmland": {
			"name": "Increase farmland",
			"description": "Increase plant collections",
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
