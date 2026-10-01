using System.Globalization;
using GitDiwaa.Core;

namespace GitDiwaa.RealGit;

internal sealed class GitRepositoryInspector
{
    private readonly GitSandbox _sandbox;
    private readonly GitProcessRunner _processRunner;

    public GitRepositoryInspector(GitSandbox sandbox, GitProcessRunner processRunner)
    {
        _sandbox = sandbox;
        _processRunner = processRunner;
    }

    public async Task<GitRepositorySnapshot> InspectAsync(CancellationToken cancellationToken)
    {
        var gitMetadata = Path.Combine(_sandbox.PlayerRepositoryPath, ".git");
        if (!Directory.Exists(gitMetadata) && !File.Exists(gitMetadata))
            return new(false, null, [], [], []);

        var currentBranchTask = ReadCurrentBranchAsync(cancellationToken);
        var filesTask = ReadFilesAsync(cancellationToken);
        var branchesTask = ReadBranchesAsync(cancellationToken);
        var commitsTask = ReadCommitsAsync(cancellationToken);

        await Task.WhenAll(currentBranchTask, filesTask, branchesTask, commitsTask);
        return new(
            true,
            await currentBranchTask,
            await filesTask,
            await branchesTask,
            await commitsTask);
    }

    private async Task<string?> ReadCurrentBranchAsync(CancellationToken cancellationToken)
    {
        var result = await RunAsync(["symbolic-ref", "--quiet", "--short", "HEAD"], cancellationToken);
        return result.Success ? result.StandardOutput.Trim() : null;
    }

    private async Task<IReadOnlyList<GitFileStatus>> ReadFilesAsync(CancellationToken cancellationToken)
    {
        var result = await RunAsync(["status", "--porcelain=v1", "-z", "--untracked-files=all"], cancellationToken);
        if (!result.Success || string.IsNullOrEmpty(result.StandardOutput)) return [];

        var records = result.StandardOutput.Split('\0', StringSplitOptions.RemoveEmptyEntries);
        var files = new List<GitFileStatus>();
        for (var index = 0; index < records.Length; index++)
        {
            var record = records[index];
            if (record.Length < 4) continue;
            var indexCode = record[0];
            var workingCode = record[1];
            var path = record[3..];
            files.Add(new(path, ParseState(indexCode), ParseState(workingCode)));
            if (indexCode is 'R' or 'C' || workingCode is 'R' or 'C') index++;
        }

        return files;
    }

    private async Task<IReadOnlyList<GitBranchInfo>> ReadBranchesAsync(CancellationToken cancellationToken)
    {
        var result = await RunAsync(
            [
                "for-each-ref",
                "--format=%(refname:short)%00%(HEAD)%00%(objectname)%00%(upstream:short)",
                "refs/heads",
                "refs/remotes"
            ],
            cancellationToken);
        if (!result.Success) return [];

        return result.StandardOutput
            .Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(line => line.Split('\0'))
            .Where(fields => fields.Length >= 4)
            .Select(fields => new GitBranchInfo(
                fields[0],
                fields[1] == "*",
                NullIfEmpty(fields[2]),
                NullIfEmpty(fields[3])))
            .ToArray();
    }

    private async Task<IReadOnlyList<GitCommitNode>> ReadCommitsAsync(CancellationToken cancellationToken)
    {
        var result = await RunAsync(
            ["log", "--all", "-n", "200", "--format=%H%x1f%P%x1f%D%x1f%s%x1f%an%x1f%aI%x1e"],
            cancellationToken);
        if (!result.Success) return [];

        var commits = new List<GitCommitNode>();
        foreach (var record in result.StandardOutput.Split(
                     '\x1e',
                     StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
        {
            var fields = record.Split('\x1f');
            if (fields.Length != 6 ||
                !DateTimeOffset.TryParse(fields[5], CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out var authoredAt))
                continue;

            commits.Add(new(
                fields[0],
                SplitNonEmpty(fields[1], ' '),
                SplitNonEmpty(fields[2], ','),
                fields[3],
                fields[4],
                authoredAt));
        }

        return commits;
    }

    private Task<GitCommandResult> RunAsync(
        IReadOnlyList<string> arguments,
        CancellationToken cancellationToken) =>
        _processRunner.RunAsync(_sandbox, _sandbox.PlayerRepositoryPath, arguments, cancellationToken);

    private static GitFileState ParseState(char value) => value switch
    {
        ' ' => GitFileState.Unchanged,
        '?' => GitFileState.Untracked,
        'A' => GitFileState.Added,
        'M' => GitFileState.Modified,
        'D' => GitFileState.Deleted,
        'R' => GitFileState.Renamed,
        'C' => GitFileState.Copied,
        'U' => GitFileState.Unmerged,
        _ => GitFileState.Unknown
    };

    private static string? NullIfEmpty(string value) => string.IsNullOrWhiteSpace(value) ? null : value;

    private static IReadOnlyList<string> SplitNonEmpty(string value, char separator) => value
        .Split(separator, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
}

