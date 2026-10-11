namespace GitDiwaa.RealGit;

public sealed record SeedCommit(
    string Branch,
    string Author,
    string Message,
    DateTimeOffset Date,
    IReadOnlyDictionary<string, string> Files);

/// <summary>สถานะเริ่มต้นของ GitHub จำลอง: เจ้าของ ชื่อ repo และประวัติที่มีอยู่แล้ว (ถ้ามี)</summary>
public sealed record RemoteSeed(
    string Owner,
    string Name,
    string Description,
    IReadOnlyList<SeedCommit> Commits)
{
    public const string DefaultOwner = "user";
    public const string DefaultName = "my-project";

    public string CloneUrl => $"https://github.com/{Owner}/{Name}.git";

    /// <summary>repo ว่างที่ผู้เล่นเป็นเจ้าของ ต้อง push งานขึ้นไปเอง</summary>
    public static RemoteSeed Empty(string owner = DefaultOwner, string name = DefaultName) =>
        new(owner, name, string.Empty, []);
}
