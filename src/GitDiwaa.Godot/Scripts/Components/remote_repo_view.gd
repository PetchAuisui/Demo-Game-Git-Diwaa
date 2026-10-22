class_name RemoteRepoView
extends Control
## หน้า Remote Repository จำลอง GitHub (ธีม dark): Code (เปิดโฟลเดอร์/ไฟล์ได้), Commits, Branches,
## Pull requests (สร้าง/ดู diff/review/merge/ปิด) อ่านและสั่งงานผ่าน GitRemoteHost เท่านั้น

signal back_requested

enum Page { REPOS, NEW_REPO, CODE, BLOB, COMMITS, BRANCHES, PULLS, NEW_PULL, PULL_DETAIL }

enum PullTab { CONVERSATION, COMMITS, FILES }

const NO_SCROLL := -1

var _account: GitRemoteAccount
var _host: GitRemoteHost
var _back_button: Button
var _restore_scroll := NO_SCROLL
var _repo: RemoteRepositoryInfo
var _page: int = Page.REPOS
var _branch := "main"
var _path := ""
var _pull_number := 0
var _pull_tab: int = PullTab.CONVERSATION
var _show_closed := false
var _new_pull_source := ""
var _status := ""
var _status_is_error := false

var _owner_label: Label
var _repo_label: Label
var _address_path: Label
var _avatar_slot: Control
var _tabs: HBoxContainer
var _scroll: ScrollContainer
var _content: VBoxContainer
var _window: PanelContainer
var _repo_header: Control
var _room_backdrop: TextureRect
var _top_margin: MarginContainer
var _header_margin: MarginContainer
var _body_margin: MarginContainer

var _refreshing := false
var _refresh_queued := false


## ความกว้างสูงสุดของเนื้อหา (หัว repo และตัวหน้าจัดกึ่งกลางให้ตรงกัน) จอกว้างขึ้นก็ไม่ยืดตาม
static func _content_max_width() -> int:
	return _s(1320)


static func _s(pixels: float) -> int:
	return GitHubTheme.s(pixels)


## โครงหน้าอยู่ใน Scenes/RemoteRepoView.tscn (แถบบน หัว repo พื้นที่เลื่อน) โค้ดนี้แค่ผูก node ใส่ไอคอน
## และต่อสัญญาณ ส่วนเนื้อหาของแต่ละหน้าสร้างตามข้อมูลลงใน Content
func _ready() -> void:
	theme = GitHubTheme.create() # ธีมเป็นโค้ดเพราะสเกลและฟอนต์คำนวณตอนรัน
	get_viewport().gui_release_focus() # ไม่ให้ช่องพิมพ์ของ terminal ด้านหลังรับคีย์บอร์ดต่อ

	_window = get_node("%Window")
	_room_backdrop = get_node("%RoomBackdrop")
	_top_margin = get_node("%TopMargin")
	_back_button = get_node("%BackButton")
	_address_path = get_node("%AddressPath")
	_avatar_slot = get_node("%AvatarSlot")
	_repo_header = get_node("%RepoHeader")
	_header_margin = get_node("%HeaderMargin")
	_owner_label = get_node("%OwnerLabel")
	_repo_label = get_node("%RepoLabel")
	_tabs = get_node("%Tabs")
	_scroll = get_node("%Scroll")
	_body_margin = get_node("%BodyMargin")
	_content = get_node("%Content")

	# ไอคอน SVG เรนเดอร์ตามสเกลตอนรัน จึงใส่จากโค้ด ส่วนขนาดและตำแหน่งอยู่ใน scene
	(get_node("%LockIcon") as TextureRect).texture = GitHubIcons.get_icon(GhIcon.LOCK, GitHubTheme.FG_MUTED, _s(14))
	(get_node("%RepoIcon") as TextureRect).texture = GitHubIcons.get_icon(GhIcon.REPO, GitHubTheme.FG_MUTED, _s(18))
	(get_node("%EscLabel") as Label).add_theme_font_override("font", GitHubTheme.mono_font())
	_repo_label.add_theme_font_override("font", GitHubTheme.bold_font())

	_back_button.icon = GitHubIcons.get_icon(GhIcon.ARROW_LEFT, GitHubTheme.FG_MUTED, _s(16))
	_back_button.pressed.connect(func() -> void: go(Page.REPOS))

	var refresh := get_node("%RefreshButton") as Button
	refresh.icon = GitHubIcons.get_icon(GhIcon.REFRESH, GitHubTheme.FG_MUTED, _s(16))
	refresh.pressed.connect(func() -> void: go(_page))

	var close := get_node("%CloseButton") as Button
	close.icon = GitHubIcons.get_icon(GhIcon.X, GitHubTheme.FG_MUTED, _s(16))
	close.pressed.connect(func() -> void: back_requested.emit())

	_owner_label.gui_input.connect(func(input: InputEvent) -> void:
		if input is InputEventMouseButton and input.pressed and input.button_index == MOUSE_BUTTON_LEFT:
			go(Page.REPOS))

	_scroll.get_v_scroll_bar().visibility_changed.connect(_update_gutters)
	_window.resized.connect(_update_gutters)
	_update_gutters.call_deferred()


## กด Esc เพื่อกลับ Sandbox ดักใน _input (ก่อน GUI) เพราะโฟกัสอาจค้างที่ช่องพิมพ์ของ terminal
## ยกเว้นขณะพิมพ์ในช่องของหน้านี้เอง (ให้ Esc ใช้เลิกพิมพ์ก่อน)
func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	var focus := get_viewport().gui_get_focus_owner()
	if (focus is LineEdit or focus is TextEdit) and is_ancestor_of(focus):
		focus.release_focus()
		get_viewport().set_input_as_handled()
		return

	get_viewport().set_input_as_handled()
	back_requested.emit()


## จัดเนื้อหาให้อยู่กึ่งกลางกว้างไม่เกิน _content_max_width ทั้งแถบบน หัว repo และตัวหน้า
## ขอบซ้าย/ขวาตรงกัน โดยหักความกว้างแถบเลื่อนฝั่งตัวหน้าออกจากขอบขวา
func _update_gutters() -> void:
	# อาจถูกเรียกแบบ deferred หลังหน้าถูกปิด (กด Esc) จึงเช็กว่าโหนดยังอยู่
	if not is_instance_valid(_window) or not is_instance_valid(_top_margin) or not is_instance_valid(_header_margin) \
			or not is_instance_valid(_body_margin) or not is_instance_valid(_scroll):
		return

	var gutter := maxi(_s(20), int((_window.size.x - _content_max_width()) / 2.0))
	var scrollbar := _scroll.get_v_scroll_bar()
	var scrollbar_width := int(scrollbar.get_combined_minimum_size().x) if scrollbar.visible else 0

	for margin in [_top_margin, _header_margin]:
		margin.add_theme_constant_override("margin_left", gutter)
		margin.add_theme_constant_override("margin_right", gutter)

	_body_margin.add_theme_constant_override("margin_left", gutter)
	_body_margin.add_theme_constant_override("margin_right", maxi(_s(12), gutter - scrollbar_width))


func open(account: GitRemoteAccount) -> void:
	_account = account
	_host = null
	go(Page.REPOS)


## เปิด repo ที่เลือกจากรายการ (เริ่มที่หน้า Code ของ repo นั้น)
func _open_repo(repo_name: String) -> void:
	var host := _account.open_repository(repo_name) if _account != null else null
	if host == null:
		return
	_host = host
	_branch = "main"
	_path = ""
	_pull_number = 0
	_show_closed = false
	_new_pull_source = ""
	go(Page.CODE)


func go(page: int, message: Variant = null, is_error: bool = false) -> void:
	_page = page
	if message != null:
		_status = message
		_status_is_error = is_error

	await _refresh()


## รีเฟรชทีละรอบ: ถ้ากดเปลี่ยนหน้าซ้อนระหว่างรอข้อมูล รอบที่สองจะรอรอบแรกจบแล้วค่อยวาดใหม่
## ไม่งั้นสองรอบจะเติมเนื้อหาลง _content พร้อมกันจนซ้ำ
func _refresh() -> void:
	if _refreshing:
		_refresh_queued = true
		return

	_refreshing = true
	while true:
		_refresh_queued = false
		await _refresh_once()
		if not (_refresh_queued and _is_alive()):
			break
	_refreshing = false


