using Godot;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// Reusable Top Bar Component for Git-Diwaa Sandbox UI.
/// Matches the authentic Checkpoint-01 TopBar visual design.
/// </summary>
public partial class TopBarPanel : PanelContainer
{
    [Signal]
    public delegate void ResetRequestedEventHandler();

    [Export]
    public string GameTitle { get; set; } = "GIT DIWAA";

    [Export]
    public string LevelText { get; set; } = "LVL  1";

    private Label _brandLabel = null!;
    private Label _levelLabel = null!;
    private Label _timerLabel = null!;
    private Label _coinLabel = null!;

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
        _timerLabel = GetNode<Label>("%TimerLabel");
        _coinLabel = GetNode<Label>("%CoinLabel");
    }

    public void SetTimer(string timeString)
    {
        if (_timerLabel != null)
        {
            _timerLabel.Text = $"⏱ {timeString}";
        }
    }

    public void SetCoins(int coins)
    {
        if (_coinLabel != null)
        {
            _coinLabel.Text = $"◉  {coins} COIN";
        }
    }

    public void SetLevel(string levelText)
    {
        if (_levelLabel != null)
        {
            _levelLabel.Text = levelText;
        }
    }

    public void SetCurrentBranch(string branchName)
    {
        // Can optionally display branch name in title or label
    }
}
