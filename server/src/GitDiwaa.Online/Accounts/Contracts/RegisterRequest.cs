using System.Text;

namespace GitDiwaa.Online.Accounts.Contracts;

public sealed record RegisterRequest(
    string Username,
    string DisplayName,
    string Email,
    string Password)
{
    private bool PrintMembers(StringBuilder builder)
    {
        builder.Append("Username = ").Append(Username)
               .Append(", DisplayName = ").Append(DisplayName)
               .Append(", Email = ***")
               .Append(", Password = ***");
        return true;
    }
}