func _refresh_once() -> void:
	if _account == null:
		return
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()

	if _page == Page.REPOS or _page == Page.NEW_REPO:
		await _refresh_account_page()
	elif _host != null:
		await _refresh_repo_page(_host)

	if not _is_alive():
		return # ปิดหน้าไปแล้วระหว่างรอข้อมูล ไม่ต้องแจ้งอะไร
	_update_gutters.call_deferred()
	var scroll_to := maxi(_restore_scroll, 0)
	_restore_scroll = NO_SCROLL
	if scroll_to == 0:
		_scroll.set_deferred("scroll_vertical", 0)
	else:
		_restore_scroll_position(scroll_to)


## กลับไปตำแหน่งเลื่อนเดิมหลังโหลดหน้าใหม่ (เช่น หลังส่งความเห็นกลาง diff) ต้องรอให้เลย์เอาต์ยาวพอก่อน
func _restore_scroll_position(value: int) -> void:
	for _frame in 3:
		await get_tree().process_frame
		if not _is_alive():
			return
		_scroll.scroll_vertical = value


## หน้าระดับบัญชี: รายการ repo และฟอร์มสร้าง repo ใหม่ (ยังไม่ได้อยู่ใน repo ใด)
func _refresh_account_page() -> void:
	var repos := await _account.list_repositories()
	if not _is_alive():
		return
	_show_account_header(_account.owner)
	_show_status()
	if _page == Page.REPOS:
		_build_repos(repos)
	else:
		_build_new_repo()


func _refresh_repo_page(host: GitRemoteHost) -> void:
	_repo = await host.get_repository()
	if not _is_alive():
		return
	var open_pulls := 0
	for pull in host.list_pull_requests():
		if pull.state == PullRequestState.OPEN:
			open_pulls += 1
	_show_repo_header(_repo, open_pulls)
	var branches := await host.list_branches()
	if not _is_alive():
		return
	if not branches.any(func(branch: RemoteBranchInfo) -> bool: return branch.name == _branch):
		_branch = _repo.default_branch

	_show_status()

	match _page:
		Page.CODE:
			await _build_code()
		Page.BLOB:
			await _build_blob()
		Page.COMMITS:
			await _build_commits()
		Page.BRANCHES:
			await _build_branches()
		Page.PULLS:
			_build_pulls(host.list_pull_requests())
		Page.NEW_PULL:
			await _build_new_pull()
		Page.PULL_DETAIL:
			await _build_pull_detail()


func _show_status() -> void:
	if _status.is_empty():
		return
	_content.add_child(GitHubUi.flash(_status, _status_is_error))
	_status = ""


func _set_avatar(owner: String) -> void:
	for child in _avatar_slot.get_children():
		_avatar_slot.remove_child(child)
		child.queue_free()

	_avatar_slot.add_child(GitHubUi.avatar(owner, 28))


func _show_account_header(owner: String) -> void:
	_repo_header.visible = false
	_back_button.visible = _page == Page.NEW_REPO
	_room_backdrop.visible = true
	_address_path.text = "/new" if _page == Page.NEW_REPO else "/%s?tab=repositories" % owner
	_set_avatar(owner)


func _show_repo_header(repo: RemoteRepositoryInfo, open_pulls: int) -> void:
	_repo_header.visible = true
	_back_button.visible = true
	_room_backdrop.visible = false
	_owner_label.text = repo.owner
	_repo_label.text = repo.name
	_address_path.text = _address_for(repo)
	_set_avatar(repo.owner)

	for child in _tabs.get_children():
		_tabs.remove_child(child)
		child.queue_free()

	var code_active := _page == Page.CODE or _page == Page.BLOB or _page == Page.COMMITS or _page == Page.BRANCHES
	_tabs.add_child(GitHubUi.tab("Code", code_active, func() -> void:
		_path = ""
		go(Page.CODE), GhIcon.CODE))
	_tabs.add_child(GitHubUi.tab("Pull requests", not code_active, func() -> void: go(Page.PULLS),
			GhIcon.PULL_OPEN, open_pulls))


## ส่วนหลัง magic-vault.com ของที่อยู่หน้าปัจจุบัน
func _address_for(repo: RemoteRepositoryInfo) -> String:
	var root := "/%s/%s" % [repo.owner, repo.name]
	match _page:
		Page.CODE:
			return root if _path.is_empty() else "%s/tree/%s/%s" % [root, _branch, _path]
		Page.BLOB:
			return "%s/blob/%s/%s" % [root, _branch, _path]
		Page.COMMITS:
			return "%s/commits/%s" % [root, _branch]
		Page.BRANCHES:
			return root + "/branches"
		Page.PULLS:
			return root + "/pulls"
		Page.NEW_PULL:
			return root + "/compare"
		Page.PULL_DETAIL:
			return "%s/pull/%d" % [root, _pull_number]
	return root


# ───────────── ตัวช่วย ─────────────


## ผู้เล่นอาจกด Esc ปิดหน้าระหว่างรอข้อมูลจาก Git จึงต้องเช็กก่อนแตะโหนดหลังทุก await
func _is_alive() -> bool:
	return is_instance_valid(self) and not is_queued_for_deletion()


static func _parent_path(path: String) -> String:
	var index := path.rfind("/")
	return "" if index < 0 else path.substr(0, index)


func _branch_picker(branches: Array[RemoteBranchInfo], on_selected: Callable, selected: String = "") -> OptionButton:
	var picker := OptionButton.new()
	picker.mouse_filter = Control.MOUSE_FILTER_PASS
	GitHubUi.fill_branch_picker(picker, branches, on_selected, _branch if selected.is_empty() else selected)
	return picker


# ───────────── Repos ─────────────


## หน้ารายการ repo ก่อนเข้า repo: โครงอยู่ใน Scenes/RepoListPage.tscn
func _build_repos(repos: Array[RemoteRepositoryInfo]) -> void:
	var page := (load("res://Scenes/RepoListPage.tscn") as PackedScene).instantiate() as RepoListPage
	_content.add_child(page)
	page.setup(_account.owner, repos, _open_repo, func() -> void: go(Page.NEW_REPO))


## ฟอร์มสร้าง repository ใหม่ (ว่าง) เหมือนหน้า New repository ของ GitHub: โครงอยู่ใน Scenes/NewRepoPage.tscn
func _build_new_repo() -> void:
	var account := _account
	var page := (load("res://Scenes/NewRepoPage.tscn") as PackedScene).instantiate() as NewRepoPage
	_content.add_child(page)
	var create := func(repo_name: String, description: String) -> OpResult:
		var created: OpResult = await account.create_repository(repo_name, description)
		if created.ok and _is_alive():
			var repo: RemoteRepositoryInfo = created.value
			_status = "สร้าง repository %s แล้ว" % repo.name
			_status_is_error = false
			_open_repo(repo.name)
		return created
	page.setup(account.owner, create, func() -> void: go(Page.REPOS))


# ───────────── Commits / Branches ─────────────


func _build_commits() -> void:
	var branches := await _host.list_branches()
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", _s(12))
	toolbar.add_child(GitHubUi.text_bold("Commits", GitHubTheme.FG, 26))
	toolbar.add_child(GitHubUi.spacer())
	toolbar.add_child(_branch_picker(branches, func(branch_name: String) -> void:
		_branch = branch_name
		go(Page.COMMITS)))
	_content.add_child(toolbar)

	var commits := await _host.list_commits(_branch, 100)
	if commits.is_empty():
		_content.add_child(GitHubUi.empty_state(GhIcon.COMMIT, "ยังไม่มี commit", "branch %s ยังไม่มีประวัติ" % _branch))
		return

	# จัดกลุ่มตามวัน เหมือนหน้า commits ของ GitHub
	var days: Array[String] = []
	var by_day := {}
	for commit in commits:
		var key := GitTime.local_day_key(commit.authored_at)
		if not by_day.has(key):
			by_day[key] = [] as Array[RemoteCommitInfo]
			days.append(key)
		(by_day[key] as Array).append(commit)

	for key in days:
		var items: Array = by_day[key]
		_content.add_child(GitHubUi.icon_text(GhIcon.COMMIT,
				"Commits on %s" % GitHubUi.date_label(items[0].authored_at), GitHubTheme.FG_MUTED, 14))
		var parts := GitHubUi.box()
		for index in items.size():
			parts.body.add_child(_commit_row(items[index], index == items.size() - 1))
		_content.add_child(parts.panel)


