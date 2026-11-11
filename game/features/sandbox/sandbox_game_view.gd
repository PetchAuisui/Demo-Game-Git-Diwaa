class_name SandboxGameView
extends Control
## Root Orchestrator for the Git-Diwaa Sandbox Game.
## Follows OOP Mediator / Controller pattern to decouple UI Panels from the Git Sandbox Service.

const CENTRAL_TOWER_CUTSCENE_PATH := "res://features/cutscene/central_tower_cutscene.tscn"
const ENDING_CUTSCENE_PATH := "res://features/cutscene/ending_cutscene.tscn"
const LEVEL_SELECT_PATH := "res://features/level_select/level_select_view.tscn"
const DEFAULT_RETURN_SCENE_PATH := "res://features/cutscene/inside_tower_cutscene.tscn"
const DIALOG_THEME_PATH := "res://features/sandbox/file_dialog_theme.tres"
const ACT2_START_LEVEL := 16
const ACT1_LOOP_SHEET_PATH := "res://assets/cutscene/backgrounds/inside-tower-loop-Sheet.png"
const ACT2_CENTRAL_SHEET_PATH := "res://assets/cutscene/backgrounds/central-tower-Sheet.png"

const BG_SHEET_COLS := 11
const BG_SHEET_ROWS := 12
const BG_FRAME_COUNT := 132
const BG_FPS := 12.0
const BG_FRAME_SIZE := Vector2(480.0, 270.0)

var _sky_backdrop: TextureRect
var _cloud_backdrop: TextureRect
var _tower_hall: TextureRect
var _tower_window_material: Material
var _bg_atlas: AtlasTexture
var _bg_anim_timer := 0.0
var _bg_frame_index := 0

var _top_bar: TopBarPanel
var _files_panel: FilesPanel
var _git_graph_panel: GitGraphPanel
var _terminal_panel: TerminalPanel
var _remote_repo_button: RemoteRepoButton
var _leave_confirm_dialog: ConfirmationDialog
var _leave_confirm_message: Label

var _sandbox_service: GitSandboxService
var _is_initialized := false
var _is_leaving := false
## คำสั่ง git ที่รันสำเร็จในรอบนี้ (ตัวพิมพ์เล็ก) ใช้ตรวจเงื่อนไขภารกิจก่อนกลับสู่เนื้อเรื่อง
var _successful_commands: PackedStringArray = []


func _ready() -> void:
	_bind_nodes()
	_setup_animated_background()
	_setup_leave_confirm_dialog()
	_wire_events()
	SceneLoader.request_preload(LEVEL_SELECT_PATH)
	_initialize_sandbox()


func _process(delta: float) -> void:
	if _bg_atlas == null:
		return
	var frame_duration := 1.0 / BG_FPS
	_bg_anim_timer += delta
	if _bg_anim_timer >= frame_duration:
		var steps := int(_bg_anim_timer / frame_duration)
		_bg_anim_timer = fmod(_bg_anim_timer, frame_duration)
		_bg_frame_index = (_bg_frame_index + steps) % BG_FRAME_COUNT
		_apply_background_frame(_bg_frame_index)


func _bind_nodes() -> void:
	_sky_backdrop = get_node_or_null("SkyBackdrop") as TextureRect
	_cloud_backdrop = get_node_or_null("CloudBackdrop") as TextureRect
	_tower_hall = get_node_or_null("TowerHall") as TextureRect
	_top_bar = get_node("%TopBar")
	_files_panel = get_node("%FilesPanel")
	_git_graph_panel = get_node("%GitGraphPanel")
	_terminal_panel = get_node("%TerminalPanel")


func _setup_animated_background() -> void:
	if _tower_hall == null or not (_tower_hall.texture is AtlasTexture):
		return
	_tower_window_material = _tower_hall.material
	_bg_atlas = (_tower_hall.texture as AtlasTexture).duplicate() as AtlasTexture
	_tower_hall.texture = _bg_atlas
	configure_background_for_level(GameProgressManager.get_selected_level_number())


func configure_background_for_level(level_num: int) -> void:
	if _bg_atlas == null or _tower_hall == null:
		return
	var is_act2 := level_num >= ACT2_START_LEVEL
	var target_path := ACT2_CENTRAL_SHEET_PATH if is_act2 else ACT1_LOOP_SHEET_PATH
	if _bg_atlas.atlas == null or _bg_atlas.atlas.resource_path != target_path:
		if ResourceLoader.exists(target_path):
			var sheet := load(target_path) as Texture2D
			if sheet != null:
				_bg_atlas.atlas = sheet
	if _sky_backdrop != null:
		_sky_backdrop.visible = not is_act2
	if _cloud_backdrop != null:
		_cloud_backdrop.visible = not is_act2
	_tower_hall.material = null if is_act2 else _tower_window_material
	_bg_anim_timer = 0.0
	_bg_frame_index = 0
	_apply_background_frame(0)


