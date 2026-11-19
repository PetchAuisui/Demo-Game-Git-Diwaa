class_name Level07Dialogue
extends RefCounted

## ด่านที่ 7: รอยอักขระที่ถูกแก้ (git diff) — มินิเกม "อักขระกุญแจ"
## พลังโกลาหลเขียนทับอักขระกุญแจบนเศษคัมภีร์ชิ้นที่ 4 — cat เห็นแต่ของปลอม (umbra)
## มีแค่คาถาเทียบรอยที่เห็นของเดิม (lumina) → เอ่ยของเดิมเพื่อปลุกเศษคัมภีร์
## จากนั้นนามแท้แอบขึ้นแท่นเตรียม: git diff เฉย ๆ ไม่เห็น ต้อง git diff --staged
## เอ่ยผิดเสียหัวใจ และถ้าคลื่นมาก่อน เศษคัมภีร์ที่ถูกแก้จะถูกสาปซ้ำ

const ORIGINAL := "จงสังเกตทุกรอยที่เปลี่ยนไป\nอักขระกุญแจ: lumina\n"

## ขั้นที่ 2: วงอักขระแปดดวง — ดวงที่ถูกเติม (sol บนแท่น, aris บนโต๊ะ) แทรกอยู่ระหว่างอักขระเดิม
const CIRCLE_BASE := "วงอักขระ\n✦ vex\n✦ orn\n✦ tal\n✦ qem\n✦ dru\n✦ pyx\n"
const CIRCLE_STAGED := "วงอักขระ\n✦ vex\n✦ orn\n✦ sol\n✦ tal\n✦ qem\n✦ dru\n✦ pyx\n"
const CIRCLE_NOW := "วงอักขระ\n✦ vex\n✦ orn\n✦ sol\n✦ tal\n✦ qem\n✦ aris\n✦ dru\n✦ pyx\n"


