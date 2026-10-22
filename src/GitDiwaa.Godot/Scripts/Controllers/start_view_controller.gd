class_name StartViewController
extends Control
## Controller for the Start Screen View.
## Orchestrates start screen navigation, audio effects, live terminal simulation,
## real-time system clock, and transition to Sandbox gameplay.

const PREVIEW_FPS := 6.67

var _start_career_btn: Button
var _resume_work_btn: Button
var _dressing_room_btn: Button
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

var _cursor_blink_timer := 0.0
var _clock_update_timer := 0.0
var _preview_anim_timer := 0.0
var _preview_frame_index := 0
var _cursor_visible := true


func _ready() -> void:
	_bind_nodes()
	_wire_events()
	_update_clock()
	_load_preview_animation()
	_start_career_btn.grab_focus()


func _bind_nodes() -> void:
	_start_career_btn = get_node("%StartCareerBtn")
	_resume_work_btn = get_node("%ResumeWorkBtn")
	_dressing_room_btn = get_node("%DressingRoomBtn")
	_tutorial_btn = get_node("%TutorialBtn")
	_clock_label = get_node("%ClockLabel")
	_output_log = get_node("%OutputLog")
	_command_input = get_node("%CommandInput")
	_cursor_block = get_node("%CursorBlock")
	_bgm_audio = get_node("%BgmAudio")
	_sfx_click = get_node("%SfxClick")
	_sfx_command = get_node("%SfxCommand")
	_scene_preview_rect = get_node("%ScenePreviewRect")


func _wire_events() -> void:
	_start_career_btn.pressed.connect(_on_start_career_pressed)
	_resume_work_btn.pressed.connect(_on_resume_work_pressed)
	_dressing_room_btn.pressed.connect(_on_dressing_room_pressed)
	_tutorial_btn.pressed.connect(_on_tutorial_pressed)

	_start_career_btn.focus_entered.connect(_on_button_focus_entered)
	_resume_work_btn.focus_entered.connect(_on_button_focus_entered)
	_dressing_room_btn.focus_entered.connect(_on_button_focus_entered)
	_tutorial_btn.focus_entered.connect(_on_button_focus_entered)

	_command_input.text_submitted.connect(_on_terminal_command_submitted)


func _load_preview_animation() -> void:
	var frames_resource: SpriteFrames = null
	if ResourceLoader.exists("res://Scenes/tower_preview_frames.tres"):
		frames_resource = load("res://Scenes/tower_preview_frames.tres")
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
	_play_sfx(_sfx_click)
	_append_terminal_text("> Executing START NEW CAREER...")
	_append_terminal_text("> Initializing Magic Tower apprentice session...")

	# Delay slightly for audio feedback before switching scene
	get_tree().create_timer(0.35).timeout.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/cutscene/cut_scence_normal.tscn"))


func _on_resume_work_pressed() -> void:
	_play_sfx(_sfx_click)
	_append_terminal_text("> Resuming active repository session...")

	get_tree().create_timer(0.35).timeout.connect(func() -> void:
		get_tree().change_scene_to_file("res://Scenes/SandboxGameView.tscn"))


func _on_dressing_room_pressed() -> void:
	_play_sfx(_sfx_click)
	_append_terminal_text("> Accessing Royal Wardrobe & Dressing Room...")

	get_tree().create_timer(0.35).timeout.connect(func() -> void:
		if ResourceLoader.exists("res://Scenes/DressingRoomView.tscn"):
			get_tree().change_scene_to_file("res://Scenes/DressingRoomView.tscn")
		else:
			_append_terminal_text("> Wardrobe module initialized."))


func _on_tutorial_pressed() -> void:
	_play_sfx(_sfx_click)
	_append_terminal_text("\n--- [ TUTORIAL & DOCUMENTATION ] ---")
	_append_terminal_text("ยินดีต้อนรับสู่ Git-Diwaa! คุณจะได้เรียนรู้ Git ผ่านโลกเวทมนตร์")
	_append_terminal_text("คำสั่งพื้นฐาน: git init, git status, git add ., git commit -m \"...\"")
	_append_terminal_text("กด [START NEW CAREER] เพื่อเข้าสู่ด่านหอคอยเวทมนตร์!\n")


func _on_terminal_command_submitted(input: String) -> void:
	var cmd := input.strip_edges()
	if cmd.is_empty():
		return

	_play_sfx(_sfx_command)
	_command_input.clear()
	_append_terminal_text("> " + cmd)

	var lower := cmd.to_lower()
	if lower == "clear" or lower == "cls":
		_output_log.text = ""
		return

	if lower == "start" or lower == "play" or lower == "run":
		_on_start_career_pressed()
		return

	if lower == "dressing" or lower == "dress" or lower == "wardrobe":
		_on_dressing_room_pressed()
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
		_append_terminal_text("Commands: git init, git status, git add, git commit, git branch, start, wardrobe, clear, help")
	else:
		_append_terminal_text("git: '%s' executed in sandbox preview." % cmd)


func _append_terminal_text(text: String) -> void:
	if _output_log.text.is_empty():
		_output_log.text = text
	else:
		_output_log.text += "\n" + text


func _play_sfx(player: AudioStreamPlayer) -> void:
	if player != null and player.stream != null:
		player.play()
