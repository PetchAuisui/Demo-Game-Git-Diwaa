class_name CommitGraphLayout
extends RefCounted
## Assigns lanes from ancestry, keeping each first-parent chain together.

var rows: Array[CommitGraphRow] = []
var edges: Array[CommitGraphEdge] = []
var lane_count: int = 1


func _init(commits: Array[CommitGraphDisplayNode] = []) -> void:
	var remaining: Array[CommitGraphDisplayNode] = []
	var seen := {}
	for commit in commits:
		if not seen.has(commit.id):
			seen[commit.id] = true
			remaining.append(commit)

	var ordered: Array[CommitGraphDisplayNode] = []
	# A parent must be below every child, even when author timestamps are out of order.
	while not remaining.is_empty():
		var parents := {}
		for commit in remaining:
			for parent in commit.parent_ids:
				parents[parent] = true
		var next: CommitGraphDisplayNode = remaining[0]
		for commit in remaining:
			if not parents.has(commit.id):
				next = commit
				break
		ordered.append(next)
		remaining.erase(next)

	var active: Array[String] = []
	var max_lanes := 1
	for commit in ordered:
		var lane := active.find(commit.id)
		if lane < 0:
			lane = active.size()
			active.append(commit.id)
		rows.append(CommitGraphRow.new(commit, lane))
		active.remove_at(lane)
		var insert_at := lane
		for parent in commit.parent_ids:
			if active.has(parent):
				continue
			active.insert(mini(insert_at, active.size()), parent)
			insert_at += 1
		max_lanes = maxi(max_lanes, maxi(active.size(), lane + 1))

	var indexes := {}
	for index in rows.size():
		indexes[rows[index].commit.id] = index
	for index in rows.size():
		var parent_ids := rows[index].commit.parent_ids
		for parent_index in parent_ids.size():
			if indexes.has(parent_ids[parent_index]):
				var target: int = indexes[parent_ids[parent_index]]
				edges.append(CommitGraphEdge.new(index, rows[index].lane, target, rows[target].lane, parent_index > 0))
	lane_count = max_lanes
