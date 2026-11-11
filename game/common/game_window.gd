extends Node
## Shared window controls for scaling and F11 / Alt+Enter fullscreen toggle.
## Adapted from Git-Diwaa-Desktop for pixel-perfect display and responsive windowing.
## (autoload "GameWindow" จึงไม่ประกาศ class_name เพื่อไม่ให้ชื่อชนกับ singleton)

const BASE_WIDTH := 1920
const BASE_HEIGHT := 1080
const MIN_WIDTH := 960
const MIN_HEIGHT := 540

const BUFFY_PATH := "res://assets/icons/cursor_pixel/Buffy_Cursors2.png"
const TOUCHY_PATHS: Array[String] = [
	"res://assets/icons/cursor_pixel/Touchy_Cursors1.png",
	"res://assets/icons/cursor_pixel/Touchy_Cursors2.png",
	"res://assets/icons/cursor_pixel/Touchy_Cursors3.png",
	"res://assets/icons/cursor_pixel/Touchy_Cursors4.png",
]
const GRABBY_PATHS: Array[String] = [
	"res://assets/icons/cursor_pixel/Grabby_Cursors1.png",
	"res://assets/icons/cursor_pixel/Grabby_Cursors2.png",
	"res://assets/icons/cursor_pixel/Grabby_Cursors3.png",
	"res://assets/icons/cursor_pixel/Grabby_Cursors4.png",
]

# ขยาย 2.5x แบบ NEAREST เพื่อให้ pixel-art คมชัดขนาดกำลังดีบนจอ 1080p และจัดวางตรงจุดสัมผัสจริง
const BUFFY_CROP := Rect2i(5, 9, 20, 15)
const BUFFY_BASE_HOTSPOT := Vector2(3, 2)
const TOUCHY_CROP := Rect2i(5, 9, 20, 15)
const TOUCHY_BASE_HOTSPOT := Vector2(3, 2)
const GRABBY_CROP := Rect2i(6, 6, 19, 18)
const GRABBY_BASE_HOTSPOT := Vector2(8, 8)
const PIXEL_SCALE := 2.5
const BUFFY_HOTSPOT := Vector2(8, 5)
const TOUCHY_HOTSPOT := Vector2(8, 5)
const GRABBY_HOTSPOT := Vector2(20, 20)

const TOOLTIP_FONT_PATH := "res://assets/fonts/ChakraPetch-SemiBold.ttf"

const TOUCHY_CLICK_SEQUENCE: Array[int] = [1, 2, 3, 0] # กดแล้วเล่นเฟรม 2 -> 3 -> 4 -> กลับ 1
const TOUCHY_FRAME_DURATION := 0.055
const GRABBY_FRAME_DURATION := 0.075
const SCROLL_HOLD_DURATION := 0.32

const SECONDARY_CURSOR_SPECS: Array[Dictionary] = [
	{"shape": Input.CURSOR_IBEAM, "path": "res://assets/icons/cursor/cursor_ibeam.png", "hotspot": Vector2(6, 15)},
	{"shape": Input.CURSOR_CROSS, "path": "res://assets/icons/cursor/cursor_cross.png", "hotspot": Vector2(13, 13)},
	{"shape": Input.CURSOR_WAIT, "path": "res://assets/icons/cursor/cursor_wait.png", "hotspot": Vector2(11, 14)},
	{"shape": Input.CURSOR_BUSY, "path": "res://assets/icons/cursor/cursor_busy.png", "hotspot": Vector2(2, 2)},
	{"shape": Input.CURSOR_CAN_DROP, "path": "res://assets/icons/cursor/cursor_can_drop.png", "hotspot": Vector2(2, 2)},
	{"shape": Input.CURSOR_FORBIDDEN, "path": "res://assets/icons/cursor/cursor_forbidden.png", "hotspot": Vector2(2, 2)},
	{"shape": Input.CURSOR_VSIZE, "path": "res://assets/icons/cursor/cursor_resize_v.png", "hotspot": Vector2(7, 14)},
	{"shape": Input.CURSOR_HSIZE, "path": "res://assets/icons/cursor/cursor_resize_h.png", "hotspot": Vector2(14, 7)},
	{"shape": Input.CURSOR_BDIAGSIZE, "path": "res://assets/icons/cursor/cursor_resize_bdiag.png", "hotspot": Vector2(13, 13)},
	{"shape": Input.CURSOR_FDIAGSIZE, "path": "res://assets/icons/cursor/cursor_resize_fdiag.png", "hotspot": Vector2(13, 13)},
	{"shape": Input.CURSOR_MOVE, "path": "res://assets/icons/cursor/cursor_move.png", "hotspot": Vector2(15, 15)},
	{"shape": Input.CURSOR_HELP, "path": "res://assets/icons/cursor/cursor_help.png", "hotspot": Vector2(2, 2)},
]


