class_name CliOptions
extends RefCounted
## ตัวเลือกบรรทัดคำสั่งของ Git-Diwaa Real Git Lab

const HELP_TEXT := """Git-Diwaa Real Git Lab

Usage:
  godot --headless --path src/GitDiwaa.Godot --script res://Scripts/Cli/cli_main.gd -- [options]

Options:
  --workspace <path>  Root for isolated game repositories
  --mission <id>      Mission identifier (default: terminal-lab)
  --attempt <id>      Attempt identifier (default: timestamp)
  --command <text>    Run one Git command and exit
  --snapshot          Print repository state after --command
  --help              Show this help

Interactive commands:
  Any allowed git command, for example: git init
  write <path> <text> | cat <path> | delete <path> | files
  snapshot | graph | where | remote-url | help | clear | exit"""

var workspace_root: String = ""
var mission_id: String = "terminal-lab"
var attempt_id: String = ""
## null เมื่อไม่ได้ระบุ --command (โหมดโต้ตอบ)
var command: Variant = null
var print_snapshot: bool = false
var show_help: bool = false


## แยกอาร์กิวเมนต์ คืน OpResult (value = CliOptions) ล้มเหลวพร้อมข้อความเมื่อ option ผิด
static func parse(arguments: PackedStringArray) -> OpResult:
	var options := CliOptions.new()
	options.workspace_root = OS.get_data_dir().path_join("GitDiwaa").path_join("workspaces")
	options.attempt_id = "attempt-" + _timestamp()

	var index := 0
	while index < arguments.size():
		var argument := arguments[index]
		match argument:
			"--workspace", "--mission", "--attempt", "--command":
				index += 1
				if index >= arguments.size() or arguments[index].strip_edges().is_empty():
					return OpResult.failure("Option '%s' requires a value." % argument)
				var value := arguments[index]
				match argument:
					"--workspace":
						options.workspace_root = FsUtil.full_path(_absolute(value))
					"--mission":
						options.mission_id = value
					"--attempt":
						options.attempt_id = value
					"--command":
						options.command = value
			"--snapshot":
				options.print_snapshot = true
			"--help", "-h":
				options.show_help = true
			_:
				return OpResult.failure("Unknown option '%s'." % argument)
		index += 1

	if options.print_snapshot and options.command == null:
		return OpResult.failure("--snapshot requires --command.")
	return OpResult.success(options)


## path สัมพัทธ์ถือว่าอิงโฟลเดอร์ที่ผู้ใช้เรียกคำสั่ง (PWD)
static func _absolute(path: String) -> String:
	if FsUtil.is_rooted(path):
		return path
	var working := OS.get_environment("PWD")
	return path if working.is_empty() else working.path_join(path)


static func _timestamp() -> String:
	var now := Time.get_datetime_dict_from_system()
	var millis := int(fmod(Time.get_unix_time_from_system(), 1.0) * 1000.0)
	return "%04d%02d%02d-%02d%02d%02d-%03d" % [now["year"], now["month"], now["day"], now["hour"], now["minute"], now["second"], millis]
