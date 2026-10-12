using System.Globalization;
using System.Text;
using GitDiwaa.Core;
using GitDiwaa.Godot.Common;
using Godot;

namespace GitDiwaa.Godot.Components;

public enum GhButtonKind
{
    Default,
    Primary,
    Danger,
    Link,
    Ghost
}

/// <summary>บรรทัดคำสั่งหนึ่งบรรทัด พร้อมคำอธิบายสั้นๆ ที่แสดงข้างๆ (ไม่ถูกคัดลอกไปด้วย)</summary>
public readonly record struct CodeLine(string Command, string? Hint = null);

/// <summary>ชิ้นส่วน UI แบบ GitHub ที่ใช้ซ้ำในหน้า Remote Repository</summary>
public static class GitHubUi
{
    private static readonly string[] AvatarColors =
        ["#1f6feb", "#8957e5", "#238636", "#9e6a03", "#da3633", "#0b7285", "#bf3989"];

    private static int S(int pixels) => GitHubTheme.S(pixels);

    public static Control Spacer() => new()
    {
        SizeFlagsHorizontal = Control.SizeFlags.ExpandFill,
        MouseFilter = Control.MouseFilterEnum.Ignore
    };

    public static Label Text(string text, Color? color = null, int size = 15, bool bold = false, bool mono = false, bool wrap = false)
    {
        var label = new Label { Text = text, MouseFilter = Control.MouseFilterEnum.Ignore };
        label.AddThemeColorOverride("font_color", color ?? GitHubTheme.Fg);
        label.AddThemeFontSizeOverride("font_size", S(size));
        if (mono) label.AddThemeFontOverride("font", GitHubTheme.MonoFont);
        else if (bold) label.AddThemeFontOverride("font", GitHubTheme.BoldFont);
        if (wrap)
        {
            label.AutowrapMode = TextServer.AutowrapMode.WordSmart;
            label.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
        }

        return label;
    }

    public static TextureRect Icon(GhIcon icon, Color color, int size = 16)
    {
        var pixels = S(size);
        return new TextureRect
        {
            Texture = GitHubIcons.Get(icon, color, pixels),
            CustomMinimumSize = new Vector2(pixels, pixels),
            ExpandMode = TextureRect.ExpandModeEnum.IgnoreSize,
            StretchMode = TextureRect.StretchModeEnum.KeepAspectCentered,
            MouseFilter = Control.MouseFilterEnum.Ignore,
            SizeFlagsVertical = Control.SizeFlags.ShrinkCenter,
            TextureFilter = CanvasItem.TextureFilterEnum.LinearWithMipmaps
        };
    }

