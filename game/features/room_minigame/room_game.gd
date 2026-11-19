class_name RoomGame
extends RefCounted
## มินิเกม "ห้องในหอคอย" (Game Design v2 — Git คือเครื่องมือเอาตัวรอด ไม่ใช่สิ่งที่ถูกสั่งให้พิมพ์)
##
## ของทุกชิ้นในห้องคือไฟล์จริงใน repo ของผู้เล่น โลกมีกฎของตัวเองที่ทำร้ายผู้เล่น
## และมีแค่คาถา Git เท่านั้นที่ใช้รับมือได้:
##   • คลื่นโกลาหล  — มาทุก N การกระทำ ทำลายของที่ "ยังไม่ปลอดภัย" (ยังไม่จารึก) → ผู้เล่นต้อง commit เอง
##                    ของที่จารึกแล้วแต่ถูกแก้จะถูกสาป (เนื้อหาเพี้ยน) → git restore ฟื้นคืนจากคัมภีร์ได้
##   • คำสาป       — ม้วนคำสาปที่ถูกจารึกลงคัมภีร์จะกัดกินหัวใจทุกคลื่น → ต้องย้อนกาล (reset) เอาออก
##   • มิติผี       — branch ที่ไม่ควรมีอยู่ดูดพลังทุกคลื่น → ต้องปิดมิติ (branch -d)
##   • ของที่ปรากฏตามเวลา (spawns) และเมื่อสำเร็จเป้าหมาย (ดู LevelMission objective key "spawn")
## หัวใจหมด = แพ้ เริ่มชั้นใหม่ได้ทันที
##
## ไม่มี UI และไม่แตะไฟล์เอง: คืน "actions" ให้ผู้เรียก (SandboxGameView / tests) นำไปทำกับ sandbox
## actions: {"write": path, "content": text} | {"delete": path}
## events:  {"type": ..., "text": ..., "path": ...} สำหรับแสดงผลในห้อง
##
## คีย์ "room" ในขั้น gameplay ของไฟล์ด่าน:
##   hearts        จำนวนหัวใจ (ค่าเริ่มต้น 3)
##   wave_every    มีคลื่นทุกกี่การกระทำ (0 = ไม่มีคลื่น)
##   first_wave    คลื่นแรกที่การกระทำที่เท่าไร (ค่าเริ่มต้น = wave_every)
##   safe          "committed" (ค่าเริ่มต้น: ปลอดภัยเมื่อจารึกแล้วเท่านั้น) | "staged" (แท่นเตรียมมีโล่ป้องกัน)
##   items         {path: {"kind": "fragment|curse|key|note", "name": "ชื่อในโลก"}}
##   spawns        [{"turn": n, "path", "content", "kind", "name"}] ปรากฏเมื่อถึงการกระทำที่ n
##   respawn       true = เศษที่สลายจะก่อตัวใหม่ในการกระทำถัดไป (เสียหัวใจแทนการแพ้ทันที)
##   phantoms      ["ghost"] ชื่อ branch ผีที่ดูดหัวใจทุกคลื่นจนกว่าจะถูกลบ
##   wrong_say     หัวใจที่เสียเมื่อเอ่ยรหัสผิด (ค่าเริ่มต้น 1)
##   blind         true = ห้องไม่บอกสถานะของเศษคัมภีร์จนกว่าผู้เล่นจะร่าย git status (ใช้ในด่านหยั่งสถานะ)
##   needs_tome    true = คลื่นทำร้ายผู้เล่นถ้ายังไม่มีคัมภีร์ (git init)
##   cursed        [paths] ของที่ถูกสาปไว้ตั้งแต่เริ่ม (ให้ห้องแสดงว่าถูกสาป)
##   essential     [paths] ของที่ห้ามหาย — ถ้าหายไปจากพื้นที่ทำงาน (เช่น reset --hard) แพ้ทันที
## คำสาปบนแท่นเตรียมตอนคลื่นมา: โล่แท่นแตกและเสียหัวใจ (สอนให้เลือกของขึ้นแท่นเอง)

