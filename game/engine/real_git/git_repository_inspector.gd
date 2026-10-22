class_name GitRepositoryInspector
extends RefCounted
## อ่านสถานะ repo ของผู้เล่น (branch ไฟล์ commit) ด้วย git จริง

var _sandbox: GitSandbox
var _process_runner: GitProcessRunner


func _init(sandbox: GitSandbox, process_runner: GitProcessRunner) -> void:
	_sandbox = sandbox
	_process_runner = process_runner


func inspect() -> GitRepositorySnapshot:
	var git_metadata := _sandbox.player_repository_path.path_join(".git")
	if not FsUtil.dir_exists(git_metadata) and not FsUtil.file_exists(git_metadata):
		return GitRepositorySnapshot.new(false, null)

	var results := await _process_runner.run_all(_sandbox, [
		_request(["symbolic-ref", "--quiet", "--short", "HEAD"]),
		_request(["status", "--porcelain=v1", "-z", "--untracked-files=all"]),
		_request([
			"for-each-ref",
			"--format=%(refname:short)%1f%(HEAD)%1f%(objectname)%1f%(upstream:short)",
			"refs/heads",
			"refs/remotes",
		]),
		_request(["log", "--all", "-n", "200", "--format=%H%x1f%P%x1f%D%x1f%s%x1f%an%x1f%aI%x1e"]),
	])
	var current_branch: Variant = results[0].standard_output.strip_edges() if results[0].success else null
	return GitRepositorySnapshot.new(
			true, current_branch, _parse_files(results[1]), _parse_branches(results[2]), _parse_commits(results[3]))


func _request(arguments: Array[String]) -> Dictionary:
	return {"directory": _sandbox.player_repository_path, "arguments": arguments}


static func _parse_files(result: GitCommandResult) -> Array[GitFileStatus]:
	var files: Array[GitFileStatus] = []
	if not result.success or result.standard_output.is_empty():
		return files

	var records := result.standard_output.split(GitProcessRunner.NUL_CHAR, false)
	var index := 0
	while index < records.size():
		var record := records[index]
		if record.length() >= 4:
			var index_code := record[0]
			var working_code := record[1]
			files.append(GitFileStatus.new(record.substr(3), _parse_state(index_code), _parse_state(working_code)))
			if index_code == "R" or index_code == "C" or working_code == "R" or working_code == "C":
				index += 1
		index += 1
	return files


static func _parse_branches(result: GitCommandResult) -> Array[GitBranchInfo]:
	var branches: Array[GitBranchInfo] = []
	if not result.success:
		return branches

	for line in result.standard_output.split("\n", false):
		var fields := line.split("\u001f")
		if fields.size() >= 4:
			branches.append(GitBranchInfo.new(
					fields[0], fields[1] == "*", _null_if_empty(fields[2]), _null_if_empty(fields[3])))
	return branches


static func _parse_commits(result: GitCommandResult) -> Array[GitCommitNode]:
	var commits: Array[GitCommitNode] = []
	if not result.success:
		return commits

	for record in result.standard_output.split("\u001e", false):
		var fields := record.strip_edges().split("\u001f")
		if fields.size() != 6:
			continue
		var authored_at := GitTime.parse_iso(fields[5])
		if authored_at == 0.0:
			continue
		commits.append(GitCommitNode.new(
				fields[0], _split_non_empty(fields[1], " "), _split_non_empty(fields[2], ","),
				fields[3], fields[4], authored_at))
	return commits


static func _parse_state(value: String) -> int:
	match value:
		" ":
			return GitFileState.UNCHANGED
		"?":
			return GitFileState.UNTRACKED
		"A":
			return GitFileState.ADDED
		"M":
			return GitFileState.MODIFIED
		"D":
			return GitFileState.DELETED
		"R":
			return GitFileState.RENAMED
		"C":
			return GitFileState.COPIED
		"U":
			return GitFileState.UNMERGED
	return GitFileState.UNKNOWN


static func _null_if_empty(value: String) -> Variant:
	return null if value.strip_edges().is_empty() else value


static func _split_non_empty(value: String, separator: String) -> Array[String]:
	var parts: Array[String] = []
	for part in value.split(separator, false):
		var trimmed := part.strip_edges()
		if not trimmed.is_empty():
			parts.append(trimmed)
	return parts
