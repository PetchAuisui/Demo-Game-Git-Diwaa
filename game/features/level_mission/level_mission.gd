class_name LevelMission
extends RefCounted

## สถานะภารกิจของ "ขั้นเล่นจริง" ในด่าน (ไม่ผูกกับ UI)
## อ่านนิยามภารกิจจาก LevelDataLoader (คีย์ "gameplay" -> ขั้น -> objectives) แล้วตรวจคำสั่งที่ผู้เล่นพิมพ์
##
## ชนิด objective:
##   command     commands: [..]        พิมพ์คำสั่งตรงตัว (เว้นวรรคซ้ำถูกยุบ) และคำสั่งสำเร็จ
##   config_set  key, validator        git config --global <key> "<ค่า>" (validator: non_empty | email)
##   config_get  key                   git config --global <key> แล้วมีค่าตอบกลับ

signal objective_completed(objective_id: String)
signal mission_completed

const EMAIL_PATTERN := "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$"

var level_number: int
var step: int
var title: String
var story: String
var success_text: String
var objectives: Array[Dictionary] = []
var total_steps: int
## แผงของ Sandbox ที่แสดงในขั้นนี้ (ว่าง = แสดงทั้งหมด)
var visible_panels: Array[String] = []

var _done: Dictionary = {}


## คืน null ถ้าด่านนี้ไม่มีขั้นเล่นจริงตามหมายเลขขั้นที่ระบุ
static func create(level_num: int, step_num: int) -> LevelMission:
	var definition := LevelDataLoader.get_gameplay_step(level_num, step_num)
	if definition.is_empty():
		return null
	var mission := LevelMission.new()
	mission.level_number = level_num
	mission.step = step_num
	mission.total_steps = LevelDataLoader.get_gameplay_step_count(level_num)
	mission.title = str(definition.get("title", ""))
	mission.story = str(definition.get("story", ""))
	mission.success_text = str(definition.get("success_text", "ภารกิจสำเร็จ!"))
	for panel_id in definition.get("visible_panels", []):
		mission.visible_panels.append(str(panel_id))
	for objective in definition.get("objectives", []):
		mission.objectives.append(objective)
	return mission


func is_done(objective_id: String) -> bool:
	return _done.has(objective_id)


func done_count() -> int:
	return _done.size()


func is_complete() -> bool:
	return not objectives.is_empty() and _done.size() >= objectives.size()


## ภารกิจแรกที่ยังไม่สำเร็จ (ใช้แสดงคำใบ้) หรือ {} เมื่อครบแล้ว
func current_objective() -> Dictionary:
	for objective in objectives:
		if not is_done(str(objective["id"])):
			return objective
	return {}


## ตรวจคำสั่งที่เพิ่งรันเสร็จ คืน id ของภารกิจที่เพิ่งสำเร็จ
func on_command(command: String, success: bool, output: String) -> Array[String]:
	var newly_done: Array[String] = []
	var tokens := tokenize(command)
	for objective in objectives:
		var objective_id := str(objective["id"])
		if is_done(objective_id):
			continue
		if _matches(objective, tokens, success, output):
			_done[objective_id] = true
			newly_done.append(objective_id)
			objective_completed.emit(objective_id)
	if not newly_done.is_empty() and is_complete():
		mission_completed.emit()
	return newly_done


## ข้อความเตือนเมื่อพิมพ์ผิดแบบที่พบบ่อยของภารกิจปัจจุบัน ("" = ไม่เข้าเงื่อนไขใด)
func mistake_message(command: String) -> String:
	var objective := current_objective()
	for near_miss in objective.get("near_miss", []):
		var regex := RegEx.new()
		if regex.compile(str(near_miss["pattern"])) == OK and regex.search(command.strip_edges()) != null:
			return str(near_miss["message"])
	return ""


func _matches(objective: Dictionary, tokens: PackedStringArray, success: bool, output: String) -> bool:
	if not success or tokens.size() < 2 or tokens[0] != "git":
		return false
	match str(objective.get("type", "")):
		"command":
			var normalized := " ".join(tokens)
			for accepted in objective.get("commands", []):
				if normalized == str(accepted):
					return true
			return false
		"config_set":
			if tokens.size() != 5 or tokens[1] != "config" or tokens[2] != "--global":
				return false
			return tokens[3] == str(objective["key"]) and _valid_value(str(objective.get("validator", "non_empty")), tokens[4])
		"config_get":
			if tokens.size() != 4 or tokens[1] != "config" or tokens[2] != "--global":
				return false
			return tokens[3] == str(objective["key"]) and not output.strip_edges().is_empty()
	return false


static func _valid_value(validator: String, value: String) -> bool:
	var trimmed := value.strip_edges()
	if trimmed.is_empty():
		return false
	if validator == "email":
		var regex := RegEx.new()
		regex.compile(EMAIL_PATTERN)
		return regex.search(trimmed) != null
	return true


## แยกคำสั่งเป็นคำ รองรับเครื่องหมายคำพูดคู่/เดี่ยว ("a b" เป็นคำเดียว) และ \" ในคำพูดคู่
static func tokenize(command: String) -> PackedStringArray:
	var tokens := PackedStringArray()
	var current := ""
	var has_token := false
	var quote := ""
	var index := 0
	while index < command.length():
		var ch := command[index]
		if quote.is_empty():
			if ch == "\"" or ch == "'":
				quote = ch
				has_token = true
			elif ch == " " or ch == "\t":
				if has_token:
					tokens.append(current)
					current = ""
					has_token = false
			else:
				current += ch
				has_token = true
		elif ch == quote:
			quote = ""
		elif ch == "\\" and quote == "\"" and index + 1 < command.length() and command[index + 1] in ["\"", "\\"]:
			index += 1
			current += command[index]
		else:
			current += ch
		index += 1
	if has_token:
		tokens.append(current)
	return tokens
