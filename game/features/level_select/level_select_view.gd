extends Control

## ฉากบทสนทนาประจำด่าน (ไม่เล่นคัตซีนเดินเข้าห้องโถงซ้ำ ซึ่งเล่นเฉพาะครั้งแรกผ่าน inside_tower_cutscene)
const LEVEL_DIALOGUE_SCENE := "res://features/dialogue/level_dialogue_view.tscn"

## หน้าต่างเลือกรวมด่าน (Level Select View)
## แสดงโครงสร้างหน้าต่าง Level / Select Level พร้อมรายการด่าน 15 ด่าน (Grid 3x5)
## สอดคล้องกับข้อกำหนดและภาพตัวอย่างในระบบ

@onready var btn_close: Button = $WindowPanel/VBoxMain/TitleBar/HBox/BtnClose
@onready var grid_container: GridContainer = $WindowPanel/VBoxMain/Margin/VBox/GridContainer

var font_res: Font = null
var font_cmd: Font = null

func _ready() -> void:
	if ResourceLoader.exists("res://assets/fonts/ChakraPetch-Bold.ttf"):
		var base_bold: Font = load("res://assets/fonts/ChakraPetch-Bold.ttf")
		var fv_title := FontVariation.new()
		fv_title.base_font = base_bold
		fv_title.spacing_top = 4
		fv_title.spacing_bottom = 2
		font_res = fv_title
	elif ResourceLoader.exists("res://assets/fonts/TA-8-bit.ttf"):
		font_res = load("res://assets/fonts/TA-8-bit.ttf")

	if ResourceLoader.exists("res://assets/fonts/ChakraPetch-Regular.ttf"):
		var base_reg: Font = load("res://assets/fonts/ChakraPetch-Regular.ttf")
		var fv_cmd := FontVariation.new()
		fv_cmd.base_font = base_reg
		fv_cmd.spacing_top = 4
		fv_cmd.spacing_bottom = 2
		font_cmd = fv_cmd
	else:
		font_cmd = font_res
		
	if btn_close:
		btn_close.pressed.connect(_on_close_pressed)
		
	_setup_level_grid()

func _on_close_pressed() -> void:
	get_tree().change_scene_to_file("res://features/start/start_view.tscn")

func _setup_level_grid() -> void:
	if not grid_container:
		return
		
	# ล้าง child เดิมใน Grid (ถ้ามี)
	for child in grid_container.get_children():
		child.queue_free()
		
	for i in range(1, 16):
		var has_level := LevelDataLoader.has_level(i)
		var is_cleared := GameProgressManager.is_level_cleared(i)
		var is_unlocked := (i == 1) or GameProgressManager.is_level_cleared(i - 1)
		var is_playable := has_level and (is_unlocked or is_cleared)
		
		var btn := _build_level_card(i, is_cleared, is_playable)
		grid_container.add_child(btn)
		if i == 1:
			btn.grab_focus()

func _build_level_card(i: int, is_cleared: bool, is_playable: bool) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(180, 110)
	btn.focus_mode = Control.FOCUS_ALL
	
	var bg_color: Color
	var border_color: Color
	var hover_color: Color
	var title_color: Color
	var cmd_color: Color
	
	if is_cleared:
		# ด่านที่เล่นผ่านสำเร็จแล้ว: แสดงการ์ดสีเขียว พร้อมชื่อคำสั่ง และดาวทอง ⭐⭐⭐
		bg_color = Color(0.44, 0.72, 0.40, 1.0)
		border_color = Color(0.20, 0.48, 0.18, 1.0)
		hover_color = Color(0.52, 0.82, 0.48, 1.0)
		title_color = Color(0.04, 0.22, 0.05, 1.0)
		cmd_color = Color(0.06, 0.26, 0.08, 1.0)
	elif is_playable:
		# กรณีด่านที่ยังเล่นไม่ผ่าน แต่ปลดล็อกแล้ว (แสดงเป็นการ์ดสีเทา)
		bg_color = Color(0.62, 0.62, 0.62, 1.0)
		border_color = Color(0.45, 0.45, 0.45, 1.0)
		hover_color = Color(0.68, 0.68, 0.68, 1.0)
		title_color = Color(0.22, 0.22, 0.25, 1.0)
		cmd_color = Color(0.32, 0.32, 0.36, 1.0)
	else:
		# ด่านที่ยังไม่เปิด / ยังไม่มีไฟล์
		bg_color = Color(0.50, 0.50, 0.50, 0.6)
		border_color = Color(0.35, 0.35, 0.35, 0.6)
		hover_color = bg_color
		title_color = Color(0.30, 0.30, 0.30, 0.8)
		cmd_color = Color(0.30, 0.30, 0.30, 0.8)

	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = bg_color
	sb_normal.border_color = border_color
	sb_normal.border_width_left = 3
	sb_normal.border_width_top = 3
	sb_normal.border_width_right = 3
	sb_normal.border_width_bottom = 3
	sb_normal.corner_radius_top_left = 14
	sb_normal.corner_radius_top_right = 14
	sb_normal.corner_radius_bottom_left = 14
	sb_normal.corner_radius_bottom_right = 14
	
	var sb_hover := sb_normal.duplicate() as StyleBoxFlat
	sb_hover.bg_color = hover_color

	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover if is_cleared else sb_normal)
	btn.add_theme_stylebox_override("focus", sb_hover)

	if is_playable:
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		var vbox := VBoxContainer.new()
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_theme_constant_override("separation", 2)
		btn.add_child(vbox)
		
		var lbl_title := Label.new()
		lbl_title.text = "ด่านที่ %d" % i
		lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_title.add_theme_color_override("font_color", title_color)
		if font_res:
			lbl_title.add_theme_font_override("font", font_res)
			lbl_title.add_theme_font_size_override("font_size", 22)
		vbox.add_child(lbl_title)
		
		var cmd_name := LevelDataLoader.get_display_command(i)
		var lbl_cmd := Label.new()
		lbl_cmd.text = cmd_name
		lbl_cmd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_cmd.add_theme_color_override("font_color", cmd_color)
		if font_cmd:
			lbl_cmd.add_theme_font_override("font", font_cmd)
			lbl_cmd.add_theme_font_size_override("font_size", 16)
		elif font_res:
			lbl_cmd.add_theme_font_override("font", font_res)
			lbl_cmd.add_theme_font_size_override("font_size", 16)
		vbox.add_child(lbl_cmd)
		
		if is_cleared:
			var lbl_stars := Label.new()
			lbl_stars.text = "★ ★ ★"
			lbl_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_stars.add_theme_color_override("font_color", Color(0.98, 0.82, 0.10, 1.0))
			if font_res:
				lbl_stars.add_theme_font_override("font", font_res)
				lbl_stars.add_theme_font_size_override("font_size", 18)
			vbox.add_child(lbl_stars)
			
		var level_idx := i
		btn.pressed.connect(func():
			GameProgressManager.set_selected_level_number(level_idx)
			get_tree().change_scene_to_file(LEVEL_DIALOGUE_SCENE)
		)
	else:
		btn.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		btn.disabled = true
		
	return btn

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_on_close_pressed()
