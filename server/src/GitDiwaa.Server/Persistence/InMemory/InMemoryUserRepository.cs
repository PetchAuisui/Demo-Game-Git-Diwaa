namespace GitDiwaa.Server.Persistence.InMemory;

public sealed class InMemoryUserRepository : IUserRepository
{
    private readonly Lock _lock = new();
    private readonly Dictionary<Guid, UserRecord> _usersById = [];
    private readonly Dictionary<string, UserRecord> _usersByUsername = new(StringComparer.Ordinal);
    private readonly Dictionary<string, UserRecord> _usersByEmail = new(StringComparer.Ordinal);
    private readonly Dictionary<string, UserRecord> _usersByDisplayName = new(StringComparer.Ordinal);

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
                DisplayNameChangedAt = existing.DisplayNameChangedAt
            };

            _usersById[merged.Id] = merged;
            _usersByUsername[merged.Username] = merged;
            _usersByEmail[merged.EmailNormalized] = merged;
            _usersByDisplayName[merged.DisplayNameKey] = merged;

            return Task.CompletedTask;
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

            if (existing.DisplayNameChangedAt is { } lastChange && lastChange.Add(cooldown) > now)
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