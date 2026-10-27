namespace GitDiwaa.Server.Persistence;

public sealed record SessionRecord(
    Guid Id,
    Guid UserId,
    string TokenHash,
    bool IsPersistent,
    DateTimeOffset CreatedAt,
    DateTimeOffset ExpiresAt,
    DateTimeOffset LastUsedAt,
    DateTimeOffset? RevokedAt);