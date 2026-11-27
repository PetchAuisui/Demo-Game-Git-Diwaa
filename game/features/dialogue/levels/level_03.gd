class_name Level03Dialogue
extends RefCounted

## ด่านที่ 3: เศษคัมภีร์ไร้ตรา (git status) — มินิเกม "ผ้าปูที่มองไม่เห็น"
## ห้องแสดงกระดาษ 6 แผ่นเป็น "?" ทั้งหมด ไม่รู้ว่าแผ่นไหนไร้ตรา/ถูกแก้ จนกว่าจะร่าย git status
## คลื่นโกลาหลมาทุก 4 การกระทำ และกระดาษไร้ตรา (เศษหน้าคัมภีร์) จะสลายถ้าโดนคลื่น
## → เดาสุ่มอ่านทีละแผ่นเสียเวลาและหัวใจ การหยั่งสถานะคือทางที่เร็วที่สุด

const SCROLLS := {
	"scroll-a.txt": "บันทึกการซ่อมแท่นเตรียม: เรียบร้อย\n",
	"scroll-b.txt": "ข้อ ๑  ทุกการจารึกต้องมีนามผู้จารึกกำกับ\nข้อ ๒  ก่อนลงมือ จงหยั่งสถานะของผ้าปูทุกครั้ง\nข้อ ๓  ของที่ยังไม่ถูกจารึก ไม่ปลอดภัยจากคลื่นโกลาหล\nข้อ ๔  ห้ามวางม้วนคำสาปขึ้นแท่นเตรียม\n",
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
		{"write": "scroll-b.txt", "content": "ข้อ ๑  ทุกการจารึกต้องมีนามผู้จารึกกำกับ\nข้อ ๒  ก่อนลงมือ จงหยั่งสถานะของผ้าปูทุกครั้ง\nข้อ ๓  ของที่ยังไม่ถูกจารึก ไม่ปลอดภัยจากคลื่นโกลาหล\nข้อ ๔  ห้ามวางม้วนคำสาปขึ้นแท่นเตรียม\nข้อ ๕  เศษคัมภีร์ที่ยังไม่จารึก ห้ามสะสมเกิน 3 ชิ้น!\n"},
		{"write": "scroll-d.txt", "content": "เมื่อคัมภีร์ต้นกำเนิดแตกสลาย แสงของเศษชิ้นแรกพุ่งขึ้นสู่ชั้นถัดไป แล้วแตกออกเป็นสามประกายกลางอากาศ\n"},
	])

	var items := {}
	for path in ["scroll-a.txt", "scroll-b.txt", "scroll-c.txt", "scroll-e.txt", "scroll-f.txt"]:
		items[path] = {"kind": "note", "name": "เอกสารกิลด์"}
	items["scroll-b.txt"] = {"kind": "note", "name": "ประกาศกฎหอคอย", "style": "proclamation"}
	items["scroll-d.txt"] = {"kind": "fragment", "name": "เศษหน้าคัมภีร์"}

	return {
		"level_id": 3,
		"title": "ด่านที่ 3: เศษคัมภีร์ไร้ตรา",
		"time_limit": 45.0,
		"max_score": 120,
		"commands": ["git status"],
		"clear_keyword": "git status บอกว่าไฟล์ไหนใหม่ (untracked) ถูกแก้ (modified) หรืออยู่บน stage แล้ว",

		"intro_sequence": [
			{"speaker": "มิวรา", "text": "ลมพัดกระดาษหกแผ่นปลิวมาเต็มผ้าปู… หน้าตาเหมือนกันหมดเลย", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "แผ่นหนึ่งไม่มีตราของคัมภีร์… มันคือเศษหน้าคัมภีร์ต้นกำเนิดที่ฉีกหลุดออกมาตอนคัมภีร์แตกสลาย! ในนั้นมีร่องรอยบอกทางไปหาเศษคัมภีร์ แต่ของที่ยังไม่ถูกจารึกจะสลายเมื่อคลื่นโกลาหลมาถึง", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "อ่านทีละแผ่นก็ไม่ทันแน่ ๆ", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ถ้างั้นก็ถามคัมภีร์สิว่ามันมองผ้าปูผืนนี้ยังไง", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 1}
		],

		"gameplay": {
			1: {
				"title": "ผ้าปูที่มองไม่เห็น",
				"story": "กระดาษ 6 แผ่นหน้าตาเหมือนกัน หาแผ่นที่ไร้ตราและแผ่นที่ถูกแอบแก้ แล้วอ่านก่อนคลื่นซัด",
				# ซ่อนแผง Files เพราะมันบอกสถานะไฟล์ให้ฟรี — ด่านนี้ต้องหยั่งสถานะเอง
				"panels": ["terminal"],
				# ม้วนคาถาที่แจกตอนเริ่มขั้นนี้ (SpellCatalog)
				"teaches": ["status"],
				"setup": setup,
				"room": {"hearts": 3, "wave_every": 4, "blind": true, "respawn": true, "items": items},
				"objectives": [
					{
						"id": "status",
						"text": "หยั่งสถานะของผ้าปู ให้คัมภีร์บอกว่ากระดาษแต่ละแผ่นเป็นอย่างไร",
						"short": "หยั่งสถานะของผ้าปู",
						"type": "command",
						"commands": ["git status"],
						"world": "หมอกจางลง — Untracked = ไร้ตรา (คัมภีร์ไม่รู้จัก) · modified = ถูกแก้ไปจากที่จารึกไว้",
						"hint": "คาถาหยั่งสถานะ: git status"
					},
					{
						"id": "whisper",
						"text": "หยิบเศษหน้าคัมภีร์ (แผ่นไร้ตรา) ขึ้นมาอ่านก่อนมันจะสลาย — คลิกกระดาษในห้อง",
						"short": "อ่านเศษหน้าคัมภีร์ (ไร้ตรา)",
						"type": "read",
						"unordered": true,
						"path": "scroll-d.txt",
						"world": "\"เมื่อคัมภีร์ต้นกำเนิดแตกสลาย แสงของเศษชิ้นแรกพุ่งขึ้นสู่ชั้นถัดไป แล้วแตกออกเป็นสามประกายกลางอากาศ\"",
						"hint": "แผ่นที่ติดป้าย ไร้ตรา (untracked) หลังร่าย git status — คลิกมันในห้องเพื่อหยิบอ่าน"
					},
					{
						"id": "rules",
						"text": "หยิบประกาศกฎหอคอย (แผ่นที่ถูกแก้) ขึ้นมาอ่าน — คลิกกระดาษในห้อง",
						"short": "อ่านประกาศกฎหอคอย (ถูกแก้)",
						"type": "read",
						"unordered": true,
						"path": "scroll-b.txt",
						"world": "ประกาศข้อ ๕ ถูกเพิ่มเข้ามาท้ายสุด: เศษคัมภีร์ที่ยังไม่จารึก ห้ามสะสมเกิน 3 ชิ้น!",
						"hint": "แผ่นที่ติดป้าย ถูกแก้ (modified) หลังร่าย git status — คลิกมันในห้องเพื่อหยิบอ่าน"
					}
				],
				"success_text": "นายมองเห็นสิ่งที่คัมภีร์เห็นแล้ว!"
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "เห็นไหม แทนที่จะเดาสุ่ม นายถามคัมภีร์ครั้งเดียวก็รู้หมด", "mewla_anim": "success"},
			{"speaker": "มิวรา", "text": "ประกาศข้อ ๕… ใครแอบเพิ่มนะ แต่มันก็จริง หอคอยไม่ชอบให้ใครเก็บของไว้โดยไม่จารึก", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "เศษคัมภีร์ชิ้นแรกอยู่ชั้นบน! ไปกันเถอะ", "mewla_anim": "idle"}
		]
	}