func _build_branches() -> void:
	var branches := await _host.list_branches()
	_content.add_child(GitHubUi.text_bold("Branches", GitHubTheme.FG, 26))

	var defaults: Array[RemoteBranchInfo] = []
	var others: Array[RemoteBranchInfo] = []
	for branch in branches:
		if branch.is_default:
			defaults.append(branch)
		else:
			others.append(branch)
	if not defaults.is_empty():
		_content.add_child(_branch_section("Default", defaults))
	if not others.is_empty():
		_content.add_child(_branch_section("Other branches", others))


func _branch_section(title: String, items: Array[RemoteBranchInfo]) -> Control:
	var parts := GitHubUi.box(GitHubUi.text_bold(title, GitHubTheme.FG, 15))
	for index in items.size():
		parts.body.add_child(_branch_row(items[index], index == items.size() - 1))
	return parts.panel


func _branch_row(branch: RemoteBranchInfo, last: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _s(12))

	var name_button := GitHubUi.btn(branch.name, func() -> void:
		_branch = branch.name
		_path = ""
		go(Page.CODE), GhButtonKind.LINK)
	name_button.custom_minimum_size = Vector2(_s(240), 0)
	name_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(name_button)
	if branch.is_default:
		row.add_child(GitHubUi.pill("default", GitHubTheme.FG_MUTED, GitHubTheme.BORDER))

	var info := GitHubUi.text("%s · %s" % [branch.last_commit_subject, GitHubUi.time_ago(branch.last_commit_at)],
			GitHubTheme.FG_MUTED, 14)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.clip_text = true
	row.add_child(info)

	if not branch.is_default:
		row.add_child(GitHubUi.pill("%d ahead" % branch.ahead,
				GitHubTheme.SUCCESS if branch.ahead > 0 else GitHubTheme.FG_MUTED,
				Color(GitHubTheme.SUCCESS, 0.5) if branch.ahead > 0 else GitHubTheme.BORDER, null, 13))
		row.add_child(GitHubUi.pill("%d behind" % branch.behind, GitHubTheme.FG_MUTED, GitHubTheme.BORDER, null, 13))
		row.add_child(GitHubUi.btn("New pull request", func() -> void:
			_new_pull_source = branch.name
			go(Page.NEW_PULL)))
		row.add_child(GitHubUi.btn("", func() -> void:
			var deleted := await _host.delete_branch(branch.name)
			go(Page.BRANCHES,
					"ลบ branch %s แล้ว" % branch.name if deleted
					else "ลบ %s ไม่ได้ (มี PR ที่ยังเปิดอยู่)" % branch.name, not deleted),
				GhButtonKind.GHOST, GhIcon.TRASH, false, GitHubTheme.DANGER))

	return GitHubUi.list_row(row, last)


## แถว commit แบบ GitHub: ข้อความ ผู้เขียน/เวลา และ hash สั้นพร้อมปุ่มคัดลอก hash เต็ม
static func _commit_row(commit: RemoteCommitInfo, last: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _s(12))

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", _s(4))
	var subject := GitHubUi.text_bold(commit.subject, GitHubTheme.FG, 15)
	subject.clip_text = true
	column.add_child(subject)
	var meta := HBoxContainer.new()
	meta.add_theme_constant_override("separation", _s(8))
	meta.add_child(GitHubUi.avatar(commit.author, 18))
	meta.add_child(GitHubUi.text_bold(commit.author, GitHubTheme.FG, 13))
	meta.add_child(GitHubUi.text("committed %s" % GitHubUi.time_ago(commit.authored_at), GitHubTheme.FG_MUTED, 13))
	column.add_child(meta)
	row.add_child(column)

	row.add_child(GitHubUi.pill(commit.short_id, GitHubTheme.FG_MUTED, GitHubTheme.BORDER, null, 13, true))
	row.add_child(GitHubUi.btn("", func() -> void: DisplayServer.clipboard_set(commit.id), GhButtonKind.GHOST, GhIcon.COPY))
	return GitHubUi.list_row(row, last)


# ───────────── Code ─────────────


func _build_code() -> void:
	if _repo.is_empty:
		_build_empty_repo()
		return

	var branches := await _host.list_branches()
	var latest_commits := await _host.list_commits(_branch, 1)
	var latest: RemoteCommitInfo = latest_commits[0] if not latest_commits.is_empty() else null
	var files := await _host.list_files(_branch, _path)
	if not _is_alive():
		return

	var rows: Array = [] # แต่ละรายการ: [แถว, ชื่อไฟล์]
	var page := (load("res://Scenes/CodePage.tscn") as PackedScene).instantiate() as CodePage
	_content.add_child(page)
	page.setup(branches, _branch,
			func(branch_name: String) -> void:
				_branch = branch_name
				_path = ""
				go(Page.CODE),
			func() -> void: go(Page.BRANCHES),
			func(text: String) -> void:
				for item in rows:
					(item[0] as Control).visible = text.is_empty() or (item[1] as String).to_lower().contains(text.to_lower()),
			_show_clone_menu)
	if not _path.is_empty():
		page.add_child(_breadcrumb())
	page.add_child(_build_file_table(latest, files, rows))
	await _add_readme(page)


## ตารางไฟล์: แถวหัวเป็น commit ล่าสุดของ branch ส่วนแถวไฟล์คลิกได้ทั้งแถว
func _build_file_table(latest: RemoteCommitInfo, files: Array[RemoteFileEntry], rows: Array) -> Control:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", _s(12))
	if latest != null:
		header.add_child(GitHubUi.avatar(latest.author, 22))
		header.add_child(GitHubUi.text_bold(latest.author, GitHubTheme.FG, 15))
		var subject := GitHubUi.text(latest.subject, GitHubTheme.FG_MUTED)
		subject.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		subject.clip_text = true
		header.add_child(subject)
		header.add_child(GitHubUi.text_mono(latest.short_id, GitHubTheme.FG_MUTED, 13))
		header.add_child(GitHubUi.text("·", GitHubTheme.FG_MUTED))
		header.add_child(GitHubUi.text(GitHubUi.time_ago(latest.authored_at), GitHubTheme.FG_MUTED, 14))
	else:
		header.add_child(GitHubUi.spacer())

	header.add_child(GitHubUi.btn(GitHubUi.count(_repo.commit_count, "Commit", "Commits"),
			func() -> void: go(Page.COMMITS), GhButtonKind.GHOST, GhIcon.HISTORY))
	var parts := GitHubUi.box(header)

	if not _path.is_empty():
		var up := HBoxContainer.new()
		up.add_theme_constant_override("separation", _s(12))
		up.add_child(GitHubUi.icon(GhIcon.FOLDER, GitHubTheme.ACCENT))
		up.add_child(GitHubUi.text("..", GitHubTheme.FG))
		parts.body.add_child(GitHubUi.list_row(up, files.is_empty(), func() -> void:
			_path = _parent_path(_path)
			go(Page.CODE)))

	for index in files.size():
		var entry := files[index]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", _s(12))
		row.add_child(GitHubUi.icon(GhIcon.FOLDER if entry.is_directory else GhIcon.FILE,
				GitHubTheme.ACCENT if entry.is_directory else GitHubTheme.FG_MUTED))
		var name_label := GitHubUi.text(entry.name, GitHubTheme.FG)
		name_label.custom_minimum_size = Vector2(_s(300), 0)
		row.add_child(name_label)
		var message := GitHubUi.text(entry.last_commit.subject if entry.last_commit != null else "", GitHubTheme.FG_MUTED, 14)
		message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		message.clip_text = true
		row.add_child(message)
		row.add_child(GitHubUi.text(
				"" if entry.last_commit == null else GitHubUi.time_ago(entry.last_commit.authored_at),
				GitHubTheme.FG_MUTED, 14))

		var list_row := GitHubUi.list_row(row, index == files.size() - 1, func() -> void:
			_path = entry.path
			go(Page.CODE if entry.is_directory else Page.BLOB))
		parts.body.add_child(list_row)
		rows.append([list_row, entry.name])

	return parts.panel


