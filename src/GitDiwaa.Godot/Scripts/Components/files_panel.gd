class_name FilesPanel
extends PanelContainer
## Workspace navigator and embedded text editor. This component owns presentation state only;
## repository and filesystem mutations are delegated through signals to the root orchestrator.

signal open_file_requested(file_path: String)
signal save_file_requested(file_path: String, content: String)
signal create_file_requested(file_path: String, content: String)
signal create_folder_requested(folder_path: String)
signal rename_entry_requested(source_path: String, destination_path: String)
signal delete_entry_requested(entry_path: String, is_directory: bool)

const INDENT_PIXELS := 22
const CHEVRON_SLOT_PIXELS := 22

@export var panel_title: String = "FILES — พื้นที่ทำงาน"
@export var empty_message: String = "ยังไม่มีไฟล์ — เริ่มสร้างด้านบน"

var _title_label: Label
var _feedback_label: Label
var _workspace_actions: Control
var _entry_actions: Control
var _navigator_surface: Control
var _editor_surface: Control
var _files_list: ItemList
var _new_file_button: Button
var _new_folder_button: Button
var _open_button: Button
var _rename_button: Button
var _delete_button: Button
var _editor_path_label: Label
var _dirty_label: Label
var _editor: CodeEdit
var _editor_layout: Control
var _save_button: Button
var _close_editor_button: Button
var _create_file_dialog: ConfirmationDialog
var _create_file_name_input: LineEdit
var _create_folder_dialog: ConfirmationDialog
var _create_folder_name_input: LineEdit
var _rename_dialog: ConfirmationDialog
var _rename_input: LineEdit
var _delete_confirm_dialog: ConfirmationDialog
var _discard_changes_dialog: ConfirmationDialog
var _rename_message: Label
var _delete_message: Label
var _discard_message: Label

var _entries: Array[WorkspaceEntryDisplayItem] = []
var _all_entries: Array[WorkspaceEntryDisplayItem] = []
## path ของโฟลเดอร์ที่พับอยู่ (ใช้เป็น set)
var _collapsed: Dictionary = {}
var _tree_icons: Dictionary = {}

## "" = ไม่มี
var _selected_path := ""
var _selected_is_directory := false
var _open_file_path := ""
var _saved_content := ""
var _pending_open_path := ""
var _pending_close := false
var _suppress_text_changed := false

var _file_icon: Texture2D
var _folder_icon: Texture2D

var has_unsaved_changes: bool:
	get:
		return not _open_file_path.is_empty() and _editor.text != _saved_content


func _ready() -> void:
	_file_icon = load("res://assets/icons/file.svg")
	_folder_icon = load("res://assets/icons/folder.svg")

	_bind_nodes()
	_rename_message = DialogStyle.apply(_rename_dialog, DialogStyle.INFO, "Aa", "เปลี่ยนชื่อ", true, _rename_input)
	_rename_dialog.register_text_enter(_rename_input)
	_delete_message = DialogStyle.apply(_delete_confirm_dialog, DialogStyle.DANGER, "!", "ยืนยันการลบ", true)
	_discard_message = DialogStyle.apply(_discard_changes_dialog, DialogStyle.WARNING, "!", "มีการแก้ไขที่ยังไม่บันทึก", true)
	for dialog in [_rename_dialog, _delete_confirm_dialog, _discard_changes_dialog]:
		(dialog as ConfirmationDialog).size = Vector2i(520, 100)
	_setup_create_dialog(_create_file_dialog, _create_file_name_input)
	_setup_create_dialog(_create_folder_dialog, _create_folder_name_input)

	_title_label.text = panel_title

	_files_list.item_selected.connect(_on_item_selected)
	_files_list.item_activated.connect(_on_item_activated)
	_files_list.empty_clicked.connect(_on_empty_clicked)
	_new_file_button.pressed.connect(func() -> void: _show_create_dialog(_create_file_dialog, _create_file_name_input))
	_new_folder_button.pressed.connect(func() -> void: _show_create_dialog(_create_folder_dialog, _create_folder_name_input))
	_open_button.pressed.connect(func() -> void:
		if not _selected_path.is_empty() and not _selected_is_directory:
			_request_open_file(_selected_path))
	_rename_button.pressed.connect(_on_rename_button_pressed)
	_delete_button.pressed.connect(_on_delete_button_pressed)
	_save_button.pressed.connect(_request_save)
	_close_editor_button.pressed.connect(_request_close_editor)
	_editor.text_changed.connect(_update_dirty_state)

	_create_file_dialog.confirmed.connect(_on_create_file_confirmed)
	_create_folder_dialog.confirmed.connect(_on_create_folder_confirmed)
	_rename_dialog.confirmed.connect(_on_rename_confirmed)
	_delete_confirm_dialog.confirmed.connect(_on_delete_confirmed)
	_discard_changes_dialog.confirmed.connect(_on_discard_changes_confirmed)

	_show_empty_editor()
	_update_action_buttons()
	set_entries([] as Array[WorkspaceEntryDisplayItem])


