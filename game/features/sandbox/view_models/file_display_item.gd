class_name FileDisplayItem
extends RefCounted

var path: String = ""
var file_name: String = ""
var index_state: int = GitFileState.UNCHANGED
var working_tree_state: int = GitFileState.UNCHANGED

var status_badge: String:
	get:
		match working_tree_state:
			GitFileState.UNTRACKED:
				return "[?]"
			GitFileState.MODIFIED:
				return "[M]"
			GitFileState.DELETED:
				return "[D]"
			GitFileState.UNKNOWN:
				return ""
		match index_state:
			GitFileState.ADDED:
				return "[A]"
			GitFileState.MODIFIED:
				return "[M]"
			GitFileState.DELETED:
				return "[D]"
			GitFileState.RENAMED:
				return "[R]"
			GitFileState.UNKNOWN:
				return ""
		return "[✓]"

var status_label: String:
	get:
		match working_tree_state:
			GitFileState.UNTRACKED:
				return "Untracked"
			GitFileState.MODIFIED:
				return "Modified"
			GitFileState.DELETED:
				return "Deleted"
			GitFileState.UNKNOWN:
				return "Unknown"
		match index_state:
			GitFileState.ADDED:
				return "Staged (Added)"
			GitFileState.MODIFIED:
				return "Staged (Modified)"
			GitFileState.DELETED:
				return "Staged (Deleted)"
			GitFileState.RENAMED:
				return "Staged (Renamed)"
			GitFileState.UNKNOWN:
				return "Unknown"
		return "Committed"

## สีของสถานะ หรือ null เมื่อไม่ต้องย้อมสี
var status_color: Variant:
	get:
		match working_tree_state:
			GitFileState.UNTRACKED:
				return SandboxThemeTokens.STATE_UNTRACKED
			GitFileState.MODIFIED:
				return SandboxThemeTokens.STATE_MODIFIED
			GitFileState.DELETED:
				return SandboxThemeTokens.STATE_DELETED
			GitFileState.UNKNOWN:
				return null
		match index_state:
			GitFileState.ADDED:
				return SandboxThemeTokens.STATE_ADDED
			GitFileState.MODIFIED:
				return SandboxThemeTokens.STATE_MODIFIED
			GitFileState.DELETED:
				return SandboxThemeTokens.STATE_DELETED
			GitFileState.RENAMED:
				return SandboxThemeTokens.STATE_RENAMED
			GitFileState.UNKNOWN:
				return null
		return SandboxThemeTokens.TEXT_SECONDARY


func _init(p_path: String = "", p_file_name: String = "", p_index_state: int = GitFileState.UNCHANGED,
		p_working_tree_state: int = GitFileState.UNCHANGED) -> void:
	path = p_path
	file_name = p_file_name
	index_state = p_index_state
	working_tree_state = p_working_tree_state


func copy() -> FileDisplayItem:
	return FileDisplayItem.new(path, file_name, index_state, working_tree_state)
