class_name Level01Dialogue
extends RefCounted

## ข้อมูลบทสนทนาด่านที่ 1: ตรวจสอบพลังและประกาศนาม (git --version + git config)
## เก็บเฉพาะโครงสร้างข้อมูลบทพูด ช้อยส์ และลำดับการตอบคำถาม
## สอดคล้องกับข้อกำหนดใน docs/inside-tower-cutscene.md

static func get_data() -> Dictionary:
	return {
		"level_id": 1,
		"title": "ด่านที่ 1: ตรวจสอบพลังและประกาศนาม",
		"time_limit": 130.0,
		"max_score": 100,
		"commands": ["git --version", "git config"],
		"clear_keyword": "git --version เพื่อเช็กความพร้อมของ Git และ git config เพื่อตั้งชื่อกับอีเมลผู้สร้างงาน",

		# ======================================================================
		# Game Design v2: ปัญหาในโลก → ลงมือทันที → โลกตอบสนอง
		# ไม่มีเมนูคำถามขวางก่อนเล่น ไม่มีฉากจบร้าย ความรู้ไปอยู่ในเป้าหมาย คำใบ้ และผลของคาถาในฉาก
		# ======================================================================
		"intro_sequence": [
			{"speaker": "มิวรา", "text": "วงเวทของหอคอยมืดสนิท… มันไม่ตอบคนที่พลังยังไม่ตื่น", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ถ้านายอยากตามหาปรมาจารย์กับเศษคัมภีร์ที่หายไป ต้องปลุกมันให้ได้ก่อน", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "ปลุกยังไง?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ร่ายคาถาวัดพลังใส่วงเวท แล้วดูว่ามันตอบอะไรกลับมา", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 1}
		],

		# ======================================================================
		# ช่วงที่ 2: ประตูหอคอยไม่รู้ว่านายเป็นใคร
		# ======================================================================
		"part2_intro_sequence": [
			{"speaker": "มิวรา", "text": "วงเวทสว่างแล้ว! แต่ดูประตูนั่นสิ… ยังไม่ยอมเปิด", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ทุกการจารึกในหอคอยต้องมีนามผู้จารึก ประตูจึงไม่ยอมให้ใครที่ไม่ประกาศนามผ่านไป", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "งั้นก็ประกาศนามซะเลย", "mewla_anim": "idle"},
			{"type": "open_gameplay", "step": 2}
		],

		# ======================================================================
		# ขั้นเล่นจริง (Sandbox + แผงภารกิจ): เปิดจาก {"type": "open_gameplay", "step": N}
		# objective.text = ข้อความเต็ม (แสดงในช่องพิมพ์เทอร์มินัล) / short = ชื่อสั้นในเช็กลิสต์ของแผงภารกิจ (ไม่ใส่ = ใช้ text)
		# ตรวจคำสั่งด้วย LevelMission (ดูชนิด objective ที่ features/level_mission/level_mission.gd)
		# ======================================================================
		"gameplay": {
			1: {
				"title": "ปลุกวงเวท",
				"story": "วงเวทหน้าประตูมืดสนิท ร่ายคาถาวัดพลังในวงร่ายเวท (Terminal) ด้านล่าง",
				# ด่านแรกใช้แค่วงร่ายเวท ยังไม่ต้องเห็นโต๊ะไฟล์หรือแผนที่ประวัติ
				"panels": ["terminal"],
				# ม้วนคาถาที่แจกตอนเริ่มขั้นนี้ (SpellCatalog)
				"teaches": ["version"],
				"objectives": [
					{
						"id": "version",
						"text": "ร่ายคาถา git --version",
						"world": "อักขระรอบวงเวทสว่างวาบขึ้นทีละตัว — พลังของนายตื่นแล้ว!",
						"type": "command",
						"commands": ["git --version", "git version"],
						"hint": "พิมพ์ git เว้นวรรค แล้วตามด้วยขีดคู่ติดกับคำว่า version (--version)",
						"near_miss": [
							{"pattern": "^git\\s+-version", "message": "ขีดหน้า version ต้องเป็นขีดคู่ --version"},
							{"pattern": "^git--", "message": "ต้องเว้นวรรคระหว่าง git กับ --version"},
							{"pattern": "^git\\s+–", "message": "อักขระนั้นไม่ใช่ขีดกลางธรรมดา ลองพิมพ์ -- ใหม่"}
						]
					}
				],
				"success_text": "วงเวทตอบรับพลังของนายแล้ว!"
			},
			2: {
				"title": "ประตูที่ไม่รู้จักนาม",
				"story": "ประตูหอคอยจะเปิดให้เฉพาะผู้ที่ประกาศนามและผูกตราประทับวิญญาณแล้วเท่านั้น",
				"panels": ["terminal"],
				# ม้วนคาถาที่แจกตอนเริ่มขั้นนี้ (SpellCatalog)
				"teaches": ["config"],
				"objectives": [
					{
						"id": "name",
						"text": "ประกาศนามด้วย git config --global user.name \"Vel\"",
						"short": "ประกาศนาม (user.name)",
						"world": "นามของนายถูกสลักลงบนบานประตู",
						"type": "config_set",
						"key": "user.name",
						"validator": "non_empty",
						"hint": "git config --global user.name แล้วตามด้วยชื่อในเครื่องหมายคำพูด เช่น \"Vel\"",
						"near_miss": [
							{"pattern": "^git\\s+config\\s+-global", "message": "--global ต้องเป็นขีดคู่"},
							{"pattern": "^git\\s+config\\s+--global\\s+user\\.name\\s*$", "message": "ยังไม่ได้ใส่ชื่อต่อท้าย (คำสั่งนี้ใช้ตรวจชื่อเท่านั้น)"}
						]
					},
					{
						"id": "email",
						"text": "ผูกตราประทับด้วย git config --global user.email \"vel@magic-tower.local\"",
						"short": "ผูกตราประทับ (user.email)",
						"world": "ตราประทับเรืองแสงข้างนาม — ประตูเริ่มสั่นไหว",
						"type": "config_set",
						"key": "user.email",
						"validator": "email",
						"hint": "git config --global user.email แล้วตามด้วยอีเมลในเครื่องหมายคำพูด ต้องมี @ และโดเมน",
						"near_miss": [
							{"pattern": "^git\\s+config\\s+--global\\s+user\\.email\\s+\\S+", "message": "อีเมลต้องมี @ และโดเมน เช่น vel@magic-tower.local"}
						]
					},
					{
						"id": "verify",
						"text": "ตรวจชื่อที่จดไว้ด้วย git config --global user.name",
						"short": "ให้ประตูขานนามกลับมา",
						"world": "ประตูขานนามของนายกลับมา แล้วค่อย ๆ เปิดออก",
						"type": "config_get",
						"key": "user.name",
						"hint": "ร่ายคาถาเดิมแต่ไม่ต้องใส่ชื่อต่อท้าย หอคอยจะตอบชื่อที่จดจำไว้"
					}
				],
				"success_text": "ประตูหอคอยเปิดออกแล้ว!"
			}
		},

		# ======================================================================
		# 3. สรุปผลหลังผ่านด่านที่ 1
		# ======================================================================
		"outro_sequence": [
			{"speaker": "มิวรา", "text": "ดีมาก ต่อจากนี้ทุกการจารึกของนายจะมีนามกำกับเสมอ", "mewla_anim": "success"},
			{"speaker": "มิวรา", "text": "ชั้นถัดไป เราจะสร้าง 'คัมภีร์เวทส่วนตัว' เล่มแรกของนายกัน", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "...หอคอยนี้ไม่มีลิฟต์เหรอ", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "…นั่นสิ", "mewla_anim": "talk"}
		]
	}
