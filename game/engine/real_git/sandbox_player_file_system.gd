class_name SandboxPlayerFileSystem
extends PlayerFileSystem
## ไฟล์ของผู้เล่นใน player-repo: ทุก path ต้องอยู่ในโฟลเดอร์นี้ ห้ามแตะ .git และห้ามผ่าน symlink

var _root: String
var _root_with_separator: String


func _init(sandbox: GitSandbox) -> void:
	_root = FsUtil.full_path(sandbox.player_repository_path)
	_root_with_separator = _root.rstrip("/") + "/"


func write_all_text(relative_path: String, content: String) -> OpResult:
	var resolved := _resolve(relative_path)
	if not resolved.ok:
		return resolved
	var path: String = resolved.value
	var link_check := _ensure_no_symbolic_links(path)
	if not link_check.ok:
		return link_check
	FsUtil.make_dirs(path.get_base_dir())
	if not FsUtil.write_text(path, content):
		return OpResult.failure("Could not write '%s'." % relative_path)
	return OpResult.success()


func read_all_text(relative_path: String) -> OpResult:
	var resolved := _resolve(relative_path)
	if not resolved.ok:
		return resolved
	var path: String = resolved.value
	var link_check := _ensure_no_symbolic_links(path)
	if not link_check.ok:
		return link_check
	if not FsUtil.file_exists(path):
		return OpResult.success(null)
	return OpResult.success(FsUtil.read_text(path))


func create_directory(relative_path: String) -> OpResult:
	var resolved := _resolve(relative_path)
	if not resolved.ok:
		return resolved
	var path: String = resolved.value
	var link_check := _ensure_no_symbolic_links(path)
	if not link_check.ok:
		return link_check
	if FsUtil.file_exists(path):
		return OpResult.failure("A file already exists at '%s'." % relative_path)
	FsUtil.make_dirs(path)
	return OpResult.success()


func move(source_relative_path: String, destination_relative_path: String) -> OpResult:
	var source_resolved := _resolve(source_relative_path)
	if not source_resolved.ok:
		return source_resolved
	var destination_resolved := _resolve(destination_relative_path)
	if not destination_resolved.ok:
		return destination_resolved
	var source: String = source_resolved.value
	var destination: String = destination_resolved.value
	var link_check := _ensure_no_symbolic_links(source)
	if not link_check.ok:
		return link_check
	link_check = _ensure_no_symbolic_links(destination)
	if not link_check.ok:
		return link_check

	if FsUtil.file_exists(destination) or FsUtil.dir_exists(destination):
		return OpResult.failure("An entry already exists at '%s'." % destination_relative_path)
	if not FsUtil.file_exists(source) and not FsUtil.dir_exists(source):
		return OpResult.failure("Workspace entry '%s' was not found." % source_relative_path)

	FsUtil.make_dirs(destination.get_base_dir())
	if DirAccess.rename_absolute(source, destination) != OK:
		return OpResult.failure("Could not move '%s'." % source_relative_path)
	return OpResult.success()


func delete(relative_path: String) -> OpResult:
	var resolved := _resolve(relative_path)
	if not resolved.ok:
		return resolved
	var path: String = resolved.value
	var link_check := _ensure_no_symbolic_links(path)
	if not link_check.ok:
		return link_check
	if not FsUtil.file_exists(path):
		return OpResult.success(false)
	if DirAccess.remove_absolute(path) != OK:
		return OpResult.failure("Could not delete '%s'." % relative_path)
	return OpResult.success(true)


func delete_directory(relative_path: String, recursive: bool = false) -> OpResult:
	var resolved := _resolve(relative_path)
	if not resolved.ok:
		return resolved
	var path: String = resolved.value
	var link_check := _ensure_no_symbolic_links(path)
	if not link_check.ok:
		return link_check
	if not FsUtil.dir_exists(path):
		return OpResult.success(false)
	if recursive:
		FsUtil.delete_recursive(path)
	elif DirAccess.remove_absolute(path) != OK:
		return OpResult.failure("The directory '%s' is not empty." % relative_path)
	return OpResult.success(true)


func list_files() -> Array[String]:
	var files: Array[String] = []
	for entry in list_entries():
		if not entry.is_directory:
			files.append(entry.path)
	return files


func list_entries() -> Array[PlayerWorkspaceEntry]:
	var entries: Array[PlayerWorkspaceEntry] = []
	_collect(_root, "", entries)
	entries.sort_custom(func(a: PlayerWorkspaceEntry, b: PlayerWorkspaceEntry) -> bool: return a.path < b.path)
	return entries


func _collect(directory: String, prefix: String, entries: Array[PlayerWorkspaceEntry]) -> void:
	for name in FsUtil.list_children(directory):
		var absolute := directory.path_join(name)
		if _is_git_metadata(absolute) or FsUtil.is_symlink(absolute):
			continue
		var relative := name if prefix.is_empty() else prefix + "/" + name
		var is_directory := FsUtil.dir_exists(absolute)
		entries.append(PlayerWorkspaceEntry.new(relative, is_directory))
		if is_directory:
			_collect(absolute, relative, entries)


## คืน OpResult (value = path เต็มใน sandbox)
func _resolve(relative_path: String) -> OpResult:
	if relative_path.strip_edges().is_empty() or FsUtil.is_rooted(relative_path):
		return OpResult.failure("Use a repository-relative file path.")
	var full := FsUtil.full_path(_root.path_join(FsUtil.normalize(relative_path)))
	if not FsUtil.starts_with_path(full, _root_with_separator) or _is_git_metadata(full):
		return OpResult.failure("File path must stay inside the repository and outside .git.")
	return OpResult.success(full)


func _ensure_no_symbolic_links(path: String) -> OpResult:
	var relative := path.substr(_root_with_separator.length())
	var current := _root
	for segment in relative.split("/", false):
		current = current.path_join(segment)
		if not FsUtil.file_exists(current) and not FsUtil.dir_exists(current):
			continue
		if FsUtil.is_symlink(current):
			return OpResult.failure("Symbolic links are not supported in player file operations.")
	return OpResult.success()


func _is_git_metadata(path: String) -> bool:
	var git_path := _root.path_join(".git")
	return FsUtil.same_path(path, git_path) or FsUtil.starts_with_path(path, git_path + "/")
