extends Node2D

## การควบคุมฉากจบเกมทั้ง 8 ฉาก (Ending Cutscene - Complete 8 Stages)
## 1. การฟื้นฟูคัมภีร์เวทต้นกำเนิด (khampri-null + ดูดเศษ 16 ชิ้นพร้อมกัน -> khampri สมบูรณ์)
## 2. ท้องฟ้าโกลาหลกลับคืนสู่สภาพปกติ (animated storm sky -> animated peaceful sky)
## 3. บ้านเมืองกลับคืนสู่ความสงบ (animated chaos village -> peaceful village)
## 4. เวลถูกวาร์ปกลับห้องสมุด (ห้องโล่ง -> วาร์ปมาตกใจ -> คัมภีร์ตกจากฟ้าลงมือ -> ท่า vel_hold)
## 5. การกลับมาของปรมาจารย์ (หลุมดำเปิด เวลกระโดดตกใจ คัมภีร์ลอย อาจารย์พุ่งขึ้นมา ยิ้มกวน)
## 6. ช่องการ์ตูนเฉลยความจริง (Comic frame ซูมอาจารย์แก่หลงลืม พลังรั่วตกหลุมตัวเอง)
## 7. กล่องบทสนทนา (คลิกหน้าจอเพื่อไปต่อ 3 ประโยคตามบท)
## 8. บทสรุปการเดินทางของเวล (ซูมกล้องออก -> จอดำ -> ข้อความสรุป -> THE END -> ปุ่มกลับสู่หน้าหลัก)

@export var start_scene_path: String = "res://scenes/StartView.tscn"

# Camera & Overlays
@onready var camera: Camera2D = $Camera2D
@onready var white_flash: ColorRect = $WhiteFlashOverlay

# Stage 1: Book Restoration
@onready var stage1: Node2D = $Stage1_BookRestoration
@onready var khampri_null: Sprite2D = $Stage1_BookRestoration/KhampriNull
@onready var khampri_full: Sprite2D = $Stage1_BookRestoration/KhampriFull
@onready var shards_container: Node2D = $Stage1_BookRestoration/ShardsContainer

# Stage 2: Sky Restoration
@onready var stage2: Node2D = $Stage2_SkyRestoration
@onready var storm_sky: Sprite2D = $Stage2_SkyRestoration/StormSky
@onready var peaceful_sky: Sprite2D = $Stage2_SkyRestoration/PeacefulSky

# Stage 3: Village Restoration
@onready var stage3: Node2D = $Stage3_VillageRestoration
@onready var village_animated: Sprite2D = $Stage3_VillageRestoration/VillageAnimated

# Stage 4-8: Library
@onready var stage4: Node2D = $Stage4_Library
@onready var library_bg: Sprite2D = $Stage4_Library/LibraryBg
@onready var dark_overlay: ColorRect = $Stage4_Library/DarkOverlay
@onready var black_hole: Sprite2D = $Stage4_Library/BlackHole
@onready var khampri_shadow: Sprite2D = $Stage4_Library/KhampriShadow
@onready var khampri_floating: Sprite2D = $Stage4_Library/KhampriFloating
@onready var vel: AnimatedSprite2D = $Stage4_Library/Vel
@onready var exclamation_mark: Sprite2D = $Stage4_Library/Vel/ExclamationMark
@onready var master_char: AnimatedSprite2D = $Stage4_Library/Master

# Stage 6: Comic Flashback Panel
@onready var comic_container: Control = $ComicPanelContainer
@onready var comic_title: Label = $ComicPanelContainer/ComicTitle
@onready var comic_caption: Label = $ComicPanelContainer/ComicCaption
@onready var flashback_master: AnimatedSprite2D = $ComicPanelContainer/ComicPanelBg/FlashbackMaster
@onready var flashback_hole: Sprite2D = $ComicPanelContainer/ComicPanelBg/FlashbackHole

# UI Elements
@onready var magic_ui: CanvasLayer = $MagicStoryUI
@onready var dialogue_box: PanelContainer = $MagicStoryUI/DialogueBox
@onready var speaker_label: Label = $MagicStoryUI/DialogueBox/Margin/VBox/SpeakerLabel
@onready var dialogue_label: Label = $MagicStoryUI/DialogueBox/Margin/VBox/DialogueLabel
@onready var continue_prompt: Label = $MagicStoryUI/DialogueBox/Margin/VBox/ContinuePrompt
@onready var the_end_container: Control = $MagicStoryUI/TheEndContainer
@onready var return_menu_btn: Button = $MagicStoryUI/TheEndContainer/ReturnMenuBtn

