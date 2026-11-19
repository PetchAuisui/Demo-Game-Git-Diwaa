class_name GitWorkspaceManager
extends RefCounted
## สร้างโฟลเดอร์ sandbox ของแต่ละ attempt (repo ของผู้เล่น, remote จำลอง, gitconfig แยก)

var root_path: String = ""


func _init(p_root_path: String = "") -> void:
	root_path = FsUtil.full_path(p_root_path)


static func is_valid_identifier(value: String) -> bool:
	if value.strip_edges().is_empty():
		return false
	for index in value.length():
		var character := value[index]
		if not GitCommandPolicy._is_ascii_alphanumeric(character) and character != "-" and character != "_":
			return false
	return true


## คืน OpResult (value = GitSandbox)
func create_attempt(mission_id: String, attempt_id: String) -> OpResult:
	if not is_valid_identifier(mission_id) or not is_valid_identifier(attempt_id):
		return OpResult.failure("Use only ASCII letters, numbers, '-' and '_'.")

	var attempt_root := root_path.path_join(mission_id).path_join(attempt_id)
	var inside := ensure_inside_root(attempt_root)
	if not inside.ok:
		return inside
	if FsUtil.dir_exists(attempt_root) and FsUtil.dir_has_entries(attempt_root):
		return OpResult.failure("Attempt already exists and is not empty: " + attempt_root)

	var player_repository := attempt_root.path_join("player-repo")
	var remotes := attempt_root.path_join("remotes")
	var config := attempt_root.path_join("config").path_join("gitconfig")
	var hooks := attempt_root.path_join("disabled-hooks")

	if not (FsUtil.make_dirs(player_repository) and FsUtil.make_dirs(remotes)
			and FsUtil.make_dirs(config.get_base_dir()) and FsUtil.make_dirs(hooks)):
		return OpResult.failure("Could not create the sandbox folders under " + attempt_root)
	if not FsUtil.write_text(config, "[init]\n\tdefaultBranch = main\n"):
		return OpResult.failure("Could not write the sandbox gitconfig: " + config)

	return OpResult.success(GitSandbox.new(
			mission_id, attempt_id, attempt_root, player_repository, remotes, config, hooks))


## สร้าง bare repository ของ remote จำลอง (coroutine) คืน OpResult (value = LocalRemote)
func create_bare_remote(sandbox: GitSandbox, runner: GitProcessRunner, name: String, alias_url: String) -> OpResult:
	if not is_valid_identifier(name):
		return OpResult.failure("Use only ASCII letters, numbers, '-' and '_'.")
	var inside := ensure_inside_root(sandbox.attempt_root)
	if not inside.ok:
		return inside

	var bare_path := sandbox.remotes_root.path_join(name + ".git")
	if FsUtil.dir_exists(bare_path) and FsUtil.dir_has_entries(bare_path):
		return OpResult.failure("Remote already exists: " + bare_path)

	FsUtil.make_dirs(bare_path)
	var init := await runner.run(sandbox, sandbox.remotes_root,
			["init", "--bare", "--initial-branch=main", bare_path] as Array[String])
	if not init.success:
		return OpResult.failure(init.output)

	var remote := LocalRemote.new(name, alias_url, bare_path)
	var registered := await register_remote(sandbox, runner, remote)
	if not registered.ok:
		return registered
	return OpResult.success(remote)


## ที่อยู่เก่าของคลัง (RemoteSeed.retired_url) ชี้ไปยัง bare repo ที่ไม่มีอยู่ → fetch/push ล้มเหลวทันที ไม่ออกเน็ต
static func retired_remote(sandbox: GitSandbox, url: String) -> LocalRemote:
	return LocalRemote.new("ruins", url, sandbox.remotes_root.path_join("ruins.git"))


## ผูก URL จำลอง (alias) กับ bare repository ใน gitconfig ของ sandbox (insteadOf)
func register_remote(sandbox: GitSandbox, runner: GitProcessRunner, remote: LocalRemote) -> OpResult:
	var inside := ensure_inside_root(sandbox.attempt_root)
	if not inside.ok:
		return inside
	inside = ensure_inside_root(remote.bare_repository_path)
	if not inside.ok:
		return inside

	var rewrite := await runner.run(sandbox, sandbox.attempt_root, [
		"config", "--file", sandbox.git_config_path,
		"url.%s.insteadOf" % remote.bare_repository_path,
		remote.alias_url,
	] as Array[String])
	if not rewrite.success:
		return OpResult.failure(rewrite.output)
	return OpResult.success()


func ensure_inside_root(path: String) -> OpResult:
	var full := FsUtil.full_path(path)
	var root_with_separator := root_path.rstrip("/") + "/"
	if not FsUtil.same_path(full, root_path) and not FsUtil.starts_with_path(full, root_with_separator):
		return OpResult.failure("Path escapes the Git-Diwaa workspace root.")
	return OpResult.success()
