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
	await _test("spell effects follow what git really did to the repository", _t_spell_effects)
	await _test("levels 2-15: every step's setup builds its world and the intended play clears it", _t_levels_2_to_5)
	await _test("levels 2-5: the wrong spell does not clear state goals", _t_levels_wrong_spells)
	await _test("levels 6-9: guessing, fake runes, inscribing curses and --hard are punished", _t_levels_6_to_9_wrong)
	await _test("levels 10-12: phantoms drain, keys need committing, merges need judging", _t_levels_10_to_12_wrong)
	await _test("vault: seeded remote, behind/ahead drift and in_sync after pull and push", _t_vault_sync)
	await _test("finishing a level's last step resumes the outro so the level is cleared", _t_resume_phase)
	await _test("spellbook: every step teaches known spells and every level's solution only uses learned spells", _t_spellbook)
	await _test("levels 13-15: no tome, a stale tome and an unpublished tome all drain hearts", _t_levels_13_to_15_wrong)
	await _test("room: chaos waves destroy uninscribed scrolls, inscriptions are safe", _t_room_waves)
	await _test("room: altar shield, cursed inscriptions, restore and phantom dimensions", _t_room_rules)
	await _test("room v2: tome needed, cursed altar, essential scrolls and exclusion checks", _t_room_rules_v2)
	await _test("room: waves never corrupt clue notes, and cursed text stays readable", _t_room_notes_safe)
	await _test("status labels: room tags and Miura's translation match git status", _t_status_labels)

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
	_check(mission.current_asker().is_empty(), "nobody asks before the spell is cast")
	mission.on_command("git -version", false, "")
	_check(not mission.is_complete())
	_check(not mission.mistake_message("git -version").is_empty())
	mission.on_command("git --version", false, "")
	_check(not mission.is_complete(), "a failed command must not count")
	mission.on_command("git   --version", true, "git version 2.39.5 (Apple Git-154)")
	_check(mission.done_count() == 1 and not mission.is_complete(), "the circle then asks for the power level")
	_check(str(mission.current_asker().get("name", "")) == "มิวรา", "Mewla asks for the power level in the room")
	mission.on_command("say 9.9.9", true, "")
	_check(not mission.is_complete(), "a made-up version must not count")
	mission.on_command("say 2.39.5", true, "")
	_check(mission.is_complete(), "the version read from the real output opens the circle")


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


func _fresh_session(mission_id: String, remote_seed: RemoteSeed = null) -> GitGameSession:
	var created: OpResult = await _factory.create(mission_id, "attempt-%d" % Time.get_ticks_usec(), remote_seed)
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


func _t_spell_effects() -> void:
	var session := await _fresh_session("spell-effects")
	if not _check(session != null, "session should start"):
		return
	await session.execute("git config --global user.name \"Vel\"")
	await session.execute("git config --global user.email \"vel@magic-tower.local\"")
	var cast := func(command: String) -> Array:
		var before := await session.inspect()
		var result := await session.execute(command)
		var effects := SpellEffectDetector.detect(before, await session.inspect(), command, result.success)
		return effects.map(func(effect: Dictionary) -> int: return effect["kind"])

	_check((await cast.call("git init")).has(SpellEffectDetector.Kind.TOME_CREATED), "init")
	session.files.write_all_text("scroll.txt", "rune\n")
	_check((await cast.call("git status")).has(SpellEffectDetector.Kind.REVEALED), "status reveals")
	_check((await cast.call("git add scroll.txt")).has(SpellEffectDetector.Kind.TO_ALTAR), "add")
	_check((await cast.call("git commit -m \"one\"")).has(SpellEffectDetector.Kind.INSCRIBED), "commit")
	session.files.write_all_text("scroll.txt", "rune 2\n")
	await session.execute("git commit -am \"two\"")
	_check((await cast.call("git reset --soft HEAD~1")).has(SpellEffectDetector.Kind.TIME_REWIND), "reset rewinds time")
	_check((await cast.call("git restore --staged scroll.txt")).has(SpellEffectDetector.Kind.FROM_ALTAR), "unstage")
	_check((await cast.call("git restore scroll.txt")).has(SpellEffectDetector.Kind.CURSE_LIFTED), "restore")
	_check((await cast.call("git branch experiment")).has(SpellEffectDetector.Kind.DIMENSION_SPLIT), "branch")
	_check((await cast.call("git switch experiment")).has(SpellEffectDetector.Kind.DIMENSION_STEP), "switch")
	_check((await cast.call("git frobnicate")).has(SpellEffectDetector.Kind.FIZZLE), "bad spell fizzles")

	session.files.write_all_text("scroll.txt", "fire\n")
	await session.execute("git commit -am \"fire\"")
	await session.execute("git switch main")
	session.files.write_all_text("scroll.txt", "ice\n")
	await session.execute("git commit -am \"ice\"")
	_check((await cast.call("git merge experiment")).has(SpellEffectDetector.Kind.DIMENSION_CLASH), "conflict clashes")
	session.dispose()


