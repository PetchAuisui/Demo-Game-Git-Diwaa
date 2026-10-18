extends Node2D

## การควบคุมฉากคัตซีนภายในหอคอยเวท (Inside Tower Cutscene)
## ลำดับเหตุการณ์:
## 1. เฟดเข้าจากจอดำสู่ห้องโถงภายในหอคอย (inside-tower-Sheet)
## 2. เวล (ฝั่งซ้าย) เดินเข้ามาในห้องโถง และพบกับมิวรา (ฝั่งขวา)
## 3. เริ่มต้นบทสนทนา: มิวราทักทาย -> เวลถาม -> มิวราแนะนำตัวและเตรียมฝึกคาถาแรก
## 4. ผู้เล่นคลิกหน้าจอ หรือกด Space / Enter เพื่ออ่านบทสนทนาทีละประโยค (มี Typewriter Effect)
## 5. เมื่อคุยจบครบทุกประโยค หรือผู้เล่นกดปุ่มข้าม (Skip / Esc) -> เฟดจอดำและสลับเข้าสู่ด่านถัดไป (SandboxGameView)

@export var next_scene_path: String = "res://Scenes/SandboxGameView.tscn"

# Animation & Visuals
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera2D = $Camera2D
@onready var background: Sprite2D = $Background
@onready var atmosphere: ColorRect = $Atmosphere
@onready var fade_overlay: ColorRect = $MagicStoryUI/FadeOverlay

# Characters
@onready var stage: Node2D = $Stage
@onready var vel: AnimatedSprite2D = $Stage/Vel
@onready var exclamation_mark: Sprite2D = $Stage/Vel/ExclamationMark
@onready var question_mark: Node2D = $Stage/Vel/QuestionMark
@onready var mewla: AnimatedSprite2D = $Stage/Mewla

# UI Elements
@onready var magic_ui: CanvasLayer = $MagicStoryUI
@onready var dialogue_box: PanelContainer = $MagicStoryUI/DialogueBox
@onready var speaker_label: Label = $MagicStoryUI/DialogueBox/Margin/VBox/SpeakerLabel
@onready var dialogue_label: Label = $MagicStoryUI/DialogueBox/Margin/VBox/DialogueLabel
@onready var continue_arrow: TextureRect = $MagicStoryUI/DialogueBox/ArrowOverlay/ArrowWrapper/ContinueArrow
@onready var arrow_wrapper: Control = $MagicStoryUI/DialogueBox/ArrowOverlay/ArrowWrapper
@onready var skip_button: Button = $MagicStoryUI/SkipButton

# เวล (ท่าปกติวนลูป): breathe -> breathe_blink -> breathe -> breathe -> breathe_blink
const VEL_IDLE_SEQ: Array[String] = ["breathe", "breathe_blink", "breathe", "breathe", "breathe_blink"]
var vel_seq_step: int = 0
var vel_custom_anim: String = ""

