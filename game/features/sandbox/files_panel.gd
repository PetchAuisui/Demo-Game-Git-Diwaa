class_name FilesPanel
extends PanelContainer
## Workspace navigator and embedded text editor. This component owns presentation state only;
## repository and filesystem mutations are delegated through signals to the root orchestrator.

signal open_file_requested(file_path: String)
signal save_file_requested(file_path: String, content: String)
signal create_file_requested(file_path: String, content: String)
signal create_folder_requested(folder_path: String)
signal rename_entry_requested(source_path: String, destination_path: String)
signal move_entry_requested(source_path: String, destination_path: String)
signal delete_entry_requested(entry_path: String, is_directory: bool)

const INDENT_PIXELS := 22
const CHEVRON_SLOT_PIXELS := 22
## ความสูงไอคอนแต่ละแถว = ความสูงแถวทั้งแถว (v_separation = 0) เพื่อให้เส้นโยงต่อกันไม่ขาด
const TREE_ROW_PIXELS := 40
const GUIDE_COLOR := Color(0.36, 0.42, 0.64, 0.9)
const DRAG_TYPE := "workspace_entry"
const DROP_HIGHLIGHT := Color(0.98, 0.72, 0.28, 0.22)

@export var panel_title: String = "FILES — พื้นที่ทำงาน"
@export var empty_message: String = "ยังไม่มีไฟล์"

var _title_label: Label
var _feedback_label: Label
var _workspace_actions: Control
var _entry_actions: Control
var _navigator_surface: Control
var _editor_surface: Control
var _files_list: ItemList
var _empty_state: Control
var _empty_title: Label
var _entry_count_label: Label
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
var _is_busy := false
## index ของแถวที่ไฮไลต์ขณะลาก (-1 = ไม่มี)
var _drop_highlight_index := -1
## path ของแถวที่กดเมาส์ล่าสุด — จำไว้ตอนกด เพราะการเลือกแถวทำให้รายการเลื่อนลง
var _pressed_entry_path := ""
## true ระหว่างกดเมาส์ค้างบนรายการ — โฟลเดอร์จะพับ/กางตอนปล่อยเมาส์ (ถ้าไม่ได้ลาก) แทนตอนกด
var _mouse_held_on_list := false
## โฟลเดอร์ที่รอพับ/กางเมื่อปล่อยเมาส์ ("" = ไม่มี)
var _pending_toggle_path := ""
var _drag_in_progress := false

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
	_files_list.gui_input.connect(_on_files_list_gui_input)
	_files_list.set_drag_forwarding(_get_list_drag_data, _can_drop_on_list, _drop_on_list)
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
	_empty_state = get_node("%EmptyState")
	_empty_title = get_node("%EmptyTitle")
	_entry_count_label = get_node("%EntryCountLabel")
	_empty_title.text = empty_message
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
	_drop_highlight_index = -1
	_empty_state.visible = _entries.is_empty()
	_entry_count_label.text = "%d รายการ" % _all_entries.size()

	if _entries.is_empty():
		_selected_path = ""
		_selected_is_directory = false
		_update_action_buttons()
		return

	var guides := _build_tree_guides()
	for index in _entries.size():
		var entry := _entries[index]
		var depth := entry.path.count("/")
		var status := "" if entry.status_badge.is_empty() else " " + entry.status_badge
		var icon := _get_tree_icon(entry.is_directory, depth, entry.is_directory and not _collapsed.has(entry.path), guides[index])
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
## รูปแบบเส้นโยงของแต่ละแถว (ตามลำดับ _entries) เป็น String ยาว depth+1 ตัว:
## ตัวที่ k < depth-1 คือเส้นแนวตั้งผ่านของบรรพบุรุษระดับ k ("|" = มีพี่น้องถัดไป, " " = ไม่มี),
## ตัวที่ depth-1 คือข้อต่อเข้าหาแถวนี้ ("T" = ยังมีพี่น้องถัดไป, "L" = ตัวสุดท้าย),
## ตัวสุดท้ายคือ "v" เมื่อเป็นโฟลเดอร์ที่กางอยู่และมีลูกแสดงอยู่ข้างล่าง
func _build_tree_guides() -> Array[String]:
	var count := _entries.size()
	var parent_of: Array[String] = []
	var is_last: Array[bool] = []
	var last_index_of_parent := {}
	for i in count:
		var parent := _entries[i].path.get_base_dir()
		parent_of.append(parent)
		last_index_of_parent[parent] = i
	for i in count:
		is_last.append(last_index_of_parent[parent_of[i]] == i)

	# ancestor_open[level] = เส้นแนวตั้งระดับนั้นยังต้องลากต่อหรือไม่
	var ancestor_open: Array[bool] = []
	var guides: Array[String] = []
	for i in count:
		var entry := _entries[i]
		var depth := entry.path.count("/")
		ancestor_open.resize(depth)
		var pattern := ""
		for level in depth:
			if level < depth - 1:
				pattern += "|" if ancestor_open[level] else " "
			else:
				pattern += "L" if is_last[i] else "T"
		var has_visible_child := i + 1 < count and parent_of[i + 1] == entry.path
		pattern += "v" if entry.is_directory and has_visible_child else "-"
		guides.append(pattern)
		if depth > 0:
			ancestor_open[depth - 1] = not is_last[i]
		ancestor_open.append(false)
	return guides


