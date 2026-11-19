class_name SandboxGameView
extends Control
## Root Orchestrator for the Git-Diwaa Sandbox Game.
## Follows OOP Mediator / Controller pattern to decouple UI Panels from the Git Sandbox Service.

const CENTRAL_TOWER_CUTSCENE_PATH := "res://features/cutscene/central_tower_cutscene.tscn"
const ENDING_CUTSCENE_PATH := "res://features/cutscene/ending_cutscene.tscn"
const LEVEL_SELECT_PATH := "res://features/level_select/level_select_view.tscn"
const LEVEL_DIALOGUE_PATH := "res://features/dialogue/level_dialogue_view.tscn"
const START_VIEW_PATH := "res://features/start/start_view.tscn"
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
var _mission: LevelMission
var _mission_panel: LevelMissionPanel
var _spell_overlay: SpellEffectOverlay
## มินิเกมห้อง (null = ด่านนี้ไม่มีมินิเกม)
var _room: RoomGame
var _room_view: RoomView
## ม้วนคาถาใหม่ / สมุดคาถา (สอนคำสั่งตอนที่ต้องใช้จริง)
var _spell_view: SpellScrollView
## จำนวนครั้งที่ผู้เล่นร่ายพลาดติดกันในเป้าหมายปัจจุบัน (ครบ 2 ครั้ง มิวราช่วยใบ้เอง)
var _mistakes := 0
const MIURA_HINT_AFTER := 2
var _leave_confirm_dialog: ConfirmationDialog
var _leave_confirm_message: Label

var _sandbox_service: GitSandboxService
var _is_initialized := false
var _is_leaving := false
var _level_timer_active := false
var _level_time_remaining := 0.0
var _timer_expired_notified := false


func _ready() -> void:
	_bind_nodes()
	_setup_animated_background()
	_setup_leave_confirm_dialog()
	_wire_events()
	_setup_spell_overlay()
	_setup_mission()
	SceneLoader.request_preload(_return_scene_path())
	_initialize_sandbox()


func _process(delta: float) -> void:
	_process_background_anim(delta)
	_process_level_timer(delta)


func _process_background_anim(delta: float) -> void:
	if _bg_atlas == null:
		return
	var frame_duration := 1.0 / BG_FPS
	_bg_anim_timer += delta
	if _bg_anim_timer >= frame_duration:
		var steps := int(_bg_anim_timer / frame_duration)
		_bg_anim_timer = fmod(_bg_anim_timer, frame_duration)
		_bg_frame_index = (_bg_frame_index + steps) % BG_FRAME_COUNT
		_apply_background_frame(_bg_frame_index)


func _process_level_timer(delta: float) -> void:
	if not _level_timer_active or _mission == null or _mission.time_limit <= 0.0:
		return
	if _level_time_remaining > 0.0:
		_level_time_remaining = maxf(0.0, _level_time_remaining - delta)
		GameProgressManager.set_level_time_remaining(_mission.level_number, _level_time_remaining)
		if _top_bar != null:
			_top_bar.set_timer_seconds(_level_time_remaining)
		if _level_time_remaining <= 0.0 and not _timer_expired_notified:
			_timer_expired_notified = true
			_on_level_timer_expired()


func _on_level_timer_expired() -> void:
	if _mission_panel != null:
		_mission_panel.show_feedback("หมดเวลาทดสอบแล้ว! ยังสามารถพิมพ์คำสั่งต่อเพื่อฝึกฝนได้", true)


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
	_files_panel.move_entry_requested.connect(_on_move_entry_requested)
	_files_panel.delete_entry_requested.connect(_on_delete_entry_requested)
	_git_graph_panel.commit_selected.connect(_on_commit_selected)
	_top_bar.finish_pressed.connect(_leave_sandbox)
	_top_bar.brand_pressed.connect(_on_brand_pressed)


