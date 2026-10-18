extends Node2D

## การควบคุมฉากคัตซีนเปิดตัวหอคอยเวทกลาง (Central Tower Intro Cutscene)
## ลำดับเหตุการณ์:
## 1. เฟดเข้าจากจอดำสู่ห้องโถงหอคอยเวทกลาง (central-tower-Sheet)
## 2. เวล (ฝั่งซ้าย) เดินเข้ามาในห้องโถง และพบกับผู้พิทักษ์ (ฝั่งขวา)
## 3. เริ่มต้นบทสนทนา: ผู้พิทักษ์ทักทาย -> เวลรายงานตัว -> ผู้พิทักษ์อธิบายธรรมเนียม GitHub Flow
## 4. ผู้เล่นคลิกหน้าจอ หรือกด Space / Enter เพื่ออ่านบทสนทนาทีละประโยค (มี Typewriter Effect)
## 5. เมื่อคุยจบครบทุกประโยค หรือผู้เล่นกดปุ่มข้าม (Skip / Esc) -> เฟดจอดำและสลับเข้าสู่ด่านที่ 16 (SandboxGameView)

@export var next_scene_path: String = "res://Scenes/SandboxGameView.tscn"

# Camera & Visuals
@onready var camera: Camera2D = $Camera2D
@onready var background: Sprite2D = $Background
@onready var atmosphere: ColorRect = $Atmosphere
@onready var fade_overlay: ColorRect = $MagicStoryUI/FadeOverlay

# Characters
@onready var stage: Node2D = $Stage
@onready var vel: AnimatedSprite2D = $Stage/Vel
@onready var exclamation_mark: Sprite2D = $Stage/Vel/ExclamationMark
@onready var guardian: AnimatedSprite2D = $Stage/Guardian

# UI Elements
@onready var magic_ui: CanvasLayer = $MagicStoryUI
@onready var dialogue_box: PanelContainer = $MagicStoryUI/DialogueBox
@onready var speaker_label: Label = $MagicStoryUI/DialogueBox/Margin/VBox/SpeakerLabel
@onready var dialogue_label: Label = $MagicStoryUI/DialogueBox/Margin/VBox/DialogueLabel
@onready var continue_prompt: Label = $MagicStoryUI/DialogueBox/Margin/VBox/ContinuePrompt
@onready var skip_button: Button = $MagicStoryUI/SkipButton