## เล่นขั้นหนึ่งของด่านแบบเดียวกับ SandboxGameView: setup เงียบ ๆ → ห้องตั้งต้น → ทุกการกระทำเดินโลกหนึ่งจังหวะ
## คืน {"mission", "room"} (room = null เมื่อด่านไม่มีมินิเกม)
func _play_level(level: int, step: int, commands: Array[String]) -> Dictionary:
	var mission := LevelMission.create(level, step)
	if not _check(mission != null, "level %d step %d should exist" % [level, step]):
		return {}
	var session := await _fresh_session("level-%02d-%d" % [level, step], LevelMission.build_remote_seed(mission.remote))
	for action in mission.setup:
		await _world_action(session, action, level)
	var room: RoomGame = RoomGame.from_config(mission.room) if not mission.room.is_empty() else null
	if room != null:
		for action in room.initial_actions():
			await _world_action(session, action, level)
		var present: Array[String] = []
		for entry in session.files.list_entries():
			if not entry.is_directory:
				present.append(entry.path)
		room.set_present(present)
		for path in room.items.keys():
			var read := session.files.read_all_text(str(path))
			if read.ok and read.value != null:
				room.remember_content(str(path), str(read.value))
	for command in commands:
		var output := ""
		var success := true
		if command.begins_with("cat "):
			var read := session.files.read_all_text(command.substr(4))
			success = read.ok and read.value != null
		elif command.begins_with("write "):
			var parts := command.split(" ", false, 2)
			session.files.write_all_text(parts[1], parts[2].replace("\\n", "\n") + "\n")
		elif command.begins_with("say "):
			pass
		else:
			# commit ที่ไม่มี -m: ในเกมเปิดหน้าจารึก (editor) — เทสต์จำลองการเขียนคำจารึกหลายบรรทัด
			var executed := CommitEditor.to_command(command, "จารึกผ่านหน้าคัมภีร์\n\nรายละเอียดของการจารึก") \
					if CommitEditor.needs_editor(command) else command
			var result := await session.execute(executed)
			success = result.success
			output = result.standard_output
		if command.contains("{answer}"):
			# คำตอบที่อ่านได้จากผลจริงของคำสั่ง (เช่น เลขเวอร์ชันของ git ในเครื่องที่รันเทสต์)
			var answers := mission.accepted_words(mission.current_objective())
			command = command.replace("{answer}", str(answers.back()) if not answers.is_empty() else "?")
		var expected_say := mission.expects_say()
		var before := mission.done_count()
		var done := mission.on_command(command, success, output, await session.inspect())
		if room != null:
			for done_id in done:
				room.on_objective_done(mission.objective(done_id), command, mission.is_complete())
		for done_id in done:
			for action in mission.spawn_actions(done_id):
				await _world_action(session, action, level)
		if room != null and not mission.is_complete():
			if command.begins_with("say ") and expected_say and mission.done_count() == before:
				room.on_wrong_say()
			else:
				await _room_turn(session, room, command, false)
		if room != null and room.is_failed():
			break
	session.dispose()
	return {"mission": mission, "room": room}


func _world_action(session: GitGameSession, action: Dictionary, level: int) -> void:
	if action.has("write"):
		_check(session.files.write_all_text(str(action["write"]), str(action.get("content", ""))).ok, "L%d write %s" % [level, action["write"]])
	elif action.has("delete"):
		session.files.delete(str(action["delete"]))
	else:
		var result := await session.execute(str(action["run"]))
		_check(result.success, "L%d '%s' failed: %s" % [level, action["run"], result.output])


