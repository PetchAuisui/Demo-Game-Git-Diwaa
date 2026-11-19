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

		"part2_intro_sequence": [
			{"speaker": "เวล", "text": "ได้ยินเสียงไหม… มีมิติชื่อ echo ร้องเรียกให้หลอมรวมกับมัน", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ฉันไม่ไว้ใจมันเลย ถ้าจะดูก็เริ่มพิธีได้ แต่อ่านให้ดีว่ามันเขียนอะไรมา", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ถ้าเป็นของโกลาหลจริง ห้ามจารึกเด็ดขาด — ยุติพิธีด้วย git merge --abort ทุกอย่างจะกลับเหมือนก่อนหลอม", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 2}
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
						"text": "หลอมมิติ experiment เข้ามาในมิติหลัก main ที่นายยืนอยู่",
						"short": "หลอมมิติ experiment เข้ามาใน main",
						"type": "state",
						"check": "has_conflict",
						"world": "⚡ ไฟกับน้ำแข็งปะทะกันกลางแท่นบูชา! — เปิด altar-core.txt ดูรอย <<<<<<< ======= >>>>>>>",
						"hint": "คาถาหลอมมิติคือ merge ตามด้วยชื่อมิติที่จะดึงเข้ามา: git merge experiment"
					},
					{
						"id": "judge",
						"text": "แก้ altar-core.txt ให้เหลือแกนที่นายเลือก (ลบรอย <<<<<<< ======= >>>>>>> ออก) แล้ววางขึ้นแท่น",
						"short": "แก้แกนแท่นบูชา แล้ววางขึ้นแท่น",
						"type": "state",
						"check": "staged",
						"paths": ["altar-core.txt"],
						"world": "การปะทะสงบลง แกนแท่นบูชาเรืองแสงตามที่นายตัดสิน",
						"hint": "แก้ไฟล์ในแผง Files หรือ write altar-core.txt แกนแท่นบูชา: ไอน้ำ แล้ว git add altar-core.txt"
					},
					{
						"id": "seal",
						"text": "จารึกผลการหลอม ให้กุญแจครบดวงในมิติหลัก",
						"short": "จารึกผลการหลอมให้พิธีจบ",
						"type": "state",
						"check": "merge_commit",
						"world": "สองแสงหลอมรวม กุญแจสุริยันจันทราครบดวง ประตูชั้นบนคลายล็อก — ได้รับเศษคัมภีร์ชิ้นที่ 9",
						"hint": "git commit -m \"หลอมมิติ\""
					}
				],
				"success_text": "ได้รับเศษคัมภีร์ชิ้นที่ 9: \"แล้วนำสิ่งที่ดีที่สุดกลับมารวมกัน\""
			},
			2: {
				"title": "มิติเงาสะท้อน",
				"story": "มิติ echo ส่งเสียงเรียกให้หลอมรวม แต่มันคือกับดักของโกลาหล — เริ่มพิธี ดูว่ามันเขียนอะไรมา แล้วยุติพิธีก่อนจะสาย",
				"panels": ["terminal", "files", "graph"],
				# ม้วนคาถาใหม่: ยุติพิธีหลอมมิติ (git merge --abort)
				"teaches": ["merge_abort"],
				"setup": Level10Dialogue.BASE + [
					{"write": "key-whole.txt", "content": "กุญแจสุริยันจันทรา ☀☾\n"},
					{"write": "altar-core.txt", "content": "แกนแท่นบูชา: ไอน้ำ\n"},
					{"run": "git add ."},
					{"run": "git commit -m \"กุญแจครบดวงและแกนแห่งไอน้ำ\""},
					{"run": "git switch -c echo"},
					{"write": "key-whole.txt", "content": "กุญแจแห่งโกลาหล — ผู้ใดหลอมรวม ข้าจะยึดหอคอย\n"},
					{"write": "altar-core.txt", "content": "แกนแท่นบูชา: เงามืด\n"},
					{"run": "git commit -am \"เสียงจากมิติเงา: จงหลอมข้าเข้าไป\""},
					{"run": "git switch main"},
					{"write": "key-whole.txt", "content": "กุญแจสุริยันจันทรา ☀☾ (เปล่งแสงเต็มดวง)\n"},
					{"write": "altar-core.txt", "content": "แกนแท่นบูชา: ไอน้ำบริสุทธิ์\n"},
					{"run": "git commit -am \"ชำระกุญแจและแกนให้บริสุทธิ์\""}
				],
				"room": {"hearts": 3, "wave_every": 3, "respawn": true, "max_commits": 5,
					"items": {
						"key-whole.txt": {"kind": "key", "name": "กุญแจสุริยันจันทรา"},
						"altar-core.txt": {"kind": "fragment", "name": "แกนแท่นบูชา"}
					}},
				"objectives": [
					{
						"id": "lure",
						"text": "เริ่มพิธีหลอมมิติ echo เข้ามาใน main เพื่อดูว่ามันส่งอะไรมา",
						"short": "เริ่มหลอมมิติ echo เข้ามา",
						"type": "state",
						"check": "has_conflict",
						"world": "⚡ แท่นบูชาสั่น อักขระสีดำไหลออกมา — หยิบกุญแจขึ้นมาอ่านดูสิ มันเขียนอะไรไว้!",
						"hint": "git merge echo"
					},
					{
						"id": "abort",
						"text": "มิติ echo คือกับดักของโกลาหล — ยุติพิธีหลอมกลางคัน ให้ทุกอย่างกลับเป็นเหมือนก่อนเริ่ม (ห้ามจารึกผลการหลอม)",
						"short": "ยุติพิธีหลอม ให้ทุกอย่างกลับเหมือนเดิม",
						"type": "state",
						"check": "clean",
						"max_count": 5,
						"spell": "merge",
						"flags": ["--abort"],
						"world": "รอยปะทะทั้งหมดถูกดูดกลับไปในมิติเงา แท่นบูชาสงบลง ทุกอย่างกลับเป็นเหมือนก่อนพิธี",
						"hint": "คาถายุติพิธีหลอม: git merge --abort",
						"near_miss": [
							{"pattern": "^git\\s+commit", "message": "อย่าจารึก! การจารึกตอนนี้คือการรับมิติเงาเข้าคัมภีร์ — ใช้ git merge --abort"}
						]
					}
				],
				"success_text": "นายรอดจากกับดักมิติเงา!"
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "ถ้าสองมิติไม่ได้แก้บรรทัดเดียวกัน Git หลอมให้เองอัตโนมัติ การปะทะเกิดเฉพาะจุดที่ชนกัน", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "และไม่ใช่ทุกมิติที่ควรหลอมรวม — ถ้าเห็นว่าผิดก็ git merge --abort ยุติพิธีได้เสมอ", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "\"แล้วนำสิ่งที่ดีที่สุดกลับมารวมกัน\" … อาจารย์กำลังสอนอะไรฉันอยู่กันแน่", "mewla_anim": "idle"}
		]
	}
