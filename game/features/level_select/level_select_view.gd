class_name LevelSelectView
extends Control

## หน้าต่างแผนที่ไต่หอคอยเวทมนตร์ (Tower Ascension Roadmap - 40 Levels)
## รวมสไตล์ Dark Gothic Fantasy และโครงสร้าง Acts 1-3 ตาม Prototype
## Act 1: บันไดวนไต่หอคอย (01-15) - แท่นหินลอยได้สไตล์ Doodle Jump
## Act 2: โถงประจำชั้นทีม (16-20) - Collab Chamber Floor Mat เป็น Loop GitHub Flow
## Act 3: ยอดหอคอยแก้ปัญหา (21-40) - Discrete Engineering Deck 5 คอลัมน์ พร้อมเงาปรมาจารย์ Git

const TOWER_STAGES: Array[Dictionary] = [
			# ACT 1: Winding Tower Ascent (01-15) - ไต่หอคอยแบบเป็นธรรมชาติ มีซ้าย-กลาง-ขวา แต่ไม่ตรงบล็อกซ้ำกัน (Organic Meandering Path)
	{ "id": 1, "act": 1, "no": "01", "title": "git --version + git config", "cmd": "git --version", "desc": "ตั้งค่านามผู้ใช้งาน user.name และ user.email", "x": 900.0, "y": 3560.0, "width": 260.0, "has_scripture": true },
	{ "id": 2, "act": 1, "no": "02", "title": "git init", "cmd": "git init", "desc": "ร่ายอาคมสร้าง Repository ว่างเปล่าเพื่อเริ่มต้นคลังตำรา", "x": 720.0, "y": 3410.0, "width": 220.0, "has_scripture": false },
	{ "id": 3, "act": 1, "no": "03", "title": "git status", "cmd": "git status", "desc": "สำรวจสถานะม้วนคาถาทั้งหมดในพื้นที่ทำงานว่ามีสิ่งใดเปลี่ยนแปลง", "x": 640.0, "y": 3250.0, "width": 220.0, "has_scripture": false },
	{ "id": 4, "act": 1, "no": "04", "title": "git add", "cmd": "git add .", "desc": "จัดเตรียมม้วนคาถาเข้าสู่ Staging Area ก่อนประทับตรา", "x": 820.0, "y": 3100.0, "width": 220.0, "has_scripture": false },
	{ "id": 5, "act": 1, "no": "05", "title": "git commit", "cmd": "git commit -m", "desc": "ประทับตราขี้ผึ้งบันทึกประวัติศาสตร์ลง Git Graph ถาวร", "x": 980.0, "y": 2940.0, "width": 240.0, "has_scripture": true },
	{ "id": 6, "act": 1, "no": "06", "title": "git log", "cmd": "git log", "desc": "กางผืนแผนที่สำรวจประวัติศาสตร์การบันทึกย้อนหลังในอดีต", "x": 1180.0, "y": 2790.0, "width": 220.0, "has_scripture": false },
	{ "id": 7, "act": 1, "no": "07", "title": "git diff", "cmd": "git diff", "desc": "ส่องดูความแตกต่างของอักขระคาถาเทียบกับบันทึกเดิม", "x": 1260.0, "y": 2630.0, "width": 220.0, "has_scripture": false },
	{ "id": 8, "act": 1, "no": "08", "title": "git restore", "cmd": "git restore <file>", "desc": "ยกเลิกการแก้ไขไฟล์ใน Working Directory กลับสู่สภาพเดิม", "x": 1080.0, "y": 2480.0, "width": 220.0, "has_scripture": false },
	{ "id": 9, "act": 1, "no": "09", "title": "git reset", "cmd": "git reset HEAD~1", "desc": "ถอยจุดตรวจเช็กพอยต์กลับสู่สถานะก่อนหน้า", "x": 920.0, "y": 2320.0, "width": 220.0, "has_scripture": false },
	{ "id": 10, "act": 1, "no": "10", "title": "git branch", "cmd": "git branch <name>", "desc": "เปิดมิติกิ่งก้านใหม่เพื่อพัฒนาคาถาโดยไม่กระทบเส้นหลัก", "x": 700.0, "y": 2170.0, "width": 240.0, "has_scripture": true },
	{ "id": 11, "act": 1, "no": "11", "title": "git switch", "cmd": "git switch <branch>", "desc": "ย้ายจิตวิญญาณสลับไปมาระหว่างกิ่งก้านคาถาอย่างปลอดภัย", "x": 650.0, "y": 2010.0, "width": 220.0, "has_scripture": false },
	{ "id": 12, "act": 1, "no": "12", "title": "git merge", "cmd": "git merge <branch>", "desc": "หลอมรวมพลังคาถาจากกิ่งก้านเข้าสู่สายหลัก", "x": 850.0, "y": 1860.0, "width": 220.0, "has_scripture": false },
	{ "id": 13, "act": 1, "no": "13", "title": "git clone + git remote", "cmd": "git clone", "desc": "คัดลอกคลังตำราจากมิติต้นทางและเชื่อมต่อสายสัมพันธ์", "x": 1060.0, "y": 1710.0, "width": 220.0, "has_scripture": false },
	{ "id": 14, "act": 1, "no": "14", "title": "git pull", "cmd": "git pull origin main", "desc": "ดึงการอัปเดตบทคาถาใหม่ล่าสุดจากหอคอยส่วนกลาง", "x": 1220.0, "y": 1560.0, "width": 220.0, "has_scripture": false },
	{ "id": 15, "act": 1, "no": "15", "title": "git push (สู่โถงทีม)", "cmd": "git push origin main", "desc": "ส่งบันทึกคาถาขึ้นสู่หอคอยส่วนกลางให้ทุกคนร่วมใช้ (สู่โถงทีม)", "x": 960.0, "y": 1380.0, "width": 320.0, "has_scripture": true },

# ACT 2: Collab Chamber Loop (16-20) - โถงประจำชั้นทีม GitHub Flow
	{ "id": 16, "act": 2, "no": "16", "title": "GitHub Flow (พบผู้พิทักษ์)", "cmd": "branch ➔ pr ➔ merge", "desc": "เรียนรู้วงจรการทำงานร่วมกันแบบสากลตั้งแต่แยกกิ่งจนถึงรวมงาน", "x": 960.0, "y": 660.0, "width": 240.0, "has_scripture": true },
	{ "id": 17, "act": 2, "no": "17", "title": "Pull Request", "cmd": "Create PR", "desc": "ยื่นคำร้องขอรวมคาถาให้เพื่อนร่วมทีมช่วยตรวจทานความถูกต้อง", "x": 1220.0, "y": 780.0, "width": 220.0, "has_scripture": false },
	{ "id": 18, "act": 2, "no": "18", "title": "Merge PR", "cmd": "Confirm Merge", "desc": "อนุมัติคำร้องและหลอมรวมโค้ดเข้าสู่สายหลักอย่างสมบูรณ์", "x": 1120.0, "y": 980.0, "width": 220.0, "has_scripture": false },
	{ "id": 19, "act": 2, "no": "19", "title": "Update PR & git fetch", "cmd": "git fetch", "desc": "อัปเดตข้อมูลมิติต้นทางโดยไม่รบกวนไฟล์งานที่กำลังพิมพ์", "x": 800.0, "y": 980.0, "width": 220.0, "has_scripture": false },
	{ "id": 20, "act": 2, "no": "20", "title": "Merge PR (Final Boss)", "cmd": "Squash & Merge", "desc": "รวมคอมมิตย่อยให้กลายเป็นบันทึกเดียวที่สะอาดเรียบร้อยก่อนขึ้นยอดหอคอย", "x": 700.0, "y": 780.0, "width": 240.0, "has_scripture": true },

	# ACT 3: Top Tower Deck (21-40) - Discrete Engineering Deck 5 คอลัมน์
	{ "id": 21, "act": 3, "no": "21", "title": "ตรวจสถานะก่อนเริ่มงาน", "cmd": "git status", "desc": "ตรวจสถานะ working tree ให้เรียบร้อยก่อนเริ่มแก้ปัญหา", "x": 480.0, "y": 420.0, "width": 130.0, "has_scripture": false },
	{ "id": 22, "act": 3, "no": "22", "title": "ตรวจสอบความแตกต่าง", "cmd": "git diff", "desc": "ส่องดูจุดเพี้ยนของโค้ดก่อนเริ่มแก้ไข", "x": 720.0, "y": 420.0, "width": 130.0, "has_scripture": false },
	{ "id": 23, "act": 3, "no": "23", "title": "คืนไฟล์ที่แก้ผิด", "cmd": "git restore", "desc": "กู้คืนไฟล์โค้ดที่พังกลับสู่สภาพเดิม", "x": 960.0, "y": 420.0, "width": 130.0, "has_scripture": false },
	{ "id": 24, "act": 3, "no": "24", "title": "นำไฟล์ลับออกจาก Stage", "cmd": "git restore --staged", "desc": "ปลดไฟล์ความลับออกจากสถานะเตรียมคอมมิต", "x": 1200.0, "y": 420.0, "width": 130.0, "has_scripture": false },
	{ "id": 25, "act": 3, "no": "25", "title": "แก้ไข Commit ล่าสุด", "cmd": "git commit --amend", "desc": "ซ่อมแซมคอมมิตล่าสุดโดยไม่สร้างขยะในประวัติ", "x": 1440.0, "y": 420.0, "width": 130.0, "has_scripture": true },
	{ "id": 26, "act": 3, "no": "26", "title": "ย้อน Commit เก็บงานไว้", "cmd": "git reset --soft", "desc": "ถอยประวัติแต่คงงานไว้ใน Staging Area", "x": 480.0, "y": 330.0, "width": 130.0, "has_scripture": false },
	{ "id": 27, "act": 3, "no": "27", "title": "ลบ Commit ทิ้งถาวร", "cmd": "git reset --hard", "desc": "ล้างโค้ดเสียทิ้งไปอย่างเด็ดขาด", "x": 720.0, "y": 330.0, "width": 130.0, "has_scripture": false },
	{ "id": 28, "act": 3, "no": "28", "title": "ย้ายงานออกจาก main", "cmd": "git switch -c", "desc": "ย้ายงานไปกิ่งฟีเจอร์ใหม่เพื่อปกป้องกิ่งหลัก", "x": 960.0, "y": 330.0, "width": 130.0, "has_scripture": false },
	{ "id": 29, "act": 3, "no": "29", "title": "ค้นหา Commit ที่เกี่ยวข้อง", "cmd": "git log --grep", "desc": "สืบค้นหาบันทึกในอดีตตามคีย์เวิร์ดของปัญหา", "x": 1200.0, "y": 330.0, "width": 130.0, "has_scripture": false },
	{ "id": 30, "act": 3, "no": "30", "title": "วิเคราะห์ Commit Graph", "cmd": "git log --graph", "desc": "กางแผนผังสายฟ้าดูความเชื่อมโยงของทุกกิ่ง", "x": 1440.0, "y": 330.0, "width": 130.0, "has_scripture": true },
	{ "id": 31, "act": 3, "no": "31", "title": "ย้าย Commit ผิด Branch", "cmd": "git branch + reset", "desc": "ซ่อมแซมเส้นเวลา ย้ายคอมมิตไปกิ่งที่ถูกต้อง", "x": 480.0, "y": 240.0, "width": 130.0, "has_scripture": false },
	{ "id": 32, "act": 3, "no": "32", "title": "รวม Feature Branch", "cmd": "git merge feature", "desc": "หลอมรวมฟีเจอร์เข้าสู่สายหลักอย่างเป็นระบบ", "x": 720.0, "y": 240.0, "width": 130.0, "has_scripture": false },
	{ "id": 33, "act": 3, "no": "33", "title": "แก้ Merge Conflict", "cmd": "solve conflict", "desc": "เผชิญหน้าอสูร Conflict ตัดสินใจเลือกโค้ดที่ถูกต้อง", "x": 960.0, "y": 240.0, "width": 130.0, "has_scripture": false },
	{ "id": 34, "act": 3, "no": "34", "title": "Clone โปรเจกต์ของทีม", "cmd": "git clone", "desc": "ดาวน์โหลดคลังตำราทีมและตรวจสอบ Remote", "x": 1200.0, "y": 240.0, "width": 130.0, "has_scripture": false },
	{ "id": 35, "act": 3, "no": "35", "title": "แก้ URL ของ Remote", "cmd": "git remote set-url", "desc": "แก้ปัญหาต่อไม่ติดด้วยการเปลี่ยน URL เซิร์ฟเวอร์", "x": 1440.0, "y": 240.0, "width": 130.0, "has_scripture": true },
	{ "id": 36, "act": 3, "no": "36", "title": "กู้คืน Remote origin", "cmd": "git remote add", "desc": "สร้างสายสัมพันธ์ใหม่หลังเผลอลบการเชื่อมต่อ", "x": 480.0, "y": 150.0, "width": 130.0, "has_scripture": false },
	{ "id": 37, "act": 3, "no": "37", "title": "รับอัปเดตจาก Remote", "cmd": "git pull --rebase", "desc": "ดึงงานเพื่อนร่วมทีมมาผสานโดยประวัติเป็นเส้นตรง", "x": 720.0, "y": 150.0, "width": 130.0, "has_scripture": false },
	{ "id": 38, "act": 3, "no": "38", "title": "ส่ง Feature ครั้งแรก", "cmd": "git push -u", "desc": "ตั้งค่า upstream tracking และส่งกิ่งงานขึ้นเซิร์ฟเวอร์", "x": 960.0, "y": 150.0, "width": 130.0, "has_scripture": false },
	{ "id": 39, "act": 3, "no": "39", "title": "แก้ไขตาม Code Review", "cmd": "amend & push", "desc": "ปรับปรุงตามคำแนะนำของรุ่นพี่และส่งอัปเดต", "x": 1200.0, "y": 150.0, "width": 130.0, "has_scripture": false },
	{ "id": 40, "act": 3, "no": "40", "title": "กู้คืนคัมภีร์และปรมาจารย์ Git (FINAL)", "cmd": "release ➔ final", "desc": "ภารกิจสูงสุด: ผสานคัมภีร์โบราณ ปลดปล่อยปรมาจารย์ Git ผู้สาบสูญสู่ยอดหอคอย", "x": 1440.0, "y": 150.0, "width": 150.0, "has_scripture": true },
]

