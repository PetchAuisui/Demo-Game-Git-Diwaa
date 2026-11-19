class_name Level11Dialogue
extends RefCounted

## ด่านที่ 11: ประตูมิติ (git switch) — มินิเกม "ครึ่งกุญแจจันทรา"
## ครึ่งกุญแจจันทราก่อตัวได้เฉพาะในมิติ experiment → ต้องข้ามมิติ (switch) และจารึกมันที่นั่น
## ก่อนคลื่นจะกวาดมันไป จากนั้นกลับ main แล้วเห็นว่ามัน "หายไป" (แต่ละมิติมีโลกของตัวเอง)
## ปิดท้ายด้วยการเปิดและก้าวเข้ามิติใหม่ในคาถาเดียว (switch -c)


static func get_data() -> Dictionary:
	return {
		"level_id": 11,
		"title": "ด่านที่ 11: ประตูมิติ",
		"time_limit": 80.0,
		"max_score": 200,
		"commands": ["git switch"],
		"clear_keyword": "git switch <มิติ> ย้ายไปอีก branch (ไฟล์เปลี่ยนตาม) · git switch -c <ใหม่> สร้างแล้วย้ายทันที",

		"intro_sequence": [
			{"speaker": "มิวรา", "text": "ได้ยินไหม… มีเสียงเรียกจากรอยแยกสีฟ้า มิติ experiment ของนาย", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ครึ่งกุญแจจันทราก่อตัวได้แค่ในมิตินั้น ข้ามไปเอามันมา แล้วจารึกไว้ก่อนคลื่นจะกวาดไป", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 1}
		],

		"gameplay": {
			1: {
				"title": "ครึ่งกุญแจจันทรา",
				"story": "ครึ่งกุญแจจันทราอยู่ในมิติ experiment เท่านั้น — ข้ามมิติไปจารึกมันไว้",
				"panels": ["terminal", "files", "graph"],
				# ม้วนคาถาที่แจกตอนเริ่มขั้นนี้ (SpellCatalog)
				"teaches": ["switch", "switch_create"],
				"setup": Level10Dialogue.BASE + [
					{"write": "fragment-7.txt", "content": "เส้นทางมีมากกว่าหนึ่งเสมอ\n"},
					{"run": "git add ."},
					{"run": "git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 7\""},
					{"run": "git branch experiment"}
				],
				"room": {"hearts": 3, "wave_every": 3, "respawn": true,
					"items": {
						"key-moon.txt": {"kind": "key", "name": "ครึ่งกุญแจจันทรา"},
						"fragment-7.txt": {"kind": "fragment", "name": "เศษคัมภีร์ชิ้นที่ 7"}
					}},
				"objectives": [
					{
						"id": "cross",
						"text": "ก้าวผ่านประตูเข้าสู่มิติ experiment",
						"short": "ข้ามไปมิติ experiment",
						"type": "state",
						"check": "current_branch",
						"branch": "experiment",
						"world": "โลกรอบตัวกระพริบเป็นสีฟ้า… ครึ่งกุญแจจันทราค่อย ๆ ก่อตัวบนโต๊ะ",
						"hint": "คาถาประตูมิติคือ switch: git switch experiment",
						"spawn": [{"write": "key-moon.txt", "content": "ครึ่งกุญแจจันทรา ☾\n"}]
					},
					{
						"id": "keep_key",
						"text": "จารึกครึ่งกุญแจไว้ในมิตินี้ก่อนคลื่นจะกวาดมันไป",
						"short": "จารึกครึ่งกุญแจ",
						"type": "state",
						"check": "committed",
						"paths": ["key-moon.txt"],
						"world": "ครึ่งกุญแจถูกจารึกลงคัมภีร์ของมิติ experiment",
						"hint": "add แล้ว commit ตามปกติ — การจารึกจะอยู่ในมิติที่นายยืนอยู่"
					},
					{
						"id": "back",
						"text": "กลับมิติหลัก main แล้วดูว่าเกิดอะไรกับครึ่งกุญแจ",
						"short": "กลับ main",
						"type": "state",
						"check": "current_branch",
						"branch": "main",
						"world": "ครึ่งกุญแจหายไปจากโต๊ะ! — ไม่ได้หายจริง มันอยู่ในมิติ experiment แต่ละมิติมีโลกของตัวเอง",
						"hint": "git switch main"
					},
					{
						"id": "new_dimension",
						"text": "เปิดมิติใหม่ชื่อ trial และก้าวเข้าไปในคาถาเดียว",
						"short": "สร้างและเข้า trial",
						"type": "state",
						"check": "current_branch",
						"branch": "trial",
						"spell": "switch",
						"flags": ["-c"],
						"world": "ได้รับเศษคัมภีร์ชิ้นที่ 8: \"จงกล้าลองในโลกคู่ขนาน\"",
						"hint": "switch มีตัวเลือก -c (create): git switch -c trial"
					}
				],
				"success_text": "ได้รับเศษคัมภีร์ชิ้นที่ 8!"
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "switch -c = branch + switch ในคาถาเดียว นักเวทขี้เกียจชอบใช้", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "แต่ครึ่งกุญแจยังติดอยู่ในอีกมิติ… ประตูชั้นบนต้องใช้กุญแจทั้งดวงแน่ ๆ", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "งั้นเราก็ต้องหลอมสองมิติเข้าด้วยกัน", "mewla_anim": "success"}
		]
	}
