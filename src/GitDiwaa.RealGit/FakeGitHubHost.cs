using System.Globalization;
using GitDiwaa.Core;

namespace GitDiwaa.RealGit;

internal sealed partial class FakeGitHubHost : IGitRemoteHost
{
    private const char Sep = '\u001f';

    private readonly GitSandbox _sandbox;
    private readonly LocalRemote _remote;
    private readonly GitProcessRunner _runner;
    private readonly RemoteSeed? _seed;
    private readonly List<PullRequestInfo> _pullRequests = [];

    public FakeGitHubHost(GitSandbox sandbox, LocalRemote remote, GitProcessRunner runner, RemoteSeed? seed)
    {
        _sandbox = sandbox;
        _remote = remote;
        _runner = runner;
        _seed = seed;
    }

    private string Owner => _seed?.Owner ?? "git-diwaa";
    private string RepoName => _seed?.Name ?? _remote.Name;

    public async Task<RemoteRepositoryInfo> GetRepositoryAsync(CancellationToken cancellationToken = default)
    {
        var branches = await ListBranchesAsync(cancellationToken);
        var defaultBranch = branches.FirstOrDefault(branch => branch.IsDefault)?.Name ?? "main";
        var count = 0;
        if (branches.Any(branch => branch.Name == defaultBranch))
            int.TryParse(await GitAsync(["rev-list", "--count", defaultBranch], cancellationToken), out count);
        return new(Owner, RepoName, _seed?.Description ?? string.Empty,
            _remote.AliasUrl, defaultBranch, branches.Count, count);
    }

    public async Task<IReadOnlyList<RemoteBranchInfo>> ListBranchesAsync(CancellationToken cancellationToken = default)
    {
        var output = await GitAsync(
            ["for-each-ref", $"--format=%(refname:short){Sep}%(objectname){Sep}%(contents:subject){Sep}%(committerdate:iso-strict)",
             "refs/heads"], cancellationToken);
        var rows = output.Split('\n', StringSplitOptions.RemoveEmptyEntries)
            .Select(line => line.Split(Sep))
            .ToList();
        var defaultName = rows.Any(row => row[0] == "main") ? "main" : rows.FirstOrDefault()?[0];
        var branches = new List<RemoteBranchInfo>();
        foreach (var row in rows)
        {
            int ahead = 0, behind = 0;
            if (defaultName is not null && row[0] != defaultName)
            {
                var counts = (await GitAsync(
                    ["rev-list", "--left-right", "--count", $"{defaultName}...{row[0]}"], cancellationToken))
                    .Split('\t');
                if (counts.Length == 2)
                {
                    int.TryParse(counts[0], out behind);
                    int.TryParse(counts[1], out ahead);
                }
            }

            branches.Add(new(row[0], row[1], row[0] == defaultName, ahead, behind, row[2],
                DateTimeOffset.Parse(row[3], CultureInfo.InvariantCulture)));
        }

        return branches;
    }

    public async Task<IReadOnlyList<RemoteCommitInfo>> ListCommitsAsync(
        string branch, int limit = 30, CancellationToken cancellationToken = default)
    {
        RequireRef(branch);
        var output = await GitAsync(
            ["log", branch, $"-n{Math.Clamp(limit, 1, 200)}", $"--format=%H{Sep}%an{Sep}%aI{Sep}%s"],
            cancellationToken);
        return output.Split('\n', StringSplitOptions.RemoveEmptyEntries).Select(ParseCommit).ToList();
    }

    public async Task<IReadOnlyList<RemoteFileEntry>> ListFilesAsync(
        string branch, string path = "", CancellationToken cancellationToken = default)
    {
        RequireRef(branch);
        path = path.Trim('/');
        if (path.Split('/').Contains("..")) return [];
        var spec = path.Length == 0 ? new[] { "ls-tree", "-z", branch } : ["ls-tree", "-z", branch, "--", path + "/"];
        var output = await GitAsync(spec, cancellationToken);
        var entries = new List<RemoteFileEntry>();
        foreach (var record in output.Split('\0', StringSplitOptions.RemoveEmptyEntries))
        {
            var tab = record.IndexOf('\t');
            var kind = record[..tab].Split(' ')[1];
            var fullPath = record[(tab + 1)..];
            var last = await GitAsync(
                ["log", "-1", branch, $"--format=%H{Sep}%an{Sep}%aI{Sep}%s", "--", fullPath], cancellationToken);
            entries.Add(new(System.IO.Path.GetFileName(fullPath), fullPath, kind == "tree",
                string.IsNullOrWhiteSpace(last) ? null : ParseCommit(last)));
        }

        return entries.OrderByDescending(entry => entry.IsDirectory)
            .ThenBy(entry => entry.Name, StringComparer.Ordinal).ToList();
    }

    public async Task<bool> DeleteBranchAsync(string branch, CancellationToken cancellationToken = default)
    {
        RequireRef(branch);
        var branches = await ListBranchesAsync(cancellationToken);
        if (branches.Any(item => item.Name == branch && item.IsDefault)) return false;
        if (_pullRequests.Any(pr => pr.State == PullRequestState.Open && pr.SourceBranch == branch)) return false;
        var result = await _runner.RunAsync(_sandbox, _remote.BareRepositoryPath, ["branch", "-D", branch], cancellationToken);
        return result.Success;
    }

    public async Task<string?> ReadFileAsync(string branch, string path, CancellationToken cancellationToken = default)
    {
        RequireRef(branch);
        if (path.StartsWith('/') || path.Split('/').Contains("..")) return null;
        var result = await _runner.RunAsync(_sandbox, _remote.BareRepositoryPath, ["show", $"{branch}:{path}"], cancellationToken);
        return result.Success ? result.StandardOutput : null;
    }

    internal async Task<string> GitAsync(IReadOnlyList<string> arguments, CancellationToken cancellationToken)
    {
        var result = await _runner.RunAsync(_sandbox, _remote.BareRepositoryPath, arguments, cancellationToken);
        return result.Success ? result.StandardOutput.TrimEnd('\n') : string.Empty;
    }

    private static RemoteCommitInfo ParseCommit(string line)
    {
        var parts = line.Split(Sep);
        return new(parts[0], parts[0][..7], parts[1],
            parts.Length > 3 ? parts[3] : string.Empty,
            DateTimeOffset.Parse(parts[2], CultureInfo.InvariantCulture));
    }

    private static void RequireRef(string value)
    {
        if (string.IsNullOrWhiteSpace(value) || value.StartsWith('-') || value.Contains(".."))
            throw new ArgumentException("Invalid branch name.", nameof(value));
    }
}