# UI Nodes
var scroll_chamber: ScrollContainer
var tower_content: Control
var path_renderer: Control
var vel_hero: Control
var vel_sprite: TextureRect
var vel_anim: AnimatedSprite2D
var black_cat: Control
var cat_sprite: TextureRect
var sfx_click: AudioStreamPlayer
var sfx_jump: AudioStreamPlayer
var sfx_meow: AudioStreamPlayer

# Navbar Nodes
var btn_back: Button
var btn_act1: Button
var btn_act2: Button
var btn_act3: Button
var btn_focus_current: Button
var btn_sound: Button

# Bottom HUD Nodes
var hud_no_badge: Label
var hud_title: Label
var hud_act_tag: Label
var hud_cmd: Label
var hud_desc: Label
var btn_launch: Button

# Assets & Textures
var tex_pedestal: Texture2D
var tex_lock: Texture2D
var tex_vel_idle: Texture2D
var tex_vel_jump: Texture2D
var tex_cat: Texture2D
var tex_guardian: Texture2D
var tex_khampri: Texture2D
var tex_magic_circle: Texture2D

# Fonts
var font_bungee: Font
var font_chakra_bold: Font
var font_chakra_reg: Font
var font_ta_pixel: Font

# State variables
var _current_stage_idx: int = 0
var _platform_nodes: Dictionary = {}
var _is_jumping := false
var _target_queue_idx: int = -1
var _jump_tween: Tween = null
var _is_muted := false
var _idle_bob_timer := 0.0
var _torch_flames: Array[ColorRect] = []
var _torch_timer := 0.0


