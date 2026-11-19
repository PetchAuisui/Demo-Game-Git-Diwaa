extends SceneTree
## Integration tests ของ engine Git จริง (ไม่ต้องมี UI)
##
## รัน:
##   godot --headless --path game --import        # ครั้งแรกหลัง clone
##   godot --headless --path game --script $PWD/tests/engine/run_tests.gd
## (หรือใส่ path เต็มของไฟล์นี้หลัง --script)

const WATCHDOG_SECONDS := 300.0

var _test_root: String
var _passed := 0
var _total := 0
var _failures: Array[String] = []
var _current := ""
var _factory: RealGitGameSessionFactory
## session หลักที่หลายเทสต์ใช้ร่วมกัน (เหมือนตัวแปร session ของเทสต์เดิม)
var _session: GitGameSession


func _initialize() -> void:
	_test_root = OS.get_cache_dir().path_join("git-diwaa-tests").path_join(
			"%08x%08x" % [randi(), Time.get_ticks_usec()])
	create_timer(WATCHDOG_SECONDS).timeout.connect(func() -> void:
		printerr("FAIL watchdog: tests did not finish within %d seconds" % int(WATCHDOG_SECONDS))
		FsUtil.delete_recursive(_test_root)
		quit(1))
	_run()


func _run() -> void:
	_factory = RealGitGameSessionFactory.new(_test_root)
	_session = await _create("act1", "player", RemoteSeed.empty())

	await _test("session starts outside a repository", _t_outside_repository)
	await _test("Git version and config are real and isolated", _t_version_and_config)
	await _test("unsafe commands and paths are rejected", _t_unsafe_commands)
	await _test("init, files, status, add and commit update snapshot", _t_init_add_commit)
	await _test("branch and merge produce a real commit graph", _t_branch_merge)
	await _test("diff, restore and reset affect only the player repository", _t_diff_restore_reset)
	await _test("local remote supports push, fetch and pull", _t_push_fetch_pull)
	await _test("clone works against the session's local bare remote", _t_clone)
	await _test("default remote is an empty GitHub repository owned by the player", _t_empty_remote)
	await _test("default session starts with no repository until the player creates one", _t_no_repository)
	await _test("pushing from the player repository shows up on the remote host", _t_publish)
	await _test("the player name becomes the owner of the remote repository", _t_player_owner)
	await _test("simulated GitHub clones seeded history and never reaches the real GitHub", _t_seeded_clone)
	await _test("account creates extra repositories that can be pushed to and cloned", _t_account_repositories)
	await _test("remote host exposes repository, branches, commits and files", _t_host_listing)
	await _test("pull requests: detail, review rules, merge and branch cleanup", _t_pull_requests)
	await _test("pull request reports conflicts and can be closed", _t_pull_request_conflicts)
	await _test("line comments post immediately or wait in a pending review until it is submitted", _t_line_comments)
	await _test("pull request file list and diff use the real (unquoted) path for non-ASCII file names", _t_thai_paths)
	await _test("solo player can review and merge their own pull requests by default", _t_solo_player)
	await _test("pull request needs commits beyond its own base branch", _t_pull_request_base)
	await _test("file API blocks traversal and Git metadata", _t_file_api_blocks)
	await _test("workspace API manages folders and renames safely", _t_workspace_api)
	await _test("attempt identifiers and duplicate attempts are rejected", _t_attempt_identifiers)
	await _test("level 1 mission step 1 accepts only the exact version spell", _t_level1_step1)
	await _test("clear scoring: no timer is not a timeout, expiry gives 2 stars", _t_clear_scoring)
	await _test("level 1 mission step 2 needs name, email and a non-empty name check", _t_level1_step2)
	await _test("state objectives follow the real repository, not the command text", _t_state_objectives)
	await _test("state objectives are judged in story order and can require a spell", _t_state_objective_order)

	FsUtil.delete_recursive(_test_root)
	if not _failures.is_empty():
		printerr("FAIL %d of %d tests failed:" % [_failures.size(), _total])
		for failure in _failures:
			printerr("  " + failure)
		quit(1)
		return
	print("\n%d/%d real-Git integration tests passed" % [_passed, _total])
	quit(0)


func _test(test_name: String, body: Callable) -> void:
	_total += 1
	_current = test_name
	var before := _failures.size()
	await body.call()
	if _failures.size() == before:
		_passed += 1
		print("PASS " + test_name)
	else:
		print("FAIL " + test_name)


# ───────────── ตัวช่วย assert ─────────────


