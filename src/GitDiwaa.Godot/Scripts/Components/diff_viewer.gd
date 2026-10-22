class_name DiffViewer
extends RefCounted
## แสดง unified diff แบบหน้า "Files changed" ของ GitHub: การ์ดต่อไฟล์ (พับได้),
## เลขบรรทัดเก่า/ใหม่ และสีเขียว/แดงที่บรรทัดที่เพิ่ม/ลบ

enum Kind { HUNK, ADD, REMOVE, CONTEXT, NOTE }

## เลขบรรทัดที่ไม่มี (บรรทัด hunk / note)
const NO_NUMBER := -1

static var _hunk_header: RegEx


class DiffLine extends RefCounted:
	var kind: int = DiffViewer.Kind.CONTEXT
	var old_number: int = DiffViewer.NO_NUMBER
	var new_number: int = DiffViewer.NO_NUMBER
	var text: String = ""

	func _init(p_kind: int, p_old: int, p_new: int, p_text: String) -> void:
		kind = p_kind
		old_number = p_old
		new_number = p_new
		text = p_text


class FileDiff extends RefCounted:
	var path: String = ""
	var lines: Array[DiffLine] = []


static func _s(pixels: float) -> int:
	return GitHubTheme.s(pixels)


static func build(diff: String, stats: Array[PullRequestFileChange], comments: DiffCommentContext = null) -> Control:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", _s(16))
	for file in _parse(diff):
		var stat: PullRequestFileChange = null
		for item in stats:
			if item.path == file.path:
				stat = item
				break
		column.add_child(_file_card(file, stat, comments))
	return column


static func _parse(diff: String) -> Array[FileDiff]:
	if _hunk_header == null:
		_hunk_header = RegEx.new()
		_hunk_header.compile("^@@ -(\\d+)(?:,\\d+)? \\+(\\d+)(?:,\\d+)? @@")

	var files: Array[FileDiff] = []
	var current: FileDiff = null
	var old_path := ""
	var has_old_path := false
	var in_hunk := false
	var old_number := 0
	var new_number := 0

	for raw in diff.split("\n"):
		if raw.begins_with("diff --git "):
			var split := raw.rfind(" b/")
			current = FileDiff.new()
			current.path = raw.substr(split + 3) if split >= 0 else raw.substr(11)
			files.append(current)
			has_old_path = false
			in_hunk = false
			continue

		if current == null:
			continue

		if raw.begins_with("@@"):
			var found := _hunk_header.search(raw)
			if found != null:
				old_number = found.get_string(1).to_int()
				new_number = found.get_string(2).to_int()
			in_hunk = true
			current.lines.append(DiffLine.new(Kind.HUNK, NO_NUMBER, NO_NUMBER, raw))
			continue

		if not in_hunk:
			if raw.begins_with("--- a/"):
				old_path = raw.substr(6)
				has_old_path = true
			elif raw.begins_with("+++ b/"):
				current.path = raw.substr(6)
			elif raw.begins_with("+++ /dev/null") and has_old_path:
				current.path = old_path
			elif raw.begins_with("Binary files"):
				current.lines.append(DiffLine.new(Kind.NOTE, NO_NUMBER, NO_NUMBER, raw))
			continue

		if raw.begins_with("+"):
			current.lines.append(DiffLine.new(Kind.ADD, NO_NUMBER, new_number, raw.substr(1)))
			new_number += 1
		elif raw.begins_with("-"):
			current.lines.append(DiffLine.new(Kind.REMOVE, old_number, NO_NUMBER, raw.substr(1)))
			old_number += 1
		elif raw.begins_with(" "):
			current.lines.append(DiffLine.new(Kind.CONTEXT, old_number, new_number, raw.substr(1)))
			old_number += 1
			new_number += 1
		elif raw.length() > 0:
			current.lines.append(DiffLine.new(Kind.NOTE, NO_NUMBER, NO_NUMBER, raw))

	return files


