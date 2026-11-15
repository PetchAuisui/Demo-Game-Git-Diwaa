class_name CommandDemonstrationCanvas
extends Control

## ผ้าใบแท่นหยั่งรู้มนตรา (Arcane Grimoire Altar & Git Visualizer)
## แสดงผลการจำลองในรูปแบบ Theme เวทมนตร์ของเกม ไม่ซ้ำกับ Terminal ในด่าน
## รองรับการต่อยอดคำสั่งอื่นๆ ในเซตเดียวกัน:
## - VERSION_CHECK: วงแหวนเวทตรวจสอบคลื่นพลังคัมภีร์ (Git Version Detection Seal)
## - CONFIG_REGISTRY: ศิลาผูกตราประทับวิญญาณและนามนักเวท (Soul Seal & Identity Stele)
## - GIT_GRAPH: สายธารดวงดาวแห่งกาลเวลา (Commit Constellation / Branch Leyline)

signal animation_started
signal animation_finished(command_name: String)

enum DisplayMode {
	VERSION_CHECK,
	CONFIG_REGISTRY,
	GIT_GRAPH,
}

var current_mode: DisplayMode = DisplayMode.VERSION_CHECK

# สถานะการจำลอง
var active_command: String = "git version"
var is_animating: bool = false
var anim_phase: int = 0 # 0 = Idle, 1 = Resonating/Casting, 2 = Result Locked

# เวลาสำหรับอนิเมชั่นวงแหวนเวทและการลอยของคัมภีร์
var anim_time: float = 0.0
var reticle_rotation: float = 0.0
var reticle_speed: float = 0.5
var book_base_y: float = 0.0

# สีโทนเวทมนตร์ตามธีมเกม
const COLOR_ALTAR_BG     := Color(0.06, 0.05, 0.12, 0.98)
const COLOR_HEADER_BG    := Color(0.14, 0.10, 0.24, 1.0)
const COLOR_GOLD_BORDER  := Color(0.85, 0.70, 0.38, 0.85)
const COLOR_MAGIC_PURPLE := Color(0.72, 0.45, 0.95, 1.0)
const COLOR_MAGIC_CYAN   := Color(0.35, 0.85, 0.95, 1.0)
const COLOR_MAGIC_GREEN  := Color(0.31, 0.95, 0.62, 1.0)
const COLOR_TEXT_WHITE   := Color(0.92, 0.94, 0.97, 1.0)
const COLOR_MUTED        := Color(0.65, 0.70, 0.80, 1.0)
const COLOR_CARD_BG      := Color(0.09, 0.08, 0.18, 0.92)

# โหนด UI
var _root_vbox: VBoxContainer
var _header_panel: Panel
var _header_title: Label
var _center_altar_panel: PanelContainer
var _magic_chamber: Control
var _reticle_rect: TextureRect
var _book_rect: TextureRect
var _particles_label: Label
var _status_tablet: PanelContainer
var _status_title: Label
var _details_vbox: VBoxContainer
var _note_panel: PanelContainer
var _note_vbox: VBoxContainer

var _font_bold: Font
var _font_reg: Font
var _active_tween: Tween


func _ready() -> void:
	if ResourceLoader.exists("res://assets/fonts/ChakraPetch-Bold.ttf"):
		_font_bold = load("res://assets/fonts/ChakraPetch-Bold.ttf")
	if ResourceLoader.exists("res://assets/fonts/ChakraPetch-Regular.ttf"):
		_font_reg = load("res://assets/fonts/ChakraPetch-Regular.ttf")

	_build_ui()
	reset_animation()


func _process(delta: float) -> void:
	anim_time += delta
	
	# หมุนวงแหวนเวทมนตร์ตามความเร็วปัจจุบัน
	reticle_rotation += reticle_speed * delta
	if _reticle_rect != null and _reticle_rect.visible:
		_reticle_rect.rotation = reticle_rotation
	
	# อนิเมชั่นคัมภีร์ลอยเบาๆ (Floating Bobbing Effect)
	if _book_rect != null:
		var float_offset := sin(anim_time * 2.2) * 6.0
		_book_rect.position.y = book_base_y + float_offset
		
		if is_animating:
			var pulse := 0.85 + 0.15 * sin(anim_time * 8.0)
			_book_rect.modulate = Color(pulse, pulse * 1.1, 1.0, 1.0)
		else:
			_book_rect.modulate = Color.WHITE


