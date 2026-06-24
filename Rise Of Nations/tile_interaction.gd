extends Node2D

const BUILDINGS := [
	{"name": "House", "color": Color("#f4c542")},
	{"name": "Farm", "color": Color("#79c267")},
	{"name": "Workshop", "color": Color("#6bb7d6")},
]

@onready var tile_map_layer: TileMapLayer = $Node2D/TileMapLayer

var selected_cell := Vector2i.ZERO
var placed_buildings: Dictionary = {}
var menu_layer: CanvasLayer
var menu_panel: PanelContainer
var menu_title: Label
var marker_layer: Node2D
var camera: Camera2D


func _ready() -> void:
	_create_build_menu()
	_create_marker_layer()
	_center_camera_on_map()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var world_position := get_global_mouse_position()
			var cell := tile_map_layer.local_to_map(tile_map_layer.to_local(world_position))

			if tile_map_layer.get_cell_source_id(cell) == -1:
				_hide_build_menu()
				return

			_show_build_menu(cell, get_viewport().get_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_hide_build_menu()


func _create_build_menu() -> void:
	menu_layer = CanvasLayer.new()
	add_child(menu_layer)

	menu_panel = PanelContainer.new()
	menu_panel.visible = false
	menu_panel.custom_minimum_size = Vector2(190, 0)
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

	for building in BUILDINGS:
		var button := Button.new()
		button.text = building["name"]
		button.pressed.connect(_on_building_pressed.bind(building["name"], building["color"]))
		list.add_child(button)

	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(_hide_build_menu)
	list.add_child(cancel_button)


func _create_marker_layer() -> void:
	marker_layer = Node2D.new()
	marker_layer.name = "BuildingMarkers"
	add_child(marker_layer)


func _center_camera_on_map() -> void:
	camera = Camera2D.new()
	camera.name = "Camera2D"
	add_child(camera)

	var used_cells := tile_map_layer.get_used_cells()
	if used_cells.is_empty():
		camera.global_position = Vector2.ZERO
	else:
		var min_position := Vector2(INF, INF)
		var max_position := Vector2(-INF, -INF)

		for cell in used_cells:
			var tile_position := tile_map_layer.to_global(tile_map_layer.map_to_local(cell))
			min_position = min_position.min(tile_position)
			max_position = max_position.max(tile_position)

		camera.global_position = (min_position + max_position) / 2.0

	camera.enabled = true
	camera.make_current()


func _show_build_menu(cell: Vector2i, viewport_position: Vector2) -> void:
	selected_cell = cell
	menu_title.text = "Build at %s, %s" % [cell.x, cell.y]
	menu_panel.position = viewport_position + Vector2(12, 12)
	menu_panel.visible = true


func _hide_build_menu() -> void:
	menu_panel.visible = false


func _on_building_pressed(building_name: String, marker_color: Color) -> void:
	placed_buildings[selected_cell] = building_name
	_add_or_update_marker(selected_cell, building_name, marker_color)
	_hide_build_menu()


func _add_or_update_marker(cell: Vector2i, building_name: String, marker_color: Color) -> void:
	var marker_name := "Building_%s_%s" % [cell.x, cell.y]
	var marker := marker_layer.get_node_or_null(marker_name) as ColorRect

	if marker == null:
		marker = ColorRect.new()
		marker.name = marker_name
		marker.custom_minimum_size = Vector2(120, 120)
		marker.size = marker.custom_minimum_size
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker_layer.add_child(marker)

	var tile_center := tile_map_layer.to_global(tile_map_layer.map_to_local(cell))
	marker.position = tile_center - marker.size / 2.0
	marker.color = Color(marker_color, 0.72)
	marker.tooltip_text = building_name
