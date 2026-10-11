namespace GitDiwaa.Core.Levels;

public enum GameAct
{
    BasicGit = 1,
    Teamwork = 2,
    Troubleshooting = 3
}

public enum GamePhase
{
    Teaching,
    ProblemSolving
}

public static class GameStructure
{
    public const int TotalLevels = 40;

    public static GameAct ActOf(int levelNumber) => levelNumber switch
    {
        >= 1 and <= 15 => GameAct.BasicGit,
        >= 16 and <= 20 => GameAct.Teamwork,
        >= 21 and <= 40 => GameAct.Troubleshooting,
        _ => throw new ArgumentOutOfRangeException(nameof(levelNumber), levelNumber, "Level must be 1-40.")
    };

    public static GamePhase PhaseOf(GameAct act) =>
        act == GameAct.Troubleshooting ? GamePhase.ProblemSolving : GamePhase.Teaching;

    /// <summary>Full score of level n = 90 + 10n (design doc).</summary>
    public static int MaxScoreOf(int levelNumber) => 90 + 10 * levelNumber;
}

public sealed record LevelTask(string Id, string Description);

public sealed record LevelDefinition(
    int Number,
    GameAct Act,
    string Title,
    IReadOnlyList<LevelTask> Tasks,
    ExpectedRepositoryState ExpectedFinalState)
{
    public GamePhase Phase => GameStructure.PhaseOf(Act);
    public int TaskCount => Tasks.Count;
    public int MaxScore => GameStructure.MaxScoreOf(Number);

    public StateComparison CompareFinalState(GitRepositorySnapshot player) => ExpectedFinalState.Compare(player);
}