## เปิดจากขั้นเล่นจริงของด่าน (หน้าบทสนทนาตั้งขั้นไว้ใน GameProgressManager) -> แสดงแผงภารกิจกลางจอ
## เวทีเอฟเฟกต์คาถากลางฉาก (Game Design v2 §4.1): วางเหนือพื้นหลัง ใต้แผงต่าง ๆ จึงไม่บังข้อความ
func _setup_spell_overlay() -> void:
	_spell_overlay = SpellEffectOverlay.new()
	_spell_overlay.name = "SpellEffectOverlay"
	add_child(_spell_overlay)
	move_child(_spell_overlay, _top_bar.get_index())
	_spell_overlay.effect_started.connect(_on_spell_effect_started)


func _on_spell_effect_started(effect: Dictionary) -> void:
	var target: Control = null
	match str(effect.get("panel", "")):
		"files":
			target = _files_panel
		"graph":
			target = _git_graph_panel
		"terminal":
			target = _terminal_panel
	if target == null or not target.is_visible_in_tree():
		return
	var color: Color = SpellEffectOverlay.COLORS.get(effect["kind"], Color.WHITE)
	var tw := create_tween()
	tw.tween_property(target, "self_modulate", color.lightened(0.55), 0.15)
	tw.tween_property(target, "self_modulate", Color.WHITE, 0.6).set_trans(Tween.TRANS_SINE)


func _setup_mission() -> void:
	var step := GameProgressManager.get_pending_mission_step()
	GameProgressManager.set_pending_mission_step(0)
	if step <= 0:
		if _top_bar != null:
			_top_bar.set_timer_visible(false)
		return
	_mission = LevelMission.create(GameProgressManager.get_selected_level_number(), step)
	if _mission == null:
		if _top_bar != null:
			_top_bar.set_timer_visible(false)
		return
	_mission_panel = LevelMissionPanel.new()
	_mission_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_dock_mission_panel_above_files()
	_mission_panel.setup(_mission)
	_apply_contextual_panels()
	_mission_panel.continue_pressed.connect(_on_mission_continue)
	_mission_panel.retry_pressed.connect(_on_room_retry)
	_mission_panel.spellbook_pressed.connect(_open_spellbook)
	_setup_room()
	_update_mission_prompt()

	if _mission.time_limit > 0.0:
		var saved_time := GameProgressManager.get_level_time_remaining(_mission.level_number)
		if saved_time < 0.0:
			_level_time_remaining = _mission.time_limit
			GameProgressManager.set_level_time_remaining(_mission.level_number, _level_time_remaining)
		else:
			_level_time_remaining = saved_time
		_level_timer_active = true
		# เวลาที่หมดไปแล้วในขั้นก่อนหน้า (0) ต้องไม่ถูกรีเซ็ตและไม่แจ้งเตือนซ้ำ
		_timer_expired_notified = _level_time_remaining <= 0.0
		if _top_bar != null:
			_top_bar.set_timer_visible(true)
			_top_bar.set_timer_seconds(_level_time_remaining)
	else:
		if _top_bar != null:
			_top_bar.set_timer_visible(false)


## สอนคาถาตอนที่ต้องใช้จริง: ขั้นที่มีคีย์ "teaches" แจกม้วนคาถาใหม่ตอนเริ่ม
func _ensure_spell_view() -> SpellScrollView:
	if _spell_view == null:
		_spell_view = SpellScrollView.new()
		_spell_view.name = "SpellScrollView"
		add_child(_spell_view)
		_spell_view.closed.connect(_terminal_panel.focus_input)
	return _spell_view


func _show_new_spells() -> void:
	if _mission == null:
		return
	var ids := SpellCatalog.taught_in(_mission.level_number, _mission.step)
	if ids.is_empty():
		return
	_ensure_spell_view().show_new_spells(ids, _mission.level_number)
	_terminal_panel.append_info("✦ ได้รับม้วนคาถาใหม่ — เปิดดูอีกครั้งได้จากปุ่ม \"คาถา\" หรือพิมพ์ spells")


func _open_spellbook() -> void:
	var ids: Array[String] = []
	if _mission != null:
		ids = SpellCatalog.learned_until(_mission.level_number, _mission.step)
	else:
		for id in SpellCatalog.SPELLS.keys():
			ids.append(str(id))
	_ensure_spell_view().show_spellbook(ids)


