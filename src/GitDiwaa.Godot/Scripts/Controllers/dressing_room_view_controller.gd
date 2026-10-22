class_name DressingRoomViewController
extends Control
## Controller for the Dressing Room / Wardrobe View.
## Currently left empty/open awaiting purchased items from the Shop.
## Supports:
## - 360-degree character rotation (Buttons & A/D, Left/Right arrow keys)
## - Interactive Cat companion with cute hop bounce & meow SFX
## - Smooth fade-in & fade-out screen transitions
## - Category tabs and clean empty state

# Color & Theme Tokens for Dressing Room
const TAB_ACTIVE_BG := Color(0.427, 0.157, 0.851, 1.0) # #6D28D9
const TAB_ACTIVE_BORDER := Color(0.545, 0.361, 0.965, 1.0) # #8B5CF6
const TAB_INACTIVE_BG := Color(0.082, 0.059, 0.180, 0.9) # #150F2E
const TAB_INACTIVE_BORDER := Color(0.180, 0.137, 0.333, 1.0) # #2E2355
const TAB_ACTIVE_TEXT := Color(1.0, 1.0, 1.0, 1.0)
const TAB_INACTIVE_TEXT := Color(0.65, 0.60, 0.80, 1.0)

var _back_btn: Button
var _rotate_left_btn: Button
var _rotate_right_btn: Button
var _char_texture: TextureRect
var _cat_sprite: TextureRect
var _sfx_click: AudioStreamPlayer
var _sfx_meow: AudioStreamPlayer
var _fade_overlay: ColorRect
var _counter_value: Label
var _empty_state_container: Control
var _items_grid: GridContainer

# Category Tabs: 0 = All, 1 = Hood, 2 = Scarf, 3 = Bag, 4 = Cat
var _tab_buttons: Array[Button] = []

# Facing textures: 0 = Front, 1 = Right, 2 = Back, 3 = Left
var _facing_textures: Array[Texture2D] = []
var _facing_index := 0

# Active Category Filter: 0 = All, 1 = Hood, 2 = Scarf, 3 = Bag, 4 = Cat
# TODO: Connect with Shop / Inventory purchased items filter once the Shop system is integrated.
var _active_category := 0

# Animation & Transition Guards
var _cat_initial_y := 0.0
var _is_cat_hopping := false
var _is_leaving := false

# Tab Styles
var _tab_active_style: StyleBoxFlat
var _tab_inactive_style: StyleBoxFlat


func _ready() -> void:
	_bind_nodes()
	_load_textures()
	_init_tab_styles()
	_wire_events()
	_update_character_facing()
	_update_category_filter(0)

	# Store ground reference position for cat hop animation
	_cat_initial_y = _cat_sprite.position.y

	# Awaiting items from shop - keep companion cat standing nicely beside Vel
	_cat_sprite.visible = true
	_empty_state_container.visible = true
	_items_grid.visible = false
	_counter_value.text = "0 ชิ้น"

	_start_fade_in()


func _bind_nodes() -> void:
	_back_btn = get_node("%BackBtn")
	_rotate_left_btn = get_node("%RotateLeftBtn")
	_rotate_right_btn = get_node("%RotateRightBtn")
	_char_texture = get_node("%CharacterSprite")
	_cat_sprite = get_node("%CatCompanionSprite")
	_sfx_click = get_node("%SfxClick")
	_sfx_meow = get_node("%SfxMeow")
	_fade_overlay = get_node("%FadeOverlay")
	_counter_value = get_node("%CounterValue")
	_empty_state_container = get_node("%EmptyStateContainer")
	_items_grid = get_node("%ItemsGrid")

	_tab_buttons = [
		get_node("%TabAll") as Button,
		get_node("%TabHood") as Button,
		get_node("%TabScarf") as Button,
		get_node("%TabBag") as Button,
		get_node("%TabCat") as Button,
	]


func _load_textures() -> void:
	var paths: Array[String] = [
		"res://assets/cutscene/characters/vel/vel_Hblue_Sredyellow_idle.png",
		"res://assets/cutscene/characters/vel/vel_right.png",
		"res://assets/cutscene/characters/vel/vel_back.png",
		"res://assets/cutscene/characters/vel/vel_left.png",
	]

	for path in paths:
		var texture := load(path) as Texture2D
		if texture == null:
			push_error("[DressingRoom] Failed to load character texture from '%s'" % path)
		_facing_textures.append(texture)


func _init_tab_styles() -> void:
	_tab_active_style = _tab_style(TAB_ACTIVE_BG, TAB_ACTIVE_BORDER, 2)
	_tab_inactive_style = _tab_style(TAB_INACTIVE_BG, TAB_INACTIVE_BORDER, 1)


static func _tab_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_border_width_all(border_width)
	style.border_color = border
	style.set_corner_radius_all(14)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _wire_events() -> void:
	_back_btn.pressed.connect(_on_back_pressed)
	_rotate_left_btn.pressed.connect(_on_rotate_left)
	_rotate_right_btn.pressed.connect(_on_rotate_right)

	for i in _tab_buttons.size():
		var category_index := i
		_tab_buttons[i].pressed.connect(func() -> void:
			_play_sfx()
			_update_category_filter(category_index))

	# Interactive cat on pedestal
	_cat_sprite.gui_input.connect(_on_cat_gui_input)


func _start_fade_in() -> void:
	if _fade_overlay == null:
		return
	_fade_overlay.modulate = Color(1, 1, 1, 1)
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "modulate:a", 0.0, 0.35) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_cat_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_cat_clicked()


func _on_cat_clicked() -> void:
	if _is_cat_hopping:
		return
	_is_cat_hopping = true

	if _sfx_meow != null and _sfx_meow.stream != null:
		_sfx_meow.play()

	# Cute hop animation anchored to initial Y ground
	var tween := create_tween()
	tween.tween_property(_cat_sprite, "position:y", _cat_initial_y - 14.0, 0.12) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_cat_sprite, "position:y", _cat_initial_y, 0.14) \
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		_cat_sprite.position = Vector2(_cat_sprite.position.x, _cat_initial_y)
		_is_cat_hopping = false)


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


func _on_rotate_left() -> void:
	_play_sfx()
	_facing_index = (_facing_index + 3) % 4
	_update_character_facing()


func _on_rotate_right() -> void:
	_play_sfx()
	_facing_index = (_facing_index + 1) % 4
	_update_character_facing()


func _update_character_facing() -> void:
	if _facing_textures.size() > _facing_index and _facing_textures[_facing_index] != null:
		_char_texture.texture = _facing_textures[_facing_index]


func _update_category_filter(category_index: int) -> void:
	_active_category = category_index

	# Apply Tab styles across all tabs
	for i in _tab_buttons.size():
		_apply_tab_style(_tab_buttons[i], i == category_index)


func _apply_tab_style(button: Button, is_active: bool) -> void:
	var style := _tab_active_style if is_active else _tab_inactive_style
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_color_override("font_color", TAB_ACTIVE_TEXT if is_active else TAB_INACTIVE_TEXT)


func _on_back_pressed() -> void:
	if _is_leaving:
		return
	_is_leaving = true

	_play_sfx()
	if _fade_overlay != null:
		var tween := create_tween()
		tween.tween_property(_fade_overlay, "modulate:a", 1.0, 0.22) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(func() -> void: get_tree().change_scene_to_file("res://Scenes/StartView.tscn"))
	else:
		get_tree().change_scene_to_file("res://Scenes/StartView.tscn")


func _play_sfx() -> void:
	if _sfx_click != null and _sfx_click.stream != null:
		_sfx_click.play()
