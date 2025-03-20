extends Node2D
class_name Backpack

@onready var tilemap := $Backpack

var are_new_tiles_shown : bool

const OCCUPIED_ATLAS_CORD = Vector2i(2, 7)
const EMPTY_ATLAS_COORD = Vector2i(3, 7)
const ADD_NEW_BLOCK_COORD = Vector2i(2, 8)

func get_nearest_tile_global_position(global_pos: Vector2) -> Vector2:
	var tile_coord = tilemap.local_to_map(tilemap.to_local(global_pos))
	return tilemap.to_global(tilemap.map_to_local(tile_coord))


func is_position_add_new_block(global_pos : Vector2) -> bool:
	var tile_coord = tilemap.local_to_map(tilemap.to_local(global_pos))
	var tile_source_id = tilemap.get_cell_source_id(tile_coord)
	if tile_source_id == 1:
		var tile_type = tilemap.get_cell_atlas_coords(tile_coord)
		return tile_type == ADD_NEW_BLOCK_COORD
	return false


func add_new_block(global_pos : Vector2) -> void:
	var tile_coord = tilemap.local_to_map(tilemap.to_local(global_pos))
	tilemap.set_cell(tile_coord, 1, EMPTY_ATLAS_COORD)
	hide_add_tiles()
	show_add_tiles()


func is_out_of_pack_bounds(block_origin: Vector2) -> bool:
	var tile_coord = tilemap.local_to_map(tilemap.to_local(block_origin))
	return tilemap.get_cell_source_id(tile_coord) == -1


func are_spaces_empty(block_cells: Array[Vector2]) -> bool:
	for cell in block_cells:
		var tile_coord = tilemap.local_to_map(tilemap.to_local(cell))
		if !is_tile_unoccupied(tile_coord):
			return false
	return true


func set_tiles_to_occupied(block_cells: Array[Vector2]) -> void:
	for cell in block_cells:
		var tile_coord = tilemap.local_to_map(tilemap.to_local(cell))
		tilemap.set_cell(tile_coord, 1, OCCUPIED_ATLAS_CORD)


func set_tiles_unoccupied(block_cells: Array[Vector2]) -> void:
	for cell in block_cells:
		var tile_coord = tilemap.local_to_map(tilemap.to_local(cell))
		tilemap.set_cell(tile_coord, 1, EMPTY_ATLAS_COORD)


func is_tile_unoccupied(tile_coord: Vector2i) -> bool:
	return tilemap.get_cell_source_id(tile_coord) == 1 and tilemap.get_cell_atlas_coords(tile_coord) == EMPTY_ATLAS_COORD


## Block Additions
func set_tile_add_new_block(tile_coord: Vector2i) -> void:
	tilemap.set_cell(tile_coord, 1, ADD_NEW_BLOCK_COORD)


func clear_tile(tile_coord: Vector2i) -> void:
	tilemap.set_cell(tile_coord)


func hide_add_tiles() -> void:
	var used_tiles = tilemap.get_used_cells()
	
	for tile in used_tiles:
		if tilemap.get_cell_atlas_coords(tile) == ADD_NEW_BLOCK_COORD:
			clear_tile(tile)
	
	are_new_tiles_shown = false


func show_add_tiles() -> void:
	var directions = [
		Vector2i(1, 0),  Vector2i(1, 1),  Vector2i(0, 1),  Vector2i(-1, 1),
		Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)
	]

	# Get all currently occupied tiles
	var used_tiles = tilemap.get_used_cells()  # Assuming layer 0, change if needed
	var perimeter_tiles = {}

	# Find all empty perimeter tiles
	for tile in used_tiles:
		for direction in directions:
			var new_tile_coord = tile + direction
			if tilemap.get_cell_source_id(new_tile_coord) == -1:  # Check if the tile is empty
				perimeter_tiles[new_tile_coord] = true  # Store unique perimeter tiles

	# Set new tiles on the perimeter
	for tile_coord in perimeter_tiles.keys():
		set_tile_add_new_block(tile_coord)
	
	are_new_tiles_shown = true
	
