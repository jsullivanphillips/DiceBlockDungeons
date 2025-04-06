extends Control

@onready var coins_label := $Coins
@onready var enemy_health := $EnemyHP
@onready var player_health := $PlayerHP
@onready var player_block := $PlayerBlock
@onready var enemy_damage := $EnemyNextMove


func update_coins_label(coins : int) -> void:
	if coins_label:
		coins_label.text = "Coins: " + str(coins)
	else:
		call_deferred("update_coins_label", coins)


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
	else:
		call_deferred("_on_battle_manager_player_shield_changed", new_value)


func _on_battle_manager_enemy_damage_changed(new_value: int) -> void:
	if enemy_damage:
		enemy_damage.text = "ENEMY DMG: " + str(new_value)
	else:
		call_deferred("_on_battle_manager_enemy_damage_changed", new_value)
