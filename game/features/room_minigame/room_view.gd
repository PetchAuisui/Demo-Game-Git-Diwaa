class_name RoomView
extends Control
## ภาพห้องในหอคอยกลางฉาก Sandbox: โต๊ะ (working tree) · แท่นเตรียม (stage) · คัมภีร์ (commit)
## พร้อมหัวใจ มาตรวัดคลื่นโกลาหล มิติที่ยืนอยู่ และข้อความเหตุการณ์ในโลก
## ข้อมูลทั้งหมดมาจาก RoomGame.describe() — ห้องสะท้อน repo จริงเสมอ
## คลิกของในห้อง = หยิบขึ้นมาอ่าน (การกระทำในโลก ไม่ต้องพิมพ์คำสั่ง) ส่วนอื่นของห้องไม่รับเมาส์

signal item_pressed(path: String)
## เอ่ยคำในโลก (รหัสผนึก อักขระ ระดับพลัง) — ทำในห้อง ไม่ใช่ในวงร่ายเวท (Terminal ไว้สำหรับ Git เท่านั้น)
signal spoken(word: String)

const TOME_TEXTURE := "res://assets/cutscene/props/khampri/Khampri.png"
const PAPER_TEXTURE := "res://assets/cutscene/props/khampri/paper.png"
const SHARD_TEXTURE_FORMAT := "res://assets/cutscene/props/khampri/minikhampri%d.png"
const SHARD_COUNT := 20
const FONT_BOLD := "res://assets/fonts/ChakraPetch-Bold.ttf"
const FONT_REGULAR := "res://assets/fonts/ChakraPetch-Regular.ttf"

const ZONES := [
	{"state": RoomGame.STATE_DESK, "title": "โต๊ะเขียน", "sub": "ยังไม่ปลอดภัย"},
	{"state": RoomGame.STATE_ALTAR, "title": "แท่นเตรียม", "sub": "รอการจารึก"},
	{"state": RoomGame.STATE_TOME, "title": "คัมภีร์", "sub": "จารึกแล้ว · ปลอดภัย"},
]
const KIND_TINT := {
	"fragment": Color(1, 0.95, 0.8),
	"curse": Color(0.55, 0.3, 0.75),
	"key": Color(1.0, 0.85, 0.35),
	"note": Color(0.9, 0.88, 0.85),
}
const CHAOS_COLOR := Color("b06bff")
const STATE_TAG_COLORS := {
	"untracked": Color("7ee8a8"),
	"modified": Color("ffb86b"),
	"staged": Color("8fd3ff"),
	"staged_modified": Color("ffd27a"),
	"cursed": Color("d6a8ff"),
	"conflict": Color("ff7b7b"),
}
const HEART_COLOR := Color("ff5a7a")
const IDLE_HINT := "คลิกกระดาษในห้องเพื่อหยิบขึ้นมาอ่าน"
const IDLE_ALPHA := 0.55
const BATTLE_HINT := "ร่ายคาถาให้ถูกก่อนศัตรูจะถึงตัว — ทุกการกระทำ ศัตรูขยับเข้ามาหนึ่งก้าว"

static var _shard_cache: Array[Texture2D] = []

var _font_bold: Font
var _font_regular: Font
var _frame: PanelContainer
var _hearts_label: Label
var _chaos_label: Label
var _chaos_bar: ProgressBar
var _dimension_label: Label
var _zone_boxes: Dictionary = {}
var _event_label: Label
var _flash: ColorRect
var _event_tween: Tween
var _zones: HBoxContainer
var _battle: BattleFieldView
var _in_battle := false
var _speak_bar: PanelContainer
var _speak_input: LineEdit


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font_bold = load(FONT_BOLD) if ResourceLoader.exists(FONT_BOLD) else null
	_font_regular = load(FONT_REGULAR) if ResourceLoader.exists(FONT_REGULAR) else null
	_build()


## วางห้องในช่องว่างกลางฉาก (ระหว่างแผงซ้าย-ขวา เหนือ Terminal)
func place_in_stage() -> void:
	anchor_left = 0.285
	anchor_right = 0.715
	anchor_top = 0.12
	anchor_bottom = 0.63
	offset_left = 0
	offset_right = 0
	offset_top = 0
	offset_bottom = 0


