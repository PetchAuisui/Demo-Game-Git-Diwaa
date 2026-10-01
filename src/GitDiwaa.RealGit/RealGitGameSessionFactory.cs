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

    public async Task<IGitGameSession> CreateAsync(
        string missionId,
        string attemptId,
        CancellationToken cancellationToken = default)
    {
        var sandbox = _workspaceManager.CreateAttempt(missionId, attemptId);
        var remote = await _workspaceManager.CreateBareRemoteAsync(
            sandbox,
            _processRunner,
            cancellationToken: cancellationToken);
        return new RealGitGameSession(_workspaceManager, sandbox, remote, _processRunner);
    }
}
