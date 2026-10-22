class_name WorkspaceEntryDisplayItem
extends RefCounted

var path: String = ""
var name: String = ""
var is_directory: bool = false
var index_state: int = GitFileState.UNCHANGED
var working_tree_state: int = GitFileState.UNCHANGED

var status_badge: String:
	get:
		if is_directory:
			return ""
		return FileDisplayItem.new(path, name, index_state, working_tree_state).status_badge

## สีของสถานะ หรือ null (โฟลเดอร์ / ไม่ต้องย้อมสี)
var status_color: Variant:
	get:
		if is_directory:
			return null
		return FileDisplayItem.new(path, name, index_state, working_tree_state).status_color


func _init(p_path: String = "", p_name: String = "", p_is_directory: bool = false,
		p_index_state: int = GitFileState.UNCHANGED,
		p_working_tree_state: int = GitFileState.UNCHANGED) -> void:
	path = p_path
	name = p_name
	is_directory = p_is_directory
	index_state = p_index_state
	working_tree_state = p_working_tree_state
