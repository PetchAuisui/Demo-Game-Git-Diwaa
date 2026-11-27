class_name ChaosLaneView
extends Control
## ลานโกลาหล: พื้นห้องใต้ผ้าปู/แท่น/คัมภีร์ ที่ทำให้กฎของห้อง "มองเห็นได้" แบบเกม
##   • ประตูโกลาหล (ซ้าย) พ่นภูตออกมา ภูตคลานเข้าหาผ้าปูตามมาตรวัดคลื่น — ถึงผ้าปูเมื่อคลื่นมา
##   • จำนวนภูต = จำนวนของที่คลื่นลูกหน้าจะทำร้าย (ของยังไม่จารึก คำสาปบนแท่น/ในคัมภีร์ มิติผี ฯลฯ)
##     ไม่มีอะไรให้ทำร้าย ภูตจะง่วงซึม — ผู้เล่นเห็นทันทีว่าทำถูกแล้ว
##   • มิติผี (branch ที่ต้องลบ) ลอยวนเป็นผี · คลังเวท (sync_required) เป็นประตูทองที่หม่นลงเมื่อไม่ตรงกัน
##   • เวลยืนเฝ้าคัมภีร์ทางขวา สะดุ้งเมื่อโดนพลังกระแทก
## เป็นภาพสะท้อนของ RoomGame อย่างเดียว ไม่มีผลต่อกฎ — ลำดับการวาดตามลำดับ node (ไม่ใช้ z_index)

const VEL_TEXTURE := "res://assets/cutscene/characters/vel/vel_Hblue_Sredyellow_idle.png"
const VEL_HURT_TEXTURE := "res://assets/cutscene/characters/vel/vel_shockpng.png"
const FONT_BOLD := "res://assets/fonts/ChakraPetch-Bold.ttf"
const MAX_IMPS := 4
const CHAOS := Color("b06bff")
const FLOOR_UNITS := 6.0      # ความหนาของพื้นหิน (หน่วยพิกเซล)
const FLOOR_MARGIN := 6.0     # ระยะพื้นจากขอบการ์ด

var _font: Font
var _panel: StyleBoxFlat
var _back: Node2D
var _actors: Node2D
var _fx: Node2D
var _vel: Sprite2D
var _vel_idle: Texture2D
var _vel_hurt_tex: Texture2D
var _portal: PixelFx
var _vault: PixelFx
var _imps: Array[PixelFx] = []
var _ghosts: Array[PixelFx] = []
var _progress := 0.0          # 0 = เพิ่งออกจากประตู · 1 = ถึงผ้าปู (คลื่นมา)
var _shown_progress := 0.0
var _threat := 0
var _has_waves := false
var _sync_text := ""
var _bare := false            # ยังไม่มีคัมภีร์ (needs_tome) — เวลไม่มีอะไรคุ้มกัน
var _caption := ""
var _hidden := false          # ห้องมืด (blind) ยังไม่ได้หยั่งสถานะ — ไม่บอกว่าอะไรปลอดภัย
var _time := 0.0
var _vel_hurt := 0.0
var _lunge := 0.0             # ภูตกระโจน (ตอนคลื่นมา)
var _cast := 0.0              # เวลย่อตัวร่ายคาถา
var _scatter := 0.0           # ภูตกระเด็นถอยหนีแสงคาถา
## ผนึกที่รอคำตอบ (เอ่ยคำในห้อง): "door" ประตูหินผนึก (ด่าน 6) · "runes" วงอักขระ (ด่าน 7) · "" ไม่มี
var _seal_kind := ""
var _seal_open := 0.0
var _seal_target := 0.0
var _seal_zap := 0.0
var _seal_circle: PixelFx
## มิติอื่นที่มีอยู่ (branch ที่ไม่ได้ยืนอยู่) เป็นรอยแยกเล็ก ๆ บนพื้นลาน พร้อมชื่อ — name -> PixelFx
var _rifts: Dictionary = {}
var _rift_names: Array[String] = []
var _blink := 0.0             # เวลหายวับ/ปรากฏตอนข้ามมิติ
var _vault_flare := 0.0
var _holy := 0.0              # แสงของคัมภีร์ที่เพิ่งถือกำเนิดกวาดลาน (1 → 0) เผาภูตที่มันผ่าน
var _hold := 0.0              # ช่วงที่ภูตยังไม่หายไปเอง (รอแสงคัมภีร์มาเผา) — วินาที
var _deferred: Array = []     # [game, described] ที่มาระหว่างรอแสงเผา — ใช้เมื่อแสงกวาดจบ
var _calm := 0.0              # ประตูโกลาหลสงบลง (หดและหม่น) เมื่อไม่มีอะไรให้ทำลาย — 0..1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	custom_minimum_size = Vector2(0, 110)
	_font = load(FONT_BOLD) if ResourceLoader.exists(FONT_BOLD) else ThemeDB.fallback_font
	# การ์ดเดียวกับโซนผ้าปู/แท่น/คัมภีร์ด้านบน — ลานเป็นส่วนหนึ่งของห้อง ไม่ใช่เส้นลอย ๆ
	_panel = StyleBoxFlat.new()
	_panel.bg_color = Color(1, 1, 1, 0.05)
	_panel.border_color = Color(1, 1, 1, 0.15)
	_panel.set_border_width_all(2)
	_panel.set_corner_radius_all(10)
	_back = Node2D.new()
	add_child(_back)
	_actors = Node2D.new()
	add_child(_actors)
	_vel_idle = load(VEL_TEXTURE) if ResourceLoader.exists(VEL_TEXTURE) else null
	_vel_hurt_tex = load(VEL_HURT_TEXTURE) if ResourceLoader.exists(VEL_HURT_TEXTURE) else _vel_idle
	_vel = Sprite2D.new()
	_vel.texture = _vel_idle
	_vel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_vel.centered = false
	_vel.flip_h = true # หันหน้าเข้าหาประตูโกลาหลทางซ้าย
	add_child(_vel)
	_fx = Node2D.new()
	add_child(_fx)
	resized.connect(_layout)


