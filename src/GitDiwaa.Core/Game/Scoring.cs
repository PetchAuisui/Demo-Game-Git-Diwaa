namespace GitDiwaa.Core.Game;

public sealed record ScoreCard(
    int Score,
    int FullScore,
    int Stars,
    int Coins,
    int Errors,
    int EffectiveCommands,
    int TargetCommands,
    TimeSpan Elapsed,
    bool OverTime);

/// <summary>
/// Secondary motivation layer (stars, score, coins) using the storyboard's formulas.
/// Shown only on the result screen — never part of the core play loop.
/// </summary>
public static class Scoring
{
    public static ScoreCard Calculate(Floor floor, int objectivesDone, int errors, int effectiveCommands, TimeSpan elapsed)
    {
        var full = floor.FullScore;
        var n = Math.Max(1, floor.TargetCommands);
        var stepPart = 0.8 * full * objectivesDone / Math.Max(1, floor.Objectives.Count);
        var efficiency = effectiveCommands <= n ? 1.0 : (double)n / effectiveCommands;
        var effPart = 0.2 * full * efficiency;
        var penalty = 0.03 * full * errors;
        var score = (int)Math.Round(Math.Max(0, stepPart + effPart - penalty));

        var ratio = (double)score / full;
        var overTime = elapsed.TotalSeconds > floor.TimeLimitSeconds;
        var stars =
            ratio >= 0.90 && errors == 0 && effectiveCommands <= n ? 3 :
            ratio >= 0.70 && errors <= 2 && effectiveCommands <= n + 2 ? 2 :
            ratio >= 0.45 ? 1 : 0;

        // Design v2: running out of time no longer fails the floor (learning > pressure),
        // it only caps the reward at one star.
        if (overTime) stars = Math.Min(stars, 1);

        var coins = stars == 0 ? 0 : floor.Number + 9 + stars switch { 1 => 5, 2 => 12, _ => 20 };
        return new ScoreCard(score, full, stars, coins, errors, effectiveCommands, n, elapsed, overTime);
    }
}
