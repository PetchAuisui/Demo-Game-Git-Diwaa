class_name AuthApiResult
extends RefCounted
## Outcome of one call to the account server.
##
## `code` mirrors AuthErrorCode in server/src/GitDiwaa.Online (spelled exactly the same),
## so one function can turn both server and client failures into a message.
## The client adds NetworkUnavailable, ServerError and RateLimited for failures it detects itself.

const NETWORK_UNAVAILABLE := "NetworkUnavailable"
const SERVER_ERROR := "ServerError"
const RATE_LIMITED := "RateLimited"
const INVALID_CREDENTIALS := "InvalidCredentials"
const VALIDATION_FAILED := "ValidationFailed"
const IDENTIFIER_TAKEN := "IdentifierTaken"
const DISPLAY_NAME_CHANGE_COOLDOWN := "DisplayNameChangeCooldown"

var ok := false
var status := 0
var code := ""
## Each entry is {"field": String, "reason": String}, field names as in AccountFields.cs.
var field_errors: Array[Dictionary] = []
var data: Dictionary = {}
var retry_after_sec := 0
## true = the request failed but may have reached the server (timed out, connection dropped,
## no response, a 5xx answer, or a 2xx answer that could not be read), so the server may already
## have acted on it. false = it certainly did not arrive (could not resolve / connect / finish TLS,
## could not even start), or the server gave a definite answer (4xx, 429).
## Only refresh cares: a refresh that may have arrived may have rotated the token already.
## Does not change `code`; callers that ignore this flag behave exactly as before.
var maybe_delivered := false


static func success(p_status: int, p_data: Dictionary) -> AuthApiResult:
	var result := AuthApiResult.new()
	result.ok = true
	result.status = p_status
	result.data = p_data
	return result


static func failure(p_status: int, p_code: String) -> AuthApiResult:
	var result := AuthApiResult.new()
	result.status = p_status
	result.code = p_code
	return result
