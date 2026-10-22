extends Node
## Shared window controls for scaling and F11 fullscreen toggle.
## Adapted from Git-Diwaa-Desktop for pixel-perfect 1080p display.
## (autoload "GameWindow" จึงไม่ประกาศ class_name เพื่อไม่ให้ชื่อชนกับ singleton)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11):
		return

	var window := get_window()
	if window.mode == Window.MODE_FULLSCREEN or window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		window.mode = Window.MODE_WINDOWED
		var screen := DisplayServer.screen_get_usable_rect(window.current_screen)
		var width := mini(1920, int(screen.size.x * 0.85))
		var height := mini(1080, int(screen.size.y * 0.85))
		var window_scale := minf(width / 1920.0, height / 1080.0)
		window.size = Vector2i(int(1920 * window_scale), int(1080 * window_scale))
		window.position = screen.position + (screen.size - window.size) / 2
	else:
		window.mode = Window.MODE_FULLSCREEN

	get_viewport().set_input_as_handled()
