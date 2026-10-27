namespace GitDiwaa.Server.Persistence;

public interface ISessionRepository
{
    Task AddAsync(SessionRecord session, CancellationToken ct = default);
    Task<SessionRecord?> FindByTokenHashAsync(string tokenHash, CancellationToken ct = default);
    Task UpdateAsync(SessionRecord session, CancellationToken ct = default);
    Task RevokeAllForUserAsync(Guid userId, DateTimeOffset revokedAt, CancellationToken ct = default);
    Task<bool> TryRevokeAsync(Guid sessionId, DateTimeOffset revokedAt, CancellationToken ct = default);
    Task TouchAsync(Guid sessionId, DateTimeOffset lastUsedAt, CancellationToken ct = default);
}