func _apply_background_frame(frame_idx: int) -> void:
	if _bg_atlas == null:
		return
	var col := frame_idx % BG_SHEET_COLS
	var row := floori(float(frame_idx) / float(BG_SHEET_COLS))
	if row >= BG_SHEET_ROWS:
		return
	_bg_atlas.region = Rect2(
		Vector2(float(col) * BG_FRAME_SIZE.x, float(row) * BG_FRAME_SIZE.y),
		BG_FRAME_SIZE
	)


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
	_top_bar.brand_pressed.connect(_on_brand_pressed)


func _setup_leave_confirm_dialog() -> void:
	_leave_confirm_dialog = ConfirmationDialog.new()
	_leave_confirm_dialog.name = "LeaveConfirmDialog"
	_leave_confirm_dialog.title = "กลับหน้าเลือกด่าน"
	_leave_confirm_dialog.borderless = true
	_leave_confirm_dialog.unresizable = true
	_leave_confirm_dialog.ok_button_text = "ออกจาก Sandbox"
	_leave_confirm_dialog.cancel_button_text = "อยู่ต่อ"
	if ResourceLoader.exists(DIALOG_THEME_PATH):
		_leave_confirm_dialog.theme = load(DIALOG_THEME_PATH) as Theme
	add_child(_leave_confirm_dialog)
	_leave_confirm_message = DialogStyle.apply(
		_leave_confirm_dialog,
		DialogStyle.WARNING,
		"!",
		"กลับหน้าเลือกด่าน?",
		true
	)
	_leave_confirm_dialog.size = Vector2i(520, 100)
	_leave_confirm_dialog.confirmed.connect(_leave_to_level_select)


func _on_brand_pressed() -> void:
	if _is_leaving:
		return
	var step := GameProgressManager.get_current_gameplay_step()
	var has_unsaved := _files_panel != null and _files_panel.has_unsaved_changes
	if _leave_confirm_dialog == null or _leave_confirm_message == null:
		_leave_to_level_select()
		return
	if step > 0 and has_unsaved:
		_leave_confirm_message.text = "กำลังทำภารกิจด่านที่ %d (ขั้นที่ %d) และมีไฟล์ที่ยังไม่บันทึก\nหากกลับหน้าเลือกด่านตอนนี้ ความคืบหน้าในรอบนี้จะหายไป" % [
			GameProgressManager.get_selected_level_number(), step
		]
	elif step > 0:
		_leave_confirm_message.text = "กำลังทำภารกิจด่านที่ %d (ขั้นที่ %d) อยู่\nหากกลับหน้าเลือกด่านตอนนี้ ความคืบหน้าในรอบนี้จะไม่ถูกบันทึก" % [
			GameProgressManager.get_selected_level_number(), step
		]
	elif has_unsaved:
		_leave_confirm_message.text = "มีไฟล์ที่ยังไม่บันทึก\nต้องการออกจาก Sandbox กลับหน้าเลือกด่านหรือไม่?"
	else:
		_leave_confirm_message.text = "ต้องการออกจาก Sandbox กลับหน้าเลือกด่านหรือไม่?"
	_leave_confirm_dialog.popup_centered()


func _leave_to_level_select() -> void:
	if _is_leaving:
		return
	_is_leaving = true
	var tree := get_tree() if is_inside_tree() else null
	if SceneLoader.change_scene(tree, LEVEL_SELECT_PATH):
		Engine.time_scale = 1.0
		GameProgressManager.set_current_gameplay_step(0)
		GameProgressManager.consume_pending_dialogue_phase()
		GameProgressManager.set_gameplay_return_scene(DEFAULT_RETURN_SCENE_PATH)
	elif not ResourceLoader.exists(LEVEL_SELECT_PATH):
		_is_leaving = false
		if _change_scene_to_cutscene(CENTRAL_TOWER_CUTSCENE_PATH):
			GameProgressManager.set_current_gameplay_step(0)
			GameProgressManager.consume_pending_dialogue_phase()
			GameProgressManager.set_gameplay_return_scene(DEFAULT_RETURN_SCENE_PATH)
	else:
		_is_leaving = false


## Injects or creates the sandbox service. Allows OOP dependency injection.
func set_sandbox_service(service: GitSandboxService) -> void:
	_sandbox_service = service


