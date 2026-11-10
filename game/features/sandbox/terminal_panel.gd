class_name TerminalPanel
extends PanelContainer
## Reusable OOP Terminal Component for Godot.
## Matches the authentic Git-Diwaa Checkpoint-01 visual style and behaviors.

signal command_submitted(command: String)

const THAI_LOG_FONT_PATH := "res://assets/fonts/ChakraPetch-Regular.ttf"
const THAI_LOG_FONT_SIZE := 20

@export var window_title: String = "●  ●  ●    TERMINAL — learner@diwaa:~/checkpoint-01"
@export var prompt_prefix: String = "learner@diwaa:~ $"

var _title_label: Label
var _hint_label: Label
var _output_log: RichTextLabel
var _prompt_label: Label
var _input_edit: LineEdit
var _enter_button: Button
var _commit_dialog: ConfirmationDialog
var _commit_input: LineEdit
var _thai_log_font: Font

var _command_history: Array[String] = []
var _history_index := 0
var _is_executing := false


func _ready() -> void:
	_thai_log_font = load(THAI_LOG_FONT_PATH) as Font
	_title_label = get_node("%TitleLabel")
	_hint_label = get_node("%HintLabel")
	_output_log = get_node("%OutputLog")
	_prompt_label = get_node("%PromptLabel")
	_input_edit = get_node("%InputEdit")
	_enter_button = get_node("%EnterButton")
	_commit_dialog = get_node("%CommitDialog")
	_commit_input = get_node("%CommitInput")

	_title_label.text = window_title
	_prompt_label.text = prompt_prefix

	_input_edit.text_submitted.connect(func(_text: String) -> void: _submit_from_input())
	_enter_button.pressed.connect(_submit_from_input)
	_input_edit.gui_input.connect(_on_input_gui_input)
	_output_log.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_input_edit.grab_focus()
	)

	DialogStyle.apply(_commit_dialog, DialogStyle.SUCCESS, "✓", "Commit message", false, _commit_input)
	_commit_dialog.size = Vector2i(780, 100)
	_commit_input.placeholder_text = "กรอกข้อความอธิบาย Commit เช่น add player profile"
	_commit_dialog.confirmed.connect(_on_commit_dialog_confirmed)
	_commit_input.text_changed.connect(
			func(text: String) -> void: _commit_dialog.get_ok_button().disabled = text.strip_edges().is_empty())
	_commit_dialog.about_to_popup.connect(func() -> void: _commit_input.grab_focus.call_deferred())

	_input_edit.grab_focus()


func _submit_from_input() -> void:
	if _is_executing:
		return

	var command := _input_edit.text.strip_edges()
	if command.is_empty():
		return

	_input_edit.clear()

	if _command_history.is_empty() or _command_history[-1] != command:
		_command_history.append(command)
	_history_index = _command_history.size()

	if command == "git commit":
		_commit_input.clear()
		_commit_dialog.get_ok_button().disabled = true
		_commit_dialog.popup_centered()
		return

	submit_command(command)


func _on_commit_dialog_confirmed() -> void:
	var message := _commit_input.text.strip_edges()
	if message.is_empty():
		append_error("Commit message cannot be empty.")
		return
	submit_command("git commit -m \"%s\"" % message.replace("\\", "\\\\").replace("\"", "\\\""))


func submit_command(command: String) -> void:
	append_command(command)

	if command.to_lower() == "clear":
		clear_output()
		return

	command_submitted.emit(command)


func _on_input_gui_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not _command_history.is_empty()):
		return

	if event.keycode == KEY_UP:
		_history_index = clampi(_history_index - 1, 0, _command_history.size())
		_show_history_entry()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_DOWN:
		_history_index = clampi(_history_index + 1, 0, _command_history.size())
		_show_history_entry()
		get_viewport().set_input_as_handled()


func _show_history_entry() -> void:
	_input_edit.text = _command_history[_history_index] if _history_index < _command_history.size() else ""
	_input_edit.caret_column = _input_edit.text.length()


func append_command(command: String) -> void:
	_append_styled_text("\n%s %s\n" % [prompt_prefix, command])
	_scroll_to_bottom()


func append_output(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	_append_styled_text(text.strip_edges(false, true) + "\n")
	_scroll_to_bottom()


func append_error(error: String) -> void:
	if error.strip_edges().is_empty():
		return
	_append_styled_text("[Error] " + error.strip_edges(false, true) + "\n")
	_scroll_to_bottom()


func append_info(info: String) -> void:
	if info.strip_edges().is_empty():
		return
	_append_styled_text(info.strip_edges(false, true) + "\n")
	_scroll_to_bottom()


func _append_styled_text(text: String) -> void:
	if _thai_log_font == null or _is_pure_ascii(text):
		_output_log.add_text(text)
		return
	var lines := text.split("\n", true)
	for i in lines.size():
		if i > 0:
			_output_log.add_text("\n")
		if not lines[i].is_empty():
			_append_styled_line(lines[i])


func _append_styled_line(line: String) -> void:
	var n := line.length()
	var thai_mask := PackedByteArray()
	thai_mask.resize(n)
	for i in n:
		thai_mask[i] = 1 if line.unicode_at(i) > 0x7F else 0

	# Attach sentence punctuation/spaces surrounding Thai text so Thai phrases keep consistent ChakraPetch sizing.
	for i in n:
		if thai_mask[i] != 0:
			continue
		var cp := line.unicode_at(i)
		if cp == 0x28: # '(' before Thai
			var next_idx := i + 1
			while next_idx < n and line.unicode_at(next_idx) == 0x20:
				next_idx += 1
			if next_idx < n and line.unicode_at(next_idx) > 0x7F:
				thai_mask[i] = 1
		elif _is_neutral_punct(cp):
			var has_thai_before := i > 0 and thai_mask[i - 1] == 1
			var look := i + 1
			while look < n and _is_neutral_punct(line.unicode_at(look)):
				look += 1
			var has_thai_after := look < n and line.unicode_at(look) > 0x7F
			if (has_thai_before and (look == n or has_thai_after)) or (cp == 0x20 and (has_thai_before or has_thai_after)):
				thai_mask[i] = 1

	var start := 0
	while start < n:
		var use_thai := thai_mask[start] == 1
		var end := start + 1
		while end < n and (thai_mask[end] == 1) == use_thai:
			end += 1
		var chunk := line.substr(start, end - start)
		if use_thai:
			_output_log.push_font(_thai_log_font, THAI_LOG_FONT_SIZE)
			_output_log.add_text(chunk)
			_output_log.pop()
		else:
			_output_log.add_text(chunk)
		start = end


static func _is_pure_ascii(text: String) -> bool:
	for i in text.length():
		if text.unicode_at(i) > 0x7F:
			return false
	return true


static func _is_neutral_punct(cp: int) -> bool:
	return cp == 0x20 or cp == 0x2E or cp == 0x2C or cp == 0x3A or cp == 0x3B or cp == 0x29 or cp == 0x21 or cp == 0x3F


func clear_output() -> void:
	_output_log.clear()


func _scroll_to_bottom() -> void:
	_output_log.scroll_to_line(maxi(0, _output_log.get_line_count() - 1))


func set_executing(executing: bool) -> void:
	_is_executing = executing
	_input_edit.editable = not executing
	_enter_button.disabled = executing
	if not executing:
		_input_edit.grab_focus()


func set_window_title(title: String) -> void:
	window_title = title
	if _title_label != null:
		_title_label.text = title


func set_prompt_prefix(prefix: String) -> void:
	prompt_prefix = prefix
	if _prompt_label != null:
		_prompt_label.text = prefix
