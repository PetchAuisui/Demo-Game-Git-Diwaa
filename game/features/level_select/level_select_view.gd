extends Control

const GameProgressManager = preload("res://common/game_progress_manager.gd")

## หน้าต่างเลือกรวมด่าน (Level Select View)
## แสดงโครงสร้างหน้าต่าง Level / Select Level พร้อมรายการด่าน 15 ด่าน (Grid 3x5)
## สอดคล้องกับข้อกำหนดและภาพตัวอย่างในระบบ

@onready var btn_close: Button = $WindowPanel/VBoxMain/TitleBar/HBox/BtnClose
@onready var grid_container: GridContainer = $WindowPanel/VBoxMain/Margin/VBox/GridContainer

var font_res: Font = null

func _ready() -> void:
	if ResourceLoader.exists("res://assets/fonts/TA-8-bit.ttf"):
		font_res = load("res://assets/fonts/TA-8-bit.ttf")
		
	if btn_close:
		btn_close.pressed.connect(_on_close_pressed)
		
	_setup_level_grid()

func _on_close_pressed() -> void:
	get_tree().change_scene_to_file("res://features/start/start_view.tscn")

func _get_command_for_level(i: int, lvl_path: String) -> String:
	var cmd_name := "git version" if i == 1 else "git command"
	if ResourceLoader.exists(lvl_path):
		var script = load(lvl_path)
		if script and script.has_method("get_data"):
			var data = script.get_data()
			if data.has("commands") and data["commands"].size() > 0:
				cmd_name = str(data["commands"][0]).replace("--", "")
			elif data.has("title"):
				cmd_name = str(data["title"])
	return cmd_name

