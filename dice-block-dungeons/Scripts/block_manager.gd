extends Node2D


@export var block_list: Array[PackedScene]
@onready var backpack: Backpack = $Backpack

@export var coins : int = 5
@onready var textEdit := $"../UI/Control/TextEdit"
@onready var die_scene : PackedScene = preload("res://Scenes/die.tscn")

signal new_slot_purchaed(coins : int)

var selected_object = null
var animations_playing : bool = false

var active_blocks : Array = [] # Blocks currently processing
var overflow_queue : Array[Array] = [] #Holds overflow info for next processing round

##
## GENERAL SECTION
##
# Main Entry Point
func handle_mouse_click(mouse_pos: Vector2):
	var topmost_object = get_topmost_object_at(mouse_pos)
	if topmost_object != null:
		if selected_object != null && !selected_object.is_locked:
			selected_object.drop_object()
			selected_object = null
		elif !topmost_object.is_locked:
			selected_object = topmost_object
			topmost_object.pick_up(mouse_pos)
			move_child(topmost_object, -1)
	handle_backpack_tile_clicked(mouse_pos)


func get_topmost_object_at(mouse_pos: Vector2) -> Node2D:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var results = space_state.intersect_point(query)
	if results.is_empty():
		return null

	results.sort_custom(func(a, b): 
		return (
		(a.collider.is_in_group("Dice") and not b.collider.is_in_group("Dice")) or 
		(a.collider.is_in_group("Dice") == b.collider.is_in_group("Dice") and a.collider.z_index > b.collider.z_index) or 
		(a.collider.is_in_group("Dice") == b.collider.is_in_group("Dice") and a.collider.z_index == b.collider.z_index and a.collider.get_index() < b.collider.get_index())
	))

	var topmost_object = results[0].collider.get_parent()
	
	return topmost_object if topmost_object and (topmost_object.is_in_group("Blocks") or topmost_object.is_in_group("Dice")) else null


##
## ADD BACKPACK TILES SECTION
##
func _on_show_add_tiles_pressed() -> void:
	if not backpack.are_new_tiles_shown:
		backpack.show_add_tiles()
	else:
		backpack.hide_add_tiles()


func handle_backpack_tile_clicked(mouse_pos: Vector2) -> void:
	if backpack.is_position_add_new_block(mouse_pos):
		if coins > 0:
			backpack.add_new_block(mouse_pos)
			coins -= 1
			new_slot_purchaed.emit(coins)


##
## BLOCK SECTION
##
func _on_spawn_block_button_pressed():
	var block = block_list.pick_random().instantiate()
	add_child(block)
	move_child(block, -1)
	var input_text = textEdit.text.strip_edges()  # Remove leading/trailing spaces
	var die_value : int
	if input_text.is_valid_int():
		die_value = input_text.to_int()
		
		# Additional check if there's a valid range for die_value
		if die_value < 1 or die_value > 6:  
			die_value = randi_range(2,6) # Fallback default value if input is invalid
	else:
		die_value = randi_range(2,6) 

	block.set_dice_slots_default_value(die_value)
	block.name = "block " + str(die_value)
	# Pick random colour
	block.tilemap.modulate = Color.from_hsv(randf(), 0.6, 0.9) # Random hue, full saturation, full value
	# Connect signals when the block is created
	block.picked_up.connect(_on_block_picked_up)
	block.dropped.connect(_on_block_dropped)


func get_topmost_block_at(mouse_pos: Vector2) -> Block:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var results = space_state.intersect_point(query)
	if results.is_empty():
		return null

	results.sort_custom(func(a, b): 
		return (a.collider.z_index > b.collider.z_index) or (a.collider.z_index == b.collider.z_index and a.collider.get_index() > b.collider.get_index()))

	var object = results[0].collider.get_parent()

	return object if object and object.is_in_group("Blocks") else null


func _on_block_picked_up(block: Block):
	if block.is_slotted:
		backpack.set_tiles_unoccupied(block.get_tile_global_positions())
		block.is_slotted = false

	move_child(block, -1) # Bring to front


func _on_block_dropped(block: Block):
	var tile_positions = block.get_tile_global_positions()
	if backpack.are_spaces_empty(tile_positions):
		var snap_pos = backpack.get_nearest_tile_global_position(tile_positions[0])
		var offset = block.global_position - tile_positions[0]
		block.global_position = snap_pos + offset
		backpack.set_tiles_to_occupied(tile_positions)
		print("dropping block")
		block.is_slotted = true
	else:
		block.pick_up(block.global_position)
		block.is_slotted = false
		print("Cannot drop block here!")


