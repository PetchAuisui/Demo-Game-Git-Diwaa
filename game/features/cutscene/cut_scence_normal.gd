extends Node2D

## การควบคุม Cutscene ปกติ (Cutscene Normal)
## ลำดับเหตุการณ์:
## 1. หมู่บ้านปกติ (แสดงเฉพาะเฟรมแรก ค้างไว้ 3.0 วินาที ตามเวลาเดิม)
## 2. ท้องฟ้าสงบสุข (peaceful-landscape เล่นทั้งหมด 66 เฟรม)
## 3. ตัดเข้าสู่ฉากหอสมุด (intro_cutscene.tscn)
## เสียง Cutscene (gitdiwa-sound+effect.MP3) เริ่มเล่นตั้งแต่ฉากหมู่บ้าน และเล่นต่อเนื่องข้ามไปยังฉากหอสมุดโดยไม่สะดุด

const CutsceneMusic = preload("res://common/cutscene_music.gd")

@onready var village: AnimatedSprite2D = $Village
@onready var sky: AnimatedSprite2D = $Sky
@onready var camera: Camera2D = $Camera2D
@onready var fade_overlay: ColorRect = $UI/FadeOverlay
@onready var bgm: AudioStreamPlayer = $BGM

@export_group("การแสดงผลหมู่บ้าน (Village Settings)")
@export var village_frame_index: int = 0
@export var village_duration: float = 3.0

var is_transitioning: bool = false
var is_fast_forwarding: bool = false
var can_fast_forward: bool = true
var skip_ctrl = null
var current_stage: int = 1 # 1 = village, 2 = sky, 3 = transitioning
var tw_intro_fade: Tween = null
var tw_village_timer: Tween = null
var tw_sky_fade: Tween = null

signal cutscene_finished

func _ready() -> void:
	Engine.time_scale = 1.0
	SceneLoader.request_preload("res://features/cutscene/intro_cutscene.tscn")
	SceneLoader.request_preload(CutsceneMusic.BGM_AUDIO_PATH)
	skip_ctrl = preload("res://features/cutscene/skip_cutscene_button.gd").new()
	skip_ctrl.next_scene_path = "res://features/cutscene/intro_cutscene.tscn"
	skip_ctrl.custom_skip_action = _on_skip_step
	add_child(skip_ctrl)
	_init_scene()
	play_normal_sequence()

func _exit_tree() -> void:
	Engine.time_scale = 1.0
	if tw_intro_fade and tw_intro_fade.is_valid():
		tw_intro_fade.kill()
		tw_intro_fade = null
	if tw_village_timer and tw_village_timer.is_valid():
		tw_village_timer.kill()
		tw_village_timer = null
	if tw_sky_fade and tw_sky_fade.is_valid():
		tw_sky_fade.kill()
		tw_sky_fade = null

func _process(_delta: float) -> void:
	if not can_fast_forward or is_transitioning:
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

func _init_scene() -> void:
	is_transitioning = false
	can_fast_forward = true
	is_fast_forwarding = false
	current_stage = 1
	Engine.time_scale = 1.0
	
	if tw_intro_fade and tw_intro_fade.is_valid():
		tw_intro_fade.kill()
		tw_intro_fade = null
	if tw_village_timer and tw_village_timer.is_valid():
		tw_village_timer.kill()
		tw_village_timer = null
	if tw_sky_fade and tw_sky_fade.is_valid():
		tw_sky_fade.kill()
		tw_sky_fade = null
	
	village.visible = true
	village.frame = village_frame_index
	village.stop()
	
	sky.visible = false
	sky.frame = 0
	sky.stop()
	
	camera.position = Vector2(960, 540)
	camera.zoom = Vector2(1.0, 1.0)
	
	fade_overlay.color = Color(0, 0, 0, 1)
	fade_overlay.visible = true

func _on_skip_step() -> void:
	if is_transitioning:
		return
	if current_stage == 1:
		# ข้ามเฉพาะฉากหมู่บ้าน ไปยังฉากท้องฟ้า
		if tw_intro_fade and tw_intro_fade.is_valid():
			tw_intro_fade.kill()
			tw_intro_fade = null
		if tw_village_timer and tw_village_timer.is_valid():
			tw_village_timer.kill()
			tw_village_timer = null
		fade_overlay.color.a = 0.0
		_on_village_finished()
	elif current_stage == 2:
		# ข้ามฉากท้องฟ้า ไปยังฉากห้องสมุดทันที (เสียงเพลงเล่นต่อเนื่อง)
		_go_to_intro_cutscene()

