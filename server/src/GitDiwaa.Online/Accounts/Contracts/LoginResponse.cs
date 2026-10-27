using System.Text;

namespace GitDiwaa.Online.Accounts.Contracts;

public sealed record LoginResponse(
    PlayerProfile Profile,
    string Token,
    DateTimeOffset ExpiresAt)
{
    private bool PrintMembers(StringBuilder builder)
    {
        builder.Append("Profile = ").Append(Profile)
               .Append(", Token = ***, ExpiresAt = ").Append(ExpiresAt);
        return true;
    }
}