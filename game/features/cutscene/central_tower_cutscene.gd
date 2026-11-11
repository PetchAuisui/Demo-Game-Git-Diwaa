extends Node2D

## การควบคุมฉากคัตซีนเปิดตัวหอคอยเวทกลาง (Central Tower Intro Cutscene)
## ลำดับเหตุการณ์:
## 1. เฟดเข้าจากจอดำสู่ห้องโถงหอคอยเวทกลาง (central-tower-Sheet)
## 2. เวล (ฝั่งซ้าย) เดินเข้ามาในห้องโถง และพบกับผู้พิทักษ์ (ฝั่งขวา)
## 3. เริ่มต้นบทสนทนา: ผู้พิทักษ์ทักทาย -> เวลรายงานตัว -> ผู้พิทักษ์อธิบายธรรมเนียม GitHub Flow
## 4. ผู้เล่นคลิกหน้าจอ หรือกด Space / Enter / Right Arrow (→) เพื่ออ่านต่อ และ Left Arrow (←) / Backspace เพื่อย้อนกลับ (มี Typewriter Effect)
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
@onready var arrow_wrapper: Control = $MagicStoryUI/DialogueBox/ArrowOverlay/ArrowWrapper
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
var is_fast_forwarding: bool = false
var skip_ctrl = null
var typewriter_tween: Tween = null
var exclamation_tween: Tween = null
var question_tween: Tween = null
var arrow_tween: Tween = null
var entrance_tween: Tween = null

# Navigation Arrows (◀ ▶)
var nav_arrows_container: HBoxContainer = null
var btn_arrow_back: TextureButton = null
var btn_arrow_next: TextureButton = null
var press_tween_back: Tween = null
var press_tween_next: Tween = null

static var _cached_arrow_left_tex: ImageTexture = null
static var _cached_arrow_right_tex: ImageTexture = null

func _ready() -> void:
	Engine.time_scale = 1.0
	SceneLoader.request_preload(next_scene_path)
	_init_scene_state()
	_play_entrance_sequence()

func _process(_delta: float) -> void:
	if is_transitioning:
		if is_fast_forwarding:
			is_fast_forwarding = false
			Engine.time_scale = 1.0
		return
	
	var is_btn_active: bool = (skip_ctrl != null and skip_ctrl.is_fast_forward)
	var wants_hold: bool = Input.is_key_pressed(KEY_SHIFT)
	
	var active: bool = is_btn_active or wants_hold
	if active != is_fast_forwarding:
		is_fast_forwarding = active
		Engine.time_scale = 2.5 if active else 1.0
		if skip_ctrl and not is_btn_active:
			skip_ctrl._apply_ff_style(active)

func _input(event: InputEvent) -> void:
	if is_transitioning:
		return
	
	# กดปุ่ม Left Arrow หรือ Backspace เพื่อย้อนกลับข้อความ (พร้อมเอฟเฟกต์ปุ่มยุบและสว่างขาว)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_LEFT or event.keycode == KEY_BACKSPACE:
			if is_dialogue_active and _can_go_back():
				get_viewport().set_input_as_handled()
				_animate_button_press(btn_arrow_back)
				_on_player_back()
				return
	
	# คลิกหรือกด Space/Enter/Right Arrow เพื่อไปต่อ (พร้อมเอฟเฟกต์ปุ่มยุบและสว่างขาว)
	if is_dialogue_active:
		var wants_advance: bool = false
		if event.is_action_pressed("ui_accept"):
			wants_advance = true
		elif event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_RIGHT):
			wants_advance = true
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# ป้องกันการคลิกโดนปุ่มควบคุม (FF / Skip / ลูกศร ◀ ▶) ถูกกลืนเป็นการกดอ่านต่อ
			var hovered := get_viewport().gui_get_hovered_control()
			if not (hovered is BaseButton):
				wants_advance = true
		
		if wants_advance:
			get_viewport().set_input_as_handled()
			_animate_button_press(btn_arrow_next)
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
	
	# ซ่อนกล่องข้อความไว้ก่อน และสร้างปุ่มลูกศร ◀ ▶
	dialogue_box.visible = false
	dialogue_box.modulate = Color(1, 1, 1, 0)
	_create_nav_arrows()
	_hide_continue_arrow()
	
	# ระบบควบคุม Cutscene: ปุ่มเร่งความเร็ว (FF 2.5x) และปุ่มข้าม (Skip / Esc)
	skip_ctrl = preload("res://features/cutscene/skip_cutscene_button.gd").new()
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
	if press_tween_back and press_tween_back.is_valid():
		press_tween_back.kill()
	if press_tween_next and press_tween_next.is_valid():
		press_tween_next.kill()


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

