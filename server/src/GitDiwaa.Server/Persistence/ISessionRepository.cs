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
    /// ผ่อนผันให้ใบเก่าที่ถูกหมุนไปแล้ว: ย้ายตัวชี้ "session ที่มาแทน" ไปยังใบใหม่ และยกเลิกใบที่มาแทนก่อนหน้า ในขั้นตอนเดียว (atomic)
    /// ทำเฉพาะเมื่อครบทุกข้อ ไม่ครบคืน false และไม่เปลี่ยนอะไรเลย:
    /// 1. ใบเก่ายังชี้ expectedSuccessorId อยู่ (compare-and-swap: มีคำขออื่นย้ายไปก่อน = false)
    /// 2. ใบที่มาแทนก่อนหน้ายังไม่ถูกยกเลิก และยังไม่เคยถูกใช้ (LastUsedAt &lt;= CreatedAt)
    ///    ถูกใช้ไปแล้วระหว่างนี้ = มีคนถือใบนั้นจริง ห้ามผ่อนผันให้ใบเก่าอีก
    /// ผล: ใบเก่า 1 ใบ มี session ที่งอกจากการผ่อนผันใช้ได้พร้อมกันแค่ใบเดียวเสมอ (ใบล่าสุด)
    /// (ฐานข้อมูลจริง: ทำ 2 UPDATE ใน transaction เดียว โดยมีเงื่อนไขข้างบนอยู่ใน WHERE)
    /// </summary>
    Task<bool> TryReplaceSuccessorAsync(Guid sessionId, Guid expectedSuccessorId, Guid newSuccessorId, DateTimeOffset now, CancellationToken ct = default);
    Task TouchAsync(Guid sessionId, DateTimeOffset lastUsedAt, CancellationToken ct = default);
}