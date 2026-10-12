using System.Text;
using System.Text.RegularExpressions;
using GitDiwaa.Godot.Common;
using Godot;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// แสดง Markdown พื้นฐานแบบ GitHub: หัวข้อ (# ## ###), ย่อหน้า, รายการ (- *), บล็อกโค้ด (```),
/// ตัวหนา (**) และโค้ดในบรรทัด (`) ข้อความที่ไม่รู้จักแสดงเป็นข้อความธรรมดา
/// </summary>
public static class MarkdownView
{
    private static int S(int pixels) => GitHubTheme.S(pixels);

    private static readonly Regex Bold = new(@"\*\*(.+?)\*\*", RegexOptions.Compiled);

    public static Control Render(string markdown)
    {
        var column = new VBoxContainer
        {
            MouseFilter = Control.MouseFilterEnum.Pass,
            SizeFlagsHorizontal = Control.SizeFlags.ExpandFill
        };
        column.AddThemeConstantOverride("separation", S(12));

        var paragraph = new List<string>();
        var code = new List<string>();
        var inCode = false;

        void FlushParagraph()
        {
            if (paragraph.Count == 0) return;
            column.AddChild(Inline(string.Join(' ', paragraph)));
            paragraph.Clear();
        }

        foreach (var raw in markdown.Replace("\r\n", "\n").Split('\n'))
        {
            var line = raw.TrimEnd();
            if (line.StartsWith("```", StringComparison.Ordinal))
            {
                if (inCode)
                {
                    column.AddChild(CodeBox(code));
                    code.Clear();
                    inCode = false;
                }
                else
                {
                    FlushParagraph();
                    inCode = true;
                }

                continue;
            }

            if (inCode)
            {
                code.Add(raw);
                continue;
            }

            if (line.Length == 0)
            {
                FlushParagraph();
                continue;
            }

            var level = HeadingLevel(line);
            if (level > 0)
            {
                FlushParagraph();
                column.AddChild(Heading(line[(level + 1)..].Trim(), level));
                continue;
            }

            if (line.StartsWith("- ", StringComparison.Ordinal) || line.StartsWith("* ", StringComparison.Ordinal))
            {
                FlushParagraph();
                column.AddChild(Bullet(line[2..].Trim()));
                continue;
            }

            paragraph.Add(line.Trim());
        }

        if (inCode && code.Count > 0) column.AddChild(CodeBox(code));
        FlushParagraph();
        return column;
    }

    private static int HeadingLevel(string line)
    {
        var level = 0;
        while (level < line.Length && level < 3 && line[level] == '#') level++;
        return level > 0 && level < line.Length && line[level] == ' ' ? level : 0;
    }

    private static Control Heading(string text, int level)
    {
        var size = level switch { 1 => 28, 2 => 22, _ => 18 };
        var column = new VBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        column.AddThemeConstantOverride("separation", S(8));
        column.AddChild(GitHubUi.Text(text, GitHubTheme.Fg, size, bold: true, wrap: true));
        if (level <= 2) column.AddChild(new HSeparator());
        return column;
    }

    private static Control Bullet(string text)
    {
        var row = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        row.AddThemeConstantOverride("separation", S(10));
        var dot = GitHubUi.Text("•", GitHubTheme.FgMuted);
        dot.SizeFlagsVertical = Control.SizeFlags.ShrinkBegin;
        row.AddChild(dot);
        row.AddChild(Inline(text));
        return row;
    }

    private static Control CodeBox(IReadOnlyList<string> lines)
    {
        var box = GitHubUi.Card(14, 10);
        box.AddThemeStyleboxOverride("panel", GitHubTheme.Box(GitHubTheme.CanvasSubtle, GitHubTheme.Border, 8, 1, 14, 10));
        var label = new RichTextLabel
        {
            Text = string.Join('\n', lines),
            FitContent = true,
            ScrollActive = false,
            SelectionEnabled = true,
            MouseFilter = Control.MouseFilterEnum.Pass,
            AutowrapMode = TextServer.AutowrapMode.Off
        };
        label.AddThemeFontOverride("normal_font", GitHubTheme.MonoFont);
        label.AddThemeFontSizeOverride("normal_font_size", S(14));
        label.AddThemeColorOverride("default_color", GitHubTheme.Fg);
        box.AddChild(label);
        return box;
    }

    private static RichTextLabel Inline(string text)
    {
        var label = new RichTextLabel
        {
            BbcodeEnabled = true,
            FitContent = true,
            ScrollActive = false,
            SelectionEnabled = true,
            AutowrapMode = TextServer.AutowrapMode.WordSmart,
            MouseFilter = Control.MouseFilterEnum.Pass,
            SizeFlagsHorizontal = Control.SizeFlags.ExpandFill
        };
        label.AddThemeFontOverride("bold_font", GitHubTheme.BoldFont);
        label.AddThemeFontOverride("mono_font", GitHubTheme.MonoFont);
        label.AddThemeFontSizeOverride("normal_font_size", S(15));
        label.AddThemeFontSizeOverride("bold_font_size", S(15));
        label.AddThemeFontSizeOverride("mono_font_size", S(14));
        label.AddThemeColorOverride("default_color", GitHubTheme.Fg);
        label.Text = ToBbcode(text);
        return label;
    }

    private static string ToBbcode(string text)
    {
        var parts = text.Split('`');
        if (parts.Length % 2 == 0) parts = [text]; // backtick ไม่ครบคู่ ไม่ตีความเป็นโค้ด

        var builder = new StringBuilder();
        for (var index = 0; index < parts.Length; index++)
        {
            var segment = parts[index].Replace("[", "[lb]");
            if (parts.Length > 1 && index % 2 == 1)
                builder.Append("[bgcolor=#6e768133][code] ").Append(segment).Append(" [/code][/bgcolor]");
            else
                builder.Append(Bold.Replace(segment, "[b]$1[/b]"));
        }

        return builder.ToString();
    }
}