# Audio (SFX only, NO BGM)
@onready var sfx_fusion: AudioStreamPlayer = $Audio/SfxFusion
@onready var sfx_warp: AudioStreamPlayer = $Audio/SfxWarp
@onready var sfx_pop: AudioStreamPlayer = $Audio/SfxPop
@onready var sfx_next: AudioStreamPlayer = $Audio/SfxNext
@onready var sfx_success: AudioStreamPlayer = $Audio/SfxSuccess

var shards16: Array[Sprite2D] = []
var shard_initial_positions: Array[Vector2] = []
var current_stage: int = 1
var is_waiting_dialogue: bool = false
var dialogue_callback: Callable = Callable()
var is_fast_forwarding: bool = false
var can_fast_forward: bool = true
var typewriter_tween: Tween = null

# Animation timers for spritesheets
var storm_anim_timer: float = 0.0
var peaceful_anim_timer: float = 0.0
var village_anim_timer: float = 0.0
var village_is_restoring: bool = false
var village_current_frame: float = 58.0

# Camera shake
var camera_shake_amount: float = 0.0

func _ready() -> void:
	Engine.time_scale = 1.0
	
	# เพิ่มปุ่มข้าม cutscene
	var skip_btn = preload("res://scripts/cutscene/skip_cutscene_button.gd").new()
	skip_btn.next_scene_path = start_scene_path
	add_child(skip_btn)
	
	_init_shards()
	_reset_all_stages()
	
	if return_menu_btn:
		return_menu_btn.pressed.connect(_on_return_menu_pressed)
	
	play_stage_1_book_restoration()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _process(delta: float) -> void:
	# อัปเดตเฟรมแอนิเมชันของท้องฟ้าในฉาก 2
	if current_stage == 2:
		storm_anim_timer += delta * 12.0
		if storm_sky.visible:
			storm_sky.frame = int(storm_anim_timer) % 66
		
		peaceful_anim_timer += delta * 10.0
		if peaceful_sky.visible:
			peaceful_sky.frame = int(peaceful_anim_timer) % 66

	# อัปเดตเฟรมแอนิเมชันของหมู่บ้านในฉาก 3
	if current_stage == 3:
		if not village_is_restoring:
			# ช่วงโกลาหล เล่นเฟรม 54 ถึง 62
			village_anim_timer += delta * 8.0
			village_animated.frame = 54 + (int(village_anim_timer) % 9)
		else:
			# ช่วงเวทมนตร์เยียวยา ถอยกลับสู่สภาพสงบ (เฟรม 0)
			if village_current_frame > 0.0:
				village_current_frame = maxf(0.0, village_current_frame - (delta * 32.0))
				village_animated.frame = int(village_current_frame)
			else:
				# หยุดนิ่งที่เฟรม 0 (หมู่บ้านสงบสุขสมบูรณ์)
				village_animated.frame = 0

	# ระบบสั่นของกล้อง (Camera shake)
	if camera_shake_amount > 0.0:
		camera.offset = Vector2(
			randf_range(-camera_shake_amount, camera_shake_amount),
			randf_range(-camera_shake_amount, camera_shake_amount)
		)
		camera_shake_amount = maxf(0.0, camera_shake_amount - delta * 12.0)
	else:
		camera.offset = Vector2.ZERO

	# เร่งความเร็ว (Fast forward) เมื่อกดค้าง และไม่อยู่ในช่วงรอคลิกบทสนทนา
	if can_fast_forward and not is_waiting_dialogue:
		var wants_ff: bool = Input.is_key_pressed(KEY_SPACE) or \
			Input.is_key_pressed(KEY_ENTER) or \
			Input.is_key_pressed(KEY_SHIFT) or \
			Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		
		if wants_ff != is_fast_forwarding:
			is_fast_forwarding = wants_ff
			Engine.time_scale = 2.5 if wants_ff else 1.0

func _input(event: InputEvent) -> void:
	if not is_waiting_dialogue:
		return
	
	if event.is_action_pressed("ui_accept") or \
	   (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)) or \
	   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
		_advance_dialogue()

func _advance_dialogue() -> void:
	if not is_waiting_dialogue:
		return
	
	# หากตัวหนังสือกำลังพิมพ์อยู่ ให้คลิกเพื่อแสดงเต็มทันที
	if dialogue_label.visible_ratio < 0.95:
		if typewriter_tween and typewriter_tween.is_valid():
			typewriter_tween.kill()
		dialogue_label.visible_ratio = 1.0
		return
	
	is_waiting_dialogue = false
	_play_sfx(sfx_next)
	
	if dialogue_callback.is_valid():
		dialogue_callback.call()

