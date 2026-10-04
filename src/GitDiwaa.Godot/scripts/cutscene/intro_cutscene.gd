extends Sprite2D

## การควบคุม Cutscene เปิดเรื่อง (Intro Cutscene)
## ลำดับเหตุการณ์:
## 1. ปรมาจารย์ & เวล เดินเข้ามายังกลางห้อง (จังหวะ 400ms / 200ms)
## 2. แสงมืดลง + หลุมดำเปิดใต้เท้าอาจารย์
## 3. อาจารย์รู้ตัว ทำหน้า shock1 ยืนตกใจดีเลย์ 1.2 วินาที
## 4. อาจารย์สะดุ้ง คัมภีร์ (khampri) หลุดมือกระเด็นตกพื้นด้านหน้า (26, 86) สไตล์ Pixel Art
## 5. อาจารย์ถูกดูดจมหายเข้าไปในหลุมดำ -> เวลช็อก + หลุมดำปิด
## 6. คัมภีร์สั่น มีแสงทองลอดออกมา แล้วแตกกระจายออกเป็น 20 ชิ้น (minikhampri) ล้อมรอบจุดแตก
##    โดยมีแผ่นกระดาษโบราณ (paper.png) ชิ้นเดียวที่เหลืออยู่ตรงกลางของเศษซาก
## 7. รอแปปนึง ให้เห็นเศษซากเต็มพื้น
## 8. วงเวท/หลุมดำรอบสองค่อย ๆ ปรากฏขึ้นมา ค่อย ๆ ดูดเศษทั้ง 20 ชิ้นหายไปหมด
##    เหลือเฉพาะกระดาษแผ่นเดียวตรงกลางที่ไม่โดนดูดเข้าไป
## 9. หลุมดำปิด เวลได้สติเดินข้ามห้องมาหากระดาษที่ตกอยู่
## 10. กระดาษลอยขึ้นสู่มือเวล
## 11. หน้าจอแสดงพื้นหลังกระดาษจาง ๆ พร้อมตัวอักษรเวทมนตร์ภาษาไทย (ฟอนต์ Chakra Petch)
##     เด้งขึ้นมา ลอยระลอกคลื่น เรืองแสงสีทอง และยึกยักมีพลังเวท
## 12. เมื่อผู้เล่นกดไปต่อ (Space / คลิก) กระดาษในมือและตัวหนังสือจะสลายหายไปพร้อมกัน

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
@onready var parchment_frame: TextureRect = $MagicStoryUI/ParchmentFrame
@onready var rune_container: Control = $MagicStoryUI/RuneContainer
@onready var rune_label: RichTextLabel = $MagicStoryUI/RuneContainer/RuneRichLabel
@onready var continue_prompt: Label = $MagicStoryUI/RuneContainer/ContinuePrompt

var shards: Array[Sprite2D] = []
var can_continue: bool = false
var is_continuing: bool = false

signal cutscene_finished