func update_room(game: RoomGame, items: Array[Dictionary], branch: String) -> void:
	_hearts_label.text = "♥ ".repeat(game.hearts) + "♡ ".repeat(maxi(0, game.max_hearts - game.hearts))
	if game.has_waves():
		var left := game.turns_until_wave()
		_chaos_label.text = "คลื่นโกลาหลในอีก %d การกระทำ" % left if left > 1 else "คลื่นโกลาหลกำลังมา!"
		_chaos_bar.max_value = game.wave_every
		_chaos_bar.value = game.wave_every - left
		_chaos_label.visible = true
		_chaos_bar.visible = true
	else:
		_chaos_label.visible = false
		_chaos_bar.visible = false
	_dimension_label.text = "มิติ: %s" % branch if not branch.is_empty() else "ยังไม่มีคัมภีร์"
	if game.has_battle():
		# ด่านต่อสู้: ไม่มีของให้ปกป้อง แสดงสนามรบแทนโต๊ะ/แท่น/คัมภีร์
		if not _in_battle:
			_in_battle = true
			_show_idle_hint()
		_zones.visible = false
		_battle.visible = true
		_dimension_label.visible = false
		_battle.update_battle(game)
		return

	for zone in _zone_boxes.values():
		for child in (zone as Container).get_children():
			child.queue_free()
	var index := 0
	for item in items:
		var state := str(item["state"])
		var zone_state := state
		if state == RoomGame.STATE_CURSED or state == RoomGame.STATE_CONFLICT:
			zone_state = RoomGame.STATE_DESK
		var box: Container = _zone_boxes.get(zone_state, null)
		if box != null:
			box.add_child(_make_item(item, index))
		index += 1


## โน้ตของมิวรา (เช่น คำแปลผล git status) แสดงในห้องนานกว่าเหตุการณ์ปกติ — วงร่ายเวทเหลือไว้ให้ Git
func show_note(lines: PackedStringArray, seconds: float = 9.0) -> void:
	if lines.is_empty():
		return
	_event_label.text = "\n".join(lines)
	_event_label.add_theme_color_override("font_color", Color("c9f2ff"))
	if _event_tween != null and _event_tween.is_valid():
		_event_tween.kill()
	_event_label.modulate.a = 1.0
	_event_tween = create_tween()
	_event_tween.tween_interval(seconds)
	_event_tween.tween_property(_event_label, "modulate:a", 0.0, 0.8)
	_event_tween.tween_callback(_show_idle_hint)


## แสดงเหตุการณ์ในโลก (คลื่น, สลาย, ก่อตัวใหม่) — คลื่นทำให้ห้องสั่นและเรืองม่วง
func play_events(events: Array[Dictionary]) -> void:
	if events.is_empty():
		return
	var lines: PackedStringArray = []
	var has_wave := false
	var has_damage := false
	for event in events:
		lines.append(str(event["text"]))
		has_wave = has_wave or event["type"] == "wave"
		has_damage = has_damage or event["type"] == "damage"
	if _in_battle:
		_battle.play(events)
	_event_label.text = "\n".join(lines)
	_event_label.add_theme_color_override("font_color", Color("ffb3c4") if has_damage else Color("d8f7ff"))
	if _event_tween != null and _event_tween.is_valid():
		_event_tween.kill()
	_event_label.modulate.a = 1.0
	_event_tween = create_tween()
	_event_tween.tween_interval(4.5)
	_event_tween.tween_property(_event_label, "modulate:a", 0.0, 0.8)
	_event_tween.tween_callback(_show_idle_hint)
	if has_wave or has_damage:
		_flash.color = Color(CHAOS_COLOR, 0.0) if has_wave else Color(HEART_COLOR, 0.0)
		var flash := create_tween()
		flash.tween_property(_flash, "color:a", 0.45, 0.12)
		flash.tween_property(_flash, "color:a", 0.0, 0.7)
		var shake := create_tween()
		for i in 6:
			shake.tween_property(_frame, "position:x", 8.0 * (1 if i % 2 == 0 else -1), 0.04)
		shake.tween_property(_frame, "position:x", 0.0, 0.04)


func _show_idle_hint() -> void:
	_event_label.text = BATTLE_HINT if _in_battle else IDLE_HINT
	_event_label.add_theme_color_override("font_color", Color("e8dcc0"))
	_event_label.modulate.a = IDLE_ALPHA


