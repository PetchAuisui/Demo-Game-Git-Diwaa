class_name CommitEditor
extends RefCounted
## git commit ที่ไม่มี -m จะเปิด editor ให้เขียนคำจารึก (COMMIT_EDITMSG) เหมือน Git จริง
## ในเกม "editor" คือหน้าจารึกของคัมภีร์ (CommitEditorView) — เมื่อเขียนเสร็จ เกมรันคำสั่งเดิมพร้อมข้อความที่เขียน
## ถ้าปล่อยว่าง เกมรันคำสั่งเดิมตรง ๆ ให้ Git ยกเลิกเองด้วยข้อความจริง (Aborting commit due to empty commit message.)

const TEMPLATE_COMMENT := [
	"# เขียนคำจารึกด้านบน: บรรทัดแรกคือหัวเรื่องสั้น ๆ",
	"# เว้นหนึ่งบรรทัด แล้วเขียนรายละเอียดได้หลายบรรทัด",
	"# บรรทัดที่ขึ้นต้นด้วย # จะถูกละเว้น — ถ้าคำจารึกว่าง การจารึกจะถูกยกเลิก",
]


## true = คำสั่งนี้จะเปิด editor (commit ที่ไม่มี -m / -am)
static func needs_editor(command: String) -> bool:
	var tokens := LevelMission.tokenize(command)
	if tokens.size() < 2 or tokens[0] != "git" or tokens[1] != "commit":
		return false
	for token in tokens.slice(2):
		if token == "-am" or token.begins_with("-m") or token == "--no-edit":
			return false
	return true


## ตัดบรรทัด # และช่องว่างหัวท้ายออก เหมือนที่ Git ทำกับ COMMIT_EDITMSG
static func clean_message(text: String) -> String:
	var kept := PackedStringArray()
	for line in text.split("\n"):
		if line.strip_edges().begins_with("#"):
			continue
		kept.append(line.strip_edges(false, true))
	return "\n".join(kept).strip_edges()


## คำสั่งที่รันจริง: ตัวเลือกเดิม (-a, --amend) + -m ทีละย่อหน้า ("" = คำจารึกว่าง ให้รันคำสั่งเดิม)
static func to_command(command: String, message: String) -> String:
	var cleaned := clean_message(message)
	if cleaned.is_empty():
		return command.strip_edges()
	var parts := PackedStringArray(["git", "commit"])
	for token in LevelMission.tokenize(command).slice(2):
		parts.append(token)
	for paragraph in cleaned.split("\n\n", false):
		var text := paragraph.strip_edges()
		if not text.is_empty():
			parts.append("-m")
			parts.append("\"%s\"" % text.replace("\\", "\\\\").replace("\"", "\\\""))
	return " ".join(parts)


## ข้อความตั้งต้นในหน้าจารึก (--amend เปิดพร้อมคำจารึกเดิม เหมือน Git)
static func template(previous_message: String = "") -> String:
	var lines := PackedStringArray()
	lines.append(previous_message)
	lines.append("")
	lines.append_array(TEMPLATE_COMMENT)
	return "\n".join(lines)
