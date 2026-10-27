class_name GitFileStatus
extends RefCounted

var path: String = ""
var index_state: int = GitFileState.UNCHANGED
var working_tree_state: int = GitFileState.UNCHANGED


func _init(p_path: String = "", p_index_state: int = GitFileState.UNCHANGED,
		p_working_tree_state: int = GitFileState.UNCHANGED) -> void:
	path = p_path
	index_state = p_index_state
	working_tree_state = p_working_tree_state


func to_dict() -> Dictionary:
	return {
		"Path": path,
		"IndexState": GitFileState.name_of(index_state),
		"WorkingTreeState": GitFileState.name_of(working_tree_state),
	}