func _ready() -> void:
	_load_resources()
	_bind_nodes()
	_wire_navbar()
	_init_game_progression()
	_spawn_tower_platforms()
	_setup_character_and_cat()

	# เลื่อนมุมมองกล้องไปยังตำแหน่งด่านเริ่มต้นของผู้เล่นทันที
	get_tree().create_timer(0.05).timeout.connect(func():
		_jump_to_stage(_current_stage_idx, false)
	)


func _load_resources() -> void:
	if ResourceLoader.exists("res://assets/fonts/Bungee-Regular.ttf"):
		font_bungee = load("res://assets/fonts/Bungee-Regular.ttf")

	if ResourceLoader.exists("res://assets/fonts/ChakraPetch-Bold.ttf"):
		var base_bold: Font = load("res://assets/fonts/ChakraPetch-Bold.ttf")
		var fv := FontVariation.new()
		fv.base_font = base_bold
		fv.spacing_top = 4
		fv.spacing_bottom = 2
		font_chakra_bold = fv

	if ResourceLoader.exists("res://assets/fonts/ChakraPetch-Regular.ttf"):
		var base_reg: Font = load("res://assets/fonts/ChakraPetch-Regular.ttf")
		var fv := FontVariation.new()
		fv.base_font = base_reg
		fv.spacing_top = 4
		fv.spacing_bottom = 2
		font_chakra_reg = fv

	if ResourceLoader.exists("res://assets/fonts/TA-8-bit.ttf"):
		font_ta_pixel = load("res://assets/fonts/TA-8-bit.ttf")

	if ResourceLoader.exists("res://assets/art/dressing_room/pedestal.png"):
		tex_pedestal = load("res://assets/art/dressing_room/pedestal.png")

	if ResourceLoader.exists("res://assets/art/dressing_room/icon_lock.png"):
		tex_lock = load("res://assets/art/dressing_room/icon_lock.png")

	if ResourceLoader.exists("res://assets/cutscene/characters/vel/vel_Hblue_Sredyellow_idle.png"):
		tex_vel_idle = load("res://assets/cutscene/characters/vel/vel_Hblue_Sredyellow_idle.png")

	if ResourceLoader.exists("res://assets/cutscene/characters/vel/vel_shockpng.png"):
		tex_vel_jump = load("res://assets/cutscene/characters/vel/vel_shockpng.png")

	if ResourceLoader.exists("res://assets/art/dressing_room/cat_companion_black.png"):
		tex_cat = load("res://assets/art/dressing_room/cat_companion_black.png")

	if ResourceLoader.exists("res://assets/cutscene/characters/guardian/guardian-idle.png"):
		tex_guardian = load("res://assets/cutscene/characters/guardian/guardian-idle.png")

	if ResourceLoader.exists("res://assets/cutscene/props/khampri/Khampri.png"):
		tex_khampri = load("res://assets/cutscene/props/khampri/Khampri.png")

	if ResourceLoader.exists("res://assets/art/dressing_room/magic_reticle.png"):
		tex_magic_circle = load("res://assets/art/dressing_room/magic_reticle.png")


func _bind_nodes() -> void:
	scroll_chamber = get_node_or_null("%ScrollChamber")
	tower_content = get_node_or_null("%TowerContent")
	path_renderer = get_node_or_null("%PathRenderer")
	vel_hero = get_node_or_null("%VelHero")
	vel_sprite = get_node_or_null("%VelSprite")
	black_cat = get_node_or_null("%BlackCat")
	cat_sprite = get_node_or_null("%CatSprite")

	sfx_click = get_node_or_null("%SfxClick")
	sfx_jump = get_node_or_null("%SfxJump")
	sfx_meow = get_node_or_null("%SfxMeow")

	btn_back = get_node_or_null("%BtnBack")
	btn_act1 = get_node_or_null("%BtnAct1")
	btn_act2 = get_node_or_null("%BtnAct2")
	btn_act3 = get_node_or_null("%BtnAct3")
	btn_focus_current = get_node_or_null("%BtnFocusCurrent")
	btn_sound = get_node_or_null("%BtnSound")

	hud_no_badge = get_node_or_null("%HudLevelBadge")
	if not hud_no_badge:
		hud_no_badge = get_node_or_null("%HudNoBadge")
	hud_title = get_node_or_null("%HudTitle")
	hud_act_tag = get_node_or_null("%HudActTag")
	hud_cmd = get_node_or_null("%HudCmd")
	hud_desc = get_node_or_null("%HudDesc")
	btn_launch = get_node_or_null("%BtnLaunch")

	if path_renderer:
		path_renderer.draw.connect(_on_draw_path)





