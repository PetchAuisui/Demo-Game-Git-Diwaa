class_name GitBranchInfo
extends RefCounted

var name: String = ""
var is_current: bool = false
## null เมื่อไม่มีค่า
var commit_id: Variant = null
var upstream: Variant = null


func _init(p_name: String = "", p_is_current: bool = false, p_commit_id: Variant = null,
		p_upstream: Variant = null) -> void:
	name = p_name
	is_current = p_is_current
	commit_id = p_commit_id
	upstream = p_upstream


func to_dict() -> Dictionary:
	return {"Name": name, "IsCurrent": is_current, "CommitId": commit_id, "Upstream": upstream}
