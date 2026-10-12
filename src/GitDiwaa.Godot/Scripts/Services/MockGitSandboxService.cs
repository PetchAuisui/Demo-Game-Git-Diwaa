using GitDiwaa.Core;
using GitDiwaa.Godot.ViewModels;

namespace GitDiwaa.Godot.Services;

/// <summary>
/// Mock implementation of IGitSandboxService for UI testing, previews, and unit tests.
/// Demonstrates OOP polymorphism and decouples UI testing from real OS process execution.
/// </summary>
public sealed class MockGitSandboxService : IGitSandboxService
{
    private readonly List<FileDisplayItem> _files = new();
    private readonly List<CommitGraphDisplayNode> _commits = new();
    private readonly Dictionary<string, string> _fileContents = new(StringComparer.Ordinal);
    private readonly HashSet<string> _directories = new(StringComparer.Ordinal);
    private bool _isInitialized = true;
    private string _currentBranch = "main";

    public IGitRemoteHost? RemoteHost => null;
    public GitSessionInfo? Info => new("mock-01", "mock-attempt-1", "/tmp/mock-git-repo", "file:///tmp/mock-remote.git");
    public bool IsInitialized => _isInitialized;
    public string CurrentBranch => _currentBranch;

    public MockGitSandboxService()
    {
        SeedSampleData();
    }

    private void SeedSampleData()
    {
        _files.Clear();
        _files.Add(new FileDisplayItem("README.md", "README.md", GitFileState.Unchanged, GitFileState.Unchanged));
        _files.Add(new FileDisplayItem("src/Game.cs", "Game.cs", GitFileState.Modified, GitFileState.Modified));
        _files.Add(new FileDisplayItem("notes.txt", "notes.txt", GitFileState.Untracked, GitFileState.Untracked));
        _fileContents.Clear();
        _fileContents["README.md"] = "# Git-Diwaa\n";
        _fileContents["src/Game.cs"] = "public sealed class Game { }\n";
        _fileContents["notes.txt"] = "Learn git status\n";
        _directories.Clear();
        _directories.Add("src");

        _commits.Clear();
        var baseDate = DateTimeOffset.UtcNow.AddMinutes(-30);
        _commits.Add(new CommitGraphDisplayNode(
            Id: "a1b2c3d4e5f67890123456789012345678901234",
            ShortId: "a1b2c3d",
            ParentIds: Array.Empty<string>(),
            Branches: Array.Empty<string>(),
            IsCurrentBranchHead: false,
            Subject: "Initial commit: Add project skeleton",
            Author: "learner <learner@diwaa.dev>",
            AuthoredAt: baseDate
        ));
        _commits.Add(new CommitGraphDisplayNode(
            Id: "b2c3d4e5f67890123456789012345678901234a1",
            ShortId: "b2c3d4e",
            ParentIds: new[] { "a1b2c3d4e5f67890123456789012345678901234" },
            Branches: new[] { "main" },
            IsCurrentBranchHead: true,
            Subject: "feat: Add core mechanics and files",
            Author: "learner <learner@diwaa.dev>",
            AuthoredAt: baseDate.AddMinutes(15)
        ));
    }

    public Task InitializeAsync(string missionId = "checkpoint-01", string? attemptId = null, CancellationToken cancellationToken = default)
    {
        _isInitialized = true;
        SeedSampleData();
        return Task.CompletedTask;
    }

    public Task<GitCommandResult> ExecuteAsync(string commandLine, CancellationToken cancellationToken = default)
    {
        var trimmed = commandLine.Trim();

        if (trimmed == "git status")
        {
            var output = $"On branch {_currentBranch}\nChanges not staged for commit:\n  modified:   src/Game.cs\n\nUntracked files:\n  notes.txt\n";
            return Task.FromResult(new GitCommandResult(true, 0, output, string.Empty, trimmed));
        }

        if (trimmed.StartsWith("git checkout -b ") || trimmed.StartsWith("git switch -c "))
        {
            var parts = trimmed.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length >= 4)
            {
                _currentBranch = parts[3];
                return Task.FromResult(new GitCommandResult(true, 0, $"Switched to a new branch '{_currentBranch}'", string.Empty, trimmed));
            }
        }