## มิวราช่วยเมื่อผู้เล่นติด: ร่ายพลาดซ้ำ หรือเพิ่งเสียหัวใจ → บอกคำใบ้ของเป้าหมายปัจจุบันเอง
func _miura_hint(reason: String) -> void:
	if _mission == null or _mission_panel == null or _mission.is_complete():
		return
	var hint := str(_mission.current_objective().get("hint", ""))
	if hint.is_empty():
		return
	_mistakes = 0
	_mission_panel.show_feedback("มิวรา: %s — %s" % [reason, hint], false)
	_terminal_panel.append_info("✦ มิวรา: " + hint)


## มินิเกมห้อง: ห้องในหอคอยกลางฉาก ของในห้องคือไฟล์จริง คลื่นโกลาหลทำลายสิ่งที่ยังไม่จารึก
func _setup_room() -> void:
	if _mission == null or _mission.room.is_empty():
		return
	_room = RoomGame.from_config(_mission.room)
	_spell_overlay.compact = true
	if _room_view == null:
		_room_view = RoomView.new()
		_room_view.name = "RoomView"
		add_child(_room_view)
		_room_view.place_in_stage()
		_room_view.item_pressed.connect(func(path: String) -> void:
			if _is_initialized and not _room.is_failed():
				_terminal_panel.submit_command("cat " + path))
		move_child(_room_view, _spell_overlay.get_index())


func _workspace_paths() -> Array[String]:
	var paths: Array[String] = []
	for entry in await _sandbox_service.get_workspace_entries():
		if not entry.is_directory:
			paths.append(entry.path)
	return paths


func _update_room_view() -> void:
	if _room == null or _room_view == null:
		return
	var snapshot := await _sandbox_service.inspect()
	var paths := await _workspace_paths()
	if _is_leaving or not is_inside_tree():
		return
	var branch := str(snapshot.current_branch) if snapshot.is_initialized and snapshot.current_branch != null else ""
	_room_view.update_room(_room, _room.describe(snapshot, paths), branch)


## ของตั้งต้นของห้อง (turn 0) และจดจำเนื้อหาเศษคัมภีร์ที่มีอยู่ เพื่อให้เศษที่สลายก่อตัวใหม่ได้
func _start_room() -> void:
	if _room == null:
		return
	await _apply_world_actions(_room.initial_actions())
	_room.set_present(await _workspace_paths())
	for path in _room.items.keys():
		var read := _sandbox_service.read_file(str(path))
		if read.ok and read.value != null:
			_room.remember_content(str(path), str(read.value))
	await _update_room_view()


## หนึ่งการกระทำของผู้เล่นผ่านไป → โลกเดินหนึ่งจังหวะ (คลื่นโกลาหล, ของที่ปรากฏ)
func _advance_room(command: String) -> void:
	if _room == null or _room.is_failed() or (_mission != null and _mission.is_complete()):
		return
	var snapshot := await _sandbox_service.inspect()
	var paths := await _workspace_paths()
	if _is_leaving or not is_inside_tree():
		return
	_room.set_present(paths)
	var outcome := _room.on_turn(snapshot, command)
	var actions: Array = outcome["actions"]
	_room_view.play_events(outcome["events"])
	for event in outcome["events"]:
		_terminal_panel.append_info("✦ " + str(event["text"]))
	if outcome["events"].any(func(e: Dictionary) -> bool: return e["type"] == "damage") and not _room.is_failed():
		_miura_hint("ระวัง! พลังลดลงแล้ว")
	if actions.is_empty():
		# โลกไม่เปลี่ยน: ใช้สถานะที่เพิ่งอ่านมาวาดห้องเลย ไม่ต้องตรวจ repo ซ้ำ (ห้องตอบสนองไวขึ้น)
		var branch := str(snapshot.current_branch) if snapshot.is_initialized and snapshot.current_branch != null else ""
		_room_view.update_room(_room, _room.describe(snapshot, paths), branch)
	else:
		await _apply_world_actions(actions)
		await _refresh_state()
		await _update_room_view()
	_check_room_defeat()


func _apply_world_actions(actions: Array) -> void:
	for action in actions:
		if _is_leaving or not is_inside_tree():
			return
		if action.has("delete"):
			_sandbox_service.delete_file(str(action["delete"]))
		elif action.has("write"):
			await _sandbox_service.write_file(str(action["write"]), str(action.get("content", "")))
			if _room != null:
				_room.remember_content(str(action["write"]), str(action.get("content", "")))
		elif action.has("run"):
			await _sandbox_service.execute(str(action["run"]))


