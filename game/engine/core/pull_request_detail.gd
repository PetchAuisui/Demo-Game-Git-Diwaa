class_name PullRequestDetail
extends RefCounted

var pull: PullRequestInfo = null
var commits: Array[RemoteCommitInfo] = []
var files: Array[PullRequestFileChange] = []
var diff: String = ""
var has_conflicts: bool = false
var reviews: Array[PullRequestReview] = []
## null เมื่อ merge ได้
var merge_blocked_reason: Variant = null
var line_comments: Array[PullRequestLineComment] = []


func _init(p_pull: PullRequestInfo = null, p_commits: Array[RemoteCommitInfo] = [],
		p_files: Array[PullRequestFileChange] = [], p_diff: String = "", p_has_conflicts: bool = false,
		p_reviews: Array[PullRequestReview] = [], p_merge_blocked_reason: Variant = null) -> void:
	pull = p_pull
	commits = p_commits
	files = p_files
	diff = p_diff
	has_conflicts = p_has_conflicts
	reviews = p_reviews
	merge_blocked_reason = p_merge_blocked_reason


func copy() -> PullRequestDetail:
	var clone := PullRequestDetail.new(pull, commits, files, diff, has_conflicts, reviews, merge_blocked_reason)
	clone.line_comments = line_comments
	return clone
