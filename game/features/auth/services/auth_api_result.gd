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

var ok := false
var status := 0
var code := ""
## Each entry is {"field": String, "reason": String}, field names as in AccountFields.cs.
var field_errors: Array[Dictionary] = []
var data: Dictionary = {}
var retry_after_sec := 0


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
