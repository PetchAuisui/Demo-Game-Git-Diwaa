namespace GitDiwaa.Core;

public enum GitFileState
{
    Unmodified,
    Untracked,
    Added,
    Modified,
    Deleted,
    Renamed,
    Copied,
    Unmerged,
    Unknown
}

public sealed record GitFileStatus(string Path, GitFileState IndexState, GitFileState WorkingTreeState)
{
    public bool IsUntracked => IndexState == GitFileState.Untracked;
    public bool IsStaged => IndexState is not (GitFileState.Unmodified or GitFileState.Untracked or GitFileState.Unmerged);
    public bool HasUnstagedChanges => WorkingTreeState is not (GitFileState.Unmodified or GitFileState.Untracked);
    public bool IsUnmerged => IndexState == GitFileState.Unmerged || WorkingTreeState == GitFileState.Unmerged;
}

public sealed record GitBranchInfo(string Name, bool IsCurrent, string? CommitId, string? Upstream, bool IsRemote = false);

public sealed record GitRemoteInfo(string Name, string FetchUrl);

public sealed record GitCommitNode(
    string Id,
    IReadOnlyList<string> ParentIds,
    IReadOnlyList<string> References,
    string Subject,
    string Author,
    DateTimeOffset AuthoredAt)
{
    public string ShortId => Id.Length > 7 ? Id[..7] : Id;
    public bool IsMerge => ParentIds.Count > 1;
}

public sealed record GitRepositorySnapshot(
    bool IsInitialized,
    string? CurrentBranch,
    IReadOnlyList<GitFileStatus> Files,
    IReadOnlyList<GitBranchInfo> Branches,
    IReadOnlyList<GitCommitNode> Commits)
{
    public static GitRepositorySnapshot Empty { get; } = new(false, null, [], [], []);

    /// <summary>Directory (relative to the player's workspace root) the snapshot was taken from.</summary>
    public string CurrentDirectory { get; init; } = ".";
    public string? HeadCommitId { get; init; }
    public bool IsMerging { get; init; }
    public string? UserName { get; init; }
    public string? UserEmail { get; init; }
    public IReadOnlyList<string> TrackedFiles { get; init; } = [];
    public IReadOnlyList<string> WorkspaceFiles { get; init; } = [];
    public IReadOnlyList<GitRemoteInfo> Remotes { get; init; } = [];

    public IEnumerable<GitBranchInfo> LocalBranches => Branches.Where(b => !b.IsRemote);
    public IEnumerable<GitBranchInfo> RemoteBranches => Branches.Where(b => b.IsRemote);
    public IEnumerable<GitFileStatus> StagedFiles => Files.Where(f => f.IsStaged);
    public IEnumerable<GitFileStatus> UntrackedFiles => Files.Where(f => f.IsUntracked);
    public IEnumerable<GitFileStatus> ModifiedFiles => Files.Where(f => f.HasUnstagedChanges);
    public IEnumerable<GitFileStatus> UnmergedFiles => Files.Where(f => f.IsUnmerged);
    public bool IsClean => Files.Count == 0;

    public GitCommitNode? Head => HeadCommitId is null ? null : Commits.FirstOrDefault(c => c.Id == HeadCommitId);

    /// <summary>Number of commits reachable from HEAD (first-parent and merge parents).</summary>
    public int HeadHistoryLength
    {
        get
        {
            if (HeadCommitId is null) return 0;
            var byId = Commits.ToDictionary(c => c.Id);
            var seen = new HashSet<string>();
            var stack = new Stack<string>();
            stack.Push(HeadCommitId);
            while (stack.Count > 0)
            {
                var id = stack.Pop();
                if (!seen.Add(id) || !byId.TryGetValue(id, out var node)) continue;
                foreach (var p in node.ParentIds) stack.Push(p);
            }
            return seen.Count;
        }
    }

    public GitBranchInfo? FindBranch(string name) => Branches.FirstOrDefault(b => b.Name == name);
    public GitFileStatus? FindFile(string path) => Files.FirstOrDefault(f => f.Path == path);
    public bool IsTracked(string path) => TrackedFiles.Contains(path);
}
