namespace GitDiwaa.Online.Accounts;

public static class PrivacyPolicy
{
    // เวอร์ชันของนโยบายความเป็นส่วนตัว (ปี-เดือน-วัน) เปลี่ยนทุกครั้งที่แก้เนื้อหานโยบาย
    // ต้องตรงกับ PRIVACY_POLICY_VERSION ในเกมเสมอ ไม่อย่างนั้น server จะไม่รับการยินยอม
    public const string CurrentVersion = "2026-11-09";
}
