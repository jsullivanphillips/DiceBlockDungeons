extends Node2D

@onready var block_scene: PackedScene = preload("res://Scenes/Blocks/block.tscn")
@onready var backpack: Backpack = $Backpack

@export var coins : int = 5

@onready var die_scene : PackedScene = preload("res://Scenes/die.tscn")

signal new_slot_purchaed(coins : int)

var selected_object = null

# Main Entry Point
func handle_mouse_click(mouse_pos: Vector2):
	var topmost_object = get_topmost_object_at(mouse_pos)
	if topmost_object != null:
		if selected_object != null:
			selected_object.drop_object()
			selected_object = null
		else:
			selected_object = topmost_object
			topmost_object.pick_up(mouse_pos)
			move_child(topmost_object, -1)
	handle_backpack_tile_clicked(mouse_pos)


func _on_spawn_die_button_pressed() -> void:
	var die = die_scene.instantiate()
	add_child(die)
	die.set_random_value()
	die.die_dropped.connect(_on_die_dropped)

	
func _on_spawn_block_button_pressed():
	var block = block_scene.instantiate()
	add_child(block)
	move_child(block, -1)
	var die_value = randi_range(2,6)
	block.set_dice_slots_default_value(die_value)
	block.name = "block " + str(die_value)
	# Pick random colour
	block.tilemap.modulate = Color.from_hsv(randf(), 0.7, 1.0) # Random hue, full saturation, full value
	# Connect signals when the block is created
	block.picked_up.connect(_on_block_picked_up)
	block.dropped.connect(_on_block_dropped)
	block.slot_overflowed.connect(_on_slot_overflowed)


## TO DO: PASS BLOCK OBJECT INSTEAD OF SLOT POSITION TO THIS FUNCTION!!
func _on_slot_overflowed(overflow_value : int, block : Block):
	# get global positions of tiles adjacent to the tile
	var die_slots = block.get_die_slot_positions()
	
	for slot_position in die_slots:
		var adjacent_backpack_slots_global_positions = backpack.get_adjacent_backpack_slots_global_positions(slot_position)
		for g_position in adjacent_backpack_slots_global_positions:
			die_dropped_at_position(g_position, overflow_value)


func handle_backpack_tile_clicked(mouse_pos: Vector2) -> void:
	if backpack.is_position_add_new_block(mouse_pos):
		if coins > 0:
			backpack.add_new_block(mouse_pos)
			coins -= 1
			new_slot_purchaed.emit(coins)


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
	
	var i = 0
	for object in results:
		print("[", i, "]: ", object.collider.get_parent())
		i += 1
	
	return topmost_object if topmost_object and (topmost_object.is_in_group("Blocks") or topmost_object.is_in_group("Dice")) else null



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


func _on_die_dropped(die : Die) -> void:
	var die_position = die.global_position
	
	var block_at_position = get_topmost_block_at(die_position)
	var is_block_at_position = block_at_position is Block
	var is_die_slot_at_position := false
	
	if is_block_at_position:
		is_die_slot_at_position = block_at_position.is_position_a_die_slot(die_position)
	
	if is_die_slot_at_position and block_at_position.is_slotted:
		block_at_position.die_placed_in_slot(die.value)
		die.queue_free()


func die_dropped_at_position(die_position : Vector2, value : int) -> void:
	var block_at_position = get_topmost_block_at(die_position)
	var is_block_at_position = block_at_position is Block
	var is_die_slot_at_position := false
	
	if is_block_at_position:
		is_die_slot_at_position = block_at_position.is_position_a_die_slot(die_position)
	
	if is_die_slot_at_position and block_at_position.is_slotted:
		block_at_position.die_placed_in_slot(value)



func _on_show_add_tiles_pressed() -> void:
	if not backpack.are_new_tiles_shown:
		backpack.show_add_tiles()
	else:
		backpack.hide_add_tiles()