## เส้นทางที่ตั้งใจของแต่ละขั้น (ใช้ทั้งในเทสต์และเป็นเฉลยอ้างอิงของทีม)
const SOLUTIONS := [
	[1, 1, ["git --version", "say {answer}"]],
	[1, 2, ["git config --global user.name \"Vel\"", "git config --global user.email \"vel@magic-tower.local\"", "git config --global user.name"]],
	[2, 1, ["git init"]],
	[3, 1, ["git status", "cat scroll-d.txt", "cat scroll-b.txt"]],
	[4, 1, ["git add fragment-1a.txt", "git add fragment-1b.txt fragment-1c.txt"]],
	[4, 2, ["git add ."]],
	[5, 1, ["git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 1\""]],
	[5, 2, ["git commit -am \"เศษคัมภีร์ชิ้นที่ 2\""]],
	[6, 1, ["git log --oneline", "say aurora", "git add fragment-3.txt", "git commit -m \"เศษคัมภีร์ชิ้นที่ 3\""]],
	[7, 1, ["git diff", "say lumina", "git diff --staged", "say ignis"]],
	[8, 1, ["git restore fragment-5.txt", "git restore --staged curse.txt"]],
	[9, 1, ["git reset --mixed HEAD~1", "git add fragment-6.txt", "git commit -m \"เศษคัมภีร์ชิ้นที่ 6\""]],
	[9, 1, ["git reset --soft HEAD~1", "git restore --staged curse.txt", "git commit -m \"เศษคัมภีร์ชิ้นที่ 6\""]],
	[10, 1, ["git branch", "git branch -d phantom", "git branch experiment"]],
	[11, 1, ["git switch experiment", "git add key-moon.txt", "git commit -m \"ครึ่งกุญแจจันทรา\"", "git switch main", "git switch -c trial"]],
	[12, 1, ["git merge experiment", "write altar-core.txt แกนแท่นบูชา: ไอน้ำ", "git add altar-core.txt", "git commit -m \"หลอมมิติ\""]],
	[13, 1, ["git clone https://magic-vault.com/user/light-tome.git", "git remote -v", "cat fragment-10.txt"]],
	[14, 1, ["git pull", "cat fragment-11.txt"]],
	[14, 1, ["git fetch", "git pull", "cat fragment-11.txt"]],
	[15, 1, ["git remote add origin https://magic-vault.com/user/apprentice-tome.git", "git push -u origin main"]],
	[5, 3, ["git commit"]],
	[5, 4, ["git add fragment-2-seal.txt", "git commit --amend --no-edit"]],
	[5, 4, ["git add fragment-2-seal.txt", "git commit --amend"]],
	[6, 2, ["git log -n 3 --oneline", "say lumen"]],
	[6, 3, ["git log --graph --all --oneline", "say nyx"]],
	[7, 2, ["git diff HEAD", "say solaris"]],
	[12, 2, ["git merge echo", "cat key-whole.txt", "git merge --abort"]],
	[13, 2, ["git remote -v", "git remote set-url origin https://magic-vault.com/user/light-tome.git", "git remote remove shadow"]],
	[13, 2, ["git remote -v", "git remote remove shadow", "git remote set-url origin https://magic-vault.com/user/light-tome.git"]],
	[15, 2, ["git push origin main"]],
]


func _t_levels_2_to_5() -> void:
	for play in SOLUTIONS:
		var commands: Array[String] = []
		commands.assign(play[2])
		var outcome := await _play_level(play[0], play[1], commands)
		if outcome.is_empty():
			continue
		var mission: LevelMission = outcome["mission"]
		var room: RoomGame = outcome["room"]
		_check(mission.is_complete(), "level %d step %d not cleared; stuck at '%s'" % [play[0], play[1], mission.current_objective().get("id", "")])
		_check(room == null or room.hearts == room.max_hearts, "level %d step %d: the intended play should not lose hearts" % [play[0], play[1]])
		_check(mission.objectives.all(func(o: Dictionary) -> bool: return not str(o.get("world", "")).is_empty()),
				"level %d step %d: every goal should have a world reaction" % [play[0], play[1]])


func _t_levels_wrong_spells() -> void:
	# ด่าน 1 ขั้น 1: ร่ายผิดซ้ำ ภูตคลานถึงตัว / คาถาวัดพลังเผาภูตทั้งหมด
	var level1 := await _play_level(1, 1, ["git -version", "git -version", "git -version"])
	_check(level1["room"].hearts == 1, "level 1: imps reach Vel while the spell is miscast (hearts %d)" % level1["room"].hearts)
	var level1b := await _play_level(1, 1, ["git -version", "git --version"])
	_check(level1b["room"].banished_total == 2 and not level1b["room"].imps.has(1), "level 1: the light of git --version burns every imp")
	_check(level1b["room"].hearts == 3, "level 1: banishing in time costs nothing")
	# ด่าน 1 ขั้น 2: ผู้เฝ้าประตูสลักนาม/ตราประทับที่ตั้งด้วย git config แล้วเปิดประตูเมื่อขานนามกลับ
	var gate := await _play_level(1, 2, ["git config --global user.name \"Vel\"", "git config --global user.email \"vel@magic-tower.local\""])
	_check(gate["room"].engraved.get("user.name") == "Vel" and gate["room"].engraved.get("user.email") == "vel@magic-tower.local",
			"level 1: the gatekeeper engraves the name and seal that git config set")
	_check(not gate["room"].gate_open, "level 1: the gate stays shut until the name is read back")
	var opened := await _play_level(1, 2, ["git config --global user.name \"Vel\"", "git config --global user.email \"vel@magic-tower.local\"", "git config --global user.name"])
	_check(opened["mission"].is_complete() and opened["room"].gate_open, "level 1: reading the name back opens the gate")
	var idle := await _play_level(1, 2, ["git status", "git status", "git status", "git status"])
	_check(idle["room"].engraved.is_empty() and not idle["room"].gate_open and idle["room"].hearts == 3,
			"level 1: the gatekeeper only listens to naming spells and never attacks")
	# ด่าน 2: พิมพ์ผิดจนคลื่นมาถึงก่อนมีคัมภีร์ = เสียหัวใจ
	var level2 := await _play_level(2, 1, ["git inti", "git int", "git init"])
	_check(level2["room"].hearts == 2 and level2["mission"].is_complete(), "level 2: the wave hits before the tome exists")
	# ด่าน 3: อ่านก่อนหยั่งสถานะไม่นับข้ามลำดับ
	var level3 := await _play_level(3, 1, ["cat scroll-b.txt"])
	_check(level3["mission"].done_count() == 0, "level 3 needs status first")
	var level3_swapped := await _play_level(3, 1, ["git status", "cat scroll-b.txt", "cat scroll-d.txt"])
	_check(level3_swapped["mission"].is_complete(), "level 3: the two scrolls can be read in either order")
	# ด่าน 4: git add . ลากม้วนคำสาปขึ้นแท่น → ไม่ผ่าน และระเบิดเมื่อคลื่นมา
	# ด่าน 4 ขั้น 2: วางประกายทีละดวง ไม่ทันคลื่น — ต้องยกทั้งโต๊ะในคาถาเดียว
	var level4_slow := await _play_level(4, 2, ["git add spark-1.txt", "git add spark-2.txt"])
	_check(level4_slow["room"].is_failed(), "level 4 step 2: one spark at a time loses to the wave")
	var level4 := await _play_level(4, 1, ["git add .", "git status", "git status"])
	_check(not level4["mission"].is_complete(), "level 4: add . must not clear")
	_check(level4["room"].hearts < level4["room"].max_hearts, "level 4: the cursed altar explodes")
	# ด่าน 5 ขั้น 1: ลังเลจนคลื่นกวาดแท่นเตรียม
	var level5 := await _play_level(5, 1, ["git status", "git status"])
	_check(level5["room"].hearts < 3, "level 5: the altar is not safe any more")
	# ด่าน 5 ขั้น 2: add . แล้ว commit = ลากคำสาปเข้าคัมภีร์
	var level5b := await _play_level(5, 2, ["git add .", "git commit -m \"ทุกอย่าง\""])
	_check(not level5b["mission"].is_complete(), "level 5 step 2: the curse must stay out of the tome")

