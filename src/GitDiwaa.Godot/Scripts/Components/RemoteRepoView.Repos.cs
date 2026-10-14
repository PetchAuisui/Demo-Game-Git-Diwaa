using GitDiwaa.Core;
using GitDiwaa.Godot.Common;
using Godot;

namespace GitDiwaa.Godot.Components;

public partial class RemoteRepoView
{
    private static readonly PackedScene RepoListPageScene = GD.Load<PackedScene>("res://Scenes/RepoListPage.tscn");

    /// <summary>หน้ารายการ repo ก่อนเข้า repo: โครงอยู่ใน Scenes/RepoListPage.tscn</summary>
    private void BuildRepos(IReadOnlyList<RemoteRepositoryInfo> repos)
    {
        var page = RepoListPageScene.Instantiate<RepoListPage>();
        _content.AddChild(page);
        page.Setup(_account!.Owner, repos, OpenRepo, () => Go(Page.NewRepo));
    }

    /// <summary>ฟอร์มสร้าง repository ใหม่ (ว่าง) เหมือนหน้า New repository ของ GitHub</summary>
    private void BuildNewRepo()
    {
        var owner = _account!.Owner;
        var panel = new PanelContainer { SizeFlagsHorizontal = SizeFlags.ShrinkCenter, CustomMinimumSize = new Vector2(S(640), 0) };
        panel.AddThemeStyleboxOverride("panel", GitHubTheme.Box(new Color(GitHubTheme.Canvas, 0.92f), GitHubTheme.Border, 12, 1, 28, 24));
        var form = new VBoxContainer();
        form.AddThemeConstantOverride("separation", S(16));
        form.AddChild(GitHubUi.Text("Create a new repository", GitHubTheme.Fg, 26, bold: true));
        form.AddChild(GitHubUi.Text("repository ใหม่จะว่างเปล่า — ตั้งค่าแล้ว push งานจาก terminal ขึ้นมาได้เลย", GitHubTheme.FgMuted, 15));

        var nameRow = new HBoxContainer();
        nameRow.AddThemeConstantOverride("separation", S(8));
        nameRow.AddChild(GitHubUi.Text(owner, GitHubTheme.Fg, 18, bold: true));
        nameRow.AddChild(GitHubUi.Text("/", GitHubTheme.FgMuted, 18));
        var name = new LineEdit
        {
            PlaceholderText = "repository-name",
            SizeFlagsHorizontal = SizeFlags.ExpandFill,
            MouseFilter = MouseFilterEnum.Pass
        };
        nameRow.AddChild(name);
        form.AddChild(GitHubUi.Text("Repository name", GitHubTheme.Fg, 15, bold: true));
        form.AddChild(nameRow);

        form.AddChild(GitHubUi.Text("Description (ไม่บังคับ)", GitHubTheme.Fg, 15, bold: true));
        var description = new LineEdit { SizeFlagsHorizontal = SizeFlags.ExpandFill, MouseFilter = MouseFilterEnum.Pass };
        form.AddChild(description);

        var error = GitHubUi.Text(string.Empty, GitHubTheme.Danger, 15, wrap: true);
        error.Visible = false;
        form.AddChild(error);

        var buttons = new HBoxContainer();
        buttons.AddThemeConstantOverride("separation", S(10));
        async void Create()
        {
            try
            {
                var repo = await _account.CreateRepositoryAsync(name.Text, description.Text);
                if (!IsAlive) return;
                _status = $"สร้าง repository {repo.Name} แล้ว";
                _statusIsError = false;
                OpenRepo(repo.Name);
            }
            catch (Exception ex)
            {
                // ข้อผิดพลาดอื่น (เช่นสร้างโฟลเดอร์ไม่ได้) ต้องไม่หลุดออกจาก async void จนเกมค้าง
                // กดสร้างซ้ำเร็วๆ: ครั้งแรกสำเร็จแล้วหน้าถูกสร้างใหม่ ช่อง error เดิมถูกลบไปแล้ว
                if (!IsAlive || !IsInstanceValid(error)) return;
                error.Text = ex.Message;
                error.Visible = true;
            }
        }

        name.TextSubmitted += _ => Create();
        buttons.AddChild(GitHubUi.Btn("Create repository", Create, GhButtonKind.Primary, GhIcon.Repo));
        buttons.AddChild(GitHubUi.Btn("ยกเลิก", () => Go(Page.Repos)));
        form.AddChild(buttons);

        panel.AddChild(form);
        _content.AddChild(panel);
        Callable.From(() => { if (IsInstanceValid(name)) name.GrabFocus(); }).CallDeferred();
    }
}
