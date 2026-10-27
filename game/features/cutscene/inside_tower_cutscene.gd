extends Node2D

## ด่านที่ 1: ตรวจสอบพลังและประกาศนาม (git --version + git config)
## คัตซีนภายในหอคอยเวท (Inside Tower Cutscene)
##
## ลำดับเหตุการณ์:
## 1. เฟดเข้าจากจอดำสู่ห้องโถงภายในหอคอย (inside-tower-Sheet)
## 2. เวล (ฝั่งซ้าย) เดินเข้ามาในห้องโถง และพบกับมิวรา (ฝั่งขวา)
## 3. เริ่มต้นบทสนทนา: มิวราทักทาย -> เวลถาม -> มิวราแนะนำตัว
## 4. ขั้นสอน ส่วนที่ 1 (git --version) -> แสดงตัวเลือก 4 ข้อในกล่องข้อความเดิม
##    - วนลูปถามได้เรื่อยๆ / มีตัวเลือกย่อย ใช่-ไม่ (ถ้าตอบ ไม่ จะจบแบบลับเข้าผิดหอคอย)
## 5. ขั้นสอน ส่วนที่ 2 (git config user.name/email) -> แสดงตัวเลือก 3 ข้อในกล่องข้อความเดิม
## 6. สรุปผล: มิวราคุยกับเวล -> เวลเดินผ่านมิวรา -> ตัดเข้าฉากเดินขึ้นบันได 2 ขั้นเพื่อผ่านด่าน

@export var next_scene_path: String = "res://features/sandbox/sandbox_game_view.tscn"
@export_enum("Intro & Part 1", "Part 2 (git config)", "Outro (Stairs)") var debug_start_phase: int = 0

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
@onready var dialogue_label: Label = $MagicStoryUI/DialogueBox/Margin/VBox/DialogueLabel
@onready var continue_arrow: TextureRect = $MagicStoryUI/DialogueBox/ArrowOverlay/ArrowWrapper/ContinueArrow
@onready var arrow_wrapper: Control = $MagicStoryUI/DialogueBox/ArrowOverlay/ArrowWrapper

# UI Dynamic Controls
var choice_container: VBoxContainer = null
var choice_buttons: Array[Button] = []
var active_choices: Array[Dictionary] = []
var is_showing_choices: bool = false
var bad_ending_panel: Control = null

# เวล (ท่าปกติวนลูป): breathe -> breathe_blink -> breathe -> breathe -> breathe_blink
const VEL_IDLE_SEQ: Array[String] = ["breathe", "breathe_blink", "breathe", "breathe", "breathe_blink"]
var vel_seq_step: int = 0

# Dialogue Queue System
var current_queue: Array[Dictionary] = []
var queue_index: int = 0

var is_dialogue_active: bool = false
var is_typing: bool = false
var is_transitioning: bool = false
var is_fast_forwarding: bool = false
var skip_ctrl = null
var font_ta8bit: Font = null

var typewriter_tween: Tween = null
var question_tween: Tween = null
var exclamation_tween: Tween = null
var arrow_tween: Tween = null
var entrance_tween: Tween = null
var stand_tween: Tween = null
var warp_tween: Tween = null
var reaction_tween: Tween = null
var hop_tween: Tween = null
var open_box_tween: Tween = null