const CORRUPTED_TEXT := "ค̷͓ว̷า̴ม̸โ̷ก̵ล̸า̴ห̷ล̷ ̸ก̵ั̶ด̶ก̷ิ̸น̷อ̸ั̷ก̸ข̷ร̶ะ̵\n"
const STATE_DESK := "desk"         # untracked หรือแก้ไขแต่ยังไม่ขึ้นแท่น
const STATE_ALTAR := "altar"       # staged
const STATE_TOME := "tome"         # จารึกแล้วและไม่มีการแก้ค้าง
const STATE_CURSED := "cursed"     # ถูกจารึกแล้วแต่เนื้อหาถูกแก้ (รอฟื้นคืน)
const STATE_CONFLICT := "conflict" # มิติปะทะ

var hearts := 3
var max_hearts := 3
var turn := 0
var wave_every := 0
var first_wave := 0
var safe_mode := "committed"
var respawn := false
var blind := false
var revealed := false
var wrong_say_damage := 1
var needs_tome := false
var essential: Array[String] = []
var _seen_essential: Dictionary = {}
var items: Dictionary = {}
var spawns: Array[Dictionary] = []
var phantoms: Array[String] = []
var _pending_respawn: Array[Dictionary] = []
var _contents: Dictionary = {}
## path ที่คลื่นสาปไว้และยังไม่ถูกฟื้นคืน
var _corrupted: Dictionary = {}
## path ที่มีอยู่จริงในพื้นที่ทำงานล่าสุด (ผู้เรียกตั้งค่าก่อน on_turn ผ่าน set_present)
var _present: Dictionary = {}


static func from_config(config: Dictionary) -> RoomGame:
	var game := RoomGame.new()
	game.max_hearts = int(config.get("hearts", 3))
	game.hearts = game.max_hearts
	game.wave_every = int(config.get("wave_every", 0))
	game.first_wave = int(config.get("first_wave", game.wave_every))
	game.safe_mode = str(config.get("safe", "committed"))
	game.respawn = bool(config.get("respawn", false))
	game.blind = bool(config.get("blind", false))
	game.wrong_say_damage = int(config.get("wrong_say", 1))
	game.needs_tome = bool(config.get("needs_tome", false))
	for path in config.get("cursed", []):
		game._corrupted[str(path)] = true
	for path in config.get("essential", []):
		game.essential.append(str(path))
	game.items = (config.get("items", {}) as Dictionary).duplicate(true)
	for spawn in config.get("spawns", []):
		game.spawns.append(spawn)
		game.items[str(spawn["path"])] = {"kind": str(spawn.get("kind", "fragment")), "name": str(spawn.get("name", spawn["path"]))}
	for phantom in config.get("phantoms", []):
		game.phantoms.append(str(phantom))
	return game


func is_failed() -> bool:
	return hearts <= 0


func has_waves() -> bool:
	return wave_every > 0


## จำนวนการกระทำก่อนคลื่นถัดไป (-1 = ไม่มีคลื่น)
func turns_until_wave() -> int:
	if not has_waves():
		return -1
	if turn < first_wave:
		return first_wave - turn
	var since := (turn - first_wave) % wave_every
	return wave_every - since if since != 0 else wave_every


## ของที่ต้องเกิดตั้งแต่ก่อนเริ่ม (turn 0)
func initial_actions() -> Array[Dictionary]:
	return _spawn_actions(0)


