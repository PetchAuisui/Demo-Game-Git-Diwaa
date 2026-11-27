class_name RoomView
extends Control
## ภาพห้องในหอคอยกลางฉาก Sandbox: ผ้าปูเวทของเวล (working tree) · แท่นเตรียม (stage) · คัมภีร์ (commit)
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
	{"state": RoomGame.STATE_DESK, "title": "ผ้าปูเวท", "sub": "ยังไม่ปลอดภัย"},
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
const MEWLA_SHEETS := {
	"idle": "res://assets/cutscene/characters/mewla/mewla_idle-Sheet.png",
	"talk": "res://assets/cutscene/characters/mewla/mewla_talk-Sheet.png",
}
const MEWLA_FRAME := Vector2(47, 83)
const MEWLA_FRAMES := 6
const GATE_HINT := "ตอบผู้เฝ้าประตูด้วยคาถาในวงร่ายเวท — ทุกค่าที่ตั้งจะถูกจารึกบนบานประตู"
const BATTLE_HINT := "ร่ายคาถาให้ถูกก่อนศัตรูจะถึงตัว — ทุกการกระทำ ศัตรูขยับเข้ามาหนึ่งก้าว"

static var _shard_cache: Array[Texture2D] = []

var _font_bold: Font
var _font_regular: Font
var _frame: PanelContainer
var _hearts_label: Label
var _chaos_label: Label
var _chaos_bar: ProgressBar
var _dimension_label: Label
var _fragment_label: Label
var _zone_boxes: Dictionary = {}
var _furniture: Dictionary = {}     # state -> RoomFurniture (ผ้าปู / แท่นเตรียม / แท่นวางคัมภีร์)
var _stage: RoomSpellStage
var _fog: RoomFog
var _camera: RoomCamera
var _wake_layer: Control       # ใต้กล้อง: วงเวทบนแท่นและคลื่นแสงปลุกห้อง (ถูกซูมไปพร้อมห้อง)
var _essential: Array[String] = []
var _frame_style: StyleBoxFlat
## ห้องก่อน git init: หลับใหล (ผ้าปูยังม้วนอยู่ แท่นหินหม่น) จนกว่าคัมภีร์จะถือกำเนิด
var _dormant := false     # ห้องหลับใหล (ยังไม่มีคัมภีร์)
var _waking := false      # คาถาถือกำเนิดกำลังปลุกห้อง — หัวห้อง/มิติรอจนคัมภีร์ลงแท่น
var _pending_branch := "" # มิติที่รอแสดงตอนคัมภีร์ลงแท่น
var _room_seen := false
var _scene_until := 0.0   # ฉากคาถาใหญ่ (เช่น คัมภีร์ถือกำเนิด) เล่นถึงเวลานี้ — ป้ายฉลองรอให้ฉากจบก่อน   # วาดห้องครั้งแรกแล้วหรือยัง (ครั้งแรกแสดงทันที ไม่เล่นท่างอก)
var _dimension := ""
var _event_label: Label
var _flash: ColorRect
var _event_tween: Tween
var _zones: HBoxContainer
var _battle: BattleFieldView
var _lane: ChaosLaneView
var _in_battle := false
var _gate_mode := false
var _speak_bar: PanelContainer
var _speak_input: LineEdit
var _speak_title: Label
var _speak_button: Button
## ผู้ถาม (เช่น มิวรา) ที่โผล่มาถามคำตอบในห้อง — ว่าง = เอ่ยต่อหน้าวงเวท/ประตูตรง ๆ
var _ask_row: HBoxContainer
var _ask_portrait: TextureRect
var _ask_atlas: AtlasTexture
var _ask_name: Label
var _ask_line: Label
var _ask_frame := 0
var _ask_talk_left := 0.0
var _ask_tick := 0.0
var _asker: Dictionary = {}
## เอฟเฟกต์ pixel art (PixelFx) ลอยเหนือห้อง: ของขึ้นแท่น/เข้าคัมภีร์ เกิดใหม่ โดนคลื่น ได้รับโล่
var _fx_layer: Control
var _rows: Dictionary = {}          # path -> แถวของในห้อง (หาตำแหน่งเอฟเฟกต์)
var _last_states: Dictionary = {}   # path -> state ครั้งก่อน (รู้ว่าของเพิ่งขึ้นแท่น/เข้าคัมภีร์)
var _pending_fx: Array[Dictionary] = []  # เอฟเฟกต์ที่รอแถวของถูกวาดใหม่ก่อนจะรู้ตำแหน่ง
var _pending_flights: Array[Dictionary] = []  # ของที่ย้ายโซน: {path, from, effect} บินโค้งจากที่เดิมไปที่ใหม่
var _urgent := false  # คลื่นลูกหน้ามาในการกระทำถัดไป — ของที่ยังไม่ปลอดภัยสั่นถี่ขึ้น
var _safe_mode := "committed"


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
	if _waking:
		_pending_branch = branch # หัวห้องเปลี่ยนตอนคัมภีร์ลงแท่น ไม่ใช่ก่อน (ผลไม่มาก่อนเหตุ)
	else:
		_dimension_label.text = "มิติ: %s" % branch if not branch.is_empty() else "ยังไม่มีคัมภีร์"
	if game.has_battle():
		# ด่านต่อสู้: ไม่มีของให้ปกป้อง แสดงสนามรบแทนผ้าปู/แท่น/คัมภีร์
		if not _in_battle:
			_in_battle = true
			_gate_mode = not game.gate.is_empty()
			_show_idle_hint()
		_zones.visible = false
		_battle.visible = true
		_dimension_label.visible = false
		_battle.update_battle(game)
		_lane.visible = false
		return
	_urgent = game.has_waves() and game.turns_until_wave() <= 1
	_safe_mode = game.safe_mode
	_lane.update_lane(game, items)
	_update_furniture(game, items)
	_update_dormancy(game)
	_update_fog(game)
	if not _waking:
		_set_dimension(branch)

	var old_icons := {}
	for path in _rows:
		var old_row: Control = _rows[path]
		if is_instance_valid(old_row) and old_row.is_inside_tree() and old_row.get_child_count() > 0:
			var old_icon := old_row.get_child(0) as TextureRect
			old_icons[path] = {"rect": old_icon.get_global_rect(), "texture": old_icon.texture, "modulate": old_icon.modulate}
	_essential = game.essential
	for zone in _zone_boxes.values():
		for child in (zone as Container).get_children():
			child.queue_free()
	_rows.clear()
	var states := {}
	var index := 0
	for item in items:
		var state := str(item["state"])
		var path := str(item["path"])
		states[path] = state
		var zone_state := state
		if state == RoomGame.STATE_CURSED or state == RoomGame.STATE_CONFLICT:
			zone_state = RoomGame.STATE_DESK
		var box: Container = _zone_boxes.get(zone_state, null)
		if box != null:
			var row := _make_item(item, index)
			box.add_child(row)
			_rows[path] = row
		# ของเพิ่งย้ายโซน: ขึ้นแท่นเตรียม (add) = ประกายฟ้า · เข้าคัมภีร์ (commit) = ประกายทอง
		var before := str(_last_states.get(path, ""))
		if not before.is_empty() and before != state:
			var effect := ""
			if state == RoomGame.STATE_TOME:
				effect = "commit_sparkle"
			elif state == RoomGame.STATE_ALTAR:
				effect = "stage_sparkle"
			if old_icons.has(path) and box != null:
				# ของลอยโค้งจากที่เดิมไปที่ใหม่ แล้วค่อยเกิดประกายตอนลงถึง (เหตุ → ผล)
				_pending_flights.append({"path": path, "from": old_icons[path], "effect": effect})
			elif not effect.is_empty():
				_pending_fx.append({"effect": effect, "path": path})
		index += 1
	_last_states = states
	_flush_fx_next_frame()


