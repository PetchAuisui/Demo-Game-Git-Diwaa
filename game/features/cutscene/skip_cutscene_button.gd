extends CanvasLayer

## ระบบควบคุม Cutscene (Cutscene Controls):
## - ปุ่มเร่งความเร็ว (Fast-Forward Toggle 1.0x / 2.5x) สไตล์ Retro Neon พร้อมลูกศรเด้งไปทางขวา (Bouncing Arrows)
## - ปุ่มข้าม Cutscene (Skip Button) กรอบขอบมนดำ-ขาว สไตล์ 8-bit ตามดีไซน์เกม
##
## วิธีใช้งานใน Cutscene:
##   var skip_ctrl = preload("res://features/cutscene/skip_cutscene_button.gd").new()
##   skip_ctrl.next_scene_path = "res://features/sandbox/sandbox_game_view.tscn"
##   add_child(skip_ctrl)

@export var next_scene_path: String = "res://features/sandbox/sandbox_game_view.tscn"
@export var show_fast_forward: bool = true
@export var show_skip: bool = true

var custom_skip_action: Callable = Callable()
var is_fast_forward: bool = false
var _skipping: bool = false

var container: HBoxContainer
var ff_button: Button = null
var ff_content: HBoxContainer = null
var ff_arrow_wrapper: Control = null
var ff_arrow1_label: Label = null
var ff_arrow2_label: Label = null
var ff_speed_label: Label = null
var ff_bounce_tween: Tween = null

var dev_skip_button: Button = null
var font_res: Font = null

func _ready() -> void:
	layer = 100
	
	if ResourceLoader.exists("res://assets/fonts/TA-8-bit.ttf"):
		font_res = load("res://assets/fonts/TA-8-bit.ttf")
	
	container = HBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	container.offset_left = -350.0
	container.offset_right = -20.0
	container.offset_top = 20.0
	container.offset_bottom = 60.0
	container.add_theme_constant_override("separation", 10)
	container.alignment = BoxContainer.ALIGNMENT_END
	add_child(container)
	
	# 1. ปุ่มเร่งความเร็ว (Fast-Forward: ⏵ 1.0x <-> ⏵ ⏵ 2.5x)
	if show_fast_forward:
		ff_button = Button.new()
		ff_button.focus_mode = Control.FOCUS_NONE
		ff_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		ff_button.custom_minimum_size = Vector2(100, 40)
		
		# กล่องจัดเนื้อหาภายในปุ่ม (จัดกึ่งกลาง พร้อมเว้นระยะสม่ำเสมอ)
		ff_content = HBoxContainer.new()
		ff_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ff_content.alignment = BoxContainer.ALIGNMENT_CENTER
		ff_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ff_content.add_theme_constant_override("separation", 6)
		ff_button.add_child(ff_content)
		
		# กล่องครอบลูกศร (Control เพื่อขยับตำแหน่งและเด้งดึ๋งได้อิสระ)
		ff_arrow_wrapper = Control.new()
		ff_arrow_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ff_arrow_wrapper.custom_minimum_size = Vector2(12, 24)
		ff_arrow_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ff_content.add_child(ff_arrow_wrapper)
		
		# ลูกศรตัวที่ 1 (แสดงตลอด ชดเชยระนาบ -4px ให้ตรงระดับกึ่งกลางและระนาบเดียวกับตัวเลข 1.0x / 2.5x)
		ff_arrow1_label = Label.new()
		ff_arrow1_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ff_arrow1_label.text = "⏵"
		ff_arrow1_label.position = Vector2(0, -4)
		ff_arrow1_label.size = Vector2(14, 24)
		ff_arrow1_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if font_res:
			ff_arrow1_label.add_theme_font_override("font", font_res)
			ff_arrow1_label.add_theme_font_size_override("font_size", 20)
		ff_arrow_wrapper.add_child(ff_arrow1_label)
		
		# ลูกศรตัวที่ 2 (เพิ่มขึ้นมาเมื่อเร่งสปีด 2.5x เด้งไปทางขวาพร้อมลูกศรตัวที่ 1)
		ff_arrow2_label = Label.new()
		ff_arrow2_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ff_arrow2_label.text = "⏵"
		ff_arrow2_label.position = Vector2(11, -4)
		ff_arrow2_label.size = Vector2(14, 24)
		ff_arrow2_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ff_arrow2_label.visible = false
		if font_res:
			ff_arrow2_label.add_theme_font_override("font", font_res)
			ff_arrow2_label.add_theme_font_size_override("font_size", 20)
		ff_arrow_wrapper.add_child(ff_arrow2_label)
		
		# ข้อความบอกระดับความเร็ว (1.0x / 2.5x จัดกึ่งกลางแนวตั้งเสมอ)
		ff_speed_label = Label.new()
		ff_speed_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ff_speed_label.text = "1.0x"
		ff_speed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if font_res:
			ff_speed_label.add_theme_font_override("font", font_res)
			ff_speed_label.add_theme_font_size_override("font_size", 20)
		ff_content.add_child(ff_speed_label)
		
		_apply_ff_style(false)
		ff_button.pressed.connect(_toggle_fast_forward)
		ff_button.mouse_entered.connect(_on_ff_hover.bind(true))
		ff_button.mouse_exited.connect(_on_ff_hover.bind(false))
		container.add_child(ff_button)
	
	# 2. ปุ่มข้าม (Skip: ข้าม)
	if show_skip:
		dev_skip_button = Button.new()
		dev_skip_button.text = "ข้าม"
		dev_skip_button.focus_mode = Control.FOCUS_NONE
		dev_skip_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		dev_skip_button.custom_minimum_size = Vector2(90, 40)
		if font_res:
			dev_skip_button.add_theme_font_override("font", font_res)
			dev_skip_button.add_theme_font_size_override("font_size", 20)
		_apply_skip_style()
		dev_skip_button.pressed.connect(skip)
		container.add_child(dev_skip_button)

