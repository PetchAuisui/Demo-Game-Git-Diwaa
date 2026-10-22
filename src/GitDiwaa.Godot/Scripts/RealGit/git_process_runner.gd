class_name GitProcessRunner
extends RefCounted
## รัน git จริงเป็น process แยก (ผ่าน OS.execute_with_pipe) พร้อม environment ที่กัน sandbox
## เมธอด run / run_all เป็น coroutine: เรียกด้วย await โดยไม่บล็อกเฟรมของเกม

const TIMEOUT_MSEC := 15000
## NUL ในผลลัพธ์ของ git (เช่น status -z) แปลงเป็นตัวอักษรนี้ เพราะ String ของ Godot เก็บ NUL ไม่ได้
const NUL_CHAR := "\u0001"


class Job extends RefCounted:
	var command: String = ""
	var pid: int = -1
	var spawn_error: String = ""
	var started_msec: int = 0
	var stdio: FileAccess
	var stderr: FileAccess
	var stdout_thread: Thread
	var stderr_thread: Thread


## รัน `git <arguments>` ในโฟลเดอร์ working_directory
## extra_environment คือตัวแปร environment เพิ่มเติมสำหรับคำสั่งนี้ (เช่น วันที่ของ commit)
func run(sandbox: GitSandbox, working_directory: String, arguments: Array[String],
		extra_environment: Dictionary = {}) -> GitCommandResult:
	var job := _spawn(sandbox, working_directory, arguments, extra_environment)
	return await _finish(job)


## รันหลายคำสั่งพร้อมกัน แต่ละรายการคือ {"directory": String, "arguments": Array[String]}
## คืนผลตามลำดับเดียวกับที่ส่งมา
func run_all(sandbox: GitSandbox, requests: Array) -> Array[GitCommandResult]:
	var jobs: Array[Job] = []
	for request in requests:
		jobs.append(_spawn(sandbox, request["directory"], request["arguments"], {}))
	var results: Array[GitCommandResult] = []
	for job in jobs:
		results.append(await _finish(job))
	return results


func _spawn(sandbox: GitSandbox, working_directory: String, arguments: Array[String],
		extra_environment: Dictionary) -> Job:
	var job := Job.new()
	job.command = _format_command(arguments)

	var full_arguments := PackedStringArray(["-C", working_directory])
	full_arguments.append_array(PackedStringArray(arguments))

	var environment := _sandbox_environment(sandbox)
	environment.merge(extra_environment, true)
	var saved := _apply_environment(environment)
	var info := OS.execute_with_pipe("git", full_arguments)
	_restore_environment(saved)

	if info.is_empty():
		job.spawn_error = "Unable to start git. Is Git installed and available on PATH?"
		return job

	job.pid = info["pid"]
	job.stdio = info["stdio"]
	job.stderr = info["stderr"]
	job.started_msec = Time.get_ticks_msec()
	job.stdout_thread = Thread.new()
	job.stderr_thread = Thread.new()
	job.stdout_thread.start(_read_all.bind(job.stdio))
	job.stderr_thread.start(_read_all.bind(job.stderr))
	return job


func _finish(job: Job) -> GitCommandResult:
	if job.pid < 0:
		return GitCommandResult.rejected(job.spawn_error, job.command)

	var tree := Engine.get_main_loop() as SceneTree
	var timed_out := false
	while OS.is_process_running(job.pid):
		if Time.get_ticks_msec() - job.started_msec > TIMEOUT_MSEC:
			OS.kill(job.pid)
			timed_out = true
			break
		await tree.process_frame

	var out_bytes: PackedByteArray = job.stdout_thread.wait_to_finish()
	var err_bytes: PackedByteArray = job.stderr_thread.wait_to_finish()
	job.stdio.close()
	job.stderr.close()

	if timed_out:
		return GitCommandResult.rejected(
				"Git command timed out after %d seconds." % (TIMEOUT_MSEC / 1000), job.command)

	var exit_code := OS.get_process_exit_code(job.pid)
	return GitCommandResult.new(exit_code == 0, exit_code, _decode(out_bytes), _decode(err_bytes), job.command)


## อ่านท่อจนจบ (บล็อก จึงรันในเธรดแยก)
static func _read_all(file: FileAccess) -> PackedByteArray:
	var bytes := PackedByteArray()
	while true:
		var chunk := file.get_buffer(4096)
		if chunk.is_empty():
			break
		bytes.append_array(chunk)
	return bytes


static func _decode(bytes: PackedByteArray) -> String:
	if bytes.has(0):
		for index in bytes.size():
			if bytes[index] == 0:
				bytes[index] = 1
	return bytes.get_string_from_utf8()


static func _sandbox_environment(sandbox: GitSandbox) -> Dictionary:
	return {
		"GIT_CONFIG_GLOBAL": sandbox.git_config_path,
		"GIT_CONFIG_NOSYSTEM": "1",
		"GIT_TERMINAL_PROMPT": "0",
		"GCM_INTERACTIVE": "Never",
		"GIT_EDITOR": "true",
		"GIT_SEQUENCE_EDITOR": "true",
		"GIT_MERGE_AUTOEDIT": "no",
		"LC_ALL": "C",
		"GIT_CONFIG_COUNT": "2",
		"GIT_CONFIG_KEY_0": "core.hooksPath",
		"GIT_CONFIG_VALUE_0": sandbox.hooks_path,
		"GIT_CONFIG_KEY_1": "protocol.file.allow",
		"GIT_CONFIG_VALUE_1": "always",
	}


## ตั้ง environment ของโปรเซสเกมชั่วคราวให้ process ลูกสืบทอด คืนค่าเดิมไว้ใช้คืนสภาพ
static func _apply_environment(environment: Dictionary) -> Dictionary:
	var saved := {}
	for key: String in environment:
		saved[key] = OS.get_environment(key) if OS.has_environment(key) else null
		OS.set_environment(key, str(environment[key]))
	return saved


static func _restore_environment(saved: Dictionary) -> void:
	for key: String in saved:
		if saved[key] == null:
			OS.unset_environment(key)
		else:
			OS.set_environment(key, saved[key])


static func _format_command(arguments: Array[String]) -> String:
	var parts: PackedStringArray = []
	for argument in arguments:
		parts.append(_quote_for_display(argument))
	return "git " + " ".join(parts)


static func _quote_for_display(value: String) -> String:
	if value.strip_edges() != value or value.contains(" ") or value.contains("\t") or value.contains("\n"):
		return "\"" + value.replace("\"", "\\\"") + "\""
	return value
