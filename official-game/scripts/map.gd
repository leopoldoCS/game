extends Node2D

# Added for LEADERBOARD
# ---------------------------------------------------------
@export var tutorial_mode := false

var player_texture = preload("res://my assets/Monster.png")
var npc_texture = preload("res://my assets/Monster.png")

# ---------------------------------------------------------
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

var camera_offset_y = 320
var rows = 11
var cols = 4

var tiles = []

# countdown variable
var race_started = false

# For Leaderboard Order Finish
var finish_order = []

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
var tutorial_step := 0
var tutorial_panel: PanelContainer
var tutorial_label: Label
var tutorial_button: Button
var tutorial_finished := false

var player = PlayerScene.instantiate()
var npc = NPCScene.instantiate()
var npc2 = NPCScene.instantiate()

@onready var camera = $Camera2D

func _process(delta):
	camera.position.y = lerp(camera.position.y, player.position.y - camera_offset_y, 0.01)

func _on_tile_clicked(tile):
	if not race_started:
		return
	if player_state != PlayerState.CHOOSING:
		return
	if tutorial_mode and tutorial_step < 1:
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
	if tutorial_mode and tutorial_step == 1:
		advance_tutorial_step()

func get_random_question_type():
	var values = TileType.values()
	values.append(0)
	return values.pick_random()

func _on_quiz_answered(was_correct):
	if tutorial_mode and tutorial_step == 2:
		if was_correct:
			show_tutorial_message("Nice. A correct answer lets you move onto the tile you picked. Watch your monster move forward.")
			advance_tutorial_step()
		else:
			show_tutorial_message("A wrong answer means you stay put. Click a highlighted tile and try again.")
			tutorial_button.hide()

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
		if current_npc_row == rows - 1:
			npc_finished = true
		if current_npc2_row == rows - 1:
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
	var tile_size = 160
	var spacing = 0

	var start_x = 510
	var start_y = 720

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

	# ADDED TO CALL LEADERBOARD
	update_leaderboard()
	if tutorial_mode:
		setup_tutorial_ui()
		show_tutorial_message("Welcome to the tutorial. Your goal is to race up the board by clicking a highlighted tile.")
		tutorial_button.text = "Show Me"
		tutorial_button.show()

	create_finish_line()
	start_countdown()

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
	if current_row == rows - 1:
		player.position.y -= 160

	if current_row == 9 and "YOU" not in finish_order:
		finish_order.append("YOU")

	update_leaderboard()

	if tutorial_mode and tutorial_step == 3:
		tutorial_button.text = "Next"
		tutorial_button.show()

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

func setup_tutorial_ui():
	var ui_layer = find_child("UI", true, false)
	if ui_layer == null:
		return

	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.custom_minimum_size = Vector2(520, 180)
	tutorial_panel.position = Vector2(840, 540)
	tutorial_panel.size = Vector2(520, 180)
	tutorial_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.94)
	style.border_color = Color(0.94, 0.77, 0.18, 1.0)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	tutorial_panel.add_theme_stylebox_override("panel", style)

	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.offset_left = 18
	container.offset_top = 18
	container.offset_right = -18
	container.offset_bottom = -18
	container.add_theme_constant_override("separation", 12)
	tutorial_panel.add_child(container)

	tutorial_label = Label.new()
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_label.custom_minimum_size = Vector2(0, 110)
	tutorial_label.add_theme_font_size_override("font_size", 26)
	container.add_child(tutorial_label)

	tutorial_button = Button.new()
	tutorial_button.custom_minimum_size = Vector2(0, 46)
	tutorial_button.text = "Next"
	tutorial_button.add_theme_font_size_override("font_size", 22)
	tutorial_button.pressed.connect(_on_tutorial_button_pressed)
	container.add_child(tutorial_button)

	ui_layer.add_child(tutorial_panel)

func show_tutorial_message(message: String):
	if tutorial_panel == null:
		return
	tutorial_panel.show()
	tutorial_label.text = message

func _on_tutorial_button_pressed():
	match tutorial_step:
		0:
			show_tutorial_message("Highlighted tiles are your valid moves. Click one of them to open a quiz question.")
			tutorial_button.hide()
			advance_tutorial_step()
		3:
			show_tutorial_message("NPCs race upward too. In the full game they keep moving, so answer quickly to stay ahead.")
			tutorial_button.text = "Finish Tutorial"
			tutorial_button.show()
			advance_tutorial_step()
		4:
			tutorial_finished = true
			get_tree().change_scene_to_file("res://scenes/map.tscn")

func advance_tutorial_step():
	tutorial_step += 1

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

	var move_tile_target = selected_npc_tile
	await get_tree().create_timer(1).timeout
	if move_tile_target == null:
		return
	npc_move_to_tile(move_tile_target.row, move_tile_target.col)
	selected_npc_tile = null
	find_tiles(current_row, current_col)

func npc2_start_move():
	if selected_npc2_tile == null:
		return

	var move_tile_target = selected_npc2_tile
	await get_tree().create_timer(2).timeout
	if move_tile_target == null:
		return
	npc2_move_to_tile(move_tile_target.row, move_tile_target.col)
	selected_npc2_tile = null
	find_tiles(current_row, current_col)

