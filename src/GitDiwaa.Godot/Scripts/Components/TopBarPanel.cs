using Godot;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// Reusable Top Bar Component for Git-Diwaa Sandbox UI.
/// Cleaned up to show only available sandbox systems (brand and mode badge).
/// Dummy timer and coins removed as requested.
/// </summary>
public partial class TopBarPanel : PanelContainer
{
    [Export]
    public string GameTitle { get; set; } = "GIT DIWAA";

    [Export]
    public string ModeText { get; set; } = "SANDBOX";

    private Label _brandLabel = null!;
    private Label _modeLabel = null!;

    public override void _Ready()
    {
        BindNodes();
        _brandLabel.Text = GameTitle;
        _modeLabel.Text = ModeText;
    }

    private void BindNodes()
    {
        _brandLabel = GetNode<Label>("%BrandLabel");
        _modeLabel = GetNode<Label>("%ModeLabel");
    }

    public void SetModeText(string modeText)
    {
        ModeText = modeText;
        if (_modeLabel != null)
        {
            _modeLabel.Text = modeText;
        }
    }
}