class _CursorInputWatcher extends Node:
	var _owner_window: Node

	func _init(owner_window: Node) -> void:
		name = "CursorInputWatcher"
		process_mode = Node.PROCESS_MODE_ALWAYS
		_owner_window = owner_window

	func _input(event: InputEvent) -> void:
		if _owner_window != null and is_instance_valid(_owner_window):
			_owner_window._on_raw_input(event)


var _buffy_image: Image = null
var _touchy_frames: Array[Image] = []
var _grabby_frames: Array[Image] = []
var _secondary_cursor_images: Array[Image] = []
var _tracked_windows: Array[Window] = []
var _watcher: _CursorInputWatcher
var _last_raw_event: InputEvent = null

var _touchy_click_active := false
var _touchy_step := 0
var _touchy_timer := 0.0

var _scroll_anim_timer := 0.0
var _grabby_loop_timer := 0.0
var _grabby_frame_idx := 0
var _dragging_scrollbar: ScrollBar = null

var _applied_arrow_key := ""
var _applied_hand_key := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_tooltip_theme()
	_setup_custom_cursors()
	_setup_input_watcher()
	_setup_tree_hooks()

	var window := get_window()
	window.min_size = Vector2i(MIN_WIDTH, MIN_HEIGHT)

	# หากเปิดมาเป็น Windowed แล้วจอเล็กกว่า 1080p ให้ปรับขนาดให้พอดีกับจออัตโนมัติ
	if window.mode == Window.MODE_WINDOWED:
		_fit_windowed_to_screen(window)


func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_POINTING_HAND)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_DRAG)
	for spec: Dictionary in SECONDARY_CURSOR_SPECS:
		Input.set_custom_mouse_cursor(null, spec["shape"])
	_buffy_image = null
	_touchy_frames.clear()
	_grabby_frames.clear()
	_secondary_cursor_images.clear()
	_tracked_windows.clear()
	_last_raw_event = null
	_dragging_scrollbar = null
	_watcher = null
	SceneLoader.flush_preloads()


func _process(delta: float) -> void:
	if _dragging_scrollbar != null:
		if not is_instance_valid(_dragging_scrollbar) or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_dragging_scrollbar = null

	if _scroll_anim_timer > 0.0:
		_scroll_anim_timer = maxf(0.0, _scroll_anim_timer - delta)
		_grabby_loop_timer += delta
		if _grabby_loop_timer >= GRABBY_FRAME_DURATION:
			_grabby_loop_timer = fmod(_grabby_loop_timer, GRABBY_FRAME_DURATION)
			_grabby_frame_idx = (_grabby_frame_idx + 1) % 4
		_apply_uniform_cursor("grabby", _grabby_frame_idx)
		return

	_grabby_loop_timer = 0.0
	_grabby_frame_idx = 0

	if _dragging_scrollbar != null:
		_apply_uniform_cursor("grabby", 0)
		return

	var hovered := _get_hovered_control()
	if _is_hovering_scrollbar(hovered):
		_apply_uniform_cursor("grabby", 0)
		return

	if _touchy_click_active:
		_touchy_timer += delta
		if _touchy_timer >= TOUCHY_FRAME_DURATION:
			_touchy_timer = fmod(_touchy_timer, TOUCHY_FRAME_DURATION)
			_touchy_step += 1
			if _touchy_step >= TOUCHY_CLICK_SEQUENCE.size():
				_touchy_click_active = false
				_apply_idle_cursors(hovered)
			else:
				_apply_uniform_cursor("touchy", TOUCHY_CLICK_SEQUENCE[_touchy_step])
		return

	_apply_idle_cursors(hovered)


