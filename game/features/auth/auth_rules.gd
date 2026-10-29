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


static func validate_display_name(raw: String) -> String:
	var trimmed := raw.strip_edges()
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
