class_name CommitGraphCanvas
extends Control
## Scrollable graph surface with keyboard and pointer selection.

signal selected(commit: CommitGraphDisplayNode)

const ROW_HEIGHT := 72.0
const LANE_COLORS: Array[Color] = [
	Color("65dfb2"), Color("8ca9ff"), Color("df9ffa"), Color("ffb66c"), Color("68d3ee"),
]

var _layout := CommitGraphLayout.new()
var _selected := -1
var _hovered := -1

var _text_x: float:
	get:
		return 32.0 + _layout.lane_count * 24.0


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	mouse_exited.connect(func() -> void:
		_hovered = -1
		tooltip_text = ""
		queue_redraw())


func set_layout(layout: CommitGraphLayout) -> void:
	var selected_id := ""
	if _selected >= 0 and _selected < _layout.rows.size():
		selected_id = _layout.rows[_selected].commit.id
	_layout = layout
	_selected = -1
	for index in layout.rows.size():
		if layout.rows[index].commit.id == selected_id:
			_selected = index
			break
	_hovered = -1
	tooltip_text = ""
	custom_minimum_size = Vector2(0, layout.rows.size() * ROW_HEIGHT + 8)
	queue_redraw()


static func _lane_color(lane: int) -> Color:
	return LANE_COLORS[lane % LANE_COLORS.size()]


static func _point(row: int, lane: int) -> Vector2:
	return Vector2(24 + lane * 24, row * ROW_HEIGHT + 27)


func _draw() -> void:
	var font := get_theme_font("font")
	for index in _layout.rows.size():
		if index == _selected or index == _hovered:
			var highlight := StyleBoxFlat.new()
			highlight.bg_color = Color("26344e") if index == _selected else Color("171f33")
			highlight.set_corner_radius_all(8)
			draw_style_box(highlight, Rect2(0, index * ROW_HEIGHT + 2, size.x, ROW_HEIGHT - 4))

	for edge in _layout.edges:
		var from := _point(edge.from_row, edge.from_lane)
		var to := _point(edge.to_row, edge.to_lane)
		if edge.is_merge and edge.from_lane != edge.to_lane:
			# Merge edge: leave the merge commit diagonally, then run down the merged branch's lane.
			var bend_y := from.y + ROW_HEIGHT / 2
			draw_polyline(PackedVector2Array([from, Vector2(from.x, from.y + 12), Vector2(to.x, bend_y), to]),
					_lane_color(edge.to_lane).darkened(0.25), 2.5, true)
			continue
		var fork_y := to.y - ROW_HEIGHT / 2
		draw_polyline(PackedVector2Array([from, Vector2(from.x, fork_y), Vector2(to.x, to.y - 12), to]),
				_lane_color(edge.from_lane).darkened(0.25), 2.5, true)

	for index in _layout.rows.size():
		var row := _layout.rows[index]
		var point := _point(index, row.lane)
		var color := Color("ffc959") if row.commit.is_current_branch_head else _lane_color(row.lane)
		if row.commit.is_current_branch_head:
			draw_circle(point, 12, Color(color, 0.18))
		draw_circle(point, 7, color)
		draw_circle(point, 3, Color("111827"))
		var y := index * ROW_HEIGHT
		draw_string(font, Vector2(_text_x, y + 26), row.commit.subject, HORIZONTAL_ALIGNMENT_LEFT,
				size.x - _text_x - 12, 18, Color("e7edf7"))
		var refs := "HEAD · " if row.commit.is_current_branch_head else ""
		refs += " · ".join(row.commit.branches)
		var metadata := row.commit.short_id + (("   " + refs) if refs.length() > 0 else ("   " + row.commit.author))
		draw_string(font, Vector2(_text_x, y + 50), metadata, HORIZONTAL_ALIGNMENT_LEFT,
				size.x - _text_x - 12, 14, color if refs.length() > 0 else Color("94a3bb"))


func _row_at(y: float) -> int:
	var row_index := floori(y / ROW_HEIGHT)
	if row_index >= 0 and row_index < _layout.rows.size():
		return row_index
	return -1


func _get_cursor_shape(at_position: Vector2) -> CursorShape:
	if _row_at(at_position.y) != -1:
		return Control.CURSOR_POINTING_HAND
	return Control.CURSOR_ARROW


func _gui_input(input: InputEvent) -> void:
	if input is InputEventMouseMotion:
		_hovered = _row_at(input.position.y)
		var has_row := _hovered != -1
		tooltip_text = "%s\nดับเบิลคลิก หรือ Ctrl/Cmd+C เพื่อคัดลอก ID" % _layout.rows[_hovered].commit.id \
				if has_row else ""
		queue_redraw()
	if input is InputEventMouseButton and input.pressed and input.button_index == MOUSE_BUTTON_LEFT:
		var row_idx := _row_at(input.position.y)
		if row_idx != -1:
			_choose(row_idx)
			if input.double_click:
				_copy_selected_id()
		grab_focus()
		accept_event()
	if input is InputEventKey and input.pressed:
		if input.keycode == KEY_C and (input.ctrl_pressed or input.meta_pressed):
			_copy_selected_id()
			accept_event()
		if input.keycode == KEY_DOWN:
			_choose(mini(_selected + 1, _layout.rows.size() - 1))
			accept_event()
		if input.keycode == KEY_UP:
			_choose(maxi(0, _selected - 1))
			accept_event()


func _copy_selected_id() -> void:
	if _selected < 0 or _selected >= _layout.rows.size():
		return
	DisplayServer.clipboard_set(_layout.rows[_selected].commit.id)
	tooltip_text = "✓ คัดลอก Commit ID แล้ว"


func _choose(index: int) -> void:
	if index < 0 or index >= _layout.rows.size():
		return
	_selected = index
	selected.emit(_layout.rows[index].commit)
	queue_redraw()
