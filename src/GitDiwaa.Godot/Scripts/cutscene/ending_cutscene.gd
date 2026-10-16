extends Node2D

## การควบคุมฉากจบเกมทั้ง 8 ฉาก (Ending Cutscene - Complete 8 Stages)
## 1. การฟื้นฟูคัมภีร์เวทต้นกำเนิด (khampri-null + ดูดเศษ 16 ชิ้นพร้อมกัน -> khampri สั่น 3 ครั้ง + ปล่อยวงแสง)
## 2. ท้องฟ้าโกลาหลกลับคืนสู่สภาพปกติ (animated storm sky -> แสงวาบนุ่มนวล 0.3s -> animated peaceful sky)
## 3. บ้านเมืองกลับคืนสู่ความสงบ (animated chaos village -> แสงเวทเยียวยา -> peaceful village ต่อเนื่อง)
## 4. เวลถูกวาร์ปกลับห้องสมุด (ห้องโล่ง -> วาร์ปพร้อมวงแสงที่พื้น -> คัมภีร์ตกใส่มือแล้วเปลี่ยนเป็น vel_hold พอดี)
## 5. การกลับมาของปรมาจารย์ (หลุมดำเปิด เวลสะดุ้งกระโดด หนังสือเด้งลอยค้างแล้วรับกลับมา -> อาจารย์พุ่งขึ้นมา)
## 6. ช่องการ์ตูนเฉลยความจริง (ขยายกรอบใหญ่ ซูมอาจารย์เด่นชัด ฉากหลังมืด 65% อาจารย์หลงลืมตกหลุมตัวเอง)
## 7. กล่องบทสนทนา (อาจารย์ยิ้มขี้เล่น เวลยืนนิ่ง 1 วินาทีเน้นอารมณ์ ก่อนถอนหายใจ)
## 8. บทสรุปการเดินทางของเวล (ซูมกล้องออก -> พื้นหลังมืดลงอย่างต่อเนื่อง -> ข้อความสรุปกระชับชัดเจน -> THE END)

@export var start_scene_path: String = "res://scenes/StartView.tscn"

# Camera & Overlays
@onready var camera: Camera2D = $Camera2D
@onready var white_flash: ColorRect = $WhiteFlashOverlay

# Stage 1: Book Restoration
@onready var stage1: Node2D = $Stage1_BookRestoration
@onready var ring_of_light: Sprite2D = $Stage1_BookRestoration/RingOfLight
@onready var book_aura: Sprite2D = $Stage1_BookRestoration/BookAura
@onready var khampri_null: Sprite2D = $Stage1_BookRestoration/KhampriNull
@onready var khampri_full: Sprite2D = $Stage1_BookRestoration/KhampriFull
@onready var shards_container: Node2D = $Stage1_BookRestoration/ShardsContainer

# Stage 2: Sky Restoration
@onready var stage2: Node2D = $Stage2_SkyRestoration
@onready var storm_sky: Sprite2D = $Stage2_SkyRestoration/StormSky
@onready var peaceful_sky: Sprite2D = $Stage2_SkyRestoration/PeacefulSky

# Stage 3: Village Restoration
@onready var stage3: Node2D = $Stage3_VillageRestoration
@onready var village_chaos: Sprite2D = $Stage3_VillageRestoration/VillageChaos
@onready var village_peaceful: Sprite2D = $Stage3_VillageRestoration/VillagePeaceful

# Stage 4-8: Library
@onready var stage4: Node2D = $Stage4_Library
@onready var library_bg: Sprite2D = $Stage4_Library/LibraryBg
@onready var warp_spark: Sprite2D = $Stage4_Library/WarpSpark
@onready var dark_overlay: ColorRect = $Stage4_Library/DarkOverlay
@onready var black_hole: Sprite2D = $Stage4_Library/BlackHole
@onready var khampri_shadow: Sprite2D = $Stage4_Library/KhampriShadow
@onready var khampri_floating: Sprite2D = $Stage4_Library/KhampriFloating
@onready var vel: AnimatedSprite2D = $Stage4_Library/Vel
@onready var exclamation_mark: Sprite2D = $Stage4_Library/Vel/ExclamationMark
@onready var anger_mark: Sprite2D = $Stage4_Library/Vel/AngerMark
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
var sfx_fusion: AudioStreamPlayer
var sfx_warp: AudioStreamPlayer
var sfx_pop: AudioStreamPlayer
var sfx_next: AudioStreamPlayer
var sfx_success: AudioStreamPlayer

var shards16: Array[Sprite2D] = []
var shard_initial_positions: Array[Vector2] = []
var current_stage: int = 1
var is_waiting_dialogue: bool = false
var dialogue_callback: Callable = Callable()
var is_fast_forwarding: bool = false
var can_fast_forward: bool = true
var typewriter_tween: Tween = null
var anger_bounce_tween: Tween = null

