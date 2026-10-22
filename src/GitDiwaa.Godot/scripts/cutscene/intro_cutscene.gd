extends Sprite2D

## การควบคุม Cutscene เปิดเรื่อง (Intro Cutscene)
## ลำดับเหตุการณ์:
## 1. ปรมาจารย์ & เวล เดินเข้ามายังกลางห้อง (แสงห้องปกติ ไม่มืด ไม่สั่น)
## 2. หลุมดำเปิดใต้เท้าอาจารย์
## 3. อาจารย์รู้ตัว ทำหน้า shock1 ยืนตกใจ
## 4. อาจารย์ตกหลุมดำ คัมภีร์ดรอปออกมาสไตล์ Minecraft (ดีดขึ้นนิดนึงแล้วตกถึงพื้นไม้ ไม่เด้ง ไม่เอียง)
## 5. อาจารย์จมหายไป -> เวลช็อก + หลุมดำแรกปิด
## 6. คัมภีร์นอนนิ่งบนพื้นไม้ (30, 96) ก่อนแตก สั่นแค่ตัวคัมภีร์ แล้วแตกออกเป็น 20 ชิ้น (เศษไม่เอียง)
## 7. รอแปปนึง ให้เห็นเศษซากกระจายรอบห้อง
## 8. วงเวท/หลุมดำรอบสองเปิดขึ้นมาแบบวงเล็ก ค่อย ๆ ดูดเศษทั้ง 20 ชิ้นหายไป
## 9. หลังการดูดเสร็จสิ้น เศษคัมภีร์หน้าสุดท้าย (paper.png) ร่อนตกลงมาจากด้านบน ส่ายลงมาสัมผัสพื้นไม้ (16.6s -> 17.8s)
## 10. เมื่อกระดาษลงสู่พื้นแล้ว หลุมดำปิด เวลได้สติเดินเข้าไปหากระดาษ (18.0s -> 20.0s)
## 11. เวลหยุดข้างกระดาษ กระดาษลอยขึ้นสู่มือเวล (20.3s)
## 12. หน้าจอปรากฏกระดาษโบราณกึ่งกลางจอ พร้อมข้อความมนตราโบราณภาษาไทย (ฟอนต์ TA 8 BIT สไตล์ 8-bit เก่าขลัง)
##     กึ่งกลางแผ่นกระดาษ ลอยพริ้วไหวอย่างสงบ
## 13. เมื่อผู้เล่นกดไปต่อ (Space / คลิก) กระดาษในมือและตัวหนังสือจะสลายหายไปพร้อมกัน

@export_enum("AnimationPlayer", "ScriptTween") var playback_mode: String = "AnimationPlayer"

@export_group("ตำแหน่งตัวละคร (Positions)")
@export var character_y: float = 59.0
@export var spawn_x: float = -250.0
@export var master_target_x: float = 40.0
@export var vel_target_x: float = -40.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var master: AnimatedSprite2D = $Master
@onready var vel: AnimatedSprite2D = $Vel
@onready var exclamation_mark: Sprite2D = $Vel/ExclamationMark
@onready var black_hole: Sprite2D = $BlackHole
@onready var room_lighting: CanvasModulate = $RoomLighting

@onready var khampri: Sprite2D = $Khampri
@onready var khampri_shadow: Sprite2D = $KhampriShadow
@onready var paper_shadow: Sprite2D = $PaperShadow
@onready var shards_container: Node2D = $Shards
@onready var paper_on_floor: Sprite2D = $PaperOnFloor

@onready var magic_ui: CanvasLayer = $MagicStoryUI
@onready var backdrop: ColorRect = $MagicStoryUI/Backdrop
@onready var parchment_shadow: TextureRect = $MagicStoryUI/ParchmentShadow
@onready var parchment_frame: TextureRect = $MagicStoryUI/ParchmentFrame
@onready var rune_container: Control = $MagicStoryUI/RuneContainer
@onready var rune_aura_label: RichTextLabel = $MagicStoryUI/RuneContainer/RuneAuraLabel
@onready var rune_label: RichTextLabel = $MagicStoryUI/RuneContainer/RuneRichLabel
@onready var continue_prompt: Label = $MagicStoryUI/RuneContainer/ContinuePrompt

var shards: Array[Sprite2D] = []
var can_continue: bool = false
var is_continuing: bool = false
var is_fast_forwarding: bool = false
var can_fast_forward: bool = true
var tw_ex_bob: Tween = null
var tw_paper_glow: Tween = null
var skip_ctrl = null

signal cutscene_finished

# โทนสีฟิลเตอร์คัมภีร์และเศษคัมภีร์ให้กลมกลืนกับห้องสมุด (ไม่เด่น/สว่างจ้าเกินไป)
const BOOK_TINT: Color = Color(0.70, 0.63, 0.55, 1.0)

