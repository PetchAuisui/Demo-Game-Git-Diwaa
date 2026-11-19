using GitDiwaa.Core;
using GitDiwaa.RealGit;
using static GitDiwaa.Tests.TestRunner;

namespace GitDiwaa.Tests;

public static class RealGitTests
{
    public static void Register()
    {
        var policy = new CommandPolicy();

        foreach (var ok in new[]
        {
            "git --version", "git status", "git add .", "git add scroll-1.txt",
            "git commit -m \"จารึก ../ แรก\"", "git commit -am \"fix..\"",
            "git config --global user.name \"เวล ศิษย์\"", "git config --global user.email vel@tower.diwaa",
            "git config --global user.name", "git log --oneline -n 3", "git log --graph --all --oneline",
            "git diff --staged", "git restore --staged curse.txt", "git reset --soft HEAD~1",
            "git branch -d phantom", "git switch -c experiment", "git merge experiment", "git merge --abort",
            "git clone https://archive.diwaa/light-tome.git", "git remote -v",
            "git remote add origin https://archive.diwaa/vel.git", "git push -u origin main", "git pull", "git fetch origin",
        })
        {
            Test($"policy allows: {ok}", () => Assert.True(policy.Evaluate(ok).Allowed, policy.Evaluate(ok).Reason ?? ""));
        }

        foreach (var bad in new[]
        {
            "rm -rf /", "git status; rm -rf ~", "git status && ls", "git log | cat",
            "git -C / status", "git -c core.pager=sh status", "git --git-dir=/etc status",
            "git add ../../secret", "git add /etc/passwd", "git add ~/x", "git checkout main",
            "git config --global core.editor vim", "git config --global alias.x \"!sh\"",
            "git clone https://github.com/torvalds/linux.git", "git clone file:///etc",
            "git remote add evil git@github.com:x/y.git", "git diff --output=/tmp/x", "git add -p",
            "git commit -m \"unterminated", "git help", "git submodule add x",
        })
        {
            Test($"policy denies: {bad}", () => Assert.True(!policy.Evaluate(bad).Allowed, "should be denied"));
        }

        Test("checkout hint points to switch/restore", () =>
        {
            var d = policy.Evaluate("git checkout -b x");
            Assert.True(d.Reason!.Contains("switch") && d.Reason.Contains("restore"), d.Reason);
        });

        Test("workspace is not inside a parent repo and config is isolated", async () =>
        {
            await using var s = await NewSession();
            var snap = await s.InspectAsync();
            Assert.True(!snap.IsInitialized, "fresh workspace must not see a parent repository");
            Assert.Equal(null, snap.UserName, "user.name before config");

            var r = await s.ExecuteAsync("git config --global user.name \"เวล\"");
            Assert.True(r.Success, r.Output);
            snap = await s.InspectAsync();
            Assert.Equal("เวล", snap.UserName, "user.name after config");
        });

        Test("init → add → commit is reflected in the snapshot", async () =>
        {
            await using var s = await NewSession();
            await Configure(s);
            Assert.True((await s.ExecuteAsync("git init")).Success, "init");
            await s.Files.WriteAllTextAsync("a.txt", "rune A\n");
            await s.Files.WriteAllTextAsync("b.txt", "rune B\n");

            var snap = await s.InspectAsync();
            Assert.Equal("main", snap.CurrentBranch, "default branch");
            Assert.Equal(2, snap.UntrackedFiles.Count(), "untracked");

            await s.ExecuteAsync("git add a.txt");
            snap = await s.InspectAsync();
            Assert.Equal(1, snap.StagedFiles.Count(), "staged");

            var c = await s.ExecuteAsync("git commit -m \"first\"");
            Assert.True(c.Success, c.Output);
            snap = await s.InspectAsync();
            Assert.Equal(1, snap.Commits.Count, "commits");
            Assert.Equal("first", snap.Head!.Subject, "subject");
            Assert.True(snap.IsTracked("a.txt") && !snap.IsTracked("b.txt"), "tracked files");
        });

        Test("plain `git commit` without message aborts instead of opening an editor", async () =>
        {
            await using var s = await NewSession();
            await Configure(s);
            await s.ExecuteAsync("git init");
            await s.Files.WriteAllTextAsync("a.txt", "x");
            await s.ExecuteAsync("git add .");
            var r = await s.ExecuteAsync("git commit");
            Assert.True(!r.Success, "commit without message should fail fast");
        });

        Test("merge conflict is detected as unmerged + merging", async () =>
        {
            await using var s = await NewSession();
            await Configure(s);
            await s.ExecuteAsync("git init");
            await s.Files.WriteAllTextAsync("f.txt", "base\n");
            await s.ExecuteAsync("git add .");
            await s.ExecuteAsync("git commit -m base");
            await s.ExecuteAsync("git switch -c experiment");
            await s.Files.WriteAllTextAsync("f.txt", "fire\n");
            await s.ExecuteAsync("git commit -am fire");
            await s.ExecuteAsync("git switch main");
            await s.Files.WriteAllTextAsync("f.txt", "ice\n");
            await s.ExecuteAsync("git commit -am ice");
            var m = await s.ExecuteAsync("git merge experiment");
            Assert.True(!m.Success, "merge should conflict");

            var snap = await s.InspectAsync();
            Assert.True(snap.IsMerging, "MERGE_HEAD should exist");
            Assert.Equal(1, snap.UnmergedFiles.Count(), "unmerged files");

            await s.Files.WriteAllTextAsync("f.txt", "fire and ice\n");
            await s.ExecuteAsync("git add f.txt");
            var c = await s.ExecuteAsync("git commit -m merged");
            Assert.True(c.Success, c.Output);
            snap = await s.InspectAsync();
            Assert.True(snap.Head!.IsMerge && !snap.IsMerging, "merge commit");
        });

        Test("virtual archive: clone, NPC push, pull, push -u", async () =>
        {
            await using var s = await NewSession();
            await Configure(s);
            var url = await s.Authoring.CreateBareRemoteAsync("light-tome");
            Assert.Equal("https://archive.diwaa/light-tome.git", url, "virtual url");

            // An NPC seeds the archive.
            await s.Authoring.RunGitAsync(["clone", "-q", url, "."], "guardian");
            await s.Authoring.WriteNpcFileAsync("guardian", "light.txt", "light\n");
            await s.Authoring.RunGitAsync(["add", "."], "guardian");
            await s.Authoring.RunGitAsync(["-c", "user.name=Guardian", "-c", "user.email=g@diwaa", "commit", "-qm", "seed"], "guardian");
            var seeded = await s.Authoring.RunGitAsync(["push", "-q", "origin", "main"], "guardian");
            Assert.True(seeded.Success, seeded.Output);

            var clone = await s.ExecuteAsync($"git clone {url}");
            Assert.True(clone.Success, clone.Output);
            Assert.True(!clone.Output.Contains("/remotes/") && !clone.Output.Contains("file://"), "sandbox path leaked: " + clone.Output);
            Assert.Equal(null, s.ChangeDirectory("light-tome"), "cd");

            var snap = await s.InspectAsync();
            Assert.True(snap.IsInitialized, "cloned repo");
            Assert.Equal("https://archive.diwaa/light-tome.git", snap.Remotes.Single().FetchUrl, "origin url");

            // NPC pushes something new; player pulls.
            await s.Authoring.WriteNpcFileAsync("guardian", "more.txt", "more\n");
            await s.Authoring.RunGitAsync(["add", "."], "guardian");
            await s.Authoring.RunGitAsync(["-c", "user.name=Guardian", "-c", "user.email=g@diwaa", "commit", "-qm", "more"], "guardian");
            await s.Authoring.RunGitAsync(["push", "-q"], "guardian");
            var pull = await s.ExecuteAsync("git pull");
            Assert.True(pull.Success, pull.Output);
            snap = await s.InspectAsync();
            Assert.True(snap.WorkspaceFiles.Contains("more.txt"), "pulled file");

            // Player pushes to a fresh archive with -u.
            var mine = await s.Authoring.CreateBareRemoteAsync("vel");
            await s.ExecuteAsync($"git remote add mine {mine}");
            var push = await s.ExecuteAsync("git push -u mine main");
            Assert.True(push.Success, push.Output);
            snap = await s.InspectAsync();
            Assert.Equal("mine/main", snap.FindBranch("main")!.Upstream, "upstream");
        });

        Test("cd and files cannot escape the workspace", async () =>
        {
            await using var s = await NewSession();
            Assert.True(s.ChangeDirectory("..") is not null, "cd .. from root must fail");
            Assert.True(s.ChangeDirectory("/etc") is not null, "cd /etc must fail");
            var threw = false;
            try { await s.Files.WriteAllTextAsync("../escape.txt", "x"); }
            catch (UnauthorizedAccessException) { threw = true; }
            Assert.True(threw, "write outside workspace must throw");
            Assert.Equal(null, await s.Files.ReadAllTextAsync("../home/.gitconfig"), "read outside");
        });

        Test("porcelain parser handles renames and unmerged", () =>
        {
            var files = GitStateInspector.ParseStatus("R  new.txt\0old.txt\0UU c.txt\0?? n.txt\0 M m.txt\0");
            Assert.Equal(4, files.Count, "count");
            Assert.Equal(GitFileState.Renamed, files[0].IndexState, "rename");
            Assert.True(files[1].IsUnmerged, "unmerged");
            Assert.True(files[2].IsUntracked, "untracked");
            Assert.True(files[3].HasUnstagedChanges && !files[3].IsStaged, "modified");
        });
    }

    private static int _counter;

    public static async Task<RealGitSession> NewSession()
    {
        var root = Path.Combine(Path.GetTempPath(), "git-diwaa-tests", $"{Environment.ProcessId}-{Interlocked.Increment(ref _counter)}");
        if (Directory.Exists(root)) Directory.Delete(root, true);
        await Task.CompletedTask;
        return new RealGitSession(new SandboxLayout(root), "test", _counter.ToString());
    }

    public static async Task Configure(IGitGameSession s)
    {
        await s.ExecuteAsync("git config --global user.name Tester");
        await s.ExecuteAsync("git config --global user.email tester@diwaa");
    }
}