## การ์ดเปิดขั้น: ป้ายชั้น + ชื่อขั้น + เป้าหมายแรก + ภัยของห้อง พุ่งลงมากลางห้องแล้วหายไปเอง
## (ไม่รับเมาส์ ไม่บังวงร่ายเวท) — ผู้เล่นรู้ทันทีว่าต้องทำอะไรและอะไรกำลังไล่ล่า
func show_intro(floor_text: String, title: String, goal: String, threat: String) -> void:
	if not is_inside_tree():
		return
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.14, 0.94)
	style.border_color = Color("ffd36b")
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(14)
	card.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 2)
	card.add_child(column)
	var lines := [[floor_text, 15, Color("c9b6ff")], [title, 30, Color("ffd36b")],
			["เป้าหมาย: " + goal, 18, Color("fff3d6")], [threat, 16, Color("ffb3c4")]]
	for line in lines:
		if str(line[0]).strip_edges().is_empty() or str(line[0]) == "เป้าหมาย: ":
			continue
		var label := _label(int(line[1]), line[2], true)
		label.text = str(line[0])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.clip_text = true
		column.add_child(label)
	_fx_layer.add_child(card)
	card.custom_minimum_size = Vector2(size.x * 0.7, 0)
	card.reset_size()
	await get_tree().process_frame
	if not is_instance_valid(card):
		return
	card.position = Vector2((size.x - card.size.x) * 0.5, -card.size.y)
	var rest := Vector2(card.position.x, size.y * 0.22)
	var tw := card.create_tween()
	tw.tween_property(card, "position", rest, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: _shake_frame(4.0))
	tw.tween_interval(2.6)
	tw.tween_property(card, "modulate:a", 0.0, 0.4)
	tw.tween_callback(card.queue_free)