func _add_readme(page: Control) -> void:
	var readme_path := "README.md" if _path.is_empty() else "%s/README.md" % _path
	var readme: Variant = await _host.read_file(_branch, readme_path)
	if readme == null or not is_instance_valid(page):
		return # ปิดหน้าหรือรีเฟรชระหว่างรอ

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", _s(8))
	header.add_child(GitHubUi.icon(GhIcon.BOOK, GitHubTheme.FG_MUTED))
	header.add_child(GitHubUi.text_bold("README", GitHubTheme.FG, 14))
	var parts := GitHubUi.box(header)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", _s(32))
	margin.add_theme_constant_override("margin_right", _s(32))
	margin.add_theme_constant_override("margin_top", _s(24))
	margin.add_theme_constant_override("margin_bottom", _s(28))
	margin.add_child(MarkdownView.render(readme))
	parts.body.add_child(margin)
	page.add_child(parts.panel)


## repo ที่ยังไม่มีอะไรถูก push: หน้า Quick setup เป็นขั้นตอน 1-2-3 บอก URL และคำสั่งที่ใช้ใน terminal ของเกม
## (คำแนะนำวิธีใช้อยู่บนสุด เพราะผู้เล่นต้องกด Esc ออกไปพิมพ์ใน terminal แล้วกลับมาดูผล)
func _build_empty_repo() -> void:
	var repo := _repo

	_content.add_child(GitHubUi.info(
			"คลิกที่คำสั่งเพื่อคัดลอก → กด Esc กลับไปที่ terminal → วางด้วย Ctrl/⌘+V แล้วกด Enter ทีละบรรทัด → เปิดหน้านี้อีกครั้งเพื่อดูผลที่ push",
			"ทำตามขั้นตอนเหล่านี้ใน terminal ของ Sandbox"))

	var intro := VBoxContainer.new()
	intro.add_theme_constant_override("separation", _s(6))
	intro.add_child(GitHubUi.text_bold("Quick setup — repo นี้ยังว่างอยู่", GitHubTheme.FG, 26))
	intro.add_child(GitHubUi.text("push งานจากเครื่องของคุณขึ้นมา แล้วไฟล์ branch และ commit จะแสดงที่หน้านี้",
			GitHubTheme.FG_MUTED, 16, false, false, true))
	_content.add_child(intro)

	var url_card := GitHubUi.card(16, 12)
	var url_row := HBoxContainer.new()
	url_row.add_theme_constant_override("separation", _s(10))
	url_row.add_child(GitHubUi.pill("HTTPS", GitHubTheme.FG, GitHubTheme.BORDER))
	url_row.add_child(_read_only_field(repo.clone_url))
	url_row.add_child(GitHubUi.btn("Copy URL", func() -> void: DisplayServer.clipboard_set(repo.clone_url),
			GhButtonKind.DEFAULT, GhIcon.COPY))
	url_card.add_child(url_row)
	_content.add_child(url_card)

	var step_one: Array[CodeLine] = [
		CodeLine.new("git config --global user.name \"%s\"" % repo.owner, "ชื่อที่จะขึ้นใน commit"),
		CodeLine.new("git config --global user.email \"%s@example.com\"" % repo.owner, "อีเมลที่จะขึ้นใน commit"),
	]
	_content.add_child(GitHubUi.step(1, "ตั้งชื่อผู้ใช้ Git", "ครั้งแรกเท่านั้น — ข้ามได้ถ้าเคยตั้งไว้แล้ว",
			GitHubUi.command_block(step_one)))

	var step_two: Array[CodeLine] = [
		CodeLine.new("write README.md # %s" % repo.name, "คำสั่งของเกม สร้างไฟล์ README.md (ไม่ใช่คำสั่ง Git)"),
		CodeLine.new("git init", "สร้าง repo ในเครื่อง"),
		CodeLine.new("git add README.md", "เลือกไฟล์ที่จะบันทึก"),
		CodeLine.new("git commit -m \"first commit\"", "บันทึกเป็น commit แรก"),
	]
	_content.add_child(GitHubUi.step(2, "สร้างไฟล์แรก แล้ว commit", null, GitHubUi.command_block(step_two)))

	var step_three: Array[CodeLine] = [
		CodeLine.new("git remote add origin " + repo.clone_url, "ผูกชื่อ origin กับ repo นี้"),
		CodeLine.new("git push -u origin main", "ส่ง branch main ขึ้นมา"),
	]
	_content.add_child(GitHubUi.step(3, "เชื่อมกับ repo นี้ แล้ว push", "มี repo ในเครื่องอยู่แล้ว? เริ่มที่ขั้นนี้ได้เลย",
			GitHubUi.command_block(step_three)))

	var clone := VBoxContainer.new()
	clone.add_theme_constant_override("separation", _s(10))
	clone.add_child(GitHubUi.text_bold("หรือ clone repo ว่างนี้ลงมาทำงานต่อ", GitHubTheme.FG, 16))
	var clone_lines: Array[CodeLine] = [CodeLine.new("git clone " + repo.clone_url, "ดึง repo นี้ลงมาเป็นโฟลเดอร์ใหม่")]
	clone.add_child(GitHubUi.command_block(clone_lines))
	_content.add_child(clone)


static func _read_only_field(value: String) -> LineEdit:
	var field := LineEdit.new()
	field.text = value
	field.editable = false
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return field


func _build_blob() -> void:
	_content.add_child(_breadcrumb())
	var text: Variant = await _host.read_file(_branch, _path)
	var lines := (str(text) if text != null else "").replace("\r\n", "\n").strip_edges(false, true).split("\n")
	if not _is_alive():
		return

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", _s(10))
	header.add_child(GitHubUi.icon(GhIcon.FILE, GitHubTheme.FG_MUTED))
	header.add_child(GitHubUi.text_bold(_path.get_file(), GitHubTheme.FG, 15))
	header.add_child(GitHubUi.text(GitHubUi.count(lines.size(), "line", "lines"), GitHubTheme.FG_MUTED, 13))
	header.add_child(GitHubUi.spacer())
	if text != null:
		header.add_child(GitHubUi.btn("Copy", func() -> void: DisplayServer.clipboard_set(text),
				GhButtonKind.GHOST, GhIcon.COPY))
	var parts := GitHubUi.box(header)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_top", _s(10))
	margin.add_theme_constant_override("margin_bottom", _s(10))
	margin.add_theme_constant_override("margin_right", _s(16))
	margin.add_child(GitHubUi.text("ไม่พบไฟล์หรืออ่านไม่ได้", GitHubTheme.FG_MUTED) if text == null
			else GitHubUi.code_lines(lines))
	parts.body.add_child(margin)
	_content.add_child(parts.panel)


## เมนู Clone ที่เปิดจากปุ่ม Code: ลอยใต้ปุ่มและปิดเองเมื่อคลิกข้างนอก เหมือน GitHub
func _show_clone_menu(anchor: Button) -> void:
	var url := _repo.clone_url
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(_s(640), 0)
	column.add_theme_constant_override("separation", _s(10))
	column.add_child(GitHubUi.icon_text(GhIcon.CODE, "Clone", GitHubTheme.FG, 15, true))

	var url_row := HBoxContainer.new()
	url_row.add_theme_constant_override("separation", _s(8))
	url_row.add_child(GitHubUi.pill("HTTPS", GitHubTheme.FG, GitHubTheme.BORDER))
	url_row.add_child(_read_only_field(url))
	url_row.add_child(GitHubUi.btn("", func() -> void: DisplayServer.clipboard_set(url), GhButtonKind.DEFAULT, GhIcon.COPY))
	column.add_child(url_row)

	column.add_child(GitHubUi.text("พิมพ์คำสั่งนี้ใน terminal ของ Sandbox", GitHubTheme.FG_MUTED, 13))
	column.add_child(GitHubUi.code_block(["git clone " + url] as Array[String]))
	_show_floating_panel(anchor, column)


