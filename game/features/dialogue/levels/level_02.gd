class_name Level02Dialogue
extends RefCounted

## ด่านที่ 2: คัมภีร์เล่มแรก (git init) — Game Design v2
## ปัญหาในโลก: เศษคัมภีร์ที่จะได้พบต้องมีที่จารึก แต่บนแท่นยังไม่มีคัมภีร์ (ผ้าปูของเวลยังม้วนอยู่)

const IDENTITY := [
	{"run": "git config --global user.name \"Vel\""},
	{"run": "git config --global user.email \"vel@magic-tower.local\""},
]


static func get_data() -> Dictionary:
	return {
		"level_id": 2,
		"title": "ด่านที่ 2: คัมภีร์เล่มแรก",
		"time_limit": 40.0,
		"max_score": 110,
		"commands": ["git init"],
		"clear_keyword": "git init เพื่อสร้างคัมภีร์ (repository) ใหม่ที่จดจำทุกการเปลี่ยนแปลงในโฟลเดอร์",

		"intro_sequence": [
			{"speaker": "มิวรา", "text": "ได้ยินเสียงนั่นไหม… คลื่นโกลาหลกำลังไหลลงมาตามบันได!", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "นักเวทที่ไม่มีคัมภีร์รองรับพลังจะโดนมันซัดเต็ม ๆ", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "แล้วฉันมีเวลาแค่ไหน?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ไม่กี่อึดใจ — ดูมาตรวัดสีม่วงไว้ แล้วทำให้คัมภีร์ถือกำเนิดก่อนมันมาถึง", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 1}
		],

		"gameplay": {
			1: {
				"title": "คัมภีร์เล่มแรก",
				"story": "คลื่นโกลาหลกำลังมา และนายยังไม่มีคัมภีร์รองรับพลัง",
				"panels": ["terminal"],
				# ม้วนคาถาที่แจกตอนเริ่มขั้นนี้ (SpellCatalog)
				"teaches": ["init"],
				"setup": IDENTITY,
				# คลื่นแรกมาหลังการกระทำที่ 2: ถ้ายังไม่มีคัมภีร์จะเสียหัวใจ (พิมพ์ผิดก็กินเวลา)
				"room": {"hearts": 3, "wave_every": 2, "needs_tome": true},
				"objectives": [
					{
						"id": "tome",
						"text": "สร้างคัมภีร์เวทส่วนตัวในห้องนี้ ก่อนคลื่นโกลาหลมาถึง",
						"short": "สร้างคัมภีร์ก่อนคลื่นมา",
						"type": "state",
						"check": "repo_initialized",
						"world": "แสงรวมตัวเหนือแท่นหิน ก่อตัวเป็นหนังสือ — มันซ่อนตัวอยู่ในห้องลับชื่อ .git",
						"hint": "คาถากำเนิดคัมภีร์สั้นมาก: git ตามด้วยคำว่า init (initialize — เริ่มต้น)",
						"near_miss": [
							{"pattern": "^git\\s+inti", "message": "สะกดผิดนิดเดียว — init (i-n-i-t)"},
							{"pattern": "^git\\s+create", "message": "Git ใช้คำว่า init ไม่ใช่ create"}
						]
					}
				],
				"success_text": "คัมภีร์เวทส่วนตัวของนายถือกำเนิดแล้ว!"
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "ต่อจากนี้ทุกอย่างที่วางบนผ้าปูผืนนี้ คัมภีร์จะเฝ้ามองไว้", "mewla_anim": "success"},
			{"speaker": "มิวรา", "text": "ชั้นถัดไปมีกระดาษปลิวมาเต็มผ้าปู… ไปดูกันว่าคัมภีร์มองเห็นอะไร", "mewla_anim": "talk"}
		]
	}
