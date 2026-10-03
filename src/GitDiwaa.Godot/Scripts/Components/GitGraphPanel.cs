using Godot;
using GitDiwaa.Core;
using GitDiwaa.Godot.Common;
using GitDiwaa.Godot.ViewModels;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// Reusable OOP Git Graph Component for Godot.
/// Visualizes commit history, branch pointers, commit messages, and connection lines.
/// Supports empty states matching the reference design.
/// </summary>
public partial class GitGraphPanel : PanelContainer
{
    [Signal]
    public delegate void CommitSelectedEventHandler(string commitId);

    [Export]
    public string PanelTitle { get; set; } = "GIT GRAPH";

    [Export]
    public string EmptyTitle { get; set; } = "ยังไม่มี Commit";

    [Export]
    public string EmptySubtitle { get; set; } = "สร้าง repository และ commit แล้วประวัติจะแสดงที่นี่";

    private Label _titleLabel = null!;
    private Label _countBadgeLabel = null!;
    private Control _emptyContainer = null!;
    private Label _emptyTitleLabel = null!;
    private Label _emptySubtitleLabel = null!;
    private ScrollContainer _scrollContainer = null!;
    private VBoxContainer _commitListContainer = null!;

    private readonly List<CommitGraphDisplayNode> _currentCommits = new();
    private string? _selectedCommitId;

    public override void _Ready()
    {
        ApplyStyles();
        BindNodes();

        _titleLabel.Text = PanelTitle;
        _emptyTitleLabel.Text = EmptyTitle;
        _emptySubtitleLabel.Text = EmptySubtitle;

        UpdateView();
    }

    private void BindNodes()
    {
        _titleLabel = GetNode<Label>("%TitleLabel");
        _countBadgeLabel = GetNode<Label>("%CountBadgeLabel");
        _emptyContainer = GetNode<Control>("%EmptyContainer");
        _emptyTitleLabel = GetNode<Label>("%EmptyTitleLabel");
        _emptySubtitleLabel = GetNode<Label>("%EmptySubtitleLabel");
        _scrollContainer = GetNode<ScrollContainer>("%ScrollContainer");
        _commitListContainer = GetNode<VBoxContainer>("%CommitListContainer");
    }

    private void ApplyStyles()
    {
        var panelStyle = SandboxThemeTokens.CreatePanelStyle(
            bgColor: SandboxThemeTokens.PanelBackground,
            borderColor: SandboxThemeTokens.BorderSubtle,
            borderWidth: 1,
            cornerRadius: 6,
            contentMargin: 10
        );
        AddThemeStyleboxOverride("panel", panelStyle);
    }

    public void SetCommits(IEnumerable<CommitGraphDisplayNode> commits)
    {
        _currentCommits.Clear();
        _currentCommits.AddRange(commits);
        UpdateView();
    }

    public void SetSnapshot(GitRepositorySnapshot snapshot)
    {
        var displayNodes = snapshot.Commits.Select(c =>
            CommitGraphDisplayNode.FromCoreCommit(c, snapshot.Branches, snapshot.CurrentBranch)
        );
        SetCommits(displayNodes);
    }

    public IReadOnlyList<CommitGraphDisplayNode> GetCommits() => _currentCommits.AsReadOnly();

    public void SetEmptyMessage(string title, string subtitle)
    {
        EmptyTitle = title;
        EmptySubtitle = subtitle;
        if (_emptyTitleLabel != null) _emptyTitleLabel.Text = title;
        if (_emptySubtitleLabel != null) _emptySubtitleLabel.Text = subtitle;
    }

    private void UpdateView()
    {
        if (_commitListContainer == null) return;

        foreach (Node child in _commitListContainer.GetChildren())
        {
            child.QueueFree();
        }

        var count = _currentCommits.Count;
        _countBadgeLabel.Text = count > 0 ? $"({count})" : string.Empty;

        if (count == 0)
        {
            _emptyContainer.Visible = true;
            _scrollContainer.Visible = false;
            return;
        }

        _emptyContainer.Visible = false;
        _scrollContainer.Visible = true;

        for (int i = 0; i < _currentCommits.Count; i++)
        {
            var commit = _currentCommits[i];
            var isLast = i == _currentCommits.Count - 1;
            var nodeCard = CreateCommitNodeCard(commit, isLast);
            _commitListContainer.AddChild(nodeCard);
        }
    }

