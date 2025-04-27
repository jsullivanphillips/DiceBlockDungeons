extends Node

class_name EnemyManager

var player_state : PlayerState
var ui_bridge : UIBridge

@export var enemy_default_health := 10
@export var enemy_damage := 3
var enemy_health := 10

@export var enemies: Array[EnemyData]
var current_enemy_index : int

signal enemy_health_changed(old_health : int, new_health : int)
signal enemy_max_health_set(max_health: int)
signal enemy_damage_changed(value : int)
signal enemy_name_changed(enemy_name: String)
signal enemy_died()
signal game_won()

var is_enemy_dead : bool

func set_first_enemy():
	current_enemy_index = -1
	next_enemy()


func get_coins_dropped() -> int:
	return enemies[current_enemy_index].coins_dropped


func next_enemy():
	current_enemy_index += 1
	if current_enemy_index < enemies.size():
		is_enemy_dead = false
		var enemy = enemies[current_enemy_index]
		enemy_health = enemy.max_health
		enemy_max_health_set.emit(enemy_health)
		enemy_damage = enemy.damage
		enemy_damage_changed.emit(enemy_damage)
		enemy_health_changed.emit(0, enemy_health)
		enemy_name_changed.emit(enemy.name)
		if enemy.image:
			ui_bridge.set_enemy_image(enemy.image)
			ui_bridge.start_enemy_idle_animation()
	else:
		game_won.emit()


func run_enemy_turn():
	if enemy_health <= 0:
		return  # skip turn if dead

	ui_bridge.play_enemy_attack_animation()
	await get_tree().create_timer(1.0).timeout
	player_state.apply_damage(enemy_damage)
	SFXManager.play_sfx("hit")
	await get_tree().create_timer(0.5).timeout
	enemy_damage = max(1, enemies[current_enemy_index].damage + randi_range(-1, 1))
	enemy_damage_changed.emit(enemy_damage)


func deal_damage(damage: int):
	var old_health = enemy_health
	enemy_health = max(enemy_health - damage, 0)
	enemy_health_changed.emit(old_health, enemy_health)
	ui_bridge.flash_enemy_red()
	if enemy_health <= 0:
		is_enemy_dead = true
		enemy_died.emit()
		ui_bridge.stop_enemy_idle_animation()
