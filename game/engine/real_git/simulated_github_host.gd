class_name SimulatedGitHubHost
extends GitRemoteHost
## GitHub จำลองของ repo หนึ่ง: อ่านข้อมูลจาก bare repository ด้วย git จริง
## ส่วน pull request / review / comment เก็บในหน่วยความจำของ session

const SEP := "\u001f"
const MAX_DIFF_LENGTH := 20000

var _sandbox: GitSandbox
var _remote: LocalRemote
var _runner: GitProcessRunner
var _seed: RemoteSeed
var _pull_requests: Array[PullRequestInfo] = []
## หมายเลข PR -> Array[PullRequestReview]
var _reviews: Dictionary = {}
## หมายเลข PR -> PullRequestDetail ที่บันทึกไว้ตอน merge
var _merged_details: Dictionary = {}
## หมายเลข PR -> Array[PullRequestLineComment]
var _line_comments: Dictionary = {}

var repository_name: String:
	get:
		return _seed.name


func _init(sandbox: GitSandbox, remote: LocalRemote, runner: GitProcessRunner, remote_seed: RemoteSeed) -> void:
	_sandbox = sandbox
	_remote = remote
	_runner = runner
	_seed = remote_seed


func get_repository() -> RemoteRepositoryInfo:
	var branches := await list_branches()
	var default_branch := "main"
	for branch in branches:
		if branch.is_default:
			default_branch = branch.name
			break
	var count := 0
	for branch in branches:
		if branch.name == default_branch:
			count = (await _git(["rev-list", "--count", default_branch] as Array[String])).to_int()
			break
	return RemoteRepositoryInfo.new(_seed.owner, _seed.name, _seed.description, _remote.alias_url,
			default_branch, branches.size(), count)


func list_branches() -> Array[RemoteBranchInfo]:
	var output := await _git([
		"for-each-ref",
		"--format=%(refname:short)%1f%(objectname)%1f%(contents:subject)%1f%(committerdate:iso-strict)",
		"refs/heads",
	] as Array[String])
	var rows: Array[PackedStringArray] = []
	for line in output.split("\n", false):
		rows.append(line.split(SEP))

	var default_name := ""
	for row in rows:
		if row[0] == "main":
			default_name = "main"
			break
	if default_name.is_empty() and not rows.is_empty():
		default_name = rows[0][0]

	var branches: Array[RemoteBranchInfo] = []
	for row in rows:
		var ahead := 0
		var behind := 0
		if not default_name.is_empty() and row[0] != default_name:
			var counts := (await _git(
					["rev-list", "--left-right", "--count", "%s...%s" % [default_name, row[0]]] as Array[String])
					).split("\t")
			if counts.size() == 2:
				behind = counts[0].to_int()
				ahead = counts[1].to_int()
		branches.append(RemoteBranchInfo.new(row[0], row[1], row[0] == default_name, ahead, behind, row[2],
				GitTime.parse_iso(row[3])))
	return branches


func list_commits(branch: String, limit: int = 30) -> Array[RemoteCommitInfo]:
	var commits: Array[RemoteCommitInfo] = []
	if not _require_ref(branch):
		return commits
	var output := await _git([
		"log", branch, "-n%d" % clampi(limit, 1, 200), "--format=%H%x1f%an%x1f%aI%x1f%s",
	] as Array[String])
	for line in output.split("\n", false):
		commits.append(_parse_commit(line))
	return commits


func list_files(branch: String, path: String = "") -> Array[RemoteFileEntry]:
	var entries: Array[RemoteFileEntry] = []
	if not _require_ref(branch):
		return entries
	path = path.lstrip("/").rstrip("/")
	if ".." in path.split("/"):
		return entries

	var arguments: Array[String] = ["ls-tree", "-z", branch]
	if not path.is_empty():
		arguments.append_array(["--", path + "/"] as Array[String])
	var output := await _git(arguments)
	for record in output.split(GitProcessRunner.NUL_CHAR, false):
		var tab := record.find("\t")
		if tab < 0:
			continue
		var kind := record.substr(0, tab).split(" ")[1]
		var full_path := record.substr(tab + 1)
		var last := await _git(["log", "-1", branch, "--format=%H%x1f%an%x1f%aI%x1f%s", "--", full_path] as Array[String])
		entries.append(RemoteFileEntry.new(full_path.get_file(), full_path, kind == "tree",
				null if last.strip_edges().is_empty() else _parse_commit(last)))

	entries.sort_custom(func(a: RemoteFileEntry, b: RemoteFileEntry) -> bool:
		if a.is_directory != b.is_directory:
			return a.is_directory
		return a.name < b.name)
	return entries


