class_name AuthThemeTokens
extends RefCounted

## Visual color tokens and style factory for Authentication views.

# --- Backdrop ---
const BACKDROP := Color("12141a")

# --- Parchment Card ---
const CARD_BG := Color("e3cca4")
const CARD_BORDER := Color("b6a07f")
const TEXT_PRIMARY := Color("2c241d")
const TEXT_MUTED := Color("7a6e60")

# --- Form Inputs ---
const INPUT_BG := Color("fdf5e6")
const INPUT_BORDER := Color("b6a07f")
const INPUT_BORDER_FOCUS := Color("705335")

# --- Buttons & Links ---
const BUTTON_BG := Color("d4a348")
const BUTTON_HOVER_BG := Color("e2b359")
const BUTTON_PRESSED_BG := Color("bf8f38")
const BUTTON_TEXT := Color("2c241d")
const BUTTON_DISABLED_BG := Color("c9bfae")
const BUTTON_DISABLED_TEXT := Color("7a6e60")
const LINK_TEXT := Color("bc7d47")

# --- Password Reveal Toggle ---
const TOGGLE_ICON := Color.WHITE
const TOGGLE_BG := Color("4a3b2c")
const TOGGLE_HOVER_BG := Color("5c4a37")

# --- Error Feedback ---
const ERROR_TEXT := Color("a82828")
# สีข้อความแจ้งผลสำเร็จ เช่น "สมัครสมาชิกสำเร็จ"
const SUCCESS_TEXT := Color("2e6b34")


static func create_input_style(border_color: Color = INPUT_BORDER) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = INPUT_BG
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


## จัดสีปุ่มของหน้าบัญชีทุกหน้าให้เหมือนกัน (เดิมเขียนซ้ำไว้ 4 ไฟล์)
## ค่าเริ่มต้น = ปุ่มหลักสีทอง / ปุ่มรองส่ง INPUT_BG, Color.WHITE, CARD_BORDER
## ใส่สีตอนปิดใช้งานให้เสมอ ปุ่มไหนถูกปิดชั่วคราว (เช่น ระหว่างรอ server) จะได้ดูออกว่ากดไม่ได้
static func style_button(btn: Button, normal: Color = BUTTON_BG, hover: Color = BUTTON_HOVER_BG, pressed_bg: Color = BUTTON_PRESSED_BG) -> void:
	btn.add_theme_stylebox_override("normal", create_button_style(normal))
	btn.add_theme_stylebox_override("hover", create_button_style(hover))
	btn.add_theme_stylebox_override("pressed", create_button_style(pressed_bg))
	btn.add_theme_stylebox_override("disabled", create_button_style(BUTTON_DISABLED_BG))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(color_name, BUTTON_TEXT)
	btn.add_theme_color_override("font_disabled_color", BUTTON_DISABLED_TEXT)


static func create_button_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_border_width_all(0)
	style.set_corner_radius_all(6)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
