extends Node2D

## ตัวควบคุมและแสดงผลบทสนทนาประจำด่าน (Level Dialogue View)
## รองรับบทสนทนา ด่าน 1 ถึง ด่าน 15 แบบแยกไฟล์ข้อมูล (Data-driven)
##
## วิธีใช้งาน:
## - กำหนด @export var level_number: int เพื่อเลือกด่านที่ต้องการเล่น (ค่าเริ่มต้น: 1)
## - สคริปต์จะโหลดข้อมูลจาก res://features/dialogue/levels/level_%02d.gd มาแสดงผลอัตโนมัติ
## - รองรับ Typewriter Effect, BBCode ไฮไลต์โค้ดสไตล์ Markdown, ช้อยส์ในกล่องข้อความเดิม,
##   และเชื่อมต่อไปยังหน้าจำลองการเล่นภายในด่าน (Gameplay Placeholder View)

static var start_phase: int = 0

@export var level_number: int = 1
@export var next_scene_path: String = "res://features/sandbox/sandbox_game_view.tscn"
@export var play_entrance_cutscene: bool = false
@export var fade_in_from_black: bool = false
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

# Data & Queue
var level_data: Dictionary = {}
var current_queue: Array = []
var queue_index: int = 0

var is_dialogue_active: bool = false
var is_typing: bool = false
var is_transitioning: bool = false
var is_fast_forwarding: bool = false
var skip_ctrl = null
var font_ta8bit: Font = null

# Animation Sequence
const VEL_IDLE_SEQ: Array[String] = ["breathe", "breathe_blink", "breathe", "breathe", "breathe_blink"]
var vel_seq_step: int = 0

# Cutscene Tweens & States
var entrance_tween: Tween = null
var stand_tween: Tween = null
var warp_tween: Tween = null
var reaction_tween: Tween = null
var hop_tween: Tween = null
var open_box_tween: Tween = null
var is_in_entrance_cutscene: bool = false

var typewriter_tween: Tween = null
var question_tween: Tween = null
var exclamation_tween: Tween = null
var arrow_tween: Tween = null

# บทสนทนาสำหรับช่วงคัตซีนเปิดตัวพบมิวราครั้งแรก (5 ประโยค)
const INTRO_DIALOGUES: Array[Dictionary] = [
	{
		"speaker": "มิวรา",
		"text": "ยินดีต้อนรับสู่กิลด์แห่งหอคอยเวท",
		"mewla_anim": "talk"
	},
	{
		"speaker": "เวล",
		"text": "เธอคือ...",
		"emote": "question",
		"mewla_anim": "idle"
	},
	{
		"speaker": "มิวรา",
		"text": "“แมวไง เห็นก็รู้ปะ” ฉันมิวรา ผู้ดูแลกิลด์\nและเป็นคนที่จะสอนนายตั้งแต่พื้นฐาน",
		"mewla_anim": "talk"
	},
	{
		"speaker": "มิวรา",
		"text": "ก่อนเข้าสู่บททดสอบของหอคอย\nนายต้องตรวจสอบว่าพลังเวทของตัวเองพร้อมใช้งานหรือยัง",
		"mewla_anim": "talk"
	},
	{
		"speaker": "มิวรา",
		"text": "มาเริ่มคาถาแรกกัน",
		"mewla_anim": "success"
	}
]

