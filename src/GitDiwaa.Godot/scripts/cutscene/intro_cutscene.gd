extends Sprite2D

## การควบคุม Cutscene เปิดเรื่อง (Intro Cutscene)
## ลำดับเหตุการณ์:
## 1. ปรมาจารย์เดินเข้ามาก่อน ก้าวขาจังหวะ 400ms/200ms จนถึงกลางห้องขวา (x = 40, y = 59 ที่ 5.4s)
## 2. เวลเดินตามเข้ามา ก้าวขาจังหวะ 400ms/200ms จนถึงกลางห้องซ้าย (x = -40, y = 59 ที่ 6.0s)
## 3. ฉากสั่นเบา ๆ + แสงในห้องมืดลงเล็กน้อย (6.3s)
## 4. หลุมดำเปิดเต็มที่ใต้เท้าอาจารย์ (6.8s -> 7.8s)
## 5. อาจารย์รู้ตัว หน้า shock1 ยืนตกใจมองหลุมดำดีเลย์ประมาณ 1.2 วินาที (7.8s -> 9.0s)
## 6. อาจารย์กระโดดสะดุ้งแล้วร่วงผลุบจมหายเข้าไปในใจกลางหลุมดำตรง ๆ (9.0s -> 9.4s)
## 7. เวลสะดุ้งเป็นหน้า Shock พร้อมเครื่องหมายตกใจ (!) เด้งป๊อปขึ้นบนหัว (9.4s)
## 8. หลุมดำหดเล็กลงแล้วปิดตัวลง (10.2s -> 11.2s)
## 9. เครื่องหมาย ! หายไป และเวลเปลี่ยนเป็นท่ายืนหายใจกระพริบตา (11.4s)

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

func _ready() -> void:
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

## เล่น Animation ผ่าน Tween ใน GDScript (หากต้องการทดสอบหรือต่อยอดด้วยโค้ด)
func play_with_tween() -> void:
	# รีเซ็ตสถานะเริ่มต้น
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
	
	# 1. ปรมาจารย์เดินเข้ามา (3 รอบ = 5.4s)
	var tw_master_walk = create_tween()
	tw_master_walk.tween_property(master, "position:x", master_target_x, 5.4)
	tw_master_walk.tween_callback(func():
		master.flip_h = false
		master.play("breathe_blink")
	)
	
	# 2. เวลเดินตามเข้ามา (เริ่มที่ 1.8s เดิน 4.2s ถึงที่ 6.0s)
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
	
	# 4. หลุมดำเปิดเต็มที่ (6.8s -> 7.8s)
	var tw_hole = create_tween()
	tw_hole.tween_interval(6.8)
	tw_hole.tween_callback(func(): black_hole.visible = true)
	tw_hole.tween_property(black_hole, "scale", Vector2(1.3, 1.1), 1.0)
	
	# 5. อาจารย์รู้ตัว ยืนดีเลย์มองหลุมดำด้วยหน้า shock1 (7.8s -> 9.0s)
	var tw_shock = create_tween()
	tw_shock.tween_interval(7.8)
	tw_shock.tween_callback(func():
		master.play("shock1")
	)
	
	# 6. อาจารย์กระโดดแล้วผลุบจมหายเข้าไปในใจกลางหลุมดำ (9.0s -> 9.4s)
	var tw_fall = create_tween()
	tw_fall.tween_interval(9.0)
	tw_fall.tween_property(master, "position:y", 53.0, 0.08) # hop
	var tw_drop = create_tween()
	tw_drop.tween_interval(9.08)
	tw_drop.parallel().tween_property(master, "position:y", 97.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_drop.parallel().tween_property(master, "scale", Vector2(0.1, 0.1), 0.32)
	tw_drop.parallel().tween_property(master, "modulate:a", 0.0, 0.32)
	tw_drop.tween_callback(func():
		master.visible = false
		# เวลช็อก + เครื่องหมาย ! ป๊อปขึ้นบนหัว
		vel.play("shock")
		exclamation_mark.visible = true
		var tw_ex = create_tween()
		tw_ex.tween_property(exclamation_mark, "scale", Vector2(1.35, 1.35), 0.08)
		tw_ex.tween_property(exclamation_mark, "scale", Vector2(1.0, 1.0), 0.08)
	)
	
	# 7. หลุมดำหดและปิด (10.2s -> 11.2s)
	var tw_close = create_tween()
	tw_close.tween_interval(10.2)
	tw_close.tween_property(black_hole, "scale", Vector2.ZERO, 1.0)
	tw_close.tween_callback(func():
		black_hole.visible = false
	)
	
	# 8. หลุมดำปิดเสร็จสิ้น -> เวลหายตกใจ คืนสู่ท่ายืนหายใจกระพริบตา (11.4s)
	var tw_recover = create_tween()
	tw_recover.tween_interval(11.2)
	tw_recover.tween_property(exclamation_mark, "scale", Vector2.ZERO, 0.2)
	tw_recover.tween_callback(func():
		exclamation_mark.visible = false
		vel.play("breathe_blink")
	)
