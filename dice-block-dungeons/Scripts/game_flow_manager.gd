extends Node

class_name GameFlowManager

var dice_manager : DiceManager
var block_manager : BlockManager
var player_state : PlayerState
var backpack : Backpack
var combat_processor : CombatProcessor
var enemy_manager : EnemyManager
var ui_bridge : UIBridge
var camera : CameraShake


enum GameState {
	IDLE,
	PLAYER_TURN_START,
	PLAYER_INPUT,
	PROCESSING_COMBAT,
	ENEMY_TURN,
	GAME_OVER,
	GAME_WON
}

# For debugging
const GameStateNames = {
	GameState.IDLE: "IDLE",
	GameState.PLAYER_TURN_START: "PLAYER_TURN_START",
	GameState.PLAYER_INPUT: "PLAYER_INPUT",
	GameState.PROCESSING_COMBAT: "PROCESSING_COMBAT",
	GameState.ENEMY_TURN: "ENEMY_TURN",
	GameState.GAME_OVER: "GAME_OVER",
	GameState.GAME_WON: "GAME_WON"
	
}

var current_state: GameState = GameState.IDLE

func _ready() -> void:
	call_deferred("_post_ready")


func _post_ready() -> void:
	enemy_manager.set_first_enemy()
	player_state.setup_game()
	ui_bridge.show_shop_interface()
	camera.slide_to_shop_position()


func player_turn_over():
	if current_state == GameState.IDLE:
		return
	player_state.discard_unused_hand_blocks()
	change_state(GameState.ENEMY_TURN)


func request_start_game():
	if current_state == GameState.IDLE:
		ui_bridge.hide_shop_interface()
		backpack.hide_add_tiles()
		camera.slide_to_battle_position()
		player_state.initialize_block_deck(block_manager.starting_blocks_array)
		change_state(GameState.PLAYER_TURN_START)
	else:
		push_warning("Start Game requested but game already started or not in IDLE state.")


func start_combat_processing(processing_round: Array[Array]):
	change_state(GameState.PROCESSING_COMBAT)
	await combat_processor.process_die_drop(processing_round)
	# ^ this should not return until all processing animations are complete, including overflow

	_on_combat_processing_complete()


func _on_combat_processing_complete() -> void:
	if enemy_manager.is_enemy_dead:
		change_state(GameState.IDLE)
		ui_bridge.show_shop_interface()
		camera.slide_to_shop_position()
		dice_manager.clear_all_dice()
		block_manager.reset_all_dice_slots_to_default()
		block_manager.clear_all_blocks()
		player_state.reset_block_deck()
		player_state.add_coins(enemy_manager.get_coins_dropped())
		player_state.shield = 0
		enemy_manager.next_enemy()
	else:
		if dice_manager.has_remaining_dice():
			change_state(GameState.PLAYER_INPUT)
		else:
			player_turn_over()


func is_combat_processing() -> bool:
	return current_state == GameState.PROCESSING_COMBAT


func wait_for_processing() -> void:
	while is_combat_processing():
		await get_tree().process_frame


func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	
	match current_state:
		GameState.PLAYER_TURN_START:
			await start_player_turn()
			change_state(GameState.PLAYER_INPUT)

		GameState.PLAYER_INPUT:
			ui_bridge.set_end_turn_visibility(true)
			pass  # Wait for input (player drops a die)

		GameState.PROCESSING_COMBAT:
			pass  # Handled by start_combat_processing()

		GameState.ENEMY_TURN:
			ui_bridge.set_end_turn_visibility(false)
			await enemy_manager.run_enemy_turn()
			await get_tree().create_timer(1).timeout
			if current_state != GameState.GAME_OVER and current_state != GameState.GAME_WON:
				player_state.shield = 0
				change_state(GameState.PLAYER_TURN_START)

		GameState.GAME_OVER:
			pass


func start_player_turn() -> void:
	await dice_manager.spawn_player_dice()
	player_state.draw_blocks(3)
	for block in player_state.current_hand:
		block_manager.spawn_block_from_resource(block, true)  # true = spawn into hand
	change_state(GameState.PLAYER_INPUT)


func _on_battle_won(coins_won : int):
	dice_manager.clear_all_dice()
	await get_tree().create_timer(0.5).timeout
	player_state.add_coins(coins_won)


func on_player_health_less_than_zero():
	change_state(GameState.GAME_OVER)
	_on_game_over()


func _on_game_over():
	ui_bridge.show_game_over()

func request_restart_game():
	if current_state == GameState.GAME_OVER or current_state == GameState.GAME_WON:
		restart_game()
		change_state(GameState.IDLE)
		ui_bridge.hide_restart_button()


func restart_game():
	# Destroy all objects in Blocks group
	block_manager.clear_all_blocks()

	# Destroy all objects in Dice group
	dice_manager.clear_all_dice()
	
	player_state.restart_game()

	# Reset the backpack
	backpack.reset_backpack()
	
	# Show the store
	ui_bridge.show_shop_interface()
	camera.slide_to_shop_position()


func try_end_player_turn():
	if get_tree().get_nodes_in_group("Dice").is_empty():
		player_turn_over()


func _on_end_turn_pressed() -> void:
	if current_state == GameState.PLAYER_INPUT:
		dice_manager.clear_all_dice()
		player_turn_over()


func _on_enemy_manager_game_won() -> void:
	change_state(GameState.GAME_WON)
	ui_bridge.show_game_won()
	
