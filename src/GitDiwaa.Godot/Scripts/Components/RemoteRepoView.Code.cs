using GitDiwaa.Core;
using GitDiwaa.Godot.Common;
using Godot;

namespace GitDiwaa.Godot.Components;

public partial class RemoteRepoView
{
    // ───────────── Code ─────────────

    private async Task BuildCodeAsync()
    {
        if (_repo!.IsEmpty)
        {
            BuildEmptyRepo();
            return;
        }

        var branches = await _host!.ListBranchesAsync();
        var latest = (await _host.ListCommitsAsync(_branch, 1)).FirstOrDefault();
        var files = await _host.ListFilesAsync(_branch, _path);

        var rows = new List<(Control Row, string Name)>();
        _content.AddChild(BuildCodeToolbar(branches, rows));
        if (_path.Length > 0) _content.AddChild(Breadcrumb());
        _content.AddChild(BuildFileTable(latest, files, rows));
        await AddReadmeAsync();
    }

    private Control BuildCodeToolbar(IReadOnlyList<RemoteBranchInfo> branches, List<(Control Row, string Name)> rows)
    {
        var toolbar = new HBoxContainer();
        toolbar.AddThemeConstantOverride("separation", S(10));
        toolbar.AddChild(BranchPicker(branches, name =>
        {
            _branch = name;
            _path = string.Empty;
            Go(Page.Code);
        }));
        toolbar.AddChild(GitHubUi.Btn(
            GitHubUi.Count(branches.Count, "Branch", "Branches"), () => Go(Page.Branches), GhButtonKind.Ghost, GhIcon.Branch));
        toolbar.AddChild(GitHubUi.Spacer());

        var search = new LineEdit
        {
            PlaceholderText = "Go to file",
            CustomMinimumSize = new Vector2(S(260), 0),
            RightIcon = GitHubIcons.Get(GhIcon.Search, GitHubTheme.FgMuted, S(16), 1f),
            ClearButtonEnabled = true,
            MouseFilter = MouseFilterEnum.Pass
        };
        search.TextChanged += text =>
        {
            foreach (var (row, name) in rows)
                row.Visible = text.Length == 0 || name.Contains(text, StringComparison.OrdinalIgnoreCase);
        };
        toolbar.AddChild(search);
        Button? codeButton = null;
        codeButton = GitHubUi.Btn("Code ▾", () => ShowCloneMenu(codeButton!), GhButtonKind.Primary, GhIcon.Code);
        toolbar.AddChild(codeButton);
        return toolbar;
    }

    /// <summary>ตารางไฟล์: แถวหัวเป็น commit ล่าสุดของ branch ส่วนแถวไฟล์คลิกได้ทั้งแถว</summary>
    private Control BuildFileTable(RemoteCommitInfo? latest, IReadOnlyList<RemoteFileEntry> files, List<(Control Row, string Name)> rows)
    {
        var header = new HBoxContainer();
        header.AddThemeConstantOverride("separation", S(12));
        if (latest is not null)
        {
            header.AddChild(GitHubUi.Avatar(latest.Author, 22));
            header.AddChild(GitHubUi.Text(latest.Author, GitHubTheme.Fg, 15, bold: true));
            var subject = GitHubUi.Text(latest.Subject, GitHubTheme.FgMuted);
            subject.SizeFlagsHorizontal = SizeFlags.ExpandFill;
            subject.ClipText = true;
            header.AddChild(subject);
            header.AddChild(GitHubUi.Text(latest.ShortId, GitHubTheme.FgMuted, 13, mono: true));
            header.AddChild(GitHubUi.Text("·", GitHubTheme.FgMuted));
            header.AddChild(GitHubUi.Text(GitHubUi.TimeAgo(latest.AuthoredAt), GitHubTheme.FgMuted, 14));
        }
        else
        {
            header.AddChild(GitHubUi.Spacer());
        }

        header.AddChild(GitHubUi.Btn(
            GitHubUi.Count(_repo!.CommitCount, "Commit", "Commits"), () => Go(Page.Commits), GhButtonKind.Ghost, GhIcon.History));
        var (box, body) = GitHubUi.Box(header);

        if (_path.Length > 0)
        {
            var up = new HBoxContainer();
            up.AddThemeConstantOverride("separation", S(12));
            up.AddChild(GitHubUi.Icon(GhIcon.Folder, GitHubTheme.Accent));
            up.AddChild(GitHubUi.Text("..", GitHubTheme.Fg));
            body.AddChild(GitHubUi.ListRow(up, files.Count == 0, () =>
            {
                _path = ParentPath(_path);
                Go(Page.Code);
            }));
        }

        for (var index = 0; index < files.Count; index++)
        {
            var entry = files[index];
            var row = new HBoxContainer();
            row.AddThemeConstantOverride("separation", S(12));
            row.AddChild(GitHubUi.Icon(entry.IsDirectory ? GhIcon.Folder : GhIcon.File,
                entry.IsDirectory ? GitHubTheme.Accent : GitHubTheme.FgMuted));
            var name = GitHubUi.Text(entry.Name, GitHubTheme.Fg);
            name.CustomMinimumSize = new Vector2(S(300), 0);
            row.AddChild(name);
            var message = GitHubUi.Text(entry.LastCommit?.Subject ?? string.Empty, GitHubTheme.FgMuted, 14);
            message.SizeFlagsHorizontal = SizeFlags.ExpandFill;
            message.ClipText = true;
            row.AddChild(message);
            row.AddChild(GitHubUi.Text(entry.LastCommit is null ? string.Empty : GitHubUi.TimeAgo(entry.LastCommit.AuthoredAt),
                GitHubTheme.FgMuted, 14));

            var listRow = GitHubUi.ListRow(row, index == files.Count - 1, () =>
            {
                _path = entry.Path;
                Go(entry.IsDirectory ? Page.Code : Page.Blob);
            });
            body.AddChild(listRow);
            rows.Add((listRow, entry.Name));
        }

        return box;
    }

