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
        var toolbar = new HBoxContainer();
        toolbar.AddThemeConstantOverride("separation", 10);
        toolbar.AddChild(BranchPicker(branches, name => { _branch = name; _path = ""; Go(Page.Code); }));
        toolbar.AddChild(Btn($"⑂ {Count(branches.Count, "Branch", "Branches")}", () => Go(Page.Branches), flat: true));
        toolbar.AddChild(Btn($"🕒 {Count(_repo!.CommitCount, "Commit", "Commits")}", () => Go(Page.Commits), flat: true));
        toolbar.AddChild(new Control { SizeFlagsHorizontal = SizeFlags.ExpandFill });
        toolbar.AddChild(Btn("<> Code ▾", () => { _cloneOpen = !_cloneOpen; Go(Page.Code); }, color: Green));
        _content.AddChild(toolbar);

        if (_cloneOpen) _content.AddChild(CloneBox());

        _content.AddChild(Breadcrumb());

        var commits = await _host.ListCommitsAsync(_branch, 1);
        if (commits.Count > 0)
        {
            var latest = commits[0];
            var bar = Card();
            var row = new HBoxContainer();
            row.AddThemeConstantOverride("separation", 14);
            row.AddChild(Lbl(latest.Author, SandboxThemeTokens.PrimaryText));
            var subject = Lbl(latest.Subject, SandboxThemeTokens.SubtitleText);
            subject.SizeFlagsHorizontal = SizeFlags.ExpandFill;
            subject.ClipText = true;
            row.AddChild(subject);
            row.AddChild(Lbl($"{latest.ShortId}  ·  {Ago(latest.AuthoredAt)}", SandboxThemeTokens.TextSecondary, 14));
            bar.AddChild(row);
            _content.AddChild(bar);
        }

        var table = Card();
        var grid = new GridContainer { Columns = 3 };
        grid.AddThemeConstantOverride("h_separation", 24);
        grid.AddThemeConstantOverride("v_separation", 4);
        if (_path.Length > 0)
        {
            grid.AddChild(Btn("📁 ..", () => { _path = ParentPath(_path); Go(Page.Code); }, flat: true));
            grid.AddChild(new Control());
            grid.AddChild(new Control());
        }

        foreach (var file in await _host.ListFilesAsync(_branch, _path))
        {
            var entry = file;
            var nameButton = Btn($"{(entry.IsDirectory ? "📁" : "📄")} {entry.Name}", () =>
            {
                if (entry.IsDirectory) { _path = entry.Path; Go(Page.Code); }
                else { _path = entry.Path; Go(Page.Blob); }
            }, flat: true);
            nameButton.CustomMinimumSize = new Vector2(240, 0);
            nameButton.Alignment = HorizontalAlignment.Left;
            grid.AddChild(nameButton);
            var message = Lbl(entry.LastCommit?.Subject ?? "", SandboxThemeTokens.SubtitleText, 15);
            message.SizeFlagsHorizontal = SizeFlags.ExpandFill;
            message.ClipText = true;
            grid.AddChild(message);
            grid.AddChild(Lbl(entry.LastCommit is null ? "" : Ago(entry.LastCommit.AuthoredAt), SandboxThemeTokens.TextSecondary, 14));
        }

        table.AddChild(grid);
        _content.AddChild(table);

        var readmePath = _path.Length == 0 ? "README.md" : $"{_path}/README.md";
        var readme = await _host.ReadFileAsync(_branch, readmePath);
        if (readme is not null)
        {
            var box = Card();
            var inner = new VBoxContainer();
            inner.AddChild(Lbl("≡ README.md", SandboxThemeTokens.GoldTitle, 14));
            inner.AddChild(new HSeparator());
            foreach (var line in readme.TrimEnd().Split('\n'))
            {
                if (line.StartsWith("# ")) inner.AddChild(Lbl(line[2..], SandboxThemeTokens.PrimaryText, 26));
                else if (line.StartsWith("## ")) inner.AddChild(Lbl(line[3..], SandboxThemeTokens.PrimaryText, 20));
                else inner.AddChild(Lbl(line, SandboxThemeTokens.TextSecondary, wrap: true));
            }

            box.AddChild(inner);
            _content.AddChild(box);
        }
    }

    /// <summary>repo ที่ยังไม่มีอะไรถูก push: หน้า Quick setup บอก URL และคำสั่งที่ใช้ได้ใน terminal ของเกม</summary>
    private void BuildEmptyRepo()
    {
        var repo = _repo!;
        var card = Card();
        var box = new VBoxContainer();
        box.AddThemeConstantOverride("separation", 8);
        box.AddChild(Lbl("Quick setup — repo นี้ยังว่างอยู่", SandboxThemeTokens.GoldTitle, 22));
        box.AddChild(Lbl("push งานจากคลังในเครื่องขึ้นมา แล้วไฟล์ branch และ commit จะแสดงที่หน้านี้",
            SandboxThemeTokens.TextSecondary, wrap: true));

        var urlRow = new HBoxContainer();
        urlRow.AddThemeConstantOverride("separation", 8);
        urlRow.AddChild(new LineEdit { Text = repo.CloneUrl, Editable = false, SizeFlagsHorizontal = SizeFlags.ExpandFill });
        urlRow.AddChild(Btn("Copy URL", () => DisplayServer.ClipboardSet(repo.CloneUrl)));
        box.AddChild(urlRow);

        box.AddChild(new HSeparator());
        box.AddChild(Lbl("ครั้งแรก: ตั้งชื่อผู้ใช้ Git (ข้ามได้ถ้าตั้งแล้ว)", SandboxThemeTokens.PrimaryText));
        box.AddChild(CommandRow($"git config --global user.name \"{repo.Owner}\""));
        box.AddChild(CommandRow($"git config --global user.email \"{repo.Owner}@example.com\""));

        box.AddChild(new HSeparator());
        box.AddChild(Lbl("…สร้างโปรเจกต์ใหม่ แล้ว push ขึ้นมา (พิมพ์ใน terminal ของ Sandbox)", SandboxThemeTokens.PrimaryText));
        foreach (var command in new[]
                 {
                     $"write README.md # {repo.Name}",
                     "git init",
                     "git add README.md",
                     "git commit -m \"first commit\"",
                     $"git remote add origin {repo.CloneUrl}",
                     "git push -u origin main"
                 })
            box.AddChild(CommandRow(command));

        box.AddChild(new HSeparator());
        box.AddChild(Lbl("…หรือ clone repo ว่างนี้มาทำงานต่อ", SandboxThemeTokens.PrimaryText));
        box.AddChild(CommandRow($"git clone {repo.CloneUrl}"));

        card.AddChild(box);
        _content.AddChild(card);
    }

    private static HBoxContainer CommandRow(string command)
    {
        var row = new HBoxContainer();
        row.AddThemeConstantOverride("separation", 10);
        var prompt = Lbl("$", SandboxThemeTokens.TextSecondary, 15);
        prompt.AddThemeFontOverride("font", Mono());
        row.AddChild(prompt);
        var text = Lbl(command, SandboxThemeTokens.PromptGreen, 15);
        text.AddThemeFontOverride("font", Mono());
        text.SizeFlagsHorizontal = SizeFlags.ExpandFill;
        row.AddChild(text);
        row.AddChild(Btn("Copy", () => DisplayServer.ClipboardSet(command)));
        return row;
    }

    private async Task BuildBlobAsync()
    {
        _content.AddChild(Breadcrumb());
        var text = await _host!.ReadFileAsync(_branch, _path);
        var editor = new TextEdit
        {
            Text = text ?? "(ไม่พบไฟล์หรืออ่านไม่ได้)",
            Editable = false,
            CustomMinimumSize = new Vector2(0, 420),
            SizeFlagsHorizontal = SizeFlags.ExpandFill
        };
        editor.AddThemeFontOverride("font", Mono());
        _content.AddChild(editor);
        var backToFiles = Btn("← กลับไปรายการไฟล์", () => { _path = ParentPath(_path); Go(Page.Code); });
        backToFiles.SizeFlagsHorizontal = SizeFlags.ShrinkBegin;
        _content.AddChild(backToFiles);
    }

    private VBoxContainer CloneBox()
    {
        var box = new VBoxContainer();
        var card = Card();
        var inner = new VBoxContainer();
        inner.AddThemeConstantOverride("separation", 6);
        inner.AddChild(Lbl("Clone (HTTPS) — ใช้ใน terminal ของเกม", SandboxThemeTokens.GoldTitle, 15));
        var row = new HBoxContainer();
        var url = new LineEdit { Text = _repo!.CloneUrl, Editable = false, SizeFlagsHorizontal = SizeFlags.ExpandFill };
        row.AddChild(url);
        row.AddChild(Btn("Copy", () => DisplayServer.ClipboardSet($"git clone {_repo.CloneUrl}")));
        inner.AddChild(row);
        inner.AddChild(Lbl($"git clone {_repo.CloneUrl}", SandboxThemeTokens.PromptGreen, 14));
        card.AddChild(inner);
        box.AddChild(card);
        return box;
    }

    private HBoxContainer Breadcrumb()
    {
        var row = new HBoxContainer();
        row.AddChild(Btn(_repo!.Name, () => { _path = ""; Go(Page.Code); }, flat: true));
        var parts = _path.Split('/', StringSplitOptions.RemoveEmptyEntries);
        var built = "";
        foreach (var part in parts)
        {
            built = built.Length == 0 ? part : $"{built}/{part}";
            var target = built;
            row.AddChild(Lbl("/", SandboxThemeTokens.TextSecondary));
            row.AddChild(Btn(part, () =>
            {
                _path = target;
                Go(_page == Page.Blob && target == _path && parts[^1] == part ? Page.Blob : Page.Code);
            }, flat: true));
        }

        return row;
    }
}
