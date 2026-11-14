using System.Text;

namespace GitDiwaa.Online.Accounts.Contracts;

public sealed record LoginRequest(
    string Identifier,
    string Password,
    bool RememberMe)
{
    private bool PrintMembers(StringBuilder builder)
    {
        // ผู้เล่นใส่อีเมลในช่องนี้ได้: ถ้าเป็นอีเมลให้ซ่อน (ชื่อผู้ใช้แสดงได้ ช่วยตอนไล่ปัญหา)
        bool looksLikeEmail = Identifier?.Contains('@') == true;
        builder.Append("Identifier = ").Append(looksLikeEmail ? "***" : Identifier)
               .Append(", Password = ***")
               .Append(", RememberMe = ").Append(RememberMe);
        return true;
    }
}