## ป้ายลอยเมื่อทำเป้าหมายสำเร็จ: "สำเร็จ!" · ทำต่อเนื่องไม่โดนพลังกระแทก = คอมโบ · จบด่านหัวใจเต็ม = ไร้รอยแผล
func celebrate_objective(streak: int, finished: bool, flawless: bool) -> void:
	if not is_inside_tree():
		return
	var wait := _scene_until - Time.get_ticks_msec() / 1000.0
	if wait > 0.0:
		await get_tree().create_timer(wait).timeout
		if not is_inside_tree():
			return
	var text := "สำเร็จ!"
	var color := Color("9fe8b8")
	if finished and flawless:
		text = "ไร้รอยแผล!"
		color = Color("ffd36b")
	elif streak >= 2:
		text = "คอมโบ x%d!" % streak
		color = Color("ffd36b") if streak >= 3 else Color("8fd3ff")
	var label := _label(34 if finished or streak >= 3 else 28, color, true)
	label.add_theme_constant_override("outline_size", 8)
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(size.x, 48)
	label.position = Vector2(0, size.y * 0.34)
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE * 0.4
	_fx_layer.add_child(label)
	var tw := label.create_tween()
	tw.tween_property(label, "scale", Vector2.ONE * 1.15, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "scale", Vector2.ONE, 0.1)
	tw.tween_interval(0.5 if not finished else 1.1)
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 46.0, 0.6).set_ease(Tween.EASE_IN)
	tw.tween_property(label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(label.queue_free)
	var unit := maxf(1.0, round(size.y / 220.0))
	var at := Vector2(size.x * 0.5, size.y * 0.34 + 96)
	PixelFx.spawn(_fx_layer, "stage_sparkle" if streak < 3 and not finished else "commit_sparkle", at, unit * (1.4 if finished else 1.0))
	if finished and flawless:
		PixelFx.spawn(_fx_layer, "confetti", Vector2(size.x * 0.2, size.y), unit)
		PixelFx.spawn(_fx_layer, "confetti", Vector2(size.x * 0.8, size.y), unit, 0.0, true)


## ตัวนับเศษคัมภีร์ต้นกำเนิด (n/12) — แสดงเมื่อเรื่องดำเนินถึงการตามหาเศษแล้ว · gained = เพิ่งได้ชิ้นใหม่ (เด้ง)
func set_fragments(count: int, show: bool, gained: bool = false) -> void:
	_fragment_label.visible = show or count > 0
	_fragment_label.text = "✦ เศษคัมภีร์ %d/%d" % [count, FragmentLedger.TOTAL]
	if gained:
		_fragment_label.pivot_offset = _fragment_label.size * 0.5
		var tw := create_tween()
		tw.tween_property(_fragment_label, "scale", Vector2.ONE * 1.5, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_fragment_label, "scale", Vector2.ONE, 0.3)


## สีประจำมิติ: main ทองอุ่น · experiment ฟ้าจันทรา · trial เขียว · echo ม่วงเงา · อื่น ๆ ตามชื่อ
static func dimension_color(branch: String) -> Color:
	match branch:
		"", "main", "master":
			return Color("ebcb70")
		"experiment":
			return Color("8fd3ff")
		"trial":
			return Color("7ee8a8")
		"echo", "phantom":
			return Color("d6a8ff")
	return Color.from_hsv(float(branch.hash() % 360) / 360.0, 0.45, 1.0)


## มิติที่ยืนอยู่ย้อมกรอบห้องและแสงของคัมภีร์ — ข้ามมิติแล้วห้องเปลี่ยนสีให้เห็นทันที
func _set_dimension(branch: String) -> void:
	if branch == _dimension:
		return
	_dimension = branch
	var color := dimension_color(branch)
	if _frame_style != null:
		_frame_style.border_color = Color(color, 0.9)
	_dimension_label.add_theme_color_override("font_color", color.lightened(0.2))
	var pedestal: RoomFurniture = _furniture.get(RoomGame.STATE_TOME, null)
	if pedestal != null:
		pedestal.tint = color


## ห้องที่ยังไม่มีคัมภีร์ (ด่าน git init / ก่อน clone) หลับใหล: เฟอร์นิเจอร์ซีดเทา เทียนดับ หยากไย่ฝุ่นจับ
## กล้องซูมใกล้ที่แท่นวางคัมภีร์ที่ว่างเปล่า — ห้องตื่นเมื่อคาถาถือกำเนิดปลุก (begin_wake → wake_room → finish_wake)
func _update_dormancy(game: RoomGame) -> void:
	var dormant := not game.has_tome
	if not _room_seen:
		_room_seen = true
		_set_dormant(dormant)
		for state in _furniture:
			((_furniture[state] as RoomFurniture).get_parent() as Control).modulate.a = 1.0
	elif dormant and not _dormant:
		_set_dormant(true)
	elif not dormant and _dormant and not _waking:
		_set_dormant(false) # มีคัมภีร์โดยไม่มีฉากปลุก (เช่น เริ่มใหม่) — ตื่นทันที
	if _dormant:
		_place_fog.call_deferred()
		if not _camera.visible and not _waking:
			_camera.close_up()


func _set_dormant(on: bool) -> void:
	_dormant = on
	for state in _furniture:
		var furniture_node: RoomFurniture = _furniture[state]
		furniture_node.awake = 0.0 if on else 1.0
		var panel := furniture_node.get_parent() as Control
		panel.modulate = Color(0.78, 0.76, 0.85, panel.modulate.a) if on else Color(1, 1, 1, panel.modulate.a)
	(_furniture[RoomGame.STATE_TOME] as RoomFurniture).hold_tome = on
	if not on:
		_camera.visible = false


## คาถาถือกำเนิดเริ่มแล้ว: ห้องค้างสภาพหลับไว้ (หัวห้อง มิติ) จนกว่าคัมภีร์จะลงแท่น — คืน true ถ้าห้องหลับอยู่
func begin_wake() -> bool:
	if not _dormant:
		return false
	_waking = true
	return true


## คลื่นแสงแผ่จากแท่นวางคัมภีร์ไปทั่วห้อง ของแต่ละชิ้นตื่นเมื่อแสงผ่าน กล้องถอยกลับขนาดจริงในช่วงเดียวกัน
## คืนเวลาที่ใช้ (วินาที)
func wake_room() -> float:
	if not _dormant:
		return 0.0
	var seconds := 1.0
	_camera.pull_back(seconds)
	var pedestal: RoomFurniture = _furniture[RoomGame.STATE_TOME]
	var origin := pedestal.top_global()
	var farthest := 0.0
	for state in _furniture:
		var node: RoomFurniture = _furniture[state]
		farthest = maxf(farthest, origin.distance_to(node.global_position + node.size * 0.5))
	var ring := WakeRing.new()
	ring.center = origin - _wake_layer.global_position
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wake_layer.add_child(ring)
	var reach := farthest + 60.0
	var tw := ring.create_tween()
	tw.tween_property(ring, "radius", reach, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(ring.queue_free)
	for state in _furniture:
		var node: RoomFurniture = _furniture[state]
		var at := node.global_position + node.size * 0.5
		var delay := clampf(origin.distance_to(at) / reach, 0.0, 1.0)
		# เวลาที่แสงไปถึง (ประมาณการ ease-out ของวงแสง)
		var when := seconds * (1.0 - sqrt(1.0 - delay))
		var panel := node.get_parent() as Control
		get_tree().create_timer(when).timeout.connect(func() -> void:
			node.wake(0.35)
			create_tween().tween_property(panel, "modulate", Color(1, 1, 1, panel.modulate.a), 0.35)
			spawn_under_camera("dust_puff", node.top_global() + Vector2(0, -4), fx_unit() * 0.6))
	return seconds


## คัมภีร์ลงแท่นแล้ว: ห้องตื่นเต็มที่ หัวห้องและสีมิติเปลี่ยนตอนนี้
func finish_wake() -> void:
	if not _waking:
		return
	_waking = false
	_dormant = false
	_camera.visible = false
	_dimension_label.text = "มิติ: %s" % _pending_branch if not _pending_branch.is_empty() else "ยังไม่มีคัมภีร์"
	_set_dimension(_pending_branch)


## วางเอฟเฟกต์ใต้กล้อง (ถูกซูมไปพร้อมห้อง) ที่ตำแหน่ง global
func spawn_under_camera(effect: String, global_point: Vector2, scale_by: float, start_seconds: float = 0.0) -> PixelFx:
	return PixelFx.spawn(_wake_layer, effect, global_point - _wake_layer.global_position, scale_by, start_seconds)


## จุด global ในห้องปรากฏตรงไหนบนจอตอนนี้ (ถ้ากล้องซูมอยู่) — พิกัดชั้นเอฟเฟกต์ สำหรับเล็งสิ่งที่วาดทับกล้อง
func camera_point(global_point: Vector2) -> Vector2:
	if _camera == null or not _camera.visible:
		return to_fx(global_point)
	return to_fx(_zones.global_position + _camera.to_view(global_point - _zones.global_position))


## ฉากคาถาใหญ่ยังเล่นอยู่อีกกี่วินาที (แผงภารกิจ "สำเร็จ" รอให้จบก่อน)
func scene_remaining() -> float:
	return maxf(0.0, _scene_until - Time.get_ticks_msec() / 1000.0)


## คลิกในห้องระหว่างฉากใหญ่ = เร่งให้จบเร็วขึ้น (สำหรับคนเล่นซ้ำ)
func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed) or scene_remaining() <= 0.0 or not is_visible_in_tree():
		return
	if not get_global_rect().has_point((event as InputEventMouseButton).global_position):
		return
	var left := scene_remaining()
	Engine.time_scale = 3.0
	_scene_until = Time.get_ticks_msec() / 1000.0 + left / 3.0
	get_tree().create_timer(left / 3.0, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)


## ห้องมืด (blind): หมอกคลุมโซนทั้งสามจนกว่าจะหยั่งสถานะ แล้วแสงตะเกียงกวาดหมอกหาย
func _update_fog(game: RoomGame) -> void:
	var dark := game.blind and not game.revealed
	if dark and not _fog.visible:
		_fog.cover()
	elif not dark and _fog.visible:
		_fog.reveal()
	_place_fog.call_deferred()


func _place_fog() -> void:
	if _zones == null or not is_inside_tree():
		return
	_fog.position = _zones.global_position - global_position
	_fog.size = _zones.size
	_camera.position = _fog.position
	_camera.size = _zones.size
	_wake_layer.size = size
	var pedestal: RoomFurniture = _furniture.get(RoomGame.STATE_TOME, null)
	if pedestal != null:
		_camera.focus = pedestal.top_global() - _zones.global_position


## ผนึกที่รอคำตอบในลาน (ประตูหินด่าน 6 · วงอักขระด่าน 7) — kind "" = ไม่มี
func set_seal(kind: String, opened: bool) -> void:
	if _lane != null:
		_lane.set_seal(kind, opened)


## ตำแหน่งไอคอนของในห้อง (พิกัดชั้นเอฟเฟกต์) — Vector2.INF ถ้าไม่มีแถวนั้น
func row_point(path: String) -> Vector2:
	var row: Control = _rows.get(path, null)
	if row == null or not is_instance_valid(row) or not row.is_inside_tree() or row.get_child_count() == 0:
		return Vector2.INF
	var icon := row.get_child(0) as Control
	return to_fx(icon.global_position + icon.size * 0.5)


func _update_furniture(game: RoomGame, items: Array[Dictionary]) -> void:
	var altar: RoomFurniture = _furniture[RoomGame.STATE_ALTAR]
	altar.staged = items.filter(func(item: Dictionary) -> bool: return item["state"] == RoomGame.STATE_ALTAR).size()
	# คลื่นมาในการกระทำถัดไป: ผ้าปู/แท่นที่มีของเสี่ยงสั่นกึก ๆ
	var risky := func(item: Dictionary, zone: String) -> bool:
		if not str(item.get("kind", "")) in ["fragment", "key"] or item.get("hidden", false):
			return false
		var state := str(item["state"])
		if zone == RoomGame.STATE_DESK:
			return state == RoomGame.STATE_DESK or state == RoomGame.STATE_CURSED
		return state == RoomGame.STATE_ALTAR and game.safe_mode != "staged"
	var desk: RoomFurniture = _furniture[RoomGame.STATE_DESK]
	desk.urgent = _urgent and items.any(func(item: Dictionary) -> bool: return risky.call(item, RoomGame.STATE_DESK))
	altar.urgent = _urgent and items.any(func(item: Dictionary) -> bool: return risky.call(item, RoomGame.STATE_ALTAR))
	altar.shield = game.safe_mode == "staged"
	var pedestal: RoomFurniture = _furniture[RoomGame.STATE_TOME]
	pedestal.has_tome = game.has_tome
	pedestal.pages = game.page_count
	pedestal.max_pages = game.max_commits


## ผลของคาถาที่ร่ายสำเร็จ (จาก SpellEffectDetector) → ฉากในห้องตรงเฟอร์นิเจอร์/ลาน — ห้องต่อสู้ใช้สนามรบของตัวเอง
func cast(effects: Array[Dictionary], command: String, snapshot: GitRepositorySnapshot = null) -> void:
	if _in_battle or not is_inside_tree():
		return
	if effects.is_empty() and not command.begins_with("git remote"):
		return
	if _stage == null:
		_stage = RoomSpellStage.new(self)
	_stage.play(effects, command, snapshot)


## ฉากคาถาที่กำลังเล่นจะยาวอีกกี่วินาที (ป้ายฉลองเป้าหมายรอจนจบ ไม่ทับกัน)
func hold_scene(seconds: float) -> void:
	_scene_until = maxf(_scene_until, Time.get_ticks_msec() / 1000.0 + seconds)


## ป้ายชื่อคาถาในห้อง (ชื่อในโลกเวท + ความหมาย Git) — ขึ้นตอนที่ผลเกิดจริง ซ้อนลงมาถ้ามีหลายป้าย
var _announced := 0
func announce(effect: Dictionary) -> void:
	if not is_inside_tree() or _in_battle:
		return
	var kind := int(effect.get("kind", -1))
	var color: Color = SpellEffectOverlay.COLORS.get(kind, Color.WHITE)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", -2)
	var title := _label(26, color, true)
	title.text = str(effect.get("title", ""))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 6)
	box.add_child(title)
	var meaning := _label(14, Color(1, 1, 1, 0.85), false)
	var detail := str(effect.get("detail", ""))
	meaning.text = str(effect.get("meaning", "")) + ("" if detail.is_empty() else " · " + detail.left(40))
	meaning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(meaning)
	_fx_layer.add_child(box)
	var top := zone_rect(RoomGame.STATE_DESK).position.y + 34.0 + _announced * 52.0
	box.size = Vector2(size.x, 0)
	box.position = Vector2(0, top)
	box.pivot_offset = Vector2(size.x * 0.5, 20)
	box.scale = Vector2.ONE * 0.6
	_announced += 1
	var tw := box.create_tween()
	tw.tween_property(box, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.4)
	tw.set_parallel(true)
	tw.tween_property(box, "modulate:a", 0.0, 0.45)
	tw.tween_property(box, "position:y", top - 14.0, 0.45)
	tw.chain().tween_callback(func() -> void:
		_announced = maxi(0, _announced - 1)
		box.queue_free())


