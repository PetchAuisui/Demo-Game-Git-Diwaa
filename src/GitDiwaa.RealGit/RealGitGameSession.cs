using GitDiwaa.Core;

namespace GitDiwaa.RealGit;

internal sealed class RealGitGameSession : IGitGameSession
{
    private readonly GitSandbox _sandbox;
    private readonly RemoteRegistry _remotes;
    private readonly GitCommandPolicy _policy;
    private readonly GitProcessRunner _processRunner;
    private readonly GitRepositoryInspector _inspector;

    public RealGitGameSession(
        GitSandbox sandbox,
        GitWorkspaceManager workspace,
        LocalRemote? remote,
        GitProcessRunner processRunner,
        RemoteSeed seed)
    {
        _sandbox = sandbox;
        _remotes = new(remote);
        _policy = new(sandbox, _remotes);
        _processRunner = processRunner;
        _inspector = new(sandbox, processRunner);
        Files = new SandboxPlayerFileSystem(sandbox);
        var primary = remote is null ? null : new SimulatedGitHubHost(sandbox, remote, processRunner, seed);
        RemoteHost = primary;
        RemoteAccount = new SimulatedGitHubAccount(sandbox, workspace, processRunner, _remotes, seed, primary);
        Info = new(
            sandbox.MissionId,
            sandbox.AttemptId,
            sandbox.PlayerRepositoryPath,
            remote?.AliasUrl ?? string.Empty);
    }

    public GitSessionInfo Info { get; }
    public IPlayerFileSystem Files { get; }
    public IGitRemoteHost? RemoteHost { get; }
    public IGitRemoteAccount RemoteAccount { get; }

    public async Task<GitCommandResult> ExecuteAsync(
        string commandLine,
        CancellationToken cancellationToken = default)
    {
        IReadOnlyList<string> tokens;
        try
        {
            tokens = GitCommandLine.Tokenize(commandLine);
        }
        catch (ArgumentException exception)
        {
            return GitCommandResult.Rejected(exception.Message, commandLine);
        }

        if (tokens.Count == 0 || tokens[0] != "git")
            return GitCommandResult.Rejected("Command must start with 'git'.", commandLine);

        var arguments = tokens.Skip(1).ToArray();
        var validationError = _policy.Validate(arguments);
        if (validationError is not null) return GitCommandResult.Rejected(validationError, commandLine);

        var workingDirectory = _sandbox.PlayerRepositoryPath;
        if (arguments[0] == "clone")
        {
            workingDirectory = _sandbox.AttemptRoot;
            arguments = ["clone", arguments[1], _sandbox.PlayerRepositoryPath];
        }

        var result = await _processRunner.RunAsync(_sandbox, workingDirectory, arguments, cancellationToken);
        return HideInternalRemotePath(result);
    }

    public Task<GitRepositorySnapshot> InspectAsync(CancellationToken cancellationToken = default) =>
        _inspector.InspectAsync(cancellationToken);

    public ValueTask DisposeAsync() => ValueTask.CompletedTask;

    private GitCommandResult HideInternalRemotePath(GitCommandResult result)
    {
        var output = result.StandardOutput;
        var error = result.StandardError;
        foreach (var remote in _remotes.Remotes)
        {
            output = output.Replace(remote.BareRepositoryPath, remote.AliasUrl, StringComparison.Ordinal);
            error = error.Replace(remote.BareRepositoryPath, remote.AliasUrl, StringComparison.Ordinal);
        }

        return result with { StandardOutput = output, StandardError = error };
    }
}
