# DieData.gd
extends Resource
class_name DieData

@export var min_value: int = 1
@export var max_value: int = 6

func roll() -> int:
	return randi_range(min_value, max_value)
