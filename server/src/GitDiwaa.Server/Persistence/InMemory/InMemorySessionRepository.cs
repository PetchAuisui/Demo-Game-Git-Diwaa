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

    public Task<SessionRecord?> FindByIdAsync(Guid sessionId, CancellationToken ct = default)
    {
        lock (_lock)
        {
            _sessionsById.TryGetValue(sessionId, out var session);
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

    public Task<bool> TryRevokeAsync(Guid sessionId, DateTimeOffset revokedAt, CancellationToken ct = default)
    {
        lock (_lock)
        {
            if (!_sessionsById.TryGetValue(sessionId, out var session))
            {
                return Task.FromResult(false);
            }

            if (session.RevokedAt is not null)
            {
                return Task.FromResult(false);
            }

            var revokedSession = session with { RevokedAt = revokedAt };
            _sessionsById[sessionId] = revokedSession;
            _sessionsByTokenHash[session.TokenHash] = revokedSession;
            return Task.FromResult(true);
        }
    }

    public Task<bool> TryRotateAsync(Guid sessionId, Guid replacedBySessionId, DateTimeOffset rotatedAt, CancellationToken ct = default)
    {
        lock (_lock)
        {
            if (!_sessionsById.TryGetValue(sessionId, out var session) || session.RevokedAt is not null)
            {
                return Task.FromResult(false);
            }

            var rotatedSession = session with
            {
                RevokedAt = rotatedAt,
                RotatedAt = rotatedAt,
                ReplacedBySessionId = replacedBySessionId
            };
            _sessionsById[sessionId] = rotatedSession;
            _sessionsByTokenHash[session.TokenHash] = rotatedSession;
            return Task.FromResult(true);
        }
    }

    public Task<bool> TryReplaceSuccessorAsync(Guid sessionId, Guid expectedSuccessorId, Guid newSuccessorId, CancellationToken ct = default)
    {
        lock (_lock)
        {
            if (!_sessionsById.TryGetValue(sessionId, out var session) ||
                session.RotatedAt is null ||
                session.ReplacedBySessionId != expectedSuccessorId)
            {
                return Task.FromResult(false);
            }

            var repointedSession = session with { ReplacedBySessionId = newSuccessorId };
            _sessionsById[sessionId] = repointedSession;
            _sessionsByTokenHash[session.TokenHash] = repointedSession;
            return Task.FromResult(true);
        }
    }

    public Task TouchAsync(Guid sessionId, DateTimeOffset lastUsedAt, CancellationToken ct = default)
    {
        lock (_lock)
        {
            if (!_sessionsById.TryGetValue(sessionId, out var session))
            {
                return Task.CompletedTask;
            }

            var touchedSession = session with { LastUsedAt = lastUsedAt };
            _sessionsById[sessionId] = touchedSession;
            _sessionsByTokenHash[session.TokenHash] = touchedSession;
            return Task.CompletedTask;
        }
    }
}