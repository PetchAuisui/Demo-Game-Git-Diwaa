extends Control

## หน้าต่างจำลองการเล่น / พิมพ์คำสั่งภายในด่าน (Gameplay Placeholder View)
## ใช้เป็นตัวแทนหน้าพิมพ์คำสั่งจริงระหว่างรอพัฒนาระบบเทอร์มินัล/เกมเพลย์หลัก
## รองรับการสลับขั้นตอน:
##   ขั้นที่ 1: git --version -> กดเสร็จสิ้น -> กลับไปคุยบทเรียนที่ 2 (git config)
##   ขั้นที่ 2: git config    -> กดเสร็จสิ้น -> กลับไปคุยบทสรุป (Outro)

static var current_step: int = 1
static var return_scene_path: String = "res://features/cutscene/inside_tower_cutscene.tscn"

@onready var mission_title_label: Label = $CenterContainer/MainPanel/Margin/VBox/MissionTitleLabel
@onready var mission_desc_label: RichTextLabel = $CenterContainer/MainPanel/Margin/VBox/MissionDescLabel
@onready var terminal_content: RichTextLabel = $CenterContainer/MainPanel/Margin/VBox/TerminalPanel/TerminalMargin/TerminalContent
@onready var btn_finish: Button = $CenterContainer/MainPanel/Margin/VBox/BtnFinish

func _ready() -> void:
	_update_ui_for_step(current_step)
	btn_finish.pressed.connect(_on_finish_pressed)
	btn_finish.grab_focus()

func _update_ui_for_step(step: int) -> void:
	if mission_title_label == null:
		mission_title_label = get_node_or_null("CenterContainer/MainPanel/Margin/VBox/MissionTitleLabel")
	if mission_desc_label == null:
		mission_desc_label = get_node_or_null("CenterContainer/MainPanel/Margin/VBox/MissionDescLabel")
	if terminal_content == null:
		terminal_content = get_node_or_null("CenterContainer/MainPanel/Margin/VBox/TerminalPanel/TerminalMargin/TerminalContent")
	if btn_finish == null:
		btn_finish = get_node_or_null("CenterContainer/MainPanel/Margin/VBox/BtnFinish")
		
	if not mission_title_label:
		return
		
	if step == 1:
		mission_title_label.text = "ภารกิจขั้นที่ 1: ตรวจสอบระดับพลังเวท"
		mission_desc_label.text = "ร่ายคาถา [color=#70d6ff]git[/color] [color=#5fffe0]--version[/color] เพื่อตรวจสอบความพร้อมของพลัง Git ในตัวท่าน"
		terminal_content.text = "[color=#8b949e]$[/color] [color=#70d6ff]git[/color] [color=#5fffe0]--version[/color]\n[color=#5fffe0]git version 2.43.0.magic (พลังเวท Git ตอบสนอง พร้อมใช้งาน!)[/color]\n\n[color=#ffd166]✓ การตรวจสอบพลังเวทเสร็จสมบูรณ์ พร้อมไปต่อขั้นตอนถัดไป[/color]"
		btn_finish.text = "เสร็จสิ้นขั้นที่ 1 (กลับไปรายงานมิวรา)"
	else:
		mission_title_label.text = "ภารกิจขั้นที่ 2: ประกาศนามและผูกตราประทับวิญญาณ"
		mission_desc_label.text = "ร่ายคาถา [color=#70d6ff]git[/color] [color=#70d6ff]config[/color] [color=#5fffe0]--global[/color] เพื่อลงทะเบียนชื่อและอีเมลกับสำนักเวท"
		terminal_content.text = "[color=#8b949e]$[/color] [color=#70d6ff]git[/color] [color=#70d6ff]config[/color] [color=#5fffe0]--global[/color] [color=#f8fafc]user.name[/color] [color=#ffd166]\"Vel\"[/color]\n[color=#8b949e]$[/color] [color=#70d6ff]git[/color] [color=#70d6ff]config[/color] [color=#5fffe0]--global[/color] [color=#f8fafc]user.email[/color] [color=#ffd166]\"vel@magic-tower.local\"[/color]\n\n[color=#ffd166]✓ จารึกตัวตนของ \"Vel\" สำเร็จ สำนักเวทจดจำท่านแล้ว[/color]"
		btn_finish.text = "เสร็จสิ้นขั้นที่ 2 (กลับไปสรุปผลกับมิวรา)"

func _on_finish_pressed() -> void:
	btn_finish.disabled = true
	var dialogue_script = load("res://features/dialogue/level_dialogue_view.gd")
	if dialogue_script:
		if current_step == 1:
			dialogue_script.start_phase = 1
		else:
			dialogue_script.start_phase = 2
		
	var target = return_scene_path
	if target == "" or not ResourceLoader.exists(target):
		target = "res://features/cutscene/inside_tower_cutscene.tscn"
	get_tree().change_scene_to_file(target)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if not btn_finish.disabled:
				get_viewport().set_input_as_handled()
				_on_finish_pressed()
