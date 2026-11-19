class_name Level05Dialogue
extends RefCounted

## ด่านที่ 5: การจารึกครั้งแรก (git commit) — Game Design v2
## ปัญหาในโลก: เศษคัมภีร์ชิ้นที่ 1 บนแท่นเตรียมสั่นจะสลาย → ต้องจารึก
## จากนั้นเศษชิ้นที่ 2 ซ่อนอยู่ในชิ้นแรก (ไฟล์ที่ถูก track แล้วถูกแก้) → จารึกด้วย -a โดยไม่ต้อง add

const ALTAR_READY := [
	{"run": "git config --global user.name \"Vel\""},
	{"run": "git config --global user.email \"vel@magic-tower.local\""},
	{"run": "git init"},
	{"write": "miura-note.txt", "content": "อย่าลืมให้อาหารแมว\n"},
	{"run": "git add ."},
	{"run": "git commit -m \"บันทึกของมิวรา\""},
	{"write": "fragment-1a.txt", "content": "ศิษย์\n"},
	{"write": "fragment-1b.txt", "content": "ของ\n"},
	{"write": "fragment-1c.txt", "content": "ข้า…\n"},
	{"run": "git add ."},
]


static func get_data() -> Dictionary:
	return {
		"level_id": 5,
		"title": "ด่านที่ 5: การจารึกครั้งแรก",
		"time_limit": 115.0,
		"max_score": 140,
		"commands": ["git commit"],
		"clear_keyword": "git commit -m บันทึกสิ่งที่อยู่บน stage เป็นเวอร์ชันถาวร · git commit -am จารึกไฟล์ที่ถูกแก้โดยไม่ต้อง add",

		"intro_sequence": [
			{"speaker": "มิวรา", "text": "ดูสิ! เศษคัมภีร์ชิ้นที่ 1 บนแท่นเตรียมเริ่มสั่นแล้ว", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ถ้าไม่จารึกลงคัมภีร์ พลังของมันจะสลาย — และอย่าลืมคำจารึก อนาคตนายจะได้รู้ว่าจารึกอะไรไว้", "mewla_anim": "talk"},
			{"type": "open_gameplay", "step": 1}
		],

		"part2_intro_sequence": [
			{"speaker": "เวล", "text": "เดี๋ยวนะ… มีอักขระใหม่ปรากฏต่อท้าย fragment-1c!", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "เศษคัมภีร์ชิ้นที่ 2 ซ่อนอยู่ในชิ้นแรก! ไฟล์นี้คัมภีร์รู้จักอยู่แล้ว นายจารึกข้ามแท่นได้เลยในคาถาเดียว", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 2}
		],

		"gameplay": {
			1: {
				"title": "การจารึกครั้งแรก",
				"story": "เศษคัมภีร์ชิ้นที่ 1 บนแท่นเตรียมสั่นจะสลาย จารึกลงคัมภีร์พร้อมคำจารึก",
				"panels": ["terminal", "files", "graph"],
				"setup": ALTAR_READY,
				"objectives": [
					{
						"id": "inscribe",
						"text": "จารึกทุกอย่างบนแท่นเตรียมพร้อมคำจารึก (git commit -m \"...\")",
						"short": "จารึกพร้อมคำจารึก",
						"type": "state",
						"check": "committed",
						"paths": ["fragment-1a.txt", "fragment-1b.txt", "fragment-1c.txt"],
						"count": 2,
						"spell": "commit",
						"world": "แสงสีทองจารึกลงบนหน้ากระดาษ เศษคัมภีร์หยุดสั่น",
						"hint": "git commit -m แล้วตามด้วยคำจารึกในเครื่องหมายคำพูด",
						"near_miss": [
							{"pattern": "^git\\s+commit\\s+-m\\s*$", "message": "ต้องมีคำจารึกต่อท้าย -m ในเครื่องหมายคำพูด"},
							{"pattern": "^git\\s+comit", "message": "สะกดว่า commit (m สองตัว)"}
						]
					}
				],
				"success_text": "เศษคัมภีร์ชิ้นที่ 1 ถูกจารึกอย่างถาวรแล้ว!"
			},
			2: {
				"title": "เศษที่ซ่อนอยู่",
				"story": "fragment-1c.txt เผยอักขระใหม่ — จารึกการแก้ไขนี้ทันทีโดยไม่ต้องวางขึ้นแท่นก่อน",
				"panels": ["terminal", "files", "graph"],
				"setup": ALTAR_READY + [
					{"run": "git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 1\""},
					{"write": "fragment-1c.txt", "content": "ข้า…\nความรู้ที่ไม่ถูกจารึก\n"}
				],
				"objectives": [
					{
						"id": "skip_altar",
						"text": "จารึกการแก้ไขในคาถาเดียว ไม่ต้อง add ก่อน (git commit -am \"...\")",
						"short": "จารึกข้ามแท่นเตรียม",
						"type": "state",
						"check": "committed",
						"paths": ["fragment-1c.txt"],
						"count": 3,
						"spell": "commit",
						"flags": ["-a", "-am"],
						"world": "หน้าที่สองของคัมภีร์เรืองแสง — ได้รับเศษคัมภีร์ชิ้นที่ 2: \"ความรู้ที่ไม่ถูกจารึก\"",
						"hint": "เพิ่ม -a (all) เข้าไปในคาถาจารึก: git commit -am \"คำจารึก\""
					}
				],
				"success_text": "สองชิ้นในคราวเดียว!"
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "ไม่เลวเลยศิษย์ฝึกหัด -a ใช้ได้เฉพาะไฟล์ที่คัมภีร์รู้จักแล้วนะ ไฟล์ใหม่ยังต้อง add ก่อน", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "\"ศิษย์ของข้า… ความรู้ที่ไม่ถูกจารึก\" — นี่มันข้อความของอาจารย์!", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ถ้าอยากรู้ประโยคที่เหลือ ก็ต้องปีนต่อไป", "mewla_anim": "success"}
		]
	}
