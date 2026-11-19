class_name SpellEffectDetector
extends RefCounted
## เลือก "ผลของคาถา" ที่จะแสดงในฉาก โดยเทียบ GitRepositorySnapshot ก่อน/หลังคำสั่ง (Game Design v2 §4.1)
## ไม่เดาจากข้อความคำสั่งอย่างเดียว เอฟเฟกต์จึงตรงกับสิ่งที่ Git ทำจริงเสมอ
## ผลลัพธ์เป็น Array ของ Dictionary: {kind, title, detail, panel}
##   panel = "files" | "graph" | "terminal" | "" (แผงที่ควรเรืองแสงตาม)

enum Kind {
	RUNE_GLOW,       # git --version
	NAME_BOUND,      # git config user.name / user.email
	TOME_CREATED,    # git init
	REVEALED,        # status / log / diff / show — คาถาสำรวจที่ไม่เปลี่ยนโลก
	TO_ALTAR,        # มีไฟล์ขึ้น stage เพิ่ม
	FROM_ALTAR,      # ไฟล์ลงจาก stage โดยไม่ได้ commit
	INSCRIBED,       # commit ใหม่
	TIME_REWIND,     # HEAD ถอยกลับไปยัง commit ในอดีต
	CURSE_LIFTED,    # การแก้ไขใน working tree ถูกทิ้ง (restore)
	DIMENSION_SPLIT, # branch ใหม่
	DIMENSION_CLOSED,# ลบ branch
	DIMENSION_STEP,  # เปลี่ยน branch
	DIMENSIONS_MERGED,
	DIMENSION_CLASH, # conflict
	PORTAL_SEND,     # push
	PORTAL_RECEIVE,  # pull / fetch นำ commit ใหม่มา
	FIZZLE,          # คำสั่งล้มเหลว / ถูกปฏิเสธ
}

const TITLES := {
	Kind.RUNE_GLOW: "วงเวทตื่นขึ้น",
	Kind.NAME_BOUND: "นามถูกสลักลงบนประตู",
	Kind.TOME_CREATED: "คัมภีร์เวทถือกำเนิด",
	Kind.REVEALED: "ม่านหมอกถูกเปิดออก",
	Kind.TO_ALTAR: "เศษคัมภีร์ลอยขึ้นแท่นเตรียม",
	Kind.FROM_ALTAR: "เศษคัมภีร์ลงจากแท่นเตรียม",
	Kind.INSCRIBED: "จารึกลงคัมภีร์แล้ว",
	Kind.TIME_REWIND: "กาลเวลาหมุนย้อน",
	Kind.CURSE_LIFTED: "รอยสาปสลายไป",
	Kind.DIMENSION_SPLIT: "รอยแยกมิติเปิดออก",
	Kind.DIMENSION_CLOSED: "มิติหนึ่งถูกปิดผนึก",
	Kind.DIMENSION_STEP: "ก้าวผ่านประตูมิติ",
	Kind.DIMENSIONS_MERGED: "สองมิติหลอมรวมเป็นหนึ่ง",
	Kind.DIMENSION_CLASH: "มิติปะทะกัน!",
	Kind.PORTAL_SEND: "ส่งผ่านประตูสู่คลังเวท",
	Kind.PORTAL_RECEIVE: "ความรู้ไหลมาจากคลังเวท",
	Kind.FIZZLE: "คาถาไม่ตอบสนอง",
}

## คำอธิบายสั้นตามความหมายจริงของ Git (เชื่อมอุปมา ↔ คำสั่งจริง)
const MEANINGS := {
	Kind.RUNE_GLOW: "Git พร้อมใช้งาน",
	Kind.NAME_BOUND: "ตั้งค่าผู้เขียน commit",
	Kind.TOME_CREATED: "สร้าง repository ใหม่",
	Kind.REVEALED: "ตรวจดูสถานะ / ประวัติ",
	Kind.TO_ALTAR: "เพิ่มเข้า staging area",
	Kind.FROM_ALTAR: "นำออกจาก staging area",
	Kind.INSCRIBED: "สร้าง commit ใหม่",
	Kind.TIME_REWIND: "ย้าย HEAD กลับไป commit ก่อนหน้า",
	Kind.CURSE_LIFTED: "คืนไฟล์กลับเป็นแบบที่ commit ไว้",
	Kind.DIMENSION_SPLIT: "สร้าง branch ใหม่",
	Kind.DIMENSION_CLOSED: "ลบ branch",
	Kind.DIMENSION_STEP: "เปลี่ยน branch",
	Kind.DIMENSIONS_MERGED: "merge สำเร็จ",
	Kind.DIMENSION_CLASH: "merge conflict — ต้องแก้ไฟล์เอง",
	Kind.PORTAL_SEND: "push ขึ้น remote",
	Kind.PORTAL_RECEIVE: "ได้ commit ใหม่จาก remote",
	Kind.FIZZLE: "คำสั่งไม่สำเร็จ",
}

