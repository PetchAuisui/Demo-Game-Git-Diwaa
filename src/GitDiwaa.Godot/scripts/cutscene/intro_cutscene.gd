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
@onready var shards_container: Node2D = $Shards
@onready var paper_on_floor: Sprite2D = $PaperOnFloor

@onready var magic_ui: CanvasLayer = $MagicStoryUI
@onready var backdrop: ColorRect = $MagicStoryUI/Backdrop
@onready var parchment_shadow: TextureRect = $MagicStoryUI/ParchmentShadow
@onready var parchment_frame: TextureRect = $MagicStoryUI/ParchmentFrame
@onready var rune_container: Control = $MagicStoryUI/RuneContainer
@onready var rune_label: RichTextLabel = $MagicStoryUI/RuneContainer/RuneRichLabel
@onready var continue_prompt: Label = $MagicStoryUI/RuneContainer/ContinuePrompt

var shards: Array[Sprite2D] = []
var can_continue: bool = false
var is_continuing: bool = false

signal cutscene_finished

# พิกัดปลายทางที่เศษทั้ง 20 ชิ้นจะกระจายตกบนพื้นห้องล้อมรอบจุดที่คัมภีร์แตก (30, 96)
const SHARD_LANDING_POSITIONS: Array[Vector2] = [
	Vector2(-5.0, 84.0),
	Vector2(4.0, 78.0),
	Vector2(15.0, 74.0),
	Vector2(30.0, 72.0),
	Vector2(45.0, 74.0),
	Vector2(58.0, 78.0),
	Vector2(68.0, 84.0),
	Vector2(75.0, 96.0),
	Vector2(70.0, 104.0),
	Vector2(58.0, 108.0),
	Vector2(45.0, 110.0),
	Vector2(30.0, 110.0),
	Vector2(15.0, 108.0),
	Vector2(2.0, 104.0),
	Vector2(-8.0, 96.0),
	Vector2(12.0, 88.0),
	Vector2(48.0, 88.0),
	Vector2(50.0, 102.0),
	Vector2(12.0, 102.0),
	Vector2(30.0, 86.0),
]

func _ready() -> void:
	_init_shards()
	_reset_cutscene_state()
	
	if playback_mode == "AnimationPlayer":
		if not anim_player.is_playing() or anim_player.current_animation != "walk_in":
			anim_player.play("walk_in")
		anim_player.animation_finished.connect(func(_anim_name):
			vel.play("breathe_blink")
		)
	else:
		if anim_player.is_playing():
			anim_player.stop()
		play_with_tween()

func _input(event: InputEvent) -> void:
	if not can_continue or is_continuing:
		return
	if event.is_action_pressed("ui_accept") or \
	   (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)) or \
	   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
		_trigger_continue()

func _init_shards() -> void:
	shards.clear()
	if shards_container:
		for child in shards_container.get_children():
			if child is Sprite2D:
				shards.append(child)

func _reset_cutscene_state() -> void:
	can_continue = false
	is_continuing = false
	
	# แสงห้องปกติ ไม่มืด กล้องนิ่ง
	if room_lighting:
		room_lighting.color = Color(1, 1, 1, 1)
	position = Vector2(960, 540)
	
	if khampri:
		khampri.visible = false
		khampri.position = Vector2(40, 52)
		khampri.rotation = 0.0
		khampri.scale = Vector2(0.25, 0.25)
		khampri.modulate = Color(1, 1, 1, 1)
	
	for s in shards:
		s.visible = false
		s.scale = Vector2(0.25, 0.25)
		s.modulate = Color(1, 1, 1, 1)
		s.rotation = 0.0
	
	if paper_on_floor:
		paper_on_floor.visible = false
		paper_on_floor.position = Vector2(30, 96)
		paper_on_floor.rotation = 0.0
		paper_on_floor.scale = Vector2(0.065, 0.065)
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
	if continue_prompt:
		continue_prompt.modulate = Color(1, 1, 1, 0)