func _process(delta: float) -> void:
	# เอฟเฟกต์ไฟคบเพลิงกะพริบ
	pass




func _wire_navbar() -> void:
	if btn_back:
		btn_back.pressed.connect(_on_back_pressed)
	if btn_act1:
		btn_act1.pressed.connect(func(): _scroll_to_y(3200, true); _highlight_act(1))
	if btn_act2:
		btn_act2.pressed.connect(func(): _scroll_to_y(700, true); _highlight_act(2))
	if btn_act3:
		btn_act3.pressed.connect(func(): _scroll_to_y(50, true); _highlight_act(3))
	if btn_focus_current:
		btn_focus_current.pressed.connect(func(): _jump_to_stage(_current_stage_idx, true))
	if btn_sound:
		btn_sound.pressed.connect(_on_toggle_sound)
	if btn_launch:
		btn_launch.pressed.connect(_on_launch_stage_pressed)


func _on_back_pressed() -> void:
	_play_sfx(sfx_click)
	get_tree().change_scene_to_file("res://features/start/start_view.tscn")


func _on_toggle_sound() -> void:
	_is_muted = not _is_muted
	AudioServer.set_bus_mute(0, _is_muted)
	if btn_sound:
		btn_sound.text = "🔇" if _is_muted else "🔊"
	if not _is_muted:
		_play_sfx(sfx_click)


func _highlight_act(act_num: int) -> void:
	var color_active := Color(0.961, 0.620, 0.043, 1.0)
	var color_dim := Color(0.580, 0.643, 0.722, 1.0)

	if btn_act1:
		btn_act1.add_theme_color_override("font_color", color_active if act_num == 1 else color_dim)
	if btn_act2:
		btn_act2.add_theme_color_override("font_color", color_active if act_num == 2 else color_dim)
	if btn_act3:
		btn_act3.add_theme_color_override("font_color", color_active if act_num == 3 else color_dim)


func _init_game_progression() -> void:
	var total_stars := 0
	var highest_cleared_id := 0

	for stg in TOWER_STAGES:
		var stg_id: int = stg["id"]
		if GameProgressManager.is_level_cleared(stg_id):
			total_stars += 3
			if stg_id > highest_cleared_id:
				highest_cleared_id = stg_id

	# ด่านเริ่มต้นของผู้เล่น: เมื่อกลับมาที่หน้าด่าน เวลจะยืนที่ด่านล่าสุดที่ผ่านแล้ว
	# และปลดล็อกด่านถัดไปรอไว้ ถ้ากดคลิกหรือกดลูกศรเวลจึงจะกระโดดไปด่านถัดไป
	var target_id := highest_cleared_id if highest_cleared_id > 0 else 1
	for i in range(TOWER_STAGES.size()):
		if TOWER_STAGES[i]["id"] == target_id:
			_current_stage_idx = i
			break

	_target_queue_idx = _current_stage_idx
	_update_hud_display(TOWER_STAGES[_current_stage_idx])