func _check(condition: bool, message: String = "Expected true.") -> bool:
	if not condition:
		_failures.append("%s: %s" % [_current, message])
	return condition


func _equal(expected: Variant, actual: Variant) -> bool:
	return _check(expected == actual, "Expected '%s', got '%s'." % [expected, actual])


func _contains(actual: String, expected: String) -> bool:
	return _check(actual.to_lower().contains(expected.to_lower()),
			"Expected text containing '%s', got '%s'." % [expected, actual])


# ───────────── ตัวช่วยสร้าง session / รันคำสั่ง ─────────────


func _create(mission: String, attempt: String, remote_seed: RemoteSeed = null,
		factory: RealGitGameSessionFactory = null) -> GitGameSession:
	var result: OpResult = await (factory if factory != null else _factory).create(mission, attempt, remote_seed)
	if not result.ok:
		_failures.append("could not create session %s/%s: %s" % [mission, attempt, result.message])
		return null
	return result.value


func _run_git(command: String, session: GitGameSession = null) -> GitCommandResult:
	var target := session if session != null else _session
	var result := await target.execute(command)
	_check(result.success, "%s\n%s" % [command, result.output])
	return result


func _reject(command: String, expected_message: String) -> void:
	var result := await _session.execute(command)
	_check(not result.success, "Expected '%s' to be rejected." % command)
	_equal(-1, result.exit_code)
	_contains(result.output, expected_message)


func _write(path: String, content: String, session: GitGameSession = null) -> void:
	var result := (session if session != null else _session).files.write_all_text(path, content)
	_check(result.ok, "write %s: %s" % [path, result.message])


func _read(path: String, session: GitGameSession = null) -> Variant:
	var result := (session if session != null else _session).files.read_all_text(path)
	_check(result.ok, "read %s: %s" % [path, result.message])
	return result.value


func _commit_file(session: GitGameSession, path: String, content: String, message: String) -> void:
	_write(path, content, session)
	await _run_git("git add " + path, session)
	await _run_git("git commit -m \"%s\"" % message, session)


## ตั้งชื่อ, git init, commit แรก แล้ว push main ขึ้น origin เหมือนที่ผู้เล่นทำในเกม
func _publish_main(session: GitGameSession) -> void:
	await _run_git("git config --global user.name \"Git Diwaa Player\"", session)
	await _run_git("git config --global user.email player@git-diwaa.local", session)
	await _run_git("git init", session)
	await _commit_file(session, "README.md", "# my-project\n", "first commit")
	await _run_git("git remote add origin " + session.info.remote_url, session)
	await _run_git("git push -u origin main", session)


## repo ตัวอย่างสำหรับเทสต์: main มี 2 commit และ feature/login อีก 1 commit
func _sample_seed(now: float, rules: RemoteRules = null) -> RemoteSeed:
	var commits: Array[SeedCommit] = [
		SeedCommit.new("main", "user", "Initial commit", now - 2 * 86400.0, {
			"README.md": "# my-project\n\nA sample project.\n",
			"app.py": "print('hello')\n",
		}),
		SeedCommit.new("main", "user", "Update README", now - 2 * 86400.0 + 3 * 3600.0, {
			"README.md": "# my-project\n\nA sample project.\nSee notes.md.\n",
			"notes.md": "# Notes\n",
		}),
		SeedCommit.new("feature/login", "teammate", "Add login draft", now - 86400.0, {
			"login.py": "print('login')\n",
		}),
	]
	var remote_seed := RemoteSeed.new("user", "my-project", "", commits)
	remote_seed.rules = rules if rules != null else RemoteRules.new()
	return remote_seed


# ───────────── เทสต์ ─────────────


func _t_outside_repository() -> void:
	var snapshot := await _session.inspect()
	_check(not snapshot.is_initialized)
	_equal("act1", _session.info.mission_id)
	_equal("player", _session.info.attempt_id)
	_equal("https://magic-vault.com/user/my-project.git", _session.info.remote_url)


func _t_version_and_config() -> void:
	_contains((await _run_git("git --version")).output, "git version")
	_contains((await _run_git("git version")).output, "git version")
	await _run_git("git config --global user.name \"Git Diwaa Player\"")
	await _run_git("git config --global user.email player@git-diwaa.local")
	_equal("Git Diwaa Player", (await _run_git("git config --global user.name")).output)
	_equal("player@git-diwaa.local", (await _run_git("git config --global user.email")).output)


