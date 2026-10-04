extends Sprite2D

## การควบคุม Cutscene เปิดเรื่อง (Intro Cutscene)
## ลำดับเหตุการณ์:
## 1. ปรมาจารย์ & เวล เดินเข้ามายังกลางห้อง (จังหวะ 400ms / 200ms)
## 2. ฉากสั่น + แสงมืดลง + หลุมดำเปิดใต้เท้าอาจารย์
## 3. อาจารย์รู้ตัว ทำหน้า shock1 ยืนตกใจดีเลย์ 1.2 วินาที
## 4. อาจารย์สะดุ้งกระโดด คัมภีร์ (khampri) หลุดลอยขึ้นฟ้า
## 5. อาจารย์ถูกดูดจมหายเข้าไปในใจกลางหลุมดำ -> เวลช็อก + หลุมดำปิดชั่วคราว
## 6. คัมภีร์หมุนควงตกลงมากระแทกพื้นอย่างแรง ดึงดูดสายตาทันที
## 7. คัมภีร์สั่น มีแสงลอดออกจากรอยแตก แล้วระเบิดแตกกระจายออกเป็น 20 เศษคัมภีร์ (minikhampri)
## 8. หลุมดำกลับมาเปิดอย่างรุนแรง ดูดเศษคัมภีร์ 19 ชิ้นหายไปในหลุมดำ เหลือไว้เพียง 1 หน้าบนพื้น (ชิ้นที่ 20)
## 9. เวลได้สติ เดินเข้าไปหยิบเศษคัมภีร์ขึ้นมา
## 10. ตัวอักษรเวทมนตร์ค่อย ๆ ปรากฏขึ้นกลางจอ:
##     "หากคัมภีร์แตกสลาย
##     จงตามหาเศษแห่งต้นกำเนิด
##     ณ หอคอย..."

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
@onready var magic_ui: CanvasLayer = $MagicStoryUI
@onready var backdrop: ColorRect = $MagicStoryUI/Backdrop
@onready var rune_label: Label = $MagicStoryUI/RuneLabel

var shards: Array[Sprite2D] = []

