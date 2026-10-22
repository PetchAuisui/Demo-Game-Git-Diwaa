class_name GitGraphPreview
extends Control
## Manual preview fixture; not used by the game's main scene.


func _ready() -> void:
	var panel := (load("res://Scenes/GitGraphPanel.tscn") as PackedScene).instantiate() as GitGraphPanel
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var now := GitTime.now()
	var branches: Array[GitBranchInfo] = [
		GitBranchInfo.new("main", true, "a123456", null),
		GitBranchInfo.new("feature/quest", false, "c123456", null),
	]
	var commits: Array[GitCommitNode] = [
		GitCommitNode.new("a123456", ["b123456", "c123456"] as Array[String], [] as Array[String],
				"Merge feature/quest into main", "Player", now),
		GitCommitNode.new("b123456", ["d123456"] as Array[String], [] as Array[String],
				"ปรับบทสนทนาของมิวรา", "Player", now - 5 * 60),
		GitCommitNode.new("c123456", ["d123456"] as Array[String], [] as Array[String],
				"เพิ่มภารกิจในหอคอย", "Miura", now - 8 * 60),
		GitCommitNode.new("d123456", ["e123456"] as Array[String], [] as Array[String],
				"เตรียมไฟล์สำหรับภารกิจแรก", "Player", now - 15 * 60),
		GitCommitNode.new("e123456", [] as Array[String], [] as Array[String],
				"เริ่มต้นการผจญภัย Git-Diwaa", "Player", now - 30 * 60),
	]
	var snapshot := GitRepositorySnapshot.new(true, "main", [] as Array[GitFileStatus], branches, commits)
	panel.set_snapshot(snapshot)

	var display: Array[CommitGraphDisplayNode] = []
	for commit in snapshot.commits:
		display.append(CommitGraphDisplayNode.from_core_commit(commit, snapshot.branches))
	var layout := CommitGraphLayout.new(display)
	if layout.rows[0].commit.id != "a123456" or layout.lane_count < 2 or layout.edges.size() != 5 \
			or layout.edges.any(func(edge: CommitGraphEdge) -> bool: return edge.to_row <= edge.from_row):
		push_error("Preview graph ancestry check failed.")
		return

	var canvas := panel.find_children("*", "CommitGraphCanvas", true, false)[0] as CommitGraphCanvas
	var selected_id := [""]
	canvas.selected.connect(func(commit: CommitGraphDisplayNode) -> void: selected_id[0] = commit.id)
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_DOWN
	canvas._gui_input(key)
	if selected_id[0] != "a123456":
		push_error("Preview keyboard selection failed.")
		return
	panel.set_empty_state()
	panel.set_snapshot(snapshot)
	print("PASS graph preview: merge ancestry, lane split, keyboard selection, empty-state refresh")
