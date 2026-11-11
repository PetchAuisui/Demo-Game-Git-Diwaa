namespace GitDiwaa.Server.Accounts;

public sealed class AccountOptions
{
    public TimeSpan ShortSessionLifetime { get; set; } = TimeSpan.FromHours(12);
    public TimeSpan PersistentSessionLifetime { get; set; } = TimeSpan.FromDays(30);
    // ใส่รหัสผิดกี่ครั้งจากต้นทางเดียวกัน (IP) ถึงพักการล็อกอินของต้นทางนั้นกับบัญชีนี้
    // นับแยกต้นทาง: คนที่รู้ชื่อผู้ใช้ของเราแล้วใส่ผิดรัวๆ จากเน็ตอื่น ล็อกได้แค่ตัวเขาเอง ไม่ใช่เรา
    public int MaxFailedLoginAttempts { get; set; } = 5;
    // ใส่ผิดรวมกันจากทุกต้นทางกี่ครั้งถึงพักทั้งบัญชี (กันการเดารหัสโดยสลับ IP ไปเรื่อยๆ)
    public int MaxFailedLoginAttemptsPerAccount { get; set; } = 20;
    public TimeSpan LockoutDuration { get; set; } = TimeSpan.FromMinutes(15);

    // ช่วงผ่อนผันหลังหมุน token: token ใบเก่าที่เพิ่งถูกแทน เอามา refresh ซ้ำได้ภายในเวลานี้โดยไม่ถือว่าถูกขโมย
    // (คำตอบ refresh หายกลางทางแล้วเกมลองใหม่ / เปิดเกม 2 หน้าต่างที่ใช้ไฟล์จดจำเดียวกัน)
    // เลยช่วงนี้ไปแล้วยังใช้ใบเก่า = ถือว่าถูกขโมย ตัดทุก session ของบัญชี  ตั้งเป็น TimeSpan.Zero = ไม่ผ่อนผันเลย
    public TimeSpan RefreshReuseGracePeriod { get; set; } = TimeSpan.FromSeconds(60);

    // เปลี่ยนชื่อที่แสดงได้ 1 ครั้งต่อช่วงเวลานี้ (กันการเปลี่ยนชื่อไปมาเพื่อสวมรอยหรือหลบการรายงาน)
    public TimeSpan DisplayNameChangeCooldown { get; set; } = TimeSpan.FromDays(14);

    // ไม่รับรหัสผ่านที่เดาง่าย (AccountInputValidator.ValidatePasswordStrength) ค่าเริ่มต้นเปิดไว้เพื่อความปลอดภัย
    // server ปิดให้เองเฉพาะตอนพัฒนา (Development) ดู ServerApp
    public bool RejectWeakPasswords { get; set; } = true;
}