class_name RemoteBranchInfo
extends RefCounted

var name: String = ""
var commit_id: String = ""
var is_default: bool = false
var ahead: int = 0
var behind: int = 0
var last_commit_subject: String = ""
var last_commit_at: float = 0.0


func _init(p_name: String = "", p_commit_id: String = "", p_is_default: bool = false, p_ahead: int = 0,
		p_behind: int = 0, p_last_commit_subject: String = "", p_last_commit_at: float = 0.0) -> void:
	name = p_name
	commit_id = p_commit_id
	is_default = p_is_default
	ahead = p_ahead
	behind = p_behind
	last_commit_subject = p_last_commit_subject
	last_commit_at = p_last_commit_at
