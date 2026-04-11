extends Area2D

var col = 0
var row = 0
var tile_type = "Normal"
enum TileState {
	OCCUPIED,
	EMPTY,
	RESERVED
}

var tile_state = TileState.EMPTY

var selectable = null

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
	
	if (tile_state == TileState.RESERVED || tile_state == TileState.OCCUPIED):
		return;
	
	if selectable:
		sprite.modulate = Color(1, 1, 1) # bright
	else:
		sprite.modulate = Color(0.6, 0.6, 0.6) # dim
		
func set_selected():
	sprite.modulate = Color(0.0, 1.0, 0.3) # neon green

func set_tile_state(new_state):
	tile_state = new_state
	
	if new_state == TileState.OCCUPIED:
		sprite.modulate = Color(1.0, 0.0, 0.3)
