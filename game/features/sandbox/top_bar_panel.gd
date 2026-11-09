class_name TopBarPanel
extends PanelContainer
## Reusable Top Bar Component for Git-Diwaa Sandbox UI.
## Displays the game title, mode/level badge, and mission complete button.

signal finish_pressed
signal brand_pressed

@export var game_title: String = "GIT DI WAA"
@export var mode_text: String = "SANDBOX"

var _brand_btn: Button
var _brand_label: Label
var _brand_hat: TextureRect
var _mode_label: Label
var _divider: ColorRect
var _btn_finish: Button


func _ready() -> void:
	_brand_btn = get_node_or_null("%BrandBtn")
	_brand_label = get_node_or_null("%BrandLabel")
	_brand_hat = get_node_or_null("%BrandHat")
	_mode_label = get_node_or_null("%ModeLabel")
	_divider = get_node_or_null("%Divider")
	_btn_finish = get_node_or_null("%BtnFinish")

	if _brand_label != null:
		_brand_label.text = game_title
	if _brand_hat != null:
		_brand_hat.texture = GameProgressManager.get_current_hat_texture()
		_brand_hat.position.y = -4.0
		_brand_hat.rotation_degrees = 0.0
	set_mode_text(mode_text)

	if _brand_btn != null:
		_brand_btn.mouse_entered.connect(_on_brand_hover.bind(true))
		_brand_btn.mouse_exited.connect(_on_brand_hover.bind(false))

	if _btn_finish != null:
		_btn_finish.pressed.connect(func(): finish_pressed.emit())


func _on_brand_hover(is_hover: bool) -> void:
	if _brand_hat != null:
		var tw := create_tween()
		if is_hover:
			tw.tween_property(_brand_hat, "position:y", -7.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(_brand_hat, "rotation_degrees", -6.0, 0.10)
			tw.tween_property(_brand_hat, "position:y", -4.0, 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(_brand_hat, "rotation_degrees", 0.0, 0.12)
		else:
			tw.tween_property(_brand_hat, "position:y", -4.0, 0.10)
			tw.parallel().tween_property(_brand_hat, "rotation_degrees", 0.0, 0.10)


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