func _t_unsafe_commands() -> void:
	await _reject("pwd", "start with 'git'")
	await _reject("git help", "not enabled")
	await _reject("git add ../outside.txt", "escapes")
	await _reject("git --git-dir=/tmp status", "not enabled")
	await _reject("git remote add origin https://example.com/repo.git", "https://magic-vault.com/user/my-project.git")
	await _reject("git remote add origin https://git-diwaa.local/other.git", "registered")


func _t_init_add_commit() -> void:
	await _run_git("git init")
	_write("README.md", "hello Git-Diwaa\n")

	var untracked := await _session.inspect()
	_check(untracked.is_initialized)
	_equal("main", untracked.current_branch)
	_check(untracked.files.any(func(file: GitFileStatus) -> bool:
		return file.path == "README.md" and file.index_state == GitFileState.UNTRACKED))

	await _run_git("git add README.md")
	var staged := await _session.inspect()
	_check(staged.files.any(func(file: GitFileStatus) -> bool:
		return file.path == "README.md" and file.index_state == GitFileState.ADDED))

	await _run_git("git commit -m \"initial commit\"")
	var committed := await _session.inspect()
	_equal(0, committed.files.size())
	_check(committed.branches.any(func(branch: GitBranchInfo) -> bool:
		return branch.name == "main" and branch.is_current))
	if _equal(1, committed.commits.size()):
		_equal("initial commit", committed.commits[0].subject)
		_equal("Git Diwaa Player", committed.commits[0].author)


func _t_branch_merge() -> void:
	await _run_git("git switch -c feature/demo")
	_write("feature.txt", "feature\n")
	await _run_git("git add feature.txt")
	await _run_git("git commit -m \"feature work\"")

	await _run_git("git switch main")
	_write("main.txt", "main\n")
	await _run_git("git add main.txt")
	await _run_git("git commit -m \"main work\"")
	await _run_git("git merge --no-ff feature/demo")

	var snapshot := await _session.inspect()
	_check(snapshot.branches.any(func(branch: GitBranchInfo) -> bool: return branch.name == "feature/demo"))
	_check(snapshot.commits.any(func(commit: GitCommitNode) -> bool: return commit.parent_ids.size() == 2))
	var all_parents_known := true
	for commit in snapshot.commits:
		for parent in commit.parent_ids:
			all_parents_known = all_parents_known and snapshot.commits.any(
					func(other: GitCommitNode) -> bool: return other.id == parent)
	_check(all_parents_known)


func _t_diff_restore_reset() -> void:
	_write("README.md", "temporary change\n")
	_contains((await _run_git("git diff")).output, "+temporary change")
	await _run_git("git restore README.md")
	_equal("hello Git-Diwaa\n", _read("README.md"))

	_write("reset.txt", "reset me\n")
	await _run_git("git add reset.txt")
	await _run_git("git commit -m \"reset target\"")
	await _run_git("git reset --hard HEAD~1")
	_check(not _session.files.list_files().has("reset.txt"))


func _t_push_fetch_pull() -> void:
	await _run_git("git remote add origin " + _session.info.remote_url)
	_contains((await _run_git("git remote -v")).output, _session.info.remote_url)
	await _run_git("git push -u origin main")
	await _run_git("git fetch origin")

	_write("remote.txt", "from pushed commit\n")
	await _run_git("git add remote.txt")
	await _run_git("git commit -m \"remote update\"")
	await _run_git("git push")
	await _run_git("git reset --hard HEAD~1")
	_check(not _session.files.list_files().has("remote.txt"))
	await _run_git("git pull")
	_equal("from pushed commit\n", _read("remote.txt"))


func _t_clone() -> void:
	var clone_session := await _create("clone", "player", RemoteSeed.empty())
	var clone := await clone_session.execute("git clone " + clone_session.info.remote_url)
	_check(clone.success, clone.output)
	_check((await clone_session.inspect()).is_initialized)


func _t_empty_remote() -> void:
	var empty := await _create("act1-empty", "player", RemoteSeed.empty())
	_equal("https://magic-vault.com/user/my-project.git", empty.info.remote_url)

	var host := empty.remote_host
	var repo := await host.get_repository()
	_equal("user", repo.owner)
	_equal("my-project", repo.name)
	_equal("https://magic-vault.com/user/my-project.git", repo.clone_url)
	_check(repo.is_empty)
	_equal(0, repo.commit_count)
	_equal(0, (await host.list_branches()).size())
	_equal(0, (await host.list_commits("main")).size())
	_equal(0, (await host.list_files("main")).size())
	_check(await host.read_file("main", "README.md") == null)
	_equal(0, host.list_pull_requests().size())


