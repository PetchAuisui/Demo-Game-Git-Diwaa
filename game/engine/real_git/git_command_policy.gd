class_name GitCommandPolicy
extends RefCounted
## ตรวจคำสั่ง git ของผู้เล่นก่อนรันจริง: อนุญาตเฉพาะคำสั่งและ option ที่เกมเปิดไว้

const ALLOWED_COMMANDS: Array[String] = [
	"init", "status", "add", "commit", "log", "diff", "restore", "reset",
	"branch", "switch", "merge", "clone", "remote", "fetch", "pull", "push",
]

var _sandbox: GitSandbox
var _remotes: RemoteRegistry


func _init(sandbox: GitSandbox, remotes: RemoteRegistry) -> void:
	_sandbox = sandbox
	_remotes = remotes


## คืนข้อความข้อผิดพลาด หรือ "" เมื่อคำสั่งใช้ได้
func validate(arguments: Array[String]) -> String:
	if arguments.is_empty():
		return "Missing Git command."
	if arguments.size() == 1 and (arguments[0] == "--version" or arguments[0] == "version"):
		return ""
	if arguments[0] == "config":
		return _validate_config(arguments)
	if not ALLOWED_COMMANDS.has(arguments[0]):
		return "Command 'git %s' is not enabled in Git-Diwaa." % arguments[0]

	for argument in arguments:
		if _is_process_escape_option(argument):
			return "Changing Git's executable, config, hooks, or working directory is not allowed."

	match arguments[0]:
		"init":
			return "" if arguments.size() == 1 else "Use: git init"
		"status":
			return "" if arguments.size() == 1 else "Use: git status"
		"add":
			return _validate_path_command(arguments, ["-A", "--all"])
		"commit":
			return _validate_commit(arguments)
		"log":
			return _validate_log(arguments)
		"diff":
			return _validate_diff(arguments)
		"restore":
			return _validate_path_command(arguments, ["--staged"])
		"reset":
			return _validate_reset(arguments)
		"branch":
			return _validate_branch(arguments)
		"switch":
			return _validate_switch(arguments)
		"merge":
			return _validate_merge(arguments)
		"clone":
			return _validate_clone(arguments)
		"remote":
			return _validate_remote(arguments)
		"fetch":
			return _validate_fetch(arguments)
		"pull":
			return _validate_pull(arguments)
		"push":
			return _validate_push(arguments)
	return "Unsupported command."


static func _validate_config(arguments: Array[String]) -> String:
	if arguments.size() < 3 or arguments.size() > 4 or arguments[1] != "--global":
		return "Only sandboxed global user.name and user.email settings are allowed."
	if arguments[2] == "user.name" or arguments[2] == "user.email":
		return ""
	return "Only user.name and user.email may be configured."


static func _validate_commit(arguments: Array[String]) -> String:
	var index := 1
	while index < arguments.size():
		if arguments[index] == "-a" or arguments[index] == "--amend" or arguments[index] == "--no-edit":
			index += 1
			continue
		# -am "ข้อความ" เป็นรูปแบบย่อที่ใช้กันทั่วไป (= -a -m)
		if (arguments[index] == "-m" or arguments[index] == "-am") and index + 1 < arguments.size() \
				and not arguments[index + 1].strip_edges().is_empty():
			index += 2
			continue
		return "Git-Diwaa supports commit with -a, -m, -am, --amend and --no-edit only."
	return ""


static func _validate_log(arguments: Array[String]) -> String:
	var index := 1
	while index < arguments.size():
		var value := arguments[index]
		if value == "--oneline" or value == "--graph" or value == "--all" or value == "--decorate":
			index += 1
			continue
		if value == "-n" and index + 1 < arguments.size() \
				and arguments[index + 1].is_valid_int() and arguments[index + 1].to_int() > 0:
			index += 2
			continue
		if value.begins_with("-n") and value.substr(2).is_valid_int() and value.substr(2).to_int() > 0:
			index += 1
			continue
		return "Git-Diwaa supports log with --oneline, --graph, --all, --decorate and -n only."
	return ""


static func _validate_diff(arguments: Array[String]) -> String:
	for index in range(1, arguments.size()):
		if arguments[index] != "--staged" and arguments[index] != "HEAD":
			return "Use: git diff [--staged] or git diff HEAD"
	return ""


static func _validate_reset(arguments: Array[String]) -> String:
	if arguments.size() > 3:
		return "Use one reset mode and one revision."
	for index in range(1, arguments.size()):
		var value := arguments[index]
		if value.begins_with("-") and value != "--soft" and value != "--mixed" and value != "--hard":
			return "Reset mode must be --soft, --mixed or --hard."
	for index in range(1, arguments.size()):
		var value := arguments[index]
		if not value.begins_with("-") and not _is_safe_revision(value):
			return "Invalid reset revision."
	return ""


static func _validate_branch(arguments: Array[String]) -> String:
	if arguments.size() == 1:
		return ""
	if arguments.size() == 2 and (arguments[1] == "-a" or arguments[1] == "--all"):
		return ""
	if arguments.size() == 2 and _is_safe_ref(arguments[1]):
		return ""
	if arguments.size() == 3 and arguments[1] == "-d" and _is_safe_ref(arguments[2]):
		return ""
	return "Use: git branch, git branch --all, git branch <name>, or git branch -d <name>."


