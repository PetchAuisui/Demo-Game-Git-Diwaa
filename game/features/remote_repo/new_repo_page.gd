class_name NewRepoPage
extends PanelContainer
## ฟอร์มสร้าง repository ใหม่ (ว่าง) เหมือนหน้า New repository ของ GitHub (Scenes/NewRepoPage.tscn)
## โครงฟอร์มอยู่ใน scene โค้ดนี้ผูกปุ่ม สร้าง repo และแสดงข้อผิดพลาด

var _error: Label
var _name: LineEdit
var _description: LineEdit
var _busy := false
var _create: Callable


func _ready() -> void:
	_error = get_node("%Error")
	_name = get_node("%NameEdit")

	for label in ["%Title", "%NameLabel", "%OwnerLabel", "%DescriptionLabel"]:
		(get_node(label) as Label).add_theme_font_override("font", GitHubTheme.bold_font())
	(get_node("%CreateButton") as Button).icon = GitHubIcons.get_icon(GhIcon.REPO, Color.WHITE, GitHubTheme.s(16))


## create(name: String, description: String) -> OpResult  (coroutine) สร้าง repo จากชื่อและคำอธิบาย
##   ล้มเหลวพร้อมข้อความ จะแสดงใต้ช่องกรอก
## cancel() กดยกเลิก
func setup(owner: String, create: Callable, cancel: Callable) -> void:
	(get_node("%OwnerLabel") as Label).text = owner
	_description = get_node("%DescriptionEdit")
	_create = create

	_name.text_submitted.connect(func(_text: String) -> void: _submit())
	(get_node("%CreateButton") as Button).pressed.connect(_submit)
	(get_node("%CancelButton") as Button).pressed.connect(cancel)
	(func() -> void:
		if is_instance_valid(_name):
			_name.grab_focus()).call_deferred()


func _submit() -> void:
	if _busy:
		return # กดซ้ำ (Enter แล้วคลิก) ระหว่างรอ ไม่ให้สร้างสองรอบ
	_busy = true
	_error.visible = false
	var result: OpResult = await _create.call(_name.text, _description.text)
	# กดสร้างซ้ำเร็วๆ: ครั้งแรกสำเร็จแล้วหน้าถูกสร้างใหม่ ฟอร์มเดิมถูกลบไปแล้ว
	if not is_instance_valid(self) or is_queued_for_deletion():
		return
	_busy = false
	if result != null and not result.ok:
		_error.text = result.message
		_error.visible = true
