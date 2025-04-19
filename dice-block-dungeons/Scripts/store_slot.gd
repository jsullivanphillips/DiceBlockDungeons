extends Control

class_name StoreSlot

signal purchase_requested(resource: BlockResource)

@onready var name_label := $NameLabel
@onready var buy_button := $BuyButton
@onready var block_preview_viewport := $BlockPreview/PreviewViewport

var resource: BlockResource

func _ready():
	buy_button.pressed.connect(_on_buy_pressed)

func setup(item: BlockResource):
	resource = item
	name_label.text = _format_block_stats(item)
	buy_button.text = "Buy (" + str(item.price) + "g)"

	# Clear previous preview
	for child in block_preview_viewport.get_children():
		child.queue_free()

	if not block_preview_viewport.world_2d:
		block_preview_viewport.world_2d = World2D.new()
	
	# Spawn a locked preview block
	if item.scene:
		var block = item.scene.instantiate()
		block_preview_viewport.add_child(block)
		block.set_process(false)
		block.set_physics_process(false)
		block.set_meta("is_shop_preview", true)
		block.call_deferred("setup_from_resource", item)
		block.scale = Vector2(0.3, 0.3)  # Shrink for UI
		block.position = block_preview_viewport.size / 2.0
		# Optional: prevent interactions
		if block.has_method("lock"):
			block.lock()


func _format_block_stats(item: BlockResource) -> String:
	var parts = []
	if item.attack > 0:
		parts.append("Deals " + str(item.attack) + " damage")
	if item.shield > 0:
		parts.append("Gives " + str(item.shield) + " shield")
	if item.bonus_dice > 0:
		parts.append("Gives " + str(item.bonus_dice) + " bonus die 🎲")
	parts.append("Dice Cost to Activate: " + str(item.dice_cost))
	return "  •  ".join(parts)



		
		
func _on_buy_pressed():
	purchase_requested.emit(resource, self)
