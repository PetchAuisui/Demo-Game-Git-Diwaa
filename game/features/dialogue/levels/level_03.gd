class_name Level03Dialogue
extends RefCounted

## ด่านที่ 3: เศษคัมภีร์ไร้ตรา (git status) — Game Design v2
## ปัญหาในโลก: กระดาษร่วงลงบนโต๊ะ บางแผ่นคัมภีร์รู้จัก บางแผ่นไม่ และมีแผ่นหนึ่งถูกใครแอบแก้
## ผู้เล่นต้องหยั่งสถานะ แล้ว "หยิบอ่าน" แผ่นที่ถูกต้องเอง (วัดผลด้วยการลงมือ ไม่ใช่ตัวเลือก)


static func get_data() -> Dictionary:
	return {
		"level_id": 3,
		"title": "ด่านที่ 3: เศษคัมภีร์ไร้ตรา",
		"time_limit": 45.0,
		"max_score": 120,
		"commands": ["git status"],
		"clear_keyword": "git status บอกว่าไฟล์ไหนใหม่ (untracked) ถูกแก้ (modified) หรืออยู่บน stage แล้ว",

		"intro_sequence": [
			{"speaker": "มิวรา", "text": "ลมพัดกระดาษปลิวมาเต็มโต๊ะเลย…", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "คัมภีร์ของนายรู้จักบางแผ่น แต่บางแผ่นไม่มีตราของมันเลย และมีแผ่นหนึ่งถูกใครแอบแก้", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "แล้วจะรู้ได้ยังไงว่าแผ่นไหนเป็นแผ่นไหน?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ถามคัมภีร์สิ — คาถาหยั่งสถานะจะบอกว่ามันมองโต๊ะนี้ยังไง", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 1}
		],

		"gameplay": {
			1: {
				"title": "เศษคัมภีร์ไร้ตรา",
				"story": "กระดาษหลายแผ่นอยู่บนโต๊ะ หาว่าแผ่นไหนไร้ตรา แผ่นไหนถูกแอบแก้ แล้วหยิบอ่าน",
				"panels": ["terminal", "files"],
				"setup": [
					{"run": "git config --global user.name \"Miura\""},
					{"run": "git config --global user.email \"miura@magic-tower.local\""},
					{"run": "git init"},
					{"write": "miura-note.txt", "content": "อย่าลืมให้อาหารแมว\n"},
					{"write": "tower-rules.txt", "content": "กฎหอคอย ข้อ 1: ห้ามวิ่งบนบันได\n"},
					{"run": "git add ."},
					{"run": "git commit -m \"บันทึกของมิวรา\""},
					{"run": "git config --global user.name \"Vel\""},
					{"run": "git config --global user.email \"vel@magic-tower.local\""},
					{"write": "tower-rules.txt", "content": "กฎหอคอย ข้อ 1: ห้ามวิ่งบนบันได\nกฎหอคอย ข้อ 2: เศษคัมภีร์ที่ยังไม่จารึก ห้ามสะสมเกิน 3 ชิ้น!\n"},
					{"write": "whisper.txt", "content": "…เศษคัมภีร์ชิ้นแรกถูกแบ่งเป็นสามส่วน ซ่อนอยู่บนชั้นถัดไป…\n"}
				],
				"objectives": [
					{
						"id": "status",
						"text": "หยั่งสถานะของโต๊ะ ด้วย git status",
						"short": "หยั่งสถานะ",
						"type": "command",
						"commands": ["git status"],
						"world": "Untracked = ไร้ตรา (คัมภีร์ไม่รู้จัก) · modified = ถูกแก้ไปจากที่จารึกไว้",
						"hint": "คาถาหยั่งสถานะ: git ตามด้วยคำว่า status"
					},
					{
						"id": "whisper",
						"text": "หยิบอ่านเศษคัมภีร์ที่ไร้ตรา (cat <ไฟล์> หรือเปิดในแผง Files)",
						"short": "อ่านแผ่นที่ไร้ตรา",
						"type": "read",
						"path": "whisper.txt",
						"world": "\"…เศษคัมภีร์ชิ้นแรกถูกแบ่งเป็นสามส่วน ซ่อนอยู่บนชั้นถัดไป…\"",
						"hint": "ดูหมวด Untracked files ในผลของ git status — มีแผ่นเดียว"
					},
					{
						"id": "rules",
						"text": "อ่านแผ่นที่ถูกใครแอบแก้ไข",
						"short": "อ่านแผ่นที่ถูกแก้",
						"type": "read",
						"path": "tower-rules.txt",
						"world": "กฎข้อ 2 ถูกเพิ่มเข้ามา: เศษคัมภีร์ที่ยังไม่จารึก ห้ามสะสมเกิน 3 ชิ้น!",
						"hint": "ดูหมวด Changes not staged (modified) ในผลของ git status"
					}
				],
				"success_text": "นายเริ่ม 'มองเห็น' สิ่งที่คัมภีร์เห็นแล้ว!"
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "กฎข้อ 2… ใครแอบเพิ่มเข้ามานะ แต่มันก็จริง หอคอยไม่ชอบให้ใครเก็บของไว้โดยไม่จารึก", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "เศษคัมภีร์ชิ้นแรกอยู่ชั้นบน! ไปกันเถอะ", "mewla_anim": "idle"}
		]
	}