func _bind_nodes() -> void:
	_title_label = get_node("%TitleLabel")
	_feedback_label = get_node("%FeedbackLabel")
	_workspace_actions = get_node("%WorkspaceActions")
	_entry_actions = get_node("%EntryActions")
	_navigator_surface = get_node("%NavigatorSurface")
	_editor_surface = get_node("%EditorSurface")
	_files_list = get_node("%FilesList")
	_new_file_button = get_node("%NewFileButton")
	_new_folder_button = get_node("%NewFolderButton")
	_open_button = get_node("%OpenButton")
	_rename_button = get_node("%RenameButton")
	_delete_button = get_node("%DeleteButton")
	_editor_path_label = get_node("%EditorPathLabel")
	_dirty_label = get_node("%DirtyLabel")
	_editor = get_node("%Editor")
	_editor_layout = get_node("%EditorLayout")
	_save_button = get_node("%SaveButton")
	_close_editor_button = get_node("%CloseEditorButton")
	_create_file_dialog = get_node("%CreateFileDialog")
	_create_file_name_input = get_node("%CreateFileNameInput")
	_create_folder_dialog = get_node("%CreateFolderDialog")
	_create_folder_name_input = get_node("%CreateFolderNameInput")
	_rename_dialog = get_node("%RenameDialog")
	_rename_input = get_node("%RenameInput")
	_delete_confirm_dialog = get_node("%DeleteConfirmDialog")
	_discard_changes_dialog = get_node("%DiscardChangesDialog")


func _setup_create_dialog(dialog: ConfirmationDialog, name_input: LineEdit) -> void:
	dialog.get_ok_button().theme_type_variation = "CreateAction"
	dialog.get_ok_button().custom_minimum_size = Vector2(172, 46)
	dialog.get_cancel_button().custom_minimum_size = Vector2(112, 46)
	dialog.register_text_enter(name_input)
	name_input.text_changed.connect(func(text: String) -> void: dialog.get_ok_button().disabled = text.strip_edges().is_empty())


func set_entries(entries: Array[WorkspaceEntryDisplayItem]) -> void:
	_all_entries.clear()
	_all_entries.append_array(_sort_as_tree(entries))
	_render_entries()


func _render_entries() -> void:
	var previous_selection := _selected_path
	_entries.clear()
	for entry in _all_entries:
		if not _is_hidden_by_collapsed_ancestor(entry.path):
			_entries.append(entry)
	_files_list.clear()

	if _entries.is_empty():
		_files_list.add_item(empty_message)
		_files_list.set_item_disabled(0, true)
		_selected_path = ""
		_selected_is_directory = false
		_update_action_buttons()
		return

	for index in _entries.size():
		var entry := _entries[index]
		var depth := entry.path.count("/")
		var status := "" if entry.status_badge.is_empty() else " " + entry.status_badge
		var icon := _get_tree_icon(entry.is_directory, depth, entry.is_directory and not _collapsed.has(entry.path))
		_files_list.add_item(entry.name + status, icon)
		_files_list.set_item_tooltip(index, entry.path)
		if entry.status_color != null:
			_files_list.set_item_custom_fg_color(index, entry.status_color)

		if entry.path == previous_selection:
			_files_list.select(index)

	if not previous_selection.is_empty() and not _entries.any(func(entry: WorkspaceEntryDisplayItem) -> bool: return entry.path == previous_selection):
		_selected_path = ""
		_selected_is_directory = false
	_update_action_buttons()