func _spawn_tower_platforms() -> void:
	if not tower_content:
		return

	for child in tower_content.get_children():
		if child.name.begins_with("Platform_") or child.name == "MasterSilhouette" or child.name == "CollabMagicCircle":
			child.queue_free()

	# 1. วงแหวนเวทมนตร์โถง Act 2 (GitHub Flow Collab Chamber)
	if tex_magic_circle:
		var circle_rect := TextureRect.new()
		circle_rect.name = "CollabMagicCircle"
		circle_rect.texture = tex_magic_circle
		circle_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		circle_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		circle_rect.custom_minimum_size = Vector2(440.0, 440.0)
		circle_rect.size = Vector2(440.0, 440.0)
		circle_rect.position = Vector2(960.0 - 220.0, 820.0 - 220.0)
		circle_rect.modulate = Color(0.20, 0.55, 0.40, 0.35)
		circle_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tower_content.add_child(circle_rect)

	# 2. สร้างแท่นศิลาบันไดวนแบบกว้างตามการจัดวางดั้งเดิม (Wide Gothic Stone Slabs)
	for i in range(TOWER_STAGES.size()):
		var stg := TOWER_STAGES[i]
		var stg_id: int = stg["id"]
		var is_cleared := GameProgressManager.is_level_cleared(stg_id)
		var is_unlocked := (stg_id == 1) or GameProgressManager.is_level_cleared(stg_id - 1)
		var is_current := (i == _current_stage_idx)
		var p_width: float = stg["width"]
		var p_x: float = stg["x"]
		var p_y: float = stg["y"]
		var plat_height: float = 56.0

		var plat := Control.new()
		plat.name = "Platform_%02d" % stg_id
		plat.size = Vector2(p_width, plat_height)
		plat.position = Vector2(p_x - (p_width / 2.0), p_y - (plat_height / 2.0))

		# ปุ่มแท่นหินศิลา (Gothic Stone Slab Button)
		var slab_btn := Button.new()
		slab_btn.name = "SlabBtn"
		slab_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		slab_btn.focus_mode = Control.FOCUS_NONE

		# สไตล์กรอบและพื้นหลังแท่นหิน (ไม่มีเส้นขอบขาว 100%)
		var sb_norm := StyleBoxFlat.new()
		sb_norm.corner_radius_top_left = 4
		sb_norm.corner_radius_top_right = 4
		sb_norm.corner_radius_bottom_left = 4
		sb_norm.corner_radius_bottom_right = 4
		sb_norm.border_width_left = 2
		sb_norm.border_width_top = 2
		sb_norm.border_width_right = 2
		sb_norm.border_width_bottom = 3

		var title_color: Color
		var badge_bg: Color
		var badge_border: Color
		var badge_num_color: Color

		if is_current:
			# ด่านปัจจุบัน: หินสีน้ำตาลอุ่น ขอบทองอำพัน พร้อมแสงออร่าทองนวล
			sb_norm.bg_color = Color(0.18, 0.13, 0.08, 0.96)
			sb_norm.border_color = Color(0.96, 0.62, 0.07, 1.0)
			sb_norm.shadow_color = Color(0.96, 0.62, 0.04, 0.38)
			sb_norm.shadow_size = 6
			title_color = Color(0.98, 0.88, 0.47, 1.0)
			badge_bg = Color(0.28, 0.18, 0.08, 1.0)
			badge_border = Color(0.96, 0.62, 0.07, 1.0)
			badge_num_color = Color(0.98, 0.88, 0.47, 1.0)
		elif is_cleared:
			# ด่านที่ผ่านแล้ว: หินสีน้ำเงินโกธิค ขอบเทาเหล็กกล้า
			sb_norm.bg_color = Color(0.08, 0.12, 0.18, 0.95)
			sb_norm.border_color = Color(0.28, 0.38, 0.52, 1.0)
			sb_norm.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
			sb_norm.shadow_size = 3
			title_color = Color(0.85, 0.90, 0.96, 1.0)
			badge_bg = Color(0.12, 0.18, 0.26, 1.0)
			badge_border = Color(0.32, 0.44, 0.60, 1.0)
			badge_num_color = Color(0.82, 0.88, 0.96, 1.0)
		elif is_unlocked:
			# ด่านที่ปลดล็อกแล้ว: หินสีน้ำตาลทอง
			sb_norm.bg_color = Color(0.13, 0.10, 0.07, 0.95)
			sb_norm.border_color = Color(0.72, 0.48, 0.16, 1.0)
			title_color = Color(0.94, 0.82, 0.50, 1.0)
			badge_bg = Color(0.20, 0.14, 0.08, 1.0)
			badge_border = Color(0.72, 0.48, 0.16, 1.0)
			badge_num_color = Color(0.94, 0.82, 0.50, 1.0)
		else:
			# ด่านที่ล็อก: ศิลามืดมิด ขอบเหล็กมืด
			sb_norm.bg_color = Color(0.06, 0.07, 0.10, 0.92)
			sb_norm.border_color = Color(0.14, 0.17, 0.24, 0.85)
			title_color = Color(0.40, 0.46, 0.56, 0.8)
			badge_bg = Color(0.09, 0.11, 0.15, 1.0)
			badge_border = Color(0.18, 0.22, 0.30, 0.8)
			badge_num_color = Color(0.35, 0.42, 0.52, 0.8)

		var sb_hover := sb_norm.duplicate() as StyleBoxFlat
		sb_hover.bg_color = sb_norm.bg_color.lightened(0.15)
		if is_unlocked:
			sb_hover.border_color = Color(0.98, 0.88, 0.47, 1.0)
		else:
			sb_hover.border_color = Color(0.22, 0.28, 0.38, 1.0)

		var sb_pressed := sb_norm.duplicate() as StyleBoxFlat
		sb_pressed.border_width_top = 3
		sb_pressed.border_width_bottom = 1

		slab_btn.add_theme_stylebox_override("normal", sb_norm)
		slab_btn.add_theme_stylebox_override("hover", sb_hover)
		slab_btn.add_theme_stylebox_override("pressed", sb_pressed)
		slab_btn.add_theme_stylebox_override("focus", sb_norm)

		# 3. จัดวางองค์ประกอบภายในแท่นหิน (ข้างในรูปด่านแบบใหม่ ไม่ยืด ไม่เละ)
		var inner_margin := MarginContainer.new()
		inner_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner_margin.add_theme_constant_override("margin_left", 8)
		inner_margin.add_theme_constant_override("margin_right", 8)
		inner_margin.add_theme_constant_override("margin_top", 4)
		inner_margin.add_theme_constant_override("margin_bottom", 4)

		var hbox := HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_theme_constant_override("separation", 8)
		hbox.set_anchors_preset(Control.PRESET_FULL_RECT)

		# 3.1 ป้ายเหรียญศิลาแสดงเลขด่าน (ฝั่งซ้าย)
		var num_badge := PanelContainer.new()
		num_badge.custom_minimum_size = Vector2(36.0, 36.0)
		num_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		num_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var sb_badge := StyleBoxFlat.new()
		sb_badge.bg_color = badge_bg
		sb_badge.border_color = badge_border
		sb_badge.border_width_left = 1
		sb_badge.border_width_top = 1
		sb_badge.border_width_right = 1
		sb_badge.border_width_bottom = 2
		sb_badge.corner_radius_top_left = 3
		sb_badge.corner_radius_top_right = 3
		sb_badge.corner_radius_bottom_left = 3
		sb_badge.corner_radius_bottom_right = 3
		num_badge.add_theme_stylebox_override("panel", sb_badge)

		var num_lbl := Label.new()
		num_lbl.text = str(stg["no"])
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		num_lbl.add_theme_color_override("font_color", badge_num_color)
		if font_bungee:
			num_lbl.add_theme_font_override("font", font_bungee)
			num_lbl.add_theme_font_size_override("font_size", 14)
		elif font_ta_pixel:
			num_lbl.add_theme_font_override("font", font_ta_pixel)
			num_lbl.add_theme_font_size_override("font_size", 12)
		num_badge.add_child(num_lbl)
		hbox.add_child(num_badge)

		# 3.2 ชื่อด่านและชิปคำสั่ง Git (ตรงกลาง)
		if p_width >= 180.0:
			var info_vbox := VBoxContainer.new()
			info_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			info_vbox.add_theme_constant_override("separation", 2)

			var title_lbl := Label.new()
			title_lbl.text = str(stg["title"])
			title_lbl.clip_text = true
			title_lbl.add_theme_color_override("font_color", title_color)
			if font_chakra_bold:
				title_lbl.add_theme_font_override("font", font_chakra_bold)
				title_lbl.add_theme_font_size_override("font_size", 12)
			info_vbox.add_child(title_lbl)

			var cmd_lbl := Label.new()
			cmd_lbl.text = str(stg["cmd"])
			cmd_lbl.clip_text = true
			if is_unlocked:
				cmd_lbl.add_theme_color_override("font_color", Color(0.13, 0.83, 0.93, 0.95))
			else:
				cmd_lbl.add_theme_color_override("font_color", Color(0.35, 0.45, 0.55, 0.75))
			if font_ta_pixel:
				cmd_lbl.add_theme_font_override("font", font_ta_pixel)
				cmd_lbl.add_theme_font_size_override("font_size", 10)
			info_vbox.add_child(cmd_lbl)

			hbox.add_child(info_vbox)

		# 3.3 ฝั่งขวา (ไอคอนล็อก หรือ ดาว)
		if not is_unlocked and tex_lock:
			var lock_rect := TextureRect.new()
			lock_rect.texture = tex_lock
			lock_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			lock_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			lock_rect.custom_minimum_size = Vector2(18.0, 22.0)
			lock_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			lock_rect.modulate = Color(0.55, 0.62, 0.72, 0.85)
			lock_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hbox.add_child(lock_rect)
		elif is_cleared:
			var star_icon := Label.new()
			star_icon.text = "★★★"
			star_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			star_icon.add_theme_color_override("font_color", Color(0.98, 0.82, 0.10, 1.0))
			star_icon.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.02, 0.9))
			star_icon.add_theme_constant_override("outline_size", 2)
			if font_ta_pixel:
				star_icon.add_theme_font_override("font", font_ta_pixel)
			star_icon.add_theme_font_size_override("font_size", 16)
			hbox.add_child(star_icon)
		elif is_unlocked:
			var star_icon := Label.new()
			star_icon.text = "★★★"
			star_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			star_icon.add_theme_color_override("font_color", Color(0.42, 0.48, 0.56, 0.85))
			star_icon.add_theme_color_override("font_outline_color", Color(0.08, 0.10, 0.14, 0.9))
			star_icon.add_theme_constant_override("outline_size", 2)
			if font_ta_pixel:
				star_icon.add_theme_font_override("font", font_ta_pixel)
			star_icon.add_theme_font_size_override("font_size", 16)
			hbox.add_child(star_icon)
		inner_margin.add_child(hbox)
		slab_btn.add_child(inner_margin)


		var current_idx := i
		# แสดงรายละเอียดด่านใน HUD เมื่อนำเมาส์มาวางค้างไว้ (Hover / Hold)
		slab_btn.mouse_entered.connect(func():
			_update_hud_display(TOWER_STAGES[current_idx])
		)
		slab_btn.mouse_exited.connect(func():
			_update_hud_display(TOWER_STAGES[_current_stage_idx])
		)

		if is_unlocked:
			slab_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			slab_btn.pressed.connect(func():
				_on_platform_selected(current_idx)
			)
		else:
			slab_btn.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
			slab_btn.pressed.connect(func():
				_on_locked_platform_clicked(current_idx)
			)

		plat.add_child(slab_btn)
		tower_content.add_child(plat)
		_platform_nodes[stg_id] = plat


	if path_renderer:
		path_renderer.queue_redraw()



