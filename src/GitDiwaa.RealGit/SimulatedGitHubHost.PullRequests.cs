using GitDiwaa.Core;

namespace GitDiwaa.RealGit;

internal sealed partial class SimulatedGitHubHost
{
    private readonly Dictionary<int, List<PullRequestReview>> _reviews = [];
    private readonly Dictionary<int, PullRequestDetail> _mergedDetails = [];

    public IReadOnlyList<PullRequestInfo> ListPullRequests() => _pullRequests.ToList();

    public async Task<PullRequestInfo> OpenPullRequestAsync(
        string title, string body, string author, string sourceBranch, string targetBranch,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(title)) throw new InvalidOperationException("A title is required.");
        var branches = await ListBranchesAsync(cancellationToken);
        if (!branches.Any(branch => branch.Name == sourceBranch) ||
            !branches.Any(branch => branch.Name == targetBranch))
            throw new InvalidOperationException("Both branches must exist on the remote.");
        if (sourceBranch == targetBranch)
            throw new InvalidOperationException("Source and target branch must differ.");
        if (_pullRequests.Any(pr => pr.State == PullRequestState.Open &&
                                    pr.SourceBranch == sourceBranch && pr.TargetBranch == targetBranch))
            throw new InvalidOperationException("A pull request for these branches is already open.");
        if (await GitAsync(["rev-list", "--count", $"{targetBranch}..{sourceBranch}"], cancellationToken) == "0")
            throw new InvalidOperationException($"There is nothing to compare: {sourceBranch} has no new commits.");

