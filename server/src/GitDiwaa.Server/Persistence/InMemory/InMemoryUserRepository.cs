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

            if (!string.Equals(existing.DisplayNameKey, user.DisplayNameKey, StringComparison.Ordinal))
            {
                throw new InvalidOperationException("DisplayNameKey cannot be changed through UpdateAsync.");
            }

            _usersById[user.Id] = user;
            _usersByUsername[user.Username] = user;
            _usersByEmail[user.EmailNormalized] = user;
            _usersByDisplayName[user.DisplayNameKey] = user;

            return Task.CompletedTask;
        }
    }
}