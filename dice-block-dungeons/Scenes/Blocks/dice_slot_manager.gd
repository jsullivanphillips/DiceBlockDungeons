extends Node
class_name DiceSlotManager

@onready var tilemap: TileMapLayer = $"../Z-Block-TileMapLayer"
var dice_slots_default_value := 0
var dice_slots_value := 0

# Update dice slots based on the die value placed
func update_slots(die_value : int) -> int:
	var start_value = dice_slots_value
	var end_value = max(0, start_value - die_value)
	var overflow_value = die_value - (start_value - end_value)
	
	# Update slot visuals (can be optimized if needed)
	_update_slot_visuals(start_value, end_value)

	# Update the value
	if end_value == 0:
		# Reset to default if empty
		_reset_slots()
	else:
		dice_slots_value = end_value
		
	return overflow_value

# Helper function to update the slot visuals
func _update_slot_visuals(start_value: int, end_value: int) -> void:
	# Logic for updating the visual representation of dice slots
	var duration = 0.6
	for current_value in range(start_value - 1, end_value-1, -1):  # Step downwards
		if current_value > 0:
			_update_dice_slots_visuals(current_value)
			await get_tree().create_timer(duration).timeout

# Update dice slots visuals
func _update_dice_slots_visuals(current_value : int):
	var die_slots = _get_die_slot_coordinates()
	for cell in die_slots:
		tilemap.set_cell(cell, 1, Vector2i(current_value, 0))

# Reset dice slots to default
func _reset_slots() -> void:
	var die_slots = _get_die_slot_coordinates()
	for cell in die_slots:
		tilemap.set_cell(cell, 1, Vector2i(dice_slots_default_value, 0))
	dice_slots_value = dice_slots_default_value

# Retrieve coordinates of dice slots
func _get_die_slot_coordinates() -> Array[Vector2i]:
	var die_slot_coordinates : Array[Vector2i] = []
	var used_cells = tilemap.get_used_cells()
	for cell in used_cells:
		if tilemap.get_cell_atlas_coords(cell).x > 0:
			die_slot_coordinates.append(cell)
	return die_slot_coordinates
