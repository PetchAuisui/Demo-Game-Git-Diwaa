class_name BrandButton
extends Button
## Shared brand logo button ("GIT DI WAA") with witch hat hover animation.

const HAT_DEFAULT_Y: float = -4.0

@export var brand_title: String = "GIT DI WAA":
	set(value):
		brand_title = value
		if is_instance_valid(_brand_title_label):
			_brand_title_label.text = value

@export var interactive: bool = true:
	set(value):
		interactive = value
		_apply_interactive_state()

var _brand_title_label: Label
var _brand_hat: TextureRect
var _brand_hat_tween: Tween


func _ready() -> void:
	_brand_title_label = get_node_or_null("BrandTitle") as Label
	_brand_hat = get_node_or_null("BrandHat") as TextureRect

	if _brand_title_label != null:
		_brand_title_label.text = brand_title
	if _brand_hat != null:
		_brand_hat.texture = GameProgressManager.get_current_hat_texture()
		_brand_hat.position.y = HAT_DEFAULT_Y
		_brand_hat.rotation_degrees = 0.0

	mouse_entered.connect(_on_brand_hover.bind(true))
	mouse_exited.connect(_on_brand_hover.bind(false))
	_apply_interactive_state()


func _apply_interactive_state() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW
	if not interactive and _brand_hat != null:
		if _brand_hat_tween != null and _brand_hat_tween.is_valid():
			_brand_hat_tween.kill()
		_brand_hat.position.y = HAT_DEFAULT_Y
		_brand_hat.rotation_degrees = 0.0


func _on_brand_hover(is_hover: bool) -> void:
	if not interactive or _brand_hat == null:
		return
	if _brand_hat_tween != null and _brand_hat_tween.is_valid():
		_brand_hat_tween.kill()
	_brand_hat_tween = create_tween()
	if is_hover:
		_brand_hat_tween.tween_property(_brand_hat, "position:y", -7.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_brand_hat_tween.parallel().tween_property(_brand_hat, "rotation_degrees", -6.0, 0.10)
		_brand_hat_tween.tween_property(_brand_hat, "position:y", HAT_DEFAULT_Y, 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		_brand_hat_tween.parallel().tween_property(_brand_hat, "rotation_degrees", 0.0, 0.12)
	else:
		_brand_hat_tween.tween_property(_brand_hat, "position:y", HAT_DEFAULT_Y, 0.10)
		_brand_hat_tween.parallel().tween_property(_brand_hat, "rotation_degrees", 0.0, 0.10)