    private async Task AddReadmeAsync()
    {
        var readmePath = _path.Length == 0 ? "README.md" : $"{_path}/README.md";
        var readme = await _host!.ReadFileAsync(_branch, readmePath);
        if (readme is null) return;

        var header = new HBoxContainer();
        header.AddThemeConstantOverride("separation", S(8));
        header.AddChild(GitHubUi.Icon(GhIcon.Book, GitHubTheme.FgMuted));
        header.AddChild(GitHubUi.Text("README", GitHubTheme.Fg, 14, bold: true));
        var (box, body) = GitHubUi.Box(header);

        var margin = new MarginContainer { MouseFilter = MouseFilterEnum.Pass };
        margin.AddThemeConstantOverride("margin_left", S(32));
        margin.AddThemeConstantOverride("margin_right", S(32));
        margin.AddThemeConstantOverride("margin_top", S(24));
        margin.AddThemeConstantOverride("margin_bottom", S(28));
        margin.AddChild(MarkdownView.Render(readme));
        body.AddChild(margin);
        _content.AddChild(box);
    }

    /// <summary>repo ที่ยังไม่มีอะไรถูก push: หน้า Quick setup แบบ GitHub บอก URL และคำสั่งที่ใช้ใน terminal ของเกม</summary>
    private void BuildEmptyRepo()
    {
        var repo = _repo!;
        var card = GitHubUi.Card(28, 22);
        var column = new VBoxContainer();
        column.AddThemeConstantOverride("separation", S(14));

        column.AddChild(GitHubUi.Text("Quick setup — repo นี้ยังว่างอยู่", GitHubTheme.Fg, 22, bold: true));
        column.AddChild(GitHubUi.Text("push งานจากคลังในเครื่องขึ้นมา แล้วไฟล์ branch และ commit จะแสดงที่หน้านี้",
            GitHubTheme.FgMuted, wrap: true));

        var urlRow = new HBoxContainer();
        urlRow.AddThemeConstantOverride("separation", S(8));
        urlRow.AddChild(GitHubUi.Pill("HTTPS", GitHubTheme.Fg, GitHubTheme.Border));
        urlRow.AddChild(new LineEdit { Text = repo.CloneUrl, Editable = false, SizeFlagsHorizontal = SizeFlags.ExpandFill });
        urlRow.AddChild(GitHubUi.Btn("Copy URL", () => DisplayServer.ClipboardSet(repo.CloneUrl), GhButtonKind.Default, GhIcon.Copy));
        column.AddChild(urlRow);
        column.AddChild(new HSeparator());

        column.AddChild(GitHubUi.Text("…สร้างโปรเจกต์ใหม่ แล้ว push ขึ้นมา", GitHubTheme.Fg, 18, bold: true));
        column.AddChild(GitHubUi.Text("ครั้งแรก: ตั้งชื่อผู้ใช้ Git (ข้ามได้ถ้าตั้งแล้ว)", GitHubTheme.FgMuted, 14));
        column.AddChild(GitHubUi.CodeBlock(
        [
            $"git config --global user.name \"{repo.Owner}\"",
            $"git config --global user.email \"{repo.Owner}@example.com\""
        ]));
        column.AddChild(GitHubUi.CodeBlock(
        [
            $"write README.md # {repo.Name}",
            "git init",
            "git add README.md",
            "git commit -m \"first commit\"",
            $"git remote add origin {repo.CloneUrl}",
            "git push -u origin main"
        ]));
        column.AddChild(new HSeparator());

        column.AddChild(GitHubUi.Text("…หรือ push คลังที่มีอยู่แล้ว", GitHubTheme.Fg, 18, bold: true));
        column.AddChild(GitHubUi.CodeBlock([$"git remote add origin {repo.CloneUrl}", "git push -u origin main"]));
        column.AddChild(new HSeparator());

        column.AddChild(GitHubUi.Text("…หรือ clone repo ว่างนี้มาทำงานต่อ", GitHubTheme.Fg, 18, bold: true));
        column.AddChild(GitHubUi.CodeBlock([$"git clone {repo.CloneUrl}"]));

        column.AddChild(GitHubUi.Info("พิมพ์คำสั่งใน terminal ของ Sandbox (กด Esc หรือ ← กลับ Sandbox) แล้วเปิดหน้านี้อีกครั้งเพื่อดูผล"));
        card.AddChild(column);
        _content.AddChild(card);
    }

