class_name PullRequestActionResult
extends RefCounted
## ผลของการกระทำกับ pull request (review / close / merge) พร้อมข้อความอธิบายให้ UI แสดง

var success: bool = false
var message: String = ""
var pull_request: PullRequestInfo = null


func _init(p_success: bool = false, p_message: String = "", p_pull_request: PullRequestInfo = null) -> void:
	success = p_success
	message = p_message
	pull_request = p_pull_request