func _t_no_repository() -> void:
	var fresh := await _create("act1-none", "player")
	_equal("", fresh.info.remote_url)
	_check(fresh.remote_host == null)

	var account := fresh.remote_account
	_equal("user", account.owner)
	_equal(0, (await account.list_repositories()).size())
	_check(account.open_repository("my-project") == null)

	var rejected := await fresh.execute("git remote add origin https://magic-vault.com/user/my-project.git")
	_check(not rejected.success)
	_contains(rejected.output, "Create a repository")

	var created: OpResult = await account.create_repository("first", "")
	if not _check(created.ok, created.message):
		return
	_equal("https://magic-vault.com/user/first.git", (created.value as RemoteRepositoryInfo).clone_url)
	_equal(1, (await account.list_repositories()).size())
	var clone := await fresh.execute("git clone https://magic-vault.com/user/first.git")
	_check(clone.success, clone.output)


func _t_publish() -> void:
	var player := await _create("act1-publish", "player", RemoteSeed.empty())
	await _publish_main(player)

	var host := player.remote_host
	var repo := await host.get_repository()
	_check(not repo.is_empty)
	_equal("main", repo.default_branch)
	_equal(1, repo.commit_count)

	var commits := await host.list_commits("main")
	if _equal(1, commits.size()):
		_equal("first commit", commits[0].subject)
		_equal("Git Diwaa Player", commits[0].author)
	var files := await host.list_files("main")
	if _equal(1, files.size()):
		_equal("README.md", files[0].name)
	_contains(str(await host.read_file("main", "README.md")), "my-project")


func _t_player_owner() -> void:
	var alice_factory := RealGitGameSessionFactory.new(_test_root, "alice")
	var alice := await _create("act1-alice", "player", RemoteSeed.empty("alice"), alice_factory)
	_equal("https://magic-vault.com/alice/my-project.git", alice.info.remote_url)
	_equal("alice", (await alice.remote_host.get_repository()).owner)
	_check(not RealGitGameSessionFactory.new(_test_root, "../evil").validation_error.is_empty())


func _t_seeded_clone() -> void:
	var github := await _create("act1-clone", "player", _sample_seed(GitTime.now()))
	_equal("https://magic-vault.com/user/my-project.git", github.info.remote_url)

	var real := await github.execute("git clone https://github.com/torvalds/linux.git")
	_check(not real.success)
	_contains(real.output, "registered")

	var clone := await github.execute("git clone " + github.info.remote_url)
	_check(clone.success, clone.output)
	_contains((await github.execute("git remote -v")).output, "magic-vault.com/user/my-project.git")
	_check((await github.inspect()).commits.any(func(commit: GitCommitNode) -> bool: return commit.subject == "Initial commit"))
	_check(not (await github.execute("git remote set-url origin https://github.com/torvalds/linux.git")).success)


func _t_account_repositories() -> void:
	var session := await _create("act1-account", "player", RemoteSeed.empty())
	var account := session.remote_account
	_equal(1, (await account.list_repositories()).size())

	var created: OpResult = await account.create_repository("notes", "my notes")
	if not _check(created.ok, created.message):
		return
	var info: RemoteRepositoryInfo = created.value
	_equal("https://magic-vault.com/user/notes.git", info.clone_url)
	_check(info.is_empty)
	_equal(2, (await account.list_repositories()).size())
	_check(not (await account.create_repository("NOTES", "")).ok)
	_check(not (await account.create_repository("bad name", "")).ok)

	# สร้างชื่อเดียวกันพร้อมกัน: สำเร็จได้แค่ครั้งเดียว
	var racing: Array[bool] = []
	var attempt := func() -> void:
		var result: OpResult = await account.create_repository("race", "")
		racing.append(result.ok)
	for _index in 3:
		attempt.call()
	while racing.size() < 3:
		await process_frame
	_equal(1, racing.count(true))
	_equal(3, (await account.list_repositories()).size())

	await _run_git("git config --global user.name \"Git Diwaa Player\"", session)
	await _run_git("git config --global user.email player@git-diwaa.local", session)
	await _run_git("git init", session)
	_write("a.txt", "hello", session)
	await _run_git("git add .", session)
	await _run_git("git commit -m first", session)
	await _run_git("git remote add origin https://magic-vault.com/user/notes.git", session)
	await _run_git("git push -u origin main", session)

	var notes := account.open_repository("notes")
	_equal(1, (await notes.get_repository()).commit_count)
	_check((await account.open_repository("my-project").get_repository()).is_empty)
	_check(not (await session.execute("git remote set-url origin https://magic-vault.com/user/other.git")).success)