func fx_layer() -> Control:
	return _fx_layer


func furniture(state: String) -> RoomFurniture:
	return _furniture.get(state, null)


func lane() -> ChaosLaneView:
	return _lane


func zone_rect(state: String) -> Rect2:
	var furniture_node: RoomFurniture = _furniture.get(state, null)
	if furniture_node == null:
		return Rect2()
	var panel := furniture_node.get_parent() as Control
	return Rect2(panel.global_position - _fx_layer.global_position, panel.size)


## พิกัด global → พิกัดในชั้นเอฟเฟกต์
func to_fx(global_point: Vector2) -> Vector2:
	return global_point - _fx_layer.global_position


func fx_unit() -> float:
	return maxf(1.0, round(size.y / 220.0))


func shake(strength: float) -> void:
	_shake_frame(strength)


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
	else:
		_queue_room_fx(events)
		_lane.play(events)
	if has_damage:
		_break_heart()
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
		if not _in_battle:
			_shake_frame(8.0)


## เหตุการณ์ในห้อง (ไม่ใช่ด่านต่อสู้) → เอฟเฟกต์ pixel art ตรงของชิ้นนั้น
## ของที่เพิ่งเกิดยังไม่มีแถวในห้อง จึงรอจนห้องวาดใหม่ (หรือไม่เกินครึ่งวินาที) ค่อยหาตำแหน่ง
func _queue_room_fx(events: Array[Dictionary]) -> void:
	for event in events:
		var path := str(event.get("path", ""))
		match str(event["type"]):
			"wave":
				_pending_fx.append({"effect": "chaos_wave", "path": ""})
			"damage":
				_pending_fx.append({"effect": "damage", "path": path})
			"shielded":
				_pending_fx.append({"effect": "shield", "path": path})
			"spawn", "respawn":
				_pending_fx.append({"effect": "stage_sparkle", "path": path, "small": true})
	if not _pending_fx.is_empty():
		get_tree().create_timer(0.5).timeout.connect(_flush_fx)


