extends Node2D

@onready var block_scene : PackedScene = preload("res://Scenes/block.tscn")

@onready var backpack : Backpack = $Backpack

func _on_spawn_block_button_pressed() -> void:
	var block = block_scene.instantiate()
	add_child(block)