## ขนาดพิกเซลแบบจำนวนเต็ม ให้ pixel art คมเท่ากันทุกจอ
func _unit() -> float:
	return maxf(1.0, round(size.y / 50.0))


## ระดับผิวพื้นหิน (ภูต ประตู และเวลยืนบนเส้นนี้)
func _ground() -> float:
	return size.y - FLOOR_MARGIN - FLOOR_UNITS * _unit()


func _portal_x() -> float:
	return 34.0 * _unit()


## จุดที่ภูตไปถึงตอนคลื่นมา = กลางโซนผ้าปู/แท่น (ครึ่งซ้ายของห้อง)
func _target_x() -> float:
	return size.x * 0.42


func _vel_x() -> float:
	return size.x - 40.0 * _unit()


func update_lane(game: RoomGame, described: Array[Dictionary]) -> void:
	if _hold > 0.0 or _holy > 0.0:
		# ภูตยังรอแสงคัมภีร์มาเผา: ลานยังคงสภาพเดิม (ภูต ประตู คำบรรยาย) จนกว่าแสงกวาดจบ — เหตุมาก่อนผล
		_deferred = [game, described]
		return
	_has_waves = game.has_waves()
	visible = _has_waves or not game.phantoms.is_empty() or game.sync_required
	if not visible:
		return
	_hidden = game.blind and not game.revealed
	# ห้องมืด: ไม่รู้ว่าอะไรเสี่ยง จึงแสดงภูตหนึ่งตัวที่ตื่นอยู่เสมอ (ไม่หลอกว่าปลอดภัย)
	_threat = 1 if _hidden else game.threat_count(described)
	_sync_text = game.sync_text
	_bare = game.needs_tome and not game.has_tome
	if _has_waves:
		var left := game.turns_until_wave()
		_progress = clampf(float(game.wave_every - left) / maxf(1.0, float(game.wave_every - 1)), 0.0, 1.0)
	_ensure_portals(game)
	_sync_imps()
	_sync_ghosts(game.active_phantoms)
	_sync_rifts(game)
	_caption = _make_caption(game)
	_layout()
	queue_redraw()


