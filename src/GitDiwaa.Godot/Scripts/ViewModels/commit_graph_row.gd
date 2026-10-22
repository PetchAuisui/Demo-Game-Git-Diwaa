class_name CommitGraphRow
extends RefCounted

var commit: CommitGraphDisplayNode
var lane: int = 0


func _init(p_commit: CommitGraphDisplayNode = null, p_lane: int = 0) -> void:
	commit = p_commit
	lane = p_lane
