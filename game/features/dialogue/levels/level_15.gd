class_name Level15Dialogue
extends RefCounted

## ด่านที่ 15: ประตูสู่คลังเวทกลาง (git push) — มินิเกม "ประตูที่ต้องการคัมภีร์ของนาย"
## ยอดหอคอยมีประตูเวทเชื่อมไปคลังเวทกลาง มันดูดพลังจากผู้ที่ยังไม่ส่งคัมภีร์ของตนเข้าคลัง (sync_required)
## ต้องผูกสายเชื่อม origin กับที่อยู่ในคลังของนาย แล้วส่งพร้อมผูกเส้นทาง (push -u)

const URL := "https://magic-vault.com/user/apprentice-tome.git"


static func get_data() -> Dictionary:
	return {
		"level_id": 15,
		"title": "ด่านที่ 15: ประตูสู่คลังเวทกลาง",
		"time_limit": 110.0,
		"max_score": 240,
		"commands": ["git push"],
		"clear_keyword": "git remote add origin <url> ผูกสายเชื่อม · git push -u origin main ส่งครั้งแรกพร้อมผูกเส้นทาง ครั้งต่อไปใช้ git push",

		"intro_sequence": [
			{"speaker": "เวล", "text": "ยอดหอคอยแล้ว… ประตูเวทวงกลมหมุนอยู่กลางอากาศ แต่มันดูดพลังฉันอยู่!", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ประตูนี้เปิดให้เฉพาะผู้ที่ส่งคัมภีร์ของตนเข้าคลังแล้ว ที่อยู่ในคลังของนายเตรียมไว้แล้ว: " + URL, "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ผูกสายเชื่อมชื่อ origin แล้วส่งคัมภีร์ผ่านประตูไป — เร็วเข้า ก่อนพลังจะหมด", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 1}
		],

		"gameplay": {
			1: {
				"title": "ประตูสู่คลังเวทกลาง",
				"story": "ประตูดูดพลังผู้ที่ยังไม่ส่งคัมภีร์เข้าคลัง — ผูกสายเชื่อม origin แล้วส่งคัมภีร์ของนายไปที่ " + URL,
				"panels": ["terminal", "files", "graph"],
				# ม้วนคาถาที่แจกตอนเริ่มขั้นนี้ (SpellCatalog)
				"teaches": ["remote_add", "push"],
				"remote": {"name": "apprentice-tome", "description": "คัมภีร์ของเวล ศิษย์ของปรมาจารย์"},
				"setup": Level13Dialogue.IDENTITY + [
					{"run": "git init"},
					{"write": "fragment-10.txt", "content": "ความรู้ที่ไม่ถูกแบ่งปัน\n"},
					{"run": "git add ."},
					{"run": "git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 10\""},
					{"write": "fragment-11.txt", "content": "ย่อมดับไปพร้อมผู้ครอบครอง\n"},
					{"run": "git add ."},
					{"run": "git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 11\""}
				],
				"room": {"hearts": 3, "wave_every": 3, "sync_required": true,
					"items": {
						"fragment-10.txt": {"kind": "fragment", "name": "เศษคัมภีร์ชิ้นที่ 10"},
						"fragment-11.txt": {"kind": "fragment", "name": "เศษคัมภีร์ชิ้นที่ 11"}
					}},
				"objectives": [
					{
						"id": "bond",
						"text": "ผูกสายเชื่อมชื่อ origin ไปยังที่อยู่ในคลังของนาย",
						"short": "ผูกสายเชื่อม origin",
						"type": "command",
						"commands": ["git remote add origin " + URL],
						"world": "สายใยแสงพุ่งจากคัมภีร์ของนายไปจรดประตูเวท",
						"hint": "git remote add <ชื่อ> <ที่อยู่> — git remote add origin " + URL
					},
					{
						"id": "send",
						"text": "ส่งคัมภีร์เข้าคลังเป็นครั้งแรก พร้อมผูก main เข้ากับ origin/main",
						"short": "ส่งคัมภีร์ผ่านประตู",
						"type": "state",
						"check": "in_sync",
						"upstream": "origin/main",
						"spell": "push",
						"flags": ["-u", "--set-upstream"],
						"world": "เศษคัมภีร์ทั้งหมดบินวนเป็นเกลียวแล้วพุ่งเข้าประตูเวท… ประตูหยุดหมุนและเปิดออก",
						"hint": "คาถาส่งผ่านประตูคือ push ครั้งแรกต้องผูกเส้นทางด้วย -u: git push -u origin main"
					}
				],
				"success_text": "ได้รับเศษคัมภีร์ชิ้นที่ 12: \"ข้ารอเจ้าอยู่ที่คลังเวทกลาง\""
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "ครั้งต่อไปแค่ git push ก็พอ เพราะเส้นทางผูกไว้แล้ว", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "\"ข้ารอเจ้าอยู่ที่คลังเวทกลาง\"… อาจารย์อยู่ที่นั่น!", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ฉันไปได้แค่ตรงนี้ หลังประตูคือคลังเวทกลาง ผู้พิทักษ์จะดูแลนายต่อ", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "มิวรา… ขอบคุณนะ", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "อย่าลืมกินข้าวด้วยล่ะ ศิษย์ฝึกหัด", "mewla_anim": "success"}
		]
	}
