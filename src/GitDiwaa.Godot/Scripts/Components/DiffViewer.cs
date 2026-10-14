using System.Globalization;
using System.Text.RegularExpressions;
using GitDiwaa.Core;
using GitDiwaa.Godot.Common;
using Godot;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// แสดง unified diff แบบหน้า "Files changed" ของ GitHub: การ์ดต่อไฟล์ (พับได้),
/// เลขบรรทัดเก่า/ใหม่ และสีเขียว/แดงที่บรรทัดที่เพิ่ม/ลบ
/// </summary>
public static class DiffViewer
{
    /// <summary>
    /// ความเห็นรายบรรทัดของ PR: <see cref="Comments"/> แสดงใต้บรรทัดที่ตรงกัน ส่วนปุ่ม + ที่เลขบรรทัดและกล่องเขียน
    /// จะมีก็ต่อเมื่อ <see cref="Submit"/> ไม่เป็น null (PR ที่ยังเปิดอยู่)
    /// </summary>
    public sealed record CommentContext(
        IReadOnlyList<PullRequestLineComment> Comments,
        string Viewer,
        Action<string, int, bool, string, bool>? Submit)
    {
        public bool HasPendingReview =>
            Comments.Any(comment => comment.IsPending && comment.Author.Equals(Viewer, StringComparison.OrdinalIgnoreCase));
    }

    private enum Kind { Hunk, Add, Remove, Context, Note }

    private sealed record DiffLine(Kind Kind, int? Old, int? New, string Text);

    private sealed class FileDiff
    {
        public string Path = string.Empty;
        public readonly List<DiffLine> Lines = [];
    }

    private static int S(int pixels) => GitHubTheme.S(pixels);

    private static readonly Regex HunkHeader = new(@"^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@", RegexOptions.Compiled);

    public static Control Build(string diff, IReadOnlyList<PullRequestFileChange> stats, CommentContext? comments = null)
    {
        var column = new VBoxContainer
        {
            MouseFilter = Control.MouseFilterEnum.Pass,
            SizeFlagsHorizontal = Control.SizeFlags.ExpandFill
        };
        column.AddThemeConstantOverride("separation", S(16));
        foreach (var file in Parse(diff))
            column.AddChild(FileCard(file, stats.FirstOrDefault(stat => stat.Path == file.Path), comments));
        return column;
    }

    private static List<FileDiff> Parse(string diff)
    {
        var files = new List<FileDiff>();
        FileDiff? current = null;
        string? oldPath = null;
        var inHunk = false;
        var oldNumber = 0;
        var newNumber = 0;

        foreach (var raw in diff.Split('\n'))
        {
            if (raw.StartsWith("diff --git ", StringComparison.Ordinal))
            {
                var split = raw.LastIndexOf(" b/", StringComparison.Ordinal);
                current = new FileDiff { Path = split >= 0 ? raw[(split + 3)..] : raw[11..] };
                files.Add(current);
                oldPath = null;
                inHunk = false;
                continue;
            }

            if (current is null) continue;

            if (raw.StartsWith("@@", StringComparison.Ordinal))
            {
                var match = HunkHeader.Match(raw);
                if (match.Success)
                {
                    oldNumber = int.Parse(match.Groups[1].Value, CultureInfo.InvariantCulture);
                    newNumber = int.Parse(match.Groups[2].Value, CultureInfo.InvariantCulture);
                }

                inHunk = true;
                current.Lines.Add(new(Kind.Hunk, null, null, raw));
                continue;
            }

            if (!inHunk)
            {
                if (raw.StartsWith("--- a/", StringComparison.Ordinal)) oldPath = raw[6..];
                else if (raw.StartsWith("+++ b/", StringComparison.Ordinal)) current.Path = raw[6..];
                else if (raw.StartsWith("+++ /dev/null", StringComparison.Ordinal) && oldPath is not null) current.Path = oldPath;
                else if (raw.StartsWith("Binary files", StringComparison.Ordinal)) current.Lines.Add(new(Kind.Note, null, null, raw));
                continue;
            }

            if (raw.StartsWith('+')) current.Lines.Add(new(Kind.Add, null, newNumber++, raw[1..]));
            else if (raw.StartsWith('-')) current.Lines.Add(new(Kind.Remove, oldNumber++, null, raw[1..]));
            else if (raw.StartsWith(' ')) current.Lines.Add(new(Kind.Context, oldNumber++, newNumber++, raw[1..]));
            else if (raw.Length > 0) current.Lines.Add(new(Kind.Note, null, null, raw));
        }

        return files;
    }

