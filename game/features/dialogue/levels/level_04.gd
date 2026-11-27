class_name Level04Dialogue
extends RefCounted

## ด่านที่ 4: แท่นเตรียม (git add) — มินิเกม "แท่นที่ต้องเลือก"
## เศษคัมภีร์ชิ้นที่ 1 แตกสามส่วนอยู่บนผ้าปูพร้อม "ม้วนคำสาป"
## มิวรากางโล่ป้องกันแท่นเตรียมไว้ (safe = staged): ของบนแท่นรอดคลื่น ของบนผ้าปูสลาย
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
			{"speaker": "เวล", "text": "นั่นไง! กระดาษสามแผ่นเรืองแสงอยู่บนผ้าปู… แล้วม้วนสีดำนั่นอะไร?", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ม้วนคำสาป อย่าแตะมัน! ส่วนสามแผ่นนั่นคือเศษคัมภีร์ชิ้นที่ 1 ที่แตกออก", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ฉันจะกางโล่ไว้ที่แท่นเตรียม ของบนแท่นจะรอดจากคลื่น แต่ของบนผ้าปูไม่รอด", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "วางเศษทั้งสามขึ้นแท่นให้ได้ — และอย่าเผลอเอาม้วนคำสาปขึ้นไปด้วยล่ะ มันจะระเบิด", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 1}
		],

		"gameplay": {
			1: {
				"title": "แท่นที่ต้องเลือก",
				"story": "เศษคัมภีร์ชิ้นที่ 1 แตกเป็นสามส่วนอยู่บนผ้าปูพร้อมม้วนคำสาป — วางเฉพาะเศษคัมภีร์ทั้งสามส่วนขึ้นแท่นเตรียม",
				"panels": ["terminal", "files"],
				# ม้วนคาถาที่แจกตอนเริ่มขั้นนี้ (SpellCatalog)
				"teaches": ["add"],
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
					{"write": "curse.txt", "content": "[ม้วนคำสาป] ผู้ใดวางม้วนนี้บนแท่น แท่นจะแตกสลาย\n"}
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
						"text": "วางส่วนแรก (fragment-1a.txt) ขึ้นแท่นเตรียม ให้โล่ของมิวราปกป้องไว้ก่อนคลื่นมา",
						"short": "วางส่วนแรกขึ้นแท่น (fragment-1a)",
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
						"text": "วางส่วนกลางและส่วนท้าย (fragment-1b.txt, fragment-1c.txt) ขึ้นแท่น — ห้ามเอาม้วนคำสาป (curse.txt) ขึ้นไปด้วย",
						"short": "วางส่วนกลาง + ส่วนท้ายขึ้นแท่น (ไม่เอาม้วนคำสาป)",
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
			},
			2: {
				"title": "ประกายเวท",
				"story": "การหลอมรวมปล่อยประกายเวทห้าดวงลงบนผ้าปู ทุกดวงต้องขึ้นแท่นพร้อมกันก่อนคลื่นมา",
				"panels": ["terminal", "files"],
				# ม้วนคาถาใหม่: ยกทั้งผืน (git add .) — ตรงข้ามกับขั้นที่ 1 ที่ add . คือกับดัก
				"teaches": ["add_all"],
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
					{"run": "git add fragment-1a.txt fragment-1b.txt fragment-1c.txt"},
					{"write": "spark-1.txt", "content": "ประกายเวทดวงที่ ๑ ✦\n"},
					{"write": "spark-2.txt", "content": "ประกายเวทดวงที่ ๒ ✦\n"},
					{"write": "spark-3.txt", "content": "ประกายเวทดวงที่ ๓ ✦\n"},
					{"write": "spark-4.txt", "content": "ประกายเวทดวงที่ ๔ ✦\n"},
					{"write": "spark-5.txt", "content": "ประกายเวทดวงที่ ๕ ✦\n"}
				],
				"room": {
					"hearts": 3, "wave_every": 2, "safe": "staged", "respawn": true,
					"items": {
						"fragment-1a.txt": {"kind": "fragment", "name": "เศษชิ้นที่ 1 · ส่วนแรก"},
						"fragment-1b.txt": {"kind": "fragment", "name": "เศษชิ้นที่ 1 · ส่วนกลาง"},
						"fragment-1c.txt": {"kind": "fragment", "name": "เศษชิ้นที่ 1 · ส่วนท้าย"},
						"miura-note.txt": {"kind": "note", "name": "บันทึกมิวรา"},
						"spark-1.txt": {"kind": "fragment", "name": "ประกายเวท ๑"},
						"spark-2.txt": {"kind": "fragment", "name": "ประกายเวท ๒"},
						"spark-3.txt": {"kind": "fragment", "name": "ประกายเวท ๓"},
						"spark-4.txt": {"kind": "fragment", "name": "ประกายเวท ๔"},
						"spark-5.txt": {"kind": "fragment", "name": "ประกายเวท ๕"}
					}
				},
				"objectives": [
					{
						"id": "sparks",
						"text": "วางประกายเวททั้งห้าดวงขึ้นแท่นพร้อมกันในคาถาเดียว ก่อนคลื่นจะมาดับมัน",
						"short": "วางประกายเวททั้งห้าขึ้นแท่น (คาถาเดียว)",
						"type": "state",
						"check": "staged",
						"paths": ["spark-1.txt", "spark-2.txt", "spark-3.txt", "spark-4.txt", "spark-5.txt"],
						"spell": "add",
						"world": "ประกายทั้งห้าลอยขึ้นแท่นพร้อมกัน แล้วซึมเข้าสู่เศษคัมภีร์ชิ้นที่ 1 — มันเปล่งแสงแรงขึ้น",
						"hint": "บนผ้าปูเหลือแต่ของที่ต้องการทั้งหมด ไม่มีของต้องห้ามแล้ว — ยกทั้งผืนด้วย git add . (จุด = ทุกอย่างในโฟลเดอร์นี้)"
					}
				],
				"success_text": "เศษคัมภีร์ชิ้นที่ 1 ได้รับพลังจากประกายเวทครบแล้ว!"
			}
		},

		"part2_intro_sequence": [
			{"speaker": "เวล", "text": "เศษคัมภีร์หลอมรวมแล้ว… เดี๋ยว! มีประกายเล็ก ๆ พุ่งออกมาเต็มผ้าปู!", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ประกายเวทจากการหลอมรวม ห้าดวง! ถ้ายังค้างบนผ้าปูตอนคลื่นมา มันจะดับหมด", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "คราวนี้บนผ้าปูไม่มีของต้องห้ามแล้ว ยกทั้งผืนขึ้นแท่นในคาถาเดียวได้เลย — วางทีละดวงไม่ทันแน่", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 2}
		],

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "เห็นไหม บางทีต้องเลือกขึ้นแท่นทีละชิ้น บางทีก็ยกทั้งผืนได้ — ดูให้ดีก่อนเสมอว่าบนผ้าปูมีอะไร", "mewla_anim": "success"},
			{"speaker": "มิวรา", "text": "แต่โล่ของฉันอยู่ได้แค่ชั้นนี้… ชั้นหน้าแท่นเตรียมจะไม่ปลอดภัยอีกแล้ว", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "แล้วอะไรถึงจะปลอดภัย?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "สิ่งที่ถูกจารึกลงคัมภีร์แล้วเท่านั้น", "mewla_anim": "talk"}
		]
	}
