class_name TopBarPanel
extends PanelContainer
## Reusable Top Bar Component for Git-Diwaa Sandbox UI.
## Displays the game title, mode badge, and the exit button.

signal finish_pressed
signal brand_pressed

@export var game_title: String = "GIT DI WAA"
@export var mode_text: String = "SANDBOX"

var _brand_btn: BrandButton
var _mode_label: Label
var _divider: ColorRect
var _btn_finish: Button
var _timer_pill: PanelContainer
var _clock_icon: TextureRect
var _timer_label: Label


func _ready() -> void:
	_brand_btn = get_node_or_null("%BrandBtn") as BrandButton
	_mode_label = get_node_or_null("%ModeLabel")
	_divider = get_node_or_null("%Divider")
	_btn_finish = get_node_or_null("%BtnFinish")
	_timer_pill = get_node_or_null("%TimerPill") as PanelContainer
	_clock_icon = get_node_or_null("%ClockIcon") as TextureRect
	_timer_label = get_node_or_null("%TimerLabel") as Label

	set_mode_text(mode_text)

	if _brand_btn != null:
		_brand_btn.brand_title = game_title
		_brand_btn.pressed.connect(func(): brand_pressed.emit())

	if _btn_finish != null:
		_btn_finish.pressed.connect(func(): finish_pressed.emit())


func set_mode_text(new_mode_text: String) -> void:
	mode_text = new_mode_text
	var has_text := not new_mode_text.is_empty()
	if _mode_label != null:
		_mode_label.text = new_mode_text
		_mode_label.visible = has_text
	if _divider != null:
		_divider.visible = has_text


func set_finish_button_text(new_text: String) -> void:
	if _btn_finish != null:
		_btn_finish.text = new_text


func set_finish_button_visible(is_vis: bool) -> void:
	if _btn_finish != null:
		_btn_finish.visible = is_vis


func set_timer_visible(is_vis: bool) -> void:
	if _timer_pill != null:
		_timer_pill.visible = is_vis


func set_timer_seconds(seconds: float) -> void:
	if _timer_label == null:
		return
	var total_secs := maxi(0, int(ceil(seconds)))
	var mins := total_secs / 60
	var secs := total_secs % 60
	_timer_label.text = "%02d:%02d" % [mins, secs]
	if total_secs <= 10:
		_timer_label.add_theme_color_override("font_color", SandboxThemeTokens.ERROR_TEXT)
		if _clock_icon != null:
			_clock_icon.modulate = SandboxThemeTokens.ERROR_TEXT
	elif total_secs <= 30:
		_timer_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2, 1.0))
		if _clock_icon != null:
			_clock_icon.modulate = Color(1.0, 0.65, 0.2, 1.0)
	else:
		_timer_label.add_theme_color_override("font_color", SandboxThemeTokens.GOLD_TITLE)
		if _clock_icon != null:
			_clock_icon.modulate = SandboxThemeTokens.GOLD_TITLE