## หัวใจดวงสุดท้ายในแถบแตกกระจาย (pixel art) ตรงตำแหน่งหัวใจที่เพิ่งหายไป
func _break_heart() -> void:
	if _hearts_label == null or not is_inside_tree():
		return
	var lost := maxi(0, _hearts_label.text.count("♥") - 1) # ยังเป็นจำนวนก่อนโดน (ห้องวาดใหม่หลังเหตุการณ์)
	await get_tree().process_frame
	var char_w := _hearts_label.size.x / maxf(1.0, float(_hearts_label.text.length()))
	var at := _hearts_label.global_position - _fx_layer.global_position \
			+ Vector2(char_w * (lost * 2 + 0.5), _hearts_label.size.y * 0.5)
	PixelFx.spawn(_fx_layer, "heart_lost", at, maxf(1.0, round(size.y / 300.0)))


func _flush_fx_next_frame() -> void:
	if (_pending_fx.is_empty() and _pending_flights.is_empty()) or not is_inside_tree():
		return
	await get_tree().process_frame
	_flush_fx()
	_fly_items()


## ของที่ย้ายโซน (add / commit / restore --staged / reset) บินโค้งข้ามห้อง — ตัวจริงซ่อนไว้จนสำเนาลงถึง
func _fly_items() -> void:
	var unit := maxf(1.0, round(size.y / 220.0))
	for flight in _pending_flights:
		var row: Control = _rows.get(str(flight["path"]), null)
		if row == null or not is_instance_valid(row) or not row.is_inside_tree():
			continue
		var icon := row.get_child(0) as TextureRect
		var from: Dictionary = flight["from"]
		var start: Rect2 = from["rect"]
		var origin := _fx_layer.global_position
		var ghost := TextureRect.new()
		ghost.texture = icon.texture
		ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost.size = start.size
		ghost.pivot_offset = start.size * 0.5
		ghost.modulate = icon.modulate
		_fx_layer.add_child(ghost)
		var a := start.position - origin
		var b := icon.global_position - origin
		# โค้งขึ้นแต่ไม่ล้นขอบบนของห้อง
		var lift := -minf(absf(b.x - a.x) * 0.3, maxf(12.0, minf(a.y, b.y) - 8.0))
		icon.modulate.a = 0.0
		var effect := str(flight["effect"])
		var land := func() -> void:
			if is_instance_valid(icon):
				icon.modulate.a = 1.0
				var pop := icon.create_tween()
				icon.pivot_offset = icon.size * 0.5
				pop.tween_property(icon, "scale", Vector2(1.35, 0.75), 0.06)
				pop.tween_property(icon, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			if not effect.is_empty():
				PixelFx.spawn(_fx_layer, effect, b + Vector2(icon.size.x * 0.5, icon.size.y), unit)
			ghost.queue_free()
		var tw := ghost.create_tween()
		tw.tween_method(func(t: float) -> void:
			var k := ease(t, 0.6)
			ghost.position = a.lerp(b, k) + Vector2(0, lift * 4.0 * t * (1.0 - t))
			ghost.rotation = sin(t * PI) * 0.5
			ghost.scale = Vector2.ONE * (1.0 + 0.6 * sin(t * PI)), 0.0, 1.0, 0.42)
		tw.tween_callback(land)
	_pending_flights.clear()


func _flush_fx() -> void:
	if not is_inside_tree():
		_pending_fx.clear()
		return
	var unit := maxf(1.0, round(size.y / 220.0))
	for fx in _pending_fx:
		var at := size * 0.5
		var row: Control = _rows.get(str(fx["path"]), null)
		if row != null and is_instance_valid(row) and row.is_inside_tree():
			# ใต้ไอคอนของ (ซ้ายของแถว) — pivot ของเอฟเฟกต์ส่วนใหญ่คือพื้น
			at = row.global_position - _fx_layer.global_position + Vector2(18, row.size.y)
		var scale_by := unit * (0.6 if fx.get("small", false) else 1.0)
		if fx["effect"] == "chaos_wave":
			scale_by = unit * 1.6
		PixelFx.spawn(_fx_layer, str(fx["effect"]), at, scale_by)
	_pending_fx.clear()


## สั่นกรอบห้องทั้งกรอบ แรงลดลงเรื่อย ๆ (สนามรบขอผ่าน shake_requested ตอนการโจมตีชนจริง)
var _shake_tween: Tween
func _shake_frame(strength: float) -> void:
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	_shake_tween = create_tween()
	var steps := 7
	for i in steps:
		var k := strength * (1.0 - float(i) / steps)
		_shake_tween.tween_property(_frame, "position", Vector2(randf_range(-k, k), randf_range(-k, k) * 0.6), 0.035)
	_shake_tween.tween_property(_frame, "position", Vector2.ZERO, 0.04)


func _show_idle_hint() -> void:
	_event_label.text = (GATE_HINT if _gate_mode else BATTLE_HINT) if _in_battle else IDLE_HINT
	_event_label.add_theme_color_override("font_color", Color("e8dcc0"))
	_event_label.modulate.a = IDLE_ALPHA


func _build() -> void:
	_frame = PanelContainer.new()
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.1, 0.78)
	style.border_color = Color(0.75, 0.6, 0.3, 0.9)
	_frame_style = style
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
	_fragment_label = _label(18, Color("ffd36b"), true)
	_fragment_label.visible = false
	_fragment_label.pivot_offset = Vector2(60, 12)
	header.add_child(_fragment_label)
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
	# ยังไม่รู้ว่าห้องหลับหรือตื่น — ซ่อนโซนไว้ก่อนจนกว่าจะวาดห้องครั้งแรก (ไม่ให้สภาพผิดโผล่แวบ)
	for state in _furniture:
		((_furniture[state] as RoomFurniture).get_parent() as Control).modulate.a = 0.0
	_lane = ChaosLaneView.new()
	_lane.visible = false
	root.add_child(_lane)
	_battle = BattleFieldView.new()
	_battle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_battle.visible = false
	_battle.shake_requested.connect(_shake_frame)
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

	_fog = RoomFog.new()
	_fog.visible = false
	add_child(_fog)
	_wake_layer = Control.new()
	_wake_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_wake_layer)
	_camera = RoomCamera.new()
	_camera.visible = false
	add_child(_camera)

	_fx_layer = Control.new()
	_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fx_layer)


