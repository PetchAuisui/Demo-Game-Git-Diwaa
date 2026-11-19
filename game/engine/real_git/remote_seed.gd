class_name RemoteSeed
extends RefCounted
## สถานะเริ่มต้นของ GitHub จำลอง: เจ้าของ ชื่อ repo และประวัติที่มีอยู่แล้ว (ถ้ามี)

const DEFAULT_OWNER := "user"
const DEFAULT_NAME := "my-project"

var owner: String = DEFAULT_OWNER
var name: String = DEFAULT_NAME
var description: String = ""
var commits: Array[SeedCommit] = []
var rules: RemoteRules = RemoteRules.new()
## true = บัญชีเริ่มต้นโดยไม่มี repo เลย ผู้เล่นต้องสร้างเองผ่านหน้า New repository
var starts_without_repository: bool = false
## ที่อยู่เก่าของคลังที่ย้ายไปแล้ว ("" = ไม่มี) — policy ยอมให้ผูกสายเชื่อมไปได้ แต่ไปถึงไม่ได้จริง
## ใช้สอน git remote set-url (สายเชื่อมชี้ที่อยู่เก่า ต้องเปลี่ยนเป็นที่อยู่ใหม่)
var retired_url: String = ""

var clone_url: String:
	get:
		return "https://magic-vault.com/%s/%s.git" % [owner, name]


func _init(p_owner: String = DEFAULT_OWNER, p_name: String = DEFAULT_NAME, p_description: String = "",
		p_commits: Array[SeedCommit] = []) -> void:
	owner = p_owner
	name = p_name
	description = p_description
	commits = p_commits


## repo ว่างที่ผู้เล่นเป็นเจ้าของ ต้อง push งานขึ้นไปเอง
static func empty(p_owner: String = DEFAULT_OWNER, p_name: String = DEFAULT_NAME) -> RemoteSeed:
	return RemoteSeed.new(p_owner, p_name, "", [] as Array[SeedCommit])


## บัญชีที่ยังไม่มี repo ใดๆ (ชื่อ repo แรกผู้เล่นตั้งเอง)
static func no_repository(p_owner: String = DEFAULT_OWNER) -> RemoteSeed:
	var remote_seed := RemoteSeed.empty(p_owner)
	remote_seed.starts_without_repository = true
	return remote_seed


func copy() -> RemoteSeed:
	var clone := RemoteSeed.new(owner, name, description, commits)
	clone.rules = rules
	clone.starts_without_repository = starts_without_repository
	clone.retired_url = retired_url
	return clone
