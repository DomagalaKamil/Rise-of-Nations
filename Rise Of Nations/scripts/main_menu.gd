extends Control
const GAME_SCENE := "res://scenes/main_scene.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_build_menu()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _build_menu() -> void:
	var background := ColorRect.new()
	background.color = Color("#101318")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	move_child(background, 0) 
	

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_exit_pressed() -> void:
	get_tree().quit()
