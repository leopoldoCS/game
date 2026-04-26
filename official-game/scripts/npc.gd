extends Node2D


@onready var monster
@onready var monster1 = $monster1
@onready var monster2 = $monster2
@onready var monster3 = $monster3

func update():
	if monster == 1:
		monster1.visible = true;
	elif monster == 2:
		monster2.visible = true;
	elif monster == 3:
		monster3.visible = true;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