func _get_tree_icon(is_directory: bool, depth: int, expanded: bool, guide: String = "") -> Texture2D:
	var key := "%s|%d|%s|%s" % [is_directory, depth, expanded, guide]
	if _tree_icons.has(key):
		return _tree_icons[key]

	var source := (_folder_icon if is_directory else _file_icon).get_image()
	if source.is_compressed():
		source.decompress()
	source.convert(Image.FORMAT_RGBA8)

	var left := depth * INDENT_PIXELS
	var gap := 2
	var width := left + CHEVRON_SLOT_PIXELS + gap + source.get_width()
	var height := maxi(TREE_ROW_PIXELS, maxi(source.get_height(), CHEVRON_SLOT_PIXELS))
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	_draw_tree_guides(image, depth, is_directory, guide)
	if is_directory:
		_draw_chevron(image, left, height / 2, expanded)
	image.blit_rect(source, Rect2i(Vector2i.ZERO, source.get_size()),
			Vector2i(left + CHEVRON_SLOT_PIXELS + gap, (height - source.get_height()) / 2))

	var texture := ImageTexture.create_from_image(image)
	_tree_icons[key] = texture
	return texture


static func _draw_tree_guides(image: Image, depth: int, is_directory: bool, guide: String) -> void:
	if guide.is_empty():
		return
	var height := image.get_height()
	var mid := height / 2
	for level in depth:
		var x := level * INDENT_PIXELS + CHEVRON_SLOT_PIXELS / 2 - 1
		match guide[level]:
			"|":
				_fill(image, Rect2i(x, 0, 2, height))
			"T", "L":
				var bottom := height if guide[level] == "T" else mid + 1
				_fill(image, Rect2i(x, 0, 2, bottom))
				# เส้นแนวนอนวิ่งไปหาลูกศร (โฟลเดอร์) หรือไอคอนไฟล์
				var end_x := depth * INDENT_PIXELS + (4 if is_directory else CHEVRON_SLOT_PIXELS - 2)
				_fill(image, Rect2i(x, mid - 1, end_x - x, 2))
	if guide[guide.length() - 1] == "v":
		var cx := depth * INDENT_PIXELS + CHEVRON_SLOT_PIXELS / 2 - 1
		_fill(image, Rect2i(cx, mid + 7, 2, height - mid - 7))


static func _fill(image: Image, rect: Rect2i) -> void:
	var clipped := rect.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	if clipped.has_area():
		image.fill_rect(clipped, GUIDE_COLOR)


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
	_feedback_label.tooltip_text = message


func set_busy(busy: bool) -> void:
	_is_busy = busy
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
		# เมาส์: รอจนปล่อยเมาส์ เพื่อไม่ให้การกดเพื่อลากโฟลเดอร์ไปพับ/กางมันและทำให้แถวเลื่อน
		if _mouse_held_on_list:
			_pending_toggle_path = entry.path
		else:
			_toggle_folder(entry.path)
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
	# แสดงปุ่มตลอด (ปิดใช้เมื่อยังไม่เลือก) เพื่อไม่ให้รายการกระโดดลงตอนกดแถว
	_entry_actions.visible = _open_file_path.is_empty()
	_open_button.disabled = not has_selection or _selected_is_directory
	_rename_button.disabled = not has_selection
	_delete_button.disabled = not has_selection


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		_drag_in_progress = true
	elif what == NOTIFICATION_DRAG_END:
		_drag_in_progress = false
		_mouse_held_on_list = false
		_pending_toggle_path = ""
		_set_drop_highlight(-1)


