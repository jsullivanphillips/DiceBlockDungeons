@tool
extends Node2D
class_name Block


# Signals
signal picked_up(block)
signal dropped(block)
signal activated(block)
signal countdown_complete(block : Block, overflow_value : int)
signal counted_down()
signal rotated()

# Variables
var is_locked : = false
var dragging: bool = false
var is_in_play: bool = false

@onready var camera: CameraShake
@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var die_scene : PackedScene = preload("res://Scenes/die.tscn")

var is_slotted: bool

var dice_slots_default_value := 0
var dice_slots_value := 0

@export var damage_value = 0
@export var block_value = 0
@export var bonus_dice_value = 0
@onready var stat_label = $Label

#const ShapeLib = preload("res://Blocks/BlockShapeLibrary.gd")
var _pending_resource: BlockResource = null

func setup_from_resource(resource: BlockResource):
	_pending_resource = resource
	call_deferred("_apply_pending_resource")


func _apply_pending_resource():
	# Wait one frame to allow @onready vars like tilemap to init
	await get_tree().process_frame

	if not is_instance_valid(tilemap):
		push_warning("TileMap still not initialized after deferral.")
		return
	generate_shape_from_resource(_pending_resource)
	set_stats_from_resource(_pending_resource)
	_pending_resource = null


func set_stats_from_resource(block_resource: BlockResource):
	damage_value = block_resource.attack
	block_value = block_resource.shield
	bonus_dice_value = block_resource.bonus_dice
	set_dice_slots_default_value(block_resource.dice_cost)
	
	if damage_value > 0:
		stat_label.text = str(damage_value) + " dmg"
	elif block_value > 0:
		stat_label.text = str(block_value) + " blk"
	elif bonus_dice_value > 0:
		stat_label.text = str(bonus_dice_value) + " dice"
	else:
		stat_label.text = ""
	
	if damage_value > 0:
		tilemap.modulate = Color.from_hsv(0, 0.5, 0.9)
	elif block_value > 0:
		tilemap.modulate = Color.from_hsv(0.6, 0.5, 0.9)
	elif bonus_dice_value > 0:
		tilemap.modulate = Color.from_hsv(0.3, 0.5, 0.9)

func generate_shape_from_resource(block_resource: BlockResource):
	var tiles = BlockShapeLibrary.get_tiles(block_resource.shape_id)
	var offset = BlockShapeLibrary.get_offset(block_resource.shape_id)
	
	tilemap.clear()
	for cell in tiles:
		tilemap.set_cell(cell["pos"], 1, Vector2i(cell["tile"], 0))
	tilemap.position = offset


##
## DISPLAY FUNCTIONS
##
# Activate the block with visual effects
func activate() -> void:
	activated.emit(self)
	is_in_play = true
	show_in_play_visual()
	# Change saturation to full saturation to indicate the block is in play
	var old_color = tilemap.modulate
	var modified_color = Color.from_hsv(old_color.h, 0.9, 0.95, old_color.a)

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


func show_in_play_visual():
	# Get current HSV values
	var base_color := tilemap.modulate
	var h = base_color.h
	var s = base_color.s
	var v = base_color.v
	var a = base_color.a

	# Boost saturation slightly and clamp
	var boosted_color := Color.from_hsv(h, clamp(s + 0.4, 0, 1), v, a)
	tilemap.modulate = boosted_color


func play_discard_animation():
	var tween := create_tween()

	var up_pos := global_position + Vector2(0, -50)
	var exit_pos := get_viewport_rect().size + Vector2(100, 100)  # bottom right, offscreen
	var shrink_scale := scale * 0.1

	# Move up slightly
	tween.tween_property(self, "global_position", up_pos, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Then fly and shrink
	tween.tween_property(self, "global_position", exit_pos, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "scale", shrink_scale, 0.4).set_trans(Tween.TRANS_SINE)

	await tween.finished
	queue_free()


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
	var duration = 0.4
	
	# Step down the dice slot value
	for current_value in range(start_value - 1, end_value-1, -1):  # Step downwards
		if current_value > 0:
			counted_down.emit()
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


func slide_into_position(target_position: Vector2) -> void:
	# Start smaller
	scale = Vector2(0.1, 0.1)

	var tween := create_tween()

	# Slide into position
	tween.tween_property(self, "global_position", target_position, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Grow to full size in parallel
	tween.parallel().tween_property(self, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)



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
			global_position = camera.get_global_mouse_position()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			rotated.emit()
			rotation_degrees += 90
