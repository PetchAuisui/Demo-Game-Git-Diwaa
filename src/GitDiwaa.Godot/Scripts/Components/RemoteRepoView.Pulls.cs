using System.Text;
using GitDiwaa.Core;
using GitDiwaa.Godot.Common;
using Godot;

namespace GitDiwaa.Godot.Components;

public partial class RemoteRepoView
{
    // ───────────── Pull requests ─────────────

    private void BuildPulls(IReadOnlyList<PullRequestInfo> pulls)
    {
        var rows = new List<(Control Row, string Title)>();

        var toolbar = new HBoxContainer();
        toolbar.AddThemeConstantOverride("separation", 10);
        var search = new LineEdit
        {
            PlaceholderText = "Search pull requests",
            RightIcon = GitHubIcons.Get(GhIcon.Search, GitHubTheme.FgMuted, 16, 1f),
            ClearButtonEnabled = true,
            SizeFlagsHorizontal = SizeFlags.ExpandFill,
            MouseFilter = MouseFilterEnum.Pass
        };
        search.TextChanged += text =>
        {
            foreach (var (row, title) in rows)
                row.Visible = text.Length == 0 || title.Contains(text, StringComparison.OrdinalIgnoreCase);
        };
        toolbar.AddChild(search);
        toolbar.AddChild(GitHubUi.Btn("New pull request", () =>
        {
            _newPullSource = string.Empty;
            Go(Page.NewPull);
        }, GhButtonKind.Primary));
        _content.AddChild(toolbar);

        if (pulls.Count == 0)
        {
            _content.AddChild(GitHubUi.EmptyState(GhIcon.PullOpen, "Welcome to pull requests!",
                "Pull requests ใช้เสนอให้นำการเปลี่ยนแปลงจาก branch หนึ่งไปรวมกับอีก branch หนึ่ง " +
                "ลอง push branch ใหม่ขึ้นมา แล้วกด New pull request"));
            return;
        }

        var open = pulls.Where(p => p.State == PullRequestState.Open).ToList();
        var closed = pulls.Where(p => p.State != PullRequestState.Open).ToList();

        var filters = new HBoxContainer();
        filters.AddThemeConstantOverride("separation", 4);
        filters.AddChild(FilterButton($"{open.Count} Open", GhIcon.PullOpen, !_showClosed, () =>
        {
            _showClosed = false;
            Go(Page.Pulls);
        }));
        filters.AddChild(FilterButton($"{closed.Count} Closed", GhIcon.Check, _showClosed, () =>
        {
            _showClosed = true;
            Go(Page.Pulls);
        }));
        var (box, body) = GitHubUi.Box(filters);

        var shown = (_showClosed ? closed : open).OrderByDescending(p => p.Number).ToList();
        if (shown.Count == 0)
        {
            var empty = new MarginContainer();
            empty.AddThemeConstantOverride("margin_top", 28);
            empty.AddThemeConstantOverride("margin_bottom", 28);
            var message = GitHubUi.Text(_showClosed ? "ยังไม่มี pull request ที่ปิดแล้ว" : "ไม่มี pull request ที่เปิดอยู่",
                GitHubTheme.FgMuted, 16);
            message.HorizontalAlignment = HorizontalAlignment.Center;
            empty.AddChild(message);
            body.AddChild(empty);
        }

        for (var index = 0; index < shown.Count; index++)
        {
            var item = shown[index];
            var row = BuildPullRow(item);
            var listRow = GitHubUi.ListRow(row, index == shown.Count - 1, () =>
            {
                _pullNumber = item.Number;
                _pullTab = PullTab.Conversation;
                Go(Page.PullDetail);
            });
            body.AddChild(listRow);
            rows.Add((listRow, item.Title));
        }

        _content.AddChild(box);
    }

    private static Button FilterButton(string text, GhIcon icon, bool active, Action onPressed)
    {
        var button = GitHubUi.Btn(text, onPressed, GhButtonKind.Ghost, icon,
            iconColor: active ? GitHubTheme.Fg : GitHubTheme.FgMuted);
        if (active)
        {
            button.AddThemeColorOverride("font_color", GitHubTheme.Fg);
            button.AddThemeFontOverride("font", GitHubTheme.BoldFont);
        }

        return button;
    }

