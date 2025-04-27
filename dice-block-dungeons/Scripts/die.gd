extends Node2D
class_name Die

@onready var sprite2d := $Sprite2D
var min_sprite_frame = 1
var max_sprite_frame = 6

var value = 1
var is_locked : = false

signal die_picked_up(block)
signal die_dropped(block)

var dragging: bool = false
@onready var camera: Camera2D = get_viewport().get_camera_2d()

func set_random_value() -> void:
	value = randi_range(1,6)
	sprite2d.set_frame(value)

func set_value(p_value : int) -> void:
	if p_value <= 6 and p_value > 0:
		value = p_value
		sprite2d.set_frame(value)


func pick_up(mouse_position: Vector2):
	die_picked_up.emit(self)
	dragging = true
	global_position = mouse_position


func drop_object():
	die_dropped.emit(self)
	dragging = false


func _input(event: InputEvent):
	if dragging:
		if event is InputEventMouseMotion:
			global_position = camera.get_global_mouse_position()


func is_being_dragged() -> bool:
	return dragging
