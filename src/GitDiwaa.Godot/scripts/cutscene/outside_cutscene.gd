extends Node2D

## การควบคุม Cutscene วิกฤตและหอคอย (Cutscene Chaos)
## ลำดับเหตุการณ์:
## 1. ท้องฟ้าพายุไม่ปกติ (storm-clouds เล่นทั้งหมด 60 เฟรม)
## 2. บ้านเมืองไม่ปกติ (village-normal เริ่มเล่นตั้งแต่เฟรมที่ 20 ถึงจบ 58)
## 3. หอคอยทมิฬ (เมฆลอยไป-กลับ Ping-pong) + เวลยืนมอง + ไตเติลเกม Git Di Waa

@onready var storm_sky: AnimatedSprite2D = $StormSky
@onready var village: AnimatedSprite2D = $Village
@onready var tower: AnimatedSprite2D = $Tower
@onready var vel_shadow: Sprite2D = $VelShadow
@onready var vel: Sprite2D = $Vel
@onready var camera: Camera2D = $Camera2D

@onready var fade_overlay: ColorRect = $UI/FadeOverlay
@onready var title_container: Control = $UI/TitleContainer
@onready var title_label_aura: Label = $UI/TitleContainer/TitleLabelAura
@onready var title_label: Label = $UI/TitleContainer/TitleLabel
@onready var subtitle_label: Label = $UI/TitleContainer/SubtitleLabel
@onready var start_prompt: Label = $UI/TitleContainer/StartPrompt

@export var next_scene_path: String = "res://Scenes/SandboxGameView.tscn"

var can_start: bool = false
var is_starting: bool = false
var is_tower_forward: bool = true
var is_fast_forwarding: bool = false
var can_fast_forward: bool = true

signal cutscene_finished

func _ready() -> void:
	Engine.time_scale = 1.0
	_init_scene()
	play_chaos_sequence()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _process(_delta: float) -> void:
	# ตรวจสอบการกดค้างเพื่อเร่งสปีด (Fast-forward) แบบ Real-time
	if can_fast_forward and not can_start and not is_starting:
		var wants_ff: bool = Input.is_key_pressed(KEY_SPACE) or \
			Input.is_key_pressed(KEY_ENTER) or \
			Input.is_key_pressed(KEY_SHIFT) or \
			Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		
		if wants_ff != is_fast_forwarding:
			is_fast_forwarding = wants_ff
			Engine.time_scale = 2.5 if wants_ff else 1.0

func _input(event: InputEvent) -> void:
	if not can_start or is_starting:
		return
	
	if event.is_action_pressed("ui_accept") or \
	   (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)) or \
	   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
		_trigger_start_level()

func _init_scene() -> void:
	can_start = false
	is_starting = false
	can_fast_forward = true
	is_fast_forwarding = false
	Engine.time_scale = 1.0
	is_tower_forward = true
	
	storm_sky.visible = true
	storm_sky.frame = 0
	storm_sky.stop()
	
	village.visible = false
	village.frame = 0
	village.stop()
	
	tower.visible = false
	tower.frame = 0
	tower.stop()
	if tower.sprite_frames:
		tower.sprite_frames.set_animation_loop("tower_loop", false)
	
	if vel_shadow:
		vel_shadow.visible = false
		vel_shadow.position = Vector2(960, 1056)
		vel_shadow.scale = Vector2(4.8, 2.4)
		vel_shadow.modulate = Color(0, 0, 0, 0)
	
	vel.visible = false
	vel.position = Vector2(960, 880)
	vel.scale = Vector2(4.6, 4.6)
	vel.modulate = Color(1, 1, 1, 0)
	
	camera.position = Vector2(960, 540)
	camera.zoom = Vector2(1.0, 1.0)
	
	title_container.modulate = Color(1, 1, 1, 0)
	if subtitle_label:
		subtitle_label.text = "— ตำนานแห่งหอคอยต้นกำเนิด —"
	if start_prompt:
		start_prompt.text = "— กด Space หรือคลิก เพื่อเข้าสู่ด่านแรก —"
	fade_overlay.color = Color(0, 0, 0, 1)
	fade_overlay.visible = true

func play_chaos_sequence() -> void:
	# 1. ค่อย ๆ สว่างขึ้นจากจอดำสู่ท้องฟ้าพายุ 0.5 วินาที
	var tw = create_tween()
	tw.tween_property(fade_overlay, "color:a", 0.0, 0.5)
	tw.tween_callback(func():
		storm_sky.play("storm_sky", 1.0)
		storm_sky.animation_finished.connect(_on_storm_sky_finished, CONNECT_ONE_SHOT)
	)

