extends Node2D
class_name Block

signal picked_up(block)
signal dropped(block)
signal activated(block)

signal countdown_complete(block : Block, overflow_value : int)

var is_locked : = false
var dragging: bool = false


@onready var camera: Camera2D = get_viewport().get_camera_2d()
@onready var tilemap: TileMapLayer = $"Z-Block-TileMapLayer"

@onready var die_scene : PackedScene = preload("res://Scenes/die.tscn")

var is_slotted: bool

var dice_slots_default_value := 0
var dice_slots_value := 0


##
## Display
##
func activate() -> void:
	activated.emit(self)

	var old_color = tilemap.modulate
	var modified_color = old_color
	modified_color.s = 0.2
	modified_color.v = 0.95

	var tween = get_tree().create_tween()

	# Step 1: Bright Flash + Scale Up (Pop Effect)
	tween.tween_property(tilemap, "modulate", modified_color, 0.2) \
		.set_trans(Tween.TRANS_CIRC) \
		.set_ease(Tween.EASE_OUT)
	
	tween.parallel().tween_property(self, "scale", Vector2(1.15, 1.15), 0.2) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)

	await tween.finished

	# Step 2: Subtle Return to Normal Color + Scale
	var tween_back = get_tree().create_tween()
	tween_back.tween_property(tilemap, "modulate", old_color, 0.4) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)
	
	tween_back.parallel().tween_property(self, "scale", Vector2(1, 1), 0.3) \
		.set_trans(Tween.TRANS_BOUNCE) \
		.set_ease(Tween.EASE_OUT)

	await tween_back.finished

	reset_to_default_values()


func change_color_to_darker():
	var old_color = tilemap.modulate
	var modified_color = old_color
	modified_color.s = 0.8
	modified_color.v = 0.6

	var tween = get_tree().create_tween()

	# Step 1: Flash to Darker Color with a Pop Effect
	tween.tween_property(tilemap, "modulate", modified_color, 0.3)  # Smooth transition to darker
	tween.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

	# Add a scale up for a "pop" effect (like Candy Crush!)
	tween.parallel().tween_property(self, "scale", Vector2(1.1, 1.1), 0.3) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)

	await tween.finished

	# Step 2: Bounce Back to Normal Color + Scale
	var tween_back = get_tree().create_tween()

	# Returning to original color smoothly
	tween_back.tween_property(tilemap, "modulate", old_color, 0.5) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_IN_OUT)

	# Adding bounce back for extra fun when scaling down
	tween_back.parallel().tween_property(self, "scale", Vector2(1, 1), 0.4) \
		.set_trans(Tween.TRANS_BOUNCE) \
		.set_ease(Tween.EASE_OUT)

	await tween_back.finished




func update_dice_slots_visuals(current_value : int):
	var die_slots = get_die_slot_coordinates()
	for cell in die_slots:
		tilemap.set_cell(cell, 1, Vector2i(current_value, 0))


## Internal Logic
func reset_to_default_values():
	var die_slots = get_die_slot_coordinates()
	for cell in die_slots:
		tilemap.set_cell(cell, 1, Vector2i(dice_slots_default_value, 0))
		dice_slots_value = dice_slots_default_value
	



func die_placed_in_slot(die_value : int) -> void:
	is_locked = true
	
	await change_color_to_darker()

	var start_value = dice_slots_value
	var end_value = max(0, start_value - die_value)
	var overflow_value = die_value - (start_value - end_value)
	var duration = 0.6
	
	for current_value in range(start_value - 1, end_value-1, -1):  # Step downwards
		if current_value > 0:
			update_dice_slots_visuals(current_value)
			await get_tree().create_timer(duration).timeout
		
	if end_value == 0:
		await activate()
		overflow_value = max(0, overflow_value)
		reset_to_default_values()
	else:
		dice_slots_value = end_value
	
	
	countdown_complete.emit(self, overflow_value)
	
	is_locked = false


##
## API Stuff 
##
func set_dice_slots(die_value: int) -> void:
	var die_slots = get_die_slot_coordinates()
	for slot in die_slots:
		tilemap.set_cell(slot, 1, Vector2i(die_value, 0))


func set_dice_slots_default_value(die_value : int) -> void:
	var used_cells = tilemap.get_used_cells()
	for cell in used_cells:
		if tilemap.get_cell_source_id(cell) == 1:
			if tilemap.get_cell_atlas_coords(cell).x > 0:
				tilemap.set_cell(cell, 1, Vector2i(die_value, 0))
				dice_slots_value = die_value
				dice_slots_default_value = die_value


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
	print("tile_positions: ", tile_positions)
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
