extends Control

var is_muted := false
var current_level := 1
var current_xp_percentage := 0.0
var xp_to_next_level := 100
var current_coins := 0

@onready var _level_button: Button = $LevelPanel/CenterContainer/LevelButton
@onready var _level_value: Label = $LevelPopup/PanelContainer/VBoxContainer/LevelValue
@onready var _xp_value: Label = $LevelPopup/PanelContainer/VBoxContainer/XPValue
@onready var _xp_bar: ProgressBar = $LevelPopup/PanelContainer/VBoxContainer/XPBar
@onready var _coins_value: Label = $LevelPopup/PanelContainer/VBoxContainer/CoinsValue

var _backend_client: Node

func _ready() -> void:
	$LeftButtons/tutorialButton.pressed.connect(_on_tutorial_button_pressed)
	_backend_client = preload("res://scripts/backend_client.gd").new()
	add_child(_backend_client)
	_backend_client.progress_loaded.connect(_on_progress_loaded)
	_backend_client.request_failed.connect(_on_backend_request_failed)
	_refresh_player_info()
	_backend_client.get_progress()

func _process(delta: float) -> void:
	pass

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map.tscn")

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

func _refresh_player_info() -> void:
	_level_button.text = "Level %d" % current_level
	_level_value.text = "Level %d" % current_level
	_xp_value.text = "Progress: %.1f%%  |  %d XP to next level" % [current_xp_percentage, xp_to_next_level]
	_xp_bar.value = current_xp_percentage
	_coins_value.text = "Money: $%d" % current_coins

func _on_progress_loaded(data: Dictionary) -> void:
	current_level = int(data.get("current_level", 1))
	current_xp_percentage = float(data.get("xp_progress_percentage", 0.0))
	xp_to_next_level = int(data.get("xp_to_next_level", 100))
	current_coins = int(data.get("currency_balance", 0))
	_refresh_player_info()

func _on_backend_request_failed(message: String) -> void:
	_xp_value.text = "Backend sync unavailable"
	_coins_value.text = message
