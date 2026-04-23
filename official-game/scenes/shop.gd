extends Control

var coins := 200

var shop_items = {
	"Rare": 50,
	"Legendary": 100,
	"Mystic": 300
}

@onready var currency_label = $CenterContainer/ShopPanel/VBoxContainer/CurrencyLabel
@onready var message_label = $CenterContainer/ShopPanel/VBoxContainer/MessageLabel

func _ready() -> void:
	_update_currency_label()
	message_label.text = ""

func _update_currency_label() -> void:
	currency_label.text = "Coins: %d" % coins

func _buy_item(item_name: String) -> void:
	var cost = shop_items[item_name]

	if coins >= cost:
		coins -= cost
		_update_currency_label()
		message_label.text = "Purchased %s!" % item_name
	else:
		message_label.text = "Not enough coins!"

func _on_buy_button_1_pressed() -> void:
	_buy_item("Rare")

func _on_buy_button_2_pressed() -> void:
	_buy_item("Legendary")

func _on_buy_button_3_pressed() -> void:
	_buy_item("Mystic")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/mainRoom.tscn")