func _show_current_dialogue(skip_typewriter: bool = false) -> void:
	if current_dialogue_index >= DIALOGUES.size():
		_finish_cutscene()
		return
	
	var data = DIALOGUES[current_dialogue_index]
	is_dialogue_active = true
	
	speaker_label.text = data["speaker"]
	if data["speaker"] == "ผู้พิทักษ์":
		speaker_label.add_theme_color_override("font_color", Color(0.92, 0.80, 0.44, 1.0)) # สีทองอบอุ่น
	else:
		speaker_label.add_theme_color_override("font_color", Color(0.45, 0.75, 0.95, 1.0)) # สีฟ้าอ่อนสดใส (เวล / ผู้เล่น)
	dialogue_label.text = data["text"]
	
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
	
	if skip_typewriter:
		dialogue_label.visible_ratio = 1.0
		is_typing = false
		_show_continue_arrow()
		return
	
	dialogue_label.visible_ratio = 0.0
	is_typing = true
	_hide_continue_arrow()
	
	var duration: float = clampf(float(data["text"].length()) * 0.03, 0.35, 1.4)
	typewriter_tween = create_tween()
	typewriter_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)
	typewriter_tween.tween_callback(func():
		is_typing = false
		_show_continue_arrow()
	)

func _on_player_advance() -> void:
	if not is_dialogue_active:
		return
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

func _can_go_back() -> bool:
	if not is_instance_valid(dialogue_box) or not dialogue_box.visible:
		return false
	if is_transitioning or not is_dialogue_active:
		return false
	return current_dialogue_index > 0

func _on_player_back() -> void:
	if not _can_go_back():
		return
	if typewriter_tween and typewriter_tween.is_valid():
		typewriter_tween.kill()
	current_dialogue_index -= 1
	_show_current_dialogue(true)

func _show_continue_arrow() -> void:
	if arrow_tween and arrow_tween.is_valid():
		arrow_tween.kill()
	if is_instance_valid(continue_arrow):
		continue_arrow.visible = false
	if is_instance_valid(arrow_wrapper):
		arrow_wrapper.visible = false
	_update_nav_arrows()

func _hide_continue_arrow() -> void:
	if arrow_tween and arrow_tween.is_valid():
		arrow_tween.kill()
	if is_instance_valid(continue_arrow):
		continue_arrow.visible = false
		continue_arrow.position.y = 0.0
	if is_instance_valid(arrow_wrapper):
		arrow_wrapper.visible = false
	_update_nav_arrows()

# ==============================================================================
# NAVIGATION ARROWS SYSTEM (ลูกศร ◀ ▶ ข้างกัน)
# ==============================================================================

static func _get_nav_arrow_texture(is_left: bool) -> ImageTexture:
	if is_left and _cached_arrow_left_tex != null:
		return _cached_arrow_left_tex
	if not is_left and _cached_arrow_right_tex != null:
		return _cached_arrow_right_tex
	
	var arrow_stream = load("res://assets/cutscene/frame dialog text/arrow.png")
	if not arrow_stream:
		return null
	var img: Image = arrow_stream.get_image()
	if not img:
		return null
	var cropped: Image = img.get_region(Rect2i(561, 344, 537, 334))
	
	if is_left:
		var img_left = cropped.duplicate()
		img_left.rotate_90(CLOCKWISE)
		_cached_arrow_left_tex = ImageTexture.create_from_image(img_left)
		return _cached_arrow_left_tex
	else:
		var img_right = cropped.duplicate()
		img_right.rotate_90(COUNTERCLOCKWISE)
		_cached_arrow_right_tex = ImageTexture.create_from_image(img_right)
		return _cached_arrow_right_tex