func _setup_character_and_cat() -> void:
	if not vel_hero:
		return

	# ซ่อนแมวดำตามคำสั่ง (เอาแมวออกไปก่อน)
	if black_cat:
		black_cat.visible = false

	vel_hero.z_index = 25
	vel_hero.pivot_offset = Vector2(24.0, 83.0)

	# สร้างแอนิเมชันสำหรับเวล (5.0 FPS, Frame Durations [2.0, 1.0, 2.0, 1.0, 2.0, 1.0] ตามสเปก)
	if not vel_anim:
		var frames := SpriteFrames.new()
		var frame_durations: Array[float] = [2.0, 1.0, 2.0, 1.0, 2.0, 1.0]

		frames.add_animation("breathe")
		frames.set_animation_loop("breathe", true)
		frames.set_animation_speed("breathe", 5.0)

		var tex_breathe := load("res://assets/cutscene/characters/vel/vel_breathe_blink-Sheet.png") as Texture2D
		if tex_breathe:
			for f in range(6):
				var atlas := AtlasTexture.new()
				atlas.atlas = tex_breathe
				atlas.region = Rect2(f * 48, 0, 48, 83)
				frames.add_frame("breathe", atlas, frame_durations[f])

		frames.add_animation("walk")
		frames.set_animation_loop("walk", true)
		frames.set_animation_speed("walk", 5.0)

		var tex_walk := load("res://assets/cutscene/characters/vel/vel_walk_right-Sheet.png") as Texture2D
		if tex_walk:
			for f in range(6):
				var atlas := AtlasTexture.new()
				atlas.atlas = tex_walk
				atlas.region = Rect2(f * 48, 0, 48, 83)
				frames.add_frame("walk", atlas, frame_durations[f])

		frames.add_animation("hold")
		frames.set_animation_loop("hold", true)
		frames.set_animation_speed("hold", 5.0)
		var tex_hold := load("res://assets/cutscene/characters/vel/vel_hold.png") as Texture2D
		if tex_hold:
			frames.add_frame("hold", tex_hold, 1.0)

		frames.add_animation("stand_straight")
		frames.set_animation_loop("stand_straight", true)
		frames.set_animation_speed("stand_straight", 5.0)
		var tex_straight := load("res://assets/cutscene/characters/vel/vel_Hblue_Sredyellow_idle.png") as Texture2D
		if tex_straight:
			frames.add_frame("stand_straight", tex_straight, 1.0)

		vel_anim = AnimatedSprite2D.new()
		vel_anim.name = "VelAnim"
		vel_anim.sprite_frames = frames
		vel_anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		vel_anim.position = Vector2(24.0, 41.5)
		if vel_sprite:
			vel_sprite.visible = false
		vel_hero.add_child(vel_anim)

	if vel_anim:
		vel_anim.play("breathe")

	var stg := TOWER_STAGES[_current_stage_idx]
	vel_hero.position = Vector2(stg["x"] - 24.0, stg["y"] - 107.0)


func _on_platform_selected(idx: int) -> void:
	if idx == _current_stage_idx and not _is_jumping:
		_on_launch_stage_pressed()
		return
	_try_navigate_stage(idx)


func _on_locked_platform_clicked(idx: int) -> void:
	_play_sfx(sfx_click)
	var stg := TOWER_STAGES[idx]
	if hud_desc:
		var original_text := str(stg["desc"])
		hud_desc.text = "🔒 แท่นหินด่าน %s ยังถูกผนึก! ต้องผ่านด่านก่อนหน้าเพื่อปลดล็อก" % stg["no"]
		get_tree().create_timer(1.8).timeout.connect(func():
			if _current_stage_idx == idx:
				hud_desc.text = original_text
		)


func _try_navigate_stage(target_idx: int) -> void:
	if target_idx < 0 or target_idx >= TOWER_STAGES.size():
		return

	var target_stg: Dictionary = TOWER_STAGES[target_idx]
	var target_id: int = target_stg["id"]
	var is_unlocked: bool = (target_id == 1) or GameProgressManager.is_level_cleared(target_id - 1)

	if not is_unlocked:
		_on_locked_platform_clicked(target_idx)
		return

	_target_queue_idx = target_idx

	if not _is_jumping:
		_step_towards_queued_target()


func _step_towards_queued_target() -> void:
	if _target_queue_idx == -1 or _target_queue_idx == _current_stage_idx:
		# ถึงจุดหมายปลายทางแล้ว หรือหยุดเดิน: ยืนตัวตรง หายใจตามปกติ
		_is_jumping = false
		_target_queue_idx = _current_stage_idx
		if vel_anim:
			vel_anim.play("breathe")
		var curr_stg := TOWER_STAGES[_current_stage_idx]
		if vel_hero:
			vel_hero.position = Vector2(curr_stg["x"] - 24.0, curr_stg["y"] - 107.0)
			vel_hero.scale = Vector2.ONE
		return

	var step_dir := 1 if _target_queue_idx > _current_stage_idx else -1
	var next_step_idx := _current_stage_idx + step_dir

	var next_stg: Dictionary = TOWER_STAGES[next_step_idx]
	var next_id: int = next_stg["id"]
	var is_unlocked: bool = (next_id == 1) or GameProgressManager.is_level_cleared(next_id - 1)
	if not is_unlocked:
		_target_queue_idx = _current_stage_idx
		_is_jumping = false
		if vel_anim:
			vel_anim.play("breathe")
		return

	_perform_jump_step(next_step_idx)


