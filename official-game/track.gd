extends Node2D

const ROWS := 10
const COLS := 4
const TILE_SIZE := Vector2(80, 80)
const START_POS := Vector2(200, 700)

var tile_data = []

func _ready():
	build_tile_data()
	queue_redraw()

func build_tile_data():
	tile_data.clear()

	for row in range(ROWS):
		var row_data = []
		for col in range(COLS):
			var tile_type = "boost" if (row + col) % 2 == 0 else "mud"
			row_data.append(tile_type)
		tile_data.append(row_data)

func get_tile_type(row: int, col: int) -> String:
	if not is_in_bounds(row, col):
		return ""
	return tile_data[row][col]

func get_cell_position(row: int, col: int) -> Vector2:
	return START_POS + Vector2(col * TILE_SIZE.x, -row * TILE_SIZE.y)

func is_in_bounds(row: int, col: int) -> bool:
	return row >= 0 and row < ROWS and col >= 0 and col < COLS

func _draw():
	for row in range(ROWS):
		for col in range(COLS):
			var pos = get_cell_position(row, col)
			var rect = Rect2(pos, TILE_SIZE)

			var tile_type = get_tile_type(row, col)
			var color = Color.GREEN if tile_type == "boost" else Color.BROWN

			draw_rect(rect, color)
			draw_rect(rect, Color.BLACK, false, 2.0)
