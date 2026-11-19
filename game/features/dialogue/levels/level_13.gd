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
		"clear_keyword": "git clone <url> คัดลอกคัมภีร์ทั้งเล่มพร้อมประวัติ · git remote -v ดูสายเชื่อมไปยังคลัง",

		"intro_sequence": [
			{"speaker": "เวล", "text": "ชั้นนี้ไม่มีโต๊ะ ไม่มีคัมภีร์… แต่มองเห็นโดมแก้วของคลังเวทกลางอยู่ไกลลิบ", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ไม่มีคัมภีร์ก็ไม่มีอะไรรองรับคลื่นโกลาหล — แต่ผู้พิทักษ์คลังทิ้งคัมภีร์แสงสว่างไว้ให้นาย", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "มันอยู่ที่ " + URL + " — คัดลอกมาทั้งเล่มเลย ไม่ต้องเดินไปถึงที่นั่น", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 1}
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
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "clone ได้ทั้งเนื้อหา ประวัติ และสายเชื่อมกลับไปที่คลัง — ต่างจากการลอกกระดาษธรรมดามาก", "mewla_anim": "success"},
			{"speaker": "เวล", "text": "\"ความรู้ที่ไม่ถูกแบ่งปัน\"… ประโยคของอาจารย์ใกล้จะครบแล้ว", "mewla_anim": "idle"}
		]
	}
