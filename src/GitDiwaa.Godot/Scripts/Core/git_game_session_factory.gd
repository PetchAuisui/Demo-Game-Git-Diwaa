class_name GitGameSessionFactory
extends RefCounted


## คืน OpResult (value = GitGameSession) เป็น coroutine
## remote_seed = สถานะเริ่มต้นของ GitHub จำลอง (null = บัญชีที่ยังไม่มี repo)
func create(_mission_id: String, _attempt_id: String, _remote_seed: RemoteSeed = null) -> OpResult:
	push_error("GitGameSessionFactory.create ยังไม่ได้ implement")
	return OpResult.failure("not implemented")
