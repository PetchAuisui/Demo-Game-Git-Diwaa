using GitDiwaa.Core;
using GitDiwaa.Godot.Common;
using Godot;

namespace GitDiwaa.Godot.Components;

public partial class RemoteRepoView
{
    // ───────────── Commits / Branches ─────────────

    private async Task BuildCommitsAsync()
    {
        var branches = await _host!.ListBranchesAsync();
        var toolbar = new HBoxContainer();
        toolbar.AddThemeConstantOverride("separation", 12);
        toolbar.AddChild(GitHubUi.Text("Commits", GitHubTheme.Fg, 26, bold: true));
        toolbar.AddChild(GitHubUi.Spacer());
        toolbar.AddChild(BranchPicker(branches, name =>
        {
            _branch = name;
            Go(Page.Commits);
        }));
        _content.AddChild(toolbar);

        var commits = await _host.ListCommitsAsync(_branch, 100);
        if (commits.Count == 0)
        {
            _content.AddChild(GitHubUi.EmptyState(GhIcon.Commit, "ยังไม่มี commit", $"branch {_branch} ยังไม่มีประวัติ"));
            return;
        }

        // จัดกลุ่มตามวัน เหมือนหน้า commits ของ GitHub
        foreach (var day in commits.GroupBy(commit => commit.AuthoredAt.LocalDateTime.Date))
        {
            var items = day.ToList();
            _content.AddChild(GitHubUi.IconText(GhIcon.Commit,
                $"Commits on {GitHubUi.DateLabel(items[0].AuthoredAt)}", GitHubTheme.FgMuted, 14));
            var (box, body) = GitHubUi.Box();
            for (var index = 0; index < items.Count; index++)
                body.AddChild(CommitRow(items[index], index == items.Count - 1));
            _content.AddChild(box);
        }
    }

    private async Task BuildBranchesAsync()
    {
        var branches = await _host!.ListBranchesAsync();
        _content.AddChild(GitHubUi.Text("Branches", GitHubTheme.Fg, 26, bold: true));

        var defaults = branches.Where(branch => branch.IsDefault).ToList();
        var others = branches.Where(branch => !branch.IsDefault).ToList();
        if (defaults.Count > 0) _content.AddChild(BranchSection("Default", defaults));
        if (others.Count > 0) _content.AddChild(BranchSection("Other branches", others));
    }

    private Control BranchSection(string title, IReadOnlyList<RemoteBranchInfo> items)
    {
        var (box, body) = GitHubUi.Box(GitHubUi.Text(title, GitHubTheme.Fg, 15, bold: true));
        for (var index = 0; index < items.Count; index++)
            body.AddChild(BranchRow(items[index], index == items.Count - 1));
        return box;
    }

    private Control BranchRow(RemoteBranchInfo branch, bool last)
    {
        var row = new HBoxContainer();
        row.AddThemeConstantOverride("separation", 12);

        var name = GitHubUi.Btn(branch.Name, () =>
        {
            _branch = branch.Name;
            _path = string.Empty;
            Go(Page.Code);
        }, GhButtonKind.Link);
        name.CustomMinimumSize = new Vector2(240, 0);
        name.Alignment = HorizontalAlignment.Left;
        row.AddChild(name);
        if (branch.IsDefault) row.AddChild(GitHubUi.Pill("default", GitHubTheme.FgMuted, GitHubTheme.Border));

        var info = GitHubUi.Text($"{branch.LastCommitSubject} · {GitHubUi.TimeAgo(branch.LastCommitAt)}", GitHubTheme.FgMuted, 14);
        info.SizeFlagsHorizontal = SizeFlags.ExpandFill;
        info.ClipText = true;
        row.AddChild(info);

        if (!branch.IsDefault)
        {
            row.AddChild(GitHubUi.Text($"{branch.Behind} behind | {branch.Ahead} ahead", GitHubTheme.FgMuted, 13));
            row.AddChild(GitHubUi.Btn("New pull request", () =>
            {
                _newPullSource = branch.Name;
                Go(Page.NewPull);
            }));
            row.AddChild(GitHubUi.Btn(string.Empty, async () =>
            {
                var deleted = await _host!.DeleteBranchAsync(branch.Name);
                Go(Page.Branches, deleted ? $"ลบ branch {branch.Name} แล้ว" : $"ลบ {branch.Name} ไม่ได้ (มี PR ที่ยังเปิดอยู่)", !deleted);
            }, GhButtonKind.Ghost, GhIcon.Trash, iconColor: GitHubTheme.Danger));
        }

        return GitHubUi.ListRow(row, last);
    }

    /// <summary>แถว commit แบบ GitHub: ข้อความ ผู้เขียน/เวลา และ hash สั้นพร้อมปุ่มคัดลอก hash เต็ม</summary>
    private static Control CommitRow(RemoteCommitInfo commit, bool last)
    {
        var row = new HBoxContainer();
        row.AddThemeConstantOverride("separation", 12);

        var column = new VBoxContainer { SizeFlagsHorizontal = SizeFlags.ExpandFill };
        column.AddThemeConstantOverride("separation", 4);
        var subject = GitHubUi.Text(commit.Subject, GitHubTheme.Fg, 15, bold: true);
        subject.ClipText = true;
        column.AddChild(subject);
        var meta = new HBoxContainer();
        meta.AddThemeConstantOverride("separation", 8);
        meta.AddChild(GitHubUi.Avatar(commit.Author, 18));
        meta.AddChild(GitHubUi.Text(commit.Author, GitHubTheme.Fg, 13, bold: true));
        meta.AddChild(GitHubUi.Text($"committed {GitHubUi.TimeAgo(commit.AuthoredAt)}", GitHubTheme.FgMuted, 13));
        column.AddChild(meta);
        row.AddChild(column);

        row.AddChild(GitHubUi.Pill(commit.ShortId, GitHubTheme.FgMuted, GitHubTheme.Border, size: 13, mono: true));
        row.AddChild(GitHubUi.Btn(string.Empty, () => DisplayServer.ClipboardSet(commit.Id), GhButtonKind.Ghost, GhIcon.Copy));
        return GitHubUi.ListRow(row, last);
    }
}
