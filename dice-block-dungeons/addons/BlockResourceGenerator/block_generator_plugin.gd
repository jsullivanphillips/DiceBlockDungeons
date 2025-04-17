@tool
extends EditorPlugin

var generator_panel
var file_watcher_connected := false
const BlockShapeLibrary = preload("res://Blocks/BlockShapeLibrary.gd")
var _last_shape_json_timestamp := 0

func _enter_tree():
	generator_panel = preload("res://addons/BlockResourceGenerator/block_resource_generator.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, generator_panel)
	print("✅ Block Generator Plugin loaded")

	if not file_watcher_connected:
		get_editor_interface().get_resource_filesystem().filesystem_changed.connect(_on_filesystem_changed)
		file_watcher_connected = true

func _exit_tree():
	remove_control_from_docks(generator_panel)
	generator_panel.queue_free()
	print("👋 Block Generator Plugin unloaded")


func _on_filesystem_changed():
	var json_path := "res://Blocks/ShapeLibrary.json"
	if FileAccess.file_exists(json_path):
		var modified_time = FileAccess.get_modified_time(json_path)
		
		# Only reload if timestamp has changed
		if modified_time != _last_shape_json_timestamp:
			_last_shape_json_timestamp = modified_time
			print("🔁 Reloading ShapeLibrary.json from plugin...")
			BlockShapeLibrary.load_shapes()
			
			# Refresh dropdown if plugin is open
			if generator_panel and generator_panel.has_method("refresh_shape_dropdown"):
				generator_panel.refresh_shape_dropdown()
