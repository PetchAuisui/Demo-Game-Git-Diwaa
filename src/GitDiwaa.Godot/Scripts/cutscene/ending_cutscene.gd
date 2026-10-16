extends Sprite2D

## การควบคุม Cutscene ฉากจบ (Ending Cutscene - Reverse Concept)
## ลำดับเหตุการณ์:
## 1. เวลยืนมองเศษคัมภีร์ทั้ง 16 ชิ้นที่กระจายอยู่รอบห้อง (แสงห้องสลัว)
## 2. เศษคัมภีร์เรืองแสงสีทอง และลอยพุ่งกลับมารวมกันที่จุดศูนย์กลาง (Reverse Shatter)
## 3. ผสานเป็น "คัมภีร์เวทต้นกำเนิด" (Khampri) สมบูรณ์ ส่องแสงเจิดจ้า
## 4. เกิด White Flash วาร์ปเวลและคัมภีร์กลับสู่ห้องสมุดเริ่มต้น
## 5. หลุมดำเปิดขึ้นกลางห้อง และร่างของอาจารย์ดีดตัวพุ่งพรวดขึ้นมาจากหลุมดำ (Reverse Drop)
## 6. อาจารย์ทำหน้าช็อกและสับสน หลุมดำปิดลง อาจารย์หันมามองเวลด้วยสายตาใสซื่อ
## 7. MagicStoryUI ปรากฏ พร้อมระบบบทสนทนาเล่าความจริงสุดโก๊ะของอาจารย์ (5 หน้า)
## 8. จบฉากด้วยหน้าต่าง THE END และปุ่มกลับสู่หน้าหลัก (StartView)

@export var start_scene_path: String = "res://scenes/StartView.tscn"

@onready var room_lighting: CanvasModulate = $RoomLighting
@onready var flash_overlay: ColorRect = $FlashOverlay
@onready var black_hole: Sprite2D = $BlackHole
@onready var khampri: Sprite2D = $Khampri
@onready var khampri_shadow: Sprite2D = $KhampriShadow
@onready var shards_container: Node2D = $Shards
@onready var vel: AnimatedSprite2D = $Vel
@onready var master_char: AnimatedSprite2D = $Master
@onready var exclamation_mark: Sprite2D = $Vel/ExclamationMark

# UI Nodes
@onready var magic_ui: CanvasLayer = $MagicStoryUI
@onready var backdrop: ColorRect = $MagicStoryUI/Backdrop
@onready var parchment_shadow: TextureRect = $MagicStoryUI/ParchmentShadow
@onready var parchment_frame: TextureRect = $MagicStoryUI/ParchmentFrame
@onready var dialogue_container: Control = $MagicStoryUI/DialogueContainer
@onready var speaker_label: Label = $MagicStoryUI/DialogueContainer/SpeakerLabel
@onready var speaker_aura_label: Label = $MagicStoryUI/DialogueContainer/SpeakerAuraLabel
@onready var dialogue_aura_label: RichTextLabel = $MagicStoryUI/DialogueContainer/DialogueAuraLabel
@onready var dialogue_rich_label: RichTextLabel = $MagicStoryUI/DialogueContainer/DialogueRichLabel
@onready var continue_prompt: Label = $MagicStoryUI/DialogueContainer/ContinuePrompt
@onready var page_indicator: Label = $MagicStoryUI/DialogueContainer/PageIndicator

# The End Screen
@onready var the_end_container: Control = $MagicStoryUI/TheEndContainer
@onready var the_end_title: Label = $MagicStoryUI/TheEndContainer/TitleLabel
@onready var the_end_subtitle: Label = $MagicStoryUI/TheEndContainer/SubtitleLabel
@onready var return_menu_btn: Button = $MagicStoryUI/TheEndContainer/ReturnMenuBtn