    public static HBoxContainer IconText(GhIcon icon, string text, Color color, int size = 15, bool bold = false)
    {
        var row = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Ignore };
        row.AddThemeConstantOverride("separation", S(6));
        row.AddChild(Icon(icon, color, size + 1));
        row.AddChild(Text(text, color, size, bold));
        return row;
    }

    public static Button Btn(
        string text, Action onPressed, GhButtonKind kind = GhButtonKind.Default,
        GhIcon? icon = null, bool toggle = false, Color? iconColor = null)
    {
        var button = new Button
        {
            Text = text,
            ToggleMode = toggle,
            FocusMode = Control.FocusModeEnum.None,
            MouseFilter = Control.MouseFilterEnum.Pass,
            MouseDefaultCursorShape = Control.CursorShape.PointingHand,
            ThemeTypeVariation = kind switch
            {
                GhButtonKind.Primary => GitHubTheme.PrimaryButton,
                GhButtonKind.Danger => GitHubTheme.DangerButton,
                GhButtonKind.Link => GitHubTheme.LinkButton,
                GhButtonKind.Ghost => GitHubTheme.GhostButton,
                _ => string.Empty
            }
        };

        if (icon is { } glyph)
        {
            var tint = iconColor ?? kind switch
            {
                GhButtonKind.Primary => Colors.White,
                GhButtonKind.Danger => GitHubTheme.Danger,
                GhButtonKind.Link => GitHubTheme.Accent,
                _ => GitHubTheme.FgMuted
            };
            button.Icon = GitHubIcons.Get(glyph, tint, S(16)); // texture 3 เท่า ถูกจำกัดกว้างด้วย icon_max_width ใน theme
        }

        button.Pressed += onPressed;
        return button;
    }

    /// <summary>กล่องโค้งมีเส้นขอบ ใส่เนื้อหาตรงๆ (ช่องไฟด้านใน 16x12)</summary>
    public static PanelContainer Card(int padH = 16, int padV = 12)
    {
        var card = new PanelContainer
        {
            MouseFilter = Control.MouseFilterEnum.Pass,
            SizeFlagsHorizontal = Control.SizeFlags.ExpandFill
        };
        card.AddThemeStyleboxOverride("panel", GitHubTheme.Box(GitHubTheme.Surface, GitHubTheme.Border, 8, 1, padH, padV));
        return card;
    }

    /// <summary>กล่องสำหรับรายการ: มีหัวตาราง (ถ้าใส่) และพื้นที่ใส่แถวเรียงกัน</summary>
    public static (PanelContainer Panel, VBoxContainer Body) Box(Control? header = null)
    {
        var panel = new PanelContainer
        {
            MouseFilter = Control.MouseFilterEnum.Pass,
            SizeFlagsHorizontal = Control.SizeFlags.ExpandFill
        };
        panel.AddThemeStyleboxOverride("panel", GitHubTheme.Box(GitHubTheme.Surface, GitHubTheme.Border));
        var body = new VBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        body.AddThemeConstantOverride("separation", S(0));
        panel.AddChild(body);
        if (header is not null) body.AddChild(Header(header));
        return (panel, body);
    }

    public static PanelContainer Header(Control content)
    {
        var bar = new PanelContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        var style = GitHubTheme.Underlined(GitHubTheme.SurfaceRaised, GitHubTheme.Border, 1, 16, 10);
        style.CornerRadiusTopLeft = 5;
        style.CornerRadiusTopRight = 5;
        bar.AddThemeStyleboxOverride("panel", style);
        bar.AddChild(content);
        return bar;
    }

    /// <summary>แถวในรายการ: เส้นคั่นล่าง และถ้ามี onClick จะไฮไลต์เมื่อชี้และคลิกได้ทั้งแถว</summary>
    public static PanelContainer ListRow(Control content, bool last = false, Action? onClick = null)
    {
        var row = new PanelContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        StyleBoxFlat Style(bool hover) => GitHubTheme.Underlined(
            hover ? GitHubTheme.SurfaceRaised : Colors.Transparent, GitHubTheme.BorderMuted, last ? 0 : 1, 16, 9);

        row.AddThemeStyleboxOverride("panel", Style(false));
        if (onClick is not null)
        {
            row.MouseDefaultCursorShape = Control.CursorShape.PointingHand;
            row.MouseEntered += () => row.AddThemeStyleboxOverride("panel", Style(true));
            row.MouseExited += () => row.AddThemeStyleboxOverride("panel", Style(false));
            row.GuiInput += input =>
            {
                if (input is InputEventMouseButton { Pressed: true, ButtonIndex: MouseButton.Left })
                {
                    row.AcceptEvent();
                    onClick();
                }
            };
        }

        row.AddChild(content);
        return row;
    }

    public static PanelContainer Pill(string text, Color fg, Color border, Color? bg = null, int size = 12, bool mono = false)
    {
        var pill = new PanelContainer { MouseFilter = Control.MouseFilterEnum.Ignore };
        pill.AddThemeStyleboxOverride("panel", GitHubTheme.Box(bg ?? Colors.Transparent, border, 12, 1, 8, 1));
        pill.AddChild(Text(text, fg, size, mono: mono));
        return pill;
    }

    /// <summary>ป้ายปุ่มคีย์บอร์ดเล็กๆ เช่น Esc</summary>
    public static PanelContainer KeyHint(string key)
    {
        var chip = new PanelContainer { MouseFilter = Control.MouseFilterEnum.Ignore, SizeFlagsVertical = Control.SizeFlags.ShrinkCenter };
        chip.AddThemeStyleboxOverride("panel", GitHubTheme.Box(GitHubTheme.Surface, GitHubTheme.Border, 6, 1, 8, 1));
        chip.AddChild(Text(key, GitHubTheme.FgMuted, 13, mono: true));
        return chip;
    }

    /// <summary>ชื่อ branch แบบพื้นฟ้าอ่อนอักษร mono เหมือนในหน้า PR</summary>
    public static PanelContainer BranchPill(string name)
    {
        var pill = new PanelContainer { MouseFilter = Control.MouseFilterEnum.Ignore };
        pill.AddThemeStyleboxOverride("panel", GitHubTheme.Box(GitHubTheme.AccentSubtle, Colors.Transparent, 8, 0, 7, 2));
        pill.AddChild(Text(name, GitHubTheme.Accent, 13, mono: true));
        return pill;
    }

    public static PanelContainer StatePill(PullRequestState state)
    {
        var (fill, icon, label) = state switch
        {
            PullRequestState.Open => (GitHubTheme.SuccessEmphasis, GhIcon.PullOpen, "Open"),
            PullRequestState.Merged => (GitHubTheme.DoneEmphasis, GhIcon.PullMerged, "Merged"),
            _ => (GitHubTheme.DangerEmphasis, GhIcon.PullClosed, "Closed")
        };
        var pill = new PanelContainer { MouseFilter = Control.MouseFilterEnum.Ignore, SizeFlagsVertical = Control.SizeFlags.ShrinkCenter };
        pill.AddThemeStyleboxOverride("panel", GitHubTheme.Box(fill, fill, 16, 0, 12, 5));
        var row = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Ignore };
        row.AddThemeConstantOverride("separation", S(6));
        row.AddChild(Icon(icon, Colors.White, 14));
        row.AddChild(Text(label, Colors.White, 14, bold: true));
        pill.AddChild(row);
        return pill;
    }

    public static TextureRect StateIcon(PullRequestState state, int size = 16) => state switch
    {
        PullRequestState.Open => Icon(GhIcon.PullOpen, GitHubTheme.Success, size),
        PullRequestState.Merged => Icon(GhIcon.PullMerged, GitHubTheme.Done, size),
        _ => Icon(GhIcon.PullClosed, GitHubTheme.Danger, size)
    };

    /// <summary>วงกลมสีพร้อมไอคอนขาว (สถานะในไทม์ไลน์และกล่อง merge)</summary>
    public static PanelContainer Bubble(GhIcon icon, Color fill, int size = 32)
    {
        var pixels = S(size);
        var bubble = new PanelContainer
        {
            CustomMinimumSize = new Vector2(pixels, pixels),
            MouseFilter = Control.MouseFilterEnum.Ignore,
            SizeFlagsVertical = Control.SizeFlags.ShrinkBegin
        };
        bubble.AddThemeStyleboxOverride("panel", GitHubTheme.Box(fill, fill, pixels / 2, 0));
        var glyph = Icon(icon, Colors.White, size / 2);
        glyph.SizeFlagsHorizontal = Control.SizeFlags.ShrinkCenter;
        glyph.SizeFlagsVertical = Control.SizeFlags.ShrinkCenter;
        bubble.AddChild(glyph);
        return bubble;
    }

    public static PanelContainer Counter(int number)
    {
        var counter = new PanelContainer { MouseFilter = Control.MouseFilterEnum.Ignore, SizeFlagsVertical = Control.SizeFlags.ShrinkCenter };
        counter.AddThemeStyleboxOverride("panel", GitHubTheme.Box(new(0.52f, 0.56f, 0.62f, 0.35f), Colors.Transparent, 10, 0, 7, 0));
        counter.AddChild(Text(number.ToString(CultureInfo.InvariantCulture), GitHubTheme.Fg, 12));
        return counter;
    }

    public static PanelContainer Avatar(string name, int size = 24)
    {
        var index = name.Aggregate(0, (sum, character) => sum + character) % AvatarColors.Length;
        var fill = new Color(AvatarColors[index]);
        var pixels = S(size);
        var avatar = new PanelContainer
        {
            CustomMinimumSize = new Vector2(pixels, pixels),
            MouseFilter = Control.MouseFilterEnum.Ignore,
            SizeFlagsVertical = Control.SizeFlags.ShrinkCenter
        };
        avatar.AddThemeStyleboxOverride("panel", GitHubTheme.Box(fill, fill, pixels / 2, 0));
        var initial = Text(name.Length > 0 ? name[..1].ToUpperInvariant() : "?", Colors.White, size / 2 + 1, bold: true);
        initial.HorizontalAlignment = HorizontalAlignment.Center;
        initial.VerticalAlignment = VerticalAlignment.Center;
        initial.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
        initial.SizeFlagsVertical = Control.SizeFlags.ExpandFill;
        avatar.AddChild(initial);
        return avatar;
    }

    /// <summary>แถบแจ้งผลหลังทำรายการ (สำเร็จ = เขียว, ผิดพลาด = แดง)</summary>
    public static PanelContainer Flash(string message, bool error)
    {
        var fg = error ? GitHubTheme.Danger : GitHubTheme.Success;
        var panel = new PanelContainer { MouseFilter = Control.MouseFilterEnum.Pass, SizeFlagsHorizontal = Control.SizeFlags.ExpandFill };
        panel.AddThemeStyleboxOverride("panel", GitHubTheme.Box(
            error ? GitHubTheme.DangerSubtle : GitHubTheme.SuccessSubtle, new Color(fg, 0.4f), 8, 1, 14, 10));
        var row = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        row.AddThemeConstantOverride("separation", S(10));
        row.AddChild(Icon(error ? GhIcon.Alert : GhIcon.Check, fg));
        row.AddChild(Text(message, GitHubTheme.Fg, 15, wrap: true));
        panel.AddChild(row);
        return panel;
    }

    /// <summary>แถบข้อมูลสีฟ้า (คำแนะนำ ไม่ใช่ผลลัพธ์ของการกระทำ) ใส่หัวข้อตัวหนาได้</summary>
    public static PanelContainer Info(string message, string? title = null)
    {
        var panel = new PanelContainer { MouseFilter = Control.MouseFilterEnum.Pass, SizeFlagsHorizontal = Control.SizeFlags.ExpandFill };
        panel.AddThemeStyleboxOverride("panel", GitHubTheme.Box(
            GitHubTheme.AccentSubtle, new Color(GitHubTheme.Accent, 0.5f), 8, 1, 16, 12));
        var row = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        row.AddThemeConstantOverride("separation", S(12));
        var icon = Icon(GhIcon.Info, GitHubTheme.Accent, 18);
        icon.SizeFlagsVertical = Control.SizeFlags.ShrinkBegin;
        row.AddChild(icon);

        var text = new VBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass, SizeFlagsHorizontal = Control.SizeFlags.ExpandFill };
        text.AddThemeConstantOverride("separation", S(2));
        if (title is not null) text.AddChild(Text(title, GitHubTheme.Fg, 16, bold: true, wrap: true));
        text.AddChild(Text(message, GitHubTheme.Fg, 15, wrap: true));
        row.AddChild(text);
        panel.AddChild(row);
        return panel;
    }

    public static PanelContainer CodeBlock(IEnumerable<string> lines) =>
        CommandBlock(lines.Select(line => new CodeLine(line)));

    /// <summary>
    /// บล็อกคำสั่งสีเข้มเหมือนหน้าต่าง terminal: ย้อมสีส่วนต่างของคำสั่ง ใส่คำอธิบายสั้นๆ ข้างบรรทัดได้
    /// และคลิกทั้งแถวเพื่อคัดลอกทีละบรรทัด (terminal ของเกมรับคำสั่งทีละบรรทัด)
    /// </summary>
    public static PanelContainer CommandBlock(IEnumerable<CodeLine> lines)
    {
        var items = lines.ToList();
        var commandWidth = items.Any(item => item.Hint is not null)
            ? items.Max(item => GitHubTheme.MonoFont.GetStringSize(item.Command, HorizontalAlignment.Left, -1, S(15)).X) * 1.04f + S(6)
            : 0f;

        var panel = new PanelContainer { MouseFilter = Control.MouseFilterEnum.Pass, SizeFlagsHorizontal = Control.SizeFlags.ExpandFill };
        panel.AddThemeStyleboxOverride("panel", GitHubTheme.Box(GitHubTheme.Inset, GitHubTheme.Border, 8, 1, 6, 6));
        var column = new VBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        column.AddThemeConstantOverride("separation", S(2));
        foreach (var line in items) column.AddChild(CommandRow(line, commandWidth));
        panel.AddChild(column);
        return panel;
    }

    private static Control CommandRow(CodeLine line, float commandWidth)
    {
        var row = new PanelContainer
        {
            MouseFilter = Control.MouseFilterEnum.Pass,
            MouseDefaultCursorShape = Control.CursorShape.PointingHand,
            TooltipText = "คลิกเพื่อคัดลอกคำสั่งนี้"
        };
        StyleBoxFlat Style(bool hover) => GitHubTheme.Box(
            hover ? new Color(1f, 1f, 1f, 0.07f) : Colors.Transparent, Colors.Transparent, 6, 0, 10, 6);
        row.AddThemeStyleboxOverride("panel", Style(false));

        var cells = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Ignore };
        cells.AddThemeConstantOverride("separation", S(12));

        var prompt = Text("$", GitHubTheme.FgSubtle, 15, mono: true);
        prompt.SizeFlagsVertical = Control.SizeFlags.ShrinkBegin;
        cells.AddChild(prompt);

        var command = Highlight(line.Command);
        if (commandWidth > 0)
        {
            command.CustomMinimumSize = new Vector2(commandWidth, 0);
            command.SizeFlagsHorizontal = Control.SizeFlags.ShrinkBegin;
        }

        cells.AddChild(command);

        // คำอธิบายข้างบรรทัด ใช้ช่องเดียวกันแสดง "คัดลอกแล้ว" ชั่วคราว เพื่อไม่ให้แถวขยับ
        var note = Text(line.Hint ?? string.Empty, GitHubTheme.FgMuted, 14, wrap: line.Hint is not null);
        note.SizeFlagsVertical = Control.SizeFlags.ShrinkBegin;
        if (line.Hint is null) note.SizeFlagsHorizontal = Control.SizeFlags.ShrinkEnd;
        cells.AddChild(note);

        var icon = Icon(GhIcon.Copy, GitHubTheme.FgSubtle);
        icon.SizeFlagsVertical = Control.SizeFlags.ShrinkBegin;
        cells.AddChild(icon);
        row.AddChild(cells);

        void ShowCopyIcon(Color color) => icon.Texture = GitHubIcons.Get(GhIcon.Copy, color, S(16));
        row.MouseEntered += () =>
        {
            row.AddThemeStyleboxOverride("panel", Style(true));
            ShowCopyIcon(GitHubTheme.Fg);
        };
        row.MouseExited += () =>
        {
            row.AddThemeStyleboxOverride("panel", Style(false));
            ShowCopyIcon(GitHubTheme.FgSubtle);
        };
        row.GuiInput += input =>
        {
            if (input is not InputEventMouseButton { Pressed: true, ButtonIndex: MouseButton.Left }) return;
            row.AcceptEvent();
            DisplayServer.ClipboardSet(line.Command);
            note.Text = "คัดลอกแล้ว";
            note.AddThemeColorOverride("font_color", GitHubTheme.Success);
            icon.Texture = GitHubIcons.Get(GhIcon.Check, GitHubTheme.Success, S(16));
            row.GetTree().CreateTimer(1.4).Timeout += () =>
            {
                if (!GodotObject.IsInstanceValid(row)) return;
                note.Text = line.Hint ?? string.Empty;
                note.AddThemeColorOverride("font_color", GitHubTheme.FgMuted);
                ShowCopyIcon(GitHubTheme.FgSubtle);
            };
        };
        return row;
    }

    private static RichTextLabel Highlight(string command)
    {
        var label = new RichTextLabel
        {
            BbcodeEnabled = true,
            FitContent = true,
            ScrollActive = false,
            SelectionEnabled = false,
            AutowrapMode = TextServer.AutowrapMode.Arbitrary,
            MouseFilter = Control.MouseFilterEnum.Ignore,
            SizeFlagsHorizontal = Control.SizeFlags.ExpandFill
        };
        label.AddThemeFontOverride("normal_font", GitHubTheme.MonoFont);
        label.AddThemeFontOverride("bold_font", GitHubTheme.MonoBoldFont);
        label.AddThemeFontSizeOverride("normal_font_size", S(15));
        label.AddThemeFontSizeOverride("bold_font_size", S(15));
        label.AddThemeColorOverride("default_color", GitHubTheme.Fg);
        label.Text = CommandToBbcode(command);
        return label;
    }

    /// <summary>
    /// ย้อมสีคำสั่ง: ชื่อคำสั่ง (git / write ของเกม) ตัวหนา, คำสั่งย่อยของ git สีเขียว, flag สีส้ม,
    /// ข้อความในเครื่องหมายคำพูดสีฟ้าอ่อน, URL และชื่อไฟล์สีฟ้า
    /// </summary>
    private static string CommandToBbcode(string command)
    {
        var tokens = Tokenize(command);
        var builder = new StringBuilder();
        for (var index = 0; index < tokens.Count; index++)
        {
            if (index > 0) builder.Append(' ');
            var token = tokens[index];
            var bold = false;
            Color? color = null;

            if (index == 0)
            {
                bold = true;
                if (token == "write") color = GitHubTheme.SyntaxGame;
            }
            else if (tokens[0] == "write")
            {
                color = index == 1 ? GitHubTheme.SyntaxPath : GitHubTheme.SyntaxString;
            }
            else if (token.StartsWith('-'))
            {
                color = GitHubTheme.SyntaxFlag;
            }
            else if (tokens[0] == "git" && index == 1)
            {
                color = GitHubTheme.SyntaxSubcommand;
                bold = true;
            }
            else if (token.StartsWith('"') || token.StartsWith('\''))
            {
                color = GitHubTheme.SyntaxString;
            }
            else if (token.Contains("://", StringComparison.Ordinal))
            {
                color = GitHubTheme.SyntaxPath;
            }

            var text = token.Replace("[", "[lb]");
            if (bold) text = $"[b]{text}[/b]";
            builder.Append(color is { } tint ? $"[color=#{tint.ToHtml(false)}]{text}[/color]" : text);
        }

        return builder.ToString();
    }

    private static List<string> Tokenize(string command)
    {
        var tokens = new List<string>();
        var current = new StringBuilder();
        var quote = '\0';
        foreach (var character in command)
        {
            if (quote != '\0')
            {
                current.Append(character);
                if (character == quote) quote = '\0';
            }
            else if (character is '"' or '\'')
            {
                quote = character;
                current.Append(character);
            }
            else if (char.IsWhiteSpace(character))
            {
                if (current.Length == 0) continue;
                tokens.Add(current.ToString());
                current.Clear();
            }
            else
            {
                current.Append(character);
            }
        }

        if (current.Length > 0) tokens.Add(current.ToString());
        return tokens;
    }

    /// <summary>วงกลมสีฟ้าใส่เลขขั้นตอน</summary>
    public static PanelContainer NumberBubble(int number, int size = 30)
    {
        var pixels = S(size);
        var bubble = new PanelContainer
        {
            CustomMinimumSize = new Vector2(pixels, pixels),
            MouseFilter = Control.MouseFilterEnum.Ignore,
            SizeFlagsVertical = Control.SizeFlags.ShrinkCenter
        };
        bubble.AddThemeStyleboxOverride("panel", GitHubTheme.Box(GitHubTheme.AccentEmphasis, GitHubTheme.AccentEmphasis, pixels / 2, 0));
        var label = Text(number.ToString(CultureInfo.InvariantCulture), Colors.White, 15, bold: true);
        label.HorizontalAlignment = HorizontalAlignment.Center;
        label.VerticalAlignment = VerticalAlignment.Center;
        label.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
        label.SizeFlagsVertical = Control.SizeFlags.ExpandFill;
        bubble.AddChild(label);
        return bubble;
    }

    /// <summary>การ์ดขั้นตอน: เลขวงกลม หัวข้อ คำอธิบายสั้นๆ ชิดขวา ตามด้วยเนื้อหา (เช่น บล็อกคำสั่ง)</summary>
    public static PanelContainer Step(int number, string title, string? hint, Control body)
    {
        var card = Card(20, 16);
        var column = new VBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        column.AddThemeConstantOverride("separation", S(12));

        var header = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        header.AddThemeConstantOverride("separation", S(12));
        header.AddChild(NumberBubble(number));
        header.AddChild(Text(title, GitHubTheme.Fg, 18, bold: true));
        if (hint is not null)
        {
            header.AddChild(Spacer());
            header.AddChild(Text(hint, GitHubTheme.FgMuted, 14));
        }

        column.AddChild(header);
        column.AddChild(body);
        card.AddChild(column);
        return card;
    }

    public static Control EmptyState(GhIcon icon, string title, string hint)
    {
        var (panel, body) = Box();
        var column = new VBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass, SizeFlagsHorizontal = Control.SizeFlags.ExpandFill };
        column.AddThemeConstantOverride("separation", S(10));
        var glyph = Icon(icon, GitHubTheme.FgMuted, 32);
        glyph.SizeFlagsHorizontal = Control.SizeFlags.ShrinkCenter;
        column.AddChild(glyph);
        var heading = Text(title, GitHubTheme.Fg, 20, bold: true);
        heading.HorizontalAlignment = HorizontalAlignment.Center;
        heading.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
        column.AddChild(heading);
        var detail = Text(hint, GitHubTheme.FgMuted, 15, wrap: true);
        detail.HorizontalAlignment = HorizontalAlignment.Center;
        column.AddChild(detail);

        var margin = new MarginContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        margin.AddThemeConstantOverride("margin_top", S(40));
        margin.AddThemeConstantOverride("margin_bottom", S(40));
        margin.AddThemeConstantOverride("margin_left", S(24));
        margin.AddThemeConstantOverride("margin_right", S(24));
        margin.AddChild(column);
        body.AddChild(margin);
        return panel;
    }

    /// <summary>แท็บแบบ GitHub: ขีดส้มใต้แท็บที่เลือก มีไอคอนและตัวเลขนับได้</summary>
    public static PanelContainer Tab(string text, bool active, Action onClick, GhIcon? icon = null, int? counter = null)
    {
        var tab = new PanelContainer
        {
            MouseFilter = Control.MouseFilterEnum.Pass,
            MouseDefaultCursorShape = Control.CursorShape.PointingHand
        };
        StyleBoxFlat Style(bool hover) => GitHubTheme.Underlined(
            hover && !active ? new Color(1f, 1f, 1f, 0.05f) : Colors.Transparent,
            active ? GitHubTheme.TabUnderline : Colors.Transparent, 2, 12, 8);

        tab.AddThemeStyleboxOverride("panel", Style(false));
        tab.MouseEntered += () => tab.AddThemeStyleboxOverride("panel", Style(true));
        tab.MouseExited += () => tab.AddThemeStyleboxOverride("panel", Style(false));
        tab.GuiInput += input =>
        {
            if (input is InputEventMouseButton { Pressed: true, ButtonIndex: MouseButton.Left })
            {
                tab.AcceptEvent();
                onClick();
            }
        };

        var row = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Ignore };
        row.AddThemeConstantOverride("separation", S(8));
        if (icon is { } glyph) row.AddChild(Icon(glyph, active ? GitHubTheme.Fg : GitHubTheme.FgMuted));
        row.AddChild(Text(text, GitHubTheme.Fg, 15, bold: active));
        if (counter is { } count) row.AddChild(Counter(count));
        tab.AddChild(row);
        return tab;
    }

    /// <summary>แสดงโค้ดทีละบรรทัดพร้อมเลขบรรทัด (หน้าเปิดไฟล์) จำกัดจำนวนบรรทัดเพื่อไม่ให้หน้าหนัก</summary>
    public static Control CodeLines(IReadOnlyList<string> lines, int max = 500)
    {
        var column = new VBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass, SizeFlagsHorizontal = Control.SizeFlags.ExpandFill };
        column.AddThemeConstantOverride("separation", S(0));
        for (var index = 0; index < Math.Min(lines.Count, max); index++)
        {
            var row = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
            row.AddThemeConstantOverride("separation", S(16));
            var number = Text((index + 1).ToString(CultureInfo.InvariantCulture), GitHubTheme.FgSubtle, 13, mono: true);
            number.CustomMinimumSize = new Vector2(S(48), 0);
            number.HorizontalAlignment = HorizontalAlignment.Right;
            row.AddChild(number);
            var code = Text(lines[index], GitHubTheme.Fg, 14, mono: true);
            code.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
            code.ClipText = true;
            row.AddChild(code);
            column.AddChild(row);
        }

        if (lines.Count > max)
            column.AddChild(Text($"… ไฟล์ยาว {lines.Count} บรรทัด แสดงเฉพาะ {max} บรรทัดแรก", GitHubTheme.FgMuted, 14));
        return column;
    }

    public static string TimeAgo(DateTimeOffset when)
    {
        var span = DateTimeOffset.Now - when;
        if (span.TotalSeconds < 60) return "just now";
        if (span.TotalMinutes < 60) return Ago((int)span.TotalMinutes, "minute");
        if (span.TotalHours < 24) return Ago((int)span.TotalHours, "hour");
        if (span.TotalDays < 30) return Ago((int)span.TotalDays, "day");
        return when.ToString("MMM d, yyyy", CultureInfo.InvariantCulture);
    }

    public static string DateLabel(DateTimeOffset when) => when.ToString("MMM d, yyyy", CultureInfo.InvariantCulture);

    /// <summary>เอกพจน์/พหูพจน์แบบ GitHub เช่น "1 Commit" / "2 Commits"</summary>
    public static string Count(int number, string singular, string plural) =>
        $"{number} {(number == 1 ? singular : plural)}";

    private static string Ago(int number, string unit) => $"{number} {unit}{(number == 1 ? string.Empty : "s")} ago";
}
