class_name StartViewController
extends Control

## Controller for the Start Screen View.
## Orchestrates start screen navigation, audio effects, live terminal simulation,
## real-time system clock, and transitions to level select or the free-play Git sandbox.

const PREVIEW_FPS := 6.67
const THAI_LOG_FONT_SIZE := 22
const LEVEL_SELECT_PATH := "res://features/level_select/level_select_view.tscn"
const SANDBOX_PATH := "res://features/sandbox/sandbox_game_view.tscn"
const START_VIEW_PATH := "res://features/start/start_view.tscn"

var _start_career_btn: Button
var _resume_work_btn: Button
var _sandbox_btn: Button
var _dressing_room_btn: Button
var _quit_game_btn: Button
var _tutorial_btn: Button
var _clock_label: Label
var _output_log: RichTextLabel
var _command_input: LineEdit
var _cursor_block: Label
var _bgm_audio: AudioStreamPlayer
var _sfx_click: AudioStreamPlayer
var _sfx_command: AudioStreamPlayer
var _scene_preview_rect: TextureRect
var _preview_frames: Array[Texture2D] = []
var _thai_log_font: Font

var _cursor_blink_timer := 0.0
var _clock_update_timer := 0.0
var _preview_anim_timer := 0.0
var _preview_frame_index := 0
var _cursor_visible := true
var _is_leaving := false
var _quit_popup_open := false


func _ready() -> void:
	_thai_log_font = SandboxThemeTokens.create_terminal_thai_font()
	_bind_nodes()
	_wire_events()
	_setup_inline_icons()
	_update_clock()
	_load_preview_animation()
	_start_career_btn.grab_focus()

	SceneLoader.request_preload(SANDBOX_PATH)


func _bind_nodes() -> void:
	_start_career_btn = get_node("%StartCareerBtn")
	_resume_work_btn = get_node("%ResumeWorkBtn")
	_sandbox_btn = get_node("%SandboxBtn")
	_dressing_room_btn = get_node("%DressingRoomBtn")
	_quit_game_btn = get_node("%QuitGameBtn")
	# เว็บเอ็กซ์พอร์ตสั่ง quit() ไม่ได้ จึงซ่อนปุ่มไว้
	_quit_game_btn.visible = not OS.has_feature("web")
	_tutorial_btn = get_node("%TutorialBtn")
	_clock_label = get_node("%ClockLabel")
	_output_log = get_node("%OutputLog")
	_command_input = get_node("%CommandInput")
	_cursor_block = get_node("%CursorBlock")
	_bgm_audio = get_node("%BgmAudio")
	_sfx_click = get_node("%SfxClick")
	_sfx_command = get_node("%SfxCommand")
	_scene_preview_rect = get_node("%ScenePreviewRect")


## วางไอคอน SVG ของปุ่มเมนูให้ติดกับข้อความตรงกลางปุ่ม (ตำแหน่งเดียวกับ emoji เดิม) แทนการชิดขอบปุ่ม
func _setup_inline_icons() -> void:
	for button: Button in [_resume_work_btn, _sandbox_btn, _dressing_room_btn, _quit_game_btn, _tutorial_btn]:
		button.resized.connect(_center_icon_with_text.bind(button))
		_center_icon_with_text.call_deferred(button)


## ตั้งระยะขอบซ้าย-ขวาเท่ากันให้พื้นที่เนื้อหาพอดีกับ ข้อความ + ช่องว่าง + ไอคอน จึงอยู่ติดกันกลางปุ่ม
func _center_icon_with_text(button: Button) -> void:
	if button.icon == null or button.size.x <= 0.0:
		return
	var font := button.get_theme_font("font")
	var font_size := button.get_theme_font_size("font_size")
	var text_width := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var icon_width := float(button.get_theme_constant("icon_max_width"))
	if icon_width <= 0.0:
		icon_width = float(button.icon.get_width())
	var group_width := ceilf(text_width) + float(button.get_theme_constant("h_separation")) + icon_width
	var side_margin := floorf(maxf((button.size.x - group_width) * 0.5, 0.0))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := button.get_theme_stylebox(state)
		if style == null or (is_equal_approx(style.content_margin_left, side_margin) and is_equal_approx(style.content_margin_right, side_margin)):
			continue
		style = style.duplicate() as StyleBox
		style.content_margin_left = side_margin
		style.content_margin_right = side_margin
		button.add_theme_stylebox_override(state, style)


