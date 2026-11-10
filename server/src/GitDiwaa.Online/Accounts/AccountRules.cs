namespace GitDiwaa.Online.Accounts;

public static class AccountRules
{
    public const int UsernameMinLength = 3;
    public const int UsernameMaxLength = 20;

    public const int EmailMaxLength = 254;
    public const int EmailLocalPartMaxLength = 64;

    public const int DisplayNameMinLength = 1;
    public const int DisplayNameMaxLength = 50;

    public const int PasswordMinLength = 8;
    public const int PasswordMaxLength = 128;

    public const int LoginIdentifierMaxLength = 254;

    // สมัครโดยไม่ตั้งชื่อที่แสดง: server ตั้งให้เป็น "player-" ตามด้วยเลขลำดับ (player-1, player-2, ...)
    // ชื่อรูปแบบนี้สงวนไว้ให้ระบบ ผู้เล่นตั้งเองไม่ได้ (กันชื่อชนกับชื่อที่ระบบจะออกให้ในอนาคต)
    public const string GeneratedDisplayNamePrefix = "player-";

    // เลขแรกของชื่อที่ระบบตั้งให้ (player-10001, player-10002, ...) เริ่มที่หลักหมื่นเพื่อให้ชื่อยาวเท่ากัน
    // และไม่บอกจำนวนผู้เล่นตรงๆ ตอนเกมเพิ่งเปิด (เหมือนตั้งค่า START WITH ของ sequence ในฐานข้อมูล)
    public const long FirstGeneratedPlayerNumber = 10001;

    // สิทธิ์เปลี่ยนชื่อที่แสดงตอนเริ่มต้น (ใช้ได้ทันที) ใช้หมดแล้วได้คืนครั้งละ 1 ทุกช่วงเวลาที่ตั้งไว้
    public const int InitialDisplayNameChanges = 2;

    /// <summary>
    /// ชื่อนี้เป็นรูปแบบที่ระบบสงวนไว้หรือไม่ ("player-" + ตัวเลขล้วน) เทียบแบบเดียวกับการเช็คชื่อซ้ำ
    /// (ไม่สนตัวพิมพ์เล็กใหญ่ และตัวอักษรเต็มความกว้าง เช่น "ＰＬＡＹＥＲ-５" ก็นับ)
    /// </summary>
    public static bool IsReservedDisplayName(string displayName)
    {
        ArgumentNullException.ThrowIfNull(displayName);

        string key = AccountNormalizer.NormalizeDisplayNameKey(displayName);
        if (!key.StartsWith(GeneratedDisplayNamePrefix, StringComparison.Ordinal) ||
            key.Length == GeneratedDisplayNamePrefix.Length)
        {
            return false;
        }

        for (int i = GeneratedDisplayNamePrefix.Length; i < key.Length; i++)
        {
            if (key[i] is < '0' or > '9')
            {
                return false;
            }
        }

        return true;
    }
}