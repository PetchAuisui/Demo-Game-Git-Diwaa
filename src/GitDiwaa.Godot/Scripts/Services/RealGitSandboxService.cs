using System.IO;
using GitDiwaa.Core;
using GitDiwaa.Godot.ViewModels;
using GitDiwaa.RealGit;
using Godot;

namespace GitDiwaa.Godot.Services;

/// <summary>
/// Real Git sandbox service that wraps GitDiwaa.RealGit engine.
/// Provides isolated workspace directory, runs real Git CLI, and produces snapshot ViewModels.
/// </summary>
public sealed class RealGitSandboxService : IGitSandboxService
{
    private readonly string _workspaceRoot;
    private readonly string _playerName;
    private IGitGameSessionFactory? _factory;
    private IGitGameSession? _session;
    private GitRepositorySnapshot? _lastSnapshot;

    public GitSessionInfo? Info => _session?.Info;
    public bool IsInitialized => _session != null;
    public IGitRemoteHost? RemoteHost => _session?.RemoteHost;
    public IGitRemoteAccount? RemoteAccount => _session?.RemoteAccount;
    public string CurrentBranch => _lastSnapshot?.CurrentBranch ?? "main";

    /// <param name="customWorkspaceRoot">โฟลเดอร์เก็บ workspace (ค่าเริ่มต้น user://git-workspaces)</param>
    /// <param name="playerName">ชื่อผู้เล่น ใช้เป็นเจ้าของ repo บน GitHub จำลอง (ยังไม่มีหน้า login จึงใช้ "user")</param>
    public RealGitSandboxService(string? customWorkspaceRoot = null, string playerName = RemoteSeed.DefaultOwner)
    {
        _playerName = playerName;

        if (!string.IsNullOrWhiteSpace(customWorkspaceRoot))
        {
            _workspaceRoot = customWorkspaceRoot;
            return;
        }

        try
        {
            var preferredRoot = ProjectSettings.GlobalizePath("user://git-workspaces");
            Directory.CreateDirectory(preferredRoot);
            var testFile = Path.Combine(preferredRoot, $".test_{Guid.NewGuid():N}");
            File.WriteAllText(testFile, "test");
            File.Delete(testFile);
            _workspaceRoot = preferredRoot;
            return;
        }
        catch
        {
            // If user:// path cannot be written to, fallback to system temp
        }

        var tempRoot = Path.Combine(Path.GetTempPath(), "git-diwaa-workspaces");
        Directory.CreateDirectory(tempRoot);
        _workspaceRoot = tempRoot;
    }

    public async Task InitializeAsync(
        string missionId = "checkpoint-01",
        string? attemptId = null,
        CancellationToken cancellationToken = default)
    {
        attemptId ??= $"attempt-{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}";
        _factory = new RealGitGameSessionFactory(_workspaceRoot, _playerName);

        if (_session != null)
        {
            await _session.DisposeAsync();
            _session = null;
        }

        _session = await _factory.CreateAsync(missionId, attemptId, cancellationToken);
        _lastSnapshot = await _session.InspectAsync(cancellationToken);
    }

    public async Task<GitCommandResult> ExecuteAsync(
        string commandLine,
        CancellationToken cancellationToken = default)
    {
        EnsureSession();
        var result = await _session!.ExecuteAsync(commandLine, cancellationToken);
        _lastSnapshot = await _session.InspectAsync(cancellationToken);
        return result;
    }

    public async Task<GitRepositorySnapshot> InspectAsync(CancellationToken cancellationToken = default)
    {
        EnsureSession();
        _lastSnapshot = await _session!.InspectAsync(cancellationToken);
        return _lastSnapshot;
    }

    public async Task<IReadOnlyList<FileDisplayItem>> GetFilesAsync(CancellationToken cancellationToken = default)
    {
        EnsureSession();
        _lastSnapshot = await _session!.InspectAsync(cancellationToken);

        var fileItems = new List<FileDisplayItem>();
        foreach (var file in _lastSnapshot.Files)
        {
            fileItems.Add(new FileDisplayItem(
                Path: file.Path,
                FileName: System.IO.Path.GetFileName(file.Path),
                IndexState: file.IndexState,
                WorkingTreeState: file.WorkingTreeState
            ));
        }

        return fileItems;
    }

    public async Task<IReadOnlyList<WorkspaceEntryDisplayItem>> GetWorkspaceEntriesAsync(
        CancellationToken cancellationToken = default)
    {
        EnsureSession();
        _lastSnapshot = await _session!.InspectAsync(cancellationToken);
        var statusByPath = _lastSnapshot.Files.ToDictionary(file => file.Path, StringComparer.Ordinal);

        return _session.Files.ListEntries()
            .Select(entry =>
            {
                statusByPath.TryGetValue(entry.Path, out var status);
                return new WorkspaceEntryDisplayItem(
                    entry.Path,
                    Path.GetFileName(entry.Path),
                    entry.IsDirectory,
                    status?.IndexState ?? GitFileState.Unknown,
                    status?.WorkingTreeState ?? GitFileState.Unknown);
            })
            .ToArray();
    }

    public async Task<IReadOnlyList<CommitGraphDisplayNode>> GetCommitGraphAsync(CancellationToken cancellationToken = default)
    {
        EnsureSession();
        _lastSnapshot = await _session!.InspectAsync(cancellationToken);

        var nodes = new List<CommitGraphDisplayNode>();
        foreach (var commit in _lastSnapshot.Commits)
        {
            nodes.Add(CommitGraphDisplayNode.FromCoreCommit(
                commit,
                _lastSnapshot.Branches,
                _lastSnapshot.CurrentBranch
            ));
        }

        return nodes;
    }

    public async Task WriteFileAsync(
        string relativePath,
        string content,
        CancellationToken cancellationToken = default)
    {
        EnsureSession();
        await _session!.Files.WriteAllTextAsync(relativePath, content, cancellationToken);
        _lastSnapshot = await _session.InspectAsync(cancellationToken);
    }

    public async Task<string?> ReadFileAsync(
        string relativePath,
        CancellationToken cancellationToken = default)
    {
        EnsureSession();
        return await _session!.Files.ReadAllTextAsync(relativePath, cancellationToken);
    }

    public Task CreateDirectoryAsync(
        string relativePath,
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        EnsureSession();
        _session!.Files.CreateDirectory(relativePath);
        return Task.CompletedTask;
    }

    public Task RenameEntryAsync(
        string sourceRelativePath,
        string destinationRelativePath,
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        EnsureSession();
        _session!.Files.Move(sourceRelativePath, destinationRelativePath);
        return Task.CompletedTask;
    }

    public bool DeleteFile(string relativePath)
    {
        EnsureSession();
        var deleted = _session!.Files.Delete(relativePath);
        return deleted;
    }

    public bool DeleteEntry(string relativePath, bool isDirectory)
    {
        EnsureSession();
        return isDirectory
            ? _session!.Files.DeleteDirectory(relativePath, recursive: true)
            : _session!.Files.Delete(relativePath);
    }

    public async Task ResetAsync(CancellationToken cancellationToken = default)
    {
        await InitializeAsync(cancellationToken: cancellationToken);
    }

    public async ValueTask DisposeAsync()
    {
        if (_session != null)
        {
            await _session.DisposeAsync();
            _session = null;
        }
    }

    private void EnsureSession()
    {
        if (_session == null)
        {
            throw new InvalidOperationException("Git sandbox session has not been initialized. Call InitializeAsync() first.");
        }
    }
}
