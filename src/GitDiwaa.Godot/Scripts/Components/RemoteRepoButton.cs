using GitDiwaa.Godot.Common;
using Godot;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// ปุ่มไปหน้า Remote Repository (GitHub จำลอง): ไอคอนก้อนเมฆ (สื่อว่าอยู่บนเซิร์ฟเวอร์) + ข้อความ Remote Repo
/// ใช้สไตล์เดียวกับปุ่มใน FilesPanel จึงวางในพาเนลไหนก็เข้ากัน สร้างด้วยโค้ดแล้วใส่ผ่าน GitGraphPanel.AddHeaderAction
/// </summary>
public partial class RemoteRepoButton : Button
{
    private const string AvailableHint = "เปิด Remote Repository (GitHub จำลอง): ดูไฟล์ branch และ pull request ที่ push ขึ้นไป";
    private const string UnavailableHint = "ใช้ได้เฉพาะโหมด Real Git";

    public override void _Ready()
    {
        Text = "Remote Repo";
        Icon = GitHubIcons.Get(GhIcon.Cloud, SandboxThemeTokens.GoldTitle, 20);
        FocusMode = FocusModeEnum.None;
        MouseDefaultCursorShape = CursorShape.PointingHand;
        CustomMinimumSize = new Vector2(0, 34);
        AddThemeFontSizeOverride("font_size", 17);
        AddThemeConstantOverride("icon_max_width", 20);
        AddThemeConstantOverride("h_separation", 8);

        var normal = Style(new Color(0.12f, 0.14f, 0.24f, 0.98f), new Color(0.42f, 0.48f, 0.72f));
        var hover = Style(new Color(0.19f, 0.23f, 0.38f), new Color(0.66f, 0.71f, 0.98f));
        AddThemeStyleboxOverride("normal", normal);
        AddThemeStyleboxOverride("hover", hover);
        AddThemeStyleboxOverride("pressed", hover);
        AddThemeStyleboxOverride("disabled", Style(new Color(0.06f, 0.07f, 0.12f, 0.7f), new Color(0.24f, 0.27f, 0.37f, 0.7f)));
        SetAvailable(!Disabled);
    }

    /// <summary>กดได้เมื่อมี remote ให้ดู (โหมด Real Git) ไม่เช่นนั้นเทาและบอกเหตุผลเมื่อชี้</summary>
    public void SetAvailable(bool available)
    {
        Disabled = !available;
        TooltipText = available ? AvailableHint : UnavailableHint;
    }

    private static StyleBoxFlat Style(Color fill, Color border)
    {
        var style = new StyleBoxFlat { BgColor = fill, BorderColor = border };
        style.SetBorderWidthAll(2);
        style.SetCornerRadiusAll(7);
        style.ContentMarginLeft = 12;
        style.ContentMarginRight = 12;
        style.ContentMarginTop = 5;
        style.ContentMarginBottom = 5;
        return style;
    }
}
