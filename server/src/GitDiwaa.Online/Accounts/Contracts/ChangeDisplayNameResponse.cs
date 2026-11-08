namespace GitDiwaa.Online.Accounts.Contracts;

/// <summary>
/// ผลการเปลี่ยนชื่อที่แสดง: โปรไฟล์ล่าสุด และเวลาที่จะเปลี่ยนชื่อได้อีกครั้ง (UTC)
/// </summary>
public sealed record ChangeDisplayNameResponse(
    PlayerProfile Profile,
    DateTimeOffset NextChangeAllowedAt);
