using Godot;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// Reusable Top Bar Component for Git-Diwaa Sandbox UI.
/// Displays the game title and SANDBOX badge.
/// </summary>
public partial class TopBarPanel : PanelContainer
{
    [Export]
    public string GameTitle { get; set; } = "GIT DIWAA";

    [Export]
    public string ModeText { get; set; } = "SANDBOX";

    [Signal]
    public delegate void RepoPressedEventHandler();

    private Label _brandLabel = null!;
    private Button _repoButton = null!;
    private Label _modeLabel = null!;

    public override void _Ready()
    {
        BindNodes();
        _brandLabel.Text = GameTitle;
        _modeLabel.Text = ModeText;
        _repoButton.Pressed += () => EmitSignal(SignalName.RepoPressed);
    }

    private void BindNodes()
    {
        _brandLabel = GetNode<Label>("%BrandLabel");
        _modeLabel = GetNode<Label>("%ModeLabel");
        _repoButton = GetNode<Button>("%RepoButton");
    }

    public void SetRepoButtonEnabled(bool enabled) => _repoButton.Disabled = !enabled;

    public void SetModeText(string modeText)
    {
        ModeText = modeText;
        if (_modeLabel != null)
        {
            _modeLabel.Text = modeText;
        }
    }
}
