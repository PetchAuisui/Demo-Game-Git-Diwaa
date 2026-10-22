class_name GitSessionInfo
extends RefCounted

var mission_id: String = ""
var attempt_id: String = ""
var repository_path: String = ""
var remote_url: String = ""


func _init(p_mission_id: String = "", p_attempt_id: String = "", p_repository_path: String = "",
		p_remote_url: String = "") -> void:
	mission_id = p_mission_id
	attempt_id = p_attempt_id
	repository_path = p_repository_path
	remote_url = p_remote_url
