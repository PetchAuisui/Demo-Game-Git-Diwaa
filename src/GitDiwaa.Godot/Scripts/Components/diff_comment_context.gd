class_name DiffCommentContext
extends RefCounted
## ความเห็นรายบรรทัดของ PR: comments แสดงใต้บรรทัดที่ตรงกัน ส่วนปุ่ม + ที่เลขบรรทัดและกล่องเขียน
## จะมีก็ต่อเมื่อ submit ไม่ว่าง (PR ที่ยังเปิดอยู่)

var comments: Array[PullRequestLineComment] = []
var viewer: String = ""
## submit(path: String, line: int, on_new_side: bool, body: String, start_review: bool)
var submit: Callable = Callable()

var has_pending_review: bool:
	get:
		for comment in comments:
			if comment.is_pending and comment.author.to_lower() == viewer.to_lower():
				return true
		return false


func _init(p_comments: Array[PullRequestLineComment] = [], p_viewer: String = "",
		p_submit: Callable = Callable()) -> void:
	comments = p_comments
	viewer = p_viewer
	submit = p_submit
