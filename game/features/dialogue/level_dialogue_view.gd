extends Node2D

## ตัวควบคุมและแสดงผลบทสนทนาประจำด่าน (Level Dialogue View)
## รองรับบทสนทนา ด่าน 1 ถึง ด่าน 15 แบบแยกไฟล์ข้อมูล (Data-driven)
##
## วิธีใช้งาน:
## - กำหนด @export var level_number: int เพื่อเลือกด่านที่ต้องการเล่น (ค่าเริ่มต้น: 1)
## - สคริปต์จะโหลดข้อมูลจาก res://features/dialogue/levels/level_%02d.gd มาแสดงผลอัตโนมัติ
## - รองรับ Typewriter Effect, BBCode ไฮไลต์โค้ดสไตล์ Markdown, ช้อยส์ในกล่องข้อความเดิม,
##   ระบบฝึกร่ายคาถาจำลอง (Terminal Practice) และ คัตซีนเดินขึ้นบันไดผ่านด่าน (Stairs Outro)

@export var level_number: int = 1
@export var next_scene_path: String = "res://features/sandbox/sandbox_game_view.tscn"
@export_enum("Intro & Part 1", "Part 2", "Outro") var debug_phase: int = 0

# Animation & Visuals
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera2D = $Camera2D
@onready var background: Sprite2D = $Background
@onready var atmosphere: ColorRect = $Atmosphere
@onready var fade_overlay: ColorRect = $MagicStoryUI/FadeOverlay

# Characters
@onready var stage: Node2D = $Stage
@onready var vel: AnimatedSprite2D = $Stage/Vel
@onready var exclamation_mark: Node2D = $Stage/Vel/ExclamationMark
@onready var question_mark: Node2D = $Stage/Vel/QuestionMark
@onready var mewla: AnimatedSprite2D = $Stage/Mewla

# UI Elements
@onready var magic_ui: CanvasLayer = $MagicStoryUI
@onready var dialogue_box: PanelContainer = $MagicStoryUI/DialogueBox
@onready var speaker_label: Label = $MagicStoryUI/DialogueBox/Margin/VBox/SpeakerLabel
@onready var dialogue_label: RichTextLabel = $MagicStoryUI/DialogueBox/Margin/VBox/DialogueLabel
@onready var continue_arrow: TextureRect = $MagicStoryUI/DialogueBox/ArrowOverlay/ArrowWrapper/ContinueArrow
@onready var arrow_wrapper: Control = $MagicStoryUI/DialogueBox/ArrowOverlay/ArrowWrapper

# Choice System Elements
var choice_container: VBoxContainer = null
var choice_buttons: Array[Button] = []
var active_choices: Array = []
var is_showing_choices: bool = false
var bad_ending_panel: Control = null

# Terminal Simulation Box
var terminal_panel: PanelContainer = null
var terminal_text_label: RichTextLabel = null

# Data & Queue
var level_data: Dictionary = {}
var current_queue: Array = []
var queue_index: int = 0

var is_dialogue_active: bool = false
var is_typing: bool = false
var is_transitioning: bool = false
var is_fast_forwarding: bool = false
var is_terminal_practicing: bool = false
var skip_ctrl = null
var font_ta8bit: Font = null

# Animation Sequence
const VEL_IDLE_SEQ: Array[String] = ["breathe", "breathe_blink", "breathe", "breathe", "breathe_blink"]
var vel_seq_step: int = 0

var typewriter_tween: Tween = null
var question_tween: Tween = null
var exclamation_tween: Tween = null
var arrow_tween: Tween = null