## ทำ actions ของ RoomGame กับ session จริง แล้วคืน path ที่อยู่ในพื้นที่ทำงาน
func _apply_room(session: GitGameSession, room: RoomGame, outcome: Dictionary) -> void:
	for action in outcome["actions"]:
		if action.has("delete"):
			session.files.delete(str(action["delete"]))
		else:
			session.files.write_all_text(str(action["write"]), str(action["content"]))


func _room_turn(session: GitGameSession, room: RoomGame, command: String, execute := true) -> Dictionary:
	if execute and command.begins_with("git "):
		await session.execute(command)
	var paths: Array[String] = []
	for entry in session.files.list_entries():
		if not entry.is_directory:
			paths.append(entry.path)
	room.set_present(paths)
	var outcome := room.on_turn(await session.inspect(), command)
	_apply_room(session, room, outcome)
	return outcome


func _t_room_waves() -> void:
	var session := await _fresh_session("room-waves")
	await session.execute("git config --global user.name \"Vel\"")
	await session.execute("git config --global user.email \"vel@magic-tower.local\"")
	await session.execute("git init")
	var room := RoomGame.from_config({
		"hearts": 3, "wave_every": 3,
		"spawns": [
			{"turn": 0, "path": "safe.txt", "content": "A\n", "kind": "fragment", "name": "เศษ A"},
			{"turn": 0, "path": "lost.txt", "content": "B\n", "kind": "fragment", "name": "เศษ B"},
			{"turn": 2, "path": "late.txt", "content": "C\n", "kind": "fragment", "name": "เศษ C"},
		],
	})
	_apply_room(session, room, {"actions": room.initial_actions()})
	_equal(3, room.turns_until_wave())

	await _room_turn(session, room, "git add safe.txt")
	var spawned := await _room_turn(session, room, "git commit -m \"เก็บเศษ A\"")
	_check(spawned["events"].any(func(e: Dictionary) -> bool: return e["type"] == "spawn"), "late.txt should spawn on turn 2")
	_check(session.files.read_all_text("late.txt").value == "C\n")

	var wave := await _room_turn(session, room, "git status")
	_check(wave["wave"], "turn 3 is a wave")
	_equal(1, room.hearts) # lost.txt + late.txt were never inscribed
	_check(session.files.read_all_text("safe.txt").value == "A\n", "inscribed scroll survives")
	_check(session.files.read_all_text("lost.txt").value == null, "uninscribed scroll is destroyed")
	_equal(3, room.turns_until_wave())

	room.wave_every = 1
	var defeat := await _room_turn(session, room, "git status")
	_check(defeat["events"].any(func(e: Dictionary) -> bool: return e["type"] == "defeat") == false, "nothing left to lose")
	session.files.write_all_text("lost.txt", "B again\n")
	defeat = await _room_turn(session, room, "git status")
	_check(room.is_failed() and defeat["events"].any(func(e: Dictionary) -> bool: return e["type"] == "defeat"), "hearts reach zero")
	session.dispose()


