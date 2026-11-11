class_name GitRemoteHost
extends RefCounted
## ข้อมูลและการกระทำของหน้า Remote Repository ที่จำลอง GitHub
## (Code / Commits / Branches / Pull requests) โดยไม่ออกเครือข่ายจริง
## คลาสนี้เป็นสัญญา (interface) ให้ SimulatedGitHubHost สืบทอด
##
## เมธอดที่ใช้ git จริงเป็น coroutine (เรียกด้วย await) ส่วนที่เหลือทำงานทันที


func get_repository() -> RemoteRepositoryInfo:
	push_error("GitRemoteHost.get_repository ยังไม่ได้ implement")
	return null


func list_branches() -> Array[RemoteBranchInfo]:
	push_error("GitRemoteHost.list_branches ยังไม่ได้ implement")
	return []


func list_commits(_branch: String, _limit: int = 30) -> Array[RemoteCommitInfo]:
	push_error("GitRemoteHost.list_commits ยังไม่ได้ implement")
	return []


func list_files(_branch: String, _path: String = "") -> Array[RemoteFileEntry]:
	push_error("GitRemoteHost.list_files ยังไม่ได้ implement")
	return []


## null เมื่อไม่พบไฟล์
func read_file(_branch: String, _path: String) -> Variant:
	push_error("GitRemoteHost.read_file ยังไม่ได้ implement")
	return null


func delete_branch(_branch: String) -> bool:
	push_error("GitRemoteHost.delete_branch ยังไม่ได้ implement")
	return false


func list_pull_requests() -> Array[PullRequestInfo]:
	push_error("GitRemoteHost.list_pull_requests ยังไม่ได้ implement")
	return []


## คืน OpResult (value = PullRequestInfo) ล้มเหลวพร้อมข้อความเมื่อเงื่อนไขไม่ครบ
func open_pull_request(_title: String, _body: String, _author: String, _source_branch: String,
		_target_branch: String) -> OpResult:
	push_error("GitRemoteHost.open_pull_request ยังไม่ได้ implement")
	return OpResult.failure("not implemented")


## null เมื่อไม่พบ PR
func get_pull_request(_number: int) -> PullRequestDetail:
	push_error("GitRemoteHost.get_pull_request ยังไม่ได้ implement")
	return null


func review_pull_request(_number: int, _reviewer: String, _verdict: int, _body: String = "") -> PullRequestActionResult:
	push_error("GitRemoteHost.review_pull_request ยังไม่ได้ implement")
	return null


## คอมเมนต์รายบรรทัดใน diff: start_review = true เก็บเป็น pending review
## (ส่งพร้อมกันตอน review_pull_request) ไม่งั้นโพสต์ทันที
func add_line_comment(_number: int, _author: String, _path: String, _line: int, _on_new_side: bool,
		_body: String, _start_review: bool) -> PullRequestActionResult:
	push_error("GitRemoteHost.add_line_comment ยังไม่ได้ implement")
	return null


## คอมเมนต์ทั่วไปบน PR (ช่อง Add a comment) ไม่แตะ pending review ของผู้เขียน
func comment_on_pull_request(_number: int, _author: String, _body: String) -> PullRequestActionResult:
	push_error("GitRemoteHost.comment_on_pull_request ยังไม่ได้ implement")
	return null


func close_pull_request(_number: int) -> PullRequestActionResult:
	push_error("GitRemoteHost.close_pull_request ยังไม่ได้ implement")
	return null


func merge_pull_request(_number: int) -> PullRequestActionResult:
	push_error("GitRemoteHost.merge_pull_request ยังไม่ได้ implement")
	return null
