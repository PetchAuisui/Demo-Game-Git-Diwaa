namespace GitDiwaa.Server.Persistence;

public interface ISessionRepository
{
    Task AddAsync(SessionRecord session, CancellationToken ct = default);
    Task<SessionRecord?> FindByTokenHashAsync(string tokenHash, CancellationToken ct = default);
    Task<SessionRecord?> FindByIdAsync(Guid sessionId, CancellationToken ct = default);
    Task UpdateAsync(SessionRecord session, CancellationToken ct = default);
    /// <summary>
    /// ยกเลิกทุก session ของผู้ใช้ ทุกเครื่อง (เก็บไว้ใช้ตอนเปลี่ยนรหัสผ่าน / ปิดบัญชี ตอนนี้ refresh ใช้ RevokeFamilyAsync แทน)
    /// </summary>
    Task RevokeAllForUserAsync(Guid userId, DateTimeOffset revokedAt, CancellationToken ct = default);

    /// <summary>
    /// ยกเลิกทุก session ใน "สาย token" เดียวกัน (การล็อกอินครั้งเดียวกัน และทุกใบที่ refresh ต่อกันมา)
    /// ใช้เมื่อพบว่าใบเก่าในสายถูกใช้ซ้ำ: ตัดเฉพาะเครื่องนั้น ไม่กระทบการล็อกอินจากเครื่องอื่น
    /// familyId เป็น Guid.Empty = ไม่ทำอะไร (ไม่จับ session ที่ไม่มีสายมารวมกัน)
    /// </summary>
    Task RevokeFamilyAsync(Guid familyId, DateTimeOffset revokedAt, CancellationToken ct = default);
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