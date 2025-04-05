extends Node
class_name BlockVisualEffects

@onready var tilemap: TileMapLayer = $"../Z-Block-TileMapLayer"

# Change the block's color to a darker shade with a "pop" effect
func change_color_to_darker() -> void:
	var old_color = tilemap.modulate
	var modified_color = old_color
	modified_color.s = 0.8
	modified_color.v = 0.6

	var tween = get_tree().create_tween()

	# Step 1: Flash to Darker Color with a Pop Effect
	tween.tween_property(tilemap, "modulate", modified_color, 0.3)
	tween.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

	# Add a scale up for a "pop" effect
	tween.parallel().tween_property(self, "scale", Vector2(1.1, 1.1), 0.3) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)

	await tween.finished

	# Step 2: Bounce Back to Normal Color + Scale
	var tween_back = get_tree().create_tween()

	# Returning to original color smoothly
	tween_back.tween_property(tilemap, "modulate", old_color, 0.5) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_IN_OUT)

	# Adding bounce back for extra fun when scaling down
	tween_back.parallel().tween_property(self, "scale", Vector2(1, 1), 0.4) \
		.set_trans(Tween.TRANS_BOUNCE) \
		.set_ease(Tween.EASE_OUT)

	await tween_back.finished


func play_activate_animation() -> void:
	var old_color = tilemap.modulate
	var modified_color = old_color
	modified_color.s = 0.2
	modified_color.v = 0.95

	var tween = get_tree().create_tween()

	# Step 1: Bright Flash + Scale Up (Pop Effect)
	tween.tween_property(tilemap, "modulate", modified_color, 0.2) \
		.set_trans(Tween.TRANS_CIRC) \
		.set_ease(Tween.EASE_OUT)
	
	tween.parallel().tween_property(self, "scale", Vector2(1.15, 1.15), 0.2) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)

	await tween.finished

	# Step 2: Subtle Return to Normal Color + Scale
	var tween_back = get_tree().create_tween()
	tween_back.tween_property(tilemap, "modulate", old_color, 0.4) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)
	
	tween_back.parallel().tween_property(self, "scale", Vector2(1, 1), 0.3) \
		.set_trans(Tween.TRANS_BOUNCE) \
		.set_ease(Tween.EASE_OUT)

	await tween_back.finished

	get_parent().reset_to_default_values()