func _setup_tooltip_theme() -> void:
	var default_theme := ThemeDB.get_default_theme()
	if default_theme == null:
		return
	if ResourceLoader.exists(TOOLTIP_FONT_PATH):
		var font := load(TOOLTIP_FONT_PATH) as Font
		if font != null:
			default_theme.set_font("font", "TooltipLabel", font)
	default_theme.set_font_size("font_size", "TooltipLabel", 15)
	default_theme.set_color("font_color", "TooltipLabel", Color(0.96, 0.91, 0.82, 1.0))

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.065, 0.05, 0.96)
	panel_style.border_color = Color(0.58, 0.44, 0.22, 0.95)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(5)
	panel_style.content_margin_left = 10.0
	panel_style.content_margin_right = 10.0
	panel_style.content_margin_top = 5.0
	panel_style.content_margin_bottom = 5.0
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	panel_style.shadow_size = 4
	panel_style.shadow_offset = Vector2(0, 2)
	default_theme.set_stylebox("panel", "TooltipPanel", panel_style)


func _setup_custom_cursors() -> void:
	_buffy_image = _load_scaled_pixel_cursor(BUFFY_PATH, BUFFY_CROP, PIXEL_SCALE)

	_touchy_frames.clear()
	for p: String in TOUCHY_PATHS:
		var img := _load_scaled_pixel_cursor(p, TOUCHY_CROP, PIXEL_SCALE)
		if img != null:
			_touchy_frames.append(img)

	_grabby_frames.clear()
	for p: String in GRABBY_PATHS:
		var img := _load_scaled_pixel_cursor(p, GRABBY_CROP, PIXEL_SCALE)
		if img != null:
			_grabby_frames.append(img)

	_secondary_cursor_images.clear()
	for spec: Dictionary in SECONDARY_CURSOR_SPECS:
		var path: String = spec["path"]
		if not ResourceLoader.exists(path):
			continue
		var tex := load(path) as Texture2D
		if tex == null:
			continue
		var img := tex.get_image()
		if img == null or img.is_empty():
			continue
		_secondary_cursor_images.append(img)
		Input.set_custom_mouse_cursor(img, spec["shape"], spec["hotspot"])

	if _grabby_frames.size() >= 1:
		Input.set_custom_mouse_cursor(_grabby_frames[0], Input.CURSOR_DRAG, GRABBY_HOTSPOT)

	_apply_idle_cursors(_get_hovered_control())


func _load_scaled_pixel_cursor(path: String, crop_rect: Rect2i, scale_factor: float) -> Image:
	if not ResourceLoader.exists(path):
		return null
	var tex := load(path) as Texture2D
	if tex == null:
		return null
	var src := tex.get_image()
	if src == null or src.is_empty():
		return null
	var region := src.get_region(crop_rect)
	region.resize(roundi(crop_rect.size.x * scale_factor), roundi(crop_rect.size.y * scale_factor), Image.INTERPOLATE_NEAREST)
	return region


func _resolve_cursor(mode: String, frame_idx: int) -> Dictionary:
	if mode == "buffy" and _buffy_image != null:
		return {"key": "buffy:0", "image": _buffy_image, "hotspot": BUFFY_HOTSPOT}
	if mode == "grabby" and frame_idx >= 0 and frame_idx < _grabby_frames.size():
		return {"key": "grabby:%d" % frame_idx, "image": _grabby_frames[frame_idx], "hotspot": GRABBY_HOTSPOT}
	if mode == "touchy" and frame_idx >= 0 and frame_idx < _touchy_frames.size():
		return {"key": "touchy:%d" % frame_idx, "image": _touchy_frames[frame_idx], "hotspot": TOUCHY_HOTSPOT}
	return {}