# Dialogue Script Data (บทสนทนาประจำฉาก)
const DIALOGUES: Array[Dictionary] = [
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

var current_dialogue_index: int = 0
var is_dialogue_active: bool = false
var is_typing: bool = false
var is_transitioning: bool = false
var typewriter_tween: Tween = null
var question_tween: Tween = null
var exclamation_tween: Tween = null
var arrow_tween: Tween = null
var entrance_tween: Tween = null

func _ready() -> void:
	# 1. ตั้งค่าเริ่มต้นหน้าจอ
	fade_overlay.visible = true
	fade_overlay.color = Color(0, 0, 0, 1)
	dialogue_box.visible = false
	continue_arrow.visible = false
	exclamation_mark.visible = false
	question_mark.visible = false
	
	# ตั้งค่าตำแหน่งตัวละคร
	camera.position = Vector2(960, 540)
	vel.position = Vector2(-120, 750)
	vel.scale = Vector2(4, 4)
	vel.play("walk")
	vel.animation_looped.connect(_on_vel_animation_looped)
	
	mewla.position = Vector2(1220, 750)
	mewla.scale = Vector2(4, 4)
	mewla.play("idle")
	
	question_mark.scale = Vector2.ONE
	
	# เล่นอนิเมชันแบ็กกราวด์ลูปวน
	if anim_player.has_animation("background_loop"):
		anim_player.play("background_loop")
		
	# เชื่อมต่อปุ่มข้าม
	if skip_button and not skip_button.pressed.is_connected(_on_skip_button_pressed):
		skip_button.pressed.connect(_on_skip_button_pressed)
		
	# 2. เริ่มโฟลว์เดินเข้าฉาก
	_start_cutscene_sequence()

func _input(event: InputEvent) -> void:
	if is_transitioning:
		return
		
	# กด Esc เพื่อข้ามคัตซีน
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_skip_cutscene()
		return
		
	# คลิกหรือกด Space/Enter เพื่อไปต่อ
	if is_dialogue_active:
		var wants_advance: bool = false
		if event.is_action_pressed("ui_accept"):
			wants_advance = true
		elif event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			wants_advance = true
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# ตรวจสอบว่าไม่ได้กดโดนปุ่ม Skip
			if skip_button and not skip_button.get_global_rect().has_point(event.position):
				wants_advance = true
				
		if wants_advance:
			get_viewport().set_input_as_handled()
			_on_player_advance()

func _on_skip_button_pressed() -> void:
	_skip_cutscene()

func _start_cutscene_sequence() -> void:
	# เฟดสว่างเข้ามา
	var fade_in = create_tween()
	fade_in.tween_property(fade_overlay, "color:a", 0.0, 0.8)
	
	# เวลเดินเข้ามาจากทางซ้าย (-120 -> 700) ตามสเปก Open Game (ระยะ 820px ใน 4.2 วินาที @ ความเร็ว ~195-200 px/s)
	entrance_tween = create_tween()
	entrance_tween.set_trans(Tween.TRANS_LINEAR)
	entrance_tween.tween_property(vel, "position:x", 700.0, 4.2)
	
	entrance_tween.tween_callback(func():
		# ซิงค์จังหวะหายใจ/ผงกหัวให้เวลและมิวราเริ่มต้นที่เฟรม 0 พร้อมกันเป๊ะๆ (ตามสเปก md: 6 เฟรม @ 5 FPS [2, 1, 2, 1, 2, 1] = 1.8s)
		vel_seq_step = 0
		vel.play("breathe")
		vel.set_frame_and_progress(0, 0.0)
		mewla.play("idle")
		mewla.set_frame_and_progress(0, 0.0)
		
		# หน่วงเวลาเล็กน้อยก่อนกล่องข้อความปรากฏ
		var delay_tween = create_tween()
		delay_tween.tween_interval(0.35)
		delay_tween.tween_callback(func():
			_open_dialogue_box()
		)
	)

func _open_dialogue_box() -> void:
	dialogue_box.visible = true
	dialogue_box.modulate.a = 0.0
	
	var box_tween = create_tween()
	box_tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.25)
	box_tween.tween_callback(func():
		current_dialogue_index = 0
		_show_dialogue(current_dialogue_index)
	)

func _show_dialogue(index: int) -> void:
	if index < 0 or index >= DIALOGUES.size():
		_finish_cutscene()
		return
		
	var data = DIALOGUES[index]
	is_dialogue_active = true
	is_typing = true
	_hide_continue_arrow()
	
	speaker_label.text = data["speaker"]
	dialogue_label.text = data["text"]
	dialogue_label.visible_ratio = 0.0
	
	# ปรับสีชื่อผู้พูดและท่าทางมิวรา พร้อมส่งต่อ frame และ progress ให้จังหวะขยับตัวไม่หลุดเฟส
	var target_mewla_anim = data.get("mewla_anim", "talk")
	if data["speaker"] == "มิวรา":
		speaker_label.add_theme_color_override("font_color", Color(0.941, 0.824, 0.451, 1.0)) # สีทอง
		if mewla.animation != target_mewla_anim:
			mewla.play(target_mewla_anim)
			mewla.set_frame_and_progress(vel.frame, vel.frame_progress)
	else:
		speaker_label.add_theme_color_override("font_color", Color(0.48, 0.78, 1.0, 1.0)) # สีฟ้าอ่อนสำหรับเวล
		if mewla.animation != "idle":
			mewla.play("idle")
			mewla.set_frame_and_progress(vel.frame, vel.frame_progress)
		
	# อัปเดตท่าทางเวล
	if vel_custom_anim != "":
		vel_custom_anim = ""
		vel.play("breathe")
		vel.set_frame_and_progress(mewla.frame, mewla.frame_progress)
		
	# ไอคอน Emote
	var emote = data.get("emote", "")
	if emote == "question":
		_hide_exclamation()
		_pop_question_mark()
	elif emote == "exclamation":
		_hide_question_mark()
		_pop_exclamation()
	else:
		_hide_question_mark()
		_hide_exclamation()
		
	# Typewriter effect
	if typewriter_tween and typewriter_tween.is_valid():
		typewriter_tween.kill()
		
	var duration: float = clampf(float(data["text"].length()) * 0.035, 0.4, 1.5)
	typewriter_tween = create_tween()
	typewriter_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)
	typewriter_tween.tween_callback(func():
		is_typing = false
		_show_continue_arrow()
	)