func _make_caption(game: RoomGame) -> String:
	if _hidden:
		return "ห้องมืดเกินกว่าจะเห็นว่าภูตจ้องอะไร — หยั่งสถานะก่อน"
	if not game.active_phantoms.is_empty():
		return "มิติผี %s ดูดพลังทุกคลื่น" % ", ".join(game.active_phantoms)
	if _bare:
		return "ยังไม่มีคัมภีร์ — คลื่นจะซัดใส่เวลตรง ๆ"
	if not _sync_text.is_empty():
		return "คลังเวทไม่ตรงกับคัมภีร์ของนาย"
	if _holy > 0.0:
		return "แสงของคัมภีร์เผาภูตจนสิ้นซาก!"
	if _threat == 0:
		return "ประตูโกลาหลสงบลง — ไม่มีอะไรให้ภูตทำลาย"
	return "ภูต %d ตัวจ้องของที่ยังไม่ปลอดภัย" % mini(_threat, MAX_IMPS)


func _ensure_portals(game: RoomGame) -> void:
	if _has_waves and _portal == null:
		_portal = PixelFx.spawn(_back, "chaos_portal", Vector2.ZERO, 1.0)
	if game.sync_required and _vault == null:
		_vault = PixelFx.spawn(_back, "vault_portal", Vector2.ZERO, 1.0)


## ภูตหนึ่งตัวต่อของที่ตกอยู่ในอันตราย (อย่างน้อยหนึ่งตัวถ้าห้องมีคลื่น ให้เห็นจังหวะคลื่นเสมอ)
func _sync_imps() -> void:
	# ไม่มีของให้ทำลาย = ไม่มีภูต (ประตูสงบ) — ผู้เล่นเห็นทันทีว่าทำถูกแล้ว
	var want := clampi(_threat, 0, MAX_IMPS) if _has_waves else 0
	while _imps.size() < want:
		var imp := PixelFx.spawn(_actors, "imp_idle", Vector2(_portal_x(), _ground()), _unit() * 0.6, randf() * 1.5)
		if imp == null:
			break
		_imps.append(imp)
		PixelFx.spawn(_fx, "imp_poof", Vector2(_portal_x(), _ground()), _unit() * 0.5)
	while _imps.size() > want and _holy <= 0.0 and _hold <= 0.0: # ระหว่างรอ/แสงกวาด ปล่อยให้แสงเผาภูตเอง
		var imp: PixelFx = _imps.pop_back()
		PixelFx.spawn(_fx, "imp_poof", imp.position, _unit() * 0.5)
		imp.queue_free()


func _sync_ghosts(names: Array[String]) -> void:
	while _ghosts.size() < names.size():
		var ghost := PixelFx.spawn(_actors, "phantom", Vector2.ZERO, _unit() * 0.55, randf() * 2.0)
		if ghost == null:
			break
		_ghosts.append(ghost)
	while _ghosts.size() > names.size():
		# ปิดมิติแล้ว: ผีสลายเป็นควัน
		var ghost: PixelFx = _ghosts.pop_back()
		PixelFx.spawn(_fx, "boss_down", ghost.position, _unit() * 0.35)
		ghost.queue_free()


