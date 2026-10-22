class_name MarkdownView
extends RefCounted
## แสดง Markdown พื้นฐานแบบ GitHub: หัวข้อ (# ## ###), ย่อหน้า, รายการ (- *), บล็อกโค้ด (```),
## ตัวหนา (**) และโค้ดในบรรทัด (`) ข้อความที่ไม่รู้จักแสดงเป็นข้อความธรรมดา

static var _bold: RegEx


static func _s(pixels: float) -> int:
	return GitHubTheme.s(pixels)


static func render(markdown: String) -> Control:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", _s(12))

	var paragraph: Array[String] = []
	var code: Array[String] = []
	var in_code := false

	for raw in markdown.replace("\r\n", "\n").split("\n"):
		var line := raw.strip_edges(false, true)
		if line.begins_with("```"):
			if in_code:
				column.add_child(_code_box(code))
				code.clear()
				in_code = false
			else:
				_flush_paragraph(column, paragraph)
				in_code = true
			continue

		if in_code:
			code.append(raw)
			continue

		if line.is_empty():
			_flush_paragraph(column, paragraph)
			continue

		var level := _heading_level(line)
		if level > 0:
			_flush_paragraph(column, paragraph)
			column.add_child(_heading(line.substr(level + 1).strip_edges(), level))
			continue

		if line.begins_with("- ") or line.begins_with("* "):
			_flush_paragraph(column, paragraph)
			column.add_child(_bullet(line.substr(2).strip_edges()))
			continue

		paragraph.append(line.strip_edges())

	if in_code and not code.is_empty():
		column.add_child(_code_box(code))
	_flush_paragraph(column, paragraph)
	return column


static func _flush_paragraph(column: VBoxContainer, paragraph: Array[String]) -> void:
	if paragraph.is_empty():
		return
	column.add_child(_inline(" ".join(paragraph)))
	paragraph.clear()


static func _heading_level(line: String) -> int:
	var level := 0
	while level < line.length() and level < 3 and line[level] == "#":
		level += 1
	return level if level > 0 and level < line.length() and line[level] == " " else 0


static func _heading(content: String, level: int) -> Control:
	var size := 28 if level == 1 else (22 if level == 2 else 18)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	column.add_theme_constant_override("separation", _s(8))
	column.add_child(GitHubUi.text_bold(content, GitHubTheme.FG, size, true))
	if level <= 2:
		column.add_child(HSeparator.new())
	return column


static func _bullet(content: String) -> Control:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_theme_constant_override("separation", _s(10))
	var dot := GitHubUi.text("•", GitHubTheme.FG_MUTED)
	dot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(dot)
	row.add_child(_inline(content))
	return row


static func _code_box(lines: Array[String]) -> Control:
	var panel := GitHubUi.card(14, 10)
	panel.add_theme_stylebox_override("panel", GitHubTheme.box(GitHubTheme.INSET, GitHubTheme.BORDER, 8, 1, 14, 10))
	var label := RichTextLabel.new()
	label.text = "\n".join(lines)
	label.fit_content = true
	label.scroll_active = false
	label.selection_enabled = true
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_override("normal_font", GitHubTheme.mono_font())
	label.add_theme_font_size_override("normal_font_size", _s(14))
	label.add_theme_color_override("default_color", GitHubTheme.FG)
	panel.add_child(label)
	return panel


static func _inline(content: String) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.selection_enabled = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("bold_font", GitHubTheme.bold_font())
	label.add_theme_font_override("mono_font", GitHubTheme.mono_font())
	label.add_theme_font_size_override("normal_font_size", _s(15))
	label.add_theme_font_size_override("bold_font_size", _s(15))
	label.add_theme_font_size_override("mono_font_size", _s(14))
	label.add_theme_color_override("default_color", GitHubTheme.FG)
	label.text = _to_bbcode(content)
	return label


static func _to_bbcode(content: String) -> String:
	if _bold == null:
		_bold = RegEx.new()
		_bold.compile("\\*\\*(.+?)\\*\\*")

	var parts := content.split("`")
	if parts.size() % 2 == 0:
		parts = PackedStringArray([content]) # backtick ไม่ครบคู่ ไม่ตีความเป็นโค้ด

	var builder := ""
	for index in parts.size():
		var segment := parts[index].replace("[", "[lb]")
		if parts.size() > 1 and index % 2 == 1:
			builder += "[bgcolor=#6e768133][code] " + segment + " [/code][/bgcolor]"
		else:
			builder += _bold.sub(segment, "[b]$1[/b]", true)
	return builder
