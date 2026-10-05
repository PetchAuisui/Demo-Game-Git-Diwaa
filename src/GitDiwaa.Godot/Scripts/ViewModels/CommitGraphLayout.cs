namespace GitDiwaa.Godot.ViewModels;

public sealed record CommitGraphRow(CommitGraphDisplayNode Commit, int Lane);
public sealed record CommitGraphEdge(int FromRow, int FromLane, int ToRow, int ToLane);

/// <summary>Assigns lanes from ancestry, keeping each first-parent chain together.</summary>
public sealed class CommitGraphLayout
{
    public IReadOnlyList<CommitGraphRow> Rows { get; }
    public IReadOnlyList<CommitGraphEdge> Edges { get; }
    public int LaneCount { get; }

    public CommitGraphLayout(IEnumerable<CommitGraphDisplayNode> commits)
    {
        var remaining = commits.DistinctBy(commit => commit.Id).ToList();
        var ordered = new List<CommitGraphDisplayNode>();
        // A parent must be below every child, even when author timestamps are out of order.
        while (remaining.Count > 0)
        {
            var parents = remaining.SelectMany(commit => commit.ParentIds).ToHashSet();
            var next = remaining.FirstOrDefault(commit => !parents.Contains(commit.Id)) ?? remaining[0];
            ordered.Add(next);
            remaining.Remove(next);
        }

        var active = new List<string>();
        var rows = new List<CommitGraphRow>();
        var maxLanes = 1;
        foreach (var commit in ordered)
        {
            var lane = active.IndexOf(commit.Id);
            if (lane < 0) { lane = active.Count; active.Add(commit.Id); }
            rows.Add(new(commit, lane));
            active.RemoveAt(lane);
            var insertAt = lane;
            foreach (var parent in commit.ParentIds)
            {
                if (active.Contains(parent)) continue;
                active.Insert(Math.Min(insertAt++, active.Count), parent);
            }
            maxLanes = Math.Max(maxLanes, Math.Max(active.Count, lane + 1));
        }

        var indexes = rows.Select((row, index) => (row.Commit.Id, index)).ToDictionary(pair => pair.Id, pair => pair.index);
        var edges = new List<CommitGraphEdge>();
        for (var index = 0; index < rows.Count; index++)
            foreach (var parent in rows[index].Commit.ParentIds)
                if (indexes.TryGetValue(parent, out var target))
                    edges.Add(new(index, rows[index].Lane, target, rows[target].Lane));
        Rows = rows;
        Edges = edges;
        LaneCount = maxLanes;
    }
}
