extends PanelContainer

var brand_btn: Button
var brand_title: Label
var brand_hat: TextureRect


func _ready() -> void:
	brand_btn = get_node_or_null("%BrandBtn")
	brand_title = get_node_or_null("%BrandTitle")
	brand_hat = get_node_or_null("%BrandHat")

	if brand_hat:
		brand_hat.texture = GameProgressManager.get_current_hat_texture()
		brand_hat.position.y = -4.0
		brand_hat.rotation_degrees = 0.0

	if brand_btn:
		brand_btn.mouse_entered.connect(_on_brand_hover.bind(true))
		brand_btn.mouse_exited.connect(_on_brand_hover.bind(false))


func _on_brand_hover(is_hover: bool) -> void:
	if brand_hat:
		var tw := create_tween()
		if is_hover:
			tw.tween_property(brand_hat, "position:y", -7.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(brand_hat, "rotation_degrees", -6.0, 0.10)
			tw.tween_property(brand_hat, "position:y", -4.0, 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(brand_hat, "rotation_degrees", 0.0, 0.12)
		else:
			tw.tween_property(brand_hat, "position:y", -4.0, 0.10)
			tw.parallel().tween_property(brand_hat, "rotation_degrees", 0.0, 0.10)
