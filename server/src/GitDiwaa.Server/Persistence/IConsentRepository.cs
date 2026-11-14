namespace GitDiwaa.Server.Persistence;

public interface IConsentRepository
{
    Task AddAsync(ConsentRecord record, CancellationToken ct = default);
    Task<IReadOnlyList<ConsentRecord>> ListForUserAsync(Guid userId, CancellationToken ct = default);
}