        var pullRequest = new PullRequestInfo(
            _pullRequests.Count + 1, title, body, author, sourceBranch, targetBranch,
            PullRequestState.Open, false, DateTimeOffset.Now);
        _pullRequests.Add(pullRequest);
        _reviews[pullRequest.Number] = [];
        return pullRequest;
    }

    public async Task<PullRequestDetail?> GetPullRequestAsync(int number, CancellationToken cancellationToken = default)
    {
        var pull = Find(number);
        if (pull is null) return null;

        // หลัง merge แล้ว base..source ว่างเปล่า จึงคืนภาพ commit/ไฟล์/diff ที่บันทึกไว้ตอน merge
        if (pull.State == PullRequestState.Merged && _mergedDetails.TryGetValue(number, out var snapshot))
            return snapshot with { Pull = pull };

        var commits = new List<RemoteCommitInfo>();
        var files = new List<PullRequestFileChange>();
        var diff = string.Empty;
        if (pull.State != PullRequestState.Merged)
        {
            var range = $"{pull.TargetBranch}..{pull.SourceBranch}";
            var triple = $"{pull.TargetBranch}...{pull.SourceBranch}";
            commits.AddRange((await GitAsync(["log", range, $"--format=%H{Sep}%an{Sep}%aI{Sep}%s"], cancellationToken))
                .Split('\n', StringSplitOptions.RemoveEmptyEntries).Select(ParseCommit));

            var statuses = (await GitAsync(["diff", "--name-status", triple], cancellationToken))
                .Split('\n', StringSplitOptions.RemoveEmptyEntries)
                .Select(line => line.Split('\t'))
                .Where(parts => parts.Length >= 2)
                .ToDictionary(parts => parts[^1], parts => parts[0][..1]);
            foreach (var line in (await GitAsync(["diff", "--numstat", triple], cancellationToken))
                         .Split('\n', StringSplitOptions.RemoveEmptyEntries))
            {
                var parts = line.Split('\t');
                if (parts.Length < 3) continue;
                files.Add(new(parts[2], statuses.GetValueOrDefault(parts[2], "M"),
                    int.TryParse(parts[0], out var add) ? add : 0,
                    int.TryParse(parts[1], out var del) ? del : 0));
            }

            diff = await GitAsync(["diff", triple], cancellationToken);
            if (diff.Length > 20_000) diff = diff[..20_000] + "\n… (diff truncated)";
        }

        var (hasConflicts, blockedReason) = pull.State == PullRequestState.Open
            ? await CheckMergeAsync(pull, cancellationToken)
            : (false, null);
        return new(pull, commits, files, diff, hasConflicts,
            _reviews.GetValueOrDefault(number)?.ToList() ?? [], blockedReason);
    }

    public PullRequestActionResult ReviewPullRequest(int number, string reviewer, ReviewVerdict verdict, string body = "")
    {
        var pull = Find(number);
        if (pull is null) return NotFound(number);
        if (pull.State != PullRequestState.Open) return NotOpen(pull);

        if (verdict != ReviewVerdict.Commented && !_seed.Rules.AllowSelfReview &&
            string.Equals(pull.Author, reviewer, StringComparison.OrdinalIgnoreCase))
            return new(false, "You can't approve or request changes on your own pull request.", pull);

        var reviews = _reviews[number];
        reviews.Add(new(reviewer, verdict, body, DateTimeOffset.Now));
        var decision = reviews.LastOrDefault(review => review.Verdict != ReviewVerdict.Commented);
        var updated = Update(number, item => item with { IsApproved = decision?.Verdict == ReviewVerdict.Approved })!;
        return new(true, verdict switch
        {
            ReviewVerdict.Approved => $"Approved pull request #{number}.",
            ReviewVerdict.ChangesRequested => $"Requested changes on pull request #{number}.",
            _ => $"Comment added to pull request #{number}."
        }, updated);
    }

    public PullRequestActionResult ClosePullRequest(int number)
    {
        var pull = Find(number);
        if (pull is null) return NotFound(number);
        if (pull.State != PullRequestState.Open) return NotOpen(pull);

        var closed = Update(number, item => item with { State = PullRequestState.Closed })!;
        return new(true, $"Pull request #{number} closed.", closed);
    }

    public async Task<PullRequestActionResult> MergePullRequestAsync(
        int number, CancellationToken cancellationToken = default)
    {
        var pull = Find(number);
        if (pull is null) return NotFound(number);
        if (pull.State != PullRequestState.Open) return NotOpen(pull);

        var (_, blockedReason) = await CheckMergeAsync(pull, cancellationToken);
        if (blockedReason is not null) return new(false, blockedReason, pull);
        var beforeMerge = await GetPullRequestAsync(number, cancellationToken);

        var work = Path.Combine(_sandbox.AttemptRoot, $"merge-work-{number}");
        try
        {
            await StepAsync(_sandbox.AttemptRoot, ["clone", _remote.BareRepositoryPath, work], cancellationToken);
            await StepAsync(work, ["switch", "-c", "pr-target", $"origin/{pull.TargetBranch}"], cancellationToken);
            await StepAsync(work,
                ["-c", $"user.name={Owner}", "-c", $"user.email={Owner.ToLowerInvariant()}@git-diwaa.local",
                 "merge", "--no-ff", $"origin/{pull.SourceBranch}",
                 "-m", $"Merge pull request #{number} from {Owner}/{pull.SourceBranch}"],
                cancellationToken);
            await StepAsync(work, ["push", "origin", $"pr-target:{pull.TargetBranch}"], cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return new(false, $"Merge failed: {exception.Message}", pull);
        }
        finally
        {
            RemoteSeeder.ForceDelete(work);
        }

        var merged = Update(number, item => item with { State = PullRequestState.Merged })!;
        if (beforeMerge is not null)
            _mergedDetails[number] = beforeMerge with { Pull = merged, HasConflicts = false, MergeBlockedReason = null };
        return new(true, $"Pull request #{number} merged into {pull.TargetBranch}.", merged);
    }

    /// <summary>ตรวจว่า merge ได้ไหม: conflict (ตรวจจริงด้วย git merge-tree) และกติกา review ของ repo</summary>
    private async Task<(bool HasConflicts, string? BlockedReason)> CheckMergeAsync(
        PullRequestInfo pull, CancellationToken cancellationToken)
    {
        var probe = await _runner.RunAsync(_sandbox, _remote.BareRepositoryPath,
            ["merge-tree", "--write-tree", pull.TargetBranch, pull.SourceBranch], cancellationToken);
        if (!probe.Success)
        {
            return probe.ExitCode == 1
                ? (true, "This branch has conflicts that must be resolved.")
                : (false, $"Unable to check whether this pull request can be merged: {probe.Output}");
        }

        return _seed.Rules.RequireApproval && !pull.IsApproved
            ? (false, "Review required: approve the pull request before merging.")
            : (false, null);
    }

    private PullRequestInfo? Find(int number) => _pullRequests.FirstOrDefault(item => item.Number == number);

    private static PullRequestActionResult NotFound(int number) =>
        new(false, $"Pull request #{number} not found.", null);

    private static PullRequestActionResult NotOpen(PullRequestInfo pull) =>
        new(false, $"Pull request #{pull.Number} is already {pull.State}.", pull);

    private PullRequestInfo? Update(int number, Func<PullRequestInfo, PullRequestInfo> change)
    {
        var index = _pullRequests.FindIndex(item => item.Number == number);
        if (index < 0) return null;
        return _pullRequests[index] = change(_pullRequests[index]);
    }

    private async Task StepAsync(string directory, IReadOnlyList<string> arguments, CancellationToken cancellationToken)
    {
        var result = await _runner.RunAsync(_sandbox, directory, arguments, cancellationToken);
        if (!result.Success) throw new InvalidOperationException(result.Output);
    }
}