func _t_room_rules() -> void:
	var session := await _fresh_session("room-rules")
	await session.execute("git config --global user.name \"Vel\"")
	await session.execute("git config --global user.email \"vel@magic-tower.local\"")
	await session.execute("git init")
	session.files.write_all_text("old.txt", "เดิม\n")
	session.files.write_all_text("curse.txt", "สาป\n")
	session.files.write_all_text("shield.txt", "โล่\n")
	await session.execute("git add old.txt curse.txt")
	await session.execute("git commit -m \"เผลอจารึกคำสาป\"")
	await session.execute("git branch ghost")
	await session.execute("git add shield.txt")

	var room := RoomGame.from_config({
		"hearts": 9, "wave_every": 1, "safe": "staged", "phantoms": ["ghost"],
		"items": {
			"old.txt": {"kind": "fragment", "name": "เศษเก่า"},
			"curse.txt": {"kind": "curse", "name": "ม้วนคำสาป"},
			"shield.txt": {"kind": "fragment", "name": "เศษบนแท่น"},
		},
	})
	session.files.write_all_text("old.txt", "แก้ไว้แต่ไม่จารึก\n")
	var wave := await _room_turn(session, room, "git status")
	_check(wave["events"].any(func(e: Dictionary) -> bool: return e["type"] == "shielded"), "altar shield protects staged scroll")
	_check(session.files.read_all_text("old.txt").value == RoomGame.CORRUPTED_TEXT, "edited inscription gets cursed")
	_equal(6, room.hearts) # cursed old.txt + committed curse + phantom dimension

	var described := room.describe(await session.inspect(), ["old.txt", "curse.txt", "shield.txt"])
	_equal(RoomGame.STATE_CURSED, described[0]["state"])
	_equal(RoomGame.STATE_TOME, described[1]["state"])
	_equal(RoomGame.STATE_ALTAR, described[2]["state"])

	await session.execute("git restore old.txt")
	await session.execute("git branch -d ghost")
	await session.execute("git commit -m \"เก็บเศษบนแท่น\"")
	session.files.delete("curse.txt")
	await session.execute("git add curse.txt")
	await session.execute("git commit -m \"ทิ้งคำสาป\"")
	wave = await _room_turn(session, room, "git status")
	_equal(6, room.hearts) # restored, phantom closed, curse gone: nothing hurts any more
	_check(session.files.read_all_text("old.txt").value == "เดิม\n", "restore brings the inscribed text back")
	_equal(0, room.on_wrong_say().size() - 1) # one damage event
	_equal(5, room.hearts)
	session.dispose()


func _t_room_rules_v2() -> void:
	var session := await _fresh_session("room-rules-v2")
	await session.execute("git config --global user.name \"Vel\"")
	await session.execute("git config --global user.email \"vel@magic-tower.local\"")
	var room := RoomGame.from_config({"hearts": 5, "wave_every": 1, "needs_tome": true, "safe": "staged",
		"essential": ["six.txt"],
		"items": {"curse.txt": {"kind": "curse", "name": "คำสาป"}, "a.txt": {"kind": "fragment", "name": "A"}}})
	await _room_turn(session, room, "git status")
	_equal(4, room.hearts) # no tome yet

	await session.execute("git init")
	session.files.write_all_text("six.txt", "6\n")
	await session.execute("git add six.txt")
	await session.execute("git commit -m \"หก\"")
	session.files.write_all_text("a.txt", "a\n")
	session.files.write_all_text("curse.txt", "x\n")
	await session.execute("git add .")
	var snapshot := await session.inspect()
	_check(not LevelMission.evaluate_state({"check": "staged", "paths": ["a.txt"], "exclude": ["curse.txt"]}, snapshot), "curse on altar breaks exclusion")
	await _room_turn(session, room, "git status")
	_equal(3, room.hearts) # the cursed scroll on the altar explodes

	await session.execute("git restore --staged curse.txt")
	snapshot = await session.inspect()
	_check(LevelMission.evaluate_state({"check": "staged", "paths": ["a.txt"], "exclude": ["curse.txt"]}, snapshot))
	_check(LevelMission.evaluate_state({"check": "not_staged", "paths": ["curse.txt"]}, snapshot))
	_check(LevelMission.evaluate_state({"check": "not_committed", "paths": ["curse.txt", "a.txt"]}, snapshot))
	await session.execute("git commit -m \"เก็บ\"")
	snapshot = await session.inspect()
	_check(LevelMission.evaluate_state({"check": "committed", "paths": ["a.txt", "six.txt"], "exclude": ["curse.txt"]}, snapshot))
	await session.execute("git branch phantom")
	await session.execute("git branch -d phantom")
	_check(LevelMission.evaluate_state({"check": "branch_absent", "branch": "phantom"}, await session.inspect()))

	session.files.delete("six.txt")
	await _room_turn(session, room, "git status")
	_check(room.is_failed(), "losing an essential scroll is a defeat")
	session.dispose()


