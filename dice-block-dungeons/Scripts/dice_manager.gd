extends Node2D

class_name DiceManager

var input_manager : InputManager
var combat_processor : CombatProcessor
var player_state : PlayerState
var game_flow_manager : GameFlowManager

@onready var die_scene : PackedScene = preload("res://Scenes/die.tscn")
@onready var die_spawn_point := $"../SpawnMarkers/DieSpawnPoint"

var has_sent_player_turn_over := false

func spawn_die(die_value : int) -> void:
	SFXManager.play_sfx("dice_spawn")
	var die = die_scene.instantiate()
	add_child(die)
	die.set_value(die_value)
	die.die_dropped.connect(_on_die_dropped)
	die.global_position = die_spawn_point.global_position + Vector2(randf_range(-100, 100), randf_range(-105, 100))


func spawn_player_dice() -> void:
	for die_data in player_state.dice_inventory:
		var value = die_data.roll()
		spawn_die(value)
		await get_tree().create_timer(0.75).timeout


func bring_die_to_front(die: Die) -> void:
	if die.get_parent() == self and is_instance_valid(die):
		move_child(die, -1)
	else:
		push_warning("Cannot bring die to front — not a child of DiceManager or not valid.")



func _on_die_dropped(die : Die) -> void:
	var die_position = die.global_position
	
	var block_at_position = input_manager.get_topmost_block_at(die_position)
	var is_block_at_position = block_at_position is Block
	var is_die_slot_at_position := false
	
	if is_block_at_position:
		is_die_slot_at_position = block_at_position.is_position_a_die_slot(die_position)
	
	if is_die_slot_at_position and block_at_position.is_slotted and not game_flow_manager.is_combat_processing():
		drop_die_in_slot(die, block_at_position)
	else:
		SFXManager.play_sfx("click")


func die_dropped_at_position(die_position : Vector2, value : int) -> void:
	var block_at_position = input_manager.get_topmost_block_at(die_position)
	var is_block_at_position = block_at_position is Block
	var is_die_slot_at_position := false
	
	if is_block_at_position:
		is_die_slot_at_position = block_at_position.is_position_a_die_slot(die_position)
	
	if is_die_slot_at_position and block_at_position.is_slotted:
		await block_at_position.die_placed_in_slot(value)
	
	return


func drop_die_in_slot(die: Die, block: Block):
	var die_value = die.value
	die.queue_free()
	var processing_round : Array[Array]
	processing_round = [[block, die_value]]
	game_flow_manager.start_combat_processing(processing_round)


func display_slotted_die(die_value: int, die_slots : Array[Vector2]) -> void:
	var tweens = []
	var duration = 1
	var created_dice = []  # List to track the dice created in this function

	for die_slot in die_slots:
		var die = die_scene.instantiate()
		die.scale = Vector2(0.7, 0.7)
		add_child(die)
		die.global_position = die_slot + Vector2(0, -100)
		die.set_value(die_value)
		
		var target_position = die_slot + Vector2(0, -120)
		var tween = get_tree().create_tween()
		tween.tween_property(die, "global_position", target_position, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
		
		tweens.append(tween)
		created_dice.append(die)  # Track the created dice

	# Wait for all tweens to finish before destroying the dice
	for tween in tweens:
		await tween.finished
	
	# Destroy only the dice created by this function
	for die in created_dice:
		if die != null and is_instance_valid(die):
			die.queue_free()


func clear_all_dice():
	for die in get_tree().get_nodes_in_group("Dice"):
		die.queue_free()


func has_remaining_dice() -> bool:
	return get_tree().get_nodes_in_group("Dice").size() > 0


func _on_spawn_die_button_pressed() -> void:	
	pass
	# connect this function to UI_BRIDGE
	#var input_text = diceTextEdit.text.strip_edges()  # Remove leading/trailing spaces
	#var die_value : int
	#if input_text.is_valid_int():
		#die_value = input_text.to_int()
		#
		## Additional check if there's a valid range for die_value
		#if die_value < 1 or die_value > 6:  
			#die_value = randi_range(2,6) # Fallback default value if input is invalid
	#else:
		#die_value = randi_range(2,6) 
#
	#spawn_die(die_value)
