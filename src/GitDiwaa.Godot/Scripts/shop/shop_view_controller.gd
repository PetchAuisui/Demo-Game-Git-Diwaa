class_name ShopViewController
extends Control

## Controller สำหรับหน้าต่างร้านค้าเวทมนตร์ (Shop / Magic Bazaar)
## พัฒนาด้วย GDScript (ภาษา Godot)
## ควบคุมการแสดงผลสินค้า 12 ชิ้น, การกรองหมวดหมู่, สถานะล็อค, การซื้อไอเทม และเสียงเอฟเฟกต์

const ShopServiceScript = preload("res://Scripts/shop/shop_service.gd")

# สีประจำ Theme สำหรับร้านค้าเวทมนตร์
const COLOR_BG_LOCKED := Color("120d2b")
const COLOR_BORDER_LOCKED := Color("2d225a")
const COLOR_BG_OWNED := Color("0b1d1c")
const COLOR_BORDER_OWNED := Color("1f6b52")
const COLOR_GOLD := Color("f5c842")
const COLOR_TEXT_MUTED := Color("9d93be")
const COLOR_TEXT_LOCKED := Color("ff7b72")
const COLOR_TEXT_OWNED := Color("56d364")

const TAB_ACTIVE_BG := Color("6d28d9")
const TAB_ACTIVE_BORDER := Color("8b5cf6")
const TAB_INACTIVE_BG := Color("150f2e")
const TAB_INACTIVE_BORDER := Color("2e2355")

@onready var back_btn: Button = %BackBtn
@onready var coin_label: Label = %CoinLabel
@onready var items_grid: GridContainer = %ItemsGrid
@onready var sfx_click: AudioStreamPlayer = %SfxClick
@onready var sfx_success: AudioStreamPlayer = %SfxSuccess
@onready var fade_overlay: ColorRect = %FadeOverlay
@onready var count_info_label: Label = %CountInfoLabel

@onready var tab_buttons: Array[Button] = [
	%TabAll,
	%TabHood,
	%TabScarf,
	%TabBag,
	%TabCat
]

var shop_service: ShopService
var current_category: String = "all"
var is_leaving: bool = false

# สไตล์แคชสำหรับแท็บ
var tab_active_style: StyleBoxFlat
var tab_inactive_style: StyleBoxFlat

func _ready() -> void:
	shop_service = ShopService.new()
	shop_service.coins_changed.connect(_on_coins_changed)
	shop_service.item_purchased.connect(_on_item_purchased)
	
	_init_tab_styles()
	_wire_events()
	_update_coin_display()
	_update_category_filter("all", 0)
	_start_fade_in()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _init_tab_styles() -> void:
	tab_active_style = StyleBoxFlat.new()
	tab_active_style.bg_color = TAB_ACTIVE_BG
	tab_active_style.set_border_width_all(2)
	tab_active_style.border_color = TAB_ACTIVE_BORDER
	tab_active_style.set_corner_radius_all(14)
	tab_active_style.content_margin_left = 16
	tab_active_style.content_margin_right = 16
	tab_active_style.content_margin_top = 8
	tab_active_style.content_margin_bottom = 8
	
	tab_inactive_style = StyleBoxFlat.new()
	tab_inactive_style.bg_color = TAB_INACTIVE_BG
	tab_inactive_style.set_border_width_all(1)
	tab_inactive_style.border_color = TAB_INACTIVE_BORDER
	tab_inactive_style.set_corner_radius_all(14)
	tab_inactive_style.content_margin_left = 16
	tab_inactive_style.content_margin_right = 16
	tab_inactive_style.content_margin_top = 8
	tab_inactive_style.content_margin_bottom = 8

func _wire_events() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	
	var categories: Array[String] = ["all", "hood", "scarf", "bag", "cat"]
	for i in range(tab_buttons.size()):
		var cat: String = categories[i]
		var idx: int = i
		tab_buttons[i].pressed.connect(func():
			_play_sfx(sfx_click)
			_update_category_filter(cat, idx)
		)

func _start_fade_in() -> void:
	if fade_overlay == null:
		return
	fade_overlay.modulate = Color(1, 1, 1, 1)
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _update_coin_display() -> void:
	if coin_label != null:
		coin_label.text = "%d COINS" % shop_service.coins

func _on_coins_changed(_new_amount: int) -> void:
	_update_coin_display()
	_refresh_items_display()

func _on_item_purchased(_item_id: String) -> void:
	_refresh_items_display()

