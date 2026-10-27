using System.Text;
using GitDiwaa.Online.Accounts.Contracts;

namespace GitDiwaa.Server.Accounts;

public sealed record LoginSession(PlayerProfile Profile, string Token, DateTimeOffset ExpiresAt)
{
    private bool PrintMembers(StringBuilder builder)
    {
        builder.Append("Profile = ").Append(Profile)
               .Append(", Token = ***")
               .Append(", ExpiresAt = ").Append(ExpiresAt);
        return true;
    }
}