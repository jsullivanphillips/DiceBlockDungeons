extends Node2D
class_name Block

signal picked_up(block)
signal dropped(block)
signal slot_overflowed(value : int, slot_position : Vector2)

var dragging: bool = false
@onready var camera: Camera2D = get_viewport().get_camera_2d()
@onready var tilemap: TileMapLayer = $"Z-Block-TileMapLayer"

var is_slotted: bool

var dice_slots_default_value := 0
var dice_slots_value := 0

func set_dice_slots(die_value : int) -> void:
	var used_cells = tilemap.get_used_cells()
	for cell in used_cells:
		if tilemap.get_cell_atlas_coords(cell).x > 0:
			tilemap.set_cell(cell, 1, Vector2i(die_value, 0))
			dice_slots_value = die_value


func set_dice_slots_default_value(die_value : int) -> void:
	var used_cells = tilemap.get_used_cells()
	for cell in used_cells:
		if tilemap.get_cell_atlas_coords(cell).x > 0:
			tilemap.set_cell(cell, 1, Vector2i(die_value, 0))
			dice_slots_value = die_value
			dice_slots_default_value = die_value
			


func die_placed_in_slot(die_value : int, slot_position : Vector2) -> void:
	print("die (", die_value, ") placed in slot (", dice_slots_value, ")")
	if die_value >= dice_slots_value:
		var overflow_value = die_value - dice_slots_value
		# activate
		print("activating!")
		# overflow
		if overflow_value > 0:
			print("overflowing by (", overflow_value, ")")
			slot_overflowed.emit(overflow_value, slot_position)
		# reset value
		set_dice_slots(dice_slots_default_value)
	else:
		set_dice_slots(dice_slots_value - die_value)


func is_position_a_die_slot(p_global_position : Vector2) -> bool:
	var tile_coord = tilemap.local_to_map(tilemap.to_local(p_global_position))
	var tile_source_id = tilemap.get_cell_source_id(tile_coord)
	if tile_source_id == 1:
		var tile_type = tilemap.get_cell_atlas_coords(tile_coord)
		return tile_type.x > 0 and tile_type.x < 7
	return false


func pick_up(mouse_position: Vector2):
	picked_up.emit(self)
	dragging = true
	global_position = mouse_position


func drop_object():
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