func _create_nav_arrows() -> void:
	if nav_arrows_container != null and is_instance_valid(nav_arrows_container):
		return
	
	var arrow_overlay = dialogue_box.get_node_or_null("ArrowOverlay")
	if not arrow_overlay:
		return
	
	# ปรับระยะขอบขวาของ Margin เพื่อป้องกันข้อความยาวทับลูกศร ◀ ▶
	var margin_node = dialogue_box.get_node_or_null("Margin")
	if margin_node:
		margin_node.add_theme_constant_override("margin_right", 96)
	
	# ซ่อนลูกศรเดี่ยวเดิม
	if arrow_wrapper:
		arrow_wrapper.visible = false
	if continue_arrow:
		continue_arrow.visible = false
	
	nav_arrows_container = HBoxContainer.new()
	nav_arrows_container.name = "NavArrowsContainer"
	nav_arrows_container.layout_mode = 1
	nav_arrows_container.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	nav_arrows_container.anchor_left = 1.0
	nav_arrows_container.anchor_right = 1.0
	nav_arrows_container.anchor_top = 1.0
	nav_arrows_container.anchor_bottom = 1.0
	nav_arrows_container.offset_left = -78.0
	nav_arrows_container.offset_top = -42.0
	nav_arrows_container.offset_right = -24.0
	nav_arrows_container.offset_bottom = -16.0
	nav_arrows_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	nav_arrows_container.grow_vertical = Control.GROW_DIRECTION_BEGIN
	nav_arrows_container.alignment = BoxContainer.ALIGNMENT_END
	nav_arrows_container.add_theme_constant_override("separation", 12)
	
	# 1. ปุ่มลูกศรซ้าย ◀ (ย้อนกลับ)
	btn_arrow_back = TextureButton.new()
	btn_arrow_back.name = "BtnArrowBack"
	btn_arrow_back.texture_normal = _get_nav_arrow_texture(true)
	btn_arrow_back.ignore_texture_size = true
	btn_arrow_back.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn_arrow_back.custom_minimum_size = Vector2(20, 26)
	btn_arrow_back.focus_mode = Control.FOCUS_NONE
	btn_arrow_back.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_arrow_back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_setup_arrow_hover(btn_arrow_back)
	btn_arrow_back.pressed.connect(func():
		_animate_button_press(btn_arrow_back)
		_on_player_back()
	)
	nav_arrows_container.add_child(btn_arrow_back)
	
	# 2. ปุ่มลูกศรขวา ▶ (ไปต่อ)
	btn_arrow_next = TextureButton.new()
	btn_arrow_next.name = "BtnArrowNext"
	btn_arrow_next.texture_normal = _get_nav_arrow_texture(false)
	btn_arrow_next.ignore_texture_size = true
	btn_arrow_next.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn_arrow_next.custom_minimum_size = Vector2(20, 26)
	btn_arrow_next.focus_mode = Control.FOCUS_NONE
	btn_arrow_next.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_arrow_next.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_setup_arrow_hover(btn_arrow_next)
	btn_arrow_next.pressed.connect(func():
		_animate_button_press(btn_arrow_next)
		_on_player_advance()
	)
	nav_arrows_container.add_child(btn_arrow_next)
	
	arrow_overlay.add_child(nav_arrows_container)
	_update_nav_arrows()

