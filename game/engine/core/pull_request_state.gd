class_name PullRequestState
extends RefCounted

enum { OPEN, MERGED, CLOSED }

const NAMES: Array[String] = ["Open", "Merged", "Closed"]


static func name_of(state: int) -> String:
	return NAMES[state]