## เรียกเมื่อคัมภีร์แตกสลาย (11.8s)
func _on_shatter_khampri() -> void:
	if not khampri:
		return
	khampri.visible = false
	var origin: Vector2 = khampri.position # (30, 96) บนพื้นไม้
	
	# เมื่อคัมภีร์แตก กระดาษยังไม่ปรากฏทันที (จะร่วงหล่นลงมาทีหลังจากเหตุการณ์ดูดเศษซาก)
	if paper_on_floor:
		paper_on_floor.visible = false
	
	# เศษคัมภีร์ทั้ง 20 ชิ้นระเบิดพุ่งกระจายรอบจุดแตก (เศษไม่เอียง สไตล์ Pixel Art)
	for i in range(shards.size()):
		var s: Sprite2D = shards[i]
		s.position = origin
		s.scale = Vector2(0.25, 0.25)
		s.modulate = Color(1.4, 1.3, 1.1, 1.0)
		s.visible = true
		s.rotation = 0.0 # ไม่เอียง
		
		var target: Vector2 = SHARD_LANDING_POSITIONS[i] if i < SHARD_LANDING_POSITIONS.size() else origin + Vector2(randf_range(-35, 35), randf_range(-15, 15))
		var apex_y: float = min(origin.y, target.y) - randf_range(16.0, 30.0)
		var duration: float = randf_range(0.42, 0.58)
		
		var tw = create_tween().set_parallel(true)
		tw.tween_property(s, "position:x", target.x, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var tw_y = create_tween()
		tw_y.tween_property(s, "position:y", apex_y, duration * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_y.tween_property(s, "position:y", target.y, duration * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(s, "modulate", Color(1, 1, 1, 1), duration)

## เศษคัมภีร์แผ่นสุดท้ายที่หลงเหลือ ร่วงหล่นลงมาจากด้านบนเล็กน้อยสู่พื้นไม้ (16.6s -> 17.8s)
func _on_paper_flutter_down() -> void:
	if not paper_on_floor:
		return
	paper_on_floor.visible = true
	paper_on_floor.position = Vector2(34.0, 52.0)
	paper_on_floor.rotation = -0.08
	paper_on_floor.scale = Vector2(0.065, 0.065)
	paper_on_floor.modulate = Color(1.3, 1.25, 1.1, 1.0)
	
	var tw = create_tween().set_parallel(true)
	# ส่ายไปมาซ้ายขวาอย่างเป็นธรรมชาติ
	var tw_x = create_tween()
	tw_x.tween_property(paper_on_floor, "position:x", 27.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw_x.tween_property(paper_on_floor, "position:x", 32.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw_x.tween_property(paper_on_floor, "position:x", 30.0, 0.4).set_trans(Tween.TRANS_SINE)
	
	# ค่อย ๆ ลอยตกลงสู่พื้นไม้
	tw.tween_property(paper_on_floor, "position:y", 96.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# หมุนส่ายเบา ๆ แล้ววางราบสนิท
	var tw_rot = create_tween()
	tw_rot.tween_property(paper_on_floor, "rotation", 0.06, 0.4)
	tw_rot.tween_property(paper_on_floor, "rotation", -0.03, 0.4)
	tw_rot.tween_property(paper_on_floor, "rotation", 0.0, 0.4)
	
	tw.tween_property(paper_on_floor, "modulate", Color(1, 1, 1, 1), 1.2)

## เรียกเมื่อวงเวท/หลุมดำรอบสอง (วงเล็ก) ค่อย ๆ ดูดเศษทั้งหมด (15.0s)
func _on_suck_shards() -> void:
	var vortex_center: Vector2 = black_hole.position # (35, 96)
	
	# ค่อย ๆ ดูดเศษทั้ง 20 ชิ้นหมุนวนเข้าไปในวงเวททีละชิ้นอย่างนุ่มนวล
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
	var hand_pos: Vector2 = vel.position + Vector2(6.0, 0.0)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(paper_on_floor, "position", hand_pos, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(paper_on_floor, "scale", Vector2(0.08, 0.08), 0.6)
	tw.tween_property(paper_on_floor, "modulate", Color(2.0, 1.8, 1.2, 1.0), 0.6)

## แสดงตัวอักษรเวทมนตร์เด้งขึ้นมาพร้อมพื้นหลังกระดาษจาง ๆ และปุ่มกดไปต่อ (21.0s)
func _on_reveal_magic_text() -> void:
	if not rune_container:
		return
	can_continue = true
	is_continuing = false
	
	# ลูปแสงเรืองรองนุ่มนวลบนตัวอักษรมนตราโบราณ
	if rune_label:
		var tw_glow = create_tween().set_loops()
		tw_glow.tween_property(rune_label, "modulate", Color(1.15, 1.1, 0.95, 1.0), 1.5).set_trans(Tween.TRANS_SINE)
		tw_glow.tween_property(rune_label, "modulate", Color(0.92, 0.88, 0.8, 1.0), 1.5).set_trans(Tween.TRANS_SINE)
	
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
	
	# ปิดข้อความแนะนำ
	if continue_prompt:
		var tw_cp = create_tween()
		tw_cp.tween_property(continue_prompt, "modulate:a", 0.0, 0.2)
	
	var tw_dissolve = create_tween().set_parallel(true)
	
	# 1. กล่องข้อความเวทมนตร์สลายลอยฟุ้งหายไป
	if rune_container:
		tw_dissolve.tween_property(rune_container, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_dissolve.tween_property(rune_container, "scale", Vector2(1.12, 1.12), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 2. พื้นหลังกระดาษและเงาสลายหายไป
	if parchment_shadow:
		tw_dissolve.tween_property(parchment_shadow, "modulate:a", 0.0, 0.8)
	if parchment_frame:
		tw_dissolve.tween_property(parchment_frame, "modulate:a", 0.0, 0.8)
	
	# 3. แผ่นกระดาษบนมือเวลสลายหายไปพร้อมตัวหนังสือ (เรืองแสงวาบ ลอยขึ้น และสลายเป็นละออง)
	if paper_on_floor:
		tw_dissolve.tween_property(paper_on_floor, "modulate", Color(3.0, 2.5, 1.5, 0.0), 0.8)
		tw_dissolve.tween_property(paper_on_floor, "scale", Vector2(0.12, 0.12), 0.8)
		tw_dissolve.tween_property(paper_on_floor, "position:y", paper_on_floor.position.y - 10.0, 0.8)
	
	# 4. ฉากหลังสีดำจางลงสู่ปกติ
	if backdrop:
		tw_dissolve.tween_property(backdrop, "color", Color(0, 0, 0, 0), 1.0)
	
	tw_dissolve.chain().tween_callback(func():
		if paper_on_floor:
			paper_on_floor.visible = false
		if magic_ui:
			magic_ui.visible = false
		emit_signal("cutscene_finished")
		print("[IntroCutscene] Cutscene finished.")
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
	
	# 4. อาจารย์ตกหลุมดำ (9.0s -> 9.35s)
	var tw_fall = create_tween()
	tw_fall.tween_interval(9.0)
	tw_fall.tween_property(master, "position:y", 53.0, 0.08)
	var tw_drop = create_tween()
	tw_drop.tween_interval(9.08)
	tw_drop.parallel().tween_property(master, "position:y", 97.0, 0.27).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_drop.parallel().tween_property(master, "scale", Vector2(0.1, 0.1), 0.27)
	tw_drop.parallel().tween_property(master, "modulate:a", 0.0, 0.27)
	tw_drop.tween_callback(func():
		master.visible = false
		vel.play("shock")
		exclamation_mark.visible = true
		var tw_ex = create_tween()
		tw_ex.tween_property(exclamation_mark, "scale", Vector2(1.35, 1.35), 0.08)
		tw_ex.tween_property(exclamation_mark, "scale", Vector2(1.0, 1.0), 0.08)
	)
	
	# 5. ปรมาจารย์จมลงหลุมดำจนมิด แล้วคัมภีร์จึงดีดดรอปออกมาสไตล์ Minecraft (9.35s -> 9.80s)
	var tw_book = create_tween()
	tw_book.tween_interval(9.35)
	tw_book.tween_callback(func():
		khampri.visible = true
		khampri.position = Vector2(38, 56)
		khampri.rotation = 0.0
		# ดีดขึ้นเล็กน้อย 0.15s
		var tw_pop = create_tween().set_parallel(true)
		tw_pop.tween_property(khampri, "position:x", 35.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_pop.tween_property(khampri, "position:y", 46.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# ตกถึงพื้นไม้ตรงๆ 0.30s (ไม่มีเด้ง)
		tw_pop.chain().set_parallel(true)
		tw_pop.tween_property(khampri, "position:x", 30.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_pop.tween_property(khampri, "position:y", 96.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		# หลุมดำแรกหดตัวปิดหลังจากคัมภีร์ลงแตะพื้น
		var tw_h1 = create_tween()
		tw_h1.tween_interval(0.45)
		tw_h1.tween_property(black_hole, "scale", Vector2.ZERO, 0.5)
		tw_h1.tween_callback(func(): black_hole.visible = false)
	)
	
	# 6. สั่นแค่คัมภีร์บนพื้นไม้ (11.2s -> 11.8s)
	var tw_tremble = create_tween()
	tw_tremble.tween_interval(11.2)
	tw_tremble.tween_callback(func():
		var tw_shake = create_tween().set_loops(6)
		tw_shake.tween_property(khampri, "position:x", 31.0, 0.05)
		tw_shake.tween_property(khampri, "position:x", 29.0, 0.05)
		tw_shake.chain().tween_property(khampri, "position:x", 30.0, 0.02)
	)
	
	# 7. คัมภีร์แตกเป็น 20 ชิ้น (11.8s)
	var tw_shatter = create_tween()
	tw_shatter.tween_interval(11.8)
	tw_shatter.tween_callback(_on_shatter_khampri)
	
	# 8. รอแปปนึง แล้ววงเวทรอบสอง (วงเล็ก) ค่อย ๆ ดูด (14.2s -> 17.5s)
	var tw_h2_in = create_tween()
	tw_h2_in.tween_interval(14.2)
	tw_h2_in.tween_callback(func():
		black_hole.position = Vector2(35, 96)
		black_hole.visible = true
		var tw_h2 = create_tween()
		tw_h2.tween_property(black_hole, "scale", Vector2(0.75, 0.65), 0.8)
	)
	var tw_suck = create_tween()
	tw_suck.tween_interval(15.0)
	tw_suck.tween_callback(_on_suck_shards)
	
	# เศษคัมภีร์แผ่นสุดท้ายร่อนตกลงมาจากด้านบนสู่พื้นไม้ (16.6s)
	var tw_flutter = create_tween()
	tw_flutter.tween_interval(16.6)
	tw_flutter.tween_callback(_on_paper_flutter_down)
	
	var tw_h2_out = create_tween()
	tw_h2_out.tween_interval(17.2)
	tw_h2_out.tween_property(black_hole, "scale", Vector2.ZERO, 0.5)
	tw_h2_out.tween_callback(func(): black_hole.visible = false)
	
	# 9. เมื่อกระดาษลงสู่พื้นแล้ว เวลค่อยเดินเข้าไปหา (18.0s -> 20.0s)
	var tw_walk_paper = create_tween()
	tw_walk_paper.tween_interval(18.0)
	tw_walk_paper.tween_callback(func():
		exclamation_mark.visible = false
		vel.play("walk_right")
	)
	tw_walk_paper.tween_property(vel, "position", Vector2(16, 59), 2.0)
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
		tw_t.tween_property(parchment_frame, "modulate", Color(1, 1, 1, 0.78), 0.5)
		if parchment_shadow:
			tw_t.tween_property(parchment_shadow, "modulate", Color(0, 0, 0, 0.55), 0.5)
		
		rune_container.scale = Vector2(0.2, 0.2)
		rune_container.modulate = Color(1, 1, 1, 0)
		var tw_pop = create_tween().set_parallel(true)
		tw_pop.tween_property(rune_container, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_pop.tween_property(rune_container, "modulate", Color(1, 1, 1, 1), 0.4)
		_on_reveal_magic_text()
	)
