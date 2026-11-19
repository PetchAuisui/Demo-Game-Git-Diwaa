using System.Diagnostics;

namespace GitDiwaa.Core.Game;

/// <summary>
/// Plays one floor: the loop is always <i>problem → player acts → world reacts</i>.
/// Progress is judged from the real repository state, never from multiple-choice answers.
/// </summary>
public sealed class FloorRunner : IAsyncDisposable
{
    private readonly Floor _floor;
    private readonly FloorContext _ctx;
    private readonly Stopwatch _clock = new();
    private int _current;
    private int _hintLevel;

    public FloorRunner(Floor floor, IGitGameSession session, string playerName)
    {
        _floor = floor;
        _ctx = new FloorContext(session, playerName);
    }

    public Floor Floor => _floor;
    public IGitGameSession Session => _ctx.Session;
    public GitRepositorySnapshot Snapshot { get; private set; } = GitRepositorySnapshot.Empty;
    public int CurrentObjectiveIndex => _current;
    public Objective? CurrentObjective => _current < _floor.Objectives.Count ? _floor.Objectives[_current] : null;
    public int Errors { get; private set; }
    public int EffectiveCommands { get; private set; }
    public bool IsCleared { get; private set; }
    public bool IsFailed { get; private set; }
    public bool IsOver => IsCleared || IsFailed;
    public TimeSpan Elapsed => _clock.Elapsed;

    /// <summary>Panels currently visible: the floor's base panels plus those unlocked by completed goals.</summary>
    public UiPanel Panels { get; private set; }

    public async Task<IReadOnlyList<GameEvent>> StartAsync(CancellationToken ct = default)
    {
        await _floor.Setup(_ctx);
        Panels = _floor.Panels | UiPanel.Terminal;
        Snapshot = await Session.InspectAsync(ct);
        var events = _floor.Intro.Select(l => (GameEvent)new SpokenLine(Personalize(l))).ToList();
        events.Add(new ObjectiveStarted(0, _floor.Objectives[0], _floor.Guided));
        return events;
    }

    /// <summary>Timer starts only when the player begins the mission (after the intro).</summary>
    public void BeginTimer() => _clock.Start();

    public async Task<IReadOnlyList<GameEvent>> HandleAsync(string input, CancellationToken ct = default)
    {
        input = input.Trim();
        if (IsOver || input.Length == 0) return [];
        if (!_clock.IsRunning) _clock.Start();

        var (verb, arg) = SplitVerb(input);
        return verb switch
        {
            "git" => await CastAsync(input, ct),
            "say" => await AfterActionAsync(PlayerActionKind.Say, input, null, arg, [new SpokenLine(Line.Player($"\"{arg}\""))], ct),
            "read" or "cat" => await ReadAsync(input, arg, ct),
            "scribe" => await ScribeAsync(input, arg, ct),
            "resolve" => await ResolveAsync(input, arg, ct),
            "cd" => await ChangeDirectoryAsync(input, arg, ct),
            "ls" => [new Notice(DescribeFiles())],
            "hint" => [NextHint()],
            "ask" => Ask(arg),
            _ => [new SpellRejected(input, "ไม่รู้จักคำนี้ — พิมพ์ `help` เพื่อดูสิ่งที่ทำได้ หรือร่ายคาถาที่ขึ้นต้นด้วย `git`")],
        };
    }

    private async Task<IReadOnlyList<GameEvent>> CastAsync(string input, CancellationToken ct)
    {
        var before = Snapshot;
        var result = await Session.ExecuteAsync(input, ct);
        var events = new List<GameEvent>();

        if (result.ExitCode == -1 && !result.Success)
        {
            Errors++;
            events.Add(new SpellRejected(input, result.StandardError));
            events.Add(new EffectPlayed(new WorldEffect(EffectKind.Fizzle)));
            return events;
        }

        events.Add(new SpellOutput(result.DisplayCommand, result.Output, result.Success));
        if (result.Success) EffectiveCommands++;
        else Errors++;

        var after = await Session.InspectAsync(ct);
        foreach (var e in EffectDetector.Detect(before, after, input, result))
            events.Add(new EffectPlayed(e));

        var explanation = result.Success ? null : MiuraInterpreter.Explain(result.Output);
        if (explanation is not null) events.Add(new SpokenLine(Line.Miura(explanation)));
        if (!result.Success && after.UnmergedFiles.Any())
            events.Add(new SpokenLine(Line.Miura("ใช้ `resolve <ไฟล์>` เพื่อตัดสินการปะทะ แล้ววางขึ้นแท่นและจารึก (หรือ `git merge --abort` เพื่อยกเลิกพิธี)")));

        Snapshot = after;
        events.AddRange(await EvaluateAsync(new ObjectiveContext(before, after, PlayerActionKind.Git, input, result, null, _ctx.Flags), ct));
        return events;
    }

