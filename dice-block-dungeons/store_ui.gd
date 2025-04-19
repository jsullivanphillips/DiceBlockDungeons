extends Control

class_name StoreUI

var player_state : PlayerState

signal purchase_requested(item_resource: BlockResource, store_slot: StoreSlot)
signal reroll_requested()
signal exit_requested()
signal buy_die_requested()

@onready var item_slot_container := $VBoxContainer/ItemSlotHBox
@onready var reroll_button := $VBoxContainer/RerollButton
@onready var exit_button := $VBoxContainer/HBoxContainer2/ExitButton
@onready var buy_die_button := $VBoxContainer/BuyDieButton
@onready var store_slot_scene := preload("res://Scenes/store_slot.tscn")

func _ready():
	reroll_button.pressed.connect(_on_reroll_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	buy_die_button.pressed.connect(_on_buy_die_pressed)


func open_store(block_options: Array[BlockResource]):
	clear_store()
	
	for resource in block_options:
		var slot = store_slot_scene.instantiate()
		item_slot_container.add_child(slot)
		slot.call_deferred("setup", resource)
		slot.purchase_requested.connect(_on_purchase_requested)
		


func clear_store():
	if not is_instance_valid(item_slot_container):
		push_warning("⚠️ item_slot_container is not valid.")
		return

	for child in item_slot_container.get_children():
		if child is StoreSlot:
			child.queue_free()


func _on_reroll_pressed():
	reroll_requested.emit()

func _on_exit_pressed():
	exit_requested.emit()

func _on_buy_die_pressed():
	buy_die_requested.emit()

func _on_purchase_requested(resource: BlockResource, store_slot: StoreSlot):
	purchase_requested.emit(resource, store_slot)


func _on_ui_bridge_slot_purchased(slot: StoreSlot) -> void:
	if is_instance_valid(slot):
		slot.queue_free()
