namespace GitDiwaa.RealGit;

internal sealed class GitWorkspaceManager
{
    private readonly StringComparison _pathComparison = OperatingSystem.IsWindows()
        ? StringComparison.OrdinalIgnoreCase
        : StringComparison.Ordinal;

    public GitWorkspaceManager(string rootPath)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(rootPath);
        RootPath = Path.GetFullPath(rootPath);
    }

    public string RootPath { get; }

    public GitSandbox CreateAttempt(string missionId, string attemptId)
    {
        ValidateIdentifier(missionId, nameof(missionId));
        ValidateIdentifier(attemptId, nameof(attemptId));

        var attemptRoot = Path.Combine(RootPath, missionId, attemptId);
        EnsureInsideRoot(attemptRoot);
        if (Directory.Exists(attemptRoot) && Directory.EnumerateFileSystemEntries(attemptRoot).Any())
            throw new InvalidOperationException($"Attempt already exists and is not empty: {attemptRoot}");

        var playerRepository = Path.Combine(attemptRoot, "player-repo");
        var remotes = Path.Combine(attemptRoot, "remotes");
        var config = Path.Combine(attemptRoot, "config", "gitconfig");
        var hooks = Path.Combine(attemptRoot, "disabled-hooks");

        Directory.CreateDirectory(playerRepository);
        Directory.CreateDirectory(remotes);
        Directory.CreateDirectory(Path.GetDirectoryName(config)!);
        Directory.CreateDirectory(hooks);
        File.WriteAllText(config, "[init]\n\tdefaultBranch = main\n");

        return new(
            missionId,
            attemptId,
            attemptRoot,
            playerRepository,
            remotes,
            config,
            hooks);
    }

    public async Task<LocalRemote> CreateBareRemoteAsync(
        GitSandbox sandbox,
        GitProcessRunner processRunner,
        string name,
        string aliasUrl,
        CancellationToken cancellationToken = default)
    {
        ValidateIdentifier(name, nameof(name));
        EnsureInsideRoot(sandbox.AttemptRoot);

        var barePath = Path.Combine(sandbox.RemotesRoot, $"{name}.git");
        if (Directory.Exists(barePath) && Directory.EnumerateFileSystemEntries(barePath).Any())
            throw new InvalidOperationException($"Remote already exists: {barePath}");

        Directory.CreateDirectory(barePath);
        var init = await processRunner.RunAsync(
            sandbox,
            sandbox.RemotesRoot,
            ["init", "--bare", "--initial-branch=main", barePath],
            cancellationToken);
        if (!init.Success) throw new InvalidOperationException(init.Output);

        var remote = new LocalRemote(name, aliasUrl, barePath);
        await RegisterRemoteAsync(sandbox, processRunner, remote, cancellationToken);
        return remote;
    }

    public async Task RegisterRemoteAsync(
        GitSandbox sandbox,
        GitProcessRunner processRunner,
        LocalRemote remote,
        CancellationToken cancellationToken = default)
    {
        EnsureInsideRoot(sandbox.AttemptRoot);
        EnsureInsideRoot(remote.BareRepositoryPath);

        var rewrite = await processRunner.RunAsync(
            sandbox,
            sandbox.AttemptRoot,
            [
                "config",
                "--file",
                sandbox.GitConfigPath,
                $"url.{remote.BareRepositoryPath}.insteadOf",
                remote.AliasUrl
            ],
            cancellationToken);
        if (!rewrite.Success) throw new InvalidOperationException(rewrite.Output);
    }

    public void EnsureInsideRoot(string path)
    {
        var fullPath = Path.GetFullPath(path);
        var rootWithSeparator = RootPath.TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
        if (!fullPath.Equals(RootPath, _pathComparison) &&
            !fullPath.StartsWith(rootWithSeparator, _pathComparison))
            throw new InvalidOperationException("Path escapes the Git-Diwaa workspace root.");
    }

    private static void ValidateIdentifier(string value, string parameterName)
    {
        if (string.IsNullOrWhiteSpace(value) ||
            value.Any(character => !(char.IsAsciiLetterOrDigit(character) || character is '-' or '_')))
            throw new ArgumentException("Use only ASCII letters, numbers, '-' and '_'.", parameterName);
    }
}

