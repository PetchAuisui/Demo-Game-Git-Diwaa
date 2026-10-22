class_name RemoteCommitInfo
extends RefCounted

var id: String = ""
var short_id: String = ""
var author: String = ""
var subject: String = ""
var authored_at: float = 0.0


func _init(p_id: String = "", p_short_id: String = "", p_author: String = "", p_subject: String = "",
		p_authored_at: float = 0.0) -> void:
	id = p_id
	short_id = p_short_id
	author = p_author
	subject = p_subject
	authored_at = p_authored_at