static func get_data() -> Dictionary:
	return {
		"level_id": 7,
		"title": "ด่านที่ 7: รอยอักขระที่ถูกแก้",
		"time_limit": 100.0,
		"max_score": 160,
		"commands": ["git diff"],
		"clear_keyword": "git diff เทียบโต๊ะกับแท่น (- ของเดิม / + ของใหม่) · git diff --staged เทียบแท่นกับคัมภีร์ · git diff HEAD เทียบทุกอย่างกับการจารึกล่าสุด",

		"intro_sequence": [
			{"speaker": "มิวรา", "text": "หมอกสีม่วงลอยผ่านโต๊ะ… อักขระกุญแจบนเศษคัมภีร์ชิ้นที่ 4 บิดเบี้ยวไปแล้ว", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "ก็อ่านดูก็รู้แล้วนี่ว่าเขียนว่าอะไร", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "สิ่งที่นายอ่านคือของที่โกลาหลเขียนทับ ถ้าเอ่ยอักขระปลอม พลังจะย้อนกลับมาหานาย — ต้องรู้ว่าของเดิมคืออะไร", "mewla_anim": "talk"},
			{"type": "open_gameplay", "step": 1}
		],

		"part2_intro_sequence": [
			{"speaker": "เวล", "text": "พื้นห้องมีวงอักขระแปดดวง… ทุกดวงหน้าตาเหมือนกันหมด", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "รหัสคืออักขระที่ถูกเติมหลังการจารึกล่าสุด ดวงหนึ่งแอบขึ้นแท่นไปแล้ว อีกดวงยังอยู่บนโต๊ะ", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "เทียบทีละครึ่งวงจะกระชากพลัง ต้องเทียบทั้งหมดกับการจารึกล่าสุดในคราวเดียว — git diff HEAD", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 2}
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
						"text": "เศษชิ้นที่ 4 ถูกเขียนทับ — หาอักขระกุญแจดั้งเดิม แล้วพิมพ์ say ตามด้วยอักขระนั้น",
						"short": "เอ่ยอักขระกุญแจดั้งเดิม",
						"type": "say",
						"words": ["lumina"],
						"world": "lumina เปล่งแสงขับหมอกออกไป… แต่แท่นเตรียมสว่างขึ้นเอง มีบางอย่างแอบขึ้นไปบนแท่น!",
						"hint": "หยิบอ่านเห็นแค่ของปลอม — คาถาเทียบรอย git diff จะแสดงบรรทัด - (ของเดิม) และ + (ของใหม่)",
						"spawn": [
							{"write": "fragment-4.txt", "content": ORIGINAL + "นามแท้: ignis\n"},
							{"run": "git add fragment-4.txt"}
						]
					},
					{
						"id": "true_name",
						"text": "มีอักขระใหม่แอบขึ้นแท่นเตรียม — หานามแท้ที่ถูกเพิ่มบนแท่น แล้วพิมพ์ say ตามด้วยนามนั้น",
						"short": "เอ่ยนามแท้ที่แอบขึ้นแท่น",
						"type": "say",
						"words": ["ignis"],
						"world": "เศษคัมภีร์ชิ้นที่ 4 ตื่นขึ้นและจารึกตัวเองลงคัมภีร์: \"จงสังเกตทุกรอยที่เปลี่ยนไป\"",
						"hint": "git diff เทียบแค่โต๊ะกับแท่น (ตอนนี้เหมือนกัน) ต้องเทียบแท่นกับคัมภีร์: git diff --staged",
						"spawn": [{"run": "git commit -m \"ปลุกเศษคัมภีร์ชิ้นที่ 4\""}]
					}
				],
				"success_text": "ได้รับเศษคัมภีร์ชิ้นที่ 4!"
			},
			2: {
				"title": "วงอักขระแปดดวง",
				"story": "วงเวทมีอักขระแปดดวง แต่มีแค่ดวงที่ถูกเติมหลังการจารึกล่าสุดเท่านั้นที่เป็นรหัส — ครึ่งหนึ่งอยู่บนแท่น อีกครึ่งอยู่บนโต๊ะ ต้องเห็นทั้งสองพร้อมกัน",
				"panels": ["terminal", "files"],
				# ม้วนคาถาใหม่: เทียบรอยทั้งหมดกับการจารึกล่าสุด (git diff HEAD)
				"teaches": ["diff_head"],
				"setup": [
					{"run": "git config --global user.name \"Vel\""},
					{"run": "git config --global user.email \"vel@magic-tower.local\""},
					{"run": "git init"},
					{"write": "rune-circle.txt", "content": CIRCLE_BASE},
					{"run": "git add ."},
					{"run": "git commit -m \"วาดวงอักขระ\""},
					{"write": "rune-circle.txt", "content": CIRCLE_STAGED},
					{"run": "git add rune-circle.txt"},
					{"write": "rune-circle.txt", "content": CIRCLE_NOW}
				],
				"room": {
					"hearts": 3, "wave_every": 5, "wrong_say": 1,
					"forbidden": [
						{"pattern": "^git\\s+diff(?!.*\\bHEAD\\b)", "text": "เทียบรอยได้แค่ครึ่งวง อักขระอีกครึ่งเลือนหายไปชั่วขณะ — วงเวทกระชากพลังนาย!"}
					],
					"items": {
						"rune-circle.txt": {"kind": "note", "name": "วงอักขระแปดดวง"}
					}
				},
				"objectives": [
					{
						"id": "whole",
						"text": "เทียบรอยทั้งโต๊ะและแท่นกับการจารึกล่าสุดในคาถาเดียว",
						"short": "เทียบรอยทั้งหมดกับการจารึกล่าสุด",
						"type": "state",
						"check": "cast",
						"spell": "diff",
						"flags": ["HEAD"],
						"world": "อักขระที่เพิ่งถูกเติมทั้งสองดวงเรืองแสงขึ้นพร้อมกัน",
						"hint": "HEAD คือการจารึกล่าสุด: git diff HEAD เทียบทุกอย่าง (โต๊ะ + แท่น) กับมัน"
					},
					{
						"id": "circle",
						"text": "พิมพ์ say ตามด้วยอักขระสองดวงที่ถูกเติมหลังการจารึกล่าสุด ต่อกันเป็นคำเดียว (เรียงจากบนลงล่าง)",
						"short": "เอ่ยอักขระที่ถูกเติม (ต่อกันเป็นคำเดียว)",
						"type": "say",
						"words": ["solaris"],
						"world": "วงอักขระหมุนแล้วเปิดเป็นประตูแสง",
						"hint": "ในผลของ git diff HEAD ดูบรรทัดที่ขึ้นต้นด้วย + แล้วเอาอักขระมาต่อกัน"
					}
				],
				"success_text": "วงอักขระแปดดวงเปิดออก!"
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "diff ดูโต๊ะเทียบแท่น ส่วน diff --staged ดูแท่นเทียบคัมภีร์ จำไว้ให้ดี", "mewla_anim": "success"},
			{"speaker": "เวล", "text": "ถ้าไม่มีคาถาเทียบรอย ฉันคงเอ่ย umbra ไปแล้วแน่ ๆ", "mewla_anim": "idle"}
		]
	}
