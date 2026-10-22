class_name GitTime
extends RefCounted
## เวลาทั้งหมดเก็บเป็น Unix timestamp (วินาที, float) แทน DateTimeOffset

const MONTHS: Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

static var _iso_pattern: RegEx


static func now() -> float:
	return Time.get_unix_time_from_system()


## แปลง ISO 8601 ที่ Git พิมพ์ออกมา (เช่น 2026-10-22T10:00:00+07:00 หรือ ...Z) เป็น Unix timestamp
## (Time.get_unix_time_from_datetime_string ทิ้ง offset ไป จึงคำนวณเองที่นี่)
static func parse_iso(text: String) -> float:
	if _iso_pattern == null:
		_iso_pattern = RegEx.new()
		_iso_pattern.compile("^(\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2})(?:\\.\\d+)?(?:Z|([+-])(\\d{2}):?(\\d{2}))?$")
	var found := _iso_pattern.search(text.strip_edges())
	if found == null:
		return 0.0
	var seconds := float(Time.get_unix_time_from_datetime_string(found.get_string(1)))
	if found.get_string(2) != "":
		var offset := found.get_string(3).to_int() * 3600 + found.get_string(4).to_int() * 60
		seconds -= offset if found.get_string(2) == "+" else -offset
	return seconds


static func to_iso(unix: float) -> String:
	return Time.get_datetime_string_from_unix_time(int(unix)) + "Z"


## รูปแบบวันที่ที่ Git ใช้ใน GIT_AUTHOR_DATE / GIT_COMMITTER_DATE
static func git_date(unix: float) -> String:
	return "%d +0000" % int(unix)


static func _local(unix: float) -> Dictionary:
	var bias_seconds: int = Time.get_time_zone_from_system()["bias"] * 60
	return Time.get_datetime_dict_from_unix_time(int(unix) + bias_seconds)


## กุญแจวันที่ท้องถิ่น (ใช้จัดกลุ่ม commit ตามวัน)
static func local_day_key(unix: float) -> String:
	var d := _local(unix)
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]


## "MMM d, yyyy" เช่น Oct 22, 2026
static func date_label(unix: float) -> String:
	var d := _local(unix)
	return "%s %d, %d" % [MONTHS[int(d["month"]) - 1], d["day"], d["year"]]


## "dd MMM yyyy HH:mm" เวลาท้องถิ่น
static func format_local(unix: float) -> String:
	var d := _local(unix)
	return "%02d %s %d %02d:%02d" % [d["day"], MONTHS[int(d["month"]) - 1], d["year"], d["hour"], d["minute"]]


static func time_ago(unix: float) -> String:
	var span := now() - unix
	if span < 60.0:
		return "just now"
	if span < 3600.0:
		return _ago(int(span / 60.0), "minute")
	if span < 86400.0:
		return _ago(int(span / 3600.0), "hour")
	if span < 86400.0 * 30.0:
		return _ago(int(span / 86400.0), "day")
	return date_label(unix)


static func _ago(number: int, unit: String) -> String:
	return "%d %s%s ago" % [number, unit, "" if number == 1 else "s"]
