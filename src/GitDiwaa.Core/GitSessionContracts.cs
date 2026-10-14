namespace GitDiwaa.Core;

public sealed record GitSessionInfo(
    string MissionId,
    string AttemptId,
    string RepositoryPath,
    string RemoteUrl);

public sealed record PlayerWorkspaceEntry(string Path, bool IsDirectory);

public interface IPlayerFileSystem
{
    Task WriteAllTextAsync(string relativePath, string content, CancellationToken cancellationToken = default);
    Task<string?> ReadAllTextAsync(string relativePath, CancellationToken cancellationToken = default);
    void CreateDirectory(string relativePath);
    void Move(string sourceRelativePath, string destinationRelativePath);
    bool Delete(string relativePath);
    bool DeleteDirectory(string relativePath, bool recursive = false);
    IReadOnlyList<string> ListFiles();
    IReadOnlyList<PlayerWorkspaceEntry> ListEntries();
}

public interface IGitGameSession : IAsyncDisposable
{
    GitSessionInfo Info { get; }
    IPlayerFileSystem Files { get; }
    /// <summary>host ของ repo แรกจาก seed ของด่าน (null ถ้าบัญชีเริ่มโดยไม่มี repo ใช้ <see cref="RemoteAccount"/> แทน)</summary>
    IGitRemoteHost? RemoteHost { get; }

    /// <summary>บัญชีที่มีหลาย repo บน GitHub จำลอง (null ถ้า session ไม่รองรับ)</summary>
    IGitRemoteAccount? RemoteAccount => null;

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