func _is_hidden_by_collapsed_ancestor(path: String) -> bool:
	var slash := path.rfind("/")
	while slash > 0:
		if _collapsed.has(path.substr(0, slash)):
			return true
		slash = path.rfind("/", slash - 1)
	return false


## ItemList always draws the icon at the far left, so each row's icon texture is composed as
## [indent][chevron slot][icon]: folders get a chevron, files leave the slot blank (VS Code style).
func _get_tree_icon(is_directory: bool, depth: int, expanded: bool) -> Texture2D:
	var key := "%s|%d|%s" % [is_directory, depth, expanded]
	if _tree_icons.has(key):
		return _tree_icons[key]

	var source := (_folder_icon if is_directory else _file_icon).get_image()
	if source.is_compressed():
		source.decompress()
	source.convert(Image.FORMAT_RGBA8)

	var left := depth * INDENT_PIXELS
	var gap := 2
	var width := left + CHEVRON_SLOT_PIXELS + gap + source.get_width()
	var height := maxi(source.get_height(), CHEVRON_SLOT_PIXELS)
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	if is_directory:
		_draw_chevron(image, left, height / 2, expanded)
	image.blit_rect(source, Rect2i(Vector2i.ZERO, source.get_size()),
			Vector2i(left + CHEVRON_SLOT_PIXELS + gap, (height - source.get_height()) / 2))

	var texture := ImageTexture.create_from_image(image)
	_tree_icons[key] = texture
	return texture


static func _draw_chevron(image: Image, slot_x: int, center_y: int, expanded: bool) -> void:
	var color := Color(0.78, 0.80, 0.88)
	var cx := slot_x + CHEVRON_SLOT_PIXELS / 2
	for i in 7:
		for thickness in 2:
			if expanded:
				# "v": arms meet at the bottom.
				image.set_pixel(cx - 6 + i, center_y - 3 + i - thickness + 1, color)
				image.set_pixel(cx + 6 - i, center_y - 3 + i - thickness + 1, color)
			else:
				# ">": arms meet at the right.
				image.set_pixel(cx - 3 + i - thickness + 1, center_y - 6 + i, color)
				image.set_pixel(cx - 3 + i - thickness + 1, center_y + 6 - i, color)


## Orders entries depth-first so every child sits directly under its parent,
## with folders listed before files at each level.
static func _sort_as_tree(entries: Array[WorkspaceEntryDisplayItem]) -> Array[WorkspaceEntryDisplayItem]:
	var directories := {}
	for entry in entries:
		if entry.is_directory:
			directories[entry.path] = true

	# แต่ละรายการมีกุญแจเป็นลำดับ [ชื่อ, เป็นโฟลเดอร์?] ของทุกส่วนใน path
	var keyed: Array[Dictionary] = []
	for entry in entries:
		var parts := entry.path.split("/")
		var key: Array = []
		for i in parts.size():
			var is_last := i == parts.size() - 1
			key.append([parts[i], not is_last or directories.has(entry.path)])
		keyed.append({"entry": entry, "key": key})

	keyed.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var key_a: Array = a["key"]
		var key_b: Array = b["key"]
		var length := mini(key_a.size(), key_b.size())
		for i in length:
			if key_a[i][1] != key_b[i][1]:
				return key_a[i][1] # โฟลเดอร์ก่อนไฟล์
			var name_a: String = (key_a[i][0] as String).to_lower()
			var name_b: String = (key_b[i][0] as String).to_lower()
			if name_a != name_b:
				return name_a < name_b
		return key_a.size() < key_b.size())

	var sorted: Array[WorkspaceEntryDisplayItem] = []
	for item in keyed:
		sorted.append(item["entry"])
	return sorted


