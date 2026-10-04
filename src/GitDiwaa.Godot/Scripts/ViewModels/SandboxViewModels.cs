using GitDiwaa.Core;
using GitDiwaa.Godot.Common;
using Godot;

namespace GitDiwaa.Godot.ViewModels;

public enum TerminalLogType
{
    Command,
    Output,
    Error,
    Info,
    System
}

public sealed record TerminalLogEntry(
    TerminalLogType Type,
    string Text,
    DateTimeOffset Timestamp)
{
    public static TerminalLogEntry Command(string cmd) => new(TerminalLogType.Command, cmd, DateTimeOffset.UtcNow);
    public static TerminalLogEntry Output(string text) => new(TerminalLogType.Output, text, DateTimeOffset.UtcNow);
    public static TerminalLogEntry Error(string err) => new(TerminalLogType.Error, err, DateTimeOffset.UtcNow);
    public static TerminalLogEntry Info(string info) => new(TerminalLogType.Info, info, DateTimeOffset.UtcNow);
    public static TerminalLogEntry System(string sys) => new(TerminalLogType.System, sys, DateTimeOffset.UtcNow);
}

public sealed record FileDisplayItem(
    string Path,
    string FileName,
    GitFileState IndexState,
    GitFileState WorkingTreeState)
{
    public string StatusBadge => WorkingTreeState switch
    {
        GitFileState.Untracked => "[?]",
        GitFileState.Modified => "[M]",
        GitFileState.Deleted => "[D]",
        _ => IndexState switch
        {
            GitFileState.Added => "[A]",
            GitFileState.Modified => "[M]",
            GitFileState.Deleted => "[D]",
            GitFileState.Renamed => "[R]",
            _ => "[✓]"
        }
    };

    public string StatusLabel => WorkingTreeState switch
    {
        GitFileState.Untracked => "Untracked",
        GitFileState.Modified => "Modified",
        GitFileState.Deleted => "Deleted",
        _ => IndexState switch
        {
            GitFileState.Added => "Staged (Added)",
            GitFileState.Modified => "Staged (Modified)",
            GitFileState.Deleted => "Staged (Deleted)",
            GitFileState.Renamed => "Staged (Renamed)",
            _ => "Committed"
        }
    };

    public Color StatusColor => WorkingTreeState switch
    {
        GitFileState.Untracked => SandboxThemeTokens.StateUntracked,
        GitFileState.Modified => SandboxThemeTokens.StateModified,
        GitFileState.Deleted => SandboxThemeTokens.StateDeleted,
        _ => IndexState switch
        {
            GitFileState.Added => SandboxThemeTokens.StateAdded,
            GitFileState.Modified => SandboxThemeTokens.StateModified,
            GitFileState.Deleted => SandboxThemeTokens.StateDeleted,
            GitFileState.Renamed => SandboxThemeTokens.StateRenamed,
            _ => SandboxThemeTokens.TextSecondary
        }
    };
}

public sealed record WorkspaceEntryDisplayItem(
    string Path,
    string Name,
    bool IsDirectory,
    GitFileState IndexState,
    GitFileState WorkingTreeState)
{
    public string StatusBadge => IsDirectory
        ? string.Empty
        : new FileDisplayItem(Path, Name, IndexState, WorkingTreeState).StatusBadge;

    public Color StatusColor => IsDirectory
        ? SandboxThemeTokens.TextSecondary
        : new FileDisplayItem(Path, Name, IndexState, WorkingTreeState).StatusColor;
}

public sealed record CommitGraphDisplayNode(
    string Id,
    string ShortId,
    IReadOnlyList<string> ParentIds,
    IReadOnlyList<string> Branches,
    bool IsCurrentBranchHead,
    string Subject,
    string Author,
    DateTimeOffset AuthoredAt)
{
    public static CommitGraphDisplayNode FromCoreCommit(
        GitCommitNode commit,
        IReadOnlyList<GitBranchInfo> branches,
        string? currentBranch)
    {
        var shortId = commit.Id.Length >= 7 ? commit.Id[..7] : commit.Id;
        var pointingBranches = branches
            .Where(b => string.Equals(b.CommitId, commit.Id, StringComparison.OrdinalIgnoreCase))
            .Select(b => b.Name)
            .ToList();

        var isCurrentHead = branches.Any(b => b.IsCurrent && string.Equals(b.CommitId, commit.Id, StringComparison.OrdinalIgnoreCase));

        return new CommitGraphDisplayNode(
            Id: commit.Id,
            ShortId: shortId,
            ParentIds: commit.ParentIds,
            Branches: pointingBranches,
            IsCurrentBranchHead: isCurrentHead,
            Subject: commit.Subject,
            Author: commit.Author,
            AuthoredAt: commit.AuthoredAt
        );
    }
}
