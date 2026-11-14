extends SceneTree
## Headless verification script สำหรับทดสอบ UI Cursor และ CommitGraphCanvas
##
## รัน:
##   godot --headless --path game --script ../tests/ui/run_cursor_tests.gd

const GameWindowScript = preload("res://common/game_window.gd")

var _passed := 0
var _total := 0
var _failures: Array[String] = []


func _initialize() -> void:
	print("--- Running UI & Cursor Tests (Headless) ---")
	await process_frame
	_test_commit_graph_cursor_shape()
	_test_commit_graph_focus_on_blank_click()
	_test_commit_graph_hover_deduplication()
	_test_is_hovering_clickable_enabled_button()
	_test_is_hovering_clickable_button_with_default_arrow()
	_test_is_hovering_clickable_nested_label()
	_test_is_hovering_clickable_disabled_button()
	_test_is_hovering_clickable_plain_control()
	_test_touchy_click_animation_on_disabled_button()

	print("\n--- Test Results ---")
	print("Passed: %d / %d" % [_passed, _total])
	if _failures.is_empty():
		print("All tests passed successfully!")
		quit(0)
	else:
		printerr("Failures (%d):\n  * %s" % [_failures.size(), "\n  * ".join(_failures)])
		quit(1)


func _assert_true(condition: bool, test_name: String) -> void:
	_total += 1
	if condition:
		_passed += 1
		print("  [PASS] %s" % test_name)
	else:
		_failures.append(test_name)
		printerr("  [FAIL] %s" % test_name)


func _create_sample_layout() -> CommitGraphLayout:
	var layout := CommitGraphLayout.new()
	var commit := CommitGraphDisplayNode.new(
		"abc1234567890abcdef",
		"abc1234",
		[],
		["main"],
		true,
		"feat: initial commit",
		"Tester",
		1700000000.0
	)
	var row := CommitGraphRow.new(commit, 0)
	layout.rows.append(row)
	layout.lane_count = 1
	return layout


func _test_commit_graph_cursor_shape() -> void:
	var canvas := CommitGraphCanvas.new()
	canvas.set_layout(_create_sample_layout())

	# แถวแรก y = 0..72 ต้องเป็น POINTING_HAND
	var hand_shape := canvas.get_cursor_shape(Vector2(50, 20))
	_assert_true(hand_shape == Control.CURSOR_POINTING_HAND, "commit graph: แถว commit ต้องได้ CURSOR_POINTING_HAND ผ่าน get_cursor_shape")

	# พื้นที่ว่างใต้แถวสุดท้าย y >= 72 ต้องเป็น CURSOR_ARROW
	var arrow_shape := canvas.get_cursor_shape(Vector2(50, 200))
	_assert_true(arrow_shape == Control.CURSOR_ARROW, "commit graph: พื้นที่ว่างต้องได้ CURSOR_ARROW ผ่าน get_cursor_shape")
	canvas.free()


func _test_commit_graph_focus_on_blank_click() -> void:
	var root := Control.new()
	root.size = Vector2(800, 600)
	get_root().add_child(root)

	var canvas := CommitGraphCanvas.new()
	canvas.size = Vector2(800, 600)
	canvas.set_layout(_create_sample_layout())
	root.add_child(canvas)

	# จำลองคลิกซ้ายที่พื้นที่ว่าง y = 300 (ไม่มี commit)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(100, 300)

	canvas._gui_input(click)

	_assert_true(canvas.has_focus(), "commit graph: คลิกพื้นที่ว่างต้องได้รับ focus")

	root.free()


func _test_commit_graph_hover_deduplication() -> void:
	var canvas := CommitGraphCanvas.new()
	canvas.set_layout(_create_sample_layout())

	# ขยับเมาส์ในแถวแรก y = 10
	var motion1 := InputEventMouseMotion.new()
	motion1.position = Vector2(50, 10)
	canvas._gui_input(motion1)
	_assert_true(canvas._hovered == 0, "commit graph: hover แถวแรก _hovered ต้องเป็น 0")

	# ขยับเมาส์ในแถวเดิม y = 25
	var motion2 := InputEventMouseMotion.new()
	motion2.position = Vector2(50, 25)
	canvas._gui_input(motion2)
	_assert_true(canvas._hovered == 0, "commit graph: ขยับเมาส์ในแถวเดิม _hovered ยังต้องเป็น 0")

	# ขยับเมาส์ออกไปพื้นที่ว่าง y = 200
	var motion3 := InputEventMouseMotion.new()
	motion3.position = Vector2(50, 200)
	canvas._gui_input(motion3)
	_assert_true(canvas._hovered == -1, "commit graph: ขยับเมาส์ไปพื้นที่ว่าง _hovered ต้องเป็น -1")

	canvas.free()