func _on_storm_sky_finished() -> void:
	# 2. สลับภาพสู่บ้านเมืองโกลาหล (เล่นแอนิเมชันตั้งแต่เฟรมที่ 20 ถึงจบ 58)
	village.visible = true
	village.frame = 0
	village.modulate = Color(1, 1, 1, 0)
	
	var tw_vil_in = create_tween()
	tw_vil_in.tween_property(village, "modulate:a", 1.0, 0.35)
	tw_vil_in.chain().tween_callback(func():
		storm_sky.visible = false
	)
	
	village.play("village_chaos", 1.0)
	village.animation_finished.connect(_on_village_chaos_finished, CONNECT_ONE_SHOT)

func _on_village_chaos_finished() -> void:
	# 3. สลับภาพสู่หอคอยทมิฬ
	tower.visible = true
	tower.modulate = Color(1, 1, 1, 0)
	_start_tower_ping_pong()
	
	var tw_tow_in = create_tween()
	tw_tow_in.tween_property(tower, "modulate:a", 1.0, 0.4)
	tw_tow_in.chain().tween_callback(func():
		village.visible = false
	)
	
	if vel_shadow:
		vel_shadow.visible = true
		var tw_shadow = create_tween()
		tw_shadow.tween_property(vel_shadow, "modulate:a", 0.65, 0.7)
	
	vel.visible = true
	var tw_vel = create_tween()
	tw_vel.tween_property(vel, "modulate:a", 1.0, 0.7)
	
	var tw_wait = create_tween()
	tw_wait.tween_interval(1.5)
	tw_wait.tween_callback(_reveal_game_title)

func _start_tower_ping_pong() -> void:
	if not tower:
		return
	if tower.sprite_frames:
		tower.sprite_frames.set_animation_loop("tower_loop", false)
	is_tower_forward = true
	if not tower.animation_finished.is_connected(_on_tower_animation_finished):
		tower.animation_finished.connect(_on_tower_animation_finished)
	tower.play("tower_loop", 1.0)

func _on_tower_animation_finished() -> void:
	if not is_instance_valid(tower) or not tower.visible:
		return
	is_tower_forward = not is_tower_forward
	if is_tower_forward:
		tower.play("tower_loop", 1.0)
	else:
		tower.play_backwards("tower_loop")

func _reveal_game_title() -> void:
	can_fast_forward = false
	is_fast_forwarding = false
	Engine.time_scale = 1.0
	
	var tw_title = create_tween()
	tw_title.tween_property(title_container, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var tw_title_aura = create_tween().set_loops()
	tw_title_aura.tween_property(title_label_aura, "modulate:a", 0.75, 1.6).set_trans(Tween.TRANS_SINE)
	tw_title_aura.tween_property(title_label_aura, "modulate:a", 0.30, 1.6).set_trans(Tween.TRANS_SINE)
	
	var tw_prompt = create_tween().set_loops()
	tw_prompt.tween_property(start_prompt, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	tw_prompt.tween_property(start_prompt, "modulate:a", 0.35, 0.8).set_trans(Tween.TRANS_SINE)
	
	can_start = true

func _trigger_start_level() -> void:
	if is_starting:
		return
	is_starting = true
	can_start = false
	can_fast_forward = false
	is_fast_forwarding = false
	Engine.time_scale = 1.0
	
	var tw_out = create_tween()
	tw_out.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), 1.0)
	tw_out.tween_callback(func():
		Engine.time_scale = 1.0
		emit_signal("cutscene_finished")
		print("[CutsceneChaos] เข้าสู่ด่านแรกเรียบร้อย!")
		if next_scene_path != "" and ResourceLoader.exists(next_scene_path):
			get_tree().change_scene_to_file(next_scene_path)
		else:
			push_warning("[OutsideCutscene] next_scene_path is empty or not found: '%s'. กรุณากำหนด Path ซีนด่านแรกใน Inspector" % next_scene_path)
			# ค่อยๆ จางจอดำออกเพื่อไม่ให้ผู้เล่นติดอยู่ในจอสีดำสนิท
			var tw_recover = create_tween()
			tw_recover.tween_property(fade_overlay, "color:a", 0.0, 0.5)
			can_start = true
			is_starting = false
	)
