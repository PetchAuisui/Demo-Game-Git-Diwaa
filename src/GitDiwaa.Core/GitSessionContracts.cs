namespace GitDiwaa.Core;

public sealed record GitSessionInfo(
    string MissionId,
    string AttemptId,
    string RepositoryPath,
    string RemoteUrl);

public interface IPlayerFileSystem
{
    Task WriteAllTextAsync(string relativePath, string content, CancellationToken cancellationToken = default);
    Task<string?> ReadAllTextAsync(string relativePath, CancellationToken cancellationToken = default);
    bool Delete(string relativePath);
    IReadOnlyList<string> ListFiles();
}

/// <summary>
/// Trusted operations used by floor scripts to prepare a scene (never exposed to the player).
/// Bypasses the command policy, but still runs inside the sandbox.
/// </summary>
public interface ISandboxAuthoring
{
    /// <summary>Virtual host the player types for remotes, e.g. <c>https://archive.diwaa/</c>.</summary>
    string VirtualRemoteBase { get; }

    /// <summary>Runs git with raw arguments in the player's current directory (or a named NPC workspace).</summary>
    Task<GitCommandResult> RunGitAsync(IReadOnlyList<string> arguments, string? npcWorkspace = null, CancellationToken cancellationToken = default);

    /// <summary>Creates an empty bare repository and returns the virtual URL the player can use.</summary>
    Task<string> CreateBareRemoteAsync(string name, CancellationToken cancellationToken = default);

    /// <summary>Writes a file inside an NPC workspace (another mage working on the shared archive).</summary>
    Task WriteNpcFileAsync(string npcWorkspace, string relativePath, string content, CancellationToken cancellationToken = default);
}

public interface IGitGameSession : IAsyncDisposable
{
    GitSessionInfo Info { get; }
    IPlayerFileSystem Files { get; }
    ISandboxAuthoring Authoring { get; }

    /// <summary>Current directory relative to the workspace root ("." when at the root).</summary>
    string CurrentDirectory { get; }

    /// <summary>Moves the player within the workspace (never outside). Returns an error message or null.</summary>
    string? ChangeDirectory(string relativePath);

    Task<GitCommandResult> ExecuteAsync(string commandLine, CancellationToken cancellationToken = default);
    Task<GitRepositorySnapshot> InspectAsync(CancellationToken cancellationToken = default);
}

public interface IGitGameSessionFactory
{
    Task<IGitGameSession> CreateAsync(
        string missionId,
        string attemptId,
        CancellationToken cancellationToken = default);
}
