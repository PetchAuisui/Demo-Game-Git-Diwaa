using GitDiwaa.Core;

namespace GitDiwaa.RealGit;

internal sealed partial class FakeGitHubHost
{
    private readonly Dictionary<int, List<PullRequestReview>> _reviews = [];

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
        if (branches.Single(branch => branch.Name == sourceBranch).Ahead == 0 &&
            (await GitAsync(["rev-list", "--count", $"{targetBranch}..{sourceBranch}"], cancellationToken)) == "0")
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
        var pull = _pullRequests.FirstOrDefault(item => item.Number == number);
        if (pull is null) return null;

        var range = $"{pull.TargetBranch}..{pull.SourceBranch}";
        var triple = $"{pull.TargetBranch}...{pull.SourceBranch}";
        var commits = pull.State == PullRequestState.Merged
            ? []
            : (await GitAsync(["log", range, $"--format=%H{Sep}%an{Sep}%aI{Sep}%s"], cancellationToken))
                .Split('\n', StringSplitOptions.RemoveEmptyEntries).Select(ParseCommit).ToList();

        var files = new List<PullRequestFileChange>();
        var diff = string.Empty;
        if (pull.State != PullRequestState.Merged)
        {
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

        var conflicts = false;
        if (pull.State == PullRequestState.Open)
        {
            var probe = await _runner.RunAsync(_sandbox, _remote.BareRepositoryPath,
                ["merge-tree", "--write-tree", pull.TargetBranch, pull.SourceBranch], cancellationToken);
            conflicts = !probe.Success;
        }

        return new(pull, commits, files, diff, conflicts, _reviews.GetValueOrDefault(number)?.ToList() ?? []);
    }

    public PullRequestInfo? ReviewPullRequest(int number, string reviewer, ReviewVerdict verdict, string body = "")
    {
        var pull = _pullRequests.FirstOrDefault(item => item.Number == number);
        if (pull is null || pull.State != PullRequestState.Open) return pull;
        if (string.Equals(pull.Author, reviewer, StringComparison.OrdinalIgnoreCase) && verdict != ReviewVerdict.Commented)
            return pull; // เหมือน GitHub: อนุมัติ PR ของตัวเองไม่ได้

        var list = _reviews[number];
        list.Add(new(reviewer, verdict, body, DateTimeOffset.Now));
        var decisive = list.LastOrDefault(review => review.Verdict != ReviewVerdict.Commented);
        return Update(number, item => item with { IsApproved = decisive?.Verdict == ReviewVerdict.Approved });
    }

    public PullRequestInfo? ClosePullRequest(int number) =>
        Update(number, pull => pull.State == PullRequestState.Open ? pull with { State = PullRequestState.Closed } : pull);

    public async Task<PullRequestMergeResult> MergePullRequestAsync(
        int number, CancellationToken cancellationToken = default)
    {
        var pullRequest = _pullRequests.FirstOrDefault(item => item.Number == number);
        if (pullRequest is null) return new(false, $"Pull request #{number} not found.", null);
        if (pullRequest.State != PullRequestState.Open)
            return new(false, $"Pull request #{number} is already {pullRequest.State}.", pullRequest);
        if (!pullRequest.IsApproved)
            return new(false, "Review required: approve the pull request before merging.", pullRequest);

        var work = Path.Combine(_sandbox.AttemptRoot, $"merge-work-{number}");
        try
        {
            await StepAsync(_sandbox.AttemptRoot, ["clone", _remote.BareRepositoryPath, work], cancellationToken);
            await StepAsync(work, ["switch", "-c", "pr-target", $"origin/{pullRequest.TargetBranch}"], cancellationToken);
            await StepAsync(work,
                ["-c", $"user.name={Owner}", "-c", $"user.email={Owner.ToLowerInvariant()}@git-diwaa.local",
                 "merge", "--no-ff", $"origin/{pullRequest.SourceBranch}",
                 "-m", $"Merge pull request #{number} from {Owner}/{pullRequest.SourceBranch}"],
                cancellationToken);
            await StepAsync(work, ["push", "origin", $"pr-target:{pullRequest.TargetBranch}"], cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return new(false, $"Merge failed: {exception.Message}", pullRequest);
        }
        finally
        {
            RemoteSeeder.ForceDelete(work);
        }

        var merged = Update(number, item => item with { State = PullRequestState.Merged });
        return new(true, $"Pull request #{number} merged into {pullRequest.TargetBranch}.", merged);
    }

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
