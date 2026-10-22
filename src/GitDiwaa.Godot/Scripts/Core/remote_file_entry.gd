class_name RemoteFileEntry
extends RefCounted

var name: String = ""
var path: String = ""
var is_directory: bool = false
## null เมื่อไม่รู้ commit ล่าสุดของไฟล์
var last_commit: RemoteCommitInfo = null


func _init(p_name: String = "", p_path: String = "", p_is_directory: bool = false,
		p_last_commit: RemoteCommitInfo = null) -> void:
	name = p_name
	path = p_path
	is_directory = p_is_directory
	last_commit = p_last_commit
