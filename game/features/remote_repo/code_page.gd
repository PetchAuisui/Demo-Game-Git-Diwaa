class_name CodePage
extends VBoxContainer
## หน้า Code ของ repo (Scenes/CodePage.tscn): แถบเครื่องมือ (branch ปุ่ม Branches ช่อง Go to file ปุ่ม Code) อยู่ใน scene
## ส่วนที่ตามมา (breadcrumb ตารางไฟล์ README) สร้างตามข้อมูลแล้วต่อท้ายหน้านี้ด้วย add_child


func _ready() -> void:
	var size := GitHubTheme.s(16)
	(get_node("%BranchesButton") as Button).icon = GitHubIcons.get_icon(GhIcon.BRANCH, GitHubTheme.FG_MUTED, size)
	(get_node("%SearchEdit") as LineEdit).right_icon = GitHubIcons.get_icon(GhIcon.SEARCH, GitHubTheme.FG_MUTED, size, 1.0)
	(get_node("%CodeButton") as Button).icon = GitHubIcons.get_icon(GhIcon.CODE, Color.WHITE, size)


## on_branch_selected(name: String) เปลี่ยน branch จากตัวเลือก
## on_branches() กดปุ่ม Branches
## on_search(text: String) พิมพ์ในช่อง Go to file (กรองแถวไฟล์)
## on_code(button: Button) กดปุ่ม Code (ส่งปุ่มไปเป็นจุดยึดของเมนู Clone)
func setup(branches: Array[RemoteBranchInfo], selected: String, on_branch_selected: Callable,
		on_branches: Callable, on_search: Callable, on_code: Callable) -> void:
	GitHubUi.fill_branch_picker(get_node("%BranchPicker") as OptionButton, branches, on_branch_selected, selected)

	var branches_button := get_node("%BranchesButton") as Button
	branches_button.text = GitHubUi.count(branches.size(), "Branch", "Branches")
	branches_button.pressed.connect(on_branches)

	(get_node("%SearchEdit") as LineEdit).text_changed.connect(func(text: String) -> void: on_search.call(text))

	var code_button := get_node("%CodeButton") as Button
	code_button.pressed.connect(func() -> void: on_code.call(code_button))
