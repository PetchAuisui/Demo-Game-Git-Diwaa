namespace GitDiwaa.Server.Persistence;

public interface IUserRepository
{
    Task<UserRecord?> FindByIdAsync(Guid id, CancellationToken ct = default);
    Task<UserRecord?> FindByUsernameAsync(string normalizedUsername, CancellationToken ct = default);
    Task<UserRecord?> FindByEmailAsync(string normalizedEmail, CancellationToken ct = default);
    Task<UserAddResult> TryAddAsync(UserRecord user, CancellationToken ct = default);
    Task UpdateAsync(UserRecord user, CancellationToken ct = default);

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