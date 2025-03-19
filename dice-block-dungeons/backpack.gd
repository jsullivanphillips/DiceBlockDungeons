extends Node2D

class_name Backpack


@onready var tilemap := $Backpack
## Block moving design
#  Look into colliders for tilemaps.


func get_nearest_tile_global_position(p_global_position : Vector2) -> Vector2:
	var local_cell_position = tilemap.to_local(p_global_position)
	var tile_coord = tilemap.local_to_map(local_cell_position)
	var local_snap_position = tilemap.map_to_local(tile_coord)
	var global_snap_position = tilemap.to_global(local_snap_position)
	return global_snap_position


func is_out_of_pack_bounds(block_origin : Vector2) -> bool:
	var block_local_position = tilemap.to_local(block_origin)
	var tile_coord = tilemap.local_to_map(block_local_position)
	var tile_id = tilemap.get_cell_source_id(tile_coord)  # Get tile ID at tilemap coordinate (x, y)
	print("tile id at ", tile_coord, " is : ", tile_id)
	if tile_id == -1:
		return true  # Tile is empty
	else:
		return false  # Tile contains a tile


func are_spaces_empty(block_cells : Array[Vector2]) -> bool:
	for cell in block_cells:
		var local_cell_position = tilemap.to_local(cell)
		var tile_coord = tilemap.local_to_map(local_cell_position)
		if !is_tile_unoccupied(tile_coord):
			return false
	return true


func is_tile_unoccupied(tile_coord : Vector2i) -> bool:
	var tile_id = tilemap.get_cell_source_id(tile_coord)  # Get tile ID at tilemap coordinate (x, y)
	if tile_id == 1:
		return true  # Tile is empty
	else:
		return false  # Tile contains a tile


func _on_block_placed(block_cells : Array[Vector2]) -> void :
	pass