func _ready() -> void:
	if ResourceLoader.exists("res://assets/fonts/TA-8-bit.ttf"):
		font_ta8bit = load("res://assets/fonts/TA-8-bit.ttf")
		
	# สร้าง Choice Container ภายในกล่องข้อความเดิม (DialogueBox) ใต้ SpeakerLabel
	var vbox = dialogue_box.get_node_or_null("Margin/VBox")
	if vbox:
		choice_container = VBoxContainer.new()
		choice_container.visible = false
		choice_container.add_theme_constant_override("separation", 6)
		vbox.add_child(choice_container)
		
	camera.position = Vector2(960, 540)
	continue_arrow.visible = false
	exclamation_mark.visible = false
	question_mark.visible = false
	exclamation_mark.scale = Vector2.ONE
	exclamation_mark.position = Vector2(0, -42)
	question_mark.scale = Vector2.ONE
	question_mark.position = Vector2(0, -36)
	
	if anim_player.has_animation("background_loop"):
		anim_player.play("background_loop")
		
	# ปุ่มเร่งความเร็ว และปุ่มข้าม
	skip_ctrl = preload("res://features/cutscene/skip_cutscene_button.gd").new()
	skip_ctrl.next_scene_path = next_scene_path
	skip_ctrl.custom_skip_action = _on_skip_step
	add_child(skip_ctrl)
	
	# โหลดข้อมูลด่าน
	_load_level_data(level_number)
	
	if start_phase > 0:
		debug_phase = start_phase
		play_entrance_cutscene = false
		fade_in_from_black = true
		start_phase = 0
	
	if play_entrance_cutscene:
		# เริ่มต้นในโหมดคัตซีนเดินเข้าห้องโถง
		is_in_entrance_cutscene = true
		fade_overlay.visible = true
		fade_overlay.color = Color(0, 0, 0, 1)
		dialogue_box.visible = false
		
		vel.position = Vector2(-120, 680)
		vel.scale = Vector2(4, 4)
		vel.play("walk")
		if not vel.animation_looped.is_connected(_on_vel_animation_looped):
			vel.animation_looped.connect(_on_vel_animation_looped)
		
		mewla.visible = false
		mewla.position = Vector2(1220, 680)
		mewla.scale = Vector2.ZERO
		mewla.modulate = Color(1, 1, 1, 0)
		
		_start_entrance_cutscene()
	else:
		# เริ่มต้นในโหมดบทสนทนาด่านทันที (ไม่เล่นคัตซีนเดินเข้า)
		is_in_entrance_cutscene = false
		fade_overlay.visible = fade_in_from_black
		fade_overlay.color = Color(0, 0, 0, 1) if fade_in_from_black else Color(0, 0, 0, 0)
		dialogue_box.visible = true
		dialogue_box.modulate.a = 1.0
		
		vel.position = Vector2(700, 680)
		vel.scale = Vector2(4, 4)
		vel.play("breathe")
		if not vel.animation_looped.is_connected(_on_vel_animation_looped):
			vel.animation_looped.connect(_on_vel_animation_looped)
		
		mewla.visible = true
		mewla.position = Vector2(1220, 680)
		mewla.scale = Vector2(4, 4)
		mewla.modulate = Color.WHITE
		mewla.play("idle")
		
		_start_dialogue_scene()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _process(_delta: float) -> void:
	if is_transitioning:
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
	if is_transitioning:
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
	_begin_dialogue_phase()
	if fade_in_from_black:
		var fade_in = create_tween()
		fade_in.tween_property(fade_overlay, "color:a", 0.0, 0.4)

func _begin_dialogue_phase() -> void:
	dialogue_box.visible = true
	dialogue_box.modulate.a = 1.0
	if debug_phase == 1:
		_load_sequence(level_data.get("part2_intro_sequence", []))
	elif debug_phase == 2:
		_load_sequence(level_data.get("outro_sequence", []))
	else:
		_load_sequence(level_data.get("intro_sequence", []))

# ==============================================================================
# ENTRANCE CUTSCENE (เดินเข้าห้องโถง & พบมิวราก่อนเริ่มบทเรียน)
# ==============================================================================

func _start_entrance_cutscene() -> void:
	# 1. เฟดสว่างเข้ามา
	var fade_in = create_tween()
	fade_in.tween_property(fade_overlay, "color:a", 0.0, 0.8)
	
	# 2. เวลเดินเข้ามาจากทางซ้าย (-120 -> 700) ใน 3.6 วินาที
	entrance_tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	entrance_tween.tween_property(vel, "position:x", 700.0, 3.6)
	entrance_tween.tween_callback(func():
		vel_seq_step = 0
		vel.play("breathe")
		vel.set_frame_and_progress(0, 0.0)
		
		if stand_tween and stand_tween.is_valid():
			stand_tween.kill()
		stand_tween = create_tween()
		stand_tween.tween_interval(1.0)
		stand_tween.tween_callback(func():
			if not is_transitioning:
				_warp_in_mewla_and_shock_vel()
		)
	)

