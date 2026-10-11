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
        if (branches.Count < 2)
        {
            _content.AddChild(Lbl("Open a pull request", SandboxThemeTokens.GoldTitle, 22));
            _content.AddChild(Lbl(branches.Count == 0
                    ? "repo ยังว่าง — push branch ขึ้นมาก่อนจึงจะเปิด pull request ได้"
                    : "ต้องมีอย่างน้อย 2 branch — สร้างและ push branch ใหม่ก่อน เช่น git switch -c feature/xxx แล้ว git push -u origin feature/xxx",
                SandboxThemeTokens.TextSecondary, wrap: true));
            var back = Btn("← Pull requests", () => Go(Page.Pulls));
            back.SizeFlagsHorizontal = SizeFlags.ShrinkBegin;
            _content.AddChild(back);
            return;
        }

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
                var pr = await _host.OpenPullRequestAsync(title.Text, body.Text, _repo!.Owner,
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
        var summary = pull.State switch
        {
            PullRequestState.Merged => $"{pull.Author} merged {detail.Commits.Count} commit(s) from {pull.SourceBranch} into {pull.TargetBranch}",
            PullRequestState.Closed => $"{pull.Author} wanted to merge {detail.Commits.Count} commit(s) from {pull.SourceBranch} into {pull.TargetBranch}",
            _ => $"{pull.Author} wants to merge {detail.Commits.Count} commit(s) from {pull.SourceBranch} into {pull.TargetBranch}"
        };
        _content.AddChild(Lbl(summary, SandboxThemeTokens.TextSecondary, 14));

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
                detail.HasConflicts ? SandboxThemeTokens.ErrorText : SandboxThemeTokens.StateModified, wrap: true));
        else
            box.AddChild(Lbl("✓ This branch has no conflicts with the base branch", SandboxThemeTokens.PromptGreen));

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
}
