class_name TopBarPanel
extends PanelContainer
## Reusable Top Bar Component for Git-Diwaa Sandbox UI.
## Displays the game title, mode/level badge, and mission complete button.

signal finish_pressed

@export var game_title: String = "GIT DIWAA"
@export var mode_text: String = "SANDBOX"

var _brand_label: Label
var _mode_label: Label
var _btn_finish: Button


func _ready() -> void:
	_brand_label = get_node("%BrandLabel")
	_mode_label = get_node("%ModeLabel")
	_btn_finish = get_node_or_null("%BtnFinish")
	_brand_label.text = game_title
	_mode_label.text = mode_text
	if _btn_finish:
		_btn_finish.pressed.connect(func(): finish_pressed.emit())


func set_mode_text(new_mode_text: String) -> void:
	mode_text = new_mode_text
	if _mode_label != null:
		_mode_label.text = new_mode_text


func set_finish_button_text(new_text: String) -> void:
	if _btn_finish != null:
		_btn_finish.text = new_text


func set_finish_button_visible(is_vis: bool) -> void:
	if _btn_finish != null:
		_btn_finish.visible = is_vis
