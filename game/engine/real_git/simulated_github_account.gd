class_name SimulatedGitHubAccount
extends GitRemoteAccount
## บัญชีผู้เล่นบน GitHub จำลอง: repo แรก (ถ้ามี) มาจาก seed ของด่าน ผู้เล่นสร้าง repo ว่างเพิ่มได้เอง
## แต่ละ repo มี bare repository และ SimulatedGitHubHost ของตัวเอง

const MAX_NAME_LENGTH := 64

var _sandbox: GitSandbox
var _workspace: GitWorkspaceManager
var _runner: GitProcessRunner
var _registry: RemoteRegistry
var _seed: RemoteSeed
var _hosts: Array[SimulatedGitHubHost] = []
var _creating: bool = false


func _init(sandbox: GitSandbox, workspace: GitWorkspaceManager, runner: GitProcessRunner,
		registry: RemoteRegistry, remote_seed: RemoteSeed, primary: SimulatedGitHubHost) -> void:
	_sandbox = sandbox
	_workspace = workspace
	_runner = runner
	_registry = registry
	_seed = remote_seed
	owner = remote_seed.owner
	if primary != null:
		_hosts.append(primary)


func list_repositories() -> Array[RemoteRepositoryInfo]:
	var repos: Array[RemoteRepositoryInfo] = []
	for host in _hosts.duplicate():
		repos.append(await host.get_repository())
	return repos


func open_repository(name: String) -> GitRemoteHost:
	for host in _hosts:
		if host.repository_name.to_lower() == name.to_lower():
			return host
	return null


func create_repository(name: String, description: String) -> OpResult:
	name = name.strip_edges()
	if name.is_empty():
		return OpResult.failure("ต้องตั้งชื่อ repository")
	if name.length() > MAX_NAME_LENGTH:
		return OpResult.failure("ชื่อ repository ยาวเกิน %d ตัวอักษร" % MAX_NAME_LENGTH)
	if not GitWorkspaceManager.is_valid_identifier(name):
		return OpResult.failure("ชื่อ repository ใช้ได้เฉพาะตัวอักษรอังกฤษ ตัวเลข - และ _")

	# กันสร้างชื่อเดียวกันซ้อนกัน (เช็กชื่อซ้ำกับสร้าง bare repo ต้องเป็นก้อนเดียว)
	var tree := Engine.get_main_loop() as SceneTree
	while _creating:
		await tree.process_frame
	_creating = true

	if open_repository(name) != null:
		_creating = false
		return OpResult.failure("มี repository ชื่อ %s อยู่แล้ว" % name)

	var new_seed := RemoteSeed.empty(owner, name)
	new_seed.description = description.strip_edges()
	new_seed.rules = _seed.rules
	var created := await _workspace.create_bare_remote(_sandbox, _runner, "repo-" + name, new_seed.clone_url)
	if not created.ok:
		_creating = false
		return created

	var remote: LocalRemote = created.value
	_registry.add(remote)
	var host := SimulatedGitHubHost.new(_sandbox, remote, _runner, new_seed)
	_hosts.append(host)
	_creating = false

	return OpResult.success(await host.get_repository())