# พิกัดปลายทางที่เศษทั้ง 20 ชิ้นจะกระจายตกบนพื้นห้องล้อมรอบจุดที่คัมภีร์แตก (26, 86)
const SHARD_LANDING_POSITIONS: Array[Vector2] = [
	Vector2(-14.0, 80.0),
	Vector2(-6.0, 74.0),
	Vector2(4.0, 71.0),
	Vector2(16.0, 70.0),
	Vector2(32.0, 71.0),
	Vector2(46.0, 74.0),
	Vector2(58.0, 80.0),
	Vector2(68.0, 88.0),
	Vector2(64.0, 96.0),
	Vector2(52.0, 101.0),
	Vector2(38.0, 103.0),
	Vector2(24.0, 103.0),
	Vector2(10.0, 101.0),
	Vector2(-2.0, 96.0),
	Vector2(-12.0, 88.0),
	Vector2(8.0, 81.0),
	Vector2(20.0, 94.0),
	Vector2(34.0, 80.0),
	Vector2(44.0, 92.0),
	Vector2(14.0, 91.0),
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
	
	if khampri:
		khampri.visible = false
		khampri.position = Vector2(38, 50)
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
		paper_on_floor.position = Vector2(26, 86)
		paper_on_floor.scale = Vector2(0.065, 0.065)
		paper_on_floor.modulate = Color(1, 1, 1, 1)
	
	if backdrop:
		backdrop.color = Color(0, 0, 0, 0)
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
	var origin: Vector2 = khampri.position # (26, 86)
	
	# แผ่นกระดาษโบราณปรากฏขึ้นตรงกลางจุดที่คัมภีร์แตก และอยู่นิ่งที่ตรงกลาง
	if paper_on_floor:
		paper_on_floor.position = origin
		paper_on_floor.visible = true
		paper_on_floor.scale = Vector2(0.065, 0.065) # ขนาดใหญ่กว่าเศษนิดหน่อย
		paper_on_floor.modulate = Color(1.8, 1.6, 1.2, 1.0)
		var tw_p = create_tween()
		tw_p.tween_property(paper_on_floor, "modulate", Color(1, 1, 1, 1), 0.6)
	
	# เศษคัมภีร์ทั้ง 20 ชิ้นระเบิดพุ่งกระจายรอบจุดแตก (มีกระดาษอยู่ตรงกลาง)
	for i in range(shards.size()):
		var s: Sprite2D = shards[i]
		s.position = origin
		s.scale = Vector2(0.25, 0.25)
		s.modulate = Color(1.6, 1.5, 1.1, 1.0)
		s.visible = true
		s.rotation = 0.0
		
		var target: Vector2 = SHARD_LANDING_POSITIONS[i] if i < SHARD_LANDING_POSITIONS.size() else origin + Vector2(randf_range(-40, 40), randf_range(-15, 20))
		var apex_y: float = min(origin.y, target.y) - randf_range(20.0, 38.0)
		var duration: float = randf_range(0.45, 0.65)
		
		var tw = create_tween().set_parallel(true)
		tw.tween_property(s, "position:x", target.x, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var tw_y = create_tween()
		tw_y.tween_property(s, "position:y", apex_y, duration * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_y.tween_property(s, "position:y", target.y, duration * 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw_y.tween_property(s, "rotation", randf_range(-3.0, 3.0), duration)
		tw.tween_property(s, "modulate", Color(1, 1, 1, 1), duration)

## เรียกเมื่อวงเวท/หลุมดำรอบสองค่อย ๆ ดูดเศษทั้งหมด (15.2s)
func _on_suck_shards() -> void:
	var vortex_center: Vector2 = black_hole.position # (32, 90)
	
	# ค่อย ๆ ดูดเศษทั้ง 20 ชิ้นหมุนวนเข้าไปในวงเวททีละชิ้น/เป็นระลอกอย่างนุ่มนวล
	for i in range(shards.size()):
		var s: Sprite2D = shards[i]
		var delay: float = randf_range(0.0, 1.2)
		var suck_duration: float = randf_range(0.7, 1.0)
		
		var tw = create_tween()
		tw.tween_interval(delay)
		tw.tween_callback(func():
			if not is_instance_valid(s):
				return
			var tw_suck = create_tween().set_parallel(true)
			tw_suck.tween_property(s, "position", vortex_center, suck_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw_suck.tween_property(s, "scale", Vector2.ZERO, suck_duration)
			tw_suck.tween_property(s, "rotation", s.rotation + randf_range(4.0, 8.0), suck_duration)
			tw_suck.tween_property(s, "modulate:a", 0.0, suck_duration)
			tw_suck.chain().tween_callback(func(): s.visible = false)
		)
	
	# กระดาษแผ่นเดียวที่เหลืออยู่ตรงกลาง ไม่ถูกดูดเข้าไป! กะพริบแสงสีทองอย่างอัศจรรย์
	if paper_on_floor:
		var tw_p = create_tween().set_loops(5)
		tw_p.tween_property(paper_on_floor, "modulate", Color(2.0, 1.8, 1.1, 1.0), 0.45)
		tw_p.tween_property(paper_on_floor, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.45)

## เรียกเมื่อเวลเดินมาหยุดข้างกระดาษ แล้วกระดาษลอยขึ้นสู่มือเวล (20.8s)
func _on_pickup_shard() -> void:
	if not paper_on_floor:
		return
	var hand_pos: Vector2 = vel.position + Vector2(6.0, -8.0)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(paper_on_floor, "position", hand_pos, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(paper_on_floor, "scale", Vector2(0.08, 0.08), 0.7)
	tw.tween_property(paper_on_floor, "modulate", Color(2.2, 1.9, 1.2, 1.0), 0.7)

## แสดงตัวอักษรเวทมนตร์เด้งขึ้นมาพร้อมพื้นหลังกระดาษจาง ๆ และปุ่มกดไปต่อ (21.6s)
func _on_reveal_magic_text() -> void:
	if not rune_container:
		return
	can_continue = true
	is_continuing = false
	
	# ลูปแสงเรืองรองบนตัวอักษรเวทมนตร์
	if rune_label:
		var tw_glow = create_tween().set_loops()
		tw_glow.tween_property(rune_label, "modulate", Color(1.3, 1.25, 1.1, 1.0), 1.2).set_trans(Tween.TRANS_SINE)
		tw_glow.tween_property(rune_label, "modulate", Color(1.0, 0.96, 0.9, 1.0), 1.2).set_trans(Tween.TRANS_SINE)
	
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
	
	# 2. พื้นหลังกระดาษจาง ๆ สลายหายไป
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
	
	# 3. ฉากสั่น + แสงมืดลง
	var tw_env = create_tween()
	tw_env.tween_interval(6.3)
	tw_env.tween_property(room_lighting, "color", Color(0.62, 0.6, 0.73, 1.0), 1.2)
	
	# 4. หลุมดำเปิด (6.8s -> 7.8s)
	var tw_hole = create_tween()
	tw_hole.tween_interval(6.8)
	tw_hole.tween_callback(func(): black_hole.visible = true)
	tw_hole.tween_property(black_hole, "scale", Vector2(1.3, 1.1), 1.0)
	
	# 5. อาจารย์ shock1 (7.8s -> 9.0s)
	var tw_shock = create_tween()
	tw_shock.tween_interval(7.8)
	tw_shock.tween_callback(func(): master.play("shock1"))
	
	# 6. คัมภีร์กระเด็นหลุดมือแบบ Pixel Art (9.0s -> 9.68s)
	var tw_book = create_tween()
	tw_book.tween_interval(9.0)
	tw_book.tween_callback(func():
		khampri.visible = true
		khampri.position = Vector2(38, 50)
		var tw_arc = create_tween().set_parallel(true)
		tw_arc.tween_property(khampri, "position:x", 26.0, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_arc.tween_property(khampri, "position:y", 86.0, 0.48).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw_arc.tween_property(khampri, "rotation", 0.0, 0.48)
	)
	
	# อาจารย์ตกหลุมดำ (9.0s -> 9.4s)
	var tw_fall = create_tween()
	tw_fall.tween_interval(9.0)
	tw_fall.tween_property(master, "position:y", 53.0, 0.08)
	var tw_drop = create_tween()
	tw_drop.tween_interval(9.08)
	tw_drop.parallel().tween_property(master, "position:y", 97.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_drop.parallel().tween_property(master, "scale", Vector2(0.1, 0.1), 0.32)
	tw_drop.parallel().tween_property(master, "modulate:a", 0.0, 0.32)
	tw_drop.tween_callback(func():
		master.visible = false
		vel.play("shock")
		exclamation_mark.visible = true
		var tw_ex = create_tween()
		tw_ex.tween_property(exclamation_mark, "scale", Vector2(1.35, 1.35), 0.08)
		tw_ex.tween_property(exclamation_mark, "scale", Vector2(1.0, 1.0), 0.08)
		
		# หลุมดำแรกหดตัวปิด
		var tw_h1 = create_tween()
		tw_h1.tween_property(black_hole, "scale", Vector2.ZERO, 0.8)
		tw_h1.tween_callback(func(): black_hole.visible = false)
	)
	
	# 7. คัมภีร์แตกเป็น 20 ชิ้น (11.8s)
	var tw_shatter = create_tween()
	tw_shatter.tween_interval(11.8)
	tw_shatter.tween_callback(_on_shatter_khampri)
	
	# 8. รอแปปนึง แล้ววงเวทรอบสองค่อย ๆ ดูด (14.2s -> 18.2s)
	var tw_h2_in = create_tween()
	tw_h2_in.tween_interval(14.2)
	tw_h2_in.tween_callback(func():
		black_hole.position = Vector2(32, 90)
		black_hole.visible = true
		var tw_h2 = create_tween()
		tw_h2.tween_property(black_hole, "scale", Vector2(1.6, 1.35), 1.0)
	)
	var tw_suck = create_tween()
	tw_suck.tween_interval(15.2)
	tw_suck.tween_callback(_on_suck_shards)
	
	var tw_h2_out = create_tween()
	tw_h2_out.tween_interval(17.6)
	tw_h2_out.tween_property(black_hole, "scale", Vector2.ZERO, 0.6)
	tw_h2_out.tween_callback(func(): black_hole.visible = false)
	
	# 9. เวลเดินไปดูกระดาษที่เหลือตรงกลาง (18.5s -> 20.6s)
	var tw_walk_paper = create_tween()
	tw_walk_paper.tween_interval(18.5)
	tw_walk_paper.tween_callback(func():
		exclamation_mark.visible = false
		vel.play("walk_right")
	)
	tw_walk_paper.tween_property(vel, "position", Vector2(12, 80), 2.1)
	tw_walk_paper.tween_callback(func():
		vel.play("breathe_blink")
	)
	
	# 10. เวลหยิบกระดาษลอยขึ้น (20.8s)
	var tw_pickup = create_tween()
	tw_pickup.tween_interval(20.8)
	tw_pickup.tween_callback(_on_pickup_shard)
	
	# 11. ตัวอักษรเวทมนตร์เด้งขึ้นมาพร้อมพื้นหลังกระดาษจาง ๆ (21.6s)
	var tw_ui = create_tween()
	tw_ui.tween_interval(21.6)
	tw_ui.tween_callback(func():
		var tw_t = create_tween().set_parallel(true)
		tw_t.tween_property(backdrop, "color", Color(0, 0, 0, 0.45), 0.5)
		tw_t.tween_property(parchment_frame, "modulate", Color(1, 1, 1, 0.58), 0.5)
		
		rune_container.scale = Vector2(0.2, 0.2)
		rune_container.modulate = Color(1, 1, 1, 0)
		var tw_pop = create_tween().set_parallel(true)
		tw_pop.tween_property(rune_container, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_pop.tween_property(rune_container, "modulate", Color(1, 1, 1, 1), 0.4)
		_on_reveal_magic_text()
	)