## แสดง/ซ่อนช่องเอ่ยคำ (แสดงเฉพาะตอนที่โลกรอคำตอบอยู่)
## asker = {"name", "question", "placeholder"} — มีผู้ถาม (มิวรา) โผล่มาถาม แล้วผู้เล่นพิมพ์ตอบเธอ
func set_speaking(active: bool, asker: Dictionary = {}) -> void:
	if _speak_bar == null:
		return
	var changed := _speak_bar.visible != active or (active and asker != _asker)
	_asker = asker if active else {}
	_apply_asker()
	if not changed:
		return
	_speak_bar.visible = active
	if active:
		_speak_bar.modulate.a = 0.0
		create_tween().tween_property(_speak_bar, "modulate:a", 1.0, 0.3)
		if not _asker.is_empty():
			_asker_talk(str(_asker.get("question", "")))
			_speak_input.grab_focus.call_deferred()


## ผู้ถามพูดตอบ (เช่น ตอบผิด มิวราทัก) — ไม่มีผู้ถามก็ไม่ทำอะไร
## คำถามของผู้เฝ้าประตู (คำตอบคือคาถา Git ในวงร่ายเวท ไม่ใช่การพิมพ์ในห้อง)
func set_guard_line(text: String) -> void:
	if _battle != null:
		_battle.set_guard_line(text)


