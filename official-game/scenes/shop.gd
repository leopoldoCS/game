extends Control

var shop_items = {
	"Rare": {"item_id": "rare_pet_skin", "slot": "skin", "cost": 50},
	"Legendary": {"item_id": "legendary_pet_skin", "slot": "skin", "cost": 100},
	"Mystic": {"item_id": "mystic_pet_skin", "slot": "skin", "cost": 300},
}

@onready var currency_label = $CenterContainer/ShopPanel/VBoxContainer/CurrencyLabel
@onready var message_label = $CenterContainer/ShopPanel/VBoxContainer/MessageLabel

var coins := 0
var _backend_client: Node

func _ready() -> void:
	_backend_client = preload("res://scripts/backend_client.gd").new()
	add_child(_backend_client)
	_backend_client.progress_loaded.connect(_on_progress_loaded)
	_backend_client.purchase_completed.connect(_on_purchase_completed)
	_backend_client.request_failed.connect(_on_backend_request_failed)
	_update_currency_label()
	message_label.text = "Loading balance..."
	_backend_client.get_progress()

func _update_currency_label() -> void:
	currency_label.text = "Money: $%d" % coins

func _buy_item(item_name: String) -> void:
	var item = shop_items[item_name]
	message_label.text = "Purchasing %s..." % item_name
	_backend_client.purchase_item(item["item_id"], item_name, item["slot"], item["cost"])

func _on_buy_button_1_pressed() -> void:
	_buy_item("Rare")

func _on_buy_button_2_pressed() -> void:
	_buy_item("Legendary")

func _on_buy_button_3_pressed() -> void:
	_buy_item("Mystic")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/mainRoom.tscn")

func _on_progress_loaded(data: Dictionary) -> void:
	coins = int(data.get("currency_balance", 0))
	_update_currency_label()
	message_label.text = ""

func _on_purchase_completed(data: Dictionary) -> void:
	coins = int(data.get("currency_balance", coins))
	_update_currency_label()
	message_label.text = "Purchased!"

func _on_backend_request_failed(message: String) -> void:
	message_label.text = message
