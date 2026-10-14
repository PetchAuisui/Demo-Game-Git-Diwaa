using GitDiwaa.Core;
using GitDiwaa.Godot.Common;
using Godot;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// หน้ารายการ repo ก่อนเข้า repo (Scenes/RepoListPage.tscn): การ์ดโปรไฟล์ซ้าย, ช่องค้นหา + ปุ่ม New และรายการ repo ขวา
/// โครงอยู่ใน scene โค้ดนี้ใส่ข้อมูล (ชื่อเจ้าของ จำนวน repo แถวรายการ) และกรองตามคำค้น
/// </summary>
public partial class RepoListPage : VBoxContainer
{
    private HBoxContainer _tabs = null!;
    private VBoxContainer _list = null!;

    public override void _Ready()
    {
        _tabs = GetNode<HBoxContainer>("%Tabs");
        _list = GetNode<VBoxContainer>("%List");
        GetNode<Button>("%NewButton").Icon = GitHubIcons.Get(GhIcon.Repo, Colors.White, GitHubTheme.S(16));
        GetNode<Label>("%OwnerName").AddThemeFontOverride("font", GitHubTheme.BoldFont);
    }

    /// <param name="onOpen">เรียกเมื่อกดแถว repo (ส่งชื่อ repo)</param>
    /// <param name="onNew">เรียกเมื่อกดปุ่ม New</param>
    public void Setup(string owner, IReadOnlyList<RemoteRepositoryInfo> repos, Action<string> onOpen, Action onNew)
    {
        _tabs.AddChild(GitHubUi.Tab("Repositories", true, () => { }, GhIcon.Repo, repos.Count));

        GetNode<Label>("%OwnerName").Text = owner;
        var slot = GetNode<CenterContainer>("%AvatarSlot");
        slot.AddChild(GitHubUi.Avatar(owner, 120));

        GetNode<Button>("%NewButton").Pressed += onNew;
        GetNode<LineEdit>("%SearchEdit").TextChanged += text => FillList(repos, text, onOpen);
        FillList(repos, string.Empty, onOpen);
    }

    private void FillList(IReadOnlyList<RemoteRepositoryInfo> repos, string filter, Action<string> onOpen)
    {
        foreach (var child in _list.GetChildren())
        {
            _list.RemoveChild(child);
            child.QueueFree();
        }

        var shown = repos
            .Where(repo => filter.Length == 0 || repo.Name.Contains(filter, StringComparison.OrdinalIgnoreCase))
            .ToList();
        if (shown.Count == 0)
        {
            _list.AddChild(GitHubUi.EmptyState(GhIcon.Repo, "ไม่พบ repository", repos.Count == 0 ? "กด New เพื่อสร้าง repository แรก" : "ลองค้นหาด้วยชื่ออื่น"));
            return;
        }

        for (var index = 0; index < shown.Count; index++)
        {
            var repo = shown[index];
            var row = new HBoxContainer();
            row.AddThemeConstantOverride("separation", GitHubTheme.S(10));
            var text = new VBoxContainer { SizeFlagsHorizontal = SizeFlags.ExpandFill, MouseFilter = MouseFilterEnum.Ignore };
            text.AddChild(GitHubUi.Text(repo.Name, GitHubTheme.Accent, 22, bold: true));
            var meta = repo.IsEmpty
                ? "ยังว่างอยู่ — push งานขึ้นมาก่อน"
                : $"{GitHubUi.Count(repo.BranchCount, "branch", "branches")} · {GitHubUi.Count(repo.CommitCount, "commit", "commits")}";
            text.AddChild(GitHubUi.Text(meta, GitHubTheme.FgMuted, 14));
            row.AddChild(text);
            row.AddChild(GitHubUi.Pill("Public", GitHubTheme.FgMuted, GitHubTheme.Border));
            _list.AddChild(GitHubUi.ListRow(row, index == shown.Count - 1, () => onOpen(repo.Name)));
        }
    }
}
