using Godot;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// Reusable Top Bar Component for Git-Diwaa Sandbox UI.
/// Displays the game title and level badge.
/// </summary>
public partial class TopBarPanel : PanelContainer
{
    [Export]
    public string GameTitle { get; set; } = "GIT DIWAA";

    [Export]
    public string LevelText { get; set; } = "LVL  1";

    private Label _brandLabel = null!;
    private Label _levelLabel = null!;

    public override void _Ready()
    {
        BindNodes();
        _brandLabel.Text = GameTitle;
        _levelLabel.Text = LevelText;
    }

    private void BindNodes()
    {
        _brandLabel = GetNode<Label>("%BrandLabel");
        _levelLabel = GetNode<Label>("%LevelLabel");
    }

    public void SetLevelText(string levelText)
    {
        LevelText = levelText;
        if (_levelLabel != null)
        {
            _levelLabel.Text = levelText;
        }
    }
}
