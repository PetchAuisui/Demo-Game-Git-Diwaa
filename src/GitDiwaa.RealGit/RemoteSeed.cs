namespace GitDiwaa.RealGit;

public sealed record SeedCommit(
    string Branch,
    string Author,
    string Message,
    DateTimeOffset Date,
    IReadOnlyDictionary<string, string> Files);

/// <summary>
/// กติกา pull request ของ GitHub จำลอง ค่าเริ่มต้นเหมาะกับ sandbox คนเดียว
/// (review เป็นทางเลือกและรีวิว PR ตัวเองได้) ด่านที่ต้องการ code review จริงเปิดโหมดเข้มได้
/// </summary>
public sealed record RemoteRules(bool RequireApproval = false, bool AllowSelfReview = true);

/// <summary>สถานะเริ่มต้นของ GitHub จำลอง: เจ้าของ ชื่อ repo และประวัติที่มีอยู่แล้ว (ถ้ามี)</summary>
public sealed record RemoteSeed(
    string Owner,
    string Name,
    string Description,
    IReadOnlyList<SeedCommit> Commits)
{
    public const string DefaultOwner = "user";
    public const string DefaultName = "my-project";

    public RemoteRules Rules { get; init; } = new();

    /// <summary>true = บัญชีเริ่มต้นโดยไม่มี repo เลย ผู้เล่นต้องสร้างเองผ่านหน้า New repository</summary>
    public bool StartsWithoutRepository { get; init; }

    public string CloneUrl => $"https://github.com/{Owner}/{Name}.git";

    /// <summary>repo ว่างที่ผู้เล่นเป็นเจ้าของ ต้อง push งานขึ้นไปเอง</summary>
    public static RemoteSeed Empty(string owner = DefaultOwner, string name = DefaultName) =>
        new(owner, name, string.Empty, []);

    /// <summary>บัญชีที่ยังไม่มี repo ใดๆ (ชื่อ repo แรกผู้เล่นตั้งเอง)</summary>
    public static RemoteSeed NoRepository(string owner = DefaultOwner) =>
        Empty(owner) with { StartsWithoutRepository = true };
}
