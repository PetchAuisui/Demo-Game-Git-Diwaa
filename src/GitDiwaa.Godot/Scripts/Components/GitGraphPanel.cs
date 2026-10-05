using Godot;
using GitDiwaa.Core;
using GitDiwaa.Godot.ViewModels;
using GitDiwaa.Godot.Common;

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
	private Button _copyCommitButton = null!;
	private CommitGraphDisplayNode? _selectedCommit;

	public override void _Ready()
	{
		BindNodes();
		var layout = _graphOutput.GetParent();
		var subtitle = new Label
		{
			Text = "COMMIT TIMELINE · เลือก commit เพื่อดูรายละเอียด",
			ClipText = true,
			MouseFilter = MouseFilterEnum.Ignore
		};
		subtitle.AddThemeFontSizeOverride("font_size", 12);
		subtitle.AddThemeColorOverride("font_color", new Color("8da6c6"));
		layout.AddChild(subtitle);
		layout.MoveChild(subtitle, 1);
		_scroll = new ScrollContainer
		{
			SizeFlagsVertical = SizeFlags.ExpandFill, SizeFlagsHorizontal = SizeFlags.ExpandFill,
			HorizontalScrollMode = ScrollContainer.ScrollMode.Disabled
		};
		_canvas = new CommitGraphCanvas { SizeFlagsHorizontal = SizeFlags.ExpandFill };
		_scroll.AddChild(_canvas);
		layout.AddChild(_scroll);
		_details = new Label
		{
			Text = "เลือกจุดบันทึกเพื่อดูรายละเอียด",
			AutowrapMode = TextServer.AutowrapMode.WordSmart,
			CustomMinimumSize = new Vector2(0, 38),
			MaxLinesVisible = 2,
			TextOverrunBehavior = TextServer.OverrunBehavior.TrimEllipsis,
			SizeFlagsHorizontal = SizeFlags.ExpandFill
		};
		_details.AddThemeFontSizeOverride("font_size", 13);
		_details.AddThemeColorOverride("font_color", new Color("a3b2ca"));
		var footer = new PanelContainer();
		var footerStyle = SandboxThemeTokens.CreateCardStyle();
		footerStyle.BgColor = new Color("17283c");
		footerStyle.BorderColor = new Color("526381");
		footerStyle.BorderWidthLeft = footerStyle.BorderWidthRight = footerStyle.BorderWidthTop = footerStyle.BorderWidthBottom = 1;
		footerStyle.ContentMarginLeft = footerStyle.ContentMarginRight = 10;
		footerStyle.ContentMarginTop = footerStyle.ContentMarginBottom = 8;
		footer.AddThemeStyleboxOverride("panel", footerStyle);
		var footerLayout = new HBoxContainer();
		footerLayout.AddThemeConstantOverride("separation", 8);
		footer.AddChild(footerLayout);
		footerLayout.AddChild(_details);
		layout.AddChild(footer);
		_copyCommitButton = new Button
		{
			Name = "CopyCommitButton",
			Text = "คัดลอก ID",
			TooltipText = "คัดลอก hash เต็มของ commit ที่เลือก",
			Disabled = true,
			CustomMinimumSize = new Vector2(96, 32),
			SizeFlagsVertical = SizeFlags.ShrinkCenter
		};
		_copyCommitButton.AddThemeFontSizeOverride("font_size", 13);
		_copyCommitButton.AddThemeColorOverride("font_color", new Color("ffc959"));
		var buttonStyle = SandboxThemeTokens.CreateButtonStyle();
		buttonStyle.BgColor = new Color("202d44");
		buttonStyle.BorderColor = new Color("8b7041");
		_copyCommitButton.AddThemeStyleboxOverride("normal", buttonStyle);
		var hoverStyle = (StyleBoxFlat)buttonStyle.Duplicate();
		hoverStyle.BgColor = new Color("30415d");
		hoverStyle.BorderColor = new Color("ffc959");
		_copyCommitButton.AddThemeStyleboxOverride("hover", hoverStyle);
		_copyCommitButton.AddThemeStyleboxOverride("pressed", hoverStyle);
		var disabledStyle = (StyleBoxFlat)buttonStyle.Duplicate();
		disabledStyle.BgColor = new Color("1c293b");
		disabledStyle.BorderColor = new Color("36465b");
		_copyCommitButton.AddThemeStyleboxOverride("disabled", disabledStyle);
		footerLayout.AddChild(_copyCommitButton);
		_details.VisibilityChanged += () => footer.Visible = _details.Visible;
		_copyCommitButton.Pressed += () =>
		{
			if (_selectedCommit == null) return;
			DisplayServer.ClipboardSet(_selectedCommit.Id);
			_copyCommitButton.Text = "✓ คัดลอกแล้ว";
		};
		_canvas.Selected += ShowCommitDetails;
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
		ShowCommitDetails(null);
		_copyCommitButton.Visible = false;
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
			ShowCommitDetails(null);
			_copyCommitButton.Visible = false;
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
		_copyCommitButton.Visible = true;
		ShowCommitDetails(list.FirstOrDefault(commit => commit.Id == _selectedCommit?.Id));
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

	private void ShowCommitDetails(CommitGraphDisplayNode? commit)
	{
		_selectedCommit = commit;
		_copyCommitButton.Disabled = commit == null;
		_copyCommitButton.Text = "คัดลอก ID";
		_details.Text = commit == null ? "เลือกจุดบันทึกเพื่อดูรายละเอียด" :
			$"{commit.ShortId} · {commit.Author}\n{commit.AuthoredAt.ToLocalTime():dd MMM yyyy HH:mm}";
		_details.TooltipText = commit == null ? string.Empty :
			$"{commit.Subject}\n{commit.Id}\nParents: {string.Join(", ", commit.ParentIds)}";
	}
}