func _warp_in_mewla_and_shock_vel() -> void:
	if is_transitioning:
		return
		
	mewla.visible = true
	mewla.scale = Vector2(4.0, 4.0)
	mewla.position = Vector2(1220.0, 655.0)
	mewla.modulate = Color(1.0, 1.0, 1.0, 0.0)
	mewla.play("idle")
	
	if warp_tween and warp_tween.is_valid():
		warp_tween.kill()
	warp_tween = create_tween().set_parallel(true)
	warp_tween.tween_property(mewla, "modulate:a", 1.0, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	warp_tween.tween_property(mewla, "position:y", 680.0, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	if reaction_tween and reaction_tween.is_valid():
		reaction_tween.kill()
	reaction_tween = create_tween()
	reaction_tween.tween_interval(0.35)
	reaction_tween.tween_callback(func():
		if is_transitioning:
			return
		_trigger_vel_shock_jump()
	)

func _trigger_vel_shock_jump() -> void:
	if is_transitioning:
		return
		
	vel.play("shock")
	_start_exclamation_jump()
	
	if hop_tween and hop_tween.is_valid():
		hop_tween.kill()
		
	var vel_shadow = vel.get_node_or_null("DropShadow")
	hop_tween = create_tween()
	hop_tween.tween_property(vel, "position:y", 610.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if vel_shadow:
		hop_tween.parallel().tween_property(vel_shadow, "scale", Vector2(0.45, 0.30), 0.42)
		hop_tween.parallel().tween_property(vel_shadow, "position:y", 38.5 + (680.0 - 610.0), 0.42)
		hop_tween.parallel().tween_property(vel_shadow, "modulate:a", 0.4, 0.42)
		
	hop_tween.chain().tween_property(vel, "position:y", 680.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if vel_shadow:
		hop_tween.parallel().tween_property(vel_shadow, "scale", Vector2(0.65, 0.45), 0.36)
		hop_tween.parallel().tween_property(vel_shadow, "position:y", 38.5, 0.36)
		hop_tween.parallel().tween_property(vel_shadow, "modulate:a", 1.0, 0.36)
		
	hop_tween.chain().tween_callback(func():
		_hide_exclamation_landing()
		vel_seq_step = 0
		vel.play("breathe")
		vel.set_frame_and_progress(0, 0.0)
	)
	
	if open_box_tween and open_box_tween.is_valid():
		open_box_tween.kill()
	open_box_tween = create_tween()
	open_box_tween.tween_interval(0.42 + 0.36 + 0.65)
	open_box_tween.tween_callback(func():
		if not is_transitioning:
			_open_dialogue_box_for_intro()
	)

func _open_dialogue_box_for_intro() -> void:
	if is_transitioning:
		return
	dialogue_box.visible = true
	dialogue_box.modulate.a = 0.0
	
	var box_tween = create_tween()
	box_tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.25)
	box_tween.tween_callback(func():
		if is_transitioning:
			return
		_load_sequence(INTRO_DIALOGUES)
	)

func _start_exclamation_jump() -> void:
	if exclamation_tween and exclamation_tween.is_valid():
		exclamation_tween.kill()
		
	exclamation_mark.visible = true
	exclamation_mark.scale = Vector2.ZERO
	exclamation_mark.position = Vector2(0, -42)
	exclamation_mark.modulate.a = 1.0
	
	exclamation_tween = create_tween()
	exclamation_tween.tween_property(exclamation_mark, "scale", Vector2(1.15, 1.15), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	exclamation_tween.parallel().tween_property(exclamation_mark, "position:y", -52.0, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	exclamation_tween.chain().tween_property(exclamation_mark, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	exclamation_tween.parallel().tween_property(exclamation_mark, "position:y", -42.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _hide_exclamation_landing() -> void:
	if exclamation_tween and exclamation_tween.is_valid():
		exclamation_tween.kill()
	if not is_instance_valid(exclamation_mark):
		return
	exclamation_tween = create_tween().set_parallel(true)
	exclamation_tween.tween_property(exclamation_mark, "scale", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	exclamation_tween.tween_property(exclamation_mark, "modulate:a", 0.0, 0.15)
	exclamation_tween.chain().tween_callback(func():
		if is_instance_valid(exclamation_mark):
			exclamation_mark.visible = false
			exclamation_mark.position = Vector2(0, -42)
	)

func _hide_exclamation() -> void:
	if exclamation_tween and exclamation_tween.is_valid():
		exclamation_tween.kill()
	if is_instance_valid(exclamation_mark):
		exclamation_mark.visible = false
		exclamation_mark.scale = Vector2.ZERO
		exclamation_mark.position = Vector2(0, -42)

func _on_skip_step() -> void:
	if is_in_entrance_cutscene:
		# ข้ามเฉพาะส่วนเดินเข้าและบทนำ -> เข้าสู่บทสอนด่าน 1 ทันทีในซีนเดิม ไร้รอยต่อ
		is_in_entrance_cutscene = false
		if entrance_tween and entrance_tween.is_valid(): entrance_tween.kill()
		if stand_tween and stand_tween.is_valid(): stand_tween.kill()
		if warp_tween and warp_tween.is_valid(): warp_tween.kill()
		if reaction_tween and reaction_tween.is_valid(): reaction_tween.kill()
		if hop_tween and hop_tween.is_valid(): hop_tween.kill()
		if open_box_tween and open_box_tween.is_valid(): open_box_tween.kill()
		if typewriter_tween and typewriter_tween.is_valid(): typewriter_tween.kill()
		
		vel.position = Vector2(700, 680)
		vel.play("breathe")
		var vel_shadow = vel.get_node_or_null("DropShadow")
		if vel_shadow:
			vel_shadow.position.y = 38.5
			vel_shadow.scale = Vector2(0.65, 0.45)
			vel_shadow.modulate.a = 1.0
			
		mewla.visible = true
		mewla.position = Vector2(1220, 680)
		mewla.scale = Vector2(4, 4)
		mewla.modulate = Color.WHITE
		mewla.play("idle")
		
		_hide_exclamation()
		_hide_question_mark()
		_hide_continue_arrow()
		
		fade_overlay.visible = false
		fade_overlay.color = Color(0, 0, 0, 0)
		dialogue_box.visible = true
		dialogue_box.modulate.a = 1.0
		
		_load_sequence(level_data.get("intro_sequence", []))
		return
		
	# หากอยู่ในช่วงบทเรียนปกติแล้วกดข้าม -> ข้ามเข้าสู่ Sandbox
	if next_scene_path != "" and ResourceLoader.exists(next_scene_path):
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file(next_scene_path)

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
		if is_in_entrance_cutscene:
			# จบบทนำ 5 ประโยคของคัตซีน -> ไหลเข้าสู่บทสอนด่าน 1 ในซีนเดิมทันที ไร้รอยต่อ 100%
			is_in_entrance_cutscene = false
			_load_sequence(level_data.get("intro_sequence", []))
			return
		_finish_dialogue_stage()
		return
		
	var item = current_queue[queue_index]
	if item.has("type"):
		var type = item["type"]
		if type == "choice_menu":
			_display_choice_menu(item["menu"])
			return
		elif type == "goto":
			var target_seq = item.get("target", "")
			if target_seq != "" and level_data.has(target_seq):
				_load_sequence(level_data[target_seq])
			return
		elif type == "open_gameplay":
			var step = item.get("step", 1)
			_open_gameplay_step(step)
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
		choice_container.remove_child(c)
		c.queue_free()
	choice_buttons.clear()
	active_choices = []
	
	var menu_key = "%s_choices" % menu_id
	var menu_info = level_data.get(menu_key, {})
	var prompt_title = menu_info.get("prompt", "ตัวเลือกคำถาม")
	var raw_options = menu_info.get("options", [])
	active_choices = raw_options.duplicate(true)
	
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
# GAMEPLAY PLACEHOLDER & STAGE FINISH
# ==============================================================================

func _open_gameplay_step(step: int) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	is_dialogue_active = false
	_hide_continue_arrow()
	
	var placeholder_script = load("res://features/dialogue/gameplay_placeholder_view.gd")
	if placeholder_script:
		placeholder_script.current_step = step
		placeholder_script.return_scene_path = scene_file_path if scene_file_path != "" else "res://features/cutscene/inside_tower_cutscene.tscn"
	
	var fade_tw = create_tween()
	fade_tw.tween_property(fade_overlay, "color:a", 1.0, 0.35)
	fade_tw.tween_callback(func():
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file("res://features/dialogue/gameplay_placeholder_view.tscn")
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
