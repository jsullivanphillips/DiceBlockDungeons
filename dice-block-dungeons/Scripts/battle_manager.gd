extends Node2D

# ====================================================================
# ⚔️ BATTLE MANAGER
# Handles setup, turn transitions, enemy progression, and combat logic
# ====================================================================

# === 📊 CONFIGURATION ===
@export var player_default_health := 15
@export var number_of_player_dice := 3
@export var enemy_default_health := 10
@export var enemy_damage := 3

var player_health := 15
var player_current_shield := 0
var enemy_health := 10
var current_enemy_index := -1
var is_enemy_dead := false

@export var enemies: Array = [
	{"HP": 10, "DMG": 3},
	{"HP": 13, "DMG": 3},
	{"HP": 18, "DMG": 4},
	{"HP": 22, "DMG": 5},
	{"HP": 35, "DMG": 5}
]

# === 🎮 STATE TRACKING ===
enum BATTLE_STATE { NEUTRAL, PLAYER_TURN, ENEMY_TURN }
var battle_state := BATTLE_STATE.NEUTRAL
var is_animations_playing := false

# === 📢 SIGNALS ===
signal on_player_turn_start(number_of_dice: int)
signal on_player_turn_over()

signal player_health_changed(new_health: int)
signal player_shield_changed(new_value: int)
signal enemy_health_changed(new_health: int)
signal enemy_damage_changed(new_value: int)
signal enemy_took_damage(damage: int)
signal enemy_dealt_damage()

signal battle_won(coins_won: int)
signal game_over()

# ====================================================================
# 🛠️ GAME SETUP & ENEMY MANAGEMENT
# ====================================================================

## 🔁 Resets game and loads first enemy
func _on_setup_game():
	clear_shield()
	player_health = player_default_health
	player_health_changed.emit(player_health)
	current_enemy_index = -1
	next_enemy()

## ➕ Loads the next enemy's stats
func next_enemy():
	current_enemy_index += 1
	if current_enemy_index < enemies.size():
		var enemy_data = enemies[current_enemy_index]
		enemy_default_health = enemy_data["HP"]
		enemy_damage = enemy_data["DMG"]
		enemy_health = enemy_default_health

		enemy_health_changed.emit(enemy_health)
		enemy_damage_changed.emit(enemy_damage)
		is_enemy_dead = false

# ====================================================================
# 🔄 TURN FLOW MANAGEMENT
# ====================================================================

## ▶️ Starts the battle (player turn)
func _on_start_battle_pressed():
	battle_state = BATTLE_STATE.PLAYER_TURN
	change_state()

## ⏭ Ends player turn, starts enemy turn
func _on_player_turn_over():
	if battle_state == BATTLE_STATE.PLAYER_TURN:
		battle_state = BATTLE_STATE.ENEMY_TURN
		on_player_turn_over.emit()
		change_state()

## ⏭ Ends enemy turn, starts player turn
func _on_enemy_turn_over():
	battle_state = BATTLE_STATE.PLAYER_TURN
	change_state()

## ❌ Called when player health reaches 0
func _on_game_over():
	game_over.emit()
	_on_setup_game()
	battle_state = BATTLE_STATE.NEUTRAL
	change_state()

## ✅ Called when enemy health reaches 0
func _on_enemy_died():
	if is_enemy_dead:
		return
	
	is_enemy_dead = true
	battle_won.emit(4)
	battle_state = BATTLE_STATE.NEUTRAL
	## DONT GO TO NEXT ENEMY UNTIL ALL DICE ANIMATIONS HAVE FINISHED
	await wait_for_animations()
	
	next_enemy()
	change_state()

func wait_for_animations():
	while is_animations_playing:
		await get_tree().process_frame  # Waits one frame before rechecking


# ====================================================================
# ⚔️ COMBAT LOGIC
# ====================================================================

## 🛡️ Handles damage and shield from activated blocks
func _block_activated(block: Block):
	if block.damage_value > 0:
		_on_enemy_take_damage(block.damage_value)

	if block.block_value > 0:
		player_current_shield += block.block_value
		player_shield_changed.emit(player_current_shield)

## 💥 Damages enemy and checks for death
func _on_enemy_take_damage(damage: int):
	enemy_health -= damage
	enemy_health_changed.emit(enemy_health)
	enemy_took_damage.emit(damage)
	if enemy_health <= 0:
		_on_enemy_died()

## 🧼 Clears player's shield points
func clear_shield():
	player_current_shield = 0
	player_shield_changed.emit(player_current_shield)

# ====================================================================
# 🔁 BATTLE STATE HANDLER
# Manages transitions and logic during each state
# ====================================================================

func change_state():
	match battle_state:
		BATTLE_STATE.NEUTRAL:
			clear_shield()
			print("State: NEUTRAL – Waiting...")

		BATTLE_STATE.PLAYER_TURN:
			print("State: PLAYER_TURN – Player's move")
			clear_shield()
			on_player_turn_start.emit(number_of_player_dice)

		BATTLE_STATE.ENEMY_TURN:
			if enemy_health == 0:
				battle_state = BATTLE_STATE.NEUTRAL
				return
			print("State: ENEMY_TURN – Enemy attacks")
			enemy_dealt_damage.emit()
			var damage_blocked = min(player_current_shield, enemy_damage)
			var final_damage = enemy_damage - damage_blocked

			player_current_shield -= damage_blocked
			player_shield_changed.emit(player_current_shield)

			player_health -= final_damage
			player_health_changed.emit(player_health)

			if player_health <= 0:
				_on_game_over()
			else:
				await get_tree().create_timer(1.0).timeout
				_on_enemy_turn_over()


func _on_end_turn_pressed() -> void:
	if battle_state == BATTLE_STATE.PLAYER_TURN:
		_on_player_turn_over()
		
		
func _on_block_manager_animations_playing_value_changed(p_is_animations_playing: bool) -> void:
	is_animations_playing = p_is_animations_playing