func _t_levels_6_to_9_wrong() -> void:
	var level6 := await _play_level(6, 1, ["say lumos", "say open", "git log"])
	_check(level6["room"].hearts == 1 and level6["mission"].done_count() == 0, "level 6: guessing the seal costs hearts")
	var level7 := await _play_level(7, 1, ["cat fragment-4.txt", "say umbra"])
	_check(level7["room"].hearts == 2 and level7["mission"].done_count() == 0, "level 7: the forged rune backfires")
	var level8 := await _play_level(8, 1, ["git add .", "git commit -m \"ทับคำสาป\""])
	_check(not level8["mission"].is_complete(), "level 8: inscribing over the curse is not a cure")
	# ด่าน 6 ขั้น 2: คลี่ม้วนประวัติทั้งม้วน = ฝุ่นโกลาหลฟุ้ง
	var level6b := await _play_level(6, 2, ["git log --oneline", "git log -n 3"])
	_check(level6b["room"].hearts == 2 and level6b["mission"].done_count() == 1, "level 6 step 2: unrolling the whole scroll costs a heart")
	# ด่าน 6 ขั้น 3: log ธรรมดาไม่เห็นมิติที่ซ่อน
	var level6c := await _play_level(6, 3, ["git log --oneline"])
	_check(level6c["mission"].done_count() == 0, "level 6 step 3: a plain log does not map other dimensions")
	# ด่าน 7 ขั้น 2: เทียบรอยทีละครึ่ง = เสียพลัง
	var level7b := await _play_level(7, 2, ["git diff", "git diff --staged"])
	_check(level7b["room"].hearts == 1 and level7b["mission"].done_count() == 0, "level 7 step 2: half comparisons backfire")
	# ด่าน 5 ขั้น 3: -m บรรทัดเดียวไม่ผ่านม้วนพิธี / ขั้น 4: จารึกหน้าใหม่ = เกินกำลังคัมภีร์
	var level5c := await _play_level(5, 3, ["git commit -m \"สั้น ๆ\""])
	_check(not level5c["mission"].is_complete(), "level 5 step 3: a one-line -m does not satisfy the ritual scroll")
	var level5d := await _play_level(5, 4, ["git add fragment-2-seal.txt", "git commit -m \"ตรา\""])
	_check(not level5d["mission"].is_complete() and level5d["room"].hearts == 2, "level 5 step 4: a new page overloads the tome")
	var level9 := await _play_level(9, 1, ["git reset --hard HEAD~1"])
	_check(level9["room"].is_failed(), "level 9: --hard destroys fragment 6 and loses the floor")


func _t_levels_10_to_12_wrong() -> void:
	var level10 := await _play_level(10, 1, ["git status", "git branch", "git status", "git status"])
	_check(level10["room"].hearts == 1, "level 10: the phantom dimension drains every wave")
	var level11 := await _play_level(11, 1, ["git switch experiment"])
	_check(level11["mission"].done_count() == 1, "level 11: entering the dimension does not also inscribe the key")
	var level11b := await _play_level(11, 1, ["git switch experiment", "git status", "git status"])
	_check(level11b["room"].hearts == 2, "level 11: an uninscribed key is swept away by the wave")
	# ด่าน 12 ขั้น 2: จารึกผลการหลอมกับมิติเงา = รับคำสาปเข้าคัมภีร์
	var level12b := await _play_level(12, 2, ["git merge echo", "git add .", "git commit -m \"หลอม\""])
	_check(not level12b["mission"].is_complete() and level12b["room"].hearts == 2, "level 12 step 2: sealing the shadow merge is a trap")
	var level12 := await _play_level(12, 1, ["git merge experiment", "git add altar-core.txt"])
	_check(level12["mission"].done_count() == 2 and not level12["mission"].is_complete(), "level 12: the ritual is not sealed until it is inscribed")


func _t_vault_sync() -> void:
	var seed := LevelMission.build_remote_seed({"name": "light-tome", "commits": [
		{"author": "Guardian", "message": "หนึ่ง", "files": {"a.txt": "1\n"}},
		{"author": "Guardian", "message": "สอง", "files": {"b.txt": "2\n"}},
	]})
	_equal("https://magic-vault.com/user/light-tome.git", seed.clone_url)
	var session := await _fresh_session("vault-sync", seed)
	await session.execute("git config --global user.name \"Vel\"")
	await session.execute("git config --global user.email \"vel@magic-tower.local\"")
	var cloned := await session.execute("git clone " + seed.clone_url)
	_check(cloned.success, "clone: " + cloned.output)
	var in_sync := {"check": "in_sync", "upstream": "origin/main"}
	var snapshot := await session.inspect()
	_check(LevelMission.evaluate_state(in_sync, snapshot), "fresh clone is in sync")
	_equal("", RoomGame.sync_drift(snapshot))

	await session.execute("git reset --hard HEAD~1")
	snapshot = await session.inspect()
	_check(not LevelMission.evaluate_state(in_sync, snapshot))
	_check(RoomGame.sync_drift(snapshot).contains("ล้าหลัง"), "behind the vault")
	await session.execute("git pull")
	_check(LevelMission.evaluate_state(in_sync, await session.inspect()), "pull brings it back in sync")

	session.files.write_all_text("c.txt", "3\n")
	await session.execute("git add c.txt")
	await session.execute("git commit -m \"สาม\"")
	snapshot = await session.inspect()
	_check(RoomGame.sync_drift(snapshot).contains("ยังไม่ได้รับ"), "ahead of the vault")
	var pushed := await session.execute("git push")
	_check(pushed.success, "push: " + pushed.output)
	_check(LevelMission.evaluate_state(in_sync, await session.inspect()), "push brings it back in sync")
	session.dispose()


