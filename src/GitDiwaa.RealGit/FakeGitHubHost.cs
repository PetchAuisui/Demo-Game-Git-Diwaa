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
            ["for-each-ref", $"--format=%(refname:short){Sep}%(objectname)", "refs/heads"], cancellationToken);
        var rows = output.Split('\n', StringSplitOptions.RemoveEmptyEntries)
            .Select(line => line.Split(Sep))
            .Select(parts => (Name: parts[0], Id: parts[1]))
            .ToList();
        var defaultName = rows.Any(row => row.Name == "main") ? "main" : rows.FirstOrDefault().Name;
        return rows.Select(row => new RemoteBranchInfo(row.Name, row.Id, row.Name == defaultName)).ToList();
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
        string branch, CancellationToken cancellationToken = default)
    {
        RequireRef(branch);
        var output = await GitAsync(["ls-tree", "-z", "--name-only", branch], cancellationToken);
        var entries = new List<RemoteFileEntry>();
        foreach (var name in output.Split('\0', StringSplitOptions.RemoveEmptyEntries))
        {
            var last = await GitAsync(
                ["log", "-1", branch, $"--format=%H{Sep}%an{Sep}%aI{Sep}%s", "--", name], cancellationToken);
            var isDirectory = (await GitAsync(["cat-file", "-t", $"{branch}:{name}"], cancellationToken)) == "tree";
            entries.Add(new(name, isDirectory, string.IsNullOrWhiteSpace(last) ? null : ParseCommit(last)));
        }

        return entries.OrderByDescending(entry => entry.IsDirectory).ThenBy(entry => entry.Name, StringComparer.Ordinal).ToList();
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
