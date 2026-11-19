class_name Level07Dialogue
extends RefCounted

## ด่านที่ 7: รอยอักขระที่ถูกแก้ (git diff) — มินิเกม "อักขระกุญแจ"
## พลังโกลาหลเขียนทับอักขระกุญแจบนเศษคัมภีร์ชิ้นที่ 4 — cat เห็นแต่ของปลอม (umbra)
## มีแค่คาถาเทียบรอยที่เห็นของเดิม (lumina) → เอ่ยของเดิมเพื่อปลุกเศษคัมภีร์
## จากนั้นนามแท้แอบขึ้นแท่นเตรียม: git diff เฉย ๆ ไม่เห็น ต้อง git diff --staged
## เอ่ยผิดเสียหัวใจ และถ้าคลื่นมาก่อน เศษคัมภีร์ที่ถูกแก้จะถูกสาปซ้ำ

const ORIGINAL := "จงสังเกตทุกรอยที่เปลี่ยนไป\nอักขระกุญแจ: lumina\n"


static func get_data() -> Dictionary:
	return {
		"level_id": 7,
		"title": "ด่านที่ 7: รอยอักขระที่ถูกแก้",
		"time_limit": 100.0,
		"max_score": 160,
		"commands": ["git diff"],
		"clear_keyword": "git diff เทียบโต๊ะกับคัมภีร์ (- ของเดิม / + ของใหม่) · git diff --staged เทียบแท่นเตรียมกับคัมภีร์",

		"intro_sequence": [
			{"speaker": "มิวรา", "text": "หมอกสีม่วงลอยผ่านโต๊ะ… อักขระกุญแจบนเศษคัมภีร์ชิ้นที่ 4 บิดเบี้ยวไปแล้ว", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "ก็อ่านดูก็รู้แล้วนี่ว่าเขียนว่าอะไร", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "สิ่งที่นายอ่านคือของที่โกลาหลเขียนทับ ถ้าเอ่ยอักขระปลอม พลังจะย้อนกลับมาหานาย — ต้องรู้ว่าของเดิมคืออะไร", "mewla_anim": "talk"},
			{"type": "open_gameplay", "step": 1}
		],

		"gameplay": {
			1: {
				"title": "อักขระกุญแจ",
				"story": "อักขระกุญแจบน fragment-4 ถูกเขียนทับ — หาอักขระดั้งเดิมแล้วเอ่ยเพื่อปลุกเศษคัมภีร์",
				"panels": ["terminal", "files", "graph"],
				# ม้วนคาถาที่แจกตอนเริ่มขั้นนี้ (SpellCatalog)
				"teaches": ["diff", "diff_staged"],
				"setup": [
					{"run": "git config --global user.name \"Vel\""},
					{"run": "git config --global user.email \"vel@magic-tower.local\""},
					{"run": "git init"},
					{"write": "fragment-3.txt", "content": "ย่อมสูญหายไปกับกาลเวลา\n"},
					{"run": "git add ."},
					{"run": "git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 3\""},
					{"write": "fragment-4.txt", "content": ORIGINAL},
					{"run": "git add ."},
					{"run": "git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 4 (ยังหลับอยู่)\""},
					{"write": "fragment-4.txt", "content": "จงสังเกตทุกรอยที่เปลี่ยนไป\nอักขระกุญแจ: umbra\n"}
				],
				"room": {
					"hearts": 3, "wave_every": 5, "wrong_say": 1, "cursed": ["fragment-4.txt"],
					"items": {
						"fragment-3.txt": {"kind": "fragment", "name": "เศษคัมภีร์ชิ้นที่ 3"},
						"fragment-4.txt": {"kind": "fragment", "name": "เศษคัมภีร์ชิ้นที่ 4"}
					}
				},
				"objectives": [
					{
						"id": "key_rune",
						"text": "หาอักขระกุญแจดั้งเดิมที่ถูกเขียนทับ แล้วเอ่ยมัน (พิมพ์ say ตามด้วยอักขระ)",
						"short": "เอ่ยอักขระดั้งเดิม",
						"type": "say",
						"words": ["lumina"],
						"world": "lumina เปล่งแสงขับหมอกออกไป… แต่แท่นเตรียมสว่างขึ้นเอง มีบางอย่างแอบขึ้นไปบนแท่น!",
						"hint": "cat เห็นแค่ของปลอม — คาถาเทียบรอย git diff จะแสดงบรรทัด - (ของเดิม) และ + (ของใหม่)",
						"spawn": [
							{"write": "fragment-4.txt", "content": ORIGINAL + "นามแท้: ignis\n"},
							{"run": "git add fragment-4.txt"}
						]
					},
					{
						"id": "true_name",
						"text": "มีอักขระใหม่แอบขึ้นแท่นเตรียม — หานามแท้ที่ถูกเพิ่มเข้ามาแล้วเอ่ยมัน",
						"short": "เอ่ยนามแท้",
						"type": "say",
						"words": ["ignis"],
						"world": "เศษคัมภีร์ชิ้นที่ 4 ตื่นขึ้นและจารึกตัวเองลงคัมภีร์: \"จงสังเกตทุกรอยที่เปลี่ยนไป\"",
						"hint": "git diff เทียบแค่โต๊ะกับแท่น (ตอนนี้เหมือนกัน) ต้องเทียบแท่นกับคัมภีร์: git diff --staged",
						"spawn": [{"run": "git commit -m \"ปลุกเศษคัมภีร์ชิ้นที่ 4\""}]
					}
				],
				"success_text": "ได้รับเศษคัมภีร์ชิ้นที่ 4!"
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "diff ดูโต๊ะเทียบแท่น ส่วน diff --staged ดูแท่นเทียบคัมภีร์ จำไว้ให้ดี", "mewla_anim": "success"},
			{"speaker": "เวล", "text": "ถ้าไม่มีคาถาเทียบรอย ฉันคงเอ่ย umbra ไปแล้วแน่ ๆ", "mewla_anim": "idle"}
		]
	}