# ---- สร้างโครงสร้าง UI ด้วย Theme เวทมนตร์ ----

func _build_ui() -> void:
	_root_vbox = VBoxContainer.new()
	_root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_vbox.add_theme_constant_override("separation", 0)
	add_child(_root_vbox)

	# 1. แถบหัวเรื่องแท่นมนตรา
	_header_panel = Panel.new()
	_header_panel.custom_minimum_size = Vector2(0, 42)
	var hdr_style := StyleBoxFlat.new()
	hdr_style.bg_color = COLOR_HEADER_BG
	hdr_style.border_color = COLOR_GOLD_BORDER * 0.7
	hdr_style.border_width_bottom = 1
	_header_panel.add_theme_stylebox_override("panel", hdr_style)
	_root_vbox.add_child(_header_panel)

	_header_title = Label.new()
	_header_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_header_title.text = "🔮 แท่นหยั่งรู้มนตรา: สัมผัสพลังคัมภีร์เวท"
	_header_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45, 1.0))
	_header_title.add_theme_font_size_override("font_size", 16)
	if _font_bold:
		_header_title.add_theme_font_override("font", _font_bold)
	_header_panel.add_child(_header_title)

	# 2. พื้นที่แท่นหยั่งรู้ส่วนกลาง (Central Altar Chamber)
	_center_altar_panel = PanelContainer.new()
	_center_altar_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var altar_style := StyleBoxFlat.new()
	altar_style.bg_color = COLOR_ALTAR_BG
	_center_altar_panel.add_theme_stylebox_override("panel", altar_style)
	_root_vbox.add_child(_center_altar_panel)

	var altar_margin := MarginContainer.new()
	altar_margin.add_theme_constant_override("margin_left", 14)
	altar_margin.add_theme_constant_override("margin_top", 10)
	altar_margin.add_theme_constant_override("margin_right", 14)
	altar_margin.add_theme_constant_override("margin_bottom", 10)
	_center_altar_panel.add_child(altar_margin)

	var chamber_vbox := VBoxContainer.new()
	chamber_vbox.add_theme_constant_override("separation", 10)
	altar_margin.add_child(chamber_vbox)

	# 2.1 ห้องเวทมนตร์ (Magic Chamber) แสดงวงแหวนและคัมภีร์ลอย
	_magic_chamber = Control.new()
	_magic_chamber.custom_minimum_size = Vector2(0, 210)
	_magic_chamber.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_magic_chamber.clip_contents = true
	chamber_vbox.add_child(_magic_chamber)

	# วงแหวนเวทหมุนวน (Magic Reticle)
	_reticle_rect = TextureRect.new()
	if ResourceLoader.exists("res://assets/art/dressing_room/magic_reticle.png"):
		_reticle_rect.texture = load("res://assets/art/dressing_room/magic_reticle.png")
	_reticle_rect.custom_minimum_size = Vector2(260, 260)
	_reticle_rect.pivot_offset = Vector2(130, 130)
	_reticle_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_reticle_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_reticle_rect.modulate = Color(0.45, 0.75, 1.0, 0.45)
	_magic_chamber.add_child(_reticle_rect)

	# คัมภีร์เวทมนตร์ลอยอยู่ตรงกลาง (Khampri Book)
	_book_rect = TextureRect.new()
	if ResourceLoader.exists("res://assets/cutscene/props/khampri/Khampri.png"):
		_book_rect.texture = load("res://assets/cutscene/props/khampri/Khampri.png")
	_book_rect.custom_minimum_size = Vector2(110, 110)
	_book_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_book_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_magic_chamber.add_child(_book_rect)

	# จัดกึ่งกลางเมื่อขนาดพร้อม
	_magic_chamber.resized.connect(_reposition_chamber_items)

	# 2.2 ศิลาแสดงผลการหยั่งรู้เวทมนตร์ (Status Tablet)
	_status_tablet = PanelContainer.new()
	var tablet_style := StyleBoxFlat.new()
	tablet_style.bg_color = COLOR_CARD_BG
	tablet_style.border_color = COLOR_GOLD_BORDER * 0.75
	tablet_style.border_width_left = 2
	tablet_style.border_width_top = 2
	tablet_style.border_width_right = 2
	tablet_style.border_width_bottom = 2
	tablet_style.set_corner_radius_all(10)
	_status_tablet.add_theme_stylebox_override("panel", tablet_style)
	chamber_vbox.add_child(_status_tablet)

	var tab_margin := MarginContainer.new()
	tab_margin.add_theme_constant_override("margin_left", 14)
	tab_margin.add_theme_constant_override("margin_top", 10)
	tab_margin.add_theme_constant_override("margin_right", 14)
	tab_margin.add_theme_constant_override("margin_bottom", 10)
	_status_tablet.add_child(tab_margin)

	var tab_vbox := VBoxContainer.new()
	tab_vbox.add_theme_constant_override("separation", 6)
	tab_margin.add_child(tab_vbox)

	_status_title = _make_label("✦ รอการร่ายคาถาตรวจสอบระดับพลังเวท ✦", Color(1.0, 0.85, 0.45, 1.0), true, 16)
	_status_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tab_vbox.add_child(_status_title)

	_details_vbox = VBoxContainer.new()
	_details_vbox.add_theme_constant_override("separation", 4)
	tab_vbox.add_child(_details_vbox)

	# 3. กล่องคำอธิบายหลักการทำงานจริงของคำสั่ง (Note Panel ด้านล่าง)
	_note_panel = PanelContainer.new()
	_note_panel.custom_minimum_size = Vector2(0, 114)
	var note_style := StyleBoxFlat.new()
	note_style.bg_color = Color(0.08, 0.10, 0.18, 0.95)
	note_style.border_color = Color(0.35, 0.45, 0.68, 0.7)
	note_style.border_width_left = 1
	note_style.border_width_top = 1
	note_style.border_width_right = 1
	note_style.border_width_bottom = 1
	note_style.set_corner_radius_all(8)
	_note_panel.add_theme_stylebox_override("panel", note_style)
	chamber_vbox.add_child(_note_panel)

	var note_margin := MarginContainer.new()
	note_margin.add_theme_constant_override("margin_left", 14)
	note_margin.add_theme_constant_override("margin_top", 10)
	note_margin.add_theme_constant_override("margin_right", 14)
	note_margin.add_theme_constant_override("margin_bottom", 10)
	_note_panel.add_child(note_margin)

	_note_vbox = VBoxContainer.new()
	_note_vbox.add_theme_constant_override("separation", 5)
	note_margin.add_child(_note_vbox)


