using GitDiwaa.Godot.Common;
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
        ConfigureRepoButton();
    }

    /// <summary>ปุ่มไปหน้า remote repository: ไอคอนก้อนเมฆ (สื่อว่าอยู่บนเซิร์ฟเวอร์) พร้อมข้อความ Remote Repo</summary>
    private void ConfigureRepoButton()
    {
        _repoButton.Text = "Remote Repo";
        _repoButton.Icon = GitHubIcons.Get(GhIcon.Cloud, SandboxThemeTokens.GoldTitle, 22);
        _repoButton.AddThemeConstantOverride("icon_max_width", 22);
        _repoButton.AddThemeConstantOverride("h_separation", 8);
        _repoButton.MouseDefaultCursorShape = CursorShape.PointingHand;
        SetRepoButtonEnabled(!_repoButton.Disabled);
    }

    private void BindNodes()
    {
        _brandLabel = GetNode<Label>("%BrandLabel");
        _modeLabel = GetNode<Label>("%ModeLabel");
        _repoButton = GetNode<Button>("%RepoButton");
    }

    public void SetRepoButtonEnabled(bool enabled)
    {
        _repoButton.Disabled = !enabled;
        _repoButton.TooltipText = enabled
            ? "เปิด Remote Repository (GitHub จำลอง): ดูไฟล์ branch และ pull request ที่ push ขึ้นไป"
            : "ใช้ได้เฉพาะโหมด Real Git";
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