func _check_room_defeat() -> void:
	if _room == null or not _room.is_failed() or _mission_panel == null:
		return
	_level_timer_active = false
	_terminal_panel.set_executing(true)
	_mission_panel.show_failed("พลังของนายหมดลง… หอคอยส่งนายกลับไปเริ่มชั้นนี้ใหม่")


## แพ้แล้วกดลองใหม่: สร้างพื้นที่ใหม่ ทำ setup ซ้ำ และเริ่มภารกิจกับห้องตั้งแต่ต้น
func _on_room_retry() -> void:
	if _mission == null:
		return
	_terminal_panel.clear_output()
	_terminal_panel.append_info("หอคอยสร้างชั้นนี้ขึ้นใหม่...")
	var result := await _sandbox_service.reset()
	if _is_leaving or not is_inside_tree():
		return
	if not result.ok:
		_terminal_panel.append_error("เริ่มใหม่ไม่สำเร็จ: " + result.message)
		return
	_mission = LevelMission.create(_mission.level_number, _mission.step)
	_mission_panel.setup(_mission)
	_update_mission_prompt()
	_setup_room()
	await _apply_mission_setup()
	await _start_room()
	_level_timer_active = _mission.time_limit > 0.0 and _level_time_remaining > 0.0
	_terminal_panel.set_executing(false)
	await _refresh_state()


## แผงภารกิจอยู่บนสุดของคอลัมน์ซ้าย ส่วนแผง Files อยู่ใต้ลงมา (ใช้พื้นที่เดิมของแผง Files)
## ซ่อนแผงที่ด่านนี้ยังไม่ถึงเนื้อหา เพื่อลดความสับสน (เช่น ด่าน 1 ใช้แค่ Terminal)
func _apply_contextual_panels() -> void:
	_files_panel.visible = _mission.shows_panel("files")
	_git_graph_panel.visible = _mission.shows_panel("graph")


func _dock_mission_panel_above_files() -> void:
	var column := VBoxContainer.new()
	column.name = "LeftColumn"
	column.layout_mode = 1
	column.anchor_left = _files_panel.anchor_left
	column.anchor_top = _files_panel.anchor_top
	column.anchor_right = _files_panel.anchor_right
	column.anchor_bottom = _files_panel.anchor_bottom
	column.add_theme_constant_override("separation", 8)
	var index := _files_panel.get_index()
	add_child(column)
	move_child(column, index)
	_files_panel.reparent(column, false)
	_files_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_mission_panel)
	column.move_child(_mission_panel, 0)


## ภารกิจปัจจุบันแสดงเป็นข้อความจางในช่องพิมพ์ของเทอร์มินัล (ครบแล้วไม่แสดง)
func _update_mission_prompt() -> void:
	_terminal_panel.set_input_placeholder(str(_mission.current_objective().get("text", "")))


func _on_mission_progress(command: String, result: GitCommandResult, snapshot: GitRepositorySnapshot = null) -> void:
	if _mission.is_complete():
		return
	var newly_done := _mission.on_command(command, result.success, result.standard_output, snapshot)
	_mission_panel.refresh()
	_update_mission_prompt()
	if _mission.is_complete():
		_level_timer_active = false
		_mission_panel.show_complete(_mission.success_text, _mission_continue_label())
		return
	for done_id in newly_done:
		_apply_world_actions(_mission.spawn_actions(done_id))
	if not newly_done.is_empty():
		_mistakes = 0
	elif not result.success or command.begins_with("say "):
		_mistakes += 1
	if not newly_done.is_empty():
		var world := _mission.world_text(newly_done[-1])
		_mission_panel.show_feedback(world if not world.is_empty() else "ถูกต้อง! ภารกิจสำเร็จ", false)
		return
	var mistake := _mission.mistake_message(command)
	if _mistakes >= MIURA_HINT_AFTER:
		_miura_hint("ดูเหมือนนายจะติดอยู่")
		return
	if not mistake.is_empty():
		_mission_panel.show_feedback(mistake, true)


