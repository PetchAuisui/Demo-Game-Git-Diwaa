using System.Globalization;
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

/// <summary>ชิ้นส่วน UI แบบ GitHub ที่ใช้ซ้ำในหน้า Remote Repository</summary>
public static class GitHubUi
{
    private static readonly string[] AvatarColors =
        ["#1f6feb", "#8957e5", "#238636", "#9e6a03", "#da3633", "#0b7285", "#bf3989"];

    public static Control Spacer() => new()
    {
        SizeFlagsHorizontal = Control.SizeFlags.ExpandFill,
        MouseFilter = Control.MouseFilterEnum.Ignore
    };

    public static Label Text(string text, Color? color = null, int size = 15, bool bold = false, bool mono = false, bool wrap = false)
    {
        var label = new Label { Text = text, MouseFilter = Control.MouseFilterEnum.Ignore };
        label.AddThemeColorOverride("font_color", color ?? GitHubTheme.Fg);
        label.AddThemeFontSizeOverride("font_size", size);
        if (mono) label.AddThemeFontOverride("font", GitHubTheme.MonoFont);
        else if (bold) label.AddThemeFontOverride("font", GitHubTheme.BoldFont);
        if (wrap)
        {
            label.AutowrapMode = TextServer.AutowrapMode.WordSmart;
            label.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
        }

        return label;
    }

    public static TextureRect Icon(GhIcon icon, Color color, int size = 16) => new()
    {
        Texture = GitHubIcons.Get(icon, color, size),
        CustomMinimumSize = new Vector2(size, size),
        ExpandMode = TextureRect.ExpandModeEnum.IgnoreSize,
        StretchMode = TextureRect.StretchModeEnum.KeepAspectCentered,
        MouseFilter = Control.MouseFilterEnum.Ignore,
        SizeFlagsVertical = Control.SizeFlags.ShrinkCenter,
        TextureFilter = CanvasItem.TextureFilterEnum.LinearWithMipmaps
    };

