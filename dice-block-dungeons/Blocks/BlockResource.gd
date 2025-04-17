extends Resource
class_name BlockResource

const Rarity = preload("res://Blocks/Rarity.gd")  # Update path as needed

@export var display_name: String
@export var scene: PackedScene
@export var shape_id: String = "L"
@export var rarity: Rarity.Rarity = Rarity.Rarity.COMMON
@export var dice_cost: int = 1 
@export var attack: int = 0     # How much damage this block does
@export var shield: int = 0     # How much block/shield it gives
@export var description: String
@export var icon: Texture2D
@export var price: int = 3
