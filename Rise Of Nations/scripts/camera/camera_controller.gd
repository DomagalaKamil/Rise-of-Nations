extends RefCounted

const Settings = preload("res://scripts/camera/camera_settings.gd")

var camera: Camera2D
var is_dragging := false
var camera_min_bound := Vector2.ZERO
var camera_max_bound := Vector2.ZERO


func setup(parent: Node, tile_map_layer: TileMapLayer) -> void:
	camera = Camera2D.new()
	camera.name = "Camera2D"
	parent.add_child(camera)
	camera.zoom = Vector2(Settings.DEFAULT_CAMERA_ZOOM, Settings.DEFAULT_CAMERA_ZOOM)
	_center_on_tilemap(tile_map_layer)
	camera.enabled = true
	camera.make_current()


func handle_input(event: InputEvent) -> bool:
	if camera == null:
		return false

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			return true
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom(Settings.CAMERA_ZOOM_STEP)
			return true
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom(-Settings.CAMERA_ZOOM_STEP)
			return true
	elif event is InputEventMouseMotion and is_dragging:
		camera.global_position -= event.relative / camera.zoom.x
		_clamp_position()
		return true

	return false


func _center_on_tilemap(tile_map_layer: TileMapLayer) -> void:
	var used_cells := tile_map_layer.get_used_cells()
	if used_cells.is_empty():
		camera.global_position = Vector2.ZERO
		camera_min_bound = Vector2.ZERO
		camera_max_bound = Vector2.ZERO
	else:
		var min_position := Vector2(INF, INF)
		var max_position := Vector2(-INF, -INF)

		for cell in used_cells:
			var tile_position := tile_map_layer.to_global(tile_map_layer.map_to_local(cell))
			min_position = min_position.min(tile_position)
			max_position = max_position.max(tile_position)

		camera_min_bound = min_position - Vector2(Settings.CAMERA_LIMIT_PADDING, Settings.CAMERA_LIMIT_PADDING)
		camera_max_bound = max_position + Vector2(Settings.CAMERA_LIMIT_PADDING, Settings.CAMERA_LIMIT_PADDING)
		camera.global_position = (min_position + max_position) / 2.0

	camera.limit_left = int(camera_min_bound.x)
	camera.limit_top = int(camera_min_bound.y)
	camera.limit_right = int(camera_max_bound.x)
	camera.limit_bottom = int(camera_max_bound.y)


func _zoom(amount: float) -> void:
	var next_zoom: float = clampf(camera.zoom.x + amount, Settings.MIN_CAMERA_ZOOM, Settings.MAX_CAMERA_ZOOM)
	camera.zoom = Vector2(next_zoom, next_zoom)
	_clamp_position()


func _clamp_position() -> void:
	camera.global_position = Vector2(
		clampf(camera.global_position.x, camera_min_bound.x, camera_max_bound.x),
		clampf(camera.global_position.y, camera_min_bound.y, camera_max_bound.y)
	)
