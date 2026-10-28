class_name ShopService
extends RefCounted

## Service จัดการระบบร้านค้าและเศรษฐกิจเหรียญ Coin (ภาษา Godot / GDScript)
## กำหนดราคาสินค้า 12 ชิ้นสอดคล้องกับตาราง 40 ด่าน (รวม 1,960 Coins จากยอดเต็ม 1,980 Coins)
## รองรับการบันทึกข้อมูลถาวรผ่าน user://player_shop_data.json

signal coins_changed(new_amount: int)
signal item_purchased(item_id: String)

const SAVE_PATH: String = "user://player_shop_data.json"
const DEFAULT_COINS: int = 500 # เหรียญเริ่มต้นสำหรับทดสอบระบบในร้านค้า

# รายการสินค้าทั้ง 12 ชิ้น (ฮู้ด 3 สี, ผ้าพันคอ 4 สี, กระเป๋า 2 แบบ, แมว 3 สี)
# คำนวณราคาตาม Tier ก้าวหน้าของด่าน 1-40
const CATALOG: Array[Dictionary] = [
	# --- ฮู้ด (Hood) ---
	{
		"id": "hood_green",
		"name_th": "ฮู้ดใบไม้ฝึกหัด",
		"category": "hood",
		"category_th": "ฮู้ด",
		"price": 80,
		"tier": 1,
		"tier_name": "Tier 1: เริ่มต้น (Act 1)"
	},
	{
		"id": "hood_yellow",
		"name_th": "ฮู้ดแสงตะวันแห่งรุ่งอรุณ",
		"category": "hood",
		"category_th": "ฮู้ด",
		"price": 120,
		"tier": 2,
		"tier_name": "Tier 2: ทั่วไป (Act 1-2)"
	},
	{
		"id": "hood_pink",
		"name_th": "ฮู้ดซากุระเวทมนตร์",
		"category": "hood",
		"category_th": "ฮู้ด",
		"price": 200,
		"tier": 3,
		"tier_name": "Tier 3: หายาก (Act 2-3)"
	},
	
	# --- ผ้าพันคอ (Scarf) ---
	{
		"id": "scarf_green",
		"name_th": "ผ้าพันคอเอลฟ์พงไพร",
		"category": "scarf",
		"category_th": "ผ้าพันคอ",
		"price": 60,
		"tier": 1,
		"tier_name": "Tier 1: เริ่มต้น (Act 1)"
	},
	{
		"id": "scarf_red",
		"name_th": "ผ้าพันคอเพลิงรูบี้",
		"category": "scarf",
		"category_th": "ผ้าพันคอ",
		"price": 100,
		"tier": 2,
		"tier_name": "Tier 2: ทั่วไป (Act 1-2)"
	},
	{
		"id": "scarf_silver",
		"name_th": "ผ้าพันคอไหมเงินประกายหมอก",
		"category": "scarf",
		"category_th": "ผ้าพันคอ",
		"price": 180,
		"tier": 3,
		"tier_name": "Tier 3: หายาก (Act 2-3)"
	},
	{
		"id": "scarf_red_gold",
		"name_th": "ผ้าพันคอราชวงศ์เพลิงทอง",
		"category": "scarf",
		"category_th": "ผ้าพันคอ",
		"price": 280,
		"tier": 4,
		"tier_name": "Tier 4: ตำนาน (Act 3 Endgame)"
	},
	
	# --- กระเป๋า (Bag) ---
	{
		"id": "bag_satchel",
		"name_th": "กระเป๋าย่ามนักเดินทาง",
		"category": "bag",
		"category_th": "กระเป๋า",
		"price": 90,
		"tier": 1,
		"tier_name": "Tier 1: เริ่มต้น (Act 1)"
	},
	{
		"id": "bag_backpack",
		"name_th": "กระเป๋าเป้นักผจญภัย",
		"category": "bag",
		"category_th": "กระเป๋า",
		"price": 150,
		"tier": 2,
		"tier_name": "Tier 2: ทั่วไป (Act 1-2)"
	},
	
	# --- แมวคู่หู (Cat - 3 สี) ---
	{
		"id": "cat_black",
		"name_th": "น้องแมวมิวราสีดำ",
		"category": "cat",
		"category_th": "แมวคู่หู",
		"price": 160,
		"tier": 2,
		"tier_name": "Tier 2: ทั่วไป (Act 1-2)"
	},
	{
		"id": "cat_orange",
		"name_th": "น้องแมวส้มจอมซน",
		"category": "cat",
		"category_th": "แมวคู่หู",
		"price": 220,
		"tier": 3,
		"tier_name": "Tier 3: หายาก (Act 2-3)"
	},
	{
		"id": "cat_white",
		"name_th": "น้องแมวขาวหิมะศักดิ์สิทธิ์",
		"category": "cat",
		"category_th": "แมวคู่หู",
		"price": 320,
		"tier": 4,
		"tier_name": "Tier 4: ตำนาน (Act 3 Endgame)"
	}
]

var coins: int = DEFAULT_COINS
var owned_item_ids: Array = []

func _init() -> void:
	load_data()

## โหลดข้อมูลสถานะผู้เล่น
func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		coins = DEFAULT_COINS
		owned_item_ids = []
		return
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("[ShopService] Failed to open save file for reading: " + SAVE_PATH)
		return
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_warning("[ShopService] Save file corrupted, resetting to defaults: " + json.get_error_message())
		coins = DEFAULT_COINS
		owned_item_ids = []
		return
	
	if json.data is Dictionary:
		var data: Dictionary = json.data
		coins = int(data.get("coins", DEFAULT_COINS))
		owned_item_ids = Array(data.get("owned_items", []))
	else:
		coins = DEFAULT_COINS
		owned_item_ids = []

## บันทึกข้อมูลลง user://
func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[ShopService] Failed to open save file for writing: " + SAVE_PATH)
		return
	
	var data := {
		"coins": coins,
		"owned_items": owned_item_ids,
		"saved_at": Time.get_datetime_string_from_system()
	}
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

## ตรวจสอบว่ามีไอเทมนี้แล้วหรือไม่
func is_item_owned(item_id: String) -> bool:
	return owned_item_ids.has(item_id)

## ดึงข้อมูลไอเทมตาม ID
func get_item_by_id(item_id: String) -> Dictionary:
	for item in CATALOG:
		if item.get("id") == item_id:
			return item
	return {}

## ตรวจสอบว่าสามารถซื้อได้หรือไม่ (ยังไม่มี และเหรียญพอ)
func can_buy(item_id: String) -> bool:
	if is_item_owned(item_id):
		return false
	var item := get_item_by_id(item_id)
	if item.is_empty():
		return false
	var price: int = int(item.get("price", 999999))
	return coins >= price

## ซื้อสินค้า
func buy_item(item_id: String) -> bool:
	if not can_buy(item_id):
		return false
	
	var item := get_item_by_id(item_id)
	var price: int = int(item.get("price", 0))
	coins -= price
	owned_item_ids.append(item_id)
	save_data()
	
	coins_changed.emit(coins)
	item_purchased.emit(item_id)
	return true

## เพิ่มเหรียญ (เช่น ได้รับจากการผ่านด่าน)
func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	save_data()
	coins_changed.emit(coins)

## ดึงสินค้าตามหมวดหมู่ (all, hood, scarf, bag, cat)
func get_items_by_category(category: String) -> Array[Dictionary]:
	if category == "all" or category.is_empty():
		return CATALOG.duplicate()
	
	var filtered: Array[Dictionary] = []
	for item in CATALOG:
		if item.get("category") == category:
			filtered.append(item)
	return filtered