func delete_branch(branch: String) -> bool:
	if not _require_ref(branch):
		return false
	for item in await list_branches():
		if item.name == branch and item.is_default:
			return false
	for pull in _pull_requests:
		if pull.state == PullRequestState.OPEN and pull.source_branch == branch:
			return false
	var result := await _runner.run(_sandbox, _remote.bare_repository_path, ["branch", "-D", branch] as Array[String])
	return result.success


func read_file(branch: String, path: String) -> Variant:
	if not _require_ref(branch):
		return null
	if path.begins_with("/") or ".." in path.split("/"):
		return null
	var result := await _runner.run(_sandbox, _remote.bare_repository_path,
			["show", "%s:%s" % [branch, path]] as Array[String])
	return result.standard_output if result.success else null


## รัน git ใน bare repository คืน stdout (ตัด \n ท้ายสุด) หรือ "" เมื่อล้มเหลว
func _git(arguments: Array[String]) -> String:
	var result := await _runner.run(_sandbox, _remote.bare_repository_path, arguments)
	return result.standard_output.rstrip("\n") if result.success else ""


static func _parse_commit(line: String) -> RemoteCommitInfo:
	var parts := line.split(SEP)
	return RemoteCommitInfo.new(parts[0], parts[0].substr(0, 7), parts[1],
			parts[3] if parts.size() > 3 else "", GitTime.parse_iso(parts[2]))


static func _require_ref(value: String) -> bool:
	if value.strip_edges().is_empty() or value.begins_with("-") or value.contains(".."):
		push_error("Invalid branch name.")
		return false
	return true


# ───────────── Pull requests ─────────────


func list_pull_requests() -> Array[PullRequestInfo]:
	var copy: Array[PullRequestInfo] = []
	copy.assign(_pull_requests)
	return copy


func open_pull_request(title: String, body: String, author: String, source_branch: String,
		target_branch: String) -> OpResult:
	if title.strip_edges().is_empty():
		return OpResult.failure("A title is required.")
	var branches := await list_branches()
	var has_source := false
	var has_target := false
	for branch in branches:
		has_source = has_source or branch.name == source_branch
		has_target = has_target or branch.name == target_branch
	if not has_source or not has_target:
		return OpResult.failure("Both branches must exist on the remote.")
	if source_branch == target_branch:
		return OpResult.failure("Source and target branch must differ.")
	for pull in _pull_requests:
		if pull.state == PullRequestState.OPEN and pull.source_branch == source_branch \
				and pull.target_branch == target_branch:
			return OpResult.failure("A pull request for these branches is already open.")
	var new_commits := await _git(["rev-list", "--count", "%s..%s" % [target_branch, source_branch]] as Array[String])
	if new_commits == "0":
		return OpResult.failure("There is nothing to compare: %s has no new commits." % source_branch)

	var pull_request := PullRequestInfo.new(_pull_requests.size() + 1, title, body, author, source_branch,
			target_branch, PullRequestState.OPEN, false, GitTime.now())
	_pull_requests.append(pull_request)
	_reviews[pull_request.number] = []
	_line_comments[pull_request.number] = []
	return OpResult.success(pull_request)


func get_pull_request(number: int) -> PullRequestDetail:
	var pull := _find(number)
	if pull == null:
		return null

	# หลัง merge แล้ว base..source ว่างเปล่า จึงคืนภาพ commit/ไฟล์/diff ที่บันทึกไว้ตอน merge
	if pull.state == PullRequestState.MERGED and _merged_details.has(number):
		var snapshot: PullRequestDetail = (_merged_details[number] as PullRequestDetail).copy()
		snapshot.pull = pull
		snapshot.line_comments = _line_comments_of(number)
		return snapshot

	var commits: Array[RemoteCommitInfo] = []
	var files: Array[PullRequestFileChange] = []
	var diff := ""
	if pull.state != PullRequestState.MERGED:
		var data_range := "%s..%s" % [pull.target_branch, pull.source_branch]
		var triple := "%s...%s" % [pull.target_branch, pull.source_branch]
		for line in (await _git(["log", data_range, "--format=%H%x1f%an%x1f%aI%x1f%s"] as Array[String])).split("\n", false):
			commits.append(_parse_commit(line))

		var statuses := {}
		for line in (await _git(["-c", "core.quotepath=false", "diff", "--no-renames", "--name-status", triple] as Array[String])).split("\n", false):
			var parts := line.split("\t")
			if parts.size() >= 2:
				statuses[parts[parts.size() - 1]] = parts[0].substr(0, 1)
		for line in (await _git(["-c", "core.quotepath=false", "diff", "--no-renames", "--numstat", triple] as Array[String])).split("\n", false):
			var parts := line.split("\t")
			if parts.size() < 3:
				continue
			files.append(PullRequestFileChange.new(parts[2], statuses.get(parts[2], "M"),
					parts[0].to_int() if parts[0].is_valid_int() else 0,
					parts[1].to_int() if parts[1].is_valid_int() else 0))

		diff = await _git(["-c", "core.quotepath=false", "diff", "--no-renames", triple] as Array[String])
		if diff.length() > MAX_DIFF_LENGTH:
			diff = diff.substr(0, MAX_DIFF_LENGTH) + "\n… (diff truncated)"

	var has_conflicts := false
	var blocked_reason: Variant = null
	if pull.state == PullRequestState.OPEN:
		var check := await _check_merge(pull)
		has_conflicts = check["has_conflicts"]
		blocked_reason = check["blocked_reason"]

	var reviews: Array[PullRequestReview] = []
	reviews.assign(_reviews_of(number))
	var detail := PullRequestDetail.new(pull, commits, files, diff, has_conflicts, reviews, blocked_reason)
	detail.line_comments = _line_comments_of(number)
	return detail


