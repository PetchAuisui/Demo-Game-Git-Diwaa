using GitDiwaa.Core;

namespace GitDiwaa.RealGit;

/// <summary>
/// Extracts a typed snapshot using machine-readable git output only
/// (porcelain status, for-each-ref, formatted log) — never the human text.
/// </summary>
public sealed class GitStateInspector
{
    private const int MaxCommits = 300;
    private readonly GitProcessRunner _runner;
    private readonly SandboxLayout _layout;

    public GitStateInspector(GitProcessRunner runner, SandboxLayout layout)
    {
        _runner = runner;
        _layout = layout;
    }

    public async Task<GitRepositorySnapshot> InspectAsync(string directory, CancellationToken ct = default)
    {
        var relDir = Path.GetRelativePath(_layout.Workspace, directory).Replace('\\', '/');
        var userName = await ConfigAsync("user.name", directory, ct);
        var userEmail = await ConfigAsync("user.email", directory, ct);
        var workspaceFiles = ListWorkspaceFiles(directory);

        var inside = await Git(directory, ct, "rev-parse", "--is-inside-work-tree");
        if (!inside.Success || inside.StandardOutput.Trim() != "true")
        {
            return GitRepositorySnapshot.Empty with
            {
                CurrentDirectory = relDir,
                UserName = userName,
                UserEmail = userEmail,
                WorkspaceFiles = workspaceFiles,
            };
        }

        var currentBranch = await Git(directory, ct, "symbolic-ref", "--short", "-q", "HEAD");
        var head = await Git(directory, ct, "rev-parse", "-q", "--verify", "HEAD");
        var merging = await Git(directory, ct, "rev-parse", "-q", "--verify", "MERGE_HEAD");
        var status = await Git(directory, ct, "status", "--porcelain=v1", "-z", "--untracked-files=all");
        var refs = await Git(directory, ct, "for-each-ref",
            "--format=%(refname)%00%(objectname)%00%(upstream:short)%00%(HEAD)%00%(symref)",
            "refs/heads", "refs/remotes");
        var tracked = await Git(directory, ct, "ls-files", "-z");
        var remotes = await Git(directory, ct, "remote", "-v");

        var commits = head.Success
            ? ParseLog((await Git(directory, ct, "log", "--all", $"-n{MaxCommits}", "--date-order",
                "--format=%H%x00%P%x00%D%x00%s%x00%an%x00%aI%x1e")).StandardOutput)
            : [];

        return new GitRepositorySnapshot(
            IsInitialized: true,
            CurrentBranch: currentBranch.Success ? currentBranch.StandardOutput.Trim() : null,
            Files: ParseStatus(status.StandardOutput),
            Branches: ParseRefs(refs.StandardOutput),
            Commits: commits)
        {
            CurrentDirectory = relDir,
            HeadCommitId = head.Success ? head.StandardOutput.Trim() : null,
            IsMerging = merging.Success,
            UserName = userName,
            UserEmail = userEmail,
            TrackedFiles = SplitZ(tracked.StandardOutput),
            WorkspaceFiles = workspaceFiles,
            Remotes = ParseRemotes(remotes.StandardOutput),
        };
    }

    private Task<GitCommandResult> Git(string dir, CancellationToken ct, params string[] args) =>
        _runner.RunAsync(args, dir, forPlayer: false, ct);

    private async Task<string?> ConfigAsync(string key, string dir, CancellationToken ct)
    {
        var r = await Git(dir, ct, "config", "--global", "--get", key);
        return r.Success ? r.StandardOutput.Trim() : null;
    }

    private static IReadOnlyList<string> ListWorkspaceFiles(string dir) =>
        Directory.Exists(dir)
            ? Directory.EnumerateFiles(dir, "*", SearchOption.AllDirectories)
                .Select(f => Path.GetRelativePath(dir, f).Replace('\\', '/'))
                .Where(f => !f.Split('/').Contains(".git"))
                .Order(StringComparer.Ordinal)
                .ToList()
            : [];

    public static IReadOnlyList<string> SplitZ(string raw) =>
        raw.Split('\0', StringSplitOptions.RemoveEmptyEntries);

    public static IReadOnlyList<GitFileStatus> ParseStatus(string porcelainZ)
    {
        var result = new List<GitFileStatus>();
        var entries = porcelainZ.Split('\0');
        for (var i = 0; i < entries.Length; i++)
        {
            var e = entries[i];
            if (e.Length < 4) continue;
            var x = e[0];
            var y = e[1];
            var path = e[3..];
            if (x is 'R' or 'C') i++; // next entry is the original path

            if (x == '?' && y == '?')
            {
                result.Add(new GitFileStatus(path, GitFileState.Untracked, GitFileState.Untracked));
                continue;
            }

            var unmerged = (x, y) is ('U', _) or (_, 'U') or ('A', 'A') or ('D', 'D');
            result.Add(unmerged
                ? new GitFileStatus(path, GitFileState.Unmerged, GitFileState.Unmerged)
                : new GitFileStatus(path, Map(x), Map(y)));
        }
        return result;
    }

    private static GitFileState Map(char c) => c switch
    {
        ' ' => GitFileState.Unmodified,
        'M' or 'T' => GitFileState.Modified,
        'A' => GitFileState.Added,
        'D' => GitFileState.Deleted,
        'R' => GitFileState.Renamed,
        'C' => GitFileState.Copied,
        'U' => GitFileState.Unmerged,
        '?' => GitFileState.Untracked,
        _ => GitFileState.Unknown,
    };

    public static IReadOnlyList<GitBranchInfo> ParseRefs(string raw)
    {
        var list = new List<GitBranchInfo>();
        foreach (var line in raw.Split('\n', StringSplitOptions.RemoveEmptyEntries))
        {
            var parts = line.Split('\0');
            if (parts.Length < 5 || parts[4].Length > 0) continue; // skip symbolic refs like origin/HEAD
            var refName = parts[0];
            var isRemote = refName.StartsWith("refs/remotes/");
            var name = isRemote ? refName["refs/remotes/".Length..] : refName["refs/heads/".Length..];
            list.Add(new GitBranchInfo(
                name,
                IsCurrent: parts[3] == "*",
                CommitId: parts[1],
                Upstream: string.IsNullOrEmpty(parts[2]) ? null : parts[2],
                IsRemote: isRemote));
        }
        return list;
    }

    public static IReadOnlyList<GitCommitNode> ParseLog(string raw)
    {
        var list = new List<GitCommitNode>();
        foreach (var record in raw.Split('\x1e', StringSplitOptions.RemoveEmptyEntries))
        {
            var p = record.Trim('\n').Split('\0');
            if (p.Length < 6) continue;
            var refs = p[2].Split(", ", StringSplitOptions.RemoveEmptyEntries)
                .Select(r => r.StartsWith("HEAD -> ") ? r["HEAD -> ".Length..] : r)
                .ToList();
            list.Add(new GitCommitNode(
                p[0],
                p[1].Split(' ', StringSplitOptions.RemoveEmptyEntries),
                refs,
                p[3],
                p[4],
                DateTimeOffset.TryParse(p[5], out var at) ? at : DateTimeOffset.MinValue));
        }
        return list;
    }

    public static IReadOnlyList<GitRemoteInfo> ParseRemotes(string raw) =>
        raw.Split('\n', StringSplitOptions.RemoveEmptyEntries)
            .Select(l => l.Split(['\t', ' '], StringSplitOptions.RemoveEmptyEntries))
            .Where(p => p.Length >= 3 && p[2] == "(fetch)")
            .Select(p => new GitRemoteInfo(p[0], p[1]))
            .ToList();
}