func asker_reply(text: String) -> void:
	if _asker.is_empty() or text.is_empty():
		return
	_asker_talk(text)
	var tween := create_tween()
	tween.tween_property(_ask_row, "position:x", _ask_row.position.x + 8, 0.05)
	tween.tween_property(_ask_row, "position:x", _ask_row.position.x - 8, 0.08)
	tween.tween_property(_ask_row, "position:x", _ask_row.position.x, 0.05)


func has_asker() -> bool:
	return not _asker.is_empty()


func _apply_asker() -> void:
	var asking := not _asker.is_empty()
	_ask_row.visible = asking
	_speak_title.text = "✦ ตอบ%s" % str(_asker.get("name", "")) if asking else "✦ เอ่ยคำ"
	_speak_button.text = "ตอบ" if asking else "เอ่ย"
	_speak_input.placeholder_text = str(_asker.get("placeholder", "พิมพ์คำตอบ แล้วกด Enter")) if asking \
		else "พิมพ์คำที่จะเอ่ยต่อหน้าวงเวท/ประตู แล้วกด Enter (เอ่ยผิดพลังจะสะท้อนกลับ)"
	_ask_name.text = str(_asker.get("name", ""))


func _asker_talk(text: String) -> void:
	_ask_line.text = text
	_ask_line.visible_ratio = 0.0
	var tween := create_tween()
	tween.tween_property(_ask_line, "visible_ratio", 1.0, clampf(text.length() * 0.025, 0.3, 1.6))
	_ask_talk_left = clampf(text.length() * 0.04, 1.0, 2.6)


func _process(delta: float) -> void:
	if _ask_row == null or not _ask_row.is_visible_in_tree():
		return
	_ask_tick += delta
	if _ask_tick < 0.16:
		return
	_ask_tick = 0.0
	_ask_talk_left = maxf(0.0, _ask_talk_left - 0.16)
	_ask_frame = (_ask_frame + 1) % MEWLA_FRAMES
	var sheet: String = MEWLA_SHEETS["talk"] if _ask_talk_left > 0.0 else MEWLA_SHEETS["idle"]
	if ResourceLoader.exists(sheet):
		_ask_atlas.atlas = load(sheet)
	_ask_atlas.region = Rect2(Vector2(MEWLA_FRAME.x * _ask_frame, 0), MEWLA_FRAME)


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
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	_speak_bar.add_child(column)
	_build_ask_row(column)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)
	var title := _label(18, Color("ffd36b"), true)
	title.text = "✦ เอ่ยคำ"
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(title)
	_speak_title = title
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
	_speak_button = button


