using Godot;

namespace GitDiwaa.Godot.Common;

/// <summary>
/// สีและสไตล์แบบ GitHub (dark) สำหรับหน้า Remote Repository จำลอง
/// สร้าง <see cref="Theme"/> ชุดเดียวให้ทุกปุ่ม ช่องกรอก เมนู และแถบเลื่อนในหน้านั้น
/// </summary>
public static class GitHubTheme
{
    /// <summary>
    /// อัตราขยายของทั้งหน้า: เกมตั้งฟอนต์เริ่มต้นไว้ 24 ส่วนขนาดแบบ GitHub จริงอยู่ที่ 14–16
    /// จึงคูณทุกขนาด (ตัวอักษร ไอคอน ช่องไฟ) ด้วยค่านี้ ให้อ่านสบายเท่ากับ UI ส่วนอื่นของเกม
    /// </summary>
    public const float UiScale = 1.35f;

    public static int S(int pixels) => Mathf.RoundToInt(pixels * UiScale);

    public static float S(float pixels) => pixels * UiScale;

    // พื้นผิวเป็นชั้นๆ: แถบบน/ช่องกรอก/บล็อกโค้ด (เข้มสุด) < พื้นหน้า < การ์ด < หัวการ์ดและแถวที่ชี้
    public static readonly Color Backdrop = new(0.004f, 0.016f, 0.035f, 0.97f);
    public static readonly Color Inset = new("#05070a");
    public static readonly Color Canvas = new("#0a0d12");
    public static readonly Color Surface = new("#11161d");
    public static readonly Color SurfaceRaised = new("#1a212b");
    public static readonly Color Border = new("#3d444d");
    public static readonly Color BorderMuted = new("#2b323b");

    // ตัวอักษร (สว่างกว่า GitHub เดิมเล็กน้อย ให้อ่านบนพื้นเข้มได้ชัด)
    public static readonly Color Fg = new("#f0f6fc");
    public static readonly Color FgMuted = new("#9ba5b0");
    public static readonly Color FgSubtle = new("#7d8590");

    // สีสถานะ
    public static readonly Color Accent = new("#4493f8");
    public static readonly Color AccentHover = new("#79b8ff");
    public static readonly Color AccentEmphasis = new("#1f6feb");
    public static readonly Color AccentSubtle = new("#12233b");
    public static readonly Color Success = new("#3fb950");
    public static readonly Color SuccessEmphasis = new("#238636");
    public static readonly Color SuccessSubtle = new("#12261e");
    public static readonly Color Danger = new("#f85149");
    public static readonly Color DangerEmphasis = new("#da3633");
    public static readonly Color DangerSubtle = new("#25171c");
    public static readonly Color Attention = new("#d29922");
    public static readonly Color Done = new("#a371f7");
    public static readonly Color DoneEmphasis = new("#8957e5");
    public static readonly Color TabUnderline = new("#f78166");

    // สีไล่คำสั่งในบล็อกโค้ด
    public static readonly Color SyntaxSubcommand = new("#7ee787");
    public static readonly Color SyntaxFlag = new("#ffa657");
    public static readonly Color SyntaxString = new("#a5d6ff");
    public static readonly Color SyntaxPath = new("#79c0ff");
    public static readonly Color SyntaxGame = new("#d2a8ff");

    // diff
    public static readonly Color DiffAdd = new("#12261e");
    public static readonly Color DiffAddGutter = new("#173c24");
    public static readonly Color DiffRemove = new("#25171c");
    public static readonly Color DiffRemoveGutter = new("#532426");
    public static readonly Color DiffHunk = new("#132339");

    // ชื่อ theme type variation ของปุ่ม
    public const string PrimaryButton = "GhPrimaryButton";
    public const string DangerButton = "GhDangerButton";
    public const string LinkButton = "GhLinkButton";
    public const string GhostButton = "GhGhostButton";

    private static Font? _mono;
    private static Font? _bold;

    public static Font MonoFont => _mono ??= new SystemFont
    {
        FontNames = ["Menlo", "Consolas", "DejaVu Sans Mono", "monospace"]
    };

    public static Font BoldFont => _bold ??= new FontVariation
    {
        BaseFont = ThemeDB.FallbackFont,
        VariationEmbolden = 0.35f
    };

