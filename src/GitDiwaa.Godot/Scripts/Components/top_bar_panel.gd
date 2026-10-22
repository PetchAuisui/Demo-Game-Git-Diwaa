class_name TopBarPanel
extends PanelContainer
## Reusable Top Bar Component for Git-Diwaa Sandbox UI.
## Displays the game title and SANDBOX badge.

@export var game_title: String = "GIT DIWAA"
@export var mode_text: String = "SANDBOX"

var _brand_label: Label
var _mode_label: Label


func _ready() -> void:
	_brand_label = get_node("%BrandLabel")
	_mode_label = get_node("%ModeLabel")
	_brand_label.text = game_title
	_mode_label.text = mode_text


func set_mode_text(new_mode_text: String) -> void:
	mode_text = new_mode_text
	if _mode_label != null:
		_mode_label.text = new_mode_text
