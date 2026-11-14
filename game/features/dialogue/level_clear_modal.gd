extends Control

## หน้าต่างสรุปผลเมื่อผ่านด่าน (Level Clear / Success Modal)
## แสดงโครงสร้างหน้าต่าง Success พร้อมผลดาว สรุปคะแนน คีย์เวิร์ดประจำด่าน
## และปุ่มควบคุม 3 ปุ่ม: "เล่นอีกครั้ง", "กลับไปหน้าเลือกด่าน", "ด่านต่อไป"

@onready var btn_replay: Button = $WindowPanel/VBoxMain/Margin/VBox/HBoxButtons/BtnReplay
@onready var btn_level_select: Button = $WindowPanel/VBoxMain/Margin/VBox/HBoxButtons/BtnLevelSelect
@onready var btn_next_level: Button = $WindowPanel/VBoxMain/Margin/VBox/HBoxButtons/BtnNextLevel

const STAR_GOLD := preload("res://assets/icons/star_gold.png")
const STAR_GRAY := preload("res://assets/icons/star_gray.png")

@export var level_number: int = 1
@export var level_command: String = "git version"
@export var level_keyword: String = "การตรวจสอบพลัง หมายถึง git --version"
@export var replay_scene_path: String = "res://features/dialogue/level_dialogue_view.tscn"
@export var level_select_scene_path: String = "res://features/level_select/level_select_view.tscn"

@onready var level_title_label: Label = $WindowPanel/VBoxMain/Margin/VBox/LevelTitle
@onready var star1: TextureRect = $WindowPanel/VBoxMain/Margin/VBox/StarsHBox/Star1
@onready var star2: TextureRect = $WindowPanel/VBoxMain/Margin/VBox/StarsHBox/Star2
@onready var star3: TextureRect = $WindowPanel/VBoxMain/Margin/VBox/StarsHBox/Star3

@onready var score_current_label: Label = $WindowPanel/VBoxMain/Margin/VBox/ScorePanel/VBoxScore/Row1/Value
@onready var score_prev_label: Label = $WindowPanel/VBoxMain/Margin/VBox/ScorePanel/VBoxScore/Row2/Value
@onready var score_diff_label: Label = $WindowPanel/VBoxMain/Margin/VBox/ScorePanel/VBoxScore/Row3/Value
@onready var reward_label: Label = $WindowPanel/VBoxMain/Margin/VBox/ScorePanel/VBoxScore/Row4/Value

@onready var keyword_header_label: Label = $WindowPanel/VBoxMain/Margin/VBox/KeywordPanel/VBoxKW/Header
@onready var keyword_body_label: Label = $WindowPanel/VBoxMain/Margin/VBox/KeywordPanel/VBoxKW/Body

func _ready() -> void:
	_apply_level_info()
	if btn_replay:
		btn_replay.focus_mode = Control.FOCUS_NONE
		btn_replay.pressed.connect(_on_replay_pressed)
	if btn_level_select:
		btn_level_select.focus_mode = Control.FOCUS_NONE
		btn_level_select.pressed.connect(_on_level_select_pressed)
	if btn_next_level:
		btn_next_level.focus_mode = Control.FOCUS_NONE
		btn_next_level.pressed.connect(_on_next_level_pressed)

## ดึงข้อมูลด่านที่เพิ่งเล่นจบ (ด่านที่เลือกไว้) มาแสดงชื่อคำสั่งและคีย์เวิร์ดประจำด่าน
func _apply_level_info() -> void:
	level_number = GameProgressManager.get_selected_level_number()
	var data := LevelDataLoader.load_data(level_number)
	if not data.is_empty():
		level_command = LevelDataLoader.get_display_command(level_number, data)
		level_keyword = str(data.get("clear_keyword", level_keyword))
	if level_title_label:
		level_title_label.text = "ด่านที่ %d : %s" % [level_number, level_command]
	if keyword_header_label:
		keyword_header_label.text = "[คีย์เวิร์ดประจำด่านที่ %d]" % level_number
	if keyword_body_label:
		keyword_body_label.text = level_keyword

	var last_run := GameProgressManager.get_last_run_result()
	var earned_stars: int = int(last_run.get("stars", 2))
	var current_score: int = int(last_run.get("score", 100))
	var prev_score: int = int(last_run.get("prev_score", 70))
	var score_diff: int = int(last_run.get("score_diff", 30))

	if star1:
		star1.texture = STAR_GOLD if earned_stars >= 1 else STAR_GRAY
		star1.self_modulate = Color.WHITE
	if star2:
		star2.texture = STAR_GOLD if earned_stars >= 2 else STAR_GRAY
		star2.self_modulate = Color.WHITE
	if star3:
		star3.texture = STAR_GOLD if earned_stars >= 3 else STAR_GRAY
		star3.self_modulate = Color.WHITE

	if score_current_label:
		score_current_label.text = str(current_score)
	if score_prev_label:
		score_prev_label.text = str(prev_score)
	if score_diff_label:
		score_diff_label.text = "+%d" % score_diff
	if reward_label:
		reward_label.text = "%d COINS" % (earned_stars * 5)

func _on_replay_pressed() -> void:
	var target = replay_scene_path
	if target == "" or not ResourceLoader.exists(target):
		target = "res://features/dialogue/level_dialogue_view.tscn"
	get_tree().change_scene_to_file(target)

func _on_level_select_pressed() -> void:
	var target = level_select_scene_path
	if target == "" or not ResourceLoader.exists(target):
		target = "res://features/level_select/level_select_view.tscn"
	get_tree().change_scene_to_file(target)

func _on_next_level_pressed() -> void:
	# ปัจจุบันด่านถัดไปยังเป็นโครง จึงเปิดหน้าเลือกด่าน
	_on_level_select_pressed()

func _input(event: InputEvent) -> void:
	# ปิดการใช้งานปุ่ม Spacebar และ Enter บนหน้าดาว เพื่อให้ผู้เล่นใช้การคลิกเมาส์เท่านั้นตามคำขอ
	if event is InputEventKey:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
			get_viewport().set_input_as_handled()
			_on_level_select_pressed()