func show_file(file_path: String, content: String) -> void:
	_open_file_path = file_path
	_saved_content = content
	_suppress_text_changed = true
	_editor.text = content
	_suppress_text_changed = false
	_editor_path_label.text = file_path
	_workspace_actions.visible = false
	_navigator_surface.visible = false
	_editor_surface.visible = true
	_editor_layout.visible = true
	_update_dirty_state()
	_editor.grab_focus()


func mark_saved(file_path: String) -> void:
	if _open_file_path != file_path:
		return
	_saved_content = _editor.text
	_update_dirty_state()


func notify_entry_renamed(source_path: String, destination_path: String) -> void:
	if _open_file_path == source_path or _open_file_path.begins_with(source_path + "/"):
		_open_file_path = destination_path + _open_file_path.substr(source_path.length())
		_editor_path_label.text = _open_file_path
	if _selected_path == source_path or _selected_path.begins_with(source_path + "/"):
		_selected_path = destination_path + _selected_path.substr(source_path.length())


func notify_entry_deleted(path: String) -> void:
	if _open_file_path == path or _open_file_path.begins_with(path + "/"):
		_show_empty_editor()


func show_feedback(message: String, is_error: bool = false) -> void:
	_feedback_label.text = message
	_feedback_label.modulate = Color(1.0, 0.48, 0.52) if is_error else Color(0.45, 0.95, 0.66)
	_feedback_label.visible = true


func set_busy(busy: bool) -> void:
	_new_file_button.disabled = busy
	_new_folder_button.disabled = busy
	_open_button.disabled = busy or _selected_path.is_empty() or _selected_is_directory
	_rename_button.disabled = busy or _selected_path.is_empty()
	_delete_button.disabled = busy or _selected_path.is_empty()
	_save_button.disabled = busy or not has_unsaved_changes
	if not busy:
		_update_action_buttons()


func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	var entry := _entries[index]
	_selected_path = entry.path
	_selected_is_directory = entry.is_directory
	if entry.is_directory:
		# Click toggles expand/collapse, like a VS Code explorer folder.
		if not _collapsed.erase(entry.path):
			_collapsed[entry.path] = true
		_render_entries()
	_update_action_buttons()
	show_feedback(("เลือกโฟลเดอร์ %s" if entry.is_directory else "เลือกไฟล์ %s") % entry.path)


