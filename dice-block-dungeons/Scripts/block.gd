extends Node2D
class_name Block

signal picked_up(block)
signal dropped(block)
signal slot_overflowed(value : int, slot_positions : Array[Vector2])

var is_locked : = false
var dragging: bool = false
@onready var camera: Camera2D = get_viewport().get_camera_2d()
@onready var tilemap: TileMapLayer = $"Z-Block-TileMapLayer"

@onready var die_scene : PackedScene = preload("res://Scenes/die.tscn")

var is_slotted: bool

var dice_slots_default_value := 0
var dice_slots_value := 0

func set_dice_slots(die_value: int) -> void:
	var die_slots = get_die_slot_coordinates()
	for slot in die_slots:
		tilemap.set_cell(slot, 1, Vector2i(die_value, 0))


func set_dice_slots_default_value(die_value : int) -> void:
	var used_cells = tilemap.get_used_cells()
	for cell in used_cells:
		if tilemap.get_cell_atlas_coords(cell).x > 0:
			tilemap.set_cell(cell, 1, Vector2i(die_value, 0))
			dice_slots_value = die_value
			dice_slots_default_value = die_value


func activate(die_slots : Array[Vector2i]) -> void:
	var old_color = tilemap.modulate
	tilemap.modulate = Color.WHITE
	await get_tree().create_timer(0.5).timeout
	tilemap.modulate = old_color
	await get_tree().create_timer(0.25).timeout
	for cell in die_slots:
		tilemap.set_cell(cell, 1, Vector2i(dice_slots_default_value, 0))
		dice_slots_value = dice_slots_default_value
	await get_tree().create_timer(0.5).timeout


func display_slotted_die(die_value: int) -> void:
	var die_slots = get_die_slot_positions()
	var tweens = []

	for die_slot in die_slots:
		var die = die_scene.instantiate()
		die.scale = Vector2(0.6,0.6)
		add_child(die)
		die.global_position = die_slot + Vector2(0, -100)
		die.set_value(die_value)
		
		var target_position = die_slot + Vector2(0, -120)
		var tween = get_tree().create_tween()
		tween.tween_property(die, "global_position", target_position, 0.75).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
		
		tweens.append(tween)

	# Wait for all tweens to finish before destroying the dice
	for tween in tweens:
		await tween.finished
	
	# Destroy all created dice
	for die in get_children():
		if die is Die:  # Assuming 'Die' is the class name of the dice
			die.queue_free()


func die_placed_in_slot(die_value : int) -> void:
	# die slotted feedback
	is_locked = true
	display_slotted_die(die_value)
	var old_color = tilemap.modulate
	var modified_color = old_color
	modified_color.s = 0.6
	modified_color.v = 0.8
	tilemap.modulate = modified_color # increase saturation to 0.6 and reduce value to 0.8
	await get_tree().create_timer(0.7).timeout
	tilemap.modulate = old_color
	await get_tree().create_timer(0.3).timeout

	var die_slots = get_die_slot_coordinates()
	var overflow_value = die_value - dice_slots_value 
	var overflow_delay = 0.0
	var duration = 0.4
	var start_value = dice_slots_value # 1

	if overflow_value < 0: 
		var end_value = dice_slots_value - die_value
		var step_count = abs(start_value - end_value) 

		# Avoid division by zero if start and end values are the same
		if step_count > 0:
			var step_time = duration
			# Iterate through each value between start_value and end_value
			for current_value in range(start_value - 1, end_value - 1, -1):  # Step downwards
				for cell in die_slots:
					tilemap.set_cell(cell, 1, Vector2i(current_value, 0))
				await get_tree().create_timer(step_time).timeout
		else:
			for cell in die_slots:
				tilemap.set_cell(cell, 1, Vector2i(end_value, 0))
		dice_slots_value = end_value
	else:
		var end_value = 1 # 1
		var step_count = abs(start_value - end_value) # Ensure positive step count
		# Avoid division by zero if start and end values are the same
		if step_count > 0:
			var step_time = duration
			# Iterate through each value between start_value and end_value
			for current_value in range(start_value - 1, end_value - 1, -1):  # Step downwards
				for cell in die_slots:
					tilemap.set_cell(cell, 1, Vector2i(current_value, 0))
				await get_tree().create_timer(step_time).timeout
			# Die slot has reached minimum value of 1
			await activate(die_slots)
			
			# Reset die slot value to default value
			for cell in die_slots:
				tilemap.set_cell(cell, 1, Vector2i(dice_slots_default_value, 0))
			dice_slots_value = dice_slots_default_value
			
			if overflow_value > 0:
				await get_tree().create_timer(overflow_delay).timeout
				slot_overflowed.emit(overflow_value, self)
		else: 
			await activate(die_slots)
			# Reset die slot value to default value
			
			
			if overflow_value > 0:
				await get_tree().create_timer(overflow_delay).timeout
				slot_overflowed.emit(overflow_value, self)
	is_locked = false


func get_die_slot_coordinates() -> Array[Vector2i]:
	var die_slot_coordinates : Array[Vector2i] = []
	var used_cells = tilemap.get_used_cells()
	
	for cell in used_cells:
		if tilemap.get_cell_atlas_coords(cell).x > 0:
			die_slot_coordinates.append(cell)
	return die_slot_coordinates


func get_die_slot_positions() -> Array[Vector2]:
	var used_tiles = tilemap.get_used_cells()
	var die_slot_positions : Array[Vector2] = []
	
	for tile in used_tiles:
		if is_coord_a_die_slot(tile):
			die_slot_positions.append(get_coord_global_position(tile))
	
	return die_slot_positions


func get_coord_global_position(cell : Vector2i) -> Vector2:
	return tilemap.to_global(tilemap.map_to_local(cell))


func get_tile_global_positions() -> Array[Vector2]:
	var tile_positions: Array[Vector2]
	for cell in tilemap.get_used_cells():
		tile_positions.append(tilemap.to_global(tilemap.map_to_local(cell)))
	return tile_positions


func is_coord_a_die_slot(tile_coord : Vector2i) -> bool:
	var tile_source_id = tilemap.get_cell_source_id(tile_coord)
	if tile_source_id == 1:
		var tile_type = tilemap.get_cell_atlas_coords(tile_coord)
		return tile_type.x > 0 and tile_type.x < 7
	return false


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
