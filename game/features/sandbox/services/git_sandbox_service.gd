class_name GitSandboxService
extends RefCounted
## Domain contract for Git Sandbox operations in the Godot UI.
## Decouples UI components from Real Git execution and filesystem details.
## เมธอดที่มีคำว่า (coroutine) เรียกด้วย await; ที่คืน OpResult ล้มเหลวพร้อมข้อความที่แสดงให้ผู้เล่นอ่านได้

var info: GitSessionInfo:
	get:
		return _get_info()
var is_initialized: bool:
	get:
		return _get_is_initialized()
## หน้า Remote Repository จำลอง (null เมื่อใช้ mock service)
var remote_host: GitRemoteHost:
	get:
		return _get_remote_host()
## บัญชีที่มีหลาย repo บน GitHub จำลอง (null เมื่อใช้ mock service)
var remote_account: GitRemoteAccount:
	get:
		return _get_remote_account()
var current_branch: String:
	get:
		return _get_current_branch()


func _get_info() -> GitSessionInfo:
	return null


func _get_is_initialized() -> bool:
	return false


func _get_remote_host() -> GitRemoteHost:
	return null


func _get_remote_account() -> GitRemoteAccount:
	return null


func _get_current_branch() -> String:
	return "main"


## (coroutine) คืน OpResult
## remote_seed = สถานะเริ่มต้นของคลังเวท (GitHub จำลอง) ของด่าน หรือ null = บัญชีว่าง
func initialize(_mission_id: String = "checkpoint-01", _attempt_id: String = "", _remote_seed: RemoteSeed = null) -> OpResult:
	push_error("GitSandboxService.initialize ยังไม่ได้ implement")
	return OpResult.failure("not implemented")


## (coroutine)
func execute(_command_line: String) -> GitCommandResult:
	push_error("GitSandboxService.execute ยังไม่ได้ implement")
	return null


## (coroutine)
func inspect() -> GitRepositorySnapshot:
	push_error("GitSandboxService.inspect ยังไม่ได้ implement")
	return null


## (coroutine)
func get_files() -> Array[FileDisplayItem]:
	push_error("GitSandboxService.get_files ยังไม่ได้ implement")
	return []


## (coroutine)
func get_workspace_entries() -> Array[WorkspaceEntryDisplayItem]:
	push_error("GitSandboxService.get_workspace_entries ยังไม่ได้ implement")
	return []


## (coroutine)
func get_commit_graph() -> Array[CommitGraphDisplayNode]:
	push_error("GitSandboxService.get_commit_graph ยังไม่ได้ implement")
	return []


## (coroutine) คืน OpResult
func write_file(_relative_path: String, _content: String) -> OpResult:
	push_error("GitSandboxService.write_file ยังไม่ได้ implement")
	return OpResult.failure("not implemented")


## คืน OpResult (value = เนื้อหา หรือ null เมื่อไม่พบไฟล์)
func read_file(_relative_path: String) -> OpResult:
	push_error("GitSandboxService.read_file ยังไม่ได้ implement")
	return OpResult.failure("not implemented")


func create_directory(_relative_path: String) -> OpResult:
	push_error("GitSandboxService.create_directory ยังไม่ได้ implement")
	return OpResult.failure("not implemented")


func rename_entry(_source_relative_path: String, _destination_relative_path: String) -> OpResult:
	push_error("GitSandboxService.rename_entry ยังไม่ได้ implement")
	return OpResult.failure("not implemented")


## คืน OpResult (value = true เมื่อลบจริง)
func delete_file(_relative_path: String) -> OpResult:
	push_error("GitSandboxService.delete_file ยังไม่ได้ implement")
	return OpResult.failure("not implemented")


## คืน OpResult (value = true เมื่อลบจริง)
func delete_entry(_relative_path: String, _is_directory: bool) -> OpResult:
	push_error("GitSandboxService.delete_entry ยังไม่ได้ implement")
	return OpResult.failure("not implemented")


## (coroutine) คืน OpResult
func reset() -> OpResult:
	push_error("GitSandboxService.reset ยังไม่ได้ implement")
	return OpResult.failure("not implemented")


func dispose() -> void:
	pass
