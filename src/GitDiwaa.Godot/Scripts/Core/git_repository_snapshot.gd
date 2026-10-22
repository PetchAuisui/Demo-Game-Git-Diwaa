class_name GitRepositorySnapshot
extends RefCounted

var is_initialized: bool = false
## null เมื่อ HEAD ไม่ได้ชี้ branch
var current_branch: Variant = null
var files: Array[GitFileStatus] = []
var branches: Array[GitBranchInfo] = []
var commits: Array[GitCommitNode] = []


func _init(p_is_initialized: bool = false, p_current_branch: Variant = null,
		p_files: Array[GitFileStatus] = [], p_branches: Array[GitBranchInfo] = [],
		p_commits: Array[GitCommitNode] = []) -> void:
	is_initialized = p_is_initialized
	current_branch = p_current_branch
	files = p_files
	branches = p_branches
	commits = p_commits


func to_dict() -> Dictionary:
	return {
		"IsInitialized": is_initialized,
		"CurrentBranch": current_branch,
		"Files": files.map(func(item: GitFileStatus) -> Dictionary: return item.to_dict()),
		"Branches": branches.map(func(item: GitBranchInfo) -> Dictionary: return item.to_dict()),
		"Commits": commits.map(func(item: GitCommitNode) -> Dictionary: return item.to_dict()),
	}