func _t_levels_13_to_15_wrong() -> void:
	var level13 := await _play_level(13, 1, ["git status", "git status", "git status"])
	_check(level13["room"].hearts == 2, "level 13: waves hit while there is no tome")
	var level14 := await _play_level(14, 1, ["git fetch", "git status"])
	_check(level14["room"].hearts == 2 and level14["mission"].done_count() == 0, "level 14: fetch alone leaves the tome stale")
	# ด่าน 13 ขั้น 2: ที่อยู่เก่าร้างแล้ว ส่องคลังไม่ได้ / สายเงาดูดพลังทุกคลื่น
	var level13b := await _play_level(13, 2, ["git fetch origin", "git status", "git status"])
	_check(level13b["room"].hearts == 2 and level13b["mission"].done_count() == 0, "level 13 step 2: the old address is a ruin and the shadow drains")
	# ด่าน 15 ขั้น 2: ประตูต้องการปลายทางชัด ๆ
	var level15b := await _play_level(15, 2, ["git push"])
	_check(not level15b["mission"].is_complete(), "level 15 step 2: the gate wants origin main spelled out")
	var level15 := await _play_level(15, 1, ["git remote add origin https://magic-vault.com/user/apprentice-tome.git", "git push origin main", "git status"])
	_check(not level15["mission"].is_complete() and level15["room"].hearts == 2, "level 15: a push without -u leaves the path unbound")


func _t_resume_phase() -> void:
	_equal(2, LevelMission.resume_phase_after(1, 1)) # ด่านขั้นเดียว (เช่น ด่าน 2) → outro
	_equal(1, LevelMission.resume_phase_after(1, 2)) # ด่านสองขั้น → part 2 ก่อน
	_equal(2, LevelMission.resume_phase_after(2, 2))
	_equal(3, LevelMission.resume_phase_after(2, 4)) # ด่านสี่ขั้น: หลังขั้น 2 → part3_intro
	_equal(4, LevelMission.resume_phase_after(3, 4))
	_equal(2, LevelMission.resume_phase_after(4, 4))
	for level in range(1, 16):
		var data := LevelDataLoader.load_data(level)
		_check(not data.is_empty(), "level %d data" % level)
		_check(not (data.get("outro_sequence", []) as Array).is_empty(), "level %d needs an outro to be cleared" % level)
		var steps := LevelDataLoader.get_gameplay_step_count(level)
		if steps >= 2:
			_check(not (data.get("part2_intro_sequence", []) as Array).is_empty(), "level %d has step 2 but no part 2 dialogue" % level)
		for step in range(3, steps + 1):
			_check(not (data.get("part%d_intro_sequence" % step, []) as Array).is_empty(), "level %d has step %d but no part %d dialogue" % [level, step, step])


func _t_spellbook() -> void:
	for level in range(1, 16):
		for step in range(1, LevelDataLoader.get_gameplay_step_count(level) + 1):
			var taught := SpellCatalog.taught_in(level, step)
			_check(not taught.is_empty(), "level %d step %d should hand out a spell scroll" % [level, step])
			for id in taught:
				_check(SpellCatalog.has_spell(id), "level %d step %d teaches unknown spell '%s'" % [level, step, id])
	var learned := SpellCatalog.learned_until(15, LevelDataLoader.get_gameplay_step_count(15))
	_equal(SpellCatalog.SPELLS.size(), learned.size())
	_check(SpellCatalog.learned_until(4, 1).has("add") and not SpellCatalog.learned_until(4, 1).has("commit"), "spells unlock in story order")
	# เฉลยทุกขั้นใช้เฉพาะคาถาที่ได้เรียนมาแล้ว (ไม่มีด่านที่ต้องรู้คำสั่งที่เกมยังไม่สอน)
	var spell_of := {"--version": "version", "config": "config", "init": "init", "status": "status", "add": "add",
		"log": "log", "restore": "restore", "reset": "reset", "branch": "branch", "switch": "switch", "merge": "merge",
		"clone": "clone", "remote": "remote", "fetch": "fetch", "pull": "pull", "push": "push", "diff": "diff", "commit": "commit"}
	_check(not SpellCatalog.has_spell("cat"), "reading is an in-world action (click), not a spell to learn")
	_check(not SpellCatalog.has_spell("say"), "speaking is an in-world action (the room's speak field), not a terminal spell")
	for play in SOLUTIONS:
		var known := SpellCatalog.learned_until(play[0], play[1])
		for command: String in play[2]:
			if command.begins_with("cat ") or command.begins_with("say "):
				continue # ในเทสต์จำลองการคลิกกระดาษด้วย cat — ในเกมผู้เล่นคลิกอ่าน ไม่ต้องรู้คำสั่ง
			var tokens := LevelMission.tokenize(command)
			var id := ""
			if tokens[0] == "git":
				id = spell_of.get(tokens[1], "")
				if tokens[1] == "add" and (tokens.has(".") or tokens.has("-A") or tokens.has("--all")):
					id = "add_all"
				elif tokens[1] == "commit" and (tokens.has("-am") or tokens.has("-a")):
					id = "commit_all"
				elif tokens[1] == "diff" and tokens.has("--staged"):
					id = "diff_staged"
				elif tokens[1] == "restore" and tokens.has("--staged"):
					id = "restore_staged"
				elif tokens[1] == "branch" and tokens.has("-d"):
					id = "branch_delete"
				elif tokens[1] == "switch" and tokens.has("-c"):
					id = "switch_create"
				elif tokens[1] == "remote" and tokens.has("add"):
					id = "remote_add"
				elif tokens[1] == "remote" and tokens.has("set-url"):
					id = "remote_set_url"
				elif tokens[1] == "remote" and tokens.has("remove"):
					id = "remote_remove"
				elif tokens[1] == "commit" and tokens.has("--amend"):
					id = "amend"
				elif tokens[1] == "commit" and CommitEditor.needs_editor(command):
					id = "commit_editor"
				elif tokens[1] == "log" and LevelMission.has_flag(tokens, "-n*"):
					id = "log_n"
				elif tokens[1] == "log" and tokens.has("--graph"):
					id = "log_graph"
				elif tokens[1] == "diff" and tokens.has("HEAD"):
					id = "diff_head"
				elif tokens[1] == "merge" and tokens.has("--abort"):
					id = "merge_abort"
				elif tokens[1] == "push" and not tokens.has("-u"):
					id = "push_named"
			else:
				id = tokens[0]
			_check(known.has(id), "level %d step %d uses '%s' before it is taught" % [play[0], play[1], command])


