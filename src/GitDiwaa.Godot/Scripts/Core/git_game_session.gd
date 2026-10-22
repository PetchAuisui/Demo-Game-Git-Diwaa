class_name GitGameSession
extends RefCounted
## session ของเกม: คำสั่ง git จริงใน sandbox ไฟล์ของผู้เล่น และ GitHub จำลอง

var info: GitSessionInfo = null
var files: PlayerFileSystem = null
## host ของ repo แรกจาก seed ของด่าน (null ถ้าบัญชีเริ่มโดยไม่มี repo ใช้ remote_account แทน)
var remote_host: GitRemoteHost = null
## บัญชีที่มีหลาย repo บน GitHub จำลอง (null ถ้า session ไม่รองรับ)
var remote_account: GitRemoteAccount = null


## คืน GitCommandResult (coroutine)
func execute(_command_line: String) -> GitCommandResult:
	push_error("GitGameSession.execute ยังไม่ได้ implement")
	return null


## คืน GitRepositorySnapshot (coroutine)
func inspect() -> GitRepositorySnapshot:
	push_error("GitGameSession.inspect ยังไม่ได้ implement")
	return null


func dispose() -> void:
	pass
