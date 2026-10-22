class_name GitHubIcons
extends RefCounted
## ไอคอนแบบ GitHub วาดเป็น SVG เส้นเรียบง่าย (viewBox 16x16) แล้วแปลงเป็น texture ตามสีที่ขอ
## ไม่พึ่งฟอนต์ของระบบ จึงหน้าตาเหมือนกันทุกเครื่อง

static var _cache: Dictionary = {}


## size = ขนาดที่แสดง (px)
## render_scale = เรนเดอร์กี่เท่าของ size ปุ่ม/รูปใช้ 3 เท่า (theme จำกัดความกว้างให้) ส่วน LineEdit ใช้ 1
static func get_icon(icon: int, color: Color, size: int = 16, render_scale: float = 3.0) -> Texture2D:
	var hex := "#" + color.to_html(false)
	var key := "%d|%s|%d|%s" % [icon, hex, size, render_scale]
	if _cache.has(key):
		return _cache[key]

	var svg := "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"%d\" height=\"%d\" viewBox=\"0 0 16 16\">" % [size, size] \
			+ "<g fill=\"none\" stroke=\"%s\" stroke-width=\"1.5\" stroke-linecap=\"round\" stroke-linejoin=\"round\">" % hex \
			+ _body(icon).replace("$c", hex) \
			+ "</g></svg>"

	var image := Image.new()
	var texture: Texture2D = null
	if image.load_svg_from_string(svg, render_scale) == OK:
		texture = ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture


