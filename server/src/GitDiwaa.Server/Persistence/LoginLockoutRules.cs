namespace GitDiwaa.Server.Persistence;

/// <summary>
/// กติกาพักการล็อกอินหลังใส่รหัสผิด (ค่ามาจาก AccountOptions)
/// MaxPerClient  ใส่ผิดกี่ครั้งจากต้นทางเดียวกัน (IP) ถึงพักเฉพาะต้นทางนั้น คนอื่นแกล้งล็อกบัญชีเราจากเน็ตอื่นไม่ได้
/// MaxPerAccount ใส่ผิดรวมกันจากทุกต้นทางกี่ครั้งถึงพักทั้งบัญชี กันการเดารหัสโดยสลับ IP ไปเรื่อยๆ
/// </summary>
public readonly record struct LoginLockoutRules(int MaxPerClient, int MaxPerAccount, TimeSpan LockoutDuration);
