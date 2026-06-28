extends RefCounted

const ICON_SIZE := Vector2(28, 28)
const BAR_SIZE := Vector2(120, 12)
const COIN_ICON := preload("res://art/coin_icon.png")
const WOOD_ICON := preload("res://art/wood_icon.png")
const POPULATION_ICON := preload("res://art/population_icon.png")
const ROCK_ICON_PATH := "res://art/rock_icon.png"

var canvas_layer: CanvasLayer
var gold_label: Label
var wood_label: Label
var rock_label: Label
var population_label: Label
var gold_bar: ProgressBar
var wood_bar: ProgressBar
var rock_bar: ProgressBar
var rock_icon: Texture2D


func setup(parent: Node) -> void:
	rock_icon = _load_icon_or_fallback(ROCK_ICON_PATH, WOOD_ICON)

	canvas_layer = CanvasLayer.new()
	parent.add_child(canvas_layer)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	margin.offset_left = -190
	margin.offset_top = 16
	margin.offset_right = -16
	margin.offset_bottom = 210
	canvas_layer.add_child(margin)

	var panel := PanelContainer.new()
	margin.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	var gold_widgets: Dictionary = _create_capacity_resource(column, COIN_ICON)
	gold_label = gold_widgets["label"] as Label
	gold_bar = gold_widgets["bar"] as ProgressBar

	var wood_widgets: Dictionary = _create_capacity_resource(column, WOOD_ICON)
	wood_label = wood_widgets["label"] as Label
	wood_bar = wood_widgets["bar"] as ProgressBar

	var rock_widgets: Dictionary = _create_capacity_resource(column, rock_icon)
	rock_label = rock_widgets["label"] as Label
	rock_bar = rock_widgets["bar"] as ProgressBar

	population_label = _create_population_resource(column)


func update_values(resource_state: Dictionary) -> void:
	var gold: int = int(resource_state.get("gold", 0))
	var gold_capacity: int = int(resource_state.get("gold_capacity", 0))
	var wood: int = int(resource_state.get("wood", 0))
	var wood_capacity: int = int(resource_state.get("wood_capacity", 0))
	var rock: int = int(resource_state.get("rock", 0))
	var rock_capacity: int = int(resource_state.get("rock_capacity", 0))
	var population: int = int(resource_state.get("population", 0))

	gold_label.text = "%s/%s" % [gold, gold_capacity]
	gold_bar.max_value = maxf(float(gold_capacity), 1.0)
	gold_bar.value = gold

	wood_label.text = "%s/%s" % [wood, wood_capacity]
	wood_bar.max_value = maxf(float(wood_capacity), 1.0)
	wood_bar.value = wood

	rock_label.text = "%s/%s" % [rock, rock_capacity]
	rock_bar.max_value = maxf(float(rock_capacity), 1.0)
	rock_bar.value = rock

	population_label.text = str(population)


func _create_capacity_resource(parent: BoxContainer, icon: Texture2D) -> Dictionary:
	var resource_row := HBoxContainer.new()
	resource_row.add_theme_constant_override("separation", 6)
	parent.add_child(resource_row)

	var icon_rect := TextureRect.new()
	icon_rect.texture = icon
	icon_rect.custom_minimum_size = ICON_SIZE
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	resource_row.add_child(icon_rect)

	var value_column := VBoxContainer.new()
	value_column.add_theme_constant_override("separation", 2)
	resource_row.add_child(value_column)

	var label := Label.new()
	label.text = "0/0"
	value_column.add_child(label)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = BAR_SIZE
	bar.show_percentage = false
	value_column.add_child(bar)

	return {
		"label": label,
		"bar": bar,
	}


func _create_population_resource(parent: BoxContainer) -> Label:
	var resource_row := HBoxContainer.new()
	resource_row.add_theme_constant_override("separation", 6)
	parent.add_child(resource_row)

	var icon_rect := TextureRect.new()
	icon_rect.texture = POPULATION_ICON
	icon_rect.custom_minimum_size = ICON_SIZE
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	resource_row.add_child(icon_rect)

	var label := Label.new()
	label.text = "0"
	resource_row.add_child(label)
	return label


func _load_icon_or_fallback(path: String, fallback: Texture2D) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded_resource: Resource = load(path)
		if loaded_resource is Texture2D:
			return loaded_resource as Texture2D

	return fallback
