namespace GitDiwaa.Server.Persistence.InMemory;

public sealed class InMemorySessionRepository : ISessionRepository
{
    private readonly Lock _lock = new();
    private readonly Dictionary<string, SessionRecord> _sessionsByTokenHash = new(StringComparer.Ordinal);
    private readonly Dictionary<Guid, SessionRecord> _sessionsById = [];

    // ล้าง session ที่หมดอายุแล้วออกจากหน่วยความจำ ไม่อย่างนั้น server ที่เปิดค้างนานๆ ใช้ memory เพิ่มเรื่อยๆ
    // (ทุกการ login / refresh เพิ่ม session ใหม่ 1 ใบ) ล้างเป็นรอบเมื่อจำนวนถึงเกณฑ์ ไม่ไล่ทั้งหมดทุกครั้งที่เพิ่ม
    // เกณฑ์รอบถัดไป = 2 เท่าของที่เหลือหลังล้าง (ไม่ต่ำกว่าค่าเริ่มต้น) เฉลี่ยแล้วต่อการเพิ่ม 1 ครั้งยังเร็วเท่าเดิม
    private const int DefaultPruneThreshold = 10_000;
    // ล้างเฉพาะใบที่หมดอายุมาแล้วเกินช่วงนี้ เผื่อไว้มากกว่าช่วงผ่อนผันของการ refresh (60 วินาที) และนาฬิกาคลาดเล็กน้อย
    private static readonly TimeSpan PruneAfterExpiry = TimeSpan.FromHours(1);
    private readonly int _minPruneThreshold;
    private int _nextPruneAt;

    /// <param name="pruneThreshold">จำนวน session ที่จะเริ่มล้างใบหมดอายุ (เทสตั้งให้น้อยได้)</param>
    public InMemorySessionRepository(int pruneThreshold = DefaultPruneThreshold)
    {
        ArgumentOutOfRangeException.ThrowIfLessThan(pruneThreshold, 1);
        _minPruneThreshold = pruneThreshold;
        _nextPruneAt = pruneThreshold;
    }

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

            if (_sessionsById.Count >= _nextPruneAt)
            {
                // เวลาอ้างอิง = เวลาที่ session ใหม่ถูกสร้าง (มาจาก TimeProvider ของ AccountService ไม่ใช่นาฬิกาเครื่อง)
                PruneExpired(session.CreatedAt);
                _nextPruneAt = Math.Max(_minPruneThreshold, _sessionsById.Count * 2);
            }

            return Task.CompletedTask;
        }
    }

    // เรียกภายใต้ _lock เท่านั้น
    // ลบเฉพาะใบที่ "หมดอายุ" แล้ว ไม่ลบใบที่ถูกหมุน / ถูกยกเลิกแต่ยังไม่หมดอายุ:
    // ใบพวกนั้นต้องเก็บไว้ ถ้ามีคนเอาใบเก่าที่ถูกหมุนแล้วมาใช้ซ้ำ server ต้องหาเจอเพื่อตัดสาย token ของเครื่องนั้น
    // ใบที่หมดอายุแล้วใช้ทำอะไรไม่ได้อีก (refresh / ใช้เรียก endpoint ไม่ผ่าน) ลบได้ปลอดภัย
    private void PruneExpired(DateTimeOffset now)
    {
        DateTimeOffset cutoff = now - PruneAfterExpiry;
        foreach (var (id, session) in _sessionsById.ToList())
        {
            if (session.ExpiresAt < cutoff)
            {
                _sessionsById.Remove(id);
                _sessionsByTokenHash.Remove(session.TokenHash);
            }
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

    public Task RevokeFamilyAsync(Guid familyId, DateTimeOffset revokedAt, CancellationToken ct = default)
    {
        if (familyId == Guid.Empty)
        {
            return Task.CompletedTask;
        }

        lock (_lock)
        {
            foreach (var (id, session) in _sessionsById.ToList())
            {
                if (session.FamilyId == familyId && session.RevokedAt is null)
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

    public Task<bool> TryReplaceSuccessorAsync(Guid sessionId, Guid expectedSuccessorId, Guid newSuccessorId, DateTimeOffset now, CancellationToken ct = default)
    {
        lock (_lock)
        {
            if (!_sessionsById.TryGetValue(sessionId, out var session) ||
                session.RotatedAt is null ||
                session.ReplacedBySessionId != expectedSuccessorId)
            {
                return Task.FromResult(false);
            }

            // ใบที่มาแทนก่อนหน้า: ต้องยังใช้ได้และยังไม่เคยถูกใช้ ถึงจะยกเลิกแล้วออกใบใหม่แทนได้
            if (!_sessionsById.TryGetValue(expectedSuccessorId, out var previous) ||
                previous.RevokedAt is not null ||
                previous.FirstUsedAt is not null)
            {
                return Task.FromResult(false);
            }

            var revokedPrevious = previous with { RevokedAt = now };
            _sessionsById[previous.Id] = revokedPrevious;
            _sessionsByTokenHash[previous.TokenHash] = revokedPrevious;

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

            var touchedSession = session with { LastUsedAt = lastUsedAt, FirstUsedAt = session.FirstUsedAt ?? lastUsedAt };
            _sessionsById[sessionId] = touchedSession;
            _sessionsByTokenHash[session.TokenHash] = touchedSession;
            return Task.CompletedTask;
        }
    }
}