func _t_host_listing() -> void:
	var github := await _create("act1-host", "player", _sample_seed(GitTime.now()))
	var host := github.remote_host

	var repo := await host.get_repository()
	_equal("user", repo.owner)
	_equal("main", repo.default_branch)
	_equal(2, repo.branch_count)
	_equal(2, repo.commit_count)

	var branches := await host.list_branches()
	_check(branches.any(func(branch: RemoteBranchInfo) -> bool: return branch.name == "feature/login"))
	var defaults := branches.filter(func(branch: RemoteBranchInfo) -> bool: return branch.is_default)
	if _equal(1, defaults.size()):
		_equal("main", defaults[0].name)

	var commits := await host.list_commits("main")
	if _equal(2, commits.size()):
		_equal("Update README", commits[0].subject)
		_check(commits[0].authored_at > commits[1].authored_at)

	var files := await host.list_files("main")
	_check(files.any(func(file: RemoteFileEntry) -> bool: return file.name == "README.md" and file.last_commit != null))
	_contains(str(await host.read_file("main", "README.md")), "sample project")
	_check(await host.read_file("main", "../etc/passwd") == null)


func _t_pull_requests() -> void:
	var strict := RemoteRules.new(true, false)
	var github := await _create("act1-pr", "player", _sample_seed(GitTime.now(), strict))
	var host := github.remote_host

	var login: RemoteBranchInfo = null
	for branch in await host.list_branches():
		if branch.name == "feature/login":
			login = branch
	if not _check(login != null, "feature/login branch missing"):
		return
	_equal(1, login.ahead)
	_equal(0, login.behind)

	_check(not (await host.open_pull_request("same", "", "teammate", "main", "main")).ok)
	var opened: OpResult = await host.open_pull_request("Add login", "login body", "teammate", "feature/login", "main")
	if not _check(opened.ok, opened.message):
		return
	var pr: PullRequestInfo = opened.value
	_equal(1, pr.number)
	_check(not (await host.open_pull_request("again", "", "teammate", "feature/login", "main")).ok)

	var detail := await host.get_pull_request(pr.number)
	_equal(1, detail.commits.size())
	if _equal(1, detail.files.size()):
		_equal("login.py", detail.files[0].path)
		_equal("A", detail.files[0].status)
	_contains(detail.diff, "+print('login')")
	_check(not detail.has_conflicts)
	_contains(str(detail.merge_blocked_reason if detail.merge_blocked_reason != null else ""), "Review required")

	var blocked := await host.merge_pull_request(pr.number)
	_check(not blocked.success)
	_contains(blocked.message, "Review required")

	var own := host.review_pull_request(pr.number, "teammate", ReviewVerdict.APPROVED)
	_check(not own.success)
	_contains(own.message, "own pull request")
	_check(host.review_pull_request(pr.number, "teammate", ReviewVerdict.COMMENTED, "self note").success)
	_check(host.review_pull_request(pr.number, "user", ReviewVerdict.APPROVED).success)
	_check(host.list_pull_requests()[0].is_approved)
	_check(host.review_pull_request(pr.number, "user", ReviewVerdict.CHANGES_REQUESTED, "rename file").success)
	_check(not host.list_pull_requests()[0].is_approved)
	host.review_pull_request(pr.number, "user", ReviewVerdict.APPROVED)
	_check((await host.get_pull_request(pr.number)).merge_blocked_reason == null)

	_check(not await host.delete_branch("feature/login"))
	var merged := await host.merge_pull_request(pr.number)
	_check(merged.success, merged.message)
	_equal(PullRequestState.MERGED, host.list_pull_requests()[0].state)
	_check(await host.read_file("main", "login.py") != null)

	var after := await host.get_pull_request(pr.number) # merge แล้วยังเห็น commit/ไฟล์/diff ที่เข้าไป
	_equal(PullRequestState.MERGED, after.pull.state)
	_equal(1, after.commits.size())
	if _equal(1, after.files.size()):
		_equal("login.py", after.files[0].path)
	_contains(after.diff, "+print('login')")
	_check(after.merge_blocked_reason == null)
	_check(not (await host.merge_pull_request(pr.number)).success)
	_check(not await host.delete_branch("main"))
	_check(await host.delete_branch("feature/login"))
	_equal(1, (await host.list_branches()).size())

	_check(not (await host.open_pull_request("bad", "", "teammate", "nope", "main")).ok)


