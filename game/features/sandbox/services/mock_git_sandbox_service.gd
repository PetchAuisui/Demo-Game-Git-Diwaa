class_name MockGitSandboxService
extends GitSandboxService
## Mock implementation of GitSandboxService for UI testing, previews, and unit tests.
## Demonstrates OOP polymorphism and decouples UI testing from real OS process execution.

const FIRST_COMMIT_ID := "a1b2c3d4e5f67890123456789012345678901234"

var _files: Array[FileDisplayItem] = []
var _commits: Array[CommitGraphDisplayNode] = []
var _file_contents: Dictionary = {}
var _directories: Dictionary = {}
var _is_initialized_value := true
var _current_branch_value := "main"


func _init() -> void:
	_seed_sample_data()


func _get_info() -> GitSessionInfo:
	return GitSessionInfo.new("mock-01", "mock-attempt-1", "/tmp/mock-git-repo", "file:///tmp/mock-remote.git")


func _get_is_initialized() -> bool:
	return _is_initialized_value


func _get_current_branch() -> String:
	return _current_branch_value


func _seed_sample_data() -> void:
	_files.clear()
	_files.append(FileDisplayItem.new("README.md", "README.md", GitFileState.UNCHANGED, GitFileState.UNCHANGED))
	_files.append(FileDisplayItem.new("src/game.gd", "game.gd", GitFileState.MODIFIED, GitFileState.MODIFIED))
	_files.append(FileDisplayItem.new("notes.txt", "notes.txt", GitFileState.UNTRACKED, GitFileState.UNTRACKED))
	_file_contents.clear()
	_file_contents["README.md"] = "# Git-Diwaa\n"
	_file_contents["src/game.gd"] = "class_name Game\nextends Node\n"
	_file_contents["notes.txt"] = "Learn git status\n"
	_directories.clear()
	_directories["src"] = true

	_commits.clear()
	var base_date := GitTime.now() - 30.0 * 60.0
	_commits.append(CommitGraphDisplayNode.new(
			FIRST_COMMIT_ID, "a1b2c3d", [] as Array[String], [] as Array[String], false,
			"Initial commit: Add project skeleton", "learner <learner@diwaa.dev>", base_date))
	_commits.append(CommitGraphDisplayNode.new(
			"b2c3d4e5f67890123456789012345678901234a1", "b2c3d4e", [FIRST_COMMIT_ID] as Array[String],
			["main"] as Array[String], true,
			"feat: Add core mechanics and files", "learner <learner@diwaa.dev>", base_date + 15.0 * 60.0))


func initialize(_mission_id: String = "checkpoint-01", _attempt_id: String = "", _remote_seed: RemoteSeed = null) -> OpResult:
	_is_initialized_value = true
	_seed_sample_data()
	return OpResult.success()


func execute(command_line: String) -> GitCommandResult:
	var trimmed := command_line.strip_edges()

	if trimmed == "git status":
		var output := "On branch %s\nChanges not staged for commit:\n  modified:   src/game.gd\n\nUntracked files:\n  notes.txt\n" % _current_branch_value
		return GitCommandResult.new(true, 0, output, "", trimmed)

	if trimmed.begins_with("git checkout -b ") or trimmed.begins_with("git switch -c "):
		var parts := trimmed.split(" ", false)
		if parts.size() >= 4:
			_current_branch_value = parts[3]
			return GitCommandResult.new(true, 0, "Switched to a new branch '%s'" % _current_branch_value, "", trimmed)

	if trimmed == "git --version" or trimmed == "git version":
		return GitCommandResult.new(true, 0, "git version 2.45.0 (Git-Diwaa Mock)", "", trimmed)

	if trimmed.begins_with("git commit"):
		var new_id := "%08x%08x%08x%08x" % [randi(), randi(), randi(), randi()]
		var subject := "New commit"
		if trimmed.contains("-m"):
			subject = trimmed.split("-m")[1].strip_edges().trim_prefix("\"").trim_suffix("\"") \
					.trim_prefix("'").trim_suffix("'")
		var parent_ids: Array[String] = []
		if not _commits.is_empty():
			parent_ids.append(_commits[0].id)
		_commits.insert(0, CommitGraphDisplayNode.new(
				new_id, new_id.substr(0, 7), parent_ids, [_current_branch_value] as Array[String], true,
				subject, "learner <learner@diwaa.dev>", GitTime.now()))
		return GitCommandResult.new(true, 0, "[%s %s] commit created" % [_current_branch_value, new_id.substr(0, 7)], "", trimmed)

	return GitCommandResult.new(true, 0, "Executed: " + trimmed, "", trimmed)