func _wire_events() -> void:
	_start_career_btn.pressed.connect(_on_start_career_pressed)
	_resume_work_btn.pressed.connect(_on_resume_work_pressed)
	_sandbox_btn.pressed.connect(_on_sandbox_pressed)
	_dressing_room_btn.pressed.connect(_on_dressing_room_pressed)
	_quit_game_btn.pressed.connect(_on_quit_game_pressed)
	_tutorial_btn.pressed.connect(_on_tutorial_pressed)

	_start_career_btn.focus_entered.connect(_on_button_focus_entered)
	_resume_work_btn.focus_entered.connect(_on_button_focus_entered)
	_sandbox_btn.focus_entered.connect(_on_button_focus_entered)
	_dressing_room_btn.focus_entered.connect(_on_button_focus_entered)
	_quit_game_btn.focus_entered.connect(_on_button_focus_entered)
	_tutorial_btn.focus_entered.connect(_on_button_focus_entered)

	_command_input.text_submitted.connect(_on_terminal_command_submitted)


func _load_preview_animation() -> void:
	var frames_resource: SpriteFrames = null
	if ResourceLoader.exists("res://features/start/tower_preview_frames.tres"):
		frames_resource = load("res://features/start/tower_preview_frames.tres")
	elif ResourceLoader.exists("res://assets/art/start_screen/tower_preview_frames.tres"):
		frames_resource = load("res://assets/art/start_screen/tower_preview_frames.tres")

	if frames_resource != null and frames_resource.has_animation("default"):
		for i in frames_resource.get_frame_count("default"):
			_preview_frames.append(frames_resource.get_frame_texture("default", i))


func _process(delta: float) -> void:
	# Blinking cursor
	_cursor_blink_timer += delta
	if _cursor_blink_timer >= 0.5:
		_cursor_blink_timer = 0.0
		_cursor_visible = not _cursor_visible
		_cursor_block.visible = _cursor_visible

	# Live clock
	_clock_update_timer += delta
	if _clock_update_timer >= 1.0:
		_clock_update_timer = 0.0
		_update_clock()

	# Tower preview animation (6.67 FPS, 0-65 looping)
	if not _preview_frames.is_empty() and _scene_preview_rect != null:
		_preview_anim_timer += delta
		if _preview_anim_timer >= 1.0 / PREVIEW_FPS:
			_preview_anim_timer -= 1.0 / PREVIEW_FPS
			_preview_frame_index = (_preview_frame_index + 1) % _preview_frames.size()
			_scene_preview_rect.texture = _preview_frames[_preview_frame_index]


func _update_clock() -> void:
	_clock_label.text = "MT: " + Time.get_time_string_from_system()


func _on_button_focus_entered() -> void:
	_play_sfx(_sfx_click)


func _on_start_career_pressed() -> void:
	if _is_leaving:
		return
	_is_leaving = true
	_play_sfx(_sfx_click)
	_append_terminal_text("> Executing START NEW CAREER...")

	if GameProgressManager.has_seen_intro_cutscene():
		_append_terminal_text("> Opening Tower Ascension Roadmap...")
		get_tree().create_timer(0.35).timeout.connect(func() -> void:
			if not is_inside_tree():
				return
			_transition_to_scene(LEVEL_SELECT_PATH))
	else:
		_append_terminal_text("> Initializing Magic Tower apprentice session...")
		get_tree().create_timer(0.35).timeout.connect(func() -> void:
			if not is_inside_tree():
				return
			var prev_selected := GameProgressManager.get_selected_level_number()
			GameProgressManager.set_selected_level_number(1)
			if not _transition_to_scene("res://features/cutscene/cut_scence_normal.tscn"):
				GameProgressManager.set_selected_level_number(prev_selected))


## เล่นต่อจากที่ค้างไว้: ไปหน้าเลือกด่าน
func _on_resume_work_pressed() -> void:
	if _is_leaving:
		return
	_is_leaving = true
	_play_sfx(_sfx_click)
	_append_terminal_text("> Opening Tower Ascension Roadmap...")

	get_tree().create_timer(0.2).timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		_transition_to_scene(LEVEL_SELECT_PATH))


## เข้าห้องทดลองคำสั่ง git แบบอิสระ ปุ่มออกใน Sandbox จะพากลับหน้าแรก
func _on_sandbox_pressed() -> void:
	if _is_leaving:
		return
	_is_leaving = true
	_play_sfx(_sfx_click)
	_append_terminal_text("> Opening free-play Git sandbox...")

	get_tree().create_timer(0.2).timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		GameProgressManager.set_sandbox_return_scene(START_VIEW_PATH)
		if not _transition_to_scene(SANDBOX_PATH):
			GameProgressManager.set_sandbox_return_scene(""))


func _transition_to_scene(target_path: String) -> bool:
	var tree := get_tree() if is_inside_tree() else null
	if not SceneLoader.change_scene(tree, target_path):
		_is_leaving = false
		push_warning("[StartView] Scene not found: '%s'" % target_path)
		return false
	return true


