class_name Level04Dialogue
extends RefCounted

## ด่านที่ 4: แท่นเตรียม (git add) — มินิเกม "แท่นที่ต้องเลือก"
## เศษคัมภีร์ชิ้นที่ 1 แตกสามส่วนอยู่บนโต๊ะพร้อม "ม้วนคำสาป"
## มิวรากางโล่ป้องกันแท่นเตรียมไว้ (safe = staged): ของบนแท่นรอดคลื่น ของบนโต๊ะสลาย
## แต่ถ้าม้วนคำสาปอยู่บนแท่นตอนคลื่นมา มันจะระเบิด → git add . แบบไม่ดูคือกับดัก ต้องเลือกขึ้นแท่นเอง


static func get_data() -> Dictionary:
	return {
		"level_id": 4,
		"title": "ด่านที่ 4: แท่นเตรียม",
		"time_limit": 100.0,
		"max_score": 130,
		"commands": ["git add"],
		"clear_keyword": "git add <ไฟล์> เลือกเฉพาะสิ่งที่จะจารึกขึ้น staging area — git add . เอาทุกอย่าง รวมถึงของที่ไม่ต้องการ",

		"intro_sequence": [
			{"speaker": "เวล", "text": "นั่นไง! กระดาษสามแผ่นเรืองแสงอยู่บนโต๊ะ… แล้วม้วนสีดำนั่นอะไร?", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ม้วนคำสาป อย่าแตะมัน! ส่วนสามแผ่นนั่นคือเศษคัมภีร์ชิ้นที่ 1 ที่แตกออก", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ฉันจะกางโล่ไว้ที่แท่นเตรียม ของบนแท่นจะรอดจากคลื่น แต่ของบนโต๊ะไม่รอด", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "วางเศษทั้งสามขึ้นแท่นให้ได้ — และอย่าเผลอเอาม้วนคำสาปขึ้นไปด้วยล่ะ มันจะระเบิด", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 1}
		],

		"gameplay": {
			1: {
				"title": "แท่นที่ต้องเลือก",
				"story": "เศษคัมภีร์สามส่วนกับม้วนคำสาปอยู่บนโต๊ะ — วางเฉพาะเศษคัมภีร์ขึ้นแท่นที่มีโล่ป้องกัน",
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
					{"write": "fragment-1c.txt", "content": "ข้า…\n"},
					{"write": "curse.txt", "content": "☠ ผู้ใดวางม้วนนี้บนแท่น แท่นจะแตกสลาย ☠\n"}
				],
				"room": {
					"hearts": 3, "wave_every": 3, "safe": "staged", "respawn": true,
					"items": {
						"fragment-1a.txt": {"kind": "fragment", "name": "เศษชิ้นที่ 1 · ส่วนแรก"},
						"fragment-1b.txt": {"kind": "fragment", "name": "เศษชิ้นที่ 1 · ส่วนกลาง"},
						"fragment-1c.txt": {"kind": "fragment", "name": "เศษชิ้นที่ 1 · ส่วนท้าย"},
						"curse.txt": {"kind": "curse", "name": "ม้วนคำสาป"},
						"miura-note.txt": {"kind": "note", "name": "บันทึกมิวรา"}
					}
				},
				"objectives": [
					{
						"id": "first",
						"text": "ช่วยส่วนแรกขึ้นไปอยู่ใต้โล่ก่อนคลื่นแรกมา",
						"short": "ส่วนแรกขึ้นแท่น",
						"type": "state",
						"check": "staged",
						"paths": ["fragment-1a.txt"],
						"exclude": ["curse.txt"],
						"spell": "add",
						"world": "กระดาษแผ่นแรกลอยขึ้นไปหมุนวนใต้โล่ของมิวรา",
						"hint": "คาถาวางขึ้นแท่นคือ add ระบุชื่อไฟล์ต่อท้าย: git add fragment-1a.txt"
					},
					{
						"id": "rest",
						"text": "วางอีกสองส่วนให้ครบ โดยไม่ให้ม้วนคำสาปขึ้นแท่น",
						"short": "ครบสามส่วน ไม่มีคำสาป",
						"type": "state",
						"check": "staged",
						"paths": ["fragment-1a.txt", "fragment-1b.txt", "fragment-1c.txt"],
						"exclude": ["curse.txt"],
						"spell": "add",
						"world": "สามส่วนหมุนวนเร็วขึ้น… แล้วหลอมรวมเป็นเศษคัมภีร์ชิ้นที่ 1!",
						"hint": "git add . จะลากม้วนคำสาปขึ้นไปด้วย — ระบุชื่อทีละไฟล์ (ใส่หลายไฟล์ในคาถาเดียวได้)",
						"near_miss": [
							{"pattern": "^git\\s+add\\s+(\\.|-A|--all)\\s*$", "message": "ระวัง! คาถานี้ลากม้วนคำสาปขึ้นแท่นด้วย"}
						]
					}
				],
				"success_text": "ได้รับเศษคัมภีร์ชิ้นที่ 1: \"ศิษย์ของข้า…\""
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "เลือกได้ดี — แท่นเตรียมมีไว้ให้นายเลือกว่าอะไรควรถูกจารึก ไม่ใช่โกยทุกอย่างขึ้นไป", "mewla_anim": "success"},
			{"speaker": "มิวรา", "text": "แต่โล่ของฉันอยู่ได้แค่ชั้นนี้… ชั้นหน้าแท่นเตรียมจะไม่ปลอดภัยอีกแล้ว", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "แล้วอะไรถึงจะปลอดภัย?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "สิ่งที่ถูกจารึกลงคัมภีร์แล้วเท่านั้น", "mewla_anim": "talk"}
		]
	}
