class_name AuthRules
extends RefCounted

## Input constraints and validation rules matching server-side AccountRules.cs and AccountInputValidator.cs.
##
## SECURITY NOTICE:
## 1. Values here must mirror AccountRules.cs exactly to ensure consistent validation boundaries.
## 2. Client-side checks provide immediate UX feedback only; the server remains the ultimate authority.

# --- Length Limits ---
const USERNAME_MIN_LEN := 3
const USERNAME_MAX_LEN := 20
const DISPLAY_NAME_MAX_LEN := 50
const EMAIL_MAX_LEN := 254
const EMAIL_LOCAL_MAX_LEN := 64
const PASSWORD_MIN_LEN := 8
const PASSWORD_MAX_LEN := 128
const LOGIN_IDENTIFIER_MAX_LEN := 254

# --- Field Names (must match AccountFields.cs) ---
const FIELD_IDENTIFIER := "identifier"
const FIELD_DISPLAY_NAME := "displayName"
const FIELD_USERNAME := "username"
const FIELD_EMAIL := "email"
const FIELD_PASSWORD := "password"
const FIELD_CONFIRM_PASSWORD := "confirmPassword"  # client-only

# --- Error Reasons (matching server enum names) ---
const REQUIRED := "Required"
const TOO_SHORT := "TooShort"
const TOO_LONG := "TooLong"
const INVALID_CHARACTERS := "InvalidCharacters"
const INVALID_FORMAT := "InvalidFormat"
const MISMATCH := "Mismatch"  # client-only: confirm password
const TAKEN := "Taken"  # server-only: display name already used by someone else
const TOO_COMMON := "TooCommon"  # server-only: รหัสผ่านเดาง่ายเกินไป (ปิดตอน server รันแบบ Development)
const RESERVED := "Reserved"  # player-<ตัวเลข> สงวนไว้ให้ระบบตั้งให้ผู้เล่นใหม่

# ตรงกับ AccountRules.GeneratedDisplayNamePrefix ใน server
const GENERATED_DISPLAY_NAME_PREFIX := "player-"

static var _username_regex: RegEx


static func _get_username_regex() -> RegEx:
	if _username_regex == null:
		_username_regex = RegEx.create_from_string("^[a-z0-9][a-z0-9-]{1,18}[a-z0-9]\\z")
	return _username_regex


static func validate_username(raw: String) -> String:
	var trimmed := raw.strip_edges()
	if trimmed.is_empty():
		return REQUIRED

	for i in range(trimmed.length()):
		var c := trimmed.unicode_at(i)
		var is_lower := c >= 0x61 and c <= 0x7A  # a-z
		var is_upper := c >= 0x41 and c <= 0x5A  # A-Z
		var is_digit := c >= 0x30 and c <= 0x39  # 0-9
		var is_hyphen := c == 0x2D              # -
		if not (is_lower or is_upper or is_digit or is_hyphen):
			return INVALID_CHARACTERS

	var lower := trimmed.to_lower()
	if lower.length() < USERNAME_MIN_LEN:
		return TOO_SHORT
	if lower.length() > USERNAME_MAX_LEN:
		return TOO_LONG

	var regex := _get_username_regex()
	if regex == null or regex.search(lower) == null:
		return INVALID_FORMAT

	return ""


static func validate_email(raw: String) -> String:
	var trimmed := raw.strip_edges()
	if trimmed.is_empty():
		return REQUIRED
	if trimmed.length() > EMAIL_MAX_LEN:
		return TOO_LONG

	for i in range(trimmed.length()):
		var c := trimmed.unicode_at(i)
		var is_lower := c >= 0x61 and c <= 0x7A  # a-z
		var is_upper := c >= 0x41 and c <= 0x5A  # A-Z
		var is_digit := c >= 0x30 and c <= 0x39  # 0-9
		var is_allowed_punct := (
			c == 0x2E   # .
			or c == 0x5F  # _
			or c == 0x25  # %
			or c == 0x2B  # +
			or c == 0x2D  # -
			or c == 0x40  # @
		)
		if not (is_lower or is_upper or is_digit or is_allowed_punct):
			return INVALID_CHARACTERS

	if trimmed.contains(".."):
		return INVALID_FORMAT

	var at_count := trimmed.count("@")
	if at_count != 1:
		return INVALID_FORMAT

	var at_index := trimmed.find("@")
	if at_index == 0:
		return INVALID_FORMAT

	var local_part := trimmed.substr(0, at_index)
	var domain_part := trimmed.substr(at_index + 1)

	if local_part.length() > EMAIL_LOCAL_MAX_LEN:
		return INVALID_FORMAT
	if local_part.begins_with(".") or local_part.ends_with("."):
		return INVALID_FORMAT

	if not domain_part.contains("."):
		return INVALID_FORMAT
	if domain_part.begins_with(".") or domain_part.ends_with("."):
		return INVALID_FORMAT

	return ""