## เมนูลอยใต้ปุ่ม anchor ชิดขอบขวา คลิกข้างนอกเพื่อปิด
## ใช้ overlay ในหน้าเดียวกันแทน PopupPanel เพราะหน้าต่าง popup ยืดเต็มความสูงจอ
## ความกว้างมาจาก custom_minimum_size ของ content
func _show_floating_panel(anchor: Button, content: Control) -> Control:
	# ชั้นโปร่งใสเต็มหน้า คลิกตรงไหนนอกเมนูก็ปิด
	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.gui_input.connect(func(input: InputEvent) -> void:
		if input is InputEventMouseButton and input.pressed:
			overlay.queue_free())

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := GitHubTheme.box(GitHubTheme.SURFACE_RAISED, GitHubTheme.BORDER, 8, 1, 18, 14)
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.add_child(content)
	overlay.add_child(panel)
	add_child(overlay)

	# วางชิดขอบขวาของปุ่ม ใต้ปุ่ม 6px (พิกัดสัมพัทธ์กับหน้านี้)
	# ความกว้างรู้แน่นอน แต่ความสูงต้องรอให้ข้อความ autowrap รู้ความกว้างก่อน
	# ถ้าอ่านความสูงตอนนี้จะได้ค่ามหาศาล (label คิดว่ากว้าง 0) กล่องเลยยืดเต็มจอ
	var width := content.custom_minimum_size.x + panel_style.get_minimum_size().x
	var anchor_rect := anchor.get_global_rect()
	panel.position = Vector2(anchor_rect.end.x - width, anchor_rect.end.y + 6) - get_global_rect().position
	panel.size = Vector2(width, 0)
	_shrink_to_content(panel)
	return overlay


## รอให้จัดเลย์เอาต์ครบสองเฟรมแล้วหดกล่องให้พอดีเนื้อหา
func _shrink_to_content(panel: Control) -> void:
	for _frame in 2:
		await get_tree().process_frame
		if not is_instance_valid(panel):
			return
		panel.reset_size()

	# กล่องสูงเกินที่เหลือใต้ปุ่ม: เลื่อนขึ้นให้ปุ่มล่างสุดไม่หลุดจอ
	var space := get_viewport_rect().size.y - get_global_rect().position.y
	var overflow := panel.position.y + panel.size.y + _s(12) - space
	if overflow > 0.0:
		panel.position = Vector2(panel.position.x, maxf(_s(8), panel.position.y - overflow))


func _breadcrumb() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _s(6))
	row.add_child(GitHubUi.btn(_repo.name, func() -> void:
		_path = ""
		go(Page.CODE), GhButtonKind.LINK))

	var segments := _path.split("/", false)
	var built := ""
	for index in segments.size():
		built = segments[index] if built.is_empty() else "%s/%s" % [built, segments[index]]
		var target := built
		row.add_child(GitHubUi.text("/", GitHubTheme.FG_MUTED))
		if index == segments.size() - 1:
			row.add_child(GitHubUi.text_bold(segments[index], GitHubTheme.FG, 15))
		else:
			row.add_child(GitHubUi.btn(segments[index], func() -> void:
				_path = target
				go(Page.CODE), GhButtonKind.LINK))

	return row


# ───────────── Pull requests ─────────────


func _build_pulls(pulls: Array[PullRequestInfo]) -> void:
	var rows: Array = [] # แต่ละรายการ: [แถว, ชื่อ PR]

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", _s(10))
	var search := LineEdit.new()
	search.placeholder_text = "Search pull requests"
	search.right_icon = GitHubIcons.get_icon(GhIcon.SEARCH, GitHubTheme.FG_MUTED, _s(16), 1.0)
	search.clear_button_enabled = true
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.mouse_filter = Control.MOUSE_FILTER_PASS
	search.text_changed.connect(func(text: String) -> void:
		for item in rows:
			(item[0] as Control).visible = text.is_empty() or (item[1] as String).to_lower().contains(text.to_lower()))
	toolbar.add_child(search)
	toolbar.add_child(GitHubUi.btn("New pull request", func() -> void:
		_new_pull_source = ""
		go(Page.NEW_PULL), GhButtonKind.PRIMARY))
	_content.add_child(toolbar)

	if pulls.is_empty():
		_content.add_child(GitHubUi.empty_state(GhIcon.PULL_OPEN, "Welcome to pull requests!",
				"Pull requests ใช้เสนอให้นำการเปลี่ยนแปลงจาก branch หนึ่งไปรวมกับอีก branch หนึ่ง "
				+ "ลอง push branch ใหม่ขึ้นมา แล้วกด New pull request"))
		return

	var open_pulls: Array[PullRequestInfo] = []
	var closed: Array[PullRequestInfo] = []
	for pull in pulls:
		if pull.state == PullRequestState.OPEN:
			open_pulls.append(pull)
		else:
			closed.append(pull)

	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", _s(4))
	filters.add_child(_filter_button("%d Open" % open_pulls.size(), GhIcon.PULL_OPEN, not _show_closed, func() -> void:
		_show_closed = false
		go(Page.PULLS)))
	filters.add_child(_filter_button("%d Closed" % closed.size(), GhIcon.CHECK, _show_closed, func() -> void:
		_show_closed = true
		go(Page.PULLS)))
	var parts := GitHubUi.box(filters)

	var shown: Array[PullRequestInfo] = []
	shown.assign(closed if _show_closed else open_pulls)
	shown.sort_custom(func(a: PullRequestInfo, b: PullRequestInfo) -> bool: return a.number > b.number)
	if shown.is_empty():
		var empty := MarginContainer.new()
		empty.add_theme_constant_override("margin_top", _s(28))
		empty.add_theme_constant_override("margin_bottom", _s(28))
		var message := GitHubUi.text("ยังไม่มี pull request ที่ปิดแล้ว" if _show_closed else "ไม่มี pull request ที่เปิดอยู่",
				GitHubTheme.FG_MUTED, 16)
		message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_child(message)
		parts.body.add_child(empty)

	for index in shown.size():
		var item := shown[index]
		var row := _build_pull_row(item)
		var list_row := GitHubUi.list_row(row, index == shown.size() - 1, func() -> void:
			_pull_number = item.number
			_pull_tab = PullTab.CONVERSATION
			go(Page.PULL_DETAIL))
		parts.body.add_child(list_row)
		rows.append([list_row, item.title])

	_content.add_child(parts.panel)


static func _filter_button(text: String, glyph: int, active: bool, on_pressed: Callable) -> Button:
	var button := GitHubUi.btn(text, on_pressed, GhButtonKind.GHOST, glyph, false,
			GitHubTheme.FG if active else GitHubTheme.FG_MUTED)
	if active:
		button.add_theme_color_override("font_color", GitHubTheme.FG)
		button.add_theme_font_override("font", GitHubTheme.bold_font())
	return button


static func _build_pull_row(pull: PullRequestInfo) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _s(12))

	var state := GitHubUi.state_icon(pull.state, 18)
	state.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(state)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", _s(4))
	column.add_child(GitHubUi.text_bold(pull.title, GitHubTheme.FG, 16))

	var meta := HFlowContainer.new()
	meta.add_theme_constant_override("h_separation", _s(8))
	meta.add_theme_constant_override("v_separation", _s(6))
	var summary: String
	match pull.state:
		PullRequestState.MERGED:
			summary = "#%d by %s was merged" % [pull.number, pull.author]
		PullRequestState.CLOSED:
			summary = "#%d by %s was closed" % [pull.number, pull.author]
		_:
			summary = "#%d opened %s by %s" % [pull.number, GitHubUi.time_ago(pull.created_at), pull.author]
	meta.add_child(GitHubUi.text(summary, GitHubTheme.FG_MUTED, 13))
	meta.add_child(GitHubUi.branch_pill(pull.source_branch))
	meta.add_child(GitHubUi.text("→", GitHubTheme.FG_MUTED, 13))
	meta.add_child(GitHubUi.branch_pill(pull.target_branch))
	column.add_child(meta)
	row.add_child(column)

	if pull.is_approved and pull.state == PullRequestState.OPEN:
		row.add_child(GitHubUi.icon_text(GhIcon.CHECK, "Approved", GitHubTheme.SUCCESS, 13))
	return row


