namespace GitDiwaa.Core.Levels;

/// <summary>Fluent builder for <see cref="LevelDefinition"/>; the act is derived from the level number.</summary>
public sealed class LevelBuilder
{
    private readonly int _number;
    private string _title = "";
    private readonly List<LevelTask> _tasks = [];
    private ExpectedRepositoryState _finalState = new();

    private LevelBuilder(int number) => _number = number;

    public static LevelBuilder ForLevel(int number)
    {
        GameStructure.ActOf(number); // validates 1-40
        return new LevelBuilder(number);
    }

    public LevelBuilder Titled(string title)
    {
        _title = title;
        return this;
    }

    public LevelBuilder AddTask(string description)
    {
        _tasks.Add(new LevelTask($"L{_number:00}-T{_tasks.Count + 1}", description));
        return this;
    }

    public LevelBuilder ExpectFinalState(Action<ExpectedRepositoryStateBuilder> configure)
    {
        var b = new ExpectedRepositoryStateBuilder();
        configure(b);
        _finalState = b.Build();
        return this;
    }

    public LevelDefinition Build()
    {
        if (string.IsNullOrWhiteSpace(_title))
            throw new InvalidOperationException($"Level {_number} needs a title.");
        if (_tasks.Count == 0)
            throw new InvalidOperationException($"Level {_number} needs at least one task.");

        return new LevelDefinition(_number, GameStructure.ActOf(_number), _title, _tasks.ToArray(), _finalState);
    }
}

public sealed class ExpectedRepositoryStateBuilder
{
    private ExpectedRepositoryState _s = new();

    public ExpectedRepositoryStateBuilder Initialized(bool value = true) { _s = _s with { IsInitialized = value }; return this; }
    public ExpectedRepositoryStateBuilder OnBranch(string name) { _s = _s with { CurrentBranch = name }; return this; }
    public ExpectedRepositoryStateBuilder HasBranch(params string[] names) { _s = _s with { RequiredBranches = [.. _s.RequiredBranches, .. names] }; return this; }
    public ExpectedRepositoryStateBuilder HasFile(string path, GitFileState? index = null, GitFileState? workingTree = null) { _s = _s with { Files = [.. _s.Files, new ExpectedFile(path, index, workingTree)] }; return this; }
    public ExpectedRepositoryStateBuilder CommitCount(int? min = null, int? max = null) { _s = _s with { MinCommitCount = min, MaxCommitCount = max }; return this; }
    public ExpectedRepositoryStateBuilder HasCommit(params string[] subjects) { _s = _s with { RequiredCommitSubjects = [.. _s.RequiredCommitSubjects, .. subjects] }; return this; }
    public ExpectedRepositoryStateBuilder CleanWorkingTree(bool value = true) { _s = _s with { RequireCleanWorkingTree = value }; return this; }

    internal ExpectedRepositoryState Build() => _s;
}
