extends Node2D

class_name BlockManager

@export var block_list: Array[PackedScene]

@onready var block_spawn_point := $"../SpawnMarkers/BlockSpawnPoint"

var input_manager : InputManager
var combat_processor : CombatProcessor
var backpack : Backpack
var player_state : PlayerState

func spawn_block():
	var block = block_list.pick_random().instantiate()
	SFXManager.play_sfx("drop_block")
	add_child(block)
	bring_block_to_front(block)
	
	block.name = "block"
	block.picked_up.connect(_on_block_picked_up)
	block.rotated.connect(_on_block_rotated)
	block.dropped.connect(_on_block_dropped)
	block.counted_down.connect(_on_block_counted_down)
	block.activated.connect(combat_processor._on_block_activated)
	block.activated.connect(_on_block_activated)
	block.global_position = block_spawn_point.global_position + Vector2(randf_range(-100, 100), randf_range(-105, 100))


func _on_block_counted_down():
	SFXManager.play_sfx("dice_spawn")


func _on_block_rotated() -> void :
	SFXManager.play_sfx("click")


func _on_block_picked_up(block: Block):
	if block.is_slotted:
		backpack.set_tiles_unoccupied(block.get_tile_global_positions())
		block.is_slotted = false

	bring_block_to_front(block)

func reset_all_dice_slots_to_default() -> void:
	for block in get_tree().get_nodes_in_group("Blocks"):
		if block.has_method("reset_to_default_values"):
			block.reset_to_default_values()
		else:
			push_warning("Block does not have method - reset_to_default_values()")


func _on_block_activated(block : Block) -> void:
	if block.damage_value > 0:
		SFXManager.play_sfx("hit")
	if block.block_value > 0:
		SFXManager.play_sfx("shield")


func bring_block_to_front(block : Node2D):
	if block.get_parent() == self and is_instance_valid(block):
		move_child(block, -1)
	else:
		push_warning("Cannot bring block to front — not a child of BlockManager or not valid.")



func _on_block_dropped(block: Block):
	var tile_positions = block.get_tile_global_positions()
	SFXManager.play_sfx("drop_block")
	if backpack.are_spaces_empty(tile_positions):
		var snap_pos = backpack.get_nearest_tile_global_position(tile_positions[0])
		var offset = block.global_position - tile_positions[0]
		block.global_position = snap_pos + offset
		backpack.set_tiles_to_occupied(tile_positions)
		block.is_slotted = true
	else:
		block.pick_up(block.global_position)
		block.is_slotted = false


func _on_get_more_blocks_pressed() -> void:
	if player_state.coins < 3:
		return
	else:
		player_state.spend_coins(3)
		for i in range(3):
			spawn_block()
			await get_tree().create_timer(0.75).timeout


func get_blocks_with_adjacent_slots(block : Block) -> Array[Block]:
	var die_slots = block.get_die_slot_positions()
	var target_blocks: Array[Block] = []
	for slot_position in die_slots:
		var adjacent_backpack_slots_global_positions = backpack.get_adjacent_backpack_slots_global_positions(slot_position)
		for g_position in adjacent_backpack_slots_global_positions:
			var block_at_position = input_manager.get_topmost_block_at(g_position)
			var is_block_at_position = block_at_position is Block
			var is_die_slot_at_position := false
			
			if is_block_at_position:
				is_die_slot_at_position = block_at_position.is_position_a_die_slot(g_position)
			
			if is_die_slot_at_position and block_at_position.is_slotted:
				if block_at_position not in target_blocks:
					target_blocks.append(block_at_position)
	return target_blocks


func get_blocks_with_cardinal_adjacent_slots(block : Block) -> Array[Block]:
	var die_slots = block.get_die_slot_positions()
	var target_blocks: Array[Block] = []
	for slot_position in die_slots:
		var adjacent_backpack_slots_global_positions = backpack.get_cardinal_adjacent_backpack_slots_global_positions(slot_position)
		for g_position in adjacent_backpack_slots_global_positions:
			var block_at_position = input_manager.get_topmost_block_at(g_position)
			var is_block_at_position = block_at_position is Block
			var is_die_slot_at_position := false
			
			if is_block_at_position:
				is_die_slot_at_position = block_at_position.is_position_a_die_slot(g_position)
			
			if is_die_slot_at_position and block_at_position.is_slotted:
				if block_at_position not in target_blocks:
					target_blocks.append(block_at_position)
	return target_blocks

func clear_all_blocks():
	for block in get_tree().get_nodes_in_group("Blocks"):
		block.queue_free()
