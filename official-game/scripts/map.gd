extends Node2D
#Added by Leo for LEADERBOARD
#---------------------------------------------------------

var player_texture = preload("res://my assets/Monster.png")
var npc_texture = preload("res://my assets/Monster.png")
#---------------------------------------------------------
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
enum TileType {
	NORMAL,
	FREEZE,
	ANSWER_HELP
}

var player_state = PlayerState.CHOOSING

var player = PlayerScene.instantiate()
var npc = NPCScene.instantiate()
var npc2 = NPCScene.instantiate()

func _on_tile_clicked(tile):
	if player_state != PlayerState.CHOOSING:
		return

	selected_tile = tile
	player_state = PlayerState.ANSWERING
	tile.set_selected()
	tile.set_tile_state(tile.TileState.RESERVED)
	var type = tile.tile_type
	var quiz = preload("res://QuizPopup.tscn").instantiate()
	add_child(quiz)
	quiz.tile_type = type
	
	quiz.answered.connect(_on_quiz_answered)
	
func get_random_question_type():
	var values = TileType.values()
	values.append(0)
	return values.pick_random()
	
func _on_quiz_answered(was_correct):
	if was_correct:
		start_movement_timer()
	else:
		start_wrong_timer()

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
			tile.tile_type = get_random_question_type()
			
			
			var x = start_x + col * (tile_size + spacing)
			var y = start_y - row * (tile_size + spacing)
			
			tile.position = Vector2(x, y)
			
			tile.tile_clicked.connect(_on_tile_clicked)
			
			tiles[row].append(tile)
			
			add_child(tile)
			tile.update_visual()

	
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
	#ADDED TO CALL LEADERBOARD
	update_leaderboard()


func move_tile(row, col):
	var current_tile = tiles[current_row][current_col]
	current_tile.set_tile_state(current_tile.TileState.EMPTY)
	current_col = col
	current_row = row
	var moved_to_tile = tiles[row][col]
	moved_to_tile.set_tile_state(moved_to_tile.TileState.OCCUPIED)
	moved_to_tile.tile_type = TileType.NORMAL
	moved_to_tile.update_visual()
	find_tiles(current_row, current_col)
	player_state = PlayerState.CHOOSING
	print(current_row, current_col)
	player.position = tiles[current_row][current_col].position
	#ADDED TO CALL LEADERBOARD
	update_leaderboard()
	

	
func start_movement_timer():
	player_state = PlayerState.MOVING
	await get_tree().create_timer(1).timeout
	tiles[current_row][current_col].tile_type = TileType.NORMAL
	tiles[current_row][current_col].update_visual()
	var row = selected_tile.row
	var col = selected_tile.col
	move_tile(row, col)
	
	tiles[row][col].set_tile_state(tiles[row][col].TileState.OCCUPIED)	
	
	selected_tile = null

func start_wrong_timer():
	selected_tile.set_tile_state(selected_tile.TileState.EMPTY)
	selected_tile.set_selectable(false)
	selected_tile = null
	player_state = PlayerState.CHOOSING
	find_tiles(current_row, current_col)

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
	tiles[current_npc_row][current_npc_col].tile_type = TileType.NORMAL
	tiles[current_npc_row][current_npc_col].update_visual()
	#ADDED TO CALL LEADERBOARD
	update_leaderboard()

func npc2_move_to_tile(row, col):
	tiles[current_npc2_row][current_npc2_col].set_tile_state(tiles[current_npc2_row][current_npc2_col].TileState.EMPTY)
	tiles[current_npc2_row][current_npc2_col].set_selectable(false)
	
	current_npc2_row = row
	current_npc2_col = col
	
	tiles[current_npc2_row][current_npc2_col].set_tile_state(tiles[current_npc2_row][current_npc2_col].TileState.OCCUPIED)
	npc2.position = tiles[current_npc2_row][current_npc2_col].position
	tiles[current_npc2_row][current_npc2_col].tile_type = TileType.NORMAL
	tiles[current_npc2_row][current_npc2_col].update_visual()
	#ADDED TO CALL LEADERBOARD
	update_leaderboard()
	
func npc_loop():
	while !npc_finished:
		npc_choose_move()
		await npc_start_move()

func npc2_loop():
	while !npc2_finished:
		npc2_choose_move()
		await npc2_start_move()


#FUNCTION ADDED FOR LEADERBOARD BY LEO
#------------------------------------------
func update_leaderboard():
	var standings = [
		{"name": "YOU", "row": current_row, "pic": player_texture},
		{"name": "NPC 1", "row": current_npc_row, "pic": npc_texture},
		{"name": "NPC 2", "row": current_npc2_row, "pic": npc_texture},
	]
	standings.sort_custom(func(a, b): return a["row"] > b["row"])

	var n1 = find_child("Name1", true, false)
	var n2 = find_child("Name2", true, false)
	var n3 = find_child("Name3", true, false)
	var p1 = find_child("Pic1", true, false)
	var p2 = find_child("Pic2", true, false)
	var p3 = find_child("Pic3", true, false)
	var r1 = find_child("Rank1", true, false)
	var r2 = find_child("Rank2", true, false)
	var r3 = find_child("Rank3", true, false)

	if n1 == null:
		return

	r1.text = "1st"
	r2.text = "2nd"
	r3.text = "3rd"
	n1.text = standings[0]["name"]
	n2.text = standings[1]["name"]
	n3.text = standings[2]["name"]
	p1.texture = standings[0]["pic"]
	p2.texture = standings[1]["pic"]
	p3.texture = standings[2]["pic"]

	#------------------------------------------
