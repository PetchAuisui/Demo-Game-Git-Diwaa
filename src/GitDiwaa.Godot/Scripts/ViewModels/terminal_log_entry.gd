class_name TerminalLogEntry
extends RefCounted

var type: int = TerminalLogType.OUTPUT
var text: String = ""
## Unix timestamp (วินาที)
var timestamp: float = 0.0


func _init(p_type: int = TerminalLogType.OUTPUT, p_text: String = "", p_timestamp: float = 0.0) -> void:
	type = p_type
	text = p_text
	timestamp = p_timestamp


static func command(cmd: String) -> TerminalLogEntry:
	return TerminalLogEntry.new(TerminalLogType.COMMAND, cmd, GitTime.now())


static func output(text: String) -> TerminalLogEntry:
	return TerminalLogEntry.new(TerminalLogType.OUTPUT, text, GitTime.now())


static func error(err: String) -> TerminalLogEntry:
	return TerminalLogEntry.new(TerminalLogType.ERROR, err, GitTime.now())


static func info(text: String) -> TerminalLogEntry:
	return TerminalLogEntry.new(TerminalLogType.INFO, text, GitTime.now())


static func system(text: String) -> TerminalLogEntry:
	return TerminalLogEntry.new(TerminalLogType.SYSTEM, text, GitTime.now())
