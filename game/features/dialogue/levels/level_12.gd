class_name Level12Dialogue
extends RefCounted

## ด่านที่ 12: พิธีหลอมมิติ (git merge) — มินิเกม "กุญแจสุริยันจันทรา"
## ประตูชั้นบนต้องการกุญแจทั้งดวง: ครึ่งสุริยันอยู่ใน main ครึ่งจันทราอยู่ใน experiment → ต้อง merge
## แต่ทั้งสองมิติเขียน "แกนแท่นบูชา" ต่างกัน (ไฟ vs น้ำแข็ง) → การปะทะ (conflict)
## ผู้เล่นตัดสินเองว่าแกนจะเป็นอะไร (แก้ไฟล์ใน Files หรือ write) แล้ววางขึ้นแท่นและจารึกให้พิธีจบ

const CORE_BASE := "แกนแท่นบูชา: ???\n"


static func get_data() -> Dictionary:
	return {
		"level_id": 12,
		"title": "ด่านที่ 12: พิธีหลอมมิติ",
		"time_limit": 75.0,
		"max_score": 210,
		"commands": ["git merge"],
		"clear_keyword": "git merge <มิติ> หลอม branch · conflict: แก้ไฟล์ → git add → git commit · git merge --abort ยกเลิกพิธี",

		"intro_sequence": [
			{"speaker": "เวล", "text": "ประตูชั้นบนมีรูกุญแจรูปวงกลม… ครึ่งสุริยันอยู่ในมือฉัน แต่ครึ่งจันทราอยู่ในอีกมิติ", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "หลอมมิติ experiment เข้ามาสิ แล้วกุญแจจะครบดวง", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "แต่ระวัง… ทั้งสองมิติจารึกแกนแท่นบูชาไว้ต่างกัน ไฟกับน้ำแข็งจะปะทะกัน และนายต้องเป็นคนตัดสิน", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 1}
		],

		"gameplay": {
			1: {
				"title": "กุญแจสุริยันจันทรา",
				"story": "หลอมมิติ experiment เข้ากับ main ให้กุญแจครบดวง และตัดสินการปะทะที่แกนแท่นบูชา",
				"panels": ["terminal", "files", "graph"],
				# ม้วนคาถาที่แจกตอนเริ่มขั้นนี้ (SpellCatalog)
				"teaches": ["merge", "write"],
				"setup": Level10Dialogue.BASE + [
					{"write": "key-sun.txt", "content": "ครึ่งกุญแจสุริยัน ☀\n"},
					{"write": "altar-core.txt", "content": CORE_BASE},
					{"run": "git add ."},
					{"run": "git commit -m \"วางแกนแท่นบูชาและครึ่งกุญแจสุริยัน\""},
					{"run": "git switch -c experiment"},
					{"write": "key-moon.txt", "content": "ครึ่งกุญแจจันทรา ☾\n"},
					{"write": "altar-core.txt", "content": "แกนแท่นบูชา: เปลวไฟ\n"},
					{"run": "git add ."},
					{"run": "git commit -m \"ครึ่งกุญแจจันทราและแกนแห่งไฟ\""},
					{"run": "git switch main"},
					{"write": "altar-core.txt", "content": "แกนแท่นบูชา: น้ำแข็ง\n"},
					{"run": "git commit -am \"แกนแห่งน้ำแข็ง\""}
				],
				"room": {"hearts": 3, "wave_every": 4, "respawn": true,
					"items": {
						"key-sun.txt": {"kind": "key", "name": "ครึ่งกุญแจสุริยัน"},
						"key-moon.txt": {"kind": "key", "name": "ครึ่งกุญแจจันทรา"},
						"altar-core.txt": {"kind": "fragment", "name": "แกนแท่นบูชา"}
					}},
				"objectives": [
					{
						"id": "ritual",
						"text": "เริ่มพิธีหลอมมิติ experiment เข้ากับ main",
						"short": "เริ่มพิธีหลอมมิติ",
						"type": "state",
						"check": "has_conflict",
						"world": "⚡ ไฟกับน้ำแข็งปะทะกันกลางแท่นบูชา! — เปิด altar-core.txt ดูรอย <<<<<<< ======= >>>>>>>",
						"hint": "คาถาหลอมมิติคือ merge ตามด้วยชื่อมิติที่จะดึงเข้ามา: git merge experiment"
					},
					{
						"id": "judge",
						"text": "ตัดสินแกนแท่นบูชา (แก้ altar-core.txt ให้เหลือแบบที่นายเลือก) แล้ววางขึ้นแท่น",
						"short": "ตัดสินการปะทะ",
						"type": "state",
						"check": "staged",
						"paths": ["altar-core.txt"],
						"world": "การปะทะสงบลง แกนแท่นบูชาเรืองแสงตามที่นายตัดสิน",
						"hint": "แก้ไฟล์ในแผง Files หรือ write altar-core.txt แกนแท่นบูชา: ไอน้ำ แล้ว git add altar-core.txt"
					},
					{
						"id": "seal",
						"text": "จารึกผลการหลอม ให้กุญแจครบดวงในมิติหลัก",
						"short": "จารึกผลการหลอม",
						"type": "state",
						"check": "merge_commit",
						"world": "สองแสงหลอมรวม กุญแจสุริยันจันทราครบดวง ประตูชั้นบนคลายล็อก — ได้รับเศษคัมภีร์ชิ้นที่ 9",
						"hint": "git commit -m \"หลอมมิติ\""
					}
				],
				"success_text": "ได้รับเศษคัมภีร์ชิ้นที่ 9: \"แล้วนำสิ่งที่ดีที่สุดกลับมารวมกัน\""
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "ถ้าสองมิติไม่ได้แก้บรรทัดเดียวกัน Git หลอมให้เองอัตโนมัติ การปะทะเกิดเฉพาะจุดที่ชนกัน", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "และถ้าวันหน้ากลัวการปะทะ git merge --abort จะยกเลิกพิธีกลับไปก่อนหลอม", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "\"แล้วนำสิ่งที่ดีที่สุดกลับมารวมกัน\" … อาจารย์กำลังสอนอะไรฉันอยู่กันแน่", "mewla_anim": "idle"}
		]
	}