func _perform_jump_step(next_idx: int) -> void:
	_is_jumping = true
	var prev_idx := _current_stage_idx
	_current_stage_idx = next_idx

	_update_platform_highlight(prev_idx, false)
	_update_platform_highlight(_current_stage_idx, true)

	var stg := TOWER_STAGES[_current_stage_idx]
	_update_hud_display(stg)
	_highlight_act(int(stg["act"]))

	var target_vel_pos := Vector2(stg["x"] - 24.0, stg["y"] - 107.0)
	var start_vel_pos := vel_hero.position if vel_hero else target_vel_pos
	var is_moving_right := target_vel_pos.x >= start_vel_pos.x

	var prev_stg_id: int = TOWER_STAGES[prev_idx]["id"]
	var next_stg_id: int = TOWER_STAGES[next_idx]["id"]
	var is_between_15_and_16 := (prev_stg_id == 15 and next_stg_id == 16) or (prev_stg_id == 16 and next_stg_id == 15)

	# เล่นแอนิเมชันตามเงื่อนไข
	if vel_anim:
		if is_between_15_and_16:
			vel_anim.flip_h = false
			if next_stg_id == 15:
				# ตอนระหว่าง 15-16 ลงมาจาก 16 สู่ 15 -> ให้ท่า hold ที่ยกแขน
				vel_anim.play("hold")
			else:
				# ตอนระหว่าง 15-16 ขึ้นจาก 15 สู่ 16 -> ให้ท่าตัวยืนตรงปกติ
				vel_anim.play("stand_straight")
		else:
			# เดิน/วิ่งต่อเนื่องทั่วไป
			vel_anim.flip_h = not is_moving_right
			vel_anim.play("walk")

	_play_sfx(sfx_jump)
	_scroll_to_y(int(stg["y"]) - 460, true)

	var has_more_steps := (_target_queue_idx != _current_stage_idx)
	var jump_duration := 0.65 if is_between_15_and_16 else (0.32 if has_more_steps else 0.42)
	var peak_height := 50.0 if is_between_15_and_16 else 90.0

	if _jump_tween and _jump_tween.is_valid():
		_jump_tween.kill()

	_jump_tween = create_tween()
	_jump_tween.tween_method(func(t: float):
		if not vel_hero:
			return
		var curr_x := lerpf(start_vel_pos.x, target_vel_pos.x, t)
		var base_y := lerpf(start_vel_pos.y, target_vel_pos.y, t)
		var arc_y := 4.0 * peak_height * t * (1.0 - t)
		vel_hero.position = Vector2(curr_x, base_y - arc_y)
	, 0.0, 1.0, jump_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_jump_tween.finished.connect(func():
		_play_sfx(sfx_click)
		_step_towards_queued_target()
	)


func _jump_to_stage(target_idx: int, animate: bool = true) -> void:
	if target_idx < 0 or target_idx >= TOWER_STAGES.size():
		return

	if not animate:
		if _jump_tween and _jump_tween.is_valid():
			_jump_tween.kill()
		_is_jumping = false
		var prev_idx := _current_stage_idx
		_current_stage_idx = target_idx
		_target_queue_idx = target_idx
		_update_platform_highlight(prev_idx, false)
		_update_platform_highlight(_current_stage_idx, true)

		var stg := TOWER_STAGES[_current_stage_idx]
		_update_hud_display(stg)
		_highlight_act(int(stg["act"]))

		var target_vel_pos := Vector2(stg["x"] - 24.0, stg["y"] - 107.0)
		if vel_hero:
			vel_hero.position = target_vel_pos
			vel_hero.scale = Vector2.ONE
		if vel_anim:
			vel_anim.play("breathe")
		_scroll_to_y(int(stg["y"]) - 460, false)
		return

	_try_navigate_stage(target_idx)


func _update_platform_highlight(idx: int, is_active: bool) -> void:
	if idx < 0 or idx >= TOWER_STAGES.size():
		return
	var stg: Dictionary = TOWER_STAGES[idx]
	var stg_id: int = stg["id"]
	if not _platform_nodes.has(stg_id):
		return
	var plat: Control = _platform_nodes[stg_id]
	var slab_btn := plat.get_node_or_null("SlabBtn") as Button
	if not slab_btn:
		return

	var is_cleared := GameProgressManager.is_level_cleared(stg_id)
	var is_unlocked := (stg_id == 1) or GameProgressManager.is_level_cleared(stg_id - 1)

	var sb_norm := StyleBoxFlat.new()
	sb_norm.corner_radius_top_left = 4
	sb_norm.corner_radius_top_right = 4
	sb_norm.corner_radius_bottom_left = 4
	sb_norm.corner_radius_bottom_right = 4
	sb_norm.border_width_left = 2
	sb_norm.border_width_top = 2
	sb_norm.border_width_right = 2
	sb_norm.border_width_bottom = 3

	if is_active:
		sb_norm.bg_color = Color(0.18, 0.13, 0.08, 0.96)
		sb_norm.border_color = Color(0.96, 0.62, 0.07, 1.0)
		sb_norm.shadow_color = Color(0.96, 0.62, 0.04, 0.38)
		sb_norm.shadow_size = 6
	elif is_cleared:
		sb_norm.bg_color = Color(0.08, 0.12, 0.18, 0.95)
		sb_norm.border_color = Color(0.28, 0.38, 0.52, 1.0)
		sb_norm.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
		sb_norm.shadow_size = 3
	elif is_unlocked:
		sb_norm.bg_color = Color(0.13, 0.10, 0.07, 0.95)
		sb_norm.border_color = Color(0.72, 0.48, 0.16, 1.0)
	else:
		sb_norm.bg_color = Color(0.06, 0.07, 0.10, 0.92)
		sb_norm.border_color = Color(0.14, 0.17, 0.24, 0.85)

	var sb_hover := sb_norm.duplicate() as StyleBoxFlat
	sb_hover.bg_color = sb_norm.bg_color.lightened(0.15)
	if is_unlocked:
		sb_hover.border_color = Color(0.98, 0.88, 0.47, 1.0)
	else:
		sb_hover.border_color = Color(0.22, 0.28, 0.38, 1.0)

	slab_btn.add_theme_stylebox_override("normal", sb_norm)
	slab_btn.add_theme_stylebox_override("hover", sb_hover)


func _update_hud_display(stg: Dictionary) -> void:
	var stg_id: int = stg["id"]
	var is_cleared := GameProgressManager.is_level_cleared(stg_id)
	var is_unlocked := (stg_id == 1) or GameProgressManager.is_level_cleared(stg_id - 1)

	if hud_no_badge:
		hud_no_badge.text = "LV %s" % stg["no"]
	if hud_title:
		hud_title.text = "ด่าน %s — %s" % [stg["no"], stg["title"]]
	if hud_act_tag:
		var act_num: int = stg["act"]
		hud_act_tag.text = "ACT %d" % act_num
		if act_num == 1:
			hud_act_tag.add_theme_color_override("font_color", Color(0.55, 0.75, 0.95, 1.0))
		elif act_num == 2:
			hud_act_tag.add_theme_color_override("font_color", Color(0.45, 0.85, 0.65, 1.0))
		else:
			hud_act_tag.add_theme_color_override("font_color", Color(0.85, 0.65, 0.98, 1.0))
	if hud_cmd:
		hud_cmd.text = stg["cmd"]
	if hud_desc:
		hud_desc.text = stg["desc"]

	if btn_launch:
		if is_unlocked:
			btn_launch.disabled = false
			btn_launch.text = "เข้าสู่ด่าน" if not is_cleared else "ทบทวนด่าน"
		else:
			btn_launch.disabled = true
			btn_launch.text = "ยังไม่ปลดล็อก"


func _scroll_to_y(target_y: int, animate: bool = true) -> void:
	if not scroll_chamber:
		return
	var clamped_y := clampi(target_y, 0, 3600)
	if animate:
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(scroll_chamber, "scroll_vertical", clamped_y, 0.38)
	else:
		scroll_chamber.scroll_vertical = clamped_y


func _on_draw_path() -> void:
	if not path_renderer:
		return
	var stages: Array[Dictionary] = TOWER_STAGES
	if stages.is_empty():
		return

	# วาดเส้นทาง Act 1: บันไดวน (1 -> 15)
	for i in range(14):
		var s1 := stages[i]
		var s2 := stages[i + 1]
		var is_cleared := GameProgressManager.is_level_cleared(int(s1["id"]))
		var line_color := Color(0.42, 0.78, 0.52, 0.95) if is_cleared else Color(0.30, 0.35, 0.48, 0.65)
		_draw_curved_connection(Vector2(s1["x"], s1["y"]), Vector2(s2["x"], s2["y"]), line_color)

	# เชื่อม Act 1 -> Act 2 (15 -> 16)
	if stages.size() >= 16:
		var s15 := stages[14]
		var s16 := stages[15]
		var is_cleared := GameProgressManager.is_level_cleared(15)
		var line_color := Color(0.42, 0.78, 0.52, 0.95) if is_cleared else Color(0.35, 0.42, 0.55, 0.7)
		_draw_curved_connection(Vector2(s15["x"], s15["y"]), Vector2(s16["x"], s16["y"]), line_color)

	# วาดเส้นทาง Act 2: ลูปห้องทีม (16 -> 17 -> 18 -> 19 -> 20 -> 16)
	if stages.size() >= 20:
		var act2_indices: Array[int] = [15, 16, 17, 18, 19]
		for k in range(act2_indices.size()):
			var idx1: int = act2_indices[k]
			var idx2: int = act2_indices[(k + 1) % act2_indices.size()]
			var s_a := stages[idx1]
			var s_b := stages[idx2]
			var is_cleared := GameProgressManager.is_level_cleared(int(s_a["id"]))
			var line_color := Color(0.42, 0.78, 0.52, 0.95) if is_cleared else Color(0.24, 0.38, 0.32, 0.7)
			_draw_curved_connection(Vector2(s_a["x"], s_a["y"]), Vector2(s_b["x"], s_b["y"]), line_color)

	# เชื่อม Act 2 -> Act 3 (20 -> 21)
	if stages.size() >= 21:
		var s20 := stages[19]
		var s21 := stages[20]
		var is_cleared := GameProgressManager.is_level_cleared(20)
		var line_color := Color(0.42, 0.78, 0.52, 0.95) if is_cleared else Color(0.38, 0.30, 0.48, 0.7)
		_draw_curved_connection(Vector2(s20["x"], s20["y"]), Vector2(s21["x"], s21["y"]), line_color)


func _draw_curved_connection(p1: Vector2, p2: Vector2, color: Color) -> void:
	if not path_renderer:
		return
	var steps := 14
	var prev_pt := p1
	var mid_y := (p1.y + p2.y) / 2.0

	var c1_x := p1.x
	var c2_x := p2.x

	# เลี้ยวโค้งวนกลับตามผนังหอคอย
	if p1.x > 1150.0 and p2.x > 1150.0:
		c1_x = maxf(p1.x, p2.x) + 30.0
		c2_x = maxf(p1.x, p2.x) + 30.0
	elif p1.x < 750.0 and p2.x < 750.0:
		c1_x = minf(p1.x, p2.x) - 30.0
		c2_x = minf(p1.x, p2.x) - 30.0

	var c1 := Vector2(c1_x, mid_y)
	var c2 := Vector2(c2_x, mid_y)

	for s in range(1, steps + 1):
		var t := float(s) / float(steps)
		var pt := _bezier_interpolate(p1, c1, c2, p2, t)
		path_renderer.draw_dashed_line(prev_pt, pt, color, 2.5, 4.0)
		prev_pt = pt


func _bezier_interpolate(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	var tt := t * t
	var uu := u * u
	var uuu := uu * u
	var ttt := tt * t

	var p := uuu * p0
	p += 3.0 * uu * t * p1
	p += 3.0 * u * tt * p2
	p += ttt * p3
	return p


func _on_launch_stage_pressed() -> void:
	var stg := TOWER_STAGES[_current_stage_idx]
	var stg_id: int = stg["id"]
	var is_unlocked := (stg_id == 1) or GameProgressManager.is_level_cleared(stg_id - 1)
	if not is_unlocked:
		return

	_play_sfx(sfx_click)
	GameProgressManager.set_selected_level_number(stg_id)

	if stg_id == 1:
		get_tree().change_scene_to_file("res://features/cutscene/inside_tower_cutscene.tscn")
	elif stg_id == 16:
		get_tree().change_scene_to_file("res://features/cutscene/central_tower_cutscene.tscn")
	else:
		var lvl_path := "res://features/dialogue/levels/level_%02d.gd" % stg_id
		if ResourceLoader.exists(lvl_path):
			get_tree().change_scene_to_file("res://features/cutscene/inside_tower_cutscene.tscn")
		else:
			get_tree().change_scene_to_file("res://features/sandbox/sandbox_game_view.tscn")


func _play_sfx(player: AudioStreamPlayer) -> void:
	if player and not _is_muted:
		player.play()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_on_back_pressed()
		elif event.keycode == KEY_UP or event.keycode == KEY_W or event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			get_viewport().set_input_as_handled()
			var base_idx := _target_queue_idx if _is_jumping and _target_queue_idx != -1 else _current_stage_idx
			_try_navigate_stage(base_idx + 1)
		elif event.keycode == KEY_DOWN or event.keycode == KEY_S or event.keycode == KEY_LEFT or event.keycode == KEY_A:
			get_viewport().set_input_as_handled()
			var base_idx := _target_queue_idx if _is_jumping and _target_queue_idx != -1 else _current_stage_idx
			_try_navigate_stage(base_idx - 1)
		elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			get_viewport().set_input_as_handled()
			_on_launch_stage_pressed()
		elif event.keycode == KEY_1:
			_scroll_to_y(3200, true)
			_highlight_act(1)
		elif event.keycode == KEY_2:
			_scroll_to_y(700, true)
			_highlight_act(2)
		elif event.keycode == KEY_3:
			_scroll_to_y(50, true)
			_highlight_act(3)