static func _validate_switch(arguments: Array[String]) -> String:
	if arguments.size() == 2 and _is_safe_ref(arguments[1]):
		return ""
	if arguments.size() == 3 and arguments[1] == "-c" and _is_safe_ref(arguments[2]):
		return ""
	return "Use: git switch <branch> or git switch -c <branch>."


static func _validate_merge(arguments: Array[String]) -> String:
	if arguments.size() == 2 and (arguments[1] == "--abort" or _is_safe_ref(arguments[1])):
		return ""
	if arguments.size() == 3 and arguments[1] == "--no-ff" and _is_safe_ref(arguments[2]):
		return ""
	return "Use: git merge <branch>, git merge --no-ff <branch>, or git merge --abort."


func _validate_clone(arguments: Array[String]) -> String:
	if arguments.size() != 2:
		return "Use: git clone <game-remote-url>."
	if FsUtil.dir_has_entries(_sandbox.player_repository_path):
		return "The player repository must be empty before clone."
	return _validate_remote_url(arguments[1])


func _validate_remote(arguments: Array[String]) -> String:
	if arguments.size() == 2 and arguments[1] == "-v":
		return ""
	if arguments.size() == 4 and arguments[1] == "add" and _is_safe_ref(arguments[2]):
		return _validate_remote_url(arguments[3])
	if arguments.size() == 4 and arguments[1] == "set-url" and _is_safe_ref(arguments[2]):
		return _validate_remote_url(arguments[3])
	if arguments.size() == 3 and arguments[1] == "remove" and _is_safe_ref(arguments[2]):
		return ""
	return "Git-Diwaa supports remote -v, add, set-url and remove."


static func _validate_fetch(arguments: Array[String]) -> String:
	if arguments.size() <= 2 and (arguments.size() == 1 or _is_safe_ref(arguments[1])):
		return ""
	return "Use: git fetch [remote]."


static func _validate_pull(arguments: Array[String]) -> String:
	var remaining := _without(arguments, ["--rebase"])
	if remaining.size() <= 2 and remaining.all(_is_safe_ref):
		return ""
	return "Use: git pull [--rebase] [remote] [branch]."


static func _validate_push(arguments: Array[String]) -> String:
	var remaining := _without(arguments, ["-u", "--set-upstream", "-f", "--force"])
	if remaining.size() <= 2 and remaining.all(_is_safe_ref):
		return ""
	return "Use: git push [-u] [--force] [remote] [branch]."


## อาร์กิวเมนต์หลังชื่อคำสั่ง ตัด option ที่ระบุออก
static func _without(arguments: Array[String], removed: Array[String]) -> Array[String]:
	var remaining: Array[String] = []
	for index in range(1, arguments.size()):
		if not removed.has(arguments[index]):
			remaining.append(arguments[index])
	return remaining


static func _validate_path_command(arguments: Array[String], allowed_options: Array[String]) -> String:
	if arguments.size() < 2:
		return "git %s requires a file path." % arguments[0]
	for index in range(1, arguments.size()):
		var value := arguments[index]
		if value.begins_with("-") and not allowed_options.has(value):
			return "Option '%s' is not enabled." % value
		if not value.begins_with("-") and value != "." and not _is_safe_relative_path(value):
			return "File path escapes the repository or targets Git metadata."
	return ""


func _validate_remote_url(url: String) -> String:
	for remote in _remotes.retired:
		if url == remote.alias_url:
			return ""
	for remote in _remotes.remotes:
		if url == remote.alias_url:
			return ""
		if FsUtil.is_rooted(url) and FsUtil.same_path(FsUtil.full_path(url), FsUtil.full_path(remote.bare_repository_path)):
			return ""

	if _remotes.remotes.is_empty():
		return "No remotes are registered for this Git-Diwaa session yet. Create a repository from the Magic Vault page first."

	var aliases: Array[String] = []
	for remote in _remotes.remotes:
		aliases.append(remote.alias_url)
	return "Only the remotes registered for this Git-Diwaa session are allowed: " + ", ".join(aliases)


static func _is_process_escape_option(value: String) -> bool:
	return value == "-C" or value == "--exec-path" or value == "--git-dir" or value == "--work-tree" \
			or value == "--config-env" \
			or value.begins_with("--exec-path=") or value.begins_with("--git-dir=") \
			or value.begins_with("--work-tree=") or value.begins_with("--config-env=") \
			or value.begins_with("--upload-pack=") or value.begins_with("--receive-pack=")


static func _path_segments(value: String) -> PackedStringArray:
	var segments: PackedStringArray = []
	for part in value.replace("\\", "/").split("/", false):
		segments.append(part)
	return segments


static func _is_safe_relative_path(value: String) -> bool:
	if FsUtil.is_rooted(value):
		return false
	for segment in _path_segments(value):
		if segment == ".." or segment.to_lower() == ".git":
			return false
	return true


static func _is_ascii_alphanumeric(character: String) -> bool:
	var code := character.unicode_at(0)
	return (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122)


static func _is_safe_revision(value: String) -> bool:
	if value.strip_edges().is_empty() or value.begins_with("-"):
		return false
	for index in value.length():
		var character := value[index]
		if not _is_ascii_alphanumeric(character) and not "-_/.~^".contains(character):
			return false
	return true


static func _is_safe_ref(value: String) -> bool:
	if value.strip_edges().is_empty() or value.begins_with("-") or value.contains("..") or value.ends_with("."):
		return false
	for index in value.length():
		var character := value[index]
		if not _is_ascii_alphanumeric(character) and not "-_/.".contains(character):
			return false
	return true
