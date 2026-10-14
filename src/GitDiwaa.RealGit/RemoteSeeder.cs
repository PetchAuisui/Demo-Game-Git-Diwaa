namespace GitDiwaa.RealGit;

internal static class RemoteSeeder
{
    public static async Task SeedAsync(
        GitSandbox sandbox,
        LocalRemote remote,
        GitProcessRunner runner,
        RemoteSeed seed,
        CancellationToken cancellationToken)
    {
        if (seed.Commits.Count == 0) return;

        var work = Path.Combine(sandbox.AttemptRoot, "seed-work");
        Directory.CreateDirectory(work);
        try
        {
            await RunAsync(runner, sandbox, work, ["init", "--initial-branch=main"], null, cancellationToken);
            var created = new HashSet<string>();
            foreach (var commit in seed.Commits)
            {
                if (created.Count == 0 && commit.Branch == "main")
                    created.Add("main");
                else if (created.Add(commit.Branch))
                    await RunAsync(runner, sandbox, work, ["switch", "-c", commit.Branch, "main"], null, cancellationToken);
                else
                    await RunAsync(runner, sandbox, work, ["switch", commit.Branch], null, cancellationToken);

                foreach (var (path, content) in commit.Files)
                {
                    var full = Path.Combine(work, path);
                    Directory.CreateDirectory(Path.GetDirectoryName(full)!);
                    await File.WriteAllTextAsync(full, content, cancellationToken);
                }

                var date = commit.Date.ToString("o");
                var env = new Dictionary<string, string>
                {
                    ["GIT_AUTHOR_DATE"] = date,
                    ["GIT_COMMITTER_DATE"] = date
                };
                await RunAsync(runner, sandbox, work, ["add", "."], null, cancellationToken);
                await RunAsync(runner, sandbox, work,
                    ["-c", $"user.name={commit.Author}", "-c", $"user.email={commit.Author.ToLowerInvariant()}@git-diwaa.local",
                     "commit", "-m", commit.Message], env, cancellationToken);
            }

            await RunAsync(runner, sandbox, work,
                ["push", remote.BareRepositoryPath, .. created.Select(branch => $"{branch}:{branch}")],
                null, cancellationToken);
        }
        finally
        {
            ForceDelete(work);
        }
    }

    private static async Task RunAsync(
        GitProcessRunner runner,
        GitSandbox sandbox,
        string directory,
        IReadOnlyList<string> arguments,
        IReadOnlyDictionary<string, string>? env,
        CancellationToken cancellationToken)
    {
        var result = await runner.RunAsync(sandbox, directory, arguments, cancellationToken, env);
        if (!result.Success) throw new InvalidOperationException($"Seeding failed: {result.Output}");
    }

    internal static void ForceDelete(string path)
    {
        if (!Directory.Exists(path)) return;
        foreach (var file in Directory.EnumerateFiles(path, "*", SearchOption.AllDirectories))
            File.SetAttributes(file, FileAttributes.Normal);
        Directory.Delete(path, recursive: true);
    }
}