func _reposition_chamber_items() -> void:
	if _magic_chamber == null:
		return
	var c_size := _magic_chamber.size
	if c_size.x <= 0 or c_size.y <= 0:
		return

	if _reticle_rect:
		_reticle_rect.position = Vector2(
			(c_size.x - _reticle_rect.custom_minimum_size.x) * 0.5,
			(c_size.y - _reticle_rect.custom_minimum_size.y) * 0.5
		)
		_reticle_rect.pivot_offset = _reticle_rect.custom_minimum_size * 0.5

	if _book_rect:
		book_base_y = (c_size.y - _book_rect.custom_minimum_size.y) * 0.5
		_book_rect.position = Vector2(
			(c_size.x - _book_rect.custom_minimum_size.x) * 0.5,
			book_base_y
		)


# ---- Public API ----

func set_mode(mode: DisplayMode) -> void:
	current_mode = mode
	reset_animation()


func reset_animation() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()

	is_animating = false
	anim_phase = 0
	reticle_speed = 0.4
	
	if _reticle_rect:
		_reticle_rect.modulate = Color(0.45, 0.75, 1.0, 0.4)
	if _book_rect:
		_book_rect.modulate = Color.WHITE

	match current_mode:
		DisplayMode.VERSION_CHECK:
			active_command = "git version"
			_header_title.text = "🔮 แท่นหยั่งรู้มนตรา: สัมผัสพลังคัมภีร์เวท (Git Version)"
		DisplayMode.CONFIG_REGISTRY:
			active_command = "git config --global user.name \"Vel\""
			_header_title.text = "📜 ศิลาจารึกวิญญาณ: ประกาศนามและผูกตราประทับ (Git Config)"
		DisplayMode.GIT_GRAPH:
			active_command = "git commit"
			_header_title.text = "✨ สายธารดวงดาวแห่งกาลเวลา: ประวัติการจารึก (Git Graph)"

	_refresh_tablet_ui()
	_refresh_note_ui()


