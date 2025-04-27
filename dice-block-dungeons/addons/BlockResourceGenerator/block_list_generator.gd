@tool
extends Node

const GENERATED_BLOCKS_DIR := "res://Blocks/GeneratedBlocks"
const BLOCK_LIST_JSON_PATH := "res://Blocks/GeneratedBlocks/BlockList.json"

static func generate_block_list_json():
	var dir = DirAccess.open(GENERATED_BLOCKS_DIR)
	if not dir:
		push_error("❌ Could not open GeneratedBlocks folder")
		return

	var block_paths := []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			block_paths.append(GENERATED_BLOCKS_DIR + "/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	var json_text = JSON.stringify(block_paths, "\t")  # Pretty print
	var file = FileAccess.open(BLOCK_LIST_JSON_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_text)
		file.flush()
		file.close()
		print("✅ BlockList.json generated with %d blocks" % block_paths.size())
	else:
		push_error("❌ Failed to save BlockList.json")