func _ready() -> void:
	if ResourceLoader.exists("res://assets/fonts/TA-8-bit.ttf"):
		font_ta8bit = load("res://assets/fonts/TA-8-bit.ttf")
		
	# ตั้งค่าหน้าจอเริ่มต้น
	fade_overlay.visible = true
	fade_overlay.color = Color(0, 0, 0, 1)
	dialogue_box.visible = false
	continue_arrow.visible = false
	exclamation_mark.visible = false
	question_mark.visible = false
	
	# สร้าง Choice Container ภายในกล่องข้อความเดิม (DialogueBox) ใต้ SpeakerLabel
	var vbox = dialogue_box.get_node_or_null("Margin/VBox")
	if vbox:
		choice_container = VBoxContainer.new()
		choice_container.visible = false
		choice_container.add_theme_constant_override("separation", 6)
		vbox.add_child(choice_container)
		
	# วางตำแหน่งตัวละครในท่ายืนพร้อมคุยทันที (พิกัดตามมาตรฐานใน md)
	camera.position = Vector2(960, 540)
	vel.position = Vector2(700, 680)
	vel.scale = Vector2(4, 4)
	vel.play("breathe")
	vel.animation_looped.connect(_on_vel_animation_looped)
	
	mewla.visible = true
	mewla.position = Vector2(1220, 680)
	mewla.scale = Vector2(4, 4)
	mewla.modulate = Color.WHITE
	mewla.play("idle")
	
	if anim_player.has_animation("background_loop"):
		anim_player.play("background_loop")
		
	# ปุ่มเร่งความเร็ว และปุ่มข้าม
	skip_ctrl = preload("res://features/cutscene/skip_cutscene_button.gd").new()
	skip_ctrl.next_scene_path = next_scene_path
	add_child(skip_ctrl)
	
	# โหลดข้อมูลด่าน
	_load_level_data(level_number)
	
	# เริ่มเปิดฉาก
	_start_dialogue_scene()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _process(_delta: float) -> void:
	if is_transitioning or is_terminal_practicing:
		if is_fast_forwarding:
			is_fast_forwarding = false
			Engine.time_scale = 1.0
		return
	
	var is_btn_active: bool = (skip_ctrl != null and skip_ctrl.is_fast_forward)
	var wants_hold: bool = Input.is_key_pressed(KEY_SHIFT) or \
		(not is_dialogue_active and (Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER)))
	
	var active: bool = is_btn_active or wants_hold
	if active != is_fast_forwarding:
		is_fast_forwarding = active
		Engine.time_scale = 2.5 if active else 1.0
		if skip_ctrl and not is_btn_active:
			skip_ctrl._apply_ff_style(active)

func _input(event: InputEvent) -> void:
	if is_transitioning or is_terminal_practicing:
		return
		
	# การเลือกช้อยส์ด้วยแป้นตัวเลข 1, 2, 3, 4
	if is_showing_choices:
		if event is InputEventKey and event.pressed and not event.echo:
			var idx := -1
			if event.keycode == KEY_1 or event.keycode == KEY_KP_1:
				idx = 0
			elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
				idx = 1
			elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
				idx = 2
			elif event.keycode == KEY_4 or event.keycode == KEY_KP_4:
				idx = 3
				
			if idx >= 0 and idx < active_choices.size():
				get_viewport().set_input_as_handled()
				_on_choice_selected(idx)
				return
		return
		
	# คลิกหรือกด Space/Enter เพื่อไปต่อ
	if is_dialogue_active:
		var wants_advance: bool = false
		if event.is_action_pressed("ui_accept"):
			wants_advance = true
		elif event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			wants_advance = true
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var hovered := get_viewport().gui_get_hovered_control()
			if not (hovered is BaseButton):
				wants_advance = true
				
		if wants_advance:
			get_viewport().set_input_as_handled()
			_on_player_advance()

# ==============================================================================
# DATA LOADER & BBCODE FORMATTER
# ==============================================================================

func _load_level_data(num: int) -> void:
	var path = "res://features/dialogue/levels/level_%02d.gd" % num
	if ResourceLoader.exists(path):
		var script = load(path)
		if script and script.has_method("get_data"):
			level_data = script.get_data()
			return
			
	push_warning("[LevelDialogueView] Data file not found for level %d at %s. Using fallback." % [num, path])
	level_data = {
		"title": "ด่านที่ %d" % num,
		"intro_sequence": [
			{"speaker": "มิวรา", "text": "ยินดีต้อนรับสู่ด่านที่ %d" % num, "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "มาเริ่มกันเลย!", "mewla_anim": "idle"}
		]
	}

func _highlight_code_syntax(code: String) -> String:
	var parts := code.split(" ")
	var styled_parts: Array[String] = []
	for p in parts:
		if p in ["git", "config"]:
			styled_parts.append("[color=#70d6ff]%s[/color]" % p) # Sky Cyan คีย์เวิร์ด
		elif p.begins_with("-"):
			styled_parts.append("[color=#5fffe0]%s[/color]" % p) # Neon Pastel Mint อักขระ/แฟล็ก
		elif p.begins_with("\"") or p.ends_with("\""):
			styled_parts.append("[color=#ffd166]%s[/color]" % p) # Soft Gold ข้อความสตริง
		else:
			styled_parts.append("[color=#f8fafc]%s[/color]" % p) # Bright White ตัวระบุชื่อ
	return " ".join(styled_parts)

func _format_bbcode(raw: String) -> String:
	var result := raw
	# แปลง Markdown `code` เป็นโค้ดสไตล์บล็อกโปรแกรมมิ่ง (High-Contrast Neon Mint / Sky Cyan Badge)
	var regex := RegEx.new()
	if regex.compile("`([^`]+)`") == OK:
		var matches := regex.search_all(result)
		for i in range(matches.size() - 1, -1, -1):
			var m = matches[i]
			var inner = m.get_string(1)
			var highlighted = _highlight_code_syntax(inner)
			var replacement = "[bgcolor=#14192b] %s [/bgcolor]" % highlighted
			result = result.left(m.get_start()) + replacement + result.substr(m.get_end())
	return result

func _start_dialogue_scene() -> void:
	var fade_in = create_tween()
	fade_in.tween_property(fade_overlay, "color:a", 0.0, 0.5)
	fade_in.tween_callback(func():
		_open_dialogue_box()
		if debug_phase == 1:
			_load_sequence(level_data.get("part2_intro_sequence", []))
		elif debug_phase == 2:
			_load_sequence(level_data.get("outro_sequence", []))
		else:
			_load_sequence(level_data.get("intro_sequence", []))
	)

func _open_dialogue_box() -> void:
	if is_transitioning:
		return
	dialogue_box.visible = true
	dialogue_box.modulate.a = 0.0
	var box_tween = create_tween()
	box_tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.25)

