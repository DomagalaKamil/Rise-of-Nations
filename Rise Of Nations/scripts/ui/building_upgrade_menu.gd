extends RefCounted

signal upgrade_requested(category_id: String)
signal back_requested
signal closed

const BuildingUpgrades = preload("res://scripts/definitions/building_upgrade_definitions.gd")
const PANEL_SIZE := Vector2(680, 560)

var menu_layer: CanvasLayer
var menu_panel: PanelContainer
var title_label: Label
var upgrade_buttons: VBoxContainer
var info_label: Label
var alert_label: Label
var alert_message_id := 0


func setup(parent: Node) -> void:
	menu_layer = CanvasLayer.new()
	parent.add_child(menu_layer)

	menu_panel = PanelContainer.new()
	menu_panel.visible = false
	menu_panel.custom_minimum_size = PANEL_SIZE
	_apply_panel_style(menu_panel)
	menu_layer.add_child(menu_panel)
	_center_panel()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	menu_panel.add_child(margin)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	margin.add_child(list)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	list.add_child(header)

	var back_button := Button.new()
	back_button.text = "Back"
	back_button.pressed.connect(_on_back_pressed)
	header.add_child(back_button)

	title_label = Label.new()
	title_label.text = "Building Upgrades"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(hide)
	header.add_child(close_button)

	info_label = Label.new()
	info_label.modulate = Color(1.0, 1.0, 1.0, 0.75)
	list.add_child(info_label)

	alert_label = Label.new()
	alert_label.text = "Can't afford at this time"
	alert_label.modulate = Color(1.0, 0.18, 0.18, 1.0)
	alert_label.visible = false
	list.add_child(alert_label)

	upgrade_buttons = VBoxContainer.new()
	upgrade_buttons.add_theme_constant_override("separation", 10)
	list.add_child(upgrade_buttons)


func show_for_building(building_data: Dictionary) -> void:
	_refresh(building_data)
	_center_panel()
	menu_panel.visible = true


func refresh_deferred(building_data: Dictionary) -> void:
	call_deferred("_refresh", building_data)


func show_alert(message: String) -> void:
	if alert_label == null or menu_layer == null:
		return

	alert_message_id += 1
	alert_label.text = message
	alert_label.visible = true
	var timer: SceneTreeTimer = menu_layer.get_tree().create_timer(2.0)
	timer.timeout.connect(_hide_alert.bind(alert_message_id))


func hide() -> void:
	if menu_panel != null:
		menu_panel.visible = false
	if alert_label != null:
		alert_label.visible = false
	closed.emit()


func _refresh(building_data: Dictionary) -> void:
	for child in upgrade_buttons.get_children():
		child.queue_free()

	if alert_label != null:
		alert_label.visible = false

	var building_type: String = str(building_data.get("type", ""))
	title_label.text = "%s Upgrades" % building_type.capitalize()

	if not BuildingUpgrades.has_upgrades(building_type):
		info_label.text = "No upgrades available"
		return

	var upgrades: Dictionary = building_data.get("upgrades", {})
	var categories: Dictionary = BuildingUpgrades.get_upgrade_categories(building_type)
	info_label.text = "Upgrade costs are paid from your resources"

	for category_value in categories.keys():
		var category_id: String = str(category_value)
		var category_label: String = BuildingUpgrades.get_upgrade_name(building_type, category_id)
		var category_description: String = BuildingUpgrades.get_upgrade_description(building_type, category_id)
		var current_level: int = int(upgrades.get(category_id, 1))
		upgrade_buttons.add_child(_create_upgrade_row(category_id, category_label, category_description, current_level))


func _create_upgrade_row(category_id: String, category_label: String, category_description: String, current_level: int) -> VBoxContainer:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 40)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

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

	row.add_child(button)

	var description_label := Label.new()
	description_label.text = category_description
	description_label.modulate = Color(1.0, 1.0, 1.0, 0.68)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.custom_minimum_size = Vector2(0, 22)
	row.add_child(description_label)

	return row


func _apply_panel_style(panel: PanelContainer) -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.94)
	panel_style.border_color = Color(0.28, 0.28, 0.28, 1.0)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", panel_style)


func _hide_alert(message_id: int) -> void:
	if message_id == alert_message_id and alert_label != null:
		alert_label.visible = false


func _center_panel() -> void:
	var viewport_size := Vector2(1152, 648)
	if menu_layer != null:
		viewport_size = menu_layer.get_viewport().get_visible_rect().size
	menu_panel.position = (viewport_size - PANEL_SIZE) / 2.0


func _on_upgrade_button_pressed(category_id: String) -> void:
	upgrade_requested.emit(category_id)


func _on_back_pressed() -> void:
	menu_panel.visible = false
	back_requested.emit()
