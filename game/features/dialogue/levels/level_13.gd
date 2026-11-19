class_name Level13Dialogue
extends RefCounted

## ด่านที่ 13: คัมภีร์แสงสว่าง (git clone + git remote) — มินิเกม "คัมภีร์จากคลังเวท"
## ชั้นนี้ไม่มีคัมภีร์ของนายเลย คลื่นโกลาหลจึงซัดเข้าใส่ทุกครั้งจนกว่าจะมีคัมภีร์รองรับ
## คัมภีร์แสงสว่างอยู่ในคลังเวทกลาง (Magic Vault) → clone มาทั้งเล่มพร้อมประวัติ
## แล้วตรวจสายเชื่อม (remote -v) และอ่านเศษคัมภีร์ชิ้นที่ 10 ที่ผู้พิทักษ์ฝากไว้

const LIGHT_TOME := {
	"name": "light-tome",
	"description": "คัมภีร์แสงสว่าง — ความรู้ร่วมของจอมเวททุกคน",
	"commits": [
		{"author": "Guardian", "message": "ก่อตั้งคัมภีร์แสงสว่าง", "files": {"README.md": "# คัมภีร์แสงสว่าง\nความรู้ร่วมของจอมเวททุกคนในคลังเวทกลาง\n"}},
		{"author": "Guardian", "message": "ฝากเศษคัมภีร์ชิ้นที่ 10 ไว้ให้ศิษย์ของปรมาจารย์", "files": {"fragment-10.txt": "ความรู้ที่ไม่ถูกแบ่งปัน\n"}},
	],
}
const URL := "https://magic-vault.com/user/light-tome.git"
## ขั้นที่ 2: ที่อยู่เก่าของคลัง (ร้างแล้ว) — ผูกสายได้แต่ไปไม่ถึง ต้อง git remote set-url ไปที่อยู่ใหม่
const OLD_URL := "https://magic-vault.com/user/old-light-tome.git"
const MOVED_TOME := {
	"name": "light-tome",
	"description": "คัมภีร์แสงสว่าง — ความรู้ร่วมของจอมเวททุกคน",
	"retired_url": OLD_URL,
	"commits": [
		{"author": "Guardian", "message": "ก่อตั้งคัมภีร์แสงสว่าง", "files": {"README.md": "# คัมภีร์แสงสว่าง\nความรู้ร่วมของจอมเวททุกคนในคลังเวทกลาง\n"}},
		{"author": "Guardian", "message": "ฝากเศษคัมภีร์ชิ้นที่ 10 ไว้ให้ศิษย์ของปรมาจารย์", "files": {"fragment-10.txt": "ความรู้ที่ไม่ถูกแบ่งปัน\n"}},
	],
}
const IDENTITY := [
	{"run": "git config --global user.name \"Vel\""},
	{"run": "git config --global user.email \"vel@magic-tower.local\""},
]