func _animate_button_press(btn: TextureButton) -> void:
	if not is_instance_valid(btn) or not btn.visible or btn.disabled:
		return
	if btn == btn_arrow_back and press_tween_back and press_tween_back.is_valid():
		press_tween_back.kill()
	elif btn == btn_arrow_next and press_tween_next and press_tween_next.is_valid():
		press_tween_next.kill()
	
	btn.pivot_offset = btn.size / 2.0
	btn.position.y = 2.0
	btn.scale = Vector2(0.90, 0.90)
	btn.modulate = Color(2.4, 2.4, 2.4, 1.0)
	
	var tw = btn.create_tween()
	tw.set_parallel(true)
	tw.tween_property(btn, "position:y", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var is_hovered = btn.get_global_rect().has_point(btn.get_global_mouse_position())
	var target_mod = Color(1.4, 1.4, 1.4, 1.0) if is_hovered else Color(1.0, 1.0, 1.0, 1.0)
	tw.tween_property(btn, "modulate", target_mod, 0.14)
	
	if btn == btn_arrow_back:
		press_tween_back = tw
	elif btn == btn_arrow_next:
		press_tween_next = tw

func _setup_arrow_hover(btn: TextureButton) -> void:
	btn.mouse_entered.connect(func():
		var is_pressing = (btn == btn_arrow_back and press_tween_back and press_tween_back.is_valid()) or \
			(btn == btn_arrow_next and press_tween_next and press_tween_next.is_valid())
		if not is_pressing and not btn.disabled and btn.visible:
			var tw = create_tween()
			tw.tween_property(btn, "modulate", Color(1.4, 1.4, 1.4, 1.0), 0.08)
	)
	btn.mouse_exited.connect(func():
		var is_pressing = (btn == btn_arrow_back and press_tween_back and press_tween_back.is_valid()) or \
			(btn == btn_arrow_next and press_tween_next and press_tween_next.is_valid())
		if not is_pressing and not btn.disabled and btn.visible:
			var tw = create_tween()
			tw.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	)

func _update_nav_arrows() -> void:
	if not nav_arrows_container or not is_instance_valid(nav_arrows_container):
		return
	if not is_instance_valid(dialogue_box) or not dialogue_box.visible or is_transitioning:
		nav_arrows_container.visible = false
		return
	
	nav_arrows_container.visible = true
	
	# ลูกศรซ้าย ◀ (ย้อนกลับ)
	var can_back = _can_go_back()
	btn_arrow_back.disabled = not can_back
	btn_arrow_back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if can_back else Control.CURSOR_ARROW
	if can_back:
		if not (press_tween_back and press_tween_back.is_valid()):
			var is_hovered = btn_arrow_back.get_global_rect().has_point(btn_arrow_back.get_global_mouse_position())
			btn_arrow_back.modulate = Color(1.4, 1.4, 1.4, 1.0) if is_hovered else Color(1.0, 1.0, 1.0, 1.0)
	else:
		if press_tween_back and press_tween_back.is_valid():
			press_tween_back.kill()
		btn_arrow_back.position.y = 0.0
		btn_arrow_back.scale = Vector2.ONE
		btn_arrow_back.modulate = Color(1.0, 1.0, 1.0, 0.25)
	
	# ลูกศรขวา ▶ (ไปต่อ)
	var can_next = is_dialogue_active or is_typing
	btn_arrow_next.disabled = not can_next
	btn_arrow_next.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if can_next else Control.CURSOR_ARROW
	if can_next:
		if not (press_tween_next and press_tween_next.is_valid()):
			var is_hovered = btn_arrow_next.get_global_rect().has_point(btn_arrow_next.get_global_mouse_position())
			btn_arrow_next.modulate = Color(1.4, 1.4, 1.4, 1.0) if is_hovered else Color(1.0, 1.0, 1.0, 1.0)
	else:
		if press_tween_next and press_tween_next.is_valid():
			press_tween_next.kill()
		btn_arrow_next.position.y = 0.0
		btn_arrow_next.scale = Vector2.ONE
		btn_arrow_next.modulate = Color(1.0, 1.0, 1.0, 0.25)

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
	is_typing = false
	if typewriter_tween and typewriter_tween.is_valid():
		typewriter_tween.kill()
	_hide_continue_arrow()
	_hide_question_mark()
	_hide_exclamation()
	
	# ซ่อนกล่องข้อความ
	if is_instance_valid(dialogue_box):
		var tw_box = create_tween()
		tw_box.tween_property(dialogue_box, "modulate:a", 0.0, 0.2)
	
	# เฟดจอดำ และเปลี่ยนซีน
	if is_instance_valid(fade_overlay):
		fade_overlay.visible = true
		var tw_fade_out = create_tween()
		tw_fade_out.tween_property(fade_overlay, "color:a", 1.0, 0.4)
		tw_fade_out.tween_callback(_switch_to_gameplay)
	else:
		_switch_to_gameplay()

func _skip_cutscene() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	is_dialogue_active = false
	is_typing = false
	if typewriter_tween and typewriter_tween.is_valid():
		typewriter_tween.kill()
	if entrance_tween and entrance_tween.is_valid():
		entrance_tween.kill()
	_hide_continue_arrow()
	_hide_question_mark()
	_hide_exclamation()
	if is_instance_valid(dialogue_box):
		dialogue_box.visible = false
	_switch_to_gameplay()

func _switch_to_gameplay() -> void:
	Engine.time_scale = 1.0
	if not SceneLoader.change_scene(get_tree(), next_scene_path):
		push_warning("[CentralTowerCutscene] next_scene_path not found: '%s'" % next_scene_path)
