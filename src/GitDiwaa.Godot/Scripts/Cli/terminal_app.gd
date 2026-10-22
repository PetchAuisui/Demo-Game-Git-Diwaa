class_name TerminalApp
extends RefCounted
## โปรแกรมทดสอบ Git แบบ Terminal: รับคำสั่งแล้วส่งเข้า session จริง

var _terminal: CliTerminal
var _session: GitGameSession


func _init(terminal: CliTerminal, session: GitGameSession) -> void:
	_terminal = terminal
	_session = session


## รันคำสั่งเดียวแล้วจบ คืน exit code (coroutine)
func run_command(command: String, print_snapshot: bool) -> int:
	var result := await _session.execute(command)
	_print_result(result)
	if print_snapshot:
		await _print_snapshot()
	return 0 if result.success else 1


## โหมดโต้ตอบ (coroutine) คืน exit code
func run_interactive() -> int:
	_show_header()
	while true:
		_terminal.write("git-diwaa> ")
		var input: Variant = _terminal.read_line()
		if input == null or (input as String).strip_edges().to_lower() == "exit":
			return 0

		var command: String = (input as String).strip_edges()
		if command.is_empty():
			continue

		if await _run_host_command(command):
			continue
		if command == "git commit":
			_terminal.write("Commit message: ")
			var message: Variant = _terminal.read_line()
			if message == null or (message as String).strip_edges().is_empty():
				_terminal.write_error("Commit message cannot be empty.")
				continue
			command = "git commit -m \"%s\"" % (message as String).replace("\"", "\\\"")

		_print_result(await _session.execute(command))
	return 0


## คำสั่งของเกมเอง (ไม่ใช่ git) คืน true เมื่อจัดการแล้ว
func _run_host_command(command: String) -> bool:
	var parts := split_command(command, 3)
	match parts[0].to_lower():
		"help":
			_terminal.write_line(CliOptions.HELP_TEXT)
		"clear":
			_terminal.clear()
		"where":
			_terminal.write_line(_session.info.repository_path)
		"remote-url":
			_terminal.write_line(
					"No repository yet — create one on the simulated GitHub first."
					if _session.info.remote_url.is_empty() else _session.info.remote_url)
		"files":
			var files := _session.files.list_files()
			_terminal.write_line("Working tree is empty." if files.is_empty() else "\n".join(files))
		"write":
			if parts.size() < 3:
				_terminal.write_error("Usage: write <path> <text>")
			else:
				var written := _session.files.write_all_text(parts[1], parts[2])
				if written.ok:
					_terminal.write_line("Wrote '%s'." % parts[1])
				else:
					_terminal.write_error("Operation failed: " + written.message)
		"cat":
			if parts.size() != 2:
				_terminal.write_error("Usage: cat <path>")
			else:
				var read := _session.files.read_all_text(parts[1])
				if not read.ok:
					_terminal.write_error("Operation failed: " + read.message)
				else:
					_terminal.write_line(str(read.value) if read.value != null else "File '%s' not found." % parts[1])
		"delete":
			if parts.size() != 2:
				_terminal.write_error("Usage: delete <path>")
			else:
				var deleted := _session.files.delete(parts[1])
				if not deleted.ok:
					_terminal.write_error("Operation failed: " + deleted.message)
				else:
					_terminal.write_line("Deleted '%s'." % parts[1] if deleted.value == true
							else "File '%s' not found." % parts[1])
		"snapshot":
			await _print_snapshot()
		"graph":
			_print_result(await _session.execute("git log --graph --all --oneline --decorate"))
		_:
			return false
	return true


func _print_snapshot() -> void:
	var snapshot := await _session.inspect()
	_terminal.write_line(JSON.stringify(snapshot.to_dict(), "  "))


func _print_result(result: GitCommandResult) -> void:
	if not result.output.strip_edges().is_empty():
		if result.success:
			_terminal.write_line(result.output)
		else:
			_terminal.write_error(result.output)
		return
	_terminal.write_line("Command completed." if result.success else "Command failed (exit %d)." % result.exit_code)


func _show_header() -> void:
	_terminal.write_line("========================================")
	_terminal.write_line("       Git-Diwaa — Real Git Lab")
	_terminal.write_line("========================================")
	_terminal.write_line("Sandbox: " + _session.info.repository_path)
	if not _session.info.remote_url.is_empty():
		_terminal.write_line("Game remote: " + _session.info.remote_url)
	_terminal.write_line("Commands only affect this isolated game session.")
	_terminal.write_line("Type help for available commands or exit to quit.\n")


## แยกคำแรก ๆ ด้วยช่องว่าง ส่วนที่เหลือท้ายสุดเก็บทั้งก้อนเป็นคำสุดท้าย (เหมือน Split(' ', count))
static func split_command(text: String, max_parts: int) -> Array[String]:
	var parts: Array[String] = []
	var rest := text.strip_edges()
	while not rest.is_empty():
		if parts.size() == max_parts - 1:
			parts.append(rest)
			break
		var space := rest.find(" ")
		if space < 0:
			parts.append(rest)
			break
		parts.append(rest.substr(0, space))
		rest = rest.substr(space + 1).strip_edges(true, false)
	if parts.is_empty():
		parts.append("")
	return parts