func _apply_cursors(arrow_mode: String, arrow_frame: int, hand_mode: String, hand_frame: int) -> void:
	var arrow_spec := _resolve_cursor(arrow_mode, arrow_frame)
	if not arrow_spec.is_empty() and arrow_spec["key"] != _applied_arrow_key:
		_applied_arrow_key = arrow_spec["key"]
		Input.set_custom_mouse_cursor(arrow_spec["image"], Input.CURSOR_ARROW, arrow_spec["hotspot"])

	var hand_spec := _resolve_cursor(hand_mode, hand_frame)
	if not hand_spec.is_empty() and hand_spec["key"] != _applied_hand_key:
		_applied_hand_key = hand_spec["key"]
		Input.set_custom_mouse_cursor(hand_spec["image"], Input.CURSOR_POINTING_HAND, hand_spec["hotspot"])


func _apply_uniform_cursor(mode: String, frame_idx: int) -> void:
	_apply_cursors(mode, frame_idx, mode, frame_idx)


func _apply_idle_cursors(hovered: Control) -> void:
	# ปกติใช้ Buffy2 เป็นเมาส์หลัก และเปลี่ยนเป็น Touchy1 เมื่อชี้ปุ่มที่กดได้ (ไม่รวมปุ่มที่ disabled)
	if _is_hovering_disabled_button(hovered):
		_apply_uniform_cursor("buffy", 0)
	else:
		_apply_cursors("buffy", 0, "touchy", 0)


func _setup_input_watcher() -> void:
	var root_vp := get_tree().root
	_watcher = _CursorInputWatcher.new(self)
	if not root_vp.child_entered_tree.is_connected(_on_root_child_entered):
		root_vp.child_entered_tree.connect(_on_root_child_entered)
	root_vp.add_child.call_deferred(_watcher)


func _on_root_child_entered(_node: Node) -> void:
	_keep_watcher_last.call_deferred()


func _keep_watcher_last() -> void:
	if _watcher == null or not is_instance_valid(_watcher):
		return
	var root_vp := get_tree().root
	if _watcher.get_parent() == root_vp and _watcher.get_index() != root_vp.get_child_count() - 1:
		root_vp.move_child(_watcher, -1)


func _setup_tree_hooks() -> void:
	var tree := get_tree()
	if not tree.node_added.is_connected(_on_tree_node_added):
		tree.node_added.connect(_on_tree_node_added)
	_hook_nodes_recursive(tree.root)


func _hook_nodes_recursive(node: Node) -> void:
	_on_tree_node_added(node)
	for child: Node in node.get_children(true):
		_hook_nodes_recursive(child)


func _on_tree_node_added(node: Node) -> void:
	if node is ScrollBar:
		_hook_scrollbar(node as ScrollBar)
	elif node is Window and node != get_tree().root:
		_hook_window(node as Window)
	if node is AcceptDialog:
		_hook_dialog(node as AcceptDialog)


func _hook_window(win: Window) -> void:
	if not _tracked_windows.has(win):
		_tracked_windows.append(win)
	if not win.has_meta(&"_gw_win_hooked"):
		win.set_meta(&"_gw_win_hooked", true)
		win.window_input.connect(_on_raw_input)


func _hook_dialog(dialog: AcceptDialog) -> void:
	var buttons: Array[Button] = [dialog.get_ok_button()]
	if dialog is ConfirmationDialog:
		buttons.append((dialog as ConfirmationDialog).get_cancel_button())
	for btn: Button in buttons:
		if btn != null and is_instance_valid(btn) and btn.mouse_default_cursor_shape == Control.CURSOR_ARROW:
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _hook_scrollbar(sb: ScrollBar) -> void:
	if sb.has_meta(&"_gw_hooked"):
		return
	sb.set_meta(&"_gw_hooked", true)
	sb.scrolling.connect(_on_scrollbar_scrolling.bind(sb))
	sb.gui_input.connect(_on_scrollbar_gui_input.bind(sb))


func _on_scrollbar_scrolling(_sb: ScrollBar) -> void:
	_trigger_scroll_anim()