static func _file_card(file: FileDiff, stat: PullRequestFileChange, comments: DiffCommentContext) -> Control:
	var chevron := GitHubUi.icon(GhIcon.CHEVRON_DOWN, GitHubTheme.FG_MUTED)
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override("separation", _s(10))
	header.add_child(chevron)
	var name_label := GitHubUi.text_mono(file.path, GitHubTheme.FG, 14)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	if stat != null:
		header.add_child(GitHubUi.text_bold("+%d" % stat.additions, GitHubTheme.SUCCESS, 13))
		header.add_child(GitHubUi.text_bold("−%d" % stat.deletions, GitHubTheme.DANGER, 13))

	var parts := GitHubUi.box(header)
	var lines := VBoxContainer.new()
	lines.mouse_filter = Control.MOUSE_FILTER_PASS
	lines.add_theme_constant_override("separation", 0)
	for line in file.lines:
		lines.add_child(_line_block(file.path, line, comments))
	parts.body.add_child(lines)

	# คลิกหัวการ์ดเพื่อพับ/ขยายไฟล์
	var header_panel := parts.body.get_child(0) as PanelContainer
	header_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	header_panel.gui_input.connect(func(input: InputEvent) -> void:
		if not (input is InputEventMouseButton and input.pressed and input.button_index == MOUSE_BUTTON_LEFT):
			return
		header_panel.accept_event()
		lines.visible = not lines.visible
		chevron.texture = GitHubIcons.get_icon(
				GhIcon.CHEVRON_DOWN if lines.visible else GhIcon.CHEVRON_RIGHT, GitHubTheme.FG_MUTED, _s(16)))
	return parts.panel


## หนึ่งบรรทัดของ diff + ความเห็นใต้บรรทัด + กล่องเขียนความเห็น (เปิดจากปุ่ม + ตอนชี้เมาส์)
static func _line_block(path: String, line: DiffLine, comments: DiffCommentContext) -> Control:
	var block := VBoxContainer.new()
	block.mouse_filter = Control.MOUSE_FILTER_PASS
	block.add_theme_constant_override("separation", 0)

	var editor_slot := VBoxContainer.new()
	var commentable := comments != null and not comments.submit.is_null() \
			and (line.kind == Kind.ADD or line.kind == Kind.REMOVE or line.kind == Kind.CONTEXT)
	var number := line.old_number if line.kind == Kind.REMOVE else line.new_number
	var on_new_side := line.kind != Kind.REMOVE
	var open_editor := Callable()
	if commentable and number != NO_NUMBER:
		open_editor = func() -> void:
			if editor_slot.get_child_count() > 0:
				return
			var close := func() -> void:
				for child in editor_slot.get_children():
					editor_slot.remove_child(child)
					child.queue_free()
			editor_slot.add_child(CommentEditor.create(path, number, on_new_side, comments, close))

	block.add_child(_line_row(line, open_editor))

	if comments != null and number != NO_NUMBER:
		for comment in comments.comments:
			if comment.path == path and comment.line == number and comment.on_new_side == on_new_side \
					and (not comment.is_pending or comment.author.to_lower() == comments.viewer.to_lower()):
				block.add_child(_inline_comment(comment))

	block.add_child(editor_slot)
	return block


static func _indented(child: Control) -> Control:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", _s(84))
	margin.add_theme_constant_override("margin_right", _s(16))
	margin.add_theme_constant_override("margin_top", _s(8))
	margin.add_theme_constant_override("margin_bottom", _s(10))
	margin.add_child(child)
	return margin


static func _inline_comment(comment: PullRequestLineComment) -> Control:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", _s(8))
	header.add_child(GitHubUi.avatar(comment.author, 22))
	header.add_child(GitHubUi.text_bold(comment.author, GitHubTheme.FG, 14))
	header.add_child(GitHubUi.text("commented %s" % GitHubUi.time_ago(comment.at), GitHubTheme.FG_MUTED, 13))
	if comment.is_pending:
		header.add_child(GitHubUi.pill("Pending", GitHubTheme.ATTENTION, Color(GitHubTheme.ATTENTION, 0.55), null, 12))
	var parts := GitHubUi.box(header)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", _s(14))
	margin.add_theme_constant_override("margin_right", _s(14))
	margin.add_theme_constant_override("margin_top", _s(10))
	margin.add_theme_constant_override("margin_bottom", _s(12))
	margin.add_child(MarkdownView.render(comment.body))
	parts.body.add_child(margin)
	return _indented(parts.panel)


