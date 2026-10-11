using Godot;
using GitDiwaa.Core;

namespace GitDiwaa.Godot.Components;

/// <summary>Manual preview fixture; not used by the game's main scene.</summary>
public partial class GitGraphPreview : Control
{
    public override void _Ready()
    {
        var panel = GD.Load<PackedScene>("res://Scenes/GitGraphPanel.tscn").Instantiate<GitGraphPanel>();
        AddChild(panel);
        panel.SetAnchorsAndOffsetsPreset(LayoutPreset.FullRect);
        var now = DateTimeOffset.Now;
        var snapshot = new GitRepositorySnapshot(true, "main", [],
            [new("main", true, "a123456", null), new("feature/quest", false, "c123456", null)],
            [
                new("a123456", ["b123456", "c123456"], [], "Merge feature/quest into main", "Player", now),
                new("b123456", ["d123456"], [], "ปรับบทสนทนาของมิวรา", "Player", now.AddMinutes(-5)),
                new("c123456", ["d123456"], [], "เพิ่มภารกิจในหอคอย", "Miura", now.AddMinutes(-8)),
                new("d123456", ["e123456"], [], "เตรียมไฟล์สำหรับภารกิจแรก", "Player", now.AddMinutes(-15)),
                new("e123456", [], [], "เริ่มต้นการผจญภัย Git-Diwaa", "Player", now.AddMinutes(-30))
            ]);
        panel.SetSnapshot(snapshot);
        var layout = new ViewModels.CommitGraphLayout(snapshot.Commits.Select(commit =>
            ViewModels.CommitGraphDisplayNode.FromCoreCommit(commit, snapshot.Branches, snapshot.CurrentBranch)));
        if (layout.Rows[0].Commit.Id != "a123456" || layout.LaneCount < 2 || layout.Edges.Count != 5 ||
            layout.Edges.Any(edge => edge.ToRow <= edge.FromRow))
            throw new InvalidOperationException("Preview graph ancestry check failed.");
        var canvas = panel.FindChildren("*", "", true, false).OfType<CommitGraphCanvas>().Single();
        string? selectedId = null;
        canvas.Selected += commit => selectedId = commit.Id;
        canvas._GuiInput(new InputEventKey { Pressed = true, Keycode = Key.Down });
        if (selectedId != "a123456") throw new InvalidOperationException("Preview keyboard selection failed.");
        panel.SetEmptyState();
        panel.SetSnapshot(snapshot);
        GD.Print("PASS graph preview: merge ancestry, lane split, keyboard selection, empty-state refresh");
    }
}
