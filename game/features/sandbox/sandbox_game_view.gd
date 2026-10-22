class_name SandboxGameView
extends Control
## Root Orchestrator for the Git-Diwaa Sandbox Game.
## Follows OOP Mediator / Controller pattern to decouple UI Panels from the Git Sandbox Service.

var _top_bar: TopBarPanel
var _files_panel: FilesPanel
var _git_graph_panel: GitGraphPanel
var _terminal_panel: TerminalPanel
var _remote_repo_button: RemoteRepoButton

var _sandbox_service: GitSandboxService
var _is_initialized := false


func _ready() -> void:
	_bind_nodes()
	_wire_events()
	_initialize_sandbox()


func _bind_nodes() -> void:
	_top_bar = get_node("%TopBar")
	_files_panel = get_node("%FilesPanel")
	_git_graph_panel = get_node("%GitGraphPanel")
	_terminal_panel = get_node("%TerminalPanel")


func _wire_events() -> void:
	_remote_repo_button = RemoteRepoButton.new()
	_remote_repo_button.pressed.connect(_on_repo_pressed)
	_git_graph_panel.add_header_action(_remote_repo_button)
	_terminal_panel.command_submitted.connect(_on_command_submitted)
	_files_panel.open_file_requested.connect(_on_open_file_requested)
	_files_panel.save_file_requested.connect(_on_save_file_requested)
	_files_panel.create_file_requested.connect(_on_create_file_requested)
	_files_panel.create_folder_requested.connect(_on_create_folder_requested)
	_files_panel.rename_entry_requested.connect(_on_rename_entry_requested)
	_files_panel.delete_entry_requested.connect(_on_delete_entry_requested)
	_git_graph_panel.commit_selected.connect(_on_commit_selected)


## Injects or creates the sandbox service. Allows OOP dependency injection.
func set_sandbox_service(service: GitSandboxService) -> void:
	_sandbox_service = service


func _initialize_sandbox() -> void:
	_terminal_panel.set_executing(true)
	_terminal_panel.append_info("Git-Diwaa Terminal กำลังสร้างพื้นที่ทดลอง...")

	if _sandbox_service == null:
		var real_service := RealGitSandboxService.new()
		var started := await real_service.initialize("checkpoint-01")
		if started.ok:
			_sandbox_service = real_service
		else:
			push_error("Real Git initialization failed (%s), falling back to Mock service." % started.message)
			var mock_service := MockGitSandboxService.new()
			await mock_service.initialize()
			_sandbox_service = mock_service

	_is_initialized = true
	_remote_repo_button.set_available(_sandbox_service.remote_account != null)
	_terminal_panel.set_executing(false)

	if _sandbox_service.info != null:
		_terminal_panel.set_window_title("●  ●  ●    TERMINAL — learner@diwaa:~/%s" % _sandbox_service.info.mission_id)
		_terminal_panel.append_info("พร้อมใช้งาน — พิมพ์ help หรือเริ่มด้วย git --version\n")

	await _refresh_state()


func _on_repo_pressed() -> void:
	if _sandbox_service == null or _sandbox_service.remote_account == null:
		_terminal_panel.append_error("หน้า repo ใช้ได้เฉพาะเมื่อเปิดโหมด Real Git")
		return

	var view := (load("res://features/remote_repo/remote_repo_view.tscn") as PackedScene).instantiate() as RemoteRepoView
	view.back_requested.connect(func() -> void: view.queue_free())
	add_child(view)
	view.open(_sandbox_service.remote_account)


func _on_command_submitted(command: String) -> void:
	if not _is_initialized:
		return

	var trimmed := command.strip_edges()
	var lower := trimmed.to_lower()

	# Built-in help handler
	if lower == "help":
		_show_help()
		return

	# Helper host file commands
	if lower.begins_with("write "):
		await _handle_write_command(trimmed)
		return

	if lower.begins_with("cat "):
		await _handle_cat_command(trimmed)
		return

	if lower.begins_with("delete "):
		_handle_delete_command(trimmed)
		return

	if lower == "sandbox-reset":
		_on_reset_requested()
		return

	if lower == "files":
		await _handle_files_command()
		return

	# Execute via Git sandbox service
	_terminal_panel.set_executing(true)
	var result := await _sandbox_service.execute(trimmed)

	if result.success:
		if not result.standard_output.strip_edges().is_empty():
			_terminal_panel.append_output(result.standard_output.strip_edges(false, true))
		else:
			_terminal_panel.append_info("✓ สำเร็จ")
	else:
		var error_message := result.standard_error.strip_edges(false, true) \
				if not result.standard_error.strip_edges().is_empty() \
				else "✗ คำสั่งล้มเหลว (exit %d)" % result.exit_code
		_terminal_panel.append_error(error_message)

	_terminal_panel.set_executing(false)
	await _refresh_state()


