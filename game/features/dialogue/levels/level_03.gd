class_name Level03Dialogue
extends RefCounted

## ด่านที่ 3: เศษคัมภีร์ไร้ตรา (git status) — มินิเกม "โต๊ะที่มองไม่เห็น"
## ห้องแสดงกระดาษ 6 แผ่นเป็น "?" ทั้งหมด ไม่รู้ว่าแผ่นไหนไร้ตรา/ถูกแก้ จนกว่าจะร่าย git status
## คลื่นโกลาหลมาทุก 4 การกระทำ และกระดาษไร้ตรา (เสียงกระซิบ) จะสลายถ้าโดนคลื่น
## → เดาสุ่มอ่านทีละแผ่นเสียเวลาและหัวใจ การหยั่งสถานะคือทางที่เร็วที่สุด

const SCROLLS := {
	"scroll-a.txt": "บันทึกการซ่อมแท่นเตรียม: เรียบร้อย\n",
	"scroll-b.txt": "กฎหอคอย ข้อ 1: ห้ามวิ่งบนบันได\n",
	"scroll-c.txt": "สูตรขนมปลาของมิวรา (ห้ามแตะ)\n",
	"scroll-e.txt": "รายชื่อศิษย์ที่ยังค้างค่าน้ำหมึก\n",
	"scroll-f.txt": "แผนที่ห้องเก็บไม้กวาด\n",
}


static func get_data() -> Dictionary:
	var setup: Array = [
		{"run": "git config --global user.name \"Miura\""},
		{"run": "git config --global user.email \"miura@magic-tower.local\""},
		{"run": "git init"},
	]
	for path in SCROLLS:
		setup.append({"write": path, "content": SCROLLS[path]})
	setup.append_array([
		{"run": "git add ."},
		{"run": "git commit -m \"เอกสารของกิลด์\""},
		{"run": "git config --global user.name \"Vel\""},
		{"run": "git config --global user.email \"vel@magic-tower.local\""},
		# ใครบางคนแอบแก้กฎหอคอย และกระดาษไร้ตราหนึ่งแผ่นร่วงลงมา
		{"write": "scroll-b.txt", "content": "กฎหอคอย ข้อ 1: ห้ามวิ่งบนบันได\nกฎหอคอย ข้อ 2: เศษคัมภีร์ที่ยังไม่จารึก ห้ามสะสมเกิน 3 ชิ้น!\n"},
		{"write": "scroll-d.txt", "content": "…เศษคัมภีร์ชิ้นแรกถูกแบ่งเป็นสามส่วน ซ่อนอยู่บนชั้นถัดไป…\n"},
	])

	var items := {}
	for path in ["scroll-a.txt", "scroll-b.txt", "scroll-c.txt", "scroll-e.txt", "scroll-f.txt"]:
		items[path] = {"kind": "note", "name": "เอกสารกิลด์"}
	items["scroll-b.txt"] = {"kind": "note", "name": "กฎหอคอย"}
	items["scroll-d.txt"] = {"kind": "fragment", "name": "เสียงกระซิบ"}

	return {
		"level_id": 3,
		"title": "ด่านที่ 3: เศษคัมภีร์ไร้ตรา",
		"time_limit": 45.0,
		"max_score": 120,
		"commands": ["git status"],
		"clear_keyword": "git status บอกว่าไฟล์ไหนใหม่ (untracked) ถูกแก้ (modified) หรืออยู่บน stage แล้ว",

		"intro_sequence": [
			{"speaker": "มิวรา", "text": "ลมพัดกระดาษหกแผ่นปลิวมาเต็มโต๊ะ… หน้าตาเหมือนกันหมดเลย", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "แผ่นหนึ่งไม่มีตราของคัมภีร์ — มันคือเสียงกระซิบที่บอกทางไปหาเศษคัมภีร์ แต่มันจะสลายเมื่อคลื่นโกลาหลมาถึง", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "อ่านทีละแผ่นก็ไม่ทันแน่ ๆ", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ถ้างั้นก็ถามคัมภีร์สิว่ามันมองโต๊ะนี้ยังไง", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 1}
		],

		"gameplay": {
			1: {
				"title": "โต๊ะที่มองไม่เห็น",
				"story": "กระดาษ 6 แผ่นหน้าตาเหมือนกัน หาแผ่นที่ไร้ตราและแผ่นที่ถูกแอบแก้ แล้วอ่านก่อนคลื่นซัด",
				# ซ่อนแผง Files เพราะมันบอกสถานะไฟล์ให้ฟรี — ด่านนี้ต้องหยั่งสถานะเอง
				"panels": ["terminal"],
				# ม้วนคาถาที่แจกตอนเริ่มขั้นนี้ (SpellCatalog)
				"teaches": ["status", "cat"],
				"setup": setup,
				"room": {"hearts": 3, "wave_every": 4, "blind": true, "respawn": true, "items": items},
				"objectives": [
					{
						"id": "status",
						"text": "ทำให้คัมภีร์เผยว่ามันมองเห็นกระดาษแต่ละแผ่นอย่างไร",
						"short": "หยั่งสถานะของโต๊ะ",
						"type": "command",
						"commands": ["git status"],
						"world": "หมอกจางลง — Untracked = ไร้ตรา (คัมภีร์ไม่รู้จัก) · modified = ถูกแก้ไปจากที่จารึกไว้",
						"hint": "คาถาหยั่งสถานะ: git status"
					},
					{
						"id": "whisper",
						"text": "อ่านกระดาษไร้ตราก่อนมันจะสลาย (คลิกกระดาษในห้อง หรือพิมพ์ cat ตามด้วยชื่อไฟล์)",
						"short": "อ่านเสียงกระซิบ",
						"type": "read",
						"path": "scroll-d.txt",
						"world": "\"…เศษคัมภีร์ชิ้นแรกถูกแบ่งเป็นสามส่วน ซ่อนอยู่บนชั้นถัดไป…\"",
						"hint": "ดูหมวด Untracked files ในผลของ git status แล้ว cat ไฟล์นั้น"
					},
					{
						"id": "rules",
						"text": "อ่านกระดาษที่ถูกใครบางคนแอบแก้",
						"short": "อ่านแผ่นที่ถูกแก้",
						"type": "read",
						"path": "scroll-b.txt",
						"world": "กฎข้อ 2 ถูกเพิ่มเข้ามา: เศษคัมภีร์ที่ยังไม่จารึก ห้ามสะสมเกิน 3 ชิ้น!",
						"hint": "ดูบรรทัด modified: ในผลของ git status"
					}
				],
				"success_text": "นายมองเห็นสิ่งที่คัมภีร์เห็นแล้ว!"
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "เห็นไหม แทนที่จะเดาสุ่ม นายถามคัมภีร์ครั้งเดียวก็รู้หมด", "mewla_anim": "success"},
			{"speaker": "มิวรา", "text": "กฎข้อ 2… ใครแอบเพิ่มนะ แต่มันก็จริง หอคอยไม่ชอบให้ใครเก็บของไว้โดยไม่จารึก", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "เศษคัมภีร์ชิ้นแรกอยู่ชั้นบน! ไปกันเถอะ", "mewla_anim": "idle"}
		]
	}
