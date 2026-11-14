class_name Level01Dialogue
extends RefCounted

## ข้อมูลบทสนทนาด่านที่ 1: ตรวจสอบพลังและประกาศนาม (git --version + git config)
## เก็บเฉพาะโครงสร้างข้อมูลบทพูด ช้อยส์ และลำดับการตอบคำถาม
## สอดคล้องกับข้อกำหนดใน docs/inside-tower-cutscene.md

static func get_data() -> Dictionary:
	return {
		"level_id": 1,
		"title": "ด่านที่ 1: ตรวจสอบพลังและประกาศนาม",
		"commands": ["git --version", "git config"],
		"clear_keyword": "การตรวจสอบพลัง หมายถึง git --version",

		# ======================================================================
		# 1. ขั้นสอน - ส่วนที่ 1: ตรวจสอบพลังเวท (git --version)
		# ======================================================================
		"intro_sequence": [
			{"speaker": "มิวรา", "text": "ร่ายคาถานี้ดู", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "`git --version`", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "แค่นี้เอง?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ถ้าพลัง Git ถูกปลุกไว้แล้ว คาถานี้จะแสดงระดับพลังตอบกลับมาเอง ใช้สำหรับเช็กว่าพลัง Git พร้อมไหม", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "เข้าใจแล้ว", "mewla_anim": "idle"},
			{"type": "choice_menu", "menu": "part1_main"}
		],
		
		# กล่องคำถามหลักส่วนที่ 1
		"part1_main_choices": {
			"prompt": "เลือกข้อมูลที่ต้องการตรวจสอบก่อนเริ่มภารกิจ:",
			"options": [
				{"text": "พลัง Git คืออะไร?", "id": "part1_git"},
				{"text": "มีอะไรต้องระวังเป็นพิเศษไหมตอนร่ายคาถา?", "id": "part1_warning"},
				{"text": "ฉันมาทำอะไรที่นี่?", "id": "part1_purpose"},
				{"text": "ฉันจะลองดู", "id": "part1_try"}
			]
		},
		
		# ช้อยส์ 1: พลัง Git คืออะไร?
		"part1_git_seq": [
			{"speaker": "เวล", "text": "พลัง Git คืออะไรกันแน่?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "Git คือพลังที่ใช้บันทึกการเปลี่ยนแปลงของคัมภีร์เวทส่วนตัว", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ทุกครั้งที่นายแก้ไขหรือจารึกอะไรลงไป Git จะจดจำร่องรอยเหล่านั้นเอาไว้", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ต่อให้เวลาผ่านไป นายก็ยังย้อนกลับไปดูอดีตของคัมภีร์เวทส่วนตัวได้", "mewla_anim": "talk"},
			{"type": "choice_menu", "menu": "part1_main"}
		],
		
		# ช้อยส์ 2: มีอะไรต้องระวังเป็นพิเศษไหมตอนร่ายคาถา?
		"part1_warning_seq": [
			{"speaker": "เวล", "text": "มีอะไรต้องระวังเป็นพิเศษไหม?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "มี", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "หืม?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "อักขระหน้าคำว่า version ต้องเป็นขีดคู่", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ใช้เป็น `version` แบบนี้ได้แต่ถ้าเป็น `--version` ไม่ใช่ `-version` และ `git --version` ต้องเว้นวรรคระหว่าง `git` กับ `--version` ด้วย", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ศิษย์ฝึกหัดหลายคนพลาดตรงนี้", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "อักขระเวทละเอียดกว่าที่คิด", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ผิดเพียงตัวเดียว คาถาอาจไม่ตอบสนอง", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "เข้าใจแล้ว", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ดี…ก่อนร่ายคาถา ตรวจสอบอักขระให้ครบทุกครั้ง", "mewla_anim": "talk"},
			{"type": "choice_menu", "menu": "part1_main"}
		],
		
		# ช้อยส์ 3: ฉันมาทำอะไรที่นี่?
		"part1_purpose_seq": [
			{"speaker": "เวล", "text": "ฉันมาทำอะไรที่นี่กันแน่?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ฉันจะไปรู้เหรอ", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "...", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "นายเดินเข้ามาเองนะ", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ถ้างั้นฉันถามกลับ", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "นายมาที่นี่เพื่อตามหาใครหรือสิ่งใดหรือเปล่า?", "mewla_anim": "talk"},
			{"type": "choice_menu", "menu": "part1_purpose_sub"}
		],
		
		# ช้อยส์ย่อย: ใช่ / ไม่
		"part1_purpose_sub_choices": {
			"prompt": "นายมาที่นี่เพื่อตามหาใครหรือสิ่งใดหรือเปล่า?",
			"options": [
				{"text": "ใช่", "id": "purpose_yes"},
				{"text": "ไม่", "id": "purpose_no"}
			]
		},
		
		"purpose_yes_seq": [
			{"speaker": "มิวรา", "text": "ดี", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "งั้นฉันจะสอนนายให้ไปหาสิ่ง ๆ นั้นเอง", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "เริ่มจากคาถาบทแรกกัน", "mewla_anim": "success"},
			{"type": "choice_menu", "menu": "part1_main"}
		],
		
		"purpose_no_seq": [
			{"speaker": "มิวรา", "text": "อ้าว…งั้นนายเข้าผิดหอคอยแล้ว", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ทางออกอยู่ด้านหลัง ขอให้โชคดี", "mewla_anim": "talk"},
			{"type": "bad_ending"}
		],
		
		# ช้อยส์ 4: ฉันจะลองดู (เข้าสู่เกมเพลย์จำลองขั้นที่ 1 ทันที)
		"part1_try_seq": [
			{"type": "open_gameplay", "step": 1}
		],
		
		# ======================================================================
		# 2. ขั้นสอน - ส่วนที่ 2: ประกาศตัวตนจารึกคัมภีร์ (git config)
		# ======================================================================
		"part2_intro_sequence": [
			{"speaker": "มิวรา", "text": "ดีมาก นายผ่านบททดสอบแรกแล้ว", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "ง่ายกว่าที่คิดนะ", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "เพราะนี่เป็นแค่จุดเริ่มต้น... ต่อไป นายต้องลงทะเบียนตัวตนของนักเวทกับสำนักเวทเสียก่อน", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "ทำไมต้องลงทะเบียนด้วย?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "เพราะต่อจากนี้นายจะได้เริ่มรวบรวมและจารึก 'เศษคัมภีร์' ลงในคัมภีร์เวทส่วนตัวของนาย", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "เศษคัมภีร์?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "เศษคัมภีร์คือชิ้นส่วนขององค์ความรู้ที่เคยอยู่ในคัมภีร์เวทต้นกำเนิด หลังจากคัมภีร์เวทต้นกำเนิดแตกสลาย เศษคัมภีร์เหล่านั้นก็กระจัดกระจายไปทั่วหอคอย", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "บางชิ้นอาจบันทึกความรู้พื้นฐาน บางชิ้นอาจบันทึกคาถาหรืออักขระสำคัญ และบางชิ้นอาจเป็นกุญแจสำคัญที่นำไปสู่ความจริงเกี่ยวกับการหายตัวไปของปรมาจารย์", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "แต่ทุกครั้งที่นายจารึกการเปลี่ยนแปลงลงในคัมภีร์เวทส่วนตัว สำนักเวทต้องรู้ก่อนว่าเจ้าของการจารึกคือใคร ไม่อย่างนั้นต่อให้จารึกเศษคัมภีร์ดีแค่ไหน ก็ไม่มีใครรู้ว่าใครเป็นคนจารึก", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "งั้นฉันต้องทำยังไง", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ประกาศตัวตนของนายให้สำนักเวทรู้ซะ... มาเริ่มคาถาบทต่อไปกัน", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ร่ายคาถานี้เพื่อประกาศนามของนาย:\n`git config --global user.name \"Vel\"`", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "แล้วตามด้วยการผูกตราประทับวิญญาณ:\n`git config --global user.email \"vel@magic-tower.local\"`", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "คาถาสองบท?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ใช่ บทแรกใช้ตั้งชื่อ บทที่สองใช้ผูกอีเมล", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "แต่ถ้านายอยากตรวจสอบว่าหอคอยจดจำชื่อนายไว้หรือยัง ให้ลองร่ายคาถาเดิมแต่ ไม่ต้องใส่ชื่อต่อท้าย ดูสิ (`git config --global user.name`)", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "แล้วถ้ายังไม่เคยลงทะเบียนล่ะ", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "คาถาจะไม่ตอบกลับอะไรเลย... นั่นหมายความว่านายต้องรีบประกาศนามเดี๋ยวนี้!", "mewla_anim": "talk"},
			{"type": "choice_menu", "menu": "part2_main"}
		],
		
		# กล่องคำถามหลักส่วนที่ 2
		"part2_main_choices": {
			"prompt": "เลือกข้อมูลที่ต้องการตรวจสอบก่อนเริ่มภารกิจ:",
			"options": [
				{"text": "ทำไมต้องมีชื่อกับอีเมล?", "id": "part2_name_email"},
				{"text": "มีอะไรต้องระวังตอนร่ายคาถา?", "id": "part2_warning"},
				{"text": "ฉันจะลองดู", "id": "part2_try"}
			]
		},
		
		"part2_name_email_seq": [
			{"speaker": "เวล", "text": "ทำไมต้องมีทั้งชื่อและอีเมลด้วย?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "เพราะทุกการจารึกต้องระบุว่าเป็นผลงานของนักเวทคนไหน", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ชื่อใช้แสดงตัวตน", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ส่วนอีเมลใช้เชื่อมข้อมูลการจารึกเข้ากับตัวตนของนาย", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "เมื่อย้อนดูประวัติของคัมภีร์เวทส่วนตัว นายจะรู้ได้ว่าใครเป็นคนจารึกสิ่งนั้น", "mewla_anim": "talk"},
			{"type": "choice_menu", "menu": "part2_main"}
		],
		
		"part2_warning_seq": [
			{"speaker": "เวล", "text": "มีอะไรต้องระวังไหม?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "มี", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "อักขระ `--global` ต้องเป็นขีดคู่", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "และต้องเว้นวรรคระหว่าง `git`, `config`, `--global` และคำสั่งที่ตามมา", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ถ้าอักขระผิด คาถาอาจไม่ทำงานตามที่ตั้งใจ", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "เข้าใจแล้ว", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "ดี…นักเวทที่ร่ายคาถาแม่น มักเริ่มจากการพิมพ์ให้แม่นก่อน", "mewla_anim": "talk"},
			{"type": "choice_menu", "menu": "part2_main"}
		],
		
		# ช้อยส์ 3: ฉันจะลองดู (เข้าสู่เกมเพลย์จำลองขั้นที่ 2 ทันที)
		"part2_try_seq": [
			{"type": "open_gameplay", "step": 2}
		],
		
		# ======================================================================
		# 3. สรุปผลหลังผ่านด่านที่ 1
		# ======================================================================
		"outro_sequence": [
			{"speaker": "มิวรา", "text": "ลองเช็กดูหน่อยไหมว่าประกาศนามสำเร็จรึเปล่า ใช้คาถาเดิมเลย แต่ไม่ต้องใส่ชื่อต่อท้ายนะ", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ถ้ามีชื่อแสดงขึ้นมา แปลว่าตัวตนของนายถูกลงทะเบียนไว้แล้ว!", "mewla_anim": "success"},
			{"speaker": "มิวรา", "text": "ดีมาก ตอนนี้หอคอยรู้แล้วว่านายเป็นใคร", "mewla_anim": "talk"},
			{"speaker": "เวล", "text": "แปลว่าพร้อมสำหรับการจารึกแล้ว?", "emote": "question", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "เกือบ... ตัวตนของนักเวทน่ะพร้อมแล้ว", "mewla_anim": "talk"},
			{"speaker": "มิวรา", "text": "ต่อไป เราจะไปสร้าง 'คัมภีร์เวทส่วนตัว' เล่มแรกของนายกัน... ไปชั้นถัดไปกันเถอะ", "mewla_anim": "success"},
			{"speaker": "เวล", "text": "...ทำไมหอคอยถึงไม่มีลิฟต์บ้างเนอะ เหนื่อย", "mewla_anim": "idle"},
			{"speaker": "มิวรา", "text": "…นั้นสิ", "mewla_anim": "talk"}
		]
	}