func _mission_continue_label() -> String:
	return "ไปต่อ"


## ทำภารกิจครบ -> กลับหน้าบทสนทนาช่วงถัดไปของด่านเดิม (ขั้น 1 -> ช่วง 1, ขั้น 2 -> ช่วง 2)
func _on_mission_continue() -> void:
	if _is_leaving:
		return
	_is_leaving = true
	GameProgressManager.set_resume_dialogue_phase(LevelMission.resume_phase_after(_mission.step, _mission.total_steps))
	var tree := get_tree() if is_inside_tree() else null
	if SceneLoader.change_scene(tree, LEVEL_DIALOGUE_PATH):
		Engine.time_scale = 1.0
	else:
		_is_leaving = false
		GameProgressManager.set_resume_dialogue_phase(-1)


func _setup_leave_confirm_dialog() -> void:
	_leave_confirm_dialog = ConfirmationDialog.new()
	_leave_confirm_dialog.name = "LeaveConfirmDialog"
	_leave_confirm_dialog.title = "ออกจาก Sandbox"
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
		"%s?" % _return_label(),
		true
	)
	_leave_confirm_dialog.size = Vector2i(520, 100)
	_leave_confirm_dialog.confirmed.connect(_leave_sandbox)


func _on_brand_pressed() -> void:
	if _is_leaving:
		return
	var has_unsaved := _files_panel != null and _files_panel.has_unsaved_changes
	if _leave_confirm_dialog == null or _leave_confirm_message == null:
		_leave_sandbox()
		return
	if has_unsaved:
		_leave_confirm_message.text = "มีไฟล์ที่ยังไม่บันทึก\nต้องการออกจาก Sandbox %sหรือไม่?" % _return_label()
	else:
		_leave_confirm_message.text = "ต้องการออกจาก Sandbox %sหรือไม่?" % _return_label()
	_leave_confirm_dialog.popup_centered()


## ฉากที่ปุ่มออกจะพากลับไป: ตั้งผ่าน GameProgressManager ก่อนเปิด Sandbox (หน้าแรกตั้งเป็น START_VIEW_PATH) ค่าเริ่มต้นคือหน้าเลือกด่าน
static func _return_scene_path() -> String:
	var path := GameProgressManager.get_sandbox_return_scene()
	return LEVEL_SELECT_PATH if path.is_empty() else path


static func _return_label() -> String:
	return "กลับหน้าแรก" if _return_scene_path() == START_VIEW_PATH else "กลับหน้าเลือกด่าน"


func _leave_sandbox() -> void:
	if _is_leaving:
		return
	_is_leaving = true
	GameProgressManager.clear_level_timer()
	var tree := get_tree() if is_inside_tree() else null
	if SceneLoader.change_scene(tree, _return_scene_path()):
		Engine.time_scale = 1.0
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
		var remote_seed := LevelMission.build_remote_seed(_mission.remote) if _mission != null else null
		var started := await real_service.initialize("checkpoint-01", "", remote_seed)
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

	_top_bar.set_mode_text("ด่านที่ %d" % _mission.level_number if _mission != null else "SANDBOX")
	_top_bar.set_finish_button_text(_return_label())

	if _sandbox_service.info != null:
		_terminal_panel.set_window_title("●  ●  ●    TERMINAL — learner@diwaa:~/%s" % _sandbox_service.info.mission_id)
	await _apply_mission_setup()
	if _is_leaving or not is_inside_tree():
		return
	await _start_room()
	if _is_leaving or not is_inside_tree():
		return
	_show_new_spells()
	_terminal_panel.append_info("พร้อมใช้งาน — พิมพ์ help หรือเริ่มด้วย git --version\n")

	await _refresh_state()


