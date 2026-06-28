extends RefCounted

signal upgrade_requested(category_id: String)

const BuildingUpgrades = preload("res://scripts/definitions/building_upgrade_definitions.gd")

var menu_layer: CanvasLayer
var menu_panel: PanelContainer
var title_label: Label
var upgrade_buttons: VBoxContainer
var info_label: Label


func setup(parent: Node) -> void:
	menu_layer = CanvasLayer.new()
	parent.add_child(menu_layer)

	menu_panel = PanelContainer.new()
	menu_panel.visible = false
	menu_panel.custom_minimum_size = Vector2(320, 0)
	menu_layer.add_child(menu_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	menu_panel.add_child(margin)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	margin.add_child(list)

	title_label = Label.new()
	title_label.text = "Building Upgrades"
	list.add_child(title_label)

	info_label = Label.new()
	info_label.modulate = Color(1.0, 1.0, 1.0, 0.75)
	list.add_child(info_label)

	upgrade_buttons = VBoxContainer.new()
	upgrade_buttons.add_theme_constant_override("separation", 5)
	list.add_child(upgrade_buttons)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(hide)
	list.add_child(close_button)


func show_for_building(building_data: Dictionary, viewport_position: Vector2) -> void:
	_refresh(building_data)
	menu_panel.position = viewport_position + Vector2(12, 12)
	menu_panel.visible = true


func refresh_deferred(building_data: Dictionary) -> void:
	call_deferred("_refresh", building_data)


func hide() -> void:
	if menu_panel != null:
		menu_panel.visible = false


func _refresh(building_data: Dictionary) -> void:
	for child in upgrade_buttons.get_children():
		child.queue_free()

	var building_type: String = str(building_data.get("type", ""))
	title_label.text = "%s Upgrades" % building_type.capitalize()

	if not BuildingUpgrades.has_upgrades(building_type):
		info_label.text = "No upgrades available"
		return

	var upgrades: Dictionary = building_data.get("upgrades", {})
	var categories: Dictionary = BuildingUpgrades.get_upgrade_categories(building_type)
	info_label.text = "Demo costs only"

	for category_value in categories.keys():
		var category_id: String = str(category_value)
		var category_label: String = str(categories[category_id])
		var current_level: int = int(upgrades.get(category_id, 1))
		var button := Button.new()

		if BuildingUpgrades.can_upgrade(current_level):
			var next_level: int = current_level + 1
			var cost: Dictionary = BuildingUpgrades.get_upgrade_cost(next_level)
			button.text = "%s: Lv %s -> %s (%s wood, %s gold)" % [
				category_label,
				current_level,
				next_level,
				int(cost["wood"]),
				int(cost["gold"]),
			]
			button.pressed.connect(_on_upgrade_button_pressed.bind(category_id))
		else:
			button.text = "%s: Lv %s (Max)" % [category_label, current_level]
			button.disabled = true

		upgrade_buttons.add_child(button)


func _on_upgrade_button_pressed(category_id: String) -> void:
	upgrade_requested.emit(category_id)
