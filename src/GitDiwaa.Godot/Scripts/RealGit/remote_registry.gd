class_name RemoteRegistry
extends RefCounted
## remote ทั้งหมดของ session (repo จาก seed ถ้ามี กับ repo ที่ผู้เล่นสร้างเพิ่ม)
## ใช้ร่วมกันระหว่าง policy, session และบัญชี

var remotes: Array[LocalRemote] = []


func _init(primary: LocalRemote = null) -> void:
	if primary != null:
		remotes.append(primary)


func add(remote: LocalRemote) -> void:
	remotes.append(remote)
