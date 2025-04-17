extends Camera2D

class_name CameraShake

var shake_strength = 0
var shake_decay = 0
var random = RandomNumberGenerator.new()

func _ready():
	random.randomize()

func _process(delta):
	if shake_strength > 0:
		offset = Vector2(
			random.randf_range(-shake_strength, shake_strength),
			random.randf_range(-shake_strength, shake_strength)
		)
		shake_strength = lerpf(shake_strength, 0, shake_decay * delta)
	else:
		offset = Vector2.ZERO

func shake(strength = 10, decay = 5):
	shake_strength = strength
	shake_decay = decay

func _on_battle_manager_enemy_took_damage(_damage) -> void:
	shake()