func _build_new_pull() -> void:
	var branches := await _host.list_branches()
	if not _is_alive():
		return
	_content.add_child(GitHubUi.text_bold("Open a pull request", GitHubTheme.FG, 26))
	_content.add_child(GitHubUi.text("เลือก branch ที่มีการเปลี่ยนแปลง (compare) เพื่อนำไปรวมกับ branch ปลายทาง (base)",
			GitHubTheme.FG_MUTED))

	if branches.size() < 2:
		_content.add_child(GitHubUi.empty_state(GhIcon.BRANCH, "ยังเปรียบเทียบไม่ได้",
				"repo ยังว่าง — push branch ขึ้นมาก่อนจึงจะเปิด pull request ได้" if branches.is_empty()
				else "ต้องมีอย่างน้อย 2 branch — สร้างและ push branch ใหม่ก่อน เช่น git switch -c feature/xxx แล้ว git push -u origin feature/xxx"))
		var back := GitHubUi.btn("Pull requests", func() -> void: go(Page.PULLS), GhButtonKind.DEFAULT, GhIcon.ARROW_LEFT)
		back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_content.add_child(back)
		return

	var default_branch := "main"
	var first_other := ""
	for branch in branches:
		if branch.is_default:
			default_branch = branch.name
		elif first_other.is_empty():
			first_other = branch.name
	var source := _new_pull_source
	if not branches.any(func(branch: RemoteBranchInfo) -> bool: return branch.name == _new_pull_source):
		source = first_other if not first_other.is_empty() else default_branch

	# แถบเลือก base ← compare
	var compare := GitHubUi.card(16, 12)
	compare.add_theme_stylebox_override("panel", GitHubTheme.box(GitHubTheme.SURFACE, GitHubTheme.BORDER, 8, 1, 16, 12))
	var compare_column := VBoxContainer.new()
	compare_column.add_theme_constant_override("separation", _s(10))
	var pickers := HBoxContainer.new()
	pickers.add_theme_constant_override("separation", _s(10))
	pickers.add_child(GitHubUi.icon(GhIcon.PULL_OPEN, GitHubTheme.FG_MUTED, 18))
	pickers.add_child(GitHubUi.text("base:", GitHubTheme.FG_MUTED))
	var base_picker := _branch_picker(branches, func(_name: String) -> void: pass, default_branch)
	pickers.add_child(base_picker)
	pickers.add_child(GitHubUi.icon(GhIcon.ARROW_LEFT, GitHubTheme.FG_MUTED))
	pickers.add_child(GitHubUi.text("compare:", GitHubTheme.FG_MUTED))
	var compare_picker := _branch_picker(branches, func(_name: String) -> void: pass, source)
	pickers.add_child(compare_picker)
	compare_column.add_child(pickers)

	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", _s(6))
	compare_column.add_child(summary)

	# ช่องหัวข้อสร้างก่อน เพื่อให้ฟังก์ชันด้านล่างจับ (capture) ได้
	var title := LineEdit.new()
	title.placeholder_text = "Title"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_PASS
	var title_touched := [false] # ใช้ Array เพราะ lambda จับตัวแปรเดี่ยวแบบคัดลอกค่า

	var update_summary := func() -> void:
		for child in summary.get_children():
			summary.remove_child(child)
			child.queue_free()

		var head := branches[compare_picker.selected]
		var target := branches[base_picker.selected]
		if head.name == target.name:
			summary.add_child(GitHubUi.icon_text(GhIcon.ALERT, "base และ compare ต้องเป็นคนละ branch", GitHubTheme.ATTENTION, 14))
		elif target.is_default:
			summary.add_child(GitHubUi.icon_text(GhIcon.COMMIT,
					"%s นำหน้า %s %s" % [head.name, target.name, GitHubUi.count(head.ahead, "commit", "commits")]
					+ (" และตามหลัง %d" % head.behind if head.behind > 0 else ""), GitHubTheme.FG_MUTED, 14))
		else:
			summary.add_child(GitHubUi.icon_text(GhIcon.COMMIT, "เปรียบเทียบ %s กับ %s" % [head.name, target.name],
					GitHubTheme.FG_MUTED, 14))

	var suggest_title := func() -> void:
		if not title_touched[0]:
			title.text = branches[compare_picker.selected].last_commit_subject

	compare_picker.item_selected.connect(func(_index: int) -> void:
		update_summary.call()
		suggest_title.call())
	base_picker.item_selected.connect(func(_index: int) -> void: update_summary.call())
	update_summary.call()
	compare.add_child(compare_column)
	_content.add_child(compare)

	# ฟอร์มหัวข้อ + รายละเอียด
	var form := HBoxContainer.new()
	form.add_theme_constant_override("separation", _s(14))
	var avatar := GitHubUi.avatar(_repo.owner, 40)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	form.add_child(avatar)

	var card := GitHubUi.card(16, 16)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fields := VBoxContainer.new()
	fields.add_theme_constant_override("separation", _s(12))
	title.text_changed.connect(func(_text: String) -> void: title_touched[0] = true) # เปลี่ยนด้วยโค้ด (suggest_title) ไม่ส่งสัญญาณนี้
	suggest_title.call()
	fields.add_child(title)
	var body := TextEdit.new()
	body.placeholder_text = "Leave a comment"
	body.custom_minimum_size = Vector2(0, _s(150))
	body.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	fields.add_child(body)

	var error := GitHubUi.text("", GitHubTheme.DANGER, 14, false, false, true)
	error.visible = false
	fields.add_child(error)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", _s(10))
	buttons.add_child(GitHubUi.spacer())
	buttons.add_child(GitHubUi.btn("Cancel", func() -> void: go(Page.PULLS)))
	buttons.add_child(GitHubUi.btn("Create pull request", func() -> void:
		var opened: OpResult = await _host.open_pull_request(title.text, body.text, _repo.owner,
				branches[compare_picker.selected].name, branches[base_picker.selected].name)
		if not _is_alive():
			return
		if opened.ok:
			var pr: PullRequestInfo = opened.value
			_pull_number = pr.number
			_pull_tab = PullTab.CONVERSATION
			go(Page.PULL_DETAIL, "สร้าง pull request #%d แล้ว" % pr.number)
		else:
			error.text = opened.message
			error.visible = true, GhButtonKind.PRIMARY))
	fields.add_child(buttons)
	card.add_child(fields)
	form.add_child(card)
	_content.add_child(form)


func _build_pull_detail() -> void:
	var detail := await _host.get_pull_request(_pull_number)
	if not _is_alive():
		return
	if detail == null:
		go(Page.PULLS, "ไม่พบ pull request", true)
		return

	var pull := detail.pull
	_content.add_child(GitHubUi.heading(pull.title, "#%d" % pull.number))

	var commit_text := GitHubUi.count(detail.commits.size(), "commit", "commits")
	var meta := HFlowContainer.new()
	meta.add_theme_constant_override("h_separation", _s(8))
	meta.add_theme_constant_override("v_separation", _s(6))
	meta.add_child(GitHubUi.state_pill(pull.state))
	meta.add_child(GitHubUi.text_bold(pull.author, GitHubTheme.FG, 15))
	var verb: String
	match pull.state:
		PullRequestState.MERGED:
			verb = "merged %s into" % commit_text
		PullRequestState.CLOSED:
			verb = "wanted to merge %s into" % commit_text
		_:
			verb = "wants to merge %s into" % commit_text
	meta.add_child(GitHubUi.text(verb, GitHubTheme.FG_MUTED))
	meta.add_child(GitHubUi.branch_pill(pull.target_branch))
	meta.add_child(GitHubUi.text("from", GitHubTheme.FG_MUTED))
	meta.add_child(GitHubUi.branch_pill(pull.source_branch))
	_content.add_child(meta)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", _s(4))
	tabs.add_child(GitHubUi.tab("Conversation", _pull_tab == PullTab.CONVERSATION,
			func() -> void: _switch_pull_tab(PullTab.CONVERSATION), GhIcon.COMMENT))
	tabs.add_child(GitHubUi.tab("Commits", _pull_tab == PullTab.COMMITS,
			func() -> void: _switch_pull_tab(PullTab.COMMITS), GhIcon.COMMIT, detail.commits.size()))
	tabs.add_child(GitHubUi.tab("Files changed", _pull_tab == PullTab.FILES,
			func() -> void: _switch_pull_tab(PullTab.FILES), GhIcon.FILE, detail.files.size()))
	var tab_column := VBoxContainer.new()
	tab_column.add_theme_constant_override("separation", 0)
	tab_column.add_child(tabs)
	tab_column.add_child(HSeparator.new())
	_content.add_child(tab_column)

	match _pull_tab:
		PullTab.COMMITS:
			_build_pull_commits(detail)
		PullTab.FILES:
			_build_pull_files(detail)
		_:
			await _build_conversation(detail)


