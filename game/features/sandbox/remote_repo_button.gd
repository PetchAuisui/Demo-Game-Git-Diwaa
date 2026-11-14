class_name RemoteRepoButton
extends Button
## ปุ่มไปหน้า Remote Repository (Magic Vault): ไอคอนก้อนเมฆ (สื่อว่าอยู่บนเซิร์ฟเวอร์) + ข้อความ Remote Repo
## ใช้สไตล์เดียวกับปุ่มใน FilesPanel จึงวางในพาเนลไหนก็เข้ากัน สร้างด้วยโค้ดแล้วใส่ผ่าน GitGraphPanel.add_header_action

const AVAILABLE_HINT := "เปิด Remote Repository (Magic Vault): ดูไฟล์ branch และ pull request ที่ push ขึ้นไป"
const UNAVAILABLE_HINT := "ใช้ได้เฉพาะโหมด Real Git"


func _ready() -> void:
	text = "คลังออนไลน์"
	icon = GitHubIcons.get_icon(GhIcon.CLOUD, SandboxThemeTokens.GOLD_TITLE, 20)
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(0, 34)
	var font_semibold = load("res://assets/fonts/ChakraPetch-SemiBold.ttf")
	if font_semibold:
		add_theme_font_override("font", font_semibold)
	add_theme_font_size_override("font_size", 16)
	add_theme_constant_override("icon_max_width", 20)
	add_theme_constant_override("h_separation", 8)

	var normal := _style(Color(0.12, 0.14, 0.24, 0.98), Color(0.42, 0.48, 0.72))
	var hover := _style(Color(0.19, 0.23, 0.38), Color(0.66, 0.71, 0.98))
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", hover)
	add_theme_stylebox_override("disabled", _style(Color(0.06, 0.07, 0.12, 0.7), Color(0.24, 0.27, 0.37, 0.7)))
	set_available(not disabled)


## กดได้เมื่อมี remote ให้ดู (โหมด Real Git) ไม่เช่นนั้นเทาและบอกเหตุผลเมื่อชี้
func set_available(available: bool) -> void:
	disabled = not available
	tooltip_text = AVAILABLE_HINT if available else UNAVAILABLE_HINT


static func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style