func _init_shards() -> void:
	shards16.clear()
	shard_initial_positions.clear()
	for child in shards_container.get_children():
		if child is Sprite2D:
			shards16.append(child)

func _reset_all_stages() -> void:
	can_fast_forward = true
	is_fast_forwarding = false
	Engine.time_scale = 1.0
	camera.position = Vector2(960, 540)
	camera.zoom = Vector2.ONE
	camera.offset = Vector2.ZERO
	camera_shake_amount = 0.0
	
	# ซ่อน/แสดงแต่ละ Stage
	stage1.visible = true
	stage2.visible = false
	stage3.visible = false
	stage4.visible = false
	comic_container.visible = false
	white_flash.visible = false
	white_flash.color = Color(1, 1, 1, 0.0)
	dialogue_box.visible = false
	the_end_container.visible = false
	if dark_overlay:
		dark_overlay.visible = false
	
	# เตรียม Stage 1
	khampri_null.visible = true
	khampri_null.scale = Vector2(0.1, 0.1)
	khampri_null.modulate = Color(1, 1, 1, 0.0)
	khampri_full.visible = false
	khampri_full.scale = Vector2(2.8, 2.8)
	
	# จัดตำแหน่งเศษ 16 ชิ้นกระจายรอบคัมภีร์
	var count = shards16.size()
	for i in range(count):
		var s: Sprite2D = shards16[i]
		var angle: float = (float(i) / float(count)) * TAU - (PI * 0.5)
		var dist: float = 330.0 if (i % 2 == 0) else 270.0
		var pos = Vector2(cos(angle) * dist * 1.3, sin(angle) * dist)
		shard_initial_positions.append(pos)
		s.position = pos
		s.scale = Vector2(0.9, 0.9)
		s.rotation = angle + (PI * 0.5)
		s.modulate = Color(1, 1, 1, 0.0)
		s.visible = true

