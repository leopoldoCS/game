extends Node2D

var TileScene = preload("res://scenes/tile.tscn")
var PlayerScene = preload("res://scenes/player.tscn")
var NPCScene = preload("res://scenes/npc.tscn")

var current_row = 0
var current_col = 0
var current_npc_row = 0
var current_npc_col = 1
var current_npc2_row = 0
var current_npc2_col = 2

var selected_tile = null
var selected_npc_tile = null
var selected_npc2_tile = null

var npc_finished = false
var npc2_finished = false

var tiles = []

enum PlayerState {
	CHOOSING,
	ANSWERING,
	MOVING
}
enum NPCState {
	CHOOSING,
	MOVING
}

var player_state = PlayerState.CHOOSING
var npc_state = NPCState.CHOOSING
var npc2_state = NPCState.CHOOSING

var player = PlayerScene.instantiate()
var npc = NPCScene.instantiate()
var npc2 = NPCScene.instantiate()

func _on_tile_clicked(tile):
	if player_state != PlayerState.CHOOSING:
		return
	
	print(current_row, current_col)
	print("MAP received:", tile.row, tile.col)
	selected_tile = tile
	player_state = PlayerState.ANSWERING
	tile.set_selected()
	tile.set_tile_state(tile.TileState.RESERVED)

func get_valid_tiles(row, col):
	var valid_tiles = []
	
	var next_row = row + 1
	var left = col - 1
	var front = col
	var right = col + 1
	
	if next_row >= tiles.size():
		print("Reached end of board")
		if (current_npc_row == 9):
			npc_finished = true
		if (current_npc2_row == 9):
			npc2_finished = true
		return valid_tiles
	
	if tiles[next_row][front].tile_state == tiles[next_row][front].TileState.EMPTY:
		valid_tiles.append(tiles[next_row][front])
	
	if left > -1:
		if tiles[next_row][left].tile_state == tiles[next_row][left].TileState.EMPTY:
			valid_tiles.append(tiles[next_row][left])
	if right < 4:
		if tiles[next_row][right].tile_state == tiles[next_row][right].TileState.EMPTY:
			valid_tiles.append(tiles[next_row][right])
			
	if col == 0:
		if tiles[next_row][right + 1].tile_state == tiles[next_row][right + 1].TileState.EMPTY:
			valid_tiles.append(tiles[next_row][right + 1])
	if col == 3:
		if tiles[next_row][left - 1].tile_state == tiles[next_row][left - 1].TileState.EMPTY:
			valid_tiles.append(tiles[next_row][left - 1])
			
	return valid_tiles
	
func find_tiles(row, col):
	clear_map()
	for tile in get_valid_tiles(row, col):
		tile.set_selectable(true)
	
func clear_map():
	for row in tiles:
		for tile in row:
			tile.set_selectable(false)
			

func _ready():
	var rows = 10
	var cols = 4
	var tile_size = 80
	var spacing = 0
	
	
	var start_x = 498
	var start_y = 760
	

	
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

	
	var start = tiles[0][0]
	start.set_tile_state(start.TileState.OCCUPIED)
	

	add_child(player)
	player.position = tiles[0][0].position
	
	add_child(npc)
	npc.position = tiles[0][1].position
	tiles[current_npc_row][current_npc_col].set_tile_state(tiles[current_npc_row][current_npc_col].TileState.OCCUPIED)
	
	add_child(npc2)
	npc2.position = tiles[0][2].position
	tiles[current_npc2_row][current_npc2_col].set_tile_state(tiles[current_npc2_row][current_npc2_col].TileState.OCCUPIED)
	
	find_tiles(current_row, current_col)
	
	npc_loop()
	npc2_loop()


func move_tile(row, col):
	var current_tile = tiles[current_row][current_col]
	current_tile.set_tile_state(current_tile.TileState.EMPTY)
	current_col = col
	current_row = row
	var moved_to_tile = tiles[row][col]
	moved_to_tile.set_tile_state(moved_to_tile.TileState.OCCUPIED)
	find_tiles(current_row, current_col)
	player_state = PlayerState.CHOOSING
	print(current_row, current_col)
	player.position = tiles[current_row][current_col].position
	
func _input(event):
	#if event is InputEventKey and event.pressed:
		#if event.keycode == KEY_N:
			#print("heloon")
			#npc_choose_move()
			#npc_start_move()
			
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
	await get_tree().create_timer(1).timeout
	var row = selected_tile.row
	var col = selected_tile.col
	move_tile(row, col)
	
	tiles[row][col].set_tile_state(tiles[row][col].TileState.OCCUPIED)
	
	selected_tile = null

func start_wrong_timer():
	player_state = PlayerState.MOVING
	await get_tree().create_timer(1.0).timeout
	player_state = PlayerState.ANSWERING

func npc_choose_move():
	var valid_moves = get_valid_tiles(current_npc_row, current_npc_col)
	
	if valid_moves.is_empty():
		return
	
	selected_npc_tile = valid_moves.pick_random()
	selected_npc_tile.set_tile_state(selected_npc_tile.TileState.RESERVED)
	selected_npc_tile.set_selectable(false)
	selected_npc_tile.set_selected()

func npc2_choose_move():
	var valid_moves = get_valid_tiles(current_npc2_row, current_npc2_col)
	
	if valid_moves.is_empty():
		return
	
	selected_npc2_tile = valid_moves.pick_random()
	selected_npc2_tile.set_tile_state(selected_npc2_tile.TileState.RESERVED)
	selected_npc2_tile.set_selectable(false)
	selected_npc2_tile.set_selected()

func npc_start_move():
	if selected_npc_tile == null:
		return
	
	await get_tree().create_timer(1).timeout
	npc_move_to_tile(selected_npc_tile.row, selected_npc_tile.col)
	selected_npc_tile = null
	find_tiles(current_row, current_col)

func npc2_start_move():
	if selected_npc2_tile == null:
		return
	
	await get_tree().create_timer(2).timeout
	npc2_move_to_tile(selected_npc2_tile.row, selected_npc2_tile.col)
	selected_npc2_tile = null
	find_tiles(current_row, current_col)

func npc_move_to_tile(row, col):
	tiles[current_npc_row][current_npc_col].set_tile_state(tiles[current_npc_row][current_npc_col].TileState.EMPTY)
	tiles[current_npc_row][current_npc_col].set_selectable(false)
	
	current_npc_row = row
	current_npc_col = col
	
	tiles[current_npc_row][current_npc_col].set_tile_state(tiles[current_npc_row][current_npc_col].TileState.OCCUPIED)
	npc.position = tiles[current_npc_row][current_npc_col].position

func npc2_move_to_tile(row, col):
	tiles[current_npc2_row][current_npc2_col].set_tile_state(tiles[current_npc2_row][current_npc2_col].TileState.EMPTY)
	tiles[current_npc2_row][current_npc2_col].set_selectable(false)
	
	current_npc2_row = row
	current_npc2_col = col
	
	tiles[current_npc2_row][current_npc2_col].set_tile_state(tiles[current_npc2_row][current_npc2_col].TileState.OCCUPIED)
	npc2.position = tiles[current_npc2_row][current_npc2_col].position
	
func npc_loop():
	while !npc_finished:
		npc_choose_move()
		await npc_start_move()

func npc2_loop():
	while !npc2_finished:
		npc2_choose_move()
		await npc2_start_move()
