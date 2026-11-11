class_name GitCommitNode
extends RefCounted

var id: String = ""
var parent_ids: Array[String] = []
var references: Array[String] = []
var subject: String = ""
var author: String = ""
## Unix timestamp (วินาที)
var authored_at: float = 0.0


func _init(p_id: String = "", p_parent_ids: Array[String] = [], p_references: Array[String] = [],
		p_subject: String = "", p_author: String = "", p_authored_at: float = 0.0) -> void:
	id = p_id
	parent_ids = p_parent_ids
	references = p_references
	subject = p_subject
	author = p_author
	authored_at = p_authored_at


func to_dict() -> Dictionary:
	return {
		"Id": id,
		"ParentIds": parent_ids,
		"References": references,
		"Subject": subject,
		"Author": author,
		"AuthoredAt": GitTime.to_iso(authored_at),
	}
