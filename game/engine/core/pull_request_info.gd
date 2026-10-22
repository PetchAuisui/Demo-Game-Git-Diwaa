class_name PullRequestInfo
extends RefCounted

var number: int = 0
var title: String = ""
var body: String = ""
var author: String = ""
var source_branch: String = ""
var target_branch: String = ""
var state: int = PullRequestState.OPEN
var is_approved: bool = false
var created_at: float = 0.0


func _init(p_number: int = 0, p_title: String = "", p_body: String = "", p_author: String = "",
		p_source_branch: String = "", p_target_branch: String = "", p_state: int = PullRequestState.OPEN,
		p_is_approved: bool = false, p_created_at: float = 0.0) -> void:
	number = p_number
	title = p_title
	body = p_body
	author = p_author
	source_branch = p_source_branch
	target_branch = p_target_branch
	state = p_state
	is_approved = p_is_approved
	created_at = p_created_at


func copy() -> PullRequestInfo:
	return PullRequestInfo.new(number, title, body, author, source_branch, target_branch, state, is_approved,
			created_at)
