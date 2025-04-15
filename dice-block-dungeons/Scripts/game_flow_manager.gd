extends Node

class_name GameFlowManager

var dice_manager : DiceManager
var block_manager : BlockManager
var player_state : PlayerState
var backpack : Backpack
var combat_processor : CombatProcessor
var enemy_manager : EnemyManager


enum GameState {
	IDLE,
	PLAYER_TURN_START,
	PLAYER_INPUT,
	PROCESSING_COMBAT,
	ENEMY_TURN,
	GAME_OVER
}

# For debugging
const GameStateNames = {
	GameState.IDLE: "IDLE",
	GameState.PLAYER_TURN_START: "PLAYER_TURN_START",
	GameState.PLAYER_INPUT: "PLAYER_INPUT",
	GameState.PROCESSING_COMBAT: "PROCESSING_COMBAT",
	GameState.ENEMY_TURN: "ENEMY_TURN",
	GameState.GAME_OVER: "GAME_OVER"
}


var current_state: GameState = GameState.IDLE


func _ready() -> void:
	call_deferred("_post_ready")


func _post_ready() -> void:
	player_state.coins = 5
	enemy_manager.set_first_enemy()


func player_turn_over():
	if current_state == GameState.IDLE:
		return
	change_state(GameState.ENEMY_TURN)


func request_start_game():
	if current_state == GameState.IDLE:
		change_state(GameState.PLAYER_TURN_START)
	else:
		push_warning("Start Game requested but game already started or not in IDLE state.")


func start_combat_processing(processing_round: Array[Array]):
	change_state(GameState.PROCESSING_COMBAT)
	await combat_processor.process_die_drop(processing_round)
	# ^ this should not return until all processing animations are complete, including overflow

	_on_combat_processing_complete()


func _on_combat_processing_complete() -> void:
	match current_state:
		GameState.PROCESSING_COMBAT:
			if enemy_manager.is_enemy_dead:
				# This assumes the enemy died *during* processing
				change_state(GameState.IDLE)
				dice_manager.clear_all_dice()
				block_manager.reset_all_dice_slots_to_default()
				player_state.add_coins(enemy_manager.get_coins_dropped())
				enemy_manager.next_enemy()
			elif dice_manager.has_remaining_dice():
				change_state(GameState.PLAYER_INPUT)
			else:
				change_state(GameState.ENEMY_TURN)

func is_combat_processing() -> bool:
	return current_state == GameState.PROCESSING_COMBAT


func wait_for_processing() -> void:
	while is_combat_processing():
		await get_tree().process_frame


func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return

	## debug
	print("\n🔄 Requested state change: %s → %s" % [
		GameStateNames.get(current_state, str(current_state)),
		GameStateNames.get(new_state, str(new_state))
	])
	print_stack()

	current_state = new_state
	print("✅ Game state changed to:", GameStateNames.get(current_state, str(current_state)))

	match current_state:
		GameState.PLAYER_TURN_START:
			await dice_manager.spawn_player_dice()
			change_state(GameState.PLAYER_INPUT)

		GameState.PLAYER_INPUT:
			pass  # Wait for input (player drops a die)

		GameState.PROCESSING_COMBAT:
			pass  # Handled by start_combat_processing()

		GameState.ENEMY_TURN:
			await enemy_manager.run_enemy_turn()
			await get_tree().create_timer(1).timeout
			change_state(GameState.PLAYER_TURN_START)

		GameState.GAME_OVER:
			pass


func start_player_turn() -> void:
	await dice_manager.spawn_player_dice()
	change_state(GameState.PLAYER_INPUT)


func _on_battle_won(coins_won : int):
	dice_manager.clear_all_dice()
	await get_tree().create_timer(0.5).timeout
	player_state.add_coins(coins_won)


func _on_game_over():
	restart_game()


func restart_game():
	# Destroy all objects in Blocks group
	block_manager.clear_all_blocks()

	# Destroy all objects in Dice group
	dice_manager.clear_all_dice()
	
	player_state.coins = 5
	player_state.shield = 0

	# Reset the backpack
	backpack.reset_backpack()


func try_end_player_turn():
	if get_tree().get_nodes_in_group("Dice").is_empty():
		player_turn_over()


func _on_end_turn_pressed() -> void:
	pass
