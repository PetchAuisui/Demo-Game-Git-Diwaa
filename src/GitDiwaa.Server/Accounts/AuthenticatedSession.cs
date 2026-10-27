using GitDiwaa.Online.Accounts.Contracts;

namespace GitDiwaa.Server.Accounts;

public sealed record AuthenticatedSession(
    Guid SessionId,
    PlayerProfile Profile);