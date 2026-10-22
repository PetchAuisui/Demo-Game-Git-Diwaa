class_name SeedCommit
extends RefCounted

var branch: String = ""
var author: String = ""
var message: String = ""
## Unix timestamp (วินาที)
var date: float = 0.0
## path -> เนื้อหาไฟล์
var files: Dictionary = {}


func _init(p_branch: String = "", p_author: String = "", p_message: String = "", p_date: float = 0.0,
		p_files: Dictionary = {}) -> void:
	branch = p_branch
	author = p_author
	message = p_message
	date = p_date
	files = p_files