    private async Task<IReadOnlyList<GameEvent>> ReadAsync(string input, string arg, CancellationToken ct)
    {
        if (arg.Length == 0) return [new Notice("อ่านอะไรดี? `read <ไฟล์>`\n" + DescribeFiles())];
        var text = await Session.Files.ReadAllTextAsync(arg, ct);
        if (text is null) return [new SpellRejected(input, $"ไม่มีเศษคัมภีร์ชื่อ `{arg}` บนโต๊ะ")];
        return await AfterActionAsync(PlayerActionKind.Read, input, null, arg, [new ScrollText(arg, text)], ct);
    }

    private async Task<IReadOnlyList<GameEvent>> ScribeAsync(string input, string arg, CancellationToken ct)
    {
        var space = arg.IndexOf(' ');
        if (space <= 0) return [new SpellRejected(input, "รูปแบบ: scribe <ไฟล์> <ข้อความ>")];
        var path = arg[..space];
        var content = arg[(space + 1)..].Trim().Trim('"').Replace("\\n", "\n");
        try
        {
            await Session.Files.WriteAllTextAsync(path, content + "\n", ct);
        }
        catch (UnauthorizedAccessException)
        {
            return [new SpellRejected(input, "เขียนได้เฉพาะเศษคัมภีร์บนโต๊ะของตัวเอง")];
        }
        return await AfterActionAsync(PlayerActionKind.Scribe, input, null, path, [new Notice($"✒️  เขียนลงบน {path} แล้ว")], ct);
    }

    /// <summary>
    /// Resolves a conflicted scroll: <c>resolve f.txt ours|theirs|both</c>.
    /// This is a meaningful decision (which dimension's runes survive), not a quiz.
    /// </summary>
    private async Task<IReadOnlyList<GameEvent>> ResolveAsync(string input, string arg, CancellationToken ct)
    {
        var parts = arg.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 0) return [new SpellRejected(input, "รูปแบบ: resolve <ไฟล์> ours|theirs|both")];
        var path = parts[0];
        var text = await Session.Files.ReadAllTextAsync(path, ct);
        if (text is null || !text.Contains("<<<<<<<"))
            return [new SpellRejected(input, $"`{path}` ไม่มีรอยปะทะของมิติ")];
        if (parts.Length < 2 || parts[1] is not ("ours" or "theirs" or "both"))
            return [new ScrollText(path, text), new Notice("เลือกว่าจะเก็บอักขระของมิติไหน: `resolve " + path + " ours` (มิติที่ยืนอยู่) / `theirs` (มิติที่หลอมเข้ามา) / `both` (รวมทั้งสอง)")];

