namespace GitDiwaa.Core.Game;

public enum EffectKind
{
    RuneGlow,         // --version
    NameBound,        // config user.name / user.email
    TomeCreated,      // init
    Revealed,         // observation spells (status/log/diff/show)
    ToAltar,          // staged more files
    FromAltar,        // unstaged without committing
    Inscribed,        // new commit at HEAD
    TimeRewind,       // HEAD moved back in history
    CurseLifted,      // working-tree changes discarded
    DimensionSplit,   // new branch
    DimensionClosed,  // deleted branch
    DimensionStep,    // switched branch
    DimensionsMerged, // merge commit
    DimensionClash,   // conflict
    ArchiveCopied,    // clone
    BondCreated,      // remote added / changed
    PortalSend,       // push
    PortalReceive,    // pull / fetch brought commits
    Fizzle,           // failed or rejected command
}

public sealed record WorldEffect(EffectKind Kind, string Detail = "");

/// <summary>
/// Decides which visual effect to play by comparing repository state before and after a spell.
/// The UI never guesses from the command text alone, so effects always match what git really did.
/// </summary>
public static class EffectDetector
{
    private static readonly HashSet<string> Observations = ["status", "log", "diff", "show", "branch", "remote"];

    public static IReadOnlyList<WorldEffect> Detect(
        GitRepositorySnapshot before,
        GitRepositorySnapshot after,
        string commandLine,
        GitCommandResult result)
    {
        var key = Spellbook.KeyOf(commandLine);
        var effects = new List<WorldEffect>();

        if (!result.Success)
        {
            // A failed merge still changes the world: the dimensions clash.
            if (key == "merge" && after.UnmergedFiles.Any())
                effects.Add(new(EffectKind.DimensionClash, string.Join(", ", after.UnmergedFiles.Select(f => f.Path))));
            else if (key == "pull" && after.UnmergedFiles.Any())
                effects.Add(new(EffectKind.DimensionClash, string.Join(", ", after.UnmergedFiles.Select(f => f.Path))));
            else
                effects.Add(new(EffectKind.Fizzle));
            return effects;
        }

        if (key == "version") effects.Add(new(EffectKind.RuneGlow, result.StandardOutput.Trim()));

        if (before.UserName != after.UserName && after.UserName is not null)
            effects.Add(new(EffectKind.NameBound, after.UserName));
        if (before.UserEmail != after.UserEmail && after.UserEmail is not null)
            effects.Add(new(EffectKind.NameBound, after.UserEmail));

        if (key == "clone") effects.Add(new(EffectKind.ArchiveCopied));
        else if (!before.IsInitialized && after.IsInitialized) effects.Add(new(EffectKind.TomeCreated));

        if (before.IsInitialized && after.IsInitialized && before.CurrentDirectory == after.CurrentDirectory)
            DetectRepositoryChanges(before, after, key, effects);

        if (effects.Count == 0 && key is not null && Observations.Contains(key))
            effects.Add(new(EffectKind.Revealed, key));

        return effects;
    }

