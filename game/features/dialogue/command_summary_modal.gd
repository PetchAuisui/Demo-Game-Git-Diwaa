class_name CommandSummaryModal
extends Control

## หน้าต่างสรุปคำสั่งและสาธิตการร่ายมนตร์ Git (Command Summary & Demonstration Modal)
## แสดงผลหลังจบบทสนทนาก่อนเข้าสู่เทอร์มินัลพิมพ์คำสั่งใน Sandbox
## อิงตามสไตล์ Learn Git Branching แต่ปรับแต่งให้เข้ากับธีมคัมภีร์เวทมนตร์ของเกม

const CommandDemonstrationCanvas = preload("res://features/dialogue/command_demonstration_canvas.gd")

signal proceed_to_terminal(step: int)
signal modal_closed

@export var level_number: int = 1
@export var current_step: int = 1

# โหนด UI ภายในหน้าต่าง
@onready var dim_overlay: ColorRect = $DimOverlay
@onready var modal_panel: PanelContainer = $CenterContainer/ModalPanel
@onready var title_label: Label = %TitleLabel
@onready var close_btn: Button = %CloseButton

# ฝั่งซ้าย: เนื้อหาคำอธิบายและการทดลองร่ายคาถา
@onready var step_badge: Label = %StepBadge
@onready var guide_rich_label: RichTextLabel = %GuideRichLabel
@onready var cast_command_btn: Button = %CastCommandButton
@onready var reset_anim_btn: Button = %ResetAnimationButton
@onready var outcome_panel: PanelContainer = %OutcomePanel
@onready var outcome_label: RichTextLabel = %OutcomeLabel

# ปุ่มนำทางด้านล่าง
@onready var nav_prev_btn: Button = %NavPrevButton
@onready var nav_next_btn: Button = %NavNextButton
@onready var page_indicator: Label = %PageIndicator
@onready var start_terminal_btn: Button = %StartTerminalButton

# ฝั่งขวา: ผ้าใบจำลองกราฟ Git
@onready var demo_canvas: CommandDemonstrationCanvas = %DemoCanvas

# ข้อมูลสไลด์การสาธิต
var slides: Array[Dictionary] = []
var current_slide_index: int = 0
var has_executed_current_slide: bool = false
var _is_closing: bool = false

# เสียงประกอบ
const SFX_CLICK_PATH := "res://assets/audio/sfx_click.wav"
const SFX_COMMAND_PATH := "res://assets/audio/sfx_command.wav"
const SFX_SUCCESS_PATH := "res://assets/audio/sfx_success.wav"


func _ready() -> void:
	_setup_slides()
	_wire_signals()
	_show_slide(0)
	_play_open_animation()


func _setup_slides() -> void:
	slides.clear()
	
	# โหลดสไลด์จากข้อมูลด่านถ้ามีนิยามไว้
	var custom_slides: Array = LevelDataLoader.get_demonstration_slides(level_number, current_step)
	if custom_slides.size() > 0:
		for s in custom_slides:
			if s is Dictionary:
				slides.append(s)
		return

	# สไลด์มาตรฐานอิงตาม Reference (Git Commit Demonstration)
	slides.append({
		"title": "⚙ การจำลองการจารึก: บันทึกคัมภีร์เวท (Git Demonstration)",
		"badge": "✦ บทเรียนการจารึก: Git Commit",
		"guide_text": "มาดูการทำงานจริงของพลังเวท Git ในคัมภีร์ส่วนตัวกันเถอะ\n\nทางด้านขวาคือภาพจำลองสายธารคัมภีร์เวท (Git Repository) ในขณะนี้มีจุดจารึกอยู่ 2 จุด นั่นคือจุดเริ่มต้นแรกสุด [b][color=#73BFF2]c0[/color][/b] และจุดจารึกถัดมา [b][color=#73BFF2]c1[/color][/b] ที่บันทึกการเปลี่ยนแปลงสำคัญไว้\n\nกดปุ่ม [b][color=#52e0ac]git commit[/color][/b] ด้านล่าง เพื่อร่ายคาถาและสร้างจุดจารึกใหม่!",
		"command": "git commit",
		"button_icon": "✨",
		"outcome_text": "[color=#52e0ac]ยอดเยี่ยมมาก![/color] เราเพิ่งจารึกการเปลี่ยนแปลงลงในคัมภีร์เวทและบันทึกเป็น Commit ใหม่ [b][color=#73BFF2]c2[/color][/b]\nสายธารเวทมนตร์ขยายตัว และกิ่งเวท [b][color=#52e0ac]main*[/color][/b] ได้เลื่อนมาปกป้องจุดจารึกล่าสุดเรียบร้อย!",
		"mode": CommandDemonstrationCanvas.DemoMode.COMMIT
	})
	
	# สไลด์ที่ 2: สรุปคาถาประจำด่านที่ 1 (git --version & git config)
	if level_number == 1:
		slides.append({
			"title": "🔮 สรุปคาถาประจำด่าน: ตรวจสอบพลังและประกาศนาม",
			"badge": "✦ คาถาที่ต้องร่ายในเทอร์มินัล",
			"guide_text": "ก่อนเข้าสู่สนามฝึกฝนจริง ตรวจสอบความถูกต้องของคาถาเหล่านี้:\n\n" +
				"1. [b][color=#73BFF2]git --version[/color][/b]\n" +
				"   • ใช้ตรวจสอบว่าพลัง Git ตื่นขึ้นมาแล้วหรือไม่ (ระวัง: หน้า version ต้องเป็นขีดคู่ [b]--[/b])\n\n" +
				"2. [b][color=#73BFF2]git config --global user.name \"Vel\"[/color][/b]\n" +
				"   • ประกาศนามของนักเวทให้สำนักเวทจดจำ\n\n" +
				"3. [b][color=#73BFF2]git config --global user.email \"vel@...\"[/color][/b]\n" +
				"   • ผูกตราประทับวิญญาณเชื่อมกับตัวตนของเจ้า",
			"command": "ร่ายคาถาตรวจสอบตราประทับ",
			"button_icon": "🔮",
			"outcome_text": "[color=#FFE680]ตราประทับวิญญาณพร้อมแล้ว![/color]\nเมื่อเข้าไปในเทอร์มินัล ให้พิมพ์คาถาเหล่านี้อย่างแม่นยำทีละขั้นตอนเพื่อปลดล็อกพลังของหอคอย",
			"mode": CommandDemonstrationCanvas.DemoMode.CONFIG
		})


