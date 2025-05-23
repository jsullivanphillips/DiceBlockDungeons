extends Node

class_name PlayerState

var camera : CameraShake
var block_manager : BlockManager

func restart_game():
	setup_game()

func setup_game():
	set_starting_coins(1)
	setup_initial_dice()
	shield = 0
	health = max_health
	max_health_changed.emit(max_health)
#
# Health and Shield
#
signal health_changed(old_value: int, new_value: int)
signal max_health_changed(new_value: int)
signal shield_changed(old_value: int, new_value: int)
signal game_over()

var max_health := 15:
	set(value):
		max_health = value
		max_health_changed.emit(value)
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
		camera.shake()
		if health <= 0:
			game_over.emit()

func heal(amount: int):
	health += amount

func add_shield(amount: int):
	shield += amount


#
# Players Dice
#
signal dice_collection_changed
signal number_of_dice_changed(number_of_dice: int)

# Player's dice pool
var dice_inventory: Array[DieData] = []


func setup_initial_dice():
	dice_inventory.clear()
	for i in range(2):
		var die := DieData.new()
		die.min_value = 1
		die.max_value = 6
		add_die(die)


func add_die(die_data: DieData) -> void:
	dice_inventory.append(die_data)
	dice_collection_changed.emit()
	number_of_dice_changed.emit(dice_inventory.size())


func remove_die(die_data: DieData) -> void:
	dice_inventory.erase(die_data)
	dice_collection_changed.emit()
	number_of_dice_changed.emit(dice_inventory.size())


func get_random_die() -> DieData:
	if dice_inventory.is_empty():
		push_error("Tried to get a die from empty inventory.")
		return null
	return dice_inventory.pick_random()


#
# Block Deck System (Deckbuilder Prototype)
#
var block_deck: Array[BlockResource] = []
var block_draw_pile: Array[BlockResource] = []
var block_discard_pile: Array[BlockResource] = []
var current_hand: Array[BlockResource] = []

func initialize_block_deck(starting_blocks: Array[BlockResource]) -> void:
	block_deck = starting_blocks.duplicate()
	block_draw_pile = block_deck.duplicate()
	block_draw_pile.shuffle()
	block_discard_pile.clear()
	current_hand.clear()


func draw_blocks(num: int) -> void:
	for i in range(num):
		if block_draw_pile.is_empty():
			reshuffle_discard_into_draw()
		if not block_draw_pile.is_empty():
			var block = block_draw_pile.pop_back()
			current_hand.append(block)
	print("drew ", num, " blocks: ", current_hand)


func add_block_to_hand(block: BlockResource) -> void:
	current_hand.append(block)


func reshuffle_discard_into_draw() -> void:
	block_draw_pile = block_discard_pile.duplicate()
	block_draw_pile.shuffle()
	block_discard_pile.clear()


func discard_block(block: BlockResource) -> void:
	if current_hand.has(block):
		current_hand.erase(block)
		block_discard_pile.append(block)


func reset_block_deck() -> void:
	block_draw_pile.clear()
	block_discard_pile.clear()
	current_hand.clear()


func discard_unused_hand_blocks() -> void:
	for block in current_hand:
		var instance := block_manager.find_block_instance_with_resource(block)
		if instance and is_instance_valid(instance):
			instance.queue_free()
		block_discard_pile.append(block)
	current_hand.clear()


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

func set_starting_coins(p_coins : int) -> void:
	print_stack()
	coins = p_coins


func add_coins(amount: int) -> void:
	for i in range(amount):
		print_stack()
		coins += 1
		SFXManager.play_sfx("coin")  # Plays your coin sound
		coins_changed.emit(coins - 1, coins)  # Optional: notify UI
		await get_tree().create_timer(0.33).timeout


func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		return true
	return false
