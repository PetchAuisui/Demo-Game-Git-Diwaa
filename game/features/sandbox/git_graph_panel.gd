class_name GitGraphPanel
extends PanelContainer
## Reusable OOP Git Graph Component for Godot.
## Matches the authentic Checkpoint-01 GraphPanel visual style.

signal commit_selected(commit_id: String)

@export var panel_title: String = "แผนผัง GIT GRAPH"
@export var empty_text: String = "ยังไม่มี Commit\nสร้าง repository และ commit แล้วประวัติจะแสดงที่นี่"

var _title_label: Label
var _header_actions: HBoxContainer
var _graph_output: RichTextLabel
var _scroll: ScrollContainer
var _canvas: CommitGraphCanvas
var _details: Label


func _ready() -> void:
	_title_label = get_node("%TitleLabel")
	_header_actions = get_node("%HeaderActions")
	_graph_output = get_node("%GraphOutput")

	var layout := _graph_output.get_parent()
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var font_regular = load("res://assets/fonts/ChakraPetch-Regular.ttf")
	_canvas = CommitGraphCanvas.new()
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if font_regular:
		_canvas.add_theme_font_override("font", font_regular)
	_scroll.add_child(_canvas)
	layout.add_child(_scroll)
	_details = Label.new()
	_details.text = "เลือกจุดบันทึกเพื่อดูรายละเอียด"
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.custom_minimum_size = Vector2(0, 48)
	if font_regular:
		_details.add_theme_font_override("font", font_regular)
	_details.add_theme_font_size_override("font_size", 15)
	_details.add_theme_color_override("font_color", Color("a3b2ca"))
	layout.add_child(_details)
	_canvas.selected.connect(func(commit: CommitGraphDisplayNode) -> void:
		_details.text = "%s · %s · %s\n%s" % [commit.short_id, commit.author, GitTime.format_local(commit.authored_at), commit.subject]
		_details.tooltip_text = "%s\nParents: %s" % [commit.id, ", ".join(commit.parent_ids)]
		commit_selected.emit(commit.id))
	_title_label.text = panel_title
	set_empty_state()


## เพิ่มปุ่มหรือตัวควบคุมที่มุมขวาของหัวพาเนล (เจ้าของพาเนลเป็นคนเลือกว่าจะใส่อะไร)
func add_header_action(action: Control) -> void:
	_header_actions.add_child(action)


func set_empty_state() -> void:
	_canvas.set_layout(CommitGraphLayout.new())
	_title_label.text = panel_title
	_details.text = "เลือกจุดบันทึกเพื่อดูรายละเอียด"
	_scroll.visible = false
	_details.visible = false
	_graph_output.visible = true
	_graph_output.text = empty_text


func set_graph_text(text: String) -> void:
	if text.strip_edges().is_empty():
		set_empty_state()
	else:
		_scroll.visible = false
		_details.visible = false
		_graph_output.visible = true
		_graph_output.text = text.strip_edges(false, true)


func set_commits(commits: Array[CommitGraphDisplayNode]) -> void:
	if commits.is_empty():
		set_empty_state()
		return

	_graph_output.visible = false
	_scroll.visible = true
	_details.visible = true
	_canvas.set_layout(CommitGraphLayout.new(commits))
	_title_label.text = "%s  ·  %d คอมมิต" % [panel_title, commits.size()]


func set_snapshot(snapshot: GitRepositorySnapshot) -> void:
	var display_nodes: Array[CommitGraphDisplayNode] = []
	for commit in snapshot.commits:
		display_nodes.append(CommitGraphDisplayNode.from_core_commit(commit, snapshot.branches))
	set_commits(display_nodes)
