@tool
extends VBoxContainer

const OUTPUT_PATH := "res://Blocks/ShapeLibrary.json"
const GRID_SIZE := 5

@onready var shape_name = $ShapeName
@onready var offset_x = $HBoxContainer/OffsetX
@onready var offset_y = $HBoxContainer/OffsetY
@onready var tile_grid = $TileGrid
@onready var save_button = $SaveButton

var tile_data := {}

func _ready():
	const GRID_HALF = GRID_SIZE / 2

	for y in range(-GRID_HALF, GRID_HALF + 1):
		for x in range(-GRID_HALF, GRID_HALF + 1):
			var btn = Button.new()
			btn.text = ""
			btn.toggle_mode = true
			btn.custom_minimum_size = Vector2(128, 128)
			btn.set_meta("pos", Vector2i(x, y))
			btn.connect("toggled", func(_pressed): _on_tile_toggled(_pressed, btn))
			tile_grid.add_child(btn)

	save_button.connect("pressed", _on_save_pressed)


func _on_tile_toggled(_pressed: bool, button: Button):
	var pos = button.get_meta("pos")

	# Cycle state: none → 0 → 1 → none...
	if pos not in tile_data:
		tile_data[pos] = 0
	elif tile_data[pos] == 0:
		tile_data[pos] = 1
	else:
		tile_data.erase(pos)

	# Update visual
	_update_tile_visual(button, tile_data.get(pos, null))


func _update_tile_visual(button: Button, tile_type):
	match tile_type:
		0:
			button.text = "🧱"  # Regular tile
		1:
			button.text = "🎲"  # Dice slot
		null:
			button.text = ""   # Empty


func _on_save_pressed():
	if shape_name.text.strip_edges() == "":
		push_error("Please enter a shape name.")
		return

	var shape = {
		"tiles": [],
		"offset": Vector2(offset_x.value, offset_y.value)
	}

	for pos in tile_data.keys():
		shape["tiles"].append({
			"pos": pos,
			"tile": tile_data[pos]
		})

	var shapes = {}
	var file = FileAccess.open(OUTPUT_PATH, FileAccess.READ)
	if file:
		var existing_json = file.get_as_text()
		if existing_json != "":
			shapes = JSON.parse_string(existing_json)
		file.close()

	shapes[shape_name.text.strip_edges()] = shape

	file = FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(shapes, "\t"))
	file.close()

	print("✅ Shape saved to JSON:", shape_name.text)
