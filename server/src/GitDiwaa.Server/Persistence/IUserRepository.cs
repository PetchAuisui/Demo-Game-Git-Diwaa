namespace GitDiwaa.Server.Persistence;

public interface IUserRepository
{
    Task<UserRecord?> FindByIdAsync(Guid id, CancellationToken ct = default);
    Task<UserRecord?> FindByUsernameAsync(string normalizedUsername, CancellationToken ct = default);
    Task<UserRecord?> FindByEmailAsync(string normalizedEmail, CancellationToken ct = default);
    Task<UserAddResult> TryAddAsync(UserRecord user, CancellationToken ct = default);
    Task UpdateAsync(UserRecord user, CancellationToken ct = default);
}