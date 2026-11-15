extends Node2D

## การควบคุม Cutscene วิกฤตและหอคอย (Cutscene Chaos)
## ลำดับเหตุการณ์:
## 1. ท้องฟ้าพายุไม่ปกติ (storm-clouds เล่นทั้งหมด 60 เฟรม)
## 2. บ้านเมืองไม่ปกติ (village-normal เริ่มเล่นตั้งแต่เฟรมที่ 20 ถึงจบ 58)
## 3. หอคอยทมิฬ (เมฆลอยไป-กลับ Ping-pong) + เวลยืนมอง + ไตเติลเกม Git Di Waa

const CutsceneMusic = preload("res://common/cutscene_music.gd")

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

@export var next_scene_path: String = "res://features/cutscene/inside_tower_cutscene.tscn"

var can_start: bool = false
var is_starting: bool = false
var is_tower_forward: bool = true
var is_fast_forwarding: bool = false
var can_fast_forward: bool = true
var skip_ctrl = null
var current_stage: int = 1 # 1 = storm sky, 2 = chaos village, 3 = tower & title
var tw_stage1_fade: Tween = null
var tw_stage2_fade: Tween = null
var tw_stage3_wait: Tween = null
var tw_title: Tween = null

signal cutscene_finished

func _ready() -> void:
	Engine.time_scale = 1.0
	CutsceneMusic.play()
	skip_ctrl = preload("res://features/cutscene/skip_cutscene_button.gd").new()
	skip_ctrl.next_scene_path = _get_resolved_next_scene()
	skip_ctrl.custom_skip_action = _on_skip_step
	add_child(skip_ctrl)
	
	_init_scene()
	play_chaos_sequence()

func _exit_tree() -> void:
	Engine.time_scale = 1.0
	if tw_title and tw_title.is_valid():
		tw_title.kill()
		tw_title = null

func _process(_delta: float) -> void:
	
	if not can_fast_forward or is_starting:
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

func _get_resolved_next_scene() -> String:
	if next_scene_path != "" and ResourceLoader.exists(next_scene_path):
		return next_scene_path
	if ResourceLoader.exists("res://features/cutscene/inside_tower_cutscene.tscn"):
		return "res://features/cutscene/inside_tower_cutscene.tscn"
	return ""

func _input(event: InputEvent) -> void:
	if not can_start or is_starting:
		return
	
	var wants_start: bool = false
	if event.is_action_pressed("ui_accept"):
		wants_start = true
	elif event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_RIGHT):
		wants_start = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# ป้องกันการคลิกโดนปุ่ม UI ถูกกลืนเป็นการกดเริ่มด่าน
		var hovered := get_viewport().gui_get_hovered_control()
		if not (hovered is BaseButton):
			wants_start = true
	
	if wants_start:
		get_viewport().set_input_as_handled()
		_trigger_start_level()

func _init_scene() -> void:
	can_start = false
	is_starting = false
	can_fast_forward = true
	is_fast_forwarding = false
	current_stage = 1
	Engine.time_scale = 1.0
	is_tower_forward = true
	
	if tw_title and tw_title.is_valid():
		tw_title.kill()
		tw_title = null
	
	if skip_ctrl:
		skip_ctrl.visible = true
		if skip_ctrl.container:
			skip_ctrl.container.modulate.a = 1.0
	
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
		subtitle_label.text = "― ตำนานแห่งหอคอยต้นกำเนิด ―"
	if start_prompt:
		start_prompt.text = "คลิกหน้าจอเพื่อไปต่อ"
	fade_overlay.color = Color(0, 0, 0, 1)
	fade_overlay.visible = true

func _on_skip_step() -> void:
	if is_starting:
		return
	if current_stage == 1:
		_skip_to_stage_2()
	elif current_stage == 2:
		_skip_to_stage_3()
	else:
		_trigger_start_level()

func _skip_to_stage_2() -> void:
	if current_stage >= 2 or is_starting:
		return
	current_stage = 2
	if tw_stage1_fade and tw_stage1_fade.is_valid():
		tw_stage1_fade.kill()
		tw_stage1_fade = null
	if storm_sky.animation_finished.is_connected(_on_storm_sky_finished):
		storm_sky.animation_finished.disconnect(_on_storm_sky_finished)
	storm_sky.stop()
	storm_sky.visible = false
	fade_overlay.color.a = 0.0
	
	village.visible = true
	village.frame = 0
	village.modulate = Color(1, 1, 1, 1)
	village.play("village_chaos", 1.0)
	if not village.animation_finished.is_connected(_on_village_chaos_finished):
		village.animation_finished.connect(_on_village_chaos_finished, CONNECT_ONE_SHOT)