func inspect() -> GitRepositorySnapshot:
	var files: Array[GitFileStatus] = []
	for item in _files:
		files.append(GitFileStatus.new(item.path, item.index_state, item.working_tree_state))
	var branches: Array[GitBranchInfo] = [
		GitBranchInfo.new(_current_branch_value, true, _commits[0].id if not _commits.is_empty() else null, null),
	]
	var commits: Array[GitCommitNode] = []
	for item in _commits:
		commits.append(GitCommitNode.new(item.id, item.parent_ids, item.branches, item.subject, item.author, item.authored_at))
	return GitRepositorySnapshot.new(true, _current_branch_value, files, branches, commits)


func get_files() -> Array[FileDisplayItem]:
	var copy: Array[FileDisplayItem] = []
	copy.assign(_files)
	return copy


func get_workspace_entries() -> Array[WorkspaceEntryDisplayItem]:
	var entries: Array[WorkspaceEntryDisplayItem] = []
	for path: String in _directories:
		entries.append(WorkspaceEntryDisplayItem.new(path, path.get_file(), true, GitFileState.UNCHANGED, GitFileState.UNCHANGED))
	for file in _files:
		entries.append(WorkspaceEntryDisplayItem.new(file.path, file.file_name, false, file.index_state, file.working_tree_state))
	entries.sort_custom(func(a: WorkspaceEntryDisplayItem, b: WorkspaceEntryDisplayItem) -> bool: return a.path < b.path)
	return entries


func get_commit_graph() -> Array[CommitGraphDisplayNode]:
	var copy: Array[CommitGraphDisplayNode] = []
	copy.assign(_commits)
	return copy


func write_file(relative_path: String, content: String) -> OpResult:
	var existing := _find_file(relative_path)
	if existing != null:
		_files.erase(existing)
	var state := GitFileState.UNTRACKED if existing == null else GitFileState.MODIFIED
	_files.append(FileDisplayItem.new(relative_path, relative_path.get_file(), state, state))
	_file_contents[relative_path] = content
	_add_parent_directories(relative_path)
	return OpResult.success()


func read_file(relative_path: String) -> OpResult:
	return OpResult.success(_file_contents.get(relative_path, null))


func create_directory(relative_path: String) -> OpResult:
	if _find_file(relative_path) != null or _directories.has(relative_path):
		return OpResult.failure("มีไฟล์หรือโฟลเดอร์ชื่อ '%s' อยู่แล้ว" % relative_path)
	_directories[relative_path] = true
	_add_parent_directories(relative_path)
	return OpResult.success()


func rename_entry(source_relative_path: String, destination_relative_path: String) -> OpResult:
	if _find_file(destination_relative_path) != null or _directories.has(destination_relative_path):
		return OpResult.failure("มีไฟล์หรือโฟลเดอร์ชื่อ '%s' อยู่แล้ว" % destination_relative_path)

	var file := _find_file(source_relative_path)
	if file != null:
		_files.erase(file)
		var moved := file.copy()
		moved.path = destination_relative_path
		moved.file_name = destination_relative_path.get_file()
		_files.append(moved)
		_file_contents[destination_relative_path] = _file_contents[source_relative_path]
		_file_contents.erase(source_relative_path)
	elif _directories.has(source_relative_path):
		var prefix := source_relative_path + "/"
		for path: String in _directories.keys():
			if path == source_relative_path or path.begins_with(prefix):
				_directories.erase(path)
				_directories[destination_relative_path + path.substr(source_relative_path.length())] = true

		for item: FileDisplayItem in _files.duplicate():
			if item.path.begins_with(prefix):
				var new_path: String = destination_relative_path + item.path.substr(source_relative_path.length())
				_files.erase(item)
				var renamed := item.copy()
				renamed.path = new_path
				renamed.file_name = new_path.get_file()
				_files.append(renamed)
				_file_contents[new_path] = _file_contents[item.path]
				_file_contents.erase(item.path)
	else:
		return OpResult.failure("ไม่พบ '%s'" % source_relative_path)

	_add_parent_directories(destination_relative_path)
	return OpResult.success()


func delete_file(relative_path: String) -> OpResult:
	var existing := _find_file(relative_path)
	if existing != null:
		_files.erase(existing)
		_file_contents.erase(relative_path)
		return OpResult.success(true)
	return OpResult.success(false)


func delete_entry(relative_path: String, is_directory: bool) -> OpResult:
	if not is_directory:
		return delete_file(relative_path)
	if not _directories.has(relative_path):
		return OpResult.success(false)

	var prefix := relative_path + "/"
	for path: String in _directories.keys():
		if path == relative_path or path.begins_with(prefix):
			_directories.erase(path)
	for file: FileDisplayItem in _files.duplicate():
		if file.path.begins_with(prefix):
			_files.erase(file)
			_file_contents.erase(file.path)
	return OpResult.success(true)


func reset() -> OpResult:
	_seed_sample_data()
	return OpResult.success()


func _find_file(path: String) -> FileDisplayItem:
	for file in _files:
		if file.path == path:
			return file
	return null


func _add_parent_directories(path: String) -> void:
	var current := path.get_base_dir()
	while not current.is_empty() and current != ".":
		_directories[current] = true
		current = current.get_base_dir()