## กล่อง "Add a comment on line R47": Write / Preview + Cancel / Comment / Start a review
class CommentEditor extends VBoxContainer:
	var _path: String
	var _line: int
	var _on_new_side: bool
	var _comments: DiffCommentContext
	var _tabs: HBoxContainer
	var _input: TextEdit
	var _preview: MarginContainer
	var _single: Button
	var _review: Button

	static func create(path: String, line: int, on_new_side: bool, comments: DiffCommentContext,
			close: Callable) -> Control:
		var editor := CommentEditor.new()
		editor._build(path, line, on_new_side, comments, close)
		return DiffViewer._indented(editor._card)

	var _card: PanelContainer

	func _build(path: String, line: int, on_new_side: bool, comments: DiffCommentContext, close: Callable) -> void:
		_path = path
		_line = line
		_on_new_side = on_new_side
		_comments = comments

		_card = GitHubUi.card(16, 14)
		add_theme_constant_override("separation", DiffViewer._s(10))

		var title := HBoxContainer.new()
		title.add_theme_constant_override("separation", DiffViewer._s(10))
		title.add_child(GitHubUi.avatar(comments.viewer, 28))
		title.add_child(GitHubUi.text_bold("Add a comment on line %s%d" % ["R" if on_new_side else "L", line], GitHubTheme.FG, 16))
		add_child(title)

		_input = TextEdit.new()
		_input.placeholder_text = "Leave a comment"
		_input.custom_minimum_size = Vector2(0, DiffViewer._s(110))
		_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		_preview = MarginContainer.new()
		_preview.visible = false
		_preview.custom_minimum_size = Vector2(0, DiffViewer._s(110))

		_tabs = HBoxContainer.new()
		_tabs.add_theme_constant_override("separation", DiffViewer._s(4))
		_show_tabs(false)
		add_child(_tabs)
		add_child(_input)
		add_child(_preview)

		var buttons := HBoxContainer.new()
		buttons.add_theme_constant_override("separation", DiffViewer._s(10))
		buttons.add_child(GitHubUi.spacer())
		buttons.add_child(GitHubUi.btn("Cancel", close))
		_single = GitHubUi.btn("Comment", func() -> void: comments.submit.call(path, line, on_new_side, _input.text, false),
				GhButtonKind.DEFAULT, GhIcon.COMMENT)
		_review = GitHubUi.btn("Add review comment" if comments.has_pending_review else "Start a review",
				func() -> void: comments.submit.call(path, line, on_new_side, _input.text, true), GhButtonKind.PRIMARY)
		# ถ้ามี pending review อยู่แล้ว GitHub ให้เพิ่มเข้า review เดิมเท่านั้น ไม่มีปุ่ม Comment เดี่ยว
		if not comments.has_pending_review:
			buttons.add_child(_single)
		buttons.add_child(_review)
		add_child(buttons)

		_input.text_changed.connect(_sync)
		_sync()
		_card.add_child(self)

	func _show_tabs(previewing: bool) -> void:
		for child in _tabs.get_children():
			_tabs.remove_child(child)
			child.queue_free()

		_tabs.add_child(GitHubUi.tab("Write", not previewing, func() -> void: _show_tabs(false)))
		_tabs.add_child(GitHubUi.tab("Preview", previewing, func() -> void: _show_tabs(true)))
		_input.visible = not previewing
		_preview.visible = previewing
		if not previewing:
			return
		for child in _preview.get_children():
			_preview.remove_child(child)
			child.queue_free()

		_preview.add_child(GitHubUi.text("Nothing to preview", GitHubTheme.FG_MUTED) if _input.text.strip_edges().is_empty()
				else MarkdownView.render(_input.text))

	func _sync() -> void:
		var empty := _input.text.strip_edges().is_empty()
		_single.disabled = empty
		_review.disabled = empty


