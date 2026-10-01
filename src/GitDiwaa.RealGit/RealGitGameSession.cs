using GitDiwaa.Core;

namespace GitDiwaa.RealGit;

internal sealed class RealGitGameSession : IGitGameSession
{
    private readonly GitSandbox _sandbox;
    private readonly LocalRemote _remote;
    private readonly GitCommandPolicy _policy;
    private readonly GitProcessRunner _processRunner;
    private readonly GitRepositoryInspector _inspector;

    public RealGitGameSession(
        GitSandbox sandbox,
        LocalRemote remote,
        GitProcessRunner processRunner)
    {
        _sandbox = sandbox;
        _remote = remote;
        _policy = new(sandbox, remote);
        _processRunner = processRunner;
        _inspector = new(sandbox, processRunner);
        Files = new SandboxPlayerFileSystem(sandbox);
        Info = new(
            sandbox.MissionId,
            sandbox.AttemptId,
            sandbox.PlayerRepositoryPath,
            remote.AliasUrl);
    }

    public GitSessionInfo Info { get; }
    public IPlayerFileSystem Files { get; }

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

    private GitCommandResult HideInternalRemotePath(GitCommandResult result) => result with
    {
        StandardOutput = result.StandardOutput.Replace(
            _remote.BareRepositoryPath,
            _remote.AliasUrl,
            StringComparison.Ordinal),
        StandardError = result.StandardError.Replace(
            _remote.BareRepositoryPath,
            _remote.AliasUrl,
            StringComparison.Ordinal)
    };
}
