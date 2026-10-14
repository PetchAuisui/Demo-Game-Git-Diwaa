namespace GitDiwaa.Core;

public sealed record RemoteRepositoryInfo(
    string Owner,
    string Name,
    string Description,
    string CloneUrl,
    string DefaultBranch,
    int BranchCount,
    int CommitCount)
{
    /// <summary>ยังไม่มี branch ใดถูก push ขึ้นมา (หน้า Quick setup)</summary>
    public bool IsEmpty => BranchCount == 0;
}

public sealed record RemoteBranchInfo(
    string Name,
    string CommitId,
    bool IsDefault,
    int Ahead,
    int Behind,
    string LastCommitSubject,
    DateTimeOffset LastCommitAt);

public sealed record RemoteCommitInfo(
    string Id,
    string ShortId,
    string Author,
    string Subject,
    DateTimeOffset AuthoredAt);

public sealed record RemoteFileEntry(string Name, string Path, bool IsDirectory, RemoteCommitInfo? LastCommit);

public enum PullRequestState
{
    Open,
    Merged,
    Closed
}

public enum ReviewVerdict
{
    Approved,
    ChangesRequested,
    Commented
}

public sealed record PullRequestReview(string Reviewer, ReviewVerdict Verdict, string Body, DateTimeOffset At);

public sealed record PullRequestInfo(
    int Number,
    string Title,
    string Body,
    string Author,
    string SourceBranch,
    string TargetBranch,
    PullRequestState State,
    bool IsApproved,
    DateTimeOffset CreatedAt);

public sealed record PullRequestFileChange(string Path, string Status, int Additions, int Deletions);

public sealed record PullRequestDetail(
    PullRequestInfo Pull,
    IReadOnlyList<RemoteCommitInfo> Commits,
    IReadOnlyList<PullRequestFileChange> Files,
    string Diff,
    bool HasConflicts,
    IReadOnlyList<PullRequestReview> Reviews,
    string? MergeBlockedReason);

/// <summary>ผลของการกระทำกับ pull request (review / close / merge) พร้อมข้อความอธิบายให้ UI แสดง</summary>
public sealed record PullRequestActionResult(bool Success, string Message, PullRequestInfo? PullRequest);

/// <summary>
/// ข้อมูลและการกระทำของหน้า Remote Repository ที่จำลอง GitHub
/// (Code / Commits / Branches / Pull requests) โดยไม่ออกเครือข่ายจริง
/// </summary>
public interface IGitRemoteHost
{
    Task<RemoteRepositoryInfo> GetRepositoryAsync(CancellationToken cancellationToken = default);

    Task<IReadOnlyList<RemoteBranchInfo>> ListBranchesAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<RemoteCommitInfo>> ListCommitsAsync(
        string branch, int limit = 30, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<RemoteFileEntry>> ListFilesAsync(
        string branch, string path = "", CancellationToken cancellationToken = default);
    Task<string?> ReadFileAsync(string branch, string path, CancellationToken cancellationToken = default);
    Task<bool> DeleteBranchAsync(string branch, CancellationToken cancellationToken = default);

    IReadOnlyList<PullRequestInfo> ListPullRequests();
    Task<PullRequestInfo> OpenPullRequestAsync(
        string title, string body, string author, string sourceBranch, string targetBranch,
        CancellationToken cancellationToken = default);
    Task<PullRequestDetail?> GetPullRequestAsync(int number, CancellationToken cancellationToken = default);
    PullRequestActionResult ReviewPullRequest(int number, string reviewer, ReviewVerdict verdict, string body = "");
    PullRequestActionResult ClosePullRequest(int number);
    Task<PullRequestActionResult> MergePullRequestAsync(int number, CancellationToken cancellationToken = default);
}

/// <summary>
/// บัญชีผู้เล่นบน GitHub จำลอง: มีได้หลาย repo เลือกเปิดและสร้างใหม่ได้เหมือน GitHub จริง
/// แต่ละ repo เป็น <see cref="IGitRemoteHost"/> ของตัวเอง (PR/branch แยกกัน)
/// </summary>
public interface IGitRemoteAccount
{
    string Owner { get; }
    Task<IReadOnlyList<RemoteRepositoryInfo>> ListRepositoriesAsync(CancellationToken cancellationToken = default);

    /// <summary>host ของ repo ตามชื่อ (ไม่สนตัวพิมพ์ใหญ่เล็ก) หรือ null ถ้าไม่มี</summary>
    IGitRemoteHost? OpenRepository(string name);

    /// <summary>สร้าง repo ว่างใหม่ ชื่อซ้ำหรือไม่ถูกรูปแบบจะโยน <see cref="InvalidOperationException"/> พร้อมข้อความที่แสดงให้ผู้เล่นอ่านได้</summary>
    Task<RemoteRepositoryInfo> CreateRepositoryAsync(
        string name, string description, CancellationToken cancellationToken = default);
}
