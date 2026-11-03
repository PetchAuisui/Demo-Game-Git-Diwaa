extends Node2D

## การควบคุมฉากคัตซีนเปิดตัวหอคอยเวทกลาง (Central Tower Intro Cutscene)
## ลำดับเหตุการณ์:
## 1. เฟดเข้าจากจอดำสู่ห้องโถงหอคอยเวทกลาง (central-tower-Sheet)
## 2. เวล (ฝั่งซ้าย) เดินเข้ามาในห้องโถง และพบกับผู้พิทักษ์ (ฝั่งขวา)
## 3. เริ่มต้นบทสนทนา: ผู้พิทักษ์ทักทาย -> เวลรายงานตัว -> ผู้พิทักษ์อธิบายธรรมเนียม GitHub Flow
## 4. ผู้เล่นคลิกหน้าจอ หรือกด Space / Enter เพื่ออ่านบทสนทนาทีละประโยค (มี Typewriter Effect)
## 5. เมื่อคุยจบครบทุกประโยค หรือผู้เล่นกดปุ่มข้าม (Skip / Esc) -> เฟดจอดำและสลับเข้าสู่ด่านที่ 16 (SandboxGameView)

@export var next_scene_path: String = "res://features/sandbox/sandbox_game_view.tscn"

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
@onready var guardian: AnimatedSprite2D = $Stage/Guardian

# UI Elements
@onready var magic_ui: CanvasLayer = $MagicStoryUI
@onready var dialogue_box: PanelContainer = $MagicStoryUI/DialogueBox
@onready var speaker_label: Label = $MagicStoryUI/DialogueBox/Margin/VBox/SpeakerLabel
@onready var dialogue_label: Label = $MagicStoryUI/DialogueBox/Margin/VBox/DialogueLabel
@onready var continue_arrow: TextureRect = $MagicStoryUI/DialogueBox/ArrowOverlay/ArrowWrapper/ContinueArrow


# ลำดับท่าทางวนลูป (Sequence Loops)
# ผู้พิทักษ์ขณะพูด: talk -> talk_blink -> talk -> talk -> talk_blink
const GUARDIAN_TALK_SEQ: Array[String] = ["talk", "talk_blink", "talk", "talk", "talk_blink"]

# ผู้พิทักษ์ขณะไม่ได้พูด (ฟัง/รอ): breathe -> breathe_blink -> breathe -> breathe -> breathe_blink
const GUARDIAN_IDLE_SEQ: Array[String] = ["breathe", "breathe_blink", "breathe", "breathe", "breathe_blink"]

# เวล (ท่าปกติวนลูป): breathe -> breathe_blink -> breathe -> breathe -> breathe_blink
const VEL_IDLE_SEQ: Array[String] = ["breathe", "breathe_blink", "breathe", "breathe", "breathe_blink"]

# สถานะลำดับแอนิเมชันของตัวละคร
var is_guardian_speaking: bool = false
var guardian_seq_step: int = 0
var vel_seq_step: int = 0
var vel_custom_anim: String = ""

