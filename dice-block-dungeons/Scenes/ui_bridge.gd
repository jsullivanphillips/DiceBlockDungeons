extends Node

class_name UIBridge

var game_flow_manager : GameFlowManager
var block_manager : BlockManager
var backpack : Backpack

var text_color := Color.WHITE

@onready var coins_label = $"../Interface/Coins"
@onready var player_health_label = $"../Interface/PlayerHP"
@onready var player_shield_label = $"../Interface/PlayerBlock"
@onready var enemy_health_label = $"../Interface/EnemyHP"
@onready var enemy_damage_label = $"../Interface/EnemyNextMove"

func _on_start_battle_pressed() -> void:
	game_flow_manager.request_start_game()


func flash_label(label: Label, flash_color: Color = Color.RED, duration := 0.3):
	var original_color = text_color
	label.modulate = flash_color
	await get_tree().create_timer(duration).timeout
	label.modulate = original_color


func _on_get_more_blocks_btn_pressed() -> void:
	block_manager._on_get_more_blocks_pressed()


func _on_show_add_tiles_pressed() -> void:
	backpack._on_show_add_tiles_pressed()


func _on_player_state_coins_changed(old_value: int, new_value: int) -> void:
	coins_label.text = "Gold: " + str(new_value)
	flash_label(coins_label, Color.GOLD, 0.3)


func _on_player_state_health_changed(old_value: int, new_value: int) -> void:
	player_health_label.text = "HP: " + str(new_value)
	flash_label(player_health_label, Color.RED, 0.3)


func _on_enemy_manager_enemy_health_changed(old_health: int, new_health: int) -> void:
	enemy_health_label.text = "HP: " + str(new_health)
	flash_label(enemy_health_label, Color.RED, 0.3)


func _on_player_state_shield_changed(old_value: int, new_value: int) -> void:
	player_shield_label.text = "Shield: " + str(new_value)
	flash_label(player_shield_label, Color.SKY_BLUE, 0.3)


func _on_enemy_manager_enemy_damage_changed(value: int) -> void:
	enemy_damage_label.text = "Dmg: " + str(value)
