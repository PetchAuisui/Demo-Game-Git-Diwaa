extends CanvasLayer

## ระบบควบคุม Cutscene: ปุ่มเร่งความเร็ว (Toggle Fast-Forward 1.0x / 2.5x) สไตล์เรโทรนีออนม่วง
## พร้อมปุ่ม [DEV] ข้าม ⏵⏵ (Esc) สำหรับนักพัฒนาทดสอบฉากซ้ำ (พร้อมถอดออกได้ในอนาคต)

@export var next_scene_path: String = "res://Scenes/SandboxGameView.tscn"

var is_fast_forward: bool = false
var _skipping: bool = false

var container: HBoxContainer
var ff_button: Button
var dev_skip_button: Button

func _ready() -> void:
	layer = 100
	
	container = HBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	container.offset_left = -340.0
	container.offset_right = -20.0
	container.offset_top = 16.0
	container.offset_bottom = 54.0
	container.add_theme_constant_override("separation", 10)
	container.alignment = BoxContainer.ALIGNMENT_END
	add_child(container)
	
	# 1. ปุ่มเร่งความเร็ว (Fast-Forward Toggle Button: > 1.0x <-> >> 2.5x)
	ff_button = Button.new()
	ff_button.focus_mode = Control.FOCUS_NONE
	ff_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ff_button.custom_minimum_size = Vector2(95, 36)
	_apply_ff_style(false)
	ff_button.pressed.connect(_toggle_fast_forward)
	container.add_child(ff_button)
	
	# 2. ปุ่ม [DEV] SKIP ชั่วคราวสำหรับเทสต์ฉาก
	dev_skip_button = Button.new()
	dev_skip_button.text = "[DEV] ข้าม ⏵⏵ (Esc)"
	dev_skip_button.focus_mode = Control.FOCUS_NONE
	dev_skip_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	dev_skip_button.custom_minimum_size = Vector2(175, 36)
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
	
	if active:
		# แสง Glow สีนีออนม่วง/ชมพู สไตล์เรโทร
		style.bg_color = Color(0.26, 0.08, 0.42, 0.95)
		style.border_color = Color(0.95, 0.45, 1.0, 1.0)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.shadow_color = Color(0.85, 0.25, 1.0, 0.45)
		style.shadow_size = 6
		ff_button.text = ">> 2.5x"
		ff_button.add_theme_color_override("font_color", Color(1.0, 0.88, 1.0, 1.0))
	else:
		# โทนเรโทรนีออนม่วงเข้มปกติ
		style.bg_color = Color(0.12, 0.07, 0.20, 0.85)
		style.border_color = Color(0.65, 0.45, 0.85, 0.7)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.shadow_size = 0
		ff_button.text = "> 1.0x"
		ff_button.add_theme_color_override("font_color", Color(0.92, 0.88, 0.98, 0.9))
	
	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.35, 0.15, 0.52, 0.95)
	hover_style.border_color = Color(1.0, 0.65, 1.0, 1.0)
	
	ff_button.add_theme_stylebox_override("normal", style)
	ff_button.add_theme_stylebox_override("hover", hover_style)
	ff_button.add_theme_stylebox_override("pressed", hover_style)

func _apply_skip_style() -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	style.bg_color = Color(0.14, 0.08, 0.24, 0.85)
	style.border_color = Color(0.55, 0.38, 0.75, 0.65)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	
	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.24, 0.12, 0.38, 0.95)
	hover_style.border_color = Color(0.85, 0.55, 1.0, 0.9)
	
	dev_skip_button.add_theme_stylebox_override("normal", style)
	dev_skip_button.add_theme_stylebox_override("hover", hover_style)
	dev_skip_button.add_theme_stylebox_override("pressed", hover_style)
	dev_skip_button.add_theme_color_override("font_color", Color(0.92, 0.88, 0.98, 0.85))

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
