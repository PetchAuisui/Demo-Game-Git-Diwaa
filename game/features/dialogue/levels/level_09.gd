class_name Level09Dialogue
extends RefCounted

## ด่านที่ 9: เวทย้อนกาล (git reset) — มินิเกม "หน้ากระดาษต้องสาป"
## การจารึกล่าสุดมีม้วนคำสาปติดเข้าไปพร้อมเศษคัมภีร์ชิ้นที่ 6 → คำสาปในคัมภีร์กัดกินหัวใจทุกคลื่น
## คัมภีร์ฉีกหน้าไม่ได้ แต่ย้อนเวลาได้: เลือกระดับเอง
##   --soft  ของกลับไปอยู่บนแท่น (คำสาปบนแท่นจะระเบิดถ้าคลื่นมาก่อนเอาลง)
##   --mixed ของกลับไปอยู่บนโต๊ะ (ปลอดภัยกว่าในห้องนี้)
##   --hard  ทุกอย่างหายรวมถึงเศษคัมภีร์ชิ้นที่ 6 → แพ้ทันที (essential)

const SAFE := "จารึกเศษคัมภีร์ชิ้นที่ 5"


static func get_data() -> Dictionary:
	return {
		"level_id": 9,
		"title": "ด่านที่ 9: เวทย้อนกาล",
		"time_limit": 110.0,
		"max_score": 180,
		"commands": ["git reset"],
		"clear_keyword": "git reset --soft HEAD~1 ย้อน commit เก็บงานบน stage · --mixed เก็บบนโต๊ะ · --hard ทิ้งทั้งหมด",

		"intro_sequence": [
			{"speaker": "มิวรา", "text": "แย่แล้ว! หน้าล่าสุดของคัมภีร์มีรอยดำลามออกมา — ม้วนคำสาปติดไปกับการจารึกครั้งล่าสุด", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ตราบใดที่มันอยู่ในคัมภีร์ มันจะกัดกินพลังนายทุกคลื่น", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "ฉีกหน้านั้นทิ้งได้ไหม?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ไม่ได้ แต่ย้อนเวลาได้ — แค่ระวังอย่าย้อนแรงจนเศษคัมภีร์ชิ้นที่ 6 หายไปด้วย", "mewla_anim": "success"},
			{"type": "open_gameplay", "step": 1}
		],

		"gameplay": {
			1: {
				"title": "หน้ากระดาษต้องสาป",
				"story": "การจารึกล่าสุดมีคำสาปติดมา — ย้อนกาลเอามันออกจากคัมภีร์ แล้วจารึกเฉพาะเศษคัมภีร์ชิ้นที่ 6",
				"panels": ["terminal", "files", "graph"],
				"setup": [
					{"run": "git config --global user.name \"Vel\""},
					{"run": "git config --global user.email \"vel@magic-tower.local\""},
					{"run": "git init"},
					{"write": "fragment-4.txt", "content": "จงสังเกตทุกรอยที่เปลี่ยนไป\n"},
					{"run": "git add ."},
					{"run": "git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 4\""},
					{"write": "fragment-5.txt", "content": "ความผิดพลาดแก้ไขได้เสมอ\n"},
					{"run": "git add ."},
					{"run": "git commit -m \"%s\"" % SAFE},
					{"write": "fragment-6.txt", "content": "หากเจ้ากล้าย้อนกลับไปมอง\n"},
					{"write": "curse.txt", "content": "☠ ผู้ใดจารึกม้วนนี้ คัมภีร์จะเป็นของโกลาหล ☠\n"},
					{"run": "git add ."},
					{"run": "git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 6\""}
				],
				"room": {
					"hearts": 3, "wave_every": 3, "respawn": true, "essential": ["fragment-6.txt"],
					"items": {
						"fragment-4.txt": {"kind": "fragment", "name": "เศษคัมภีร์ชิ้นที่ 4"},
						"fragment-5.txt": {"kind": "fragment", "name": "เศษคัมภีร์ชิ้นที่ 5"},
						"fragment-6.txt": {"kind": "fragment", "name": "เศษคัมภีร์ชิ้นที่ 6"},
						"curse.txt": {"kind": "curse", "name": "ม้วนคำสาป"}
					}
				},
				"objectives": [
					{
						"id": "rewind",
						"text": "ย้อนกาลจนคำสาปหลุดออกจากคัมภีร์ โดยเศษคัมภีร์ชิ้นที่ 6 ยังอยู่",
						"short": "ย้อนกาลไล่คำสาป",
						"type": "state",
						"check": "not_committed",
						"paths": ["curse.txt", "fragment-6.txt"],
						"world": "นาฬิกาทรายยักษ์หมุนกลับ หน้ากระดาษที่ดำมืดม้วนตัวหายไป",
						"hint": "HEAD~1 คือหนึ่งการจารึกก่อนหน้า — git reset --soft HEAD~1 (ของอยู่บนแท่น) หรือ --mixed (ของอยู่บนโต๊ะ) อย่าใช้ --hard!",
						"near_miss": [
							{"pattern": "--hard", "message": "--hard ลบทุกอย่างในการจารึกนั้น รวมถึงเศษคัมภีร์ชิ้นที่ 6!"}
						]
					},
					{
						"id": "reinscribe",
						"text": "จารึกเศษคัมภีร์ชิ้นที่ 6 อีกครั้ง — ให้ม้วนคำสาปอยู่นอกคัมภีร์",
						"short": "จารึกเฉพาะชิ้นที่ 6",
						"type": "state",
						"check": "committed",
						"paths": ["fragment-6.txt"],
						"exclude": ["curse.txt"],
						"count": 3,
						"world": "ได้รับเศษคัมภีร์ชิ้นที่ 6: \"หากเจ้ากล้าย้อนกลับไปมอง\"",
						"hint": "ดูว่าม้วนคำสาปอยู่บนแท่นหรือบนโต๊ะ ถ้าบนแท่นให้ git restore --staged curse.txt ก่อน แล้วจารึก"
					}
				],
				"success_text": "คัมภีร์สะอาดแล้ว!"
			}
		},

		"outro_sequence": [
			{"speaker": "มิวรา", "text": "soft เก็บไว้บนแท่น mixed เก็บไว้บนโต๊ะ hard ลบทิ้งหมด — ย้อนกาลแล้วเลือกจารึกใหม่ได้ถูกต้อง", "mewla_anim": "success"},
			{"speaker": "เวล", "text": "\"หากเจ้ากล้าย้อนกลับไปมอง\" … อาจารย์อยากให้ฉันมองย้อนไปที่อะไรกันนะ", "mewla_anim": "idle"}
		]
	}