func _t_pull_request_conflicts() -> void:
	var now := GitTime.now()
	var remote_seed := _sample_seed(now)
	remote_seed.commits.append(SeedCommit.new("feature/login", "teammate", "Edit README on feature", now,
			{"README.md": "feature version\n"}))
	remote_seed.commits.append(SeedCommit.new("main", "user", "Edit README on main", now,
			{"README.md": "main version\n"}))
	var github := await _create("act1-conflict", "player", remote_seed)
	var host := github.remote_host
	var opened: OpResult = await host.open_pull_request("Conflicting", "", "teammate", "feature/login", "main")
	if not _check(opened.ok, opened.message):
		return
	var pr: PullRequestInfo = opened.value
	var detail := await host.get_pull_request(pr.number)
	_check(detail.has_conflicts)
	_contains(str(detail.merge_blocked_reason), "conflicts")
	host.review_pull_request(pr.number, "user", ReviewVerdict.APPROVED)
	var merge := await host.merge_pull_request(pr.number)
	_check(not merge.success)
	_contains(merge.message, "conflicts")

	var closed := host.close_pull_request(pr.number)
	_check(closed.success)
	_equal(PullRequestState.CLOSED, closed.pull_request.state)
	_check(not host.close_pull_request(pr.number).success)


func _t_line_comments() -> void:
	var lines := await _create("act1-lines", "player", RemoteSeed.empty())
	await _publish_main(lines)
	var host := lines.remote_host
	await _run_git("git switch -c feature/lines", lines)
	await _commit_file(lines, "lines.txt", "a\nb\n", "add lines")
	await _run_git("git push -u origin feature/lines", lines)
	var opened: OpResult = await host.open_pull_request("Lines", "", "user", "feature/lines", "main")
	if not _check(opened.ok, opened.message):
		return
	var pr: PullRequestInfo = opened.value

	_check(host.add_line_comment(pr.number, "user", "lines.txt", 2, true, "single", false).success)
	_check(host.add_line_comment(pr.number, "user", "lines.txt", 1, true, "draft", true).success)
	_check(not host.add_line_comment(pr.number, "user", "lines.txt", 1, true, "  ", false).success)
	_check(not host.add_line_comment(pr.number, "user", "lines.txt", 0, true, "bad line", false).success)

	var before := (await host.get_pull_request(pr.number)).line_comments
	if _equal(2, before.size()):
		_check(not _comment_with_body(before, "single").is_pending)
		_check(_comment_with_body(before, "draft").is_pending)

	# คอมเมนต์ทั่วไปบน PR ต้องไม่ส่ง pending review ไปด้วย
	_check(not host.comment_on_pull_request(pr.number, "user", "  ").success)
	_check(host.comment_on_pull_request(pr.number, "user", "general").success)
	_check(_comment_with_body((await host.get_pull_request(pr.number)).line_comments, "draft").is_pending)

	_check(host.review_pull_request(pr.number, "user", ReviewVerdict.COMMENTED).success)
	_check((await host.get_pull_request(pr.number)).line_comments.all(
			func(comment: PullRequestLineComment) -> bool: return not comment.is_pending))

	_check(host.close_pull_request(pr.number).success)
	_check(not host.add_line_comment(pr.number, "user", "lines.txt", 1, true, "late", false).success)


func _comment_with_body(comments: Array[PullRequestLineComment], body: String) -> PullRequestLineComment:
	for comment in comments:
		if comment.body == body:
			return comment
	_check(false, "comment '%s' not found" % body)
	return PullRequestLineComment.new()


func _t_thai_paths() -> void:
	var thai := await _create("act1-thai", "player", RemoteSeed.empty())
	await _publish_main(thai)
	var host := thai.remote_host
	await _run_git("git switch -c feature/thai", thai)
	await _commit_file(thai, "บันทึก.txt", "สวัสดี\n", "add thai file")
	await _run_git("git push -u origin feature/thai", thai)
	var opened: OpResult = await host.open_pull_request("Thai", "", "user", "feature/thai", "main")
	if not _check(opened.ok, opened.message):
		return
	var pr: PullRequestInfo = opened.value

	var detail := await host.get_pull_request(pr.number)
	if _equal(1, detail.files.size()):
		_equal("บันทึก.txt", detail.files[0].path)
	_contains(detail.diff, "+++ b/บันทึก.txt")