func _on_player_advance() -> void:
	if is_typing:
		# เร่งแสดงข้อความเต็มทันที
		if typewriter_tween and typewriter_tween.is_valid():
			typewriter_tween.kill()
		dialogue_label.visible_ratio = 1.0
		is_typing = false
		_show_continue_arrow()
		return
		
	if is_dialogue_active:
		current_dialogue_index += 1
		if current_dialogue_index < DIALOGUES.size():
			_show_dialogue(current_dialogue_index)
		else:
			_finish_cutscene()

func _on_vel_animation_looped() -> void:
	if vel.animation in VEL_IDLE_SEQ:
		vel_seq_step = (vel_seq_step + 1) % VEL_IDLE_SEQ.size()
		vel.play(VEL_IDLE_SEQ[vel_seq_step])

func _pop_question_mark() -> void:
	question_mark.visible = true
	question_mark.scale = Vector2.ZERO
	question_mark.position = Vector2(0, -36)
	
	if question_tween and question_tween.is_valid():
		question_tween.kill()
		
	question_tween = create_tween()
	question_tween.set_parallel(true)
	question_tween.tween_property(question_mark, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	question_tween.tween_property(question_mark, "modulate:a", 1.0, 0.15)

func _hide_question_mark() -> void:
	if not question_mark.visible:
		return
	if question_tween and question_tween.is_valid():
		question_tween.kill()
		
	question_tween = create_tween()
	question_tween.tween_property(question_mark, "modulate:a", 0.0, 0.15)
	question_tween.tween_callback(func():
		question_mark.visible = false
	)

func _pop_exclamation() -> void:
	exclamation_mark.visible = true
	exclamation_mark.scale = Vector2.ZERO
	
	if exclamation_tween and exclamation_tween.is_valid():
		exclamation_tween.kill()
		
	exclamation_tween = create_tween()
	exclamation_tween.set_parallel(true)
	exclamation_tween.tween_property(exclamation_mark, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	exclamation_tween.tween_property(exclamation_mark, "modulate:a", 1.0, 0.15)

func _hide_exclamation() -> void:
	if not exclamation_mark.visible:
		return
	if exclamation_tween and exclamation_tween.is_valid():
		exclamation_tween.kill()
		
	exclamation_tween = create_tween()
	exclamation_tween.tween_property(exclamation_mark, "modulate:a", 0.0, 0.15)
	exclamation_tween.tween_callback(func():
		exclamation_mark.visible = false
	)

func _show_continue_arrow() -> void:
	continue_arrow.visible = true
	if arrow_tween and arrow_tween.is_valid():
		arrow_tween.kill()
		
	arrow_wrapper.position.y = 0.0
	arrow_tween = create_tween().set_loops()
	arrow_tween.tween_property(arrow_wrapper, "position:y", 4.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	arrow_tween.tween_property(arrow_wrapper, "position:y", 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _hide_continue_arrow() -> void:
	continue_arrow.visible = false
	if arrow_tween and arrow_tween.is_valid():
		arrow_tween.kill()

func _skip_cutscene() -> void:
	if is_transitioning:
		return
	_finish_cutscene()

func _finish_cutscene() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	is_dialogue_active = false
	
	if entrance_tween and entrance_tween.is_valid():
		entrance_tween.kill()
		
	_hide_continue_arrow()
	_hide_question_mark()
	_hide_exclamation()
	
	# เฟดจอดำ
	var finish_tween = create_tween()
	finish_tween.tween_property(fade_overlay, "color:a", 1.0, 0.6)
	finish_tween.tween_callback(func():
		if next_scene_path != "" and ResourceLoader.exists(next_scene_path):
			get_tree().change_scene_to_file(next_scene_path)
		else:
			push_warning("Next scene path not found: %s" % next_scene_path)
	)
