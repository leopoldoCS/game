extends Area2D

var col = 0
var row = 0
var tile_type = "Normal"

var selectable = true

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

func _input_event(viewport, event, shape_idx):
	if not selectable:
		return

	if event is InputEventMouseButton and event.pressed:
		print("Tile clicked: ", row, col)
		emit_signal("tile_clicked", self)

signal tile_clicked(tile)

func set_selectable(value: bool):
	selectable = value
	
	if selectable:
		sprite.modulate = Color(1, 1, 1) # bright
	else:
		sprite.modulate = Color(0.5, 0.5, 0.5) # dim
