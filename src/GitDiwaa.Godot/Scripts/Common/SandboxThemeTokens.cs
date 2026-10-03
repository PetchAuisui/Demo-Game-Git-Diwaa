using Godot;

namespace GitDiwaa.Godot.Common;

/// <summary>
/// Design tokens and styling helpers for Git-Diwaa Sandbox UI.
/// Encapsulates colors, StyleBoxes, and theme constants in a reusable OOP fashion.
/// </summary>
public static class SandboxThemeTokens
{
    // Color Palette
    public static readonly Color BackgroundDark = new(0.06f, 0.07f, 0.10f, 0.95f);      // #0f121a
    public static readonly Color PanelBackground = new(0.08f, 0.09f, 0.13f, 0.92f);     // #141721
    public static readonly Color TerminalBackground = new(0.06f, 0.06f, 0.09f, 0.98f);  // #0f0f17
    public static readonly Color BorderGold = new(0.90f, 0.66f, 0.24f, 1.0f);           // #e6a83d
    public static readonly Color BorderSubtle = new(0.23f, 0.26f, 0.38f, 1.0f);         // #3b4261
    public static readonly Color BorderFocus = new(0.38f, 0.55f, 0.95f, 1.0f);          // #608cf2

    // Text Colors
    public static readonly Color TextPrimary = new(0.95f, 0.96f, 0.98f, 1.0f);          // #f2f5fa
    public static readonly Color TextSecondary = new(0.60f, 0.64f, 0.72f, 1.0f);        // #99a3b8
    public static readonly Color TextGold = new(0.96f, 0.77f, 0.33f, 1.0f);             // #f5c454
    public static readonly Color TextGreen = new(0.29f, 0.87f, 0.50f, 1.0f);            // #4ade80
    public static readonly Color TextCyan = new(0.22f, 0.74f, 0.97f, 1.0f);             // #38bdf8
    public static readonly Color TextRed = new(0.97f, 0.44f, 0.44f, 1.0f);              // #f87171

    // Status / Git State Colors
    public static readonly Color StateUntracked = new(0.85f, 0.40f, 0.40f, 1.0f);       // Red/Orange (?)
    public static readonly Color StateModified = new(0.95f, 0.75f, 0.25f, 1.0f);        // Yellow (M)
    public static readonly Color StateAdded = new(0.30f, 0.85f, 0.45f, 1.0f);           // Green (A)
    public static readonly Color StateDeleted = new(0.90f, 0.30f, 0.30f, 1.0f);         // Dark Red (D)
    public static readonly Color StateRenamed = new(0.35f, 0.75f, 0.95f, 1.0f);         // Cyan (R)

    /// <summary>
    /// Creates a styled flat panel box with borders and optional rounding.
    /// </summary>
    public static StyleBoxFlat CreatePanelStyle(
        Color bgColor,
        Color borderColor,
        int borderWidth = 2,
        int cornerRadius = 6,
        int contentMargin = 12)
    {
        var style = new StyleBoxFlat
        {
            BgColor = bgColor,
            BorderColor = borderColor,
            BorderWidthLeft = borderWidth,
            BorderWidthTop = borderWidth,
            BorderWidthRight = borderWidth,
            BorderWidthBottom = borderWidth,
            CornerRadiusTopLeft = cornerRadius,
            CornerRadiusTopRight = cornerRadius,
            CornerRadiusBottomRight = cornerRadius,
            CornerRadiusBottomLeft = cornerRadius,
            ContentMarginLeft = contentMargin,
            ContentMarginTop = contentMargin,
            ContentMarginRight = contentMargin,
            ContentMarginBottom = contentMargin
        };
        return style;
    }

    /// <summary>
    /// Creates a button StyleBox for normal, hover, pressed states.
    /// </summary>
    public static StyleBoxFlat CreateButtonStyle(
        Color bgColor,
        Color borderColor,
        int borderWidth = 1,
        int cornerRadius = 4)
    {
        return new StyleBoxFlat
        {
            BgColor = bgColor,
            BorderColor = borderColor,
            BorderWidthLeft = borderWidth,
            BorderWidthTop = borderWidth,
            BorderWidthRight = borderWidth,
            BorderWidthBottom = borderWidth,
            CornerRadiusTopLeft = cornerRadius,
            CornerRadiusTopRight = cornerRadius,
            CornerRadiusBottomRight = cornerRadius,
            CornerRadiusBottomLeft = cornerRadius,
            ContentMarginLeft = 10,
            ContentMarginTop = 6,
            ContentMarginRight = 10,
            ContentMarginBottom = 6
        };
    }
}
