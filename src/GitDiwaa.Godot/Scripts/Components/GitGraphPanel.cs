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
	private ScrollContainer _scroll = null!;
	private CommitGraphCanvas _canvas = null!;
	private Label _details = null!;

	public override void _Ready()
	{
		BindNodes();
		var layout = _graphOutput.GetParent();
		_scroll = new ScrollContainer { SizeFlagsVertical = SizeFlags.ExpandFill, SizeFlagsHorizontal = SizeFlags.ExpandFill, HorizontalScrollMode = ScrollContainer.ScrollMode.Disabled };
		_canvas = new CommitGraphCanvas { SizeFlagsHorizontal = SizeFlags.ExpandFill };
		_scroll.AddChild(_canvas);
		layout.AddChild(_scroll);
		_details = new Label
		{
			Text = "เลือกจุดบันทึกเพื่อดูรายละเอียด",
			AutowrapMode = TextServer.AutowrapMode.WordSmart,
			CustomMinimumSize = new Vector2(0, 48)
		};
		_details.AddThemeFontSizeOverride("font_size", 15);
		_details.AddThemeColorOverride("font_color", new Color("a3b2ca"));
		layout.AddChild(_details);
		_canvas.Selected += commit =>
		{
			_details.Text = $"{commit.ShortId} · {commit.Author} · {commit.AuthoredAt.ToLocalTime():dd MMM yyyy HH:mm}\n{commit.Subject}";
			_details.TooltipText = $"{commit.Id}\nParents: {string.Join(", ", commit.ParentIds)}";
		};
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
		_canvas.SetLayout(new CommitGraphLayout(Array.Empty<CommitGraphDisplayNode>()));
		_titleLabel.Text = PanelTitle;
		_details.Text = "เลือกจุดบันทึกเพื่อดูรายละเอียด";
		_scroll.Visible = false;
		_details.Visible = false;
		_graphOutput.Visible = true;
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
			_scroll.Visible = false;
			_details.Visible = false;
			_graphOutput.Visible = true;
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

		_graphOutput.Visible = false;
		_scroll.Visible = true;
		_details.Visible = true;
		_canvas.SetLayout(new CommitGraphLayout(list));
		_titleLabel.Text = $"{PanelTitle}  ·  {list.Count} commits";
	}

	public void SetSnapshot(GitRepositorySnapshot snapshot)
	{
		var displayNodes = snapshot.Commits.Select(c =>
			CommitGraphDisplayNode.FromCoreCommit(c, snapshot.Branches, snapshot.CurrentBranch)
		);
		SetCommits(displayNodes);
	}
}
