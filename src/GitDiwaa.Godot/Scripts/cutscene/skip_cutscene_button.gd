extends CanvasLayer

## ปุ่มข้าม Cutscene (มุมขวาบน หรือกด Esc) — ข้ามทั้งชุด normal -> intro -> outside ไปยังด่านแรกทันที
## ใช้งาน: add_child(preload("res://scripts/cutscene/skip_cutscene_button.gd").new()) ใน _ready ของแต่ละ cutscene

@export var next_scene_path: String = "res://Scenes/SandboxGameView.tscn"

var _skipping: bool = false

func _ready() -> void:
	layer = 100
	
	var button := Button.new()
	button.text = "ข้าม ⏵⏵  (Esc)"
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.modulate = Color(1, 1, 1, 0.75)
	button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	button.offset_left = -170.0
	button.offset_right = -20.0
	button.offset_top = 16.0
	button.offset_bottom = 52.0
	button.pressed.connect(skip)
	add_child(button)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		skip()

func skip() -> void:
	if _skipping:
		return
	_skipping = true
	Engine.time_scale = 1.0
	if next_scene_path != "" and ResourceLoader.exists(next_scene_path):
		get_tree().change_scene_to_file(next_scene_path)
	else:
		push_warning("[SkipCutscene] next_scene_path not found: '%s'" % next_scene_path)
		_skipping = false
