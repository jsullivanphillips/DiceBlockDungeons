extends Node

class_name StoreManager

var store_ui: Control
var player_state: PlayerState
var block_manager: BlockManager

signal store_opened(shop_inventory: Array[BlockResource])
signal slot_purchased(slot: StoreSlot)

var block_pool: Array[BlockResource] = []
var shop_inventory: Array[BlockResource] = []

@export var shop_size := 3 # Number of blocks per shop
@export var include_dice := false

func _ready():
	_load_block_pool()
	call_deferred("generate_store")

func _load_block_pool():
	var dir = DirAccess.open("res://Blocks/GeneratedBlocks")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var path = "res://Blocks/GeneratedBlocks/" + file_name
				var res = load(path)
				if res is BlockResource:
					block_pool.append(res)
			file_name = dir.get_next()

func generate_store():
	shop_inventory.clear()

	# Categorize blocks by primary effect
	var attack_blocks: Array[BlockResource] = []
	var shield_blocks: Array[BlockResource] = []
	var bonus_dice_blocks: Array[BlockResource] = []
	var mixed_blocks: Array[BlockResource] = []

	for block in block_pool:
		var is_attack = block.attack > 0
		var is_shield = block.shield > 0
		var is_bonus_dice = block.bonus_dice > 0

		var type_count = int(is_attack) + int(is_shield) + int(is_bonus_dice)

		if type_count > 1:
			mixed_blocks.append(block)
		elif is_attack:
			attack_blocks.append(block)
		elif is_shield:
			shield_blocks.append(block)
		elif is_bonus_dice:
			bonus_dice_blocks.append(block)

	# Ensure all 3 types are available
	if attack_blocks.is_empty() or shield_blocks.is_empty() or bonus_dice_blocks.is_empty():
		push_error("⚠️ Not enough block variety in block_pool to guarantee 1 of each type (attack, shield, bonus_dice).")
		return

	# Pick one of each required type
	var guaranteed_attack = attack_blocks.pick_random()
	var guaranteed_shield = shield_blocks.pick_random()
	var guaranteed_bonus = bonus_dice_blocks.pick_random()

	# Build remaining inventory
	var remaining_blocks = block_pool.duplicate()
	remaining_blocks.erase(guaranteed_attack)
	remaining_blocks.erase(guaranteed_shield)
	remaining_blocks.erase(guaranteed_bonus)
	remaining_blocks.shuffle()

	var remaining_needed = shop_size - 3
	var rest_of_inventory = remaining_blocks.slice(0, remaining_needed)

	# Combine final inventory
	shop_inventory = ([guaranteed_attack, guaranteed_shield, guaranteed_bonus])as Array[BlockResource] + rest_of_inventory
	shop_inventory.shuffle()  # Optional: to randomize order in UI

	store_opened.emit(shop_inventory)


func purchase_requested(item: BlockResource, slot: StoreSlot):
	var item_cost = item.price
	if player_state.coins >= item_cost:
		block_manager.spawn_block_from_resource(item)
		player_state.spend_coins(item_cost)
		slot_purchased.emit(slot)

func buy_die_requested():
	if player_state.coins >= 6:
		player_state.spend_coins(6)
		var die := DieData.new()
		die.min_value = 1
		die.max_value = 6
		player_state.add_die(die)

func reroll_store():
	if player_state.coins >= 1: # or whatever cost you want
		player_state.spend_coins(1)
		generate_store()
	else:
		push_warning("Not enough coins to reroll store")