func _on_scrollbar_gui_input(event: InputEvent, sb: ScrollBar) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging_scrollbar = sb
			_touchy_click_active = false
			if _scroll_anim_timer <= 0.0:
				_apply_uniform_cursor("grabby", 0)
		elif _dragging_scrollbar == sb:
			_dragging_scrollbar = null


func _get_hovered_control() -> Control:
	var write_idx := 0
	var hovered_in_subwindow: Control = null
	for i in _tracked_windows.size():
		var win := _tracked_windows[i]
		if win != null and is_instance_valid(win) and win.is_inside_tree():
			_tracked_windows[write_idx] = win
			write_idx += 1
			if win.visible:
				var ctrl := win.gui_get_hovered_control()
				if ctrl != null and is_instance_valid(ctrl):
					hovered_in_subwindow = ctrl
	_tracked_windows.resize(write_idx)
	if hovered_in_subwindow != null:
		return hovered_in_subwindow

	var vp := get_viewport()
	if vp == null:
		return null
	return vp.gui_get_hovered_control()


func _is_hovering_disabled_button(hovered: Control) -> bool:
	var curr := hovered
	while curr != null:
		if curr is BaseButton:
			return (curr as BaseButton).disabled
		if curr.mouse_filter == Control.MOUSE_FILTER_STOP:
			break
		var parent := curr.get_parent()
		curr = parent as Control if parent is Control else null
	return false


func _is_hovering_scrollbar(hovered: Control) -> bool:
	return hovered is ScrollBar and hovered.visible


func _trigger_scroll_anim() -> void:
	_touchy_click_active = false
	var was_active := _scroll_anim_timer > 0.0
	_scroll_anim_timer = SCROLL_HOLD_DURATION
	if not was_active:
		if _applied_arrow_key == "grabby:0":
			_grabby_loop_timer = GRABBY_FRAME_DURATION * 0.85
			_grabby_frame_idx = 0
		else:
			_grabby_loop_timer = 0.0
			_grabby_frame_idx = 0
			_apply_uniform_cursor("grabby", 0)


func _on_raw_input(event: InputEvent) -> void:
	if event == _last_raw_event:
		return
	_last_raw_event = event

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if mb.pressed:
				_trigger_scroll_anim()
			return

		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				if _dragging_scrollbar != null or _is_hovering_scrollbar(_get_hovered_control()):
					return
				_scroll_anim_timer = 0.0
				_touchy_click_active = true
				_touchy_step = 0
				_touchy_timer = 0.0
				_apply_uniform_cursor("touchy", TOUCHY_CLICK_SEQUENCE[0])
			elif mb.button_index == MOUSE_BUTTON_LEFT:
				_dragging_scrollbar = null
	elif event is InputEventMouseMotion and _dragging_scrollbar != null:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_trigger_scroll_anim()
		else:
			_dragging_scrollbar = null


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	var is_f11: bool = (event.keycode == KEY_F11)
	var is_alt_enter: bool = ((event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER) and event.alt_pressed)
	if not (is_f11 or is_alt_enter):
		return

	toggle_fullscreen()
	get_viewport().set_input_as_handled()


func toggle_fullscreen() -> void:
	var window := get_window()
	if window.mode == Window.MODE_FULLSCREEN or window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		window.mode = Window.MODE_WINDOWED
		_fit_windowed_to_screen(window)
	else:
		window.mode = Window.MODE_FULLSCREEN


func _fit_windowed_to_screen(window: Window) -> void:
	var screen := DisplayServer.screen_get_usable_rect(window.current_screen)
	var width := mini(BASE_WIDTH, int(screen.size.x * 0.85))
	var height := mini(BASE_HEIGHT, int(screen.size.y * 0.85))
	var window_scale := minf(float(width) / float(BASE_WIDTH), float(height) / float(BASE_HEIGHT))
	window.size = Vector2i(int(BASE_WIDTH * window_scale), int(BASE_HEIGHT * window_scale))
	window.position = screen.position + (screen.size - window.size) / 2

