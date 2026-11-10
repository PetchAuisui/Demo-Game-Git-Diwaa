class_name GitHubTheme
extends RefCounted
## สีและสไตล์แบบ GitHub (dark) สำหรับหน้า Remote Repository จำลอง
## สร้าง Theme ชุดเดียวให้ทุกปุ่ม ช่องกรอก เมนู และแถบเลื่อนในหน้านั้น

## อัตราขยายของทั้งหน้า: เกมตั้งฟอนต์เริ่มต้นไว้ 24 ส่วนขนาดแบบ GitHub จริงอยู่ที่ 14–16
## จึงคูณทุกขนาด (ตัวอักษร ไอคอน ช่องไฟ) ด้วยค่านี้ ให้อ่านสบายเท่ากับ UI ส่วนอื่นของเกม
const UI_SCALE := 1.35

# พื้นผิวเป็นชั้นๆ: แถบบน/ช่องกรอก/บล็อกโค้ด (เข้มสุด) < พื้นหน้า < การ์ด < หัวการ์ดและแถวที่ชี้
const BACKDROP := Color(0.004, 0.016, 0.035, 0.97)
const INSET := Color("#05070a")
const CANVAS := Color("#0a0d12")
const SURFACE := Color("#11161d")
const SURFACE_RAISED := Color("#1a212b")
const BORDER := Color("#3d444d")
const BORDER_MUTED := Color("#2b323b")

# ตัวอักษร (สว่างกว่า GitHub เดิมเล็กน้อย ให้อ่านบนพื้นเข้มได้ชัด)
const FG := Color("#f0f6fc")
const FG_MUTED := Color("#9ba5b0")
const FG_SUBTLE := Color("#7d8590")

# สีสถานะ
const ACCENT := Color("#4493f8")
const ACCENT_HOVER := Color("#79b8ff")
const ACCENT_EMPHASIS := Color("#1f6feb")
const ACCENT_SUBTLE := Color("#12233b")
const SUCCESS := Color("#3fb950")
const SUCCESS_EMPHASIS := Color("#238636")
const SUCCESS_SUBTLE := Color("#12261e")
const DANGER := Color("#f85149")
const DANGER_EMPHASIS := Color("#da3633")
const DANGER_SUBTLE := Color("#25171c")
const ATTENTION := Color("#d29922")
const DONE := Color("#a371f7")
const DONE_EMPHASIS := Color("#8957e5")
const TAB_UNDERLINE := Color("#f78166")

# สีไล่คำสั่งในบล็อกโค้ด
const SYNTAX_SUBCOMMAND := Color("#7ee787")
const SYNTAX_FLAG := Color("#ffa657")
const SYNTAX_STRING := Color("#a5d6ff")
const SYNTAX_PATH := Color("#79c0ff")
const SYNTAX_GAME := Color("#d2a8ff")

# diff
const DIFF_ADD := Color("#12261e")
const DIFF_ADD_GUTTER := Color("#173c24")
const DIFF_REMOVE := Color("#25171c")
const DIFF_REMOVE_GUTTER := Color("#532426")
const DIFF_HUNK := Color("#132339")

# ชื่อ theme type variation ของปุ่ม
const PRIMARY_BUTTON := "GhPrimaryButton"
const DANGER_BUTTON := "GhDangerButton"
const LINK_BUTTON := "GhLinkButton"
const GHOST_BUTTON := "GhGhostButton"

static var _mono: Font
static var _bold: Font
static var _mono_bold: Font


static func s(pixels: float) -> int:
	return roundi(pixels * UI_SCALE)


static func sf(pixels: float) -> float:
	return pixels * UI_SCALE


static func mono_font() -> Font:
	if _mono == null:
		var font := SystemFont.new()
		font.font_names = PackedStringArray(["Menlo", "Consolas", "DejaVu Sans Mono", "monospace"])
		_mono = font
	return _mono


static func mono_bold_font() -> Font:
	if _mono_bold == null:
		var font := FontVariation.new()
		font.base_font = mono_font()
		font.variation_embolden = 0.4
		_mono_bold = font
	return _mono_bold


static func bold_font() -> Font:
	if _bold == null:
		var font := FontVariation.new()
		font.base_font = ThemeDB.fallback_font
		font.variation_embolden = 0.35
		_bold = font
	return _bold


