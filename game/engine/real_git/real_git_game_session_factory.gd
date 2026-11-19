class_name RealGitGameSessionFactory
extends GitGameSessionFactory
## สร้าง session ใหม่ (หนึ่ง attempt ต่อหนึ่ง sandbox) ที่มีบัญชี GitHub จำลองของผู้เล่น

var _workspace_manager: GitWorkspaceManager
var _process_runner := GitProcessRunner.new()
var _player_name: String

## ข้อความข้อผิดพลาดของชื่อผู้เล่น หรือ "" เมื่อใช้ได้ (create จะล้มเหลวถ้าไม่ว่าง)
var validation_error: String = ""


## workspace_root = โฟลเดอร์เก็บ attempt ทั้งหมด
## player_name = ชื่อผู้เล่น ใช้เป็นเจ้าของ (host) ของ repo บน GitHub จำลอง
func _init(workspace_root: String = "", player_name: String = RemoteSeed.DEFAULT_OWNER) -> void:
	if not GitWorkspaceManager.is_valid_identifier(player_name):
		validation_error = "Use only ASCII letters, numbers, '-' and '_'."
	_workspace_manager = GitWorkspaceManager.new(workspace_root)
	_player_name = player_name


## สร้าง session ที่มีบัญชี GitHub จำลองของผู้เล่นแต่ยังไม่มี repo ผู้เล่นสร้างเอง
## ส่ง remote_seed เพื่อให้ GitHub จำลองเริ่มต้นตามนั้น (เช่น มีประวัติอยู่แล้ว)
## คืน OpResult (value = RealGitGameSession) เป็น coroutine
func create(mission_id: String, attempt_id: String, remote_seed: RemoteSeed = null) -> OpResult:
	if not validation_error.is_empty():
		return OpResult.failure(validation_error)
	if remote_seed == null:
		remote_seed = RemoteSeed.no_repository(_player_name)
	if not GitWorkspaceManager.is_valid_identifier(remote_seed.owner) \
			or not GitWorkspaceManager.is_valid_identifier(remote_seed.name):
		return OpResult.failure("Use only ASCII letters, numbers, '-' and '_'.")

	var attempt := _workspace_manager.create_attempt(mission_id, attempt_id)
	if not attempt.ok:
		return attempt
	var sandbox: GitSandbox = attempt.value
	if remote_seed.starts_without_repository:
		return OpResult.success(RealGitGameSession.new(sandbox, _workspace_manager, null, _process_runner, remote_seed))

	var created := await _workspace_manager.create_bare_remote(sandbox, _process_runner, "origin", remote_seed.clone_url)
	if not created.ok:
		return created
	var remote: LocalRemote = created.value
	var seeded := await RemoteSeeder.seed_remote(sandbox, remote, _process_runner, remote_seed)
	if not seeded.ok:
		return seeded
	if not remote_seed.retired_url.is_empty():
		var retired := await _workspace_manager.register_remote(sandbox, _process_runner,
				GitWorkspaceManager.retired_remote(sandbox, remote_seed.retired_url))
		if not retired.ok:
			return retired
	return OpResult.success(RealGitGameSession.new(sandbox, _workspace_manager, remote, _process_runner, remote_seed))
