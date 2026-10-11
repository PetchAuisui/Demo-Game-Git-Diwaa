namespace GitDiwaa.Core.Levels;

public sealed record ExpectedFile(string Path, GitFileState? IndexState = null, GitFileState? WorkingTreeState = null);

public sealed record StateComparison(bool IsMatch, IReadOnlyList<string> Mismatches);

/// <summary>
/// Final repository state a level expects. Every null / empty member is "don't care",
/// so equivalent command sequences that reach the same state both pass.
/// </summary>
public sealed record ExpectedRepositoryState
{
    public bool? IsInitialized { get; init; }
    public string? CurrentBranch { get; init; }
    public IReadOnlyList<string> RequiredBranches { get; init; } = [];
    public IReadOnlyList<ExpectedFile> Files { get; init; } = [];
    public int? MinCommitCount { get; init; }
    public int? MaxCommitCount { get; init; }
    public IReadOnlyList<string> RequiredCommitSubjects { get; init; } = [];
    public bool? RequireCleanWorkingTree { get; init; }

    public StateComparison Compare(GitRepositorySnapshot player)
    {
        var mismatches = new List<string>();

        if (IsInitialized is { } init && player.IsInitialized != init)
            mismatches.Add($"initialized: expected {init}, got {player.IsInitialized}");

        if (CurrentBranch is not null && player.CurrentBranch != CurrentBranch)
            mismatches.Add($"current branch: expected '{CurrentBranch}', got '{player.CurrentBranch}'");

        foreach (var branch in RequiredBranches)
            if (!player.Branches.Any(b => b.Name == branch))
                mismatches.Add($"missing branch '{branch}'");

        foreach (var expected in Files)
        {
            var actual = player.Files.FirstOrDefault(f => f.Path == expected.Path);
            if (actual is null)
            {
                mismatches.Add($"missing file status for '{expected.Path}'");
                continue;
            }
            if (expected.IndexState is { } i && actual.IndexState != i)
                mismatches.Add($"'{expected.Path}' index: expected {i}, got {actual.IndexState}");
            if (expected.WorkingTreeState is { } w && actual.WorkingTreeState != w)
                mismatches.Add($"'{expected.Path}' working tree: expected {w}, got {actual.WorkingTreeState}");
        }

        var count = player.Commits.Count;
        if (MinCommitCount is { } min && count < min)
            mismatches.Add($"commits: expected at least {min}, got {count}");
        if (MaxCommitCount is { } max && count > max)
            mismatches.Add($"commits: expected at most {max}, got {count}");

        foreach (var subject in RequiredCommitSubjects)
            if (!player.Commits.Any(c => c.Subject == subject))
                mismatches.Add($"missing commit '{subject}'");

        if (RequireCleanWorkingTree == true
            && player.Files.Any(f => f.IndexState != GitFileState.Unchanged || f.WorkingTreeState != GitFileState.Unchanged))
            mismatches.Add("working tree is not clean");

        return new StateComparison(mismatches.Count == 0, mismatches);
    }
}
