class_name CommitGraphDisplayNode
extends RefCounted

var id: String = ""
var short_id: String = ""
var parent_ids: Array[String] = []
var branches: Array[String] = []
var is_current_branch_head: bool = false
var subject: String = ""
var author: String = ""
var authored_at: float = 0.0


func _init(p_id: String = "", p_short_id: String = "", p_parent_ids: Array[String] = [],
		p_branches: Array[String] = [], p_is_current_branch_head: bool = false, p_subject: String = "",
		p_author: String = "", p_authored_at: float = 0.0) -> void:
	id = p_id
	short_id = p_short_id
	parent_ids = p_parent_ids
	branches = p_branches
	is_current_branch_head = p_is_current_branch_head
	subject = p_subject
	author = p_author
	authored_at = p_authored_at


static func from_core_commit(commit: GitCommitNode, all_branches: Array[GitBranchInfo]) -> CommitGraphDisplayNode:
	var short := commit.id.substr(0, 7)
	var pointing: Array[String] = []
	var is_current_head := false
	for branch in all_branches:
		if branch.commit_id != null and str(branch.commit_id).to_lower() == commit.id.to_lower():
			pointing.append(branch.name)
			is_current_head = is_current_head or branch.is_current
	return CommitGraphDisplayNode.new(commit.id, short, commit.parent_ids, pointing, is_current_head,
			commit.subject, commit.author, commit.authored_at)
