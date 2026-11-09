extends Node
## Shared window controls for scaling and F11 / Alt+Enter fullscreen toggle.
## Adapted from Git-Diwaa-Desktop for pixel-perfect display and responsive windowing.
## (autoload "GameWindow" จึงไม่ประกาศ class_name เพื่อไม่ให้ชื่อชนกับ singleton)

const BASE_WIDTH := 1920
const BASE_HEIGHT := 1080
const MIN_WIDTH := 960
const MIN_HEIGHT := 540


func _ready() -> void:
	var window := get_window()
	window.min_size = Vector2i(MIN_WIDTH, MIN_HEIGHT)

	# หากเปิดมาเป็น Windowed แล้วจอเล็กกว่า 1080p ให้ปรับขนาดให้พอดีกับจออัตโนมัติ
	if window.mode == Window.MODE_WINDOWED:
		_fit_windowed_to_screen(window)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	var is_f11: bool = (event.keycode == KEY_F11)
	var is_alt_enter: bool = (event.keycode == KEY_ENTER and event.alt_pressed)
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

