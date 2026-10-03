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
    private bool _isInitialized = true;
    private string _currentBranch = "main";

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

    public Task<IReadOnlyList<CommitGraphDisplayNode>> GetCommitGraphAsync(CancellationToken cancellationToken = default)
    {
        return Task.FromResult<IReadOnlyList<CommitGraphDisplayNode>>(_commits.ToList());
    }

    public Task WriteFileAsync(string relativePath, string content, CancellationToken cancellationToken = default)
    {
        var existing = _files.FirstOrDefault(f => f.Path == relativePath);
        if (existing != null) _files.Remove(existing);
        _files.Add(new FileDisplayItem(relativePath, System.IO.Path.GetFileName(relativePath), GitFileState.Untracked, GitFileState.Untracked));
        return Task.CompletedTask;
    }

    public Task<string?> ReadFileAsync(string relativePath, CancellationToken cancellationToken = default)
    {
        return Task.FromResult<string?>($"Content of {relativePath}");
    }

    public bool DeleteFile(string relativePath)
    {
        var existing = _files.FirstOrDefault(f => f.Path == relativePath);
        if (existing != null)
        {
            _files.Remove(existing);
            return true;
        }
        return false;
    }

    public Task ResetAsync(CancellationToken cancellationToken = default)
    {
        SeedSampleData();
        return Task.CompletedTask;
    }

    public ValueTask DisposeAsync() => ValueTask.CompletedTask;
}
