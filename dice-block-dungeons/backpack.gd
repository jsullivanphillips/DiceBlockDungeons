extends Node2D

class_name Backpack

@onready var tilemap := $Backpack

const OCCUPIED_ATLAS_CORD = Vector2i(2, 7)
const EMPTY_ATLAS_COORD = Vector2i(3,7)


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


func set_tiles_to_occupied(block_cells : Array[Vector2]) -> void:
	for cell in block_cells:
		var local_cell_position = tilemap.to_local(cell)
		var tile_coord = tilemap.local_to_map(local_cell_position)
		tilemap.set_cell(tile_coord, 1, OCCUPIED_ATLAS_CORD)


func set_tiles_unoccupied(block_cells : Array[Vector2]) -> void:
	for cell in block_cells:
		var local_cell_position = tilemap.to_local(cell)
		var tile_coord = tilemap.local_to_map(local_cell_position)
		var tile_id = tilemap.get_cell_source_id(tile_coord)
		if tile_id == 1:
			var atlas_coords = tilemap.get_cell_atlas_coords(tile_coord)
			if atlas_coords == OCCUPIED_ATLAS_CORD:	
				tilemap.set_cell(tile_coord, 1, EMPTY_ATLAS_COORD)


func is_tile_unoccupied(tile_coord : Vector2i) -> bool:
	var tile_id = tilemap.get_cell_source_id(tile_coord)  # Get tile ID at tilemap coordinate (x, y)
	if tile_id == 1:
		var atlas_coords = tilemap.get_cell_atlas_coords(tile_coord)
		if atlas_coords == EMPTY_ATLAS_COORD:
			return true # Tile is empty
		return false # Tile contains something
	else:
		return false  # Tile contains something