# Animation timers for spritesheets
var storm_anim_timer: float = 0.0
var peaceful_anim_timer: float = 0.0
var village_chaos_anim_timer: float = 0.0
var village_peaceful_anim_timer: float = 0.0

# Camera shake
var camera_shake_amount: float = 0.0

func _ready() -> void:
	Engine.time_scale = 1.0
	
	# เพิ่มปุ่มข้าม cutscene
	var skip_btn = preload("res://scripts/cutscene/skip_cutscene_button.gd").new()
	skip_btn.next_scene_path = start_scene_path
	add_child(skip_btn)
	
	_init_sfx()
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
		if village_chaos.visible and village_chaos.modulate.a > 0.01:
			village_chaos_anim_timer += delta * 8.0
			village_chaos.frame = 50 + (int(village_chaos_anim_timer) % 9)
		
		if village_peaceful.visible and village_peaceful.modulate.a > 0.01:
			village_peaceful_anim_timer += delta * 8.0
			# เล่นถึงแค่ท้องฟ้าสว่างเต็มที่ (เฟรม 11) แล้วคงค้างไว้ ไม่วนกลับไปเป็นท้องฟ้าโกลาหล
			village_peaceful.frame = mini(int(village_peaceful_anim_timer), 11)

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
	if ring_of_light:
		ring_of_light.visible = false
	if book_aura:
		book_aura.visible = false
	if dark_overlay:
		dark_overlay.visible = false
	if anger_bounce_tween and anger_bounce_tween.is_valid():
		anger_bounce_tween.kill()
	if anger_mark:
		anger_mark.visible = false
		anger_mark.scale = Vector2.ZERO
	if village_chaos:
		village_chaos.visible = false
		village_chaos.modulate = Color(1, 1, 1, 1)
	if village_peaceful:
		village_peaceful.visible = false
		village_peaceful.modulate = Color(1, 1, 1, 0)
	
	# เตรียม Stage 1: คัมภีร์เริ่มจากขนาดเล็ก ไม่ใหญ่จนเต็มจอ
	khampri_null.visible = true
	khampri_null.scale = Vector2(0.5, 0.5)
	khampri_null.modulate = Color(1, 1, 1, 0.0)
	khampri_full.visible = false
	khampri_full.scale = Vector2(2.2, 2.2)
	
	# จัดตำแหน่งเศษ 16 ชิ้นกระจายรอบคัมภีร์ให้เห็นเป็นชิ้นชัดเจน ขนาดใหญ่ขึ้นเล็กน้อย (1.35)
	var count = shards16.size()
	for i in range(count):
		var s: Sprite2D = shards16[i]
		var angle: float = (float(i) / float(count)) * TAU - (PI * 0.5)
		var dist: float = 300.0 if (i % 2 == 0) else 250.0
		var pos = Vector2(cos(angle) * dist * 1.25, sin(angle) * dist)
		shard_initial_positions.append(pos)
		s.position = pos
		s.scale = Vector2(1.35, 1.35)
		s.rotation = angle + (PI * 0.5)
		s.modulate = Color(1, 1, 1, 0.0)
		s.visible = true

