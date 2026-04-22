extends Control

const MAP_SCENE := preload("res://scenes/map.tscn")

func _on_start_game_pressed():
	get_tree().change_scene_to_packed(MAP_SCENE)

func _on_tutorial_pressed():
	var map = MAP_SCENE.instantiate()
	map.tutorial_mode = true
	get_tree().root.add_child(map)
	get_tree().current_scene = map
	queue_free()