func _initialize_sandbox() -> void:
	_terminal_panel.set_executing(true)
	_terminal_panel.append_info("Git-Diwaa Terminal กำลังสร้างพื้นที่ทดลอง...")

	if _sandbox_service == null:
		var real_service := RealGitSandboxService.new()
		var started := await real_service.initialize("checkpoint-01")
		if _is_leaving or not is_inside_tree():
			real_service.dispose()
			return
		if started.ok:
			_sandbox_service = real_service
		else:
			push_error("Real Git initialization failed (%s), falling back to Mock service." % started.message)
			var mock_service := MockGitSandboxService.new()
			await mock_service.initialize()
			if _is_leaving or not is_inside_tree():
				mock_service.dispose()
				return
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
		_top_bar.set_mode_text("SANDBOX")
		_top_bar.set_finish_button_text("กลับหน้าเลือกด่าน")

	if _sandbox_service.info != null:
		_terminal_panel.set_window_title("●  ●  ●    TERMINAL — learner@diwaa:~/%s" % _sandbox_service.info.mission_id)
		if step > 0:
			var step_info := LevelDataLoader.get_gameplay_step(lvl, step)
			var hints: Array = step_info.get("hints", [])
			if hints.is_empty():
				_terminal_panel.append_info("📜 ภารกิจด่านที่ %d (ขั้นที่ %d)" % [lvl, step])
			for hint in hints:
				_terminal_panel.append_info("[ด่านที่ %d] %s" % [lvl, hint])
			_terminal_panel.append_info("💡 เมื่อทำภารกิจครบแล้ว ให้กดปุ่ม [เสร็จสิ้น (ไปต่อ)] ด้านบนขวา หรือพิมพ์ 'done' เพื่อดำเนินเนื้อเรื่องต่อ\n")
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
	if lower == "cutscene central" or lower == "cutscene-central":
		play_central_tower_cutscene()
		return

	if lower == "level 16" or lower == "level-16":
		if GameProgressManager.get_selected_level_number() < ACT2_START_LEVEL:
			GameProgressManager.set_selected_level_number(ACT2_START_LEVEL)
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
		_successful_commands.append(lower)
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


func _change_scene_to_cutscene(scene_path: String) -> bool:
	var tree := get_tree() if is_inside_tree() else null
	if ResourceLoader.exists(scene_path) and tree != null:
		if tree.change_scene_to_file(scene_path) == OK:
			Engine.time_scale = 1.0
			return true
	_terminal_panel.append_error("ไม่พบไฟล์ฉาก: %s" % scene_path)
	push_error("[SandboxGameView] Cutscene scene not found: %s" % scene_path)
	return false


func _show_cutscene_help() -> void:
	_terminal_panel.append_info("""คำสั่งเปลี่ยนฉาก Cutscene (สำหรับทดสอบโฟลว์เกม):
  cutscene central  - เล่นฉากหอคอยเวทกลาง (Act 2 / ด่าน 16)
  cutscene ending   - เล่นฉากจบของเกม (Ending & Credits)
  level 16          - จำลองการเข้าสู่ด่าน 16 (ตัดเข้าฉากหอคอยกลาง)""")


func _show_help() -> void:
	_terminal_panel.append_info("""คำสั่ง Git: git --version (หรือ git version), config, init, status, add, commit, log, diff,
            restore, reset, branch, switch, merge, clone, remote, pull, push

คำสั่ง UI / ทดสอบ: write <path> <content>, cat <path>, delete <path>, files,
                  sandbox-reset, cutscene <central|ending>, level 16, clear, help""")


func _on_finish_gameplay_pressed() -> void:
	var current_step := GameProgressManager.get_current_gameplay_step()
	if current_step > 0:
		var missing := _get_missing_requirements(current_step)
		if not missing.is_empty():
			_terminal_panel.append_error("ยังทำภารกิจไม่ครบ — ลองร่ายคาถาเหล่านี้ให้สำเร็จก่อน:\n  " + "\n  ".join(missing))
			return
		# ส่งต่อไปยัง dialogue phase ถัดไป:
		# จบขั้น 1 -> ไป phase 1 (part 2 intro)
		# จบขั้น 2 -> ไป phase 2 (outro)
		var next_phase := 1 if current_step == 1 else 2
		var return_scene := GameProgressManager.get_gameplay_return_scene()
		if return_scene.is_empty():
			return_scene = DEFAULT_RETURN_SCENE_PATH
		if _change_scene_to_cutscene(return_scene):
			_terminal_panel.append_info("กำลังกลับสู่เนื้อเรื่อง...")
			GameProgressManager.set_pending_dialogue_phase(next_phase)
			GameProgressManager.set_current_gameplay_step(0)
	else:
		_leave_to_level_select()


## คืนรายการคำสั่งที่ภารกิจของขั้นนี้ต้องการ แต่ผู้เล่นยังไม่ได้รันสำเร็จ
func _get_missing_requirements(step: int) -> PackedStringArray:
	var missing: PackedStringArray = []
	var step_info := LevelDataLoader.get_gameplay_step(GameProgressManager.get_selected_level_number(), step)
	for req in step_info.get("required", []):
		var tokens: Array = req.get("match", [])
		var satisfied := false
		for cmd in _successful_commands:
			var has_all := true
			for token in tokens:
				if not cmd.contains(str(token).to_lower()):
					has_all = false
					break
			if has_all:
				satisfied = true
				break
		if not satisfied:
			missing.append(str(req.get("label", " ".join(tokens))))
	return missing


func _exit_tree() -> void:
	# ออกจาก Sandbox ทางใดก็ตาม (เช่น คำสั่ง cutscene / level 16) ให้ล้างขั้นภารกิจ ไม่ให้ค้างไปรอบถัดไป
	GameProgressManager.set_current_gameplay_step(0)
	if _sandbox_service != null:
		_sandbox_service.dispose()
