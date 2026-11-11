class_name RemoteRules
extends RefCounted
## กติกา pull request ของ GitHub จำลอง ค่าเริ่มต้นเหมาะกับ sandbox คนเดียว
## (review เป็นทางเลือกและรีวิว PR ตัวเองได้) ด่านที่ต้องการ code review จริงเปิดโหมดเข้มได้

var require_approval: bool = false
var allow_self_review: bool = true


func _init(p_require_approval: bool = false, p_allow_self_review: bool = true) -> void:
	require_approval = p_require_approval
	allow_self_review = p_allow_self_review
