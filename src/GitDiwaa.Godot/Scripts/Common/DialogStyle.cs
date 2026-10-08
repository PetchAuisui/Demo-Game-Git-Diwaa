using Godot;

namespace GitDiwaa.Godot.Common;

/// <summary>
/// Gives a ConfirmationDialog a heading (glyph + title) and an accent colour
/// so each kind of dialog reads at a glance: red = destructive, orange = unsaved
/// changes, blue = rename, green = commit.
/// </summary>
public static class DialogStyle
{
    public static readonly Color Danger = new(0.94f, 0.36f, 0.36f);
    public static readonly Color Warning = new(1.0f, 0.64f, 0.26f);
    public static readonly Color Info = new(0.46f, 0.72f, 1.0f);
    public static readonly Color Success = new(0.45f, 0.86f, 0.56f);

    /// <summary>Returns the message label (null when no message is wanted).</summary>
    public static Label? Apply(ConfirmationDialog dialog, Color accent, string glyph, string heading,
        bool withMessage, Control? input = null)
    {
        dialog.GetLabel().Visible = false;

        var panel = (StyleBoxFlat)dialog.GetThemeStylebox("panel", "AcceptDialog").Duplicate();
        panel.BorderColor = accent;
        dialog.AddThemeStyleboxOverride("panel", panel);

        var ok = dialog.GetOkButton();
        ok.ThemeTypeVariation = "CreateAction";
        ok.AddThemeStyleboxOverride("normal", Fill(accent));
        ok.AddThemeStyleboxOverride("hover", Fill(accent.Lightened(0.2f)));
        ok.AddThemeStyleboxOverride("pressed", Fill(accent));
        ok.CustomMinimumSize = new Vector2(140, 46);
        dialog.GetCancelButton().CustomMinimumSize = new Vector2(112, 46);

        var margin = new MarginContainer { Name = "Content" };
        margin.AddThemeConstantOverride("margin_left", 4);
        margin.AddThemeConstantOverride("margin_top", 18);
        margin.AddThemeConstantOverride("margin_right", 4);
        margin.AddThemeConstantOverride("margin_bottom", 16);
        var layout = new VBoxContainer();
        layout.AddThemeConstantOverride("separation", 14);
        margin.AddChild(layout);

        var head = new HBoxContainer();
        head.AddThemeConstantOverride("separation", 10);
        var badge = new Label
        {
            Text = glyph,
            CustomMinimumSize = new Vector2(34, 34),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };
        badge.AddThemeColorOverride("font_color", new Color(0.05f, 0.06f, 0.1f));
        badge.AddThemeFontSizeOverride("font_size", 22);
        var badgeStyle = Fill(accent);
        badgeStyle.SetCornerRadiusAll(17);
        badgeStyle.ContentMarginLeft = badgeStyle.ContentMarginRight = 0;
        badgeStyle.ContentMarginTop = badgeStyle.ContentMarginBottom = 0;
        badge.AddThemeStyleboxOverride("normal", badgeStyle);
        head.AddChild(badge);
        var title = new Label { Text = heading };
        title.AddThemeColorOverride("font_color", accent);
        title.AddThemeFontSizeOverride("font_size", 26);
        head.AddChild(title);
        layout.AddChild(head);

        Label? message = null;
        if (withMessage)
        {
            message = new Label
            {
                AutowrapMode = TextServer.AutowrapMode.WordSmart,
                CustomMinimumSize = new Vector2(440, 0),
                SizeFlagsHorizontal = Control.SizeFlags.ExpandFill,
            };
            layout.AddChild(message);
        }

        if (input != null)
        {
            input.GetParent()?.RemoveChild(input);
            input.CustomMinimumSize = new Vector2(0, 48);
            input.SizeFlagsHorizontal = Control.SizeFlags.ExpandFill;
            layout.AddChild(input);
        }

        dialog.AddChild(margin);
        return message;
    }

    private static StyleBoxFlat Fill(Color color)
    {
        var s = new StyleBoxFlat { BgColor = color };
        s.SetCornerRadiusAll(7);
        s.ContentMarginLeft = s.ContentMarginRight = 24;
        s.ContentMarginTop = s.ContentMarginBottom = 10;
        return s;
    }
}
