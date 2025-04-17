@tool
extends EditorPlugin

var panel : Control

func _enter_tree():
	var scene = preload("res://addons/shape_editor/shape_editor.tscn")
	panel = scene.instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, panel)
	panel.name = "Shape Editor"

func _exit_tree():
	if panel:
		remove_control_from_docks(panel)
		panel.queue_free()
