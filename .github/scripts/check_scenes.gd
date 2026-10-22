extends SceneTree
# Headless smoke check: every .gd/.tscn/.tres must load, and every scene must instantiate
# (this also verifies that the GDScript attached to nodes parses and resolves its class names).

var failures := 0


func _initialize() -> void:
	var files: Array[String] = []
	_collect("res://", files)
	files.sort()
	print("Checking %d resources" % files.size())

	for path in files:
		var res := ResourceLoader.load(path)
		if res == null:
			_fail("cannot load %s" % path)
			continue
		if res is PackedScene:
			var node: Node = res.instantiate()
			if node == null:
				_fail("cannot instantiate %s" % path)
			else:
				node.free()
		print("ok   %s" % path)

	if failures > 0:
		printerr("%d resource(s) failed" % failures)
	quit(1 if failures > 0 else 0)


func _collect(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		if sub.begins_with("."):
			continue
		_collect(dir_path.path_join(sub), out)
	for f in dir.get_files():
		if f.ends_with(".gd") or f.ends_with(".tscn") or f.ends_with(".tres"):
			out.append(dir_path.path_join(f))


func _fail(msg: String) -> void:
	failures += 1
	printerr("FAIL " + msg)