const _OBSERVATIONS := ["status", "log", "diff", "show"]


static func detect(before: GitRepositorySnapshot, after: GitRepositorySnapshot,
		command: String, success: bool) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	var tokens := LevelMission.tokenize(command)
	var spell := tokens[1] if tokens.size() >= 2 and tokens[0] == "git" else ""
	if spell == "version" or (tokens.size() >= 2 and tokens[1] == "--version"):
		spell = "version"

	if before == null or after == null:
		if not success:
			effects.append(_make(Kind.FIZZLE, "", "terminal"))
		return effects

	if not success:
		if spell in ["merge", "pull"] and _unmerged(after).size() > _unmerged(before).size():
			effects.append(_make(Kind.DIMENSION_CLASH, ", ".join(PackedStringArray(_unmerged(after))), "files"))
		else:
			effects.append(_make(Kind.FIZZLE, "", "terminal"))
		return effects

	if spell == "version":
		effects.append(_make(Kind.RUNE_GLOW, "", "terminal"))
	if spell == "config" and tokens.size() >= 5:
		effects.append(_make(Kind.NAME_BOUND, tokens[4], "terminal"))

	if not before.is_initialized and after.is_initialized:
		effects.append(_make(Kind.TOME_CREATED, "", "graph"))
	elif before.is_initialized and after.is_initialized:
		_detect_repository_changes(before, after, spell, effects)

	if effects.is_empty() and spell in _OBSERVATIONS:
		effects.append(_make(Kind.REVEALED, spell, "files" if spell == "status" else "graph"))
	return effects


static func _detect_repository_changes(before: GitRepositorySnapshot, after: GitRepositorySnapshot,
		spell: String, effects: Array[Dictionary]) -> void:
	var before_local := _local_branch_names(before)
	var after_local := _local_branch_names(after)
	for name in after_local:
		if not before_local.has(name):
			effects.append(_make(Kind.DIMENSION_SPLIT, name, "graph"))
	for name in before_local:
		if not after_local.has(name):
			effects.append(_make(Kind.DIMENSION_CLOSED, name, "graph"))

	var same_branch := str(before.current_branch) == str(after.current_branch)
	if not same_branch and after.current_branch != null:
		effects.append(_make(Kind.DIMENSION_STEP, str(after.current_branch), "graph"))

	var before_head := head_id(before)
	var after_head := head_id(after)
	var head_moved := before_head != after_head
	if head_moved and same_branch and not after_head.is_empty():
		var head := _commit(after, after_head)
		# commit ที่ถูกย้อนผ่านอาจหายจาก log --all หลัง reset จึงต้องใช้ประวัติจากทั้งสอง snapshot
		if not before_head.is_empty() and is_ancestor([before, after], after_head, before_head):
			effects.append(_make(Kind.TIME_REWIND, head.subject if head != null else "", "graph"))
		elif spell in ["pull", "fetch"]:
			effects.append(_make(Kind.PORTAL_RECEIVE, head.subject if head != null else "", "graph"))
		elif (head != null and head.parent_ids.size() > 1) or spell == "merge":
			effects.append(_make(Kind.DIMENSIONS_MERGED, head.subject if head != null else "", "graph"))
		else:
			effects.append(_make(Kind.INSCRIBED, head.subject if head != null else "", "graph"))

	if _unmerged(after).size() > _unmerged(before).size():
		effects.append(_make(Kind.DIMENSION_CLASH, ", ".join(PackedStringArray(_unmerged(after))), "files"))

	if spell == "push" and _remote_refs(before) != _remote_refs(after):
		effects.append(_make(Kind.PORTAL_SEND, str(after.current_branch), "graph"))
	elif spell == "fetch" and _remote_refs(before) != _remote_refs(after) \
			and not effects.any(func(e: Dictionary) -> bool: return e["kind"] == Kind.PORTAL_RECEIVE):
		effects.append(_make(Kind.PORTAL_RECEIVE, "origin", "graph"))

	if not head_moved and same_branch:
		var before_staged := _staged(before)
		var after_staged := _staged(after)
		var raised := after_staged.filter(func(path: String) -> bool: return not before_staged.has(path))
		var lowered := before_staged.filter(func(path: String) -> bool: return not after_staged.has(path))
		if not raised.is_empty():
			effects.append(_make(Kind.TO_ALTAR, ", ".join(PackedStringArray(raised)), "files"))
		if not lowered.is_empty():
			effects.append(_make(Kind.FROM_ALTAR, ", ".join(PackedStringArray(lowered)), "files"))
		if spell in ["restore", "reset"]:
			var before_dirty := _dirty(before)
			var after_dirty := _dirty(after)
			var healed := before_dirty.filter(func(path: String) -> bool:
				return not after_dirty.has(path) and not after_staged.has(path))
			if not healed.is_empty():
				effects.append(_make(Kind.CURSE_LIFTED, ", ".join(PackedStringArray(healed)), "files"))


