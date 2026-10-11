namespace GitDiwaa.RealGit;

public sealed record SeedCommit(
    string Branch,
    string Author,
    string Message,
    DateTimeOffset Date,
    IReadOnlyDictionary<string, string> Files);

/// <summary>ประวัติเริ่มต้นของ GitHub จำลองต่อด่าน</summary>
public sealed record RemoteSeed(
    string Owner,
    string Name,
    string Description,
    IReadOnlyList<SeedCommit> Commits)
{
    public string CloneUrl => $"https://github.com/{Owner}/{Name}.git";

    /// <summary>repo ตัวอย่างตามหน้า Figma: Preeyaporn / Khamphi_Projects_one</summary>
    public static RemoteSeed Khamphi(DateTimeOffset now) => new(
        "Preeyaporn",
        "Khamphi_Projects_one",
        "Diwaa realm repository",
        [
            new("main", "Preeyaporn", "Initial commit: add core spellcraft engine and scripts",
                now.AddDays(-2),
                new Dictionary<string, string>
                {
                    ["README.md"] = "# Khamphi_Projects_one\n\nWelcome to the Diwaa realm repository.\n",
                    ["spellcraft.py"] = "print('spellcraft engine')\n"
                }),
            new("main", "Preeyaporn", "Update documentation for mystical rituals",
                now.AddDays(-2).AddHours(3),
                new Dictionary<string, string>
                {
                    ["README.md"] = "# Khamphi_Projects_one\n\nWelcome to the Diwaa realm repository.\nSee rituals.md.\n",
                    ["rituals.md"] = "# Rituals\n"
                }),
            new("feature/ward-spell", "Muira", "Add ward spell draft",
                now.AddDays(-1),
                new Dictionary<string, string> { ["ward.py"] = "print('ward')\n" })
        ]);
}
