namespace GitDiwaa.Online.Accounts.Contracts;

public sealed record PlayerProfile(
    Guid Id,
    string Username,
    string DisplayName);