using GitDiwaa.Core;
using GitDiwaa.RealGit;

var testRoot = Path.Combine(Path.GetTempPath(), "git-diwaa-tests", Guid.NewGuid().ToString("N"));
var tests = new TestRunner();

try
{
    var factory = new RealGitGameSessionFactory(testRoot);
    await using var session = await factory.CreateAsync("act1", "player");

    await tests.RunAsync("session starts outside a repository", async () =>
    {
        var snapshot = await session.InspectAsync();
        Assert.False(snapshot.IsInitialized);
        Assert.Equal("act1", session.Info.MissionId);
        Assert.Equal("player", session.Info.AttemptId);
        Assert.Contains(session.Info.RemoteUrl, "https://git-diwaa.local/");
    });

    await tests.RunAsync("Git version and config are real and isolated", async () =>
    {
        Assert.Contains((await RunAsync("git --version")).Output, "git version");
        await RunAsync("git config --global user.name \"Git Diwaa Player\"");
        await RunAsync("git config --global user.email player@git-diwaa.local");
        Assert.Equal("Git Diwaa Player", (await RunAsync("git config --global user.name")).Output);
        Assert.Equal("player@git-diwaa.local", (await RunAsync("git config --global user.email")).Output);
    });

    await tests.RunAsync("unsafe commands and paths are rejected", async () =>
    {
        await RejectAsync("pwd", "start with 'git'");
        await RejectAsync("git help", "not enabled");
        await RejectAsync("git add ../outside.txt", "escapes");
        await RejectAsync("git --git-dir=/tmp status", "not enabled");
        await RejectAsync("git remote add origin https://example.com/repo.git", "local remote");
        await RejectAsync("git remote add origin https://git-diwaa.local/other.git", "registered");
    });

    await tests.RunAsync("init, files, status, add and commit update snapshot", async () =>
    {
        await RunAsync("git init");
        await session.Files.WriteAllTextAsync("README.md", "hello Git-Diwaa\n");

        var untracked = await session.InspectAsync();
        Assert.True(untracked.IsInitialized);
        Assert.Equal("main", untracked.CurrentBranch);
        Assert.True(untracked.Files.Any(file => file.Path == "README.md" && file.IndexState == GitFileState.Untracked));

        await RunAsync("git add README.md");
        var staged = await session.InspectAsync();
        Assert.True(staged.Files.Any(file => file.Path == "README.md" && file.IndexState == GitFileState.Added));

        await RunAsync("git commit -m \"initial commit\"");
        var committed = await session.InspectAsync();
        Assert.Equal(0, committed.Files.Count);
        Assert.True(committed.Branches.Any(branch => branch.Name == "main" && branch.IsCurrent));
        Assert.Equal("initial commit", committed.Commits.Single().Subject);
        Assert.Equal("Git Diwaa Player", committed.Commits.Single().Author);
    });

    await tests.RunAsync("branch and merge produce a real commit graph", async () =>
    {
        await RunAsync("git switch -c feature/demo");
        await session.Files.WriteAllTextAsync("feature.txt", "feature\n");
        await RunAsync("git add feature.txt");
        await RunAsync("git commit -m \"feature work\"");

        await RunAsync("git switch main");
        await session.Files.WriteAllTextAsync("main.txt", "main\n");
        await RunAsync("git add main.txt");
        await RunAsync("git commit -m \"main work\"");
        await RunAsync("git merge --no-ff feature/demo");

        var snapshot = await session.InspectAsync();
        Assert.True(snapshot.Branches.Any(branch => branch.Name == "feature/demo"));
        Assert.True(snapshot.Commits.Any(commit => commit.ParentIds.Count == 2));
        Assert.True(snapshot.Commits.SelectMany(commit => commit.ParentIds).All(parent =>
            snapshot.Commits.Any(commit => commit.Id == parent)));
    });

    await tests.RunAsync("diff, restore and reset affect only the player repository", async () =>
    {
        await session.Files.WriteAllTextAsync("README.md", "temporary change\n");
        Assert.Contains((await RunAsync("git diff")).Output, "+temporary change");
        await RunAsync("git restore README.md");
        Assert.Equal("hello Git-Diwaa\n", await session.Files.ReadAllTextAsync("README.md"));

        await session.Files.WriteAllTextAsync("reset.txt", "reset me\n");
        await RunAsync("git add reset.txt");
        await RunAsync("git commit -m \"reset target\"");
        await RunAsync("git reset --hard HEAD~1");
        Assert.False(session.Files.ListFiles().Contains("reset.txt"));
    });

    await tests.RunAsync("local remote supports push, fetch and pull", async () =>
    {
        await RunAsync($"git remote add origin {session.Info.RemoteUrl}");
        Assert.Contains((await RunAsync("git remote -v")).Output, session.Info.RemoteUrl);
        await RunAsync("git push -u origin main");
        await RunAsync("git fetch origin");

        await session.Files.WriteAllTextAsync("remote.txt", "from pushed commit\n");
        await RunAsync("git add remote.txt");
        await RunAsync("git commit -m \"remote update\"");
        await RunAsync("git push");
        await RunAsync("git reset --hard HEAD~1");
        Assert.False(session.Files.ListFiles().Contains("remote.txt"));
        await RunAsync("git pull");
        Assert.Equal("from pushed commit\n", await session.Files.ReadAllTextAsync("remote.txt"));
    });

    await tests.RunAsync("clone works against the session's local bare remote", async () =>
    {
        await using var cloneSession = await factory.CreateAsync("clone", "player");
        var clone = await cloneSession.ExecuteAsync($"git clone {cloneSession.Info.RemoteUrl}");
        Assert.True(clone.Success, clone.Output);
        Assert.True((await cloneSession.InspectAsync()).IsInitialized);
    });

    await tests.RunAsync("file API blocks traversal and Git metadata", async () =>
    {
        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            session.Files.WriteAllTextAsync("../outside.txt", "blocked"));
        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            session.Files.WriteAllTextAsync(".git/config", "blocked"));
    });

    await tests.RunAsync("attempt identifiers and duplicate attempts are rejected", async () =>
    {
        await Assert.ThrowsAsync<ArgumentException>(() => factory.CreateAsync("../bad", "attempt"));
        await Assert.ThrowsAsync<InvalidOperationException>(() => factory.CreateAsync("act1", "player"));
    });

    Console.WriteLine($"\n{tests.Passed}/{tests.Total} real-Git integration tests passed");
    return 0;

    async Task<GitCommandResult> RunAsync(string command)
    {
        var result = await session.ExecuteAsync(command);
        Assert.True(result.Success, $"{command}\n{result.Output}");
        return result;
    }

    async Task RejectAsync(string command, string expectedMessage)
    {
        var result = await session.ExecuteAsync(command);
        Assert.False(result.Success);
        Assert.Equal(-1, result.ExitCode);
        Assert.Contains(result.Output, expectedMessage);
    }
}
catch (Exception exception)
{
    Console.Error.WriteLine($"FAIL after {tests.Passed}/{tests.Total} tests: {exception.Message}");
    return 1;
}
finally
{
    if (Directory.Exists(testRoot)) Directory.Delete(testRoot, recursive: true);
}

internal sealed class TestRunner
{
    public int Passed { get; private set; }
    public int Total { get; private set; }

    public async Task RunAsync(string name, Func<Task> action)
    {
        Total++;
        await action();
        Passed++;
        Console.WriteLine($"PASS {name}");
    }
}

internal static class Assert
{
    public static void True(bool condition, string message = "Expected true.")
    {
        if (!condition) throw new InvalidOperationException(message);
    }

    public static void False(bool condition, string message = "Expected false.") => True(!condition, message);

    public static void Equal<T>(T expected, T actual)
    {
        if (!EqualityComparer<T>.Default.Equals(expected, actual))
            throw new InvalidOperationException($"Expected '{expected}', got '{actual}'.");
    }

    public static void Contains(string actual, string expected)
    {
        if (!actual.Contains(expected, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException($"Expected text containing '{expected}', got '{actual}'.");
    }

    public static async Task ThrowsAsync<TException>(Func<Task> action) where TException : Exception
    {
        try
        {
            await action();
        }
        catch (TException)
        {
            return;
        }

        throw new InvalidOperationException($"Expected {typeof(TException).Name}.");
    }
}