# Dialogue Script Data (บทสนทนาประจำฉาก - รูปแบบเดิม 16 บท)
const DIALOGUES: Array[Dictionary] = [
	{
		"speaker": "ผู้พิทักษ์",
		"text": "มาถึงแล้วสินะ ศิษย์ฝึกหัด"
	},
	{
		"speaker": "เวล",
		"text": "ท่านคือ..."
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "ข้าคือผู้พิทักษ์คลังเวทกลาง ดูแลบันทึกและความรู้ของจอมเวททุกคนในอาณาจักร\nนายมาที่นี่เพื่อตามหาเศษคัมภีร์ที่เหลือ ใช่ไหม"
	},
	{
		"speaker": "เวล",
		"text": "ใช่ครับ"
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "ดี แต่ก่อนจะไปมากกว่านี้ ข้าอยากให้เจ้าได้เรียนรู้การใช้พลัง Git ของเราในการจารึกร่วมกับผู้อื่น"
	},
	{
		"speaker": "เวล",
		"text": "กฎเหรอครับ?",
		"emote": "question"
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "ไม่ใช่หรอก มันเรียกว่าธรรมเนียมมากกว่า โดยส่วนมากธรรมเนียมเป็นไปตามกำหนดจากเจ้าของคัมภีร์"
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "เพราะงั้นนี่คือ..."
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "'GitHub\u00A0Flow' ธรรมเนียมที่คลังเวทกลางแห่งนี้ใช้กันมาตลอด"
	},
	{
		"speaker": "เวล",
		"text": "GitHub\u00A0Flow?",
		"emote": "question"
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "ใช่ ความจริงแล้วในหมู่จอมเวททั่วอาณาจักร มีธรรมเนียมการทำงานร่วมกันอยู่หลายแบบ\nบ้างก็ใช้ 'Git\u00A0Flow' ที่ซับซ้อนกว่า มีเส้นทางแยกย่อยหลายสาย บางคลังก็ใช้แบบอื่นไปเลยก็มี"
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "แต่ที่นี่ เราเลือกใช้ 'GitHub\u00A0Flow' เพราะเรียบง่าย เหมาะกับจอมเวทที่หมุนเวียนงานกันเร็ว ๆ"
	},
	{
		"speaker": "เวล",
		"text": "แล้วมันทำงานยังไงครับ",
		"emote": "question"
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "หลักการง่ายมาก มีเส้นทางหลักอยู่เส้นเดียวคือ main ห้ามใครแก้ไขมันตรง ๆ เด็ดขาด"
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "ทุกครั้งที่จะเริ่มงานใหม่ ไม่ว่าเล็กหรือใหญ่ ต้องแยกเส้นทางจารึกใหม่ออกมาก่อนเสมอ"
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "ทำงานเสร็จ ทดสอบจนมั่นใจ ก็ยื่นคำขอบันทึกคัมภีร์กลับเข้า main แล้วให้จอมเวทคนอื่นตรวจสอบก่อนรวม"
	}
]

var current_dialogue_index: int = 0
var is_dialogue_active: bool = false
var is_typing: bool = false
var is_transitioning: bool = false
var typewriter_tween: Tween = null
var exclamation_tween: Tween = null
var question_tween: Tween = null
var arrow_tween: Tween = null
var entrance_tween: Tween = null

func _ready() -> void:
	Engine.time_scale = 1.0
	_init_scene_state()
	_play_entrance_sequence()

func _input(event: InputEvent) -> void:
	if is_transitioning:
		return
		
	# กด Esc เพื่อข้ามคัตซีน
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_skip_cutscene()
		return
		
	# ป้องกันการคลิกโดนปุ่มควบคุม (FF / Skip) ถูกกลืนเป็นการกดอ่านต่อ
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered is BaseButton:
		return
		
	# คลิกหรือกด Space/Enter เพื่อไปต่อ
	if is_dialogue_active:
		var wants_advance: bool = false
		if event.is_action_pressed("ui_accept"):
			wants_advance = true
		elif event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			wants_advance = true
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			wants_advance = true
				
		if wants_advance:
			get_viewport().set_input_as_handled()
			_on_player_advance()

