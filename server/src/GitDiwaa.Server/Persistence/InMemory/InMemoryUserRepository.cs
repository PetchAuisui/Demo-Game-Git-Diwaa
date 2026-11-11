namespace GitDiwaa.Server.Persistence.InMemory;

public sealed class InMemoryUserRepository : IUserRepository
{
    private readonly Lock _lock = new();
    private readonly Dictionary<Guid, UserRecord> _usersById = [];
    private readonly Dictionary<string, UserRecord> _usersByUsername = new(StringComparer.Ordinal);
    private readonly Dictionary<string, UserRecord> _usersByEmail = new(StringComparer.Ordinal);
    private readonly Dictionary<string, UserRecord> _usersByDisplayName = new(StringComparer.Ordinal);
    // ตัวนับใส่รหัสผิดแยกตาม (ผู้ใช้, ต้นทาง) ตัวนับรวมของบัญชีอยู่ใน UserRecord.FailedLoginCount / LockoutUntil
    private readonly Dictionary<(Guid UserId, string ClientKey), ClientLoginFailures> _clientLoginFailures = [];
    private const int ClientLoginFailuresPruneThreshold = 10_000;
    private long _lastPlayerNumber = GitDiwaa.Online.Accounts.AccountRules.FirstGeneratedPlayerNumber - 1;

    public Task<long> NextPlayerNumberAsync(CancellationToken ct = default) =>
        Task.FromResult(Interlocked.Increment(ref _lastPlayerNumber));

    public Task<UserRecord?> FindByIdAsync(Guid id, CancellationToken ct = default)
    {
        lock (_lock)
        {
            _usersById.TryGetValue(id, out var user);
            return Task.FromResult(user);
        }
    }

    public Task<UserRecord?> FindByUsernameAsync(string normalizedUsername, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(normalizedUsername);

        lock (_lock)
        {
            _usersByUsername.TryGetValue(normalizedUsername, out var user);
            return Task.FromResult(user);
        }
    }

    public Task<UserRecord?> FindByEmailAsync(string normalizedEmail, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(normalizedEmail);

        lock (_lock)
        {
            _usersByEmail.TryGetValue(normalizedEmail, out var user);
            return Task.FromResult(user);
        }
    }

    public Task<UserAddResult> TryAddAsync(UserRecord user, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(user);

        lock (_lock)
        {
            if (_usersById.ContainsKey(user.Id) ||
                _usersByUsername.ContainsKey(user.Username) ||
                _usersByEmail.ContainsKey(user.EmailNormalized))
            {
                return Task.FromResult(UserAddResult.IdentifierTaken);
            }

            if (_usersByDisplayName.ContainsKey(user.DisplayNameKey))
            {
                return Task.FromResult(UserAddResult.DisplayNameTaken);
            }

            _usersById[user.Id] = user;
            _usersByUsername[user.Username] = user;
            _usersByEmail[user.EmailNormalized] = user;
            _usersByDisplayName[user.DisplayNameKey] = user;

            return Task.FromResult(UserAddResult.Added);
        }
    }

    public Task UpdateAsync(UserRecord user, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(user);

        lock (_lock)
        {
            if (!_usersById.TryGetValue(user.Id, out var existing))
            {
                throw new InvalidOperationException($"User with ID '{user.Id}' does not exist.");
            }

            if (!string.Equals(existing.Username, user.Username, StringComparison.Ordinal) ||
                !string.Equals(existing.EmailNormalized, user.EmailNormalized, StringComparison.Ordinal))
            {
                throw new InvalidOperationException("Username and email cannot be changed through UpdateAsync.");
            }

            // ชื่อที่แสดงเปลี่ยนได้ทางเดียวคือ TryChangeDisplayNameAsync (มีเช็คชื่อซ้ำและระยะเวลา)
            // ที่นี่จึงใช้ค่าชื่อที่เก็บอยู่เสมอ: กันข้อมูลเก่าที่อ่านไว้ก่อนเปลี่ยนชื่อ (เช่น ตอน login)
            // เขียนทับชื่อใหม่ และกันการตั้งชื่อโดยไม่ผ่านการเช็คชื่อซ้ำ
            var merged = user with
            {
                DisplayName = existing.DisplayName,
                DisplayNameKey = existing.DisplayNameKey,
                DisplayNameChangedAt = existing.DisplayNameChangedAt,
                DisplayNameChangeCredits = existing.DisplayNameChangeCredits,
                LeaderboardOptIn = existing.LeaderboardOptIn
            };

            _usersById[merged.Id] = merged;
            _usersByUsername[merged.Username] = merged;
            _usersByEmail[merged.EmailNormalized] = merged;
            _usersByDisplayName[merged.DisplayNameKey] = merged;

            return Task.CompletedTask;
        }
    }