func _t_solo_player() -> void:
	var solo := await _create("act1-solo", "player", RemoteSeed.empty())
	await _publish_main(solo)
	var host := solo.remote_host

	await _run_git("git switch -c feature/one", solo)
	await _commit_file(solo, "one.txt", "one\n", "work one")
	await _run_git("git push -u origin feature/one", solo)
	var first: PullRequestInfo = (await host.open_pull_request("One", "", "user", "feature/one", "main")).value
	_check((await host.get_pull_request(first.number)).merge_blocked_reason == null) # review เป็นทางเลือก
	_check(host.review_pull_request(first.number, "user", ReviewVerdict.APPROVED).success) # รีวิวของตัวเองได้
	var merged := await host.merge_pull_request(first.number)
	_check(merged.success, merged.message)
	_check(await host.read_file("main", "one.txt") != null)

	await _run_git("git switch main", solo)
	await _run_git("git switch -c feature/two", solo)
	await _commit_file(solo, "two.txt", "two\n", "work two")
	await _run_git("git push -u origin feature/two", solo)
	var second: PullRequestInfo = (await host.open_pull_request("Two", "", "user", "feature/two", "main")).value
	var unreviewed := await host.merge_pull_request(second.number) # merge ได้แม้ยังไม่ได้รีวิว
	_check(unreviewed.success, unreviewed.message)
	_check(await host.read_file("main", "two.txt") != null)


func _t_pull_request_base() -> void:
	var player := await _create("act1-pr-base", "player", RemoteSeed.empty())
	await _publish_main(player)
	await _run_git("git switch -c feature/a", player)
	await _commit_file(player, "a.txt", "a\n", "work on a")
	await _run_git("git push -u origin feature/a", player)
	await _run_git("git switch -c feature/b", player) # แตกจาก feature/a ยังไม่มี commit ใหม่
	await _run_git("git push -u origin feature/b", player)

	var host := player.remote_host
	_check(not (await host.open_pull_request("a into b", "", "user", "feature/a", "feature/b")).ok)
	var opened: OpResult = await host.open_pull_request("b into main", "", "user", "feature/b", "main")
	if _check(opened.ok, opened.message):
		_equal(1, (opened.value as PullRequestInfo).number)


func _t_file_api_blocks() -> void:
	_check(not _session.files.write_all_text("../outside.txt", "blocked").ok)
	_check(not _session.files.write_all_text(".git/config", "blocked").ok)


func _t_workspace_api() -> void:
	_check(_session.files.create_directory("quests/act-1").ok)
	_write("quests/act-1/brief.txt", "Find the branch\n")

	var entries := _session.files.list_entries()
	_check(entries.any(func(entry: PlayerWorkspaceEntry) -> bool: return entry.path == "quests" and entry.is_directory))
	_check(entries.any(func(entry: PlayerWorkspaceEntry) -> bool: return entry.path == "quests/act-1" and entry.is_directory))
	_check(entries.any(func(entry: PlayerWorkspaceEntry) -> bool:
		return entry.path == "quests/act-1/brief.txt" and not entry.is_directory))

	_check(_session.files.move("quests/act-1/brief.txt", "quests/act-1/renamed.txt").ok)
	_equal("Find the branch\n", _read("quests/act-1/renamed.txt"))
	_check(not _session.files.list_files().has("quests/act-1/brief.txt"))

	_check(not _session.files.create_directory("../outside-folder").ok)
	_check(not _session.files.move("quests", ".git/quests").ok)

	var removed := _session.files.delete_directory("quests", true)
	_check(removed.ok and removed.value == true)
	_check(not _session.files.list_entries().any(func(entry: PlayerWorkspaceEntry) -> bool: return entry.path.begins_with("quests")))


func _t_attempt_identifiers() -> void:
	_check(not (await _factory.create("../bad", "attempt")).ok)
	_check(not (await _factory.create("act1", "player")).ok)


func _t_level1_step1() -> void:
	var mission := LevelMission.create(1, 1)
	if not _check(mission != null, "level 1 step 1 should exist"):
		return
	_check(LevelMission.create(1, 3) == null)
	mission.on_command("git -version", false, "")
	_check(not mission.is_complete())
	_check(not mission.mistake_message("git -version").is_empty())
	mission.on_command("git --version", false, "")
	_check(not mission.is_complete(), "a failed command must not count")
	mission.on_command("git   --version", true, "git version 2.0")
	_check(mission.is_complete())


func _t_level1_step2() -> void:
	var mission := LevelMission.create(1, 2)
	if not _check(mission != null, "level 1 step 2 should exist"):
		return
	_equal(["git", "config", "--global", "user.name", "Vel Hero"], Array(LevelMission.tokenize("git config --global user.name \"Vel Hero\"")))
	mission.on_command("git config --global user.name \"\"", true, "")
	_check(mission.done_count() == 0, "empty name must not count")
	mission.on_command("git config --global user.email \"vel\"", true, "")
	_check(mission.done_count() == 0, "email without @ must not count")
	mission.on_command("git config --global user.name", true, "")
	_check(mission.done_count() == 0, "name check before a name is set must not count")
	mission.on_command("git config --global user.name \"Vel\"", true, "")
	mission.on_command("git config --global user.email \"vel@magic-tower.local\"", true, "")
	_check(mission.done_count() == 2 and not mission.is_complete())
	mission.on_command("git config --global user.name", true, "Vel\n")
	_check(mission.is_complete())