    private async Task BuildBlobAsync()
    {
        _content.AddChild(Breadcrumb());
        var text = await _host!.ReadFileAsync(_branch, _path);
        var lines = (text ?? string.Empty).Replace("\r\n", "\n").TrimEnd('\n').Split('\n');

        var header = new HBoxContainer();
        header.AddThemeConstantOverride("separation", S(10));
        header.AddChild(GitHubUi.Icon(GhIcon.File, GitHubTheme.FgMuted));
        header.AddChild(GitHubUi.Text(System.IO.Path.GetFileName(_path), GitHubTheme.Fg, 15, bold: true));
        header.AddChild(GitHubUi.Text(GitHubUi.Count(lines.Length, "line", "lines"), GitHubTheme.FgMuted, 13));
        header.AddChild(GitHubUi.Spacer());
        if (text is not null)
            header.AddChild(GitHubUi.Btn("Copy", () => DisplayServer.ClipboardSet(text), GhButtonKind.Ghost, GhIcon.Copy));
        var (box, body) = GitHubUi.Box(header);

        var margin = new MarginContainer { MouseFilter = MouseFilterEnum.Pass };
        margin.AddThemeConstantOverride("margin_top", S(10));
        margin.AddThemeConstantOverride("margin_bottom", S(10));
        margin.AddThemeConstantOverride("margin_right", S(16));
        margin.AddChild(text is null
            ? GitHubUi.Text("ไม่พบไฟล์หรืออ่านไม่ได้", GitHubTheme.FgMuted)
            : GitHubUi.CodeLines(lines));
        body.AddChild(margin);
        _content.AddChild(box);
    }

    /// <summary>เมนู Clone ที่เปิดจากปุ่ม Code: ลอยใต้ปุ่มและปิดเองเมื่อคลิกข้างนอก เหมือน GitHub</summary>
    private void ShowCloneMenu(Button anchor)
    {
        var url = _repo!.CloneUrl;
        var popup = new PopupPanel();
        popup.AddThemeStyleboxOverride("panel", GitHubTheme.Box(GitHubTheme.CanvasSubtle, GitHubTheme.Border, 8, 1, 18, 14));

        var column = new VBoxContainer { CustomMinimumSize = new Vector2(S(540), 0) };
        column.AddThemeConstantOverride("separation", S(10));
        column.AddChild(GitHubUi.IconText(GhIcon.Code, "Clone", GitHubTheme.Fg, 15, bold: true));

        var urlRow = new HBoxContainer();
        urlRow.AddThemeConstantOverride("separation", S(8));
        urlRow.AddChild(GitHubUi.Pill("HTTPS", GitHubTheme.Fg, GitHubTheme.Border));
        urlRow.AddChild(new LineEdit { Text = url, Editable = false, SizeFlagsHorizontal = SizeFlags.ExpandFill });
        urlRow.AddChild(GitHubUi.Btn(string.Empty, () => DisplayServer.ClipboardSet(url), GhButtonKind.Default, GhIcon.Copy));
        column.AddChild(urlRow);

        column.AddChild(GitHubUi.Text("พิมพ์คำสั่งนี้ใน terminal ของ Sandbox", GitHubTheme.FgMuted, 13));
        column.AddChild(GitHubUi.CodeBlock([$"git clone {url}"]));
        popup.AddChild(column);

        popup.PopupHide += popup.QueueFree;
        AddChild(popup);
        var anchorRect = anchor.GetGlobalRect();
        popup.Popup(new Rect2I((int)anchorRect.End.X - S(580), (int)anchorRect.End.Y + 6, S(580), 0));
    }

    private HBoxContainer Breadcrumb()
    {
        var row = new HBoxContainer();
        row.AddThemeConstantOverride("separation", S(6));
        row.AddChild(GitHubUi.Btn(_repo!.Name, () =>
        {
            _path = string.Empty;
            Go(Page.Code);
        }, GhButtonKind.Link));

        var segments = _path.Split('/', StringSplitOptions.RemoveEmptyEntries);
        var built = string.Empty;
        for (var index = 0; index < segments.Length; index++)
        {
            built = built.Length == 0 ? segments[index] : $"{built}/{segments[index]}";
            var target = built;
            row.AddChild(GitHubUi.Text("/", GitHubTheme.FgMuted));
            if (index == segments.Length - 1)
                row.AddChild(GitHubUi.Text(segments[index], GitHubTheme.Fg, 15, bold: true));
            else
                row.AddChild(GitHubUi.Btn(segments[index], () =>
                {
                    _path = target;
                    Go(Page.Code);
                }, GhButtonKind.Link));
        }

        return row;
    }
}
