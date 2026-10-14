using GitDiwaa.Core;
using GitDiwaa.Godot.Common;
using Godot;

namespace GitDiwaa.Godot.Components;

public partial class RemoteRepoView
{
    private const string RoomTexturePath = "res://assets/art/remote/throne-room.png";

    /// <summary>ภาพห้องบัลลังก์เป็นพื้นหลังหน้ารายการ repo (พิกเซลอาร์ต จึงขยายแบบ nearest) ซ่อนไว้ในหน้าอื่น</summary>
    private static TextureRect BuildRoomBackdrop()
    {
        var backdrop = new TextureRect
        {
            Texture = ResourceLoader.Exists(RoomTexturePath) ? GD.Load<Texture2D>(RoomTexturePath) : null,
            ExpandMode = TextureRect.ExpandModeEnum.IgnoreSize,
            StretchMode = TextureRect.StretchModeEnum.KeepAspectCovered,
            TextureFilter = CanvasItem.TextureFilterEnum.Nearest,
            MouseFilter = MouseFilterEnum.Ignore,
            Visible = false
        };
        backdrop.SetAnchorsAndOffsetsPreset(LayoutPreset.FullRect);

        var shade = new ColorRect { Color = new Color(0f, 0f, 0.03f, 0.35f), MouseFilter = MouseFilterEnum.Ignore };
        shade.SetAnchorsAndOffsetsPreset(LayoutPreset.FullRect);
        backdrop.AddChild(shade);
        return backdrop;
    }

    /// <summary>หน้ารายการ repo ก่อนเข้า repo: การ์ดโปรไฟล์ซ้าย, ช่องค้นหา + ปุ่ม New และรายการ repo ขวา</summary>
    private void BuildRepos(IReadOnlyList<RemoteRepositoryInfo> repos)
    {
        var owner = _account!.Owner;

        var tabs = new HBoxContainer();
        tabs.AddChild(GitHubUi.Tab("Repositories", true, () => { }, GhIcon.Repo, repos.Count));
        _content.AddChild(tabs);

        var columns = new HBoxContainer { SizeFlagsHorizontal = SizeFlags.ExpandFill };
        columns.AddThemeConstantOverride("separation", S(28));
        columns.AddChild(BuildProfileCard(owner));

        var right = new VBoxContainer { SizeFlagsHorizontal = SizeFlags.ExpandFill };
        right.AddThemeConstantOverride("separation", S(14));

        var list = new VBoxContainer { SizeFlagsVertical = SizeFlags.ExpandFill };
        var search = new LineEdit
        {
            PlaceholderText = "Find a repository…",
            ClearButtonEnabled = true,
            SizeFlagsHorizontal = SizeFlags.ExpandFill
        };
        search.TextChanged += text => FillRepoList(list, repos, text);

        var searchRow = new HBoxContainer();
        searchRow.AddThemeConstantOverride("separation", S(10));
        searchRow.AddChild(search);
        searchRow.AddChild(GitHubUi.Btn("New", () => Go(Page.NewRepo), GhButtonKind.Primary, GhIcon.Repo));
        right.AddChild(searchRow);

        var panel = new PanelContainer { SizeFlagsVertical = SizeFlags.ExpandFill };
        panel.AddThemeStyleboxOverride("panel", GitHubTheme.Box(new Color(GitHubTheme.Canvas, 0.88f), GitHubTheme.Border, 12, 1, 8, 8));
        panel.CustomMinimumSize = new Vector2(0, S(320));
        panel.AddChild(list);
        right.AddChild(panel);
        FillRepoList(list, repos, string.Empty);

        columns.AddChild(right);
        _content.AddChild(columns);
    }

    private static Control BuildProfileCard(string owner)
    {
        var card = new PanelContainer { SizeFlagsVertical = SizeFlags.ShrinkBegin, CustomMinimumSize = new Vector2(S(250), 0) };
        card.AddThemeStyleboxOverride("panel", GitHubTheme.Box(new Color("#3a1812"), new Color("#a8793a"), 12, 3, 24, 28));
        var body = new VBoxContainer { Alignment = BoxContainer.AlignmentMode.Center };
        body.AddThemeConstantOverride("separation", S(16));

        var avatar = GitHubUi.Avatar(owner, 120);
        avatar.SizeFlagsHorizontal = SizeFlags.ShrinkCenter;
        body.AddChild(avatar);

        var name = GitHubUi.Text(owner, GitHubTheme.Fg, 26, bold: true);
        name.HorizontalAlignment = HorizontalAlignment.Center;
        body.AddChild(name);
        card.AddChild(body);
        return card;
    }

    private void FillRepoList(VBoxContainer list, IReadOnlyList<RemoteRepositoryInfo> repos, string filter)
    {
        foreach (var child in list.GetChildren())
        {
            list.RemoveChild(child);
            child.QueueFree();
        }

        var shown = repos
            .Where(repo => filter.Length == 0 || repo.Name.Contains(filter, StringComparison.OrdinalIgnoreCase))
            .ToList();
        if (shown.Count == 0)
        {
            list.AddChild(GitHubUi.EmptyState(GhIcon.Repo, "ไม่พบ repository", repos.Count == 0 ? "กด New เพื่อสร้าง repository แรก" : "ลองค้นหาด้วยชื่ออื่น"));
            return;
        }

        for (var index = 0; index < shown.Count; index++)
        {
            var repo = shown[index];
            var row = new HBoxContainer();
            row.AddThemeConstantOverride("separation", S(10));
            var text = new VBoxContainer { SizeFlagsHorizontal = SizeFlags.ExpandFill, MouseFilter = MouseFilterEnum.Ignore };
            text.AddChild(GitHubUi.Text(repo.Name, GitHubTheme.Accent, 22, bold: true));
            var meta = repo.IsEmpty
                ? "ยังว่างอยู่ — push งานขึ้นมาก่อน"
                : $"{GitHubUi.Count(repo.BranchCount, "branch", "branches")} · {GitHubUi.Count(repo.CommitCount, "commit", "commits")}";
            text.AddChild(GitHubUi.Text(meta, GitHubTheme.FgMuted, 14));
            row.AddChild(text);
            row.AddChild(GitHubUi.Pill("Public", GitHubTheme.FgMuted, GitHubTheme.Border));
            list.AddChild(GitHubUi.ListRow(row, index == shown.Count - 1, () => OpenRepo(repo.Name)));
        }
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