func _build() -> void:
	_frame = PanelContainer.new()
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.1, 0.78)
	style.border_color = Color(0.75, 0.6, 0.3, 0.9)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(16)
	_frame.add_theme_stylebox_override("panel", style)
	add_child(_frame)

	var root := VBoxContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("separation", 8)
	_frame.add_child(root)

	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)
	_hearts_label = _label(26, HEART_COLOR, true)
	header.add_child(_hearts_label)
	_dimension_label = _label(18, Color("c9b6ff"), false)
	header.add_child(_dimension_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(spacer)
	var chaos_box := VBoxContainer.new()
	chaos_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chaos_box.custom_minimum_size = Vector2(260, 0)
	header.add_child(chaos_box)
	_chaos_label = _label(17, CHAOS_COLOR.lightened(0.3), true)
	_chaos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	chaos_box.add_child(_chaos_label)
	_chaos_bar = ProgressBar.new()
	_chaos_bar.show_percentage = false
	_chaos_bar.custom_minimum_size = Vector2(0, 10)
	_chaos_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = CHAOS_COLOR
	fill.set_corner_radius_all(5)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(1, 1, 1, 0.08)
	back.set_corner_radius_all(5)
	_chaos_bar.add_theme_stylebox_override("fill", fill)
	_chaos_bar.add_theme_stylebox_override("background", back)
	chaos_box.add_child(_chaos_bar)

	_zones = HBoxContainer.new()
	_zones.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_zones.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_zones.add_theme_constant_override("separation", 10)
	root.add_child(_zones)
	for zone in ZONES:
		_zones.add_child(_make_zone(zone))
	_battle = BattleFieldView.new()
	_battle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_battle.visible = false
	root.add_child(_battle)

	_build_speak_bar(root)

	_event_label = _label(19, Color("d8f7ff"), true)
	_event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_event_label.custom_minimum_size = Vector2(0, 54)
	root.add_child(_event_label)
	_show_idle_hint()

	_flash = ColorRect.new()
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(CHAOS_COLOR, 0.0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)


## แสดง/ซ่อนช่องเอ่ยคำ (แสดงเฉพาะตอนที่โลกรอคำตอบอยู่)
func set_speaking(active: bool) -> void:
	if _speak_bar == null or _speak_bar.visible == active:
		return
	_speak_bar.visible = active
	if active:
		_speak_bar.modulate.a = 0.0
		create_tween().tween_property(_speak_bar, "modulate:a", 1.0, 0.3)


func _submit_speech(text: String = "") -> void:
	var word := _speak_input.text.strip_edges()
	if word.is_empty():
		return
	_speak_input.clear()
	spoken.emit(word)


func _build_speak_bar(root: Control) -> void:
	_speak_bar = PanelContainer.new()
	_speak_bar.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.1, 0.24, 0.92)
	style.border_color = Color("ffd36b")
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.content_margin_left = 16
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	_speak_bar.add_theme_stylebox_override("panel", style)
	root.add_child(_speak_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_speak_bar.add_child(row)
	var title := _label(18, Color("ffd36b"), true)
	title.text = "✦ เอ่ยคำ"
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(title)
	_speak_input = LineEdit.new()
	_speak_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_speak_input.placeholder_text = "พิมพ์คำที่จะเอ่ยต่อหน้าวงเวท/ประตู แล้วกด Enter (เอ่ยผิดพลังจะสะท้อนกลับ)"
	_speak_input.add_theme_font_size_override("font_size", 18)
	if _font_regular != null:
		_speak_input.add_theme_font_override("font", _font_regular)
	_speak_input.add_theme_color_override("font_color", Color("fff3d6"))
	_speak_input.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.4))
	var empty := StyleBoxEmpty.new()
	_speak_input.add_theme_stylebox_override("normal", empty)
	_speak_input.add_theme_stylebox_override("focus", empty)
	_speak_input.text_submitted.connect(_submit_speech)
	row.add_child(_speak_input)
	var button := Button.new()
	button.text = "เอ่ย"
	button.custom_minimum_size = Vector2(90, 38)
	button.add_theme_font_size_override("font_size", 18)
	if _font_bold != null:
		button.add_theme_font_override("font", _font_bold)
	button.add_theme_color_override("font_color", Color("2b1a0e"))
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("ffd36b") if state != "hover" else Color("ffe39a")
		sb.set_corner_radius_all(18)
		button.add_theme_stylebox_override(state, sb)
	button.pressed.connect(func() -> void: _submit_speech())
	row.add_child(button)


