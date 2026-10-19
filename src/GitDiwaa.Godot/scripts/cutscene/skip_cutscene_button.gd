extends CanvasLayer

## ระบบควบคุม Cutscene (Cutscene Controls):
## - ปุ่มเร่งความเร็ว (Fast-Forward Toggle 1.0x / 2.5x) สไตล์ Retro Neon
## - ปุ่มข้าม Cutscene (Skip Button) กรอบขอบมนดำ-ขาว สไตล์ 8-bit ตามดีไซน์เกม
##
## วิธีใช้งานใน Cutscene:
##   var skip_ctrl = preload("res://scripts/cutscene/skip_cutscene_button.gd").new()
##   skip_ctrl.next_scene_path = "res://Scenes/SandboxGameView.tscn"
##   add_child(skip_ctrl)

@export var next_scene_path: String = "res://Scenes/SandboxGameView.tscn"

var is_fast_forward: bool = false
var _skipping: bool = false

var container: HBoxContainer
var ff_button: Button
var dev_skip_button: Button
var font_res: Font = null

func _ready() -> void:
	layer = 100
	
	if ResourceLoader.exists("res://assets/fonts/TA-8-bit.ttf"):
		font_res = load("res://assets/fonts/TA-8-bit.ttf")
	
	container = HBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	container.offset_left = -340.0
	container.offset_right = -20.0
	container.offset_top = 20.0
	container.offset_bottom = 60.0
	container.add_theme_constant_override("separation", 10)
	container.alignment = BoxContainer.ALIGNMENT_END
	add_child(container)
	
	# 1. ปุ่มเร่งความเร็ว (Fast-Forward: ⏵ 1.0x <-> ⏵⏵ 2.5x)
	ff_button = Button.new()
	ff_button.focus_mode = Control.FOCUS_NONE
	ff_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ff_button.custom_minimum_size = Vector2(95, 40)
	if font_res:
		ff_button.add_theme_font_override("font", font_res)
		ff_button.add_theme_font_size_override("font_size", 20)
	_apply_ff_style(false)
	ff_button.pressed.connect(_toggle_fast_forward)
	container.add_child(ff_button)
	
	# 2. ปุ่มข้าม (Skip: ข้าม ⏵⏵ (Esc))
	dev_skip_button = Button.new()
	dev_skip_button.text = "ข้าม ⏵⏵ (Esc)"
	dev_skip_button.focus_mode = Control.FOCUS_NONE
	dev_skip_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	dev_skip_button.custom_minimum_size = Vector2(175, 40)
	if font_res:
		dev_skip_button.add_theme_font_override("font", font_res)
		dev_skip_button.add_theme_font_size_override("font_size", 20)
	_apply_skip_style()
	dev_skip_button.pressed.connect(skip)
	container.add_child(dev_skip_button)

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _apply_ff_style(active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	
	var hover_style := style.duplicate() as StyleBoxFlat
	
	if active:
		# เมื่อเร่งความเร็ว 2.5x: แสง Glow สีนีออนม่วงสไตล์เรโทร
		style.bg_color = Color(0.18, 0.05, 0.30, 0.95)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.95, 0.45, 1.0, 1.0)
		style.shadow_color = Color(0.85, 0.25, 1.0, 0.5)
		style.shadow_size = 6
		ff_button.text = "⏵⏵ 2.5x"
		ff_button.add_theme_color_override("font_color", Color(1.0, 0.88, 1.0, 1.0))
		ff_button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
		
		hover_style.bg_color = Color(0.28, 0.10, 0.44, 0.95)
		hover_style.border_color = Color(1.0, 0.65, 1.0, 1.0)
		hover_style.shadow_color = Color(0.95, 0.45, 1.0, 0.6)
		hover_style.shadow_size = 8
	else:
		# ความเร็วปกติ 1.0x: กรอบดำขอบขาวนวล สไตล์เดียวกับปุ่มข้ามในรูป
		style.bg_color = Color(0.00392, 0, 0.07451, 0.95)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.980392, 0.976471, 0.964706, 0.85)
		style.shadow_size = 0
		ff_button.text = "⏵ 1.0x"
		ff_button.add_theme_color_override("font_color", Color(0.980392, 0.976471, 0.964706, 0.9))
		ff_button.add_theme_color_override("font_hover_color", Color(0.980392, 0.976471, 0.964706, 1.0))
		
		hover_style.bg_color = Color(0.06, 0.04, 0.16, 0.95)
		hover_style.border_color = Color(0.980392, 0.976471, 0.964706, 1.0)
	
	ff_button.add_theme_stylebox_override("normal", style)
	ff_button.add_theme_stylebox_override("hover", hover_style)
	ff_button.add_theme_stylebox_override("pressed", hover_style)
	ff_button.add_theme_stylebox_override("focus", hover_style)

func _apply_skip_style() -> void:
	# กรอบและโทนสีเดียวกับปุ่มข้ามในรูปต้นฉบับเป๊ะๆ
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	style.bg_color = Color(0.00392, 0, 0.07451, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.980392, 0.976471, 0.964706, 0.85)
	
	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.06, 0.04, 0.16, 0.95)
	hover_style.border_color = Color(0.980392, 0.976471, 0.964706, 1.0)
	
	dev_skip_button.add_theme_stylebox_override("normal", style)
	dev_skip_button.add_theme_stylebox_override("hover", hover_style)
	dev_skip_button.add_theme_stylebox_override("pressed", hover_style)
	dev_skip_button.add_theme_stylebox_override("focus", hover_style)
	dev_skip_button.add_theme_color_override("font_color", Color(0.980392, 0.976471, 0.964706, 0.9))
	dev_skip_button.add_theme_color_override("font_hover_color", Color(0.980392, 0.976471, 0.964706, 1.0))
	dev_skip_button.add_theme_color_override("font_focus_color", Color(0.980392, 0.976471, 0.964706, 1.0))
	dev_skip_button.add_theme_color_override("font_pressed_color", Color(0.980392, 0.976471, 0.964706, 1.0))

func _toggle_fast_forward() -> void:
	is_fast_forward = not is_fast_forward
	Engine.time_scale = 2.5 if is_fast_forward else 1.0
	_apply_ff_style(is_fast_forward)

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		skip()

func skip() -> void:
	if not visible or _skipping:
		return
	_skipping = true
	Engine.time_scale = 1.0
	if next_scene_path != "" and ResourceLoader.exists(next_scene_path):
		get_tree().change_scene_to_file(next_scene_path)
	else:
		push_warning("[SkipCutscene] next_scene_path not found: '%s'" % next_scene_path)
		_skipping = false