## =============================================================
## ฉากที่ 1: การฟื้นฟูคัมภีร์เวทต้นกำเนิด
## คัมภีร์เปล่าโผล่มาตรงกลาง เศษ 16 ชิ้นโผล่รอบๆ แล้วพุ่งเข้าพร้อมกัน
## =============================================================
func play_stage_1_book_restoration() -> void:
	current_stage = 1
	
	# 1.1 คัมภีร์เปล่าขนาดใหญ่ค่อย ๆ ปรากฏขึ้นกึ่งกลางจอ (1.2s)
	var tw_book = create_tween().set_parallel(true)
	tw_book.tween_property(khampri_null, "modulate:a", 1.0, 1.2)
	tw_book.tween_property(khampri_null, "scale", Vector2(2.8, 2.8), 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 1.2 เศษคัมภีร์ทั้ง 16 ชิ้น ปรากฏขึ้นรอบ ๆ พร้อมกัน แล้วหยุดนิ่งชั่วครู่ (1.4s -> 2.4s)
	var tw_shards_in = create_tween()
	tw_shards_in.tween_interval(1.4)
	tw_shards_in.tween_callback(func():
		for s in shards16:
			var tw_s = create_tween().set_parallel(true)
			tw_s.tween_property(s, "modulate", Color(1.8, 1.6, 1.1, 1.0), 0.8).set_trans(Tween.TRANS_SINE)
	)
	
	# 1.3 เศษทั้ง 16 ชิ้น พุ่งเข้าหาคัมภีร์เปล่าพร้อม ๆ กัน! (2.6s)
	var tw_absorb = create_tween()
	tw_absorb.tween_interval(2.6)
	tw_absorb.tween_callback(func():
		_play_sfx(sfx_fusion)
		camera_shake_amount = 4.0
		
		for s in shards16:
			var tw_fly = create_tween().set_parallel(true)
			tw_fly.tween_property(s, "position", Vector2.ZERO, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tw_fly.tween_property(s, "scale", Vector2(0.15, 0.15), 0.75)
			tw_fly.tween_property(s, "rotation", s.rotation + PI * 2.0, 0.75)
			tw_fly.chain().tween_callback(func(): s.visible = false)
	)
	
	# 1.4 เมื่อเศษเข้าไปครบ คัมภีร์เปล่งแสงวาบกลายเป็นคัมภีร์สมบูรณ์ (3.4s)
	var tw_complete = create_tween()
	tw_complete.tween_interval(3.4)
	tw_complete.tween_callback(func():
		_play_sfx(sfx_success)
		camera_shake_amount = 7.0
		khampri_null.visible = false
		khampri_full.visible = true
		khampri_full.modulate = Color(3.5, 3.0, 2.0, 1.0)
		khampri_full.scale = Vector2(3.5, 3.5)
		
		var tw_shine = create_tween().set_parallel(true)
		tw_shine.tween_property(khampri_full, "scale", Vector2(2.8, 2.8), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_shine.tween_property(khampri_full, "modulate", Color(1.8, 1.6, 1.2, 1.0), 0.8)
	)
	
	# 1.5 แสงวาบสีขาวสว่างจ้าเต็มจอเพื่อตัดเข้าสู่ฉาก 2 (5.0s)
	var tw_flash = create_tween()
	tw_flash.tween_interval(5.0)
	tw_flash.tween_callback(func():
		_play_sfx(sfx_warp)
		white_flash.visible = true
		var tw_wf = create_tween()
		tw_wf.tween_property(white_flash, "color:a", 1.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_wf.tween_callback(play_stage_2_sky_restoration)
	)

## =============================================================
## ฉากที่ 2: ท้องฟ้าโกลาหลกลับคืนสู่สภาพปกติ (ใช้ภาพขยับ animated spritesheet)
## =============================================================
func play_stage_2_sky_restoration() -> void:
	current_stage = 2
	stage1.visible = false
	stage2.visible = true
	storm_sky.visible = true
	storm_sky.modulate = Color(1, 1, 1, 1)
	peaceful_sky.visible = true
	peaceful_sky.modulate = Color(1, 1, 1, 0)
	
	# แสงวาบจางลง เผยให้เห็นท้องฟ้าพายุที่กำลังเคลื่อนไหว (0.6s)
	var tw_unflash = create_tween()
	tw_unflash.tween_property(white_flash, "color:a", 0.0, 0.6)
	
	# 2.2 เล่นภาพพายุประมาณ 2 วินาที -> เกิดแสงวาบเปลี่ยนเป็นท้องฟ้าสดใส (2.2s -> 3.5s)
	var tw_magic_sweep = create_tween()
	tw_magic_sweep.tween_interval(2.2)
	tw_magic_sweep.tween_callback(func():
		_play_sfx(sfx_warp)
		
		# แสงสว่างวาบทั่วท้องฟ้า
		var tw_glare = create_tween()
		tw_glare.tween_property(white_flash, "color:a", 0.7, 0.35)
		tw_glare.tween_property(white_flash, "color:a", 0.0, 0.45)
		
		# ท้องฟ้าพายุจางหาย เผยท้องฟ้าสดใสที่กำลังเคลื่อนไหว
		var tw_sky = create_tween().set_parallel(true)
		tw_sky.tween_property(storm_sky, "modulate:a", 0.0, 1.0)
		tw_sky.tween_property(peaceful_sky, "modulate:a", 1.0, 1.0)
	)
	
	# ค้างท้องฟ้าสงบ 2.5 วินาที แล้วตัดไปฉาก 3 (5.2s)
	var tw_next = create_tween()
	tw_next.tween_interval(5.2)
	tw_next.tween_callback(func():
		var tw_wf = create_tween()
		tw_wf.tween_property(white_flash, "color:a", 1.0, 0.5)
		tw_wf.tween_callback(play_stage_3_village_restoration)
	)

## =============================================================
## ฉากที่ 3: บ้านเมืองกลับคืนสู่ความสงบ (ใช้ภาพขยับ animated spritesheet)
## แสดงความโกลาหล -> แสงเวทมนตร์เยียวยา -> คืนสู่ความสงบ (ค้างนานกว่าฉาก 2)
## =============================================================
func play_stage_3_village_restoration() -> void:
	current_stage = 3
	stage2.visible = false
	stage3.visible = true
	village_is_restoring = false
	village_animated.visible = true
	village_animated.modulate = Color(1, 1, 1, 1)
	village_current_frame = 58.0
	
	# แสงวาบจางลง เผยภาพเมืองโกลาหลกำลังเคลื่อนไหว (0.6s)
	var tw_unflash = create_tween()
	tw_unflash.tween_property(white_flash, "color:a", 0.0, 0.6)
	
	# 3.2 หลังเล่นภาพโกลาหล 2.5 วินาที เกิดแสงเวทมนตร์คลี่คลายสภาพเมืองสู่ความสงบ
	var tw_restore = create_tween()
	tw_restore.tween_interval(2.5)
	tw_restore.tween_callback(func():
		_play_sfx(sfx_success)
		village_is_restoring = true
		
		var tw_glare = create_tween()
		tw_glare.tween_property(white_flash, "color:a", 0.75, 0.35)
		tw_glare.tween_property(white_flash, "color:a", 0.0, 0.5)
	)
	
	# ค้างภาพเมืองที่สงบสุขนานขึ้น (~4 วินาที) แล้วตัดเข้าสู่ฉาก 4 ห้องสมุด (7.0s)
	var tw_next = create_tween()
	tw_next.tween_interval(7.0)
	tw_next.tween_callback(func():
		var tw_wf = create_tween()
		tw_wf.tween_property(white_flash, "color:a", 1.0, 0.6)
		tw_wf.tween_callback(play_stage_4_vel_in_library)
	)

## =============================================================
## ฉากที่ 4: เวลถูกวาร์ปกลับห้องสมุด
## หอสมุดโล่งๆ ก่อน 1.2s -> เวลวาร์ปกลับมาทำหน้าตกใจ
## คัมภีร์โผล่สูงๆ ตกลงมาในมือ -> เปลี่ยนเป็นท่า hold (ยังไม่มีบทพูด)
## =============================================================
func play_stage_4_vel_in_library() -> void:
	current_stage = 4
	stage3.visible = false
	stage4.visible = true
	
	# เริ่มต้นห้องสมุดว่างเปล่า ไม่มีตัวละคร
	vel.visible = false
	master_char.visible = false
	black_hole.visible = false
	khampri_floating.visible = false
	khampri_shadow.visible = false
	exclamation_mark.visible = false
	if dark_overlay:
		dark_overlay.visible = false
	
	# แสงขาวจางลง เผยห้องสมุดโล่งๆ เงียบสงบ (0.8s)
	var tw_unflash = create_tween()
	tw_unflash.tween_property(white_flash, "color:a", 0.0, 0.8)
	
	# 4.1 เวลวาร์ปปรากฏตัวขึ้นมากลางห้อง พร้อมทำหน้าตกใจ vel_shock (1.2s)
	var tw_warp_vel = create_tween()
	tw_warp_vel.tween_interval(1.2)
	tw_warp_vel.tween_callback(func():
		_play_sfx(sfx_warp)
		vel.visible = true
		vel.position = Vector2(-10, 59)
		vel.play("shock")
		vel.scale = Vector2(0.1, 0.1)
		vel.modulate = Color(2.0, 2.0, 2.0, 0.0)
		
		var tw_v = create_tween().set_parallel(true)
		tw_v.tween_property(vel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_v.tween_property(vel, "modulate", Color(1, 1, 1, 1), 0.35)
	)
	
	# 4.2 คัมภีร์โผล่มาสูงๆ เหนือหัว แล้วตกลงมาในมือเวล (2.2s)
	var tw_book_drop = create_tween()
	tw_book_drop.tween_interval(2.2)
	tw_book_drop.tween_callback(func():
		khampri_floating.visible = true
		khampri_floating.position = Vector2(-10, -85) # สูงเหนือหัวเวล
		khampri_floating.scale = Vector2(0.18, 0.18)
		khampri_floating.modulate = Color(1.8, 1.6, 1.1, 1.0)
		
		khampri_shadow.visible = true
		khampri_shadow.position = Vector2(-10, 98)
		khampri_shadow.scale = Vector2(0.1, 0.05)
		khampri_shadow.modulate = Color(1, 1, 1, 0.0)
		
		# คัมภีร์ตกลงมาใส่สองมือเวล
		var tw_drop = create_tween().set_parallel(true)
		tw_drop.tween_property(khampri_floating, "position:y", 14.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_drop.tween_property(khampri_shadow, "scale", Vector2(0.8, 0.4), 0.55)
		tw_drop.tween_property(khampri_shadow, "modulate:a", 0.4, 0.55)
		
		# เมื่อตกถึงมือ เด้งเบาๆ และเวลเปลี่ยนเป็นท่า vel_hold ทันที
		tw_drop.chain().tween_callback(func():
			_play_sfx(sfx_pop)
			vel.play("hold")
			
			# เด้งเล็กน้อย
			var tw_bounce = create_tween()
			tw_bounce.tween_property(khampri_floating, "position:y", 8.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_bounce.tween_property(khampri_floating, "position:y", 14.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		)
	)
	
	# ค้างบรรยากาศเงียบสงบโดยไม่มีบทพูด 2.5 วินาที แล้วเริ่มฉาก 5 (4.8s)
	var tw_next = create_tween()
	tw_next.tween_interval(4.8)
	tw_next.tween_callback(play_stage_5_master_return)

## =============================================================
## ฉากที่ 5: การกลับมาของปรมาจารย์
## หลุมดำเปิด สั่นสะเทือน เวลตกใจกระโดดขึ้น คัมภีร์ลอยค้าง 0.4 วิ แล้วตกลงมาในมือ
## อาจารย์พุ่งขึ้นมาจากหลุมดำ ยืนนิ่ง 1 วิ แล้วเปลี่ยนเป็นยิ้มกวน เวลอึ้งสุดขีด
## =============================================================
func play_stage_5_master_return() -> void:
	current_stage = 5
	
	# 5.1 หลุมดำเปิดขึ้นทางขวา มีแรงสั่นสะเทือนเล็กน้อย (0.6s)
	var tw_hole = create_tween()
	tw_hole.tween_interval(0.6)
	tw_hole.tween_callback(func():
		camera_shake_amount = 3.5
		black_hole.visible = true
		black_hole.position = Vector2(45, 96)
		black_hole.scale = Vector2.ZERO
		var tw_bh = create_tween()
		tw_bh.tween_property(black_hole, "scale", Vector2(1.2, 1.0), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	
	# 5.2 เวลตกใจกระโดดขึ้น หนังสือหลุดมือลอยขึ้นฟ้า (1.1s)
	var tw_vel_startle = create_tween()
	tw_vel_startle.tween_interval(1.1)
	tw_vel_startle.tween_callback(func():
		_play_sfx(sfx_pop)
		vel.play("shock")
		
		# เวลกระโดดตัวลอย
		var tw_vjump = create_tween()
		tw_vjump.tween_property(vel, "position:y", 38.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_vjump.tween_property(vel, "position:y", 59.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		# หนังสือหลุดมือลอยขึ้นไปสูงกว่าตัวเวล
		var tw_bjump = create_tween()
		tw_bjump.tween_property(khampri_floating, "position:y", -30.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# ค้างอยู่กลางอากาศแป๊บนึง (0.4 วิ)
		tw_bjump.tween_interval(0.4)
		# ตกลงมาใส่มือเวลเหมือนเดิม
		tw_bjump.tween_property(khampri_floating, "position:y", 14.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_bjump.tween_callback(func():
			vel.play("hold")
		)
	)
	
	# 5.3 อาจารย์พุ่งขึ้นมาจากหลุมดำ ลงมายืนที่พื้น (2.3s)
	var tw_master_emerge = create_tween()
	tw_master_emerge.tween_interval(2.3)
	tw_master_emerge.tween_callback(func():
		_play_sfx(sfx_pop)
		camera_shake_amount = 5.0
		master_char.visible = true
		master_char.position = Vector2(45, 96)
		master_char.scale = Vector2(0.2, 0.2)
		master_char.modulate = Color(1, 1, 1, 1)
		master_char.play("shock1")
		
		# ดีดตัวพุ่งขึ้นสู่ความสูง 28px แล้วลงมายืนที่ 59px
		var tw_m = create_tween().set_parallel(true)
		tw_m.tween_property(master_char, "position:y", 28.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_m.tween_property(master_char, "scale", Vector2.ONE, 0.32)
		
		tw_m.chain().tween_property(master_char, "position:y", 59.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		# หลุมดำปิดตัวลงทันทีหลังอาจารย์ขึ้นมา
		var tw_close = create_tween()
		tw_close.tween_property(black_hole, "scale", Vector2.ZERO, 0.25)
		tw_close.tween_callback(func(): black_hole.visible = false)
		
		# อาจารย์ยืนนิ่งทำหน้าธรรมดา (idle) 1 วินาที
		tw_m.chain().tween_callback(func():
			master_char.play("idle")
		)
	)
	
	# 5.4 อาจารย์เปลี่ยนเป็นยิ้มกวนๆ ตาหยี (playful) & เวลอึ้งตกใจสุดขีด (3.5s)
	var tw_expressions = create_tween()
	tw_expressions.tween_interval(3.5)
	tw_expressions.tween_callback(func():
		# อาจารย์ยิ้มกวนแบบไม่รู้ร้อนรู้หนาว (master_playful)
		master_char.play("playful")
		
		# เวลอึ้ง ตกใจสุดขีดเมื่อเห็นว่าเป็นอาจารย์
		vel.play("shock")
		exclamation_mark.visible = true
		exclamation_mark.scale = Vector2.ZERO
		var tw_ex = create_tween()
		tw_ex.tween_property(exclamation_mark, "scale", Vector2(1.3, 1.3), 0.12)
		tw_ex.tween_property(exclamation_mark, "scale", Vector2.ONE, 0.1)
	)
	
	# เข้าสู่ฉาก 6 (ช่องการ์ตูนย้อนอดีต) (5.0s)
	var tw_next = create_tween()
	tw_next.tween_interval(5.0)
	tw_next.tween_callback(play_stage_6_comic_flashback)

## =============================================================
## ฉากที่ 6: เฉลยความจริงเบื้องหลัง (ช่องสี่เหลี่ยมกรอบการ์ตูน Flashback)
## ซูมอาจารย์แก่หลงลืม พลังรั่วตกหลุมตัวเอง
## =============================================================
func play_stage_6_comic_flashback() -> void:
	current_stage = 6
	exclamation_mark.visible = false
	
	# ห้องสมุดมืดลงเล็กน้อย
	if dark_overlay:
		dark_overlay.visible = true
		dark_overlay.modulate = Color(1, 1, 1, 0.0)
		var tw_dim = create_tween()
		tw_dim.tween_property(dark_overlay, "modulate:a", 1.0, 0.4)
	
	# กรอบการ์ตูนสี่เหลี่ยมโผล่ขึ้นมาตรงกลาง (ซูมภาพอาจารย์)
	comic_container.visible = true
	comic_container.scale = Vector2(0.2, 0.2)
	comic_container.modulate = Color(1, 1, 1, 0.0)
	comic_container.pivot_offset = comic_container.size * 0.5
	
	flashback_master.visible = true
	flashback_master.position = Vector2(360, 240)
	flashback_master.scale = Vector2(3.0, 3.0)
	flashback_master.modulate = Color(1, 1, 1, 1)
	flashback_master.play("walk")
	flashback_hole.visible = false
	
	var tw_panel_in = create_tween().set_parallel(true)
	tw_panel_in.tween_property(comic_container, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_panel_in.tween_property(comic_container, "modulate:a", 1.0, 0.45)
	
	# แอนิเมชันในกรอบ: อาจารย์เดินเพลินๆ พลังเวทตกหล่นเกิดหลุมดำใต้ฝ่าเท้า (1.2s)
	var tw_hole_open = create_tween()
	tw_hole_open.tween_interval(1.2)
	tw_hole_open.tween_callback(func():
		flashback_hole.visible = true
		flashback_hole.scale = Vector2.ZERO
		var tw_h = create_tween()
		tw_h.tween_property(flashback_hole, "scale", Vector2(3.0, 2.4), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		# อาจารย์สะดุดตกใจเหวอ (shock2)
		flashback_master.play("shock2")
	)
	
	# อาจารย์ร่วงหล่นลงไปในหลุมดำของตัวเอง (2.2s)
	var tw_fall = create_tween()
	tw_fall.tween_interval(2.2)
	tw_fall.tween_callback(func():
		_play_sfx(sfx_warp)
		var tw_m_fall = create_tween().set_parallel(true)
		tw_m_fall.tween_property(flashback_master, "position:y", 370.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_m_fall.tween_property(flashback_master, "scale", Vector2(0.5, 0.5), 0.55)
		tw_m_fall.tween_property(flashback_master, "modulate:a", 0.0, 0.55)
		
		# หลุมดำปิดตามลงไป
		tw_m_fall.chain().tween_property(flashback_hole, "scale", Vector2.ZERO, 0.3)
	)
	
	# กรอบการ์ตูนหายไป กลับสู่ปัจจุบัน (4.8s)
	var tw_panel_out = create_tween()
	tw_panel_out.tween_interval(4.8)
	tw_panel_out.tween_callback(func():
		var tw_out = create_tween().set_parallel(true)
		tw_out.tween_property(comic_container, "scale", Vector2(0.3, 0.3), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw_out.tween_property(comic_container, "modulate:a", 0.0, 0.35)
		if dark_overlay:
			tw_out.tween_property(dark_overlay, "modulate:a", 0.0, 0.35)
		
		tw_out.chain().tween_callback(func():
			comic_container.visible = false
			if dark_overlay:
				dark_overlay.visible = false
			play_stage_7_dialogue()
		)
	)

## =============================================================
## ฉากที่ 7: บทสนทนา (คลิกหน้าจอเพื่อไปต่อ)
## =============================================================
func play_stage_7_dialogue() -> void:
	current_stage = 7
	
	# อาจารย์ยืนมองเวลตาใส
	master_char.play("breathe_blink")
	
	# ประโยคที่ 1: อาจารย์ถาม
	_show_dialogue(
		"ปรมาจารย์",
		"อ้าว เวล... เกิดอะไรขึ้นเนี่ย แล้วทำไมดูเหนื่อยมอมแมมแบบนี้ล่ะ?",
		_dialogue_line_2_vel
	)

func _dialogue_line_2_vel() -> void:
	# เวลทำหน้างอน/มุ่ยแก้ม (vel_angry)
	vel.play("angry")
	
	# ประโยคที่ 2: เวลตอบ
	_show_dialogue(
		"เวล",
		"เฮ้อ... ทั้งหมดนี่เป็นเพราะอาจารย์เองสินะ...",
		_dialogue_line_3_master
	)

func _dialogue_line_3_master() -> void:
	# อาจารย์ยิ้มกวนๆ ตาหยี แลบลิ้น (playful)
	master_char.play("playful")
	
	# ประโยคที่ 3: อาจารย์หัวเราะ
	_show_dialogue(
		"ปรมาจารย์",
		"ฉันเองหรอเนี่ย_55555",
		func():
			_hide_dialogue(play_stage_8_epilogue)
	)

## =============================================================
## ฉากที่ 8: บทสรุปการเดินทางของเวล (The End)
## ซูมออก -> จอดำ -> ข้อความสรุป -> THE END -> ปุ่มกลับสู่หน้าหลัก
## =============================================================
func play_stage_8_epilogue() -> void:
	current_stage = 8
	can_fast_forward = false
	is_fast_forwarding = false
	Engine.time_scale = 1.0
	
	# เวลมองคัมภีร์ในมือแล้วยิ้มบางๆ อาจารย์ยืนยิ้มอยู่ข้างๆ
	vel.play("hold")
	master_char.play("playful")
	
	# กล้องค่อย ๆ ซูมออก เผยภาพกว้างของห้องสมุด (3.0s)
	var tw_zoom = create_tween().set_parallel(true)
	tw_zoom.tween_property(camera, "zoom", Vector2(0.85, 0.85), 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# ภาพค่อย ๆ มืดลง (Fade to Black) (2.5s)
	var tw_fade_dark = create_tween()
	tw_fade_dark.tween_interval(2.5)
	tw_fade_dark.tween_callback(func():
		the_end_container.visible = true
		the_end_container.modulate = Color(1, 1, 1, 0)
		var tw_te = create_tween()
		tw_te.tween_property(the_end_container, "modulate:a", 1.0, 1.4).set_trans(Tween.TRANS_SINE)
		return_menu_btn.grab_focus()
	)

## =============================================================
## ระบบกล่องข้อความบทสนทนา (Helper Functions)
## =============================================================
func _show_dialogue(speaker: String, text: String, on_continue: Callable) -> void:
	is_waiting_dialogue = true
	dialogue_callback = on_continue
	
	speaker_label.text = speaker
	dialogue_label.text = text
	dialogue_label.visible_characters = 0
	
	dialogue_box.visible = true
	dialogue_box.modulate = Color(1, 1, 1, 0)
	dialogue_box.scale = Vector2(0.96, 0.96)
	dialogue_box.pivot_offset = dialogue_box.size * 0.5
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(dialogue_box, "modulate:a", 1.0, 0.25)
	tw.tween_property(dialogue_box, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# เอฟเฟกต์พิมพ์ตัวอักษรทีละตัว (Typewriter)
	if typewriter_tween and typewriter_tween.is_valid():
		typewriter_tween.kill()
	
	var duration: float = minf(float(text.length()) * 0.035, 1.5)
	typewriter_tween = create_tween()
	typewriter_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)

func _hide_dialogue(on_finish: Callable) -> void:
	is_waiting_dialogue = false
	if typewriter_tween and typewriter_tween.is_valid():
		typewriter_tween.kill()
		
	var tw = create_tween()
	tw.tween_property(dialogue_box, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func():
		dialogue_box.visible = false
		if on_finish.is_valid():
			on_finish.call()
	)

func _on_return_menu_pressed() -> void:
	_play_sfx(sfx_warp)
	var tw = create_tween()
	tw.tween_property(the_end_container, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file(start_scene_path)
	)

func _play_sfx(player: AudioStreamPlayer) -> void:
	if player and player.stream:
		player.play()