    private Control CreateCommitNodeCard(CommitGraphDisplayNode commit, bool isLast)
    {
        var card = new PanelContainer
        {
            CustomMinimumSize = new Vector2(0, 54),
            SizeFlagsHorizontal = SizeFlags.ExpandFill
        };

        var isSelected = string.Equals(_selectedCommitId, commit.Id, StringComparison.OrdinalIgnoreCase);
        var cardStyle = SandboxThemeTokens.CreatePanelStyle(
            bgColor: isSelected ? new Color(0.16f, 0.20f, 0.32f, 0.85f) : new Color(0.10f, 0.12f, 0.18f, 0.7f),
            borderColor: isSelected ? SandboxThemeTokens.BorderGold : new Color(0.20f, 0.23f, 0.34f, 0.6f),
            borderWidth: 1,
            cornerRadius: 4,
            contentMargin: 8
        );
        card.AddThemeStyleboxOverride("panel", cardStyle);

        var rootHBox = new HBoxContainer();
        rootHBox.AddThemeConstantOverride("separation", 10);
        card.AddChild(rootHBox);

        // Left graph column: commit node circle & vertical line
        var graphCol = new VBoxContainer
        {
            CustomMinimumSize = new Vector2(16, 0),
            Alignment = BoxContainer.AlignmentMode.Center
        };
        graphCol.AddThemeConstantOverride("separation", 2);

        var nodeCircle = new ColorRect
        {
            CustomMinimumSize = new Vector2(10, 10),
            SizeFlagsHorizontal = SizeFlags.ShrinkCenter,
            SizeFlagsVertical = SizeFlags.ShrinkCenter,
            Color = commit.IsCurrentBranchHead ? SandboxThemeTokens.BorderGold : SandboxThemeTokens.TextCyan
        };
        graphCol.AddChild(nodeCircle);

        if (!isLast)
        {
            var lineRect = new ColorRect
            {
                CustomMinimumSize = new Vector2(2, 24),
                SizeFlagsHorizontal = SizeFlags.ShrinkCenter,
                SizeFlagsVertical = SizeFlags.ExpandFill,
                Color = new Color(0.35f, 0.40f, 0.55f, 0.6f)
            };
            graphCol.AddChild(lineRect);
        }

        rootHBox.AddChild(graphCol);

        // Details column
        var detailsCol = new VBoxContainer
        {
            SizeFlagsHorizontal = SizeFlags.ExpandFill
        };
        detailsCol.AddThemeConstantOverride("separation", 3);

        // Row 1: Hash + Branch Badges
        var metaRow = new HBoxContainer();
        metaRow.AddThemeConstantOverride("separation", 6);

        var hashLabel = new Label
        {
            Text = $"[{commit.ShortId}]"
        };
        hashLabel.AddThemeColorOverride("font_color", SandboxThemeTokens.TextGold);
        hashLabel.AddThemeFontSizeOverride("font_size", 11);
        metaRow.AddChild(hashLabel);

        foreach (var branch in commit.Branches)
        {
            var branchBadge = CreateBadge(branch, commit.IsCurrentBranchHead ? SandboxThemeTokens.TextGreen : SandboxThemeTokens.TextCyan);
            metaRow.AddChild(branchBadge);
        }

        detailsCol.AddChild(metaRow);

        // Row 2: Subject
        var subjectLabel = new Label
        {
            Text = commit.Subject,
            TextOverrunBehavior = TextServer.OverrunBehavior.TrimEllipsis
        };
        subjectLabel.AddThemeColorOverride("font_color", SandboxThemeTokens.TextPrimary);
        subjectLabel.AddThemeFontSizeOverride("font_size", 12);
        detailsCol.AddChild(subjectLabel);

        // Row 3: Author and timestamp
        var authorLabel = new Label
        {
            Text = $"{commit.Author} • {FormatTimestamp(commit.AuthoredAt)}"
        };
        authorLabel.AddThemeColorOverride("font_color", SandboxThemeTokens.TextSecondary);
        authorLabel.AddThemeFontSizeOverride("font_size", 10);
        detailsCol.AddChild(authorLabel);

        rootHBox.AddChild(detailsCol);

        // Card click handling
        card.GuiInput += (InputEvent @event) =>
        {
            if (@event is InputEventMouseButton mb && mb.Pressed && mb.ButtonIndex == MouseButton.Left)
            {
                _selectedCommitId = commit.Id;
                UpdateView();
                EmitSignal(SignalName.CommitSelected, commit.Id);
            }
        };

        return card;
    }

    private Control CreateBadge(string text, Color textColor)
    {
        var badgePanel = new PanelContainer();
        var style = SandboxThemeTokens.CreatePanelStyle(
            bgColor: new Color(textColor.R, textColor.G, textColor.B, 0.15f),
            borderColor: textColor,
            borderWidth: 1,
            cornerRadius: 3,
            contentMargin: 4
        );
        style.ContentMarginTop = 1;
        style.ContentMarginBottom = 1;
        style.ContentMarginLeft = 5;
        style.ContentMarginRight = 5;
        badgePanel.AddThemeStyleboxOverride("panel", style);

        var label = new Label
        {
            Text = text
        };
        label.AddThemeColorOverride("font_color", textColor);
        label.AddThemeFontSizeOverride("font_size", 10);
        badgePanel.AddChild(label);

        return badgePanel;
    }

    private static string FormatTimestamp(DateTimeOffset timestamp)
    {
        var span = DateTimeOffset.UtcNow - timestamp;
        if (span.TotalMinutes < 1) return "Just now";
        if (span.TotalMinutes < 60) return $"{(int)span.TotalMinutes}m ago";
        if (span.TotalHours < 24) return $"{(int)span.TotalHours}h ago";
        return timestamp.ToString("yyyy-MM-dd");
    }
}