# Dialogue Script Data (บทสนทนาประจำฉาก)
const DIALOGUES: Array[Dictionary] = [
	{
		"speaker": "ผู้พิทักษ์",
		"text": "มาถึงแล้วสินะ ศิษย์ฝึกหัด",
		"vel_anim": "idle",
		"guardian_anim": "talk_blink",
		"exclamation": false
	},
	{
		"speaker": "เวล",
		"text": "ท่านคือ...",
		"vel_anim": "shock",
		"guardian_anim": "idle",
		"exclamation": true
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "ข้าคือผู้พิทักษ์คลังเวทกลาง ดูแลบันทึกและความรู้ของจอมเวททุกคนในอาณาจักร นายมาที่นี่เพื่อตามหาเศษคัมภีร์ที่เหลือ ใช่ไหม",
		"vel_anim": "breathe_blink",
		"guardian_anim": "talk_blink",
		"exclamation": false
	},
	{
		"speaker": "เวล",
		"text": "ใช่ครับ",
		"vel_anim": "idle",
		"guardian_anim": "breathe",
		"exclamation": false
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "ดี แต่ก่อนจะไปมากกว่านี้ ข้าอยากให้เจ้าได้เรียนรู้การใช้พลัง Git ของเราในการจารึกร่วมกับผู้อื่น",
		"vel_anim": "breathe_blink",
		"guardian_anim": "talk_blink",
		"exclamation": false
	},
	{
		"speaker": "เวล",
		"text": "กฎเหรอครับ?",
		"vel_anim": "breathe_blink",
		"guardian_anim": "idle",
		"exclamation": false
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "ไม่ใช่หรอก มันเรียกว่าธรรมเนียมมากกว่า โดยส่วนมากธรรมเนียมเป็นไปตามกำหนดจากเจ้าของคัมภีร์",
		"vel_anim": "idle",
		"guardian_anim": "talk_blink",
		"exclamation": false
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "เพราะงั้นนี่คือ...",
		"vel_anim": "idle",
		"guardian_anim": "breathe",
		"exclamation": false
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "'GitHub Flow' ธรรมเนียมที่คลังเวทกลางแห่งนี้ใช้กันมาตลอด",
		"vel_anim": "shock",
		"guardian_anim": "talk_blink",
		"exclamation": false
	},
	{
		"speaker": "เวล",
		"text": "GitHub Flow?",
		"vel_anim": "shock",
		"guardian_anim": "breathe",
		"exclamation": false
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "ใช่ ความจริงแล้วในหมู่จอมเวททั่วอาณาจักร มีธรรมเนียมการทำงานร่วมกันอยู่หลายแบบ บ้างก็ใช้ 'Git Flow' ที่ซับซ้อนกว่า มีเส้นทางแยกย่อยหลายสาย บางคลังก็ใช้แบบอื่นไปเลยก็มี",
		"vel_anim": "breathe_blink",
		"guardian_anim": "talk_blink",
		"exclamation": false
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "แต่ที่นี่ เราเลือกใช้ GitHub Flow เพราะเรียบง่าย เหมาะกับจอมเวทที่หมุนเวียนงานกันเร็ว ๆ",
		"vel_anim": "idle",
		"guardian_anim": "talk_blink",
		"exclamation": false
	},
	{
		"speaker": "เวล",
		"text": "แล้วมันทำงานยังไงครับ",
		"vel_anim": "breathe_blink",
		"guardian_anim": "idle",
		"exclamation": false
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "หลักการง่ายมาก มีเส้นทางหลักอยู่เส้นเดียวคือ main ห้ามใครแก้ไขมันตรง ๆ เด็ดขาด",
		"vel_anim": "shock",
		"guardian_anim": "talk_blink",
		"exclamation": false
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "ทุกครั้งที่จะเริ่มงานใหม่ ไม่ว่าเล็กหรือใหญ่ ต้องแยกเส้นทางจารึกใหม่ออกมาก่อนเสมอ",
		"vel_anim": "breathe_blink",
		"guardian_anim": "talk_blink",
		"exclamation": false
	},
	{
		"speaker": "ผู้พิทักษ์",
		"text": "ทำงานเสร็จ ทดสอบจนมั่นใจ ก็ยื่นคำขอบันทึกคัมภีร์กลับเข้า main แล้วให้จอมเวทคนอื่นตรวจสอบก่อนรวม",
		"vel_anim": "idle",
		"guardian_anim": "talk_blink",
		"exclamation": false
	}
]

var current_dialogue_index: int = 0
var is_dialogue_active: bool = false
var is_typing: bool = false
var is_transitioning: bool = false
var typewriter_tween: Tween = null
var exclamation_tween: Tween = null

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
		
	# คลิกหรือกด Space/Enter เพื่อไปต่อ
	if is_dialogue_active:
		var wants_advance: bool = false
		if event.is_action_pressed("ui_accept"):
			wants_advance = true
		elif event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			wants_advance = true
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# ตรวจสอบว่าไม่ได้กดโดนปุ่ม Skip
			if not skip_button.get_global_rect().has_point(event.position):
				wants_advance = true
				
		if wants_advance:
			get_viewport().set_input_as_handled()
			_on_player_advance()

func _init_scene_state() -> void:
	# ตั้งค่ากล้อง
	camera.position = Vector2(960, 540)
	camera.zoom = Vector2.ONE
	
	# เตรียมตัวละคร เวล (ซ้าย) ผู้พิทักษ์ (ขวา)
	vel.position = Vector2(520, 780)
	vel.scale = Vector2(4.0, 4.0)
	vel.play("walk")
	
	guardian.position = Vector2(1320, 780)
	guardian.scale = Vector2(4.0, 4.0)
	guardian.flip_h = true
	guardian.play("idle")
	
	exclamation_mark.visible = false
	exclamation_mark.scale = Vector2.ZERO
	exclamation_mark.position = Vector2(0, -60)
	
	# ซ่อนกล่องข้อความไว้ก่อน
	dialogue_box.visible = false
	dialogue_box.modulate = Color(1, 1, 1, 0)
	
	# ปุ่มข้าม
	skip_button.pressed.connect(_skip_cutscene)
	
	# หน้าจอมืดไว้สำหรับเฟดเข้า
	fade_overlay.visible = true
	fade_overlay.color = Color(0, 0, 0, 1.0)
	