func _load_sequence(seq: Array) -> void:
	current_queue = seq
	queue_index = 0
	_show_current_queue_item()

func _show_current_queue_item() -> void:
	if queue_index >= current_queue.size():
		_finish_dialogue_stage()
		return
		
	var item = current_queue[queue_index]
	if item.has("type"):
		var type = item["type"]
		if type == "choice_menu":
			_display_choice_menu(item["menu"])
			return
		elif type == "terminal_practice":
			_trigger_terminal_practice(item)
			return
		elif type == "outro_stairs":
			_trigger_outro_stairs_walk()
			return
		elif type == "bad_ending":
			_trigger_bad_ending()
			return
			
	_show_single_dialogue(item)

func _show_single_dialogue(data: Dictionary) -> void:
	is_showing_choices = false
	if choice_container:
		choice_container.visible = false
	dialogue_label.visible = true
	is_dialogue_active = true
	is_typing = true
	_hide_continue_arrow()
	
	speaker_label.text = data["speaker"]
	dialogue_label.text = _format_bbcode(data["text"])
	dialogue_label.visible_ratio = 0.0
	
	# สีชื่อผู้พูด
	var target_mewla_anim = data.get("mewla_anim", "talk")
	if data["speaker"] == "มิวรา":
		speaker_label.add_theme_color_override("font_color", Color(0.941, 0.824, 0.451, 1.0))
		if mewla.animation != target_mewla_anim:
			mewla.play(target_mewla_anim)
			mewla.set_frame_and_progress(vel.frame, vel.frame_progress)
	else:
		speaker_label.add_theme_color_override("font_color", Color(0.48, 0.78, 1.0, 1.0))
		if mewla.animation != "idle":
			mewla.play("idle")
			mewla.set_frame_and_progress(vel.frame, vel.frame_progress)
		
	if vel.animation not in VEL_IDLE_SEQ:
		vel.play(VEL_IDLE_SEQ[vel_seq_step])
		vel.set_frame_and_progress(mewla.frame, mewla.frame_progress)
		
	var emote = data.get("emote", "")
	if emote == "question":
		_pop_question_mark()
	else:
		_hide_question_mark()
		
	var sfx_path = data.get("sfx", "")
	if sfx_path != "" and ResourceLoader.exists(sfx_path):
		var sfx = AudioStreamPlayer.new()
		sfx.stream = load(sfx_path)
		sfx.finished.connect(sfx.queue_free)
		add_child(sfx)
		sfx.play()
		
	if typewriter_tween and typewriter_tween.is_valid():
		typewriter_tween.kill()
		
	var duration: float = clampf(float(data["text"].length()) * 0.035, 0.4, 1.6)
	typewriter_tween = create_tween()
	typewriter_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)
	typewriter_tween.tween_callback(func():
		is_typing = false
		_show_continue_arrow()
	)

func _on_player_advance() -> void:
	if is_typing:
		if typewriter_tween and typewriter_tween.is_valid():
			typewriter_tween.kill()
		dialogue_label.visible_ratio = 1.0
		is_typing = false
		_show_continue_arrow()
		return
		
	if is_dialogue_active and not is_showing_choices:
		queue_index += 1
		_show_current_queue_item()

