extends Control

## หน้าต่างสรุปผลเมื่อผ่านด่าน (Level Clear / Success Modal)
## แสดงโครงสร้างหน้าต่าง Success พร้อมผลดาว สรุปคะแนน คีย์เวิร์ดประจำด่าน
## และปุ่มควบคุม 3 ปุ่ม: "เล่นอีกครั้ง", "กลับไปหน้าเลือกด่าน", "ด่านต่อไป"

@onready var btn_replay: Button = $WindowPanel/VBoxMain/Margin/VBox/HBoxButtons/BtnReplay
@onready var btn_level_select: Button = $WindowPanel/VBoxMain/Margin/VBox/HBoxButtons/BtnLevelSelect
@onready var btn_next_level: Button = $WindowPanel/VBoxMain/Margin/VBox/HBoxButtons/BtnNextLevel

const STAR_GOLD := preload("res://assets/icons/star_gold.png")
const STAR_GOLD_SHEET := preload("res://assets/icons/star_gold_sheet.png")
const STAR_GRAY := preload("res://assets/icons/star_gray.png")

const FRAME_W := 320
const FRAME_H := 320
const COLS := 8
const TOTAL_FRAMES := 31
const FRAME_DURATION := 0.09 # ~11 fps matching original Animated Star GIF (100ms)

var _anim_gold_stars: Array[TextureRect] = []
var _anim_frame: int = 0
var _anim_time: float = 0.0

@export var level_number: int = 1
@export var level_command: String = "git version"
@export var level_keyword: String = "git --version เพื่อเช็กความพร้อมของ Git และ git config เพื่อตั้งชื่อกับอีเมลผู้สร้างงาน"
@export var replay_scene_path: String = "res://features/dialogue/level_dialogue_view.tscn"
@export var level_select_scene_path: String = "res://features/level_select/level_select_view.tscn"

@onready var level_title_label: Label = $WindowPanel/VBoxMain/Margin/VBox/LevelTitle
@onready var star1: TextureRect = $WindowPanel/VBoxMain/Margin/VBox/StarsHBox/Star1
@onready var star2: TextureRect = $WindowPanel/VBoxMain/Margin/VBox/StarsHBox/Star2
@onready var star3: TextureRect = $WindowPanel/VBoxMain/Margin/VBox/StarsHBox/Star3

func _process(delta: float) -> void:
	if _anim_gold_stars.is_empty():
		return
	_anim_time += delta
	if _anim_time >= FRAME_DURATION:
		_anim_time -= FRAME_DURATION
		_anim_frame = (_anim_frame + 1) % TOTAL_FRAMES
		var col := _anim_frame % COLS
		var row := _anim_frame / COLS
		var reg := Rect2(col * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H)
		for star in _anim_gold_stars:
			if star and star.texture is AtlasTexture:
				(star.texture as AtlasTexture).region = reg

@onready var score_current_label: Label = $WindowPanel/VBoxMain/Margin/VBox/ScorePanel/VBoxScore/Row1/Value
@onready var score_prev_label: Label = $WindowPanel/VBoxMain/Margin/VBox/ScorePanel/VBoxScore/Row2/Value
@onready var score_diff_label: Label = $WindowPanel/VBoxMain/Margin/VBox/ScorePanel/VBoxScore/Row3/Value
@onready var reward_label: Label = $WindowPanel/VBoxMain/Margin/VBox/ScorePanel/VBoxScore/Row4/Value

@onready var keyword_header_label: Label = $WindowPanel/VBoxMain/Margin/VBox/KeywordPanel/VBoxKW/Header
@onready var keyword_body_label: Control = $WindowPanel/VBoxMain/Margin/VBox/KeywordPanel/VBoxKW/Body

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
		keyword_header_label.text = "💡 สรุปสิ่งสำคัญประจำด่านที่ %d" % level_number
	if keyword_body_label:
		var formatted := _format_keyword_text(level_keyword)
		if keyword_body_label is RichTextLabel:
			keyword_body_label.text = "[center]%s[/center]" % formatted
		elif "text" in keyword_body_label:
			keyword_body_label.text = level_keyword

	var last_run := GameProgressManager.get_last_run_result()
	var current_score: int = int(last_run.get("score", 100))
	var earned_stars: int = int(last_run.get("stars", 2))
	if current_score >= 80 and earned_stars < 3:
		earned_stars = 3
		GameProgressManager.set_level_stars(level_number, 3)
	elif current_score >= 65 and earned_stars < 2:
		earned_stars = 2
		GameProgressManager.set_level_stars(level_number, 2)

	var prev_score: int = int(last_run.get("prev_score", 70))
	var score_diff: int = int(last_run.get("score_diff", 30))

	_anim_gold_stars.clear()
	var stars_list: Array[TextureRect] = [star1, star2, star3]
	for i in range(stars_list.size()):
		var star := stars_list[i]
		if not star:
			continue
		star.self_modulate = Color.WHITE
		if i < earned_stars:
			var atlas := AtlasTexture.new()
			atlas.atlas = STAR_GOLD_SHEET
			atlas.region = Rect2(0, 0, FRAME_W, FRAME_H)
			star.texture = atlas
			_anim_gold_stars.append(star)
		else:
			star.texture = STAR_GRAY

	_animate_stars_entrance(earned_stars)

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

## เล่นเฉพาะ Pop-in Bounce ตอนเปิดหน้าต่าง โดยไม่เอียงหรือบิดดาว เพื่อให้เห็น pixel art ของ GIF แท้ ๆ ชัดเจน
func _animate_stars_entrance(earned_stars: int) -> void:
	var stars: Array[TextureRect] = [star1, star2, star3]
	for i in range(stars.size()):
		var star := stars[i]
		if not star:
			continue
		star.pivot_offset = star.custom_minimum_size / 2.0
		star.scale = Vector2.ZERO
		star.rotation_degrees = 0.0

		var tw := create_tween()
		tw.tween_interval(0.10 + i * 0.15)
		tw.tween_property(star, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(star, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func _format_keyword_text(raw_text: String) -> String:
	if "git --version" in raw_text and "git config" in raw_text:
		return "[color=#241708]• [color=#8f3800][b]git --version[/b][/color] : เช็กความพร้อมของ Git\n• [color=#8f3800][b]git config[/b][/color] : ตั้งชื่อและอีเมลของผู้สร้างงาน[/color]"
	var text := raw_text
	for cmd in ["git --version", "git config", "git init", "git status", "git add", "git commit", "git push", "git pull", "git branch"]:
		if cmd in text:
			text = text.replace(cmd, "[color=#8f3800][b]%s[/b][/color]" % cmd)
	return "[color=#241708]%s[/color]" % text