func _handle_files_command() -> void:
	var files := await _sandbox_service.get_files()
	if files.is_empty():
		_terminal_panel.append_info("working directory ว่าง")
	else:
		var paths: PackedStringArray = []
		for file in files:
			paths.append(file.path)
		_terminal_panel.append_output("\n".join(paths))


func _handle_write_command(command: String) -> void:
	var parts := TerminalApp.split_command(command, 3)
	if parts.size() < 3:
		_terminal_panel.append_error("วิธีใช้: write <path> <content>")
		return

	var result := await _sandbox_service.write_file(parts[1], parts[2])
	if not result.ok:
		_terminal_panel.append_error("เขียนไฟล์ไม่สำเร็จ: " + result.message)
		return
	_terminal_panel.append_info("✓ เขียนไฟล์ '%s' แล้ว" % parts[1])
	await _refresh_state()


func _handle_cat_command(command: String) -> void:
	var parts := TerminalApp.split_command(command, 2)
	if parts.size() < 2:
		_terminal_panel.append_error("วิธีใช้: cat <path>")
		return

	var result := _sandbox_service.read_file(parts[1])
	if not result.ok:
		_terminal_panel.append_error("อ่านไฟล์ไม่สำเร็จ: " + result.message)
	elif result.value == null:
		_terminal_panel.append_error("ไม่พบไฟล์ '%s'" % parts[1])
	else:
		_terminal_panel.append_output(result.value)


func _handle_delete_command(command: String) -> void:
	var parts := TerminalApp.split_command(command, 2)
	if parts.size() < 2:
		_terminal_panel.append_error("วิธีใช้: delete <path>")
		return

	var result := _sandbox_service.delete_file(parts[1])
	if not result.ok:
		_terminal_panel.append_error("ลบไฟล์ไม่สำเร็จ: " + result.message)
	elif result.value == true:
		_terminal_panel.append_info("✓ ลบ '%s' แล้ว" % parts[1])
		await _refresh_state()
	else:
		_terminal_panel.append_error("ไม่พบไฟล์ '%s'" % parts[1])


func _on_open_file_requested(file_path: String) -> void:
	_files_panel.set_busy(true)
	var result := _sandbox_service.read_file(file_path)
	if not result.ok:
		_files_panel.show_feedback("เปิดไฟล์ไม่สำเร็จ: " + result.message, true)
	elif result.value == null:
		_files_panel.show_feedback("ไม่พบไฟล์ '%s'" % file_path, true)
	else:
		_files_panel.show_file(file_path, result.value)
		_files_panel.show_feedback("เปิด %s แล้ว" % file_path)
	_files_panel.set_busy(false)


func _on_save_file_requested(file_path: String, content: String) -> void:
	_files_panel.set_busy(true)
	var result := await _sandbox_service.write_file(file_path, content)
	if result.ok:
		_files_panel.mark_saved(file_path)
		_files_panel.show_feedback("บันทึก %s แล้ว — Git status อัปเดตแล้ว" % file_path)
		_terminal_panel.append_info("✓ บันทึกไฟล์ '%s' แล้ว" % file_path)
		await _refresh_state()
	else:
		_files_panel.show_feedback("บันทึกไม่สำเร็จ: " + result.message, true)
		_terminal_panel.append_error("บันทึกไฟล์ไม่สำเร็จ: " + result.message)
	_files_panel.set_busy(false)


func _on_create_file_requested(file_path: String, content: String) -> void:
	_files_panel.set_busy(true)
	var failure := ""
	var existing := _sandbox_service.read_file(file_path)
	if existing.ok and existing.value != null:
		failure = "มีไฟล์ '%s' อยู่แล้ว" % file_path
	else:
		var written := await _sandbox_service.write_file(file_path, content)
		if not written.ok:
			failure = written.message

	if failure.is_empty():
		_files_panel.show_file(file_path, content)
		_files_panel.show_feedback("สร้าง %s แล้ว" % file_path)
		_terminal_panel.append_info("✓ สร้างไฟล์ใหม่แล้ว: " + file_path)
		await _refresh_state()
	else:
		_files_panel.show_feedback("สร้างไฟล์ไม่สำเร็จ: " + failure, true)
		_terminal_panel.append_error("สร้างไฟล์ไม่สำเร็จ: " + failure)
	_files_panel.set_busy(false)