func _init_scene_state() -> void:
	# ตั้งค่ากล้อง
	camera.position = Vector2(960, 540)
	camera.zoom = Vector2.ONE
	
	# เตรียมตัวละคร:
	# เวลเกิดจากนอกจอทางซ้าย (spawn_x = -120) ที่ระดับความสูงพื้นสมดุล y = 750 (เท้าแตะพื้น 904)
	vel.position = Vector2(-120, 750)
	vel.scale = Vector2(4.0, 4.0)
	vel.play("walk")
	
	# ผู้พิทักษ์ยืนฝั่งขวา สมมาตรกับตำแหน่งเป้าหมายของเวล (x = 1220, y = 750) ห่างจากกึ่งกลาง 960 เท่ากัน 260px
	guardian.position = Vector2(1220, 750)
	guardian.scale = Vector2(4.0, 4.0)
	guardian.flip_h = true
	guardian.play("breathe")
	guardian.animation_finished.connect(_on_guardian_animation_finished)
	vel.animation_finished.connect(_on_vel_animation_finished)
	
	exclamation_mark.visible = false
	exclamation_mark.scale = Vector2.ZERO
	exclamation_mark.position = Vector2(0, -60)
	
	question_mark.visible = false
	question_mark.scale = Vector2.ZERO
	question_mark.position = Vector2(0, -36)
	
	# ซ่อนกล่องข้อความไว้ก่อน
	dialogue_box.visible = false
	dialogue_box.modulate = Color(1, 1, 1, 0)
	_hide_continue_arrow()
	
	# ระบบควบคุม Cutscene: ปุ่มเร่งความเร็ว (FF 2.5x) และปุ่มข้าม (Skip / Esc)
	var skip_ctrl = preload("res://features/cutscene/skip_cutscene_button.gd").new()
	skip_ctrl.next_scene_path = next_scene_path
	skip_ctrl.custom_skip_action = _skip_cutscene
	add_child(skip_ctrl)
	
	# หน้าจอมืดไว้สำหรับเฟดเข้า
	fade_overlay.visible = true
	fade_overlay.color = Color(0, 0, 0, 1.0)
	
	# เริ่มเล่นอนิเมชันของฉาก (วนลูปต่อเนื่อง)
	if anim_player and not anim_player.is_playing():
		anim_player.play("background_loop")

func _exit_tree() -> void:
	Engine.time_scale = 1.0


## -------------------------------------------------------------
## Sequence: เดินเข้าฉากเปิดตัว (ก้าวขาเดินมาจากนอกจอสู่ชั้นใหม่)
## -------------------------------------------------------------
func _play_entrance_sequence() -> void:
	if entrance_tween and entrance_tween.is_valid():
		entrance_tween.kill()
		
	# 1. เฟดสว่างเปิดฉาก (0.8 วินาที)
	var tw_fade_in = create_tween()
	tw_fade_in.tween_property(fade_overlay, "color:a", 0.0, 0.8)
	
	# 2. เวลเดินจากนอกจอซ้าย (-120 -> 700) ข้ามระยะทาง 820px ใน 3.6 วินาที (Linear ~228 px/s ครบ 2 ลูปเดิน 1.8s x 2 พอดี)
	entrance_tween = create_tween()
	entrance_tween.tween_property(vel, "position:x", 700.0, 3.6).set_trans(Tween.TRANS_LINEAR)
	entrance_tween.tween_callback(func():
		# รีเซ็ตและซิงค์จังหวะหายใจให้เวลและผู้พิทักษ์เริ่มต้นพร้อมกันเป๊ะๆ
		vel_seq_step = 0
		guardian_seq_step = 0
		vel.play("breathe")
		vel.set_frame_and_progress(0, 0.0)
		guardian.play("breathe")
		guardian.set_frame_and_progress(0, 0.0)
		# หน่วงเวลาหยุดยืนนิ่ง 1.0s ให้ตัวละครยืนหายใจปกติและตั้งสติก่อนเริ่มบทสนทนาแรก
		var tw_wait = create_tween()
		tw_wait.tween_interval(1.0)
		tw_wait.tween_callback(_start_dialogue_sequence)
	)

