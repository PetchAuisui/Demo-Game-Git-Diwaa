using System.Text;

namespace GitDiwaa.Online.Accounts.Contracts;

/// <summary>
/// อีเมลของเจ้าของ token (GET /me/email) ให้เมนูบัญชีในเกมแสดงแบบปิดบัง
/// </summary>
public sealed record MyEmailResponse(string Email)
{
    // กันอีเมลหลุดลง log ถ้ามีใครเผลอ log ตัว response ทั้งก้อน
    private bool PrintMembers(StringBuilder builder)
    {
        builder.Append("Email = ***");
        return true;
    }
}
