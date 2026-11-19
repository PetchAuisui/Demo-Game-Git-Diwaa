class_name Level05Dialogue
extends RefCounted

## ด่านที่ 5: การจารึกครั้งแรก (git commit) — มินิเกม "พายุโกลาหล"
## ไม่มีโล่อีกแล้ว (safe = committed): ของบนแท่นเตรียมก็สลายได้ มีแค่การจารึกที่ปลอดภัย
## ช่วงที่ 1: คลื่นมาทุก 2 การกระทำ ต้องจารึกเศษชิ้นที่ 1 ให้ทัน
## ช่วงที่ 2: เศษชิ้นที่ 2 ซ่อนอยู่ในไฟล์ที่จารึกแล้ว และม้วนคำสาปร่วงลงมา
##            git commit -a เก็บเฉพาะไฟล์ที่คัมภีร์รู้จัก จึงไม่ลากม้วนคำสาป (ไร้ตรา) ไปด้วย — เป็นคาถาที่ใช่ที่สุด

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

const ITEMS := {
	"fragment-1a.txt": {"kind": "fragment", "name": "เศษชิ้นที่ 1 · ส่วนแรก"},
	"fragment-1b.txt": {"kind": "fragment", "name": "เศษชิ้นที่ 1 · ส่วนกลาง"},
	"fragment-1c.txt": {"kind": "fragment", "name": "เศษชิ้นที่ 1 · ส่วนท้าย"},
	"miura-note.txt": {"kind": "note", "name": "บันทึกมิวรา"},
	"curse.txt": {"kind": "curse", "name": "ม้วนคำสาป"},
}


static func get_data() -> Dictionary:
	return {
		"level_id": 5,
		"title": "ด่านที่ 5: การจารึกครั้งแรก",
		"time_limit": 115.0,
		"max_score": 140,
		"commands": ["git commit"],
		"clear_keyword": "git commit -m บันทึกของบน stage อย่างถาวร · git commit -am จารึกไฟล์ที่คัมภีร์รู้จักแล้วทันที (ไม่รวมไฟล์ใหม่)",

		"intro_sequence": [
			{"speaker": "มิวรา", "text": "โล่ของฉันแตกแล้ว! คลื่นจะมาถี่ขึ้น และครั้งนี้มันกวาดแท่นเตรียมด้วย", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "จารึกเศษคัมภีร์ลงคัมภีร์ซะ — ของที่จารึกแล้วเท่านั้นที่คลื่นแตะไม่ได้", "mewla_anim": "talk"},
			{"type": "open_gameplay", "step": 1}
		],

		"part2_intro_sequence": [
			{"speaker": "เวล", "text": "เดี๋ยวนะ… มีอักขระใหม่ปรากฏต่อท้าย fragment-1c! แล้วม้วนคำสาปก็ร่วงลงมาอีกแล้ว", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "เศษชิ้นที่ 2 ซ่อนอยู่ในชิ้นแรก! คัมภีร์รู้จักไฟล์นั้นอยู่แล้ว มีคาถาที่จารึกได้ทันทีโดยไม่แตะของไร้ตราอย่างม้วนคำสาป", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 2}
		],

		"gameplay": {
			1: {
				"title": "พายุโกลาหล",
				"story": "ไม่มีโล่แล้ว คลื่นจะกวาดทั้งโต๊ะและแท่นเตรียม จารึกเศษคัมภีร์ชิ้นที่ 1 ให้ทัน",
				"panels": ["terminal", "files", "graph"],
				# ม้วนคาถาที่แจกตอนเริ่มขั้นนี้ (SpellCatalog)
				"teaches": ["commit"],
				"setup": ALTAR_READY,
				"room": {"hearts": 3, "wave_every": 2, "respawn": true, "items": ITEMS},
				"objectives": [
					{
						"id": "inscribe",
						"text": "จารึกทั้งสามส่วนลงคัมภีร์พร้อมคำจารึก ก่อนคลื่นจะกวาดแท่น",
						"short": "จารึกพร้อมคำจารึก",
						"type": "state",
						"check": "committed",
						"paths": ["fragment-1a.txt", "fragment-1b.txt", "fragment-1c.txt"],
						"count": 2,
						"spell": "commit",
						"world": "แสงสีทองจารึกลงบนหน้ากระดาษ คลื่นผ่านไปโดยไม่แตะเศษคัมภีร์ได้อีก",
						"hint": "คาถาจารึกคือ commit และต้องมีคำจารึก: git commit -m \"คำจารึก\"",
						"near_miss": [
							{"pattern": "^git\\s+commit\\s+-m\\s*$", "message": "ต้องมีคำจารึกต่อท้าย -m ในเครื่องหมายคำพูด"},
							{"pattern": "^git\\s+comit", "message": "สะกดว่า commit (m สองตัว)"}
						]
					}
				],
				"success_text": "เศษคัมภีร์ชิ้นที่ 1 ปลอดภัยในคัมภีร์แล้ว!"
			},
			2: {
				"title": "เศษที่ซ่อนอยู่",
				"story": "fragment-1c เผยอักขระใหม่ และม้วนคำสาปร่วงลงบนโต๊ะ — จารึกการแก้ไขโดยไม่ลากคำสาปเข้าคัมภีร์",
				"panels": ["terminal", "files", "graph"],
				# ม้วนคาถาที่แจกตอนเริ่มขั้นนี้ (SpellCatalog)
				"teaches": ["commit_all"],
				"setup": ALTAR_READY + [
					{"run": "git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 1\""},
					{"write": "fragment-1c.txt", "content": "ข้า…\nความรู้ที่ไม่ถูกจารึก\n"},
					{"write": "curse.txt", "content": "☠ ผู้ใดจารึกม้วนนี้ คัมภีร์จะเป็นของโกลาหล ☠\n"}
				],
				"room": {"hearts": 3, "wave_every": 2, "respawn": true, "items": ITEMS},
				"objectives": [
					{
						"id": "skip_altar",
						"text": "จารึกอักขระใหม่บน fragment-1c ในคาถาเดียว โดยไม่ให้ม้วนคำสาปเข้าคัมภีร์",
						"short": "จารึกข้ามแท่นเตรียม",
						"type": "state",
						"check": "committed",
						"paths": ["fragment-1c.txt"],
						"exclude": ["curse.txt"],
						"count": 3,
						"spell": "commit",
						"flags": ["-a", "-am"],
						"world": "หน้าที่สองของคัมภีร์เรืองแสง — ได้รับเศษคัมภีร์ชิ้นที่ 2: \"ความรู้ที่ไม่ถูกจารึก\"",
						"hint": "-a (all) จารึกทุกไฟล์ที่คัมภีร์รู้จักแล้วโดยไม่ต้อง add และไม่แตะไฟล์ไร้ตรา: git commit -am \"คำจารึก\""
					}
				],
				"success_text": "สองชิ้นในคราวเดียว!"
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "-a ไม่แตะม้วนคำสาปเพราะคัมภีร์ไม่เคยรู้จักมัน — ฉลาดมากศิษย์ฝึกหัด", "mewla_anim": "success"},
			{"speaker": "เวล", "text": "\"ศิษย์ของข้า… ความรู้ที่ไม่ถูกจารึก\" — นี่มันข้อความของอาจารย์!", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ถ้าอยากรู้ประโยคที่เหลือ ก็ต้องปีนต่อไป", "mewla_anim": "talk"}
		]
	}
