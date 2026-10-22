class_name GitSandbox
extends RefCounted

var mission_id: String = ""
var attempt_id: String = ""
var attempt_root: String = ""
var player_repository_path: String = ""
var remotes_root: String = ""
var git_config_path: String = ""
var hooks_path: String = ""


func _init(p_mission_id: String = "", p_attempt_id: String = "", p_attempt_root: String = "",
		p_player_repository_path: String = "", p_remotes_root: String = "", p_git_config_path: String = "",
		p_hooks_path: String = "") -> void:
	mission_id = p_mission_id
	attempt_id = p_attempt_id
	attempt_root = p_attempt_root
	player_repository_path = p_player_repository_path
	remotes_root = p_remotes_root
	git_config_path = p_git_config_path
	hooks_path = p_hooks_path
