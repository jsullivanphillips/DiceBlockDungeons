extends Node2D

var dragging: bool = false
var offset: Vector2

@onready var tilemap : TileMapLayer = $TileMapLayer2D

signal block_dropped(block_cells : Array[Vector2], block : Node2D)

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if dragging:
					dragging = false  # Drop the object
					block_dropped.emit(get_tile_positions(), self)
				else:
					if is_mouse_over():
						dragging = true   # Pick up the object
						offset = position - event.position
		elif event.button_index == MOUSE_BUTTON_RIGHT and dragging:
			if event.pressed:
				rotation_degrees += 90  # Rotate the object 90 degrees clockwise
	elif event is InputEventMouseMotion and dragging:
		position = event.position + offset

func get_tile_positions():
	var tile_positions: Array[Vector2] = []  # Store tile world positions

	if tilemap is TileMapLayer:
		for cell in tilemap.get_used_cells():
			var local_position = tilemap.map_to_local(cell)  # Convert cell to local position
			var cell_global_position = tilemap.to_global(local_position)  # Convert to global position
			tile_positions.append(cell_global_position)

	return tile_positions


func is_mouse_over() -> bool:
	# We add 64,64 because the tile map is offset from origin by -64, -64. 
	# this value needs to be adjusted by the offset of the tile map from origin,
	# which will change depending on the block.
	var mouse_pos = tilemap.local_to_map(to_local(get_global_mouse_position() + Vector2(64, 64)))
	for cell in tilemap.get_used_cells():
		if mouse_pos == cell:
			return true
	
	return false