## -------------------------------------------------------------
## Sequence: เดินเข้าฉากเปิดตัว
## -------------------------------------------------------------
func _play_entrance_sequence() -> void:
	# 1. เฟดสว่างเปิดฉาก (0.8 วินาที)
	var tw_fade_in = create_tween()
	tw_fade_in.tween_property(fade_overlay, "color:a", 0.0, 0.8)
	
	# 2. เวลเดินจากซ้าย (x: 520 -> 760)
	var tw_walk = create_tween()
	tw_walk.tween_property(vel, "position:x", 760.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw_walk.tween_callback(func():
		vel.play("idle")
		# หน่วงเล็กน้อย 0.3s แล้วเริ่มบทสนทนาแรก
		var tw_wait = create_tween()
		tw_wait.tween_interval(0.3)
		tw_wait.tween_callback(_start_dialogue_sequence)
	)

## -------------------------------------------------------------
## Sequence: ควบคุมบทสนทนา
## -------------------------------------------------------------
func _start_dialogue_sequence() -> void:
	current_dialogue_index = 0
	dialogue_box.visible = true
	
	# เด้งกล่องข้อความขึ้นมา
	var tw_box = create_tween().set_parallel(true)
	tw_box.tween_property(dialogue_box, "modulate:a", 1.0, 0.25)
	tw_box.tween_property(dialogue_box, "scale", Vector2.ONE, 0.25).from(Vector2(0.96, 0.96)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	_show_current_dialogue()

func _show_current_dialogue() -> void:
	if current_dialogue_index >= DIALOGUES.size():
		_finish_cutscene()
		return
		
	var data = DIALOGUES[current_dialogue_index]
	is_dialogue_active = true
	is_typing = true
	
	speaker_label.text = data["speaker"]
	dialogue_label.text = data["text"]
	dialogue_label.visible_ratio = 0.0
	
	# อัปเดตท่าทางตัวละคร
	if data.has("vel_anim") and vel.sprite_frames.has_animation(data["vel_anim"]):
		vel.play(data["vel_anim"])
	if data.has("guardian_anim") and guardian.sprite_frames.has_animation(data["guardian_anim"]):
		guardian.play(data["guardian_anim"])
		
	# ไอคอนตกใจ (!)
	if data.get("exclamation", false):
		_pop_exclamation()
	else:
		_hide_exclamation()
		
	# Typewriter effect
	if typewriter_tween and typewriter_tween.is_valid():
		typewriter_tween.kill()
		
	var duration: float = clampf(float(data["text"].length()) * 0.03, 0.35, 1.4)
	typewriter_tween = create_tween()
	typewriter_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)
	typewriter_tween.tween_callback(func():
		is_typing = false
		# เมื่อพูดจบ ถ้าผู้พิทักษ์กำลังขยับปาก ให้สลับเป็นท่ายืนปกติ
		if guardian.animation == "talk_blink":
			guardian.play("breathe")
	)

func _on_player_advance() -> void:
	if is_typing:
		# ถ้ากำลังพิมพ์อยู่ ให้เร่งแสดงผลข้อความเต็มทันที
		if typewriter_tween and typewriter_tween.is_valid():
			typewriter_tween.kill()
		dialogue_label.visible_ratio = 1.0
		is_typing = false
		if guardian.animation == "talk_blink":
			guardian.play("breathe")
	else:
		# ถ้าข้อความขึ้นครบแล้ว ให้ไปประโยคถัดไป
		current_dialogue_index += 1
		_show_current_dialogue()

func _pop_exclamation() -> void:
	if exclamation_tween and exclamation_tween.is_valid():
		exclamation_tween.kill()
	exclamation_mark.visible = true
	exclamation_mark.scale = Vector2.ZERO
	exclamation_tween = create_tween()
	exclamation_tween.tween_property(exclamation_mark, "scale", Vector2(3.5, 3.5), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _hide_exclamation() -> void:
	if is_instance_valid(exclamation_mark) and exclamation_mark.visible:
		exclamation_mark.visible = false
		exclamation_mark.scale = Vector2.ZERO

## -------------------------------------------------------------
## การเปลี่ยนผ่านและจบฉาก
## -------------------------------------------------------------
func _finish_cutscene() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	is_dialogue_active = false
	
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
	_switch_to_gameplay()

func _switch_to_gameplay() -> void:
	Engine.time_scale = 1.0
	if next_scene_path != "" and ResourceLoader.exists(next_scene_path):
		get_tree().change_scene_to_file(next_scene_path)
	else:
		push_warning("[CentralTowerCutscene] next_scene_path not found: '%s'" % next_scene_path)