static func _body(icon: int) -> String:
	match icon:
		GhIcon.REPO:
			return "<path d=\"M3 3.5A1.5 1.5 0 0 1 4.5 2H13v10H4.5A1.5 1.5 0 0 0 3 13.5Z\"/>" \
					+ "<path d=\"M3 13.5A1.5 1.5 0 0 0 4.5 15H13v-3\"/>"
		GhIcon.BOOK:
			return "<path d=\"M2 3.5C4 2.75 6.5 2.75 8 4v9c-1.5-1.25-4-1.25-6-.5Z\"/>" \
					+ "<path d=\"M14 3.5C12 2.75 9.5 2.75 8 4v9c1.5-1.25 4-1.25 6-.5Z\"/>"
		GhIcon.CODE:
			return "<polyline points=\"5.5,4 1.5,8 5.5,12\"/><polyline points=\"10.5,4 14.5,8 10.5,12\"/>"
		GhIcon.PULL_OPEN:
			return "<circle cx=\"4\" cy=\"3.5\" r=\"1.75\"/><circle cx=\"4\" cy=\"12.5\" r=\"1.75\"/><circle cx=\"12\" cy=\"12.5\" r=\"1.75\"/>" \
					+ "<path d=\"M4 5.25v5.5\"/><path d=\"M12 10.75V6.5a2 2 0 0 0-2-2H7.5\"/><path d=\"M9.25 2.75 7.5 4.5l1.75 1.75\"/>"
		GhIcon.PULL_MERGED:
			return "<circle cx=\"4\" cy=\"3.5\" r=\"1.75\"/><circle cx=\"4\" cy=\"12.5\" r=\"1.75\"/><circle cx=\"12\" cy=\"8\" r=\"1.75\"/>" \
					+ "<path d=\"M4 5.25v5.5\"/><path d=\"M4 5.5C4 7 5 8 7 8h3.25\"/>"
		GhIcon.PULL_CLOSED:
			return "<circle cx=\"4\" cy=\"3.5\" r=\"1.75\"/><circle cx=\"4\" cy=\"12.5\" r=\"1.75\"/><circle cx=\"12\" cy=\"12.5\" r=\"1.75\"/>" \
					+ "<path d=\"M4 5.25v5.5\"/><path d=\"M12 10.75V6\"/><path d=\"M10.5 2.5l3 3M13.5 2.5l-3 3\"/>"
		GhIcon.BRANCH:
			return "<circle cx=\"4\" cy=\"3.5\" r=\"1.75\"/><circle cx=\"4\" cy=\"12.5\" r=\"1.75\"/><circle cx=\"12\" cy=\"5.5\" r=\"1.75\"/>" \
					+ "<path d=\"M4 5.25v5.5\"/><path d=\"M12 7.25c0 2.25-1.5 2.25-4 2.25H7c-2 0-3 .5-3 1.25\"/>"
		GhIcon.HISTORY:
			return "<circle cx=\"8\" cy=\"8\" r=\"6\"/><path d=\"M8 4.5V8l2.5 1.5\"/>"
		GhIcon.COMMIT:
			return "<circle cx=\"8\" cy=\"8\" r=\"2.75\"/><path d=\"M1.5 8h3.75M10.75 8h3.75\"/>"
		GhIcon.FILE:
			return "<path d=\"M4 1.75h5.25L13 5.5v8.75H4z\"/><path d=\"M9.25 1.75V5.5H13\"/>"
		GhIcon.FOLDER:
			return "<path d=\"M1.75 3.5h4.5l1.5 1.75h6.5v7.75H1.75z\" fill=\"$c\" stroke=\"none\"/>"
		GhIcon.CHECK:
			return "<path d=\"M3.5 8.5l3 3 6-7\" stroke-width=\"2\"/>"
		GhIcon.X:
			return "<path d=\"M3.5 3.5l9 9M12.5 3.5l-9 9\" stroke-width=\"2\"/>"
		GhIcon.COMMENT:
			return "<path d=\"M2.5 3.5h11v7.5H8.5L5.5 13.5V11h-3z\"/>"
		GhIcon.COPY:
			return "<rect x=\"5.5\" y=\"5.5\" width=\"8\" height=\"8\" rx=\"1.5\"/>" \
					+ "<path d=\"M10.5 5.5V4A1.5 1.5 0 0 0 9 2.5H4A1.5 1.5 0 0 0 2.5 4v5A1.5 1.5 0 0 0 4 10.5h1.5\"/>"
		GhIcon.SEARCH:
			return "<circle cx=\"7\" cy=\"7\" r=\"4.5\"/><path d=\"M10.5 10.5L14 14\"/>"
		GhIcon.CHEVRON_DOWN:
			return "<path d=\"M4 6l4 4 4-4\"/>"
		GhIcon.CHEVRON_RIGHT:
			return "<path d=\"M6 4l4 4-4 4\"/>"
		GhIcon.TRASH:
			return "<path d=\"M2.75 4.5h10.5M6 4.5V2.75h4V4.5\"/><path d=\"M4 4.5l.6 8.75h6.8L12 4.5\"/>"
		GhIcon.LOCK:
			return "<rect x=\"3.5\" y=\"7\" width=\"9\" height=\"6.5\" rx=\"1.25\"/><path d=\"M5.5 7V5a2.5 2.5 0 0 1 5 0v2\"/>"
		GhIcon.ALERT:
			return "<path d=\"M8 2L14.5 13.5H1.5z\"/><path d=\"M8 6.5v3.25M8 11.5v.25\"/>"
		GhIcon.PLUS:
			return "<path d=\"M8 3v10M3 8h10\"/>"
		GhIcon.ARROW_LEFT:
			return "<path d=\"M13 8H3M7 4L3 8l4 4\"/>"
		GhIcon.CLOUD:
			return "<g transform=\"scale(0.6667)\"><path d=\"M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z\" stroke-width=\"2.25\"/></g>"
		GhIcon.REFRESH:
			return "<g transform=\"scale(0.6667)\" stroke-width=\"2.25\"><polyline points=\"23 4 23 10 17 10\"/><polyline points=\"1 20 1 14 7 14\"/>" \
					+ "<path d=\"M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15\"/></g>"
		GhIcon.INFO:
			return "<circle cx=\"8\" cy=\"8\" r=\"6\"/><path d=\"M8 7.25v3.5M8 5v.25\"/>"
	return ""
