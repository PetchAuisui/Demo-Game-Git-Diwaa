namespace GitDiwaa.Core;

public sealed record RemoteRepositoryInfo(
    string Owner,
    string Name,
    string Description,
    string CloneUrl,
    string DefaultBranch,
    int BranchCount,
    int CommitCount);

public sealed record RemoteBranchInfo(string Name, string CommitId, bool IsDefault);

public sealed record RemoteCommitInfo(
    string Id,
    string ShortId,
    string Author,
    string Subject,
    DateTimeOffset AuthoredAt);

public sealed record RemoteFileEntry(string Name, bool IsDirectory, RemoteCommitInfo? LastCommit);

public enum PullRequestState
{
    Open,
    Merged,
    Closed
}

public sealed record PullRequestInfo(
    int Number,
    string Title,
    string Author,
    string SourceBranch,
    string TargetBranch,
    PullRequestState State,
    bool IsApproved,
    DateTimeOffset CreatedAt);

public sealed record PullRequestMergeResult(bool Success, string Message, PullRequestInfo? PullRequest);

/// <summary>
/// ข้อมูลหน้า Remote Repository (Code / Branches / Pull requests) ที่จำลอง GitHub
/// โดยไม่ออกเครือข่ายจริง
/// </summary>
public interface IGitRemoteHost
{
    Task<RemoteRepositoryInfo> GetRepositoryAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<RemoteBranchInfo>> ListBranchesAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<RemoteCommitInfo>> ListCommitsAsync(
        string branch, int limit = 30, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<RemoteFileEntry>> ListFilesAsync(
        string branch, CancellationToken cancellationToken = default);
    Task<string?> ReadFileAsync(string branch, string path, CancellationToken cancellationToken = default);

    IReadOnlyList<PullRequestInfo> ListPullRequests();
    Task<PullRequestInfo> OpenPullRequestAsync(
        string title, string author, string sourceBranch, string targetBranch,
        CancellationToken cancellationToken = default);
    PullRequestInfo? ApprovePullRequest(int number);
    Task<PullRequestMergeResult> MergePullRequestAsync(int number, CancellationToken cancellationToken = default);
}
