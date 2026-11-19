class_name Level06Dialogue
extends RefCounted

## ด่านที่ 6: ม้วนประวัติของอาจารย์ (git log) — มินิเกม "ประตูผนึก"
## รหัสผนึกประตูชั้นเจ็ดอยู่ใน "คำจารึก" ของปรมาจารย์เท่านั้น ไม่อยู่ในไฟล์ใดเลย → ต้องอ่านประวัติ
## เอ่ยรหัสผิด ประตูสะท้อนพลังกลับ (เสียหัวใจ) — เดาสุ่มไม่คุ้ม
## ประตูเปิดแล้วเศษคัมภีร์ชิ้นที่ 3 ร่วงออกมา และต้องจารึกก่อนคลื่นถัดไป

const MASTER := "ปรมาจารย์"


static func _master_page(message: String, path: String, content: String) -> Array:
	return [
		{"write": path, "content": content},
		{"run": "git add %s" % path},
		{"run": "git commit -m \"%s\"" % message},
	]


static func get_data() -> Dictionary:
	var setup: Array = [
		{"run": "git config --global user.name \"%s\"" % MASTER},
		{"run": "git config --global user.email \"master@magic-tower.local\""},
		{"run": "git init"},
	]
	setup.append_array(_master_page("เริ่มศึกษาคัมภีร์เวทต้นกำเนิด", "journal.txt", "วันแรกของการศึกษา\n"))
	setup.append_array(_master_page("รับศิษย์ฝึกหัดคนใหม่ชื่อเวล", "apprentices.txt", "ศิษย์: เวล\n"))
	setup.append_array(_master_page("พบรอยร้าวบนคัมภีร์ต้นกำเนิด", "journal.txt", "วันแรกของการศึกษา\nรอยร้าวลามเร็วผิดปกติ\n"))
	setup.append_array(_master_page("ผนึกประตูชั้นเจ็ด รหัสผนึก: aurora", "seal.txt", "ประตูชั้นเจ็ด: ผนึกแล้ว\n(รหัสไม่ได้อยู่ในกระดาษแผ่นนี้ — ผู้จารึกย่อมจำได้ว่าจารึกอะไรไว้)\n"))
	setup.append_array(_master_page("พลังโกลาหลรุนแรงขึ้นทุกคืน", "journal.txt", "วันแรกของการศึกษา\nรอยร้าวลามเร็วผิดปกติ\nได้ยินเสียงจากใต้หอคอย\n"))
	setup.append_array(_master_page("ซ่อนเศษคัมภีร์ไว้หลังประตูที่ผนึก", "journal.txt", "…\n"))
	setup.append_array(_master_page("ถ้ามีใครอ่านอยู่… จงตามเศษคัมภีร์ขึ้นไป", "farewell.txt", "ข้าไปก่อนนะ\n"))
	setup.append_array([
		{"run": "git config --global user.name \"Vel\""},
		{"run": "git config --global user.email \"vel@magic-tower.local\""},
	])

	return {
		"level_id": 6,
		"title": "ด่านที่ 6: ม้วนประวัติของอาจารย์",
		"time_limit": 110.0,
		"max_score": 150,
		"commands": ["git log"],
		"clear_keyword": "git log ดูประวัติการจารึก ใคร จารึกอะไร เมื่อไร · git log --oneline ย่อให้เหลือบรรทัดละครั้ง",

		"intro_sequence": [
			{"speaker": "เวล", "text": "ประตูหินบานนี้ไม่มีลูกบิด… มีแค่ช่องเสียงสลักว่า \"เอ่ยรหัสผนึก\"", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "คัมภีร์บนโต๊ะนี้เป็นของอาจารย์ ท่านชอบจดทุกอย่างไว้ในคำจารึก", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "อย่าเดามั่วล่ะ ประตูผนึกจะสะท้อนพลังกลับใส่คนที่เอ่ยรหัสผิด", "mewla_anim": "talk"},
			{"type": "open_gameplay", "step": 1}
		],

		"gameplay": {
			1: {
				"title": "ประตูผนึก",
				"story": "ประตูชั้นเจ็ดต้องการรหัสผนึกที่ปรมาจารย์เคยจารึกไว้ เอ่ยรหัสด้วย say <รหัส>",
				"panels": ["terminal", "files", "graph"],
				"setup": setup,
				"room": {
					"hearts": 3, "wave_every": 4, "wrong_say": 1, "respawn": true,
					"items": {
						"journal.txt": {"kind": "note", "name": "บันทึกของอาจารย์"},
						"seal.txt": {"kind": "note", "name": "แผ่นผนึก"},
						"fragment-3.txt": {"kind": "fragment", "name": "เศษคัมภีร์ชิ้นที่ 3"}
					}
				},
				"objectives": [
					{
						"id": "seal",
						"text": "เอ่ยรหัสผนึกที่ปรมาจารย์จารึกไว้ (say <รหัส>)",
						"short": "เปิดประตูผนึก",
						"type": "say",
						"words": ["aurora"],
						"world": "ประตูหินสั่นสะเทือน แล้วเลื่อนเปิด… กระดาษแผ่นหนึ่งปลิวออกมาตกบนโต๊ะ",
						"hint": "รหัสไม่อยู่ในไฟล์ใดเลย อยู่ใน \"คำจารึก\" ของการจารึกครั้งหนึ่ง — git log --oneline แล้วมองหาคำว่ารหัสผนึก",
						"spawn": [{"write": "fragment-3.txt", "content": "ย่อมสูญหายไปกับกาลเวลา\n"}]
					},
					{
						"id": "keep",
						"text": "จารึกเศษคัมภีร์ที่หลุดออกมาจากประตู ก่อนคลื่นโกลาหลจะมาถึง",
						"short": "จารึกเศษชิ้นที่ 3",
						"type": "state",
						"check": "committed",
						"paths": ["fragment-3.txt"],
						"count": 8,
						"world": "ได้รับเศษคัมภีร์ชิ้นที่ 3: \"ย่อมสูญหายไปกับกาลเวลา\"",
						"hint": "add แล้ว commit เหมือนชั้นก่อน ๆ"
					}
				],
				"success_text": "ประตูชั้นเจ็ดเปิดแล้ว!"
			}
		},

		"outro_sequence": [
			{"speaker": "เวล", "text": "\"ถ้ามีใครอ่านอยู่… จงตามเศษคัมภีร์ขึ้นไป\" — อาจารย์รู้ว่าจะมีคนตามมา", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "คำจารึกที่ดีช่วยให้คนรุ่นหลังหาเจอ… นายเองก็จารึกให้ดีแบบท่านนะ", "mewla_anim": "talk"}
		]
	}
