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
    private enum Kind { Hunk, Add, Remove, Context, Note }

    private sealed record DiffLine(Kind Kind, int? Old, int? New, string Text);

    private sealed class FileDiff
    {
        public string Path = string.Empty;
        public readonly List<DiffLine> Lines = [];
    }

    private static readonly Regex HunkHeader = new(@"^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@", RegexOptions.Compiled);

    public static Control Build(string diff, IReadOnlyList<PullRequestFileChange> stats)
    {
        var column = new VBoxContainer
        {
            MouseFilter = Control.MouseFilterEnum.Pass,
            SizeFlagsHorizontal = Control.SizeFlags.ExpandFill
        };
        column.AddThemeConstantOverride("separation", 16);
        foreach (var file in Parse(diff))
            column.AddChild(FileCard(file, stats.FirstOrDefault(stat => stat.Path == file.Path)));
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

    private static Control FileCard(FileDiff file, PullRequestFileChange? stat)
    {
        var chevron = GitHubUi.Icon(GhIcon.ChevronDown, GitHubTheme.FgMuted);
        var header = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Ignore };
        header.AddThemeConstantOverride("separation", 10);
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
        lines.AddThemeConstantOverride("separation", 0);
        foreach (var line in file.Lines) lines.AddChild(LineRow(line));
        content.AddChild(lines);

        // คลิกหัวการ์ดเพื่อพับ/ขยายไฟล์
        var headerPanel = (PanelContainer)content.GetChild(0);
        headerPanel.MouseDefaultCursorShape = Control.CursorShape.PointingHand;
        headerPanel.GuiInput += input =>
        {
            if (input is not InputEventMouseButton { Pressed: true, ButtonIndex: MouseButton.Left }) return;
            headerPanel.AcceptEvent();
            lines.Visible = !lines.Visible;
            chevron.Texture = GitHubIcons.Get(lines.Visible ? GhIcon.ChevronDown : GhIcon.ChevronRight, GitHubTheme.FgMuted);
        };
        return box;
    }

    private static Control LineRow(DiffLine line)
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
            ContentMarginRight = 12,
            ContentMarginTop = 1,
            ContentMarginBottom = 1
        });

        var cells = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        cells.AddThemeConstantOverride("separation", 0);
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
            var (sign, signColor) = line.Kind switch
            {
                Kind.Add => ("+", GitHubTheme.Success),
                Kind.Remove => ("−", GitHubTheme.Danger),
                _ => (" ", GitHubTheme.FgMuted)
            };
            var mark = GitHubUi.Text(sign, signColor, 14, mono: true);
            mark.CustomMinimumSize = new Vector2(24, 0);
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

    /// <summary>คอลัมน์เลขบรรทัด (พื้นเข้มกว่าที่บรรทัดเพิ่ม/ลบ)</summary>
    private static Control Gutter(int? number, Color background)
    {
        var cell = new PanelContainer { MouseFilter = Control.MouseFilterEnum.Pass, CustomMinimumSize = new Vector2(56, 0) };
        cell.AddThemeStyleboxOverride("panel", new StyleBoxFlat
        {
            BgColor = background,
            ContentMarginLeft = 4,
            ContentMarginRight = 10,
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