## รอยแยกมิติของทุก branch ที่ไม่ได้ยืนอยู่ — เปิดใหม่มีประกาย ปิดแล้วยุบหาย
func _sync_rifts(game: RoomGame) -> void:
	var wanted: Array[String] = []
	if game.branch_names.size() > 1:
		for name in game.branch_names:
			if name != game.current_branch:
				wanted.append(name)
	var first := _rift_names.is_empty() and _rifts.is_empty()
	for name in _rifts.keys():
		if not wanted.has(name):
			var rift: PixelFx = _rifts[name]
			_rifts.erase(name)
			var tw := rift.create_tween()
			tw.tween_property(rift, "scale:x", 0.0, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
			tw.tween_callback(func() -> void:
				PixelFx.spawn(_fx, "imp_poof", rift.position, _unit() * 0.5)
				rift.queue_free())
	for name in wanted:
		if _rifts.has(name):
			continue
		var rift := PixelFx.spawn(_back, "chaos_portal", Vector2.ZERO, _unit() * 0.3, randf() * 2.0)
		if rift == null:
			continue
		rift.modulate = RoomView.dimension_color(name).lightened(0.2)
		_rifts[name] = rift
		if not first:
			rift.scale = Vector2(0.0, rift.scale.y)
			rift.create_tween().tween_property(rift, "scale:x", _unit() * 0.3, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_rift_names = wanted


func rift_point(name: String) -> Vector2:
	var rift: PixelFx = _rifts.get(name, null)
	return rift.position + Vector2(0, -20.0 * _unit()) if rift != null else Vector2(size.x * 0.6, _ground() - 20.0 * _unit())


## ข้ามมิติ: เวลหายวับแล้วปรากฏใหม่
func vel_blink() -> void:
	_blink = 1.0
	PixelFx.spawn(_fx, "stage_sparkle", vel_hand(), _unit() * 0.7)


## ประตูคลังเวทรับคัมภีร์: ขยายวาบและมีประกาย
func vault_flare() -> void:
	_vault_flare = 1.0
	PixelFx.spawn(_fx, "commit_sparkle", vault_point() + Vector2(0, 20.0 * _unit()), _unit() * 0.8)


func _layout() -> void:
	var unit := _unit()
	if _portal != null:
		_portal.position = Vector2(_portal_x(), _ground() + 2)
	if _vault != null:
		_vault.position = Vector2(_vel_x() - 46.0 * unit, _ground() + 2)
		_vault.scale = Vector2.ONE * unit * 0.5
	if _vel.texture != null:
		var h := size.y * 0.92
		var s := maxf(1.0, round(h / 83.0 * 2.0) / 2.0)
		_vel.scale = Vector2.ONE * s
		_vel.position = Vector2(_vel_x() - 24.0 * s, _ground() - 83.0 * s + 2)
	for i in _ghosts.size():
		_ghosts[i].scale = Vector2.ONE * unit * 0.55
	var names := _rifts.keys()
	for i in names.size():
		var rift: PixelFx = _rifts[names[i]]
		rift.position = Vector2(size.x * (0.52 + 0.1 * i), _ground() + 2)


func play(events: Array[Dictionary]) -> void:
	if not visible:
		return
	for event in events:
		match str(event["type"]):
			"wave":
				_wave_pounce()
			"damage":
				_vel_hurt = 1.0
				var text := str(event.get("text", ""))
				if text.contains("ประตูผนึก"):
					seal_zap()
				elif text.contains("มิติผี"):
					for ghost in _ghosts:
						var tw := ghost.create_tween()
						tw.tween_property(ghost, "position:x", _vel_x() - 20.0 * _unit(), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
				elif text.contains("คลัง") and _vault != null:
					PixelFx.spawn(_fx, "damage", _vel.position + Vector2(10, size.y * 0.5), _unit() * 0.6)


## เวลร่ายคาถา: ย่อตัวแล้วยืด มีประกายที่ปลายมือ
func vel_cast() -> void:
	if not visible:
		return
	_cast = 1.0
	PixelFx.spawn(_fx, "stage_sparkle", vel_hand(), _unit() * 0.45)


## แสงคาถาใหญ่ (เช่น คัมภีร์ถือกำเนิด) ทำให้ภูตกระเด็นถอยไปทางประตู
## คัมภีร์ถือกำเนิด (git init / clone): แสงทองของมันกวาดลานจากขวาไปซ้าย เผาภูตทุกตัวที่แสงผ่าน
## แล้วประตูโกลาหลหดตัวลง — เวลไม่ต้องรับคลื่นด้วยตัวเองอีกต่อไป
func holy_sweep() -> void:
	if not visible:
		return
	_holy = 1.0
	_bare = false
	_caption = "แสงของคัมภีร์เผาภูตจนสิ้นซาก!"
	PixelFx.spawn(_fx, "commit_sparkle", vel_hand(), _unit() * 0.8)


func _apply_deferred() -> void:
	if _deferred.is_empty():
		_sync_imps()
		return
	var pending := _deferred
	_deferred = []
	update_lane(pending[0], pending[1])


## คาถาที่กำลังจะเผาภูต (เช่น คัมภีร์กำลังถือกำเนิด): ภูตยังอยู่จนกว่าแสงจะมาถึง ไม่หายไปก่อนเอง
func hold_imps(seconds: float) -> void:
	_hold = maxf(_hold, seconds)


func _holy_x() -> float:
	return lerpf(size.x - 30.0 * _unit(), -40.0, 1.0 - _holy)


func scatter_imps() -> void:
	if not visible:
		return
	_scatter = 1.0


## คาถาล้มเหลว: ควันสีเทาฟุ่บที่มือเวล
func fizzle() -> void:
	if not visible:
		return
	var poof := PixelFx.spawn(_fx, "imp_poof", vel_hand(), _unit() * 0.45)
	if poof != null:
		poof.modulate = Color(0.6, 0.6, 0.65)
	_vel_hurt = 0.35


## ตั้งผนึกที่รอคำตอบ: kind "" = ซ้อน · opened = ผนึกถูกเปิดแล้ว (ตอบถูกครบ)
func set_seal(kind: String, opened: bool) -> void:
	if kind != _seal_kind:
		_seal_kind = kind
		_seal_open = 1.0 if opened else 0.0
		if _seal_circle != null:
			_seal_circle.queue_free()
			_seal_circle = null
		if kind == "runes":
			_seal_circle = PixelFx.spawn(_back, "vel_circle", _seal_point(), _unit() * 0.5)
	var target := 1.0 if opened else 0.0
	if target > _seal_target and _seal_kind != "":
		_seal_burst()
	_seal_target = target


## เอ่ยผิด: ผนึกช็อตกลับใส่เวล
func seal_zap() -> void:
	if _seal_kind.is_empty():
		return
	_seal_zap = 1.0
	_vel_hurt = 1.0
	var from := _seal_point() + Vector2(0, -22.0 * _unit())
	var bolt := PixelFx.spawn(_fx, "damage", vel_hand(), _unit() * 0.6)
	if bolt != null:
		bolt.modulate = Color(1.2, 0.6, 1.4)
	PixelFx.spawn(_fx, "imp_poof", from, _unit() * 0.5)


func _seal_point() -> Vector2:
	return Vector2(size.x * 0.68, _ground())


func _seal_burst() -> void:
	var at := _seal_point()
	if _seal_kind == "door":
		PixelFx.spawn(_fx, "gate_open", at + Vector2(0, -26.0 * _unit()), _unit() * 0.5)
	else:
		PixelFx.spawn(_fx, "commit_sparkle", at, _unit() * 0.8)
	PixelFx.spawn(_fx, "stage_sparkle", at, _unit() * 0.7)


func vel_hand() -> Vector2:
	return Vector2(_vel_x() - 14.0 * _unit(), _ground() - size.y * 0.45)


func vault_point() -> Vector2:
	return _vault.position + Vector2(0, -30.0 * _unit()) if _vault != null else Vector2(_vel_x() - 46.0 * _unit(), _ground() - 30.0)


## คลื่นมา: ภูตทุกตัวกระโจนเข้าหาผ้าปูแล้วระเบิดเป็นควัน ตัวใหม่คลานออกจากประตูอีกครั้ง
func _wave_pounce() -> void:
	_lunge = 1.0
	for imp in _imps:
		var land := Vector2(_target_x() + randf_range(-30, 30), _ground())
		var tw := imp.create_tween()
		tw.tween_property(imp, "position", land - Vector2(0, size.y * 0.35), 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(imp, "position", land, 0.12).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func() -> void: PixelFx.spawn(_fx, "imp_poof", land, _unit() * 0.6))
	_shown_progress = 1.0
	get_tree().create_timer(0.35).timeout.connect(func() -> void:
		for imp in _imps:
			if is_instance_valid(imp):
				imp.queue_free()
		_imps.clear()
		_shown_progress = 0.0
		_sync_imps())


## ประตูหินผนึก: กรอบหิน + บานที่เลื่อนขึ้นเมื่อรหัสถูก · รูนกลางบานเรืองม่วง ช็อตแดงเมื่อเอ่ยผิด
func _draw_door() -> void:
	var u := _unit()
	var p := _seal_point()
	var w := 26.0 * u
	var h := 38.0 * u
	var stone := [Color("2c2842"), Color("3e3a5a"), Color("565078"), Color("7a74a0")]
	var left := p.x - w * 0.5
	var top := p.y - h
	draw_rect(Rect2(left - 4 * u, top - 4 * u, w + 8 * u, 4 * u), stone[2])
	draw_rect(Rect2(left - 4 * u, top - 4 * u, w + 8 * u, u), stone[3])
	draw_rect(Rect2(left - 4 * u, top, 4 * u, h), stone[1])
	draw_rect(Rect2(left + w, top, 4 * u, h), stone[0])
	draw_rect(Rect2(left, top, w, h), Color("0d0a18"))
	if _seal_open > 0.0:
		var light := Color(1.0, 0.85, 0.5, 0.25 * _seal_open)
		draw_rect(Rect2(left, top, w, h), light)
	var slab_h := h * (1.0 - _seal_open)
	if slab_h > 0.5:
		draw_rect(Rect2(left, top, w, slab_h), stone[1])
		draw_rect(Rect2(left, top + slab_h - u, w, u), stone[0])
		for row in range(1, 4):
			var y := top + slab_h - row * 10.0 * u
			if y > top:
				draw_rect(Rect2(left, y, w, u), stone[0])
		var rune_y := top + slab_h - h * 0.55
		if rune_y > top:
			var glow := Color("c48bff").lerp(Color("ff5f7a"), _seal_zap)
			glow.a = 0.6 + 0.3 * sin(_time * 3.0) + _seal_zap * 0.4
			var cx := p.x
			draw_rect(Rect2(cx - u, rune_y - 6 * u, 2 * u, 12 * u), glow)
			draw_rect(Rect2(cx - 5 * u, rune_y - u, 10 * u, 2 * u), glow)
			draw_rect(Rect2(cx - 4 * u, rune_y - 5 * u, 2 * u, 2 * u), glow)
			draw_rect(Rect2(cx + 2 * u, rune_y + 3 * u, 2 * u, 2 * u), glow)


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	_vel_hurt = maxf(0.0, _vel_hurt - delta * 2.0)
	_lunge = maxf(0.0, _lunge - delta * 3.0)
	_cast = maxf(0.0, _cast - delta * 3.0)
	_scatter = maxf(0.0, _scatter - delta * 0.9)
	_seal_zap = maxf(0.0, _seal_zap - delta * 2.0)
	_blink = maxf(0.0, _blink - delta * 1.8)
	_vault_flare = maxf(0.0, _vault_flare - delta * 1.5)
	if _hold > 0.0:
		_hold = maxf(0.0, _hold - delta)
		if _hold <= 0.0 and _holy <= 0.0:
			_apply_deferred()
	if _holy > 0.0:
		_holy = maxf(0.0, _holy - delta / 0.8)
		var hx := _holy_x()
		for imp in _imps.duplicate():
			if is_instance_valid(imp) and imp.position.x >= hx:
				_imps.erase(imp)
				var burn := PixelFx.spawn(_fx, "imp_poof", imp.position, _unit() * 0.7)
				if burn != null:
					burn.modulate = Color(1.6, 1.3, 0.6)
				PixelFx.spawn(_fx, "damage", imp.position + Vector2(0, -8.0 * _unit()), _unit() * 0.5)
				imp.queue_free()
		if _holy <= 0.0:
			_apply_deferred()
	_calm = move_toward(_calm, 1.0 if _has_waves and _threat == 0 else 0.0, delta * 1.5)
	if _portal != null:
		# ประตูสงบ: หดลงและหม่น · มีของให้ทำลาย: เต็มขนาดและสว่าง
		_portal.scale = Vector2.ONE * _unit() * 0.55 * lerpf(1.0, 0.55, _calm)
		_portal.modulate = Color.WHITE.lerp(Color(0.45, 0.4, 0.6, 0.6), _calm)
	_seal_open = move_toward(_seal_open, _seal_target, delta / 0.8)
	if _seal_circle != null:
		_seal_circle.position = _seal_point()
		_seal_circle.scale = Vector2.ONE * _unit() * 0.5
		var lit := Color(1.4, 1.25, 0.8) if _seal_target >= 1.0 else Color(0.55, 0.5, 0.7, 0.7)
		_seal_circle.modulate = lit.lerp(Color(1.6, 0.4, 0.5), _seal_zap)
	if _lunge <= 0.0:
		_shown_progress = lerpf(_shown_progress, _progress, 1.0 - exp(-delta * 4.0))
	var unit := _unit()
	var sleepy := _threat == 0
	for i in _imps.size():
		var imp := _imps[i]
		if not is_instance_valid(imp) or _lunge > 0.0:
			continue
		var base := lerpf(_portal_x() + 18.0 * unit, _target_x(), _shown_progress)
		var x := base - i * 20.0 * unit - ease(_scatter, 0.4) * 60.0 * unit
		var hop := -absf(sin(_scatter * PI * 3.0)) * 10.0 * unit * _scatter
		imp.position = Vector2(maxf(_portal_x(), x), _ground() + hop)
		imp.modulate = Color(0.6, 0.6, 0.75, 0.8) if sleepy else Color.WHITE
		if _scatter > 0.6:
			imp.modulate = Color(1.6, 1.5, 1.2)
		imp.flip_h = false
	for i in _ghosts.size():
		var ghost := _ghosts[i]
		var phase := _time * 1.3 + i * 2.1
		var gx := size.x * (0.55 + 0.12 * sin(phase * 0.7)) - i * 40.0
		var target := Vector2(gx, _ground() - 10.0 * unit + sin(phase) * 5.0 * unit)
		ghost.position = ghost.position.lerp(target, 1.0 - exp(-delta * 3.0))
		ghost.modulate = Color(0.75, 0.85, 1.0, 0.85)
	if _vault != null:
		var synced := _sync_text.is_empty()
		_vault.modulate = Color.WHITE if synced else Color(0.85, 0.45, 0.5, 0.65 + 0.25 * sin(_time * 6.0))
		_vault.scale = Vector2.ONE * _unit() * 0.5 * (1.0 + 0.35 * sin(_vault_flare * PI))
	if _vel.texture != null:
		_vel.texture = _vel_hurt_tex if _vel_hurt > 0.4 else _vel_idle
		_vel.modulate = Color(1, 0.55, 0.6).lerp(Color.WHITE, 1.0 - _vel_hurt) if _vel_hurt > 0.0 else Color.WHITE
		if _blink > 0.0:
			_vel.modulate.a = absf(_blink - 0.5) * 2.0
		var bob := sin(_time * 2.4) * 1.0
		_vel.offset = Vector2(sin(_time * 60.0) * 2.0 * _vel_hurt, bob - sin(_cast * PI) * 4.0)
	queue_redraw()


func _draw() -> void:
	draw_style_box(_panel, Rect2(Vector2.ZERO, size))
	var u := _unit()
	var g := _ground()
	_draw_floor(u, g)
	if _seal_kind == "door":
		_draw_door()
	for name in _rifts:
		var rift: PixelFx = _rifts[name]
		var label := str(name)
		# ชื่อมิติอยู่ข้างรอยแยก (ด้านบนของลานเป็นที่ของคำบรรยาย)
		var p := rift.position + Vector2(10.0 * u, -12.0 * u)
		draw_string_outline(_font, p, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color(0, 0, 0, 0.85))
		draw_string(_font, p, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, RoomView.dimension_color(label))
	if _holy > 0.0:
		_draw_holy_light(u, g)
	# เงาใต้เท้าเวล (วงรีพิกเซลบนขอบพื้น)
	var vx := _vel_x()
	draw_rect(Rect2(vx - 9.0 * u, g, 18.0 * u, u), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(vx - 6.0 * u, g, 12.0 * u, u), Color(0, 0, 0, 0.25))
	if _bare:
		_draw_alarm(u)
	if not _caption.is_empty():
		var color := Color("c9b6ff") if _hidden else (Color("ffb3c4") if _threat > 0 else Color("9fe8b8"))
		var width := size.x * 0.8
		draw_string_outline(_font, Vector2(size.x * 0.1, 18), _caption, HORIZONTAL_ALIGNMENT_CENTER, width, 14, 4, Color(0, 0, 0, 0.85))
		draw_string(_font, Vector2(size.x * 0.1, 18), _caption, HORIZONTAL_ALIGNMENT_CENTER, width, 14, color)


## พื้นหินของลาน: แผ่นหินแถวเดียว สีเดียวกับแท่นเตรียม/แท่นวางคัมภีร์ (ขอบบนสว่าง รอยต่อเข้ม)
## ทางที่ภูตคลานผ่านมาแล้ว (จากประตูถึงตัวหน้าสุด) มีรอยร้าวเรืองม่วงกัดกินพื้น — แทนมาตรวัดแบบจุดประ
func _draw_floor(u: float, g: float) -> void:
	var stone: Array = RoomFurniture.STONE
	var left := FLOOR_MARGIN
	var width := size.x - FLOOR_MARGIN * 2.0
	var depth := FLOOR_UNITS * u
	draw_rect(Rect2(left, g, width, depth), stone[2])
	draw_rect(Rect2(left, g, width, u), stone[3])
	draw_rect(Rect2(left, g + depth - 2.0 * u, width, u), stone[1])
	draw_rect(Rect2(left, g + depth - u, width, u), stone[0])
	var slab := 22.0 * u
	var i := 0
	var x := left + slab * 0.5
	while x < left + width - u:
		draw_rect(Rect2(x, g + u, u, depth - 2.0 * u), stone[1])
		draw_rect(Rect2(x + u, g + u, u, depth - 3.0 * u), stone[3])
		draw_rect(Rect2(x + u, g, u * 2.0, u), stone[4])
		if i % 3 == 1:
			draw_rect(Rect2(x + slab * 0.55, g + 2.0 * u, u, u), stone[1]) # รอยบิ่นบนแผ่นหิน
		x += slab
		i += 1
	if not _has_waves:
		return
	var strength := 1.0 - _calm
	if strength <= 0.01:
		return
	var from := _portal_x()
	var to := lerpf(_portal_x() + 18.0 * u, _target_x(), _shown_progress)
	if to <= from:
		return
	# ไอโกลาหลจาง ๆ ลอยเหนือทาง (ไล่เป็นขั้นพิกเซล ไม่ไล่สีเนียน)
	draw_rect(Rect2(from, g - 3.0 * u, to - from, u), Color(CHAOS, 0.05 * strength))
	draw_rect(Rect2(from, g - 2.0 * u, to - from, u), Color(CHAOS, 0.1 * strength))
	draw_rect(Rect2(from, g - u, to - from, u), Color(CHAOS, 0.18 * strength))
	draw_rect(Rect2(from, g, to - from, u), Color(CHAOS, 0.85 * strength))
	draw_rect(Rect2(from, g + u, to - from, depth - 3.0 * u), Color(CHAOS.darkened(0.5), 0.35 * strength))
	# รอยร้าวซิกแซกเรืองม่วงบนหน้าแผ่นหิน กะพริบไม่พร้อมกัน
	var crack := from + 6.0 * u
	var n := 0
	while crack < to - 2.0 * u:
		var flicker := 0.6 + 0.3 * sin(_time * 4.0 + n * 1.7)
		var c := Color(CHAOS.lightened(0.35), flicker * strength)
		var lean := 1.0 if n % 2 == 0 else -1.0
		draw_rect(Rect2(crack, g + u, u, u), c)
		draw_rect(Rect2(crack + lean * u, g + 2.0 * u, u, u), c)
		draw_rect(Rect2(crack, g + 3.0 * u, u, u), c)
		crack += 11.0 * u
		n += 1


## แสงทองของคัมภีร์ที่เพิ่งถือกำเนิด: ลำแสงที่จางลงเป็นขั้นไปทางเพดาน และส่องสว่างพื้นหินตรงที่มันผ่าน
func _draw_holy_light(u: float, g: float) -> void:
	var hx := _holy_x()
	var gold := Color(1.0, 0.85, 0.4)
	var steps := 4
	for band: Array in [[0.0, 5.0, 0.5], [-4.0, 13.0, 0.2], [-10.0, 26.0, 0.08]]:
		var w: float = band[1] * u
		var bx: float = hx + band[0] * u - w * 0.5
		for s in steps:
			var top := g * float(s) / steps
			draw_rect(Rect2(bx, top, w, g / steps), Color(gold, band[2] * float(s + 1) / steps))
	draw_rect(Rect2(hx - 16.0 * u, g, 32.0 * u, u), Color(1.0, 0.92, 0.6, 0.85 * _holy))


## ยังไม่มีคัมภีร์: เครื่องหมาย "!" กะพริบข้างหัวเวล — คลื่นจะซัดใส่เวลตรง ๆ
func _draw_alarm(u: float) -> void:
	if fmod(_time * 2.5, 1.0) > 0.7:
		return
	var at := _vel.position + Vector2(-4.0 * u, 4.0 * u)
	var outline := Color(0, 0, 0, 0.8)
	var red := Color("ff5f7a")
	draw_rect(Rect2(at.x - u, at.y - u, 4.0 * u, 7.0 * u), outline)
	draw_rect(Rect2(at.x - u, at.y + 7.0 * u, 4.0 * u, 4.0 * u), outline)
	draw_rect(Rect2(at.x, at.y, 2.0 * u, 5.0 * u), red)
	draw_rect(Rect2(at.x, at.y + 8.0 * u, 2.0 * u, 2.0 * u), red)
