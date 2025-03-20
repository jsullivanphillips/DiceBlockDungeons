extends CanvasLayer

@onready var coins_label := $Control/Coins

func update_coins_label(coins : int) -> void:
	coins_label.text = "Coins: " + str(coins)