# ==============================================================================
# CHOICE SYSTEM
# ==============================================================================

func _display_choice_menu(menu_id: String) -> void:
	is_showing_choices = true
	is_typing = false
	_hide_continue_arrow()
	_hide_question_mark()
	dialogue_label.visible = false
	
	if not choice_container:
		return
		
	for c in choice_container.get_children():
		c.queue_free()
	choice_buttons.clear()
	active_choices.clear()
	
	var menu_key = "%s_choices" % menu_id
	var menu_info = level_data.get(menu_key, {})
	var prompt_title = menu_info.get("prompt", "ตัวเลือกคำถาม")
	active_choices = menu_info.get("options", [])
	
	speaker_label.text = prompt_title
	speaker_label.add_theme_color_override("font_color", Color(0.941, 0.824, 0.451, 1.0))
	
	for i in range(active_choices.size()):
		var choice = active_choices[i]
		var btn = Button.new()
		btn.text = choice["text"]
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		if font_ta8bit:
			btn.add_theme_font_override("font", font_ta8bit)
			btn.add_theme_font_size_override("font_size", 21)
			
		var normal_sb = StyleBoxFlat.new()
		normal_sb.bg_color = Color(0, 0, 0, 0)
		normal_sb.content_margin_left = 6
		normal_sb.content_margin_top = 2
		normal_sb.content_margin_bottom = 2
		
		var hover_sb = StyleBoxFlat.new()
		hover_sb.bg_color = Color(0.22, 0.16, 0.35, 0.65)
		hover_sb.corner_radius_top_left = 6
		hover_sb.corner_radius_top_right = 6
		hover_sb.corner_radius_bottom_left = 6
		hover_sb.corner_radius_bottom_right = 6
		hover_sb.content_margin_left = 12
		hover_sb.content_margin_top = 2
		hover_sb.content_margin_bottom = 2
		
		btn.add_theme_stylebox_override("normal", normal_sb)
		btn.add_theme_stylebox_override("hover", hover_sb)
		btn.add_theme_stylebox_override("pressed", hover_sb)
		btn.add_theme_stylebox_override("focus", normal_sb)
		
		btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 0.95))
		btn.add_theme_color_override("font_hover_color", Color(0.941, 0.824, 0.451, 1.0))
		
		btn.pressed.connect(_on_choice_selected.bind(i))
		choice_container.add_child(btn)
		choice_buttons.append(btn)
		
	choice_container.visible = true

func _on_choice_selected(index: int) -> void:
	if index < 0 or index >= active_choices.size():
		return
		
	var choice = active_choices[index]
	var choice_id = choice.get("id", "")
	
	if choice_container:
		choice_container.visible = false
	is_showing_choices = false
	dialogue_label.visible = true
	
	var seq_key = "%s_seq" % choice_id
	var seq = level_data.get(seq_key, [])
	if seq.size() > 0:
		_load_sequence(seq)
	else:
		push_warning("[LevelDialogueView] No sequence found for choice: %s" % choice_id)
		_finish_dialogue_stage()

# ==============================================================================
# TERMINAL PRACTICE SIMULATION (จำลองการร่ายคาถา Git)
# ==============================================================================

