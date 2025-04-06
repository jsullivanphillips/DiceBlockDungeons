extends Node2D
class_name Block

# Signals
signal picked_up(block)
signal dropped(block)
signal activated(block)
signal countdown_complete(block : Block, overflow_value : int)

# Variables
var is_locked : = false
var dragging: bool = false

@onready var camera: Camera2D = get_viewport().get_camera_2d()
@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var die_scene : PackedScene = preload("res://Scenes/die.tscn")

var is_slotted: bool

var dice_slots_default_value := 0
var dice_slots_value := 0

@export var damage_value = 0
@export var block_value = 0
@onready var stat_label = $Label

@onready var damage_block_cost : Array = [
	{"damage": 3, "block": 0, "cost": 5},
	{"damage": 0, "block": 2, "cost": 3},
	{"damage": 2, "block": 0, "cost": 4},
	{"damage": 1, "block": 0, "cost": 2},
	{"damage": 0, "block": 3, "cost": 4},
]

func _ready() -> void:
	var stats = damage_block_cost.pick_random()
	damage_value = stats["damage"]
	block_value = stats["block"]
	set_dice_slots_default_value(stats["cost"])
	
	
	if damage_value > 0:
		stat_label.text = str(damage_value) + " dmg"
	elif block_value > 0:
		stat_label.text = str(block_value) + "blk"
	else:
		stat_label.text = ""
	
	if damage_value > 0:
		tilemap.modulate = Color.from_hsv(0, 0.6, 0.9)
	elif block_value > 0:
		tilemap.modulate = Color.from_hsv(0.6, 0.6, 0.9)

##
## DISPLAY FUNCTIONS
##
# Activate the block with visual effects
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


# Change color of the block to a darker shade with a "pop" effect
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


# Update the dice slot visuals based on the current value
func update_dice_slots_visuals(current_value : int):
	var die_slots = get_die_slot_coordinates()
	for cell in die_slots:
		tilemap.set_cell(cell, 1, Vector2i(current_value, 0))


##
## INTERNAL LOGIC FUNCTIONS
##
# Reset the dice slots to their default values
func reset_to_default_values():
	var die_slots = get_die_slot_coordinates()
	for cell in die_slots:
		tilemap.set_cell(cell, 1, Vector2i(dice_slots_default_value, 0))
		dice_slots_value = dice_slots_default_value


# Handle the logic for placing a die in a slot, adjusting the slot value and handling overflow
func die_placed_in_slot(die_value : int) -> void:
	is_locked = true
	
	await change_color_to_darker()

	var start_value = dice_slots_value
	var end_value = max(0, start_value - die_value)
	var overflow_value = die_value - (start_value - end_value)
	var duration = 0.6
	
	# Step down the dice slot value
	for current_value in range(start_value - 1, end_value-1, -1):  # Step downwards
		if current_value > 0:
			update_dice_slots_visuals(current_value)
			await get_tree().create_timer(duration).timeout
		
	if end_value == 0:
		# If all slots are emptied, activate the block
		await activate()
		overflow_value = max(0, overflow_value)
		reset_to_default_values()
	else:
		dice_slots_value = end_value
	 
	countdown_complete.emit(self, overflow_value)
	
	is_locked = false


##
## API FUNCTIONS
##
# Set the dice slot value to the specified value
func set_dice_slots(die_value: int) -> void:
	var die_slots = get_die_slot_coordinates()
	for slot in die_slots:
		tilemap.set_cell(slot, 1, Vector2i(die_value, 0))


# Set the dice slots' default value
func set_dice_slots_default_value(die_value : int) -> void:
	var used_cells = tilemap.get_used_cells()
	for cell in used_cells:
		if tilemap.get_cell_source_id(cell) == 1:
			if tilemap.get_cell_atlas_coords(cell).x > 0:
				tilemap.set_cell(cell, 1, Vector2i(die_value, 0))
				dice_slots_value = die_value
				dice_slots_default_value = die_value


# Retrieve the coordinates of the dice slots
func get_die_slot_coordinates() -> Array[Vector2i]:
	var die_slot_coordinates : Array[Vector2i] = []
	var used_cells = tilemap.get_used_cells()
	
	for cell in used_cells:
		if tilemap.get_cell_atlas_coords(cell).x > 0:
			die_slot_coordinates.append(cell)
	return die_slot_coordinates


# Retrieve the world positions of the dice slots
func get_die_slot_positions() -> Array[Vector2]:
	var used_tiles = tilemap.get_used_cells()
	var die_slot_positions : Array[Vector2] = []
	for tile in used_tiles:
		if is_coord_a_die_slot(tile):
			die_slot_positions.append(get_coord_global_position(tile))
	
	return die_slot_positions


# Convert tile coordinates to global position
func get_coord_global_position(cell : Vector2i) -> Vector2:
	return tilemap.to_global(tilemap.map_to_local(cell))


# Get the global positions of all the tiles
func get_tile_global_positions() -> Array[Vector2]:
	var tile_positions: Array[Vector2]
	for cell in tilemap.get_used_cells():
		tile_positions.append(tilemap.to_global(tilemap.map_to_local(cell)))
	return tile_positions


# Check if the tile is a valid dice slot based on its coordinates
func is_coord_a_die_slot(tile_coord : Vector2i) -> bool:
	var tile_source_id = tilemap.get_cell_source_id(tile_coord)
	if tile_source_id == 1:
		var tile_type = tilemap.get_cell_atlas_coords(tile_coord)
		return tile_type.x > 0 and tile_type.x < 7
	return false


# Check if a global position corresponds to a die slot
func is_position_a_die_slot(p_global_position : Vector2) -> bool:
	var tile_coord = tilemap.local_to_map(tilemap.to_local(p_global_position))
	var tile_source_id = tilemap.get_cell_source_id(tile_coord)
	if tile_source_id == 1:
		var tile_type = tilemap.get_cell_atlas_coords(tile_coord)
		return tile_type.x > 0 and tile_type.x < 7
	return false


##
## DRAG AND DROP FUNCTIONS
##
# Handle picking up the block with the mouse
func pick_up(mouse_position: Vector2):
	picked_up.emit(self)
	dragging = true
	global_position = mouse_position


# Handle dropping the block
func drop_object():
	dropped.emit(self)
	dragging = false


# Check if the block is being dragged
func is_being_dragged() -> bool:
	return dragging


# Handle input events for drag and rotation
func _input(event: InputEvent):
	if dragging:
		if event is InputEventMouseMotion:
			global_position = camera.get_local_mouse_position()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			rotation_degrees += 90
