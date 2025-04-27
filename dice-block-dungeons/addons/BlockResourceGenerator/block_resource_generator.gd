@tool
extends VBoxContainer

const Rarity = preload("res://Blocks/Rarity.gd")
const BlockResource = preload("res://Blocks/BlockResource.gd")

const BlockListGenerator = preload("res://addons/BlockResourceGenerator/block_list_generator.gd")

var SHAPE_IDS := []

@onready var shape_dropdown := $ShapeDropdown
@onready var attack_slider := $AttackHBox/AttackSlider
@onready var shield_slider := $ShieldHBox/ShieldSlider
@onready var bonus_dice_slider := $BonusDiceHBox/BonusDiceSlider
@onready var dice_slider := $DiceHBox/DiceSlider
@onready var price_slider := $PriceHBox/PriceSlider
@onready var status_label := $StatusLabel
@onready var preview_viewport := $SubViewportContainer/PreviewViewport
@onready var regenerate_button := $RegenerateButton

@onready var attack_value_label := $AttackHBox/AttackValueLabel
@onready var shield_value_label := $ShieldHBox/ShieldValueLabel
@onready var bonus_dice_value_label := $BonusDiceHBox/BonusDiceValueLabel
@onready var dice_value_label := $DiceHBox/DiceValueLabel
@onready var price_value_label := $PriceHBox/PriceValueLabel



func _ready():
	if not Engine.is_editor_hint():
		return
	

	# Connect regenerate button
	regenerate_button.pressed.connect(_on_regenerate_button_pressed)

	# Populate shape dropdown
	shape_dropdown.clear()
	for shape_id in BlockShapeLibrary.get_shape_ids():
		shape_dropdown.add_item(shape_id)

	# Setup sliders
	_setup_slider(attack_slider, 0, 8, 1, 1)
	_setup_slider(shield_slider, 0, 8, 1, 0)
	_setup_slider(bonus_dice_slider, 0, 3, 1, 1)
	_setup_slider(dice_slider, 1, 6, 1, 1)
	_setup_slider(price_slider, 1, 6, 1, 1)

	# Connect signals for live update
	shape_dropdown.item_selected.connect(_on_input_changed)
	attack_slider.value_changed.connect(_on_input_changed)
	shield_slider.value_changed.connect(_on_input_changed)
	dice_slider.value_changed.connect(_on_input_changed)
	price_slider.value_changed.connect(_on_input_changed)
	bonus_dice_slider.value_changed.connect(_on_input_changed)

	# Initial preview
	_on_input_changed()

func _setup_slider(slider: HSlider, min_v: float, max_v: float, step_v: float, default_v: float):
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.value = default_v


func _on_input_changed(_value = null):
	# Update value labels
	attack_value_label.text = str(int(attack_slider.value))
	shield_value_label.text = str(int(shield_slider.value))
	bonus_dice_value_label.text = str(int(bonus_dice_slider.value))
	dice_value_label.text = str(int(dice_slider.value))
	price_value_label.text = str(int(price_slider.value))
	
	var resource = _build_block_resource()
	preview_block(resource)
	status_label.text = "🌀 Live Preview: " + resource.display_name


func _on_regenerate_button_pressed():
	BlockListGenerator.generate_block_list_json()
	status_label.text = "🔁 BlockList regenerated manually!"


func _build_block_resource() -> BlockResource:
	var resource = BlockResource.new()

	var selected_id: int = shape_dropdown.selected
	if selected_id == -1:
		push_warning("⚠️ No shape selected in dropdown.")
		return resource  # return default resource safely

	resource.shape_id = shape_dropdown.get_item_text(selected_id)
	resource.scene = load("res://Blocks/block.tscn")
	resource.attack = int(attack_slider.value)
	resource.shield = int(shield_slider.value)
	resource.bonus_dice = int(bonus_dice_slider.value)
	resource.dice_cost = int(dice_slider.value)
	resource.rarity = _get_rarity(resource.attack, resource.shield)
	resource.display_name = "%s A%d B%d D%d DC%d" % [resource.shape_id, resource.attack, resource.shield, resource.bonus_dice, resource.dice_cost]
	resource.price = int(price_slider.value)
	return resource


func _on_save_pressed():
	var resource = _build_block_resource()
	var folder_path = "res://Blocks/GeneratedBlocks"
	var file_name = "%s_A%d_B%d_D%d.tres" % [resource.shape_id, resource.attack, resource.shield, resource.dice_cost]
	var full_path = folder_path + "/" + file_name

	# Ensure folder exists
	DirAccess.make_dir_absolute(folder_path)

	# Save the resource
	var error = ResourceSaver.save(resource, full_path)
	if error == OK:
		status_label.text = "💾 Saved to: " + full_path
		BlockListGenerator.generate_block_list_json()  # <<< ADD THIS LINE
	else:
		push_error("❌ Failed to save resource: %s" % error)




func _get_rarity(attack: int, shield: int) -> int:
	var total = attack + shield
	if total <= 1:
		return Rarity.Rarity.COMMON
	elif total == 2:
		return Rarity.Rarity.UNCOMMON
	elif total == 3:
		return Rarity.Rarity.RARE
	else:
		return Rarity.Rarity.EPIC
	

func refresh_shape_dropdown():
	SHAPE_IDS = BlockShapeLibrary.shapes.keys()
	shape_dropdown.clear()
	for shape_id in SHAPE_IDS:
		shape_dropdown.add_item(shape_id)

	_on_input_changed()  # Refresh preview



func preview_block(resource: BlockResource):
	# Remove existing block previews
	for child in preview_viewport.get_children():
		child.queue_free()

	# Ensure it has a World2D for rendering
	if not preview_viewport.world_2d:
		preview_viewport.world_2d = World2D.new()

	# Create and add the preview block
	var block_scene = preload("res://Blocks/block.tscn")
	var block = block_scene.instantiate()
	block.setup_from_resource(resource)
	preview_viewport.add_child(block)
	block.scale = Vector2(0.5, 0.5)
	block.position = Vector2(256,256) # Let the shape's offset handle it