## จำลองการร่ายคาถาและกระตุ้นวงแหวนเวทมนตร์
func simulate_command(cmd: String) -> void:
	if is_animating:
		return

	active_command = cmd
	is_animating = true
	anim_phase = 1 # กำลังร่าย / Resonating
	animation_started.emit()

	# เร่งความเร็วการหมุนของวงแหวนเวท และเปล่งแสงสีทอง/ฟ้า
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()

	_active_tween = create_tween()
	_active_tween.tween_property(self, "reticle_speed", 3.2, 0.4).set_ease(Tween.EASE_OUT)
	_active_tween.parallel().tween_property(_reticle_rect, "modulate", Color(0.4, 0.95, 1.0, 0.85), 0.3)
	
	_refresh_tablet_ui()

	# ร่ายมนตร์ 1.1 วินาทีแล้วล็อกผลลัพธ์
	_active_tween.tween_interval(0.9)
	_active_tween.tween_callback(func() -> void:
		anim_phase = 2 # ล็อกผลลัพธ์สำเร็จ
		is_animating = false
		reticle_speed = 0.6
		if _reticle_rect:
			_reticle_rect.modulate = Color(0.35, 0.95, 0.65, 0.6)
		_refresh_tablet_ui()
		animation_finished.emit(cmd)
	)


# ---- การแสดงผลในแท็บเล็ตและกล่องข้อความ ----

func _refresh_tablet_ui() -> void:
	if _details_vbox == null or _status_title == null:
		return

	for child in _details_vbox.get_children():
		child.queue_free()

	if anim_phase == 0:
		# สถานะ Idle
		_status_title.text = "✦ รอการร่ายคาถาตรวจสอบระดับพลัง ✦"
		_status_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45, 1.0))
		
		var hint_lbl := _make_label("กดปุ่ม 'ทดสอบ git version' หรือ 'git --version' ทางด้านซ้าย", COLOR_MUTED, false, 14)
		hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_details_vbox.add_child(hint_lbl)
		
	elif anim_phase == 1:
		# สถานะกำลังร่ายเวท (Resonating)
		_status_title.text = "⚡ กำลังส่งคลื่นเวทมนตร์เข้าสู่แกนกลางคัมภีร์..."
		_status_title.add_theme_color_override("font_color", COLOR_MAGIC_CYAN)
		
		var casting_lbl := _make_label("วงแหวนเวทกำลังตรวจวัดระดับพลังของคำสั่ง: %s" % active_command, COLOR_MAGIC_GREEN, true, 14)
		casting_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_details_vbox.add_child(casting_lbl)
		
	elif anim_phase == 2:
		# ผลลัพธ์สำเร็จ (Locked)
		if current_mode == DisplayMode.VERSION_CHECK:
			_status_title.text = "✨ ตรวจพบแกนพลังเวทมนตร์ Git สำเร็จ! ✨"
			_status_title.add_theme_color_override("font_color", COLOR_MAGIC_GREEN)

			var res_grid := VBoxContainer.new()
			res_grid.add_theme_constant_override("separation", 6)
			_details_vbox.add_child(res_grid)

			res_grid.add_child(_make_attribute_row("🔮 แกนกลางคัมภีร์:", "Git Core Engine (หอคอยเวทมนตร์)", COLOR_TEXT_WHITE))
			res_grid.add_child(_make_attribute_row("⚡ ระดับพลังเวท (Version):", "Git Version 2.40.1", Color(1.0, 0.88, 0.45, 1.0), true, 17))
			res_grid.add_child(_make_attribute_row("🛡️ สถานะการตอบรับ:", "สมบูรณ์ พร้อมร่ายคาถาในเทอร์มินัล", COLOR_MAGIC_GREEN))
			res_grid.add_child(_make_attribute_row("📜 คาถาที่ใช้ทดสอบ:", active_command, COLOR_MAGIC_CYAN))

		elif current_mode == DisplayMode.CONFIG_REGISTRY:
			_status_title.text = "✨ ตราประทับวิญญาณได้รับการจารึกเรียบร้อย! ✨"
			_status_title.add_theme_color_override("font_color", COLOR_MAGIC_GREEN)

			var res_grid := VBoxContainer.new()
			res_grid.add_theme_constant_override("separation", 6)
			_details_vbox.add_child(res_grid)

			res_grid.add_child(_make_attribute_row("👤 นามผู้จารึก (user.name):", "\"Vel\"", Color(1.0, 0.88, 0.45, 1.0), true, 16))
			res_grid.add_child(_make_attribute_row("✉️ ตราประทับวิญญาณ (user.email):", "\"vel@magic-tower.local\"", COLOR_MAGIC_CYAN))
			res_grid.add_child(_make_attribute_row("🏛️ ขอบเขตการจารึก:", "ทั่วทั้งหอคอยเวท (--global)", COLOR_TEXT_WHITE))


