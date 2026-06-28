extends RefCounted

signal build_requested(building_name: String)
signal upgrade_requested(building_index: int)
signal closed

const Defs = preload("res://scripts/definitions/game_definitions.gd")
const ICON_SIZE := Vector2(44, 44)
const PANEL_SIZE := Vector2(700, 620)
const BUILDING_ICONS_TEXTURE := preload("res://art/building_icons.png")

var menu_layer: CanvasLayer
var menu_panel: PanelContainer
var menu_title: Label
var available_rows: VBoxContainer
var existing_rows: VBoxContainer


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

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	content.add_child(header)

	menu_title = Label.new()
	menu_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(menu_title)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(hide)
	header.add_child(close_button)

	var available_label := Label.new()
	available_label.text = "Can build"
	content.add_child(available_label)

	available_rows = VBoxContainer.new()
	available_rows.add_theme_constant_override("separation", 8)
	content.add_child(available_rows)

	var existing_label := Label.new()
	existing_label.text = "Existing buildings"
	content.add_child(existing_label)

	existing_rows = VBoxContainer.new()
	existing_rows.add_theme_constant_override("separation", 8)
	content.add_child(existing_rows)


func show_for_tile(terrain: String, existing_buildings: Array, max_buildings: int) -> void:
	_refresh(terrain, existing_buildings, max_buildings)
	_center_panel()
	menu_panel.visible = true


func hide() -> void:
	if menu_panel != null:
		menu_panel.visible = false
	closed.emit()


func refresh_deferred(terrain: String, existing_buildings: Array, max_buildings: int) -> void:
	call_deferred("_refresh", terrain, existing_buildings, max_buildings)


func _refresh(terrain: String, existing_buildings: Array, max_buildings: int) -> void:
	_clear_rows(available_rows)
	_clear_rows(existing_rows)

	var terrain_label: String = Defs.TERRAIN_LABELS.get(terrain, terrain.capitalize())
	menu_title.text = terrain_label
	_add_available_building_rows(terrain, existing_buildings, max_buildings)
	_add_existing_building_rows(existing_buildings)


func _add_available_building_rows(terrain: String, existing_buildings: Array, max_buildings: int) -> void:
	var allowed_buildings: Array = Defs.ALLOWED_BUILDINGS_BY_TERRAIN.get(terrain, [])
	if allowed_buildings.is_empty():
		_add_plain_row(available_rows, "No buildings available")
		return

	if existing_buildings.size() >= max_buildings:
		_add_plain_row(available_rows, "Building limit reached")
		return

	for building_name_value in allowed_buildings:
		var building_name: String = str(building_name_value)
		var row := _create_row()
		row.add_child(_create_icon(building_name))
		row.add_child(_create_text(Defs.BUILDING_LABELS.get(building_name, building_name.capitalize()), 190))
		row.add_child(_create_text("Cost: demo", 120))
		row.add_child(_create_text("Time: demo", 120))

		var build_button := Button.new()
		build_button.text = "Build"
		build_button.pressed.connect(_on_build_button_pressed.bind(building_name))
		row.add_child(build_button)
		available_rows.add_child(row)


func _add_existing_building_rows(existing_buildings: Array) -> void:
	if existing_buildings.is_empty():
		_add_plain_row(existing_rows, "No buildings placed")
		return

	for index in range(existing_buildings.size()):
		var building_data: Dictionary = existing_buildings[index]
		var building_type: String = str(building_data.get("type", ""))
		var row := _create_row()
		row.add_child(_create_icon(building_type))
		row.add_child(_create_text(Defs.BUILDING_LABELS.get(building_type, building_type.capitalize()), 230))
		row.add_child(_create_text("Lv %s" % _get_display_level(building_data), 90))

		var upgrade_button := Button.new()
		upgrade_button.text = "Upgrade"
		upgrade_button.pressed.connect(_on_upgrade_button_pressed.bind(index))
		row.add_child(upgrade_button)
		existing_rows.add_child(row)


func _get_display_level(building_data: Dictionary) -> int:
	var upgrades: Dictionary = building_data.get("upgrades", {})
	if upgrades.is_empty():
		return int(building_data.get("level", 1))

	var highest_level := 1
	for level_value in upgrades.values():
		highest_level = maxi(highest_level, int(level_value))
	return highest_level


func _create_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	return row


func _create_text(text: String, width: int) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(width, 0)
	return label


func _create_icon(building_name: String) -> TextureRect:
	var icon := TextureRect.new()
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var icon_coords: Vector2i = Defs.BUILDING_ICONS.get(building_name, Vector2i.ZERO)
	var texture_size: Vector2 = BUILDING_ICONS_TEXTURE.get_size()
	var icon_cell_size: Vector2 = Vector2(texture_size.x / Defs.ICON_GRID_SIZE.x, texture_size.y / Defs.ICON_GRID_SIZE.y)
	var atlas := AtlasTexture.new()
	atlas.atlas = BUILDING_ICONS_TEXTURE
	atlas.region = Rect2(Vector2(icon_coords.x, icon_coords.y) * icon_cell_size, icon_cell_size)
	icon.texture = atlas
	return icon


func _add_plain_row(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = Color(1.0, 1.0, 1.0, 0.65)
	parent.add_child(label)


func _clear_rows(parent: VBoxContainer) -> void:
	for child in parent.get_children():
		child.queue_free()


func _apply_panel_style(panel: PanelContainer) -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.94)
	panel_style.border_color = Color(0.28, 0.28, 0.28, 1.0)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", panel_style)


func _center_panel() -> void:
	var viewport_size := Vector2(1152, 648)
	if menu_layer != null:
		viewport_size = menu_layer.get_viewport().get_visible_rect().size
	menu_panel.position = (viewport_size - PANEL_SIZE) / 2.0


func _on_build_button_pressed(building_name: String) -> void:
	build_requested.emit(building_name)


func _on_upgrade_button_pressed(building_index: int) -> void:
	upgrade_requested.emit(building_index)
