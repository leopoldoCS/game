extends Node2D

var TileScene = preload("res://scenes/tile.tscn")

var current_row = 0
var current_col = 0

var selected_tile = null

var tiles = []

enum PlayerState {
	CHOOSING,
	ANSWERING,
	MOVING
}

var player_state = PlayerState.CHOOSING

func _on_tile_clicked(tile):
	if player_state != PlayerState.CHOOSING:
		return
	
	print(current_row, current_col)
	print("MAP received:", tile.row, tile.col)
	selected_tile = [tile.row, tile.col]
	player_state = PlayerState.ANSWERING
	tile.set_selected()
	
	
func find_tiles():
	var next_row = current_row + 1
	var left = current_col - 1
	var front = current_col
	var right = current_col + 1
	
	tiles[next_row][front].set_selectable(true)
	
	if left > -1:
		tiles[next_row][left].set_selectable(true)
	if right < 4:
		tiles[next_row][right].set_selectable(true)
	
func clear_map():
	for row in tiles:
		for tile in row:
			tile.set_selectable(false)
			

func _ready():
	var rows = 10
	var cols = 4
	var tile_size = 60
	var spacing = 0
	
	
	var start_x = 454
	var start_y = 618
	

	
	for row in range(rows):
		tiles.append([])
		for col in range(cols):
			var tile = TileScene.instantiate()
			tile.row = row
			tile.col = col
			
			var x = start_x + col * (tile_size + spacing)
			var y = start_y - row * (tile_size + spacing)
			
			tile.position = Vector2(x, y)
			
			tile.tile_clicked.connect(_on_tile_clicked)
			
			tiles[row].append(tile)
			
			add_child(tile)
	
	clear_map()
	find_tiles()

func move_tile(row, col):
	current_col = col
	current_row = row
	clear_map()
	find_tiles()
	player_state = PlayerState.CHOOSING
	print(current_row, current_col)
	
func _input(event):
	if player_state != PlayerState.ANSWERING:
		return

	if event.is_action_pressed("ui_accept"):  # like Enter
		print("Correct!")
		start_movement_timer()

	if event.is_action_pressed("ui_cancel"):  # like Esc
		print("Wrong!")
		start_wrong_timer()
	
func start_movement_timer():
	player_state = PlayerState.MOVING
	await get_tree().create_timer(2.0).timeout
	move_tile(selected_tile[0], selected_tile[1])
	selected_tile = false

func start_wrong_timer():
	player_state = PlayerState.MOVING
	await get_tree().create_timer(1.0).timeout
	player_state = PlayerState.ANSWERING