func _setup_level_grid() -> void:
	if not grid_container:
		return
		
	# ล้าง child เดิมใน Grid (ถ้ามี)
	for child in grid_container.get_children():
		child.queue_free()
		
	for i in range(1, 16):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(180, 110)
		btn.focus_mode = Control.FOCUS_ALL
		
		var lvl_path = "res://features/dialogue/levels/level_%02d.gd" % i
		var has_level = ResourceLoader.exists(lvl_path)
		var is_cleared = GameProgressManager.is_level_cleared(i)
		var is_unlocked = (i == 1) or has_level
		
		if is_cleared:
			# ด่านที่เล่นผ่านสำเร็จแล้ว: แสดงการ์ดสีเขียว พร้อมชื่อคำสั่ง และดาวทอง ⭐⭐⭐
			var green_normal = StyleBoxFlat.new()
			green_normal.bg_color = Color(0.44, 0.72, 0.40, 1.0)
			green_normal.border_color = Color(0.20, 0.48, 0.18, 1.0)
			green_normal.border_width_left = 3
			green_normal.border_width_top = 3
			green_normal.border_width_right = 3
			green_normal.border_width_bottom = 3
			green_normal.corner_radius_top_left = 14
			green_normal.corner_radius_top_right = 14
			green_normal.corner_radius_bottom_left = 14
			green_normal.corner_radius_bottom_right = 14
			
			var green_hover = green_normal.duplicate() as StyleBoxFlat
			green_hover.bg_color = Color(0.52, 0.82, 0.48, 1.0)
			green_hover.border_color = Color(0.15, 0.40, 0.12, 1.0)
			
			btn.add_theme_stylebox_override("normal", green_normal)
			btn.add_theme_stylebox_override("hover", green_hover)
			btn.add_theme_stylebox_override("pressed", green_hover)
			btn.add_theme_stylebox_override("focus", green_hover)
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			
			var vbox = VBoxContainer.new()
			vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_theme_constant_override("separation", 2)
			btn.add_child(vbox)
			
			var lbl_title = Label.new()
			lbl_title.text = "ด่านที่ %d" % i
			lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_title.add_theme_color_override("font_color", Color(0.04, 0.22, 0.05, 1.0))
			if font_res:
				lbl_title.add_theme_font_override("font", font_res)
				lbl_title.add_theme_font_size_override("font_size", 20)
			vbox.add_child(lbl_title)
			
			var cmd_name := _get_command_for_level(i, lvl_path)
			var lbl_cmd = Label.new()
			lbl_cmd.text = cmd_name
			lbl_cmd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_cmd.add_theme_color_override("font_color", Color(0.06, 0.26, 0.08, 1.0))
			if font_res:
				lbl_cmd.add_theme_font_override("font", font_res)
				lbl_cmd.add_theme_font_size_override("font_size", 16)
			vbox.add_child(lbl_cmd)
			
			var lbl_stars = Label.new()
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
				get_tree().change_scene_to_file("res://features/cutscene/inside_tower_cutscene.tscn")
			)
			grid_container.add_child(btn)
			if i == 1:
				btn.grab_focus()
		else:
			# กรณีด่านที่ยังเล่นไม่ผ่าน (แสดงเป็นการ์ดสีเทา ตามที่ผู้ใช้กำหนด)
			var grey_sb = StyleBoxFlat.new()
			grey_sb.bg_color = Color(0.62, 0.62, 0.62, 1.0)
			grey_sb.border_color = Color(0.45, 0.45, 0.45, 1.0)
			grey_sb.border_width_left = 3
			grey_sb.border_width_top = 3
			grey_sb.border_width_right = 3
			grey_sb.border_width_bottom = 3
			grey_sb.corner_radius_top_left = 14
			grey_sb.corner_radius_top_right = 14
			grey_sb.corner_radius_bottom_left = 14
			grey_sb.corner_radius_bottom_right = 14
			
			var grey_hover = grey_sb.duplicate() as StyleBoxFlat
			grey_hover.bg_color = Color(0.68, 0.68, 0.68, 1.0)
			
			btn.add_theme_stylebox_override("normal", grey_sb)
			btn.add_theme_stylebox_override("hover", grey_hover)
			btn.add_theme_stylebox_override("pressed", grey_sb)
			btn.add_theme_stylebox_override("focus", grey_hover)
			
			# ด่านที่ยังไม่ผ่านแต่มีไฟล์ข้อมูลให้เข้าเล่นได้ (เช่น ด่านที่ 1)
			if has_level and is_unlocked:
				btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				
				var vbox = VBoxContainer.new()
				vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				vbox.alignment = BoxContainer.ALIGNMENT_CENTER
				vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
				vbox.add_theme_constant_override("separation", 2)
				btn.add_child(vbox)
				
				var lbl_title = Label.new()
				lbl_title.text = "ด่านที่ %d" % i
				lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl_title.add_theme_color_override("font_color", Color(0.22, 0.22, 0.25, 1.0))
				if font_res:
					lbl_title.add_theme_font_override("font", font_res)
					lbl_title.add_theme_font_size_override("font_size", 20)
				vbox.add_child(lbl_title)
				
				var cmd_name := _get_command_for_level(i, lvl_path)
				var lbl_cmd = Label.new()
				lbl_cmd.text = cmd_name
				lbl_cmd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl_cmd.add_theme_color_override("font_color", Color(0.32, 0.32, 0.36, 1.0))
				if font_res:
					lbl_cmd.add_theme_font_override("font", font_res)
					lbl_cmd.add_theme_font_size_override("font_size", 16)
				vbox.add_child(lbl_cmd)
				
				var level_idx := i
				btn.pressed.connect(func():
					GameProgressManager.set_selected_level_number(level_idx)
					get_tree().change_scene_to_file("res://features/cutscene/inside_tower_cutscene.tscn")
				)
				if i == 1:
					btn.grab_focus()
			else:
				# ด่านที่ยังไม่เปิด / ยังไม่มีไฟล์: ปิดการคลิก
				btn.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
				
			grid_container.add_child(btn)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_on_close_pressed()
