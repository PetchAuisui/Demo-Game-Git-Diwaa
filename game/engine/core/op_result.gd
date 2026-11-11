class_name OpResult
extends RefCounted
## ผลของการกระทำที่อาจล้มเหลวด้วยข้อความที่ผู้เล่นอ่านได้ (แทน exception ของ C#)

var ok: bool = false
var message: String = ""
var value: Variant = null


func _init(p_ok: bool = false, p_message: String = "", p_value: Variant = null) -> void:
	ok = p_ok
	message = p_message
	value = p_value


static func success(p_value: Variant = null) -> OpResult:
	return OpResult.new(true, "", p_value)


static func failure(p_message: String) -> OpResult:
	return OpResult.new(false, p_message, null)
