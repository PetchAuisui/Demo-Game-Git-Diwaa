class_name CodeLine
extends RefCounted
## บรรทัดคำสั่งหนึ่งบรรทัด พร้อมคำอธิบายสั้นๆ ที่แสดงข้างๆ (ไม่ถูกคัดลอกไปด้วย)

var command: String = ""
## null เมื่อไม่มีคำอธิบาย
var hint: Variant = null


func _init(p_command: String = "", p_hint: Variant = null) -> void:
	command = p_command
	hint = p_hint
