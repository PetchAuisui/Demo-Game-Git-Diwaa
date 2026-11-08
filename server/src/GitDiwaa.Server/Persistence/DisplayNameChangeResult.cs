namespace GitDiwaa.Server.Persistence;

public enum DisplayNameChangeResult
{
    Unknown = 0,
    Changed = 1,
    UserNotFound = 2,
    DisplayNameTaken = 3,
    CooldownActive = 4
}

/// <summary>
/// ผลของ TryChangeDisplayNameAsync: User คือข้อมูลล่าสุดของผู้ใช้ (null ถ้าไม่พบผู้ใช้)
/// </summary>
public sealed record DisplayNameChangeOutcome(DisplayNameChangeResult Result, UserRecord? User);