func _ready() -> void:
	if ResourceLoader.exists("res://assets/fonts/TA-8-bit.ttf"):
		font_ta8bit = load("res://assets/fonts/TA-8-bit.ttf")
		
	# 1. ตั้งค่าเริ่มต้นหน้าจอ
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
	
	# ตั้งค่าตำแหน่งตัวละคร
	camera.position = Vector2(960, 540)
	vel.position = Vector2(-120, 680)
	vel.scale = Vector2(4, 4)
	vel.play("walk")
	vel.animation_looped.connect(_on_vel_animation_looped)
	
	# มิวรายังไม่ปรากฏในฉากตอนแรก (จะวาร์ปเข้ามาเมื่อเวลเดินมาหยุด)
	mewla.visible = false
	mewla.position = Vector2(1220, 680)
	mewla.scale = Vector2.ZERO
	mewla.modulate = Color(1, 1, 1, 0)
	
	exclamation_mark.visible = false
	exclamation_mark.scale = Vector2.ONE
	exclamation_mark.position = Vector2(0, -42)
	question_mark.visible = false
	question_mark.scale = Vector2.ONE
	question_mark.position = Vector2(0, -36)
	
	# เล่นอนิเมชันแบ็กกราวด์ลูปวน
	if anim_player.has_animation("background_loop"):
		anim_player.play("background_loop")
		
	# ระบบควบคุม Cutscene: ปุ่มเร่งความเร็ว (FF 2.5x) และปุ่มข้าม (Skip / Esc)
	skip_ctrl = preload("res://features/cutscene/skip_cutscene_button.gd").new()
	skip_ctrl.next_scene_path = next_scene_path
	add_child(skip_ctrl)
		
	# 2. เริ่มตาม Phase ที่กำหนด
	if debug_start_phase == 1:
		_start_part2_direct()
	elif debug_start_phase == 2:
		_start_outro_direct()
	else:
		_start_cutscene_sequence()

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
		
	# เมื่ออยู่ในโหมดเลือกช้อยส์ รองรับการกดตัวเลข 1, 2, 3, 4
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
# INTRO SEQUENCE & WALK-IN
# ==============================================================================

func _start_cutscene_sequence() -> void:
	var fade_in = create_tween()
	fade_in.tween_property(fade_overlay, "color:a", 0.0, 0.8)
	
	entrance_tween = create_tween()
	entrance_tween.set_trans(Tween.TRANS_LINEAR)
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
		if is_transitioning:
			return
		_hide_exclamation()
		vel_seq_step = 0
		vel.play("breathe")
		vel.set_frame_and_progress(0, 0.0)
		mewla.set_frame_and_progress(0, 0.0)
		
		var beat_tween = create_tween()
		beat_tween.tween_interval(0.65)
		beat_tween.tween_callback(func():
			if not is_transitioning:
				_start_part1()
		)
	)

# ==============================================================================
# DIALOGUE QUEUE & CHOICE SYSTEM (INLINE DIALOGUE BOX)
# ==============================================================================

func _start_part1() -> void:
	_open_dialogue_box()
	_load_sequence([
		{"speaker": "มิวรา", "text": "ยินดีต้อนรับสู่กิลด์แห่งหอคอยเวท", "mewla_anim": "talk"},
		{"speaker": "เวล", "text": "เธอคือ...", "emote": "question", "mewla_anim": "idle"},
		{"speaker": "มิวรา", "text": "“แมวไง เห็นก็รู้ปะ” ฉันมิวรา ผู้ดูแลกิลด์\nและเป็นคนที่จะสอนนายตั้งแต่พื้นฐาน", "mewla_anim": "talk", "sfx": "res://assets/audio/sfx_cat_meow.wav"},
		{"speaker": "มิวรา", "text": "ก่อนเข้าสู่บททดสอบของหอคอย\nนายต้องตรวจสอบว่าพลังเวทของตัวเองพร้อมใช้งานหรือยัง", "mewla_anim": "talk"},
		{"speaker": "มิวรา", "text": "มาเริ่มคาถาแรกกัน", "mewla_anim": "success"},
		{"speaker": "มิวรา", "text": "ร่ายคาถานี้ดู", "mewla_anim": "talk"},
		{"speaker": "มิวรา", "text": "git --version", "mewla_anim": "talk"},
		{"speaker": "เวล", "text": "แค่นี้เอง?", "emote": "question", "mewla_anim": "idle"},
		{"speaker": "มิวรา", "text": "ถ้าพลัง Git ถูกปลุกไว้แล้ว คาถานี้จะแสดงระดับพลังตอบกลับมาเอง ใช้สำหรับเช็กว่าพลัง Git พร้อมไหม", "mewla_anim": "talk"},
		{"speaker": "เวล", "text": "เข้าใจแล้ว", "mewla_anim": "idle"},
		{"type": "choice_menu", "menu": "part1_main"}
	])