## -------------------------------------------------------------
## Sequence: ควบคุมบทสนทนาและท่าทางตัวละคร
## -------------------------------------------------------------
func _start_dialogue_sequence() -> void:
	current_dialogue_index = 0
	dialogue_box.visible = true
	
	# เด้งกล่องข้อความขึ้นมา
	var tw_box = create_tween().set_parallel(true)
	tw_box.tween_property(dialogue_box, "modulate:a", 1.0, 0.25)
	tw_box.tween_property(dialogue_box, "scale", Vector2.ONE, 0.25).from(Vector2(0.96, 0.96)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	_show_current_dialogue()

func _on_guardian_animation_finished() -> void:
	var seq = GUARDIAN_TALK_SEQ if is_guardian_speaking else GUARDIAN_IDLE_SEQ
	guardian_seq_step = (guardian_seq_step + 1) % seq.size()
	guardian.play(seq[guardian_seq_step])

func _on_vel_animation_finished() -> void:
	if vel_custom_anim != "":
		return
	vel_seq_step = (vel_seq_step + 1) % VEL_IDLE_SEQ.size()
	vel.play(VEL_IDLE_SEQ[vel_seq_step])

func _update_character_postures(speaker: String, vel_override: String = "") -> void:
	# 1. จัดการผู้พิทักษ์ (พูด vs ฟัง)
	var should_guardian_speak = (speaker == "ผู้พิทักษ์")
	if is_guardian_speaking != should_guardian_speak:
		is_guardian_speaking = should_guardian_speak
		if is_guardian_speaking:
			# เมื่อผู้พิทักษ์เริ่มพูด ให้จังหวะขยับตัวและหายใจซิงค์ตรงกับเวลต่อเนื่อง
			guardian_seq_step = vel_seq_step
			var anim_to_play = GUARDIAN_TALK_SEQ[guardian_seq_step]
			guardian.play(anim_to_play)
			guardian.set_frame_and_progress(vel.frame, vel.frame_progress)
		else:
			# เมื่อผู้พิทักษ์หยุดพูด ให้ซิงค์จังหวะหายใจกลับมาตรงกับเวลทันที
			guardian_seq_step = vel_seq_step
			var anim_to_play = vel.animation if (vel.animation in GUARDIAN_IDLE_SEQ) else GUARDIAN_IDLE_SEQ[guardian_seq_step]
			guardian.play(anim_to_play)
			guardian.set_frame_and_progress(vel.frame, vel.frame_progress)

	# 2. จัดการเวล (ลูป breathe ตลอดเวลา เว้นแต่จะมีท่าพิเศษ override)
	if vel_override != "":
		vel_custom_anim = vel_override
		vel.play(vel_override)
	else:
		if vel_custom_anim != "":
			vel_custom_anim = ""
			# เมื่อเวลหมดท่าพิเศษ ให้ซิงค์จังหวะหายใจกลับมาตรงกับผู้พิทักษ์
			vel_seq_step = guardian_seq_step
			var anim_to_play = guardian.animation if (guardian.animation in VEL_IDLE_SEQ) else VEL_IDLE_SEQ[vel_seq_step]
			vel.play(anim_to_play)
			vel.set_frame_and_progress(guardian.frame, guardian.frame_progress)
		elif vel.animation not in VEL_IDLE_SEQ:
			vel_seq_step = guardian_seq_step
			vel.play(VEL_IDLE_SEQ[vel_seq_step])
			vel.set_frame_and_progress(guardian.frame, guardian.frame_progress)

func _show_current_dialogue() -> void:
	if current_dialogue_index >= DIALOGUES.size():
		_finish_cutscene()
		return
		
	var data = DIALOGUES[current_dialogue_index]
	is_dialogue_active = true
	is_typing = true
	_hide_continue_arrow()
	
	speaker_label.text = data["speaker"]
	if data["speaker"] == "ผู้พิทักษ์":
		speaker_label.add_theme_color_override("font_color", Color(0.92, 0.80, 0.44, 1.0)) # สีทองอบอุ่น
	else:
		speaker_label.add_theme_color_override("font_color", Color(0.45, 0.75, 0.95, 1.0)) # สีฟ้าอ่อนสดใส (เวล / ผู้เล่น)
	dialogue_label.text = data["text"]
	dialogue_label.visible_ratio = 0.0
	
	# อัปเดตท่าทางตัวละคร (อิงสถานะ ไม่รีสตาร์ทเฟรมใหม่ทุกครั้งที่กดข้อความ)
	var vel_override = data.get("vel_anim_override", "")
	_update_character_postures(data["speaker"], vel_override)
		
	# ไอคอนตกใจ (!) หรือสงสัย (?)
	var emote = data.get("emote", "")
	if emote == "question":
		_hide_exclamation()
		_pop_question_mark()
	elif emote == "exclamation" or data.get("exclamation", false):
		_hide_question_mark()
		_pop_exclamation()
	else:
		_hide_question_mark()
		_hide_exclamation()
		
	# Typewriter effect
	if typewriter_tween and typewriter_tween.is_valid():
		typewriter_tween.kill()
		
	var duration: float = clampf(float(data["text"].length()) * 0.03, 0.35, 1.4)
	typewriter_tween = create_tween()
	typewriter_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)
	typewriter_tween.tween_callback(func():
		is_typing = false
		_show_continue_arrow()
	)

