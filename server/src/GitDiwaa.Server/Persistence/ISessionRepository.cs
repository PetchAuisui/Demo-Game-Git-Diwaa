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

    /// <summary>
    /// ย้ายตัวชี้ "session ที่มาแทน" ของ session ที่ถูกหมุนไปแล้ว ไปยังใบใหม่ล่าสุด (ใช้ตอนผ่อนผันให้ใบเก่าต่ออายุซ้ำ)
    /// atomic แบบ compare-and-swap: เปลี่ยนเฉพาะเมื่อยังชี้ expectedSuccessorId อยู่ ถ้ามีคำขออื่นย้ายไปก่อนจะคืน false
    /// (ฐานข้อมูลจริงใช้ UPDATE ... SET replaced_by = @new WHERE id = @id AND replaced_by = @expected)
    /// ไม่ยกเลิกใบที่เคยมาแทน: ใบนั้นอาจมีคนถืออยู่จริง เช่น เกมอีกหน้าต่างหนึ่ง
    /// </summary>
    Task<bool> TryReplaceSuccessorAsync(Guid sessionId, Guid expectedSuccessorId, Guid newSuccessorId, CancellationToken ct = default);
    Task TouchAsync(Guid sessionId, DateTimeOffset lastUsedAt, CancellationToken ct = default);
}