func play_normal_sequence() -> void:
	current_stage = 1
	village.visible = true
	village.frame = village_frame_index
	village.stop() # เล่นเฉพาะเฟรมแรก ค้างไว้ ไม่เล่น Animation
	
	# เริ่มเล่นเสียงเพลง Cutscene ต่อเนื่องตั้งแต่ฉากหมู่บ้านพร้อม Fade-in ทันที
	if is_instance_valid(bgm):
		bgm.volume_db = -12.0
		bgm.play()
		CutsceneMusic.register_player(bgm)
		var tw_audio = create_tween()
		tw_audio.tween_property(bgm, "volume_db", 2.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		CutsceneMusic.play(0.8, -12.0, 2.0)
	
	# เฟดภาพเข้าจากจอดำอย่างนุ่มนวล (0.8 วินาที)
	if tw_intro_fade and tw_intro_fade.is_valid():
		tw_intro_fade.kill()
	fade_overlay.color = Color(0, 0, 0, 1)
	fade_overlay.visible = true
	tw_intro_fade = create_tween()
	tw_intro_fade.tween_property(fade_overlay, "color:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# แสดงภาพหมู่บ้านเฟรมแรก ค้างไว้ตามเวลาเดิม (3.0 วินาที)
	if tw_village_timer and tw_village_timer.is_valid():
		tw_village_timer.kill()
	tw_village_timer = create_tween()
	tw_village_timer.tween_interval(village_duration)
	tw_village_timer.tween_callback(_on_village_finished)

func _on_village_finished() -> void:
	if current_stage >= 2 or is_transitioning:
		return
	current_stage = 2
	if tw_village_timer and tw_village_timer.is_valid():
		tw_village_timer.kill()
		tw_village_timer = null
	
	sky.visible = true
	sky.frame = 0
	sky.modulate = Color(1, 1, 1, 0)
	
	if tw_sky_fade and tw_sky_fade.is_valid():
		tw_sky_fade.kill()
	tw_sky_fade = create_tween()
	tw_sky_fade.tween_property(sky, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
	tw_sky_fade.chain().tween_callback(func():
		village.visible = false
	)
	
	sky.play("peaceful_sky", 1.0)
	if not sky.animation_finished.is_connected(_on_sky_finished):
		sky.animation_finished.connect(_on_sky_finished, CONNECT_ONE_SHOT)

func _on_sky_finished() -> void:
	_go_to_intro_cutscene()

func _go_to_intro_cutscene() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	current_stage = 3
	Engine.time_scale = 1.0
	if tw_intro_fade and tw_intro_fade.is_valid():
		tw_intro_fade.kill()
		tw_intro_fade = null
	if tw_sky_fade and tw_sky_fade.is_valid():
		tw_sky_fade.kill()
		tw_sky_fade = null
	
	# ย้ายโหนดเพลง BGM ไปไว้ที่ root ก่อนสลับฉาก เพื่อให้เพลงเล่นต่อเนื่องไปยังฉากหอสมุดโดยไม่ขาดตอน
	if is_instance_valid(bgm) and bgm.get_parent() == self:
		var cur_pos: float = bgm.get_playback_position()
		bgm.reparent(get_tree().root)
		if not bgm.playing:
			bgm.play(cur_pos)
		CutsceneMusic.register_player(bgm)
	
	# เฟดภาพจอดำก่อนสลับฉาก
	var tw_fade_out = create_tween()
	tw_fade_out.tween_property(fade_overlay, "color:a", 1.0, 0.6)
	tw_fade_out.tween_callback(func():
		Engine.time_scale = 1.0
		emit_signal("cutscene_finished")
		print("[CutsceneNormal] Transitioning to IntroCutscene (Library)...")
		SceneLoader.change_scene(get_tree(), "res://features/cutscene/intro_cutscene.tscn")
	)