# พิกัดปลายทางที่เศษทั้ง 16 ชิ้นจะกระจายตกบนพื้นห้องทางด้านขวา (ศูนย์กลางที่คัมภีร์ตก 64, 96 ไม่ลามไปใกล้ตัวเวลที่ -40)
const SHARD_LANDING_POSITIONS: Array[Vector2] = [
	Vector2(40.0, 92.0),   # Shard 1 (ปานกลาง - ซ้ายบน)
	Vector2(54.0, 95.0),   # Shard 2 (ชิ้นใหญ่ หนัก - ตกใกล้ซ้าย)
	Vector2(72.0, 97.0),   # Shard 3 (ชิ้นใหญ่ หนัก - ตกใกล้ขวา)
	Vector2(84.0, 94.0),   # Shard 4 (ปานกลาง - ขวา)
	Vector2(76.0, 102.0),  # Shard 5 (ปานกลาง - ขวาล่าง)
	Vector2(50.0, 100.0),  # Shard 6 (ปานกลาง - ซ้ายล่าง)
	Vector2(59.0, 91.0),   # Shard 7 (ปานกลาง - กลางบน)
	Vector2(106.0, 90.0),  # Shard 8 (ชิ้นเล็ก - ปลิวไกล ขวา)
	Vector2(98.0, 79.0),   # Shard 9 (ชิ้นเล็ก - ปลิวไกล ขวาบน)
	Vector2(102.0, 105.0), # Shard 10 (ชิ้นเล็ก - ปลิวไกล ขวาล่าง)
	Vector2(32.0, 94.0),   # Shard 11 (ปานกลางค่อนเล็ก - ซ้าย)
	Vector2(44.0, 104.0),  # Shard 12 (ปานกลาง - ซ้ายล่าง)
	Vector2(18.0, 88.0),   # Shard 13 (ชิ้นเล็กมาก - กระเด็นไกลสุด ซ้ายบน)
	Vector2(88.0, 98.0),   # Shard 14 (ปานกลาง - ขวาล่าง)
	Vector2(26.0, 102.0),  # Shard 15 (ชิ้นเล็ก - กระเด็นไกล ซ้ายล่าง)
	Vector2(65.0, 98.0),   # Shard 16 (ชิ้นใหญ่สุด หนักมาก - ตกกระแทกจุดแตก)
]

func _ready() -> void:
	Engine.time_scale = 1.0
	skip_ctrl = preload("res://scripts/cutscene/skip_cutscene_button.gd").new()
	skip_ctrl.next_scene_path = "res://scenes/cutscene/outside_cutscene.tscn"
	add_child(skip_ctrl)
	_init_shards()
	_reset_cutscene_state()
	
	if playback_mode == "AnimationPlayer":
		if not anim_player.is_playing() or anim_player.current_animation != "walk_in":
			anim_player.play("walk_in")
		anim_player.animation_finished.connect(func(_anim_name):
			if not is_continuing:
				vel.play("breathe_blink")
		)
	else:
		if anim_player.is_playing():
			anim_player.stop()
		play_with_tween()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _process(_delta: float) -> void:
	if not can_fast_forward or can_continue or is_continuing:
		if is_fast_forwarding:
			is_fast_forwarding = false
			Engine.time_scale = 1.0
		return
	
	var is_btn_active: bool = (skip_ctrl != null and skip_ctrl.is_fast_forward)
	var wants_hold: bool = Input.is_key_pressed(KEY_SPACE) or \
		Input.is_key_pressed(KEY_ENTER) or \
		Input.is_key_pressed(KEY_SHIFT) or \
		Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	var active: bool = is_btn_active or wants_hold
	if active != is_fast_forwarding:
		is_fast_forwarding = active
		Engine.time_scale = 2.5 if active else 1.0
		if skip_ctrl and not is_btn_active:
			skip_ctrl._apply_ff_style(active)

func _input(event: InputEvent) -> void:
	if not can_continue or is_continuing:
		return
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		return
	if event.is_action_pressed("ui_accept") or \
	   (event is InputEventKey and event.pressed and not event.echo) or \
	   (event is InputEventMouseButton and event.pressed) or \
	   (event is InputEventScreenTouch and event.pressed):
		get_viewport().set_input_as_handled()
		_trigger_continue()

func _init_shards() -> void:
	shards.clear()
	if shards_container:
		for child in shards_container.get_children():
			if child is Sprite2D:
				if shards.size() < 16:
					shards.append(child)
				else:
					child.visible = false

