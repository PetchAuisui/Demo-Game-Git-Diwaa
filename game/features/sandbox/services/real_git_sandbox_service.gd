class_name RealGitSandboxService
extends GitSandboxService
## Real Git sandbox service that wraps the RealGit engine.
## Provides isolated workspace directory, runs real Git CLI, and produces snapshot ViewModels.

var _workspace_root: String
var _player_name: String
var _factory: RealGitGameSessionFactory
var _session: GitGameSession
var _last_snapshot: GitRepositorySnapshot
## จำไว้เพื่อให้ reset() สร้างคลังเวทแบบเดิมของด่านซ้ำ
var _mission_id := "checkpoint-01"
var _remote_seed: RemoteSeed


## custom_workspace_root = โฟลเดอร์เก็บ workspace (ค่าเริ่มต้น user://git-workspaces)
## player_name = ชื่อผู้เล่น ใช้เป็นเจ้าของ repo บน GitHub จำลอง (ยังไม่มีหน้า login จึงใช้ "user")
func _init(custom_workspace_root: String = "", player_name: String = RemoteSeed.DEFAULT_OWNER) -> void:
	_player_name = player_name

	if not custom_workspace_root.strip_edges().is_empty():
		_workspace_root = custom_workspace_root
		return

	var preferred_root := ProjectSettings.globalize_path("user://git-workspaces")
	if _is_writable(preferred_root):
		_workspace_root = preferred_root
		return

	# If user:// path cannot be written to, fallback to the system cache directory
	var fallback_root := OS.get_cache_dir().path_join("git-diwaa-workspaces")
	FsUtil.make_dirs(fallback_root)
	_workspace_root = fallback_root


static func _is_writable(directory: String) -> bool:
	if not FsUtil.make_dirs(directory):
		return false
	var test_file := directory.path_join(".test_%08x" % randi())
	if not FsUtil.write_text(test_file, "test"):
		return false
	DirAccess.remove_absolute(test_file)
	return true


func _get_info() -> GitSessionInfo:
	return _session.info if _session != null else null


func _get_is_initialized() -> bool:
	return _session != null


func _get_remote_host() -> GitRemoteHost:
	return _session.remote_host if _session != null else null


func _get_remote_account() -> GitRemoteAccount:
	return _session.remote_account if _session != null else null


func _get_current_branch() -> String:
	if _last_snapshot != null and _last_snapshot.current_branch != null:
		return _last_snapshot.current_branch
	return "main"


func initialize(mission_id: String = "checkpoint-01", attempt_id: String = "", remote_seed: RemoteSeed = null) -> OpResult:
	_mission_id = mission_id
	_remote_seed = remote_seed
	if attempt_id.is_empty():
		attempt_id = "attempt-%d" % int(Time.get_unix_time_from_system() * 1000.0)
	_factory = RealGitGameSessionFactory.new(_workspace_root, _player_name)

	if _session != null:
		_session.dispose()
		_session = null

	var created: OpResult = await _factory.create(mission_id, attempt_id,
			remote_seed.copy() if remote_seed != null else null)
	if not created.ok:
		return created
	_session = created.value
	_last_snapshot = await _session.inspect()
	return OpResult.success()


func execute(command_line: String) -> GitCommandResult:
	if not _ensure_session():
		return GitCommandResult.rejected(_NOT_INITIALIZED, command_line)
	var result := await _session.execute(command_line)
	_last_snapshot = await _session.inspect()
	return result


func inspect() -> GitRepositorySnapshot:
	if not _ensure_session():
		return GitRepositorySnapshot.new()
	_last_snapshot = await _session.inspect()
	return _last_snapshot


func get_files() -> Array[FileDisplayItem]:
	var items: Array[FileDisplayItem] = []
	if not _ensure_session():
		return items
	_last_snapshot = await _session.inspect()
	for file in _last_snapshot.files:
		items.append(FileDisplayItem.new(file.path, file.path.get_file(), file.index_state, file.working_tree_state))
	return items


func get_workspace_entries() -> Array[WorkspaceEntryDisplayItem]:
	var items: Array[WorkspaceEntryDisplayItem] = []
	if not _ensure_session():
		return items
	_last_snapshot = await _session.inspect()
	var status_by_path := {}
	for file in _last_snapshot.files:
		status_by_path[file.path] = file

	for entry in _session.files.list_entries():
		var status: GitFileStatus = status_by_path.get(entry.path, null)
		items.append(WorkspaceEntryDisplayItem.new(
				entry.path, entry.path.get_file(), entry.is_directory,
				status.index_state if status != null else GitFileState.UNKNOWN,
				status.working_tree_state if status != null else GitFileState.UNKNOWN))
	return items


func get_commit_graph() -> Array[CommitGraphDisplayNode]:
	var nodes: Array[CommitGraphDisplayNode] = []
	if not _ensure_session():
		return nodes
	_last_snapshot = await _session.inspect()
	for commit in _last_snapshot.commits:
		nodes.append(CommitGraphDisplayNode.from_core_commit(commit, _last_snapshot.branches))
	return nodes


func write_file(relative_path: String, content: String) -> OpResult:
	if not _ensure_session():
		return OpResult.failure(_NOT_INITIALIZED)
	var written := _session.files.write_all_text(relative_path, content)
	if written.ok:
		_last_snapshot = await _session.inspect()
	return written


func read_file(relative_path: String) -> OpResult:
	if not _ensure_session():
		return OpResult.failure(_NOT_INITIALIZED)
	return _session.files.read_all_text(relative_path)


func create_directory(relative_path: String) -> OpResult:
	if not _ensure_session():
		return OpResult.failure(_NOT_INITIALIZED)
	return _session.files.create_directory(relative_path)


func rename_entry(source_relative_path: String, destination_relative_path: String) -> OpResult:
	if not _ensure_session():
		return OpResult.failure(_NOT_INITIALIZED)
	return _session.files.move(source_relative_path, destination_relative_path)


func delete_file(relative_path: String) -> OpResult:
	if not _ensure_session():
		return OpResult.failure(_NOT_INITIALIZED)
	return _session.files.delete(relative_path)


func delete_entry(relative_path: String, is_directory: bool) -> OpResult:
	if not _ensure_session():
		return OpResult.failure(_NOT_INITIALIZED)
	if is_directory:
		return _session.files.delete_directory(relative_path, true)
	return _session.files.delete(relative_path)


func reset() -> OpResult:
	return await initialize(_mission_id, "", _remote_seed)


func dispose() -> void:
	if _session != null:
		_session.dispose()
		_session = null


const _NOT_INITIALIZED := "Git sandbox session has not been initialized. Call initialize() first."


func _ensure_session() -> bool:
	if _session == null:
		push_error(_NOT_INITIALIZED)
		return false
	return true
