class_name AuthApiClient
extends Node
## Talks to the account server over HTTP, one request at a time.
##
## SECURITY NOTICE:
## 1. Never print request bodies, response bodies, headers or tokens, not even while debugging.
## 2. Tokens travel only in the Authorization header, never in the URL (URLs end up in logs).
## 3. Everything read from a response is type-checked before use: network data is untrusted.
## 4. TLS certificate checks use Godot's defaults. Never switch to unsafe TLS options.

const MAX_TOKEN_LENGTH := 128
const MAX_CODE_LENGTH := 64
const MAX_FIELD_ERRORS := 16
const DEFAULT_RETRY_AFTER_SEC := 60
const MAX_RETRY_AFTER_SEC := 3600
# Display-name cooldown is 14 days on the server; accept a little more, never unbounded.
const MAX_COOLDOWN_RETRY_AFTER_SEC := 15 * 24 * 60 * 60

var _http: HTTPRequest
var _busy := false


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.body_size_limit = AuthConfig.MAX_RESPONSE_BYTES
	add_child(_http)


func is_busy() -> bool:
	return _busy


func health() -> AuthApiResult:
	return await _send(HTTPClient.METHOD_GET, "/health", null, "", AuthConfig.HEALTH_TIMEOUT_SEC)


func register(username: String, display_name: String, email: String, password: String, policy_version: String = "", leaderboard_opt_in: bool = false) -> AuthApiResult:
	var body := {
		"username": username,
		"email": email,
		"password": password,
		"leaderboardOptIn": leaderboard_opt_in,
	}
	if not policy_version.is_empty():
		body["policyVersion"] = policy_version
	# ไม่ส่งชื่อที่แสดง = ให้ server ตั้งให้ (player-<เลข>)
	if not display_name.is_empty():
		body["displayName"] = display_name
	return await _send(HTTPClient.METHOD_POST, AuthConfig.API_PREFIX + "/register", body, "", AuthConfig.REQUEST_TIMEOUT_SEC)


## ตรวจก่อนสมัครว่าใช้ชื่อผู้ใช้และอีเมลนี้ได้ไหม (server ไม่สร้างบัญชี ไม่บันทึกอะไร)
## ok = ใช้ได้ / IDENTIFIER_TAKEN = มีคนใช้แล้ว (server ไม่บอกว่าช่องไหน ตั้งใจไว้กันการไล่เช็คอีเมล)
func check_registration(username: String, email: String) -> AuthApiResult:
	var body := {
		"username": username,
		"email": email,
	}
	return await _send(HTTPClient.METHOD_POST, AuthConfig.API_PREFIX + "/register/check", body, "", AuthConfig.REQUEST_TIMEOUT_SEC)


func login(identifier: String, password: String, remember_me: bool) -> AuthApiResult:
	var body := {
		"identifier": identifier,
		"password": password,
		"rememberMe": remember_me,
	}
	return await _send(HTTPClient.METHOD_POST, AuthConfig.API_PREFIX + "/login", body, "", AuthConfig.REQUEST_TIMEOUT_SEC)


func refresh(token: String) -> AuthApiResult:
	return await _send(HTTPClient.METHOD_POST, AuthConfig.API_PREFIX + "/refresh", null, token, AuthConfig.REQUEST_TIMEOUT_SEC)


func logout(token: String) -> AuthApiResult:
	return await _send(HTTPClient.METHOD_POST, AuthConfig.API_PREFIX + "/logout", null, token, AuthConfig.REQUEST_TIMEOUT_SEC)


func get_display_name_status(token: String) -> AuthApiResult:
	if token.is_empty():
		return AuthApiResult.failure(0, AuthApiResult.INVALID_CREDENTIALS)
	return await _send(HTTPClient.METHOD_GET, AuthConfig.API_PREFIX + "/me/display-name", null, token, AuthConfig.REQUEST_TIMEOUT_SEC)


## อีเมลของเจ้าของ token (ต้องล็อกอิน) ใช้แสดงในเมนูบัญชีเท่านั้น
func get_my_email(token: String) -> AuthApiResult:
	if token.is_empty():
		return AuthApiResult.failure(0, AuthApiResult.INVALID_CREDENTIALS)
	return await _send(HTTPClient.METHOD_GET, AuthConfig.API_PREFIX + "/me/email", null, token, AuthConfig.REQUEST_TIMEOUT_SEC)


func change_display_name(token: String, display_name: String) -> AuthApiResult:
	if token.is_empty():
		return AuthApiResult.failure(0, AuthApiResult.INVALID_CREDENTIALS)
	var body := {"displayName": display_name}
	return await _send(HTTPClient.METHOD_PATCH, AuthConfig.API_PREFIX + "/me/display-name", body, token, AuthConfig.REQUEST_TIMEOUT_SEC)


func get_leaderboard_consent(token: String) -> AuthApiResult:
	if token.is_empty():
		return AuthApiResult.failure(0, AuthApiResult.INVALID_CREDENTIALS)
	return await _send(HTTPClient.METHOD_GET, AuthConfig.API_PREFIX + "/me/leaderboard-consent", null, token, AuthConfig.REQUEST_TIMEOUT_SEC)


