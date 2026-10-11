using System.Text;
using GitDiwaa.Core;
using GitDiwaa.Godot.Common;
using Godot;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// หน้า Remote Repository จำลอง GitHub: Code (เปิดโฟลเดอร์/ไฟล์ได้), Commits, Branches,
/// Pull requests (สร้าง/ดู diff/review/merge/ปิด) อ่านและสั่งงานผ่าน <see cref="IGitRemoteHost"/> เท่านั้น
/// </summary>
public partial class RemoteRepoView : Control
{
    [Signal] public delegate void BackRequestedEventHandler();

    private enum Page { Code, Blob, Commits, Branches, Pulls, NewPull, PullDetail }

    private static readonly Color Green = new(0.18f, 0.55f, 0.27f);
    private static readonly Color Purple = new(0.64f, 0.45f, 0.95f);

    private IGitRemoteHost? _host;
    private RemoteRepositoryInfo? _repo;
    private Page _page = Page.Code;
    private string _branch = "main";
    private string _path = "";
    private int _pullNumber;
    private bool _showClosed;
    private string _newPullSource = "";
    private string _status = "";
    private bool _statusIsError;
    private bool _cloneOpen;

    private Label _titleLabel = null!;
    private Button _codeTab = null!;
    private Button _pullTab = null!;
    private VBoxContainer _content = null!;

    public override void _Ready()
    {
        SetAnchorsAndOffsetsPreset(LayoutPreset.FullRect);
        MouseFilter = MouseFilterEnum.Stop;

        var backdrop = new ColorRect { Color = new Color(0.02f, 0.03f, 0.06f, 0.94f) };
        backdrop.SetAnchorsAndOffsetsPreset(LayoutPreset.FullRect);
        AddChild(backdrop);

        var margin = new MarginContainer();
        margin.SetAnchorsAndOffsetsPreset(LayoutPreset.FullRect);
        margin.AddThemeConstantOverride("margin_left", 60);
        margin.AddThemeConstantOverride("margin_right", 60);
        margin.AddThemeConstantOverride("margin_top", 84);
        margin.AddThemeConstantOverride("margin_bottom", 40);
        AddChild(margin);

        var card = new PanelContainer();
        card.AddThemeStyleboxOverride("panel", Panel(SandboxThemeTokens.CardBg, SandboxThemeTokens.CardBorder, 12, 22));
        margin.AddChild(card);

        var root = new VBoxContainer();
        root.AddThemeConstantOverride("separation", 10);
        card.AddChild(root);

        var header = new HBoxContainer();
        header.AddThemeConstantOverride("separation", 14);
        header.AddChild(Btn("← กลับ Sandbox", () => EmitSignal(SignalName.BackRequested)));
        _titleLabel = Lbl("", SandboxThemeTokens.GoldTitle, 24);
        _titleLabel.SizeFlagsHorizontal = SizeFlags.ExpandFill;
        header.AddChild(_titleLabel);
        header.AddChild(Lbl("Public", SandboxThemeTokens.TextSecondary, 14));
        root.AddChild(header);

        var tabs = new HBoxContainer();
        _codeTab = Btn("</> Code", () => Go(Page.Code), toggle: true);
        _pullTab = Btn("⑂ Pull requests", () => Go(Page.Pulls), toggle: true);
        tabs.AddChild(_codeTab);
        tabs.AddChild(_pullTab);
        root.AddChild(tabs);
        root.AddChild(new HSeparator());

        var scroll = new ScrollContainer
        {
            SizeFlagsVertical = SizeFlags.ExpandFill,
            HorizontalScrollMode = ScrollContainer.ScrollMode.Disabled
        };
        _content = new VBoxContainer { SizeFlagsHorizontal = SizeFlags.ExpandFill };
        _content.AddThemeConstantOverride("separation", 10);
        scroll.AddChild(_content);
        root.AddChild(scroll);
    }

    public void Open(IGitRemoteHost host)
    {
        _host = host;
        Go(Page.Code);
    }

    private async void Go(Page page, string? message = null, bool error = false)
    {
        if (page != Page.Code && page != Page.Blob) _cloneOpen = false;
        _page = page;
        if (message is not null) { _status = message; _statusIsError = error; }
        await RefreshAsync();
    }

