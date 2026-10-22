class_name GitHubUi
extends RefCounted
## ชิ้นส่วน UI แบบ GitHub ที่ใช้ซ้ำในหน้า Remote Repository

const AVATAR_COLORS: Array[String] = ["#1f6feb", "#8957e5", "#238636", "#9e6a03", "#da3633", "#0b7285", "#bf3989"]

## ความกว้างสูงสุดของตัวเลือก branch ชื่อที่ยาวกว่านี้ถูกตัดท้ายด้วย … (ดูชื่อเต็มได้จากเมนูและ tooltip)
static func branch_picker_max_width() -> int:
	return GitHubTheme.s(380)


static func _s(pixels: float) -> int:
	return GitHubTheme.s(pixels)


static func spacer() -> Control:
	var control := Control.new()
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return control


static func text(content: String, color: Variant = null, size: int = 15, bold: bool = false,
		mono: bool = false, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = content
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", color if color != null else GitHubTheme.FG)
	label.add_theme_font_size_override("font_size", _s(size))
	if mono:
		label.add_theme_font_override("font", GitHubTheme.mono_font())
	elif bold:
		label.add_theme_font_override("font", GitHubTheme.bold_font())
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


static func text_bold(content: String, color: Variant = null, size: int = 15, wrap: bool = false) -> Label:
	return text(content, color, size, true, false, wrap)


static func text_mono(content: String, color: Variant = null, size: int = 15) -> Label:
	return text(content, color, size, false, true, false)


static func icon(glyph: int, color: Color, size: int = 16) -> TextureRect:
	var pixels := _s(size)
	var rect := TextureRect.new()
	rect.texture = GitHubIcons.get_icon(glyph, color, pixels)
	rect.custom_minimum_size = Vector2(pixels, pixels)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return rect


static func icon_text(glyph: int, content: String, color: Color, size: int = 15, bold: bool = false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", _s(6))
	row.add_child(icon(glyph, color, size + 1))
	row.add_child(text(content, color, size, bold))
	return row


## icon = -1 เมื่อไม่ใส่ไอคอน, icon_color = null ใช้สีตามชนิดปุ่ม
static func btn(content: String, on_pressed: Callable, kind: int = GhButtonKind.DEFAULT, glyph: int = -1,
		toggle: bool = false, icon_color: Variant = null) -> Button:
	var button := Button.new()
	button.text = content
	button.toggle_mode = toggle
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	match kind:
		GhButtonKind.PRIMARY:
			button.theme_type_variation = GitHubTheme.PRIMARY_BUTTON
		GhButtonKind.DANGER:
			button.theme_type_variation = GitHubTheme.DANGER_BUTTON
		GhButtonKind.LINK:
			button.theme_type_variation = GitHubTheme.LINK_BUTTON
		GhButtonKind.GHOST:
			button.theme_type_variation = GitHubTheme.GHOST_BUTTON

	if glyph >= 0:
		var tint: Color
		if icon_color != null:
			tint = icon_color
		else:
			match kind:
				GhButtonKind.PRIMARY:
					tint = Color.WHITE
				GhButtonKind.DANGER:
					tint = GitHubTheme.DANGER
				GhButtonKind.LINK:
					tint = GitHubTheme.ACCENT
				_:
					tint = GitHubTheme.FG_MUTED
		button.icon = GitHubIcons.get_icon(glyph, tint, _s(16)) # texture 3 เท่า ถูกจำกัดกว้างด้วย icon_max_width ใน theme

	button.pressed.connect(on_pressed)
	return button


## กล่องโค้งมีเส้นขอบ ใส่เนื้อหาตรงๆ (ช่องไฟด้านใน 16x12)
static func card(pad_h: float = 16, pad_v: float = 12) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", GitHubTheme.box(GitHubTheme.SURFACE, GitHubTheme.BORDER, 8, 1, pad_h, pad_v))
	return panel


## กล่องสำหรับรายการ: มีหัวตาราง (ถ้าใส่) และพื้นที่ใส่แถวเรียงกัน
static func box(header_content: Control = null) -> GhBox:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", GitHubTheme.box(GitHubTheme.SURFACE, GitHubTheme.BORDER))
	var body := VBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	body.add_theme_constant_override("separation", 0)
	panel.add_child(body)
	if header_content != null:
		body.add_child(header(header_content))
	return GhBox.new(panel, body)


static func header(content: Control) -> PanelContainer:
	var bar := PanelContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := GitHubTheme.underlined(GitHubTheme.SURFACE_RAISED, GitHubTheme.BORDER, 1, 16, 10)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	bar.add_theme_stylebox_override("panel", style)
	bar.add_child(content)
	return bar


## แถวในรายการ: เส้นคั่นล่าง และถ้ามี on_click จะไฮไลต์เมื่อชี้และคลิกได้ทั้งแถว
static func list_row(content: Control, last: bool = false, on_click: Callable = Callable()) -> PanelContainer:
	var row := PanelContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := func(hover: bool) -> StyleBoxFlat:
		return GitHubTheme.underlined(
				GitHubTheme.SURFACE_RAISED if hover else Color.TRANSPARENT, GitHubTheme.BORDER_MUTED,
				0 if last else 1, 16, 9)

	row.add_theme_stylebox_override("panel", style.call(false))
	if not on_click.is_null():
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row.mouse_entered.connect(func() -> void: row.add_theme_stylebox_override("panel", style.call(true)))
		row.mouse_exited.connect(func() -> void: row.add_theme_stylebox_override("panel", style.call(false)))
		row.gui_input.connect(func(input: InputEvent) -> void:
			if input is InputEventMouseButton and input.pressed and input.button_index == MOUSE_BUTTON_LEFT:
				row.accept_event()
				on_click.call())

	row.add_child(content)
	return row


static func pill(content: String, fg: Color, border: Color, bg: Variant = null, size: int = 12,
		mono: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", GitHubTheme.box(bg if bg != null else Color.TRANSPARENT, border, 12, 1, 8, 1))
	panel.add_child(text(content, fg, size, false, mono))
	return panel


## หัวข้อหน้า ตามด้วยเลขกำกับสีจาง (เช่น ชื่อ PR  #1) ตัดบรรทัดได้โดยเลขติดท้ายชื่อเสมอ
static func heading(title: String, suffix: Variant = null, size: int = 28) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.selection_enabled = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("normal_font_size", _s(size))
	label.add_theme_color_override("default_color", GitHubTheme.FG)
	var escaped := title.replace("[", "[lb]")
	label.text = escaped if suffix == null else "%s [color=#%s]%s[/color]" % [escaped, GitHubTheme.FG_MUTED.to_html(false), suffix]
	return label


## ป้ายปุ่มคีย์บอร์ดเล็กๆ เช่น Esc
static func key_hint(key: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.add_theme_stylebox_override("panel", GitHubTheme.box(GitHubTheme.SURFACE, GitHubTheme.BORDER, 6, 1, 8, 1))
	chip.add_child(text_mono(key, GitHubTheme.FG_MUTED, 13))
	return chip


## ชื่อ branch แบบพื้นฟ้าอ่อนอักษร mono เหมือนในหน้า PR
static func branch_pill(branch_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", GitHubTheme.box(GitHubTheme.ACCENT_SUBTLE, Color.TRANSPARENT, 8, 0, 7, 2))
	panel.add_child(text_mono(branch_name, GitHubTheme.ACCENT, 13))
	return panel


static func state_pill(state: int) -> PanelContainer:
	var fill: Color
	var glyph: int
	var label: String
	match state:
		PullRequestState.OPEN:
			fill = GitHubTheme.SUCCESS_EMPHASIS
			glyph = GhIcon.PULL_OPEN
			label = "Open"
		PullRequestState.MERGED:
			fill = GitHubTheme.DONE_EMPHASIS
			glyph = GhIcon.PULL_MERGED
			label = "Merged"
		_:
			fill = GitHubTheme.DANGER_EMPHASIS
			glyph = GhIcon.PULL_CLOSED
			label = "Closed"
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", GitHubTheme.box(fill, fill, 16, 0, 12, 5))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", _s(6))
	row.add_child(icon(glyph, Color.WHITE, 14))
	row.add_child(text_bold(label, Color.WHITE, 14))
	panel.add_child(row)
	return panel


static func state_icon(state: int, size: int = 16) -> TextureRect:
	match state:
		PullRequestState.OPEN:
			return icon(GhIcon.PULL_OPEN, GitHubTheme.SUCCESS, size)
		PullRequestState.MERGED:
			return icon(GhIcon.PULL_MERGED, GitHubTheme.DONE, size)
	return icon(GhIcon.PULL_CLOSED, GitHubTheme.DANGER, size)


## วงกลมสีพร้อมไอคอนขาว (สถานะในไทม์ไลน์และกล่อง merge)
static func bubble(glyph: int, fill: Color, size: int = 32) -> PanelContainer:
	var pixels := _s(size)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(pixels, pixels)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.add_theme_stylebox_override("panel", GitHubTheme.box(fill, fill, pixels / 2, 0))
	var mark := icon(glyph, Color.WHITE, size / 2)
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_child(mark)
	return panel


static func counter(number: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", GitHubTheme.box(Color(0.52, 0.56, 0.62, 0.35), Color.TRANSPARENT, 10, 0, 7, 0))
	panel.add_child(text(str(number), GitHubTheme.FG, 12))
	return panel


static func avatar(user_name: String, size: int = 24) -> PanelContainer:
	var sum := 0
	for index in user_name.length():
		sum += user_name.unicode_at(index)
	var fill := Color(AVATAR_COLORS[sum % AVATAR_COLORS.size()])
	var pixels := _s(size)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(pixels, pixels)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", GitHubTheme.box(fill, fill, pixels / 2, 0))
	var initial := text_bold(user_name.substr(0, 1).to_upper() if user_name.length() > 0 else "?", Color.WHITE, size / 2 + 1)
	initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initial.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	initial.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(initial)
	return panel


## แถบแจ้งผลหลังทำรายการ (สำเร็จ = เขียว, ผิดพลาด = แดง)
static func flash(message: String, is_error: bool) -> PanelContainer:
	var fg := GitHubTheme.DANGER if is_error else GitHubTheme.SUCCESS
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", GitHubTheme.box(
			GitHubTheme.DANGER_SUBTLE if is_error else GitHubTheme.SUCCESS_SUBTLE, Color(fg, 0.4), 8, 1, 14, 10))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_theme_constant_override("separation", _s(10))
	row.add_child(icon(GhIcon.ALERT if is_error else GhIcon.CHECK, fg))
	row.add_child(text(message, GitHubTheme.FG, 15, false, false, true))
	panel.add_child(row)
	return panel


## แถบข้อมูลสีฟ้า (คำแนะนำ ไม่ใช่ผลลัพธ์ของการกระทำ) ใส่หัวข้อตัวหนาได้
static func info(message: String, title: Variant = null) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", GitHubTheme.box(
			GitHubTheme.ACCENT_SUBTLE, Color(GitHubTheme.ACCENT, 0.5), 8, 1, 16, 12))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_theme_constant_override("separation", _s(12))
	var glyph := icon(GhIcon.INFO, GitHubTheme.ACCENT, 18)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(glyph)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", _s(2))
	if title != null:
		column.add_child(text_bold(title, GitHubTheme.FG, 16, true))
	column.add_child(text(message, GitHubTheme.FG, 15, false, false, true))
	row.add_child(column)
	panel.add_child(row)
	return panel


static func code_block(lines: Array[String]) -> PanelContainer:
	var items: Array[CodeLine] = []
	for line in lines:
		items.append(CodeLine.new(line))
	return command_block(items)


## บล็อกคำสั่งสีเข้มเหมือนหน้าต่าง terminal: ย้อมสีส่วนต่างของคำสั่ง ใส่คำอธิบายสั้นๆ ข้างบรรทัดได้
## และคลิกทั้งแถวเพื่อคัดลอกทีละบรรทัด (terminal ของเกมรับคำสั่งทีละบรรทัด)
static func command_block(items: Array[CodeLine]) -> PanelContainer:
	var command_width := 0.0
	if items.any(func(item: CodeLine) -> bool: return item.hint != null):
		var widest := 0.0
		for item in items:
			widest = maxf(widest, GitHubTheme.mono_font().get_string_size(item.command, HORIZONTAL_ALIGNMENT_LEFT, -1, _s(15)).x)
		command_width = widest * 1.04 + _s(6)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", GitHubTheme.box(GitHubTheme.INSET, GitHubTheme.BORDER, 8, 1, 6, 6))
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	column.add_theme_constant_override("separation", _s(2))
	for item in items:
		column.add_child(_command_row(item, command_width))
	panel.add_child(column)
	return panel


static func _command_row(line: CodeLine, command_width: float) -> Control:
	var row := PanelContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.tooltip_text = "คลิกเพื่อคัดลอกคำสั่งนี้"
	var style := func(hover: bool) -> StyleBoxFlat:
		return GitHubTheme.box(Color(1.0, 1.0, 1.0, 0.07) if hover else Color.TRANSPARENT, Color.TRANSPARENT, 6, 0, 10, 6)
	row.add_theme_stylebox_override("panel", style.call(false))

	var cells := HBoxContainer.new()
	cells.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cells.add_theme_constant_override("separation", _s(12))

	var prompt := text_mono("$", GitHubTheme.FG_SUBTLE, 15)
	prompt.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	cells.add_child(prompt)

	var command := _highlight(line.command)
	if command_width > 0.0:
		command.custom_minimum_size = Vector2(command_width, 0)
		command.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	cells.add_child(command)

	# คำอธิบายข้างบรรทัด ใช้ช่องเดียวกันแสดง "คัดลอกแล้ว" ชั่วคราว เพื่อไม่ให้แถวขยับ
	var hint_text: String = line.hint if line.hint != null else ""
	var note := text(hint_text, GitHubTheme.FG_MUTED, 14, false, false, line.hint != null)
	note.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if line.hint == null:
		note.size_flags_horizontal = Control.SIZE_SHRINK_END
	cells.add_child(note)

	var copy_icon := icon(GhIcon.COPY, GitHubTheme.FG_SUBTLE)
	copy_icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	cells.add_child(copy_icon)
	row.add_child(cells)

	var show_copy_icon := func(color: Color) -> void:
		copy_icon.texture = GitHubIcons.get_icon(GhIcon.COPY, color, _s(16))
	row.mouse_entered.connect(func() -> void:
		row.add_theme_stylebox_override("panel", style.call(true))
		show_copy_icon.call(GitHubTheme.FG))
	row.mouse_exited.connect(func() -> void:
		row.add_theme_stylebox_override("panel", style.call(false))
		show_copy_icon.call(GitHubTheme.FG_SUBTLE))
	row.gui_input.connect(func(input: InputEvent) -> void:
		if not (input is InputEventMouseButton and input.pressed and input.button_index == MOUSE_BUTTON_LEFT):
			return
		row.accept_event()
		DisplayServer.clipboard_set(line.command)
		note.text = "คัดลอกแล้ว"
		note.add_theme_color_override("font_color", GitHubTheme.SUCCESS)
		copy_icon.texture = GitHubIcons.get_icon(GhIcon.CHECK, GitHubTheme.SUCCESS, _s(16))
		row.get_tree().create_timer(1.4).timeout.connect(func() -> void:
			if not is_instance_valid(row):
				return
			note.text = hint_text
			note.add_theme_color_override("font_color", GitHubTheme.FG_MUTED)
			show_copy_icon.call(GitHubTheme.FG_SUBTLE)))
	return row


static func _highlight(command: String) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.selection_enabled = false
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("normal_font", GitHubTheme.mono_font())
	label.add_theme_font_override("bold_font", GitHubTheme.mono_bold_font())
	label.add_theme_font_size_override("normal_font_size", _s(15))
	label.add_theme_font_size_override("bold_font_size", _s(15))
	label.add_theme_color_override("default_color", GitHubTheme.FG)
	label.text = _command_to_bbcode(command)
	return label


## ย้อมสีคำสั่ง: ชื่อคำสั่ง (git / write ของเกม) ตัวหนา, คำสั่งย่อยของ git สีเขียว, flag สีส้ม,
## ข้อความในเครื่องหมายคำพูดสีฟ้าอ่อน, URL และชื่อไฟล์สีฟ้า
static func _command_to_bbcode(command: String) -> String:
	var tokens := _tokenize(command)
	var parts: PackedStringArray = []
	for index in tokens.size():
		var token := tokens[index]
		var bold := false
		var color: Variant = null

		if index == 0:
			bold = true
			if token == "write":
				color = GitHubTheme.SYNTAX_GAME
		elif tokens[0] == "write":
			color = GitHubTheme.SYNTAX_PATH if index == 1 else GitHubTheme.SYNTAX_STRING
		elif token.begins_with("-"):
			color = GitHubTheme.SYNTAX_FLAG
		elif tokens[0] == "git" and index == 1:
			color = GitHubTheme.SYNTAX_SUBCOMMAND
			bold = true
		elif token.begins_with("\"") or token.begins_with("'"):
			color = GitHubTheme.SYNTAX_STRING
		elif token.contains("://"):
			color = GitHubTheme.SYNTAX_PATH

		var shown := token.replace("[", "[lb]")
		if bold:
			shown = "[b]%s[/b]" % shown
		if color != null:
			shown = "[color=#%s]%s[/color]" % [(color as Color).to_html(false), shown]
		parts.append(shown)
	return " ".join(parts)


static func _tokenize(command: String) -> Array[String]:
	var tokens: Array[String] = []
	var current := ""
	var quote := ""
	for index in command.length():
		var character := command[index]
		if quote != "":
			current += character
			if character == quote:
				quote = ""
		elif character == "\"" or character == "'":
			quote = character
			current += character
		elif character.strip_edges().is_empty():
			if current.is_empty():
				continue
			tokens.append(current)
			current = ""
		else:
			current += character

	if not current.is_empty():
		tokens.append(current)
	return tokens


## วงกลมสีฟ้าใส่เลขขั้นตอน
static func number_bubble(number: int, size: int = 30) -> PanelContainer:
	var pixels := _s(size)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(pixels, pixels)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", GitHubTheme.box(GitHubTheme.ACCENT_EMPHASIS, GitHubTheme.ACCENT_EMPHASIS, pixels / 2, 0))
	var label := text_bold(str(number), Color.WHITE, 15)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(label)
	return panel


## การ์ดขั้นตอน: เลขวงกลม หัวข้อ คำอธิบายสั้นๆ ชิดขวา ตามด้วยเนื้อหา (เช่น บล็อกคำสั่ง)
static func step(number: int, title: String, hint: Variant, body: Control) -> PanelContainer:
	var panel := card(20, 16)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	column.add_theme_constant_override("separation", _s(12))

	var header_row := HBoxContainer.new()
	header_row.mouse_filter = Control.MOUSE_FILTER_PASS
	header_row.add_theme_constant_override("separation", _s(12))
	header_row.add_child(number_bubble(number))
	header_row.add_child(text_bold(title, GitHubTheme.FG, 18))
	if hint != null:
		header_row.add_child(spacer())
		header_row.add_child(text(hint, GitHubTheme.FG_MUTED, 14))

	column.add_child(header_row)
	column.add_child(body)
	panel.add_child(column)
	return panel


static func empty_state(glyph: int, title: String, hint: String) -> Control:
	var parts := box()
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", _s(10))
	var mark := icon(glyph, GitHubTheme.FG_MUTED, 32)
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(mark)
	var title_label := text_bold(title, GitHubTheme.FG, 20)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(title_label)
	var detail := text(hint, GitHubTheme.FG_MUTED, 15, false, false, true)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(detail)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_top", _s(40))
	margin.add_theme_constant_override("margin_bottom", _s(40))
	margin.add_theme_constant_override("margin_left", _s(24))
	margin.add_theme_constant_override("margin_right", _s(24))
	margin.add_child(column)
	parts.body.add_child(margin)
	return parts.panel


## ใส่รายชื่อ branch ลงตัวเลือก (ไอคอน branch หน้าชื่อ) เลือก selected ไว้ และแจ้งชื่อเมื่อเปลี่ยน
## ปุ่มกว้างพอดีชื่อ branch ที่เลือก ไม่ใช่ชื่อที่ยาวที่สุดในรายการ และไม่เกิน branch_picker_max_width
static func fill_branch_picker(picker: OptionButton, branches: Array[RemoteBranchInfo], on_selected: Callable,
		selected: String) -> void:
	picker.fit_to_longest_item = false
	var branch_icon := GitHubIcons.get_icon(GhIcon.BRANCH, GitHubTheme.FG_MUTED, _s(16))
	for index in branches.size():
		picker.add_icon_item(branch_icon, branches[index].name, index)
		if branches[index].name == selected:
			picker.selected = index

	# วัดความกว้างได้ถูกต้องก็ต่อเมื่ออยู่ใน tree (ธีมของ GitHub มาจากโหนดแม่) ผู้เรียกบางที่ยังไม่ได้ add_child
	if picker.is_inside_tree():
		_fit_branch_picker(picker)
	else:
		picker.tree_entered.connect(func() -> void:
			if is_instance_valid(picker):
				_fit_branch_picker(picker), CONNECT_ONE_SHOT | CONNECT_DEFERRED)

	picker.item_selected.connect(func(index: int) -> void:
		_fit_branch_picker(picker)
		on_selected.call(branches[index].name))


static func _fit_branch_picker(picker: OptionButton) -> void:
	picker.clip_text = false
	picker.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	picker.custom_minimum_size = Vector2.ZERO
	picker.tooltip_text = ""
	if picker.get_combined_minimum_size().x <= branch_picker_max_width():
		return

	picker.clip_text = true
	picker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	picker.custom_minimum_size = Vector2(branch_picker_max_width(), 0)
	picker.tooltip_text = picker.get_item_text(picker.selected)


## แท็บแบบ GitHub: ขีดส้มใต้แท็บที่เลือก มีไอคอนและตัวเลขนับได้ (glyph / count = -1 เมื่อไม่ใส่)
static func tab(content: String, active: bool, on_click: Callable, glyph: int = -1, count: int = -1) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style := func(hover: bool) -> StyleBoxFlat:
		return GitHubTheme.underlined(
				Color(1.0, 1.0, 1.0, 0.05) if hover and not active else Color.TRANSPARENT,
				GitHubTheme.TAB_UNDERLINE if active else Color.TRANSPARENT, 2, 12, 8)

	panel.add_theme_stylebox_override("panel", style.call(false))
	panel.mouse_entered.connect(func() -> void: panel.add_theme_stylebox_override("panel", style.call(true)))
	panel.mouse_exited.connect(func() -> void: panel.add_theme_stylebox_override("panel", style.call(false)))
	panel.gui_input.connect(func(input: InputEvent) -> void:
		if input is InputEventMouseButton and input.pressed and input.button_index == MOUSE_BUTTON_LEFT:
			panel.accept_event()
			on_click.call())

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", _s(8))
	if glyph >= 0:
		row.add_child(icon(glyph, GitHubTheme.FG if active else GitHubTheme.FG_MUTED))
	row.add_child(text(content, GitHubTheme.FG, 15, active))
	if count >= 0:
		row.add_child(GitHubUi.counter(count))
	panel.add_child(row)
	return panel


## แสดงโค้ดทีละบรรทัดพร้อมเลขบรรทัด (หน้าเปิดไฟล์) จำกัดจำนวนบรรทัดเพื่อไม่ให้หน้าหนัก
static func code_lines(lines: PackedStringArray, max_lines: int = 500) -> Control:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 0)
	for index in mini(lines.size(), max_lines):
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_theme_constant_override("separation", _s(16))
		var number := text_mono(str(index + 1), GitHubTheme.FG_SUBTLE, 13)
		number.custom_minimum_size = Vector2(_s(48), 0)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(number)
		var code := text_mono(lines[index], GitHubTheme.FG, 14)
		code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		code.clip_text = true
		row.add_child(code)
		column.add_child(row)

	if lines.size() > max_lines:
		column.add_child(text("… ไฟล์ยาว %d บรรทัด แสดงเฉพาะ %d บรรทัดแรก" % [lines.size(), max_lines], GitHubTheme.FG_MUTED, 14))
	return column


static func time_ago(when: float) -> String:
	return GitTime.time_ago(when)


static func date_label(when: float) -> String:
	return GitTime.date_label(when)


## เอกพจน์/พหูพจน์แบบ GitHub เช่น "1 Commit" / "2 Commits"
static func count(number: int, singular: String, plural: String) -> String:
	return "%d %s" % [number, singular if number == 1 else plural]