func _reset_cutscene_state() -> void:
	can_continue = false
	is_continuing = false
	
	# แสงห้องปกติ ไม่มืด กล้องนิ่ง
	if room_lighting:
		room_lighting.color = Color(1, 1, 1, 1)
	position = Vector2(960, 540)
	
	if khampri:
		khampri.visible = false
		khampri.position = Vector2(42, 58)
		khampri.rotation = 0.0
		khampri.scale = Vector2(0.2, 0.2)
		khampri.modulate = BOOK_TINT
	
	if khampri_shadow:
		khampri_shadow.visible = false
		khampri_shadow.position = Vector2(64, 98)
		khampri_shadow.scale = Vector2(1.1, 0.7)
		khampri_shadow.modulate = Color(1, 1, 1, 0)
	
	if paper_shadow:
		paper_shadow.visible = false
		paper_shadow.position = Vector2(64, 98)
		paper_shadow.scale = Vector2(0.55, 0.35)
		paper_shadow.modulate = Color(1, 1, 1, 0)
	
	for s in shards:
		s.visible = false
		s.scale = Vector2(0.2, 0.2)
		s.modulate = BOOK_TINT
		s.rotation = 0.0
	
	if paper_on_floor:
		paper_on_floor.visible = false
		paper_on_floor.position = Vector2(64, 96)
		paper_on_floor.rotation = 0.0
		paper_on_floor.scale = Vector2(0.095, 0.095)
		paper_on_floor.modulate = Color(1, 1, 1, 1)
	
	if backdrop:
		backdrop.color = Color(0, 0, 0, 0)
	if parchment_shadow:
		parchment_shadow.modulate = Color(0, 0, 0, 0)
	if parchment_frame:
		parchment_frame.modulate = Color(1, 1, 1, 0)
	if rune_container:
		rune_container.scale = Vector2(0.01, 0.01)
		rune_container.modulate = Color(1, 1, 1, 0)
	if rune_aura_label:
		rune_aura_label.modulate = Color(1, 1, 1, 1)
	if continue_prompt:
		continue_prompt.modulate = Color(1, 1, 1, 0)
	
	if tw_ex_bob and tw_ex_bob.is_valid():
		tw_ex_bob.kill()
	if tw_paper_glow and tw_paper_glow.is_valid():
		tw_paper_glow.kill()
		tw_paper_glow = null
	can_fast_forward = true
	is_fast_forwarding = false
	Engine.time_scale = 1.0
	if skip_ctrl:
		skip_ctrl.set_fast_forward_visible(true)
	if exclamation_mark:
		exclamation_mark.visible = false
		exclamation_mark.scale = Vector2.ZERO
		exclamation_mark.position = Vector2(0, -56)

