extends Node2D

class_name InputManager

var camera : CameraShake
var block_manager : BlockManager
var dice_manager : DiceManager
var ui_bridge : UIBridge
var game_flow_manager : GameFlowManager

var selected_object = null

signal non_block_or_die_clicked(mouse_pos : Vector2)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		handle_mouse_click(camera.get_global_mouse_position())

func handle_mouse_click(mouse_pos: Vector2):
	var topmost_object = get_topmost_object_at(mouse_pos)

	if topmost_object != null:
		# Drop currently selected object
		if selected_object != null:
			if not game_flow_manager.is_combat_processing() or (game_flow_manager.is_combat_processing() and selected_object is Die):
				selected_object.drop_object()
				selected_object = null

		# Pick up new object
		elif not topmost_object.is_locked and (not game_flow_manager.is_combat_processing() or topmost_object is Die):
			SFXManager.play_sfx("pickup_block")
			selected_object = topmost_object
			topmost_object.pick_up(mouse_pos)

			# Bring to front
			if topmost_object is Block:
				block_manager.bring_block_to_front(topmost_object)
			elif topmost_object is Die:
				dice_manager.bring_die_to_front(topmost_object)  # Add this method
	else:
		SFXManager.play_sfx("click")
		non_block_or_die_clicked.emit(mouse_pos)



func get_topmost_block_at(mouse_pos: Vector2) -> Block:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var results = space_state.intersect_point(query)
	if results.is_empty():
		return null

	results.sort_custom(func(a, b): 
		return (a.collider.z_index > b.collider.z_index) or (a.collider.z_index == b.collider.z_index and a.collider.get_index() > b.collider.get_index()))

	var object = results[0].collider.get_parent()

	return object if object and object.is_in_group("Blocks") else null


func get_topmost_object_at(mouse_pos: Vector2) -> Node2D:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var results = space_state.intersect_point(query)
	if results.is_empty():
		return null

	results.sort_custom(func(a, b): 
		return (
		(a.collider.is_in_group("Dice") and not b.collider.is_in_group("Dice")) or 
		(a.collider.is_in_group("Dice") == b.collider.is_in_group("Dice") and a.collider.z_index > b.collider.z_index) or 
		(a.collider.is_in_group("Dice") == b.collider.is_in_group("Dice") and a.collider.z_index == b.collider.z_index and a.collider.get_index() < b.collider.get_index())
	))

	var topmost_object = results[0].collider.get_parent()
	
	return topmost_object if topmost_object and (topmost_object.is_in_group("Blocks") or topmost_object.is_in_group("Dice")) else null
