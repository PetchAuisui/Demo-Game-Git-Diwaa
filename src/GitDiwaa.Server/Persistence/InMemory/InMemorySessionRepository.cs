namespace GitDiwaa.Server.Persistence.InMemory;

public sealed class InMemorySessionRepository : ISessionRepository
{
    private readonly Lock _lock = new();
    private readonly Dictionary<string, SessionRecord> _sessionsByTokenHash = new(StringComparer.Ordinal);
    private readonly Dictionary<Guid, SessionRecord> _sessionsById = [];

    public Task AddAsync(SessionRecord session, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(session);

        lock (_lock)
        {
            if (_sessionsById.ContainsKey(session.Id))
            {
                throw new InvalidOperationException($"Session with ID '{session.Id}' already exists.");
            }

            if (_sessionsByTokenHash.ContainsKey(session.TokenHash))
            {
                throw new InvalidOperationException($"Session with token hash '{session.TokenHash}' already exists.");
            }

            _sessionsById[session.Id] = session;
            _sessionsByTokenHash[session.TokenHash] = session;
            return Task.CompletedTask;
        }
    }

    public Task<SessionRecord?> FindByTokenHashAsync(string tokenHash, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(tokenHash);

        lock (_lock)
        {
            _sessionsByTokenHash.TryGetValue(tokenHash, out var session);
            return Task.FromResult(session);
        }
    }

    public Task UpdateAsync(SessionRecord session, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(session);

        lock (_lock)
        {
            if (!_sessionsById.TryGetValue(session.Id, out var existing))
            {
                throw new InvalidOperationException($"Session with ID '{session.Id}' does not exist.");
            }

            if (!string.Equals(existing.TokenHash, session.TokenHash, StringComparison.Ordinal) ||
                existing.UserId != session.UserId)
            {
                throw new InvalidOperationException("TokenHash and UserId cannot be changed through UpdateAsync.");
            }

            _sessionsById[session.Id] = session;
            _sessionsByTokenHash[session.TokenHash] = session;
            return Task.CompletedTask;
        }
    }

    public Task RevokeAllForUserAsync(Guid userId, DateTimeOffset revokedAt, CancellationToken ct = default)
    {
        lock (_lock)
        {
            foreach (var (id, session) in _sessionsById.ToList())
            {
                if (session.UserId == userId && session.RevokedAt is null)
                {
                    var revokedSession = session with { RevokedAt = revokedAt };
                    _sessionsById[id] = revokedSession;
                    _sessionsByTokenHash[session.TokenHash] = revokedSession;
                }
            }

            return Task.CompletedTask;
        }
    }
}