## เรียกเมื่อคัมภีร์แตกสลาย (11.8s)
func _on_shatter_khampri() -> void:
	if not khampri:
		return
	khampri.visible = false
	if khampri_shadow:
		khampri_shadow.visible = false
	
	# เครื่องหมายบนหัวเวลสะดุ้งกระตุกเล็กน้อยตามแรงระเบิดของคัมภีร์
	if exclamation_mark and exclamation_mark.visible:
		var tw_react = create_tween()
		tw_react.tween_property(exclamation_mark, "position:y", -62.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_react.parallel().tween_property(exclamation_mark, "scale", Vector2(1.2, 1.2), 0.08)
		tw_react.tween_property(exclamation_mark, "position:y", -54.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_react.parallel().tween_property(exclamation_mark, "scale", Vector2(0.95, 0.95), 0.08)
		tw_react.tween_property(exclamation_mark, "position:y", -56.0, 0.12)
		tw_react.parallel().tween_property(exclamation_mark, "scale", Vector2(1.0, 1.0), 0.12)
	var origin: Vector2 = khampri.position # (64, 79) ขณะลอยตัวเหนือพื้น
	
	# เมื่อคัมภีร์แตก กระดาษยังไม่ปรากฏทันที (จะร่วงหล่นลงมาทีหลังจากเหตุการณ์ดูดเศษซาก)
	if paper_on_floor:
		paper_on_floor.visible = false
	
	# เศษคัมภีร์ทั้ง 16 ชิ้นแตกกระจายตามมวลจริง: ชิ้นใหญ่เคลื่อนช้าตกใกล้ ชิ้นเล็กกระเด็นไกลบินเร็ว ดีเลย์เหลื่อมล้ำกัน
	for i in range(shards.size()):
		var s: Sprite2D = shards[i]
		s.position = origin
		s.scale = Vector2(0.2, 0.2)
		s.visible = true
		s.rotation = 0.0 # สไตล์ Pixel Art
		
		# คำนวณขนาดพื้นที่ของเศษชิ้นนี้
		var piece_area: float = s.region_rect.size.x * s.region_rect.size.y
		var target: Vector2 = SHARD_LANDING_POSITIONS[i] if i < SHARD_LANDING_POSITIONS.size() else origin + Vector2(randf_range(-40, 40), randf_range(-15, 15))
		
		var duration: float
		var apex_height: float
		var launch_delay: float
		
		if piece_area > 950.0:
			# ชิ้นใหญ่/หนัก: เคลื่อนช้า ตกใกล้ โค้งเตี้ย
			duration = randf_range(0.60, 0.72)
			apex_height = randf_range(10.0, 16.0)
			launch_delay = randf_range(0.01, 0.05)
		elif piece_area < 700.0:
			# ชิ้นเล็ก/เบา: พุ่งเร็ว ปลิวไกล โค้งสูง
			duration = randf_range(0.36, 0.45)
			apex_height = randf_range(24.0, 36.0)
			launch_delay = randf_range(0.0, 0.08)
		else:
			# ชิ้นขนาดกลาง
			duration = randf_range(0.48, 0.56)
			apex_height = randf_range(16.0, 24.0)
			launch_delay = randf_range(0.02, 0.06)
		
		var apex_y: float = min(origin.y, target.y) - apex_height
		
		var tw_launch = create_tween()
		if launch_delay > 0.0:
			tw_launch.tween_interval(launch_delay)
		
		tw_launch.tween_callback(func():
			if not is_instance_valid(s):
				return
			s.modulate = Color(1.15, 1.05, 0.90, 1.0)
			var tw_move = create_tween().set_parallel(true)
			tw_move.tween_property(s, "position:x", target.x, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
			var tw_y = create_tween()
			tw_y.tween_property(s, "position:y", apex_y, duration * 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_y.tween_property(s, "position:y", target.y, duration * 0.58).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			
			tw_move.tween_property(s, "modulate", BOOK_TINT, duration)
		)

## เศษคัมภีร์แผ่นสุดท้ายที่หลงเหลือ ร่วงหล่นลงมาจากด้านบนเล็กน้อยสู่พื้นไม้ (16.4s -> 17.8s)
func _on_paper_flutter_down() -> void:
	if not paper_on_floor:
		return
	paper_on_floor.visible = true
	paper_on_floor.position = Vector2(68.0, 44.0)
	paper_on_floor.rotation = -0.05
	paper_on_floor.scale = Vector2(0.08, 0.08)
	# โผล่มาเป็นเงามืดดำ/ไหม้เกรียมก่อน ไม่ให้ดูวาร์ปมา
	paper_on_floor.modulate = Color(0.08, 0.08, 0.1, 0.0)
	
	if paper_shadow:
		paper_shadow.visible = true
		paper_shadow.position = Vector2(68.0, 98.0)
		paper_shadow.scale = Vector2(0.25, 0.15)
		paper_shadow.modulate = Color(1, 1, 1, 0.0)
		var tw_ps_x = create_tween()
		tw_ps_x.tween_interval(0.2)
		tw_ps_x.tween_property(paper_shadow, "position:x", 61.0, 0.4).set_trans(Tween.TRANS_SINE)
		tw_ps_x.tween_property(paper_shadow, "position:x", 66.0, 0.4).set_trans(Tween.TRANS_SINE)
		tw_ps_x.tween_property(paper_shadow, "position:x", 64.0, 0.4).set_trans(Tween.TRANS_SINE)
		var tw_ps = create_tween().set_parallel(true)
		tw_ps.tween_property(paper_shadow, "scale", Vector2(0.55, 0.35), 1.4)
		tw_ps.tween_property(paper_shadow, "modulate", Color(1, 1, 1, 0.55), 1.4)
	
	# ค่อยๆ ปรากฏเป็นเงามืดดำ (0.15s)
	var tw_mod = create_tween()
	tw_mod.tween_property(paper_on_floor, "modulate", Color(0.12, 0.1, 0.15, 0.95), 0.15)
	# จากนั้นค่อยๆ สลายความมืดคืนสภาพสู่สีกระดาษปกติขณะร่อนลงพื้น (1.25s)
	tw_mod.tween_property(paper_on_floor, "modulate", Color(0.28, 0.25, 0.3, 1.0), 0.30)
	tw_mod.tween_property(paper_on_floor, "modulate", Color(0.65, 0.6, 0.55, 1.0), 0.45)
	tw_mod.tween_property(paper_on_floor, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.50)
	
	var tw = create_tween().set_parallel(true)
	# ขยายสู่ขนาดปกติ 0.095
	tw.tween_property(paper_on_floor, "scale", Vector2(0.095, 0.095), 0.3)
	
	# ส่ายไปมาซ้ายขวาอย่างเป็นธรรมชาติ
	var tw_x = create_tween()
	tw_x.tween_interval(0.2)
	tw_x.tween_property(paper_on_floor, "position:x", 61.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw_x.tween_property(paper_on_floor, "position:x", 66.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw_x.tween_property(paper_on_floor, "position:x", 64.0, 0.4).set_trans(Tween.TRANS_SINE)
	
	# ค่อย ๆ ลอยตกลงสู่พื้นไม้
	tw.tween_property(paper_on_floor, "position:y", 96.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# หมุนส่ายเบา ๆ แล้ววางราบสนิท
	var tw_rot = create_tween()
	tw_rot.tween_property(paper_on_floor, "rotation", -0.08, 0.2)
	tw_rot.tween_property(paper_on_floor, "rotation", 0.06, 0.4)
	tw_rot.tween_property(paper_on_floor, "rotation", -0.03, 0.4)
	tw_rot.tween_property(paper_on_floor, "rotation", 0.0, 0.4)
	
	# เมื่อแตะพื้น ให้เรืองแสงกระพริบเบา ๆ (Pulsing glow) ดึงดูดสายตาให้รู้ว่าเป็นของสำคัญ
	tw.chain().tween_callback(func():
		if not is_instance_valid(paper_on_floor) or not paper_on_floor.visible:
			return
		if tw_paper_glow and tw_paper_glow.is_valid():
			tw_paper_glow.kill()
		tw_paper_glow = create_tween().set_loops()
		tw_paper_glow.tween_property(paper_on_floor, "modulate", Color(1.45, 1.35, 1.15, 1.0), 0.6).set_trans(Tween.TRANS_SINE)
		tw_paper_glow.tween_property(paper_on_floor, "modulate", Color(1.05, 1.0, 0.95, 1.0), 0.6).set_trans(Tween.TRANS_SINE)
	)

## เรียกเมื่อวงเวท/หลุมดำรอบสอง (วงเล็ก) ค่อย ๆ ดูดเศษทั้งหมด (15.0s)
func _on_suck_shards() -> void:
	var vortex_center: Vector2 = black_hole.position # (35, 96)
	
	# ค่อย ๆ ดูดเศษทั้ง 16 ชิ้นหมุนวนเข้าไปในวงเวททีละชิ้นอย่างนุ่มนวล
	for i in range(shards.size()):
		var s: Sprite2D = shards[i]
		var delay: float = randf_range(0.0, 1.0)
		var suck_duration: float = randf_range(0.6, 0.85)
		
		var tw = create_tween()
		tw.tween_interval(delay)
		tw.tween_callback(func():
			if not is_instance_valid(s):
				return
			var tw_suck = create_tween().set_parallel(true)
			tw_suck.tween_property(s, "position", vortex_center, suck_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw_suck.tween_property(s, "scale", Vector2.ZERO, suck_duration)
			tw_suck.tween_property(s, "modulate:a", 0.0, suck_duration)
			tw_suck.chain().tween_callback(func(): s.visible = false)
		)

## เรียกเมื่อเวลเดินมาหยุดข้างกระดาษ แล้วกระดาษลอยขึ้นสู่มือเวล (20.3s)
func _on_pickup_shard() -> void:
	if not paper_on_floor:
		return
	if tw_paper_glow and tw_paper_glow.is_valid():
		tw_paper_glow.kill()
		tw_paper_glow = null
	if paper_shadow:
		var tw_ps = create_tween()
		tw_ps.tween_property(paper_shadow, "modulate:a", 0.0, 0.5)
		tw_ps.chain().tween_callback(func(): paper_shadow.visible = false)
	var hand_pos: Vector2 = vel.position + Vector2(6.0, 0.0)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(paper_on_floor, "position", hand_pos, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(paper_on_floor, "scale", Vector2(0.12, 0.12), 0.6)
	tw.tween_property(paper_on_floor, "modulate", Color(2.0, 1.8, 1.2, 1.0), 0.6)

## แสดงตัวอักษรเวทมนตร์เด้งขึ้นมาพร้อมพื้นหลังกระดาษจาง ๆ และปุ่มกดไปต่อ (21.0s)
func _on_reveal_magic_text() -> void:
	if not rune_container:
		return
	if skip_ctrl:
		skip_ctrl.set_fast_forward_visible(false)
	can_fast_forward = false
	is_fast_forwarding = false
	Engine.time_scale = 1.0
	can_continue = true
	is_continuing = false
	
	# ลูปแสงออร่าเวทมนตร์เรืองรองอ่อน ๆ นุ่มนวล ไม่สว่างจ้าเกินไป
	if rune_aura_label:
		rune_aura_label.modulate = Color(1.0, 0.95, 0.85, 0.35)
		var tw_aura = create_tween().set_loops()
		tw_aura.tween_property(rune_aura_label, "modulate:a", 0.55, 1.5).set_trans(Tween.TRANS_SINE)
		tw_aura.tween_property(rune_aura_label, "modulate:a", 0.20, 1.5).set_trans(Tween.TRANS_SINE)
	
	# ตัวอักษรหลักคงความสว่างนวลตา คมชัด อ่านง่าย สบายตา
	if rune_label:
		rune_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# แสงกระพริบแนะนำให้กดไปต่อ
	if continue_prompt:
		continue_prompt.modulate = Color(1, 1, 1, 0)
		var tw_cp = create_tween()
		tw_cp.tween_property(continue_prompt, "modulate:a", 0.9, 0.6)
		var tw_pulse = create_tween().set_loops()
		tw_pulse.tween_property(continue_prompt, "modulate:a", 0.35, 0.8).set_trans(Tween.TRANS_SINE)
		tw_pulse.tween_property(continue_prompt, "modulate:a", 0.95, 0.8).set_trans(Tween.TRANS_SINE)

## สลายกระดาษและตัวหนังสือหายไปพร้อมกันเมื่อผู้เล่นกดไปต่อ
func _trigger_continue() -> void:
	if is_continuing:
		return
	is_continuing = true
	can_continue = false
	can_fast_forward = false
	is_fast_forwarding = false
	Engine.time_scale = 1.0
	if tw_paper_glow and tw_paper_glow.is_valid():
		tw_paper_glow.kill()
		tw_paper_glow = null
	
	# หยุด AnimationPlayer โดยคงสถานะปัจจุบันไว้ (pause + active = false)
	# ป้องกันไม่ให้ Godot รีเซ็ตค่าตำแหน่งของเวลกลับไปที่เฟรม 0 (-250)
	if anim_player:
		anim_player.pause()
		anim_player.active = false
	
	# ปิดข้อความแนะนำทันที
	if continue_prompt:
		var tw_cp = create_tween()
		tw_cp.tween_property(continue_prompt, "modulate:a", 0.0, 0.2)
	
	# 1. เวลหันขวาและเริ่มเดินไปทางขวาทันที (ไม่ดีเลย์) ด้วยท่า walk_right
	vel.visible = true
	vel.flip_h = false
	vel.play("walk_right")
	if vel.position.x < 0.0:
		vel.position.x = 50.0
	
	var tw_walk_out = create_tween()
	tw_walk_out.tween_property(vel, "position:x", 260.0, 2.5).set_trans(Tween.TRANS_LINEAR)
	
	# 2. สลายตัวหนังสือและแผ่นกระดาษในมือควบคู่กันไป
	var tw_dissolve = create_tween().set_parallel(true)
	
	# กล่องข้อความเวทมนตร์สลายลอยฟุ้งหายไป
	if rune_container:
		tw_dissolve.tween_property(rune_container, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_dissolve.tween_property(rune_container, "scale", Vector2(1.12, 1.12), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# พื้นหลังกระดาษและเงาสลายหายไป
	if parchment_shadow:
		tw_dissolve.tween_property(parchment_shadow, "modulate:a", 0.0, 0.6)
	if parchment_frame:
		tw_dissolve.tween_property(parchment_frame, "modulate:a", 0.0, 0.6)
	if paper_shadow:
		tw_dissolve.tween_property(paper_shadow, "modulate:a", 0.0, 0.4)
	
	# แผ่นกระดาษบนมือเวลสลายหายไปพร้อมตัวหนังสือ
	if paper_on_floor:
		tw_dissolve.tween_property(paper_on_floor, "modulate", Color(3.0, 2.5, 1.5, 0.0), 0.6)
		tw_dissolve.tween_property(paper_on_floor, "scale", Vector2(0.16, 0.16), 0.6)
		tw_dissolve.tween_property(paper_on_floor, "position:y", paper_on_floor.position.y - 10.0, 0.6)
	
	# ฉากหลังสีดำจากการอ่าน จางลงคืนสู่บรรยากาศห้องสมุดปกติ
	if backdrop:
		tw_dissolve.tween_property(backdrop, "color", Color(0, 0, 0, 0), 0.6)
	
	tw_dissolve.chain().tween_callback(func():
		if paper_on_floor:
			paper_on_floor.visible = false
		if rune_container:
			rune_container.visible = false
		if parchment_frame:
			parchment_frame.visible = false
		if parchment_shadow:
			parchment_shadow.visible = false
	)
	
	# 3. ขณะที่เวลเดินไปเกือบสุดห้อง ค่อย ๆ Fade จอดำสนิท เพื่อตัดฉากสู่ภายนอก
	var tw_fade_out = create_tween()
	tw_fade_out.tween_interval(1.3)
	tw_fade_out.tween_property(backdrop, "color", Color(0, 0, 0, 1), 0.8)
	tw_fade_out.tween_callback(func():
		Engine.time_scale = 1.0
		emit_signal("cutscene_finished")
		print("[IntroCutscene] Transitioning to OutsideCutscene...")
		get_tree().change_scene_to_file("res://scenes/cutscene/outside_cutscene.tscn")
	)

## โหมดสำรอง: เล่นด้วย GDScript Tween ล้วน ๆ
func play_with_tween() -> void:
	master.position = Vector2(spawn_x, character_y)
	master.scale = Vector2.ONE
	master.modulate = Color(1, 1, 1, 1)
	master.visible = true
	master.flip_h = true
	master.play("walk_left")
	
	vel.position = Vector2(spawn_x, character_y)
	vel.scale = Vector2.ONE
	vel.visible = false
	vel.flip_h = false
	
	exclamation_mark.visible = false
	exclamation_mark.scale = Vector2.ZERO
	exclamation_mark.position = Vector2(0, -56)
	
	black_hole.visible = false
	black_hole.position = Vector2(master_target_x, 97)
	black_hole.scale = Vector2.ZERO
	room_lighting.color = Color(1, 1, 1, 1)
	
	_reset_cutscene_state()
	
	# 1. อาจารย์เดินเข้า (5.4s)
	var tw_m = create_tween()
	tw_m.tween_property(master, "position:x", master_target_x, 5.4)
	tw_m.tween_callback(func():
		master.flip_h = false
		master.play("breathe_blink")
	)
	
	# 2. เวลเดินเข้า (1.8s -> 6.0s)
	var tw_v = create_tween()
	tw_v.tween_interval(1.8)
	tw_v.tween_callback(func():
		vel.visible = true
		vel.play("walk_right")
	)
	tw_v.tween_property(vel, "position:x", vel_target_x, 4.2)
	tw_v.tween_callback(func(): vel.play("breathe_blink"))
	
	# 3. หลุมดำเปิดใต้เท้าอาจารย์ (6.8s -> 7.8s) - แสงห้องปกติ ไม่มืด
	var tw_hole = create_tween()
	tw_hole.tween_interval(6.8)
	tw_hole.tween_callback(func(): black_hole.visible = true)
	tw_hole.tween_property(black_hole, "scale", Vector2(1.2, 1.0), 1.0)
	
	# 4. อาจารย์ shock1 (7.8s -> 9.0s)
	var tw_shock = create_tween()
	tw_shock.tween_interval(7.8)
	tw_shock.tween_callback(func(): master.play("shock1"))
	
	# 4. อาจารย์ตกหลุมดำ (9.0s -> 9.38s)
	var tw_fall = create_tween()
	tw_fall.tween_interval(9.0)
	tw_fall.tween_property(master, "position:y", 53.0, 0.08)
	var tw_drop = create_tween()
	tw_drop.tween_interval(9.08)
	tw_drop.parallel().tween_property(master, "position:y", 97.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_drop.parallel().tween_property(master, "scale", Vector2(0.1, 0.1), 0.30)
	tw_drop.parallel().tween_property(master, "modulate:a", 0.0, 0.30)
	tw_drop.tween_callback(func():
		master.visible = false
		vel.play("shock")
		exclamation_mark.visible = true
		exclamation_mark.position = Vector2(0, -50)
		var tw_ex = create_tween()
		tw_ex.tween_property(exclamation_mark, "position:y", -60.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_ex.parallel().tween_property(exclamation_mark, "scale", Vector2(1.35, 1.35), 0.08)
		tw_ex.tween_property(exclamation_mark, "position:y", -54.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_ex.parallel().tween_property(exclamation_mark, "scale", Vector2(0.95, 0.95), 0.10)
		tw_ex.tween_property(exclamation_mark, "position:y", -57.5, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_ex.parallel().tween_property(exclamation_mark, "scale", Vector2(1.05, 1.05), 0.12)
		tw_ex.tween_property(exclamation_mark, "position:y", -56.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_ex.parallel().tween_property(exclamation_mark, "scale", Vector2(1.0, 1.0), 0.12)
		tw_ex.chain().tween_callback(func():
			if not is_instance_valid(exclamation_mark) or not exclamation_mark.visible:
				return
			if tw_ex_bob and tw_ex_bob.is_valid():
				tw_ex_bob.kill()
			tw_ex_bob = create_tween().set_loops()
			tw_ex_bob.tween_property(exclamation_mark, "position:y", -59.5, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw_ex_bob.tween_property(exclamation_mark, "position:y", -56.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		)
	)
	
	# 5. ปรมาจารย์จมลงหลุมดำจนมิด แล้วคัมภีร์ดีดเด้งสูงเฉียงขวาออกห่างจากเวล (9.38s -> 9.80s)
	var tw_book = create_tween()
	tw_book.tween_interval(9.38)
	tw_book.tween_callback(func():
		khampri.visible = true
		khampri.position = Vector2(42, 58)
		khampri.rotation = 0.0
		if khampri_shadow:
			khampri_shadow.visible = true
			khampri_shadow.position = Vector2(42, 98)
			khampri_shadow.scale = Vector2(0.3, 0.2)
			khampri_shadow.modulate = Color(1, 1, 1, 0.15)
		
		# ดีดเด้งขึ้นสูงและเฉียงขวา 0.18s
		var tw_pop = create_tween().set_parallel(true)
		tw_pop.tween_property(khampri, "position:x", 54.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_pop.tween_property(khampri, "position:y", 18.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_pop.tween_property(khampri, "rotation", 0.12, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if khampri_shadow:
			tw_pop.tween_property(khampri_shadow, "position:x", 54.0, 0.18)
			tw_pop.tween_property(khampri_shadow, "scale", Vector2(0.65, 0.4), 0.18)
			tw_pop.tween_property(khampri_shadow, "modulate:a", 0.35, 0.18)
		
		# ตกลงสู่พื้นไม้ด้านขวาอย่างรวดเร็ว 0.24s
		tw_pop.chain().set_parallel(true)
		tw_pop.tween_property(khampri, "position:x", 64.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_pop.tween_property(khampri, "position:y", 96.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_pop.tween_property(khampri, "rotation", 0.0, 0.24)
		if khampri_shadow:
			tw_pop.tween_property(khampri_shadow, "position:x", 64.0, 0.24)
			tw_pop.tween_property(khampri_shadow, "scale", Vector2(1.1, 0.7), 0.24)
			tw_pop.tween_property(khampri_shadow, "modulate:a", 0.65, 0.24)
		
		# หลุมดำแรกหดตัวปิดหลังจากคัมภีร์ลงแตะพื้น
		var tw_h1 = create_tween()
		tw_h1.tween_interval(0.42)
		tw_h1.tween_property(black_hole, "scale", Vector2.ZERO, 0.5)
		tw_h1.tween_callback(func(): black_hole.visible = false)
	)
	
	# 6. คัมภีร์ลอยตัวขึ้น เอียง และสั่นด้วยพลังเวทมนตร์ (10.8s -> 11.8s)
	var tw_levitate = create_tween()
	tw_levitate.tween_interval(10.8)
	tw_levitate.tween_callback(func():
		var tw_float = create_tween().set_parallel(true)
		# ลอยตัวขึ้นสู่ความสูง 79 px
		tw_float.tween_property(khampri, "position:y", 79.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if khampri_shadow:
			tw_float.tween_property(khampri_shadow, "scale", Vector2(0.85, 0.5), 1.0)
			tw_float.tween_property(khampri_shadow, "modulate:a", 0.40, 1.0)
		# เรืองแสงเวทมนตร์เข้มข้นขึ้นเรื่อยๆ ก่อนแตก
		tw_float.tween_property(khampri, "modulate", Color(1.8, 1.6, 1.25, 1.0), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		# หมุนเอียงเบา ๆ ไปมา (Tilt & Wobble)
		var tw_wobble = create_tween()
		tw_wobble.tween_property(khampri, "rotation", 0.04, 0.25)
		tw_wobble.tween_property(khampri, "rotation", -0.05, 0.25)
		tw_wobble.tween_property(khampri, "rotation", 0.07, 0.25)
		tw_wobble.tween_property(khampri, "rotation", -0.04, 0.25)
		
		# สั่นระริก (Tremble)
		var tw_shake = create_tween().set_loops(10)
		tw_shake.tween_property(khampri, "position:x", 65.5, 0.05)
		tw_shake.tween_property(khampri, "position:x", 62.5, 0.05)
	)
	
	# 7. คัมภีร์แตกเป็น 16 ชิ้น (11.8s)
	var tw_shatter = create_tween()
	tw_shatter.tween_interval(11.8)
	tw_shatter.tween_callback(_on_shatter_khampri)
	
	# 8. รอแปปนึง แล้ววงเวทรอบสอง (วงเล็ก) ค่อย ๆ ดูด (14.2s -> 17.5s)
	var tw_h2_in = create_tween()
	tw_h2_in.tween_interval(14.2)
	tw_h2_in.tween_callback(func():
		black_hole.position = Vector2(64, 96)
		black_hole.visible = true
		var tw_h2 = create_tween()
		tw_h2.tween_property(black_hole, "scale", Vector2(0.75, 0.65), 0.8)
	)
	var tw_suck = create_tween()
	tw_suck.tween_interval(15.0)
	tw_suck.tween_callback(_on_suck_shards)
	
	# เศษคัมภีร์แผ่นสุดท้ายร่อนตกลงมาจากด้านบนสู่พื้นไม้ (16.4s)
	var tw_flutter = create_tween()
	tw_flutter.tween_interval(16.4)
	tw_flutter.tween_callback(_on_paper_flutter_down)
	
	var tw_h2_out = create_tween()
	tw_h2_out.tween_interval(17.2)
	tw_h2_out.tween_property(black_hole, "scale", Vector2.ZERO, 0.5)
	tw_h2_out.tween_callback(func(): black_hole.visible = false)
	
	# 9. เมื่อกระดาษลงสู่พื้นแล้ว เวลค่อยเดินเข้าไปหา (18.0s -> 20.0s)
	var tw_walk_paper = create_tween()
	tw_walk_paper.tween_interval(18.0)
	tw_walk_paper.tween_callback(func():
		if tw_ex_bob and tw_ex_bob.is_valid():
			tw_ex_bob.kill()
		exclamation_mark.visible = false
		vel.play("walk_right")
	)
	tw_walk_paper.tween_property(vel, "position", Vector2(50, 59), 2.0)
	tw_walk_paper.tween_callback(func():
		vel.play("breathe_blink")
	)
	
	# 10. เวลหยิบกระดาษลอยขึ้น (20.3s)
	var tw_pickup = create_tween()
	tw_pickup.tween_interval(20.3)
	tw_pickup.tween_callback(_on_pickup_shard)
	
	# 11. ตัวอักษรเวทมนตร์เด้งขึ้นมาพร้อมพื้นหลังกระดาษจาง ๆ กึ่งกลางจอ (21.0s)
	var tw_ui = create_tween()
	tw_ui.tween_interval(21.0)
	tw_ui.tween_callback(func():
		var tw_t = create_tween().set_parallel(true)
		tw_t.tween_property(backdrop, "color", Color(0, 0, 0, 0.85), 0.5)
		tw_t.tween_property(parchment_frame, "modulate", Color(1, 1, 1, 1.0), 0.5)
		if parchment_shadow:
			tw_t.tween_property(parchment_shadow, "modulate", Color(0, 0, 0, 0.55), 0.5)
		
		rune_container.scale = Vector2(0.2, 0.2)
		rune_container.modulate = Color(1, 1, 1, 0)
		var tw_pop = create_tween().set_parallel(true)
		tw_pop.tween_property(rune_container, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_pop.tween_property(rune_container, "modulate", Color(1, 1, 1, 1), 0.4)
		_on_reveal_magic_text()
	)
