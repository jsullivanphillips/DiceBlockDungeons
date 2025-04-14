extends Node2D

@onready var label = $Label
@onready var animation_player = $AnimationPlayer

func _ready():
	animation_player.play("float")

# Sets the displayed damage text
func set_damage(amount):
	label.text = str(amount)

# Cleans up after animation completes
func _on_animation_player_animation_finished(_anim_name):
	queue_free()
