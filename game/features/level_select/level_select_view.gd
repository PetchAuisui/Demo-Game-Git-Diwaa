class_name LevelSelectView
extends Control

## หน้าต่างแผนที่ไต่หอคอยเวทมนตร์ (Tower Ascension Roadmap - 40 Levels)
## รวมสไตล์ Dark Gothic Fantasy และโครงสร้าง Acts 1-3 ตาม Prototype
## Act 1: บันไดวนไต่หอคอย (01-15) - แท่นหินลอยได้สไตล์ Doodle Jump
## Act 2: โถงประจำชั้นทีม (16-20) - Collab Chamber Floor Mat เป็น Loop GitHub Flow
## Act 3: ยอดหอคอยแก้ปัญหา (21-40) - Discrete Engineering Deck 5 คอลัมน์ พร้อมเงาปรมาจารย์ Git

const TOWER_STAGES: Array[Dictionary] = [
	# ACT 1: Winding Tower Ascent (01-15) - ไต่หอคอยแบบเป็นธรรมชาติ กึ่งกลางสมมาตรหอคอย x=880 (Screen x=960)
	{ "id": 1, "act": 1, "no": "01", "title": "git --version + git config", "cmd": "git --version", "desc": "ตั้งค่านามผู้ใช้งาน user.name และ user.email", "x": 880.0, "y": 5125.0, "width": 260.0, "has_scripture": true },
	{ "id": 2, "act": 1, "no": "02", "title": "git init", "cmd": "git init", "desc": "ร่ายอาคมสร้าง Repository ว่างเปล่าเพื่อเริ่มต้นคลังตำรา", "x": 660.0, "y": 4900.0, "width": 220.0, "has_scripture": false },
	{ "id": 3, "act": 1, "no": "03", "title": "git status", "cmd": "git status", "desc": "สำรวจสถานะม้วนคาถาทั้งหมดในพื้นที่ทำงานว่ามีสิ่งใดเปลี่ยนแปลง", "x": 570.0, "y": 4675.0, "width": 220.0, "has_scripture": false },
	{ "id": 4, "act": 1, "no": "04", "title": "git add", "cmd": "git add .", "desc": "จัดเตรียมม้วนคาถาเข้าสู่ Staging Area ก่อนประทับตรา", "x": 760.0, "y": 4450.0, "width": 220.0, "has_scripture": false },
	{ "id": 5, "act": 1, "no": "05", "title": "git commit", "cmd": "git commit -m", "desc": "ประทับตราขี้ผึ้งบันทึกประวัติศาสตร์ลง Git Graph ถาวร", "x": 940.0, "y": 4225.0, "width": 240.0, "has_scripture": true },
	{ "id": 6, "act": 1, "no": "06", "title": "git log", "cmd": "git log", "desc": "กางผืนแผนที่สำรวจประวัติศาสตร์การบันทึกย้อนหลังในอดีต", "x": 1120.0, "y": 4000.0, "width": 220.0, "has_scripture": false },
	{ "id": 7, "act": 1, "no": "07", "title": "git diff", "cmd": "git diff", "desc": "ส่องดูความแตกต่างของอักขระคาถาเทียบกับบันทึกเดิม", "x": 1180.0, "y": 3775.0, "width": 220.0, "has_scripture": false },
	{ "id": 8, "act": 1, "no": "08", "title": "git restore", "cmd": "git restore <file>", "desc": "ยกเลิกการแก้ไขไฟล์ใน Working Directory กลับสู่สภาพเดิม", "x": 1000.0, "y": 3550.0, "width": 220.0, "has_scripture": false },
	{ "id": 9, "act": 1, "no": "09", "title": "git reset", "cmd": "git reset HEAD~1", "desc": "ถอยจุดตรวจเช็กพอยต์กลับสู่สถานะก่อนหน้า", "x": 820.0, "y": 3325.0, "width": 220.0, "has_scripture": false },
	{ "id": 10, "act": 1, "no": "10", "title": "git branch", "cmd": "git branch <name>", "desc": "เปิดมิติกิ่งก้านใหม่เพื่อพัฒนาคาถาโดยไม่กระทบเส้นหลัก", "x": 620.0, "y": 3100.0, "width": 240.0, "has_scripture": true },
	{ "id": 11, "act": 1, "no": "11", "title": "git switch", "cmd": "git switch <branch>", "desc": "ย้ายจิตวิญญาณสลับไปมาระหว่างกิ่งก้านคาถาอย่างปลอดภัย", "x": 570.0, "y": 2875.0, "width": 220.0, "has_scripture": false },
	{ "id": 12, "act": 1, "no": "12", "title": "git merge", "cmd": "git merge <branch>", "desc": "หลอมรวมพลังคาถาจากกิ่งก้านเข้าสู่สายหลัก", "x": 780.0, "y": 2650.0, "width": 220.0, "has_scripture": false },
	{ "id": 13, "act": 1, "no": "13", "title": "git clone + git remote", "cmd": "git clone", "desc": "คัดลอกคลังตำราจากมิติต้นทางและเชื่อมต่อสายสัมพันธ์", "x": 1000.0, "y": 2425.0, "width": 220.0, "has_scripture": false },
	{ "id": 14, "act": 1, "no": "14", "title": "git pull", "cmd": "git pull origin main", "desc": "ดึงการอัปเดตบทคาถาใหม่ล่าสุดจากหอคอยส่วนกลาง", "x": 1140.0, "y": 2200.0, "width": 220.0, "has_scripture": false },
	{ "id": 15, "act": 1, "no": "15", "title": "git push (สู่โถงทีม)", "cmd": "git push origin main", "desc": "ส่งบันทึกคาถาขึ้นสู่หอคอยส่วนกลางให้ทุกคนร่วมใช้ (สู่โถงทีม)", "x": 880.0, "y": 1975.0, "width": 320.0, "has_scripture": true },

	# ACT 2: Collab Chamber Loop (16-20) - โถงประจำชั้นทีม GitHub Flow กึ่งกลาง x=880
	{ "id": 16, "act": 2, "no": "16", "title": "GitHub Flow (พบผู้พิทักษ์)", "cmd": "branch ➔ pr ➔ merge", "desc": "เรียนรู้วงจรการทำงานร่วมกันแบบสากลตั้งแต่แยกกิ่งจนถึงรวมงาน", "x": 880.0, "y": 1285.0, "width": 240.0, "has_scripture": true },
	{ "id": 17, "act": 2, "no": "17", "title": "Pull Request", "cmd": "Create PR", "desc": "ยื่นคำร้องขอรวมคาถาให้เพื่อนร่วมทีมช่วยตรวจทานความถูกต้อง", "x": 1120.0, "y": 1425.0, "width": 220.0, "has_scripture": false },
	{ "id": 18, "act": 2, "no": "18", "title": "Merge PR", "cmd": "Confirm Merge", "desc": "อนุมัติคำร้องและหลอมรวมโค้ดเข้าสู่สายหลักอย่างสมบูรณ์", "x": 1040.0, "y": 1645.0, "width": 220.0, "has_scripture": false },
	{ "id": 19, "act": 2, "no": "19", "title": "Update PR & git fetch", "cmd": "git fetch", "desc": "อัปเดตข้อมูลมิติต้นทางโดยไม่รบกวนไฟล์งานที่กำลังพิมพ์", "x": 720.0, "y": 1645.0, "width": 220.0, "has_scripture": false },
	{ "id": 20, "act": 2, "no": "20", "title": "Merge PR (Final Boss)", "cmd": "Squash & Merge", "desc": "รวมคอมมิตย่อยให้กลายเป็นบันทึกเดียวที่สะอาดเรียบร้อยก่อนขึ้นยอดหอคอย", "x": 640.0, "y": 1425.0, "width": 240.0, "has_scripture": true },

	# ACT 3: Top Tower Deck (21-40) - บันไดวนคดเคี้ยวสลับซ้ายขวา (Serpentine Winding Deck with Gothic Ladders)
	# แถวที่ 1 (21-25) จากซ้ายไปขวา
	{ "id": 21, "act": 3, "no": "21", "title": "ตรวจสถานะก่อนเริ่มงาน", "cmd": "git status", "desc": "ตรวจสถานะ working tree ให้เรียบร้อยก่อนเริ่มแก้ปัญหา", "x": 280.0, "y": 1040.0, "width": 250.0, "has_scripture": false },
	{ "id": 22, "act": 3, "no": "22", "title": "ตรวจสอบความแตกต่าง", "cmd": "git diff", "desc": "ส่องดูจุดเพี้ยนของโค้ดก่อนเริ่มแก้ไข", "x": 580.0, "y": 1040.0, "width": 250.0, "has_scripture": false },
	{ "id": 23, "act": 3, "no": "23", "title": "คืนไฟล์ที่แก้ผิด", "cmd": "git restore", "desc": "กู้คืนไฟล์โค้ดที่พังกลับสู่สภาพเดิม", "x": 880.0, "y": 1040.0, "width": 250.0, "has_scripture": false },
	{ "id": 24, "act": 3, "no": "24", "title": "นำไฟล์ลับออกจาก Stage", "cmd": "git restore --staged", "desc": "ปลดไฟล์ความลับออกจากสถานะเตรียมคอมมิต", "x": 1180.0, "y": 1040.0, "width": 250.0, "has_scripture": false },
	{ "id": 25, "act": 3, "no": "25", "title": "แก้ไข Commit ล่าสุด", "cmd": "git commit --amend", "desc": "ซ่อมแซมคอมมิตล่าสุดโดยไม่สร้างขยะในประวัติ", "x": 1480.0, "y": 1040.0, "width": 250.0, "has_scripture": true },

	# แถวที่ 2 (26-30) จากขวาไปซ้าย (26 อยู่ขวาสุดตรงกับ 25 มีบันไดเชื่อมขึ้นไป, 30 อยู่ซ้ายสุด)
	{ "id": 26, "act": 3, "no": "26", "title": "ย้อน Commit เก็บงานไว้", "cmd": "git reset --soft", "desc": "ถอยประวัติแต่คงงานไว้ใน Staging Area", "x": 1480.0, "y": 800.0, "width": 250.0, "has_scripture": false },
	{ "id": 27, "act": 3, "no": "27", "title": "ลบ Commit ทิ้งถาวร", "cmd": "git reset --hard", "desc": "ล้างโค้ดเสียทิ้งไปอย่างเด็ดขาด", "x": 1180.0, "y": 800.0, "width": 250.0, "has_scripture": false },
	{ "id": 28, "act": 3, "no": "28", "title": "ย้ายงานออกจาก main", "cmd": "git switch -c", "desc": "ย้ายงานไปกิ่งฟีเจอร์ใหม่เพื่อปกป้องกิ่งหลัก", "x": 880.0, "y": 800.0, "width": 250.0, "has_scripture": false },
	{ "id": 29, "act": 3, "no": "29", "title": "ค้นหา Commit ที่เกี่ยวข้อง", "cmd": "git log --grep", "desc": "สืบค้นหาบันทึกในอดีตตามคีย์เวิร์ดของปัญหา", "x": 580.0, "y": 800.0, "width": 250.0, "has_scripture": false },
	{ "id": 30, "act": 3, "no": "30", "title": "วิเคราะห์ Commit Graph", "cmd": "git log --graph", "desc": "กางแผนผังสายฟ้าดูความเชื่อมโยงของทุกกิ่ง", "x": 280.0, "y": 800.0, "width": 250.0, "has_scripture": true },

	# แถวที่ 3 (31-35) จากซ้ายไปขวา (31 อยู่ซ้ายสุดตรงกับ 30 มีบันไดเชื่อมขึ้นไป, 35 อยู่ขวาสุด)
	{ "id": 31, "act": 3, "no": "31", "title": "ย้าย Commit ผิด Branch", "cmd": "git branch + reset", "desc": "ซ่อมแซมเส้นเวลา ย้ายคอมมิตไปกิ่งที่ถูกต้อง", "x": 280.0, "y": 560.0, "width": 250.0, "has_scripture": false },
	{ "id": 32, "act": 3, "no": "32", "title": "รวม Feature Branch", "cmd": "git merge feature", "desc": "หลอมรวมฟีเจอร์เข้าสู่สายหลักอย่างเป็นระบบ", "x": 580.0, "y": 560.0, "width": 250.0, "has_scripture": false },
	{ "id": 33, "act": 3, "no": "33", "title": "แก้ Merge Conflict", "cmd": "solve conflict", "desc": "เผชิญหน้าอสูร Conflict ตัดสินใจเลือกโค้ดที่ถูกต้อง", "x": 880.0, "y": 560.0, "width": 250.0, "has_scripture": false },
	{ "id": 34, "act": 3, "no": "34", "title": "Clone โปรเจกต์ของทีม", "cmd": "git clone", "desc": "ดาวน์โหลดคลังตำราทีมและตรวจสอบ Remote", "x": 1180.0, "y": 560.0, "width": 250.0, "has_scripture": false },
	{ "id": 35, "act": 3, "no": "35", "title": "แก้ URL ของ Remote", "cmd": "git remote set-url", "desc": "แก้ปัญหาต่อไม่ติดด้วยการเปลี่ยน URL เซิร์ฟเวอร์", "x": 1480.0, "y": 560.0, "width": 250.0, "has_scripture": true },

	# แถวที่ 4 (36-40) จากขวาไปซ้าย (36 อยู่ขวาสุดตรงกับ 35 มีบันไดเชื่อมขึ้นไป, 40 อยู่ซ้ายสุด)
	{ "id": 36, "act": 3, "no": "36", "title": "กู้คืน Remote origin", "cmd": "git remote add", "desc": "สร้างสายสัมพันธ์ใหม่หลังเผลอลบการเชื่อมต่อ", "x": 1480.0, "y": 320.0, "width": 250.0, "has_scripture": false },
	{ "id": 37, "act": 3, "no": "37", "title": "รับอัปเดตจาก Remote", "cmd": "git pull --rebase", "desc": "ดึงงานเพื่อนร่วมทีมมาผสานโดยประวัติเป็นเส้นตรง", "x": 1180.0, "y": 320.0, "width": 250.0, "has_scripture": false },
	{ "id": 38, "act": 3, "no": "38", "title": "ส่ง Feature ครั้งแรก", "cmd": "git push -u", "desc": "ตั้งค่า upstream tracking และส่งกิ่งงานขึ้นเซิร์ฟเวอร์", "x": 880.0, "y": 320.0, "width": 250.0, "has_scripture": false },
	{ "id": 39, "act": 3, "no": "39", "title": "แก้ไขตาม Code Review", "cmd": "amend & push", "desc": "ปรับปรุงตามคำแนะนำของรุ่นพี่และส่งอัปเดต", "x": 580.0, "y": 320.0, "width": 250.0, "has_scripture": false },
	{ "id": 40, "act": 3, "no": "40", "title": "กู้คืนคัมภีร์และปรมาจารย์ Git (FINAL)", "cmd": "release ➔ final", "desc": "ภารกิจสูงสุด: ผสานคัมภีร์โบราณ ปลดปล่อยปรมาจารย์ Git ผู้สาบสูญสู่ยอดหอคอย", "x": 280.0, "y": 320.0, "width": 250.0, "has_scripture": true },
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
var brand_btn: Button
var brand_title: Label
var brand_hat: TextureRect
var btn_back: Button
var btn_act1: Button
var btn_act2: Button
var btn_act3: Button
var act_progress_panel: PanelContainer
var act_progress_label: Label
var btn_focus_current: Button
var btn_sound: Button

# Act Header Tab Nodes
var act_header_tab: PanelContainer
var act_badge: Label
var act_title: Label
var act_desc: Label
var _current_active_act: int = -1
var _act_tab_tween: Tween = null

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

# Scale and Layout Constants
const VEL_SCALE: float = 1.5
const PLAT_HEIGHT: float = 80.0
const VEL_Y_OFFSET: float = 119.0

# Gothic Minimal Navbar Palette
const NAV_COLOR_ACTIVE := Color(0.722, 0.604, 0.404, 1.0)     # #B89A67 Antique gold
const NAV_COLOR_COMPLETED := Color(0.510, 0.604, 0.569, 1.0)  # #829A91 Muted sage green
const NAV_COLOR_LOCKED := Color(0.467, 0.459, 0.553, 1.0)     # #77758D Muted lavender-gray
const NAV_COLOR_PRIMARY := Color(0.894, 0.875, 0.835, 1.0)    # #E4DFD5 Primary text
const NAV_COLOR_SECONDARY := Color(0.604, 0.588, 0.667, 1.0)  # #9A96AA Secondary text

# State variables
var _current_stage_idx: int = 0
var _view_stage_idx: int = 0
var _target_scroll_y: float = -1.0
var _platform_nodes: Dictionary = {}
var _is_jumping := false
var _target_queue_idx: int = -1
var _landing_seq_id: int = 0
var _buffered_dir: Vector2 = Vector2.ZERO
var _jump_tween: Tween = null
var _scroll_tween: Tween = null
var _is_muted := false
var _idle_bob_timer := 0.0
var _torch_flames: Array[ColorRect] = []
var _torch_timer := 0.0
var _path_glow_timer: float = 0.0
var _glow_redraw_accum: float = 0.0
var _view_act_num: int = 1


func _ready() -> void:
	_load_resources()
	_bind_nodes()
	_wire_navbar()
	_init_game_progression()
	_spawn_tower_platforms()
	_setup_character_and_cat()

	# เลื่อนมุมมองกล้องไปยังตำแหน่งด่านเริ่มต้นของผู้เล่นทันทีหลังจากที่ layout เสร็จสมบูรณ์
	_initial_scroll_to_current_stage()


func _initial_scroll_to_current_stage() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_jump_to_stage(_current_stage_idx, false)
	if scroll_chamber and tower_content:
		var stg: Dictionary = TOWER_STAGES[_current_stage_idx]
		var center_offset := int(scroll_chamber.size.y * 0.5) if scroll_chamber and scroll_chamber.size.y > 0 else 540
		var target_y := int(stg["y"]) - center_offset
		var max_scroll := maxi(0, int(tower_content.custom_minimum_size.y - scroll_chamber.size.y))
		scroll_chamber.scroll_vertical = clampi(target_y, 0, max_scroll)


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

	brand_btn = get_node_or_null("%BrandBtn")
	brand_title = get_node_or_null("%BrandTitle")
	brand_hat = get_node_or_null("%BrandHat")
	if brand_hat:
		brand_hat.texture = GameProgressManager.get_current_hat_texture()
		brand_hat.position.y = -4.0
		brand_hat.rotation_degrees = 0.0

	btn_back = get_node_or_null("%BtnBack")
	btn_act1 = get_node_or_null("%BtnAct1")
	btn_act2 = get_node_or_null("%BtnAct2")
	btn_act3 = get_node_or_null("%BtnAct3")
	act_progress_panel = get_node_or_null("%ActProgressPanel")
	act_progress_label = get_node_or_null("%ActProgressLabel")
	btn_focus_current = get_node_or_null("%BtnFocusCurrent")
	btn_sound = get_node_or_null("%BtnSound")

	act_header_tab = get_node_or_null("%ActHeaderTab")
	act_badge = get_node_or_null("%ActBadge")
	act_title = get_node_or_null("%ActTitle")
	act_desc = get_node_or_null("%ActDesc")

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
	_path_glow_timer += delta
	_glow_redraw_accum += delta
	if _glow_redraw_accum >= 0.05:
		_glow_redraw_accum = 0.0
		if path_renderer:
			path_renderer.queue_redraw()


func _wire_navbar() -> void:
	if brand_btn:
		brand_btn.mouse_entered.connect(_on_brand_hover.bind(true))
		brand_btn.mouse_exited.connect(_on_brand_hover.bind(false))
		brand_btn.pressed.connect(_on_back_pressed)
	if btn_back:
		btn_back.pressed.connect(_on_back_pressed)
	if btn_act1:
		btn_act1.pressed.connect(func(): _on_act_button_pressed(1))
	if btn_act2:
		btn_act2.pressed.connect(func(): _on_act_button_pressed(2))
	if btn_act3:
		btn_act3.pressed.connect(func(): _on_act_button_pressed(3))
	if act_progress_panel:
		act_progress_panel.custom_minimum_size = Vector2(200, 44)
	if btn_focus_current:
		btn_focus_current.pressed.connect(_on_continue_pressed)
		btn_focus_current.custom_minimum_size = Vector2(116, 44)
		btn_focus_current.text = "ดำเนินต่อ →"
		btn_focus_current.add_theme_color_override("font_color", NAV_COLOR_ACTIVE)
		btn_focus_current.add_theme_color_override("font_hover_color", NAV_COLOR_PRIMARY)
		btn_focus_current.add_theme_color_override("font_pressed_color", NAV_COLOR_SECONDARY)
		btn_focus_current.add_theme_color_override("font_focus_color", NAV_COLOR_ACTIVE)
		var empty_continue_sb := StyleBoxEmpty.new()
		btn_focus_current.add_theme_stylebox_override("normal", empty_continue_sb)
		btn_focus_current.add_theme_stylebox_override("hover", empty_continue_sb)
		btn_focus_current.add_theme_stylebox_override("pressed", empty_continue_sb)
		btn_focus_current.add_theme_stylebox_override("focus", empty_continue_sb)
	if btn_sound:
		btn_sound.pressed.connect(_on_toggle_sound)
	if btn_launch:
		btn_launch.pressed.connect(_on_launch_stage_pressed)


func _on_brand_hover(is_hover: bool) -> void:
	if brand_hat:
		var tw := create_tween()
		if is_hover:
			tw.tween_property(brand_hat, "position:y", -7.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(brand_hat, "rotation_degrees", -6.0, 0.10)
			tw.tween_property(brand_hat, "position:y", -4.0, 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(brand_hat, "rotation_degrees", 0.0, 0.12)
		else:
			tw.tween_property(brand_hat, "position:y", -4.0, 0.10)
			tw.parallel().tween_property(brand_hat, "rotation_degrees", 0.0, 0.10)


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
	_refresh_act_tabs(act_num)


func _get_act_progress(act_num: int) -> Dictionary:
	var total_levels := 0
	var cleared_levels := 0
	var is_act_unlocked := false
	if act_num == 1:
		total_levels = 15
		is_act_unlocked = true
		for id in range(1, 16):
			if GameProgressManager.is_level_cleared(id):
				cleared_levels += 1
	elif act_num == 2:
		total_levels = 5
		is_act_unlocked = GameProgressManager.is_level_cleared(15) or _current_stage_idx >= 15
		for id in range(16, 21):
			if GameProgressManager.is_level_cleared(id):
				cleared_levels += 1
	elif act_num == 3:
		total_levels = 20
		is_act_unlocked = GameProgressManager.is_level_cleared(20) or _current_stage_idx >= 20
		for id in range(21, 41):
			if GameProgressManager.is_level_cleared(id):
				cleared_levels += 1
	var is_act_completed := (cleared_levels >= total_levels)
	return {
		"total": total_levels,
		"cleared": cleared_levels,
		"is_unlocked": is_act_unlocked,
		"is_completed": is_act_completed
	}


func _refresh_act_tabs(active_act: int) -> void:
	_view_act_num = active_act
	var p1 := _get_act_progress(1)
	var p2 := _get_act_progress(2)
	var p3 := _get_act_progress(3)

	_style_act_button(btn_act1, 1, active_act == 1, p1)
	_style_act_button(btn_act2, 2, active_act == 2, p2)
	_style_act_button(btn_act3, 3, active_act == 3, p3)

	var curr_prog := p1 if active_act == 1 else (p2 if active_act == 2 else p3)
	if act_progress_label:
		act_progress_label.text = "ACT %d · %d / %d LEVELS" % [active_act, curr_prog["cleared"], curr_prog["total"]]
		act_progress_label.add_theme_color_override("font_color", NAV_COLOR_SECONDARY)

	_update_act_header_tab(active_act, true)


func _update_act_header_tab(act_num: int, animate: bool = true) -> void:
	if not act_header_tab:
		return

	if act_num == _current_active_act:
		return

	_current_active_act = act_num

	var badge_text := ""
	var title_text := ""
	var desc_text := ""

	match act_num:
		1:
			badge_text = "ACT 1"
			title_text = "การใช้งาน Git เบื้องต้น"
			desc_text = "15 ด่าน"
		2:
			badge_text = "ACT 2"
			title_text = "การทำงานเป็นทีม / หอสมุดคลังเวทกลาง"
			desc_text = "5 ด่าน"
		3:
			badge_text = "ACT 3"
			title_text = "การแก้ปัญหาในการใช้งาน Git / หอคอยแห่งการฝึกตน"
			desc_text = "20 ด่าน"

	if act_badge:
		act_badge.text = badge_text
	if act_title:
		act_title.text = title_text
	if act_desc:
		act_desc.text = desc_text

	if _act_tab_tween and _act_tab_tween.is_valid():
		_act_tab_tween.kill()

	var target_top := 80.0
	var target_bottom := target_top + 38.0
	var start_top := 50.0
	var start_bottom := start_top + 38.0

	if animate:
		act_header_tab.offset_top = start_top
		act_header_tab.offset_bottom = start_bottom
		act_header_tab.modulate.a = 0.0
		_act_tab_tween = create_tween().set_parallel(true)
		_act_tab_tween.tween_property(act_header_tab, "offset_top", target_top, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_act_tab_tween.tween_property(act_header_tab, "offset_bottom", target_bottom, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_act_tab_tween.tween_property(act_header_tab, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		act_header_tab.offset_top = target_top
		act_header_tab.offset_bottom = target_bottom
		act_header_tab.modulate.a = 1.0


func _style_act_button(btn: Button, act_num: int, is_active: bool, prog: Dictionary) -> void:
	if not btn:
		return

	btn.custom_minimum_size = Vector2(96, 44)
	var text_base := "ACT %d" % act_num
	if prog["is_completed"]:
		btn.text = "%s ✓" % text_base
	else:
		btn.text = text_base

	var empty_sb := StyleBoxEmpty.new()
	empty_sb.content_margin_left = 0.0
	empty_sb.content_margin_right = 0.0
	empty_sb.content_margin_top = 0.0
	empty_sb.content_margin_bottom = 2.0

	if is_active:
		# Active Act: Antique gold text, subtle 2px bottom underline, flat transparent background
		var sb_active := StyleBoxFlat.new()
		sb_active.bg_color = Color(0, 0, 0, 0)
		sb_active.draw_center = false
		sb_active.border_width_left = 0
		sb_active.border_width_top = 0
		sb_active.border_width_right = 0
		sb_active.border_width_bottom = 2
		sb_active.border_color = NAV_COLOR_ACTIVE
		sb_active.content_margin_left = 0.0
		sb_active.content_margin_right = 0.0
		sb_active.content_margin_top = 0.0
		sb_active.content_margin_bottom = 2.0

		btn.add_theme_color_override("font_color", NAV_COLOR_ACTIVE)
		btn.add_theme_color_override("font_hover_color", NAV_COLOR_PRIMARY)
		btn.add_theme_color_override("font_pressed_color", NAV_COLOR_ACTIVE)
		btn.add_theme_color_override("font_focus_color", NAV_COLOR_ACTIVE)
		btn.add_theme_stylebox_override("normal", sb_active)
		btn.add_theme_stylebox_override("hover", sb_active)
		btn.add_theme_stylebox_override("pressed", sb_active)
		btn.add_theme_stylebox_override("focus", sb_active)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	elif prog["is_completed"]:
		# Completed Act: Muted sage green text, subtle checkmark, flat tab
		btn.add_theme_color_override("font_color", NAV_COLOR_COMPLETED)
		btn.add_theme_color_override("font_hover_color", NAV_COLOR_PRIMARY)
		btn.add_theme_color_override("font_pressed_color", NAV_COLOR_COMPLETED)
		btn.add_theme_color_override("font_focus_color", NAV_COLOR_COMPLETED)
		btn.add_theme_stylebox_override("normal", empty_sb)
		btn.add_theme_stylebox_override("hover", empty_sb)
		btn.add_theme_stylebox_override("pressed", empty_sb)
		btn.add_theme_stylebox_override("focus", empty_sb)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	elif not prog["is_unlocked"]:
		# Locked Act: Muted lavender-gray text, reduced visual emphasis
		btn.add_theme_color_override("font_color", NAV_COLOR_LOCKED)
		btn.add_theme_color_override("font_hover_color", NAV_COLOR_LOCKED)
		btn.add_theme_color_override("font_pressed_color", NAV_COLOR_LOCKED)
		btn.add_theme_color_override("font_focus_color", NAV_COLOR_LOCKED)
		btn.add_theme_stylebox_override("normal", empty_sb)
		btn.add_theme_stylebox_override("hover", empty_sb)
		btn.add_theme_stylebox_override("pressed", empty_sb)
		btn.add_theme_stylebox_override("focus", empty_sb)
		btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		# Unlocked, Inactive Act: Secondary muted text, clean flat tab
		btn.add_theme_color_override("font_color", NAV_COLOR_SECONDARY)
		btn.add_theme_color_override("font_hover_color", NAV_COLOR_PRIMARY)
		btn.add_theme_color_override("font_pressed_color", NAV_COLOR_SECONDARY)
		btn.add_theme_color_override("font_focus_color", NAV_COLOR_SECONDARY)
		btn.add_theme_stylebox_override("normal", empty_sb)
		btn.add_theme_stylebox_override("hover", empty_sb)
		btn.add_theme_stylebox_override("pressed", empty_sb)
		btn.add_theme_stylebox_override("focus", empty_sb)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _on_act_button_pressed(act_num: int) -> void:
	var prog := _get_act_progress(act_num)
	if not prog["is_unlocked"]:
		_play_sfx(sfx_click)
		if hud_desc:
			hud_desc.text = "🔒 ACT %d ยังถูกผนึก! ต้องผ่านบทก่อนหน้าเพื่อปลดล็อก" % act_num
		return

	_play_sfx(sfx_click)
	var center_offset := int(scroll_chamber.size.y * 0.5) if scroll_chamber and scroll_chamber.size.y > 0 else 540
	var target_y := 0
	if act_num == 1:
		target_y = int(TOWER_STAGES[0]["y"]) - center_offset
		_view_stage_idx = 0
	elif act_num == 2:
		target_y = 1475 - center_offset
		_view_stage_idx = 15
	else:
		target_y = 0
		_view_stage_idx = 20

	_scroll_to_y(target_y, true)
	_refresh_act_tabs(act_num)


func _on_continue_pressed() -> void:
	_play_sfx(sfx_click)
	var latest_unlocked_idx := 0
	for i in range(TOWER_STAGES.size()):
		var stg_id: int = TOWER_STAGES[i]["id"]
		var is_unlocked := (stg_id == 1) or GameProgressManager.is_level_cleared(stg_id - 1)
		if is_unlocked:
			latest_unlocked_idx = i
	_jump_to_stage(latest_unlocked_idx, true)


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
	_refresh_act_tabs(int(TOWER_STAGES[_current_stage_idx]["act"]))


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
		circle_rect.position = Vector2(880.0 - 220.0, 1475.0 - 220.0)
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
		var act_num: int = int(stg["act"])

		var p_width: float
		var plat_height: float
		var margin_h: int
		var margin_v: int
		var content_sep: int
		var badge_dim: float
		var num_font_sz: int
		var title_font_sz: int
		var cmd_font_sz: int
		var star_font_sz: int

		if act_num == 1:
			p_width = maxf(float(stg["width"]) * 1.35, 340.0)
			plat_height = PLAT_HEIGHT
			margin_h = 12
			margin_v = 6
			content_sep = 12
			badge_dim = 50.0
			num_font_sz = 20
			title_font_sz = 18
			cmd_font_sz = 15
			star_font_sz = 22
		elif act_num == 2:
			p_width = 260.0
			plat_height = PLAT_HEIGHT
			margin_h = 10
			margin_v = 6
			content_sep = 10
			badge_dim = 48.0
			num_font_sz = 19
			title_font_sz = 17
			cmd_font_sz = 14
			star_font_sz = 20
		else: # act_num == 3
			p_width = 250.0
			plat_height = 80.0
			margin_h = 10
			margin_v = 6
			content_sep = 10
			badge_dim = 46.0
			num_font_sz = 18
			title_font_sz = 16
			cmd_font_sz = 13
			star_font_sz = 18

		var p_x: float = stg["x"]
		var p_y: float = stg["y"]

		var plat := Control.new()
		plat.name = "Platform_%02d" % stg_id
		plat.size = Vector2(p_width, plat_height)
		plat.position = Vector2(p_x - (p_width / 2.0), p_y - (plat_height / 2.0))

		# ปุ่มแท่นหินศิลา (Gothic Stone Slab Button)
		var slab_btn := Button.new()
		slab_btn.name = "SlabBtn"
		slab_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		slab_btn.focus_mode = Control.FOCUS_NONE

		# 3. จัดวางองค์ประกอบภายในแท่นหิน
		var inner_margin := MarginContainer.new()
		inner_margin.name = "InnerMargin"
		inner_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner_margin.add_theme_constant_override("margin_left", margin_h)
		inner_margin.add_theme_constant_override("margin_right", margin_h)
		inner_margin.add_theme_constant_override("margin_top", margin_v)
		inner_margin.add_theme_constant_override("margin_bottom", margin_v)

		var hbox := HBoxContainer.new()
		hbox.name = "PlatformHBox"
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_theme_constant_override("separation", content_sep)
		hbox.set_anchors_preset(Control.PRESET_FULL_RECT)

		# 3.1 ป้ายเหรียญศิลาแสดงเลขด่าน (ฝั่งซ้าย)
		var num_badge := PanelContainer.new()
		num_badge.name = "NumBadge"
		num_badge.custom_minimum_size = Vector2(badge_dim, badge_dim)
		num_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		num_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var num_lbl := Label.new()
		num_lbl.name = "NumLabel"
		num_lbl.text = str(stg["no"])
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		if font_bungee:
			num_lbl.add_theme_font_override("font", font_bungee)
			num_lbl.add_theme_font_size_override("font_size", num_font_sz)
		elif font_ta_pixel:
			num_lbl.add_theme_font_override("font", font_ta_pixel)
			num_lbl.add_theme_font_size_override("font_size", num_font_sz - 2)
		num_badge.add_child(num_lbl)
		hbox.add_child(num_badge)

		# 3.2 ชื่อด่านและชิปคำสั่ง Git (ตรงกลาง)
		if p_width >= 180.0:
			var info_vbox := VBoxContainer.new()
			info_vbox.name = "InfoVBox"
			info_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			info_vbox.add_theme_constant_override("separation", 2 if act_num == 3 else 3)

			var title_lbl := Label.new()
			title_lbl.name = "TitleLabel"
			if act_num == 3:
				title_lbl.text = "ด่าน %s" % str(stg["no"])
			else:
				title_lbl.text = str(stg["title"])
			title_lbl.clip_text = true
			if font_chakra_bold:
				title_lbl.add_theme_font_override("font", font_chakra_bold)
				title_lbl.add_theme_font_size_override("font_size", title_font_sz + (2 if act_num == 3 else 0))
			info_vbox.add_child(title_lbl)

			if act_num != 3:
				var cmd_lbl := Label.new()
				cmd_lbl.name = "CmdLabel"
				cmd_lbl.text = str(stg["cmd"])
				cmd_lbl.clip_text = true
				if font_ta_pixel:
					cmd_lbl.add_theme_font_override("font", font_ta_pixel)
					cmd_lbl.add_theme_font_size_override("font_size", cmd_font_sz)
				info_vbox.add_child(cmd_lbl)

			hbox.add_child(info_vbox)

		# 3.3 ฝั่งขวา (ไอคอนล็อก หรือ ดาว)
		if not is_unlocked and tex_lock:
			var lock_rect := TextureRect.new()
			lock_rect.name = "LockRect"
			lock_rect.texture = tex_lock
			lock_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			lock_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var lock_size: float = 22.0 if act_num == 3 else 26.0
			lock_rect.custom_minimum_size = Vector2(lock_size, lock_size * 1.15)
			lock_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			lock_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hbox.add_child(lock_rect)
		elif is_cleared:
			var star_icon := Label.new()
			star_icon.name = "StarIcon"
			star_icon.text = "★★★"
			star_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			star_icon.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.02, 0.9))
			star_icon.add_theme_constant_override("outline_size", 2)
			if font_ta_pixel:
				star_icon.add_theme_font_override("font", font_ta_pixel)
			star_icon.add_theme_font_size_override("font_size", star_font_sz)
			hbox.add_child(star_icon)
		elif is_unlocked:
			var star_icon := Label.new()
			star_icon.name = "StarIcon"
			star_icon.text = "★★★"
			star_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			star_icon.add_theme_color_override("font_outline_color", Color(0.08, 0.10, 0.14, 0.9))
			star_icon.add_theme_constant_override("outline_size", 2)
			if font_ta_pixel:
				star_icon.add_theme_font_override("font", font_ta_pixel)
			star_icon.add_theme_font_size_override("font_size", star_font_sz)
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

		# ปรับแต่งสีและสไตล์ตามสถานะของด่าน
		_apply_platform_style(plat, stg_id, is_current)


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
	vel_hero.scale = Vector2(VEL_SCALE, VEL_SCALE)
	vel_hero.position = Vector2(stg["x"] - 24.0, stg["y"] - VEL_Y_OFFSET)


func _on_platform_selected(idx: int) -> void:
	if idx == _current_stage_idx and not _is_jumping:
		_on_launch_stage_pressed()
		return

	var target_stg: Dictionary = TOWER_STAGES[idx]
	var target_id: int = target_stg["id"]
	var is_unlocked: bool = (target_id == 1) or GameProgressManager.is_level_cleared(target_id - 1)
	if not is_unlocked:
		_on_locked_platform_clicked(idx)
		return

	var diff := absi(idx - _current_stage_idx)
	if diff > 1:
		_perform_direct_leap(idx)
	else:
		_try_navigate_stage(idx)


## กระโดดข้ามด่านระยะไกลรวดเดียว (Direct Leap) เมื่อคลิกข้ามหลายด่าน เช่น จาก 40 ลงมา 1
func _perform_direct_leap(to_idx: int) -> void:
	if to_idx < 0 or to_idx >= TOWER_STAGES.size() or to_idx == _current_stage_idx:
		return

	var target_stg: Dictionary = TOWER_STAGES[to_idx]
	var target_id: int = target_stg["id"]
	var is_unlocked: bool = (target_id == 1) or GameProgressManager.is_level_cleared(target_id - 1)
	if not is_unlocked:
		_on_locked_platform_clicked(to_idx)
		return

	if _jump_tween and _jump_tween.is_valid():
		_jump_tween.kill()

	_is_jumping = true
	_target_queue_idx = to_idx
	_buffered_dir = Vector2.ZERO
	_landing_seq_id += 1

	var from_idx := _current_stage_idx
	var from_stg: Dictionary = TOWER_STAGES[from_idx]
	var target_vel_pos := Vector2(target_stg["x"] - 24.0, target_stg["y"] - VEL_Y_OFFSET)
	var start_vel_pos := vel_hero.position if vel_hero else Vector2(from_stg["x"] - 24.0, from_stg["y"] - VEL_Y_OFFSET)

	var dx := target_vel_pos.x - start_vel_pos.x
	var dy := target_vel_pos.y - start_vel_pos.y
	var is_moving_right := dx >= 0.0

	# เลือกแอนิเมชันให้เหมาะสมกับการพุ่งทะยาน/ดิ่งลง
	if vel_anim:
		vel_anim.flip_h = not is_moving_right
		if dy > 300.0:
			# ตกลงมาจากหอคอยชั้นบนลงมาชั้นล่างระยะไกล (เช่น 40 ลงมา 1): ทำท่า hold ชูมือขึ้นตอนตกลงมา
			vel_anim.play("hold")
		else:
			# กระโดดพุ่งไปข้างหน้าหรือทะยานขึ้นหอคอย
			vel_anim.play("walk")

	_play_sfx(sfx_jump)

	var leap_duration: float = 0.75
	var scroll_duration: float = 0.70
	var peak_height: float = 120.0
	if dy > 600.0:
		peak_height = 60.0
	elif dy < -600.0:
		peak_height = 160.0

	_scroll_to_stage_idx(to_idx, true, false, scroll_duration)

	_jump_tween = create_tween()
	_jump_tween.tween_method(func(t: float):
		if not vel_hero:
			return
		var curr_x := lerpf(start_vel_pos.x, target_vel_pos.x, t)
		var base_y := lerpf(start_vel_pos.y, target_vel_pos.y, t)
		var arc_y := 4.0 * peak_height * t * (1.0 - t)
		vel_hero.position = Vector2(curr_x, base_y - arc_y)
	, 0.0, 1.0, leap_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_jump_tween.finished.connect(func():
		_update_platform_highlight(from_idx, false)
		_current_stage_idx = to_idx
		_target_queue_idx = to_idx
		_is_jumping = false
		_update_platform_highlight(_current_stage_idx, true)

		var landed_stg: Dictionary = TOWER_STAGES[_current_stage_idx]
		_update_hud_display(landed_stg)
		_highlight_act(int(landed_stg["act"]))
		if path_renderer:
			path_renderer.queue_redraw()

		_play_sfx(sfx_click)

		if vel_hero:
			vel_hero.position = target_vel_pos
			vel_hero.scale = Vector2(VEL_SCALE, VEL_SCALE)

		if _buffered_dir != Vector2.ZERO:
			var queued_dir := _buffered_dir
			_buffered_dir = Vector2.ZERO
			_navigate_directional(queued_dir)
			if not _is_jumping:
				_step_towards_queued_target()
		else:
			# หน่วงเวลา 0.28s ก่อนสลับเป็นท่ายืนตรงหายใจ เพื่อให้ถ้าผู้เล่นกดเดินต่อเนื่อง แอนิเมชันวิ่งจะไม่สะดุด
			_landing_seq_id += 1
			var my_seq := _landing_seq_id
			get_tree().create_timer(0.28).timeout.connect(func():
				if not _is_jumping and _landing_seq_id == my_seq:
					if vel_anim:
						vel_anim.play("breathe")
			)
	)


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
		# ถึงจุดหมายปลายทางแล้ว หรือหยุดเดิน
		_is_jumping = false
		_target_queue_idx = _current_stage_idx
		var curr_stg := TOWER_STAGES[_current_stage_idx]
		if vel_hero:
			vel_hero.position = Vector2(curr_stg["x"] - 24.0, curr_stg["y"] - VEL_Y_OFFSET)
			vel_hero.scale = Vector2(VEL_SCALE, VEL_SCALE)

		# รักษาแอนิเมชันวิ่งต่อเนื่อง (buffer 0.28s) ไม่สลับเป็นท่ายืนตรงหายใจทันที
		_landing_seq_id += 1
		var my_seq := _landing_seq_id
		get_tree().create_timer(0.28).timeout.connect(func():
			if not _is_jumping and _landing_seq_id == my_seq:
				if vel_anim:
					vel_anim.play("breathe")
		)
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
	_landing_seq_id += 1
	var from_idx := _current_stage_idx
	var to_idx := next_idx

	var from_stg_id: int = TOWER_STAGES[from_idx]["id"]
	var to_stg_id: int = TOWER_STAGES[to_idx]["id"]
	var is_between_15_and_16 := (from_stg_id == 15 and to_stg_id == 16) or (from_stg_id == 16 and to_stg_id == 15)

	var target_stg: Dictionary = TOWER_STAGES[to_idx]
	var target_vel_pos := Vector2(target_stg["x"] - 24.0, target_stg["y"] - VEL_Y_OFFSET)
	var start_vel_pos := vel_hero.position if vel_hero else target_vel_pos
	var is_moving_right := target_vel_pos.x >= start_vel_pos.x

	# เล่นแอนิเมชันตามเงื่อนไข
	if vel_anim:
		if is_between_15_and_16:
			vel_anim.flip_h = false
			if to_stg_id == 15:
				# ตอนระหว่าง 15-16 ถอยลงมาจาก 16 สู่ 15 -> ให้ท่า hold ชูมือขึ้นตอนตกลงมา
				vel_anim.play("hold")
			else:
				# ตอนระหว่าง 15-16 ไต่ขึ้นจาก 15 สู่ 16 -> ให้ท่าตัวยืนตรงปกติ
				vel_anim.play("stand_straight")
		else:
			# เดิน/กระโดดทั่วไป
			vel_anim.flip_h = not is_moving_right
			vel_anim.play("walk")

	_play_sfx(sfx_jump)

	var has_more_steps := (_target_queue_idx != to_idx and _target_queue_idx != -1)
	var jump_duration: float
	var peak_height: float
	var scroll_duration: float

	if is_between_15_and_16:
		jump_duration = 1.35
		scroll_duration = 1.30
		peak_height = 25.0 if to_stg_id == 15 else 45.0
	else:
		jump_duration = 0.42 if has_more_steps else 0.50
		scroll_duration = 0.48
		peak_height = 95.0

	_scroll_to_stage_idx(to_idx, true, false, scroll_duration)

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
	, 0.0, 1.0, jump_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_jump_tween.finished.connect(func():
		# ตัวละครลงสู่แท่นหินปลายทางเรียบร้อยแล้ว -> สลับการ์ดและอัปเดตสถานะเมื่อตัวละครไปถึง!
		_update_platform_highlight(from_idx, false)
		_current_stage_idx = to_idx
		_update_platform_highlight(_current_stage_idx, true)

		var landed_stg: Dictionary = TOWER_STAGES[_current_stage_idx]
		_update_hud_display(landed_stg)
		_highlight_act(int(landed_stg["act"]))
		if path_renderer:
			path_renderer.queue_redraw()

		_play_sfx(sfx_click)

		if _buffered_dir != Vector2.ZERO:
			_is_jumping = false
			var queued_dir := _buffered_dir
			_buffered_dir = Vector2.ZERO
			_navigate_directional(queued_dir)
			if not _is_jumping:
				_step_towards_queued_target()
		elif _target_queue_idx != _current_stage_idx and _target_queue_idx != -1:
			get_tree().create_timer(0.06).timeout.connect(_step_towards_queued_target)
		else:
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

		var target_vel_pos := Vector2(stg["x"] - 24.0, stg["y"] - VEL_Y_OFFSET)
		if vel_hero:
			vel_hero.position = target_vel_pos
			vel_hero.scale = Vector2(VEL_SCALE, VEL_SCALE)
		if vel_anim:
			vel_anim.play("breathe")
		_scroll_to_stage_idx(_current_stage_idx, false)
		return

	var diff := absi(target_idx - _current_stage_idx)
	if diff > 1:
		_perform_direct_leap(target_idx)
	else:
		_try_navigate_stage(target_idx)


func _get_stage_style_colors(stg_id: int, is_active: bool, is_cleared: bool, is_unlocked: bool) -> Dictionary:
	if is_active:
		# Current level: Glowing golden orange
		return {
			"bg_color": Color(0.18, 0.13, 0.08, 0.96),
			"border_color": Color(0.96, 0.62, 0.07, 1.0),
			"shadow_color": Color(0.96, 0.62, 0.04, 0.45),
			"shadow_size": 8,
			"hover_bg": Color(0.24, 0.18, 0.11, 0.98),
			"hover_border": Color(1.00, 0.78, 0.22, 1.0),
			"title_color": Color(0.98, 0.88, 0.47, 1.0),
			"cmd_color": Color(0.13, 0.83, 0.93, 0.95),
			"badge_bg": Color(0.28, 0.18, 0.08, 1.0),
			"badge_border": Color(0.96, 0.62, 0.07, 1.0),
			"badge_num_color": Color(0.98, 0.88, 0.47, 1.0),
			"lock_modulate": Color(0.80, 0.86, 0.94, 0.98),
			"star_color": Color(0.98, 0.82, 0.10, 1.0)
		}
	elif is_cleared:
		# Completed levels: Muted emerald green
		return {
			"bg_color": Color(0.08, 0.15, 0.11, 0.95),
			"border_color": Color(0.24, 0.50, 0.34, 1.0),
			"shadow_color": Color(0.0, 0.0, 0.0, 0.40),
			"shadow_size": 4,
			"hover_bg": Color(0.12, 0.22, 0.16, 0.98),
			"hover_border": Color(0.38, 0.70, 0.48, 1.0),
			"title_color": Color(0.84, 0.94, 0.88, 1.0),
			"cmd_color": Color(0.40, 0.82, 0.68, 0.90),
			"badge_bg": Color(0.11, 0.20, 0.15, 1.0),
			"badge_border": Color(0.28, 0.54, 0.38, 1.0),
			"badge_num_color": Color(0.80, 0.92, 0.84, 1.0),
			"lock_modulate": Color(0.80, 0.86, 0.94, 0.98),
			"star_color": Color(0.98, 0.82, 0.10, 1.0)
		}
	elif is_unlocked:
		# Available levels: Readable blue-gray
		return {
			"bg_color": Color(0.11, 0.14, 0.19, 0.96),
			"border_color": Color(0.36, 0.48, 0.64, 1.0),
			"shadow_color": Color(0.0, 0.0, 0.0, 0.35),
			"shadow_size": 3,
			"hover_bg": Color(0.16, 0.20, 0.27, 0.98),
			"hover_border": Color(0.55, 0.70, 0.90, 1.0),
			"title_color": Color(0.88, 0.93, 0.98, 1.0),
			"cmd_color": Color(0.22, 0.76, 0.94, 0.95),
			"badge_bg": Color(0.15, 0.20, 0.27, 1.0),
			"badge_border": Color(0.42, 0.54, 0.72, 1.0),
			"badge_num_color": Color(0.90, 0.95, 1.0, 1.0),
			"lock_modulate": Color(0.80, 0.86, 0.94, 0.98),
			"star_color": Color(0.48, 0.56, 0.66, 0.85)
		}
	else:
		# Locked levels: Dark desaturated blue-gray, clearly readable, metallic padlock
		return {
			"bg_color": Color(0.09, 0.11, 0.15, 0.94),
			"border_color": Color(0.22, 0.27, 0.36, 0.95),
			"shadow_color": Color(0.0, 0.0, 0.0, 0.25),
			"shadow_size": 2,
			"hover_bg": Color(0.13, 0.16, 0.21, 0.96),
			"hover_border": Color(0.32, 0.40, 0.52, 1.0),
			"title_color": Color(0.68, 0.75, 0.84, 0.95),
			"cmd_color": Color(0.44, 0.54, 0.66, 0.85),
			"badge_bg": Color(0.12, 0.15, 0.20, 1.0),
			"badge_border": Color(0.24, 0.30, 0.40, 0.90),
			"badge_num_color": Color(0.58, 0.66, 0.76, 0.95),
			"lock_modulate": Color(0.80, 0.86, 0.94, 0.98),
			"star_color": Color(0.35, 0.42, 0.50, 0.50)
		}


func _apply_platform_style(plat: Control, stg_id: int, is_active: bool) -> void:
	if not plat:
		return
	var slab_btn := plat.get_node_or_null("SlabBtn") as Button
	if not slab_btn:
		return

	var is_cleared := GameProgressManager.is_level_cleared(stg_id)
	var is_unlocked := (stg_id == 1) or GameProgressManager.is_level_cleared(stg_id - 1)
	var colors := _get_stage_style_colors(stg_id, is_active, is_cleared, is_unlocked)

	var sb_norm := StyleBoxFlat.new()
	sb_norm.corner_radius_top_left = 6
	sb_norm.corner_radius_top_right = 6
	sb_norm.corner_radius_bottom_left = 6
	sb_norm.corner_radius_bottom_right = 6
	sb_norm.border_width_left = 3
	sb_norm.border_width_top = 3
	sb_norm.border_width_right = 3
	sb_norm.border_width_bottom = 5
	sb_norm.bg_color = colors["bg_color"]
	sb_norm.border_color = colors["border_color"]
	sb_norm.shadow_color = colors["shadow_color"]
	sb_norm.shadow_size = colors["shadow_size"]

	var sb_hover := sb_norm.duplicate() as StyleBoxFlat
	sb_hover.bg_color = colors["hover_bg"]
	sb_hover.border_color = colors["hover_border"]

	var sb_pressed := sb_norm.duplicate() as StyleBoxFlat
	sb_pressed.border_width_top = 4
	sb_pressed.border_width_bottom = 2

	slab_btn.add_theme_stylebox_override("normal", sb_norm)
	slab_btn.add_theme_stylebox_override("hover", sb_hover)
	slab_btn.add_theme_stylebox_override("pressed", sb_pressed)
	slab_btn.add_theme_stylebox_override("focus", sb_norm)

	var num_badge := plat.find_child("NumBadge", true, false) as PanelContainer
	if num_badge:
		var sb_badge := StyleBoxFlat.new()
		sb_badge.bg_color = colors["badge_bg"]
		sb_badge.border_color = colors["badge_border"]
		sb_badge.border_width_left = 1
		sb_badge.border_width_top = 1
		sb_badge.border_width_right = 1
		sb_badge.border_width_bottom = 2
		sb_badge.corner_radius_top_left = 4
		sb_badge.corner_radius_top_right = 4
		sb_badge.corner_radius_bottom_left = 4
		sb_badge.corner_radius_bottom_right = 4
		num_badge.add_theme_stylebox_override("panel", sb_badge)

	var num_lbl := plat.find_child("NumLabel", true, false) as Label
	if num_lbl:
		num_lbl.add_theme_color_override("font_color", colors["badge_num_color"])

	var title_lbl := plat.find_child("TitleLabel", true, false) as Label
	if title_lbl:
		title_lbl.add_theme_color_override("font_color", colors["title_color"])

	var cmd_lbl := plat.find_child("CmdLabel", true, false) as Label
	if cmd_lbl:
		cmd_lbl.add_theme_color_override("font_color", colors["cmd_color"])

	var lock_rect := plat.find_child("LockRect", true, false) as TextureRect
	if lock_rect:
		lock_rect.modulate = colors["lock_modulate"]

	var star_icon := plat.find_child("StarIcon", true, false) as Label
	if star_icon:
		star_icon.add_theme_color_override("font_color", colors["star_color"])


func _update_platform_highlight(idx: int, is_active: bool) -> void:
	if idx < 0 or idx >= TOWER_STAGES.size():
		return
	var stg_id: int = TOWER_STAGES[idx]["id"]
	if _platform_nodes.has(stg_id):
		_apply_platform_style(_platform_nodes[stg_id], stg_id, is_active)


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


func _scroll_to_stage_idx(stage_idx: int, animate: bool = true, update_hud: bool = false, duration: float = 0.48) -> void:
	if not scroll_chamber or TOWER_STAGES.is_empty():
		return
	_view_stage_idx = clampi(stage_idx, 0, TOWER_STAGES.size() - 1)
	var stg: Dictionary = TOWER_STAGES[_view_stage_idx]
	if update_hud:
		_highlight_act(int(stg["act"]))
		_update_hud_display(stg)

	var center_offset := int(scroll_chamber.size.y * 0.5) if scroll_chamber and scroll_chamber.size.y > 0 else 540
	var target_y := int(stg["y"]) - center_offset
	_scroll_to_y(target_y, animate, duration)


func _sync_view_stage_with_scroll() -> void:
	if not scroll_chamber or TOWER_STAGES.is_empty():
		return
	var center_offset := float(scroll_chamber.size.y * 0.5) if scroll_chamber and scroll_chamber.size.y > 0 else 540.0
	var center_y := float(scroll_chamber.scroll_vertical) + center_offset
	var closest_idx := 0
	var min_dist := 999999.0
	for i in range(TOWER_STAGES.size()):
		var dist := absf(TOWER_STAGES[i]["y"] - center_y)
		if dist < min_dist:
			min_dist = dist
			closest_idx = i
	_view_stage_idx = closest_idx
	if _view_stage_idx >= 0 and _view_stage_idx < TOWER_STAGES.size():
		var current_act: int = int(TOWER_STAGES[_view_stage_idx]["act"])
		_refresh_act_tabs(current_act)


func _scroll_wheel_offset(delta_pixels: float) -> void:
	if not scroll_chamber:
		return
	var max_scroll := 4450
	if tower_content and scroll_chamber.size.y > 0:
		max_scroll = maxi(0, int(tower_content.custom_minimum_size.y - scroll_chamber.size.y))

	var current_base: float
	if _scroll_tween and _scroll_tween.is_valid() and _target_scroll_y >= 0.0:
		current_base = _target_scroll_y
	else:
		current_base = float(scroll_chamber.scroll_vertical)

	_target_scroll_y = clampf(current_base + delta_pixels, 0.0, float(max_scroll))

	if _scroll_tween and _scroll_tween.is_valid():
		_scroll_tween.kill()

	_scroll_tween = create_tween()
	_scroll_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_scroll_tween.tween_property(scroll_chamber, "scroll_vertical", int(_target_scroll_y), 0.20)
	_scroll_tween.finished.connect(func():
		_sync_view_stage_with_scroll()
	)


func _scroll_to_y(target_y: int, animate: bool = true, duration: float = 0.48) -> void:
	if not scroll_chamber:
		return
	var max_scroll := 4450
	if tower_content and scroll_chamber.size.y > 0:
		max_scroll = maxi(0, int(tower_content.custom_minimum_size.y - scroll_chamber.size.y))
	var clamped_y := clampi(target_y, 0, max_scroll)
	_target_scroll_y = float(clamped_y)

	if _scroll_tween and _scroll_tween.is_valid():
		_scroll_tween.kill()

	if animate:
		_scroll_tween = create_tween()
		_scroll_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_scroll_tween.tween_property(scroll_chamber, "scroll_vertical", clamped_y, duration)
		_scroll_tween.finished.connect(func():
			_sync_view_stage_with_scroll()
		)
	else:
		scroll_chamber.scroll_vertical = clamped_y
		_sync_view_stage_with_scroll()


func _on_draw_path() -> void:
	if not path_renderer:
		return
	var stages: Array[Dictionary] = TOWER_STAGES
	if stages.is_empty():
		return

	var draw_segment = func(idx_a: int, idx_b: int):
		if idx_a < 0 or idx_a >= stages.size() or idx_b < 0 or idx_b >= stages.size():
			return
		var s_a: Dictionary = stages[idx_a]
		var s_b: Dictionary = stages[idx_b]
		var id_b: int = int(s_b["id"])
		var id_a: int = int(s_a["id"])

		var is_cleared_b := GameProgressManager.is_level_cleared(id_b)
		var is_unlocked_b := (id_b == 1) or GameProgressManager.is_level_cleared(id_b - 1)
		var is_current_segment := (idx_b == _current_stage_idx) or (idx_a == _current_stage_idx and not is_cleared_b)

		var p1 := Vector2(s_a["x"], s_a["y"])
		var p2 := Vector2(s_b["x"], s_b["y"])

		if is_cleared_b:
			# 1. Completed Path: Muted emerald green with animated pulse glow
			var pulse := 0.22 + 0.14 * sin(_path_glow_timer * 2.8)
			var glow_col := Color(0.20, 0.75, 0.45, pulse)
			var core_col := Color(0.35, 0.78, 0.50, 0.95)
			_draw_curved_connection(p1, p2, glow_col, 5.0, 4.0)
			_draw_curved_connection(p1, p2, core_col, 2.5, 4.0)
		elif is_current_segment or is_unlocked_b:
			# 2. Current Path: Warm golden orange connecting to current level
			var pulse := 0.28 + 0.18 * sin(_path_glow_timer * 3.5)
			var glow_col := Color(0.96, 0.62, 0.04, pulse)
			var core_col := Color(0.96, 0.65, 0.15, 0.98)
			_draw_curved_connection(p1, p2, glow_col, 5.5, 4.0)
			_draw_curved_connection(p1, p2, core_col, 2.8, 4.0)
		else:
			# 3. Locked Path: Muted blue-gray, clearly visible but reduced brightness
			var locked_col := Color(0.24, 0.30, 0.40, 0.70)
			_draw_curved_connection(p1, p2, locked_col, 2.0, 4.0)

	# วาดเส้นทาง Act 1: บันไดวน (1 -> 15)
	for i in range(14):
		draw_segment.call(i, i + 1)

	# เชื่อม Act 1 -> Act 2 (15 -> 16)
	if stages.size() >= 16:
		draw_segment.call(14, 15)

	# วาดเส้นทาง Act 2: ลูปห้องทีม (16 -> 17 -> 18 -> 19 -> 20 -> 16)
	if stages.size() >= 20:
		var act2_indices: Array[int] = [15, 16, 17, 18, 19]
		for k in range(act2_indices.size()):
			var idx1: int = act2_indices[k]
			var idx2: int = act2_indices[(k + 1) % act2_indices.size()]
			draw_segment.call(idx1, idx2)

	# เชื่อม Act 2 -> Act 3 (20 -> 21)
	if stages.size() >= 21:
		draw_segment.call(19, 20)

	# วาดบันไดโกธิคสีเทาอ่อนฟ้าๆ 3 จุดเชื่อมระหว่างแถว Act 3 (Gothic Ladders)
	if stages.size() >= 40:
		_draw_gothic_ladder(1480.0, 840.0, 1000.0) # บันไดฝั่งขวา (25 -> 26)
		_draw_gothic_ladder(280.0, 600.0, 760.0)   # บันไดฝั่งซ้าย (30 -> 31)
		_draw_gothic_ladder(1480.0, 360.0, 520.0)  # บันไดฝั่งขวา (35 -> 36)

	# วาดเส้นทาง Act 3: ยอดหอคอยแบบบันไดวนคดเคี้ยวสลับซ้ายขวา (21 -> 40)
	if stages.size() >= 40:
		for k in range(20, 39):
			draw_segment.call(k, k + 1)


func _draw_gothic_ladder(cx: float, y_top: float, y_bottom: float) -> void:
	if not path_renderer:
		return
	var half_w := 24.0
	var rail_w := 5.0
	var col_shadow := Color(0.12, 0.16, 0.24, 0.90)     # Dark slate outline
	var col_main := Color(0.62, 0.72, 0.84, 0.95)       # Light slate-blue gray (เทาอ่อนฟ้าๆ)
	var col_highlight := Color(0.85, 0.92, 1.0, 0.98)   # Crisp light sky highlight

	var left_rail_x := cx - half_w
	var right_rail_x := cx + half_w - rail_w
	var ladder_h := y_bottom - y_top

	# 1. เสาราวบันไดซ้าย-ขวา (Vertical Rails)
	path_renderer.draw_rect(Rect2(left_rail_x - 1.0, y_top, rail_w + 2.0, ladder_h), col_shadow)
	path_renderer.draw_rect(Rect2(right_rail_x - 1.0, y_top, rail_w + 2.0, ladder_h), col_shadow)
	path_renderer.draw_rect(Rect2(left_rail_x, y_top, rail_w, ladder_h), col_main)
	path_renderer.draw_rect(Rect2(right_rail_x, y_top, rail_w, ladder_h), col_main)
	path_renderer.draw_line(Vector2(left_rail_x + 1.0, y_top), Vector2(left_rail_x + 1.0, y_bottom), col_highlight, 1.0)
	path_renderer.draw_line(Vector2(right_rail_x + 1.0, y_top), Vector2(right_rail_x + 1.0, y_bottom), col_highlight, 1.0)

	# 2. ขั้นบันไดแนวนอน (Horizontal Rungs) ห่างกันทุก 20px
	var rung_h := 4.0
	var curr_y := y_top + 16.0
	var rung_end_y := y_bottom - 12.0
	while curr_y <= rung_end_y:
		var rx1 := left_rail_x + rail_w
		var rx2 := right_rail_x
		var rw := rx2 - rx1
		path_renderer.draw_rect(Rect2(rx1, curr_y + 1.0, rw, rung_h), col_shadow)
		path_renderer.draw_rect(Rect2(rx1, curr_y, rw, rung_h), col_main)
		path_renderer.draw_line(Vector2(rx1, curr_y), Vector2(rx2, curr_y), col_highlight, 1.0)
		curr_y += 20.0


func _draw_curved_connection(p1: Vector2, p2: Vector2, color: Color, line_width: float = 2.5, dash_len: float = 4.0) -> void:
	if not path_renderer:
		return

	# ถ้าเป็นเส้นตรงแนวตั้งตามบันได หรือแนวนอนระหว่างด่านในแถวเดียวกัน
	if absf(p1.x - p2.x) < 2.0 or absf(p1.y - p2.y) < 2.0:
		path_renderer.draw_line(p1, p2, color, line_width)
		return

	var steps := 16
	var prev_pt := p1
	var mid_y := (p1.y + p2.y) / 2.0

	var c1_x := p1.x
	var c2_x := p2.x

	# เลี้ยวโค้งวนกลับตามผนังหอคอย
	if p1.x > 1070.0 and p2.x > 1070.0:
		c1_x = maxf(p1.x, p2.x) + 30.0
		c2_x = maxf(p1.x, p2.x) + 30.0
	elif p1.x < 670.0 and p2.x < 670.0:
		c1_x = minf(p1.x, p2.x) - 30.0
		c2_x = minf(p1.x, p2.x) - 30.0
	elif absf(p1.y - p2.y) < 30.0:
		mid_y = p1.y + 12.0

	var c1 := Vector2(c1_x, mid_y)
	var c2 := Vector2(c2_x, mid_y)

	for s in range(1, steps + 1):
		var t := float(s) / float(steps)
		var pt := _bezier_interpolate(p1, c1, c2, p2, t)
		path_renderer.draw_line(prev_pt, pt, color, line_width)
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


func _navigate_directional(dir: Vector2) -> void:
	# ถ้ากำลังกระโดดอยู่ ให้จดจำทิศทางที่กดไว้ (Input Buffer) เพื่อให้ก้าวต่อไปทันทีที่เท้าแตะแท่นหิน
	if _is_jumping:
		_buffered_dir = dir
		return

	var base_idx := _current_stage_idx
	if base_idx < 0 or base_idx >= TOWER_STAGES.size():
		return

	var curr_stg: Dictionary = TOWER_STAGES[base_idx]
	var target_idx := -1

	if dir == Vector2.UP:
		# ลูกศรขึ้น หรือ W: ก้าวขึ้นหอคอยไปด่านถัดไปทีละ 1 ด่านเสมอ
		target_idx = base_idx + 1
	elif dir == Vector2.DOWN:
		# ลูกศรลง หรือ S: ถอยลงหอคอยไปด่านก่อนหน้าทีละ 1 ด่านเสมอ (ไม่ข้ามด่าน)
		target_idx = base_idx - 1
	elif dir == Vector2.RIGHT:
		# ลูกศรขวา หรือ D: ก้าวไปข้างหน้าตามเส้นทางหรือแท่นทางขวา
		if base_idx + 1 < TOWER_STAGES.size() and TOWER_STAGES[base_idx + 1]["x"] > curr_stg["x"]:
			target_idx = base_idx + 1
		elif base_idx - 1 >= 0 and TOWER_STAGES[base_idx - 1]["x"] > curr_stg["x"]:
			target_idx = base_idx - 1
		else:
			target_idx = base_idx + 1
	elif dir == Vector2.LEFT:
		# ลูกศรซ้าย หรือ A: ถอยหลังตามเส้นทางหรือแท่นทางซ้าย
		if base_idx - 1 >= 0 and TOWER_STAGES[base_idx - 1]["x"] < curr_stg["x"]:
			target_idx = base_idx - 1
		elif base_idx + 1 < TOWER_STAGES.size() and TOWER_STAGES[base_idx + 1]["x"] < curr_stg["x"]:
			target_idx = base_idx + 1
		else:
			target_idx = base_idx - 1

	if target_idx >= 0 and target_idx < TOWER_STAGES.size() and target_idx != base_idx:
		_try_navigate_stage(target_idx)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var factor: float = event.factor if event.factor > 0.0 else 1.0
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			get_viewport().set_input_as_handled()
			_scroll_wheel_offset(-240.0 * factor)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			get_viewport().set_input_as_handled()
			_scroll_wheel_offset(240.0 * factor)
	elif event is InputEventKey and event.pressed:
		var is_nav_key: bool = (
			event.keycode == KEY_UP or event.keycode == KEY_W or
			event.keycode == KEY_DOWN or event.keycode == KEY_S or
			event.keycode == KEY_LEFT or event.keycode == KEY_A or
			event.keycode == KEY_RIGHT or event.keycode == KEY_D
		)
		if not event.echo or is_nav_key:
			if event.keycode == KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				_on_back_pressed()
			elif event.keycode == KEY_PAGEUP:
				get_viewport().set_input_as_handled()
				_scroll_wheel_offset(-600.0)
			elif event.keycode == KEY_PAGEDOWN:
				get_viewport().set_input_as_handled()
				_scroll_wheel_offset(600.0)
			elif event.keycode == KEY_UP or event.keycode == KEY_W:
				get_viewport().set_input_as_handled()
				_navigate_directional(Vector2.UP)
			elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
				get_viewport().set_input_as_handled()
				_navigate_directional(Vector2.DOWN)
			elif event.keycode == KEY_LEFT or event.keycode == KEY_A:
				get_viewport().set_input_as_handled()
				_navigate_directional(Vector2.LEFT)
			elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
				get_viewport().set_input_as_handled()
				_navigate_directional(Vector2.RIGHT)
			elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
				if not event.echo:
					get_viewport().set_input_as_handled()
					_on_launch_stage_pressed()
			elif event.keycode == KEY_1:
				if not event.echo:
					get_viewport().set_input_as_handled()
					_on_act_button_pressed(1)
			elif event.keycode == KEY_2:
				if not event.echo:
					get_viewport().set_input_as_handled()
					_on_act_button_pressed(2)
			elif event.keycode == KEY_3:
				if not event.echo:
					get_viewport().set_input_as_handled()
					_on_act_button_pressed(3)