## เรียกหลังผู้เล่นทำหนึ่งการกระทำ (คำสั่งในวงร่ายเวท / บันทึกไฟล์ / เอ่ยคำ)
## snapshot = สถานะหลังการกระทำ, tracked_clean = path ที่ถูกจารึกและไม่มีการแก้ค้าง
func on_turn(snapshot: GitRepositorySnapshot, command: String = "") -> Dictionary:
	var actions: Array[Dictionary] = []
	var events: Array[Dictionary] = []
	if is_failed():
		return {"actions": actions, "events": events, "wave": false}

	turn += 1
	var tokens := LevelMission.tokenize(command)
	if tokens.size() >= 2 and tokens[0] == "git" and tokens[1] == "status":
		revealed = true

	var respawning := {}
	for pending in _pending_respawn:
		respawning[pending["path"]] = true
		actions.append({"write": pending["path"], "content": pending["content"]})
		_corrupted.erase(pending["path"])
		events.append({"type": "respawn", "path": pending["path"], "text": "%s ก่อตัวขึ้นใหม่จากเศษแสง" % _name(pending["path"])})
	_pending_respawn.clear()

	for action in _spawn_actions(turn):
		actions.append(action)
		events.append({"type": "spawn", "path": action["write"], "text": "%s ร่วงลงมาบนโต๊ะ!" % _name(action["write"])})

	for path in essential:
		if _present.has(path):
			_seen_essential[path] = true
		elif _seen_essential.has(path) and not respawning.has(path):
			_damage(hearts, events, "%s หายไปจากโลกแล้ว — ไม่มีทางนำกลับมา!" % _name(path), path)
			return {"actions": actions, "events": events, "wave": false}

	var is_wave := has_waves() and turn >= first_wave and (turn - first_wave) % wave_every == 0
	if is_wave:
		_resolve_wave(snapshot, actions, events)
	return {"actions": actions, "events": events, "wave": is_wave}


## เอ่ยคำผิด (ปริศนาประตูผนึก) — เสียหัวใจ
func on_wrong_say() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if wrong_say_damage > 0:
		_damage(wrong_say_damage, events, "ประตูผนึกสะท้อนพลังกลับมาใส่นาย!")
	return events


## จดจำเนื้อหาของเศษคัมภีร์ เพื่อให้เศษที่สลายก่อตัวใหม่ได้ (เรียกเมื่ออ่านไฟล์ได้ หรือหลัง spawn)
func remember_content(path: String, content: String) -> void:
	if content != CORRUPTED_TEXT:
		_contents[path] = content