## กล่องพื้นหลังมีเส้นขอบรอบด้าน
static func box(bg: Color, border: Color, radius: int = 8, border_width: int = 1,
		pad_h: float = 0.0, pad_v: float = 0.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = sf(pad_h) + border_width
	style.content_margin_right = sf(pad_h) + border_width
	style.content_margin_top = sf(pad_v) + border_width
	style.content_margin_bottom = sf(pad_v) + border_width
	return style


## แถบที่มีเส้นเฉพาะด้านล่าง (หัวตาราง แถวรายการ แท็บ)
static func underlined(bg: Color, line: Color, line_width: int, pad_h: float, pad_top: float,
		pad_bottom: float = -1.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = line
	style.border_width_bottom = line_width
	style.content_margin_left = sf(pad_h)
	style.content_margin_right = sf(pad_h)
	style.content_margin_top = sf(pad_top)
	style.content_margin_bottom = sf(pad_top if pad_bottom < 0.0 else pad_bottom) + line_width
	return style


static func create() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = s(15)
	theme.set_color("font_color", "Label", FG)

	# ปุ่มทั่วไป
	for type in ["Button", "OptionButton"]:
		_set_button(theme, type,
				box(Color("#212832"), Color("#4a525c"), 8, 1, 14, 5),
				box(Color("#2c3440"), Color("#9ba5b0"), 8, 1, 14, 5),
				box(Color("#252c36"), Color("#9ba5b0"), 8, 1, 14, 5),
				box(Color("#1a2029"), Color("#343b45"), 8, 1, 14, 5),
				FG, FG, Color("#484f58"))
		theme.set_constant("h_separation", type, s(6))
		theme.set_constant("icon_max_width", type, s(16))

	# ปุ่มหลักสีเขียว
	theme.set_type_variation(PRIMARY_BUTTON, "Button")
	_set_button(theme, PRIMARY_BUTTON,
			box(SUCCESS_EMPHASIS, Color("#2ea043"), 8, 1, 14, 5),
			box(Color("#2ea043"), Color("#3fb950"), 8, 1, 14, 5),
			box(Color("#1f7a2f"), Color("#2ea043"), 8, 1, 14, 5),
			box(Color(0.137, 0.525, 0.212, 0.45), Color(0.18, 0.63, 0.26, 0.3), 8, 1, 14, 5),
			Color.WHITE, Color.WHITE, Color(1.0, 1.0, 1.0, 0.5))

	# ปุ่มอันตราย (ตัวแดง โฮเวอร์แล้วเป็นพื้นแดง)
	theme.set_type_variation(DANGER_BUTTON, "Button")
	_set_button(theme, DANGER_BUTTON,
			box(Color("#21262d"), Color("#363b42"), 8, 1, 14, 5),
			box(DANGER_EMPHASIS, DANGER, 8, 1, 14, 5),
			box(Color("#b62324"), DANGER, 8, 1, 14, 5),
			box(Color("#21262d"), Color("#30363d"), 8, 1, 14, 5),
			DANGER, Color.WHITE, Color("#484f58"))

	# ปุ่มลิงก์ (ข้อความสีฟ้า ไม่มีกรอบ)
	theme.set_type_variation(LINK_BUTTON, "Button")
	var plain := box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0)
	_set_button(theme, LINK_BUTTON, plain, plain, plain, plain, ACCENT, ACCENT_HOVER, FG_SUBTLE)

	# ปุ่มโปร่งใส (ปุ่มไอคอน/ลิงก์รอง) โฮเวอร์แล้วมีพื้น
	theme.set_type_variation(GHOST_BUTTON, "Button")
	_set_button(theme, GHOST_BUTTON,
			box(Color.TRANSPARENT, Color.TRANSPARENT, 8, 0, 8, 4),
			box(Color(0.23, 0.26, 0.31, 0.7), Color.TRANSPARENT, 8, 0, 8, 4),
			box(Color(0.23, 0.26, 0.31, 1.0), Color.TRANSPARENT, 8, 0, 8, 4),
			box(Color.TRANSPARENT, Color.TRANSPARENT, 8, 0, 8, 4),
			FG_MUTED, FG, FG_SUBTLE)

	# ช่องกรอก
	for type in ["LineEdit", "TextEdit"]:
		theme.set_stylebox("normal", type, box(INSET, BORDER, 8, 1, 12, 5))
		theme.set_stylebox("focus", type, _focus_ring())
		theme.set_stylebox("read_only", type, box(INSET, BORDER, 8, 1, 12, 5))
		theme.set_color("font_color", type, FG)
		theme.set_color("font_readonly_color", type, FG)
		theme.set_color("font_uneditable_color", type, FG)
		theme.set_color("font_placeholder_color", type, FG_SUBTLE)
		theme.set_color("caret_color", type, FG)
		theme.set_color("selection_color", type, Color(ACCENT_EMPHASIS, 0.45))

	# เมนูตัวเลือก (เช่น เลือก branch)
	theme.set_stylebox("panel", "PopupMenu", box(SURFACE_RAISED, BORDER, 8, 1, 4, 4))
	theme.set_stylebox("hover", "PopupMenu", box(Color("#2c3440"), Color.TRANSPARENT, 8, 0, 8, 4))
	var popup_separator := StyleBoxLine.new()
	popup_separator.color = BORDER
	popup_separator.thickness = 1
	theme.set_stylebox("separator", "PopupMenu", popup_separator)
	theme.set_color("font_color", "PopupMenu", FG)
	theme.set_color("font_hover_color", "PopupMenu", FG)
	theme.set_color("font_disabled_color", "PopupMenu", FG_SUBTLE)
	theme.set_constant("v_separation", "PopupMenu", s(8))
	theme.set_constant("icon_max_width", "PopupMenu", s(16))

	# คำแนะนำเมื่อชี้ (tooltip)
	theme.set_stylebox("panel", "TooltipPanel", box(SURFACE_RAISED, BORDER, 6, 1, 8, 4))
	theme.set_color("font_color", "TooltipLabel", FG)
	var tooltip_font := load("res://assets/fonts/ChakraPetch-SemiBold.ttf") as Font
	if tooltip_font != null:
		theme.set_font("font", "TooltipLabel", tooltip_font)
	theme.set_font_size("font_size", "TooltipLabel", s(14))

	# แถบเลื่อนบางๆ
	for type in ["VScrollBar", "HScrollBar"]:
		var vertical: bool = type[0] == "V"
		theme.set_stylebox("scroll", type, _thumb(Color.TRANSPARENT, vertical))
		theme.set_stylebox("scroll_focus", type, _thumb(Color.TRANSPARENT, vertical))
		theme.set_stylebox("grabber", type, _thumb(Color("#484f58"), vertical))
		theme.set_stylebox("grabber_highlight", type, _thumb(Color("#6e7681"), vertical))
		theme.set_stylebox("grabber_pressed", type, _thumb(Color("#8b949e"), vertical))

	# เส้นคั่น
	for type in ["HSeparator", "VSeparator"]:
		var line := StyleBoxLine.new()
		line.color = BORDER
		line.thickness = 1
		line.vertical = type[0] == "V"
		theme.set_stylebox("separator", type, line)
		theme.set_constant("separation", type, 1)

	theme.set_color("default_color", "RichTextLabel", FG)
	theme.set_color("selection_color", "RichTextLabel", Color(ACCENT_EMPHASIS, 0.45))
	return theme


static func _focus_ring() -> StyleBoxFlat:
	var ring := box(Color.TRANSPARENT, ACCENT_EMPHASIS, 8, 1, 12, 5)
	ring.draw_center = false
	return ring


static func _thumb(color: Color, vertical: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)
	style.content_margin_left = s(5) if vertical else 0
	style.content_margin_right = s(5) if vertical else 0
	style.content_margin_top = 0 if vertical else s(5)
	style.content_margin_bottom = 0 if vertical else s(5)
	return style


static func _set_button(theme: Theme, type: String, normal: StyleBox, hover: StyleBox, pressed: StyleBox,
		disabled: StyleBox, fg: Color, fg_hover: Color, fg_disabled: Color) -> void:
	theme.set_stylebox("normal", type, normal)
	theme.set_stylebox("hover", type, hover)
	theme.set_stylebox("pressed", type, pressed)
	theme.set_stylebox("hover_pressed", type, pressed)
	theme.set_stylebox("disabled", type, disabled)
	theme.set_stylebox("focus", type, StyleBoxEmpty.new())
	theme.set_color("font_color", type, fg)
	theme.set_color("font_focus_color", type, fg)
	theme.set_color("font_hover_color", type, fg_hover)
	theme.set_color("font_pressed_color", type, fg_hover)
	theme.set_color("font_hover_pressed_color", type, fg_hover)
	theme.set_color("font_disabled_color", type, fg_disabled)