func _start_part2_direct() -> void:
	fade_overlay.color = Color(0, 0, 0, 0)
	vel.position = Vector2(700, 680)
	vel.play("breathe")
	mewla.visible = true
	mewla.position = Vector2(1220, 680)
	mewla.scale = Vector2(4, 4)
	mewla.modulate = Color.WHITE
	mewla.play("idle")
	_open_dialogue_box()
	_start_part2()

func _start_part2() -> void:
	_load_sequence([
		{"speaker": "มิวรา", "text": "ดีมาก นายผ่านบททดสอบแรกแล้ว", "mewla_anim": "talk"},
		{"speaker": "เวล", "text": "ง่ายกว่าที่คิดนะ", "mewla_anim": "idle"},
		{"speaker": "มิวรา", "text": "เพราะนี่เป็นแค่จุดเริ่มต้น... ต่อไป นายต้องลงทะเบียนตัวตนของนักเวทกับสำนักเวทเสียก่อน", "mewla_anim": "talk"},
		{"speaker": "เวล", "text": "ทำไมต้องลงทะเบียนด้วย?", "emote": "question", "mewla_anim": "idle"},
		{"speaker": "มิวรา", "text": "เพราะต่อจากนี้นายจะได้เริ่มรวบรวมและจารึก 'เศษคัมภีร์' ลงในคัมภีร์เวทส่วนตัวของนาย", "mewla_anim": "talk"},
		{"speaker": "เวล", "text": "เศษคัมภีร์?", "emote": "question", "mewla_anim": "idle"},
		{"speaker": "มิวรา", "text": "เศษคัมภีร์คือชิ้นส่วนขององค์ความรู้ที่เคยอยู่ในคัมภีร์เวทต้นกำเนิด หลังจากคัมภีร์เวทต้นกำเนิดแตกสลาย เศษคัมภีร์เหล่านั้นก็กระจัดกระจายไปทั่วหอคอย", "mewla_anim": "talk"},
		{"speaker": "มิวรา", "text": "บางชิ้นอาจบันทึกความรู้พื้นฐาน บางชิ้นอาจบันทึกคาถาหรืออักขระสำคัญ และบางชิ้นอาจเป็นกุญแจสำคัญที่นำไปสู่ความจริงเกี่ยวกับการหายตัวไปของปรมาจารย์", "mewla_anim": "talk"},
		{"speaker": "มิวรา", "text": "แต่ทุกครั้งที่นายจารึกการเปลี่ยนแปลงลงในคัมภีร์เวทส่วนตัว สำนักเวทต้องรู้ก่อนว่าเจ้าของการจารึกคือใคร ไม่อย่างนั้นต่อให้จารึกเศษคัมภีร์ดีแค่ไหน ก็ไม่มีใครรู้ว่าใครเป็นคนจารึก", "mewla_anim": "talk"},
		{"speaker": "เวล", "text": "งั้นฉันต้องทำยังไง", "mewla_anim": "idle"},
		{"speaker": "มิวรา", "text": "ประกาศตัวตนของนายให้สำนักเวทรู้ซะ... มาเริ่มคาถาบทต่อไปกัน", "mewla_anim": "talk"},
		{"speaker": "มิวรา", "text": "ร่ายคาถานี้เพื่อประกาศนามของนาย:\ngit config --global user.name \"ชื่อของนาย\"", "mewla_anim": "talk"},
		{"speaker": "มิวรา", "text": "แล้วตามด้วยการผูกตราประทับวิญญาณ:\ngit config --global user.email \"อีเมลของนาย\"", "mewla_anim": "talk"},
		{"speaker": "เวล", "text": "คาถาสองบท?", "emote": "question", "mewla_anim": "idle"},
		{"speaker": "มิวรา", "text": "ใช่ บทแรกใช้ตั้งชื่อ บทที่สองใช้ผูกอีเมล", "mewla_anim": "talk"},
		{"speaker": "มิวรา", "text": "แต่ถ้านายอยากตรวจสอบว่าหอคอยจดจำชื่อนายไว้หรือยัง ให้ลองร่ายคาถาเดิมแต่ ไม่ต้องใส่ชื่อต่อท้าย ดูสิ (git config --global user.name)", "mewla_anim": "talk"},
		{"speaker": "เวล", "text": "แล้วถ้ายังไม่เคยลงทะเบียนล่ะ", "emote": "question", "mewla_anim": "idle"},
		{"speaker": "มิวรา", "text": "คาถาจะไม่ตอบกลับอะไรเลย... นั่นหมายความว่านายต้องรีบประกาศนามเดี๋ยวนี้!", "mewla_anim": "talk"},
		{"type": "choice_menu", "menu": "part2_main"}
	])