func set_leaderboard_consent(token: String, granted: bool, policy_version: String) -> AuthApiResult:
	if token.is_empty():
		return AuthApiResult.failure(0, AuthApiResult.INVALID_CREDENTIALS)
	var body := {"granted": granted, "policyVersion": policy_version}
	return await _send(HTTPClient.METHOD_PUT, AuthConfig.API_PREFIX + "/me/leaderboard-consent", body, token, AuthConfig.REQUEST_TIMEOUT_SEC)


func me(token: String) -> AuthApiResult:
	return await _send(HTTPClient.METHOD_GET, AuthConfig.API_PREFIX + "/me", null, token, AuthConfig.REQUEST_TIMEOUT_SEC)


func _send(method: HTTPClient.Method, path: String, body: Variant, token: String, timeout_sec: float) -> AuthApiResult:
	if _busy:
		push_warning("AuthApiClient: another request is still running.")
		return AuthApiResult.failure(0, AuthApiResult.SERVER_ERROR)

	var base := AuthConfig.base_url()
	if base.is_empty():
		return AuthApiResult.failure(0, AuthApiResult.SERVER_ERROR)

	# A malformed token could inject extra header lines; treat it as an invalid session.
	if not token.is_empty() and not _is_safe_token(token):
		return AuthApiResult.failure(0, AuthApiResult.INVALID_CREDENTIALS)

	var headers := PackedStringArray(["Accept: application/json"])
	var payload := ""
	if body != null:
		headers.append("Content-Type: application/json")
		payload = JSON.stringify(body)
	if not token.is_empty():
		headers.append("Authorization: Bearer " + token)

	_busy = true
	_http.timeout = timeout_sec
	var request_error := _http.request(base + path, headers, method, payload)
	if request_error != OK:
		_busy = false
		return AuthApiResult.failure(0, AuthApiResult.NETWORK_UNAVAILABLE)

	var response: Array = await _http.request_completed
	_busy = false
	return _parse_response(response[0], response[1], response[2], response[3])


func _parse_response(result: int, status: int, headers: PackedStringArray, raw: PackedByteArray) -> AuthApiResult:
	if result == HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
		return AuthApiResult.failure(status, AuthApiResult.SERVER_ERROR)
	if result != HTTPRequest.RESULT_SUCCESS:
		return AuthApiResult.failure(0, AuthApiResult.NETWORK_UNAVAILABLE)

	var parsed: Variant = null
	if not raw.is_empty():
		var json := JSON.new()
		if json.parse(raw.get_string_from_utf8()) == OK:
			parsed = json.data

	if status >= 200 and status < 300:
		if raw.is_empty():
			return AuthApiResult.success(status, {})
		if parsed is Dictionary:
			return AuthApiResult.success(status, parsed)
		return AuthApiResult.failure(status, AuthApiResult.SERVER_ERROR)

	if status == 429:
		var limited := AuthApiResult.failure(status, AuthApiResult.RATE_LIMITED)
		limited.retry_after_sec = _read_retry_after(headers)
		return limited

	if status >= 400 and status < 500 and parsed is Dictionary:
		var code_value: Variant = parsed.get("code")
		if code_value is String and not code_value.is_empty() and code_value.length() <= MAX_CODE_LENGTH:
			var failed := AuthApiResult.failure(status, code_value)
			failed.field_errors = _read_field_errors(parsed.get("fieldErrors"))
			if code_value == AuthApiResult.DISPLAY_NAME_CHANGE_COOLDOWN:
				failed.retry_after_sec = _read_retry_after(headers, MAX_COOLDOWN_RETRY_AFTER_SEC)
			return failed

	return AuthApiResult.failure(status, AuthApiResult.SERVER_ERROR)


func _read_field_errors(value: Variant) -> Array[Dictionary]:
	var errors: Array[Dictionary] = []
	if not (value is Array):
		return errors
	for item: Variant in value:
		if errors.size() >= MAX_FIELD_ERRORS:
			break
		if not (item is Dictionary):
			continue
		var field: Variant = item.get("field")
		var reason: Variant = item.get("reason")
		if field is String and reason is String:
			errors.append({"field": field, "reason": reason})
	return errors


func _read_retry_after(headers: PackedStringArray, max_sec: int = MAX_RETRY_AFTER_SEC) -> int:
	for header: String in headers:
		var separator := header.find(":")
		if separator <= 0:
			continue
		if header.substr(0, separator).strip_edges().to_lower() != "retry-after":
			continue
		var value := header.substr(separator + 1).strip_edges()
		if value.is_valid_int():
			return clampi(value.to_int(), 0, max_sec)
	return DEFAULT_RETRY_AFTER_SEC


func _is_safe_token(token: String) -> bool:
	if token.length() > MAX_TOKEN_LENGTH:
		return false
	for i in range(token.length()):
		var c := token.unicode_at(i)
		var is_lower := c >= 0x61 and c <= 0x7A  # a-z
		var is_upper := c >= 0x41 and c <= 0x5A  # A-Z
		var is_digit := c >= 0x30 and c <= 0x39  # 0-9
		var is_url_safe := c == 0x2D or c == 0x5F  # - _
		if not (is_lower or is_upper or is_digit or is_url_safe):
			return false
	return true