## ชื่อรูปแบบ player-<ตัวเลข> สงวนไว้ให้ระบบ (ตรงกับ AccountRules.IsReservedDisplayName ใน server)
## เช็คแบบง่ายในเกม (ไม่สนตัวพิมพ์เล็กใหญ่) server เช็คละเอียดกว่าอีกชั้น เช่น ตัวอักษรเต็มความกว้าง
static func is_reserved_display_name(raw: String) -> bool:
	var lowered := raw.strip_edges().to_lower()
	var prefix_len := GENERATED_DISPLAY_NAME_PREFIX.length()
	if not lowered.begins_with(GENERATED_DISPLAY_NAME_PREFIX) or lowered.length() == prefix_len:
		return false
	for i in range(prefix_len, lowered.length()):
		var c := lowered.unicode_at(i)
		if c < 0x30 or c > 0x39:  # ไม่ใช่ 0-9
			return false
	return true


# ช่องว่างทุกแบบที่ C# string.Trim() ตัด (char.IsWhiteSpace) แต่ strip_edges() ของ Godot ไม่ตัด
# strip_edges() ตัดแค่รหัสไม่เกิน 0x20 จึงเหลือ NBSP / ช่องว่างญี่ปุ่น (U+3000) ฯลฯ ทำให้ชื่อที่มีแต่ช่องว่างผ่านการตรวจ
const _EXTRA_SPACES := [
	0x0085, 0x00A0, 0x1680,
	0x2000, 0x2001, 0x2002, 0x2003, 0x2004, 0x2005, 0x2006, 0x2007, 0x2008, 0x2009, 0x200A,
	0x2028, 0x2029, 0x202F, 0x205F, 0x3000,
]


## ตัดช่องว่างหัวท้ายให้ตรงกับ string.Trim() ของ server (ชื่อที่แสดง / ชื่อ guest ใช้ตัวนี้แทน strip_edges)
static func trim_spaces(raw: String) -> String:
	var start := 0
	var end := raw.length()
	while start < end and _is_space(raw.unicode_at(start)):
		start += 1
	while end > start and _is_space(raw.unicode_at(end - 1)):
		end -= 1
	return raw.substr(start, end - start)


static func _is_space(c: int) -> bool:
	return c == 0x20 or (c >= 0x09 and c <= 0x0D) or _EXTRA_SPACES.has(c)


## ใช้ตอนผู้เล่นตั้งชื่อเอง (เปลี่ยนชื่อ / ชื่อ guest): กติกาเดียวกับชื่อที่แสดง และห้ามใช้ชื่อสงวน
static func validate_new_display_name(raw: String) -> String:
	var reason := validate_display_name(raw)
	if not reason.is_empty():
		return reason
	return RESERVED if is_reserved_display_name(raw) else ""


static func validate_display_name(raw: String) -> String:
	var trimmed := trim_spaces(raw)
	if trimmed.is_empty():
		return REQUIRED
	if trimmed.length() > DISPLAY_NAME_MAX_LEN:
		return TOO_LONG

	# Note: GDScript does not provide C#-equivalent CharUnicodeInfo.
	# Checking banned control, invisible, newline, and surrogate code point ranges.
	# The server will perform a strict secondary check on any edge-case characters.
	for i in range(trimmed.length()):
		var c := trimmed.unicode_at(i)
		if c < 0x20 or (c >= 0x7F and c <= 0x9F):
			return INVALID_CHARACTERS
		if (
			c == 0x00AD
			or c == 0x061C
			or (c >= 0x200B and c <= 0x200F)
			or (c >= 0x202A and c <= 0x202E)
			or (c >= 0x2060 and c <= 0x2064)
			or (c >= 0x2066 and c <= 0x2069)
			or c == 0xFEFF
		):
			return INVALID_CHARACTERS
		if c == 0x2028 or c == 0x2029:
			return INVALID_CHARACTERS
		if c > 0xFFFF:
			return INVALID_CHARACTERS

	return ""


static func validate_register_password(pw: String) -> String:
	if pw.is_empty():
		return REQUIRED
	if pw.length() < PASSWORD_MIN_LEN:
		return TOO_SHORT
	if pw.length() > PASSWORD_MAX_LEN:
		return TOO_LONG
	return ""


static func validate_login_identifier(raw: String) -> String:
	var trimmed := raw.strip_edges()
	if trimmed.is_empty():
		return REQUIRED
	if trimmed.length() > LOGIN_IDENTIFIER_MAX_LEN:
		return TOO_LONG
	return ""


static func validate_login_password(pw: String) -> String:
	# Login must NOT check minimum password length (per ValidateLogin_DoesNotRevealRegisterRules)
	if pw.is_empty():
		return REQUIRED
	if pw.length() > PASSWORD_MAX_LEN:
		return TOO_LONG
	return ""
