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
        var row = new HBoxContainer();
        row.AddThemeConstantOverride("separation", 10);
        row.AddChild(Btn("← Code", () => Go(Page.Code)));
        row.AddChild(Lbl("Commits", GitHubTheme.Fg, 20));
        row.AddChild(BranchPicker(branches, name => { _branch = name; Go(Page.Commits); }));
        _content.AddChild(row);

        var card = Card();
        var list = new VBoxContainer();
        list.AddThemeConstantOverride("separation", 8);
        foreach (var commit in await _host.ListCommitsAsync(_branch, 100))
        {
            var line = new HBoxContainer();
            line.AddThemeConstantOverride("separation", 14);
            var subject = Lbl(commit.Subject, GitHubTheme.Fg);
            subject.SizeFlagsHorizontal = SizeFlags.ExpandFill;
            subject.ClipText = true;
            line.AddChild(subject);
            line.AddChild(Lbl(commit.Author, GitHubTheme.FgMuted, 14));
            line.AddChild(Lbl(commit.ShortId, GitHubTheme.Success, 14));
            line.AddChild(Lbl(Ago(commit.AuthoredAt), GitHubTheme.FgMuted, 14));
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
        row.AddChild(Lbl("Branches", GitHubTheme.Fg, 20));
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
            var info = Lbl($"{item.LastCommitSubject} · {Ago(item.LastCommitAt)}", GitHubTheme.FgMuted, 14);
            info.SizeFlagsHorizontal = SizeFlags.ExpandFill;
            info.ClipText = true;
            line.AddChild(info);
            if (!item.IsDefault)
            {
                line.AddChild(Lbl($"↑{item.Ahead}  ↓{item.Behind}", GitHubTheme.Attention, 14));
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