    public Task<bool> IsLoginLockedAsync(Guid userId, string clientKey, DateTimeOffset now, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(clientKey);

        lock (_lock)
        {
            if (_usersById.TryGetValue(userId, out var user) && user.LockoutUntil > now)
            {
                return Task.FromResult(true);
            }

            bool clientLocked = _clientLoginFailures.TryGetValue((userId, clientKey), out var failures) &&
                                failures.LockedUntil > now;
            return Task.FromResult(clientLocked);
        }
    }

    public Task RecordFailedLoginAsync(Guid userId, string clientKey, DateTimeOffset now, LoginLockoutRules rules, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(clientKey);

        lock (_lock)
        {
            if (!_usersById.TryGetValue(userId, out var user))
            {
                return Task.CompletedTask;
            }

            var key = (userId, clientKey);
            _clientLoginFailures.TryGetValue(key, out var failures);

            // ถูกพักอยู่แล้ว (คำขอที่เข้ามาพร้อมกันก่อนจะพัก): ไม่นับเพิ่ม และไม่ยืดเวลาพัก
            if (user.LockoutUntil > now || failures.LockedUntil > now)
            {
                return Task.CompletedTask;
            }

            // ต้นทางนี้: ครั้งล่าสุดนานเกินช่วงพักแล้ว เริ่มนับใหม่
            int clientCount = failures.LastFailureAt.Add(rules.LockoutDuration) <= now ? 1 : failures.Count + 1;
            DateTimeOffset? clientLockedUntil = null;
            if (clientCount >= rules.MaxPerClient)
            {
                clientLockedUntil = now.Add(rules.LockoutDuration);
                clientCount = 0;
            }
            _clientLoginFailures[key] = new ClientLoginFailures(clientCount, clientLockedUntil, now);

            // ทั้งบัญชี: นับรวมทุกต้นทาง ครั้งล่าสุดนานเกินช่วงพักแล้ว เริ่มนับใหม่ (เหมือนตัวนับของต้นทาง)
            // ไม่อย่างนั้นบัญชีที่ไม่ได้ล็อกอินสำเร็จนานๆ จะผิดสะสมข้ามวันข้ามเดือนจนครบเกณฑ์แล้วถูกพักทั้งบัญชี
            bool accountStillCounting = user.LastFailedLoginAt is { } lastFailure &&
                                        lastFailure.Add(rules.LockoutDuration) > now;
            int accountCount = accountStillCounting ? user.FailedLoginCount + 1 : 1;
            DateTimeOffset? accountLockedUntil = user.LockoutUntil;
            if (accountCount >= rules.MaxPerAccount)
            {
                accountLockedUntil = now.Add(rules.LockoutDuration);
                accountCount = 0;
            }
            StoreUser(user with
            {
                FailedLoginCount = accountCount,
                LockoutUntil = accountLockedUntil,
                LastFailedLoginAt = now,
                UpdatedAt = now
            });

            if (_clientLoginFailures.Count > ClientLoginFailuresPruneThreshold)
            {
                PruneClientLoginFailures(now, rules.LockoutDuration);
            }

            return Task.CompletedTask;
        }
    }