func _skip_to_stage_3() -> void:
	if is_starting:
		return
	current_stage = 3
	if tw_stage1_fade and tw_stage1_fade.is_valid():
		tw_stage1_fade.kill()
		tw_stage1_fade = null
	if tw_stage2_fade and tw_stage2_fade.is_valid():
		tw_stage2_fade.kill()
		tw_stage2_fade = null
	if tw_stage3_wait and tw_stage3_wait.is_valid():
		tw_stage3_wait.kill()
		tw_stage3_wait = null
	if storm_sky.animation_finished.is_connected(_on_storm_sky_finished):
		storm_sky.animation_finished.disconnect(_on_storm_sky_finished)
	storm_sky.stop()
	if village.animation_finished.is_connected(_on_village_chaos_finished):
		village.animation_finished.disconnect(_on_village_chaos_finished)
	village.stop()
	village.visible = false
	storm_sky.visible = false
	fade_overlay.color.a = 0.0
	
	tower.visible = true
	tower.modulate = Color(1, 1, 1, 1)
	_start_tower_ping_pong()
	
	if vel_shadow:
		vel_shadow.visible = true
		vel_shadow.modulate.a = 0.65
	vel.visible = true
	vel.modulate.a = 1.0
	
	if skip_ctrl:
		skip_ctrl.visible = false
	
	_reveal_game_title()

func play_chaos_sequence() -> void:
	current_stage = 1
	# 1. ค่อย ๆ สว่างขึ้นจากจอดำสู่ท้องฟ้าพายุ 0.5 วินาที
	if tw_stage1_fade and tw_stage1_fade.is_valid():
		tw_stage1_fade.kill()
	tw_stage1_fade = create_tween()
	tw_stage1_fade.tween_property(fade_overlay, "color:a", 0.0, 0.5)
	tw_stage1_fade.tween_callback(func():
		if current_stage != 1 or is_starting:
			return
		storm_sky.play("storm_sky", 1.0)
		if not storm_sky.animation_finished.is_connected(_on_storm_sky_finished):
			storm_sky.animation_finished.connect(_on_storm_sky_finished, CONNECT_ONE_SHOT)
	)

func _on_storm_sky_finished() -> void:
	if current_stage >= 2 or is_starting:
		return
	current_stage = 2
	# 2. สลับภาพสู่บ้านเมืองโกลาหล (เล่นแอนิเมชันตั้งแต่เฟรมที่ 20 ถึงจบ 58)
	village.visible = true
	village.frame = 0
	village.modulate = Color(1, 1, 1, 0)
	
	if tw_stage2_fade and tw_stage2_fade.is_valid():
		tw_stage2_fade.kill()
	tw_stage2_fade = create_tween()
	tw_stage2_fade.tween_property(village, "modulate:a", 1.0, 0.35)
	tw_stage2_fade.chain().tween_callback(func():
		storm_sky.visible = false
	)
	
	village.play("village_chaos", 1.0)
	if not village.animation_finished.is_connected(_on_village_chaos_finished):
		village.animation_finished.connect(_on_village_chaos_finished, CONNECT_ONE_SHOT)

func _on_village_chaos_finished() -> void:
	if current_stage >= 3 or is_starting:
		return
	current_stage = 3
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
	
	# ค่อย ๆ จางปุ่มควบคุมออกเมื่อเข้าสู่ฉากหอคอยและไตเติล
	if skip_ctrl:
		var tw_fade_btn = create_tween()
		tw_fade_btn.tween_property(skip_ctrl.container, "modulate:a", 0.0, 0.5)
		tw_fade_btn.tween_callback(func():
			if skip_ctrl:
				skip_ctrl.visible = false
		)
	
	if tw_stage3_wait and tw_stage3_wait.is_valid():
		tw_stage3_wait.kill()
	tw_stage3_wait = create_tween()
	tw_stage3_wait.tween_interval(1.5)
	tw_stage3_wait.tween_callback(func():
		if current_stage == 3 and not can_start and not is_starting:
			_reveal_game_title()
	)

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
	# หน้านี้เป็นหน้าไตเติลเกม (Git Di Waa) ซ่อนปุ่มเร่งและปุ่มข้ามออกทั้งหมดตามคำขอ
	can_fast_forward = false
	is_fast_forwarding = false
	Engine.time_scale = 1.0
	
	if skip_ctrl:
		if skip_ctrl.is_fast_forward:
			skip_ctrl._toggle_fast_forward()
		skip_ctrl.visible = false
	
	if tw_title and tw_title.is_valid():
		tw_title.kill()
	tw_title = create_tween()
	tw_title.tween_property(title_container, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# เมื่อไตเติลหอคอยขึ้นเสร็จสมบูรณ์ หากเสียงยังคงเล่นอยู่ ให้ค่อย ๆ เฟดเสียงตอนท้าย
	tw_title.chain().tween_callback(func():
		if CutsceneMusic.is_playing():
			CutsceneMusic.fade_out(2.5)
	)
	
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
	
	# ค่อย ๆ เฟดเสียงเพลงออกตอนท้ายพร้อมหน้าจอมืด
	CutsceneMusic.fade_out(0.6)
	
	var tw_out = create_tween()
	tw_out.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), 0.6)
	tw_out.tween_callback(func():
		Engine.time_scale = 1.0
		emit_signal("cutscene_finished")
		print("[CutsceneChaos] เข้าสู่ด่านแรกเรียบร้อย!")
		var target_scene := _get_resolved_next_scene()
		if target_scene != "" and ResourceLoader.exists(target_scene):
			get_tree().change_scene_to_file(target_scene)
		else:
			push_warning("[OutsideCutscene] target scene not found: '%s'" % target_scene)
			var tw_recover = create_tween()
			tw_recover.tween_property(fade_overlay, "color:a", 0.0, 0.5)
			can_start = true
			is_starting = false
	)
