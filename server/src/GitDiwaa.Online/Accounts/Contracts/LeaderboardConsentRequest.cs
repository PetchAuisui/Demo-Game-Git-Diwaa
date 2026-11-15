namespace GitDiwaa.Online.Accounts.Contracts;

/// <summary>
/// ให้ (Granted = true) หรือถอน (false) ความยินยอมแสดงชื่อที่แสดงบนตารางอันดับ
/// PolicyVersion = เวอร์ชันนโยบายที่ผู้เล่นเห็นตอนตัดสินใจ
/// </summary>
public sealed record LeaderboardConsentRequest(bool Granted, string? PolicyVersion);
