using System.Text;

namespace GitDiwaa.Online.Accounts.Contracts;

public sealed record LoginRequest(
    string Identifier,
    string Password,
    bool RememberMe)
{
    private bool PrintMembers(StringBuilder builder)
    {
        builder.Append("Identifier = ").Append(Identifier)
               .Append(", Password = ***")
               .Append(", RememberMe = ").Append(RememberMe);
        return true;
    }
}