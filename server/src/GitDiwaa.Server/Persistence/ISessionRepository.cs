namespace GitDiwaa.Server.Persistence;

public interface ISessionRepository
{
    Task AddAsync(SessionRecord session, CancellationToken ct = default);
    Task<SessionRecord?> FindByTokenHashAsync(string tokenHash, CancellationToken ct = default);
    Task<SessionRecord?> FindByIdAsync(Guid sessionId, CancellationToken ct = default);
    Task UpdateAsync(SessionRecord session, CancellationToken ct = default);
    Task RevokeAllForUserAsync(Guid userId, DateTimeOffset revokedAt, CancellationToken ct = default);
    Task<bool> TryRevokeAsync(Guid sessionId, DateTimeOffset revokedAt, CancellationToken ct = default);

    /// <summary>
    /// ยกเลิก session เพราะถูกแทนด้วย session ใหม่ตอน refresh (atomic: ยิงพร้อมกันสำเร็จได้แค่ครั้งเดียว)
    /// บันทึกเวลาที่หมุนและ session ที่มาแทน เพื่อใช้ตัดสินช่วงผ่อนผันของ token ใบเก่า
    /// </summary>
    Task<bool> TryRotateAsync(Guid sessionId, Guid replacedBySessionId, DateTimeOffset rotatedAt, CancellationToken ct = default);
    Task TouchAsync(Guid sessionId, DateTimeOffset lastUsedAt, CancellationToken ct = default);
}