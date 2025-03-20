extends Node2D

@onready var camera := $Camera2D
@onready var block_manager := $BlockManager

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		block_manager.handle_mouse_click(camera.get_global_mouse_position())
