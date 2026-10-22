class_name LocalRemote
extends RefCounted

var name: String = ""
var alias_url: String = ""
var bare_repository_path: String = ""


func _init(p_name: String = "", p_alias_url: String = "", p_bare_repository_path: String = "") -> void:
	name = p_name
	alias_url = p_alias_url
	bare_repository_path = p_bare_repository_path