## แถวผู้ถาม: รูปมิวรา (ขยับปากตอนพูด) + ชื่อ + คำถามในกรอบคำพูด
func _build_ask_row(column: VBoxContainer) -> void:
	_ask_row = HBoxContainer.new()
	_ask_row.visible = false
	_ask_row.add_theme_constant_override("separation", 12)
	column.add_child(_ask_row)
	_ask_atlas = AtlasTexture.new()
	if ResourceLoader.exists(MEWLA_SHEETS["idle"]):
		_ask_atlas.atlas = load(MEWLA_SHEETS["idle"])
	_ask_atlas.region = Rect2(Vector2.ZERO, MEWLA_FRAME)
	_ask_portrait = TextureRect.new()
	_ask_portrait.texture = _ask_atlas
	_ask_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ask_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ask_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ask_portrait.custom_minimum_size = Vector2(70, 122)
	_ask_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ask_row.add_child(_ask_portrait)
	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f6ead0")
	style.border_color = Color("8a5a2b")
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 6
	style.content_margin_bottom = 8
	bubble.add_theme_stylebox_override("panel", style)
	_ask_row.add_child(bubble)
	var text_box := VBoxContainer.new()
	text_box.add_theme_constant_override("separation", 0)
	bubble.add_child(text_box)
	_ask_name = _label(16, Color("b0532a"), true)
	_ask_name.add_theme_constant_override("outline_size", 0)
	text_box.add_child(_ask_name)
	_ask_line = _label(18, Color("3a2614"), false)
	_ask_line.add_theme_constant_override("outline_size", 0)
	_ask_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(_ask_line)


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

	# เฟอร์นิเจอร์อยู่ใต้รายการของ (ลูกตัวแรกของ PanelContainer วาดก่อน)
	var furniture := RoomFurniture.new()
	furniture.kind = {RoomGame.STATE_DESK: RoomFurniture.Kind.DESK, RoomGame.STATE_ALTAR: RoomFurniture.Kind.ALTAR,
			RoomGame.STATE_TOME: RoomFurniture.Kind.PEDESTAL}[zone["state"]]
	panel.add_child(furniture)
	_furniture[zone["state"]] = furniture
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
	if not hidden and kind == "curse":
		# หมอกคำสาปวนรอบม้วน — ดูก็รู้ว่าห้ามแตะ
		PixelFx.spawn(icon, "curse_aura", Vector2(15, 30), 0.42, randf() * 2.0)
	var at_risk := kind in ["fragment", "key"] and (state == RoomGame.STATE_DESK or state == RoomGame.STATE_CURSED \
			or (state == RoomGame.STATE_ALTAR and _safe_mode != "staged"))
	if not hidden and at_risk:
		# ของที่คลื่นลูกหน้าจะทำร้ายสั่นอยู่บนผ้าปู — ยิ่งคลื่นใกล้ยิ่งสั่นถี่
		icon.pivot_offset = Vector2(15, 28)
		var period := 0.07 if _urgent else 0.32
		var swing := 0.22 if _urgent else 0.08
		var wobble := icon.create_tween().set_loops()
		wobble.tween_property(icon, "rotation", swing, period)
		wobble.tween_property(icon, "rotation", -swing, period * 2.0)
		wobble.tween_property(icon, "rotation", 0.0, period)
	elif not hidden and state == RoomGame.STATE_TOME and kind in ["fragment", "key"]:
		var glow := icon.create_tween().set_loops()
		glow.tween_property(icon, "self_modulate", Color(1.35, 1.25, 0.9), 0.9).set_trans(Tween.TRANS_SINE)
		glow.tween_property(icon, "self_modulate", Color.WHITE, 0.9).set_trans(Tween.TRANS_SINE)

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
		if _essential.has(path):
			# ของที่ห้ามหาย (เช่น reset --hard จะลบทิ้ง) มีดาวทองกำกับ
			label.text = "★ " + label.text
			label.add_theme_color_override("font_color", Color("ffd36b"))
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


## คลื่นแสงปลุกห้อง: วงแหวนพิกเซลสีทองแผ่ออกจากแท่นวางคัมภีร์ ด้านในเรืองจาง ๆ
class WakeRing extends Control:
	var center := Vector2.ZERO
	var radius := 0.0:
		set(value):
			radius = value
			queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var steps := maxi(24, int(radius * 0.25))
		for i in steps:
			var a := TAU * i / steps
			var p := (center + Vector2(cos(a), sin(a) * 0.55) * radius).round()
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(1.0, 0.85, 0.45, 0.8))
			draw_rect(Rect2(p - Vector2(5, 1), Vector2(10, 2)), Color(1.0, 0.85, 0.45, 0.25))
		var inner := radius * 0.8
		for i in steps:
			var a := TAU * (i + 0.5) / steps
			var p := (center + Vector2(cos(a), sin(a) * 0.55) * inner).round()
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.9, 0.6, 0.3))