func _make_zone(zone: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	var is_tome: bool = zone["state"] == RoomGame.STATE_TOME
	style.bg_color = Color(0.2, 0.16, 0.05, 0.55) if is_tome else Color(1, 1, 1, 0.05)
	style.border_color = Color(0.95, 0.8, 0.4, 0.8) if is_tome else Color(1, 1, 1, 0.15)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var title := _label(20, Color("ebcb70") if is_tome else Color.WHITE, true)
	title.text = zone["title"]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := _label(14, Color(1, 1, 1, 0.6), false)
	sub.text = zone["sub"]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	if is_tome and ResourceLoader.exists(TOME_TEXTURE):
		var tome := TextureRect.new()
		tome.texture = load(TOME_TEXTURE)
		tome.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tome.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tome.custom_minimum_size = Vector2(0, 56)
		tome.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tome.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(tome)
	var items := VBoxContainer.new()
	items.mouse_filter = Control.MOUSE_FILTER_IGNORE
	items.add_theme_constant_override("separation", 3)
	box.add_child(items)
	_zone_boxes[zone["state"]] = items
	return panel


func _make_item(item: Dictionary, index: int) -> Control:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.tooltip_text = "คลิกเพื่ออ่าน %s" % item["path"]
	var path := str(item["path"])
	row.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			item_pressed.emit(path))
	row.mouse_entered.connect(func() -> void: row.modulate = Color(1.25, 1.2, 1.0))
	row.mouse_exited.connect(func() -> void: row.modulate = Color.WHITE)
	row.add_theme_constant_override("separation", 6)
	var kind := str(item["kind"])
	var state := str(item["state"])
	var hidden: bool = item.get("hidden", false)

	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(30, 30)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = _shard(index) if kind in ["fragment", "key"] and not hidden else _paper()
	icon.modulate = Color(0.8, 0.8, 0.85) if hidden else KIND_TINT.get(kind, Color.WHITE)
	if state == RoomGame.STATE_CURSED:
		icon.modulate = Color(0.6, 0.35, 0.8)
	elif state == RoomGame.STATE_CONFLICT:
		icon.modulate = Color(1.0, 0.4, 0.4)
	row.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", -2)
	row.add_child(text_box)

	var label := _label(15, Color.WHITE, false)
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_box.add_child(label)
	if hidden:
		label.text = "%s · ?" % item["path"]
	else:
		label.text = str(item["name"])
		if kind == "curse":
			label.add_theme_color_override("font_color", Color("d6a8ff"))
		# ป้ายสถานะ: บอกว่าแผ่นนี้คืออะไรในภาษา Git (ตรงกับหมวดในผลของ git status)
		var git := str(item.get("git", ""))
		if git != "committed" and not git.is_empty():
			var tag := _label(15, STATE_TAG_COLORS.get(git, Color("cfd8e3")), true)
			tag.text = str(item.get("label", ""))
			tag.clip_text = true
			tag.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			text_box.add_child(tag)

	if state == RoomGame.STATE_CURSED or state == RoomGame.STATE_CONFLICT:
		var tw := row.create_tween().set_loops()
		tw.tween_property(row, "modulate:a", 0.55, 0.45)
		tw.tween_property(row, "modulate:a", 1.0, 0.45)
	return row


func _paper() -> Texture2D:
	return load(PAPER_TEXTURE) if ResourceLoader.exists(PAPER_TEXTURE) else null


## เศษคัมภีร์จาก asset minikhampri (ภาพ 480x270 ที่มีเศษเล็ก ๆ หนึ่งชิ้น) ตัดเฉพาะส่วนที่มีภาพ
func _shard(index: int) -> Texture2D:
	if _shard_cache.is_empty():
		for i in range(1, SHARD_COUNT + 1):
			var path := SHARD_TEXTURE_FORMAT % i
			if not ResourceLoader.exists(path):
				continue
			var texture: Texture2D = load(path)
			var image := texture.get_image()
			if image == null:
				continue
			var used := image.get_used_rect()
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(used)
			_shard_cache.append(atlas)
	if _shard_cache.is_empty():
		return _paper()
	return _shard_cache[index % _shard_cache.size()]


func _label(font_size: int, color: Color, bold: bool) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 3)
	var font := _font_bold if bold else _font_regular
	if font != null:
		label.add_theme_font_override("font", font)
	return label
