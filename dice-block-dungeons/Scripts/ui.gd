extends Control

@onready var coins_label := $Coins
@onready var enemy_health := $EnemyHP
@onready var player_health := $PlayerHP
@onready var player_block := $PlayerBlock
@onready var enemy_damage := $EnemyNextMove
@onready var coin_sfx := $"../../SFX/Coin"

func _on_battle_manager_enemy_health_changed(new_health: int) -> void:
	if enemy_health:
		enemy_health.text = "ENEMY HP: " + str(new_health)
	else:
		call_deferred("_on_battle_manager_enemy_health_changed", new_health)


func _on_battle_manager_player_health_changed(new_health: int) -> void:
	if player_health:
		player_health.text = "PLAYER HP: " + str(new_health)
	else:
		call_deferred("_on_battle_manager_player_health_changed", new_health)


func _on_battle_manager_player_shield_changed(new_value: int) -> void:
	if player_block:
		player_block.text = "PLAYER SHIELD: " + str(new_value)
		if new_value != 0:
			flash_label(player_block, Color.BLUE, 0.5)
	else:
		call_deferred("_on_battle_manager_player_shield_changed", new_value)


func _on_battle_manager_enemy_damage_changed(new_value: int) -> void:
	if enemy_damage:
		enemy_damage.text = "ENEMY DMG: " + str(new_value)
	else:
		call_deferred("_on_battle_manager_enemy_damage_changed", new_value)

func flash_label(label: Label, flash_color: Color = Color.RED, duration := 0.3):
	var original_color = label.modulate
	label.modulate = flash_color
	await get_tree().create_timer(duration).timeout
	label.modulate = original_color


func _on_battle_manager_enemy_took_damage(_damage: int) -> void:
	flash_label(enemy_health)


func _on_block_manager_coin_value_changed(start_value: int, end_value: int) -> void:
	if coins_label:
		if start_value != end_value:
			var current_value = start_value
			var step = 1 if end_value > start_value else -1

			while current_value != end_value:
				current_value += step
				coins_label.text = "Coins: " + str(current_value)
				if end_value > start_value:
					coin_sfx.play()
				await get_tree().create_timer(0.33).timeout
		# Ensure final value is set (in case we overshot or skipped)
		coins_label.text = "Coins: " + str(end_value)
	else:
		call_deferred("_on_block_manager_coin_value_changed", start_value, end_value)
