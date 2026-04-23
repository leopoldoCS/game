extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/race_game.tscn")


func _on_tutorial_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map.tscn")


func _on_settings_button_pressed() -> void:
	print("Settings clicked")


func _on_shop_button_pressed() -> void:
	print("Shop clicked")