##
## DICE SECTION
##
func _on_spawn_die_button_pressed() -> void:
	var die = die_scene.instantiate()
	add_child(die)
	die.set_random_value()
	die.die_dropped.connect(_on_die_dropped)


func _on_die_dropped(die : Die) -> void:
	var die_position = die.global_position
	
	var block_at_position = get_topmost_block_at(die_position)
	var is_block_at_position = block_at_position is Block
	var is_die_slot_at_position := false
	
	if is_block_at_position:
		is_die_slot_at_position = block_at_position.is_position_a_die_slot(die_position)
	
	if is_die_slot_at_position and block_at_position.is_slotted and not animations_playing:
		drop_die_in_slot(die, block_at_position)


func die_dropped_at_position(die_position : Vector2, value : int) -> void:
	var block_at_position = get_topmost_block_at(die_position)
	var is_block_at_position = block_at_position is Block
	var is_die_slot_at_position := false
	
	if is_block_at_position:
		is_die_slot_at_position = block_at_position.is_position_a_die_slot(die_position)
	
	if is_die_slot_at_position and block_at_position.is_slotted:
		await block_at_position.die_placed_in_slot(value)
	
	return



##
## Dice Dropping, Activation, and Overflow
##
func process_die_drop(blocks_and_values: Array[Array]) -> void:
	# Register blocks for countdown
	for tuple in blocks_and_values:
		var block: Block = tuple[0]
		var die_value: int = tuple[1]
		active_blocks.append(block)
		
		# Connect signal if not already connected
		if not block.countdown_complete.is_connected(_on_block_countdown_complete):
			block.countdown_complete.connect(_on_block_countdown_complete)
		
		# Start countdown animation
		block.die_placed_in_slot(die_value)
	
	# Wait until all blocks finish for proceeding
	while active_blocks:
		await get_tree().process_frame # Yield until next frame
	
	if overflow_queue:
		await process_overflow()
	else:
		print("no overflows to process")
		animations_playing = false


func _on_block_countdown_complete(block: Block, overflow_value: int) -> void:
	active_blocks.erase(block) # Remove block from active processing
	# Determine where overflow should go
	if overflow_value > 0:
		var blocks_with_adjacent_slots = get_blocks_with_adjacent_slots(block)
		for target_block in blocks_with_adjacent_slots:
			var exists_in_queue = false
			
			for i in range(overflow_queue.size()):
				var queued_block = overflow_queue[i][0]
				var queued_value = overflow_queue[i][1]
				
				if queued_block == target_block:
					exists_in_queue = true
					# If the new overflow value is greater, replace it
					if overflow_value > queued_value:
						overflow_queue[i][1] = overflow_value
					break  # No need to continue checking
					
			# If the block wasn't in the queue, add it
			if not exists_in_queue:
				overflow_queue.append([target_block, overflow_value])


func get_blocks_with_adjacent_slots(block : Block) -> Array[Block]:
	var die_slots = block.get_die_slot_positions()
	var target_blocks: Array[Block] = []
	for slot_position in die_slots:
		var adjacent_backpack_slots_global_positions = backpack.get_adjacent_backpack_slots_global_positions(slot_position)
		for g_position in adjacent_backpack_slots_global_positions:
			var block_at_position = get_topmost_block_at(g_position)
			var is_block_at_position = block_at_position is Block
			var is_die_slot_at_position := false
			
			if is_block_at_position:
				is_die_slot_at_position = block_at_position.is_position_a_die_slot(g_position)
			
			if is_die_slot_at_position and block_at_position.is_slotted:
				if block_at_position not in target_blocks:
					target_blocks.append(block_at_position)
	return target_blocks


func process_overflow() -> void:
	if overflow_queue.is_empty():
		print("overflow queue empty")
		animations_playing = false
		return # no more rounds needed
	
	# Move overflow queue to new round
	var new_round = overflow_queue.duplicate()
	overflow_queue.clear()
	
	# Start new round
	await process_die_drop(new_round)


func drop_die_in_slot(die : Die, block : Block):
	animations_playing = true
	var die_value = die.value
	die.queue_free()
	
	var initial_round: Array[Array]
	initial_round.append([block, die_value])
	process_die_drop(initial_round)
		
