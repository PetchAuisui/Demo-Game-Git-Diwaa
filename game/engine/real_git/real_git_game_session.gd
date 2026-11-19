class_name RealGitGameSession
extends GitGameSession
## session ที่รัน git จริงใน sandbox ของ attempt หนึ่ง

var _sandbox: GitSandbox
var _remotes: RemoteRegistry
var _policy: GitCommandPolicy
var _process_runner: GitProcessRunner
var _inspector: GitRepositoryInspector


func _init(sandbox: GitSandbox, workspace: GitWorkspaceManager, remote: LocalRemote,
		process_runner: GitProcessRunner, remote_seed: RemoteSeed) -> void:
	_sandbox = sandbox
	_remotes = RemoteRegistry.new(remote)
	if remote_seed != null and not remote_seed.retired_url.is_empty():
		_remotes.retired.append(GitWorkspaceManager.retired_remote(sandbox, remote_seed.retired_url))
	_policy = GitCommandPolicy.new(sandbox, _remotes)
	_process_runner = process_runner
	_inspector = GitRepositoryInspector.new(sandbox, process_runner)
	files = SandboxPlayerFileSystem.new(sandbox)
	var primary: SimulatedGitHubHost = null
	if remote != null:
		primary = SimulatedGitHubHost.new(sandbox, remote, process_runner, remote_seed)
	remote_host = primary
	remote_account = SimulatedGitHubAccount.new(sandbox, workspace, process_runner, _remotes, remote_seed, primary)
	info = GitSessionInfo.new(sandbox.mission_id, sandbox.attempt_id, sandbox.player_repository_path,
			remote.alias_url if remote != null else "")


func execute(command_line: String) -> GitCommandResult:
	var tokenized := GitCommandLine.tokenize(command_line)
	if not tokenized.ok:
		return GitCommandResult.rejected(tokenized.message, command_line)

	var tokens: Array[String] = []
	tokens.assign(tokenized.value)
	if tokens.is_empty() or tokens[0] != "git":
		return GitCommandResult.rejected("Command must start with 'git'.", command_line)

	var arguments: Array[String] = []
	arguments.assign(tokens.slice(1))
	var validation_error := _policy.validate(arguments)
	if not validation_error.is_empty():
		return GitCommandResult.rejected(validation_error, command_line)

	var working_directory := _sandbox.player_repository_path
	if arguments[0] == "clone":
		working_directory = _sandbox.attempt_root
		arguments = ["clone", arguments[1], _sandbox.player_repository_path]

	var result := await _process_runner.run(_sandbox, working_directory, arguments)
	return _hide_internal_remote_path(result)


func inspect() -> GitRepositorySnapshot:
	return await _inspector.inspect()


func _hide_internal_remote_path(result: GitCommandResult) -> GitCommandResult:
	var output := result.standard_output
	var error := result.standard_error
	for remote in _remotes.remotes + _remotes.retired:
		output = output.replace(remote.bare_repository_path, remote.alias_url)
		error = error.replace(remote.bare_repository_path, remote.alias_url)
	return result.with_streams(output, error)