    /// <summary>กล่องพื้นหลังมีเส้นขอบรอบด้าน</summary>
    public static StyleBoxFlat Box(Color bg, Color border, int radius = 8, int borderWidth = 1, float padH = 0, float padV = 0)
    {
        var box = new StyleBoxFlat { BgColor = bg, BorderColor = border };
        box.SetBorderWidthAll(borderWidth);
        box.SetCornerRadiusAll(radius);
        box.ContentMarginLeft = S(padH) + borderWidth;
        box.ContentMarginRight = S(padH) + borderWidth;
        box.ContentMarginTop = S(padV) + borderWidth;
        box.ContentMarginBottom = S(padV) + borderWidth;
        return box;
    }

    /// <summary>แถบที่มีเส้นเฉพาะด้านล่าง (หัวตาราง แถวรายการ แท็บ)</summary>
    public static StyleBoxFlat Underlined(Color bg, Color line, int lineWidth, float padH, float padTop, float? padBottom = null)
    {
        return new StyleBoxFlat
        {
            BgColor = bg,
            BorderColor = line,
            BorderWidthBottom = lineWidth,
            ContentMarginLeft = S(padH),
            ContentMarginRight = S(padH),
            ContentMarginTop = S(padTop),
            ContentMarginBottom = S(padBottom ?? padTop) + lineWidth
        };
    }

    public static Theme Create()
    {
        var theme = new Theme { DefaultFontSize = S(15) };
        theme.SetColor("font_color", "Label", Fg);

        // ปุ่มทั่วไป
        foreach (var type in new[] { "Button", "OptionButton" })
        {
            SetButton(theme, type,
                Box(new("#212832"), new("#4a525c"), 8, 1, 14, 5),
                Box(new("#2c3440"), new("#9ba5b0"), 8, 1, 14, 5),
                Box(new("#252c36"), new("#9ba5b0"), 8, 1, 14, 5),
                Box(new("#1a2029"), new("#343b45"), 8, 1, 14, 5),
                Fg, Fg, new("#484f58"));
            theme.SetConstant("h_separation", type, S(6));
            theme.SetConstant("icon_max_width", type, S(16));
        }

        // ปุ่มหลักสีเขียว
        theme.SetTypeVariation(PrimaryButton, "Button");
        SetButton(theme, PrimaryButton,
            Box(SuccessEmphasis, new("#2ea043"), 8, 1, 14, 5),
            Box(new("#2ea043"), new("#3fb950"), 8, 1, 14, 5),
            Box(new("#1f7a2f"), new("#2ea043"), 8, 1, 14, 5),
            Box(new(0.137f, 0.525f, 0.212f, 0.45f), new(0.18f, 0.63f, 0.26f, 0.3f), 8, 1, 14, 5),
            Colors.White, Colors.White, new(1f, 1f, 1f, 0.5f));

        // ปุ่มอันตราย (ตัวแดง โฮเวอร์แล้วเป็นพื้นแดง)
        theme.SetTypeVariation(DangerButton, "Button");
        SetButton(theme, DangerButton,
            Box(new("#21262d"), new("#363b42"), 8, 1, 14, 5),
            Box(DangerEmphasis, Danger, 8, 1, 14, 5),
            Box(new("#b62324"), Danger, 8, 1, 14, 5),
            Box(new("#21262d"), new("#30363d"), 8, 1, 14, 5),
            Danger, Colors.White, new("#484f58"));

        // ปุ่มลิงก์ (ข้อความสีฟ้า ไม่มีกรอบ)
        theme.SetTypeVariation(LinkButton, "Button");
        var plain = Box(Colors.Transparent, Colors.Transparent, 0, 0);
        SetButton(theme, LinkButton, plain, plain, plain, plain, Accent, AccentHover, FgSubtle);

        // ปุ่มโปร่งใส (ปุ่มไอคอน/ลิงก์รอง) โฮเวอร์แล้วมีพื้น
        theme.SetTypeVariation(GhostButton, "Button");
        SetButton(theme, GhostButton,
            Box(Colors.Transparent, Colors.Transparent, 8, 0, 8, 4),
            Box(new(0.23f, 0.26f, 0.31f, 0.7f), Colors.Transparent, 8, 0, 8, 4),
            Box(new(0.23f, 0.26f, 0.31f, 1f), Colors.Transparent, 8, 0, 8, 4),
            Box(Colors.Transparent, Colors.Transparent, 8, 0, 8, 4),
            FgMuted, Fg, FgSubtle);

        // ช่องกรอก
        foreach (var type in new[] { "LineEdit", "TextEdit" })
        {
            theme.SetStylebox("normal", type, Box(Inset, Border, 8, 1, 12, 5));
            theme.SetStylebox("focus", type, FocusRing());
            theme.SetStylebox("read_only", type, Box(Inset, Border, 8, 1, 12, 5));
            theme.SetColor("font_color", type, Fg);
            theme.SetColor("font_readonly_color", type, Fg);
            theme.SetColor("font_uneditable_color", type, Fg);
            theme.SetColor("font_placeholder_color", type, FgSubtle);
            theme.SetColor("caret_color", type, Fg);
            theme.SetColor("selection_color", type, new(AccentEmphasis, 0.45f));
        }

        // เมนูตัวเลือก (เช่น เลือก branch)
        theme.SetStylebox("panel", "PopupMenu", Box(SurfaceRaised, Border, 8, 1, 4, 4));
        theme.SetStylebox("hover", "PopupMenu", Box(new("#2c3440"), Colors.Transparent, 8, 0, 8, 4));
        theme.SetStylebox("separator", "PopupMenu", new StyleBoxLine { Color = Border, Thickness = 1 });
        theme.SetColor("font_color", "PopupMenu", Fg);
        theme.SetColor("font_hover_color", "PopupMenu", Fg);
        theme.SetColor("font_disabled_color", "PopupMenu", FgSubtle);
        theme.SetConstant("v_separation", "PopupMenu", S(8));
        theme.SetConstant("icon_max_width", "PopupMenu", S(16));

        // แถบเลื่อนบางๆ
        foreach (var type in new[] { "VScrollBar", "HScrollBar" })
        {
            var vertical = type[0] == 'V';
            theme.SetStylebox("scroll", type, Thumb(Colors.Transparent, vertical));
            theme.SetStylebox("scroll_focus", type, Thumb(Colors.Transparent, vertical));
            theme.SetStylebox("grabber", type, Thumb(new("#484f58"), vertical));
            theme.SetStylebox("grabber_highlight", type, Thumb(new("#6e7681"), vertical));
            theme.SetStylebox("grabber_pressed", type, Thumb(new("#8b949e"), vertical));
        }

        // เส้นคั่น
        foreach (var type in new[] { "HSeparator", "VSeparator" })
        {
            theme.SetStylebox("separator", type, new StyleBoxLine { Color = Border, Thickness = 1, Vertical = type[0] == 'V' });
            theme.SetConstant("separation", type, 1);
        }

        theme.SetColor("default_color", "RichTextLabel", Fg);
        theme.SetColor("selection_color", "RichTextLabel", new(AccentEmphasis, 0.45f));
        return theme;
    }