## Clicking blank space clears the selection and returns to the WORKSPACE root.
func _on_empty_clicked(_at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	_files_list.deselect_all()
	_selected_path = ""
	_selected_is_directory = false
	_update_action_buttons()
	show_feedback("เลือก WORKSPACE")


func _on_item_activated(index: int) -> void:
	if index < 0 or index >= _entries.size() or _entries[index].is_directory:
		return
	_request_open_file(_entries[index].path)


func _request_open_file(file_path: String) -> void:
	if _open_file_path == file_path:
		return
	if has_unsaved_changes:
		_pending_open_path = file_path
		_pending_close = false
		_discard_message.text = "'%s' ยังไม่ได้บันทึก\nต้องการทิ้งการแก้ไขแล้วเปิด '%s' หรือไม่?" % [_open_file_path, file_path]
		_discard_changes_dialog.popup_centered()
		return
	open_file_requested.emit(file_path)


func _request_save() -> void:
	if _open_file_path.is_empty() or not has_unsaved_changes:
		return
	save_file_requested.emit(_open_file_path, _editor.text)


func _request_close_editor() -> void:
	if has_unsaved_changes:
		_pending_close = true
		_pending_open_path = ""
		_discard_message.text = "'%s' ยังไม่ได้บันทึก\nต้องการทิ้งการแก้ไขและปิด editor หรือไม่?" % _open_file_path
		_discard_changes_dialog.popup_centered()
		return
	_show_empty_editor()


func _on_discard_changes_confirmed() -> void:
	if _pending_close:
		_show_empty_editor()
	elif not _pending_open_path.is_empty():
		var next_path := _pending_open_path
		_pending_open_path = ""
		open_file_requested.emit(next_path)
	_pending_close = false


func _show_empty_editor() -> void:
	_open_file_path = ""
	_saved_content = ""
	_suppress_text_changed = true
	_editor.clear()
	_suppress_text_changed = false
	_workspace_actions.visible = true
	_navigator_surface.visible = true
	_editor_surface.visible = false
	_editor_layout.visible = false
	_update_dirty_state()


func _update_dirty_state() -> void:
	if _suppress_text_changed:
		return
	var dirty := has_unsaved_changes
	_dirty_label.visible = dirty
	_dirty_label.text = "● ยังไม่บันทึก" if dirty else ""
	_save_button.disabled = not dirty
	if not _open_file_path.is_empty():
		_editor_path_label.text = _open_file_path + " *" if dirty else _open_file_path


func _show_create_dialog(dialog: ConfirmationDialog, input: LineEdit) -> void:
	input.clear()
	dialog.get_ok_button().disabled = true
	var folder := _build_path_in_selected_folder("dummy").get_base_dir()

	var location_node := "%CreateFileLocation" if dialog == _create_file_dialog else "%CreateFolderLocation"
	var location := get_node(location_node) as Label
	location.text = "ตำแหน่ง: พื้นที่ทำงาน /" if folder.is_empty() else "ตำแหน่ง: /" + folder
	location.tooltip_text = location.text
	dialog.popup_centered()
	input.grab_focus.call_deferred()


func _on_create_file_confirmed() -> void:
	var entry_name := _validate_simple_name(_create_file_name_input.text)
	if entry_name.is_empty():
		return
	create_file_requested.emit(_build_path_in_selected_folder(entry_name), "")


func _on_create_folder_confirmed() -> void:
	var entry_name := _validate_simple_name(_create_folder_name_input.text)
	if entry_name.is_empty():
		return
	create_folder_requested.emit(_build_path_in_selected_folder(entry_name))


func _on_rename_button_pressed() -> void:
	if _selected_path.is_empty():
		return
	_rename_input.text = _selected_path.get_file()
	_rename_message.text = "เปลี่ยนชื่อ '%s'" % _selected_path
	_rename_dialog.popup_centered()
	_rename_input.grab_focus.call_deferred()


func _on_rename_confirmed() -> void:
	if _selected_path.is_empty():
		return
	var entry_name := _validate_simple_name(_rename_input.text)
	if entry_name.is_empty():
		return
	var parent := _selected_path.get_base_dir()
	var destination := entry_name if parent.is_empty() else "%s/%s" % [parent, entry_name]
	if destination == _selected_path:
		show_feedback("ชื่อใหม่เหมือนชื่อเดิม", true)
		return
	rename_entry_requested.emit(_selected_path, destination)


func _on_delete_button_pressed() -> void:
	if _selected_path.is_empty():
		return
	var kind := "โฟลเดอร์และไฟล์ทั้งหมดภายใน" if _selected_is_directory else "ไฟล์"
	_delete_message.text = "ต้องการลบ%s '%s' หรือไม่?" % [kind, _selected_path]
	_delete_confirm_dialog.popup_centered()


func _on_delete_confirmed() -> void:
	if _selected_path.is_empty():
		return
	delete_entry_requested.emit(_selected_path, _selected_is_directory)


func _build_path_in_selected_folder(entry_name: String) -> String:
	if _selected_path.is_empty():
		return entry_name
	var folder := _selected_path if _selected_is_directory else _selected_path.get_base_dir()
	return entry_name if folder.is_empty() else "%s/%s" % [folder, entry_name]


## คืนชื่อที่ใช้ได้ หรือ "" เมื่อชื่อไม่ถูกต้อง (แจ้งผู้เล่นแล้ว)
func _validate_simple_name(value: String) -> String:
	var entry_name := value.strip_edges()
	if entry_name.is_empty() or entry_name == "." or entry_name == ".." or entry_name.contains("/") or entry_name.contains("\\"):
		show_feedback("กรุณาใช้ชื่อเดียวที่ไม่มี / หรือ \\", true)
		return ""
	return entry_name


func _update_action_buttons() -> void:
	var has_selection := not _selected_path.is_empty()
	_entry_actions.visible = has_selection and _open_file_path.is_empty()
	_open_button.disabled = not has_selection or _selected_is_directory
	_rename_button.disabled = not has_selection
	_delete_button.disabled = not has_selection