    private static Control BuildPullRow(PullRequestInfo pull)
    {
        var row = new HBoxContainer();
        row.AddThemeConstantOverride("separation", 12);

        var state = GitHubUi.StateIcon(pull.State, 18);
        state.SizeFlagsVertical = SizeFlags.ShrinkBegin;
        row.AddChild(state);

        var column = new VBoxContainer { SizeFlagsHorizontal = SizeFlags.ExpandFill };
        column.AddThemeConstantOverride("separation", 4);
        column.AddChild(GitHubUi.Text(pull.Title, GitHubTheme.Fg, 16, bold: true));

        var meta = new HBoxContainer();
        meta.AddThemeConstantOverride("separation", 8);
        var summary = pull.State switch
        {
            PullRequestState.Merged => $"#{pull.Number} by {pull.Author} was merged",
            PullRequestState.Closed => $"#{pull.Number} by {pull.Author} was closed",
            _ => $"#{pull.Number} opened {GitHubUi.TimeAgo(pull.CreatedAt)} by {pull.Author}"
        };
        meta.AddChild(GitHubUi.Text(summary, GitHubTheme.FgMuted, 13));
        meta.AddChild(GitHubUi.BranchPill(pull.SourceBranch));
        meta.AddChild(GitHubUi.Text("→", GitHubTheme.FgMuted, 13));
        meta.AddChild(GitHubUi.BranchPill(pull.TargetBranch));
        column.AddChild(meta);
        row.AddChild(column);

        if (pull.IsApproved && pull.State == PullRequestState.Open)
            row.AddChild(GitHubUi.IconText(GhIcon.Check, "Approved", GitHubTheme.Success, 13));
        return row;
    }

