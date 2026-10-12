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
        toolbar.AddThemeConstantOverride("separation", S(10));
        var search = new LineEdit
        {
            PlaceholderText = "Search pull requests",
            RightIcon = GitHubIcons.Get(GhIcon.Search, GitHubTheme.FgMuted, S(16), 1f),
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
        filters.AddThemeConstantOverride("separation", S(4));
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
            empty.AddThemeConstantOverride("margin_top", S(28));
            empty.AddThemeConstantOverride("margin_bottom", S(28));
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
        row.AddThemeConstantOverride("separation", S(12));

        var state = GitHubUi.StateIcon(pull.State, 18);
        state.SizeFlagsVertical = SizeFlags.ShrinkBegin;
        row.AddChild(state);

        var column = new VBoxContainer { SizeFlagsHorizontal = SizeFlags.ExpandFill };
        column.AddThemeConstantOverride("separation", S(4));
        column.AddChild(GitHubUi.Text(pull.Title, GitHubTheme.Fg, 16, bold: true));

        var meta = new HFlowContainer();
        meta.AddThemeConstantOverride("h_separation", S(8));
        meta.AddThemeConstantOverride("v_separation", S(6));
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
        compare.AddThemeStyleboxOverride("panel", GitHubTheme.Box(GitHubTheme.Surface, GitHubTheme.Border, 8, 1, 16, 12));
        var compareColumn = new VBoxContainer();
        compareColumn.AddThemeConstantOverride("separation", S(10));
        var pickers = new HBoxContainer();
        pickers.AddThemeConstantOverride("separation", S(10));
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
        summary.AddThemeConstantOverride("separation", S(6));
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

        LineEdit? titleField = null;
        var titleTouched = false;
        void SuggestTitle()
        {
            if (titleField is not null && !titleTouched) titleField.Text = branches[comparePicker.Selected].LastCommitSubject;
        }

        comparePicker.ItemSelected += _ =>
        {
            UpdateSummary();
            SuggestTitle();
        };
        basePicker.ItemSelected += _ => UpdateSummary();
        UpdateSummary();
        compare.AddChild(compareColumn);
        _content.AddChild(compare);

        // ฟอร์มหัวข้อ + รายละเอียด
        var form = new HBoxContainer();
        form.AddThemeConstantOverride("separation", S(14));
        var avatar = GitHubUi.Avatar(_repo!.Owner, 40);
        avatar.SizeFlagsVertical = SizeFlags.ShrinkBegin;
        form.AddChild(avatar);

        var card = GitHubUi.Card(16, 16);
        card.SizeFlagsHorizontal = SizeFlags.ExpandFill;
        var fields = new VBoxContainer();
        fields.AddThemeConstantOverride("separation", S(12));
        var title = new LineEdit { PlaceholderText = "Title", SizeFlagsHorizontal = SizeFlags.ExpandFill, MouseFilter = MouseFilterEnum.Pass };
        titleField = title;
        title.TextChanged += _ => titleTouched = true; // เปลี่ยนด้วยโค้ด (SuggestTitle) ไม่ส่งสัญญาณนี้
        SuggestTitle();
        fields.AddChild(title);
        var body = new TextEdit
        {
            PlaceholderText = "Leave a comment",
            CustomMinimumSize = new Vector2(0, S(150)),
            WrapMode = TextEdit.LineWrappingMode.Boundary
        };
        fields.AddChild(body);

        var error = GitHubUi.Text(string.Empty, GitHubTheme.Danger, 14, wrap: true);
        error.Visible = false;
        fields.AddChild(error);
        var buttons = new HBoxContainer();
        buttons.AddThemeConstantOverride("separation", S(10));
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
        if (detail is null)
        {
            Go(Page.Pulls, "ไม่พบ pull request", true);
            return;
        }

        var pull = detail.Pull;
        _content.AddChild(GitHubUi.Heading(pull.Title, $"#{pull.Number}"));

        var commitText = GitHubUi.Count(detail.Commits.Count, "commit", "commits");
        var meta = new HFlowContainer();
        meta.AddThemeConstantOverride("h_separation", S(8));
        meta.AddThemeConstantOverride("v_separation", S(6));
        meta.AddChild(GitHubUi.StatePill(pull.State));
        meta.AddChild(GitHubUi.Text(pull.Author, GitHubTheme.Fg, 15, bold: true));
        meta.AddChild(GitHubUi.Text(pull.State switch
        {
            PullRequestState.Merged => $"merged {commitText} into",
            PullRequestState.Closed => $"wanted to merge {commitText} into",
            _ => $"wants to merge {commitText} into"
        }, GitHubTheme.FgMuted));
        meta.AddChild(GitHubUi.BranchPill(pull.TargetBranch));
        meta.AddChild(GitHubUi.Text("from", GitHubTheme.FgMuted));
        meta.AddChild(GitHubUi.BranchPill(pull.SourceBranch));
        _content.AddChild(meta);

        var tabs = new HBoxContainer();
        tabs.AddThemeConstantOverride("separation", S(4));
        tabs.AddChild(GitHubUi.Tab("Conversation", _pullTab == PullTab.Conversation, () => SwitchPullTab(PullTab.Conversation), GhIcon.Comment));
        tabs.AddChild(GitHubUi.Tab("Commits", _pullTab == PullTab.Commits, () => SwitchPullTab(PullTab.Commits), GhIcon.Commit, detail.Commits.Count));
        tabs.AddChild(GitHubUi.Tab("Files changed", _pullTab == PullTab.Files, () => SwitchPullTab(PullTab.Files), GhIcon.File, detail.Files.Count));
        var tabColumn = new VBoxContainer();
        tabColumn.AddThemeConstantOverride("separation", S(0));
        tabColumn.AddChild(tabs);
        tabColumn.AddChild(new HSeparator());
        _content.AddChild(tabColumn);

        switch (_pullTab)
        {
            case PullTab.Commits: BuildPullCommits(detail); break;
            case PullTab.Files: BuildPullFiles(detail); break;
            default: await BuildConversationAsync(detail); break;
        }
    }

    private void SwitchPullTab(PullTab tab)
    {
        _pullTab = tab;
        Go(Page.PullDetail);
    }

    // ───────────── Conversation ─────────────

    private async Task BuildConversationAsync(PullRequestDetail detail)
    {
        var pull = detail.Pull;
        _content.AddChild(TimelineComment(pull.Author, "opened this pull request", pull.CreatedAt, pull.Body));
        foreach (var review in detail.Reviews) _content.AddChild(ReviewEvent(review));

        switch (pull.State)
        {
            case PullRequestState.Open:
                BuildMergeBox(detail);
                BuildReviewBox(pull);
                break;
            case PullRequestState.Merged:
                await BuildMergedBoxAsync(pull);
                break;
            default:
                var (box, body) = GitHubUi.Box();
                body.AddChild(StatusRow(GhIcon.PullClosed, GitHubTheme.DangerEmphasis, "This pull request is closed",
                    "ปิดโดยไม่ได้ merge — เปิด pull request ใหม่ได้ถ้ายังต้องการรวม branch นี้", true));
                _content.AddChild(box);
                break;
        }
    }

    private static Control TimelineComment(string author, string action, DateTimeOffset when, string? body)
    {
        var row = new HBoxContainer();
        row.AddThemeConstantOverride("separation", S(14));
        var avatar = GitHubUi.Avatar(author, 40);
        avatar.SizeFlagsVertical = SizeFlags.ShrinkBegin;
        row.AddChild(avatar);

        var header = new HBoxContainer();
        header.AddThemeConstantOverride("separation", S(8));
        header.AddChild(GitHubUi.Text(author, GitHubTheme.Fg, 15, bold: true));
        header.AddChild(GitHubUi.Text($"{action} {GitHubUi.TimeAgo(when)}", GitHubTheme.FgMuted, 14));
        var (box, content) = GitHubUi.Box(header);

        var margin = new MarginContainer { MouseFilter = MouseFilterEnum.Pass };
        margin.AddThemeConstantOverride("margin_left", S(16));
        margin.AddThemeConstantOverride("margin_right", S(16));
        margin.AddThemeConstantOverride("margin_top", S(14));
        margin.AddThemeConstantOverride("margin_bottom", S(16));
        margin.AddChild(string.IsNullOrWhiteSpace(body)
            ? GitHubUi.Text("No description provided.", GitHubTheme.FgMuted)
            : MarkdownView.Render(body));
        content.AddChild(margin);
        row.AddChild(box);
        return row;
    }

    private static Control ReviewEvent(PullRequestReview review)
    {
        var (icon, fill, verb) = review.Verdict switch
        {
            ReviewVerdict.Approved => (GhIcon.Check, GitHubTheme.SuccessEmphasis, "approved these changes"),
            ReviewVerdict.ChangesRequested => (GhIcon.X, GitHubTheme.DangerEmphasis, "requested changes"),
            _ => (GhIcon.Comment, GitHubTheme.FgSubtle, "reviewed")
        };

        var row = new HBoxContainer();
        row.AddThemeConstantOverride("separation", S(14));
        var slot = new MarginContainer { MouseFilter = MouseFilterEnum.Ignore, SizeFlagsVertical = SizeFlags.ShrinkBegin };
        slot.AddThemeConstantOverride("margin_left", S(4));
        slot.AddThemeConstantOverride("margin_right", S(4));
        slot.AddChild(GitHubUi.Bubble(icon, fill, 32));
        row.AddChild(slot);

        var column = new VBoxContainer { SizeFlagsHorizontal = SizeFlags.ExpandFill };
        column.AddThemeConstantOverride("separation", S(8));
        var line = new HBoxContainer();
        line.AddThemeConstantOverride("separation", S(8));
        line.AddChild(GitHubUi.Text(review.Reviewer, GitHubTheme.Fg, 15, bold: true));
        line.AddChild(GitHubUi.Text($"{verb} {GitHubUi.TimeAgo(review.At)}", GitHubTheme.FgMuted, 14));
        column.AddChild(line);
        if (!string.IsNullOrWhiteSpace(review.Body))
        {
            var card = GitHubUi.Card(14, 10);
            card.AddChild(GitHubUi.Text(review.Body, GitHubTheme.Fg, 15, wrap: true));
            column.AddChild(card);
        }

        row.AddChild(column);
        return row;
    }

    /// <summary>แถวสถานะในกล่อง merge: วงกลมไอคอน หัวข้อ คำอธิบาย (และปุ่มด้านขวาถ้ามี)</summary>
    private static Control StatusRow(GhIcon icon, Color fill, string title, string? detail, bool last, Control? action = null)
    {
        var row = new HBoxContainer();
        row.AddThemeConstantOverride("separation", S(14));
        row.AddChild(GitHubUi.Bubble(icon, fill, 32));
        var text = new VBoxContainer { SizeFlagsHorizontal = SizeFlags.ExpandFill };
        text.AddThemeConstantOverride("separation", S(2));
        text.AddChild(GitHubUi.Text(title, GitHubTheme.Fg, 16, bold: true, wrap: true));
        if (detail is not null) text.AddChild(GitHubUi.Text(detail, GitHubTheme.FgMuted, 14, wrap: true));
        row.AddChild(text);
        if (action is not null) row.AddChild(action);
        return GitHubUi.ListRow(row, last);
    }

    private void BuildMergeBox(PullRequestDetail detail)
    {
        var pull = detail.Pull;
        var (box, body) = GitHubUi.Box();

        var decision = detail.Reviews.LastOrDefault(review => review.Verdict != ReviewVerdict.Commented);
        if (decision is { Verdict: ReviewVerdict.Approved })
            body.AddChild(StatusRow(GhIcon.Check, GitHubTheme.SuccessEmphasis, "Changes approved",
                $"{decision.Reviewer} approved these changes", false));
        else if (decision is { Verdict: ReviewVerdict.ChangesRequested })
            body.AddChild(StatusRow(GhIcon.X, GitHubTheme.DangerEmphasis, "Changes requested",
                $"{decision.Reviewer} requested changes", false));

        if (detail.HasConflicts)
            body.AddChild(StatusRow(GhIcon.Alert, GitHubTheme.DangerEmphasis, "This branch has conflicts that must be resolved",
                "แก้ conflict ใน terminal แล้ว push ขึ้นมาใหม่ จึงจะ merge ได้", false));
        else if (detail.MergeBlockedReason is { } reason)
            body.AddChild(StatusRow(GhIcon.Alert, GitHubTheme.Attention, "Merging is blocked", reason, false));
        else
            body.AddChild(StatusRow(GhIcon.Check, GitHubTheme.SuccessEmphasis, "This branch has no conflicts with the base branch",
                "Merging can be performed automatically.", false));

        var footer = new HBoxContainer();
        footer.AddThemeConstantOverride("separation", S(10));
        var merge = GitHubUi.Btn("Merge pull request", async () =>
        {
            var result = await _host!.MergePullRequestAsync(pull.Number);
            Go(Page.PullDetail, result.Message, !result.Success);
        }, GhButtonKind.Primary, GhIcon.PullMerged);
        merge.Disabled = detail.MergeBlockedReason is not null;
        footer.AddChild(merge);
        footer.AddChild(GitHubUi.Btn("Close pull request", () =>
        {
            var result = _host!.ClosePullRequest(pull.Number);
            Go(Page.PullDetail, result.Message, !result.Success);
        }, GhButtonKind.Default, GhIcon.PullClosed));
        var padded = new MarginContainer();
        padded.AddThemeConstantOverride("margin_left", S(16));
        padded.AddThemeConstantOverride("margin_right", S(16));
        padded.AddThemeConstantOverride("margin_top", S(14));
        padded.AddThemeConstantOverride("margin_bottom", S(14));
        padded.AddChild(footer);
        body.AddChild(padded);
        _content.AddChild(box);
    }

    private async Task BuildMergedBoxAsync(PullRequestInfo pull)
    {
        var branchStillExists = (await _host!.ListBranchesAsync()).Any(branch => branch.Name == pull.SourceBranch);
        Control? action = null;
        if (branchStillExists)
            action = GitHubUi.Btn("Delete branch", async () =>
            {
                var deleted = await _host.DeleteBranchAsync(pull.SourceBranch);
                Go(Page.PullDetail, deleted ? $"ลบ branch {pull.SourceBranch} แล้ว" : "ลบ branch ไม่ได้", !deleted);
            }, GhButtonKind.Default, GhIcon.Trash);

        var (box, body) = GitHubUi.Box();
        body.AddChild(StatusRow(GhIcon.PullMerged, GitHubTheme.DoneEmphasis, "Pull request successfully merged and closed",
            branchStillExists
                ? $"คุณทำเสร็จแล้ว — ลบ branch {pull.SourceBranch} ได้อย่างปลอดภัย"
                : $"รวมเข้า {pull.TargetBranch} แล้ว และลบ branch {pull.SourceBranch} ไปแล้ว", true, action));
        _content.AddChild(box);
    }

    /// <summary>ฟอร์ม review: ความเห็น + Comment / Request changes / Approve (ผลและเหตุผลมาจาก host)</summary>
    private void BuildReviewBox(PullRequestInfo pull)
    {
        var reviewer = _repo!.Owner;
        var row = new HBoxContainer();
        row.AddThemeConstantOverride("separation", S(14));
        var avatar = GitHubUi.Avatar(reviewer, 40);
        avatar.SizeFlagsVertical = SizeFlags.ShrinkBegin;
        row.AddChild(avatar);

        var card = GitHubUi.Card(16, 14);
        var column = new VBoxContainer();
        column.AddThemeConstantOverride("separation", S(10));
        column.AddChild(GitHubUi.Text("Add your review", GitHubTheme.Fg, 16, bold: true));
        column.AddChild(GitHubUi.Text($"ในฐานะ {reviewer}", GitHubTheme.FgMuted, 13));
        var comment = new TextEdit
        {
            PlaceholderText = "Leave a comment (ไม่บังคับ)",
            CustomMinimumSize = new Vector2(0, S(84)),
            WrapMode = TextEdit.LineWrappingMode.Boundary
        };
        column.AddChild(comment);

        void Review(ReviewVerdict verdict)
        {
            var result = _host!.ReviewPullRequest(pull.Number, reviewer, verdict, comment.Text);
            Go(Page.PullDetail, result.Message, !result.Success);
        }

        var buttons = new HBoxContainer();
        buttons.AddThemeConstantOverride("separation", S(10));
        buttons.AddChild(GitHubUi.Spacer());
        buttons.AddChild(GitHubUi.Btn("Comment", () => Review(ReviewVerdict.Commented), GhButtonKind.Default, GhIcon.Comment));
        buttons.AddChild(GitHubUi.Btn("Request changes", () => Review(ReviewVerdict.ChangesRequested), GhButtonKind.Danger));
        buttons.AddChild(GitHubUi.Btn("Approve", () => Review(ReviewVerdict.Approved), GhButtonKind.Primary, GhIcon.Check));
        column.AddChild(buttons);
        card.AddChild(column);
        row.AddChild(card);
        _content.AddChild(row);
    }

    // ───────────── Commits / Files changed ─────────────

    private void BuildPullCommits(PullRequestDetail detail)
    {
        if (detail.Commits.Count == 0)
        {
            _content.AddChild(GitHubUi.EmptyState(GhIcon.Commit, "ไม่มี commit ให้แสดง",
                "PR นี้ไม่มี commit ที่ต่างจาก branch ปลายทางแล้ว"));
            return;
        }

        var (box, body) = GitHubUi.Box();
        for (var index = 0; index < detail.Commits.Count; index++)
            body.AddChild(CommitRow(detail.Commits[index], index == detail.Commits.Count - 1));
        _content.AddChild(box);
    }

    private void BuildPullFiles(PullRequestDetail detail)
    {
        if (detail.Files.Count == 0)
        {
            _content.AddChild(GitHubUi.EmptyState(GhIcon.File, "ไม่มีไฟล์ที่เปลี่ยน",
                "ไม่พบความต่างระหว่าง branch ต้นทางกับปลายทาง"));
            return;
        }

        var additions = detail.Files.Sum(file => file.Additions);
        var deletions = detail.Files.Sum(file => file.Deletions);
        var summary = new HBoxContainer();
        summary.AddThemeConstantOverride("separation", S(8));
        summary.AddChild(GitHubUi.Text($"Showing {GitHubUi.Count(detail.Files.Count, "changed file", "changed files")} with",
            GitHubTheme.FgMuted));
        summary.AddChild(GitHubUi.Text($"{additions} additions", GitHubTheme.Success, 15, bold: true));
        summary.AddChild(GitHubUi.Text("and", GitHubTheme.FgMuted));
        summary.AddChild(GitHubUi.Text($"{deletions} deletions", GitHubTheme.Danger, 15, bold: true));
        _content.AddChild(summary);
        _content.AddChild(DiffViewer.Build(detail.Diff, detail.Files));
    }
}
