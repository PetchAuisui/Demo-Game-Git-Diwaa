using GitDiwaa.Core;
using GitDiwaa.Godot.ViewModels;

namespace GitDiwaa.Godot.Services;

/// <summary>
/// Domain contract for Git Sandbox operations in the Godot UI.
/// Decouples UI components from Real Git execution and filesystem details.
/// </summary>
public interface IGitSandboxService : IAsyncDisposable
{
    GitSessionInfo? Info { get; }
    bool IsInitialized { get; }
    /// <summary>หน้า Remote Repository จำลอง (null เมื่อใช้ mock service)</summary>
    IGitRemoteHost? RemoteHost { get; }
    string CurrentBranch { get; }

    Task InitializeAsync(string missionId = "checkpoint-01", string? attemptId = null, CancellationToken cancellationToken = default);
    Task<GitCommandResult> ExecuteAsync(string commandLine, CancellationToken cancellationToken = default);
    Task<GitRepositorySnapshot> InspectAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<FileDisplayItem>> GetFilesAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<WorkspaceEntryDisplayItem>> GetWorkspaceEntriesAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<CommitGraphDisplayNode>> GetCommitGraphAsync(CancellationToken cancellationToken = default);
    Task WriteFileAsync(string relativePath, string content, CancellationToken cancellationToken = default);
    Task<string?> ReadFileAsync(string relativePath, CancellationToken cancellationToken = default);
    Task CreateDirectoryAsync(string relativePath, CancellationToken cancellationToken = default);
    Task RenameEntryAsync(string sourceRelativePath, string destinationRelativePath, CancellationToken cancellationToken = default);
    bool DeleteFile(string relativePath);
    bool DeleteEntry(string relativePath, bool isDirectory);
    Task ResetAsync(CancellationToken cancellationToken = default);
}