    private async Task BuildNewPullAsync()
    {
        var branches = await _host!.ListBranchesAsync();
        _content.AddChild(GitHubUi.Text("Open a pull request", GitHubTheme.Fg, 26, bold: true));
        _content.AddChild(GitHubUi.Text("เลือก branch ที่มีการเปลี่ยนแปลง (compare) เพื่อนำไปรวมกับ branch ปลายทาง (base)",
            GitHubTheme.FgMuted));

        if (branches.Count < 2)
        {
            _content.AddChild(GitHubUi.EmptyState(GhIcon.Branch, "ยังเปรียบเทียบไม่ได้",
                branches.Count == 0
                    ? "repo ยังว่าง — push branch ขึ้นมาก่อนจึงจะเปิด pull request ได้"
                    : "ต้องมีอย่างน้อย 2 branch — สร้างและ push branch ใหม่ก่อน เช่น git switch -c feature/xxx แล้ว git push -u origin feature/xxx"));
            var back = GitHubUi.Btn("Pull requests", () => Go(Page.Pulls), GhButtonKind.Default, GhIcon.ArrowLeft);
            back.SizeFlagsHorizontal = SizeFlags.ShrinkBegin;
            _content.AddChild(back);
            return;
        }

        var defaultBranch = branches.FirstOrDefault(b => b.IsDefault)?.Name ?? "main";
        var source = branches.Any(b => b.Name == _newPullSource)
            ? _newPullSource
            : branches.FirstOrDefault(b => !b.IsDefault)?.Name ?? defaultBranch;

        // แถบเลือก base ← compare
        var compare = GitHubUi.Card(16, 12);
        compare.AddThemeStyleboxOverride("panel", GitHubTheme.Box(GitHubTheme.CanvasSubtle, GitHubTheme.Border, 6, 1, 16, 12));
        var compareColumn = new VBoxContainer();
        compareColumn.AddThemeConstantOverride("separation", 10);
        var pickers = new HBoxContainer();
        pickers.AddThemeConstantOverride("separation", 10);
        pickers.AddChild(GitHubUi.Icon(GhIcon.PullOpen, GitHubTheme.FgMuted, 18));
        pickers.AddChild(GitHubUi.Text("base:", GitHubTheme.FgMuted));
        var basePicker = BranchPicker(branches, _ => { }, defaultBranch);
        pickers.AddChild(basePicker);
        pickers.AddChild(GitHubUi.Icon(GhIcon.ArrowLeft, GitHubTheme.FgMuted));
        pickers.AddChild(GitHubUi.Text("compare:", GitHubTheme.FgMuted));
        var comparePicker = BranchPicker(branches, _ => { }, source);
        pickers.AddChild(comparePicker);
        compareColumn.AddChild(pickers);

        var summary = new HBoxContainer();
        summary.AddThemeConstantOverride("separation", 6);
        compareColumn.AddChild(summary);
        void UpdateSummary()
        {
            foreach (var child in summary.GetChildren())
            {
                summary.RemoveChild(child);
                child.QueueFree();
            }

            var head = branches[comparePicker.Selected];
            var target = branches[basePicker.Selected];
            if (head.Name == target.Name)
                summary.AddChild(GitHubUi.IconText(GhIcon.Alert, "base และ compare ต้องเป็นคนละ branch", GitHubTheme.Attention, 14));
            else if (target.IsDefault)
                summary.AddChild(GitHubUi.IconText(GhIcon.Commit,
                    $"{head.Name} นำหน้า {target.Name} {GitHubUi.Count(head.Ahead, "commit", "commits")}"
                    + (head.Behind > 0 ? $" และตามหลัง {head.Behind}" : string.Empty), GitHubTheme.FgMuted, 14));
            else
                summary.AddChild(GitHubUi.IconText(GhIcon.Commit, $"เปรียบเทียบ {head.Name} กับ {target.Name}", GitHubTheme.FgMuted, 14));
        }

        comparePicker.ItemSelected += _ => UpdateSummary();
        basePicker.ItemSelected += _ => UpdateSummary();
        UpdateSummary();
        compare.AddChild(compareColumn);
        _content.AddChild(compare);

        // ฟอร์มหัวข้อ + รายละเอียด
        var form = new HBoxContainer();
        form.AddThemeConstantOverride("separation", 14);
        var avatar = GitHubUi.Avatar(_repo!.Owner, 40);
        avatar.SizeFlagsVertical = SizeFlags.ShrinkBegin;
        form.AddChild(avatar);

        var card = GitHubUi.Card(16, 16);
        card.SizeFlagsHorizontal = SizeFlags.ExpandFill;
        var fields = new VBoxContainer();
        fields.AddThemeConstantOverride("separation", 12);
        var title = new LineEdit { PlaceholderText = "Title", SizeFlagsHorizontal = SizeFlags.ExpandFill, MouseFilter = MouseFilterEnum.Pass };
        fields.AddChild(title);
        var body = new TextEdit
        {
            PlaceholderText = "Leave a comment",
            CustomMinimumSize = new Vector2(0, 150),
            WrapMode = TextEdit.LineWrappingMode.Boundary
        };
        fields.AddChild(body);

        var error = GitHubUi.Text(string.Empty, GitHubTheme.Danger, 14, wrap: true);
        error.Visible = false;
        fields.AddChild(error);
        var buttons = new HBoxContainer();
        buttons.AddThemeConstantOverride("separation", 10);
        buttons.AddChild(GitHubUi.Spacer());
        buttons.AddChild(GitHubUi.Btn("Cancel", () => Go(Page.Pulls)));
        buttons.AddChild(GitHubUi.Btn("Create pull request", async () =>
        {
            try
            {
                var pr = await _host.OpenPullRequestAsync(title.Text, body.Text, _repo!.Owner,
                    branches[comparePicker.Selected].Name, branches[basePicker.Selected].Name);
                _pullNumber = pr.Number;
                _pullTab = PullTab.Conversation;
                Go(Page.PullDetail, $"สร้าง pull request #{pr.Number} แล้ว");
            }
            catch (InvalidOperationException ex)
            {
                error.Text = ex.Message;
                error.Visible = true;
            }
        }, GhButtonKind.Primary));
        fields.AddChild(buttons);
        card.AddChild(fields);
        form.AddChild(card);
        _content.AddChild(form);
    }