func _start_outro_direct() -> void:
	fade_overlay.color = Color(0, 0, 0, 0)
	vel.position = Vector2(700, 680)
	vel.play("breathe")
	mewla.visible = true
	mewla.position = Vector2(1220, 680)
	mewla.scale = Vector2(4, 4)
	mewla.modulate = Color.WHITE
	mewla.play("idle")
	_open_dialogue_box()
	_start_outro()

func _start_outro() -> void:
	_load_sequence([
		{"speaker": "มิวรา", "text": "ดีมาก ตอนนี้หอคอยรู้แล้วว่านายเป็นใคร", "mewla_anim": "talk"},
		{"speaker": "เวล", "text": "แปลว่าพร้อมสำหรับการจารึกแล้ว?", "emote": "question", "mewla_anim": "idle"},
		{"speaker": "มิวรา", "text": "เกือบ... ตัวตนของนักเวทน่ะพร้อมแล้ว", "mewla_anim": "talk"},
		{"speaker": "มิวรา", "text": "ต่อไป เราจะไปสร้าง 'คัมภีร์เวทส่วนตัว' เล่มแรกของนายกัน... ไปชั้นถัดไปกันเถอะ", "mewla_anim": "success"},
		{"speaker": "เวล", "text": "...ทำไมหอคอยถึงไม่มีลิฟต์บ้างเนอะ เหนื่อย", "mewla_anim": "idle"},
		{"speaker": "มิวรา", "text": "…นั้นสิ", "mewla_anim": "talk"},
		{"type": "outro_stairs"}
	])

func _open_dialogue_box() -> void:
	if is_transitioning:
		return
	dialogue_box.visible = true
	dialogue_box.modulate.a = 0.0
	
	var box_tween = create_tween()
	box_tween.tween_property(dialogue_box, "modulate:a", 1.0, 0.25)

func _load_sequence(seq: Array[Dictionary]) -> void:
	current_queue = seq
	queue_index = 0
	_show_current_queue_item()

