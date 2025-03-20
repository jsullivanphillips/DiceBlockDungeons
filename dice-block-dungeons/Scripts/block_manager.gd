extends Node2D

@onready var block_scene: PackedScene = preload("res://Scenes/Blocks/block.tscn")
@onready var backpack: Backpack = $Backpack

@export var coins : int = 5

signal new_slot_purchaed(coins : int)

func _on_spawn_block_button_pressed():
	var block = block_scene.instantiate()
	add_child(block)
	move_child(block, -1)
	block.set_dice_values(randi_range(2,6))
	# Connect signals when the block is created
	block.picked_up.connect(_on_block_picked_up)
	block.dropped.connect(_on_block_dropped)


func handle_mouse_click(mouse_pos: Vector2):
	var topmost_block = get_topmost_block_at(mouse_pos)
	if topmost_block:
		handle_block_click(topmost_block, mouse_pos)
	
	handle_backpack_tile_clicked(mouse_pos)
	
	
func handle_backpack_tile_clicked(mouse_pos: Vector2) -> void:
	if backpack.is_position_add_new_block(mouse_pos):
		if coins > 0:
			backpack.add_new_block(mouse_pos)
			coins -= 1
			new_slot_purchaed.emit(coins)



func handle_block_click(topmost_block : Block, mouse_pos : Vector2) -> void:
	if topmost_block.is_being_dragged():
		topmost_block.drop_block()
	else:
		topmost_block.pick_up(mouse_pos)


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

	var block = results[0].collider.get_parent()
	return block if block and block.is_in_group("Blocks") else null


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


func _on_show_add_tiles_pressed() -> void:
	if not backpack.are_new_tiles_shown:
		backpack.show_add_tiles()
	else:
		backpack.hide_add_tiles()
