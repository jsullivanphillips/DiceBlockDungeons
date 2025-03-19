extends Node2D

@onready var camera := $Camera2D  # Ensure there's a Camera2D in the scene

@onready var backpack := $BlockManager/Backpack

var are_we_dragging_a_block : bool

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		select_topmost_object()

func select_topmost_object():
	var space_state = get_world_2d().direct_space_state
	var mouse_world_pos = camera.get_global_mouse_position()

	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_world_pos
	query.collide_with_bodies = true
	query.collide_with_areas = true  # Enable if you want to select areas too

	var results = space_state.intersect_point(query)

	if results.is_empty():
		print("No object found")
		return

	# Sort by Z-index first, then by scene tree order (higher `get_index()` = rendered on top)
	results.sort_custom(func(a, b): 
		return (a.collider.z_index > b.collider.z_index) or (a.collider.z_index == b.collider.z_index and a.collider.get_index() > b.collider.get_index()))

	var topmost = results[0].collider
	
	# Move up the tree to find the "Block" parent
	var block = topmost.get_parent() 

	if block and block.is_in_group("Blocks"):
		var is_block_being_dragged = block.is_being_dragged()
		
		if is_block_being_dragged && are_we_dragging_a_block: # drop block
			var tile_positions : Array[Vector2] = block.get_tile_global_positions()
			if backpack.are_spaces_empty(tile_positions):
				print("backpack slots are empty. Dropping!")
				block.drop_block()
				are_we_dragging_a_block = false
				# Find the position of one of the tiles
				var block_zero_position = tile_positions[0]
				# Calculate the offset of that tile to the origin of the block
				var offset = block.global_position - block_zero_position
				# Find which tile in the backpack that tile is closest to and get its global position
				var closest_backpack_tile_position = backpack.get_nearest_tile_global_position(block_zero_position)
				# Set the blocks global_position to the backpack tiles position 
				# minus the offset from the origin
				block.set_global_position_with_offset(closest_backpack_tile_position + offset)
				
				# Set those backpack tiles to occupied
				backpack.set_tiles_to_occupied(tile_positions)
				
			elif backpack.is_out_of_pack_bounds(block.global_position):
				print("block center: ", block.global_position, " | mouse position: ", mouse_world_pos)
				print("out of pack bounds!")
				block.drop_block()
				are_we_dragging_a_block = false
			
				
		elif not are_we_dragging_a_block: # Pick up block
			var tile_positions : Array[Vector2] = block.get_tile_global_positions()
			backpack.set_tiles_unoccupied(tile_positions)
			block.pick_up(mouse_world_pos)
			var block_manager = block.get_parent()
			block_manager.move_child(block, -1)
			are_we_dragging_a_block = true
			

	else:
		print("No valid parent with on_selected() found")
	
	
