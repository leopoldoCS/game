extends Control

const MAP_SCENE_PATH := "res://scenes/map.tscn"
const TUTORIAL_SCENE_PATH := "res://scenes/tutorial_map.tscn"

func _on_start_game_pressed():
	get_tree().change_scene_to_file(MAP_SCENE_PATH)

func _on_tutorial_pressed():
	get_tree().change_scene_to_file(TUTORIAL_SCENE_PATH)