static func _make(kind: int, detail: String, panel: String) -> Dictionary:
	return {"kind": kind, "title": TITLES[kind], "meaning": MEANINGS[kind], "detail": detail, "panel": panel}


static func head_id(snapshot: GitRepositorySnapshot) -> String:
	for branch in snapshot.branches:
		if branch.is_current and branch.commit_id != null:
			return str(branch.commit_id)
	for commit in snapshot.commits:
		if commit.references.any(func(ref: String) -> bool: return ref.begins_with("HEAD")):
			return commit.id
	return ""


## true เมื่อ ancestor อยู่ในประวัติของ descendant (และไม่ใช่ตัวเดียวกัน) โดยรวม commit จากทุก snapshot ที่ส่งมา
static func is_ancestor(snapshots: Array, ancestor: String, descendant: String) -> bool:
	var parents := {}
	for snapshot: GitRepositorySnapshot in snapshots:
		for commit in snapshot.commits:
			parents[commit.id] = commit.parent_ids
	var stack: Array[String] = [descendant]
	var seen := {}
	while not stack.is_empty():
		var id: String = stack.pop_back()
		if seen.has(id):
			continue
		seen[id] = true
		if id == ancestor and id != descendant:
			return true
		for parent in parents.get(id, []):
			stack.append(parent)
	return false


static func _commit(snapshot: GitRepositorySnapshot, id: String) -> GitCommitNode:
	for commit in snapshot.commits:
		if commit.id == id:
			return commit
	return null


static func _local_branch_names(snapshot: GitRepositorySnapshot) -> Array[String]:
	var names: Array[String] = []
	for branch in snapshot.branches:
		if not _is_remote_branch(snapshot, branch.name):
			names.append(branch.name)
	return names


static func _remote_refs(snapshot: GitRepositorySnapshot) -> Dictionary:
	var refs := {}
	for branch in snapshot.branches:
		if _is_remote_branch(snapshot, branch.name):
			refs[branch.name] = branch.commit_id
	return refs


## for-each-ref ใช้ refname:short จึงแยก remote ด้วยรูปแบบ "<remote>/<branch>" ที่ไม่ใช่ branch ปัจจุบันของผู้เล่น
static func _is_remote_branch(snapshot: GitRepositorySnapshot, name: String) -> bool:
	if name == "origin":
		return true # refs/remotes/origin/HEAD แบบย่อ
	if not name.contains("/"):
		return false
	for branch in snapshot.branches:
		if branch.upstream != null and str(branch.upstream) == name:
			return true
	return name.begins_with("origin/") or name.begins_with("upstream/")


static func _staged(snapshot: GitRepositorySnapshot) -> Array[String]:
	var paths: Array[String] = []
	for file in snapshot.files:
		if file.index_state in [GitFileState.ADDED, GitFileState.MODIFIED, GitFileState.DELETED, GitFileState.RENAMED, GitFileState.COPIED]:
			paths.append(file.path)
	return paths


static func _dirty(snapshot: GitRepositorySnapshot) -> Array[String]:
	var paths: Array[String] = []
	for file in snapshot.files:
		if file.working_tree_state in [GitFileState.MODIFIED, GitFileState.DELETED]:
			paths.append(file.path)
	return paths


static func _unmerged(snapshot: GitRepositorySnapshot) -> Array[String]:
	var paths: Array[String] = []
	for file in snapshot.files:
		if file.index_state == GitFileState.UNMERGED or file.working_tree_state == GitFileState.UNMERGED:
			paths.append(file.path)
	return paths
