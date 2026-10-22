class_name RemoteSeeder
extends RefCounted
## สร้างประวัติเริ่มต้นของ remote จำลองตาม RemoteSeed (commit ตามลำดับแล้ว push ขึ้น bare repository)


## คืน OpResult (coroutine)
static func seed_remote(sandbox: GitSandbox, remote: LocalRemote, runner: GitProcessRunner,
		remote_seed: RemoteSeed) -> OpResult:
	if remote_seed.commits.is_empty():
		return OpResult.success()

	var work := sandbox.attempt_root.path_join("seed-work")
	FsUtil.make_dirs(work)
	var outcome := await _seed_in(sandbox, remote, runner, remote_seed, work)
	FsUtil.delete_recursive(work)
	return outcome


static func _seed_in(sandbox: GitSandbox, remote: LocalRemote, runner: GitProcessRunner,
		remote_seed: RemoteSeed, work: String) -> OpResult:
	var step := await _run(runner, sandbox, work, ["init", "--initial-branch=main"] as Array[String])
	if not step.ok:
		return step

	var created: Array[String] = []
	for commit in remote_seed.commits:
		if created.is_empty() and commit.branch == "main":
			created.append("main")
		elif not created.has(commit.branch):
			created.append(commit.branch)
			step = await _run(runner, sandbox, work, ["switch", "-c", commit.branch, "main"] as Array[String])
			if not step.ok:
				return step
		else:
			step = await _run(runner, sandbox, work, ["switch", commit.branch] as Array[String])
			if not step.ok:
				return step

		for path: String in commit.files:
			var full := work.path_join(path)
			FsUtil.make_dirs(full.get_base_dir())
			FsUtil.write_text(full, commit.files[path])

		var date := GitTime.git_date(commit.date)
		var environment := {"GIT_AUTHOR_DATE": date, "GIT_COMMITTER_DATE": date}
		step = await _run(runner, sandbox, work, ["add", "."] as Array[String])
		if not step.ok:
			return step
		step = await _run(runner, sandbox, work, [
			"-c", "user.name=" + commit.author,
			"-c", "user.email=%s@git-diwaa.local" % commit.author.to_lower(),
			"commit", "-m", commit.message,
		] as Array[String], environment)
		if not step.ok:
			return step

	var push_arguments: Array[String] = ["push", remote.bare_repository_path]
	for branch in created:
		push_arguments.append("%s:%s" % [branch, branch])
	return await _run(runner, sandbox, work, push_arguments)


static func _run(runner: GitProcessRunner, sandbox: GitSandbox, directory: String, arguments: Array[String],
		environment: Dictionary = {}) -> OpResult:
	var result := await runner.run(sandbox, directory, arguments, environment)
	if not result.success:
		return OpResult.failure("Seeding failed: " + result.output)
	return OpResult.success()
