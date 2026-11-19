class_name LevelMission
extends RefCounted

## สถานะภารกิจของ "ขั้นเล่นจริง" ในด่าน (ไม่ผูกกับ UI)
## อ่านนิยามภารกิจจาก LevelDataLoader (คีย์ "gameplay" -> ขั้น -> objectives) แล้วตรวจคำสั่งที่ผู้เล่นพิมพ์
##
## ชนิด objective:
##   command     commands: [..]        พิมพ์คำสั่งตรงตัว (เว้นวรรคซ้ำถูกยุบ) และคำสั่งสำเร็จ
##   config_set  key, validator        git config --global <key> "<ค่า>" (validator: non_empty | email)
##   config_get  key                   git config --global <key> แล้วมีค่าตอบกลับ
##   state       check, ...            ตรวจจาก "สถานะ Repository" หลังคำสั่ง ไม่ใช่ข้อความคำสั่ง (Game Design v2 §4.3)
##                                     ผู้เล่นใช้คาถารูปแบบไหนก็ได้ ขอแค่โลก (repo) เป็นไปตามเป้าหมาย
##       check = repo_initialized                     มีคัมภีร์ (git init แล้ว)
##             | staged          paths: [..]          ทุกไฟล์ใน paths อยู่บนแท่นเตรียม (staged)
##             | committed       paths: [..], count   ทุกไฟล์ใน paths ถูกจารึกแล้ว (ไม่เหลือสถานะค้าง) และมี commit ≥ count
##             | commits_at_least count               มี commit อย่างน้อย count ครั้ง
##             | clean                                working tree และ stage ว่าง
##             | branch_exists   branch               มี branch ชื่อนี้
##             | current_branch  branch               ยืนอยู่บน branch นี้
##             | merge_commit                         HEAD เป็น merge commit (มีสอง parent)
##       spell (ไม่บังคับ) = ต้องสำเร็จด้วยคาถานี้ เช่น "add" / "commit" (ใช้เมื่ออยากให้ฝึกคาถาเฉพาะ)
##       objective แบบ state จะถูกตรวจเมื่อ objective ก่อนหน้าทั้งหมดสำเร็จแล้วเท่านั้น (เป็นลำดับเหตุการณ์ในเรื่อง)
##
## คีย์เสริมทุกชนิด:
##   world       ข้อความ "โลกตอบสนอง" สั้น ๆ ที่แสดงเมื่อสำเร็จ (แทนบทสนทนายาว)

signal objective_completed(objective_id: String)
signal mission_completed

const EMAIL_PATTERN := "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$"

## RegEx ที่คอมไพล์แล้ว (pattern -> RegEx หรือ null ถ้า pattern ผิด) ไม่ต้องคอมไพล์ใหม่ทุกคำสั่ง
static var _regex_cache: Dictionary = {}

var level_number: int
var step: int
var title: String
var story: String
var success_text: String
var objectives: Array[Dictionary] = []
var total_steps: int
var time_limit: float = 0.0

var _done: Dictionary = {}


## คืน null ถ้าด่านนี้ไม่มีขั้นเล่นจริงตามหมายเลขขั้นที่ระบุ
static func create(level_num: int, step_num: int) -> LevelMission:
	var level_data := LevelDataLoader.load_data(level_num)
	var gameplay: Dictionary = level_data.get("gameplay", {})
	var definition: Dictionary = gameplay.get(step_num, {})
	if definition.is_empty():
		return null
	var mission := LevelMission.new()
	mission.level_number = level_num
	mission.step = step_num
	mission.total_steps = gameplay.size()
	mission.title = str(definition.get("title", ""))
	mission.story = str(definition.get("story", ""))
	mission.success_text = str(definition.get("success_text", "ภารกิจสำเร็จ!"))
	mission.time_limit = float(definition.get("time_limit", level_data.get("time_limit", 0.0)))
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


## ข้อความ "โลกตอบสนอง" ของภารกิจ ("" = ไม่มี)
func world_text(objective_id: String) -> String:
	for objective in objectives:
		if str(objective["id"]) == objective_id:
			return str(objective.get("world", ""))
	return ""