func _reviews_of(number: int) -> Array:
	return _reviews.get(number, [])


func _line_comments_of(number: int) -> Array[PullRequestLineComment]:
	var comments: Array[PullRequestLineComment] = []
	comments.assign(_line_comments.get(number, []))
	return comments


func add_line_comment(number: int, author: String, path: String, line: int, on_new_side: bool, body: String,
		start_review: bool) -> PullRequestActionResult:
	var pull := _find(number)
	if pull == null:
		return _not_found(number)
	if pull.state != PullRequestState.OPEN:
		return _not_open(pull)
	if body.strip_edges().is_empty():
		return PullRequestActionResult.new(false, "A comment is required.", pull)
	if line < 1 or path.strip_edges().is_empty():
		return PullRequestActionResult.new(false, "Choose a line in the diff to comment on.", pull)

	_line_comments[number].append(PullRequestLineComment.new(path, line, on_new_side, author, body.strip_edges(),
			GitTime.now(), start_review))
	return PullRequestActionResult.new(true,
			"Review comment added to your pending review." if start_review
			else "Comment added to pull request #%d." % number, pull)


func comment_on_pull_request(number: int, author: String, body: String) -> PullRequestActionResult:
	var pull := _find(number)
	if pull == null:
		return _not_found(number)
	if pull.state != PullRequestState.OPEN:
		return _not_open(pull)
	if body.strip_edges().is_empty():
		return PullRequestActionResult.new(false, "A comment is required.", pull)

	# เก็บเป็น review แบบ Commented เพื่อให้ไทม์ไลน์เดิมแสดงผลเหมือนเดิม แต่ไม่ส่ง pending comments
	_reviews[number].append(PullRequestReview.new(author, ReviewVerdict.COMMENTED, body, GitTime.now()))
	return PullRequestActionResult.new(true, "Comment added to pull request #%d." % number, pull)


func review_pull_request(number: int, reviewer: String, verdict: int, body: String = "") -> PullRequestActionResult:
	var pull := _find(number)
	if pull == null:
		return _not_found(number)
	if pull.state != PullRequestState.OPEN:
		return _not_open(pull)

	if verdict != ReviewVerdict.COMMENTED and not _seed.rules.allow_self_review \
			and pull.author.to_lower() == reviewer.to_lower():
		return PullRequestActionResult.new(false, "You can't approve or request changes on your own pull request.", pull)

	var reviews: Array = _reviews[number]
	reviews.append(PullRequestReview.new(reviewer, verdict, body, GitTime.now()))

	# ส่ง pending review: ความเห็นรายบรรทัดของผู้รีวิวคนนี้กลายเป็นของสาธารณะพร้อมกัน
	var line_comments: Array = _line_comments[number]
	for index in line_comments.size():
		var comment: PullRequestLineComment = line_comments[index]
		if comment.is_pending and comment.author.to_lower() == reviewer.to_lower():
			var published := comment.copy()
			published.is_pending = false
			line_comments[index] = published

	var decision: PullRequestReview = null
	for index in range(reviews.size() - 1, -1, -1):
		if (reviews[index] as PullRequestReview).verdict != ReviewVerdict.COMMENTED:
			decision = reviews[index]
			break
	var updated := _update(number, func(item: PullRequestInfo) -> void:
		item.is_approved = decision != null and decision.verdict == ReviewVerdict.APPROVED)

	var message: String
	match verdict:
		ReviewVerdict.APPROVED:
			message = "Approved pull request #%d." % number
		ReviewVerdict.CHANGES_REQUESTED:
			message = "Requested changes on pull request #%d." % number
		_:
			message = "Comment added to pull request #%d." % number
	return PullRequestActionResult.new(true, message, updated)