## สร้าง "ปัญหาในโลก" ตั้งต้นของขั้นนี้ (ไฟล์บนโต๊ะ, การจารึกก่อนหน้า) แบบเงียบ ก่อนผู้เล่นเริ่ม
func _apply_mission_setup() -> void:
	if _mission == null or _mission.setup.is_empty():
		return
	for action in _mission.setup:
		if _is_leaving or not is_inside_tree():
			return
		if action.has("write"):
			var written := await _sandbox_service.write_file(str(action["write"]), str(action.get("content", "")))
			if not written.ok:
				push_error("mission setup write failed: %s" % written.message)
		elif action.has("run"):
			var result := await _sandbox_service.execute(str(action["run"]))
			if not result.success:
				push_error("mission setup '%s' failed: %s" % [action["run"], result.output])


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

	# Exit sandbox (same as the top-right button)
	if lower in ["exit", "quit"]:
		_leave_sandbox()
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

	if lower in ["spells", "spellbook", "สมุดคาถา"]:
		_open_spellbook()
		return

	if lower.begins_with("say "):
		await _handle_say_command(trimmed)
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
	var before := await _sandbox_service.inspect()
	if _is_leaving or not is_inside_tree():
		return
	var result := await _sandbox_service.execute(trimmed)

	if result.success:
		if not result.standard_output.strip_edges().is_empty():
			_terminal_panel.append_output(result.standard_output.strip_edges(false, true))
		else:
			_terminal_panel.append_info("✓ สำเร็จ")
	else:
		# บางคำสั่ง (เช่น merge ที่ปะทะ) เขียนข้อความจริงลง stdout — แสดงให้ผู้เล่นเห็นข้อความ Git จริงเสมอ
		if not result.standard_output.strip_edges().is_empty():
			_terminal_panel.append_output(result.standard_output.strip_edges(false, true))
		var error_message := result.standard_error.strip_edges(false, true) \
				if not result.standard_error.strip_edges().is_empty() \
				else "✗ คำสั่งล้มเหลว (exit %d)" % result.exit_code
		_terminal_panel.append_error(error_message)

	# ช่องพิมพ์ยังล็อกอยู่จนกว่าโลกจะเดินจังหวะนี้เสร็จ (คลื่น/ของที่ปรากฏ) — กันคำสั่งถัดไปแทรกกลางทาง
	var after := await _sandbox_service.inspect()
	if _is_leaving or not is_inside_tree():
		return
	_spell_overlay.play_all(SpellEffectDetector.detect(before, after, trimmed, result.success))
	if _mission != null:
		_on_mission_progress(trimmed, result, after)
	await _refresh_state()
	await _advance_room(trimmed)
	_unlock_terminal()


## เอ่ยคำในโลก (รหัสผนึก, อักขระกุญแจ) — เอ่ยผิดตอนที่ประตูรอคำตอบจะเสียพลัง
func _handle_say_command(command: String) -> void:
	var word := command.substr(4).strip_edges()
	_terminal_panel.append_info("เวล: \"%s\"" % word)
	if _mission == null:
		return
	var expected := _mission.expects_say()
	var snapshot := await _sandbox_service.inspect()
	var before := _mission.done_count()
	_on_mission_progress("say %s" % word, GitCommandResult.new(true, 0, "", ""), snapshot)
	if expected and _mission.done_count() == before and _room != null:
		var events := _room.on_wrong_say()
		_room_view.play_events(events)
		for event in events:
			_terminal_panel.append_info("✦ " + str(event["text"]))
		await _update_room_view()
		_check_room_defeat()
		return
	await _advance_room("say")


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
	await _advance_room("write")


func _handle_cat_command(command: String) -> void:
	var parts := TerminalApp.split_command(command, 2)
	var files := await _workspace_paths()
	if parts.size() < 2:
		_terminal_panel.append_error("พิมพ์ cat เว้นวรรค แล้วตามด้วยชื่อไฟล์ เช่น cat %s" % (files[0] if not files.is_empty() else "note.txt"))
		return

	var path := _resolve_scroll_name(parts[1], files)
	var result := _sandbox_service.read_file(path)
	if not result.ok:
		_terminal_panel.append_error("อ่านไฟล์ไม่สำเร็จ: " + result.message)
	elif result.value == null:
		var listing := ", ".join(PackedStringArray(files)) if not files.is_empty() else "(ว่างเปล่า)"
		_terminal_panel.append_error("ไม่พบไฟล์ '%s' — ในห้องนี้มี: %s" % [parts[1], listing])
		_terminal_panel.append_info("พิมพ์ชื่อให้ตรงทั้งหมด (รวม .txt) หรือคลิกกระดาษในห้องเพื่ออ่าน")
	else:
		_terminal_panel.append_output(result.value)
		_terminal_panel.set_executing(true)
		await _report_scroll_read(path)
		_unlock_terminal()


