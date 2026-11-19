class_name Level02Dialogue
extends RefCounted

## ด่านที่ 2: คัมภีร์เล่มแรก (git init) — Game Design v2
## ปัญหาในโลก: เศษคัมภีร์ที่จะได้พบต้องมีที่จารึก แต่บนโต๊ะยังไม่มีคัมภีร์

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
			{"speaker": "มิวรา", "text": "ชั้นสองคือห้องจารึก… แต่โต๊ะตัวนี้ว่างเปล่า", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "เศษคัมภีร์ที่นายจะเจอต้องมีที่จารึก ไม่งั้นมันจะสลายไปกับลม", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "งั้นฉันต้องมีคัมภีร์ของตัวเอง?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ใช่ ร่ายคาถากำเนิดคัมภีร์บนโต๊ะนี้เลย", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 1}
		],

		"gameplay": {
			1: {
				"title": "คัมภีร์เล่มแรก",
				"story": "บนโต๊ะยังไม่มีคัมภีร์ ร่ายคาถากำเนิดคัมภีร์เวทส่วนตัว",
				"panels": ["terminal"],
				"setup": IDENTITY,
				"objectives": [
					{
						"id": "tome",
						"text": "ให้คัมภีร์เวทส่วนตัวถือกำเนิดบนโต๊ะนี้ (git init)",
						"short": "คัมภีร์ถือกำเนิด",
						"type": "state",
						"check": "repo_initialized",
						"world": "แสงรวมตัวเหนือโต๊ะ ก่อตัวเป็นหนังสือ — มันซ่อนตัวอยู่ในห้องลับชื่อ .git",
						"hint": "คาถากำเนิดคัมภีร์สั้นมาก: git ตามด้วยคำว่า init (initialize)",
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
			{"speaker": "มิวรา", "text": "ต่อจากนี้ทุกอย่างที่เกิดบนโต๊ะนี้ คัมภีร์จะเฝ้ามองไว้", "mewla_anim": "success"},
			{"speaker": "มิวรา", "text": "ชั้นถัดไปมีกระดาษปลิวมาเต็มโต๊ะ… ไปดูกันว่าคัมภีร์มองเห็นอะไร", "mewla_anim": "talk"}
		]
	}
