class_name SandboxGameView
extends Control
## Root Orchestrator for the Git-Diwaa Sandbox Game.
## Follows OOP Mediator / Controller pattern to decouple UI Panels from the Git Sandbox Service.

const CENTRAL_TOWER_CUTSCENE_PATH := "res://features/cutscene/central_tower_cutscene.tscn"
const ENDING_CUTSCENE_PATH := "res://features/cutscene/ending_cutscene.tscn"

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
	_top_bar.finish_pressed.connect(_on_finish_gameplay_pressed)
	_top_bar.brand_pressed.connect(func(): get_tree().change_scene_to_file("res://features/level_select/level_select_view.tscn"))


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

	var step := GameProgressManager.get_current_gameplay_step()
	var lvl := GameProgressManager.get_selected_level_number()
	if step > 0:
		_top_bar.set_mode_text("ด่านที่ %d (ขั้นที่ %d)" % [lvl, step])
		_top_bar.set_finish_button_text("เสร็จสิ้น (ไปต่อ) ➔")
	else:
		_top_bar.set_finish_button_text("กลับหน้าเลือกด่าน")

	if _sandbox_service.info != null:
		_terminal_panel.set_window_title("●  ●  ●    TERMINAL — learner@diwaa:~/%s" % _sandbox_service.info.mission_id)
		if step == 1:
			_terminal_panel.append_info("📜 ภารกิจด่านที่ %d (ขั้นที่ 1): ลองพิมพ์คำสั่ง 'git --version' เพื่อตรวจสอบพลัง" % lvl)
			_terminal_panel.append_info("💡 เมื่อทดลองจนพอใจแล้ว ให้กดปุ่ม [เสร็จสิ้น (ไปต่อ)] ด้านบนขวา หรือพิมพ์ 'done' เพื่อดำเนินเนื้อเรื่องต่อ\n")
		elif step == 2:
			_terminal_panel.append_info("📜 ภารกิจด่านที่ %d (ขั้นที่ 2): ลองพิมพ์คำสั่ง 'git config --global user.name \"Vel\"' และ 'git config --global user.email \"vel@magic.world\"'" % lvl)
			_terminal_panel.append_info("💡 เมื่อทดลองจนพอใจแล้ว ให้กดปุ่ม [เสร็จสิ้น (ไปต่อ)] ด้านบนขวา หรือพิมพ์ 'done' เพื่อดำเนินเนื้อเรื่องต่อ\n")
		else:
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

	# Finished mission or exit
	if lower in ["done", "finish", "exit", "quit"]:
		_on_finish_gameplay_pressed()
		return

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

	# Cutscene & Level transition commands (Dev/Testing flow to Cutscenes)
	if lower == "cutscene central" or lower == "cutscene-central" or lower == "level 16" or lower == "level-16":
		play_central_tower_cutscene()
		return

	if lower == "cutscene ending" or lower == "cutscene-ending" or lower == "ending":
		play_ending_cutscene()
		return

	if lower == "cutscene" or lower == "cutscenes":
		_show_cutscene_help()
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


## Transitions to the Central Tower cutscene (Act 2: GitHub Flow / Level 16)
func play_central_tower_cutscene() -> void:
	_terminal_panel.append_info("กำลังเปลี่ยนฉากไปยังหอคอยเวทกลาง (Central Tower)...")
	_change_scene_to_cutscene(CENTRAL_TOWER_CUTSCENE_PATH)


## Transitions to the Ending cutscene (Clear all levels / Epilogue)
func play_ending_cutscene() -> void:
	_terminal_panel.append_info("กำลังเปลี่ยนฉากไปยังฉากจบ (Ending Cutscene)...")
	_change_scene_to_cutscene(ENDING_CUTSCENE_PATH)


func _change_scene_to_cutscene(scene_path: String) -> void:
	if ResourceLoader.exists(scene_path):
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file(scene_path)
	else:
		_terminal_panel.append_error("ไม่พบไฟล์ฉาก: %s" % scene_path)
		push_error("[SandboxGameView] Cutscene scene not found: %s" % scene_path)


func _show_cutscene_help() -> void:
	_terminal_panel.append_info("""คำสั่งเปลี่ยนฉาก Cutscene (สำหรับทดสอบโฟลว์เกม):
  cutscene central  - เล่นฉากหอคอยเวทกลาง (Act 2 / ด่าน 16)
  cutscene ending   - เล่นฉากจบของเกม (Ending & Credits)
  level 16          - จำลองการเข้าสู่ด่าน 16 (ตัดเข้าฉากหอคอยกลาง)""")


func _show_help() -> void:
	_terminal_panel.append_info("""คำสั่ง Git: git --version, config, init, status, add, commit, log, diff,
            restore, reset, branch, switch, merge, clone, remote, pull, push

คำสั่ง UI / ทดสอบ: write <path> <content>, cat <path>, delete <path>, files,
                  sandbox-reset, cutscene <central|ending>, level 16, clear, help""")


func _on_finish_gameplay_pressed() -> void:
	var current_step := GameProgressManager.get_current_gameplay_step()
	if current_step > 0:
		# ส่งต่อไปยัง dialogue phase ถัดไป:
		# จบขั้น 1 -> ไป phase 1 (part 2 intro)
		# จบขั้น 2 -> ไป phase 2 (outro)
		var next_phase := 1 if current_step == 1 else 2
		GameProgressManager.set_pending_dialogue_phase(next_phase)
		GameProgressManager.set_current_gameplay_step(0)
		var return_scene := GameProgressManager.get_gameplay_return_scene()
		if return_scene.is_empty():
			return_scene = "res://features/cutscene/inside_tower_cutscene.tscn"
		_terminal_panel.append_info("กำลังกลับสู่เนื้อเรื่อง...")
		_change_scene_to_cutscene(return_scene)
	else:
		var level_select_path := "res://features/level_select/level_select_view.tscn"
		if ResourceLoader.exists(level_select_path):
			get_tree().change_scene_to_file(level_select_path)
		else:
			_change_scene_to_cutscene(CENTRAL_TOWER_CUTSCENE_PATH)


func _exit_tree() -> void:
	if _sandbox_service != null:
		_sandbox_service.dispose()