static func _line_row(line: DiffLine, on_add_comment: Callable) -> Control:
	var background := Color.TRANSPARENT
	var gutter := Color.TRANSPARENT
	match line.kind:
		Kind.ADD:
			background = GitHubTheme.DIFF_ADD
			gutter = GitHubTheme.DIFF_ADD_GUTTER
		Kind.REMOVE:
			background = GitHubTheme.DIFF_REMOVE
			gutter = GitHubTheme.DIFF_REMOVE_GUTTER
		Kind.HUNK:
			background = GitHubTheme.DIFF_HUNK
			gutter = GitHubTheme.DIFF_HUNK

	var row := PanelContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.content_margin_left = 0
	style.content_margin_right = _s(12)
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	row.add_theme_stylebox_override("panel", style)

	var cells := HBoxContainer.new()
	cells.mouse_filter = Control.MOUSE_FILTER_PASS
	cells.add_theme_constant_override("separation", 0)
	if line.kind == Kind.HUNK or line.kind == Kind.NOTE:
		cells.add_child(_gutter(NO_NUMBER, gutter))
		cells.add_child(_gutter(NO_NUMBER, gutter))
		var note := GitHubUi.text_mono(line.text, GitHubTheme.FG_MUTED, 13)
		note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		note.clip_text = true
		cells.add_child(_pad(note, 10))
	else:
		cells.add_child(_gutter(line.old_number, gutter))
		cells.add_child(_gutter(line.new_number, gutter))
		cells.add_child(_add_comment_cell(row, on_add_comment))
		var sign := " "
		var sign_color := GitHubTheme.FG_MUTED
		if line.kind == Kind.ADD:
			sign = "+"
			sign_color = GitHubTheme.SUCCESS
		elif line.kind == Kind.REMOVE:
			sign = "−"
			sign_color = GitHubTheme.DANGER
		var mark := GitHubUi.text_mono(sign, sign_color, 14)
		mark.custom_minimum_size = Vector2(_s(24), 0)
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cells.add_child(mark)
		var code := GitHubUi.text_mono(line.text, GitHubTheme.FG, 14)
		code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		code.clip_text = true
		cells.add_child(code)

	row.add_child(cells)
	return row


## ช่องปุ่ม + สำหรับเขียนความเห็น: เห็นเฉพาะตอนชี้เมาส์ที่บรรทัด (ช่องกว้างคงที่เพื่อไม่ให้โค้ดขยับ)
static func _add_comment_cell(row: Control, on_add_comment: Callable) -> Control:
	var cell := Control.new()
	cell.mouse_filter = Control.MOUSE_FILTER_PASS
	cell.custom_minimum_size = Vector2(_s(30), 0)
	if on_add_comment.is_null():
		return cell

	var plus := GitHubUi.btn("+", on_add_comment, GhButtonKind.PRIMARY)
	plus.custom_minimum_size = Vector2(_s(22), _s(22))
	plus.tooltip_text = "เพิ่มความเห็นที่บรรทัดนี้"
	plus.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	plus.visible = false
	cell.add_child(plus)
	row.mouse_entered.connect(func() -> void: plus.visible = true)
	# ปุ่มเป็น child ที่รับเมาส์ ทำให้ row ยิง mouse_exited ตอนเมาส์เข้าปุ่ม จึงซ่อนเฉพาะเมื่อเมาส์ออกนอกแถวจริง
	row.mouse_exited.connect(func() -> void:
		plus.visible = row.get_global_rect().has_point(row.get_global_mouse_position()))
	return cell


## คอลัมน์เลขบรรทัด (พื้นเข้มกว่าที่บรรทัดเพิ่ม/ลบ)
static func _gutter(number: int, background: Color) -> Control:
	var cell := PanelContainer.new()
	cell.mouse_filter = Control.MOUSE_FILTER_PASS
	cell.custom_minimum_size = Vector2(_s(56), 0)
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.content_margin_left = _s(4)
	style.content_margin_right = _s(10)
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	cell.add_theme_stylebox_override("panel", style)
	var label := GitHubUi.text_mono("" if number == NO_NUMBER else str(number), GitHubTheme.FG_SUBTLE, 13)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cell.add_child(label)
	return cell


static func _pad(child: Control, left: int) -> Control:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", left)
	margin.add_child(child)
	return margin