# พิกัดปลายทางที่เศษทั้ง 20 ชิ้นจะกระจายตกบนพื้นห้อง (อิง Local Position ของ Libary)
const SHARD_LANDING_POSITIONS: Array[Vector2] = [
	Vector2(-60.0, 82.0),  # Shard 1
	Vector2(-45.0, 76.0),  # Shard 2
	Vector2(-30.0, 72.0),  # Shard 3
	Vector2(-12.0, 68.0),  # Shard 4
	Vector2(8.0, 69.0),    # Shard 5
	Vector2(28.0, 72.0),   # Shard 6
	Vector2(48.0, 77.0),   # Shard 7
	Vector2(65.0, 83.0),   # Shard 8
	Vector2(55.0, 92.0),   # Shard 9
	Vector2(38.0, 98.0),   # Shard 10
	Vector2(18.0, 100.0),  # Shard 11
	Vector2(-5.0, 99.0),   # Shard 12
	Vector2(-25.0, 96.0),  # Shard 13
	Vector2(-42.0, 92.0),  # Shard 14
	Vector2(-58.0, 87.0),  # Shard 15
	Vector2(-20.0, 82.0),  # Shard 16
	Vector2(0.0, 80.0),    # Shard 17
	Vector2(20.0, 83.0),   # Shard 18
	Vector2(40.0, 88.0),   # Shard 19
	Vector2(-18.0, 86.0),  # Shard 20: ชิ้นที่จะเหลืออยู่ใกล้ตัวเวล
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

func _init_shards() -> void:
	shards.clear()
	if shards_container:
		for child in shards_container.get_children():
			if child is Sprite2D:
				shards.append(child)

func _reset_cutscene_state() -> void:
	if khampri:
		khampri.visible = false
		khampri.position = Vector2(40, 48)
		khampri.rotation = 0.0
		khampri.scale = Vector2(0.25, 0.25)
		khampri.modulate = Color(1, 1, 1, 1)
	
	for s in shards:
		s.visible = false
		s.scale = Vector2(0.25, 0.25)
		s.modulate = Color(1, 1, 1, 1)
		s.rotation = 0.0
	
	if backdrop:
		backdrop.color = Color(0, 0, 0, 0)
	if rune_label:
		rune_label.modulate = Color(1, 1, 1, 0)
		rune_label.visible_ratio = 0.0

## เรียกจาก AnimationPlayer เมื่อคัมภีร์แตกสลาย (11.4s)
func _on_shatter_khampri() -> void:
	if not khampri:
		return
	khampri.visible = false
	var origin: Vector2 = khampri.position
	
	for i in range(shards.size()):
		var s: Sprite2D = shards[i]
		s.position = origin
		s.scale = Vector2(0.25, 0.25)
		s.modulate = Color(1.6, 1.5, 1.1, 1.0) # แสงเรืองทองตอนระเบิด
		s.visible = true
		s.rotation = 0.0
		
		var target: Vector2 = SHARD_LANDING_POSITIONS[i] if i < SHARD_LANDING_POSITIONS.size() else origin + Vector2(randf_range(-50, 50), randf_range(0, 30))
		var apex_y: float = min(origin.y, target.y) - randf_range(25.0, 48.0)
		var duration: float = randf_range(0.45, 0.65)
		
		var tw = create_tween().set_parallel(true)
		# กระจายพุ่งออกแนวแกน X
		tw.tween_property(s, "position:x", target.x, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# พุ่งขึ้นฟ้าแล้วตกลงมากระดอนพื้น
		var tw_y = create_tween()
		tw_y.tween_property(s, "position:y", apex_y, duration * 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_y.tween_property(s, "position:y", target.y, duration * 0.58).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		# การหมุนขณะลอย
		tw.tween_property(s, "rotation", randf_range(-4.0, 4.0), duration)
		# สีกลับสู่ประกายปกติ
		tw.tween_property(s, "modulate", Color(1, 1, 1, 1), duration)

## เรียกจาก AnimationPlayer เมื่อหลุมดำกลับมาดูดเศษคัมภีร์ (13.2s)
func _on_suck_shards() -> void:
	var vortex_center: Vector2 = black_hole.position
	
	# ดูดเฉพาะ 19 ชิ้นแรก (ดัชนี 0 ถึง 18)
	var num_to_suck = mini(19, shards.size())
	for i in range(num_to_suck):
		var s: Sprite2D = shards[i]
		var delay: float = randf_range(0.0, 0.8)
		var suck_duration: float = randf_range(0.42, 0.65)
		
		var tw = create_tween()
		tw.tween_interval(delay)
		tw.tween_callback(func():
			if not is_instance_valid(s):
				return
			var tw_suck = create_tween().set_parallel(true)
			tw_suck.tween_property(s, "position", vortex_center, suck_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tw_suck.tween_property(s, "scale", Vector2.ZERO, suck_duration)
			tw_suck.tween_property(s, "rotation", s.rotation + randf_range(5.0, 10.0), suck_duration)
			tw_suck.tween_property(s, "modulate:a", 0.0, suck_duration)
			tw_suck.chain().tween_callback(func(): s.visible = false)
		)
	
	# ชิ้นที่ 20 (ชิ้นสุดท้าย) เหลืออยู่บนพื้น เรืองแสงสีทองกระพริบ
	if shards.size() >= 20:
		var s20: Sprite2D = shards[19]
		var tw20 = create_tween().set_loops(5)
		tw20.tween_property(s20, "modulate", Color(1.8, 1.6, 0.8, 1.0), 0.35)
		tw20.tween_property(s20, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.35)

## เรียกจาก AnimationPlayer เมื่อเวลเดินมาถึงแล้วหยิบเศษคัมภีร์ (17.5s)
func _on_pickup_shard() -> void:
	if shards.size() < 20:
		return
	var s20: Sprite2D = shards[19]
	var hand_pos: Vector2 = vel.position + Vector2(10.0, -10.0)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(s20, "position", hand_pos, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(s20, "scale", Vector2(0.3, 0.3), 0.65)
	tw.tween_property(s20, "rotation", 0.0, 0.65)
	tw.tween_property(s20, "modulate", Color(2.0, 1.8, 1.1, 1.0), 0.65)

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
	
	# 1. ปรมาจารย์เดินเข้ามา (5.4s)
	var tw_master_walk = create_tween()
	tw_master_walk.tween_property(master, "position:x", master_target_x, 5.4)
	tw_master_walk.tween_callback(func():
		master.flip_h = false
		master.play("breathe_blink")
	)
	
	# 2. เวลเดินเข้ามา (1.8s -> 6.0s)
	var tw_vel_walk = create_tween()
	tw_vel_walk.tween_interval(1.8)
	tw_vel_walk.tween_callback(func():
		vel.visible = true
		vel.play("walk_right")
	)
	tw_vel_walk.tween_property(vel, "position:x", vel_target_x, 4.2)
	tw_vel_walk.tween_callback(func():
		vel.play("breathe_blink")
	)
	
	# 3. ฉากสั่น + แสงมืดลง
	var tw_env = create_tween()
	tw_env.tween_interval(6.3)
	tw_env.tween_property(room_lighting, "color", Color(0.62, 0.6, 0.73, 1.0), 1.2)
	
	# 4. หลุมดำเปิด (6.8s -> 7.8s)
	var tw_hole = create_tween()
	tw_hole.tween_interval(6.8)
	tw_hole.tween_callback(func(): black_hole.visible = true)
	tw_hole.tween_property(black_hole, "scale", Vector2(1.3, 1.1), 1.0)
	
	# 5. อาจารย์รู้ตัว shock1 (7.8s -> 9.0s)
	var tw_shock = create_tween()
	tw_shock.tween_interval(7.8)
	tw_shock.tween_callback(func(): master.play("shock1"))
	
	# 6. คัมภีร์เด้งหลุดมือ + อาจารย์ตกหลุมดำ (9.0s -> 9.4s)
	var tw_tome_launch = create_tween()
	tw_tome_launch.tween_interval(9.0)
	tw_tome_launch.tween_callback(func():
		khampri.visible = true
		khampri.position = Vector2(40, 48)
		var tw_arc = create_tween().set_parallel(true)
		tw_arc.tween_property(khampri, "position:x", 20.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_arc.tween_property(khampri, "position:y", -15.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_arc.tween_property(khampri, "rotation", -0.6, 0.4)
	)
	
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
	
	# 7. คัมภีร์หมุนควงลงมากระแทกพื้น (9.4s -> 10.3s)
	var tw_tome_fall = create_tween()
	tw_tome_fall.tween_interval(9.4)
	tw_tome_fall.tween_callback(func():
		var tw_f = create_tween().set_parallel(true)
		tw_f.tween_property(khampri, "position:x", 5.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_f.tween_property(khampri, "position:y", 88.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_f.tween_property(khampri, "rotation", TAU, 0.9)
		tw_f.chain().tween_callback(func():
			# เด้งกระดอนเล็กน้อย
			var tw_b = create_tween()
			tw_b.tween_property(khampri, "position:y", 80.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_b.tween_property(khampri, "position:y", 88.0, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		)
	)
	
	# 8. คัมภีร์สั่นและแตกออกเป็น 20 ชิ้น (11.4s)
	var tw_shatter = create_tween()
	tw_shatter.tween_interval(11.4)
	tw_shatter.tween_callback(_on_shatter_khampri)
	
	# 9. หลุมดำกลับมาดูดเศษ 19 ชิ้น (12.6s -> 15.2s)
	var tw_hole_return = create_tween()
	tw_hole_return.tween_interval(12.6)
	tw_hole_return.tween_callback(func():
		black_hole.position = Vector2(30, 92)
		black_hole.visible = true
		var tw_h2 = create_tween()
		tw_h2.tween_property(black_hole, "scale", Vector2(1.6, 1.35), 0.6)
	)
	var tw_suck = create_tween()
	tw_suck.tween_interval(13.2)
	tw_suck.tween_callback(_on_suck_shards)
	
	var tw_hole_close = create_tween()
	tw_hole_close.tween_interval(14.8)
	tw_hole_close.tween_property(black_hole, "scale", Vector2.ZERO, 0.5)
	tw_hole_close.tween_callback(func(): black_hole.visible = false)
	
	# 10. เวลเดินไปหยิบเศษคัมภีร์ชิ้นที่ 20 (16.0s -> 17.5s)
	var tw_vel_pickup = create_tween()
	tw_vel_pickup.tween_interval(15.5)
	tw_vel_pickup.tween_callback(func():
		exclamation_mark.visible = false
		vel.play("walk_right")
	)
	tw_vel_pickup.tween_property(vel, "position", Vector2(-22, 72), 1.2)
	tw_vel_pickup.tween_callback(func():
		vel.play("breathe_blink")
		_on_pickup_shard()
	)
	
	# 11. แสดงตัวอักษรเวทมนตร์ (18.5s)
	var tw_text = create_tween()
	tw_text.tween_interval(18.5)
	tw_text.tween_callback(func():
		var tw_t = create_tween().set_parallel(true)
		tw_t.tween_property(backdrop, "color", Color(0, 0, 0, 0.55), 1.0)
		tw_t.tween_property(rune_label, "modulate", Color(1, 1, 1, 1), 0.5)
		tw_t.tween_property(rune_label, "visible_ratio", 1.0, 3.0)
	)
