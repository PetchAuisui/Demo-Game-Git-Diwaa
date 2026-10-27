class_name PlayerWorkspaceEntry
extends RefCounted

var path: String = ""
var is_directory: bool = false


func _init(p_path: String = "", p_is_directory: bool = false) -> void:
	path = p_path
	is_directory = p_is_directory