## ตรวจคำสั่งที่เพิ่งรันเสร็จ คืน id ของภารกิจที่เพิ่งสำเร็จ
## snapshot = สถานะ Repository หลังคำสั่ง (จำเป็นสำหรับ objective ชนิด state)
func on_command(command: String, success: bool, output: String, snapshot: GitRepositorySnapshot = null) -> Array[String]:
	var newly_done: Array[String] = []
	var tokens := tokenize(command)
	for index in objectives.size():
		var objective := objectives[index]
		var objective_id := str(objective["id"])
		if is_done(objective_id):
			continue
		var matched := false
		if str(objective.get("type", "")) == "state":
			matched = _previous_done(index) and _matches_state(objective, tokens, success, snapshot)
		else:
			matched = _matches(objective, tokens, success, output)
		if matched:
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
		var regex := _get_regex(str(near_miss["pattern"]))
		if regex != null and regex.search(command.strip_edges()) != null:
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


func _previous_done(index: int) -> bool:
	for previous in index:
		if not is_done(str(objectives[previous]["id"])):
			return false
	return true


func _matches_state(objective: Dictionary, tokens: PackedStringArray, success: bool, snapshot: GitRepositorySnapshot) -> bool:
	if snapshot == null:
		return false
	var spell := str(objective.get("spell", ""))
	if not spell.is_empty() and (not success or tokens.size() < 2 or tokens[0] != "git" or tokens[1] != spell):
		return false
	return evaluate_state(objective, snapshot)


## ตรวจเงื่อนไขสถานะ (static เพื่อใช้ซ้ำและทดสอบได้โดยไม่ต้องมี mission)
static func evaluate_state(objective: Dictionary, snapshot: GitRepositorySnapshot) -> bool:
	if snapshot == null:
		return false
	var paths: Array = objective.get("paths", [])
	match str(objective.get("check", "")):
		"repo_initialized":
			return snapshot.is_initialized
		"staged":
			return snapshot.is_initialized and not paths.is_empty() and paths.all(func(path: Variant) -> bool:
				var status := _status_of(snapshot, str(path))
				return status != null and _is_staged_state(status.index_state))
		"committed":
			if not snapshot.is_initialized or snapshot.commits.size() < int(objective.get("count", 1)):
				return false
			return paths.all(func(path: Variant) -> bool: return _status_of(snapshot, str(path)) == null)
		"commits_at_least":
			return snapshot.commits.size() >= int(objective.get("count", 1))
		"clean":
			return snapshot.is_initialized and snapshot.files.is_empty()
		"branch_exists":
			var wanted := str(objective.get("branch", ""))
			return snapshot.branches.any(func(branch: GitBranchInfo) -> bool: return branch.name == wanted)
		"current_branch":
			return snapshot.current_branch != null and str(snapshot.current_branch) == str(objective.get("branch", ""))
		"merge_commit":
			return not snapshot.commits.is_empty() and _head_commit(snapshot) != null and _head_commit(snapshot).parent_ids.size() > 1
	return false


static func _status_of(snapshot: GitRepositorySnapshot, path: String) -> GitFileStatus:
	for file in snapshot.files:
		if file.path == path:
			return file
	return null


static func _is_staged_state(state: int) -> bool:
	return state in [GitFileState.ADDED, GitFileState.MODIFIED, GitFileState.DELETED, GitFileState.RENAMED, GitFileState.COPIED]


static func _head_commit(snapshot: GitRepositorySnapshot) -> GitCommitNode:
	for branch in snapshot.branches:
		if branch.is_current and branch.commit_id != null:
			for commit in snapshot.commits:
				if commit.id == str(branch.commit_id):
					return commit
	for commit in snapshot.commits:
		if commit.references.any(func(ref: String) -> bool: return ref.begins_with("HEAD")):
			return commit
	return snapshot.commits[0] if not snapshot.commits.is_empty() else null


static func _get_regex(pattern: String) -> RegEx:
	if not _regex_cache.has(pattern):
		var regex := RegEx.new()
		_regex_cache[pattern] = regex if regex.compile(pattern) == OK else null
	return _regex_cache[pattern]


static func _valid_value(validator: String, value: String) -> bool:
	var trimmed := value.strip_edges()
	if trimmed.is_empty():
		return false
	if validator == "email":
		var regex := _get_regex(EMAIL_PATTERN)
		return regex != null and regex.search(trimmed) != null
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