func _on_create_folder_requested(folder_path: String) -> void:
	_files_panel.set_busy(true)
	var result := _sandbox_service.create_directory(folder_path)
	if result.ok:
		_files_panel.show_feedback("สร้างโฟลเดอร์ %s แล้ว" % folder_path)
		_terminal_panel.append_info("✓ สร้างโฟลเดอร์ใหม่แล้ว: " + folder_path)
		await _refresh_state()
	else:
		_files_panel.show_feedback("สร้างโฟลเดอร์ไม่สำเร็จ: " + result.message, true)
		_terminal_panel.append_error("สร้างโฟลเดอร์ไม่สำเร็จ: " + result.message)
	_files_panel.set_busy(false)


func _on_rename_entry_requested(source_path: String, destination_path: String) -> void:
	_files_panel.set_busy(true)
	var result := _sandbox_service.rename_entry(source_path, destination_path)
	if result.ok:
		_files_panel.notify_entry_renamed(source_path, destination_path)
		_files_panel.show_feedback("เปลี่ยนชื่อเป็น %s แล้ว" % destination_path)
		_terminal_panel.append_info("✓ เปลี่ยนชื่อ '%s' → '%s'" % [source_path, destination_path])
		await _refresh_state()
	else:
		_files_panel.show_feedback("เปลี่ยนชื่อไม่สำเร็จ: " + result.message, true)
		_terminal_panel.append_error("เปลี่ยนชื่อไม่สำเร็จ: " + result.message)
	_files_panel.set_busy(false)


func _on_delete_entry_requested(entry_path: String, is_directory: bool) -> void:
	_files_panel.set_busy(true)
	var result := _sandbox_service.delete_entry(entry_path, is_directory)
	var failure := ""
	if not result.ok:
		failure = result.message
	elif result.value != true:
		failure = "ไม่พบ '%s'" % entry_path

	if failure.is_empty():
		_files_panel.notify_entry_deleted(entry_path)
		_files_panel.show_feedback("ลบ %s แล้ว — ตรวจสอบได้ด้วย git status" % entry_path)
		_terminal_panel.append_info("✓ ลบ '%s' แล้ว" % entry_path)
		await _refresh_state()
	else:
		_files_panel.show_feedback("ลบไม่สำเร็จ: " + failure, true)
		_terminal_panel.append_error("ลบไม่สำเร็จ: " + failure)
	_files_panel.set_busy(false)


func _on_commit_selected(commit_id: String) -> void:
	_terminal_panel.append_command("git show %s --stat" % commit_id.substr(0, 7))
	var result := await _sandbox_service.execute("git show %s --stat" % commit_id)
	if not result.standard_output.strip_edges().is_empty():
		_terminal_panel.append_output(result.standard_output.strip_edges(false, true))


func _on_reset_requested() -> void:
	_terminal_panel.set_executing(true)
	_terminal_panel.append_info("กำลังรีเซ็ตพื้นที่ sandbox...")
	var result := await _sandbox_service.reset()
	if result.ok:
		_terminal_panel.append_info("✓ รีเซ็ต sandbox เรียบร้อย")
		await _refresh_state()
	else:
		_terminal_panel.append_error("รีเซ็ตไม่สำเร็จ: " + result.message)
	_terminal_panel.set_executing(false)


func _refresh_state() -> void:
	var snapshot := await _sandbox_service.inspect()

	# Always show files, even if git is not initialized
	var entries := await _sandbox_service.get_workspace_entries()
	_files_panel.set_entries(entries)

	if snapshot.is_initialized:
		_git_graph_panel.set_snapshot(snapshot)
	else:
		_git_graph_panel.set_empty_state()


func _show_help() -> void:
	_terminal_panel.append_info("""คำสั่ง Git: git --version, config, init, status, add, commit, log, diff,
            restore, reset, branch, switch, merge, clone, remote, pull, push

คำสั่ง UI: write <path> <content>, cat <path>, delete <path>, files,
           sandbox-reset, clear, help""")


func _exit_tree() -> void:
	if _sandbox_service != null:
		_sandbox_service.dispose()