    private static StyleBoxFlat FocusRing()
    {
        var ring = Box(Colors.Transparent, AccentEmphasis, 8, 1, 12, 5);
        ring.DrawCenter = false;
        return ring;
    }

    private static StyleBoxFlat Thumb(Color color, bool vertical)
    {
        var box = new StyleBoxFlat { BgColor = color };
        box.SetCornerRadiusAll(5);
        box.ContentMarginLeft = vertical ? S(5) : 0;
        box.ContentMarginRight = vertical ? S(5) : 0;
        box.ContentMarginTop = vertical ? 0 : S(5);
        box.ContentMarginBottom = vertical ? 0 : S(5);
        return box;
    }

    private static void SetButton(
        Theme theme, string type,
        StyleBox normal, StyleBox hover, StyleBox pressed, StyleBox disabled,
        Color fg, Color fgHover, Color fgDisabled)
    {
        theme.SetStylebox("normal", type, normal);
        theme.SetStylebox("hover", type, hover);
        theme.SetStylebox("pressed", type, pressed);
        theme.SetStylebox("hover_pressed", type, pressed);
        theme.SetStylebox("disabled", type, disabled);
        theme.SetStylebox("focus", type, new StyleBoxEmpty());
        theme.SetColor("font_color", type, fg);
        theme.SetColor("font_focus_color", type, fg);
        theme.SetColor("font_hover_color", type, fgHover);
        theme.SetColor("font_pressed_color", type, fgHover);
        theme.SetColor("font_hover_pressed_color", type, fgHover);
        theme.SetColor("font_disabled_color", type, fgDisabled);
    }
}