func _trigger_terminal_practice(item: Dictionary) -> void:
	is_terminal_practicing = true
	is_dialogue_active = false
	_hide_continue_arrow()
	
	# สร้างหน้าต่าง Terminal จำลอง
	if not terminal_panel:
		terminal_panel = PanelContainer.new()
		terminal_panel.custom_minimum_size = Vector2(800, 260)
		terminal_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		terminal_panel.offset_left = -400
		terminal_panel.offset_top = -240
		terminal_panel.offset_right = 400
		terminal_panel.offset_bottom = 20
		
		var term_sb = StyleBoxFlat.new()
		term_sb.bg_color = Color(0.08, 0.06, 0.14, 0.95)
		term_sb.border_color = Color(0.48, 0.78, 1.0, 0.8)
		term_sb.set_border_width_all(2)
		term_sb.set_corner_radius_all(10)
		term_sb.content_margin_left = 20
		term_sb.content_margin_top = 16
		term_sb.content_margin_right = 20
		term_sb.content_margin_bottom = 16
		terminal_panel.add_theme_stylebox_override("panel", term_sb)
		
		var term_vbox = VBoxContainer.new()
		term_vbox.add_theme_constant_override("separation", 10)
		terminal_panel.add_child(term_vbox)
		
		var term_header = Label.new()
		term_header.text = "[ แท่นร่ายคาถาเวท Git ]"
		if font_ta8bit:
			term_header.add_theme_font_override("font", font_ta8bit)
			term_header.add_theme_font_size_override("font_size", 22)
		term_header.add_theme_color_override("font_color", Color(0.941, 0.824, 0.451, 1.0))
		term_vbox.add_child(term_header)
		
		terminal_text_label = RichTextLabel.new()
		terminal_text_label.bbcode_enabled = true
		terminal_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		terminal_text_label.scroll_active = false
		if font_ta8bit:
			terminal_text_label.add_theme_font_override("normal_font", font_ta8bit)
			terminal_text_label.add_theme_font_size_override("normal_font_size", 20)
		terminal_text_label.add_theme_color_override("default_color", Color.WHITE)
		term_vbox.add_child(terminal_text_label)
		
		magic_ui.add_child(terminal_panel)
		
	terminal_panel.visible = true
	terminal_panel.modulate.a = 0.0
	terminal_text_label.text = ""
	
	var commands: Array = item.get("commands", [])
	var output: String = item.get("output", "")
	var next_seq_name: String = item.get("next_sequence", "")
	
	var tw = create_tween()
	tw.tween_property(terminal_panel, "modulate:a", 1.0, 0.25)
	
	var accumulated_text := ""
	for cmd in commands:
		accumulated_text += "[color=#5fffe0]$[/color] %s\n" % _highlight_code_syntax(str(cmd))
	if output != "":
		accumulated_text += "[color=#ffd166]%s[/color]\n" % output
		
	tw.tween_interval(0.3)
	tw.tween_callback(func():
		terminal_text_label.text = accumulated_text
	)
	
	tw.tween_interval(1.6)
	tw.tween_property(terminal_panel, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func():
		terminal_panel.visible = false
		is_terminal_practicing = false
		if next_seq_name != "" and level_data.has(next_seq_name):
			_load_sequence(level_data[next_seq_name])
		else:
			queue_index += 1
			_show_current_queue_item()
	)

# ==============================================================================
# OUTRO & TRANSITIONS
# ==============================================================================

func _trigger_outro_stairs_walk() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	is_dialogue_active = false
	_hide_continue_arrow()
	
	var tw_close = create_tween()
	tw_close.tween_property(dialogue_box, "modulate:a", 0.0, 0.3)
	tw_close.tween_callback(func(): dialogue_box.visible = false)
	
	vel.play("walk")
	var walk_past = create_tween()
	walk_past.tween_property(vel, "position:x", 1500.0, 3.0).set_trans(Tween.TRANS_LINEAR)
	
	walk_past.tween_callback(func():
		var fade_black = create_tween()
		fade_black.tween_property(fade_overlay, "color:a", 1.0, 0.6)
		fade_black.tween_callback(func():
			_show_stairs_climb_scene()
		)
	)

