using System.Text;

namespace GitDiwaa.Online.Accounts.Contracts;

/// <summary>
/// ตรวจก่อนสมัครว่าใช้ชื่อผู้ใช้และอีเมลนี้ได้ไหม (เกมเรียกก่อนเปิดหน้านโยบาย) server ไม่สร้างบัญชีและไม่บันทึกอะไร
/// </summary>
public sealed record RegisterCheckRequest(string Username, string Email)
{
    // กันอีเมลหลุดลง log ถ้ามีใครเผลอ log ตัว request ทั้งก้อน
    private bool PrintMembers(StringBuilder builder)
    {
        builder.Append("Username = ").Append(Username)
               .Append(", Email = ***");
        return true;
    }
}
