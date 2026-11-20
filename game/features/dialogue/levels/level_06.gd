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


static func _identity(name: String, email: String) -> Array:
	return [
		{"run": "git config --global user.name \"%s\"" % name},
		{"run": "git config --global user.email \"%s\"" % email},
	]


## ขั้นที่ 2: ม้วนประวัติยาว (เวรยามหลายคืน) — รหัสผนึกชั้นในอยู่ในการจารึกรองสุดท้าย
static func _long_history() -> Array:
	var setup: Array = _identity(MASTER, "master@magic-tower.local") + [{"run": "git init"}]
	for night in range(1, 16):
		setup.append_array(_master_page("เวรยามคืนที่ %d: ทุกอย่างปกติ" % night, "watch.txt", "เวรยามล่าสุด: คืนที่ %d\n" % night))
	setup.append_array(_master_page("เปลี่ยนรหัสผนึกชั้นใน รหัสใหม่: lumen", "inner-seal.txt", "ผนึกชั้นใน: เปลี่ยนรหัสแล้ว\n"))
	setup.append_array(_master_page("ออกตรวจรอยร้าวชั้นล่าง", "watch.txt", "เวรยามล่าสุด: ออกตรวจชั้นล่าง\n"))
	return setup + _identity("Vel", "vel@magic-tower.local")


## ขั้นที่ 3: รหัสห้องลับอยู่ในมิติ hidden-archive ที่ไม่ใช่มิติที่ยืนอยู่ (git log เฉย ๆ มองไม่เห็น)
static func _hidden_dimension() -> Array:
	var setup: Array = _identity(MASTER, "master@magic-tower.local") + [{"run": "git init"}]
	setup.append_array(_master_page("เริ่มบันทึกห้องชั้นเจ็ด", "journal.txt", "ห้องชั้นเจ็ด\n"))
	setup.append({"run": "git switch -c hidden-archive"})
	setup.append_array(_master_page("ซ่อนตำราไว้ในห้องลับ รหัสห้องลับ: nyx", "archive.txt", "ตำราลับของปรมาจารย์\n"))
	setup.append({"run": "git switch main"})
	setup.append_array(_master_page("ปิดทางเข้าห้องลับ ไม่ให้ใครพบ", "journal.txt", "ห้องชั้นเจ็ด\nทางเข้าห้องลับถูกปิดแล้ว\n"))
	setup.append_array(_master_page("จัดชั้นหนังสือใหม่", "journal.txt", "ห้องชั้นเจ็ด\nทางเข้าห้องลับถูกปิดแล้ว\nจัดชั้นหนังสือแล้ว\n"))
	return setup + _identity("Vel", "vel@magic-tower.local")


