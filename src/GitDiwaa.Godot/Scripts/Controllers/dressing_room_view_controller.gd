class_name DressingRoomViewController
extends Control

## Controller สำหรับห้องแต่งตัว (Dressing Room / Wardrobe View)
## พัฒนาด้วย GDScript (ภาษา Godot)
## ฟังก์ชัน:
## - หมุนตัวละคร 360 องศา (ปุ่มคลิก + คีย์ลัด A/D หรือ ←/→)
## - น้องแมวมิวรา Interactive (คลิกแล้วกระโดดดึ๋ง + ส่งเสียงเหมียวเรโทร 16-bit ไม่ลอยค้างฟ้า)
## - ตู้เสื้อผ้าแบบ Empty State รองรับการดึงไอเทมหลังซื้อจากร้านค้า
## - แท็บหมวดหมู่ (ทั้งหมด, ฮู้ด, ผ้าพันคอ, กระเป๋า, แมว)
## - ทรานซิชัน Fade-in / Fade-out

const TAB_ACTIVE_BG := Color("6d28d9")
const TAB_ACTIVE_BORDER := Color("8b5cf6")
const TAB_INACTIVE_BG := Color("150f2e")
const TAB_INACTIVE_BORDER := Color("2e2355")
const TAB_ACTIVE_TEXT := Color(1.0, 1.0, 1.0, 1.0)
const TAB_INACTIVE_TEXT := Color(0.65, 0.60, 0.80, 1.0)

const FACING_PATHS: Array[String] = [
	"res://assets/cutscene/characters/vel/vel_Hblue_Sredyellow_idle.png",
	"res://assets/cutscene/characters/vel/vel_right.png",
	"res://assets/cutscene/characters/vel/vel_back.png",
	"res://assets/cutscene/characters/vel/vel_left.png"
]

@onready var back_btn: Button = %BackBtn
@onready var rotate_left_btn: Button = %RotateLeftBtn
@onready var rotate_right_btn: Button = %RotateRightBtn
@onready var char_texture: TextureRect = %CharacterSprite
@onready var cat_sprite: TextureRect = %CatCompanionSprite
@onready var sfx_click: AudioStreamPlayer = %SfxClick
@onready var sfx_meow: AudioStreamPlayer = %SfxMeow
@onready var fade_overlay: ColorRect = %FadeOverlay
@onready var counter_value: Label = %CounterValue
@onready var empty_state_container: Control = %EmptyStateContainer
@onready var items_grid: GridContainer = %ItemsGrid

@onready var tab_buttons: Array[Button] = [
	%TabAll,
	%TabHood,
	%TabScarf,
	%TabBag,
	%TabCat
]

var facing_textures: Array[Texture2D] = []
var facing_index: int = 0
var active_category: int = 0

var cat_initial_offset_top: float = 35.0
var is_cat_hopping: bool = false
var is_leaving: bool = false

var tab_active_style: StyleBoxFlat
var tab_inactive_style: StyleBoxFlat

func _ready() -> void:
	_load_textures()
	_init_tab_styles()
	_wire_events()
	_update_character_facing()
	_update_category_filter(0)
	
	cat_initial_offset_top = cat_sprite.offset_top
	cat_sprite.visible = true
	empty_state_container.visible = true
	items_grid.visible = false
	counter_value.text = "0 ชิ้น"
	
	_start_fade_in()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_A or event.keycode == KEY_LEFT:
			_on_rotate_left()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
			_on_rotate_right()
			get_viewport().set_input_as_handled()

func _load_textures() -> void:
	facing_textures.clear()
	for path in FACING_PATHS:
		var tex := load(path) as Texture2D
		if tex != null:
			facing_textures.append(tex)
		else:
			push_error("[DressingRoom] Failed to load texture: " + path)

func _init_tab_styles() -> void:
	tab_active_style = StyleBoxFlat.new()
	tab_active_style.bg_color = TAB_ACTIVE_BG
	tab_active_style.set_border_width_all(2)
	tab_active_style.border_color = TAB_ACTIVE_BORDER
	tab_active_style.set_corner_radius_all(14)
	tab_active_style.content_margin_left = 14
	tab_active_style.content_margin_right = 14
	tab_active_style.content_margin_top = 6
	tab_active_style.content_margin_bottom = 6
	
	tab_inactive_style = StyleBoxFlat.new()
	tab_inactive_style.bg_color = TAB_INACTIVE_BG
	tab_inactive_style.set_border_width_all(1)
	tab_inactive_style.border_color = TAB_INACTIVE_BORDER
	tab_inactive_style.set_corner_radius_all(14)
	tab_inactive_style.content_margin_left = 14
	tab_inactive_style.content_margin_right = 14
	tab_inactive_style.content_margin_top = 6
	tab_inactive_style.content_margin_bottom = 6

func _wire_events() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	rotate_left_btn.pressed.connect(_on_rotate_left)
	rotate_right_btn.pressed.connect(_on_rotate_right)
	
	for i in range(tab_buttons.size()):
		var idx := i
		tab_buttons[i].pressed.connect(func():
			_play_sfx(sfx_click)
			_update_category_filter(idx)
		)
	
	cat_sprite.gui_input.connect(_on_cat_gui_input)

func _start_fade_in() -> void:
	if fade_overlay == null:
		return
	fade_overlay.modulate = Color(1, 1, 1, 1)
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_cat_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_cat_clicked()

func _on_cat_clicked() -> void:
	if is_cat_hopping:
		return
	is_cat_hopping = true
	
	_play_sfx(sfx_meow)
	
	var initial_top := cat_initial_offset_top
	var initial_bottom := cat_initial_offset_top + 140.0
	
	var tween := create_tween()
	tween.tween_property(cat_sprite, "offset_top", initial_top - 14.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(cat_sprite, "offset_bottom", initial_bottom - 14.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(cat_sprite, "offset_top", initial_top, 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(cat_sprite, "offset_bottom", initial_bottom, 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func():
		cat_sprite.offset_top = initial_top
		cat_sprite.offset_bottom = initial_bottom
		is_cat_hopping = false
	)

func _on_rotate_left() -> void:
	_play_sfx(sfx_click)
	facing_index = (facing_index + 3) % 4
	_update_character_facing()

func _on_rotate_right() -> void:
	_play_sfx(sfx_click)
	facing_index = (facing_index + 1) % 4
	_update_character_facing()

func _update_character_facing() -> void:
	if facing_textures.size() > facing_index and facing_textures[facing_index] != null:
		char_texture.texture = facing_textures[facing_index]

func _update_category_filter(category_index: int) -> void:
	active_category = category_index
	for i in range(tab_buttons.size()):
		var is_active := (i == category_index)
		var btn := tab_buttons[i]
		btn.add_theme_stylebox_override("normal", tab_active_style if is_active else tab_inactive_style)
		btn.add_theme_stylebox_override("hover", tab_active_style if is_active else tab_inactive_style)
		btn.add_theme_stylebox_override("pressed", tab_active_style if is_active else tab_inactive_style)
		btn.add_theme_color_override("font_color", TAB_ACTIVE_TEXT if is_active else TAB_INACTIVE_TEXT)

func _on_back_pressed() -> void:
	if is_leaving:
		return
	is_leaving = true
	
	_play_sfx(sfx_click)
	if fade_overlay != null:
		var tween := create_tween()
		tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(func():
			get_tree().change_scene_to_file("res://Scenes/StartView.tscn")
		)
	else:
		get_tree().change_scene_to_file("res://Scenes/StartView.tscn")

func _play_sfx(player: AudioStreamPlayer) -> void:
	if player != null and player.stream != null:
		player.play()