    public static HBoxContainer IconText(GhIcon icon, string text, Color color, int size = 15, bool bold = false)
    {
        var row = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Ignore };
        row.AddThemeConstantOverride("separation", 6);
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
            button.Icon = GitHubIcons.Get(glyph, tint); // texture 2 เท่า ถูกจำกัดกว้าง 16px ด้วย icon_max_width ใน theme
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
        card.AddThemeStyleboxOverride("panel", GitHubTheme.Box(GitHubTheme.Canvas, GitHubTheme.Border, 6, 1, padH, padV));
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
        panel.AddThemeStyleboxOverride("panel", GitHubTheme.Box(GitHubTheme.Canvas, GitHubTheme.Border));
        var body = new VBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        body.AddThemeConstantOverride("separation", 0);
        panel.AddChild(body);
        if (header is not null) body.AddChild(Header(header));
        return (panel, body);
    }

    public static PanelContainer Header(Control content)
    {
        var bar = new PanelContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        var style = GitHubTheme.Underlined(GitHubTheme.CanvasSubtle, GitHubTheme.Border, 1, 16, 10);
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
            hover ? GitHubTheme.CanvasSubtle : Colors.Transparent, GitHubTheme.BorderMuted, last ? 0 : 1, 16, 9);

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

    /// <summary>ชื่อ branch แบบพื้นฟ้าอ่อนอักษร mono เหมือนในหน้า PR</summary>
    public static PanelContainer BranchPill(string name)
    {
        var pill = new PanelContainer { MouseFilter = Control.MouseFilterEnum.Ignore };
        pill.AddThemeStyleboxOverride("panel", GitHubTheme.Box(GitHubTheme.AccentSubtle, Colors.Transparent, 6, 0, 7, 2));
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
        row.AddThemeConstantOverride("separation", 6);
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

    public static PanelContainer Counter(int number)
    {
        var counter = new PanelContainer { MouseFilter = Control.MouseFilterEnum.Ignore, SizeFlagsVertical = Control.SizeFlags.ShrinkCenter };
        counter.AddThemeStyleboxOverride("panel", GitHubTheme.Box(new(0.43f, 0.46f, 0.51f, 0.4f), Colors.Transparent, 10, 0, 7, 0));
        counter.AddChild(Text(number.ToString(CultureInfo.InvariantCulture), GitHubTheme.Fg, 12));
        return counter;
    }

    public static PanelContainer Avatar(string name, int size = 24)
    {
        var index = name.Aggregate(0, (sum, character) => sum + character) % AvatarColors.Length;
        var fill = new Color(AvatarColors[index]);
        var avatar = new PanelContainer
        {
            CustomMinimumSize = new Vector2(size, size),
            MouseFilter = Control.MouseFilterEnum.Ignore,
            SizeFlagsVertical = Control.SizeFlags.ShrinkCenter
        };
        avatar.AddThemeStyleboxOverride("panel", GitHubTheme.Box(fill, fill, size / 2, 0));
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
            error ? GitHubTheme.DangerSubtle : GitHubTheme.SuccessSubtle, new Color(fg, 0.4f), 6, 1, 14, 10));
        var row = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        row.AddThemeConstantOverride("separation", 10);
        row.AddChild(Icon(error ? GhIcon.Alert : GhIcon.Check, fg));
        row.AddChild(Text(message, GitHubTheme.Fg, 15, wrap: true));
        panel.AddChild(row);
        return panel;
    }

    /// <summary>แถบข้อมูลสีฟ้า (คำแนะนำ ไม่ใช่ผลลัพธ์ของการกระทำ)</summary>
    public static PanelContainer Info(string message)
    {
        var panel = new PanelContainer { MouseFilter = Control.MouseFilterEnum.Pass, SizeFlagsHorizontal = Control.SizeFlags.ExpandFill };
        panel.AddThemeStyleboxOverride("panel", GitHubTheme.Box(
            GitHubTheme.AccentSubtle, new Color(GitHubTheme.Accent, 0.4f), 6, 1, 14, 10));
        var row = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        row.AddThemeConstantOverride("separation", 10);
        row.AddChild(Icon(GhIcon.Info, GitHubTheme.Accent));
        row.AddChild(Text(message, GitHubTheme.Fg, 15, wrap: true));
        panel.AddChild(row);
        return panel;
    }

    /// <summary>บล็อกคำสั่งสีเข้มพร้อมปุ่ม Copy ต่อบรรทัด (ผู้เล่นพิมพ์ทีละบรรทัดใน terminal ของเกม)</summary>
    public static PanelContainer CodeBlock(IEnumerable<string> lines)
    {
        var panel = Card(14, 10);
        panel.AddThemeStyleboxOverride("panel", GitHubTheme.Box(GitHubTheme.CanvasSubtle, GitHubTheme.Border, 6, 1, 14, 8));
        var column = new VBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
        column.AddThemeConstantOverride("separation", 2);
        foreach (var line in lines)
        {
            var row = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
            row.AddThemeConstantOverride("separation", 10);
            row.AddChild(Text("$", GitHubTheme.FgSubtle, 14, mono: true));
            var command = Text(line, GitHubTheme.Fg, 14, mono: true);
            command.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
            row.AddChild(command);
            var text = line;
            row.AddChild(Btn(string.Empty, () => DisplayServer.ClipboardSet(text), GhButtonKind.Ghost, GhIcon.Copy));
            column.AddChild(row);
        }

        panel.AddChild(column);
        return panel;
    }

    public static Control EmptyState(GhIcon icon, string title, string hint)
    {
        var (panel, body) = Box();
        var column = new VBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass, SizeFlagsHorizontal = Control.SizeFlags.ExpandFill };
        column.AddThemeConstantOverride("separation", 10);
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
        margin.AddThemeConstantOverride("margin_top", 40);
        margin.AddThemeConstantOverride("margin_bottom", 40);
        margin.AddThemeConstantOverride("margin_left", 24);
        margin.AddThemeConstantOverride("margin_right", 24);
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
        row.AddThemeConstantOverride("separation", 8);
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
        column.AddThemeConstantOverride("separation", 0);
        for (var index = 0; index < Math.Min(lines.Count, max); index++)
        {
            var row = new HBoxContainer { MouseFilter = Control.MouseFilterEnum.Pass };
            row.AddThemeConstantOverride("separation", 16);
            var number = Text((index + 1).ToString(CultureInfo.InvariantCulture), GitHubTheme.FgSubtle, 13, mono: true);
            number.CustomMinimumSize = new Vector2(48, 0);
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
