using GitDiwaa.Core;

namespace GitDiwaa.RealGit;

public sealed class RealGitGameSessionFactory : IGitGameSessionFactory
{
    private readonly GitWorkspaceManager _workspaceManager;
    private readonly GitProcessRunner _processRunner = new();

    public RealGitGameSessionFactory(string workspaceRoot)
    {
        _workspaceManager = new(workspaceRoot);
    }

    public Task<IGitGameSession> CreateAsync(
        string missionId,
        string attemptId,
        CancellationToken cancellationToken = default) =>
        CreateAsync(missionId, attemptId, seed: null, cancellationToken);

    /// <summary>สร้าง session ที่ remote จำลอง GitHub ตาม <paramref name="seed"/> (ถ้ามี)</summary>
    public async Task<IGitGameSession> CreateAsync(
        string missionId,
        string attemptId,
        RemoteSeed? seed,
        CancellationToken cancellationToken = default)
    {
        var sandbox = _workspaceManager.CreateAttempt(missionId, attemptId);
        var remote = await _workspaceManager.CreateBareRemoteAsync(
            sandbox,
            _processRunner,
            cancellationToken: cancellationToken,
            aliasUrl: seed?.CloneUrl);
        if (seed is not null)
            await RemoteSeeder.SeedAsync(sandbox, remote, _processRunner, seed, cancellationToken);
        return new RealGitGameSession(sandbox, remote, _processRunner, seed);
    }
}
