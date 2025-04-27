extends Control

@onready var start_button := $VBoxContainer/StartButton
@onready var version_label := $VersionLabel

@export var tutorial_pages : Array[Label]
var tutorial_page_index := 0

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	
	# Set version text dynamically
	version_label.text = "Version: " + get_build_version()

func _on_start_pressed():
	# Load your actual gameplay scene here
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")

func get_build_version() -> String:
	var version = "0.0.1"  # Your project version manually set here
	if OS.has_feature("HTML5"):
		version += " (HTML5)"
	elif OS.has_feature("Windows"):
		version += " (Windows)"
	elif OS.has_feature("MacOS"):
		version += " (MacOS)"
	elif OS.has_feature("Linux"):
		version += " (Linux)"
	else:
		version += " (Unknown Platform)"
	return version


func _on_next_button_pressed() -> void:
	if tutorial_page_index < tutorial_pages.size() - 1:
		tutorial_pages[tutorial_page_index].hide()
		tutorial_page_index += 1
		tutorial_pages[tutorial_page_index].show()
