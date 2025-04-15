extends Node2D

@onready var click_sfx := $Click
@onready var dice_spawn_sfx := $DiceSpawn
@onready var pickup_block_sfx := $PickupBlock
@onready var drop_block_sfx := $DropBlock
@onready var hit_sfx := $Hit
@onready var shield_sfx := $Shield
@onready var coin_sfx := $Coin

var sfx_dict : Dictionary = {}

func _ready() -> void:
	sfx_dict = {
		"click" : click_sfx,
		"dice_spawn" : dice_spawn_sfx,
		"pickup_block" : pickup_block_sfx,
		"drop_block" : drop_block_sfx,
		"hit" : hit_sfx,
		"shield" : shield_sfx,
		"coin" : coin_sfx
	}


func play_sfx(sfx_name: String) -> void:
	if not sfx_dict.has(sfx_name):
		push_warning("SFX key not found: " + sfx_name)
		return
	
	var sfx = sfx_dict[sfx_name]
	if not is_instance_valid(sfx):
		push_warning("SFX instance invalid for key: " + sfx_name)
		return
	
	if sfx_name == "coin":
		pass
	else:
		sfx.pitch_scale = 1.0 + randf_range(-0.15, 0.15)
	sfx.play()