func npc_move_to_tile(row, col):
	tiles[current_npc_row][current_npc_col].set_tile_state(tiles[current_npc_row][current_npc_col].TileState.EMPTY)
	tiles[current_npc_row][current_npc_col].set_selectable(false)

	current_npc_row = row
	current_npc_col = col

	tiles[current_npc_row][current_npc_col].set_tile_state(tiles[current_npc_row][current_npc_col].TileState.OCCUPIED)
	npc.position = tiles[current_npc_row][current_npc_col].position
	if current_npc_row == rows - 1:
		npc.position.y -= 160

	tiles[current_npc_row][current_npc_col].tile_type = TileType.NORMAL
	tiles[current_npc_row][current_npc_col].update_visual()
	if current_npc_row == 9 and "NPC 1" not in finish_order:
		finish_order.append("NPC 1")

	update_leaderboard()

func npc2_move_to_tile(row, col):
	tiles[current_npc2_row][current_npc2_col].set_tile_state(tiles[current_npc2_row][current_npc2_col].TileState.EMPTY)
	tiles[current_npc2_row][current_npc2_col].set_selectable(false)

	current_npc2_row = row
	current_npc2_col = col

	tiles[current_npc2_row][current_npc2_col].set_tile_state(tiles[current_npc2_row][current_npc2_col].TileState.OCCUPIED)
	npc2.position = tiles[current_npc2_row][current_npc2_col].position
	if current_npc2_row == rows - 1:
		npc2.position.y -= 160

	tiles[current_npc2_row][current_npc2_col].tile_type = TileType.NORMAL
	tiles[current_npc2_row][current_npc2_col].update_visual()
	if current_npc2_row == 9 and "NPC 2" not in finish_order:
		finish_order.append("NPC 2")

	update_leaderboard()

func npc_loop():
	while !npc_finished:
		npc_choose_move()
		await npc_start_move()

func npc2_loop():
	while !npc2_finished:
		npc2_choose_move()
		await npc2_start_move()

# FUNCTION ADDED FOR LEADERBOARD
# ------------------------------------------
func update_leaderboard():
	var standings = [
		{"name": "YOU", "row": current_row, "pic": player_texture},
		{"name": "NPC 1", "row": current_npc_row, "pic": npc_texture},
		{"name": "NPC 2", "row": current_npc2_row, "pic": npc_texture},
	]

	standings.sort_custom(func(a, b):
		if a["row"] != b["row"]:
			return a["row"] > b["row"]
		var a_pos = finish_order.find(a["name"])
		var b_pos = finish_order.find(b["name"])
		if a_pos == -1:
			a_pos = 999
		if b_pos == -1:
			b_pos = 999
		return a_pos < b_pos
	)

	var n1 = find_child("Name1", true, false)
	if n1 == null:
		return

	find_child("Rank1", true, false).text = "1st"
	find_child("Rank2", true, false).text = "2nd"
	find_child("Rank3", true, false).text = "3rd"
	n1.text = standings[0]["name"]
	find_child("Name2", true, false).text = standings[1]["name"]
	find_child("Name3", true, false).text = standings[2]["name"]
	find_child("Pic1", true, false).texture = standings[0]["pic"]
	find_child("Pic2", true, false).texture = standings[1]["pic"]
	find_child("Pic3", true, false).texture = standings[2]["pic"]

# Countdown function
func start_countdown():
	var countdown_label = find_child("Countdown", true, false)
	if countdown_label == null:
		race_started = true
		return

	var sfx = AudioStreamPlayer.new()
	add_child(sfx)

	countdown_label.visible = true

	countdown_label.text = "3"
	sfx.stream = load("res://Assets/3.ogg")
	sfx.play()
	await get_tree().create_timer(1.0).timeout

	countdown_label.text = "2"
	sfx.stream = load("res://Assets/2.ogg")
	sfx.play()
	await get_tree().create_timer(1.0).timeout

	countdown_label.text = "1"
	sfx.stream = load("res://Assets/1.ogg")
	sfx.play()
	await get_tree().create_timer(1.0).timeout

	countdown_label.text = "GO!"
	sfx.stream = load("res://Assets/go.ogg")
	sfx.play()
	await get_tree().create_timer(0.5).timeout

	countdown_label.visible = false
	sfx.queue_free()
	race_started = true
	npc_loop()
	npc2_loop()

# Create Finish Line
func create_finish_line():
	var tile_size = 160
	var last_row_y = tiles[rows - 1][0].position.y

	var line = ColorRect.new()
	line.color = Color("#e74c3c")
	line.size = Vector2(cols * tile_size, 150)
	line.position = Vector2(tiles[0][0].position.x - 80, last_row_y - 230)
	add_child(line)

	var label = Label.new()
	label.text = "FINISH"
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color("000000ff"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(tiles[0][0].position.x - 85, last_row_y - 210)
	label.size = Vector2(cols * tile_size, 45)

	line.z_index = -1
	label.z_index = -1

	add_child(label)
