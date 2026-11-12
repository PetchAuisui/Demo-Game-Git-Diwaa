extends Node2D

## การควบคุม Cutscene ปกติ (Cutscene Normal)
## ลำดับเหตุการณ์:
## 1. หมู่บ้านปกติ (village-normal เฟรม 0 ถึง 23)
## 2. ท้องฟ้าสงบสุข (peaceful-landscape เล่นทั้งหมด 66 เฟรม)
## 3. ตัดเข้าสู่ฉากหอสมุด (intro_cutscene.tscn)

@onready var village: AnimatedSprite2D = $Village
@onready var sky: AnimatedSprite2D = $Sky
@onready var camera: Camera2D = $Camera2D
@onready var fade_overlay: ColorRect = $UI/FadeOverlay

@export_group("การแสดงผลหมู่บ้าน (Village Settings)")
@export var village_frame_index: int = 0

var is_transitioning: bool = false
var is_fast_forwarding: bool = false
var can_fast_forward: bool = true
var skip_ctrl = null
var current_stage: int = 1 # 1 = village, 2 = sky, 3 = transitioning

signal cutscene_finished

func _ready() -> void:
	Engine.time_scale = 1.0
	SceneLoader.request_preload("res://features/cutscene/intro_cutscene.tscn")
	skip_ctrl = preload("res://features/cutscene/skip_cutscene_button.gd").new()
	skip_ctrl.next_scene_path = "res://features/cutscene/intro_cutscene.tscn"
	skip_ctrl.custom_skip_action = _on_skip_step
	add_child(skip_ctrl)
	_init_scene()
	play_normal_sequence()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

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
		if village.animation_finished.is_connected(_on_village_finished):
			village.animation_finished.disconnect(_on_village_finished)
		village.stop()
		fade_overlay.color.a = 0.0
		_on_village_finished()
	elif current_stage == 2:
		# ข้ามฉากท้องฟ้า ไปยังฉากห้องสมุดทันที
		_go_to_intro_cutscene()

func play_normal_sequence() -> void:
	current_stage = 1
	village.frame = village_frame_index
	village.play("village_normal", 1.0)
	if not village.animation_finished.is_connected(_on_village_finished):
		village.animation_finished.connect(_on_village_finished, CONNECT_ONE_SHOT)
	
	var tw = create_tween()
	tw.tween_property(fade_overlay, "color:a", 0.0, 0.5)

func _on_village_finished() -> void:
	if current_stage >= 2 and sky.visible:
		return
	current_stage = 2
	sky.visible = true
	sky.frame = 0
	sky.modulate = Color(1, 1, 1, 0)
	
	var tw_sky_in = create_tween()
	tw_sky_in.tween_property(sky, "modulate:a", 1.0, 0.35)
	tw_sky_in.chain().tween_callback(func():
		village.visible = false
	)
	
	sky.play("peaceful_sky", 1.0)
	sky.animation_finished.connect(_on_sky_finished, CONNECT_ONE_SHOT)

func _on_sky_finished() -> void:
	_go_to_intro_cutscene()

func _go_to_intro_cutscene() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	current_stage = 3
	Engine.time_scale = 1.0
	
	var tw_fade_out = create_tween()
	tw_fade_out.tween_property(fade_overlay, "color:a", 1.0, 0.5)
	tw_fade_out.tween_callback(func():
		Engine.time_scale = 1.0
		emit_signal("cutscene_finished")
		print("[CutsceneNormal] Transitioning to IntroCutscene (Library)...")
		SceneLoader.change_scene(get_tree(), "res://features/cutscene/intro_cutscene.tscn")
	)
