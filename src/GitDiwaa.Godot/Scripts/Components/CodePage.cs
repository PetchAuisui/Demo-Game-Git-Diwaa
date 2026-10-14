using GitDiwaa.Core;
using GitDiwaa.Godot.Common;
using Godot;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// หน้า Code ของ repo (Scenes/CodePage.tscn): แถบเครื่องมือ (branch ปุ่ม Branches ช่อง Go to file ปุ่ม Code) อยู่ใน scene
/// ส่วนที่ตามมา (breadcrumb ตารางไฟล์ README) สร้างตามข้อมูลแล้วต่อท้ายหน้านี้ด้วย <see cref="Control.AddChild"/>
/// </summary>
public partial class CodePage : VBoxContainer
{
    public override void _Ready()
    {
        var size = GitHubTheme.S(16);
        GetNode<Button>("%BranchesButton").Icon = GitHubIcons.Get(GhIcon.Branch, GitHubTheme.FgMuted, size);
        GetNode<LineEdit>("%SearchEdit").RightIcon = GitHubIcons.Get(GhIcon.Search, GitHubTheme.FgMuted, size, 1f);
        GetNode<Button>("%CodeButton").Icon = GitHubIcons.Get(GhIcon.Code, Colors.White, size);
    }

    /// <param name="onBranchSelected">เปลี่ยน branch จากตัวเลือก</param>
    /// <param name="onBranches">กดปุ่ม Branches</param>
    /// <param name="onSearch">พิมพ์ในช่อง Go to file (กรองแถวไฟล์)</param>
    /// <param name="onCode">กดปุ่ม Code (ส่งปุ่มไปเป็นจุดยึดของเมนู Clone)</param>
    public void Setup(IReadOnlyList<RemoteBranchInfo> branches, string selected, Action<string> onBranchSelected,
        Action onBranches, Action<string> onSearch, Action<Button> onCode)
    {
        GitHubUi.FillBranchPicker(GetNode<OptionButton>("%BranchPicker"), branches, onBranchSelected, selected);

        var branchesButton = GetNode<Button>("%BranchesButton");
        branchesButton.Text = GitHubUi.Count(branches.Count, "Branch", "Branches");
        branchesButton.Pressed += onBranches;

        GetNode<LineEdit>("%SearchEdit").TextChanged += text => onSearch(text);

        var codeButton = GetNode<Button>("%CodeButton");
        codeButton.Pressed += () => onCode(codeButton);
    }
}
