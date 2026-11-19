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

## สภาพหลังขั้นที่ 2: จารึกเศษชิ้นที่ 1 และชิ้นที่ 2 แล้ว (คัมภีร์มี 3 หน้า)
static func _second_fragment_done() -> Array:
	return ALTAR_READY + [
		{"run": "git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 1\""},
		{"write": "fragment-1c.txt", "content": "ข้า…\nความรู้ที่ไม่ถูกจารึก\n"},
		{"run": "git commit -am \"จารึกเศษคัมภีร์ชิ้นที่ 2\""},
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
		"clear_keyword": "git commit -m บันทึกของบน stage อย่างถาวร · git commit -am จารึกไฟล์ที่คัมภีร์รู้จักแล้วทันที · git commit (ไม่มี -m) เปิด editor เขียนคำจารึกยาว · git commit --amend แก้การจารึกล่าสุด",

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

		"part3_intro_sequence": [
			{"speaker": "เวล", "text": "ม้วนกระดาษสีทองลอยขึ้นแท่นเอง… มันเขียนว่า \"จงบอกข้าว่าเจ้าจารึกอะไร และเพราะเหตุใด\"", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ม้วนพิธีไม่ยอมรับคำจารึกบรรทัดเดียวแบบ -m หรอก ร่าย git commit เฉย ๆ สิ คัมภีร์จะเปิดหน้าให้เขียนเต็ม ๆ", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "บรรทัดแรกคือหัวเรื่องสั้น ๆ เว้นหนึ่งบรรทัด แล้วค่อยเล่ารายละเอียด — นักจารึกตัวจริงเขียนแบบนี้", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 3}
		],

		"part4_intro_sequence": [
			{"speaker": "เวล", "text": "แย่แล้ว! ตอนจารึกเศษชิ้นที่ 2 ฉันลืมตราผนึกของมันไว้บนโต๊ะ", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "คัมภีร์ชั้นนี้รับได้แค่สามหน้า ถ้าจารึกหน้าใหม่มันจะดูดพลังนาย", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "วางตราขึ้นแท่น แล้วใช้ git commit --amend เติมลงหน้าล่าสุดแทน — แก้ได้เฉพาะหน้าที่ยังไม่ส่งออกไปไหนนะ", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 4}
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
						"text": "จารึกทั้งสามส่วนที่อยู่บนแท่นลงคัมภีร์ พร้อมคำจารึก ก่อนคลื่นจะกวาดแท่น",
						"short": "จารึกเศษชิ้นที่ 1 ทั้งสามส่วนลงคัมภีร์",
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
					{"write": "curse.txt", "content": "[ม้วนคำสาป] ผู้ใดจารึกม้วนนี้ คัมภีร์จะเป็นของโกลาหล\n"}
				],
				"room": {"hearts": 3, "wave_every": 2, "respawn": true, "items": ITEMS},
				"objectives": [
					{
						"id": "skip_altar",
						"text": "ส่วนท้าย (fragment-1c.txt) มีอักขระใหม่ — จารึกมันในคาถาเดียวโดยไม่ต้องวางขึ้นแท่น และไม่ให้ม้วนคำสาปเข้าคัมภีร์",
						"short": "จารึกส่วนท้ายที่ถูกแก้ (ไม่เอาม้วนคำสาป)",
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
			},
			3: {
				"title": "ม้วนพิธีแห่งการจารึก",
				"story": "ม้วนพิธีขึ้นแท่นมาเอง มันยอมถูกจารึกด้วยคำจารึกแบบเต็ม (หัวเรื่อง + รายละเอียดหลายบรรทัด) เท่านั้น — -m บรรทัดเดียวไม่พอ",
				"panels": ["terminal", "files", "graph"],
				# ม้วนคาถาใหม่: git commit ไม่มี -m → เปิดหน้าจารึก (editor)
				"teaches": ["commit_editor"],
				"setup": _second_fragment_done() + [
					{"write": "ritual.txt", "content": "ม้วนพิธีแห่งการจารึก\nผู้จารึกต้องบอกว่าจารึกอะไร และเพราะเหตุใด\n"},
					{"run": "git add ritual.txt"}
				],
				"room": {"hearts": 3, "wave_every": 2, "respawn": true,
					"items": {
						"fragment-1a.txt": {"kind": "fragment", "name": "เศษชิ้นที่ 1 · ส่วนแรก"},
						"fragment-1b.txt": {"kind": "fragment", "name": "เศษชิ้นที่ 1 · ส่วนกลาง"},
						"fragment-1c.txt": {"kind": "fragment", "name": "เศษชิ้นที่ 1 · ส่วนท้าย"},
						"miura-note.txt": {"kind": "note", "name": "บันทึกมิวรา"},
						"ritual.txt": {"kind": "fragment", "name": "ม้วนพิธีแห่งการจารึก"}
					}},
				"objectives": [
					{
						"id": "full_inscription",
						"text": "จารึกม้วนพิธี (ritual.txt) ที่อยู่บนแท่น โดยเปิดหน้าจารึกของคัมภีร์ (ไม่ใส่ -m) แล้วเขียนหัวเรื่อง เว้นบรรทัด และรายละเอียด",
						"short": "จารึกม้วนพิธีผ่านหน้าจารึก (ไม่ใช้ -m)",
						"type": "state",
						"check": "committed",
						"paths": ["ritual.txt"],
						"count": 4,
						"spell": "commit",
						"without_flags": ["-m*", "-am"],
						"world": "ม้วนพิธีอ่านคำจารึกของนายทั้งหน้า แล้วหลอมเข้าคัมภีร์อย่างพึงพอใจ",
						"hint": "ร่าย git commit เฉย ๆ — หน้าจารึกจะเปิดขึ้นมา เขียนบรรทัดแรกเป็นหัวเรื่อง เว้นหนึ่งบรรทัด แล้วเขียนรายละเอียด จากนั้นกด Ctrl+Enter",
						"near_miss": [
							{"pattern": "^git\\s+commit\\s+.*-a?m", "message": "ม้วนพิธีปฏิเสธคำจารึกบรรทัดเดียว — ร่าย git commit โดยไม่ใส่ -m แล้วเขียนในหน้าที่เปิดขึ้นมา"}
						]
					}
				],
				"success_text": "ม้วนพิธีถูกจารึกพร้อมคำอธิบายเต็มหน้า!"
			},
			4: {
				"title": "ตราผนึกที่ลืม",
				"story": "นายจารึกเศษชิ้นที่ 2 ไปแล้ว แต่ลืมตราผนึกของมัน — คัมภีร์ชั้นนี้รับการจารึกได้แค่ 3 หน้า ต้องเติมตราลงหน้าล่าสุด ห้ามเพิ่มหน้าใหม่",
				"panels": ["terminal", "files", "graph"],
				# ม้วนคาถาใหม่: แก้การจารึกครั้งล่าสุด (git commit --amend)
				"teaches": ["amend"],
				"setup": _second_fragment_done() + [
					{"write": "fragment-2-seal.txt", "content": "ตราผนึกเศษชิ้นที่ 2 ✶\n"}
				],
				"room": {"hearts": 3, "wave_every": 2, "respawn": true, "max_commits": 3,
					"items": {
						"fragment-1a.txt": {"kind": "fragment", "name": "เศษชิ้นที่ 1 · ส่วนแรก"},
						"fragment-1b.txt": {"kind": "fragment", "name": "เศษชิ้นที่ 1 · ส่วนกลาง"},
						"fragment-1c.txt": {"kind": "fragment", "name": "เศษชิ้นที่ 1 · ส่วนท้าย"},
						"miura-note.txt": {"kind": "note", "name": "บันทึกมิวรา"},
						"fragment-2-seal.txt": {"kind": "fragment", "name": "ตราผนึกเศษชิ้นที่ 2"}
					}},
				"objectives": [
					{
						"id": "amend",
						"text": "วางตราผนึก (fragment-2-seal.txt) ขึ้นแท่น แล้วเติมมันลงในการจารึกครั้งล่าสุด — คัมภีร์ต้องยังมี 3 หน้าเท่าเดิม",
						"short": "เติมตราผนึกลงหน้าล่าสุด (ไม่เพิ่มหน้าใหม่)",
						"type": "state",
						"check": "committed",
						"paths": ["fragment-2-seal.txt"],
						"count": 3,
						"max_count": 3,
						"spell": "commit",
						"flags": ["--amend"],
						"world": "หน้าล่าสุดของคัมภีร์เรืองแสงใหม่ ตราผนึกประทับลงข้างเศษชิ้นที่ 2 โดยไม่มีหน้าเกินมา",
						"hint": "git add fragment-2-seal.txt แล้ว git commit --amend (หน้าจารึกจะเปิดพร้อมคำจารึกเดิม กด Ctrl+Enter ได้เลย) หรือ git commit --amend --no-edit",
						"near_miss": [
							{"pattern": "^git\\s+commit(?!.*--amend)", "message": "จารึกหน้าใหม่จะทำให้คัมภีร์เกินกำลัง — ใช้ --amend เพื่อแก้หน้าล่าสุดแทน"}
						]
					}
				],
				"success_text": "เศษคัมภีร์ชิ้นที่ 2 ครบพร้อมตราผนึกในหน้าเดียว!"
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "-a ไม่แตะม้วนคำสาปเพราะคัมภีร์ไม่เคยรู้จักมัน — ฉลาดมากศิษย์ฝึกหัด", "mewla_anim": "success"},
			{"speaker": "เวล", "text": "\"ศิษย์ของข้า… ความรู้ที่ไม่ถูกจารึก\" — นี่มันข้อความของอาจารย์!", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ถ้าอยากรู้ประโยคที่เหลือ ก็ต้องปีนต่อไป", "mewla_anim": "talk"}
		]
	}