func _make_attribute_row(label_text: String, value_text: String, val_color: Color, bold_val: bool = false, val_size: int = 15) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var lbl := _make_label(label_text, COLOR_MUTED, false, 14)
	lbl.custom_minimum_size = Vector2(170, 0)
	hbox.add_child(lbl)

	var val := _make_label(value_text, val_color, bold_val, val_size)
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(val)

	return hbox


func _refresh_note_ui() -> void:
	if _note_vbox == null:
		return

	for child in _note_vbox.get_children():
		child.queue_free()

	match current_mode:
		DisplayMode.VERSION_CHECK:
			_add_note_line("💡 หลักการทำงานของคาถาตรวจสอบเวอร์ชัน (git version / git --version):", Color(1.0, 0.85, 0.45, 1.0), true, 15)
			_add_note_line("• สามารถพิมพ์ได้ 2 แบบ: 'git version' (ไม่มีขีด) หรือ 'git --version' (ขีดคู่) — ให้ผลเหมือนกันทุกประการ", COLOR_TEXT_WHITE, false, 14)
			_add_note_line("• คาถานี้เป็นการถามระบบ Git ในหอคอย เพื่อตรวจสอบว่าพร้อมใช้งานหรือไม่", COLOR_MUTED, false, 14)
			_add_note_line("• ปลอดภัย 100% ไม่มีการดัดแปลง แก้ไข หรือสร้างไฟล์ใดๆ ในคัมภีร์", COLOR_MAGIC_GREEN, false, 14)
		DisplayMode.CONFIG_REGISTRY:
			_add_note_line("💡 หลักการทำงานของคำสั่ง git config (ลงทะเบียนตัวตน):", Color(1.0, 0.85, 0.45, 1.0), true, 15)
			_add_note_line("• เมื่อตั้งค่า (Set) Git จะบันทึกข้อมูลอย่างเงียบๆ โดยไม่แสดงข้อความตอบกลับ", COLOR_TEXT_WHITE, false, 14)
			_add_note_line("• หากต้องการตรวจดูค่า (Get) ให้พิมพ์คำสั่งเดิมโดยไม่ต้องระบุชื่อต่อท้าย", COLOR_MUTED, false, 14)
			_add_note_line("• ข้อมูลนี้จะถูกประทับไว้ในทุกประวัติการจารึก (Commit) ที่เจ้าจะสร้างในอนาคต", COLOR_MAGIC_GREEN, false, 14)


func _add_note_line(text: String, color: Color, bold: bool, size: int) -> void:
	var lbl := _make_label(text, color, bold, size)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note_vbox.add_child(lbl)


func _make_label(text: String, color: Color, bold: bool, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	if bold and _font_bold:
		lbl.add_theme_font_override("font", _font_bold)
	elif _font_reg:
		lbl.add_theme_font_override("font", _font_reg)
	return lbl
