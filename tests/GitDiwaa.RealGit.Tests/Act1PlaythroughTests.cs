using GitDiwaa.Core.Game;
using GitDiwaa.Story;
using static GitDiwaa.Tests.TestRunner;

namespace GitDiwaa.Tests;

public static class Act1PlaythroughTests
{
    public static void Register()
    {
        foreach (var floor in Campaign.Floors)
        {
            Test($"playthrough floor {floor.Number:00} — {floor.Title}", async () =>
            {
                await using var runner = new FloorRunner(floor, await RealGitTests.NewSession(), "Vel");
                await runner.StartAsync();
                var log = new List<string>();
                foreach (var step in floor.Solution)
                {
                    var events = await runner.HandleAsync(step);
                    log.Add($"> {step}");
                    log.AddRange(events.Select(Describe));
                    Assert.True(!runner.IsFailed, $"floor failed at `{step}`\n{string.Join("\n", log)}");
                }
                Assert.True(runner.IsCleared,
                    $"not cleared; stuck at objective {runner.CurrentObjectiveIndex}: {runner.CurrentObjective?.Goal}\n{string.Join("\n", log)}");
                Assert.Equal(0, runner.Errors, "solution should be error-free");
            });
        }

        Test("floor 9: reset --hard destroys fragment 6 and fails the floor", async () =>
        {
            await using var runner = new FloorRunner(Act1.Floor09, await RealGitTests.NewSession(), "Vel");
            await runner.StartAsync();
            await runner.HandleAsync("git log --oneline");
            var events = await runner.HandleAsync("git reset --hard HEAD~1");
            Assert.True(runner.IsFailed && events.OfType<FloorFailed>().Any(), "hard reset should fail floor 9");
        });

        Test("floor 9: reset --mixed is also a valid path", async () =>
        {
            await using var runner = new FloorRunner(Act1.Floor09, await RealGitTests.NewSession(), "Vel");
            await runner.StartAsync();
            foreach (var step in new[] { "git log", "git reset HEAD~1", "git add fragment-6.txt", "git commit -m \"ชิ้นที่ 6\"" })
                await runner.HandleAsync(step);
            Assert.True(runner.IsCleared, $"stuck at {runner.CurrentObjective?.Goal}");
        });

        Test("floor 8: inscribing the curse fails the floor", async () =>
        {
            await using var runner = new FloorRunner(Act1.Floor08, await RealGitTests.NewSession(), "Vel");
            await runner.StartAsync();
            await runner.HandleAsync("git commit -m oops");
            Assert.True(runner.IsFailed, "committing curse.txt should fail");
        });

        Test("floor 6: wrong password does not open the seal", async () =>
        {
            await using var runner = new FloorRunner(Act1.Floor06, await RealGitTests.NewSession(), "Vel");
            await runner.StartAsync();
            await runner.HandleAsync("git log --oneline");
            await runner.HandleAsync("say lumos");
            Assert.Equal(1, runner.CurrentObjectiveIndex, "still on the seal objective");
        });

        Test("floor 3: desk panel unlocks only after casting status", async () =>
        {
            await using var runner = new FloorRunner(Act1.Floor03, await RealGitTests.NewSession(), "Vel");
            await runner.StartAsync();
            Assert.True(!runner.Panels.HasFlag(UiPanel.Desk), "desk hidden at start");
            var events = await runner.HandleAsync("git status");
            Assert.True(runner.Panels.HasFlag(UiPanel.Desk) && events.OfType<PanelUnlocked>().Any(), "desk unlocked");
        });

        Test("floor 12: merge produces a clash effect", async () =>
        {
            await using var runner = new FloorRunner(Act1.Floor12, await RealGitTests.NewSession(), "Vel");
            await runner.StartAsync();
            var events = await runner.HandleAsync("git merge experiment");
            Assert.True(events.OfType<EffectPlayed>().Any(e => e.Effect.Kind == EffectKind.DimensionClash), "clash effect");
        });

        Test("every floor has hints for every objective and fragments 1-12 are awarded once", () =>
        {
            foreach (var f in Campaign.Floors)
                foreach (var o in f.Objectives)
                    Assert.True(o.Hints.Count > 0, $"floor {f.Number} objective '{o.Goal}' has no hints");
            var rewards = Campaign.Floors.Where(f => f.Reward is not null).Select(f => f.Reward!.Number).ToList();
            Assert.True(rewards.SequenceEqual(Enumerable.Range(1, 12)), "fragments 1..12 in order: " + string.Join(",", rewards));
        });
    }

    private static string Describe(GameEvent e) => e switch
    {
        SpellOutput o => $"  [{(o.Success ? "ok" : "fail")}] {o.Output}",
        SpellRejected r => $"  [rejected] {r.Reason}",
        ObjectiveDone d => $"  ✓ {d.Goal}",
        FloorFailed f => $"  ✗ {f.Reason}",
        _ => $"  {e.GetType().Name}",
    };
}
