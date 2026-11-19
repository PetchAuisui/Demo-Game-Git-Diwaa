class_name Level04Dialogue
extends RefCounted

## ด่านที่ 4: แท่นเตรียม (git add) — Game Design v2
## ปัญหาในโลก: เศษคัมภีร์ชิ้นที่ 1 แตกเป็นสามส่วน ต้องวางบนแท่นเตรียมให้ครบจึงจะหลอมกลับ
## ตรวจจากสถานะ stage จริง และต้องใช้คาถา add


static func get_data() -> Dictionary:
	return {
		"level_id": 4,
		"title": "ด่านที่ 4: แท่นเตรียม",
		"time_limit": 100.0,
		"max_score": 130,
		"commands": ["git add"],
		"clear_keyword": "git add <ไฟล์> หรือ git add . เพื่อนำการเปลี่ยนแปลงขึ้น staging area ก่อนจารึก",

		"intro_sequence": [
			{"speaker": "เวล", "text": "นั่นไง! กระดาษสามแผ่นเรืองแสงอยู่บนโต๊ะ", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "เศษคัมภีร์ชิ้นที่ 1 ที่แตกเป็นสามส่วน… วางมันบนแท่นเตรียมให้ครบ แล้วมันจะหลอมกลับ", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "แท่นเตรียมให้นายเลือกได้ว่าจะจารึกชิ้นไหน ลองวางทีละชิ้นก่อน", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 1}
		],

		"gameplay": {
			1: {
				"title": "แท่นเตรียม",
				"story": "เศษคัมภีร์ชิ้นที่ 1 แตกเป็นสามส่วนบนโต๊ะ วางขึ้นแท่นเตรียมให้ครบเพื่อหลอมกลับ",
				"panels": ["terminal", "files"],
				"setup": [
					{"run": "git config --global user.name \"Vel\""},
					{"run": "git config --global user.email \"vel@magic-tower.local\""},
					{"run": "git init"},
					{"write": "miura-note.txt", "content": "อย่าลืมให้อาหารแมว\n"},
					{"run": "git add ."},
					{"run": "git commit -m \"บันทึกของมิวรา\""},
					{"write": "fragment-1a.txt", "content": "ศิษย์\n"},
					{"write": "fragment-1b.txt", "content": "ของ\n"},
					{"write": "fragment-1c.txt", "content": "ข้า…\n"}
				],
				"objectives": [
					{
						"id": "first",
						"text": "วางส่วนแรก fragment-1a.txt ขึ้นแท่นเตรียม (git add <ไฟล์>)",
						"short": "วางส่วนแรกขึ้นแท่น",
						"type": "state",
						"check": "staged",
						"paths": ["fragment-1a.txt"],
						"spell": "add",
						"world": "กระดาษแผ่นแรกลอยขึ้นจากโต๊ะ ไปหมุนวนเหนือแท่นเตรียม",
						"hint": "git add ตามด้วยชื่อไฟล์ เช่น git add fragment-1a.txt"
					},
					{
						"id": "rest",
						"text": "วางส่วนที่เหลือทั้งหมดขึ้นแท่นในคาถาเดียว (git add .)",
						"short": "วางที่เหลือทั้งหมด",
						"type": "state",
						"check": "staged",
						"paths": ["fragment-1a.txt", "fragment-1b.txt", "fragment-1c.txt"],
						"spell": "add",
						"world": "สามส่วนหมุนวนเร็วขึ้น… แล้วหลอมรวมเป็นเศษคัมภีร์ชิ้นที่ 1!",
						"hint": "จุด (.) แปลว่า 'ทุกอย่างในโฟลเดอร์นี้' — git add ."
					}
				],
				"success_text": "ได้รับเศษคัมภีร์ชิ้นที่ 1: \"ศิษย์ของข้า…\""
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "ได้ชิ้นแรกแล้ว! แต่จำไว้ มันยังอยู่แค่บนแท่นเตรียม ยังไม่ถูกจารึก", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "ถ้าไม่จารึกจะเป็นยังไง?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ไปดูชั้นถัดไปก็รู้", "mewla_anim": "success"}
		]
	}
