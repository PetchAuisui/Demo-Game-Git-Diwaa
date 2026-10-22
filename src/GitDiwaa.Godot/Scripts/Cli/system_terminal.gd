class_name SystemTerminal
extends CliTerminal
## Terminal จริงของระบบ (stdin / stdout / stderr)

var _buffer := PackedByteArray()
var _eof := false


func read_line() -> Variant:
	while true:
		var newline := _buffer.find(10)
		if newline >= 0:
			var line := _buffer.slice(0, newline).get_string_from_utf8()
			_buffer = _buffer.slice(newline + 1)
			return line.trim_suffix("\r")
		if _eof:
			break
		var chunk := OS.read_buffer_from_stdin(4096)
		if chunk.is_empty():
			_eof = true
		else:
			_buffer.append_array(chunk)

	if _buffer.is_empty():
		return null
	var rest := _buffer.get_string_from_utf8()
	_buffer = PackedByteArray()
	return rest.trim_suffix("\r")


func write(text: String) -> void:
	printraw(text)


func write_line(text: String = "") -> void:
	print(text)


func write_error(text: String) -> void:
	printerr(text)


func clear() -> void:
	printraw("\u001b[2J\u001b[H")