static func get_data() -> Dictionary:
	var setup: Array = [
		{"run": "git config --global user.name \"%s\"" % MASTER},
		{"run": "git config --global user.email \"master@magic-tower.local\""},
		{"run": "git init"},
	]
	setup.append_array(_master_page("เริ่มศึกษาคัมภีร์เวทต้นกำเนิด", "journal.txt", "วันแรกของการศึกษา\n"))
	setup.append_array(_master_page("รับศิษย์ฝึกหัดคนใหม่ชื่อเวล", "apprentices.txt", "ศิษย์: เวล\n"))
	setup.append_array(_master_page("พบรอยร้าวบนคัมภีร์ต้นกำเนิด", "journal.txt", "วันแรกของการศึกษา\nรอยร้าวลามเร็วผิดปกติ\n"))
	setup.append_array(_master_page("ผนึกห้องเก็บตำราชั้นเจ็ดกันพลังโกลาหล รหัสผนึก: aurora", "seal.txt", "ประตูชั้นเจ็ด: ผนึกแล้ว\n(รหัสไม่ได้อยู่ในกระดาษแผ่นนี้ — ผู้จารึกย่อมจำได้ว่าจารึกอะไรไว้)\n"))
	setup.append_array(_master_page("พลังโกลาหลรุนแรงขึ้นทุกคืน", "journal.txt", "วันแรกของการศึกษา\nรอยร้าวลามเร็วผิดปกติ\nได้ยินเสียงจากใต้หอคอย\n"))
	setup.append_array(_master_page("ซ่อมแท่นเตรียมชั้นสี่", "repairs.txt", "แท่นเตรียม: ซ่อมแล้ว\n"))
	setup.append_array(_master_page("พรุ่งนี้จะสอนเวลเรื่องการจารึก", "lesson-plan.txt", "บทเรียนพรุ่งนี้: การจารึก\n"))
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
		"clear_keyword": "git log ดูประวัติการจารึก · --oneline ย่อบรรทัดละครั้ง · -n 3 ดูแค่ 3 ครั้งล่าสุด · --graph --all วาดแผนที่ทุกมิติ",

		"intro_sequence": [
			{"speaker": "เวล", "text": "ประตูหินบานนี้ไม่มีลูกบิด… มีแค่ช่องเสียงสลักว่า \"เอ่ยรหัสผนึก\"", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "คัมภีร์บนโต๊ะนี้เป็นของอาจารย์ ท่านชอบจดทุกอย่างไว้ในคำจารึก", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "อย่าเดามั่วล่ะ ประตูผนึกจะสะท้อนพลังกลับใส่คนที่เอ่ยรหัสผิด", "mewla_anim": "talk"},
			{"type": "open_gameplay", "step": 1}
		],

		"part2_intro_sequence": [
			{"speaker": "เวล", "text": "หลังประตูชั้นเจ็ดมีอีกบาน… ผนึกชั้นใน! แต่ม้วนประวัติตรงนี้ยาวเหยียดเลย", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "อาจารย์จดเวรยามทุกคืน ถ้าคลี่ทั้งม้วน ฝุ่นโกลาหลหลายสิบคืนจะฟุ้งใส่นาย", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "รหัสที่เปลี่ยนล่าสุดต้องอยู่ปลายม้วน คลี่แค่ไม่กี่บันทึกพอ — git log -n 3", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 2}
		],

		"part3_intro_sequence": [
			{"speaker": "เวล", "text": "ห้องนี้ว่างเปล่า… แต่บันทึกของอาจารย์บอกว่ามีห้องลับ", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "อาจารย์ชอบซ่อนของไว้ในอีกมิติ ม้วนประวัติธรรมดาเห็นแค่มิติที่นายยืนอยู่", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "วาดแผนที่ทุกมิติดู — git log --graph --all --oneline แล้วดูว่ามีกิ่งไหนแตกออกไป", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 3}
		],

		"gameplay": {
			1: {
				"title": "ประตูผนึก",
				"story": "ประตูชั้นเจ็ดต้องการรหัสผนึกที่ปรมาจารย์เคยจารึกไว้ หารหัสด้วยคาถาแล้วเอ่ยในช่อง ✦ เอ่ยคำ ของห้อง",
				"panels": ["terminal", "files", "graph"],
				# ม้วนคาถาที่แจกตอนเริ่มขั้นนี้ (SpellCatalog)
				"teaches": ["log"],
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
						"text": "หารหัสผนึกจากประวัติการจารึกของปรมาจารย์ แล้วเอ่ยรหัสในช่อง ✦ เอ่ยคำ ของห้อง",
						"short": "เอ่ยรหัสผนึกเปิดประตู",
						"type": "say",
						"words": ["aurora"],
						"world": "ประตูหินสั่นสะเทือน แล้วเลื่อนเปิด… เศษคัมภีร์ที่ร่วงเข้าไปในห้องผนึกตอนคัมภีร์ต้นกำเนิดแตก ปลิวออกมาตกบนโต๊ะ",
						"hint": "รหัสไม่อยู่ในไฟล์ใดเลย อยู่ใน \"คำจารึก\" ของการจารึกครั้งหนึ่ง — git log --oneline แล้วมองหาคำว่ารหัสผนึก",
						"spawn": [{"write": "fragment-3.txt", "content": "ย่อมสูญหายไปกับกาลเวลา\n"}]
					},
					{
						"id": "keep",
						"text": "จารึกเศษคัมภีร์ชิ้นที่ 3 (fragment-3.txt) ที่ร่วงออกมาจากประตู ก่อนคลื่นโกลาหลมาถึง",
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
			},
			2: {
				"title": "ม้วนประวัติยาวเหยียด",
				"story": "ประตูชั้นในต้องการรหัสผนึกที่ปรมาจารย์เพิ่งเปลี่ยนก่อนหายไป แต่ม้วนประวัติยาวหลายสิบคืน คลี่ทั้งม้วนฝุ่นโกลาหลจะฟุ้งใส่ — ดูแค่ปลายม้วน",
				"panels": ["terminal", "files"],
				# ม้วนคาถาใหม่: คลี่ม้วนแค่ปลาย (git log -n)
				"teaches": ["log_n"],
				"setup": _long_history(),
				"room": {
					"hearts": 3, "wave_every": 4, "wrong_say": 1, "respawn": true,
					"forbidden": [
						{"pattern": "^git\\s+log(?!.*\\s-n)", "text": "นายคลี่ม้วนประวัติทั้งม้วน ฝุ่นโกลาหลหลายสิบคืนฟุ้งเข้าใส่!"}
					],
					"items": {
						"watch.txt": {"kind": "note", "name": "บันทึกเวรยาม"},
						"inner-seal.txt": {"kind": "note", "name": "แผ่นผนึกชั้นใน"}
					}
				},
				"objectives": [
					{
						"id": "peek",
						"text": "คลี่ม้วนประวัติดูเฉพาะการจารึก 3 ครั้งล่าสุด (ห้ามคลี่ทั้งม้วน)",
						"short": "ดูแค่ 3 การจารึกล่าสุด",
						"type": "state",
						"check": "cast",
						"spell": "log",
						"flags": ["-n*"],
						"world": "ปลายม้วนคลี่ออกเพียงสามบรรทัด ฝุ่นไม่ฟุ้งเลย",
						"hint": "-n ตามด้วยจำนวนบอกว่าจะคลี่กี่บันทึก: git log -n 3 --oneline"
					},
					{
						"id": "inner_seal",
						"text": "เอ่ยรหัสผนึกชั้นในที่ปรมาจารย์เพิ่งเปลี่ยน ในช่อง ✦ เอ่ยคำ ของห้อง",
						"short": "เอ่ยรหัสผนึกชั้นใน",
						"type": "say",
						"words": ["lumen"],
						"world": "ผนึกชั้นในคลายออก ฝุ่นทั้งห้องร่วงลงพื้นอย่างสงบ",
						"hint": "ดูคำจารึกในสามบรรทัดที่คลี่ออกมา หาคำว่ารหัสผนึก"
					}
				],
				"success_text": "ผนึกชั้นในเปิดแล้ว!"
			},
			3: {
				"title": "มิติที่ซ่อนอยู่",
				"story": "ปรมาจารย์ซ่อนรหัสห้องลับไว้ในอีกมิติหนึ่ง — ม้วนประวัติธรรมดาเห็นแค่มิติที่นายยืนอยู่ ต้องวาดแผนที่การจารึกของทุกมิติ",
				"panels": ["terminal", "files"],
				# ม้วนคาถาใหม่: แผนที่มิติ (git log --graph --all --oneline)
				"teaches": ["log_graph"],
				"setup": _hidden_dimension(),
				"room": {
					"hearts": 3, "wave_every": 4, "wrong_say": 1, "respawn": true,
					"items": {
						"journal.txt": {"kind": "note", "name": "บันทึกของอาจารย์"}
					}
				},
				"objectives": [
					{
						"id": "map",
						"text": "วาดแผนที่การจารึกของทุกมิติเป็นกราฟ (ไม่ใช่แค่มิติ main ที่ยืนอยู่)",
						"short": "วาดแผนที่การจารึกทุกมิติ",
						"type": "state",
						"check": "cast",
						"spell": "log",
						"all_flags": ["--graph", "--all"],
						"world": "เส้นแสงแตกกิ่งออกจาก main — มีมิติชื่อ hidden-archive ซ่อนอยู่!",
						"hint": "--graph วาดเส้นกิ่ง --all รวมทุกมิติ: git log --graph --all --oneline"
					},
					{
						"id": "secret",
						"text": "เอ่ยรหัสห้องลับที่ซ่อนอยู่ในคำจารึกของมิติ hidden-archive ในช่อง ✦ เอ่ยคำ ของห้อง",
						"short": "เอ่ยรหัสห้องลับจากมิติที่ซ่อน",
						"type": "say",
						"words": ["nyx"],
						"world": "ผนังด้านหลังชั้นหนังสือเลื่อนเปิด… ห้องลับของปรมาจารย์!",
						"hint": "ดูคำจารึกบนกิ่งที่แตกออกไป (hidden-archive) หาคำว่ารหัสห้องลับ"
					}
				],
				"success_text": "พบห้องลับของปรมาจารย์!"
			}
		},

		"outro_sequence": [
			{"speaker": "เวล", "text": "\"พรุ่งนี้จะสอนเวลเรื่องการจารึก\" … นี่คือคำจารึกสุดท้ายก่อนอาจารย์หายไป", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "คำจารึกที่ดีช่วยให้คนรุ่นหลังหาเจอ… นายเองก็จารึกให้ดีแบบท่านนะ", "mewla_anim": "talk"}
		]
	}