    private static void DetectRepositoryChanges(GitRepositorySnapshot before, GitRepositorySnapshot after, string? key, List<WorldEffect> effects)
    {
        // Dimensions (branches)
        var beforeLocal = before.LocalBranches.Select(b => b.Name).ToHashSet();
        var afterLocal = after.LocalBranches.Select(b => b.Name).ToHashSet();
        foreach (var created in afterLocal.Except(beforeLocal))
            effects.Add(new(EffectKind.DimensionSplit, created));
        foreach (var removed in beforeLocal.Except(afterLocal))
            effects.Add(new(EffectKind.DimensionClosed, removed));
        if (before.CurrentBranch != after.CurrentBranch && after.CurrentBranch is not null)
            effects.Add(new(EffectKind.DimensionStep, after.CurrentBranch));

        // Remote bonds
        var beforeRemotes = before.Remotes.Select(r => $"{r.Name} {r.FetchUrl}").ToHashSet();
        if (after.Remotes.Any(r => !beforeRemotes.Contains($"{r.Name} {r.FetchUrl}")))
            effects.Add(new(EffectKind.BondCreated, string.Join(", ", after.Remotes.Select(r => r.Name))));

        // Time / inscription
        var headChanged = before.HeadCommitId != after.HeadCommitId;
        var sameBranch = before.CurrentBranch == after.CurrentBranch;
        if (headChanged && sameBranch && after.HeadCommitId is not null)
        {
            var wentBack = before.HeadCommitId is not null && IsAncestor(after, after.HeadCommitId, before.HeadCommitId, before);
            if (wentBack)
                effects.Add(new(EffectKind.TimeRewind, after.Head?.Subject ?? ""));
            else if (key is "pull" or "fetch")
                effects.Add(new(EffectKind.PortalReceive, after.Head?.Subject ?? ""));
            else if (after.Head is { IsMerge: true })
                effects.Add(new(EffectKind.DimensionsMerged, after.Head.Subject));
            else if (key == "merge")
                effects.Add(new(EffectKind.DimensionsMerged, "fast-forward"));
            else
                effects.Add(new(EffectKind.Inscribed, after.Head?.Subject ?? ""));
        }

        if (after.UnmergedFiles.Any() && !before.UnmergedFiles.Any())
            effects.Add(new(EffectKind.DimensionClash, string.Join(", ", after.UnmergedFiles.Select(f => f.Path))));

        // Remote-tracking refs moved
        var beforeRemoteRefs = before.RemoteBranches.ToDictionary(b => b.Name, b => b.CommitId);
        var remoteMoved = after.RemoteBranches.Any(b => !beforeRemoteRefs.TryGetValue(b.Name, out var id) || id != b.CommitId);
        if (remoteMoved && key == "push") effects.Add(new(EffectKind.PortalSend, after.CurrentBranch ?? ""));
        else if (remoteMoved && key == "fetch" && !effects.Any(e => e.Kind == EffectKind.PortalReceive))
            effects.Add(new(EffectKind.PortalReceive, "origin"));

        // Altar (staging) and desk (working tree), only when no commit absorbed them.
        if (!headChanged && sameBranch)
        {
            var beforeStaged = before.StagedFiles.Select(f => f.Path).ToHashSet();
            var afterStaged = after.StagedFiles.Select(f => f.Path).ToHashSet();
            var raised = afterStaged.Except(beforeStaged).ToList();
            var lowered = beforeStaged.Except(afterStaged).ToList();
            if (raised.Count > 0) effects.Add(new(EffectKind.ToAltar, string.Join(", ", raised)));
            if (lowered.Count > 0) effects.Add(new(EffectKind.FromAltar, string.Join(", ", lowered)));

            var beforeDirty = before.ModifiedFiles.Select(f => f.Path).ToHashSet();
            var afterDirty = after.ModifiedFiles.Select(f => f.Path).ToHashSet();
            var healed = beforeDirty.Except(afterDirty).Where(p => !afterStaged.Contains(p)).ToList();
            if (healed.Count > 0 && key is "restore" or "reset")
                effects.Add(new(EffectKind.CurseLifted, string.Join(", ", healed)));
        }
    }

    /// <summary>True when <paramref name="ancestor"/> is reachable from <paramref name="descendant"/>.</summary>
    private static bool IsAncestor(GitRepositorySnapshot after, string ancestor, string descendant, GitRepositorySnapshot before)
    {
        var byId = before.Commits.Concat(after.Commits).GroupBy(c => c.Id).ToDictionary(g => g.Key, g => g.First());
        var stack = new Stack<string>([descendant]);
        var seen = new HashSet<string>();
        while (stack.Count > 0)
        {
            var id = stack.Pop();
            if (!seen.Add(id)) continue;
            if (id == ancestor && id != descendant) return true;
            if (byId.TryGetValue(id, out var node))
                foreach (var p in node.ParentIds) stack.Push(p);
        }
        return false;
    }
}