# Audio Players
@onready var sfx_fusion: AudioStreamPlayer = $Audio/SfxFusion
@onready var sfx_warp: AudioStreamPlayer = $Audio/SfxWarp
@onready var sfx_pop: AudioStreamPlayer = $Audio/SfxPop
@onready var sfx_next: AudioStreamPlayer = $Audio/SfxNext
@onready var sfx_success: AudioStreamPlayer = $Audio/SfxSuccess

var shards: Array[Sprite2D] = []
var is_in_dialogue: bool = false
var current_slide_index: int = 0
var is_fast_forwarding: bool = false
var can_fast_forward: bool = true
var tw_ex_bob: Tween = null
var tw_khampri_glow: Tween = null

# โทนสีฟิลเตอร์คัมภีร์และเศษ
const BOOK_TINT: Color = Color(0.70, 0.63, 0.55, 1.0)
const GOLD_GLOW: Color = Color(2.0, 1.85, 1.25, 1.0)

# พิกัดเดิมที่เศษทั้ง 16 ชิ้นกระจายตกอยู่ (เหมือนใน Intro)
const SHARD_LANDING_POSITIONS: Array[Vector2] = [
	Vector2(40.0, 92.0),
	Vector2(54.0, 95.0),
	Vector2(72.0, 97.0),
	Vector2(84.0, 94.0),
	Vector2(76.0, 102.0),
	Vector2(50.0, 100.0),
	Vector2(59.0, 91.0),
	Vector2(106.0, 90.0),
	Vector2(98.0, 79.0),
	Vector2(102.0, 105.0),
	Vector2(32.0, 94.0),
	Vector2(44.0, 104.0),
	Vector2(18.0, 88.0),
	Vector2(88.0, 98.0),
	Vector2(26.0, 102.0),
	Vector2(65.0, 98.0),
]

# เนื้อหาบทสนทนาและคำบรรยายฉากจบ 5 หน้า
const DIALOGUE_SLIDES: Array[Dictionary] = [
	{
		"speaker": "ปรมาจารย์",
		"speaker_color": Color(0.95, 0.85, 0.45, 1.0),
		"text": "[center][wave amp=12.0 freq=2.0 connected=1]\"อ้าว เวล... เกิดอะไรขึ้นเนี่ย?\nแล้วทำไมเจ้าถึงดูเหนื่อยมอมแมมขนาดนั้นล่ะ?\"[/wave][/center]"
	},
	{
		"speaker": "ความจริงเบื้องหลังการหายตัวไป",
		"speaker_color": Color(0.75, 0.85, 1.0, 1.0),
		"text": "[center]แท้จริงแล้ว... ปรมาจารย์ไม่ได้ถูกพลังมืดลักพาตัวไปไหนเลย!\nแต่เป็นเพราะความแก่ชราและอาการหลงลืม\nทำให้พลังเวทในตัวเกิดอาการ [color=#ffdd77]'ตกหล่น'[/color] รั่วไหลออกมา\nจนกลายเป็นหลุมดำเวทมนตร์ขึ้นมาเองที่พื้น...\nแล้วท่านก็พลัดตกลงไปในหลุมของตัวเอง![/center]"
	},
	{
		"speaker": "ปริศนาคัมภีร์แตกกระจาย",
		"speaker_color": Color(1.0, 0.75, 0.75, 1.0),
		"text": "[center]และในจังหวะที่ร่วงหล่นด้วยความเร็วสูง\nอาจารย์ดันตกใจจนเผลอปล่อยมือจาก [color=#ffe880]\"คัมภีร์เวทต้นกำเนิด\"[/color]\nซ้ำร้าย หลุมดำดันปิดตัวลงก่อนที่คัมภีร์จะตกลงไป\nคัมภีร์จึงร่วงกระแทกพื้นจนแตกกระจายเป็น 16 ชิ้น!\nก่อนที่หลุมดำจะเปิดออกอีกรอบแล้วดูดกลืนเศษทั้งหมดตามลงไป...[/center]"
	},
	{
		"speaker": "ความในใจของเวล",
		"speaker_color": Color(0.85, 0.95, 0.75, 1.0),
		"text": "[center]เวลได้แต่ถอนหายใจยาว ๆ...\nสรุปว่าวิกฤตการณ์ระดับอาณาจักร การผจญภัยสุดยิ่งใหญ่\nและการฝึกฝนคาถาเวทมนตร์อันแสนซับซ้อน\nทั้งหมดนี้เกิดขึ้นเพราะความโก๊ะและหลงลืมของอาจารย์ล้วน ๆ![/center]"
	},
	{
		"speaker": "บทส่งท้าย (Epilogue)",
		"speaker_color": Color(1.0, 0.9, 0.45, 1.0),
		"text": "[center][rainbow freq=0.5 sat=0.7 val=0.95]แต่อย่างน้อยที่สุด...[/rainbow]\nวิกฤตครั้งนี้ก็ได้พิสูจน์แล้วว่า\nศิษย์ฝึกหัดผู้ไร้ประสบการณ์ในวันนั้น\nได้เติบโตเป็น [color=#ffe880][b]มหาจอมเวท[/b][/color] ผู้กอบกู้สมดุลแห่งเวทมนตร์\nและพร้อมสืบทอดเจตนารมณ์ของอาจารย์ได้อย่างสมบูรณ์แบบ[/center]"
	}
]

