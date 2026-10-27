using GitDiwaa.Server.Accounts;
using GitDiwaa.Server.Persistence;
using GitDiwaa.Server.Persistence.InMemory;
using GitDiwaa.Server.Security;

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

internal sealed record AccountTestContext(
    InMemoryUserRepository Users,
    InMemorySessionRepository Sessions,
    PasswordHasher Hasher,
    SessionTokenService TokenService,
    ManualTimeProvider Time,
    AccountService Service)
{
    public static readonly DateTimeOffset StartTime = new(2026, 10, 22, 0, 0, 0, TimeSpan.Zero);

    public static AccountTestContext Create(AccountOptions? options = null)
    {
        var users = new InMemoryUserRepository();
        var sessions = new InMemorySessionRepository();
        var hasher = new PasswordHasher();
        var tokenService = new SessionTokenService();
        var time = new ManualTimeProvider(StartTime);
        var service = new AccountService(users, sessions, hasher, tokenService, time, options ?? new AccountOptions());

        return new(users, sessions, hasher, tokenService, time, service);
    }
}