func _show_stairs_climb_scene() -> void:
	mewla.visible = false
	if ResourceLoader.exists("res://assets/cutscene/backgrounds/central-tower-Sheet.png"):
		background.texture = load("res://assets/cutscene/backgrounds/central-tower-Sheet.png")
		
	vel.position = Vector2(960, 750)
	if vel.sprite_frames.has_animation("back"):
		vel.play("back")
	else:
		vel.play("walk")
		
	var fade_in = create_tween()
	fade_in.tween_property(fade_overlay, "color:a", 0.0, 0.6)
	
	fade_in.tween_interval(0.3)
	var climb = create_tween()
	climb.tween_property(vel, "position:y", 715.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	climb.tween_interval(0.2)
	climb.tween_property(vel, "position:y", 680.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	climb.tween_callback(func():
		_show_level_cleared_banner()
	)

func _show_level_cleared_banner() -> void:
	var banner = Label.new()
	banner.text = "ผ่านด่านที่ %d สำเร็จ!" % level_number
	if level_data.has("title"):
		banner.text = "ผ่าน%s สำเร็จ!" % level_data["title"]
		
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	banner.modulate.a = 0.0
	
	if font_ta8bit:
		banner.add_theme_font_override("font", font_ta8bit)
		banner.add_theme_font_size_override("font_size", 32)
	banner.add_theme_color_override("font_color", Color(0.941, 0.824, 0.451, 1.0))
	banner.add_theme_constant_override("outline_size", 4)
	banner.add_theme_color_override("font_outline_color", Color.BLACK)
	magic_ui.add_child(banner)
	
	var tw_banner = create_tween()
	tw_banner.tween_property(banner, "modulate:a", 1.0, 0.6)
	tw_banner.tween_interval(1.8)
	tw_banner.tween_property(fade_overlay, "color:a", 1.0, 0.8)
	tw_banner.tween_callback(func():
		Engine.time_scale = 1.0
		if next_scene_path != "" and ResourceLoader.exists(next_scene_path):
			get_tree().change_scene_to_file(next_scene_path)
	)

func _trigger_bad_ending() -> void:
	is_transitioning = true
	is_dialogue_active = false
	_hide_continue_arrow()
	
	var tw_close = create_tween()
	tw_close.tween_property(dialogue_box, "modulate:a", 0.0, 0.4)
	tw_close.parallel().tween_property(fade_overlay, "color:a", 1.0, 0.8)
	
	tw_close.tween_callback(func():
		dialogue_box.visible = false
		
		bad_ending_panel = Control.new()
		bad_ending_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		magic_ui.add_child(bad_ending_panel)
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		vbox.add_theme_constant_override("separation", 24)
		bad_ending_panel.add_child(vbox)
		
		var title = Label.new()
		title.text = "ขอบคุณที่เล่น Git Di Waa\n(จบแบบลับ: เข้าผิดหอคอย)"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if font_ta8bit:
			title.add_theme_font_override("font", font_ta8bit)
			title.add_theme_font_size_override("font_size", 30)
		title.add_theme_color_override("font_color", Color(0.98, 0.85, 0.5, 1.0))
		title.add_theme_constant_override("outline_size", 4)
		title.add_theme_color_override("font_outline_color", Color.BLACK)
		vbox.add_child(title)
		
		var btn = Button.new()
		btn.text = "กลับสู่หน้าแรก"
		btn.custom_minimum_size = Vector2(200, 48)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if font_ta8bit:
			btn.add_theme_font_override("font", font_ta8bit)
			btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(func():
			get_tree().change_scene_to_file("res://features/start/start_view.tscn")
		)
		vbox.add_child(btn)
	)

func _finish_dialogue_stage() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	is_dialogue_active = false
	
	_hide_continue_arrow()
	_hide_question_mark()
	
	var finish_tween = create_tween()
	finish_tween.tween_property(fade_overlay, "color:a", 1.0, 0.5)
	finish_tween.tween_callback(func():
		Engine.time_scale = 1.0
		if next_scene_path != "" and ResourceLoader.exists(next_scene_path):
			get_tree().change_scene_to_file(next_scene_path)
	)

# ==============================================================================
# EMOTES & HELPERS
# ==============================================================================

func _on_vel_animation_looped() -> void:
	if vel.animation in VEL_IDLE_SEQ:
		vel_seq_step = (vel_seq_step + 1) % VEL_IDLE_SEQ.size()
		vel.play(VEL_IDLE_SEQ[vel_seq_step])

func _pop_question_mark() -> void:
	if question_tween and question_tween.is_valid():
		question_tween.kill()
	question_mark.visible = true
	question_mark.scale = Vector2.ZERO
	question_mark.position = Vector2(0, -36)
	question_mark.modulate.a = 1.0
	
	var tw_pop = create_tween()
	tw_pop.tween_property(question_mark, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_pop.tween_callback(func():
		if not is_instance_valid(question_mark) or not question_mark.visible:
			return
		question_tween = create_tween().set_loops()
		question_tween.tween_property(question_mark, "position:y", -39.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		question_tween.tween_property(question_mark, "position:y", -33.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	)
	question_tween = tw_pop

func _hide_question_mark() -> void:
	if question_tween and question_tween.is_valid():
		question_tween.kill()
	if is_instance_valid(question_mark):
		question_mark.visible = false
		question_mark.scale = Vector2.ZERO
		question_mark.position = Vector2(0, -36)

func _show_continue_arrow() -> void:
	if not continue_arrow:
		return
	if arrow_tween and arrow_tween.is_valid():
		arrow_tween.kill()
		
	continue_arrow.position.y = 0.0
	continue_arrow.visible = true
	arrow_tween = create_tween().set_loops()
	arrow_tween.tween_property(continue_arrow, "position:y", 4.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	arrow_tween.tween_property(continue_arrow, "position:y", 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _hide_continue_arrow() -> void:
	if arrow_tween and arrow_tween.is_valid():
		arrow_tween.kill()
	if is_instance_valid(continue_arrow):
		continue_arrow.visible = false
		continue_arrow.position.y = 0.0