func _ready() -> void:
	Engine.time_scale = 1.0
	
	# เพิ่มปุ่มข้าม cutscene (เชื่อมต่อกลับไป StartView)
	var skip_btn = preload("res://scripts/cutscene/skip_cutscene_button.gd").new()
	skip_btn.next_scene_path = start_scene_path
	add_child(skip_btn)
	
	_init_shards()
	_reset_scene_state()
	
	if return_menu_btn:
		return_menu_btn.pressed.connect(_on_return_menu_pressed)
	
	play_ending_sequence()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _process(_delta: float) -> void:
	# Fast-forward ด้วยการกด Space/Enter/Shift/Click ค้างช่วงก่อนเข้าอ่านบทสนทนา
	if can_fast_forward and not is_in_dialogue:
		var wants_ff: bool = Input.is_key_pressed(KEY_SPACE) or \
			Input.is_key_pressed(KEY_ENTER) or \
			Input.is_key_pressed(KEY_SHIFT) or \
			Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		
		if wants_ff != is_fast_forwarding:
			is_fast_forwarding = wants_ff
			Engine.time_scale = 2.5 if wants_ff else 1.0

func _input(event: InputEvent) -> void:
	if not is_in_dialogue:
		return
	
	# กด Space / Enter / คลิก เพื่อเปลี่ยนหน้าบทสนทนา
	if event.is_action_pressed("ui_accept") or \
	   (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)) or \
	   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
		_advance_dialogue()

func _init_shards() -> void:
	shards.clear()
	if shards_container:
		for child in shards_container.get_children():
			if child is Sprite2D and shards.size() < 16:
				shards.append(child)