    public Task RecordSuccessfulLoginAsync(Guid userId, string clientKey, string? upgradedPasswordHash, DateTimeOffset now, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(clientKey);

        lock (_lock)
        {
            if (!_usersById.TryGetValue(userId, out var user))
            {
                return Task.CompletedTask;
            }

            _clientLoginFailures.Remove((userId, clientKey));
            StoreUser(user with
            {
                PasswordHash = upgradedPasswordHash ?? user.PasswordHash,
                FailedLoginCount = 0,
                LockoutUntil = null,
                LastFailedLoginAt = null,
                LastLoginAt = now,
                UpdatedAt = now
            });

            return Task.CompletedTask;
        }
    }

    // เรียกภายใต้ _lock เท่านั้น
    private void StoreUser(UserRecord user)
    {
        _usersById[user.Id] = user;
        _usersByUsername[user.Username] = user;
        _usersByEmail[user.EmailNormalized] = user;
        _usersByDisplayName[user.DisplayNameKey] = user;
    }

    // เรียกภายใต้ _lock เท่านั้น: ทิ้งตัวนับที่หมดอายุแล้ว กันคนสลับ IP / ชื่อผู้ใช้ไปเรื่อยๆ จนหน่วยความจำโต
    private void PruneClientLoginFailures(DateTimeOffset now, TimeSpan lockoutDuration)
    {
        foreach (var (key, failures) in _clientLoginFailures.ToList())
        {
            bool stillLocked = failures.LockedUntil > now;
            bool stillCounting = failures.LastFailureAt.Add(lockoutDuration) > now;
            if (!stillLocked && !stillCounting)
            {
                _clientLoginFailures.Remove(key);
            }
        }
    }

    private readonly record struct ClientLoginFailures(int Count, DateTimeOffset? LockedUntil, DateTimeOffset LastFailureAt);

    public Task<UserRecord?> TrySetLeaderboardOptInAsync(Guid userId, bool optIn, DateTimeOffset now, CancellationToken ct = default)
    {
        lock (_lock)
        {
            if (!_usersById.TryGetValue(userId, out var existing))
            {
                return Task.FromResult<UserRecord?>(null);
            }

            var updated = existing with { LeaderboardOptIn = optIn, UpdatedAt = now };
            _usersById[updated.Id] = updated;
            _usersByUsername[updated.Username] = updated;
            _usersByEmail[updated.EmailNormalized] = updated;
            _usersByDisplayName[updated.DisplayNameKey] = updated;

            return Task.FromResult<UserRecord?>(updated);
        }
    }

    public Task<DisplayNameChangeOutcome> TryChangeDisplayNameAsync(
        Guid userId,
        string displayName,
        string displayNameKey,
        DateTimeOffset now,
        TimeSpan cooldown,
        CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(displayName);
        ArgumentNullException.ThrowIfNull(displayNameKey);

        lock (_lock)
        {
            if (!_usersById.TryGetValue(userId, out var existing))
            {
                return Task.FromResult(new DisplayNameChangeOutcome(DisplayNameChangeResult.UserNotFound, null));
            }

            int available = existing.AvailableDisplayNameChanges(now, cooldown);
            if (available <= 0)
            {
                return Task.FromResult(new DisplayNameChangeOutcome(DisplayNameChangeResult.CooldownActive, existing));
            }

            bool sameKey = string.Equals(existing.DisplayNameKey, displayNameKey, StringComparison.Ordinal);
            if (!sameKey && _usersByDisplayName.ContainsKey(displayNameKey))
            {
                return Task.FromResult(new DisplayNameChangeOutcome(DisplayNameChangeResult.DisplayNameTaken, existing));
            }

            var updated = existing with
            {
                DisplayName = displayName,
                DisplayNameKey = displayNameKey,
                DisplayNameChangedAt = now,
                DisplayNameChangeCredits = available - 1,
                UpdatedAt = now
            };

            if (!sameKey)
            {
                // ปล่อยชื่อเก่าให้คนอื่นใช้ได้
                _usersByDisplayName.Remove(existing.DisplayNameKey);
            }

            _usersById[updated.Id] = updated;
            _usersByUsername[updated.Username] = updated;
            _usersByEmail[updated.EmailNormalized] = updated;
            _usersByDisplayName[updated.DisplayNameKey] = updated;

            return Task.FromResult(new DisplayNameChangeOutcome(DisplayNameChangeResult.Changed, updated));
        }
    }
}