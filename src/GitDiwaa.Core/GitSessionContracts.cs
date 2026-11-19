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

public interface IGitGameSession : IAsyncDisposable
{
    GitSessionInfo Info { get; }
    IPlayerFileSystem Files { get; }
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

