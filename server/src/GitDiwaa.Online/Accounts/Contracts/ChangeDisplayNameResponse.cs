namespace GitDiwaa.Online.Accounts.Contracts;

/// <summary>
/// สถานะชื่อที่แสดง: โปรไฟล์ล่าสุด, เวลาที่เปลี่ยนชื่อได้อีกครั้ง (UTC) และจำนวนครั้งที่เปลี่ยนได้ตอนนี้
/// </summary>
public sealed record ChangeDisplayNameResponse(
    PlayerProfile Profile,
    DateTimeOffset NextChangeAllowedAt,
    int ChangesAvailable);
