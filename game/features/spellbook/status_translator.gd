class_name StatusTranslator
extends RefCounted
## มิวราแปลผลของ git status (ภาษาอังกฤษ) เป็นภาษาไทยในโลกเวท วางต่อท้ายผลจริงในวงร่ายเวท
## ผู้เล่นเห็นทั้งข้อความ Git จริงและความหมาย จึงจับคู่ "untracked = ไร้ตรา" ฯลฯ ได้เอง

const ORDER := ["conflict", "untracked", "modified", "staged", "staged_modified"]
const MEANING := {
	"untracked": "คัมภีร์ยังไม่รู้จัก — ถ้าไม่จารึก คลื่นโกลาหลจะทำลายมัน",
	"modified": "เคยจารึกแล้ว แต่ถูกแก้ไปจากฉบับในคัมภีร์",
	"staged": "วางอยู่บนแท่นเตรียม รอการจารึก",
	"staged_modified": "อยู่บนแท่นแล้ว แต่ถูกแก้ต่อบนผ้าปูอีก",
	"conflict": "สองมิติเขียนต่างกัน ต้องแก้ไฟล์แล้ว add + commit",
}


## names = path -> ชื่อในโลกเวท (จากห้องมินิเกม) ใช้แทนชื่อไฟล์ให้อ่านง่าย
## compact = true → บรรทัดสั้นสำหรับแสดงในห้อง (ไม่มีบรรทัดอธิบาย เพราะป้ายบนกระดาษบอกอยู่แล้ว)
static func explain(snapshot: GitRepositorySnapshot, names: Dictionary = {}, compact: bool = false) -> PackedStringArray:
	var lines := PackedStringArray()
	if snapshot == null or not snapshot.is_initialized:
		lines.append("มิวรา: ที่นี่ยังไม่มีคัมภีร์ (not a git repository) — ต้องกำเนิดคัมภีร์ก่อน")
		return lines

	lines.append("มิวราแปลให้ — นายยืนอยู่ในมิติ %s" % (str(snapshot.current_branch) if snapshot.current_branch != null else "(ไม่มีชื่อ)"))
	var groups := {}
	for file in snapshot.files:
		var state := RoomGame.git_state(file)
		if not groups.has(state):
			groups[state] = PackedStringArray()
		var name := str((names.get(file.path, {}) as Dictionary).get("name", ""))
		groups[state].append("%s [%s]" % [name, file.path] if not name.is_empty() else file.path)

	if groups.is_empty():
		lines.append("  • ทุกแผ่นถูกจารึกครบแล้ว (working tree clean) — คลื่นโกลาหลแตะอะไรไม่ได้")
		return lines
	for state in ORDER:
		if groups.has(state):
			lines.append("  • %s: %s" % [RoomGame.GIT_LABELS[state], ", ".join(groups[state])])
			if not compact:
				lines.append("      → %s" % MEANING[state])
	return lines
