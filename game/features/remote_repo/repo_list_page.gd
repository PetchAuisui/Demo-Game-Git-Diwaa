class_name RepoListPage
extends VBoxContainer
## หน้ารายการ repo ก่อนเข้า repo (Scenes/RepoListPage.tscn): การ์ดโปรไฟล์ซ้าย, ช่องค้นหา + ปุ่ม New และรายการ repo ขวา
## โครงอยู่ใน scene โค้ดนี้ใส่ข้อมูล (ชื่อเจ้าของ จำนวน repo แถวรายการ) และกรองตามคำค้น

var _tabs: HBoxContainer
var _list: VBoxContainer


func _ready() -> void:
	_tabs = get_node("%Tabs")
	_list = get_node("%List")
	(get_node("%NewButton") as Button).icon = GitHubIcons.get_icon(GhIcon.REPO, Color.WHITE, GitHubTheme.s(16))
	(get_node("%OwnerName") as Label).add_theme_font_override("font", GitHubTheme.bold_font())


## on_open(name: String) เรียกเมื่อกดแถว repo, on_new() เรียกเมื่อกดปุ่ม New
func setup(owner: String, repos: Array[RemoteRepositoryInfo], on_open: Callable, on_new: Callable) -> void:
	_tabs.add_child(GitHubUi.tab("Repositories", true, func() -> void: pass, GhIcon.REPO, repos.size()))

	(get_node("%OwnerName") as Label).text = owner
	(get_node("%AvatarSlot") as CenterContainer).add_child(GitHubUi.avatar(owner, 120))

	(get_node("%NewButton") as Button).pressed.connect(on_new)
	(get_node("%SearchEdit") as LineEdit).text_changed.connect(
			func(text: String) -> void: _fill_list(repos, text, on_open))
	_fill_list(repos, "", on_open)


func _fill_list(repos: Array[RemoteRepositoryInfo], filter: String, on_open: Callable) -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()

	var shown: Array[RemoteRepositoryInfo] = []
	for repo in repos:
		if filter.is_empty() or repo.name.to_lower().contains(filter.to_lower()):
			shown.append(repo)
	if shown.is_empty():
		_list.add_child(GitHubUi.empty_state(GhIcon.REPO, "ไม่พบ repository",
				"กด New เพื่อสร้าง repository แรก" if repos.is_empty() else "ลองค้นหาด้วยชื่ออื่น"))
		return

	for index in shown.size():
		var repo := shown[index]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", GitHubTheme.s(10))
		var text_column := VBoxContainer.new()
		text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_column.add_child(GitHubUi.text_bold(repo.name, GitHubTheme.ACCENT, 22))
		var meta: String
		if repo.is_empty:
			meta = "ยังว่างอยู่ — push งานขึ้นมาก่อน"
		else:
			meta = "%s · %s" % [GitHubUi.count(repo.branch_count, "branch", "branches"),
					GitHubUi.count(repo.commit_count, "commit", "commits")]
		text_column.add_child(GitHubUi.text(meta, GitHubTheme.FG_MUTED, 14))
		row.add_child(text_column)
		row.add_child(GitHubUi.pill("Public", GitHubTheme.FG_MUTED, GitHubTheme.BORDER))
		var repo_name := repo.name
		_list.add_child(GitHubUi.list_row(row, index == shown.size() - 1, func() -> void: on_open.call(repo_name)))
