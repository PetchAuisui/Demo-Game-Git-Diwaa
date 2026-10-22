class_name PullRequestFileChange
extends RefCounted

var path: String = ""
var status: String = "M"
var additions: int = 0
var deletions: int = 0


func _init(p_path: String = "", p_status: String = "M", p_additions: int = 0, p_deletions: int = 0) -> void:
	path = p_path
	status = p_status
	additions = p_additions
	deletions = p_deletions