# --- ลากไฟล์/โฟลเดอร์ไปวางในโฟลเดอร์ ---------------------------------------

func _on_files_list_gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse.pressed:
		var index := _files_list.get_item_at_position(mouse.position, true)
		_pressed_entry_path = _entries[index].path if index >= 0 and index < _entries.size() else ""
		_mouse_held_on_list = true
		_pending_toggle_path = ""
	else:
		_mouse_held_on_list = false
		_flush_pending_toggle()


func _toggle_folder(path: String) -> void:
	if not _collapsed.erase(path):
		_collapsed[path] = true
	_render_entries()


## พับ/กางโฟลเดอร์ที่รอไว้ เว้นแต่การกดครั้งนั้นกลายเป็นการลาก
func _flush_pending_toggle() -> void:
	var path := _pending_toggle_path
	_pending_toggle_path = ""
	if not path.is_empty() and not _drag_in_progress:
		_toggle_folder(path)


func _get_list_drag_data(_at_position: Vector2) -> Variant:
	if _is_busy or _pressed_entry_path.is_empty():
		return null
	var index := _index_of_path(_pressed_entry_path)
	if index < 0:
		return null
	var entry := _entries[index]
	_files_list.set_drag_preview(_build_drag_preview(entry))
	return {"type": DRAG_TYPE, "path": entry.path, "is_directory": entry.is_directory}


func _can_drop_on_list(at_position: Vector2, data: Variant) -> bool:
	var target := _resolve_drop_target(at_position)
	var ok := _is_valid_move(data, target.folder)
	_set_drop_highlight(target.index if ok else -1)
	return ok


func _drop_on_list(at_position: Vector2, data: Variant) -> void:
	_set_drop_highlight(-1)
	var target := _resolve_drop_target(at_position)
	if not _is_valid_move(data, target.folder):
		return
	var source: String = data.path
	var folder: String = target.folder
	var destination := source.get_file() if folder.is_empty() else "%s/%s" % [folder, source.get_file()]
	_collapsed.erase(folder)
	move_entry_requested.emit(source, destination)


## โฟลเดอร์ปลายทางตามตำแหน่งเมาส์: วางบนโฟลเดอร์ = เข้าโฟลเดอร์นั้น,
## วางบนไฟล์ = โฟลเดอร์เดียวกับไฟล์นั้น, วางที่ว่าง = WORKSPACE (root)
func _resolve_drop_target(at_position: Vector2) -> Dictionary:
	var index := _files_list.get_item_at_position(at_position, true)
	if index < 0 or index >= _entries.size():
		return {"folder": "", "index": -1}
	var entry := _entries[index]
	if entry.is_directory:
		return {"folder": entry.path, "index": index}
	var parent := entry.path.get_base_dir()
	return {"folder": parent, "index": _index_of_path(parent)}


func _is_valid_move(data: Variant, folder: String) -> bool:
	if _is_busy or not (data is Dictionary) or data.get("type") != DRAG_TYPE:
		return false
	var source: String = data.path
	if source.get_base_dir() == folder:
		return false
	# ห้ามย้ายโฟลเดอร์เข้าไปในตัวเองหรือโฟลเดอร์ลูกของมัน
	if data.is_directory and (folder == source or folder.begins_with(source + "/")):
		return false
	return true


func _index_of_path(path: String) -> int:
	for i in _entries.size():
		if _entries[i].path == path:
			return i
	return -1


func _set_drop_highlight(index: int) -> void:
	if index == _drop_highlight_index:
		return
	if _drop_highlight_index >= 0 and _drop_highlight_index < _files_list.item_count:
		_files_list.set_item_custom_bg_color(_drop_highlight_index, Color(0, 0, 0, 0))
	_drop_highlight_index = index
	if index >= 0 and index < _files_list.item_count:
		_files_list.set_item_custom_bg_color(index, DROP_HIGHLIGHT)


func _build_drag_preview(entry: WorkspaceEntryDisplayItem) -> Control:
	var preview := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.24, 0.95)
	style.border_color = Color(0.98, 0.72, 0.28, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	preview.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var icon := TextureRect.new()
	icon.texture = _folder_icon if entry.is_directory else _file_icon
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var label := Label.new()
	label.text = entry.name
	label.add_theme_font_size_override("font_size", 18)
	row.add_child(label)
	preview.add_child(row)
	return preview