func _switch_pull_tab(tab: int) -> void:
	_pull_tab = tab
	go(Page.PULL_DETAIL)


# ───────────── Conversation ─────────────


func _build_conversation(detail: PullRequestDetail) -> void:
	var pull := detail.pull
	_content.add_child(_timeline_comment(pull.author, "opened this pull request", pull.created_at, pull.body))
	for review in detail.reviews:
		_content.add_child(_review_event(review))
	for comment in detail.line_comments:
		if not comment.is_pending:
			_content.add_child(_timeline_comment(comment.author,
					"commented on %s line %s%d" % [comment.path, "R" if comment.on_new_side else "L", comment.line],
					comment.at, comment.body))

	match pull.state:
		PullRequestState.OPEN:
			_build_merge_box(detail)
			_build_comment_box(pull)
		PullRequestState.MERGED:
			await _build_merged_box(pull)
		_:
			var parts := GitHubUi.box()
			parts.body.add_child(_status_row(GhIcon.PULL_CLOSED, GitHubTheme.DANGER_EMPHASIS, "This pull request is closed",
					"ปิดโดยไม่ได้ merge — เปิด pull request ใหม่ได้ถ้ายังต้องการรวม branch นี้", true))
			_content.add_child(parts.panel)


static func _timeline_comment(author: String, action: String, when: float, body: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _s(14))
	var avatar := GitHubUi.avatar(author, 40)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(avatar)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", _s(8))
	header.add_child(GitHubUi.text_bold(author, GitHubTheme.FG, 15))
	header.add_child(GitHubUi.text("%s %s" % [action, GitHubUi.time_ago(when)], GitHubTheme.FG_MUTED, 14))
	var parts := GitHubUi.box(header)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", _s(16))
	margin.add_theme_constant_override("margin_right", _s(16))
	margin.add_theme_constant_override("margin_top", _s(14))
	margin.add_theme_constant_override("margin_bottom", _s(16))
	margin.add_child(GitHubUi.text("No description provided.", GitHubTheme.FG_MUTED) if body.strip_edges().is_empty()
			else MarkdownView.render(body))
	parts.body.add_child(margin)
	row.add_child(parts.panel)
	return row


static func _review_event(review: PullRequestReview) -> Control:
	var glyph: int
	var fill: Color
	var verb: String
	match review.verdict:
		ReviewVerdict.APPROVED:
			glyph = GhIcon.CHECK
			fill = GitHubTheme.SUCCESS_EMPHASIS
			verb = "approved these changes"
		ReviewVerdict.CHANGES_REQUESTED:
			glyph = GhIcon.X
			fill = GitHubTheme.DANGER_EMPHASIS
			verb = "requested changes"
		_:
			glyph = GhIcon.COMMENT
			fill = GitHubTheme.FG_SUBTLE
			verb = "reviewed"

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _s(14))
	var slot := MarginContainer.new()
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	slot.add_theme_constant_override("margin_left", _s(4))
	slot.add_theme_constant_override("margin_right", _s(4))
	slot.add_child(GitHubUi.bubble(glyph, fill, 32))
	row.add_child(slot)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", _s(8))
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", _s(8))
	line.add_child(GitHubUi.text_bold(review.reviewer, GitHubTheme.FG, 15))
	line.add_child(GitHubUi.text("%s %s" % [verb, GitHubUi.time_ago(review.at)], GitHubTheme.FG_MUTED, 14))
	column.add_child(line)
	if not review.body.strip_edges().is_empty():
		var card := GitHubUi.card(14, 10)
		card.add_child(GitHubUi.text(review.body, GitHubTheme.FG, 15, false, false, true))
		column.add_child(card)

	row.add_child(column)
	return row


## แถวสถานะในกล่อง merge: วงกลมไอคอน หัวข้อ คำอธิบาย (และปุ่มด้านขวาถ้ามี)
static func _status_row(glyph: int, fill: Color, title: String, detail: Variant, last: bool, action: Control = null) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _s(14))
	row.add_child(GitHubUi.bubble(glyph, fill, 32))
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", _s(2))
	column.add_child(GitHubUi.text_bold(title, GitHubTheme.FG, 16, true))
	if detail != null:
		column.add_child(GitHubUi.text(detail, GitHubTheme.FG_MUTED, 14, false, false, true))
	row.add_child(column)
	if action != null:
		row.add_child(action)
	return GitHubUi.list_row(row, last)


func _build_merge_box(detail: PullRequestDetail) -> void:
	var pull := detail.pull
	var parts := GitHubUi.box()

	var decision: PullRequestReview = null
	for index in range(detail.reviews.size() - 1, -1, -1):
		if detail.reviews[index].verdict != ReviewVerdict.COMMENTED:
			decision = detail.reviews[index]
			break
	if decision != null and decision.verdict == ReviewVerdict.APPROVED:
		parts.body.add_child(_status_row(GhIcon.CHECK, GitHubTheme.SUCCESS_EMPHASIS, "Changes approved",
				"%s approved these changes" % decision.reviewer, false))
	elif decision != null and decision.verdict == ReviewVerdict.CHANGES_REQUESTED:
		parts.body.add_child(_status_row(GhIcon.X, GitHubTheme.DANGER_EMPHASIS, "Changes requested",
				"%s requested changes" % decision.reviewer, false))

	if detail.has_conflicts:
		parts.body.add_child(_status_row(GhIcon.ALERT, GitHubTheme.DANGER_EMPHASIS, "This branch has conflicts that must be resolved",
				"แก้ conflict ใน terminal แล้ว push ขึ้นมาใหม่ จึงจะ merge ได้", false))
	elif detail.merge_blocked_reason != null:
		parts.body.add_child(_status_row(GhIcon.ALERT, GitHubTheme.ATTENTION, "Merging is blocked",
				detail.merge_blocked_reason, false))
	else:
		parts.body.add_child(_status_row(GhIcon.CHECK, GitHubTheme.SUCCESS_EMPHASIS, "This branch has no conflicts with the base branch",
				"Merging can be performed automatically.", false))

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", _s(10))
	var merge := GitHubUi.btn("Merge pull request", func() -> void:
		var result := await _host.merge_pull_request(pull.number)
		go(Page.PULL_DETAIL, result.message, not result.success), GhButtonKind.PRIMARY, GhIcon.PULL_MERGED)
	merge.disabled = detail.merge_blocked_reason != null
	footer.add_child(merge)
	var padded := MarginContainer.new()
	padded.add_theme_constant_override("margin_left", _s(16))
	padded.add_theme_constant_override("margin_right", _s(16))
	padded.add_theme_constant_override("margin_top", _s(14))
	padded.add_theme_constant_override("margin_bottom", _s(14))
	padded.add_child(footer)
	parts.body.add_child(padded)
	_content.add_child(parts.panel)


func _build_merged_box(pull: PullRequestInfo) -> void:
	var branch_still_exists := (await _host.list_branches()).any(
			func(branch: RemoteBranchInfo) -> bool: return branch.name == pull.source_branch)
	if not _is_alive():
		return
	var action: Control = null
	if branch_still_exists:
		action = GitHubUi.btn("Delete branch", func() -> void:
			var deleted := await _host.delete_branch(pull.source_branch)
			go(Page.PULL_DETAIL, "ลบ branch %s แล้ว" % pull.source_branch if deleted else "ลบ branch ไม่ได้", not deleted),
				GhButtonKind.DEFAULT, GhIcon.TRASH)

	var parts := GitHubUi.box()
	parts.body.add_child(_status_row(GhIcon.PULL_MERGED, GitHubTheme.DONE_EMPHASIS, "Pull request successfully merged and closed",
			"คุณทำเสร็จแล้ว — ลบ branch %s ได้อย่างปลอดภัย" % pull.source_branch if branch_still_exists
			else "รวมเข้า %s แล้ว และลบ branch %s ไปแล้ว" % [pull.target_branch, pull.source_branch], true, action))
	_content.add_child(parts.panel)


