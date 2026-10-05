using Godot;
using GitDiwaa.Core;
using GitDiwaa.Godot.ViewModels;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// Reusable OOP Git Graph Component for Godot.
/// Matches the authentic Checkpoint-01 GraphPanel visual style.
/// </summary>
public partial class GitGraphPanel : PanelContainer
{
	[Signal]
	public delegate void CommitSelectedEventHandler(string commitId);

	[Export]
	public string PanelTitle { get; set; } = "GIT GRAPH";

	[Export]
	public string EmptyText { get; set; } = "ยังไม่มี Commit\nสร้าง repository และ commit แล้วประวัติจะแสดงที่นี่";

	private Label _titleLabel = null!;
	private RichTextLabel _graphOutput = null!;

	public override void _Ready()
	{
		BindNodes();
		_titleLabel.Text = PanelTitle;
		SetEmptyState();
	}

	private void BindNodes()
	{
		_titleLabel = GetNode<Label>("%TitleLabel");
		_graphOutput = GetNode<RichTextLabel>("%GraphOutput");
	}

	public void SetEmptyState()
	{
		_graphOutput.Text = EmptyText;
	}

	public void SetGraphText(string text)
	{
		if (string.IsNullOrWhiteSpace(text))
		{
			SetEmptyState();
		}
		else
		{
			_graphOutput.Text = text.TrimEnd();
		}
	}

	public void SetCommits(IEnumerable<CommitGraphDisplayNode> commits)
	{
		var list = commits.ToList();
		if (list.Count == 0)
		{
			SetEmptyState();
			return;
		}

		_graphOutput.Clear();
		for (int i = 0; i < list.Count; i++)
		{
			var commit = list[i];
			var branchText = commit.Branches.Count > 0 ? $" ({string.Join(", ", commit.Branches)})" : string.Empty;
			var nodeMarker = commit.IsCurrentBranchHead ? "[color=#ffc959]*[/color]" : "[color=#50f29e]*[/color]";
			var hashColor = commit.IsCurrentBranchHead ? "#ffc959" : "#38bdf8";

			_graphOutput.AppendText($"{nodeMarker} [color={hashColor}]{commit.ShortId}[/color]{branchText} {commit.Subject}\n");
			if (i < list.Count - 1)
			{
				_graphOutput.AppendText("[color=#485268]|[/color]\n");
			}
		}
	}

	public void SetSnapshot(GitRepositorySnapshot snapshot)
	{
		var displayNodes = snapshot.Commits.Select(c =>
			CommitGraphDisplayNode.FromCoreCommit(c, snapshot.Branches, snapshot.CurrentBranch)
		);
		SetCommits(displayNodes);
	}
}
