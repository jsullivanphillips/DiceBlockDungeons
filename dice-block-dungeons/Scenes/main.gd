extends Node2D

@onready var camera := $Camera2D
@onready var block_manager := $BlockManager
@onready var ui := $UI
@export var coins = 4

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		block_manager.handle_mouse_click(camera.get_global_mouse_position())


func _on_block_manager_new_slot_purchaed(coins: int) -> void:
	ui.update_coins_label(coins)
