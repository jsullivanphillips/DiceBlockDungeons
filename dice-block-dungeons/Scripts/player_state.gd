extends Node

class_name PlayerState


func _ready():
	setup_initial_dice()

#
# Health and Shield
#
signal health_changed(old_value: int, new_value: int)
signal shield_changed(old_value: int, new_value: int)

var max_health := 15
var health := 15:
	set(value):
		value = clamp(value, 0, max_health)
		if value != health:
			var old = health
			health = value
			health_changed.emit(old, health)

var shield := 0:
	set(value):
		value = max(0, value)
		if value != shield:
			var old = shield
			shield = value
			shield_changed.emit(old, shield)

func apply_damage(amount: int):
	if shield > 0:
		var absorbed = min(shield, amount)
		shield -= absorbed
		amount -= absorbed
	if amount > 0:
		health -= amount

func heal(amount: int):
	health += amount

func add_shield(amount: int):
	shield += amount


#
# Players Dice
#
signal dice_collection_changed

# Player's dice pool
var dice_inventory: Array[DieData] = []


func setup_initial_dice():
	for i in range(3):
		var die := DieData.new()
		die.min_value = 1
		die.max_value = 6
		add_die(die)


func add_die(die_data: DieData) -> void:
	dice_inventory.append(die_data)
	dice_collection_changed.emit()


func remove_die(die_data: DieData) -> void:
	dice_inventory.erase(die_data)
	dice_collection_changed.emit()


func get_random_die() -> DieData:
	if dice_inventory.is_empty():
		push_error("Tried to get a die from empty inventory.")
		return null
	return dice_inventory.pick_random()

#
# Coins
#
signal coins_changed(old_value: int, new_value: int)

var coins: int = 5:
	set(value):
		if coins != value:
			var old = coins
			coins = value
			coins_changed.emit(old, coins)

func add_coins(amount: int) -> void:
	for i in range(amount):
		coins += 1
		SFXManager.play_sfx("coin")  # Plays your coin sound
		coins_changed.emit(coins - 1, coins)  # Optional: notify UI
		await get_tree().create_timer(0.33).timeout


func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		return true
	return false
