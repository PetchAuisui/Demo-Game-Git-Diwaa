class_name SpellCatalog
extends RefCounted
## สมุดคาถา: คำสั่ง Git ทุกตัวที่เกมสอน ในรูป "คาถา" ของโลกเวท (Game Design v2 §3)
## ด่านประกาศคาถาที่สอนด้วยคีย์ "teaches" ในขั้น gameplay — เกมแจก "ม้วนคาถา" ตอนเริ่มขั้นนั้น
## (สอนตอนที่ต้องใช้จริง: LM-GM "Instruction → Application") แล้วเก็บเข้าสมุดคาถาให้เปิดดูได้ตลอด
## ปริศนายังอยู่ที่ "จะใช้คาถาไหน เมื่อไร" ไม่ใช่การเดาว่าคำสั่งสะกดอย่างไร
##
## แต่ละคาถา: name (ชื่อในโลกเวท), command (คำสั่งจริง), does (ผลในโลก), real (ความหมายใน Git), example

const SPELLS := {
	"version": {"name": "คาถาวัดพลัง", "command": "git --version",
		"does": "ปลุกวงเวทให้บอกระดับพลัง Git ของนาย", "real": "แสดงเวอร์ชันของ Git ที่ติดตั้ง",
		"example": "git --version"},
	"config": {"name": "คาถาประกาศนาม", "command": "git config --global user.name \"ชื่อ\"",
		"does": "สลักนามและตราประทับ (อีเมล) ให้ทุกการจารึกรู้ว่าใครเป็นผู้จารึก", "real": "ตั้งชื่อ/อีเมลผู้เขียน commit — ไม่ใส่ค่าต่อท้าย = อ่านค่าที่ตั้งไว้",
		"example": "git config --global user.email \"vel@magic-tower.local\""},
	"init": {"name": "คาถากำเนิดคัมภีร์", "command": "git init",
		"does": "สร้างคัมภีร์เวทส่วนตัวที่จดจำทุกอย่างบนโต๊ะนี้", "real": "สร้าง Git repository ใหม่ในโฟลเดอร์ปัจจุบัน",
		"example": "git init"},
	"status": {"name": "คาถาหยั่งสถานะ", "command": "git status",
		"does": "ให้คัมภีร์บอกว่าแผ่นไหนไร้ตรา (untracked) ถูกแก้ (modified) หรืออยู่บนแท่นเตรียม", "real": "ดูสถานะไฟล์ใน working tree และ staging area",
		"example": "git status"},
	"cat": {"name": "หยิบอ่าน", "command": "cat <ไฟล์>",
		"does": "อ่านกระดาษบนโต๊ะ (หรือเปิดไฟล์ในแผง Files)", "real": "แสดงเนื้อหาไฟล์ (คำสั่งของเกม ไม่ใช่ Git)",
		"example": "cat scroll-a.txt"},
	"add": {"name": "คาถาวางขึ้นแท่น", "command": "git add <ไฟล์>",
		"does": "ยกของจากโต๊ะขึ้นแท่นเตรียม เลือกได้ทีละชิ้นหรือหลายชิ้น — git add . ยกทุกอย่าง (รวมของที่ไม่อยากได้!)", "real": "เพิ่มการเปลี่ยนแปลงเข้า staging area",
		"example": "git add fragment-1a.txt fragment-1b.txt"},
	"commit": {"name": "คาถาจารึก", "command": "git commit -m \"คำจารึก\"",
		"does": "จารึกทุกอย่างบนแท่นลงคัมภีร์อย่างถาวร — ของที่จารึกแล้วคลื่นโกลาหลแตะไม่ได้", "real": "บันทึก snapshot จาก staging area เป็น commit ใหม่",
		"example": "git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 1\""},
	"commit_all": {"name": "คาถาจารึกข้ามแท่น", "command": "git commit -am \"คำจารึก\"",
		"does": "จารึกการแก้ไขของทุกแผ่นที่คัมภีร์รู้จักแล้วทันที โดยไม่แตะของไร้ตรา", "real": "-a = add ไฟล์ที่ถูก track แล้วอัตโนมัติก่อน commit (ไม่รวมไฟล์ใหม่)",
		"example": "git commit -am \"เศษคัมภีร์ชิ้นที่ 2\""},
	"log": {"name": "คาถาคลี่ม้วนประวัติ", "command": "git log --oneline",
		"does": "อ่านการจารึกทั้งหมดย้อนหลัง — ใคร จารึกอะไร (คำจารึกมักมีความลับซ่อนอยู่)", "real": "ดูประวัติ commit (--oneline = บรรทัดละ commit)",
		"example": "git log --oneline"},
	"say": {"name": "เอ่ยคำ", "command": "say <คำ>",
		"does": "เอ่ยรหัสหรืออักขระต่อหน้าประตู/วงเวท — เอ่ยผิดพลังจะสะท้อนกลับ", "real": "คำสั่งของเกม ใช้ตอบปริศนา",
		"example": "say lumos"},
	"diff": {"name": "คาถาเทียบรอย", "command": "git diff",
		"does": "เทียบโต๊ะกับคัมภีร์: บรรทัด - คืออักขระเดิม + คืออักขระใหม่", "real": "ดูความต่างระหว่าง working tree กับ staging area",
		"example": "git diff"},
	"diff_staged": {"name": "คาถาเทียบรอยบนแท่น", "command": "git diff --staged",
		"does": "เทียบของบนแท่นเตรียมกับคัมภีร์ — เห็นสิ่งที่แอบขึ้นแท่น", "real": "ดูความต่างระหว่าง staging area กับ commit ล่าสุด",
		"example": "git diff --staged"},
	"restore": {"name": "คาถาฟื้นคืน", "command": "git restore <ไฟล์>",
		"does": "ลบรอยสาป/การแก้ไขบนโต๊ะ ให้กลับเป็นแบบที่จารึกไว้ (การแก้ไขนั้นหายจริง)", "real": "ทิ้งการเปลี่ยนแปลงใน working tree",
		"example": "git restore fragment-5.txt"},
	"restore_staged": {"name": "คาถานำลงจากแท่น", "command": "git restore --staged <ไฟล์>",
		"does": "เอาของลงจากแท่นเตรียม (ของยังอยู่บนโต๊ะ)", "real": "นำไฟล์ออกจาก staging area",
		"example": "git restore --staged curse.txt"},
	"reset": {"name": "เวทย้อนกาล", "command": "git reset --soft|--mixed|--hard HEAD~1",
		"does": "ย้อนคัมภีร์ไปก่อนการจารึกล่าสุด: soft = ของกลับขึ้นแท่น, mixed = ของกลับมาบนโต๊ะ, hard = ของหายหมด!", "real": "ย้าย HEAD/branch กลับไป commit ก่อนหน้า (HEAD~1 = ก่อนหน้าหนึ่งครั้ง)",
		"example": "git reset --mixed HEAD~1"},
	"branch": {"name": "คาถาแยกมิติ", "command": "git branch [ชื่อ]",
		"does": "ร่ายเฉย ๆ = ดูมิติทั้งหมด (* คือมิติที่ยืนอยู่) · ใส่ชื่อ = เปิดมิติใหม่", "real": "ดู/สร้าง branch",
		"example": "git branch experiment"},
	"branch_delete": {"name": "คาถาปิดมิติ", "command": "git branch -d <ชื่อ>",
		"does": "ปิดมิติที่ไม่ใช้แล้ว", "real": "ลบ branch (ที่ถูก merge แล้ว)",
		"example": "git branch -d phantom"},
	"switch": {"name": "คาถาประตูมิติ", "command": "git switch <มิติ>",
		"does": "ก้าวไปยืนในอีกมิติ — ของบนโต๊ะเปลี่ยนตามมิตินั้น", "real": "เปลี่ยน branch",
		"example": "git switch experiment"},
	"switch_create": {"name": "คาถาเปิดประตูมิติใหม่", "command": "git switch -c <มิติใหม่>",
		"does": "เปิดมิติใหม่แล้วก้าวเข้าไปทันทีในคาถาเดียว", "real": "สร้าง branch แล้ว switch ไปเลย",
		"example": "git switch -c trial"},
	"merge": {"name": "พิธีหลอมมิติ", "command": "git merge <มิติ>",
		"does": "หลอมอีกมิติเข้ามาในมิติที่ยืนอยู่ — ถ้าเขียนจุดเดียวกันต่างกันจะเกิดการปะทะ ต้องแก้ไฟล์ → add → commit", "real": "รวม branch (conflict: แก้ไฟล์ แล้ว git add และ git commit)",
		"example": "git merge experiment"},
	"write": {"name": "เขียนทับ", "command": "write <ไฟล์> <ข้อความ>",
		"does": "เขียนเนื้อหาใหม่ลงกระดาษ (หรือแก้ในแผง Files แล้วบันทึก)", "real": "คำสั่งของเกม ใช้แก้ไฟล์",
		"example": "write altar-core.txt แกนแท่นบูชา: ไอน้ำ"},
	"clone": {"name": "คาถาคัดลอกคัมภีร์", "command": "git clone <ที่อยู่>",
		"does": "คัดลอกคัมภีร์ทั้งเล่มพร้อมประวัติจากคลังเวทกลาง", "real": "คัดลอก remote repository มาเป็น repo ในเครื่อง",
		"example": "git clone https://magic-vault.com/user/light-tome.git"},
	"remote": {"name": "คาถาสายเชื่อม", "command": "git remote -v",
		"does": "ดูว่าคัมภีร์ผูกกับคลังเวทที่ไหน (origin คือชื่อสายเชื่อมหลัก)", "real": "แสดง remote และ URL",
		"example": "git remote -v"},
	"fetch": {"name": "คาถาส่องคลัง", "command": "git fetch",
		"does": "ส่องดูว่าคลังเวทมีจารึกใหม่อะไร แต่ยังไม่รวมเข้าคัมภีร์ของนาย", "real": "ดาวน์โหลดข้อมูลจาก remote (origin/main ขยับ) โดยไม่ merge",
		"example": "git fetch"},
	"pull": {"name": "คาถาเรียกความรู้", "command": "git pull",
		"does": "ดึงจารึกใหม่จากคลังเวทลงมารวมกับคัมภีร์ของนาย", "real": "fetch + merge จาก remote",
		"example": "git pull"},
	"remote_add": {"name": "คาถาผูกสายเชื่อม", "command": "git remote add <ชื่อ> <ที่อยู่>",
		"does": "ผูกคัมภีร์ของนายเข้ากับที่อยู่ในคลังเวท", "real": "เพิ่ม remote",
		"example": "git remote add origin https://magic-vault.com/user/apprentice-tome.git"},
	"push": {"name": "คาถาส่งผ่านประตูเวท", "command": "git push -u origin main",
		"does": "ส่งการจารึกของนายเข้าคลังเวท — ครั้งแรกใส่ -u เพื่อผูกเส้นทาง", "real": "อัปโหลด commit ไปยัง remote (-u ตั้ง upstream)",
		"example": "git push -u origin main"},
}


static func has_spell(id: String) -> bool:
	return SPELLS.has(id)


static func spell(id: String) -> Dictionary:
	var entry: Dictionary = SPELLS.get(id, {}).duplicate()
	entry["id"] = id
	return entry


## คาถาที่ขั้นนี้ของด่านแจกเป็นม้วนคาถาใหม่
static func taught_in(level: int, step: int) -> Array[String]:
	var ids: Array[String] = []
	for id in LevelDataLoader.get_gameplay_step(level, step).get("teaches", []):
		ids.append(str(id))
	return ids


## คาถาทั้งหมดที่ผู้เล่นได้เรียนมาจนถึงขั้นนี้ (รวมขั้นนี้) เรียงตามลำดับที่ได้รับ
static func learned_until(level: int, step: int) -> Array[String]:
	var ids: Array[String] = []
	for current_level in range(1, level + 1):
		var steps := LevelDataLoader.get_gameplay_step_count(current_level)
		for current_step in range(1, steps + 1):
			if current_level == level and current_step > step:
				break
			for id in taught_in(current_level, current_step):
				if not ids.has(id):
					ids.append(id)
	return ids
