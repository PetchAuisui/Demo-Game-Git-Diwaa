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
@export var village_hold_seconds: float = 4.95 # ประมาณ 33 เฟรม (33 * 0.15s)

var is_transitioning: bool = false
var is_fast_forwarding: bool = false
var can_fast_forward: bool = true
var skip_ctrl = null
var current_stage: int = 1 # 1 = village, 2 = sky, 3 = transitioning
var tw_hold: Tween = null

signal cutscene_finished

func _ready() -> void:
	Engine.time_scale = 1.0
	skip_ctrl = preload("res://scripts/cutscene/skip_cutscene_button.gd").new()
	skip_ctrl.next_scene_path = "res://scenes/cutscene/intro_cutscene.tscn"
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
	var wants_hold: bool = Input.is_key_pressed(KEY_SPACE) or \
		Input.is_key_pressed(KEY_ENTER) or \
		Input.is_key_pressed(KEY_SHIFT)
	
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
		if tw_hold and tw_hold.is_valid():
			tw_hold.kill()
		fade_overlay.color.a = 0.0
		_on_village_finished()
	elif current_stage == 2:
		# ข้ามฉากท้องฟ้า ไปยังฉากห้องสมุดทันที
		_go_to_intro_cutscene()

func play_normal_sequence() -> void:
	current_stage = 1
	village.frame = village_frame_index
	village.stop()
	
	var tw = create_tween()
	tw.tween_property(fade_overlay, "color:a", 0.0, 0.5)
	
	# ค้างภาพไว้นิ่งๆ ประมาณ 33 เฟรม (4.95 วินาที) แล้วค่อย Cross-fade เข้าสู่ท้องฟ้าปกติ
	tw_hold = create_tween()
	tw_hold.tween_interval(village_hold_seconds)
	tw_hold.tween_callback(_on_village_finished)

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
		get_tree().change_scene_to_file("res://scenes/cutscene/intro_cutscene.tscn")
	)
