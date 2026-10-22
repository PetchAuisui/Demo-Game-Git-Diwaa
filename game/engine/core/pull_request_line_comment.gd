class_name PullRequestLineComment
extends RefCounted
## ความเห็นรายบรรทัดใน diff ของ PR: on_new_side = บรรทัดฝั่งใหม่ (R) ไม่ใช่ฝั่งเก่า (L)
## is_pending = ยังอยู่ใน pending review ของผู้เขียน เห็นคนเดียวจนกว่าจะ Submit review

var path: String = ""
var line: int = 0
var on_new_side: bool = true
var author: String = ""
var body: String = ""
var at: float = 0.0
var is_pending: bool = false


func _init(p_path: String = "", p_line: int = 0, p_on_new_side: bool = true, p_author: String = "",
		p_body: String = "", p_at: float = 0.0, p_is_pending: bool = false) -> void:
	path = p_path
	line = p_line
	on_new_side = p_on_new_side
	author = p_author
	body = p_body
	at = p_at
	is_pending = p_is_pending


func copy() -> PullRequestLineComment:
	return PullRequestLineComment.new(path, line, on_new_side, author, body, at, is_pending)