        var resolved = ConflictResolver.Resolve(text, parts[1]);
        await Session.Files.WriteAllTextAsync(path, resolved, ct);
        return await AfterActionAsync(PlayerActionKind.Resolve, input, null, path,
            [new ScrollText(path, resolved), new Notice("⚖️  การปะทะสงบลง — อย่าลืมวางขึ้นแท่นและจารึกผลการหลอม")], ct);
    }

    private async Task<IReadOnlyList<GameEvent>> ChangeDirectoryAsync(string input, string arg, CancellationToken ct)
    {
        var error = Session.ChangeDirectory(arg);
        if (error is not null) return [new SpellRejected(input, error)];
        return await AfterActionAsync(PlayerActionKind.ChangeDirectory, input, null, arg,
            [new Notice($"🚪 เดินเข้า {Session.CurrentDirectory}")], ct);
    }

    private async Task<IReadOnlyList<GameEvent>> AfterActionAsync(
        PlayerActionKind kind, string input, GitCommandResult? result, string? arg, List<GameEvent> events, CancellationToken ct)
    {
        var before = Snapshot;
        Snapshot = await Session.InspectAsync(ct);
        events.AddRange(await EvaluateAsync(new ObjectiveContext(before, Snapshot, kind, input, result, arg, _ctx.Flags), ct));
        return events;
    }

    private async Task<IReadOnlyList<GameEvent>> EvaluateAsync(ObjectiveContext context, CancellationToken ct)
    {
        var events = new List<GameEvent>();

        var failure = _floor.FailWhen?.Invoke(context);
        if (failure is not null)
        {
            IsFailed = true;
            _clock.Stop();
            events.Add(new FloorFailed(failure));
            return events;
        }

        // Objectives are sequential story beats; several may complete from one action.
        while (CurrentObjective is { } objective && objective.IsComplete(context))
        {
            events.Add(new ObjectiveDone(_current, objective.Goal));
            if (objective.Unlocks != UiPanel.None && (Panels & objective.Unlocks) != objective.Unlocks)
            {
                Panels |= objective.Unlocks;
                events.Add(new PanelUnlocked(objective.Unlocks));
            }
            events.AddRange(objective.OnComplete.Select(l => (GameEvent)new SpokenLine(Personalize(l))));
            _current++;
            _hintLevel = 0;

            if (objective.WorldEvent is not null)
            {
                var before = Snapshot;
                await objective.WorldEvent(_ctx);
                Snapshot = await Session.InspectAsync(ct);
                context = context with { Before = before, After = Snapshot, Action = PlayerActionKind.Other, Input = "", Result = null, Argument = null };
            }

            if (CurrentObjective is { } next)
            {
                events.Add(new ObjectiveStarted(_current, next, _floor.Guided));
                // Observation-only goals must be triggered by a new action, not cascaded.
                context = context with { Action = PlayerActionKind.Other, Input = "", Result = null, Argument = null };
            }
        }

        if (CurrentObjective is null && !IsCleared)
        {
            IsCleared = true;
            _clock.Stop();
            events.AddRange(_floor.Outro.Select(l => (GameEvent)new SpokenLine(Personalize(l))));
            if (_floor.Reward is not null) events.Add(new FragmentObtained(_floor.Reward));
            var score = Scoring.Calculate(_floor, _floor.Objectives.Count, Errors, EffectiveCommands, _clock.Elapsed);
            events.Add(new FloorCleared(score, _floor.Reflection));
        }

        return events;
    }

    private GameEvent NextHint()
    {
        if (CurrentObjective is not { } objective)
            return new Notice("ชั้นนี้สำเร็จแล้ว");
        var hints = objective.Hints.Count > 0 ? objective.Hints : [objective.Goal];
        var level = Math.Min(_hintLevel, hints.Count - 1);
        _hintLevel = Math.Min(_hintLevel + 1, hints.Count - 1);
        return new HintGiven(level + 1, hints.Count, hints[level]);
    }

    private IReadOnlyList<GameEvent> Ask(string arg)
    {
        if (_floor.Ask.Count == 0)
            return [new SpokenLine(Line.Miura("ตอนนี้ไม่มีอะไรต้องอธิบาย ลองลงมือดูเลย"))];
        if (int.TryParse(arg, out var n) && n >= 1 && n <= _floor.Ask.Count)
        {
            var topic = _floor.Ask[n - 1];
            return [new SpokenLine(Line.Player(topic.Question)), .. topic.Answer.Select(l => (GameEvent)new SpokenLine(Personalize(l)))];
        }
        var menu = string.Join("\n", _floor.Ask.Select((t, i) => $"  {i + 1}. {t.Question}"));
        return [new Notice($"ถามมิวราได้ (พิมพ์ `ask <เลข>`):\n{menu}")];
    }

    private string DescribeFiles()
    {
        var files = Session.Files.ListFiles();
        return files.Count == 0 ? "(โต๊ะว่างเปล่า)" : "บนโต๊ะมี: " + string.Join("  ", files);
    }

    private Line Personalize(Line line) => line with { Text = line.Text.Replace("{player}", _ctx.PlayerName) };

    private static (string Verb, string Arg) SplitVerb(string input)
    {
        var space = input.IndexOf(' ');
        return space < 0 ? (input.ToLowerInvariant(), "") : (input[..space].ToLowerInvariant(), input[(space + 1)..].Trim());
    }

    public ValueTask DisposeAsync() => Session.DisposeAsync();
}

public static class ConflictResolver
{
    public static string Resolve(string text, string choice)
    {
        var output = new List<string>();
        var ours = new List<string>();
        var theirs = new List<string>();
        var state = 0; // 0 = normal, 1 = ours, 2 = theirs
        foreach (var line in text.Replace("\r\n", "\n").Split('\n'))
        {
            if (line.StartsWith("<<<<<<<")) { state = 1; ours.Clear(); theirs.Clear(); continue; }
            if (line.StartsWith("=======") && state == 1) { state = 2; continue; }
            if (line.StartsWith(">>>>>>>") && state == 2)
            {
                state = 0;
                output.AddRange(choice switch
                {
                    "ours" => ours,
                    "theirs" => theirs,
                    _ => ours.Concat(theirs.Where(t => !ours.Contains(t))),
                });
                continue;
            }
            (state switch { 1 => ours, 2 => theirs, _ => output }).Add(line);
        }
        return string.Join("\n", output);
    }
}