    private async Task RefreshAsync()
    {
        if (_host is null) return;
        foreach (var child in _content.GetChildren())
        {
            _content.RemoveChild(child);
            child.QueueFree();
        }

        try
        {
            _repo = await _host.GetRepositoryAsync();
            _titleLabel.Text = $"{_repo.Owner} / {_repo.Name}";
            var pulls = _host.ListPullRequests();
            _codeTab.ButtonPressed = _page is Page.Code or Page.Blob or Page.Commits or Page.Branches;
            _pullTab.ButtonPressed = !_codeTab.ButtonPressed;
            _pullTab.Text = $"⑂ Pull requests ({pulls.Count(p => p.State == PullRequestState.Open)})";
            if (!(await _host.ListBranchesAsync()).Any(b => b.Name == _branch)) _branch = _repo.DefaultBranch;

            if (_status.Length > 0)
            {
                _content.AddChild(Lbl(_status, _statusIsError ? SandboxThemeTokens.ErrorText : SandboxThemeTokens.PromptGreen, wrap: true));
                _status = "";
            }

            switch (_page)
            {
                case Page.Code: await BuildCodeAsync(); break;
                case Page.Blob: await BuildBlobAsync(); break;
                case Page.Commits: await BuildCommitsAsync(); break;
                case Page.Branches: await BuildBranchesAsync(); break;
                case Page.Pulls: BuildPulls(pulls); break;
                case Page.NewPull: await BuildNewPullAsync(); break;
                case Page.PullDetail: await BuildPullDetailAsync(); break;
            }
        }
        catch (Exception ex)
        {
            _content.AddChild(Lbl($"โหลดข้อมูล repository ไม่สำเร็จ: {ex.Message}", SandboxThemeTokens.ErrorText));
        }
    }

    // ───────────── Code ─────────────

