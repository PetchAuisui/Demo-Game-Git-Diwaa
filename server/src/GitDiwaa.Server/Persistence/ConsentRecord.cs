namespace GitDiwaa.Server.Persistence;

public static class ConsentPurposes
{
    // แสดงชื่อที่แสดงบนตารางอันดับให้ผู้เล่นคนอื่นเห็น
    public const string LeaderboardDisplay = "leaderboard_display";
}

/// <summary>
/// หลักฐานการให้ / ถอนความยินยอม 1 ครั้ง (บันทึกทุกครั้ง ไม่แก้ของเดิม)
/// เก็บเท่าที่จำเป็น: ใคร, เรื่องอะไร, นโยบายเวอร์ชันไหน, ยินยอมหรือไม่, เมื่อไหร่ ไม่เก็บ IP
/// </summary>
public sealed record ConsentRecord(
    Guid Id,
    Guid UserId,
    string Purpose,
    string PolicyVersion,
    bool Granted,
    DateTimeOffset RecordedAt);