func _t_clear_scoring() -> void:
	_check(GameProgressManager.stars_for_score(80) == 3 and GameProgressManager.stars_for_score(65) == 2 and GameProgressManager.stars_for_score(64) == 1)
	_check(GameProgressManager.calculate_score(-1.0, 130.0) == 85, "missing timer (-1) must not count as a timeout")
	_check(GameProgressManager.calculate_score(0.0, 130.0) == 65, "expired timer gives 2 stars")
	_check(GameProgressManager.calculate_score(130.0, 130.0) == 100)


func _fresh_session(mission_id: String) -> GitGameSession:
	var created: OpResult = await _factory.create(mission_id, "attempt-%d" % Time.get_ticks_usec())
	return created.value if created.ok else null


func _t_state_objectives() -> void:
	var session := await _fresh_session("state-check")
	if not _check(session != null, "session should start"):
		return
	await session.execute("git config --global user.name \"Vel\"")
	await session.execute("git config --global user.email \"vel@magic-tower.local\"")
	_check(not LevelMission.evaluate_state({"check": "repo_initialized"}, await session.inspect()))
	await session.execute("git init")
	_check(LevelMission.evaluate_state({"check": "repo_initialized"}, await session.inspect()))

	session.files.write_all_text("a.txt", "a\n")
	session.files.write_all_text("b.txt", "b\n")
	var both := {"check": "staged", "paths": ["a.txt", "b.txt"]}
	await session.execute("git add a.txt")
	_check(not LevelMission.evaluate_state(both, await session.inspect()), "only one file is staged")
	await session.execute("git add .")
	_check(LevelMission.evaluate_state(both, await session.inspect()), "both files staged")

	await session.execute("git commit -m \"first\"")
	var snapshot := await session.inspect()
	_check(LevelMission.evaluate_state({"check": "committed", "paths": ["a.txt", "b.txt"], "count": 1}, snapshot))
	_check(LevelMission.evaluate_state({"check": "clean"}, snapshot))
	_check(LevelMission.evaluate_state({"check": "current_branch", "branch": "main"}, snapshot))

	await session.execute("git switch -c experiment")
	session.files.write_all_text("a.txt", "fire\n")
	await session.execute("git commit -am \"fire\"")
	await session.execute("git switch main")
	session.files.write_all_text("b.txt", "ice\n")
	await session.execute("git commit -am \"ice\"")
	_check(not LevelMission.evaluate_state({"check": "merge_commit"}, await session.inspect()))
	var merged := await session.execute("git merge experiment")
	_check(merged.success, "merge failed: " + merged.output)
	snapshot = await session.inspect()
	_check(LevelMission.evaluate_state({"check": "branch_exists", "branch": "experiment"}, snapshot))
	_check(LevelMission.evaluate_state({"check": "merge_commit"}, snapshot), "HEAD should be the merge commit")
	session.dispose()


func _t_state_objective_order() -> void:
	var session := await _fresh_session("state-order")
	if not _check(session != null, "session should start"):
		return
	var mission := LevelMission.new()
	mission.objectives.append({"id": "tome", "type": "state", "check": "repo_initialized", "world": "คัมภีร์ถือกำเนิด"})
	mission.objectives.append({"id": "altar", "type": "state", "check": "staged", "paths": ["f.txt"], "spell": "add"})
	session.files.write_all_text("f.txt", "rune\n")

	var result := await session.execute("git status")
	_check(mission.on_command("git status", result.success, result.standard_output, await session.inspect()).is_empty())
	result = await session.execute("git init")
	_equal(["tome"], Array(mission.on_command("git init", result.success, result.standard_output, await session.inspect())))
	_equal("คัมภีร์ถือกำเนิด", mission.world_text("tome"))

	# Staging via a non-add command must not satisfy a goal that requires the add spell.
	await session.execute("git add f.txt")
	_check(mission.on_command("git status", true, "", await session.inspect()).is_empty(), "spell add is required")
	_check(not mission.on_command("git add f.txt", true, "", await session.inspect()).is_empty())
	_check(mission.is_complete())
	session.dispose()
