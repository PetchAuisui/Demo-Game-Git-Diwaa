extends Control

## หน้าต่างจำลองการเล่น / พิมพ์คำสั่งภายในด่าน (Gameplay Placeholder View)
## รองรับการสลับขั้นตอน:
##   ขั้นที่ 1: ผ่านการสอนขั้น 1 -> กดปุ่ม "เสร็จสิ้น" -> กลับไปคุยบทเรียนที่ 2 (git config)
##   ขั้นที่ 2: ผ่านการสอนขั้น 2 -> กดปุ่ม "เสร็จสิ้น" -> กลับไปคุยบทสรุป (Outro)

signal step_finished(step: int)

const GameProgressManager = preload("res://common/game_progress_manager.gd")

@export var current_step: int = 1
@export var return_scene_path: String = "res://features/cutscene/inside_tower_cutscene.tscn"

@onready var mission_title_label: Label = $CenterContainer/MainPanel/Margin/VBox/MissionTitleLabel
@onready var btn_finish: Button = $CenterContainer/MainPanel/Margin/VBox/BtnFinish

func _ready() -> void:
	_update_ui_for_step(current_step)
	btn_finish.pressed.connect(_on_finish_pressed)
	btn_finish.grab_focus()

func _update_ui_for_step(step: int) -> void:
	if mission_title_label == null:
		mission_title_label = get_node_or_null("CenterContainer/MainPanel/Margin/VBox/MissionTitleLabel")
	if btn_finish == null:
		btn_finish = get_node_or_null("CenterContainer/MainPanel/Margin/VBox/BtnFinish")
		
	if not mission_title_label:
		return
		
	if step == 1:
		mission_title_label.text = "ผ่านการสอนขั้น 1"
	else:
		mission_title_label.text = "ผ่านการสอนขั้น 2"
		
	if btn_finish:
		btn_finish.text = "เสร็จสิ้น"

func _on_finish_pressed() -> void:
	btn_finish.disabled = true
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func() -> void:
		step_finished.emit(current_step)
		
		# หากเปิดรันแบบ Scene เดี่ยวแยกอิสระ (Standalone F6 Debug)
		if get_parent() == get_tree().root:
			GameProgressManager.set_pending_dialogue_phase(1 if current_step == 1 else 2)
			var target = return_scene_path
			if target == "" or not ResourceLoader.exists(target):
				target = "res://features/cutscene/inside_tower_cutscene.tscn"
			get_tree().change_scene_to_file(target)
		else:
			# หากถูกเรียกเป็น Modal / Sub-view ภายในฉาก
			queue_free()
	)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if btn_finish and not btn_finish.disabled:
				get_viewport().set_input_as_handled()
				_on_finish_pressed()
