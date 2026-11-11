extends SceneTree
## จุดเริ่มต้นของ CLI:
##   godot --headless --path game --script res://engine/cli/cli_main.gd -- [options]


func _initialize() -> void:
	var exit_code := await _run()
	quit(exit_code)


func _run() -> int:
	var parsed := CliOptions.parse(OS.get_cmdline_user_args())
	if not parsed.ok:
		printerr("Invalid option: " + parsed.message)
		printerr("Run with --help for usage.")
		return 2

	var options: CliOptions = parsed.value
	if options.show_help:
		print(CliOptions.HELP_TEXT)
		return 0

	var factory := RealGitGameSessionFactory.new(options.workspace_root)
	var created: OpResult = await factory.create(options.mission_id, options.attempt_id, RemoteSeed.no_repository())
	if not created.ok:
		printerr("Git-Diwaa could not start: " + created.message)
		return 1

	var session: GitGameSession = created.value
	var app := TerminalApp.new(SystemTerminal.new(), session)
	if options.command == null:
		return await app.run_interactive()
	return await app.run_command(options.command, options.print_snapshot)