        if (trimmed == "git --version")
        {
            return Task.FromResult(new GitCommandResult(true, 0, "git version 2.45.0 (Git-Diwaa Mock)", string.Empty, trimmed));
        }

        if (trimmed.StartsWith("git commit"))
        {
            var newId = Guid.NewGuid().ToString("N");
            _commits.Insert(0, new CommitGraphDisplayNode(
                Id: newId,
                ShortId: newId[..7],
                ParentIds: _commits.Count > 0 ? new[] { _commits[0].Id } : Array.Empty<string>(),
                Branches: new[] { _currentBranch },
                IsCurrentBranchHead: true,
                Subject: trimmed.Contains("-m") ? trimmed.Split("-m")[1].Trim(' ', '"', '\'') : "New commit",
                Author: "learner <learner@diwaa.dev>",
                AuthoredAt: DateTimeOffset.UtcNow
            ));
            return Task.FromResult(new GitCommandResult(true, 0, $"[{_currentBranch} {newId[..7]}] commit created", string.Empty, trimmed));
        }

        return Task.FromResult(new GitCommandResult(true, 0, $"Executed: {trimmed}", string.Empty, trimmed));
    }

    public Task<GitRepositorySnapshot> InspectAsync(CancellationToken cancellationToken = default)
    {
        var files = _files.Select(f => new GitFileStatus(f.Path, f.IndexState, f.WorkingTreeState)).ToList();
        var branches = new List<GitBranchInfo> { new(_currentBranch, true, _commits.FirstOrDefault()?.Id, null) };
        var commits = _commits.Select(c => new GitCommitNode(c.Id, c.ParentIds, c.Branches, c.Subject, c.Author, c.AuthoredAt)).ToList();

        return Task.FromResult(new GitRepositorySnapshot(true, _currentBranch, files, branches, commits));
    }

    public Task<IReadOnlyList<FileDisplayItem>> GetFilesAsync(CancellationToken cancellationToken = default)
    {
        return Task.FromResult<IReadOnlyList<FileDisplayItem>>(_files.ToList());
    }

    public Task<IReadOnlyList<WorkspaceEntryDisplayItem>> GetWorkspaceEntriesAsync(
        CancellationToken cancellationToken = default)
    {
        var entries = _directories
            .Select(path => new WorkspaceEntryDisplayItem(
                path, System.IO.Path.GetFileName(path), true,
                GitFileState.Unchanged, GitFileState.Unchanged))
            .Concat(_files.Select(file => new WorkspaceEntryDisplayItem(
                file.Path, file.FileName, false, file.IndexState, file.WorkingTreeState)))
            .OrderBy(entry => entry.Path, StringComparer.Ordinal)
            .ToArray();
        return Task.FromResult<IReadOnlyList<WorkspaceEntryDisplayItem>>(entries);
    }

    public Task<IReadOnlyList<CommitGraphDisplayNode>> GetCommitGraphAsync(CancellationToken cancellationToken = default)
    {
        return Task.FromResult<IReadOnlyList<CommitGraphDisplayNode>>(_commits.ToList());
    }

    public Task WriteFileAsync(string relativePath, string content, CancellationToken cancellationToken = default)
    {
        var existing = _files.FirstOrDefault(f => f.Path == relativePath);
        if (existing != null) _files.Remove(existing);
        var state = existing == null ? GitFileState.Untracked : GitFileState.Modified;
        _files.Add(new FileDisplayItem(relativePath, System.IO.Path.GetFileName(relativePath), state, state));
        _fileContents[relativePath] = content;
        AddParentDirectories(relativePath);
        return Task.CompletedTask;
    }

    public Task<string?> ReadFileAsync(string relativePath, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(_fileContents.GetValueOrDefault(relativePath));
    }

    public Task CreateDirectoryAsync(string relativePath, CancellationToken cancellationToken = default)
    {
        if (_files.Any(file => file.Path == relativePath) || _directories.Contains(relativePath))
            throw new IOException($"มีไฟล์หรือโฟลเดอร์ชื่อ '{relativePath}' อยู่แล้ว");
        _directories.Add(relativePath);
        AddParentDirectories(relativePath);
        return Task.CompletedTask;
    }

    public Task RenameEntryAsync(
        string sourceRelativePath,
        string destinationRelativePath,
        CancellationToken cancellationToken = default)
    {
        if (_files.Any(file => file.Path == destinationRelativePath) || _directories.Contains(destinationRelativePath))
            throw new IOException($"มีไฟล์หรือโฟลเดอร์ชื่อ '{destinationRelativePath}' อยู่แล้ว");

        var file = _files.FirstOrDefault(item => item.Path == sourceRelativePath);
        if (file != null)
        {
            _files.Remove(file);
            _files.Add(file with { Path = destinationRelativePath, FileName = System.IO.Path.GetFileName(destinationRelativePath) });
            _fileContents[destinationRelativePath] = _fileContents[sourceRelativePath];
            _fileContents.Remove(sourceRelativePath);
        }
        else if (_directories.Contains(sourceRelativePath))
        {
            var affectedDirectories = _directories
                .Where(path => path == sourceRelativePath || path.StartsWith(sourceRelativePath + "/", StringComparison.Ordinal))
                .ToArray();
            foreach (var path in affectedDirectories)
            {
                _directories.Remove(path);
                _directories.Add(destinationRelativePath + path[sourceRelativePath.Length..]);
            }

            var affectedFiles = _files
                .Where(item => item.Path.StartsWith(sourceRelativePath + "/", StringComparison.Ordinal))
                .ToArray();
            foreach (var item in affectedFiles)
            {
                var newPath = destinationRelativePath + item.Path[sourceRelativePath.Length..];
                _files.Remove(item);
                _files.Add(item with { Path = newPath, FileName = System.IO.Path.GetFileName(newPath) });
                _fileContents[newPath] = _fileContents[item.Path];
                _fileContents.Remove(item.Path);
            }
        }
        else
        {
            throw new FileNotFoundException($"ไม่พบ '{sourceRelativePath}'");
        }

        AddParentDirectories(destinationRelativePath);
        return Task.CompletedTask;
    }

    public bool DeleteFile(string relativePath)
    {
        var existing = _files.FirstOrDefault(f => f.Path == relativePath);
        if (existing != null)
        {
            _files.Remove(existing);
            _fileContents.Remove(relativePath);
            return true;
        }
        return false;
    }

    public bool DeleteEntry(string relativePath, bool isDirectory)
    {
        if (!isDirectory) return DeleteFile(relativePath);
        if (!_directories.Contains(relativePath)) return false;

        _directories.RemoveWhere(path =>
            path == relativePath || path.StartsWith(relativePath + "/", StringComparison.Ordinal));
        var filesToRemove = _files
            .Where(file => file.Path.StartsWith(relativePath + "/", StringComparison.Ordinal))
            .ToArray();
        foreach (var file in filesToRemove)
        {
            _files.Remove(file);
            _fileContents.Remove(file.Path);
        }
        return true;
    }

    public Task ResetAsync(CancellationToken cancellationToken = default)
    {
        SeedSampleData();
        return Task.CompletedTask;
    }

    public ValueTask DisposeAsync() => ValueTask.CompletedTask;

    private void AddParentDirectories(string path)
    {
        var current = System.IO.Path.GetDirectoryName(path)?.Replace('\\', '/');
        while (!string.IsNullOrEmpty(current) && current != ".")
        {
            _directories.Add(current);
            current = System.IO.Path.GetDirectoryName(current)?.Replace('\\', '/');
        }
    }
}
