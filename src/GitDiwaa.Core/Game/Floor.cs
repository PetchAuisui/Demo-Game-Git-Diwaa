namespace GitDiwaa.Core.Game;

/// <summary>Panels of the world UI. Only panels the player has learned about are shown (contextual UI).</summary>
[Flags]
public enum UiPanel
{
    None = 0,
    Terminal = 1,
    Desk = 2,        // working tree
    Altar = 4,       // staging area
    Tome = 8,        // commit history
    Dimensions = 16, // branches
    Archive = 32,    // remotes
}

public enum Speaker { Narrator, Miura, Player, Guardian, Master }

public sealed record Line(Speaker Speaker, string Text)
{
    public static Line Miura(string text) => new(Speaker.Miura, text);
    public static Line Player(string text) => new(Speaker.Player, text);
    public static Line Narrate(string text) => new(Speaker.Narrator, text);
    public static Line Guardian(string text) => new(Speaker.Guardian, text);
}

public sealed record Fragment(int Number, string Name, string Lore);

public sealed record AskTopic(string Question, IReadOnlyList<Line> Answer);

public enum PlayerActionKind { Git, Say, Read, Scribe, Resolve, ChangeDirectory, Other }

/// <summary>Everything an objective can look at to decide whether it is complete.</summary>
public sealed record ObjectiveContext(
    GitRepositorySnapshot Before,
    GitRepositorySnapshot After,
    PlayerActionKind Action,
    string Input,
    GitCommandResult? Result,
    string? Argument,
    IReadOnlyDictionary<string, string> Flags)
{
    public string? SpellKey => Action == PlayerActionKind.Git ? Spellbook.KeyOf(Input) : null;
    public bool Succeeded => Result?.Success ?? true;
    public bool Cast(string spellKey) => Action == PlayerActionKind.Git && Succeeded && SpellKey == spellKey;
    public bool CastWith(string spellKey, string flag) => Cast(spellKey) && Input.Split(' ').Contains(flag);
    public bool Said(string word) => Action == PlayerActionKind.Say &&
        string.Equals(Argument?.Trim(), word, StringComparison.OrdinalIgnoreCase);
    public bool HasRead(string path) => Action == PlayerActionKind.Read && Argument == path;
}

/// <summary>
/// One goal on a floor. Goals are described as outcomes in the world;
/// the spell is only revealed on guided floors or through hints (scaffolding that fades).
/// </summary>
public sealed class Objective
{
    public required string Goal { get; init; }
    public string? GuidedSpell { get; init; }
    public IReadOnlyList<string> Hints { get; init; } = [];
    public required Func<ObjectiveContext, bool> IsComplete { get; init; }
    public IReadOnlyList<Line> OnComplete { get; init; } = [];

    /// <summary>World event fired when the goal completes (e.g. chaos corrupts a scroll).</summary>
    public Func<FloorContext, Task>? WorldEvent { get; init; }
}

/// <summary>Services a floor script can use while setting up or reacting.</summary>
public sealed class FloorContext
{
    public FloorContext(IGitGameSession session, string playerName)
    {
        Session = session;
        PlayerName = playerName;
    }

    public IGitGameSession Session { get; }
    public string PlayerName { get; }
    public IPlayerFileSystem Files => Session.Files;
    public ISandboxAuthoring Author => Session.Authoring;
    public Dictionary<string, string> Flags { get; } = new();

    public Task<GitCommandResult> Git(params string[] args) => Author.RunGitAsync(args);
    public Task<GitCommandResult> NpcGit(string npc, params string[] args) => Author.RunGitAsync(args, npc);

    /// <summary>Commits as a given author with a fixed date so seeded histories are deterministic.</summary>
    public Task<GitCommandResult> CommitAs(string author, string message, string? npc = null, string date = "2025-01-01T09:00:00+07:00") =>
        Author.RunGitAsync(["-c", $"user.name={author}", "-c", $"user.email={author.ToLowerInvariant().Replace(' ', '.')}@tower.diwaa",
            "commit", "-q", "--allow-empty", "-m", message, $"--date={date}"], npc);
}

public sealed class Floor
{
    public required int Number { get; init; }
    public int Act { get; init; } = 1;
    public required string Title { get; init; }
    public required string Hook { get; init; }
    public string Scene { get; init; } = "tower";
    public IReadOnlyList<Line> Intro { get; init; } = [];
    public required IReadOnlyList<Objective> Objectives { get; init; }
    public IReadOnlyList<Line> Outro { get; init; } = [];
    public string Reflection { get; init; } = "";
    public UiPanel Panels { get; init; } = UiPanel.Terminal;
    public IReadOnlyList<string> Spells { get; init; } = [];
    public IReadOnlyList<AskTopic> Ask { get; init; } = [];
    public Fragment? Reward { get; init; }
    public bool Guided { get; init; } = true;
    public int TimeLimitSeconds { get; init; } = 120;
    public int TargetCommands { get; init; } = 1;
    public Func<FloorContext, Task> Setup { get; init; } = _ => Task.CompletedTask;

    /// <summary>Returns a message when the player has made the floor unwinnable (e.g. destroyed a fragment).</summary>
    public Func<ObjectiveContext, string?>? FailWhen { get; init; }

    /// <summary>Canonical solution used by automated playthrough tests (and the final hint).</summary>
    public IReadOnlyList<string> Solution { get; init; } = [];

    public int FullScore => 90 + 10 * Number;
}