func _on_player_advance() -> void:
	if is_typing:
		# ถ้ากำลังพิมพ์อยู่ ให้เร่งแสดงผลข้อความเต็มทันที
		if typewriter_tween and typewriter_tween.is_valid():
			typewriter_tween.kill()
		dialogue_label.visible_ratio = 1.0
		is_typing = false
		_show_continue_arrow()
	else:
		# ถ้าข้อความขึ้นครบแล้ว ให้ไปประโยคถัดไป
		current_dialogue_index += 1
		_show_current_dialogue()

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

func _pop_question_mark() -> void:
	if question_tween and question_tween.is_valid():
		question_tween.kill()
	question_mark.visible = true
	question_mark.scale = Vector2.ZERO
	question_mark.position = Vector2(0, -36)
	
	# 1. จังหวะเด้งขยายขึ้นมาอย่างเห็นชัด (0.22s ด้วย TRANS_BACK)
	var tw_pop = create_tween()
	tw_pop.tween_property(question_mark, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_pop.tween_callback(func():
		if not is_instance_valid(question_mark) or not question_mark.visible:
			return
		# 2. ค้างไว้บนจอพร้อมลอยเด้งดึ๋งเบาๆ ขึ้นลงต่อเนื่อง (Idle Bobbing) ตราบใดที่ยังอยู่ในบทสนทนานี้
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

func _pop_exclamation() -> void:
	if exclamation_tween and exclamation_tween.is_valid():
		exclamation_tween.kill()
	exclamation_mark.visible = true
	exclamation_mark.scale = Vector2.ZERO
	exclamation_mark.modulate.a = 1.0
	exclamation_mark.position = Vector2(0, -60)
	
	exclamation_tween = create_tween()
	# 1. เด้งขึ้นมาอย่างเห็นชัด
	exclamation_tween.tween_property(exclamation_mark, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 2. ค้างไว้พอดีคำ (~1.6s)
	exclamation_tween.tween_interval(1.6)
	# 3. ลอยขึ้นและค่อยๆ จางหายไป (0.4s)
	var tw_fade = exclamation_tween.parallel()
	tw_fade.tween_property(exclamation_mark, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw_fade.tween_property(exclamation_mark, "position:y", -68.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	exclamation_tween.tween_callback(func():
		exclamation_mark.visible = false
	)

func _hide_exclamation() -> void:
	if exclamation_tween and exclamation_tween.is_valid():
		exclamation_tween.kill()
	if is_instance_valid(exclamation_mark):
		exclamation_mark.visible = false
		exclamation_mark.scale = Vector2.ZERO
		exclamation_mark.modulate.a = 1.0
		exclamation_mark.position = Vector2(0, -60)

## -------------------------------------------------------------
## การเปลี่ยนผ่านและจบฉาก
## -------------------------------------------------------------
func _finish_cutscene() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	is_dialogue_active = false
	_hide_continue_arrow()
	_hide_question_mark()
	_hide_exclamation()
	
	# ซ่อนกล่องข้อความ
	var tw_box = create_tween()
	tw_box.tween_property(dialogue_box, "modulate:a", 0.0, 0.2)
	
	# เฟดจอดำ และเปลี่ยนซีน
	var tw_fade_out = create_tween()
	tw_fade_out.tween_property(fade_overlay, "color:a", 1.0, 0.6)
	tw_fade_out.tween_callback(func():
		_switch_to_gameplay()
	)

func _skip_cutscene() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	if entrance_tween and entrance_tween.is_valid():
		entrance_tween.kill()
	_hide_continue_arrow()
	_hide_question_mark()
	_hide_exclamation()
	_switch_to_gameplay()

func _switch_to_gameplay() -> void:
	Engine.time_scale = 1.0
	if next_scene_path != "" and ResourceLoader.exists(next_scene_path):
		get_tree().change_scene_to_file(next_scene_path)
	else:
		push_warning("[CentralTowerCutscene] next_scene_path not found: '%s'" % next_scene_path)
