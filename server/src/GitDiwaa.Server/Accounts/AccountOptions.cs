namespace GitDiwaa.Server.Accounts;

public sealed class AccountOptions
{
    public TimeSpan ShortSessionLifetime { get; set; } = TimeSpan.FromHours(12);
    public TimeSpan PersistentSessionLifetime { get; set; } = TimeSpan.FromDays(30);
    public int MaxFailedLoginAttempts { get; set; } = 5;
    public TimeSpan LockoutDuration { get; set; } = TimeSpan.FromMinutes(15);

    // เปลี่ยนชื่อที่แสดงได้ 1 ครั้งต่อช่วงเวลานี้ (กันการเปลี่ยนชื่อไปมาเพื่อสวมรอยหรือหลบการรายงาน)
    public TimeSpan DisplayNameChangeCooldown { get; set; } = TimeSpan.FromDays(14);
}