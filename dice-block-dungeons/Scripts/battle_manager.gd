extends Node2D

func _block_activated(block : Block) -> void:
	print(block.block_type, " activated!")
