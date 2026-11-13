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
    Guid? ReplacedBySessionId = null,
    // "สาย token": ล็อกอิน 1 ครั้ง = สายใหม่ 1 สาย (1 เครื่อง / 1 การล็อกอิน) ทุกใบที่ได้จากการ refresh ต่อกันมาอยู่สายเดียวกัน
    // ใช้ตัดเฉพาะสายที่มีปัญหา (ใบเก่าถูกใช้ซ้ำ) โดยไม่กระทบการล็อกอินจากเครื่องอื่นของบัญชีเดียวกัน
    // Guid.Empty = ข้อมูลที่สร้างก่อนมีสาย (ไม่มีในระบบจริงตอนนี้) จะไม่ถูกจับรวมเป็นสายเดียวกัน
    Guid FamilyId = default,
    // ครั้งแรกที่ token ใบนี้ถูกใช้เรียก endpoint (null = ยังไม่เคยถูกใช้) ตั้งครั้งเดียวใน TouchAsync
    // ใช้ตัดสินช่วงผ่อนผันของ token ใบเก่า แทนการเทียบ LastUsedAt กับ CreatedAt ซึ่งพลาดได้ถ้าสร้างกับใช้ในเวลาเดียวกันพอดี
    DateTimeOffset? FirstUsedAt = null);