## ช่วยผู้เล่นที่พิมพ์ชื่อไม่ครบ: ตัด <> และเครื่องหมายคำพูด, เติม .txt ให้ถ้ามีไฟล์ชื่อนั้นอยู่จริง
static func _resolve_scroll_name(typed: String, files: Array[String]) -> String:
	var name := typed.strip_edges().trim_prefix("<").trim_suffix(">").trim_prefix("\"").trim_suffix("\"")
	if files.has(name):
		return name
	for extension in [".txt", ".md"]:
		if files.has(name + extension):
			return name + extension
	return name


## การอ่านเศษคัมภีร์ (cat หรือเปิดในแผง Files) นับเป็นการสังเกตโลกสำหรับภารกิจชนิด read
## ปลดล็อกช่องพิมพ์ — ยกเว้นตอนแพ้ (ต้องกดลองใหม่ก่อน)
func _unlock_terminal() -> void:
	if _room != null and _room.is_failed():
		return
	_terminal_panel.set_executing(false)


func _report_scroll_read(path: String) -> void:
	if _mission == null or _is_leaving:
		return
	var snapshot := await _sandbox_service.inspect()
	if _is_leaving or not is_inside_tree():
		return
	_on_mission_progress("cat %s" % path, GitCommandResult.new(true, 0, "", ""), snapshot)
	if _room != null:
		var read := _sandbox_service.read_file(path)
		if read.ok and read.value != null:
			_room.remember_content(path, str(read.value))
	await _advance_room("cat %s" % path)


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
		_report_scroll_read(file_path)
	_files_panel.set_busy(false)


func _on_save_file_requested(file_path: String, content: String) -> void:
	_files_panel.set_busy(true)
	var result := await _sandbox_service.write_file(file_path, content)
	if result.ok:
		_files_panel.mark_saved(file_path)
		_files_panel.show_feedback("บันทึก %s แล้ว — Git status อัปเดตแล้ว" % file_path)
		_terminal_panel.append_info("✓ บันทึกไฟล์ '%s' แล้ว" % file_path)
		await _refresh_state()
		await _advance_room("save")
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
	await _relocate_entry(source_path, destination_path, "เปลี่ยนชื่อ",
			"เปลี่ยนชื่อเป็น %s แล้ว" % destination_path)


func _on_move_entry_requested(source_path: String, destination_path: String) -> void:
	var folder := destination_path.get_base_dir()
	var folder_label := "WORKSPACE" if folder.is_empty() else folder
	await _relocate_entry(source_path, destination_path, "ย้าย",
			"ย้าย %s ไปที่ %s แล้ว" % [source_path.get_file(), folder_label])


## เปลี่ยนชื่อ/ย้ายไฟล์หรือโฟลเดอร์ (ใช้ rename_entry ของ service เหมือนกัน ต่างกันแค่ข้อความ)
func _relocate_entry(source_path: String, destination_path: String, verb: String, success_feedback: String) -> void:
	_files_panel.set_busy(true)
	var result := _sandbox_service.rename_entry(source_path, destination_path)
	if result.ok:
		_files_panel.notify_entry_renamed(source_path, destination_path)
		_files_panel.show_feedback(success_feedback)
		_terminal_panel.append_info("✓ %s '%s' → '%s'" % [verb, source_path, destination_path])
		await _refresh_state()
	else:
		_files_panel.show_feedback("%sไม่สำเร็จ: %s" % [verb, result.message], true)
		_terminal_panel.append_error("%sไม่สำเร็จ: %s" % [verb, result.message])
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
                  sandbox-reset, cutscene <central|ending>, level 16, exit, clear, help""")


func _exit_tree() -> void:
	# ออกจาก Sandbox ทางใดก็ตาม (เช่น คำสั่ง cutscene / level 16) ให้รอบถัดไปกลับหน้าเลือกด่านตามค่าเริ่มต้น
	GameProgressManager.set_sandbox_return_scene("")
	if _sandbox_service != null:
		_sandbox_service.dispose()
