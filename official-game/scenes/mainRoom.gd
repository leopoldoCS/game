extends Control

var is_muted := false
var current_level := 1
var current_xp := 0
var xp_to_next_level := 100

func _ready() -> void:
	$LeftButtons/tutorialButton.pressed.connect(_on_tutorial_button_pressed)
	$LevelPanel/CenterContainer/LevelButton.text = "Level %d" % current_level

func _process(delta: float) -> void:
	pass

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/tutorial_map.tscn")

func _on_tutorial_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/tutorial_map.tscn")

func _on_settings_button_pressed() -> void:
	$Settingspopup.visible = true

func _on_shop_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/shop.tscn")  # ✅ THIS is all you need

func _on_mute_button_pressed() -> void:
	is_muted = !is_muted
	AudioServer.set_bus_mute(0, is_muted)

	if is_muted:
		$Settingspopup/VBoxContainer/MuteButton.text = "Unmute"
	else:
		$Settingspopup/VBoxContainer/MuteButton.text = "Mute"

func _on_logout_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_level_button_pressed() -> void:
	$LevelPopup.visible = true

func _on_close_level_button_pressed() -> void:
	$LevelPopup.visible = false
