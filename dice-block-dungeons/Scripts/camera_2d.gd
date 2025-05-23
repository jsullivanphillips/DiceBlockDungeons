extends Camera2D

class_name CameraShake

var shake_strength = 0
var shake_decay = 0
var random = RandomNumberGenerator.new()

var tween : Tween

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


func slide_to_battle_position():
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position", Vector2(0, 0), 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_interval(0.1) # short delay
	
	tween.tween_property(self, "zoom", Vector2(0.8, 0.8), 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func slide_to_shop_position():
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position", Vector2(0, 0), 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_interval(0.1) # short delay
	
	tween.tween_property(self, "zoom", Vector2(0.9, 0.9), 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