static func get_data() -> Dictionary:
	return {
		"level_id": 13,
		"title": "ด่านที่ 13: คัมภีร์แสงสว่าง",
		"time_limit": 230.0,
		"max_score": 220,
		"commands": ["git clone", "git remote"],
		"clear_keyword": "git clone <url> คัดลอกคัมภีร์ทั้งเล่มพร้อมประวัติ · git remote -v ดูสายเชื่อม · git remote set-url เปลี่ยนที่อยู่ · git remote remove ตัดสายทิ้ง",

		"intro_sequence": [
			{"speaker": "เวล", "text": "ชั้นนี้ไม่มีโต๊ะ ไม่มีคัมภีร์… แต่มองเห็นโดมแก้วของคลังเวทกลางอยู่ไกลลิบ", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ไม่มีคัมภีร์ก็ไม่มีอะไรรองรับคลื่นโกลาหล — แต่ผู้พิทักษ์คลังทิ้งคัมภีร์แสงสว่างไว้ให้นาย", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "มันอยู่ที่ " + URL + " — คัดลอกมาทั้งเล่มเลย ไม่ต้องเดินไปถึงที่นั่น", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 1}
		],

		"part2_intro_sequence": [
			{"speaker": "เวล", "text": "พลังรั่วออกจากคัมภีร์ทุกคลื่นเลย… มีอะไรเกาะอยู่บนสายเชื่อม!", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ผู้พิทักษ์ฝากข่าวมาว่าคลังย้ายที่ไปแล้ว แต่ origin ของนายยังชี้ที่อยู่เก่า", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "แล้วยังมีสายเชื่อมเงาที่โกลาหลผูกไว้อีก — ย้ายสายด้วย set-url แล้วตัดสายเงาทิ้งด้วย remove", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 2}
		],

		"gameplay": {
			1: {
				"title": "คัมภีร์จากคลังเวท",
				"story": "ชั้นนี้ไม่มีคัมภีร์รองรับคลื่น — คัดลอกคัมภีร์แสงสว่างจากคลังเวทกลาง: " + URL,
				"panels": ["terminal", "files", "graph"],
				# ม้วนคาถาที่แจกตอนเริ่มขั้นนี้ (SpellCatalog)
				"teaches": ["clone", "remote"],
				"setup": IDENTITY,
				"remote": LIGHT_TOME,
				"room": {"hearts": 3, "wave_every": 3, "needs_tome": true,
					"items": {
						"README.md": {"kind": "note", "name": "ป้ายคัมภีร์แสงสว่าง"},
						"fragment-10.txt": {"kind": "fragment", "name": "เศษคัมภีร์ชิ้นที่ 10"}
					}},
				"objectives": [
					{
						"id": "copy",
						"text": "คัดลอกคัมภีร์แสงสว่าง (light-tome) จากคลังเวทกลางมาทั้งเล่ม ก่อนคลื่นจะมาถึง",
						"short": "คัดลอกคัมภีร์แสงสว่างจากคลัง",
						"type": "state",
						"check": "commits_at_least",
						"count": 2,
						"spell": "clone",
						"world": "ลำแสงพุ่งจากโดมแก้วมาที่ห้อง คัมภีร์แสงสว่างปรากฏพร้อมประวัติการจารึกทั้งหมด",
						"hint": "คาถาคัดลอกคัมภีร์คือ clone ตามด้วยที่อยู่: git clone " + URL
					},
					{
						"id": "bond",
						"text": "ดูว่าคัมภีร์เล่มนี้ผูกสายเชื่อมกับคลังเวทที่ไหน",
						"short": "ดูสายเชื่อมของคัมภีร์",
						"type": "command",
						"commands": ["git remote -v"],
						"world": "origin คือสายเชื่อมที่ clone สร้างให้อัตโนมัติ ชี้กลับไปยังคลังเวทกลาง",
						"hint": "คาถาสายเชื่อมคือ remote ใส่ -v เพื่อดูที่อยู่: git remote -v"
					},
					{
						"id": "gift",
						"text": "หยิบเศษคัมภีร์ชิ้นที่ 10 ที่ผู้พิทักษ์ฝากไว้ขึ้นมาอ่าน — คลิกในห้อง",
						"short": "อ่านเศษชิ้นที่ 10 จากผู้พิทักษ์",
						"type": "read",
						"path": "fragment-10.txt",
						"world": "ได้รับเศษคัมภีร์ชิ้นที่ 10: \"ความรู้ที่ไม่ถูกแบ่งปัน\"",
						"hint": "คลิก เศษคัมภีร์ชิ้นที่ 10 ในห้อง (โซนคัมภีร์) เพื่อหยิบอ่าน"
					}
				],
				"success_text": "ได้รับเศษคัมภีร์ชิ้นที่ 10!"
			},
			2: {
				"title": "สายเชื่อมที่ขาดและเงาที่เกาะ",
				"story": "คลังเวทย้ายคัมภีร์แสงสว่างไปที่อยู่ใหม่ สายเชื่อม origin ยังชี้ที่อยู่เก่าที่ร้างแล้ว และโกลาหลแอบผูกสายเชื่อมเงา (shadow) ไว้ดูดพลัง",
				"panels": ["terminal", "files", "graph"],
				# ม้วนคาถาใหม่: ย้ายสายเชื่อม (remote set-url) และตัดสายเชื่อม (remote remove)
				"teaches": ["remote_set_url", "remote_remove"],
				"setup": IDENTITY + [
					{"run": "git clone " + URL},
					{"run": "git remote add shadow " + URL},
					{"run": "git fetch shadow"},
					{"run": "git remote set-url origin " + OLD_URL}
				],
				"remote": MOVED_TOME,
				"room": {"hearts": 3, "wave_every": 3, "phantoms": ["shadow/main"],
					"items": {
						"README.md": {"kind": "note", "name": "ป้ายคัมภีร์แสงสว่าง"},
						"fragment-10.txt": {"kind": "fragment", "name": "เศษคัมภีร์ชิ้นที่ 10"}
					}},
				"objectives": [
					{
						"id": "inspect",
						"text": "ดูว่าสายเชื่อมแต่ละเส้นของคัมภีร์ชี้ไปที่ไหน",
						"short": "ตรวจสายเชื่อมทั้งหมด",
						"type": "command",
						"commands": ["git remote -v"],
						"world": "origin ชี้ไปที่อยู่เก่าที่ร้างแล้ว… และมีสายเชื่อมแปลกปลอมชื่อ shadow!",
						"hint": "git remote -v"
					},
					{
						"id": "move",
						"text": "เปลี่ยนที่อยู่ของสายเชื่อม origin ให้ชี้ไปยังที่อยู่ใหม่ของคัมภีร์แสงสว่าง: " + URL,
						"short": "ย้ายสายเชื่อม origin ไปที่อยู่ใหม่",
						"type": "command",
						"commands": ["git remote set-url origin " + URL],
						"unordered": true,
						"world": "สายเชื่อม origin สว่างวาบ ต่อติดกับโดมแก้วของคลังเวทอีกครั้ง",
						"hint": "git remote set-url <ชื่อสาย> <ที่อยู่ใหม่> — git remote set-url origin " + URL
					},
					{
						"id": "cut",
						"text": "ตัดสายเชื่อมเงา shadow ทิ้ง พร้อมเงาของมัน (shadow/main) ที่ดูดพลังนาย",
						"short": "ตัดสายเชื่อม shadow ทิ้ง",
						"type": "state",
						"check": "branch_absent",
						"branch": "shadow/main",
						"spell": "remote",
						"unordered": true,
						"world": "สายเชื่อมเงาขาดสะบั้น เงาดำสลายไปพร้อมเสียงกรีดร้อง",
						"hint": "git remote remove shadow"
					}
				],
				"success_text": "คัมภีร์ของนายผูกกับคลังเวทถูกที่แล้ว!"
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "clone ได้ทั้งเนื้อหา ประวัติ และสายเชื่อมกลับไปที่คลัง — ต่างจากการลอกกระดาษธรรมดามาก", "mewla_anim": "success"},
			{"speaker": "เวล", "text": "\"ความรู้ที่ไม่ถูกแบ่งปัน\"… ประโยคของอาจารย์ใกล้จะครบแล้ว", "mewla_anim": "idle"}
		]
	}
