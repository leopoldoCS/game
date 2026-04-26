extends Area2D

var col = 0
var row = 0
var tile_type = "Normal"

enum TileType {
	NORMAL,
	FREEZE,
	ANSWER_HELP,
	START
}

enum TileState {
	OCCUPIED,
	EMPTY,
	RESERVED
}

var tile_state = TileState.EMPTY
var selectable = null

@export var normal_texture: Texture2D
@export var freeze_texture: Texture2D
@export var answer_help_texture: Texture2D
@export var start: Texture2D

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

signal tile_clicked(tile)

func update_visual():
	match tile_type:
		TileType.NORMAL:
			sprite.texture = normal_texture
		TileType.FREEZE:
			sprite.texture = freeze_texture
		TileType.ANSWER_HELP:
			sprite.texture = answer_help_texture
		TileType.START:
			sprite.texture = start
			sprite.modulate = Color(1.0, 1.0, 1.0)

func _input_event(_viewport, event, _shape_idx):
	if not selectable:
		return

	if event is InputEventMouseButton and event.pressed:
		print("Tile clicked: ", row, col)
		emit_signal("tile_clicked", self)

func set_selectable(value: bool):
	selectable = value

	if tile_state == TileState.RESERVED or tile_state == TileState.OCCUPIED:
		return

	if selectable:
		sprite.modulate = Color(1, 1, 1)
	else:
		if tile_type == TileType.START:
			return
		sprite.modulate = Color(0.3, 0.3, 0.3)

func set_selected(kind):
	if kind == "player":
		sprite.modulate = Color(0.0, 1.0, 0.3)
	elif kind == "npc1":
		sprite.modulate = Color(0.562, 0.001, 0.682, 1.0)

func set_tile_state(new_state):
	tile_state = new_state

	if new_state == TileState.OCCUPIED:
		if tile_type == TileType.START:
			return
		sprite.modulate = Color(1.0, 0.0, 0.3)
