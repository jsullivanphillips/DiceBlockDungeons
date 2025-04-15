extends Node

class_name EnemyManager

var player_state : PlayerState

@export var enemy_default_health := 10
@export var enemy_damage := 3
var enemy_health := 10

@export var enemies: Array[EnemyData]
var current_enemy_index : int

signal enemy_health_changed(old_health : int, new_health : int)
signal enemy_damage_changed(value : int)
signal enemy_died()

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
		enemy_damage = enemy.damage
		enemy_damage_changed.emit(enemy_damage)
		enemy_health_changed.emit(0, enemy_health)


func run_enemy_turn():
	if enemy_health <= 0:
		return  # skip turn if dead

	await get_tree().create_timer(1.0).timeout
	player_state.apply_damage(enemy_damage)
	SFXManager.play_sfx("hit")


func deal_damage(damage: int):
	var old_health = enemy_health
	enemy_health = max(enemy_health - damage, 0)
	enemy_health_changed.emit(old_health, enemy_health)

	if enemy_health <= 0:
		is_enemy_dead = true
		enemy_died.emit()
