class_name CommitGraphEdge
extends RefCounted

var from_row: int = 0
var from_lane: int = 0
var to_row: int = 0
var to_lane: int = 0
var is_merge: bool = false


func _init(p_from_row: int = 0, p_from_lane: int = 0, p_to_row: int = 0, p_to_lane: int = 0,
		p_is_merge: bool = false) -> void:
	from_row = p_from_row
	from_lane = p_from_lane
	to_row = p_to_row
	to_lane = p_to_lane
	is_merge = p_is_merge
