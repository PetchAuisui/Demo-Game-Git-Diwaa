using GitDiwaa.Core;
using GitDiwaa.Core.Game;
using static GitDiwaa.Tests.TestRunner;

namespace GitDiwaa.Tests;

public static class QuestEngineTests
{
    public static void Register()
    {
        Test("effects: add → altar, commit → inscribed, reset → rewind, branch → split", async () =>
        {
            await using var s = await RealGitTests.NewSession();
            await RealGitTests.Configure(s);
            await s.ExecuteAsync("git init");
            await s.Files.WriteAllTextAsync("a.txt", "a");

            async Task<IReadOnlyList<WorldEffect>> Cast(string cmd)
            {
                var before = await s.InspectAsync();
                var r = await s.ExecuteAsync(cmd);
                return EffectDetector.Detect(before, await s.InspectAsync(), cmd, r);
            }

            Assert.True((await Cast("git add a.txt")).Any(e => e.Kind == EffectKind.ToAltar), "ToAltar");
            Assert.True((await Cast("git commit -m one")).Any(e => e.Kind == EffectKind.Inscribed), "Inscribed");
            await s.Files.WriteAllTextAsync("a.txt", "b");
            await Cast("git commit -am two");
            Assert.True((await Cast("git reset --soft HEAD~1")).Any(e => e.Kind == EffectKind.TimeRewind), "TimeRewind");
            Assert.True((await Cast("git restore --staged a.txt")).Any(e => e.Kind == EffectKind.FromAltar), "FromAltar");
            Assert.True((await Cast("git restore a.txt")).Any(e => e.Kind == EffectKind.CurseLifted), "CurseLifted");
            Assert.True((await Cast("git branch experiment")).Any(e => e.Kind == EffectKind.DimensionSplit), "Split");
            Assert.True((await Cast("git switch experiment")).Any(e => e.Kind == EffectKind.DimensionStep), "Step");
            Assert.True((await Cast("git status")).Any(e => e.Kind == EffectKind.Revealed), "Revealed");
            Assert.True((await Cast("git nonsense")).Any(e => e.Kind == EffectKind.Fizzle), "Fizzle");
        });

        Test("scoring follows storyboard formula and caps stars when over time", () =>
        {
            var floor = new Floor
            {
                Number = 1, Title = "t", Hook = "h", TargetCommands = 3, TimeLimitSeconds = 130,
                Objectives = [new Objective { Goal = "g", IsComplete = _ => true }],
            };
            var perfect = Scoring.Calculate(floor, 1, 0, 3, TimeSpan.FromSeconds(30));
            Assert.Equal(100, perfect.Score, "full score");
            Assert.Equal(3, perfect.Stars, "stars");
            Assert.Equal(30, perfect.Coins, "coins (10 base + 20)");

            var sloppy = Scoring.Calculate(floor, 1, 2, 5, TimeSpan.FromSeconds(30));
            Assert.Equal(2, sloppy.Stars, "two stars");

            var slow = Scoring.Calculate(floor, 1, 0, 3, TimeSpan.FromSeconds(500));
            Assert.Equal(1, slow.Stars, "over time caps at 1 star");
        });

        Test("conflict resolver keeps ours / theirs / both", () =>
        {
            const string text = "head\n<<<<<<< HEAD\nice\n=======\nfire\n>>>>>>> experiment\ntail";
            Assert.Equal("head\nice\ntail", ConflictResolver.Resolve(text, "ours"), "ours");
            Assert.Equal("head\nfire\ntail", ConflictResolver.Resolve(text, "theirs"), "theirs");
            Assert.Equal("head\nice\nfire\ntail", ConflictResolver.Resolve(text, "both"), "both");
        });

        Test("runner: objectives are judged from repository state and world events fire", async () =>
        {
            var floor = new Floor
            {
                Number = 2, Title = "test", Hook = "h",
                Setup = async ctx => await ctx.Session.ExecuteAsync("git config --global user.name T"),
                Objectives =
                [
                    new Objective { Goal = "make a tome", IsComplete = c => c.After.IsInitialized,
                        WorldEvent = ctx => ctx.Files.WriteAllTextAsync("gift.txt", "fragment") },
                    new Objective { Goal = "notice the gift", IsComplete = c => c.HasRead("gift.txt") },
                    new Objective { Goal = "say the word", IsComplete = c => c.Said("lumos") },
                ],
                Reward = new Fragment(1, "เศษคัมภีร์ชิ้นที่ 1", "lore"),
            };

            await using var s = await RealGitTests.NewSession();
            await using var runner = new FloorRunner(floor, s, "เวล");
            await runner.StartAsync();

            var e1 = await runner.HandleAsync("git status");
            Assert.True(e1.OfType<SpellOutput>().Single().Success == false, "status before init fails");
            Assert.Equal(1, runner.Errors, "errors");

            var e2 = await runner.HandleAsync("git init");
            Assert.True(e2.OfType<ObjectiveDone>().Any(), "init completes goal 1");
            Assert.True(e2.OfType<EffectPlayed>().Any(e => e.Effect.Kind == EffectKind.TomeCreated), "tome effect");
            Assert.True(runner.Snapshot.WorkspaceFiles.Contains("gift.txt"), "world event wrote a file");

            await runner.HandleAsync("read gift.txt");
            Assert.Equal(2, runner.CurrentObjectiveIndex, "after read");
            var hint = (await runner.HandleAsync("hint")).OfType<HintGiven>().Single();
            Assert.Equal(1, hint.Level, "hint level");

            var end = await runner.HandleAsync("say Lumos");
            Assert.True(runner.IsCleared, "floor cleared");
            Assert.True(end.OfType<FragmentObtained>().Any() && end.OfType<FloorCleared>().Any(), "reward + score");
        });

        Test("runner: checkout is rejected with a modern-spell hint and counts as an error", async () =>
        {
            var floor = new Floor { Number = 1, Title = "t", Hook = "h", Objectives = [new Objective { Goal = "g", IsComplete = _ => false }] };
            await using var s = await RealGitTests.NewSession();
            await using var runner = new FloorRunner(floor, s, "x");
            await runner.StartAsync();
            var events = await runner.HandleAsync("git checkout main");
            Assert.True(events.OfType<SpellRejected>().Single().Reason.Contains("switch"), "hint");
            Assert.Equal(1, runner.Errors, "error count");
        });
    }
}
