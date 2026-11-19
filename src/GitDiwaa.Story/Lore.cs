using GitDiwaa.Core.Game;

namespace GitDiwaa.Story;

/// <summary>Shared world data and setup helpers for floor scripts.</summary>
public static class Lore
{
    public const string Master = "ปรมาจารย์";
    public const string Miura = "มิวรา";
    public const string Guardian = "ผู้พิทักษ์คลังเวท";

    /// <summary>
    /// Each fragment carries one phrase of the master's last message. Collecting them
    /// slowly reveals it — a curiosity hook that is not a score.
    /// </summary>
    public static readonly IReadOnlyList<Fragment> Fragments =
    [
        new(1, "เศษคัมภีร์แห่งการเริ่มต้น", "\"ศิษย์ของข้า…\""),
        new(2, "เศษคัมภีร์แห่งการจารึก", "\"ความรู้ที่ไม่ถูกจารึก\""),
        new(3, "เศษคัมภีร์แห่งความทรงจำ", "\"ย่อมสูญหายไปกับกาลเวลา\""),
        new(4, "เศษคัมภีร์แห่งการเทียบรอย", "\"จงสังเกตทุกรอยที่เปลี่ยนไป\""),
        new(5, "เศษคัมภีร์แห่งการฟื้นคืน", "\"ความผิดพลาดแก้ไขได้เสมอ\""),
        new(6, "เศษคัมภีร์แห่งกาลเวลา", "\"หากเจ้ากล้าย้อนกลับไปมอง\""),
        new(7, "เศษคัมภีร์แห่งรอยแยก", "\"เส้นทางมีมากกว่าหนึ่งเสมอ\""),
        new(8, "เศษคัมภีร์แห่งประตูมิติ", "\"จงกล้าลองในโลกคู่ขนาน\""),
        new(9, "เศษคัมภีร์แห่งการหลอมรวม", "\"แล้วนำสิ่งที่ดีที่สุดกลับมารวมกัน\""),
        new(10, "เศษคัมภีร์แห่งแสงสว่าง", "\"ความรู้ที่ไม่ถูกแบ่งปัน\""),
        new(11, "เศษคัมภีร์แห่งการเรียกหา", "\"ย่อมดับไปพร้อมผู้ครอบครอง\""),
        new(12, "เศษคัมภีร์แห่งการส่งต่อ", "\"ข้ารอเจ้าอยู่ที่คลังเวทกลาง\""),
    ];

    public static Fragment Fragment(int n) => Fragments[n - 1];

    public const string ApprenticeEmail = "apprentice@tower.diwaa";

    /// <summary>Gives the sandbox the player's identity (floors after 1 assume it is already registered).</summary>
    public static async Task BlessAsync(FloorContext ctx)
    {
        await ctx.Git("config", "--global", "user.name", ctx.PlayerName);
        await ctx.Git("config", "--global", "user.email", ApprenticeEmail);
    }

    /// <summary>Creates a tome on the desk and inscribes the given pages as someone else (or the player).</summary>
    public static async Task SeedTomeAsync(FloorContext ctx, params Page[] pages)
    {
        await ctx.Git("init", "-q");
        foreach (var page in pages)
            await InscribeAsync(ctx, page);
    }

    public static async Task InscribeAsync(FloorContext ctx, Page page, string? npc = null)
    {
        foreach (var (path, content) in page.Files)
        {
            if (npc is null) await ctx.Files.WriteAllTextAsync(path, content);
            else await ctx.Author.WriteNpcFileAsync(npc, path, content);
        }
        if (page.Files.Count > 0) await ctx.Author.RunGitAsync(["add", "-A"], npc);
        await ctx.CommitAs(page.Author ?? ctx.PlayerName, page.Message, npc, page.Date);
    }

    public static async Task StageAsync(FloorContext ctx, params string[] paths) =>
        await ctx.Git(["add", "--", .. paths]);
}

public sealed record Page(string Message, IReadOnlyDictionary<string, string> Files, string? Author = null, string Date = "2025-01-01T09:00:00+07:00")
{
    public static Page Of(string message, string? author = null, string date = "2025-01-01T09:00:00+07:00", params (string Path, string Content)[] files) =>
        new(message, files.ToDictionary(f => f.Path, f => f.Content), author, date);
}

public static class Spells
{
    // Cumulative spell unlocks per floor (contextual spellbook).
    public static readonly string[] F1 = ["version", "config"];
    public static readonly string[] F2 = [.. F1, "init"];
    public static readonly string[] F3 = [.. F2, "status"];
    public static readonly string[] F4 = [.. F3, "add"];
    public static readonly string[] F5 = [.. F4, "commit"];
    public static readonly string[] F6 = [.. F5, "log", "show"];
    public static readonly string[] F7 = [.. F6, "diff"];
    public static readonly string[] F8 = [.. F7, "restore"];
    public static readonly string[] F9 = [.. F8, "reset"];
    public static readonly string[] F10 = [.. F9, "branch"];
    public static readonly string[] F11 = [.. F10, "switch"];
    public static readonly string[] F12 = [.. F11, "merge"];
    public static readonly string[] F13 = [.. F12, "clone", "remote"];
    public static readonly string[] F14 = [.. F13, "fetch", "pull"];
    public static readonly string[] F15 = [.. F14, "push"];
}
