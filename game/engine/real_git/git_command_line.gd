class_name GitCommandLine
extends RefCounted
## แยกบรรทัดคำสั่งของผู้เล่นเป็น token (รองรับ ' และ " และ \" \\ ภายใน "")


## คืน OpResult (value = Array[String]) ล้มเหลวเมื่อเครื่องหมายคำพูดไม่ปิด
static func tokenize(input: String) -> OpResult:
	var tokens: Array[String] = []
	var current := ""
	var quote := ""
	var index := 0
	while index < input.length():
		var character := input[index]
		if quote != "":
			if character == quote:
				quote = ""
				index += 1
				continue
			if quote == "\"" and character == "\\" and index + 1 < input.length() \
					and (input[index + 1] == "\"" or input[index + 1] == "\\"):
				index += 1
				current += input[index]
				index += 1
				continue
			current += character
			index += 1
			continue

		if character == "'" or character == "\"":
			quote = character
		elif _is_whitespace(character):
			if current != "":
				tokens.append(current)
				current = ""
		else:
			current += character
		index += 1

	if quote != "":
		return OpResult.failure("Unterminated quote.")
	if current != "":
		tokens.append(current)
	return OpResult.success(tokens)


static func _is_whitespace(character: String) -> bool:
	return character.strip_edges().is_empty()