## =============================================================
## ฉากที่ 1: การฟื้นฟูคัมภีร์เวทต้นกำเนิด
## คัมภีร์เริ่มขนาดเล็กขยายขึ้น เศษ 16 ชิ้นหยุดนิ่งสั้นๆ พุ่งเข้าพร้อมกัน
## คัมภีร์สั่น 2-3 ครั้ง ปล่อยวงแสง และมีออร่าเปล่งประกายรอบคัมภีร์
## =============================================================
func play_stage_1_book_restoration() -> void:
	current_stage = 1
	
	# 1.1 คัมภีร์เริ่มจากขนาดเล็กขยายขึ้นเล็กน้อย ไม่ใหญ่จนเต็มจอ (scale 0.5 -> 2.2) (0.9s)
	khampri_null.scale = Vector2(0.5, 0.5)
	khampri_null.modulate = Color(1, 1, 1, 0.0)
	var tw_book = create_tween().set_parallel(true)
	tw_book.tween_property(khampri_null, "modulate:a", 1.0, 0.8)
	tw_book.tween_property(khampri_null, "scale", Vector2(2.2, 2.2), 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 1.2 เศษคัมภีร์ทั้ง 16 ชิ้น ปรากฏขึ้นรอบ ๆ ขนาดใหญ่ขึ้น และขยับพริ้วไหวนิดหน่อย ไม่เยอะมาก (1.0s)
	var tw_shards_in = create_tween()
	tw_shards_in.tween_interval(1.0)
	tw_shards_in.tween_callback(func():
		for i in range(shards16.size()):
			var s: Sprite2D = shards16[i]
			var tw_s = create_tween().set_parallel(true)
			tw_s.tween_property(s, "modulate", Color(1.8, 1.6, 1.2, 1.0), 0.5).set_trans(Tween.TRANS_SINE)
			
			# ทำให้เศษคัมภีร์ขยับลอยพริ้วไหวเบาๆ ไม่เยอะมาก (gentle floating drift)
			var base_pos: Vector2 = shard_initial_positions[i]
			var dir: Vector2 = base_pos.normalized()
			var tw_drift = create_tween().set_loops(2)
			tw_drift.tween_property(s, "position", base_pos + dir * 10.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw_drift.tween_property(s, "position", base_pos - dir * 8.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	)
	
	# 1.3 เศษทั้งหมดหยุดนิ่งสั้น ๆ (~0.7s) เพื่อให้เห็นชัด ก่อนพุ่งเข้าหาคัมภีร์พร้อมกัน (2.2s)
	var tw_absorb = create_tween()
	tw_absorb.tween_interval(2.2)
	tw_absorb.tween_callback(func():
		_play_sfx(sfx_fusion)
		camera_shake_amount = 3.0
		
		for s in shards16:
			var tw_fly = create_tween().set_parallel(true)
			tw_fly.tween_property(s, "position", Vector2.ZERO, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tw_fly.tween_property(s, "scale", Vector2(0.2, 0.2), 0.65)
			tw_fly.tween_property(s, "rotation", s.rotation + PI * 2.0, 0.65)
			tw_fly.chain().tween_callback(func(): s.visible = false)
	)
	
	# 1.4 เมื่อรวมสำเร็จ: คัมภีร์สั่น 2–3 ครั้ง ปล่อยวงแสง และเปล่งประกายออร่านิดหน่อยรอบคัมภีร์ (2.85s)
	var tw_complete = create_tween()
	tw_complete.tween_interval(2.85)
	tw_complete.tween_callback(func():
		_play_sfx(sfx_success)
		khampri_null.visible = false
		khampri_full.visible = true
		khampri_full.modulate = Color(2.5, 2.2, 1.6, 1.0)
		khampri_full.scale = Vector2(2.5, 2.5)
		
		# เปล่งประกายออร่านิดหน่อยรอบคัมภีร์หลังรวมกับเศษคัมภีร์แล้ว
		if book_aura:
			book_aura.visible = true
			book_aura.scale = Vector2(1.2, 1.2)
			book_aura.modulate = Color(1.6, 1.4, 1.1, 0.0)
			var tw_aura = create_tween().set_parallel(true)
			tw_aura.tween_property(book_aura, "scale", Vector2(2.0, 2.0), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_aura.tween_property(book_aura, "modulate:a", 0.65, 0.5)
			
			# ออร่ากะพริบเปล่งแสงเบาๆ นุ่มนวลรอบคัมภีร์
			var tw_pulse = create_tween().set_loops()
			tw_pulse.tween_property(book_aura, "scale", Vector2(2.15, 2.15), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw_pulse.tween_property(book_aura, "scale", Vector2(1.95, 1.95), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# คัมภีร์สั่น 2-3 ครั้ง
		var tw_shake = create_tween()
		tw_shake.tween_property(khampri_full, "position:x", 967.0, 0.05)
		tw_shake.tween_property(khampri_full, "position:x", 953.0, 0.05)
		tw_shake.tween_property(khampri_full, "position:x", 965.0, 0.05)
		tw_shake.tween_property(khampri_full, "position:x", 960.0, 0.05)
		
		# ปล่อยวงแสง (Ring of Light) ขยายออกไป
		if ring_of_light:
			ring_of_light.visible = true
			ring_of_light.scale = Vector2(0.2, 0.2)
			ring_of_light.modulate = Color(2.0, 1.8, 1.2, 1.0)
			var tw_ring = create_tween().set_parallel(true)
			tw_ring.tween_property(ring_of_light, "scale", Vector2(9.0, 9.0), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_ring.tween_property(ring_of_light, "modulate:a", 0.0, 0.7)
		
		# คัมภีร์คืนขนาด 2.2 พร้อมเรืองแสงออร่านุ่มนวล
		var tw_shine = create_tween().set_parallel(true)
		tw_shine.tween_property(khampri_full, "scale", Vector2(2.2, 2.2), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_shine.tween_property(khampri_full, "modulate", Color(1.5, 1.4, 1.2, 1.0), 0.6)
	)
	
	# 1.5 แสงเวทสว่างวาบสั้น ๆ (0.35s) เปลี่ยนเข้าสู่ฉาก 2 (4.3s)
	var tw_flash = create_tween()
	tw_flash.tween_interval(4.3)
	tw_flash.tween_callback(func():
		_play_sfx(sfx_warp)
		white_flash.visible = true
		white_flash.color = Color(1.0, 0.98, 0.92, 0.0)
		var tw_wf = create_tween()
		tw_wf.tween_property(white_flash, "color:a", 0.55, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_wf.tween_callback(play_stage_2_sky_restoration)
	)

## =============================================================
## ฉากที่ 2: ท้องฟ้าโกลาหลกลับคืนสู่สภาพปกติ (แสงวาบ 0.3-0.5s เมฆเล่นต่อเนื่อง)
## =============================================================
func play_stage_2_sky_restoration() -> void:
	current_stage = 2
	stage1.visible = false
	if book_aura:
		book_aura.visible = false
	stage2.visible = true
	storm_sky.visible = true
	storm_sky.modulate = Color(1, 1, 1, 1)
	peaceful_sky.visible = true
	peaceful_sky.modulate = Color(1, 1, 1, 0)
	
	# แสงวาบจางลงอย่างรวดเร็ว (0.35s) ไม่ให้บังรายละเอียด
	var tw_unflash = create_tween()
	tw_unflash.tween_property(white_flash, "color:a", 0.0, 0.35)
	
	# 2.2 เล่นภาพพายุเคลื่อนไหวต่อเนื่อง ~1.8 วินาที -> แสงเวทมนตร์สว่างวาบชั่วขณะ 0.3-0.5s คลี่คลายสู่ปกติ
	var tw_magic_sweep = create_tween()
	tw_magic_sweep.tween_interval(1.8)
	tw_magic_sweep.tween_callback(func():
		_play_sfx(sfx_warp)
		
		# แสงสว่างวาบ 0.35s ไม่ให้จอขาวจ้าจนมองไม่เห็น
		var tw_glare = create_tween()
		tw_glare.tween_property(white_flash, "color:a", 0.5, 0.2)
		tw_glare.tween_property(white_flash, "color:a", 0.0, 0.3)
		
		# ท้องฟ้าค่อยๆ เปลี่ยนสีอย่างนุ่มนวล โดยแอนิเมชันก้อนเมฆเล่นต่อเนื่อง
		var tw_sky = create_tween().set_parallel(true)
		tw_sky.tween_property(storm_sky, "modulate:a", 0.0, 0.7)
		tw_sky.tween_property(peaceful_sky, "modulate:a", 1.0, 0.7)
	)
	
	# ค้างท้องฟ้าสงบ 2.2 วินาที แล้วเปลี่ยนผ่านอย่างต่อเนื่องเข้าสู่ฉาก 3 (4.5s)
	var tw_next = create_tween()
	tw_next.tween_interval(4.5)
	tw_next.tween_callback(func():
		var tw_wf = create_tween()
		tw_wf.tween_property(white_flash, "color:a", 0.5, 0.25)
		tw_wf.tween_callback(play_stage_3_village_restoration)
	)

## =============================================================
## ฉากที่ 3: บ้านเมืองกลับคืนสู่ความสงบ (เปลี่ยนผ่านต่อเนื่อง นุ่มนวลแบบฉากที่ 2 ไม่มีฉากดำ)
## =============================================================
func play_stage_3_village_restoration() -> void:
	current_stage = 3
	stage2.visible = false
	stage3.visible = true
	
	village_chaos.visible = true
	village_chaos.modulate = Color(1, 1, 1, 1)
	village_peaceful.visible = true
	village_peaceful.modulate = Color(1, 1, 1, 0)
	
	# แสงวาบจางลงใน 0.3s เผยเมืองกำลังโกลาหลเคลื่อนไหวต่อเนื่อง
	var tw_unflash = create_tween()
	tw_unflash.tween_property(white_flash, "color:a", 0.0, 0.3)
	
	# 3.2 เล่นภาพโกลาหล 1.8 วินาที -> แสงเวทมนตร์สว่างวาบ 0.35s คลี่คลายสู่ปกติเหมือนฉาก 2
	var tw_restore = create_tween()
	tw_restore.tween_interval(1.8)
	tw_restore.tween_callback(func():
		_play_sfx(sfx_warp)
		
		# แสงสว่างวาบนุ่มนวล 0.35s ไม่ให้จอขาวจ้า (เหมือนฉากที่ 2)
		var tw_glare = create_tween()
		tw_glare.tween_property(white_flash, "color:a", 0.5, 0.2)
		tw_glare.tween_property(white_flash, "color:a", 0.0, 0.3)
		
		# หมู่บ้านค่อยๆ เปลี่ยนจากโกลาหลสู่สงบสุขอย่างนุ่มนวล โดยแอนิเมชันเล่นต่อเนื่อง
		var tw_vil = create_tween().set_parallel(true)
		tw_vil.tween_property(village_chaos, "modulate:a", 0.0, 0.7)
		tw_vil.tween_property(village_peaceful, "modulate:a", 1.0, 0.7)
	)
	
	# ค้างภาพเมืองที่สงบสุข 2.5 วินาที แล้วเปลี่ยนผ่านเข้าสู่ฉาก 4 ห้องสมุดอย่างต่อเนื่อง (4.8s)
	var tw_next = create_tween()
	tw_next.tween_interval(4.8)
	tw_next.tween_callback(func():
		var tw_wf = create_tween()
		tw_wf.tween_property(white_flash, "color:a", 0.5, 0.25)
		tw_wf.tween_callback(play_stage_4_vel_in_library)
	)

## =============================================================
## ฉากที่ 4: เวลถูกวาร์ปกลับห้องสมุด
## จังหวะที่ 1: วาร์ปพร้อมแสงวงเล็กๆ ที่พื้น -> ปรากฏตัวแบบวิบมา ไม่เด้งตัว ด้วยหน้า cat (:3)
## จังหวะที่ 2: หนังสือตกลงมา -> เปลี่ยนเป็นท่า hold ในจังหวะที่หนังสือถึงมือจริงๆ
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
	if anger_mark:
		anger_mark.visible = false
	if warp_spark:
		warp_spark.visible = false
	if dark_overlay:
		dark_overlay.visible = false
	
	# แสงจางลงใน 0.35s เผยห้องสมุดเงียบสงบ
	var tw_unflash = create_tween()
	tw_unflash.tween_property(white_flash, "color:a", 0.0, 0.35)
	
	# จังหวะที่หนึ่ง: เวลวาร์ปกลับมา ปรากฏพร้อมแสงวงเล็กๆ ที่พื้น วิบมาแค่นั้น ไม่เด้งตัว (1.2s)
	var tw_warp_vel = create_tween()
	tw_warp_vel.tween_interval(1.2)
	tw_warp_vel.tween_callback(func():
		_play_sfx(sfx_warp)
		# แสงวงเวทที่พื้นตำแหน่งเท้าของเวล
		if warp_spark:
			warp_spark.visible = true
			warp_spark.position = Vector2(-40, 98)
			warp_spark.scale = Vector2.ZERO
			warp_spark.modulate = Color(1.5, 1.8, 2.5, 1.0)
			var tw_ws = create_tween().set_parallel(true)
			tw_ws.tween_property(warp_spark, "scale", Vector2(1.8, 1.2), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw_ws.tween_property(warp_spark, "modulate:a", 0.0, 0.45)
		
		# ตัวละครเวลปรากฏตัวขึ้นมา ทำหน้า cat (vel_cat ปากแมว :3) ตรงกับตำแหน่ง intro (-40, 59)
		vel.visible = true
		vel.position = Vector2(-40, 59)
		vel.scale = Vector2.ONE
		vel.play("cat")
		vel.modulate = Color(2.0, 2.0, 2.0, 0.0)
		
		var tw_v = create_tween()
		tw_v.tween_property(vel, "modulate", Color(1, 1, 1, 1), 0.15)
	)
	
	# จังหวะที่สอง: ตอนหนังสือตกลงมา ให้เวลเปลี่ยนเป็นท่า hold ในจังหวะที่หนังสือถึงมือจริงๆ (2.2s)
	var tw_book_drop = create_tween()
	tw_book_drop.tween_interval(2.2)
	tw_book_drop.tween_callback(func():
		khampri_floating.visible = true
		khampri_floating.position = Vector2(-40, -95) # อยู่สูงเหนือหัวเวลที่ x = -40
		khampri_floating.scale = Vector2(0.18, 0.18)
		khampri_floating.modulate = Color(1.8, 1.6, 1.1, 1.0)
		
		khampri_shadow.visible = true
		khampri_shadow.position = Vector2(-40, 98)
		khampri_shadow.scale = Vector2(0.1, 0.05)
		khampri_shadow.modulate = Color(1, 1, 1, 0.0)
		
		# คัมภีร์ร่วงตกลงมา
		var tw_drop = create_tween().set_parallel(true)
		tw_drop.tween_property(khampri_floating, "position:y", 14.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_drop.tween_property(khampri_shadow, "scale", Vector2(0.8, 0.4), 0.55)
		tw_drop.tween_property(khampri_shadow, "modulate:a", 0.4, 0.55)
		
		# ในจังหวะที่หนังสือถึงมือจริงๆ ➔ เปลี่ยนเป็นท่า vel_hold ทันที พร้อมเด้งเบาๆ
		tw_drop.chain().tween_callback(func():
			_play_sfx(sfx_pop)
			vel.play("hold")
			
			var tw_bounce = create_tween()
			tw_bounce.tween_property(khampri_floating, "position:y", 8.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_bounce.tween_property(khampri_floating, "position:y", 14.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		)
	)
	
	# ค้างบรรยากาศเงียบสงบโดยไม่มีบทพูด 2.2 วินาที แล้วเข้าสู่ฉาก 5 (4.8s)
	var tw_next = create_tween()
	tw_next.tween_interval(4.8)
	tw_next.tween_callback(play_stage_5_master_return)

## =============================================================
## ฉากที่ 5: การกลับมาของปรมาจารย์
## จังหวะคอมเมดี้: หลุมดำเปิดช้าๆ -> อาจารย์พุ่งขึ้นมาแบบช้าลงเห็นชัดเจน
## เวลสะดุ้ง คัมภีร์กระดอนขึ้นฟ้าแล้วสลายหายไป
## อาจารย์แลนดิ้งทำหน้า minishock เอ่ยถามเวล -> เวลทำหน้า angry -> เข้า Flashback
## =============================================================
func play_stage_5_master_return() -> void:
	current_stage = 5
	exclamation_mark.visible = false
	
	# 5.1 หลุมดำค่อย ๆ เปิดขึ้นทางขวา ตำแหน่ง intro_cutscene (40, 97) (0.8s)
	var tw_hole = create_tween()
	tw_hole.tween_interval(0.8)
	tw_hole.tween_callback(func():
		black_hole.visible = true
		black_hole.position = Vector2(40, 97)
		black_hole.scale = Vector2.ZERO
		var tw_bh = create_tween()
		tw_bh.tween_property(black_hole, "scale", Vector2(1.3, 1.1), 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	
	# 5.2 ปรมาจารย์พุ่งตัวขึ้นมาจากหลุมดำอย่างชัดเจน ไม่เร็วเกินไป (1.8s) โดยไม่สั่นพื้น
	# พร้อมกับจังหวะที่คัมภีร์เด้งหลุดจากมือเวลแล้วสลายหายไป
	var tw_emerge = create_tween()
	tw_emerge.tween_interval(1.8)
	tw_emerge.tween_callback(func():
		_play_sfx(sfx_pop)
		
		# อาจารย์พุ่งขึ้นมาจากหลุมดำ (40, 97)
		master_char.visible = true
		master_char.position = Vector2(40, 97)
		master_char.scale = Vector2(0.3, 0.3)
		master_char.modulate = Color(1, 1, 1, 1)
		master_char.play("shock1")
		
		# พุ่งลอยขึ้นสู่อากาศ (0.55s) แล้วตกลงมายืนบนพื้นตำแหน่ง intro_cutscene (40, 59) (0.35s)
		var tw_m = create_tween().set_parallel(true)
		tw_m.tween_property(master_char, "position:y", 10.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_m.tween_property(master_char, "scale", Vector2.ONE, 0.55)
		
		tw_m.chain().tween_property(master_char, "position:y", 59.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_m.chain().tween_callback(func():
			# อาจารย์แลนดิ้งลงพื้น ทำหน้า minishock (เหงื่อตก เลิ่กลั่ก) โดยพื้นไม่สั่น
			master_char.play("minishock")
		)
		
		# หลุมดำค่อยๆ หดปิดตัวลง
		var tw_close = create_tween()
		tw_close.tween_interval(0.4)
		tw_close.tween_property(black_hole, "scale", Vector2.ZERO, 0.35)
		tw_close.tween_callback(func(): black_hole.visible = false)
		
		# --- เวลสะดุ้งตกใจกระโดด & คัมภีร์กระดอนขึ้นฟ้าแล้วสลายหายไป (ไม่มีเครื่องหมาย !) ---
		exclamation_mark.visible = false
		vel.play("shock")
		var tw_vjump = create_tween()
		tw_vjump.tween_property(vel, "position:y", 35.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_vjump.tween_property(vel, "position:y", 59.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		# คัมภีร์เด้งลอยขึ้นฟ้า ส่องแสงสีทอง แล้วสลายหายไป
		var tw_b_vanish = create_tween().set_parallel(true)
		tw_b_vanish.tween_property(khampri_floating, "position:y", -60.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_b_vanish.tween_property(khampri_floating, "modulate", Color(2.5, 2.2, 1.4, 1.0), 0.25)
		if khampri_shadow:
			tw_b_vanish.tween_property(khampri_shadow, "modulate:a", 0.0, 0.3)
		
		# สลายตัวเป็นประกายแสงหายไปในอากาศ
		tw_b_vanish.chain().tween_property(khampri_floating, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw_b_vanish.chain().tween_property(khampri_floating, "modulate:a", 0.0, 0.25)
		tw_b_vanish.chain().tween_callback(func():
			khampri_floating.visible = false
			if khampri_shadow:
				khampri_shadow.visible = false
		)
	)
	
	# 5.3 อาจารย์แลนดิ้งทำหน้า minishock แล้วเปิดกล่องข้อความถามเวล (3.2s)
	# เวลทำหน้า idle และอาจารย์ทำหน้า minishock
	var tw_dialogue = create_tween()
	tw_dialogue.tween_interval(3.2)
	tw_dialogue.tween_callback(func():
		vel.play("idle")
		master_char.play("minishock")
		
		_show_dialogue(
			"ปรมาจารย์",
			"อ้าว เวล... เกิดอะไรขึ้นเนี่ย แล้วทำไมดูเหนื่อยมอมแมมแบบนี้ล่ะ?",
			func():
				# เมื่อผู้เล่นคลิกหรือกด Space ไปต่อ ให้ซ่อนกล่องข้อความแล้วตัดเข้า Flashback ทันที
				_hide_dialogue(play_stage_6_comic_flashback)
		)
	)

## =============================================================
## ฉากที่ 6: เฉลยความจริงเบื้องหลัง (Flashback ช้าลง ชัดเจน ให้เวลาดูและอ่านมุกตลก)
## =============================================================
func play_stage_6_comic_flashback() -> void:
	current_stage = 6
	exclamation_mark.visible = false
	
	# กรอบภาพย้อนเหตุการณ์เด้งขึ้นมา
	comic_container.visible = true
	comic_container.scale = Vector2(0.3, 0.3)
	comic_container.modulate = Color(1, 1, 1, 0.0)
	comic_container.pivot_offset = comic_container.size * 0.5
	
	flashback_master.visible = true
	flashback_master.position = Vector2(460, 345)
	flashback_master.scale = Vector2(2.8, 2.8)
	flashback_master.modulate = Color(1, 1, 1, 1)
	flashback_master.play("breathe_blink") # ยืนสงบนิ่งหายใจกระพริบตาตาใส เหมือนฉากเปิดเรื่อง
	flashback_hole.visible = false
	
	var tw_panel_in = create_tween().set_parallel(true)
	tw_panel_in.tween_property(comic_container, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_panel_in.tween_property(comic_container, "modulate:a", 1.0, 0.45)
	
	# 6.2 เมื่อกรอบเปิดขึ้นมา อาจารย์ยืนอยู่ หลุมดำค่อยๆ ขยายขึ้นใต้เท้าบนพื้นห้องสมุด (1.6s)
	var tw_hole_open = create_tween()
	tw_hole_open.tween_interval(1.6)
	tw_hole_open.tween_callback(func():
		# หลุมดำค่อยๆ ขยายขึ้นใต้เท้าที่พื้นห้องสมุด (y = 460)
		flashback_hole.visible = true
		flashback_hole.position = Vector2(460, 460)
		flashback_hole.scale = Vector2.ZERO
		var tw_h = create_tween()
		tw_h.tween_property(flashback_hole, "scale", Vector2(3.0, 2.2), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		# อาจารย์ทำท่าตกใจสุดขีด shock1 (ยกมือทาบหู ตาโตอ้าปากค้าง เหมือนฉากเปิดเรื่องเป๊ะๆ)
		flashback_master.play("shock1")
		
		# เอฟเฟกต์สะดุ้งตัวสั่นด้วยความตกใจ (เหมือนฉากเปิดเรื่อง)
		var tw_shake = create_tween().set_loops(6)
		tw_shake.tween_property(flashback_master, "position:x", 463.0, 0.05)
		tw_shake.tween_property(flashback_master, "position:x", 457.0, 0.05)
		tw_shake.chain().tween_property(flashback_master, "position:x", 460.0, 0.05)
	)
	
	# 6.3 หลังตกใจเหวออยู่ 1.5 วินาที -> อาจารย์ร่วงหล่นลงไปในหลุมดำของตัวเอง (3.3s)
	var tw_fall = create_tween()
	tw_fall.tween_interval(3.3)
	tw_fall.tween_callback(func():
		_play_sfx(sfx_warp)
		# ดีดตัวนิดนึงแล้วร่วงดิ่งลงหลุมดำ (เหมือนฉากเปิดเรื่อง)
		var tw_m_fall = create_tween().set_parallel(true)
		tw_m_fall.tween_property(flashback_master, "position:y", 510.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_m_fall.tween_property(flashback_master, "scale", Vector2(0.35, 0.35), 0.65)
		tw_m_fall.tween_property(flashback_master, "modulate:a", 0.0, 0.65)
		
		# หลุมดำหดปิดตัวลง
		tw_m_fall.chain().tween_property(flashback_hole, "scale", Vector2.ZERO, 0.35)
	)
	
	# 6.4 ค้างกรอบภาพที่ว่างเปล่าพร้อมคำบรรยายมุกตลกให้อ่านได้เต็มที่ (~3.6s) แล้วค่อยปิดกรอบ (7.6s)
	var tw_panel_out = create_tween()
	tw_panel_out.tween_interval(7.6)
	tw_panel_out.tween_callback(func():
		var tw_out = create_tween().set_parallel(true)
		tw_out.tween_property(comic_container, "scale", Vector2(0.3, 0.3), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw_out.tween_property(comic_container, "modulate:a", 0.0, 0.4)
		
		tw_out.chain().tween_callback(func():
			comic_container.visible = false
			play_stage_7_dialogue()
		)
	)

## =============================================================
## ฉากที่ 7: บทสนทนาหลังจบ Flashback
## =============================================================
func play_stage_7_dialogue() -> void:
	current_stage = 7
	
	# บทที่ 2: เวลใช้หน้า angry และปรมาจารย์ใช้หน้า cry
	vel.play("angry")
	master_char.play("cry")
	
	# ตอนเวลทำหน้า angry แสดงไอคอนสัญลักษณ์โกรธ (💢) pixel art ขนาดกะทัดรัด เด้งดุ๊กดิ๊กเบาๆ เหนือศีรษะ
	if anger_mark:
		if anger_bounce_tween and anger_bounce_tween.is_valid():
			anger_bounce_tween.kill()
		anger_mark.visible = true
		anger_mark.position = Vector2(14, -54)
		anger_mark.scale = Vector2.ZERO
		var tw_pop = create_tween()
		tw_pop.tween_property(anger_mark, "scale", Vector2(0.72, 0.72), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_pop.tween_callback(func():
			if is_instance_valid(anger_mark) and anger_mark.visible:
				anger_bounce_tween = create_tween().set_loops()
				# ขยับและพองยุบเบาๆ นุ่มนวล ไม่เด้งรุนแรง (gentle subtle bobbing)
				anger_bounce_tween.tween_property(anger_mark, "scale", Vector2(0.75, 0.75), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				anger_bounce_tween.parallel().tween_property(anger_mark, "position:y", -55.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				anger_bounce_tween.chain().tween_property(anger_mark, "scale", Vector2(0.69, 0.69), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				anger_bounce_tween.parallel().tween_property(anger_mark, "position:y", -53.5, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		)
	
	# ประโยคที่ 1 (ของฉาก 7): เวลพูดหลังรู้ความจริง
	_show_dialogue(
		"เวล",
		"เฮ้อ... ทั้งหมดนี่เป็นเพราะอาจารย์เองสินะ...",
		func():
			# ปิดไอคอนอารมณ์เสียเมื่อจบประโยคของเวล
			if is_instance_valid(anger_mark) and anger_mark.visible:
				if anger_bounce_tween and anger_bounce_tween.is_valid():
					anger_bounce_tween.kill()
				var tw_ang_out = create_tween()
				tw_ang_out.tween_property(anger_mark, "scale", Vector2.ZERO, 0.12)
				tw_ang_out.tween_callback(func(): anger_mark.visible = false)
			
			# บทที่ 3: เวลใช้หน้า breathe_blink และปรมาจารย์ใช้หน้า playful
			vel.play("breathe_blink")
			master_char.play("playful")
			
			# ประโยคที่ 2 (ของฉาก 7): อาจารย์ตอบ
			_show_dialogue(
				"ปรมาจารย์",
				"ฉันเองหรอเนี่ย_55555",
				func():
					_hide_dialogue(play_stage_8_epilogue)
			)
	)

## =============================================================
## ฉากที่ 8: บทสรุปการเดินทางของเวล (The End)
## ซูมออก -> พื้นหลังมืดลงอย่างต่อเนื่อง -> THE END ชัดเจน
## =============================================================
func play_stage_8_epilogue() -> void:
	current_stage = 8
	can_fast_forward = false
	is_fast_forwarding = false
	Engine.time_scale = 1.0
	
	if anger_mark:
		anger_mark.visible = false
	
	# เมื่อจบบทสนทนา ทั้งสองตัวละครเปลี่ยนเป็นท่ายืนนิ่ง idle
	vel.play("idle")
	master_char.play("idle")
	
	# กล้องค่อย ๆ ซูมออก เผยภาพกว้างของห้องสมุด (3.0s)
	var tw_zoom = create_tween().set_parallel(true)
	tw_zoom.tween_property(camera, "zoom", Vector2(0.85, 0.85), 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# พื้นหลังค่อย ๆ มืดลงอย่างต่อเนื่องและนุ่มนวล (Fade to Dark 2.5s)
	the_end_container.visible = true
	the_end_container.modulate = Color(1, 1, 1, 0.0)
	
	var tw_fade_dark = create_tween()
	tw_fade_dark.tween_interval(0.8)
	tw_fade_dark.tween_property(the_end_container, "modulate:a", 1.0, 2.2).set_trans(Tween.TRANS_SINE)
	tw_fade_dark.tween_callback(func():
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

func _play_sfx(_player: AudioStreamPlayer) -> void:
	# ปิดเสียงทั้งหมดในฉาก ending-cutscene ชั่วคราวตามที่ระบุ
	return

func _init_sfx() -> void:
	sfx_fusion = _create_sfx_player("res://assets/audio/sfx_success.wav")
	sfx_warp = _create_sfx_player("res://assets/audio/sfx_command.wav")
	sfx_pop = _create_sfx_player("res://assets/audio/sfx_modal.wav")
	sfx_next = _create_sfx_player("res://assets/audio/sfx_dialogue_next.wav")
	sfx_success = _create_sfx_player("res://assets/audio/sfx_success.wav")

func _create_sfx_player(path: String) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	if ResourceLoader.exists(path):
		player.stream = load(path)
	add_child(player)
	return player

