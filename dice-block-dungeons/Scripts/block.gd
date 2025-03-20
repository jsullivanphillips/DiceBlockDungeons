extends Node2D
class_name Block

signal picked_up(block)
signal dropped(block)

var dragging: bool = false
@onready var camera: Camera2D = get_viewport().get_camera_2d()
@onready var tilemap: TileMapLayer = $"Z-Block-TileMapLayer"

var is_slotted: bool

func set_dice_values(die_value : int) -> void:
	var used_cells = tilemap.get_used_cells()
	for cell in used_cells:
		if tilemap.get_cell_atlas_coords(cell).x > 0:
			tilemap.set_cell(cell, 1, Vector2i(die_value, 0))


func pick_up(mouse_position: Vector2):
	picked_up.emit(self)
	dragging = true
	global_position = mouse_position


func drop_block():
	dropped.emit(self)
	dragging = false


func is_being_dragged() -> bool:
	return dragging


func _input(event: InputEvent):
	if dragging:
		if event is InputEventMouseMotion:
			global_position = camera.get_local_mouse_position()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			rotation_degrees += 90


func get_tile_global_positions() -> Array[Vector2]:
	var tile_positions: Array[Vector2]
	for cell in tilemap.get_used_cells():
		tile_positions.append(tilemap.to_global(tilemap.map_to_local(cell)))
	return tile_positions
