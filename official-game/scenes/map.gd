extends Node2D

var TileScene = preload("res://scenes/tile.tscn")

func _ready():
	var rows = 10
	var cols = 4
	var tile_size = 60
	var spacing = 0
	
	
	var start_x = 454
	var start_y = 618
	
	for row in range(rows):
		for col in range(cols):
			var tile = TileScene.instantiate()
			tile.row = row
			tile.col = col
			
			var x = start_x + col * (tile_size + spacing)
			var y = start_y - row * (tile_size + spacing)
			
			tile.position = Vector2(x, y)
			
			add_child(tile)