    private static Control FileCard(FileDiff file, PullRequestFileChange? stat, CommentContext? comments)
    {
        var chevron = GitHubUi.Icon(GhIcon.ChevronDown, GitHubTheme.FgMuted);
        var header = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Ignore };
        header.AddThemeConstantOverride("separation", S(10));
        header.AddChild(chevron);
        var name = GitHubUi.Text(file.Path, GitHubTheme.Fg, 14, mono: true);
        name.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
        header.AddChild(name);
        if (stat is not null)
        {
            header.AddChild(GitHubUi.Text($"+{stat.Additions}", GitHubTheme.Success, 13, bold: true));
            header.AddChild(GitHubUi.Text($"−{stat.Deletions}", GitHubTheme.Danger, 13, bold: true));
        }

        var (box, content) = GitHubUi.Box(header);
        var lines = new VBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        lines.AddThemeConstantOverride("separation", S(0));
        foreach (var line in file.Lines) lines.AddChild(LineBlock(file.Path, line, comments));
        content.AddChild(lines);

        // คลิกหัวการ์ดเพื่อพับ/ขยายไฟล์
        var headerPanel = (PanelContainer)content.GetChild(0);
        headerPanel.MouseDefaultCursorShape = Control.CursorShape.PointingHand;
        headerPanel.GuiInput += input =>
        {
            if (input is not InputEventMouseButton { Pressed: true, ButtonIndex: MouseButton.Left }) return;
            headerPanel.AcceptEvent();
            lines.Visible = !lines.Visible;
            chevron.Texture = GitHubIcons.Get(lines.Visible ? GhIcon.ChevronDown : GhIcon.ChevronRight, GitHubTheme.FgMuted, S(16));
        };
        return box;
    }

    /// <summary>หนึ่งบรรทัดของ diff + ความเห็นใต้บรรทัด + กล่องเขียนความเห็น (เปิดจากปุ่ม + ตอนชี้เมาส์)</summary>
    private static Control LineBlock(string path, DiffLine line, CommentContext? comments)
    {
        var block = new VBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        block.AddThemeConstantOverride("separation", S(0));

        var editorSlot = new VBoxContainer();
        var commentable = comments?.Submit is not null && line.Kind is Kind.Add or Kind.Remove or Kind.Context;
        var number = line.Kind == Kind.Remove ? line.Old : line.New;
        var onNewSide = line.Kind != Kind.Remove;
        Action? openEditor = null;
        if (commentable && number is { } lineNumber)
            openEditor = () =>
            {
                if (editorSlot.GetChildCount() > 0) return;
                editorSlot.AddChild(CommentEditor(path, lineNumber, onNewSide, comments!, () =>
                {
                    foreach (var child in editorSlot.GetChildren())
                    {
                        editorSlot.RemoveChild(child);
                        child.QueueFree();
                    }
                }));
            };

        block.AddChild(LineRow(line, openEditor));

        if (comments is not null && number is { } existing)
            foreach (var comment in comments.Comments.Where(item =>
                         item.Path == path && item.Line == existing && item.OnNewSide == onNewSide &&
                         (!item.IsPending || item.Author.Equals(comments.Viewer, StringComparison.OrdinalIgnoreCase))))
                block.AddChild(InlineComment(comment));

        block.AddChild(editorSlot);
        return block;
    }

    private static Control Indented(Control child)
    {
        var margin = new MarginContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        margin.AddThemeConstantOverride("margin_left", S(84));
        margin.AddThemeConstantOverride("margin_right", S(16));
        margin.AddThemeConstantOverride("margin_top", S(8));
        margin.AddThemeConstantOverride("margin_bottom", S(10));
        margin.AddChild(child);
        return margin;
    }

    private static Control InlineComment(PullRequestLineComment comment)
    {
        var header = new HBoxContainer();
        header.AddThemeConstantOverride("separation", S(8));
        header.AddChild(GitHubUi.Avatar(comment.Author, 22));
        header.AddChild(GitHubUi.Text(comment.Author, GitHubTheme.Fg, 14, bold: true));
        header.AddChild(GitHubUi.Text($"commented {GitHubUi.TimeAgo(comment.At)}", GitHubTheme.FgMuted, 13));
        if (comment.IsPending)
            header.AddChild(GitHubUi.Pill("Pending", GitHubTheme.Attention, new Color(GitHubTheme.Attention, 0.55f), size: 12));
        var (box, content) = GitHubUi.Box(header);

        var margin = new MarginContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        margin.AddThemeConstantOverride("margin_left", S(14));
        margin.AddThemeConstantOverride("margin_right", S(14));
        margin.AddThemeConstantOverride("margin_top", S(10));
        margin.AddThemeConstantOverride("margin_bottom", S(12));
        margin.AddChild(MarkdownView.Render(comment.Body));
        content.AddChild(margin);
        return Indented(box);
    }

    /// <summary>กล่อง "Add a comment on line R47": Write / Preview + Cancel / Comment / Start a review</summary>
    private static Control CommentEditor(string path, int line, bool onNewSide, CommentContext comments, Action close)
    {
        var card = GitHubUi.Card(16, 14);
        var column = new VBoxContainer();
        column.AddThemeConstantOverride("separation", S(10));

        var title = new HBoxContainer();
        title.AddThemeConstantOverride("separation", S(10));
        title.AddChild(GitHubUi.Avatar(comments.Viewer, 28));
        title.AddChild(GitHubUi.Text($"Add a comment on line {(onNewSide ? "R" : "L")}{line}", GitHubTheme.Fg, 16, bold: true));
        column.AddChild(title);

        var input = new TextEdit
        {
            PlaceholderText = "Leave a comment",
            CustomMinimumSize = new Vector2(0, S(110)),
            WrapMode = TextEdit.LineWrappingMode.Boundary
        };
        var preview = new MarginContainer { Visible = false, CustomMinimumSize = new Vector2(0, S(110)) };

        var tabs = new HBoxContainer();
        tabs.AddThemeConstantOverride("separation", S(4));
        Control Tab(string text, bool selected, Action onPressed) => GitHubUi.Tab(text, selected, onPressed);
        void ShowTabs(bool previewing)
        {
            foreach (var child in tabs.GetChildren())
            {
                tabs.RemoveChild(child);
                child.QueueFree();
            }

            tabs.AddChild(Tab("Write", !previewing, () => ShowTabs(false)));
            tabs.AddChild(Tab("Preview", previewing, () => ShowTabs(true)));
            input.Visible = !previewing;
            preview.Visible = previewing;
            if (!previewing) return;
            foreach (var child in preview.GetChildren())
            {
                preview.RemoveChild(child);
                child.QueueFree();
            }

            preview.AddChild(string.IsNullOrWhiteSpace(input.Text)
                ? GitHubUi.Text("Nothing to preview", GitHubTheme.FgMuted)
                : MarkdownView.Render(input.Text));
        }

        ShowTabs(false);
        column.AddChild(tabs);
        column.AddChild(input);
        column.AddChild(preview);

        var buttons = new HBoxContainer();
        buttons.AddThemeConstantOverride("separation", S(10));
        buttons.AddChild(GitHubUi.Spacer());
        buttons.AddChild(GitHubUi.Btn("Cancel", close));
        var single = GitHubUi.Btn("Comment", () => comments.Submit!(path, line, onNewSide, input.Text, false), GhButtonKind.Default, GhIcon.Comment);
        var review = GitHubUi.Btn(comments.HasPendingReview ? "Add review comment" : "Start a review",
            () => comments.Submit!(path, line, onNewSide, input.Text, true), GhButtonKind.Primary);
        // ถ้ามี pending review อยู่แล้ว GitHub ให้เพิ่มเข้า review เดิมเท่านั้น ไม่มีปุ่ม Comment เดี่ยว
        if (!comments.HasPendingReview) buttons.AddChild(single);
        buttons.AddChild(review);
        column.AddChild(buttons);

        void Sync()
        {
            var empty = string.IsNullOrWhiteSpace(input.Text);
            single.Disabled = empty;
            review.Disabled = empty;
        }

        input.TextChanged += Sync;
        Sync();
        card.AddChild(column);
        return Indented(card);
    }

    private static Control LineRow(DiffLine line, Action? onAddComment)
    {
        var (background, gutter) = line.Kind switch
        {
            Kind.Add => (GitHubTheme.DiffAdd, GitHubTheme.DiffAddGutter),
            Kind.Remove => (GitHubTheme.DiffRemove, GitHubTheme.DiffRemoveGutter),
            Kind.Hunk => (GitHubTheme.DiffHunk, GitHubTheme.DiffHunk),
            _ => (Colors.Transparent, Colors.Transparent)
        };

        var row = new PanelContainer { MouseFilter = Control.MouseFilterEnum.Pass, SizeFlagsHorizontal = Control.SizeFlags.ExpandFill };
        row.AddThemeStyleboxOverride("panel", new StyleBoxFlat
        {
            BgColor = background,
            ContentMarginLeft = 0,
            ContentMarginRight = S(12),
            ContentMarginTop = 1,
            ContentMarginBottom = 1
        });

        var cells = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        cells.AddThemeConstantOverride("separation", S(0));
        if (line.Kind is Kind.Hunk or Kind.Note)
        {
            cells.AddChild(Gutter(null, gutter));
            cells.AddChild(Gutter(null, gutter));
            var text = GitHubUi.Text(line.Text, GitHubTheme.FgMuted, 13, mono: true);
            text.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
            text.ClipText = true;
            cells.AddChild(Pad(text, 10));
        }
        else
        {
            cells.AddChild(Gutter(line.Old, gutter));
            cells.AddChild(Gutter(line.New, gutter));
            cells.AddChild(AddCommentCell(row, onAddComment));
            var (sign, signColor) = line.Kind switch
            {
                Kind.Add => ("+", GitHubTheme.Success),
                Kind.Remove => ("−", GitHubTheme.Danger),
                _ => (" ", GitHubTheme.FgMuted)
            };
            var mark = GitHubUi.Text(sign, signColor, 14, mono: true);
            mark.CustomMinimumSize = new Vector2(S(24), 0);
            mark.HorizontalAlignment = HorizontalAlignment.Center;
            cells.AddChild(mark);
            var code = GitHubUi.Text(line.Text, GitHubTheme.Fg, 14, mono: true);
            code.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
            code.ClipText = true;
            cells.AddChild(code);
        }

        row.AddChild(cells);
        return row;
    }

    /// <summary>ช่องปุ่ม + สำหรับเขียนความเห็น: เห็นเฉพาะตอนชี้เมาส์ที่บรรทัด (ช่องกว้างคงที่เพื่อไม่ให้โค้ดขยับ)</summary>
    private static Control AddCommentCell(Control row, Action? onAddComment)
    {
        var cell = new Control { MouseFilter = Control.MouseFilterEnum.Pass, CustomMinimumSize = new Vector2(S(30), 0) };
        if (onAddComment is null) return cell;

        var plus = GitHubUi.Btn("+", onAddComment, GhButtonKind.Primary);
        plus.CustomMinimumSize = new Vector2(S(22), S(22));
        plus.TooltipText = "เพิ่มความเห็นที่บรรทัดนี้";
        plus.SetAnchorsAndOffsetsPreset(Control.LayoutPreset.Center);
        plus.Visible = false;
        cell.AddChild(plus);
        row.MouseEntered += () => plus.Visible = true;
        // ปุ่มเป็น child ที่รับเมาส์ ทำให้ row ยิง MouseExited ตอนเมาส์เข้าปุ่ม จึงซ่อนเฉพาะเมื่อเมาส์ออกนอกแถวจริง
        row.MouseExited += () => plus.Visible = row.GetGlobalRect().HasPoint(row.GetGlobalMousePosition());
        return cell;
    }

    /// <summary>คอลัมน์เลขบรรทัด (พื้นเข้มกว่าที่บรรทัดเพิ่ม/ลบ)</summary>
    private static Control Gutter(int? number, Color background)
    {
        var cell = new PanelContainer { MouseFilter = Control.MouseFilterEnum.Pass, CustomMinimumSize = new Vector2(S(56), 0) };
        cell.AddThemeStyleboxOverride("panel", new StyleBoxFlat
        {
            BgColor = background,
            ContentMarginLeft = S(4),
            ContentMarginRight = S(10),
            ContentMarginTop = 0,
            ContentMarginBottom = 0
        });
        var label = GitHubUi.Text(number?.ToString(CultureInfo.InvariantCulture) ?? string.Empty, GitHubTheme.FgSubtle, 13, mono: true);
        label.HorizontalAlignment = HorizontalAlignment.Right;
        cell.AddChild(label);
        return cell;
    }

    private static Control Pad(Control child, int left)
    {
        var margin = new MarginContainer
        {
            MouseFilter = Control.MouseFilterEnum.Pass,
            SizeFlagsHorizontal = Control.SizeFlags.ExpandFill
        };
        margin.AddThemeConstantOverride("margin_left", left);
        margin.AddChild(child);
        return margin;
    }
}