## สถานะของของแต่ละชิ้นสำหรับวาดห้อง: [{path, kind, name, state}]
## workspace_paths = ไฟล์ทั้งหมดในพื้นที่ทำงาน (ไฟล์ที่ไม่อยู่ใน status = จารึกแล้วและสะอาด)
func describe(snapshot: GitRepositorySnapshot, workspace_paths: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var statuses := {}
	if snapshot != null:
		for file in snapshot.files:
			statuses[file.path] = file
	for path in workspace_paths:
		var item: Dictionary = items.get(path, {})
		var kind := str(item.get("kind", "note"))
		var state := STATE_DESK
		if blind and not revealed:
			result.append({"path": path, "kind": "note", "name": path, "state": STATE_DESK, "hidden": true})
			continue
		if statuses.has(path):
			state = classify(statuses[path])
			if _corrupted.has(path) and state == STATE_DESK:
				state = STATE_CURSED
		elif snapshot != null and snapshot.is_initialized and not snapshot.commits.is_empty():
			state = STATE_TOME
		result.append({"path": path, "kind": kind, "name": _name(path), "state": state,
				"hidden": blind and not revealed})
	return result


static func classify(status: GitFileStatus) -> String:
	if status.index_state == GitFileState.UNMERGED or status.working_tree_state == GitFileState.UNMERGED:
		return STATE_CONFLICT
	if status.index_state == GitFileState.UNTRACKED:
		return STATE_DESK
	if status.working_tree_state == GitFileState.MODIFIED or status.working_tree_state == GitFileState.DELETED:
		return STATE_DESK # จารึกแล้วแต่มีการแก้ค้างบนโต๊ะ
	return STATE_ALTAR


func _resolve_wave(snapshot: GitRepositorySnapshot, actions: Array[Dictionary], events: Array[Dictionary]) -> void:
	events.append({"type": "wave", "text": "คลื่นโกลาหลซัดเข้ามา!"})
	if needs_tome and (snapshot == null or not snapshot.is_initialized):
		_damage(1, events, "ไม่มีคัมภีร์รองรับพลัง คลื่นซัดเข้าใส่นายเต็ม ๆ!")
	var statuses := {}
	if snapshot != null:
		for file in snapshot.files:
			statuses[file.path] = file
	for path in _corrupted.keys():
		if not statuses.has(path):
			_corrupted.erase(path) # ถูกฟื้นคืนแล้ว

	for path in items.keys():
		var item: Dictionary = items[path]
		if str(item.get("kind", "")) == "curse":
			if statuses.has(path) and classify(statuses[path]) == STATE_ALTAR:
				_damage(1, events, "%s บนแท่นเตรียมระเบิด! โล่แท่นแตก" % _name(path), path)
			continue
		if not statuses.has(path):
			continue # จารึกแล้วและสะอาด หรือยังไม่ปรากฏ → ปลอดภัย
		var status: GitFileStatus = statuses[path]
		var state := classify(status)
		if state == STATE_ALTAR and safe_mode == "staged":
			events.append({"type": "shielded", "path": path, "text": "โล่แท่นเตรียมปกป้อง %s ไว้" % _name(path)})
			continue
		if state == STATE_CONFLICT:
			continue # การปะทะถูกจัดการด้วยกฎของด่าน ไม่ซ้ำเติม
		if status.index_state == GitFileState.UNTRACKED or status.index_state == GitFileState.ADDED:
			# ยังไม่เคยถูกจารึก → สลายไปจริง ๆ
			actions.append({"delete": path})
			_damage(1, events, "%s สลายเป็นผุยผง!" % _name(path), path)
			if respawn and _contents.has(path):
				_pending_respawn.append({"path": path, "content": _contents[path]})
		else:
			# เคยจารึกแล้ว → ถูกสาป แต่คัมภีร์ยังจำฉบับเดิมไว้ (git restore)
			actions.append({"write": path, "content": CORRUPTED_TEXT})
			_corrupted[path] = true
			_damage(1, events, "%s ถูกคำสาปกัดกิน! (คัมภีร์ยังจำฉบับเดิมไว้)" % _name(path), path)
			if respawn and _contents.has(path):
				_pending_respawn.append({"path": path, "content": _contents[path]})

	# คำสาปที่ถูกจารึกลงคัมภีร์แล้ว: ไม่อยู่ใน status แต่อยู่ในพื้นที่ทำงาน = tracked
	for path in items.keys():
		if str(items[path].get("kind", "")) != "curse":
			continue
		if _is_tracked_clean(snapshot, statuses, path):
			_damage(1, events, "คำสาปใน %s ที่ถูกจารึกลงคัมภีร์กัดกินพลังของนาย!" % _name(path), path)

	if snapshot != null:
		for phantom in phantoms:
			if snapshot.branches.any(func(branch: GitBranchInfo) -> bool: return branch.name == phantom):
				_damage(1, events, "มิติผี '%s' ดูดพลังของนาย!" % phantom)


func _is_tracked_clean(snapshot: GitRepositorySnapshot, statuses: Dictionary, path: String) -> bool:
	if snapshot == null or not snapshot.is_initialized or snapshot.commits.is_empty():
		return false
	if statuses.has(path):
		return false
	return _present.has(path)


func set_present(workspace_paths: Array[String]) -> void:
	_present.clear()
	for path in workspace_paths:
		_present[path] = true
		if essential.has(path):
			_seen_essential[path] = true


func _spawn_actions(at_turn: int) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	for spawn in spawns:
		if int(spawn.get("turn", 0)) == at_turn:
			actions.append({"write": str(spawn["path"]), "content": str(spawn.get("content", ""))})
			remember_content(str(spawn["path"]), str(spawn.get("content", "")))
	return actions


func _damage(amount: int, events: Array[Dictionary], text: String, path: String = "") -> void:
	hearts = maxi(0, hearts - amount)
	events.append({"type": "damage", "path": path, "text": text})
	if hearts == 0:
		events.append({"type": "defeat", "text": "พลังของนายหมดลง… หอคอยส่งนายกลับไปเริ่มชั้นนี้ใหม่"})


func _name(path: String) -> String:
	return str((items.get(path, {}) as Dictionary).get("name", path))