func _reset_scene_state() -> void:
	is_in_dialogue = false
	current_slide_index = 0
	can_fast_forward = true
	is_fast_forwarding = false
	Engine.time_scale = 1.0
	
	position = Vector2(960, 540)
	
	# เริ่มต้นด้วยแสงสลัวสร้างความขลังในพิธีกรรมผสานคัมภีร์
	if room_lighting:
		room_lighting.color = Color(0.35, 0.35, 0.45, 1.0)
	
	if flash_overlay:
		flash_overlay.color = Color(1, 1, 1, 0.0)
		flash_overlay.visible = true
	
	# เวลยืนฝั่งซ้าย หันขวา พร้อมเริ่มพิธีกรรม
	if vel:
		vel.visible = true
		vel.position = Vector2(-40, 59)
		vel.scale = Vector2.ONE
		vel.flip_h = false
		vel.play("breathe_blink")
	
	if exclamation_mark:
		exclamation_mark.visible = false
		exclamation_mark.scale = Vector2.ZERO
		exclamation_mark.position = Vector2(0, -56)
	
	# อาจารย์ซ่อนตัวอยู่ใต้หลุมดำ
	if master_char:
		master_char.visible = false
		master_char.position = Vector2(40, 97)
		master_char.scale = Vector2(0.1, 0.1)
		master_char.modulate = Color(0.1, 0.05, 0.2, 0.0)
		master_char.flip_h = false
	
	if black_hole:
		black_hole.visible = false
		black_hole.position = Vector2(40, 96)
		black_hole.scale = Vector2.ZERO
	
	# คัมภีร์ยังไม่ปรากฏ (จะรวมจากเศษ 16 ชิ้น)
	if khampri:
		khampri.visible = false
		khampri.position = Vector2(64, 79)
		khampri.scale = Vector2(0.1, 0.1)
		khampri.rotation = 0.0
		khampri.modulate = BOOK_TINT
	
	if khampri_shadow:
		khampri_shadow.visible = false
		khampri_shadow.position = Vector2(64, 98)
		khampri_shadow.scale = Vector2(1.1, 0.7)
		khampri_shadow.modulate = Color(1, 1, 1, 0.0)
	
	# วางเศษทั้ง 16 ชิ้นกระจายตามจุดตกเดิม
	for i in range(shards.size()):
		var s: Sprite2D = shards[i]
		var landing_pos: Vector2 = SHARD_LANDING_POSITIONS[i] if i < SHARD_LANDING_POSITIONS.size() else Vector2(64, 96)
		s.visible = true
		s.position = landing_pos
		s.scale = Vector2(0.2, 0.2)
		s.modulate = BOOK_TINT
		s.rotation = 0.0
	
	# UI ซ่อนไว้ก่อน
	if backdrop:
		backdrop.color = Color(0, 0, 0, 0)
	if parchment_shadow:
		parchment_shadow.modulate = Color(0, 0, 0, 0)
	if parchment_frame:
		parchment_frame.modulate = Color(1, 1, 1, 0)
	if dialogue_container:
		dialogue_container.scale = Vector2(0.01, 0.01)
		dialogue_container.modulate = Color(1, 1, 1, 0)
	if the_end_container:
		the_end_container.visible = false
		the_end_container.modulate = Color(1, 1, 1, 0)

