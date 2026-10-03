using Godot;
using GitDiwaa.Godot.Common;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// Reusable Top Bar Component for Git-Diwaa Sandbox UI.
/// Displays game logo, level badge, current branch, coins/timer, and action controls.
/// </summary>
public partial class TopBarPanel : PanelContainer
{
    [Signal]
    public delegate void ResetRequestedEventHandler();

    [Export]
    public string GameTitle { get; set; } = "GIT DIWAA";

    [Export]
    public string LevelText { get; set; } = "LVL 1";

    private Label _titleLabel = null!;
    private Label _levelLabel = null!;
    private Label _branchLabel = null!;
    private Label _timerLabel = null!;
    private Label _coinLabel = null!;
    private Button _resetButton = null!;

    public override void _Ready()
    {
        ApplyStyles();
        BindNodes();

        _titleLabel.Text = GameTitle;
        _levelLabel.Text = LevelText;
        _resetButton.Pressed += () => EmitSignal(SignalName.ResetRequested);
    }

    private void BindNodes()
    {
        _titleLabel = GetNode<Label>("%TitleLabel");
        _levelLabel = GetNode<Label>("%LevelLabel");
        _branchLabel = GetNode<Label>("%BranchLabel");
        _timerLabel = GetNode<Label>("%TimerLabel");
        _coinLabel = GetNode<Label>("%CoinLabel");
        _resetButton = GetNode<Button>("%ResetButton");
    }

    private void ApplyStyles()
    {
        var style = SandboxThemeTokens.CreatePanelStyle(
            bgColor: new Color(0.12f, 0.11f, 0.10f, 0.98f),
            borderColor: SandboxThemeTokens.BorderGold,
            borderWidth: 2,
            cornerRadius: 0,
            contentMargin: 8
        );
        style.BorderWidthLeft = 0;
        style.BorderWidthRight = 0;
        style.BorderWidthTop = 0;
        style.BorderWidthBottom = 2;
        AddThemeStyleboxOverride("panel", style);
    }

    public void SetCurrentBranch(string branchName)
    {
        if (_branchLabel != null)
        {
            _branchLabel.Text = $"branch: {branchName}";
        }
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
            _coinLabel.Text = $"🪙 {coins} COIN";
        }
    }
}
