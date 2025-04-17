extends Node
class_name BlockShapeLibrary

const SHAPE_JSON_PATH := "res://Blocks/ShapeLibrary.json"

static var shapes := {}

# 🟢 Load immediately, not just in _ready
static func _init():
	load_shapes()

static func load_shapes():
	var file = FileAccess.open(SHAPE_JSON_PATH, FileAccess.READ)
	if file:
		var raw_json = file.get_as_text()
		var parsed = JSON.parse_string(raw_json)
		if typeof(parsed) == TYPE_DICTIONARY:
			shapes = _convert_shape_data(parsed)
		else:
			push_error("❌ Failed to parse shape JSON.")
	else:
		push_error("❌ Failed to open ShapeLibrary.json")

static func _convert_shape_data(raw: Dictionary) -> Dictionary:
	var result = {}

	for f_name in raw.keys():
		var data = raw[f_name]
		var tiles = []
		for t in data.get("tiles", []):
			tiles.append({
				"pos": _parse_vector2i(t["pos"]),
				"tile": int(t["tile"])
			})
		result[f_name] = {
			"offset": _parse_vector2(data.get("offset", "(0, 0)")),
			"tiles": tiles
		}
	return result

static func _parse_vector2(s: String) -> Vector2:
	var cleaned = s.trim_prefix("(").trim_suffix(")")
	var nums = cleaned.split(",")
	return Vector2(nums[0].to_float(), nums[1].to_float())

static func _parse_vector2i(s: String) -> Vector2i:
	var v = _parse_vector2(s)
	return Vector2i(int(v.x), int(v.y))

# ================================================================
# 🔧 Helper Methods
# ================================================================

# ✅ Get all shape IDs (for dropdowns or selection UIs)
static func get_shape_ids() -> Array:
	return shapes.keys()

# ✅ Get a full shape entry by ID
static func get_shape_data(id: StringName) -> Dictionary:
	return shapes.get(id, {})

# ✅ Get just the tile positions
static func get_tiles(id: StringName) -> Array:
	return get_shape_data(id).get("tiles", [])

# ✅ Get just the offset
static func get_offset(id: StringName) -> Vector2:
	return get_shape_data(id).get("offset", Vector2.ZERO)

# ✅ Check if shape ID exists
static func has_shape(id: StringName) -> bool:
	return shapes.has(id)

# ✅ Reload manually (for plugins or editor watchers)
static func reload():
	print("🔁 Reloading ShapeLibrary.json from plugin...")
	load_shapes()
