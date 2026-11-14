namespace GitDiwaa.Server.Persistence.InMemory;

public sealed class InMemoryConsentRepository : IConsentRepository
{
    private readonly Lock _lock = new();
    private readonly List<ConsentRecord> _records = [];

    public Task AddAsync(ConsentRecord record, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(record);

        lock (_lock)
        {
            _records.Add(record);
            return Task.CompletedTask;
        }
    }

    public Task<IReadOnlyList<ConsentRecord>> ListForUserAsync(Guid userId, CancellationToken ct = default)
    {
        lock (_lock)
        {
            IReadOnlyList<ConsentRecord> result = _records.Where(r => r.UserId == userId).ToList();
            return Task.FromResult(result);
        }
    }
}
