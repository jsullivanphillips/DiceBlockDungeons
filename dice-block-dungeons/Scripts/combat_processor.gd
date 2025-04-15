extends Node

class_name CombatProcessor

var block_manager : BlockManager
var dice_manager : DiceManager
var enemy_manager : EnemyManager
var player_state : PlayerState
var game_flow_manager : GameFlowManager

var is_combat_processing : bool

var active_blocks : Array = [] # Blocks currently processing
var overflow_queue : Array[Array] = [] #Holds overflow info for next processing round

func _on_block_activated(block : Block) -> void:
	if block.damage_value > 0:
		enemy_manager.deal_damage(block.damage_value)

	if block.block_value > 0:
		player_state.add_shield(block.block_value)

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
		dice_manager.display_slotted_die(die_value, block.get_die_slot_positions())
		SFXManager.play_sfx("drop_block")
	
	# Wait until all blocks finish for proceeding
	while active_blocks:
		await get_tree().process_frame # Yield until next frame
	
	if overflow_queue:
		await process_overflow()


func _on_block_countdown_complete(block: Block, overflow_value: int) -> void:
	active_blocks.erase(block) # Remove block from active processing
	# Determine where overflow should go
	if overflow_value > 0:
		var blocks_with_adjacent_slots = block_manager.get_blocks_with_cardinal_adjacent_slots(block)
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


func process_overflow() -> void:
	if overflow_queue.is_empty():
		return # no more rounds needed
	
	# Move overflow queue to new round
	var new_round = overflow_queue.duplicate()
	overflow_queue.clear()
	
	# Start new round
	await process_die_drop(new_round)