## กล่องคอมเมนต์ท้ายหน้า Conversation เหมือน GitHub: ช่องพิมพ์ + Close pull request + Comment
## (Approve / Request changes อยู่ที่ปุ่ม Review changes ในแท็บ Files changed)
func _build_comment_box(pull: PullRequestInfo) -> void:
	var reviewer := _repo.owner
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", _s(14))
	var avatar := GitHubUi.avatar(reviewer, 40)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(avatar)

	var card := GitHubUi.card(16, 14)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", _s(10))
	column.add_child(GitHubUi.text_bold("Add a comment", GitHubTheme.FG, 16))
	var comment := TextEdit.new()
	comment.placeholder_text = "Leave a comment"
	comment.custom_minimum_size = Vector2(0, _s(84))
	comment.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	column.add_child(comment)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", _s(10))
	buttons.add_child(GitHubUi.spacer())
	buttons.add_child(GitHubUi.btn("Close pull request", func() -> void:
		var result := _host.close_pull_request(pull.number)
		go(Page.PULL_DETAIL, result.message, not result.success), GhButtonKind.DEFAULT, GhIcon.PULL_CLOSED))
	buttons.add_child(GitHubUi.btn("Comment", func() -> void:
		if comment.text.strip_edges().is_empty():
			go(Page.PULL_DETAIL, "พิมพ์ความเห็นก่อนกด Comment", true)
			return

		var result := _host.comment_on_pull_request(pull.number, reviewer, comment.text)
		go(Page.PULL_DETAIL, result.message, not result.success), GhButtonKind.PRIMARY, GhIcon.COMMENT))
	column.add_child(buttons)
	card.add_child(column)
	row.add_child(card)
	_content.add_child(row)


## หน้าต่าง "Finish your review" ที่เปิดจากปุ่ม Review changes: ความเห็น + เลือก Comment / Approve /
## Request changes แล้วกด Submit review (ผลและเหตุผลที่ปฏิเสธมาจาก host)
func _show_review_menu(anchor: Button, pull: PullRequestInfo, pending_comments: int) -> void:
	var reviewer := _repo.owner
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(_s(440), 0)
	column.add_theme_constant_override("separation", _s(10))
	column.add_child(GitHubUi.text_bold("Finish your review", GitHubTheme.FG, 16))
	if pending_comments > 0:
		column.add_child(GitHubUi.text(
				"%s จะถูกส่งพร้อมรีวิวนี้" % GitHubUi.count(pending_comments, "pending comment", "pending comments"),
				GitHubTheme.FG_MUTED, 13))

	var comment := TextEdit.new()
	comment.placeholder_text = "Leave a comment"
	comment.custom_minimum_size = Vector2(0, _s(84))
	comment.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	column.add_child(comment)

	var group := ButtonGroup.new()
	var verdict := [ReviewVerdict.COMMENTED] # Array เพราะ lambda จับตัวแปรเดี่ยวแบบคัดลอกค่า
	var add_option := func(title: String, hint: String, value: int) -> void:
		var option := CheckBox.new()
		option.text = title
		option.button_group = group
		option.button_pressed = value == verdict[0]
		option.pressed.connect(func() -> void: verdict[0] = value)
		column.add_child(option)
		var note := GitHubUi.text(hint, GitHubTheme.FG_MUTED, 13, false, false, true)
		var indent := MarginContainer.new()
		indent.add_theme_constant_override("margin_left", _s(28))
		indent.add_child(note)
		column.add_child(indent)

	add_option.call("Comment", "Submit general feedback without explicit approval.", ReviewVerdict.COMMENTED)
	add_option.call("Approve", "Submit feedback and approve merging these changes.", ReviewVerdict.APPROVED)
	add_option.call("Request changes", "Submit feedback that must be addressed before merging.", ReviewVerdict.CHANGES_REQUESTED)

	var overlay_holder: Array[Control] = [null]
	var submit := GitHubUi.btn("Submit review", func() -> void:
		if verdict[0] == ReviewVerdict.COMMENTED and comment.text.strip_edges().is_empty() and pending_comments == 0:
			# เก็บเมนูไว้เปิดอยู่ (overlay อยู่นอก _content จึงไม่ถูกล้างตอน go) ข้อความที่พิมพ์ไว้จะไม่หาย
			go(Page.PULL_DETAIL, "พิมพ์ความเห็นก่อน หรือเลือก Approve / Request changes", true)
			return

		var result := _host.review_pull_request(pull.number, reviewer, verdict[0], comment.text)
		if overlay_holder[0] != null:
			overlay_holder[0].queue_free()
		_pull_tab = PullTab.CONVERSATION
		go(Page.PULL_DETAIL, result.message, not result.success), GhButtonKind.PRIMARY)
	var footer := HBoxContainer.new()
	footer.add_child(GitHubUi.spacer())
	footer.add_child(submit)
	column.add_child(footer)
	overlay_holder[0] = _show_floating_panel(anchor, column)


# ───────────── Commits / Files changed ─────────────


func _build_pull_commits(detail: PullRequestDetail) -> void:
	if detail.commits.is_empty():
		_content.add_child(GitHubUi.empty_state(GhIcon.COMMIT, "ไม่มี commit ให้แสดง",
				"PR นี้ไม่มี commit ที่ต่างจาก branch ปลายทางแล้ว"))
		return

	var parts := GitHubUi.box()
	for index in detail.commits.size():
		parts.body.add_child(_commit_row(detail.commits[index], index == detail.commits.size() - 1))
	_content.add_child(parts.panel)


func _build_pull_files(detail: PullRequestDetail) -> void:
	if detail.files.is_empty():
		_content.add_child(GitHubUi.empty_state(GhIcon.FILE, "ไม่มีไฟล์ที่เปลี่ยน",
				"ไม่พบความต่างระหว่าง branch ต้นทางกับปลายทาง"))
		return

	var additions := 0
	var deletions := 0
	for file in detail.files:
		additions += file.additions
		deletions += file.deletions
	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", _s(8))
	summary.add_child(GitHubUi.text("Showing %s with" % GitHubUi.count(detail.files.size(), "changed file", "changed files"),
			GitHubTheme.FG_MUTED))
	summary.add_child(GitHubUi.text_bold("%d additions" % additions, GitHubTheme.SUCCESS, 15))
	summary.add_child(GitHubUi.text("and", GitHubTheme.FG_MUTED))
	summary.add_child(GitHubUi.text_bold("%d deletions" % deletions, GitHubTheme.DANGER, 15))
	var viewer := _repo.owner
	var pending := 0
	for comment in detail.line_comments:
		if comment.is_pending and comment.author.to_lower() == viewer.to_lower():
			pending += 1
	var is_open := detail.pull.state == PullRequestState.OPEN
	if is_open:
		summary.add_child(GitHubUi.spacer())
		var review_holder: Array[Button] = [null]
		var review := GitHubUi.btn("Review changes · %d" % pending if pending > 0 else "Review changes",
				func() -> void: _show_review_menu(review_holder[0], detail.pull, pending),
				GhButtonKind.PRIMARY, GhIcon.COMMENT)
		review_holder[0] = review
		summary.add_child(review)

	_content.add_child(summary)
	var submit := Callable()
	if is_open:
		submit = func(path: String, line: int, on_new_side: bool, body: String, start_review: bool) -> void:
			var result := _host.add_line_comment(detail.pull.number, viewer, path, line, on_new_side, body, start_review)
			_restore_scroll = int(_scroll.scroll_vertical)
			go(Page.PULL_DETAIL, result.message, not result.success)
	var context := DiffCommentContext.new(detail.line_comments, viewer, submit)
	_content.add_child(DiffViewer.build(detail.diff, detail.files, context))