## เริ่มต้นไทม์ไลน์ฉากจบแบบ Reverse
func play_ending_sequence() -> void:
	# -------------------------------------------------------------
	# องก์ 1: การผสานเศษคัมภีร์ (Reverse Shatter & Fusion) (0.0s -> 4.5s)
	# -------------------------------------------------------------
	var origin_merge: Vector2 = Vector2(64, 79)
	
	# 1.1 เศษคัมภีร์ทั้ง 16 ชิ้น ค่อย ๆ เรืองแสงสีทองและลอยขึ้น (0.5s -> 1.5s)
	for i in range(shards.size()):
		var s: Sprite2D = shards[i]
		var tw_glow = create_tween().set_parallel(true)
		tw_glow.tween_property(s, "modulate", GOLD_GLOW, 1.0).set_trans(Tween.TRANS_SINE)
		tw_glow.tween_property(s, "position:y", s.position.y - 12.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 1.2 เศษคัมภีร์ทั้ง 16 ชิ้น หมุนวนพุ่งเข้าสู่จุดศูนย์กลางพร้อมกัน (Reverse Shatter) (1.8s -> 2.6s)
	var tw_converge = create_tween()
	tw_converge.tween_interval(1.8)
	tw_converge.tween_callback(func():
		_play_sfx(sfx_fusion)
		for i in range(shards.size()):
			var s: Sprite2D = shards[i]
			var delay: float = randf_range(0.0, 0.25)
			var duration: float = randf_range(0.65, 0.85)
			var tw_shard = create_tween()
			if delay > 0.0:
				tw_shard.tween_interval(delay)
			tw_shard.tween_callback(func():
				if not is_instance_valid(s):
					return
				var tw_move = create_tween().set_parallel(true)
				tw_move.tween_property(s, "position", origin_merge, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				tw_move.tween_property(s, "scale", Vector2(0.05, 0.05), duration)
				tw_move.tween_property(s, "rotation", randf_range(-PI, PI), duration)
				tw_move.chain().tween_callback(func(): s.visible = false)
			)
	)
	
	# 1.3 รวมตัวกลายเป็นคัมภีร์สมบูรณ์ (2.8s)
	var tw_rebuild = create_tween()
	tw_rebuild.tween_interval(2.8)
	tw_rebuild.tween_callback(func():
		_play_sfx(sfx_success)
		khampri.visible = true
		khampri.position = origin_merge
		khampri.scale = Vector2(0.05, 0.05)
		khampri.rotation = 0.0
		khampri.modulate = Color(3.0, 2.5, 1.5, 1.0)
		
		# ขยายตัวเด้งคืนสภาพสมบูรณ์
		var tw_pop = create_tween().set_parallel(true)
		tw_pop.tween_property(khampri, "scale", Vector2(0.24, 0.24), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_pop.tween_property(khampri, "modulate", Color(1.6, 1.4, 1.1, 1.0), 0.5)
		tw_pop.chain().tween_property(khampri, "scale", Vector2(0.20, 0.20), 0.25)
		
		if khampri_shadow:
			khampri_shadow.visible = true
			khampri_shadow.position = Vector2(origin_merge.x, 98)
			var tw_ks = create_tween()
			tw_ks.tween_property(khampri_shadow, "modulate:a", 0.6, 0.6)
	)
	
	# -------------------------------------------------------------
	# องก์ 2: White Flash & วาร์ปกลับห้องสมุด (3.8s -> 5.0s)
	# -------------------------------------------------------------
	var tw_flash = create_tween()
	tw_flash.tween_interval(3.8)
	tw_flash.tween_callback(func():
		_play_sfx(sfx_warp)
		# แสงสีขาวสว่างวาบไปทั่วบริเวณ (0.3s)
		var tw_f = create_tween()
		tw_f.tween_property(flash_overlay, "color:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_f.tween_callback(func():
			# คืนค่าแสงห้องสมุดให้สว่างสมบูรณ์
			room_lighting.color = Color(1.0, 1.0, 1.0, 1.0)
			
			# ย้ายคัมภีร์มาลอยสงบอยู่ข้างตัวเวล
			khampri.position = Vector2(-15, 62)
			khampri.scale = Vector2(0.18, 0.18)
			khampri.modulate = Color(1.3, 1.2, 1.0, 1.0)
			if khampri_shadow:
				khampri_shadow.position = Vector2(-15, 98)
				khampri_shadow.scale = Vector2(0.8, 0.4)
			
			# ลูปแสงกระพริบเรืองรองเบา ๆ บนคัมภีร์
			tw_khampri_glow = create_tween().set_loops()
			tw_khampri_glow.tween_property(khampri, "modulate", Color(1.5, 1.35, 1.1, 1.0), 0.8).set_trans(Tween.TRANS_SINE)
			tw_khampri_glow.tween_property(khampri, "modulate", Color(1.1, 1.05, 0.95, 1.0), 0.8).set_trans(Tween.TRANS_SINE)
		)
		# แสงสีขาวค่อย ๆ จางหายไป เผยให้เห็นห้องสมุด (0.8s)
		tw_f.tween_property(flash_overlay, "color:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	)
	
	# -------------------------------------------------------------
	# องก์ 3: หลุมดำเปิด & อาจารย์พุ่งโผล่พรวดขึ้นมา! (5.2s -> 7.0s)
	# -------------------------------------------------------------
	var tw_black_hole = create_tween()
	tw_black_hole.tween_interval(5.2)
	tw_black_hole.tween_callback(func():
		# 3.1 หลุมดำเปิดขึ้นที่พื้นตำแหน่งเดิม
		black_hole.visible = true
		black_hole.scale = Vector2.ZERO
		var tw_bh = create_tween()
		tw_bh.tween_property(black_hole, "scale", Vector2(1.2, 1.0), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	
	# 3.2 อาจารย์พุ่งโผล่ขึ้นมาจากหลุมดำ (Reverse Drop) (5.8s)
	var tw_master_pop = create_tween()
	tw_master_pop.tween_interval(5.8)
	tw_master_pop.tween_callback(func():
		_play_sfx(sfx_pop)
		master_char.visible = true
		master_char.position = Vector2(40, 97)
		master_char.scale = Vector2(0.1, 0.1)
		master_char.modulate = Color(0.1, 0.05, 0.2, 0.0)
		master_char.play("shock1")
		
		# พุ่งลอยตัวขึ้นสู่ความสูง 38px แล้วแลนดิ้งลงยืนที่ 59px (Reverse จากตอนจม)
		var tw_launch = create_tween().set_parallel(true)
		tw_launch.tween_property(master_char, "position:y", 38.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_launch.tween_property(master_char, "scale", Vector2(1.1, 1.1), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_launch.tween_property(master_char, "modulate", Color(1, 1, 1, 1), 0.25)
		
		tw_launch.chain().set_parallel(true)
		tw_launch.tween_property(master_char, "position:y", 59.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_launch.tween_property(master_char, "scale", Vector2(1.0, 1.0), 0.25)
		
		# หลุมดำหดตัวปิดทันทีหลังอาจารย์โผล่พ้น
		var tw_bh_close = create_tween()
		tw_bh_close.tween_property(black_hole, "scale", Vector2.ZERO, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_bh_close.tween_callback(func(): black_hole.visible = false)
		
		# เวลตกใจสะดุ้งเมื่อเห็นอาจารย์พุ่งขึ้นมา
		vel.play("shock")
		exclamation_mark.visible = true
		exclamation_mark.scale = Vector2.ZERO
		var tw_ex = create_tween()
		tw_ex.tween_property(exclamation_mark, "scale", Vector2(1.3, 1.3), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_ex.tween_property(exclamation_mark, "scale", Vector2(1.0, 1.0), 0.1)
	)
	
	# 3.3 อาจารย์หันมองเวลด้วยความใสซื่อ (6.8s)
	var tw_master_look = create_tween()
	tw_master_look.tween_interval(6.8)
	tw_master_look.tween_callback(func():
		master_char.flip_h = false
		master_char.play("breathe_blink")
		vel.play("breathe_blink")
	)
	
	# -------------------------------------------------------------
	# องก์ 4: เริ่มแสดงกล่องบทสนทนาและเฉลยความจริง (7.6s)
	# -------------------------------------------------------------
	var tw_dialogue_start = create_tween()
	tw_dialogue_start.tween_interval(7.6)
	tw_dialogue_start.tween_callback(_start_dialogue_sequence)

## เริ่มต้นระบบบทสนทนา MagicStoryUI
func _start_dialogue_sequence() -> void:
	is_in_dialogue = true
	can_fast_forward = false
	is_fast_forwarding = false
	Engine.time_scale = 1.0
	current_slide_index = 0
	
	# แสดงพื้นหลังความมืดและกรอบกระดาษ
	var tw_ui = create_tween().set_parallel(true)
	tw_ui.tween_property(backdrop, "color", Color(0, 0, 0, 0.85), 0.45)
	tw_ui.tween_property(parchment_frame, "modulate", Color(1, 1, 1, 1.0), 0.45)
	if parchment_shadow:
		tw_ui.tween_property(parchment_shadow, "modulate", Color(0, 0, 0, 0.55), 0.45)
	
	# กรอบข้อความเด้งขึ้นมา
	dialogue_container.scale = Vector2(0.2, 0.2)
	dialogue_container.modulate = Color(1, 1, 1, 0)
	var tw_pop = create_tween().set_parallel(true)
	tw_pop.tween_property(dialogue_container, "scale", Vector2(1.0, 1.0), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_pop.tween_property(dialogue_container, "modulate", Color(1, 1, 1, 1), 0.35)
	
	_show_slide(current_slide_index)

## แสดงสไลด์ตามลำดับ index
func _show_slide(index: int) -> void:
	if index < 0 or index >= DIALOGUE_SLIDES.size():
		return
	
	var slide: Dictionary = DIALOGUE_SLIDES[index]
	var speaker_text: String = slide["speaker"]
	var content_text: String = slide["text"]
	var spk_color: Color = slide["speaker_color"]
	
	speaker_label.text = speaker_text
	speaker_label.modulate = spk_color
	speaker_aura_label.text = speaker_text
	speaker_aura_label.modulate = Color(spk_color.r, spk_color.g, spk_color.b, 0.35)
	
	dialogue_rich_label.text = content_text
	dialogue_aura_label.text = content_text
	
	page_indicator.text = "%d / %d" % [index + 1, DIALOGUE_SLIDES.size()]
	
	# แอนิเมชันปุ่มคำแนะนำกะพริบ
	continue_prompt.modulate = Color(1, 1, 1, 0)
	var tw_cp = create_tween()
	tw_cp.tween_property(continue_prompt, "modulate:a", 0.9, 0.4)
	
	# ถ้าเป็นสไลด์ของเวลถอนหายใจ (index 3) ให้เวลมีเอฟเฟกต์ถอนหายใจ
	if index == 3 and exclamation_mark:
		exclamation_mark.visible = true
		exclamation_mark.modulate = Color(0.7, 0.8, 1.0, 0.9)
	elif index != 0 and exclamation_mark:
		exclamation_mark.visible = false

## กดไปหน้าถัดไป หรือเข้าสู่หน้า THE END
func _advance_dialogue() -> void:
	_play_sfx(sfx_next)
	current_slide_index += 1
	
	if current_slide_index < DIALOGUE_SLIDES.size():
		# เอฟเฟกต์เปลี่ยนหน้าข้อความนุ่มนวล
		var tw_fade = create_tween()
		tw_fade.tween_property(dialogue_rich_label, "modulate:a", 0.0, 0.12)
		tw_fade.parallel().tween_property(dialogue_aura_label, "modulate:a", 0.0, 0.12)
		tw_fade.tween_callback(func():
			_show_slide(current_slide_index)
			var tw_in = create_tween()
			tw_in.tween_property(dialogue_rich_label, "modulate:a", 1.0, 0.2)
			tw_in.parallel().tween_property(dialogue_aura_label, "modulate:a", 1.0, 0.2)
		)
	else:
		# จบบทสนทนาทั้งหมด -> เข้าสู่หน้าจอ THE END
		_show_the_end_screen()

## แสดงหน้าจอ THE END พร้อมปุ่มกลับสู่หน้าหลัก
func _show_the_end_screen() -> void:
	is_in_dialogue = false
	
	# ซ่อนกรอบบทสนทนา
	var tw_hide_diag = create_tween().set_parallel(true)
	tw_hide_diag.tween_property(dialogue_container, "modulate:a", 0.0, 0.4)
	tw_hide_diag.tween_property(parchment_frame, "modulate:a", 0.0, 0.4)
	if parchment_shadow:
		tw_hide_diag.tween_property(parchment_shadow, "modulate:a", 0.0, 0.4)
	
	# ค่อย ๆ เฟดหน้าต่าง THE END ขึ้นมา
	the_end_container.visible = true
	the_end_container.modulate = Color(1, 1, 1, 0.0)
	the_end_container.scale = Vector2(0.9, 0.9)
	
	var tw_end = create_tween().set_parallel(true)
	tw_end.tween_property(the_end_container, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	tw_end.tween_property(the_end_container, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	return_menu_btn.grab_focus()

func _on_return_menu_pressed() -> void:
	_play_sfx(sfx_warp)
	# เฟดจอดำและสลับกลับหน้าหลัก
	var tw_fade = create_tween()
	tw_fade.tween_property(backdrop, "color", Color(0, 0, 0, 1.0), 0.6)
	tw_fade.tween_callback(func():
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file(start_scene_path)
	)

func _play_sfx(player: AudioStreamPlayer) -> void:
	if player and player.stream:
		player.play()
