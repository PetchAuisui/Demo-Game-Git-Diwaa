class_name PullRequestReview
extends RefCounted

var reviewer: String = ""
var verdict: int = ReviewVerdict.COMMENTED
var body: String = ""
var at: float = 0.0


func _init(p_reviewer: String = "", p_verdict: int = ReviewVerdict.COMMENTED, p_body: String = "",
		p_at: float = 0.0) -> void:
	reviewer = p_reviewer
	verdict = p_verdict
	body = p_body
	at = p_at
