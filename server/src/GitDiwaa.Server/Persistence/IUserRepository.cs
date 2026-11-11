namespace GitDiwaa.Server.Persistence;

public interface IUserRepository
{
    Task<UserRecord?> FindByIdAsync(Guid id, CancellationToken ct = default);
    Task<UserRecord?> FindByUsernameAsync(string normalizedUsername, CancellationToken ct = default);
    Task<UserRecord?> FindByEmailAsync(string normalizedEmail, CancellationToken ct = default);
    Task<UserAddResult> TryAddAsync(UserRecord user, CancellationToken ct = default);
    Task UpdateAsync(UserRecord user, CancellationToken ct = default);

    /// <summary>
    /// ตอนนี้ผู้ใช้คนนี้ถูกพักการล็อกอินอยู่ไหม เมื่อมองจากต้นทางนี้ (clientKey เช่น IP)
    /// พักได้ 2 แบบ: เฉพาะต้นทางที่ใส่ผิดบ่อย หรือทั้งบัญชีเมื่อใส่ผิดรวมกันจากทุกต้นทางมากเกินไป
    /// </summary>
    Task<bool> IsLoginLockedAsync(Guid userId, string clientKey, DateTimeOffset now, CancellationToken ct = default);

    /// <summary>
    /// นับการใส่รหัสผิด 1 ครั้งแบบ atomic (อ่านค่า บวก และตั้งการพักในขั้นตอนเดียว)
    /// ยิงพร้อมกันกี่คำขอก็ถูกนับครบทุกครั้ง ไม่เขียนทับกัน (ฐานข้อมูลจริงใช้ UPDATE ... SET count = count + 1)
    /// </summary>
    Task RecordFailedLoginAsync(Guid userId, string clientKey, DateTimeOffset now, LoginLockoutRules rules, CancellationToken ct = default);

    /// <summary>
    /// ล็อกอินสำเร็จ: ล้างตัวนับของบัญชีและของต้นทางนี้ บันทึกเวลา และเปลี่ยน hash ถ้าส่งมา (atomic ไม่เขียนทับช่องอื่น)
    /// </summary>
    Task RecordSuccessfulLoginAsync(Guid userId, string clientKey, string? upgradedPasswordHash, DateTimeOffset now, CancellationToken ct = default);

    /// <summary>
    /// เลขลำดับถัดไปสำหรับตั้งชื่อ player-&lt;เลข&gt; ให้ผู้เล่นที่ไม่ได้ตั้งชื่อตอนสมัคร (เพิ่มทีละ 1 ไม่ซ้ำ)
    /// </summary>
    Task<long> NextPlayerNumberAsync(CancellationToken ct = default);

    /// <summary>
    /// เปลี่ยนชื่อที่แสดงแบบ atomic: เช็คระยะเวลา เช็คชื่อซ้ำ ปล่อยชื่อเก่า และจองชื่อใหม่ในขั้นตอนเดียว
    /// ยิงคำขอพร้อมกันหลายครั้งก็เปลี่ยนได้แค่ครั้งเดียว และชื่อเดียวกันมีเจ้าของได้คนเดียว
    /// </summary>
    /// <summary>
    /// ตั้งค่าการยินยอมแสดงชื่อบนตารางอันดับแบบ atomic คืนข้อมูลล่าสุด หรือ null ถ้าไม่พบผู้ใช้
    /// (UpdateAsync จะไม่แตะค่านี้ เพื่อไม่ให้ข้อมูลเก่าเขียนทับการตัดสินใจของผู้เล่น)
    /// </summary>
    Task<UserRecord?> TrySetLeaderboardOptInAsync(Guid userId, bool optIn, DateTimeOffset now, CancellationToken ct = default);

    Task<DisplayNameChangeOutcome> TryChangeDisplayNameAsync(
        Guid userId,
        string displayName,
        string displayNameKey,
        DateTimeOffset now,
        TimeSpan cooldown,
        CancellationToken ct = default);
}