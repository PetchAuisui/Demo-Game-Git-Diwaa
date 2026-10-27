namespace GitDiwaa.Server.Accounts;

public sealed class AccountOptions
{
    public TimeSpan ShortSessionLifetime { get; set; } = TimeSpan.FromHours(12);
    public TimeSpan PersistentSessionLifetime { get; set; } = TimeSpan.FromDays(30);
    public int MaxFailedLoginAttempts { get; set; } = 5;
    public TimeSpan LockoutDuration { get; set; } = TimeSpan.FromMinutes(15);
}