func _update_category_filter(category: String, active_idx: int) -> void:
	current_category = category
	
	for i in range(tab_buttons.size()):
		var btn := tab_buttons[i]
		var is_active := (i == active_idx)
		btn.add_theme_stylebox_override("normal", tab_active_style if is_active else tab_inactive_style)
		btn.add_theme_stylebox_override("hover", tab_active_style if is_active else tab_inactive_style)
		btn.add_theme_stylebox_override("pressed", tab_active_style if is_active else tab_inactive_style)
		btn.add_theme_color_override("font_color", Color.WHITE if is_active else COLOR_TEXT_MUTED)
	
	_refresh_items_display()

func _refresh_items_display() -> void:
	# เคลียร์การ์ดเก่า
	for child in items_grid.get_children():
		child.queue_free()
	
	var items: Array[Dictionary] = shop_service.get_items_by_category(current_category)
	
	var owned_count: int = 0
	for item in items:
		if shop_service.is_item_owned(item.get("id", "")):
			owned_count += 1
	
	if count_info_label != null:
		count_info_label.text = "สินค้าในหมวดหมู่นี้: %d ชิ้น (ปลดล็อคแล้ว %d ชิ้น)" % [items.size(), owned_count]
	
	# สร้างการ์ดสินค้าตามที่กำหนด:
	# 1. สินค้าที่ยังไม่ซื้อจะล็อคไว้ (🔒 ล็อค)
	# 2. ยังไม่ต้องใส่ภาพกราฟิกไอเทม (แสดงข้อมูลบล็อกคลีนๆ เรียบหรู)
	for item in items:
		var card := _create_item_card(item)
		items_grid.add_child(card)

