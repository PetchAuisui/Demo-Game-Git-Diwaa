using GitDiwaa.Server.Persistence;

namespace GitDiwaa.Server.Tests;

internal static class TestData
{
    public static UserRecord NewUser(string username, string email)
    {
        var now = DateTimeOffset.UtcNow;
        return new UserRecord(
            Id: Guid.NewGuid(),
            Username: username,
            Email: email,
            EmailNormalized: email.Trim().ToLowerInvariant(),
            DisplayName: "Test Player",
            PasswordHash: "test-hash",
            EmailVerifiedAt: null,
            FailedLoginCount: 0,
            LockoutUntil: null,
            Status: UserStatus.Active,
            CreatedAt: now,
            UpdatedAt: now,
            LastLoginAt: null);
    }
}