using GitDiwaa.Core;

namespace GitDiwaa.RealGit;

internal sealed partial class FakeGitHubHost
{
    public IReadOnlyList<PullRequestInfo> ListPullRequests() => _pullRequests.ToList();

    public async Task<PullRequestInfo> OpenPullRequestAsync(
        string title, string author, string sourceBranch, string targetBranch,
        CancellationToken cancellationToken = default)
    {
        var branches = await ListBranchesAsync(cancellationToken);
        if (!branches.Any(branch => branch.Name == sourceBranch) ||
            !branches.Any(branch => branch.Name == targetBranch))
            throw new InvalidOperationException("Both branches must exist on the remote.");
        if (sourceBranch == targetBranch)
            throw new InvalidOperationException("Source and target branch must differ.");

        var pullRequest = new PullRequestInfo(
            _pullRequests.Count + 1, title, author, sourceBranch, targetBranch,
            PullRequestState.Open, false, DateTimeOffset.Now);
        _pullRequests.Add(pullRequest);
        return pullRequest;
    }

    public PullRequestInfo? ApprovePullRequest(int number) =>
        Update(number, pullRequest => pullRequest.State == PullRequestState.Open
            ? pullRequest with { IsApproved = true }
            : pullRequest);

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
