extends Node2D
## TO DO:
# Use tilemap colliders to check for mouse over so as not to grab multiple blocks at once.
# when we try to "let go" of a block by clicking, send a signal "trying_to_drop_block" but
# continue to hold on to the block.
# Then, have a function that recieves a signal from the BlockManager that "drops" the block
# (i.e. stops dragging it) if the space below is empty. 
# Otherwise, we will continue to drag this block. 

# So in summary, when we click to drop, just emit a signal. Do nothing else.

class_name Block

var camera : Camera2D

var dragging: bool = false
var offset: Vector2

@onready var tilemap : TileMapLayer = $"Z-Block-TileMapLayer"

var offset_from_tile_zero : Vector2

var is_slotted : bool

func _ready() -> void:
	camera = get_viewport().get_camera_2d()


func _on_block_clicked(mouse_position : Vector2) -> Array[Vector2]:
	print("clicked!")
	if dragging:
		return get_tile_global_positions()
	else:
		dragging = true   # Pick up the object
		global_position = mouse_position
		return [Vector2.ZERO]


func pick_up(mouse_position : Vector2) -> void:
	dragging = true   # Pick up the object
	global_position = mouse_position


func is_being_dragged() -> bool:
	return dragging


func drop_block() -> void:
	dragging = false  # Drop the object


func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and dragging:
			if event.pressed:
				rotation_degrees += 90  # Rotate the object 90 degrees clockwise
	elif event is InputEventMouseMotion and dragging:
		var mouse_pos = camera.get_local_mouse_position()
		global_position = mouse_pos
		


func get_tile_global_positions() -> Array[Vector2]:
	var tile_positions: Array[Vector2] = []  # Store tile world positions

	if tilemap is TileMapLayer:
		for cell in tilemap.get_used_cells():
			var local_position = tilemap.map_to_local(cell)  # Convert cell to local position
			var cell_global_position = tilemap.to_global(local_position)  # Convert to global position
			tile_positions.append(cell_global_position)

	return tile_positions


func set_global_position_with_offset(p_global_position : Vector2) -> void:
	global_position = p_global_position
