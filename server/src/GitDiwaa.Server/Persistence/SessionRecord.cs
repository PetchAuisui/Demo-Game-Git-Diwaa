namespace GitDiwaa.Server.Persistence;

public sealed record SessionRecord(
    Guid Id,
    Guid UserId,
    string TokenHash,
    bool IsPersistent,
    DateTimeOffset CreatedAt,
    DateTimeOffset ExpiresAt,
    DateTimeOffset LastUsedAt,
    DateTimeOffset? RevokedAt,
    // ตั้งเมื่อ session นี้ถูกแทนด้วย token ใบใหม่ตอน refresh (ไม่ตั้งเมื่อถูกยกเลิกด้วย logout / ถูกตัดทั้งบัญชี)
    // ใช้ตัดสินช่วงผ่อนผัน: token ใบเก่าที่เพิ่งถูกหมุน เอามา refresh ซ้ำได้ช่วงสั้นๆ (ดู AccountService.RefreshAsync)
    DateTimeOffset? RotatedAt = null,
    Guid? ReplacedBySessionId = null);