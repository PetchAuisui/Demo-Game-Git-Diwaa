class_name RemoteRepositoryInfo
extends RefCounted

var owner: String = ""
var name: String = ""
var description: String = ""
var clone_url: String = ""
var default_branch: String = ""
var branch_count: int = 0
var commit_count: int = 0

## ยังไม่มี branch ใดถูก push ขึ้นมา (หน้า Quick setup)
var is_empty: bool:
	get:
		return branch_count == 0


func _init(p_owner: String = "", p_name: String = "", p_description: String = "", p_clone_url: String = "",
		p_default_branch: String = "", p_branch_count: int = 0, p_commit_count: int = 0) -> void:
	owner = p_owner
	name = p_name
	description = p_description
	clone_url = p_clone_url
	default_branch = p_default_branch
	branch_count = p_branch_count
	commit_count = p_commit_count