func _test_is_hovering_clickable_enabled_button() -> void:
	var gw = GameWindowScript.new()
	get_root().add_child(gw)

	var btn := Button.new()
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	get_root().add_child(btn)

	var is_clickable: bool = gw._is_hovering_clickable(btn)
	_assert_true(is_clickable, "game_window: ปุ่มปกติที่เปิดใช้งานต้อง _is_hovering_clickable == true")

	btn.free()
	gw.free()


func _test_is_hovering_clickable_button_with_default_arrow() -> void:
	var gw = GameWindowScript.new()
	get_root().add_child(gw)

	var btn := Button.new()
	btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
	get_root().add_child(btn)

	var is_clickable: bool = gw._is_hovering_clickable(btn)
	_assert_true(is_clickable, "game_window: ปุ่ม BaseButton แม้ใช้เคอร์เซอร์ลูกศรก็ต้อง _is_hovering_clickable == true")

	btn.free()
	gw.free()


func _test_is_hovering_clickable_nested_label() -> void:
	var gw = GameWindowScript.new()
	get_root().add_child(gw)

	var btn := Button.new()
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	btn.add_child(label)
	get_root().add_child(btn)

	var is_clickable: bool = gw._is_hovering_clickable(label)
	_assert_true(is_clickable, "game_window: โหนดลูกในปุ่ม (Label) ต้อง walk parent เจอและ _is_hovering_clickable == true")

	btn.free()
	gw.free()


func _test_is_hovering_clickable_disabled_button() -> void:
	var gw = GameWindowScript.new()
	get_root().add_child(gw)

	var btn := Button.new()
	btn.disabled = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	btn.add_child(label)
	get_root().add_child(btn)

	var is_btn_clickable: bool = gw._is_hovering_clickable(btn)
	_assert_true(not is_btn_clickable, "game_window: ปุ่มที่ disabled ต้อง _is_hovering_clickable == false")

	var is_label_clickable: bool = gw._is_hovering_clickable(label)
	_assert_true(not is_label_clickable, "game_window: โหนดลูกในปุ่ม disabled ต้อง _is_hovering_clickable == false")

	btn.free()
	gw.free()


func _test_is_hovering_clickable_plain_control() -> void:
	var gw = GameWindowScript.new()
	get_root().add_child(gw)

	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	get_root().add_child(panel)

	var is_clickable: bool = gw._is_hovering_clickable(panel)
	_assert_true(not is_clickable, "game_window: โหนด Control ธรรมดา (ไม่ใช่ปุ่มและไม่มีรูปมือ) ต้อง _is_hovering_clickable == false")

	panel.free()
	gw.free()


func _test_touchy_click_animation_on_disabled_button() -> void:
	var gw = GameWindowScript.new()
	get_root().add_child(gw)

	var btn := Button.new()
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	get_root().add_child(btn)

	gw._touchy_click_active = true
	gw._touchy_step = 0
	gw._touchy_timer = 0.0
	gw._apply_touchy_click_cursor(gw.TOUCHY_CLICK_SEQUENCE[0])

	btn.disabled = true

	gw._process(gw.TOUCHY_FRAME_DURATION + 0.01)

	_assert_true(gw._touchy_click_active, "touchy click: แอนิเมชันต้องเล่นต่อแม้ปุ่มถูก disable")
	_assert_true(gw._touchy_step == 1, "touchy click: แอนิเมชันต้องเลื่อนไปยัง step 1")
	_assert_true(gw._applied_hand_key.begins_with("touchy:"), "touchy click: เคอร์เซอร์ hand ต้องเป็น touchy ไม่ใช่ buffy")

	btn.free()
	gw.free()
