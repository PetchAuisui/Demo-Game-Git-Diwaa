class_name Level14Dialogue
extends RefCounted

## ด่านที่ 14: ความรู้ใหม่จากคลัง (git pull) — มินิเกม "คัมภีร์ล้าหลัง"
## ผู้พิทักษ์เพิ่งจารึกเศษคัมภีร์ชิ้นที่ 11 ลงคัมภีร์แสงสว่างในคลัง แต่สำเนาของนายยังเก่าอยู่
## ในหอคอยนี้ คัมภีร์ที่ล้าหลังคลังจะถูกความรู้เก่ากัดกินทุกคลื่น (sync_required) → ต้องเรียกความรู้ลงมา


static func get_data() -> Dictionary:
	var light_tome: Dictionary = Level13Dialogue.LIGHT_TOME.duplicate(true)
	light_tome["commits"].append({"author": "Guardian", "message": "เพิ่มเศษคัมภีร์ชิ้นที่ 11",
			"files": {"fragment-11.txt": "ย่อมดับไปพร้อมผู้ครอบครอง\n"}})
	return {
		"level_id": 14,
		"title": "ด่านที่ 14: ความรู้ใหม่จากคลัง",
		"time_limit": 40.0,
		"max_score": 230,
		"commands": ["git pull"],
		"clear_keyword": "git pull = git fetch (ดูว่าคลังมีอะไรใหม่) + git merge (รวมเข้ามาในคัมภีร์ของเรา)",

		"intro_sequence": [
			{"speaker": "เวล", "text": "ระฆังที่โดมแก้วดังขึ้น…", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ผู้พิทักษ์จารึกของใหม่ลงคลังแล้ว คัมภีร์ของนายไม่อัปเดตเองนะ", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "และในหอคอยนี้ คัมภีร์ที่ล้าหลังจะถูกความรู้เก่ากัดกิน — เรียกความรู้ล่าสุดลงมาให้เร็ว", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 1}
		],

		"gameplay": {
			1: {
				"title": "คัมภีร์ล้าหลัง",
				"story": "คลังเวทมีจารึกใหม่ที่คัมภีร์ของนายยังไม่มี — คัมภีร์ที่ล้าหลังจะถูกกัดกินทุกคลื่น",
				"panels": ["terminal", "files", "graph"],
				"remote": light_tome,
				"setup": Level13Dialogue.IDENTITY + [
					{"run": "git clone " + Level13Dialogue.URL},
					# สำเนาของผู้เล่นทำไว้ก่อนผู้พิทักษ์จะจารึกชิ้นที่ 11
					{"run": "git reset --hard HEAD~1"}
				],
				"room": {"hearts": 3, "wave_every": 2, "sync_required": true,
					"items": {
						"README.md": {"kind": "note", "name": "ป้ายคัมภีร์แสงสว่าง"},
						"fragment-10.txt": {"kind": "fragment", "name": "เศษคัมภีร์ชิ้นที่ 10"},
						"fragment-11.txt": {"kind": "fragment", "name": "เศษคัมภีร์ชิ้นที่ 11"}
					}},
				"objectives": [
					{
						"id": "sync",
						"text": "เรียกความรู้ล่าสุดจากคลังเวทลงมาให้คัมภีร์ของนายทันสมัย",
						"short": "ตามคลังให้ทัน",
						"type": "state",
						"check": "in_sync",
						"upstream": "origin/main",
						"world": "ความรู้ไหลจากโดมแก้วลงสู่คัมภีร์ของนาย fragment-11.txt ปรากฏบนโต๊ะ",
						"hint": "คาถาเรียกความรู้คือ pull: git pull (fetch อย่างเดียวแค่ส่องดู ยังไม่รวมเข้ามา)"
					},
					{
						"id": "read",
						"text": "อ่านเศษคัมภีร์ที่เพิ่งมาถึง",
						"short": "อ่านเศษชิ้นที่ 11",
						"type": "read",
						"path": "fragment-11.txt",
						"world": "ได้รับเศษคัมภีร์ชิ้นที่ 11: \"ย่อมดับไปพร้อมผู้ครอบครอง\"",
						"hint": "cat fragment-11.txt"
					}
				],
				"success_text": "ได้รับเศษคัมภีร์ชิ้นที่ 11!"
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "fetch แค่ส่องดูว่าคลังมีอะไรใหม่ (origin/main ขยับ) ส่วน pull ส่องแล้วรวมเข้ามาเลย", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "\"ความรู้ที่ไม่ถูกแบ่งปัน ย่อมดับไปพร้อมผู้ครอบครอง\"… อาจารย์อยากให้ฉันแบ่งปันอะไรกันนะ", "mewla_anim": "idle"}
		]
	}
