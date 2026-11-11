namespace GitDiwaa.Online.Accounts;

/// <summary>
/// รหัสผ่านที่คนใช้กันมาก (ยาว 8 ตัวขึ้นไป) ห้ามใช้ตั้งบัญชี ตามแนว NIST SP 800-63B ที่ให้ตรวจกับรายการรหัสต้องห้าม
/// คนร้ายมักลองรหัสพวกนี้รหัสเดียวกับหลายบัญชี (password spraying) ซึ่งการล็อกบัญชีหลังใส่ผิด 5 ครั้งกันไม่ได้
/// รายการนี้เป็นตัวที่พบบ่อยที่สุด ไม่ได้ครบทุกตัว เพิ่มได้ (ตัวพิมพ์เล็ก ไม่ต้องเรียง) เทียบแบบไม่สนตัวพิมพ์ใหญ่เล็ก
/// </summary>
public static class CommonPasswords
{
    private static readonly HashSet<string> Values = new(StringComparer.OrdinalIgnoreCase)
    {
        "12345678", "123456789", "1234567890", "12345678910", "123456789a", "a123456789",
        "87654321", "987654321", "0987654321", "11223344", "12341234", "123123123",
        "12344321", "11112222", "147258369", "123654789", "159753456", "741852963",
        "00000000", "11111111", "22222222", "55555555", "66666666", "88888888", "99999999",
        "password", "password1", "password12", "password123", "password!", "passw0rd",
        "p@ssw0rd", "p@ssword", "pass1234", "passwort", "mypassword",
        "qwertyui", "qwertyuiop", "qwerty12", "qwerty123", "qwerty1234", "1qaz2wsx",
        "zaq12wsx", "qazwsxedc", "1q2w3e4r", "1q2w3e4r5t", "1q2w3e4r5t6y", "q1w2e3r4",
        "asdfghjk", "asdfghjkl", "asdf1234", "zxcvbnm1", "zxcvbnm123", "abcd1234",
        "abc12345", "abc123456", "abcdefgh", "aa123456", "a1234567", "1234qwer",
        "123qweasd", "qweasdzxc", "iloveyou", "iloveyou1", "iloveyou2", "sunshine",
        "princess", "football", "baseball", "superman", "starwars", "whatever",
        "computer", "internet", "trustno1", "welcome1", "welcome123", "letmein1",
        "admin123", "administrator", "master12", "dragon12", "monkey12", "michael1",
        "jennifer", "charlie1", "shadow12", "changeme", "default1", "test1234",
        "testtest", "gitdiwaa", "gitdiwaa1", "gitdiwaa123", "gitdiwaa2026",
    };

    public static bool Contains(string password) => Values.Contains(password.Trim());
}
