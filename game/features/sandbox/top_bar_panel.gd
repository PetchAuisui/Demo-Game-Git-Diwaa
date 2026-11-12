class_name TopBarPanel
extends PanelContainer
## Reusable Top Bar Component for Git-Diwaa Sandbox UI.
## Displays the game title, mode badge, and the exit button.

signal finish_pressed
signal brand_pressed

@export var game_title: String = "GIT DI WAA"
@export var mode_text: String = "SANDBOX"

var _brand_btn: BrandButton
var _mode_label: Label
var _divider: ColorRect
var _btn_finish: Button


func _ready() -> void:
	_brand_btn = get_node_or_null("%BrandBtn") as BrandButton
	_mode_label = get_node_or_null("%ModeLabel")
	_divider = get_node_or_null("%Divider")
	_btn_finish = get_node_or_null("%BtnFinish")

	set_mode_text(mode_text)

	if _brand_btn != null:
		_brand_btn.brand_title = game_title
		_brand_btn.pressed.connect(func(): brand_pressed.emit())

	if _btn_finish != null:
		_btn_finish.pressed.connect(func(): finish_pressed.emit())


func set_mode_text(new_mode_text: String) -> void:
	mode_text = new_mode_text
	var has_text := not new_mode_text.is_empty()
	if _mode_label != null:
		_mode_label.text = new_mode_text
		_mode_label.visible = has_text
	if _divider != null:
		_divider.visible = has_text


func set_finish_button_text(new_text: String) -> void:
	if _btn_finish != null:
		_btn_finish.text = new_text


func set_finish_button_visible(is_vis: bool) -> void:
	if _btn_finish != null:
		_btn_finish.visible = is_vis