func _on_dressing_room_pressed() -> void:
	if _is_leaving:
		return
	_is_leaving = true
	_play_sfx(_sfx_click)
	_append_terminal_text("> Accessing Royal Wardrobe & Dressing Room...")

	get_tree().create_timer(0.35).timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		if ResourceLoader.exists("res://features/start/dressing_room_view.tscn"):
			_transition_to_scene("res://features/start/dressing_room_view.tscn")
		else:
			_is_leaving = false
			_append_terminal_text("> Wardrobe module initialized."))


## กดปุ่มออกจากเกม → ถามยืนยันก่อน เพื่อกันการกดพลาดจากคีย์บอร์ด/จอยที่โฟกัสวนมาถึงปุ่มนี้
func _on_quit_game_pressed() -> void:
	if _is_leaving or _quit_popup_open:
		return
	_play_sfx(_sfx_click)
	var popup := MessagePopup.open_confirm(self, "ออกจากเกม", "ต้องการออกจากเกมหรือไม่?", "ออกจากเกม", "ยกเลิก", true)
	if popup == null:
		return
	_quit_popup_open = true
	var confirmed: bool = await popup.closed
	_quit_popup_open = false
	if confirmed and is_inside_tree() and not _is_leaving:
		_confirm_quit_game()


func _confirm_quit_game() -> void:
	_is_leaving = true
	_append_terminal_text("> Terminating DevLab Studio session... Good bye!")
	get_tree().create_timer(0.25).timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		get_tree().quit())


func _on_tutorial_pressed() -> void:
	if _is_leaving:
		return
	_play_sfx(_sfx_click)
	_append_terminal_text("\n--- [ TUTORIAL & DOCUMENTATION ] ---")
	_append_terminal_text("ยินดีต้อนรับสู่ Git-Diwaa! คุณจะได้เรียนรู้ Git ผ่านโลกเวทมนตร์")
	_append_terminal_text("คำสั่งพื้นฐาน: git init, git status, git add ., git commit -m \"...\"")
	_append_terminal_text("กด [START NEW CAREER] เพื่อเข้าสู่ด่านหอคอยเวทมนตร์!\n")


func _on_terminal_command_submitted(input: String) -> void:
	if _is_leaving:
		return
	var cmd := input.strip_edges()
	if cmd.is_empty():
		return

	_play_sfx(_sfx_command)
	_command_input.clear()
	_append_terminal_text("> " + cmd)

	var lower := cmd.to_lower()
	if lower == "clear" or lower == "cls":
		_output_log.clear()
		return

	if lower == "exit" or lower == "quit":
		_on_quit_game_pressed()
		return

	if lower == "start" or lower == "play" or lower == "run":
		_on_start_career_pressed()
		return

	if lower == "dressing" or lower == "dress" or lower == "wardrobe":
		_on_dressing_room_pressed()
		return

	if lower == "level" or lower == "levels" or lower == "select":
		_is_leaving = true
		_transition_to_scene(LEVEL_SELECT_PATH)
		return

	if lower == "sandbox":
		_on_sandbox_pressed()
		return

	if lower == "clear 1" or lower == "complete 1":
		if OS.is_debug_build():
			GameProgressManager.set_level_cleared(1, true)
			_append_terminal_text("> [DEBUG] Level 1 marked as CLEARED! Card in Level Select will turn GREEN.")
		else:
			_append_terminal_text("Command only available in debug builds.")
		return

	if lower == "reset" or lower == "reset progress":
		if OS.is_debug_build():
			GameProgressManager.reset_progress()
			_append_terminal_text("> [DEBUG] Game progress reset! All cards in Level Select are now GREY.")
		else:
			_append_terminal_text("Command only available in debug builds.")
		return

	if lower == "git init":
		_append_terminal_text("Initialized empty Git repository in /magictower/spells/.git/")
	elif lower == "git status":
		_append_terminal_text("On branch main\nNo commits yet\nUntracked files: new_spell.magic")
	elif lower == "git add ." or lower == "git add new_spell.magic":
		_append_terminal_text("Changes to be committed: new_spell.magic")
	elif lower.begins_with("git commit"):
		_append_terminal_text("[main (root-commit) 8f3a1b2] Recorded spell in ancient repository")
	elif lower == "git branch":
		_append_terminal_text("* main\n  fireball")
	elif lower == "help":
		_append_terminal_text("Commands: git init, git status, git add, git commit, git branch, start, sandbox, wardrobe, clear, help")
	else:
		_append_terminal_text("git: '%s' executed in sandbox preview." % cmd)


func _append_terminal_text(text: String) -> void:
	if text.is_empty():
		return
	if _output_log.get_total_character_count() > 0:
		_output_log.add_text("\n")
	SandboxThemeTokens.append_terminal_styled_text(_output_log, text, _thai_log_font, THAI_LOG_FONT_SIZE)


func _play_sfx(player: AudioStreamPlayer) -> void:
	if player != null and player.stream != null:
		player.play()