    private async Task BuildPullDetailAsync()
    {
        var detail = await _host!.GetPullRequestAsync(_pullNumber);
        if (detail is null) { Go(Page.Pulls, "ไม่พบ pull request", true); return; }
        var pull = detail.Pull;

        var head = new HBoxContainer();
        head.AddThemeConstantOverride("separation", 12);
        head.AddChild(Btn("← Pull requests", () => Go(Page.Pulls)));
        var title = Lbl($"{pull.Title}  #{pull.Number}", GitHubTheme.Fg, 22);
        title.SizeFlagsHorizontal = SizeFlags.ExpandFill;
        head.AddChild(title);
        head.AddChild(Lbl($"{StateIcon(pull.State)} {pull.State}", pull.State == PullRequestState.Merged ? Purple : GitHubTheme.Success));
        _content.AddChild(head);
        var summary = pull.State switch
        {
            PullRequestState.Merged => $"{pull.Author} merged {detail.Commits.Count} commit(s) from {pull.SourceBranch} into {pull.TargetBranch}",
            PullRequestState.Closed => $"{pull.Author} wanted to merge {detail.Commits.Count} commit(s) from {pull.SourceBranch} into {pull.TargetBranch}",
            _ => $"{pull.Author} wants to merge {detail.Commits.Count} commit(s) from {pull.SourceBranch} into {pull.TargetBranch}"
        };
        _content.AddChild(Lbl(summary, GitHubTheme.FgMuted, 14));

        if (!string.IsNullOrWhiteSpace(pull.Body))
        {
            var description = Card();
            description.AddChild(Lbl(pull.Body, GitHubTheme.Fg, wrap: true));
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
        box.AddChild(Lbl($"Add your review (ในฐานะ {reviewer})", GitHubTheme.Fg, 15));
        box.AddChild(comment);
        var actions = new HBoxContainer();
        actions.AddThemeConstantOverride("separation", 10);
        void Review(ReviewVerdict verdict)
        {
            var result = _host!.ReviewPullRequest(pull.Number, reviewer, verdict, comment.Text);
            Go(Page.PullDetail, result.Message, !result.Success);
        }

        actions.AddChild(Btn("✓ Approve", () => Review(ReviewVerdict.Approved), color: Green));
        actions.AddChild(Btn("✗ Request changes", () => Review(ReviewVerdict.ChangesRequested)));
        actions.AddChild(Btn("💬 Comment", () => Review(ReviewVerdict.Commented)));
        box.AddChild(actions);
        box.AddChild(new HSeparator());

        if (detail.MergeBlockedReason is { } blocked)
            box.AddChild(Lbl(detail.HasConflicts ? $"⚠ {blocked}" : blocked,
                detail.HasConflicts ? GitHubTheme.Danger : GitHubTheme.Attention, wrap: true));
        else
            box.AddChild(Lbl("✓ This branch has no conflicts with the base branch", GitHubTheme.Success));

        var mergeRow = new HBoxContainer();
        mergeRow.AddThemeConstantOverride("separation", 10);
        var merge = Btn("Merge pull request", async () =>
        {
            var result = await _host!.MergePullRequestAsync(pull.Number);
            Go(Page.PullDetail, result.Message, !result.Success);
        }, color: Green);
        merge.Disabled = detail.MergeBlockedReason is not null;
        mergeRow.AddChild(merge);
        mergeRow.AddChild(Btn("Close pull request", () =>
        {
            var result = _host!.ClosePullRequest(pull.Number);
            Go(Page.PullDetail, result.Message, !result.Success);
        }));
        box.AddChild(mergeRow);
        card.AddChild(box);
        _content.AddChild(card);
    }

    private void AddSection(string heading, IEnumerable<string> lines)
    {
        var card = Card();
        var box = new VBoxContainer();
        box.AddChild(Lbl(heading, GitHubTheme.Fg, 16));
        box.AddChild(new HSeparator());
        foreach (var line in lines) box.AddChild(Lbl(line, GitHubTheme.Fg, 14, wrap: true));
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
        label.AddThemeFontOverride("normal_font", GitHubTheme.MonoFont);
        label.AddThemeFontSizeOverride("normal_font_size", 14);
        return label;
    }
}
