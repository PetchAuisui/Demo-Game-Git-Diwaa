using System.Text;

namespace GitDiwaa.Server.Persistence;

public enum UserStatus
{
    Unknown = 0,
    Active = 1,
    Disabled = 2
}

public sealed record UserRecord(
    Guid Id,
    string Username,
    string Email,
    string EmailNormalized,
    string DisplayName,
    string DisplayNameKey,
    string PasswordHash,
    DateTimeOffset? EmailVerifiedAt,
    int FailedLoginCount,
    DateTimeOffset? LockoutUntil,
    UserStatus Status,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    DateTimeOffset? LastLoginAt,
    DateTimeOffset? DisplayNameChangedAt = null)
{
    private bool PrintMembers(StringBuilder builder)
    {
        builder.Append("Id = ").Append(Id)
               .Append(", Username = ").Append(Username)
               .Append(", Email = ***, EmailNormalized = ***")
               .Append(", DisplayName = ").Append(DisplayName)
               .Append(", DisplayNameKey = ").Append(DisplayNameKey)
               .Append(", PasswordHash = ***")
               .Append(", EmailVerifiedAt = ").Append(EmailVerifiedAt)
               .Append(", FailedLoginCount = ").Append(FailedLoginCount)
               .Append(", LockoutUntil = ").Append(LockoutUntil)
               .Append(", Status = ").Append(Status)
               .Append(", CreatedAt = ").Append(CreatedAt)
               .Append(", UpdatedAt = ").Append(UpdatedAt)
               .Append(", LastLoginAt = ").Append(LastLoginAt)
               .Append(", DisplayNameChangedAt = ").Append(DisplayNameChangedAt);
        return true;
    }
}