func _show_current_queue_item() -> void:
	if queue_index >= current_queue.size():
		_finish_cutscene()
		return
		
	var item = current_queue[queue_index]
	
	if item.has("type"):
		var type = item["type"]
		if type == "choice_menu":
			_display_choice_menu(item["menu"])
			return
		elif type == "outro_stairs":
			_trigger_outro_stairs_walk()
			return
		elif type == "bad_ending":
			_trigger_bad_ending()
			return
			
	# รายการบทสนทนาปกติ
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
	dialogue_label.text = data["text"]
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
		
	# ไอคอน Emote
	var emote = data.get("emote", "")
	if emote == "question":
		_pop_question_mark()
	else:
		_hide_question_mark()
		
	# เสียง SFX
	var sfx_path = data.get("sfx", "")
	if sfx_path != "" and ResourceLoader.exists(sfx_path):
		var sfx = AudioStreamPlayer.new()
		sfx.stream = load(sfx_path)
		sfx.finished.connect(sfx.queue_free)
		add_child(sfx)
		sfx.play()
		
	# Typewriter effect
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
# CHOICE MENU IMPLEMENTATION (INSIDE DIALOGUE BOX)
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
	
	var prompt_title = "ตัวเลือกคำถาม"
	if menu_id == "part1_main":
		prompt_title = "ตัวเลือกคำถาม"
		active_choices = [
			{"text": "1. พลัง Git คืออะไร?", "id": "part1_git"},
			{"text": "2. มีอะไรต้องระวังเป็นพิเศษไหมตอนร่ายคาถา?", "id": "part1_warning"},
			{"text": "3. ฉันมาทำอะไรที่นี่?", "id": "part1_purpose"},
			{"text": "4. ฉันจะลองดู", "id": "part1_try"}
		]
	elif menu_id == "part1_purpose_sub":
		prompt_title = "นายมาที่นี่เพื่อตามหาใครหรือสิ่งใดหรือเปล่า?"
		active_choices = [
			{"text": "1. ใช่", "id": "purpose_yes"},
			{"text": "2. ไม่", "id": "purpose_no"}
		]
	elif menu_id == "part2_main":
		prompt_title = "คำถามให้ผู้เล่นเลือก (ส่วนที่ 2):"
		active_choices = [
			{"text": "1. ทำไมต้องมีชื่อกับอีเมล?", "id": "part2_name_email"},
			{"text": "2. มีอะไรต้องระวังตอนร่ายคาถา?", "id": "part2_warning"},
			{"text": "3. ฉันจะลองดู", "id": "part2_try"}
		]
		
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
		hover_sb.bg_color = Color(0.18, 0.12, 0.28, 0.55)
		hover_sb.corner_radius_top_left = 6
		hover_sb.corner_radius_top_right = 6
		hover_sb.corner_radius_bottom_left = 6
		hover_sb.corner_radius_bottom_right = 6
		hover_sb.content_margin_left = 10
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
	
	match choice_id:
		"part1_git":
			_load_sequence([
				{"speaker": "เวล", "text": "พลัง Git คืออะไรกันแน่?", "emote": "question", "mewla_anim": "idle"},
				{"speaker": "มิวรา", "text": "Git คือพลังที่ใช้บันทึกการเปลี่ยนแปลงของคัมภีร์เวทส่วนตัว", "mewla_anim": "talk"},
				{"speaker": "มิวรา", "text": "ทุกครั้งที่นายแก้ไขหรือจารึกอะไรลงไป Git จะจดจำร่องรอยเหล่านั้นเอาไว้", "mewla_anim": "talk"},
				{"speaker": "มิวรา", "text": "ต่อให้เวลาผ่านไป นายก็ยังย้อนกลับไปดูอดีตของคัมภีร์เวทส่วนตัวได้", "mewla_anim": "talk"},
				{"type": "choice_menu", "menu": "part1_main"}
			])
		"part1_warning":
			_load_sequence([
				{"speaker": "เวล", "text": "มีอะไรต้องระวังเป็นพิเศษไหม?", "emote": "question", "mewla_anim": "idle"},
				{"speaker": "มิวรา", "text": "มี", "mewla_anim": "talk"},
				{"speaker": "เวล", "text": "หืม?", "emote": "question", "mewla_anim": "idle"},
				{"speaker": "มิวรา", "text": "อักขระหน้าคำว่า version ต้องเป็นขีดคู่", "mewla_anim": "talk"},
				{"speaker": "มิวรา", "text": "--version ไม่ใช่ -version และ git --version ต้องเว้นวรรคระหว่าง git กับ --version ด้วย", "mewla_anim": "talk"},
				{"speaker": "มิวรา", "text": "ศิษย์ฝึกหัดหลายคนพลาดตรงนี้ อักขระเวทละเอียดกว่าที่คิด", "mewla_anim": "talk"},
				{"speaker": "มิวรา", "text": "ผิดเพียงตัวเดียว คาถาอาจไม่ตอบสนอง", "mewla_anim": "talk"},
				{"speaker": "เวล", "text": "เข้าใจแล้ว", "mewla_anim": "idle"},
				{"speaker": "มิวรา", "text": "ดี…ก่อนร่ายคาถา ตรวจสอบอักขระให้ครบทุกครั้ง", "mewla_anim": "talk"},
				{"type": "choice_menu", "menu": "part1_main"}
			])
		"part1_purpose":
			_load_sequence([
				{"speaker": "เวล", "text": "ฉันมาทำอะไรที่นี่กันแน่?", "emote": "question", "mewla_anim": "idle"},
				{"speaker": "มิวรา", "text": "ฉันจะไปรู้เหรอ", "mewla_anim": "talk"},
				{"speaker": "เวล", "text": "...", "mewla_anim": "idle"},
				{"speaker": "มิวรา", "text": "นายเดินเข้ามาเองนะ ถ้างั้นฉันถามกลับ", "mewla_anim": "talk"},
				{"speaker": "มิวรา", "text": "นายมาที่นี่เพื่อตามหาใครหรือสิ่งใดหรือเปล่า?", "mewla_anim": "talk"},
				{"type": "choice_menu", "menu": "part1_purpose_sub"}
			])
		"purpose_yes":
			_load_sequence([
				{"speaker": "มิวรา", "text": "ดี", "mewla_anim": "talk"},
				{"speaker": "มิวรา", "text": "งั้นฉันจะสอนนายให้ไปหาสิ่ง ๆ นั้นเอง", "mewla_anim": "talk"},
				{"speaker": "มิวรา", "text": "เริ่มจากคาถาบทแรกกัน", "mewla_anim": "success"},
				{"type": "choice_menu", "menu": "part1_main"}
			])
		"purpose_no":
			_load_sequence([
				{"speaker": "มิวรา", "text": "อ้าว…งั้นนายเข้าผิดหอคอยแล้ว", "mewla_anim": "talk"},
				{"speaker": "มิวรา", "text": "ทางออกอยู่ด้านหลัง ขอให้โชคดี", "mewla_anim": "talk"},
				{"type": "bad_ending"}
			])
		"part1_try":
			_load_sequence([
				{"speaker": "เวล", "text": "ฉันจะลองดู", "mewla_anim": "idle"}
			])
			# เมื่อคุยจบ "ฉันจะลองดู" -> สลับเข้าหน้าเกมเพลย์ Sandbox
			# ถ้าตั้งค่า preview ต่อเนื่องจะไป part 2
		"part2_name_email":
			_load_sequence([
				{"speaker": "เวล", "text": "ทำไมต้องมีทั้งชื่อและอีเมลด้วย?", "emote": "question", "mewla_anim": "idle"},
				{"speaker": "มิวรา", "text": "เพราะทุกการจารึกต้องระบุว่าเป็นผลงานของนักเวทคนไหน", "mewla_anim": "talk"},
				{"speaker": "มิวรา", "text": "ชื่อใช้แสดงตัวตน", "mewla_anim": "talk"},
				{"speaker": "มิวรา", "text": "ส่วนอีเมลใช้เชื่อมข้อมูลการจารึกเข้ากับตัวตนของนาย", "mewla_anim": "talk"},
				{"speaker": "มิวรา", "text": "เมื่อย้อนดูประวัติของคัมภีร์เวทส่วนตัว นายจะรู้ได้ว่าใครเป็นคนจารึกสิ่งนั้น", "mewla_anim": "talk"},
				{"type": "choice_menu", "menu": "part2_main"}
			])
		"part2_warning":
			_load_sequence([
				{"speaker": "เวล", "text": "มีอะไรต้องระวังไหม?", "emote": "question", "mewla_anim": "idle"},
				{"speaker": "มิวรา", "text": "มี", "mewla_anim": "talk"},
				{"speaker": "มิวรา", "text": "อักขระ --global ต้องเป็นขีดคู่", "mewla_anim": "talk"},
				{"speaker": "มิวรา", "text": "และต้องเว้นวรรคระหว่าง git, config, --global และคำสั่งที่ตามมา", "mewla_anim": "talk"},
				{"speaker": "มิวรา", "text": "ถ้าอักขระผิด คาถาอาจไม่ทำงานตามที่ตั้งใจ", "mewla_anim": "talk"},
				{"speaker": "เวล", "text": "เข้าใจแล้ว", "mewla_anim": "idle"},
				{"speaker": "มิวรา", "text": "ดี…นักเวทที่ร่ายคาถาแม่น มักเริ่มจากการพิมพ์ให้แม่นก่อน", "mewla_anim": "talk"},
				{"type": "choice_menu", "menu": "part2_main"}
			])
		"part2_try":
			_load_sequence([
				{"speaker": "เวล", "text": "ฉันจะลองดู", "mewla_anim": "idle"}
			])

