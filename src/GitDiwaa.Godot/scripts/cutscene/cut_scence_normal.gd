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

signal cutscene_finished

func _ready() -> void:
	Engine.time_scale = 1.0
	_init_scene()
	play_normal_sequence()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _init_scene() -> void:
	is_transitioning = false
	
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

func play_normal_sequence() -> void:
	# 1. ค่อย ๆ สว่างขึ้นจากจอดำสู่หมู่บ้านปกติ ค้างที่รูปเดียว (เฟรม 0) ประมาณ 33 เฟรม (4.95 วินาที)
	village.frame = village_frame_index
	village.stop()
	
	var tw = create_tween()
	tw.tween_property(fade_overlay, "color:a", 0.0, 0.5)
	
	# ค้างภาพไว้นิ่งๆ ประมาณ 33 เฟรม (4.95 วินาที) แล้วค่อย Cross-fade เข้าสู่ท้องฟ้าปกติ
	var tw_hold = create_tween()
	tw_hold.tween_interval(village_hold_seconds)
	tw_hold.tween_callback(_on_village_finished)

func _on_village_finished() -> void:
	# 2. เมื่อหมู่บ้านเล่นครบเฟรม 0-23 ให้ Cross-fade เข้าสู่ท้องฟ้าปกติ 0.35 วินาที
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
	# 3. เมื่อท้องฟ้าเล่นจบทั้งหมด ให้ Fade ดำ แล้วตัดเข้าสู่ฉากหอสมุด
	if is_transitioning:
		return
	is_transitioning = true
	
	var tw_fade_out = create_tween()
	tw_fade_out.tween_property(fade_overlay, "color:a", 1.0, 0.6)
	tw_fade_out.tween_callback(func():
		emit_signal("cutscene_finished")
		print("[CutsceneNormal] Transitioning to IntroCutscene (Library)...")
		get_tree().change_scene_to_file("res://scenes/cutscene/intro_cutscene.tscn")
	)
