extends Node2D

@onready var input_manager = $World/InputManager
@onready var dice_manager = $World/DiceManager
@onready var block_manager = $World/BlockManager
@onready var combat_processor = $CombatProcessor
@onready var game_flow_manager = $GameFlowManager
@onready var player_state = $PlayerState
@onready var backpack = $World/BlockManager/Backpack
@onready var enemy_manager = $EnemyManager
@onready var ui_bridge = $UI/UIBridge
@onready var camera = $World/Camera2D
@onready var store_ui = $UI/StoreUI
@onready var store_manager = $StoreManager

const ShapeLib = preload("res://Blocks/BlockShapeLibrary.gd")

func _ready():
	ShapeLib.load_shapes()

	dice_manager.input_manager = input_manager
	block_manager.input_manager = input_manager
	
	dice_manager.combat_processor = combat_processor
	block_manager.combat_processor = combat_processor
	game_flow_manager.combat_processor = combat_processor
	
	combat_processor.dice_manager = dice_manager
	game_flow_manager.dice_manager = dice_manager
	input_manager.dice_manager = dice_manager
	
	combat_processor.block_manager = block_manager
	game_flow_manager.block_manager = block_manager
	input_manager.block_manager = block_manager
	ui_bridge.block_manager = block_manager
	store_manager.block_manager = block_manager
	player_state.block_manager = block_manager
	
	block_manager.player_state = player_state
	game_flow_manager.player_state = player_state
	backpack.player_state = player_state
	dice_manager.player_state = player_state
	combat_processor.player_state = player_state
	enemy_manager.player_state = player_state
	store_manager.player_state = player_state
	
	block_manager.backpack = backpack
	game_flow_manager.backpack = backpack
	ui_bridge.backpack = backpack
	player_state.backpack = backpack
	
	combat_processor.enemy_manager = enemy_manager
	game_flow_manager.enemy_manager = enemy_manager
	
	combat_processor.game_flow_manager = game_flow_manager
	dice_manager.game_flow_manager = game_flow_manager
	input_manager.game_flow_manager = game_flow_manager
	ui_bridge.game_flow_manager = game_flow_manager
	
	input_manager.camera = camera
	combat_processor.camera= camera
	player_state.camera = camera
	game_flow_manager.camera = camera
	block_manager.camera = camera
	
	input_manager.ui_bridge = ui_bridge
	game_flow_manager.ui_bridge = ui_bridge
	enemy_manager.ui_bridge = ui_bridge
	
	store_manager.store_ui = store_ui
	ui_bridge.store_ui = store_ui
	
	ui_bridge.store_manager = store_manager
	
	
