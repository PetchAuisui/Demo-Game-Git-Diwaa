class_name GitFileState
extends RefCounted

enum { UNCHANGED, UNTRACKED, ADDED, MODIFIED, DELETED, RENAMED, COPIED, UNMERGED, UNKNOWN }

const NAMES: Array[String] = [
	"Unchanged", "Untracked", "Added", "Modified", "Deleted", "Renamed", "Copied", "Unmerged", "Unknown"
]


static func name_of(state: int) -> String:
	return NAMES[state]
