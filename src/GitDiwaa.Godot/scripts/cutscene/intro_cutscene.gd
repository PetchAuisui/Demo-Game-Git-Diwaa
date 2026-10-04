extends Sprite2D

## การควบคุม Cutscene เดินเข้าห้องสมุด
## ปรมาจารย์เดินเข้ามาก่อน แล้วเวลเดินตามเข้ามาเว้นระยะห่างพอสมควร (เดินจากซ้ายไปขวา, ยืนที่ y = 59)

@export_enum("AnimationPlayer", "ScriptTween") var playback_mode: String = "AnimationPlayer"

@export_group("ตำแหน่งตัวละคร (Positions)")
@export var character_y: float = 59.0
@export var spawn_x: float = -280.0
@export var master_target_x: float = 40.0
@export var vel_target_x: float = -50.0

@export_group("ระยะเวลาและความเร็ว (Timing)")
@export var master_walk_duration: float = 3.2
@export var vel_start_delay: float = 1.2
@export var vel_walk_duration: float = 2.6

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var master: AnimatedSprite2D = $Master
@onready var vel: AnimatedSprite2D = $Vel

func _ready() -> void:
	if playback_mode == "AnimationPlayer":
		if not anim_player.is_playing() or anim_player.current_animation != "walk_in":
			anim_player.play("walk_in")
	else:
		if anim_player.is_playing():
			anim_player.stop()
		play_with_tween()

## เล่น Animation ผ่าน Tween (สำหรับผู้ที่ต้องการปรับแต่งหรือต่อยอดด้วย GDScript)
func play_with_tween() -> void:
	# จุดเริ่มต้น (อยู่นอกจอด้านซ้าย ที่ระดับ y = 59)
	master.position = Vector2(spawn_x, character_y)
	master.flip_h = true
	master.play("walk_left")
	
	vel.position = Vector2(spawn_x, character_y)
	vel.flip_h = false
	vel.visible = false
	
	# ปรมาจารย์เดินเข้ามาก่อน (ซ้ายไปขวา)
	var tween_master = create_tween()
	tween_master.tween_property(master, "position:x", master_target_x, master_walk_duration)
	tween_master.tween_callback(func():
		master.flip_h = false
		master.play("breathe_blink")
	)
	
	# เวลเดินตามเข้ามาเว้นระยะห่างพอสมควร
	var tween_vel = create_tween()
	tween_vel.tween_interval(vel_start_delay)
	tween_vel.tween_callback(func():
		vel.visible = true
		vel.play("walk_right")
	)
	tween_vel.tween_property(vel, "position:x", vel_target_x, vel_walk_duration)
	tween_vel.tween_callback(func():
		vel.play("breathe_blink")
	)
