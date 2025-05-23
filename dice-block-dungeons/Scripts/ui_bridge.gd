extends Node

class_name UIBridge

var game_flow_manager : GameFlowManager
var block_manager : BlockManager
var backpack : Backpack
var store_manager : StoreManager
var store_ui : StoreUI

signal slot_purchased(slot: StoreSlot)

var text_color := Color.WHITE

@onready var interface := $"../Interface"

func show_game_won():
	interface.show_you_win()

func show_game_over():
	interface.set_restart_game_visibility(true)

func set_enemy_max_health(max_health: int) -> void:
	interface.set_enemy_max_health(max_health)

func hide_restart_button():
	interface.set_restart_game_visibility(false)

func _on_start_battle_pressed() -> void:
	game_flow_manager.request_start_game()


func _on_get_more_blocks_btn_pressed() -> void:
	block_manager._on_get_more_blocks_pressed()


func _on_show_add_tiles_pressed() -> void:
	backpack._on_show_add_tiles_pressed()


func _on_player_state_health_changed(old_value: int, new_value: int) -> void:
	interface._on_player_health_changed(old_value, new_value)
	


func _on_enemy_manager_enemy_health_changed(old_health: int, new_health: int) -> void:
	interface._on_enemy_health_changed(old_health, new_health)


func _on_store_ui_purchase_requested(item_resource: BlockResource, store_slot: StoreSlot) -> void:
	store_manager.purchase_requested(item_resource, store_slot)


func _on_store_manager_slot_purchased(slot: StoreSlot) -> void:
	slot_purchased.emit(slot)


func _on_store_ui_reroll_requested() -> void:
	store_manager.reroll_store()

func _on_store_ui_buy_die_requested() -> void:
	store_manager.buy_die_requested()


func _on_store_ui_exit_requested() -> void:
	store_ui.hide()
	
func exit_store() -> void:
	store_ui.hide()

func open_store() -> void:
	store_ui.show()
	store_manager.generate_store()

func show_shop_interface() -> void:
	#open_store()
	set_start_battle_visibility(true)
	set_end_turn_visibility(false)
	set_add_tiles_visibility(true)
	interface.set_enemy_stat_visibility(false)

func hide_shop_interface() -> void:
	exit_store()
	set_start_battle_visibility(false)
	set_add_tiles_visibility(false)
	set_end_turn_visibility(true)
	interface.set_enemy_stat_visibility(true)


func set_start_battle_visibility(set_visible: bool)-> void:
	interface.set_start_battle_visibility(set_visible)


func set_end_turn_visibility(set_visible: bool)-> void:
	interface.set_end_turn_visibility(set_visible)


func set_add_tiles_visibility(set_visible: bool)-> void:
	interface.set_add_tiles_visibility(set_visible)


func _on_player_state_number_of_dice_changed(number_of_dice: int) -> void:
	interface.update_number_of_dice(number_of_dice)


func _on_enemy_manager_enemy_name_changed(enemy_name: String) -> void:
	interface.set_enemy_name(enemy_name)


func _on_restart_game_button_pressed() -> void:
	game_flow_manager.request_restart_game()


func _on_end_turn_pressed() -> void:
	game_flow_manager._on_end_turn_pressed()


func _on_player_state_max_health_changed(new_value: int) -> void:
	interface._on_player_max_health_changed(new_value)


func flash_enemy_red():
	interface.flash_enemy_red()


func set_enemy_image(tex: Texture2D) -> void:
	interface.set_enemy_image(tex)


func start_enemy_idle_animation():
	interface.start_enemy_idle_animation()

func play_enemy_attack_animation():
	interface.play_enemy_attack_animation()
	

func stop_enemy_idle_animation():
	interface.stop_enemy_idle_animation()


func _on_enemy_manager_enemy_damage_changed(value: int) -> void:
	interface._on_enemy_damage_changed(value)


func _on_player_state_coins_changed(old_value: int, new_value: int) -> void:
	interface._on_coin_value_changed(old_value, new_value)


func _on_player_state_shield_changed(_old_value: int, new_value: int) -> void:
	interface._on_player_shield_changed(new_value)
