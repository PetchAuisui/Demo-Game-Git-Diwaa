class_name CliTerminal
extends RefCounted
## ช่องทางเข้า/ออกของ Terminal CLI (แยกเพื่อให้เทสต์แทนที่ได้)


## null เมื่อ input จบ (EOF)
func read_line() -> Variant:
	return null


func write(_text: String) -> void:
	pass


func write_line(_text: String = "") -> void:
	pass


func write_error(_text: String) -> void:
	pass


func clear() -> void:
	pass
