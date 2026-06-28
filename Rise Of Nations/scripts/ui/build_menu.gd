extends RefCounted

signal building_selected(building_name: String)

const Defs = preload("res://scripts/definitions/game_definitions.gd")

var menu_layer: CanvasLayer
var menu_panel: PanelContainer
var menu_title: Label
var menu_buttons: VBoxContainer


func setup(parent: Node) -> void:
	menu_layer = CanvasLayer.new()
	parent.add_child(menu_layer)

	menu_panel = PanelContainer.new()
	menu_panel.visible = false
	menu_panel.custom_minimum_size = Vector2(210, 0)
	menu_layer.add_child(menu_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	menu_panel.add_child(margin)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	margin.add_child(list)

	menu_title = Label.new()
	menu_title.text = "Build"
	list.add_child(menu_title)

	menu_buttons = VBoxContainer.new()
	menu_buttons.add_theme_constant_override("separation", 4)
	list.add_child(menu_buttons)

	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(hide)
	list.add_child(cancel_button)


func show_for_tile(terrain: String, existing_buildings: Array, max_buildings: int, viewport_position: Vector2) -> void:
	_refresh(terrain, existing_buildings, max_buildings)
	menu_panel.position = viewport_position + Vector2(12, 12)
	menu_panel.visible = true


func hide() -> void:
	if menu_panel != null:
		menu_panel.visible = false


func refresh_deferred(terrain: String, existing_buildings: Array, max_buildings: int) -> void:
	call_deferred("_refresh", terrain, existing_buildings, max_buildings)


func _refresh(terrain: String, existing_buildings: Array, max_buildings: int) -> void:
	for child in menu_buttons.get_children():
		child.queue_free()

	var terrain_label: String = Defs.TERRAIN_LABELS.get(terrain, terrain.capitalize())
	menu_title.text = terrain_label

	var allowed_buildings: Array = Defs.ALLOWED_BUILDINGS_BY_TERRAIN.get(terrain, [])
	if allowed_buildings.is_empty():
		_add_disabled_label("No buildings available")
		return

	if existing_buildings.size() >= max_buildings:
		_add_disabled_label("Building limit reached")
		return

	for building_name_value in allowed_buildings:
		var button := Button.new()
		var building_name := str(building_name_value)
		button.text = Defs.BUILDING_LABELS.get(building_name, building_name.capitalize())
		button.pressed.connect(_on_building_button_pressed.bind(building_name))
		menu_buttons.add_child(button)


func _add_disabled_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = Color(1.0, 1.0, 1.0, 0.65)
	menu_buttons.add_child(label)


func _on_building_button_pressed(building_name: String) -> void:
	building_selected.emit(building_name)
