using Godot;
using GitDiwaa.Godot.Common;
using GitDiwaa.Godot.ViewModels;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// Reusable OOP Files Component for Godot.
/// Displays working tree files, Git status badges, empty states, and handles file selection/creation events.
/// </summary>
public partial class FilesPanel : PanelContainer
{
    [Signal]
    public delegate void FileSelectedEventHandler(string filePath);

    [Signal]
    public delegate void CreateFileRequestedEventHandler(string filePath, string content);

    [Export]
    public string PanelTitle { get; set; } = "FILES — พื้นที่ทำงาน";

    [Export]
    public string EmptyMessage { get; set; } = "ยังไม่มีไฟล์";

    private Label _titleLabel = null!;
    private Label _countBadgeLabel = null!;
    private Label _emptyLabel = null!;
    private VBoxContainer _fileListContainer = null!;
    private ScrollContainer _scrollContainer = null!;
    private Button _createFileButton = null!;

    private readonly List<FileDisplayItem> _currentFiles = new();
    private string? _selectedFilePath;

    public override void _Ready()
    {
        ApplyStyles();
        BindNodes();

        _titleLabel.Text = PanelTitle;
        _emptyLabel.Text = EmptyMessage;

        _createFileButton.Pressed += OnCreateFileButtonPressed;

        UpdateView();
    }

    private void BindNodes()
    {
        _titleLabel = GetNode<Label>("%TitleLabel");
        _countBadgeLabel = GetNode<Label>("%CountBadgeLabel");
        _emptyLabel = GetNode<Label>("%EmptyLabel");
        _fileListContainer = GetNode<VBoxContainer>("%FileListContainer");
        _scrollContainer = GetNode<ScrollContainer>("%ScrollContainer");
        _createFileButton = GetNode<Button>("%CreateFileButton");
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

    public void SetFiles(IEnumerable<FileDisplayItem> files)
    {
        _currentFiles.Clear();
        _currentFiles.AddRange(files);
        UpdateView();
    }

    public IReadOnlyList<FileDisplayItem> GetFiles() => _currentFiles.AsReadOnly();

    public void SetEmptyMessage(string message)
    {
        EmptyMessage = message;
        if (_emptyLabel != null) _emptyLabel.Text = message;
    }

    private void UpdateView()
    {
        if (_fileListContainer == null) return;

        // Clear existing children
        foreach (Node child in _fileListContainer.GetChildren())
        {
            child.QueueFree();
        }

        var count = _currentFiles.Count;
        _countBadgeLabel.Text = count > 0 ? $"({count})" : string.Empty;

        if (count == 0)
        {
            _emptyLabel.Visible = true;
            _scrollContainer.Visible = false;
            return;
        }

        _emptyLabel.Visible = false;
        _scrollContainer.Visible = true;

        foreach (var file in _currentFiles)
        {
            var itemButton = CreateFileItemWidget(file);
            _fileListContainer.AddChild(itemButton);
        }
    }

    private Button CreateFileItemWidget(FileDisplayItem file)
    {
        var btn = new Button
        {
            Alignment = HorizontalAlignment.Left,
            CustomMinimumSize = new Vector2(0, 32),
            FocusMode = FocusModeEnum.None,
            Text = string.Empty
        };

        var isSelected = string.Equals(_selectedFilePath, file.Path, StringComparison.OrdinalIgnoreCase);

        var normalStyle = SandboxThemeTokens.CreateButtonStyle(
            bgColor: isSelected ? new Color(0.18f, 0.22f, 0.35f, 0.8f) : new Color(0.10f, 0.12f, 0.18f, 0.6f),
            borderColor: isSelected ? SandboxThemeTokens.BorderFocus : new Color(0.18f, 0.20f, 0.30f, 0.5f),
            borderWidth: 1,
            cornerRadius: 4
        );
        btn.AddThemeStyleboxOverride("normal", normalStyle);

        // Internal layout with Status Badge and Filename
        var hbox = new HBoxContainer
        {
            MouseFilter = MouseFilterEnum.Ignore
        };
        hbox.AddThemeConstantOverride("separation", 8);

        var badgeLabel = new Label
        {
            Text = file.StatusBadge,
            MouseFilter = MouseFilterEnum.Ignore
        };
        badgeLabel.AddThemeColorOverride("font_color", file.StatusColor);
        badgeLabel.AddThemeFontSizeOverride("font_size", 12);
        hbox.AddChild(badgeLabel);

        var nameLabel = new Label
        {
            Text = file.Path,
            SizeFlagsHorizontal = SizeFlags.ExpandFill,
            MouseFilter = MouseFilterEnum.Ignore
        };
        nameLabel.AddThemeColorOverride("font_color", SandboxThemeTokens.TextPrimary);
        nameLabel.AddThemeFontSizeOverride("font_size", 12);
        hbox.AddChild(nameLabel);

        var statusTextLabel = new Label
        {
            Text = file.StatusLabel,
            MouseFilter = MouseFilterEnum.Ignore
        };
        statusTextLabel.AddThemeColorOverride("font_color", file.StatusColor);
        statusTextLabel.AddThemeFontSizeOverride("font_size", 10);
        hbox.AddChild(statusTextLabel);

        btn.AddChild(hbox);

        btn.Pressed += () =>
        {
            _selectedFilePath = file.Path;
            UpdateView();
            EmitSignal(SignalName.FileSelected, file.Path);
        };

        return btn;
    }

    private void OnCreateFileButtonPressed()
    {
        // Simple inline prompt or signal
        var defaultName = $"file_{_currentFiles.Count + 1}.txt";
        var defaultContent = $"Content created at {DateTimeOffset.UtcNow:s}";
        EmitSignal(SignalName.CreateFileRequested, defaultName, defaultContent);
    }
}
