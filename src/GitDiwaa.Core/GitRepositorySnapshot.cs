namespace GitDiwaa.Core;

public enum GitFileState
{
    Untracked,
    Added,
    Modified,
    Deleted,
    Renamed,
    Copied,
    Unmerged,
    Unknown
}

public sealed record GitFileStatus(string Path, GitFileState IndexState, GitFileState WorkingTreeState);

public sealed record GitBranchInfo(string Name, bool IsCurrent, string? CommitId, string? Upstream);

public sealed record GitCommitNode(
    string Id,
    IReadOnlyList<string> ParentIds,
    IReadOnlyList<string> References,
    string Subject,
    string Author,
    DateTimeOffset AuthoredAt);

public sealed record GitRepositorySnapshot(
    bool IsInitialized,
    string? CurrentBranch,
    IReadOnlyList<GitFileStatus> Files,
    IReadOnlyList<GitBranchInfo> Branches,
    IReadOnlyList<GitCommitNode> Commits);