func set_fast_forward_visible(p_visible: bool) -> void:
	if ff_button:
		ff_button.visible = p_visible
		if not p_visible and is_fast_forward:
			_toggle_fast_forward()

func set_skip_visible(p_visible: bool) -> void:
	if dev_skip_button:
		dev_skip_button.visible = p_visible

func _exit_tree() -> void:
	_stop_bounce_animation()
	Engine.time_scale = 1.0

func _apply_ff_style(active: bool) -> void:
	if not ff_button:
		return
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	
	# สไตล์กรอบดำขอบขาวนวลแบบเดิม 8-bit ตลอดเวลา (ไม่เปลี่ยนเป็นสีม่วงนีออนตามคำขอ)
	style.bg_color = Color(0.00392, 0, 0.07451, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.980392, 0.976471, 0.964706, 0.85)
	style.shadow_size = 0
	
	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.06, 0.04, 0.16, 0.95)
	hover_style.border_color = Color(0.980392, 0.976471, 0.964706, 1.0)
	
	ff_button.add_theme_stylebox_override("normal", style)
	ff_button.add_theme_stylebox_override("hover", hover_style)
	ff_button.add_theme_stylebox_override("pressed", hover_style)
	ff_button.add_theme_stylebox_override("focus", hover_style)
	
	var font_color := Color(0.980392, 0.976471, 0.964706, 0.9)
	if ff_arrow1_label:
		ff_arrow1_label.add_theme_color_override("font_color", font_color)
	if ff_arrow2_label:
		ff_arrow2_label.add_theme_color_override("font_color", font_color)
	if ff_speed_label:
		ff_speed_label.add_theme_color_override("font_color", font_color)
	
	if active:
		if ff_arrow_wrapper:
			ff_arrow_wrapper.custom_minimum_size = Vector2(22, 24)
		if ff_arrow2_label:
			ff_arrow2_label.visible = true
			ff_arrow2_label.position = Vector2(11, -4)
		if ff_arrow1_label:
			ff_arrow1_label.position = Vector2(0, -4)
		if ff_speed_label:
			ff_speed_label.text = "2.5x"
		_start_bounce_animation()
	else:
		if ff_arrow_wrapper:
			ff_arrow_wrapper.custom_minimum_size = Vector2(12, 24)
		if ff_arrow2_label:
			ff_arrow2_label.visible = false
			ff_arrow2_label.position = Vector2(11, -4)
		if ff_arrow1_label:
			ff_arrow1_label.position = Vector2(0, -4)
		if ff_speed_label:
			ff_speed_label.text = "1.0x"
		_stop_bounce_animation()

func _on_ff_hover(is_hover: bool) -> void:
	var c := Color(1.0, 1.0, 1.0, 1.0) if is_hover else Color(0.980392, 0.976471, 0.964706, 0.9)
	if ff_arrow1_label:
		ff_arrow1_label.add_theme_color_override("font_color", c)
	if ff_arrow2_label:
		ff_arrow2_label.add_theme_color_override("font_color", c)
	if ff_speed_label:
		ff_speed_label.add_theme_color_override("font_color", c)

func _start_bounce_animation() -> void:
	_stop_bounce_animation()
	if not ff_arrow1_label or not ff_arrow2_label:
		return
	
	# สร้าง Tween วนลูปขยับลูกศรทั้งสองตัวพุ่งไปข้างหน้า (ขวา) 3px พร้อมกัน แล้วเด้งกลับเป็นจังหวะต่อเนื่อง
	ff_bounce_tween = create_tween().set_loops()
	ff_bounce_tween.tween_property(ff_arrow1_label, "position:x", 3.0, 0.20)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	ff_bounce_tween.parallel().tween_property(ff_arrow2_label, "position:x", 14.0, 0.20)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	ff_bounce_tween.chain().tween_property(ff_arrow1_label, "position:x", 0.0, 0.20)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	ff_bounce_tween.parallel().tween_property(ff_arrow2_label, "position:x", 11.0, 0.20)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	ff_bounce_tween.chain().tween_interval(0.10)

func _stop_bounce_animation() -> void:
	if ff_bounce_tween and ff_bounce_tween.is_valid():
		ff_bounce_tween.kill()
		ff_bounce_tween = null
	if ff_arrow1_label:
		ff_arrow1_label.position = Vector2(0.0, -4.0)
	if ff_arrow2_label:
		ff_arrow2_label.position = Vector2(11.0, -4.0)

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
	if custom_skip_action.is_valid():
		custom_skip_action.call()
		return
	_skipping = true
	_stop_bounce_animation()
	Engine.time_scale = 1.0
	if next_scene_path != "" and ResourceLoader.exists(next_scene_path):
		get_tree().change_scene_to_file(next_scene_path)
	else:
		push_warning("[SkipCutscene] next_scene_path not found: '%s'" % next_scene_path)
		_skipping = false
