using Godot;

namespace GitDiwaa.Godot.Common;

/// <summary>
/// Design tokens and styling helpers matching the authentic Git-Diwaa theme.
/// </summary>
public static class SandboxThemeTokens
{
    // Authentic Colors from Checkpoint01.tscn
    public static readonly Color TopBarBg = new(0.18f, 0.13f, 0.08f, 0.96f);
    public static readonly Color TopBarBorder = new(0.91f, 0.69f, 0.27f, 1.0f);

    public static readonly Color CardBg = new(0.025f, 0.031f, 0.055f, 0.9f);
    public static readonly Color CardBorder = new(0.37f, 0.42f, 0.67f, 0.9f);

    public static readonly Color TerminalBg = new(0.008f, 0.011f, 0.019f, 0.97f);
    public static readonly Color TerminalBorder = new(0.94f, 0.68f, 0.25f, 1.0f);

    public static readonly Color InputBg = new(0.03f, 0.04f, 0.065f, 1.0f);
    public static readonly Color ButtonBg = new(0.12f, 0.14f, 0.23f, 0.96f);
    public static readonly Color ButtonBorder = new(0.48f, 0.53f, 0.78f, 1.0f);

    // Text Colors
    public static readonly Color GoldTitle = new(1.0f, 0.79f, 0.35f, 1.0f);
    public static readonly Color BrandText = new(1.0f, 0.96f, 0.83f, 1.0f);
    public static readonly Color LevelGreen = new(0.7f, 1.0f, 0.67f, 1.0f);
    public static readonly Color PromptGreen = new(0.31f, 0.95f, 0.62f, 1.0f);
    public static readonly Color SubtitleText = new(0.68f, 0.73f, 0.85f, 1.0f);
    public static readonly Color TextSecondary = new(0.60f, 0.64f, 0.72f, 1.0f);
    public static readonly Color PrimaryText = new(0.87f, 0.90f, 0.95f, 1.0f);
    public static readonly Color ErrorText = new(0.98f, 0.40f, 0.48f, 1.0f);

    // Git File State Colors
    public static readonly Color StateUntracked = new(0.98f, 0.40f, 0.48f, 1.0f);
    public static readonly Color StateModified = new(1.0f, 0.79f, 0.35f, 1.0f);
    public static readonly Color StateAdded = new(0.31f, 0.95f, 0.62f, 1.0f);
    public static readonly Color StateDeleted = new(0.85f, 0.30f, 0.30f, 1.0f);
    public static readonly Color StateRenamed = new(0.35f, 0.75f, 0.95f, 1.0f);

    public static StyleBoxFlat CreateCardStyle() => new()
    {
        BgColor = CardBg,
        BorderColor = CardBorder,
        BorderWidthLeft = 3,
        BorderWidthTop = 3,
        BorderWidthRight = 3,
        BorderWidthBottom = 3,
        CornerRadiusTopLeft = 12,
        CornerRadiusTopRight = 12,
        CornerRadiusBottomRight = 12,
        CornerRadiusBottomLeft = 12,
        ContentMarginLeft = 18,
        ContentMarginTop = 18,
        ContentMarginRight = 18,
        ContentMarginBottom = 18
    };

    public static StyleBoxFlat CreateTerminalStyle() => new()
    {
        BgColor = TerminalBg,
        BorderColor = TerminalBorder,
        BorderWidthLeft = 5,
        BorderWidthTop = 5,
        BorderWidthRight = 5,
        BorderWidthBottom = 5,
        CornerRadiusTopLeft = 12,
        CornerRadiusTopRight = 12,
        CornerRadiusBottomRight = 12,
        CornerRadiusBottomLeft = 12,
        ContentMarginLeft = 27,
        ContentMarginTop = 21,
        ContentMarginRight = 27,
        ContentMarginBottom = 21
    };

    public static StyleBoxFlat CreateInputStyle() => new()
    {
        BgColor = InputBg,
        CornerRadiusTopLeft = 9,
        CornerRadiusTopRight = 9,
        CornerRadiusBottomRight = 9,
        CornerRadiusBottomLeft = 9,
        ContentMarginLeft = 18,
        ContentMarginRight = 18
    };

    public static StyleBoxFlat CreateButtonStyle() => new()
    {
        BgColor = ButtonBg,
        BorderColor = ButtonBorder,
        BorderWidthLeft = 2,
        BorderWidthTop = 2,
        BorderWidthRight = 2,
        BorderWidthBottom = 2,
        CornerRadiusTopLeft = 9,
        CornerRadiusTopRight = 9,
        CornerRadiusBottomRight = 9,
        CornerRadiusBottomLeft = 9,
        ContentMarginLeft = 21,
        ContentMarginRight = 21
    };

    public static SystemFont CreateTerminalFont() => new()
    {
        FontNames = new[] { "Menlo", "Consolas", "DejaVu Sans Mono" }
    };
}
