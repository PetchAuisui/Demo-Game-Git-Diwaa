class_name GitCommandResult
extends RefCounted

var success: bool = false
var exit_code: int = 0
var standard_output: String = ""
var standard_error: String = ""
var display_command: String = ""

## ข้อความรวม stdout/stderr สำหรับแสดงให้ผู้เล่น
var output: String:
	get:
		var out_text := standard_output.strip_edges(false, true)
		var err_text := standard_error.strip_edges(false, true)
		if standard_error.strip_edges().is_empty():
			return out_text
		if standard_output.strip_edges().is_empty():
			return err_text
		return out_text + "\n" + err_text


func _init(p_success: bool = false, p_exit_code: int = 0, p_standard_output: String = "",
		p_standard_error: String = "", p_display_command: String = "") -> void:
	success = p_success
	exit_code = p_exit_code
	standard_output = p_standard_output
	standard_error = p_standard_error
	display_command = p_display_command


static func rejected(message: String, command: String) -> GitCommandResult:
	return GitCommandResult.new(false, -1, "", message, command)


func with_streams(p_standard_output: String, p_standard_error: String) -> GitCommandResult:
	return GitCommandResult.new(success, exit_code, p_standard_output, p_standard_error, display_command)