    private async Task BuildCodeAsync()
    {
        var branches = await _host!.ListBranchesAsync();
        var toolbar = new HBoxContainer();
        toolbar.AddThemeConstantOverride("separation", 10);
        toolbar.AddChild(BranchPicker(branches, name => { _branch = name; _path = ""; Go(Page.Code); }));
        toolbar.AddChild(Btn($"⑂ {branches.Count} Branches", () => Go(Page.Branches), flat: true));
        toolbar.AddChild(Btn($"🕒 {_repo!.CommitCount} Commits", () => Go(Page.Commits), flat: true));
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
        _content.AddChild(Btn("← กลับไปรายการไฟล์", () => { _path = ParentPath(_path); Go(Page.Code); }));
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

    // ───────────── Commits / Branches ─────────────

    private async Task BuildCommitsAsync()
    {
        var branches = await _host!.ListBranchesAsync();
        var row = new HBoxContainer();
        row.AddThemeConstantOverride("separation", 10);
        row.AddChild(Btn("← Code", () => Go(Page.Code)));
        row.AddChild(Lbl("Commits", SandboxThemeTokens.GoldTitle, 20));
        row.AddChild(BranchPicker(branches, name => { _branch = name; Go(Page.Commits); }));
        _content.AddChild(row);

        var card = Card();
        var list = new VBoxContainer();
        list.AddThemeConstantOverride("separation", 8);
        foreach (var commit in await _host.ListCommitsAsync(_branch, 100))
        {
            var line = new HBoxContainer();
            line.AddThemeConstantOverride("separation", 14);
            var subject = Lbl(commit.Subject, SandboxThemeTokens.PrimaryText);
            subject.SizeFlagsHorizontal = SizeFlags.ExpandFill;
            subject.ClipText = true;
            line.AddChild(subject);
            line.AddChild(Lbl(commit.Author, SandboxThemeTokens.SubtitleText, 14));
            line.AddChild(Lbl(commit.ShortId, SandboxThemeTokens.PromptGreen, 14));
            line.AddChild(Lbl(Ago(commit.AuthoredAt), SandboxThemeTokens.TextSecondary, 14));
            list.AddChild(line);
        }

        card.AddChild(list);
        _content.AddChild(card);
    }

    private async Task BuildBranchesAsync()
    {
        var row = new HBoxContainer();
        row.AddThemeConstantOverride("separation", 10);
        row.AddChild(Btn("← Code", () => Go(Page.Code)));
        row.AddChild(Lbl("Branches", SandboxThemeTokens.GoldTitle, 20));
        _content.AddChild(row);

        var card = Card();
        var list = new VBoxContainer();
        list.AddThemeConstantOverride("separation", 8);
        foreach (var branch in await _host!.ListBranchesAsync())
        {
            var item = branch;
            var line = new HBoxContainer();
            line.AddThemeConstantOverride("separation", 14);
            var name = Btn(item.Name + (item.IsDefault ? "  [default]" : ""), () => { _branch = item.Name; _path = ""; Go(Page.Code); }, flat: true);
            name.CustomMinimumSize = new Vector2(280, 0);
            name.Alignment = HorizontalAlignment.Left;
            line.AddChild(name);
            var info = Lbl($"{item.LastCommitSubject} · {Ago(item.LastCommitAt)}", SandboxThemeTokens.TextSecondary, 14);
            info.SizeFlagsHorizontal = SizeFlags.ExpandFill;
            info.ClipText = true;
            line.AddChild(info);
            if (!item.IsDefault)
            {
                line.AddChild(Lbl($"↑{item.Ahead}  ↓{item.Behind}", SandboxThemeTokens.StateModified, 14));
                line.AddChild(Btn("New pull request", () => { _newPullSource = item.Name; Go(Page.NewPull); }));
                line.AddChild(Btn("🗑", async () =>
                {
                    var ok = await _host.DeleteBranchAsync(item.Name);
                    Go(Page.Branches, ok ? $"ลบ branch {item.Name} แล้ว"
                        : $"ลบ {item.Name} ไม่ได้ (มี PR ที่ยังเปิดอยู่)", !ok);
                }));
            }

            list.AddChild(line);
        }

        card.AddChild(list);
        _content.AddChild(card);
    }

    // ───────────── Pull requests ─────────────

    private void BuildPulls(IReadOnlyList<PullRequestInfo> pulls)
    {
        var open = pulls.Where(p => p.State == PullRequestState.Open).ToList();
        var closed = pulls.Where(p => p.State != PullRequestState.Open).ToList();
        var bar = new HBoxContainer();
        bar.AddThemeConstantOverride("separation", 10);
        bar.AddChild(Btn($"🟢 Open ({open.Count})", () => { _showClosed = false; Go(Page.Pulls); }, flat: true));
        bar.AddChild(Btn($"✓ Closed ({closed.Count})", () => { _showClosed = true; Go(Page.Pulls); }, flat: true));
        bar.AddChild(new Control { SizeFlagsHorizontal = SizeFlags.ExpandFill });
        bar.AddChild(Btn("New pull request", () => { _newPullSource = ""; Go(Page.NewPull); }, color: Green));
        _content.AddChild(bar);

        var shown = _showClosed ? closed : open;
        var card = Card();
        var list = new VBoxContainer();
        list.AddThemeConstantOverride("separation", 8);
        if (shown.Count == 0)
            list.AddChild(Lbl(_showClosed ? "ยังไม่มี pull request ที่ปิดแล้ว" : "ไม่มี pull request ที่เปิดอยู่ — กด New pull request เพื่อสร้าง",
                SandboxThemeTokens.TextSecondary));
        foreach (var pr in shown.OrderByDescending(p => p.Number))
        {
            var item = pr;
            var line = new HBoxContainer();
            line.AddThemeConstantOverride("separation", 12);
            line.AddChild(Lbl(StateIcon(item.State), SandboxThemeTokens.PrimaryText));
            var col = new VBoxContainer { SizeFlagsHorizontal = SizeFlags.ExpandFill };
            var title = Btn(item.Title, () => { _pullNumber = item.Number; Go(Page.PullDetail); }, flat: true);
            title.Alignment = HorizontalAlignment.Left;
            col.AddChild(title);
            col.AddChild(Lbl($"#{item.Number} เปิดโดย {item.Author} · {item.SourceBranch} → {item.TargetBranch} · {Ago(item.CreatedAt)}",
                SandboxThemeTokens.TextSecondary, 13));
            line.AddChild(col);
            if (item.IsApproved) line.AddChild(Lbl("✓ Approved", SandboxThemeTokens.PromptGreen, 14));
            list.AddChild(line);
        }

        card.AddChild(list);
        _content.AddChild(card);
    }

    private async Task BuildNewPullAsync()
    {
        var branches = await _host!.ListBranchesAsync();
        var defaultBranch = branches.FirstOrDefault(b => b.IsDefault)?.Name ?? "main";
        var source = branches.Any(b => b.Name == _newPullSource)
            ? _newPullSource
            : branches.FirstOrDefault(b => !b.IsDefault)?.Name ?? defaultBranch;

        _content.AddChild(Lbl("Open a pull request", SandboxThemeTokens.GoldTitle, 22));
        var card = Card();
        var form = new VBoxContainer();
        form.AddThemeConstantOverride("separation", 8);

        var baseRow = new HBoxContainer();
        baseRow.AddChild(Lbl("base: ", SandboxThemeTokens.TextSecondary));
        var basePicker = BranchPicker(branches, _ => { }, defaultBranch);
        baseRow.AddChild(basePicker);
        baseRow.AddChild(Lbl("   ←   compare: ", SandboxThemeTokens.TextSecondary));
        var comparePicker = BranchPicker(branches, _ => { }, source);
        baseRow.AddChild(comparePicker);
        form.AddChild(baseRow);

        var summary = Lbl("", SandboxThemeTokens.StateModified, 14);
        form.AddChild(summary);
        void UpdateSummary()
        {
            var compare = branches[comparePicker.Selected];
            var target = branches[basePicker.Selected];
            summary.Text = compare.Name == target.Name
                ? "base และ compare ต้องเป็นคนละ branch"
                : $"{compare.Name} นำหน้า {defaultBranch} {compare.Ahead} commit (ตามหลัง {compare.Behind})";
        }

        comparePicker.ItemSelected += _ => UpdateSummary();
        basePicker.ItemSelected += _ => UpdateSummary();
        UpdateSummary();

        var title = new LineEdit { PlaceholderText = "Title", SizeFlagsHorizontal = SizeFlags.ExpandFill };
        var body = new TextEdit { PlaceholderText = "Leave a comment", CustomMinimumSize = new Vector2(0, 120) };
        form.AddChild(title);
        form.AddChild(body);

        var error = Lbl("", SandboxThemeTokens.ErrorText, 14);
        form.AddChild(error);
        var buttons = new HBoxContainer();
        buttons.AddThemeConstantOverride("separation", 10);
        buttons.AddChild(Btn("Create pull request", async () =>
        {
            try
            {
                var pr = await _host.OpenPullRequestAsync(title.Text, body.Text, "คุณ",
                    branches[comparePicker.Selected].Name, branches[basePicker.Selected].Name);
                _pullNumber = pr.Number;
                Go(Page.PullDetail, $"สร้าง pull request #{pr.Number} แล้ว");
            }
            catch (InvalidOperationException ex)
            {
                error.Text = ex.Message;
            }
        }, color: Green));
        buttons.AddChild(Btn("ยกเลิก", () => Go(Page.Pulls)));
        form.AddChild(buttons);
        card.AddChild(form);
        _content.AddChild(card);
    }

    private async Task BuildPullDetailAsync()
    {
        var detail = await _host!.GetPullRequestAsync(_pullNumber);
        if (detail is null) { Go(Page.Pulls, "ไม่พบ pull request", true); return; }
        var pull = detail.Pull;

        var head = new HBoxContainer();
        head.AddThemeConstantOverride("separation", 12);
        head.AddChild(Btn("← Pull requests", () => Go(Page.Pulls)));
        var title = Lbl($"{pull.Title}  #{pull.Number}", SandboxThemeTokens.PrimaryText, 22);
        title.SizeFlagsHorizontal = SizeFlags.ExpandFill;
        head.AddChild(title);
        head.AddChild(Lbl($"{StateIcon(pull.State)} {pull.State}", pull.State == PullRequestState.Merged ? Purple : SandboxThemeTokens.PromptGreen));
        _content.AddChild(head);
        _content.AddChild(Lbl(
            $"{pull.Author} wants to merge {detail.Commits.Count} commit(s) from {pull.SourceBranch} into {pull.TargetBranch}",
            SandboxThemeTokens.TextSecondary, 14));

        if (!string.IsNullOrWhiteSpace(pull.Body))
        {
            var description = Card();
            description.AddChild(Lbl(pull.Body, SandboxThemeTokens.PrimaryText, wrap: true));
            _content.AddChild(description);
        }

        if (detail.Commits.Count > 0) AddSection("Commits", detail.Commits.Select(c => $"{c.ShortId}  {c.Subject}  — {c.Author}"));
        if (detail.Files.Count > 0)
            AddSection($"Files changed ({detail.Files.Count})",
                detail.Files.Select(f => $"{f.Status}  {f.Path}   +{f.Additions} −{f.Deletions}"));
        if (detail.Diff.Length > 0) _content.AddChild(DiffView(detail.Diff));
        if (detail.Reviews.Count > 0)
            AddSection("Reviews", detail.Reviews.Select(r =>
                $"{VerdictText(r.Verdict)}  {r.Reviewer}{(r.Body.Length > 0 ? $": {r.Body}" : "")}"));

        if (pull.State == PullRequestState.Open) BuildMergeBox(detail);
        else if (pull.State == PullRequestState.Merged)
        {
            var merged = Card();
            var row = new HBoxContainer();
            row.AddThemeConstantOverride("separation", 12);
            row.AddChild(Lbl($"🟣 Pull request merged into {pull.TargetBranch}", Purple));
            row.AddChild(Btn("Delete branch", async () =>
            {
                var ok = await _host.DeleteBranchAsync(pull.SourceBranch);
                Go(Page.PullDetail, ok ? $"ลบ branch {pull.SourceBranch} แล้ว" : "ลบ branch ไม่ได้", !ok);
            }));
            merged.AddChild(row);
            _content.AddChild(merged);
        }
    }

    private void BuildMergeBox(PullRequestDetail detail)
    {
        var pull = detail.Pull;
        var reviewer = _repo!.Owner;
        var card = Card();
        var box = new VBoxContainer();
        box.AddThemeConstantOverride("separation", 8);

        var comment = new LineEdit { PlaceholderText = "ความเห็น review (ไม่บังคับ)" };
        box.AddChild(Lbl($"Add your review (ในฐานะ {reviewer})", SandboxThemeTokens.GoldTitle, 15));
        box.AddChild(comment);
        var actions = new HBoxContainer();
        actions.AddThemeConstantOverride("separation", 10);
        void Review(ReviewVerdict verdict)
        {
            if (verdict != ReviewVerdict.Commented && string.Equals(pull.Author, reviewer, StringComparison.OrdinalIgnoreCase))
            {
                Go(Page.PullDetail, "อนุมัติหรือขอแก้ PR ของตัวเองไม่ได้", true);
                return;
            }

            _host!.ReviewPullRequest(pull.Number, reviewer, verdict, comment.Text);
            Go(Page.PullDetail);
        }

        actions.AddChild(Btn("✓ Approve", () => Review(ReviewVerdict.Approved), color: Green));
        actions.AddChild(Btn("✗ Request changes", () => Review(ReviewVerdict.ChangesRequested)));
        actions.AddChild(Btn("💬 Comment", () => Review(ReviewVerdict.Commented)));
        box.AddChild(actions);
        box.AddChild(new HSeparator());

        if (detail.HasConflicts)
            box.AddChild(Lbl("⚠ This branch has conflicts that must be resolved", SandboxThemeTokens.ErrorText));
        else if (!pull.IsApproved)
            box.AddChild(Lbl("Review required — ต้องมีการอนุมัติก่อน merge", SandboxThemeTokens.StateModified));
        else
            box.AddChild(Lbl("✓ This branch has no conflicts with the base branch", SandboxThemeTokens.PromptGreen));

        var mergeRow = new HBoxContainer();
        mergeRow.AddThemeConstantOverride("separation", 10);
        var merge = Btn("Merge pull request", async () =>
        {
            var result = await _host!.MergePullRequestAsync(pull.Number);
            Go(Page.PullDetail, result.Message, !result.Success);
        }, color: Green);
        merge.Disabled = detail.HasConflicts || !pull.IsApproved;
        mergeRow.AddChild(merge);
        mergeRow.AddChild(Btn("Close pull request", () =>
        {
            _host!.ClosePullRequest(pull.Number);
            Go(Page.PullDetail);
        }));
        box.AddChild(mergeRow);
        card.AddChild(box);
        _content.AddChild(card);
    }

    private void AddSection(string heading, IEnumerable<string> lines)
    {
        var card = Card();
        var box = new VBoxContainer();
        box.AddChild(Lbl(heading, SandboxThemeTokens.GoldTitle, 16));
        box.AddChild(new HSeparator());
        foreach (var line in lines) box.AddChild(Lbl(line, SandboxThemeTokens.PrimaryText, 14, wrap: true));
        card.AddChild(box);
        _content.AddChild(card);
    }

    private static RichTextLabel DiffView(string diff)
    {
        var builder = new StringBuilder();
        foreach (var raw in diff.Split('\n'))
        {
            var line = raw.Replace("[", "[lb]");
            var color = raw.StartsWith("+++") || raw.StartsWith("---") ? "#9aa3b8"
                : raw.StartsWith('+') ? "#4ff29e"
                : raw.StartsWith('-') ? "#fa6678"
                : raw.StartsWith("@@") ? "#5bc0f0"
                : "#c8cfdf";
            builder.Append($"[color={color}]{line}[/color]\n");
        }

        var label = new RichTextLabel
        {
            BbcodeEnabled = true,
            FitContent = true,
            SelectionEnabled = true,
            Text = builder.ToString(),
            SizeFlagsHorizontal = SizeFlags.ExpandFill
        };
        label.AddThemeFontOverride("normal_font", Mono());
        label.AddThemeFontSizeOverride("normal_font_size", 14);
        return label;
    }

    // ───────────── UI helpers ─────────────

    private static string StateIcon(PullRequestState state) => state switch
    {
        PullRequestState.Open => "🟢",
        PullRequestState.Merged => "🟣",
        _ => "🔴"
    };

    private static string VerdictText(ReviewVerdict verdict) => verdict switch
    {
        ReviewVerdict.Approved => "✓ Approved",
        ReviewVerdict.ChangesRequested => "✗ Changes requested",
        _ => "💬 Commented"
    };

    private static string ParentPath(string path)
    {
        var index = path.LastIndexOf('/');
        return index < 0 ? "" : path[..index];
    }

    private OptionButton BranchPicker(IReadOnlyList<RemoteBranchInfo> branches, Action<string> onSelected, string? selected = null)
    {
        selected ??= _branch;
        var picker = new OptionButton();
        for (var index = 0; index < branches.Count; index++)
        {
            picker.AddItem($"⑂ {branches[index].Name}", index);
            if (branches[index].Name == selected) picker.Selected = index;
        }

        picker.ItemSelected += index => onSelected(branches[(int)index].Name);
        return picker;
    }

    private static Label Lbl(string text, Color color, int size = 16, bool wrap = false)
    {
        var label = new Label { Text = text };
        if (wrap)
        {
            label.AutowrapMode = TextServer.AutowrapMode.WordSmart;
            label.SizeFlagsHorizontal = SizeFlags.ExpandFill;
        }

        label.AddThemeColorOverride("font_color", color);
        label.AddThemeFontSizeOverride("font_size", size);
        return label;
    }

    private static Button Btn(string text, Action onPressed, bool flat = false, bool toggle = false, Color? color = null)
    {
        var button = new Button { Text = text, Flat = flat, ToggleMode = toggle, FocusMode = FocusModeEnum.None };
        if (color is { } fill)
        {
            var style = Panel(fill, fill.Lightened(0.25f), 6, 12);
            button.AddThemeStyleboxOverride("normal", style);
            button.AddThemeStyleboxOverride("hover", Panel(fill.Lightened(0.12f), fill.Lightened(0.35f), 6, 12));
            button.AddThemeStyleboxOverride("pressed", style);
            button.AddThemeColorOverride("font_color", Colors.White);
        }

        button.Pressed += onPressed;
        return button;
    }

    private static PanelContainer Card()
    {
        var card = new PanelContainer { SizeFlagsHorizontal = SizeFlags.ExpandFill };
        card.AddThemeStyleboxOverride("panel", Panel(SandboxThemeTokens.InputBg, SandboxThemeTokens.CardBorder, 8, 14));
        return card;
    }

    private static StyleBoxFlat Panel(Color fill, Color border, int radius, int margin) => new()
    {
        BgColor = fill,
        BorderColor = border,
        BorderWidthLeft = 2, BorderWidthRight = 2, BorderWidthTop = 2, BorderWidthBottom = 2,
        CornerRadiusTopLeft = radius, CornerRadiusTopRight = radius,
        CornerRadiusBottomLeft = radius, CornerRadiusBottomRight = radius,
        ContentMarginLeft = margin, ContentMarginRight = margin,
        ContentMarginTop = margin * 0.6f, ContentMarginBottom = margin * 0.6f
    };

    private static SystemFont Mono() => new() { FontNames = ["Menlo", "Consolas", "monospace"] };

    private static string Ago(DateTimeOffset when)
    {
        var span = DateTimeOffset.Now - when;
        if (span.TotalDays >= 1) return $"{(int)span.TotalDays} day{((int)span.TotalDays == 1 ? "" : "s")} ago";
        if (span.TotalHours >= 1) return $"{(int)span.TotalHours} hour{((int)span.TotalHours == 1 ? "" : "s")} ago";
        if (span.TotalMinutes >= 1) return $"{(int)span.TotalMinutes} min ago";
        return "just now";
    }
}
