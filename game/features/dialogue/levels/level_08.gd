class_name Level08Dialogue
extends RefCounted

## ด่านที่ 8: คาถาฟื้นคืน (git restore) — มินิเกม "คำสาปสองทาง"
## เศษคัมภีร์ชิ้นที่ 5 ถูกสาป (เนื้อหาเพี้ยน) และม้วนคำสาปแอบขึ้นแท่นเตรียม
## คลื่นถัดไปมาในอีก 3 การกระทำ: เศษที่ถูกสาปจะถูกกัดซ้ำ และคำสาปบนแท่นจะระเบิด
## → ต้องฟื้นคืนเศษคัมภีร์จากคัมภีร์ (restore) และเอาคำสาปลงจากแท่น (restore --staged) ให้ทัน
## จารึกทับของที่ถูกสาปไม่นับว่าฟื้นคืน (max_count)


static func get_data() -> Dictionary:
	return {
		"level_id": 8,
		"title": "ด่านที่ 8: คาถาฟื้นคืน",
		"time_limit": 90.0,
		"max_score": 170,
		"commands": ["git restore"],
		"clear_keyword": "git restore <ไฟล์> คืนไฟล์ให้เหมือนที่ commit ไว้ · git restore --staged <ไฟล์> นำออกจาก staging area",

		"intro_sequence": [
			{"speaker": "เวล", "text": "เศษคัมภีร์ชิ้นที่ 5 … อักขระมันแตกเป็นรอยหยักไปหมด!", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "แล้วดูบนแท่นเตรียมสิ ม้วนสีดำแอบขึ้นไปอยู่บนนั้นแล้ว", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "คลื่นลูกหน้าจะกัดเศษที่ถูกสาปซ้ำ และระเบิดม้วนบนแท่น — แต่คัมภีร์ยังจำฉบับที่ถูกต้องไว้นะ", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 1}
		],

		"gameplay": {
			1: {
				"title": "คำสาปสองทาง",
				"story": "เศษคัมภีร์ชิ้นที่ 5 ถูกสาป และม้วนคำสาปอยู่บนแท่นเตรียม — แก้ทั้งสองอย่างก่อนคลื่นมา",
				"panels": ["terminal", "files", "graph"],
				# ม้วนคาถาที่แจกตอนเริ่มขั้นนี้ (SpellCatalog)
				"teaches": ["restore", "restore_staged"],
				"setup": [
					{"run": "git config --global user.name \"Vel\""},
					{"run": "git config --global user.email \"vel@magic-tower.local\""},
					{"run": "git init"},
					{"write": "fragment-4.txt", "content": "จงสังเกตทุกรอยที่เปลี่ยนไป\n"},
					{"run": "git add ."},
					{"run": "git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 4\""},
					{"write": "fragment-5.txt", "content": "ความผิดพลาดแก้ไขได้เสมอ\n"},
					{"run": "git add ."},
					{"run": "git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 5\""},
					{"write": "fragment-5.txt", "content": RoomGame.CORRUPTED_TEXT},
					{"write": "curse.txt", "content": "[ม้วนคำสาป] ผู้ใดจารึกม้วนนี้ คัมภีร์จะเป็นของโกลาหล\n"},
					{"run": "git add curse.txt"}
				],
				"room": {
					"hearts": 3, "wave_every": 3, "cursed": ["fragment-5.txt"],
					"items": {
						"fragment-4.txt": {"kind": "fragment", "name": "เศษคัมภีร์ชิ้นที่ 4"},
						"fragment-5.txt": {"kind": "fragment", "name": "เศษคัมภีร์ชิ้นที่ 5"},
						"curse.txt": {"kind": "curse", "name": "ม้วนคำสาป"}
					}
				},
				"objectives": [
					{
						"id": "heal",
						"text": "ฟื้นเศษคัมภีร์ชิ้นที่ 5 (fragment-5.txt) ที่ถูกสาป ให้กลับเป็นฉบับที่จารึกไว้ในคัมภีร์",
						"short": "ฟื้นเศษชิ้นที่ 5 กลับเป็นฉบับที่จารึก",
						"type": "state",
						"check": "committed",
						"paths": ["fragment-5.txt"],
						"max_count": 2,
						"world": "รอยหยักสลายเป็นผงแสง อักขระเดิมกลับมาชัดเจน",
						"hint": "คัมภีร์จำฉบับที่ถูกต้องไว้ คาถาฟื้นคืนคือ restore: git restore fragment-5.txt",
						"near_miss": [
							{"pattern": "^git\\s+commit", "message": "จารึกทับของที่ถูกสาปไม่ได้ฟื้นคืนมัน — มันแค่ทำให้คำสาปกลายเป็นประวัติ"}
						]
					},
					{
						"id": "unstage_curse",
						"text": "เอาม้วนคำสาป (curse.txt) ลงจากแท่นเตรียม — ห้ามจารึกมัน",
						"short": "เอาม้วนคำสาปลงจากแท่น (ห้ามจารึก)",
						"type": "state",
						"check": "not_staged",
						"paths": ["curse.txt"],
						"max_count": 2,
						"world": "ม้วนสีดำหล่นลงจากแท่น ไร้พลังเมื่อไม่มีใครวางมันขึ้นไป — ได้รับเศษคัมภีร์ชิ้นที่ 5",
						"hint": "restore ทำได้มากกว่าฟื้นคืนของบนผ้าปู ใส่ตัวเลือกที่หมายถึงแท่นเตรียม: git restore --staged curse.txt"
					}
				],
				"success_text": "ได้รับเศษคัมภีร์ชิ้นที่ 5: \"ความผิดพลาดแก้ไขได้เสมอ\""
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "restore ทิ้งการแก้ไขบนผ้าปูจริง ๆ นะ ใช้เมื่อแน่ใจว่าไม่ต้องการมันแล้ว", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "\"ความผิดพลาดแก้ไขได้เสมอ\" … อาจารย์คงรู้ว่าฉันจะพลาดบ่อยแน่ ๆ", "mewla_anim": "idle"}
		]
	}
