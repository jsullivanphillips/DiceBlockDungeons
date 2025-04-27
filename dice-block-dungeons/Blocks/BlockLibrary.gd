extends Node
class_name BlockLibrary

const BLOCK_LIST_JSON_PATH := "res://Blocks/GeneratedBlocks/BlockList.json"

static var blocks : Array[BlockResource] = []

static func _init():
	load_blocks()

static func load_blocks():
	var file = FileAccess.open(BLOCK_LIST_JSON_PATH, FileAccess.READ)
	if file:
		var raw_json = file.get_as_text()
		var parsed = JSON.parse_string(raw_json)
		if typeof(parsed) == TYPE_ARRAY:
			print("✅ Parsed JSON. Number of entries:", parsed.size())
			for path in parsed:
				var block = load(path)
				if block:
					if block is BlockResource:
						blocks.append(block)
					else:
						push_error("❗ Resource loaded, but not a BlockResource: " + path)
				else:
					push_error("❗ Failed to load resource: " + path)
		else:
			push_error("❌ Failed to parse BlockList.json")
	else:
		push_error("❌ Failed to open BlockList.json!")


# ✅ Helper methods
static func get_blocks() -> Array[BlockResource]:
	return blocks

static func reload():
	print("🔁 Reloading BlockList.json...")
	blocks.clear()
	load_blocks()