func _wire_signals() -> void:
	close_btn.pressed.connect(_on_close_pressed)
	cast_command_btn.pressed.connect(_on_cast_command_pressed)
	reset_anim_btn.pressed.connect(_on_reset_animation_pressed)
	nav_prev_btn.pressed.connect(_on_prev_slide_pressed)
	nav_next_btn.pressed.connect(_on_next_slide_pressed)
	start_terminal_btn.pressed.connect(_on_start_terminal_pressed)
	
	if demo_canvas != null:
		demo_canvas.animation_finished.connect(_on_canvas_animation_finished)


func _show_slide(index: int) -> void:
	if index < 0 or index >= slides.size():
		return
	
	current_slide_index = index
	has_executed_current_slide = false
	var slide: Dictionary = slides[index]
	
	title_label.text = slide.get("title", "⚙ Git Demonstration")
	step_badge.text = slide.get("badge", "")
	guide_rich_label.text = slide.get("guide_text", "")
	
	var cmd: String = slide.get("command", "git commit")
	var icon: String = slide.get("button_icon", "✨")
	cast_command_btn.text = "%s %s" % [icon, cmd]
	cast_command_btn.disabled = false
	
	outcome_label.text = slide.get("outcome_text", "")
	outcome_panel.visible = false
	outcome_panel.modulate.a = 0.0
	
	# อัปเดตการแสดงผลปุ่มนำทาง
	page_indicator.text = "%d / %d" % [current_slide_index + 1, slides.size()]
	nav_prev_btn.disabled = (current_slide_index == 0)
	
	var is_last_slide: bool = (current_slide_index == slides.size() - 1)
	nav_next_btn.visible = not is_last_slide
	start_terminal_btn.visible = is_last_slide
	
	# อัปเดตโหมดของผ้าใบกราฟ
	var mode: CommandDemonstrationCanvas.DemoMode = slide.get("mode", CommandDemonstrationCanvas.DemoMode.COMMIT)
	demo_canvas.set_mode(mode)


func _on_cast_command_pressed() -> void:
	_play_sfx(SFX_COMMAND_PATH)
	cast_command_btn.disabled = true
	has_executed_current_slide = true
	
	var slide: Dictionary = slides[current_slide_index]
	var mode: CommandDemonstrationCanvas.DemoMode = slide.get("mode", CommandDemonstrationCanvas.DemoMode.COMMIT)
	
	if mode == CommandDemonstrationCanvas.DemoMode.COMMIT:
		demo_canvas.play_commit_animation()
	else:
		demo_canvas.play_config_animation()


func _on_canvas_animation_finished() -> void:
	_play_sfx(SFX_SUCCESS_PATH)
	
	# แสดงกล่องข้อความผลลัพธ์ด้วย Fade in Tween
	outcome_panel.visible = true
	var tw := create_tween()
	tw.tween_property(outcome_panel, "modulate:a", 1.0, 0.35)


func _on_reset_animation_pressed() -> void:
	_play_sfx(SFX_CLICK_PATH)
	cast_command_btn.disabled = false
	has_executed_current_slide = false
	outcome_panel.visible = false
	outcome_panel.modulate.a = 0.0
	demo_canvas.reset_animation()


func _on_prev_slide_pressed() -> void:
	if current_slide_index > 0:
		_play_sfx(SFX_CLICK_PATH)
		_show_slide(current_slide_index - 1)


func _on_next_slide_pressed() -> void:
	if current_slide_index < slides.size() - 1:
		_play_sfx(SFX_CLICK_PATH)
		_show_slide(current_slide_index + 1)


func _on_start_terminal_pressed() -> void:
	_play_sfx(SFX_CLICK_PATH)
	_close_and_proceed()


func _on_close_pressed() -> void:
	_play_sfx(SFX_CLICK_PATH)
	_close_and_proceed()


func _close_and_proceed() -> void:
	if _is_closing:
		return
	_is_closing = true
	
	var tw := create_tween().set_parallel(true)
	tw.tween_property(modal_panel, "scale", Vector2(0.9, 0.9), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(modal_panel, "modulate:a", 0.0, 0.2)
	tw.tween_property(dim_overlay, "modulate:a", 0.0, 0.25)
	
	tw.chain().tween_callback(func() -> void:
		proceed_to_terminal.emit(current_step)
		modal_closed.emit()
		queue_free()
	)


func _play_open_animation() -> void:
	dim_overlay.modulate.a = 0.0
	modal_panel.modulate.a = 0.0
	modal_panel.scale = Vector2(0.88, 0.88)
	modal_panel.pivot_offset = modal_panel.size * 0.5
	
	var tw := create_tween().set_parallel(true)
	tw.tween_property(dim_overlay, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tw.tween_property(modal_panel, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tw.tween_property(modal_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_sfx(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
