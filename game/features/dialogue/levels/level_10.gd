class_name Level10Dialogue
extends RefCounted

## ด่านที่ 10: รอยแยกมิติ (git branch) — มินิเกม "มิติผี"
## มีมิติผีชื่อ phantom ค้างอยู่ในคัมภีร์ และมันดูดพลังผู้เล่นทุกคลื่น (ทุก 2 การกระทำ)
## ต้องสำรวจว่ามีมิติอะไรอยู่ (branch) ปิดมิติผี (branch -d) แล้วเปิดมิติทดลองของตัวเอง

const BASE := [
	{"run": "git config --global user.name \"Vel\""},
	{"run": "git config --global user.email \"vel@magic-tower.local\""},
	{"run": "git init"},
	{"write": "fragment-5.txt", "content": "ความผิดพลาดแก้ไขได้เสมอ\n"},
	{"run": "git add ."},
	{"run": "git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 5\""},
	{"write": "fragment-6.txt", "content": "หากเจ้ากล้าย้อนกลับไปมอง\n"},
	{"run": "git add ."},
	{"run": "git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 6\""},
]


static func get_data() -> Dictionary:
	return {
		"level_id": 10,
		"title": "ด่านที่ 10: รอยแยกมิติ",
		"time_limit": 105.0,
		"max_score": 190,
		"commands": ["git branch"],
		"clear_keyword": "git branch ดูมิติทั้งหมด · git branch <ชื่อ> สร้างมิติใหม่ · git branch -d <ชื่อ> ปิดมิติที่ไม่ใช้",

		"intro_sequence": [
			{"speaker": "เวล", "text": "อากาศกลางห้องบิดเป็นรอยแยก… ข้างในเห็นห้องเดียวกันซ้อนอยู่", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "คัมภีร์มีหลายเส้นเวลาได้ เราเรียกว่า 'มิติ' — แต่มีมิติผีตนหนึ่งค้างอยู่ และมันกำลังดูดพลังของนาย", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "หาให้เจอว่ามีมิติอะไรบ้าง ปิดตัวผีซะ แล้วเปิดมิติทดลองของนายเอง", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 1}
		],

		"gameplay": {
			1: {
				"title": "มิติผี",
				"story": "มิติผีดูดพลังทุกคลื่น — สำรวจมิติทั้งหมด ปิดมิติผี แล้วเปิดมิติทดลองชื่อ experiment",
				"panels": ["terminal", "files", "graph"],
				# ม้วนคาถาที่แจกตอนเริ่มขั้นนี้ (SpellCatalog)
				"teaches": ["branch", "branch_delete"],
				"setup": BASE + [{"run": "git branch phantom"}],
				"room": {"hearts": 3, "wave_every": 2, "phantoms": ["phantom"],
					"items": {
						"fragment-5.txt": {"kind": "fragment", "name": "เศษคัมภีร์ชิ้นที่ 5"},
						"fragment-6.txt": {"kind": "fragment", "name": "เศษคัมภีร์ชิ้นที่ 6"},
						"fragment-7.txt": {"kind": "fragment", "name": "เศษคัมภีร์ชิ้นที่ 7"}
					}},
				"objectives": [
					{
						"id": "survey",
						"text": "สำรวจว่าคัมภีร์นี้มีมิติอะไรอยู่บ้าง",
						"short": "สำรวจมิติ",
						"type": "command",
						"commands": ["git branch", "git branch -a", "git branch --all"],
						"world": "ดอกจัน * คือมิติที่นายยืนอยู่… และนั่นไง phantom มิติผีที่ไม่มีใครใช้แล้ว",
						"hint": "คาถาแยกมิติถ้าร่ายเฉย ๆ จะแสดงรายชื่อมิติ: git branch"
					},
					{
						"id": "close",
						"text": "ปิดมิติผี phantom ก่อนมันดูดพลังนายจนหมด",
						"short": "ปิดมิติผี",
						"type": "state",
						"check": "branch_absent",
						"branch": "phantom",
						"world": "มิติผีหดตัวหายไปพร้อมเสียงกรีดร้องแผ่ว ๆ",
						"hint": "คาถาแยกมิติมีตัวเลือกลบ -d (delete): git branch -d phantom"
					},
					{
						"id": "open",
						"text": "เปิดมิติทดลองของนายเองชื่อ experiment",
						"short": "เปิดมิติ experiment",
						"type": "state",
						"check": "branch_exists",
						"branch": "experiment",
						"world": "รอยแยกสีฟ้าเปิดออก… และเศษคัมภีร์ชิ้นที่ 7 ที่มิติผีกักไว้ก็หล่นลงมาจารึกตัวเองลงคัมภีร์",
						"hint": "ร่ายคาถาแยกมิติตามด้วยชื่อ: git branch experiment",
						"spawn": [
							{"write": "fragment-7.txt", "content": "เส้นทางมีมากกว่าหนึ่งเสมอ\n"},
							{"run": "git add fragment-7.txt"},
							{"run": "git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 7\""}
						]
					}
				],
				"success_text": "ได้รับเศษคัมภีร์ชิ้นที่ 7: \"เส้นทางมีมากกว่าหนึ่งเสมอ\""
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "สังเกตนะ การสร้างมิติไม่ได้พานายเข้าไปในนั้น นายยังยืนอยู่ใน main", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "แล้วจะเข้าไปได้ยังไง?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ชั้นหน้าจะได้รู้ — มีบางอย่างรอนายอยู่ในมิตินั้น", "mewla_anim": "success"}
		]
	}