# ==============================================================================
# OUTRO STAIRS TRANSITION & BAD ENDING
# ==============================================================================

func _trigger_outro_stairs_walk() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	is_dialogue_active = false
	_hide_continue_arrow()
	
	# ปิดกล่องข้อความ
	var tw_close = create_tween()
	tw_close.tween_property(dialogue_box, "modulate:a", 0.0, 0.3)
	tw_close.tween_callback(func(): dialogue_box.visible = false)
	
	# เวลเริ่มเดินผ่านหน้ามิวราไปทางขวา (700 -> 1500)
	vel.play("walk")
	var walk_past = create_tween()
	walk_past.tween_property(vel, "position:x", 1500.0, 3.2).set_trans(Tween.TRANS_LINEAR)
	
	walk_past.tween_callback(func():
		# เฟดจอดำเข้าสู่ฉากบันได
		var fade_black = create_tween()
		fade_black.tween_property(fade_overlay, "color:a", 1.0, 0.6)
		fade_black.tween_callback(func():
			_show_stairs_climb_scene()
		)
	)

func _show_stairs_climb_scene() -> void:
	# ซ่อนมิวรา และเปลี่ยนฉากหลังเป็นบันไดหินกลางหอคอย
	mewla.visible = false
	if ResourceLoader.exists("res://assets/cutscene/backgrounds/central-tower-Sheet.png"):
		background.texture = load("res://assets/cutscene/backgrounds/central-tower-Sheet.png")
		
	# วางเวลที่ฐานบันไดกลางหอคอย
	vel.position = Vector2(960, 750)
	if ResourceLoader.exists("res://assets/cutscene/characters/vel/vel_back.png"):
		var tex_back = load("res://assets/cutscene/characters/vel/vel_back.png")
		vel.sprite_frames.add_frame("back", tex_back)
		vel.play("back")
	else:
		vel.play("walk")
		
	# เฟดสว่างเข้ามา
	var fade_in = create_tween()
	fade_in.tween_property(fade_overlay, "color:a", 0.0, 0.6)
	
	# เวลเดินก้าวขึ้นบันได 2 ขั้น (ขยับ Y ขึ้นทีละขั้น)
	fade_in.tween_interval(0.3)
	var climb = create_tween()
	# ขั้นที่ 1
	climb.tween_property(vel, "position:y", 715.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	climb.tween_interval(0.2)
	# ขั้นที่ 2
	climb.tween_property(vel, "position:y", 680.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	climb.tween_callback(func():
		# แสดงป้ายผ่านด่านที่ 1
		_show_level_cleared_banner()
	)

func _show_level_cleared_banner() -> void:
	var banner = Label.new()
	banner.text = "ผ่านด่านที่ 1: ตรวจสอบพลังและประกาศนาม สำเร็จ!"
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
	exclamation_tween.chain().tween_property(exclamation_mark, "position:y", -42.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _hide_exclamation() -> void:
	if exclamation_tween and exclamation_tween.is_valid():
		exclamation_tween.kill()
	if is_instance_valid(exclamation_mark) and exclamation_mark.visible:
		var tw = create_tween()
		tw.tween_property(exclamation_mark, "scale", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(exclamation_mark, "modulate:a", 0.0, 0.15)
		tw.tween_callback(func():
			exclamation_mark.visible = false
			exclamation_mark.scale = Vector2.ZERO
			exclamation_mark.position = Vector2(0, -42)
		)

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

func _finish_cutscene() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	is_dialogue_active = false
	
	_hide_continue_arrow()
	_hide_question_mark()
	_hide_exclamation()
	
	var finish_tween = create_tween()
	finish_tween.tween_property(fade_overlay, "color:a", 1.0, 0.6)
	finish_tween.tween_callback(func():
		Engine.time_scale = 1.0
		if next_scene_path != "" and ResourceLoader.exists(next_scene_path):
			get_tree().change_scene_to_file(next_scene_path)
		else:
			push_warning("[InsideTowerCutscene] next_scene_path not found: '%s'" % next_scene_path)
			var tw_recover = create_tween()
			tw_recover.tween_property(fade_overlay, "color:a", 0.0, 0.5)
			is_transitioning = false
			is_dialogue_active = true
	)