func _t_room_notes_safe() -> void:
	var outcome := await _play_level(3, 1, ["git status", "git status", "git status", "git status", "cat scroll-b.txt"])
	_check(outcome["mission"].done_count() >= 1, "status completes")
	var session := await _fresh_session("notes-safe")
	await session.execute("git config --global user.name \"Vel\"")
	await session.execute("git config --global user.email \"vel@magic-tower.local\"")
	await session.execute("git init")
	session.files.write_all_text("clue.txt", "เบาะแส\n")
	await session.execute("git add clue.txt")
	await session.execute("git commit -m \"เบาะแส\"")
	session.files.write_all_text("clue.txt", "เบาะแสที่ถูกแก้\n")
	var room := RoomGame.from_config({"wave_every": 1, "items": {"clue.txt": {"kind": "note", "name": "เบาะแส"}}})
	await _room_turn(session, room, "git status")
	_equal("เบาะแสที่ถูกแก้\n", session.files.read_all_text("clue.txt").value)
	_equal(room.max_hearts, room.hearts)
	# ข้อความคำสาปต้องอ่านได้: ไม่มีอักขระประกอบซ้อน (combining marks) ที่ทำให้ภาษาไทยเพี้ยน
	for index in RoomGame.CORRUPTED_TEXT.length():
		var code := RoomGame.CORRUPTED_TEXT.unicode_at(index)
		_check(code < 0x0300 or code > 0x036F, "cursed text must not use combining diacritical marks")
	session.dispose()


func _t_status_labels() -> void:
	var session := await _fresh_session("status-labels")
	await session.execute("git config --global user.name \"Vel\"")
	await session.execute("git config --global user.email \"vel@magic-tower.local\"")
	_check(StatusTranslator.explain(await session.inspect())[0].contains("ยังไม่มีคัมภีร์"))
	await session.execute("git init")
	for path in ["rules.txt", "kept.txt", "altar.txt"]:
		session.files.write_all_text(path, "a\n")
	await session.execute("git add .")
	await session.execute("git commit -m \"เริ่ม\"")
	session.files.write_all_text("rules.txt", "แก้\n")
	session.files.write_all_text("note.txt", "ใหม่\n")
	session.files.write_all_text("altar.txt", "บนแท่น\n")
	await session.execute("git add altar.txt")
	var snapshot := await session.inspect()
	var room := RoomGame.from_config({"items": {"note.txt": {"kind": "fragment", "name": "บันทึกของปรมาจารย์"}}})
	var described := {}
	for item in room.describe(snapshot, ["rules.txt", "kept.txt", "altar.txt", "note.txt"]):
		described[item["path"]] = item
	_equal("modified", described["rules.txt"]["git"])
	_equal("committed", described["kept.txt"]["git"])
	_equal("staged", described["altar.txt"]["git"])
	_equal("untracked", described["note.txt"]["git"])
	_equal("ไร้ตรา (untracked)", described["note.txt"]["label"])
	var text := "\n".join(StatusTranslator.explain(snapshot, room.items))
	_check(text.contains("ไร้ตรา (untracked): บันทึกของปรมาจารย์ [note.txt]"), text)
	_check(text.contains("ถูกแก้ (modified): rules.txt"), text)
	_check(text.contains("บนแท่น (staged): altar.txt"), text)
	_check(not text.contains("kept.txt"), "inscribed scrolls are not listed")
	session.dispose()