func close_pull_request(number: int) -> PullRequestActionResult:
	var pull := _find(number)
	if pull == null:
		return _not_found(number)
	if pull.state != PullRequestState.OPEN:
		return _not_open(pull)

	var closed := _update(number, func(item: PullRequestInfo) -> void: item.state = PullRequestState.CLOSED)
	return PullRequestActionResult.new(true, "Pull request #%d closed." % number, closed)


func merge_pull_request(number: int) -> PullRequestActionResult:
	var pull := _find(number)
	if pull == null:
		return _not_found(number)
	if pull.state != PullRequestState.OPEN:
		return _not_open(pull)

	var check := await _check_merge(pull)
	if check["blocked_reason"] != null:
		return PullRequestActionResult.new(false, check["blocked_reason"], pull)
	var before_merge := await get_pull_request(number)

	var work := _sandbox.attempt_root.path_join("merge-work-%d" % number)
	var owner := _seed.owner
	var failure := ""
	var steps: Array[Dictionary] = [
		{"directory": _sandbox.attempt_root, "arguments": ["clone", _remote.bare_repository_path, work] as Array[String]},
		{"directory": work, "arguments": ["switch", "-c", "pr-target", "origin/" + pull.target_branch] as Array[String]},
		{"directory": work, "arguments": [
			"-c", "user.name=" + owner, "-c", "user.email=%s@git-diwaa.local" % owner.to_lower(),
			"merge", "--no-ff", "origin/" + pull.source_branch,
			"-m", "Merge pull request #%d from %s/%s" % [number, owner, pull.source_branch],
		] as Array[String]},
		{"directory": work, "arguments": ["push", "origin", "pr-target:" + pull.target_branch] as Array[String]},
	]
	for step in steps:
		var result := await _runner.run(_sandbox, step["directory"], step["arguments"])
		if not result.success:
			failure = result.output
			break
	FsUtil.delete_recursive(work)
	if not failure.is_empty():
		return PullRequestActionResult.new(false, "Merge failed: " + failure, pull)

	var merged := _update(number, func(item: PullRequestInfo) -> void: item.state = PullRequestState.MERGED)
	if before_merge != null:
		var snapshot := before_merge.copy()
		snapshot.pull = merged
		snapshot.has_conflicts = false
		snapshot.merge_blocked_reason = null
		_merged_details[number] = snapshot
	return PullRequestActionResult.new(true, "Pull request #%d merged into %s." % [number, pull.target_branch], merged)


## ตรวจว่า merge ได้ไหม: conflict (ตรวจจริงด้วย git merge-tree) และกติกา review ของ repo
## คืน {"has_conflicts": bool, "blocked_reason": String หรือ null}
func _check_merge(pull: PullRequestInfo) -> Dictionary:
	var probe := await _runner.run(_sandbox, _remote.bare_repository_path,
			["merge-tree", "--write-tree", pull.target_branch, pull.source_branch] as Array[String])
	if not probe.success:
		if probe.exit_code == 1:
			return {"has_conflicts": true, "blocked_reason": "This branch has conflicts that must be resolved."}
		return {"has_conflicts": false,
				"blocked_reason": "Unable to check whether this pull request can be merged: " + probe.output}

	if _seed.rules.require_approval and not pull.is_approved:
		return {"has_conflicts": false, "blocked_reason": "Review required: approve the pull request before merging."}
	return {"has_conflicts": false, "blocked_reason": null}


func _find(number: int) -> PullRequestInfo:
	for pull in _pull_requests:
		if pull.number == number:
			return pull
	return null


static func _not_found(number: int) -> PullRequestActionResult:
	return PullRequestActionResult.new(false, "Pull request #%d not found." % number, null)


static func _not_open(pull: PullRequestInfo) -> PullRequestActionResult:
	return PullRequestActionResult.new(false,
			"Pull request #%d is already %s." % [pull.number, PullRequestState.name_of(pull.state)], pull)


## แก้สำเนาของ PR แล้วแทนที่ของเดิม (PullRequestInfo ที่ UI ถืออยู่ไม่ถูกแก้ย้อนหลัง)
func _update(number: int, change: Callable) -> PullRequestInfo:
	for index in _pull_requests.size():
		if _pull_requests[index].number == number:
			var updated := _pull_requests[index].copy()
			change.call(updated)
			_pull_requests[index] = updated
			return updated
	return null