func _create_item_card(item: Dictionary) -> PanelContainer:
	var item_id: String = item.get("id", "")
	var name_th: String = item.get("name_th", "ไอเทมเวทมนตร์")
	var category_th: String = item.get("category_th", "")
	var tier_name: String = item.get("tier_name", "")
	var price: int = int(item.get("price", 0))
	var is_owned: bool = shop_service.is_item_owned(item_id)
	var can_afford: bool = shop_service.can_buy(item_id)
	
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(480, 160)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# สไตล์กรอบการ์ด
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = COLOR_BG_OWNED if is_owned else COLOR_BG_LOCKED
	card_style.set_border_width_all(2)
	card_style.border_color = COLOR_BORDER_OWNED if is_owned else COLOR_BORDER_LOCKED
	card_style.set_corner_radius_all(14)
	card_style.content_margin_left = 20
	card_style.content_margin_right = 20
	card_style.content_margin_top = 16
	card_style.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", card_style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)
	
	# แถวบน: Tier Badge + Status Badge
	var top_row := HBoxContainer.new()
	vbox.add_child(top_row)
	
	var tier_lbl := Label.new()
	tier_lbl.text = "✦ %s" % tier_name
	tier_lbl.add_theme_font_size_override("font_size", 13)
	tier_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	top_row.add_child(tier_lbl)
	
	var spacer1 := Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer1)
	
	var status_lbl := Label.new()
	if is_owned:
		status_lbl.text = "✅ ปลดล็อคแล้ว (Owned)"
		status_lbl.add_theme_color_override("font_color", COLOR_TEXT_OWNED)
	else:
		status_lbl.text = "🔒 ล็อค (Locked)"
		status_lbl.add_theme_color_override("font_color", COLOR_TEXT_LOCKED)
	status_lbl.add_theme_font_size_override("font_size", 14)
	top_row.add_child(status_lbl)
	
	# แถวกลาง: ชื่อไอเทม + หมวดหมู่ (ไม่มีรูปภาพตามคำสั่ง)
	var mid_box := VBoxContainer.new()
	mid_box.add_theme_constant_override("separation", 4)
	vbox.add_child(mid_box)
	
	var name_lbl := Label.new()
	name_lbl.text = name_th
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	mid_box.add_child(name_lbl)
	
	var cat_lbl := Label.new()
	cat_lbl.text = "ประเภท: %s (ช่องไอเทมสำหรับติดตั้งในห้องแต่งตัว)" % category_th
	cat_lbl.add_theme_font_size_override("font_size", 13)
	cat_lbl.add_theme_color_override("font_color", Color(0.7, 0.65, 0.85))
	mid_box.add_child(cat_lbl)
	
	# แถวล่าง: ราคาเหรียญ + ปุ่มซื้อ
	var bot_row := HBoxContainer.new()
	bot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(bot_row)
	
	# ป้ายแสดงราคา
	var price_panel := PanelContainer.new()
	var price_style := StyleBoxFlat.new()
	price_style.bg_color = Color(0.18, 0.14, 0.05, 0.9)
	price_style.set_border_width_all(1)
	price_style.border_color = Color(0.6, 0.48, 0.15)
	price_style.set_corner_radius_all(10)
	price_style.content_margin_left = 12
	price_style.content_margin_right = 12
	price_style.content_margin_top = 6
	price_style.content_margin_bottom = 6
	price_panel.add_theme_stylebox_override("panel", price_style)
	
	var price_hbox := HBoxContainer.new()
	price_hbox.add_theme_constant_override("separation", 8)
	price_panel.add_child(price_hbox)
	
	var coin_ico := TextureRect.new()
	var coin_tex := load("res://assets/art/dressing_room/icon_coin.png") as Texture2D
	if coin_tex != null:
		coin_ico.texture = coin_tex
	coin_ico.custom_minimum_size = Vector2(22, 22)
	coin_ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	price_hbox.add_child(coin_ico)
	
	var price_lbl := Label.new()
	price_lbl.text = "%d COINS" % price
	price_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	price_lbl.add_theme_font_size_override("font_size", 16)
	price_hbox.add_child(price_lbl)
	
	bot_row.add_child(price_panel)
	
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_row.add_child(spacer2)
	
	# ปุ่มซื้อสินค้า
	var buy_btn := Button.new()
	buy_btn.custom_minimum_size = Vector2(170, 42)
	
	var btn_style := StyleBoxFlat.new()
	btn_style.set_corner_radius_all(12)
	btn_style.content_margin_left = 16
	btn_style.content_margin_right = 16
	btn_style.content_margin_top = 8
	btn_style.content_margin_bottom = 8
	
	if is_owned:
		buy_btn.text = "เป็นเจ้าของแล้ว ✨"
		buy_btn.disabled = true
		btn_style.bg_color = Color(0.12, 0.28, 0.22, 0.8)
		btn_style.set_border_width_all(1)
		btn_style.border_color = Color(0.24, 0.55, 0.42)
		buy_btn.add_theme_color_override("font_color", COLOR_TEXT_OWNED)
	elif can_afford:
		buy_btn.text = "ซื้อสินค้า 🪙"
		buy_btn.disabled = false
		btn_style.bg_color = Color(0.43, 0.16, 0.85, 1.0) # Purple
		btn_style.set_border_width_all(2)
		btn_style.border_color = Color(0.68, 0.38, 1.0)
		buy_btn.add_theme_color_override("font_color", Color.WHITE)
		buy_btn.pressed.connect(func():
			_on_buy_button_pressed(item_id, name_th, price, card)
		)
	else:
		buy_btn.text = "เหรียญไม่พอ 🔒"
		buy_btn.disabled = true
		btn_style.bg_color = Color(0.18, 0.12, 0.16, 0.7)
		btn_style.set_border_width_all(1)
		btn_style.border_color = Color(0.35, 0.20, 0.25)
		buy_btn.add_theme_color_override("font_color", Color(0.6, 0.45, 0.5))
	
	buy_btn.add_theme_stylebox_override("normal", btn_style)
	buy_btn.add_theme_stylebox_override("hover", btn_style)
	buy_btn.add_theme_stylebox_override("pressed", btn_style)
	buy_btn.add_theme_stylebox_override("disabled", btn_style)
	buy_btn.add_theme_font_size_override("font_size", 16)
	
	bot_row.add_child(buy_btn)
	
	return card

func _on_buy_button_pressed(item_id: String, item_name: String, _price: int, card: PanelContainer) -> void:
	if shop_service.buy_item(item_id):
		_play_sfx(sfx_success)
		
		# Bounce / pulse tween บนการ์ดที่เพิ่งซื้อสำเร็จ
		var tween := create_tween()
		tween.tween_property(card, "scale", Vector2(1.04, 1.04), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		
		print("[Shop] Successfully purchased: %s (%s)" % [item_name, item_id])

func _on_back_pressed() -> void:
	if is_leaving:
		return
	is_leaving = true
	
	_play_sfx(sfx_click)
	if fade_overlay != null:
		var tween := create_tween()
		tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(func():
			get_tree().change_scene_to_file("res://Scenes/StartView.tscn")
		)
	else:
		get_tree().change_scene_to_file("res://Scenes/StartView.tscn")

func _play_sfx(player: AudioStreamPlayer) -> void:
	if player != null and player.stream != null:
		player.play()
