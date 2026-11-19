using GitDiwaa.Core;

namespace GitDiwaa.RealGit;

public sealed class RealGitSession : IGitGameSession, ISandboxAuthoring
{
    private readonly SandboxLayout _layout;
    private readonly CommandPolicy _policy;
    private readonly GitProcessRunner _runner;
    private readonly GitStateInspector _inspector;
    private readonly bool _deleteOnDispose;
    private string _currentDirectory;

    public RealGitSession(SandboxLayout layout, string missionId, string attemptId, bool deleteOnDispose = true)
    {
        _layout = layout;
        _layout.Create();
        _policy = new CommandPolicy();
        _runner = new GitProcessRunner(layout, _policy.VirtualRemoteBase);
        _inspector = new GitStateInspector(_runner, layout);
        _deleteOnDispose = deleteOnDispose;
        _currentDirectory = layout.Workspace;
        Files = new SandboxFileSystem(layout, () => _currentDirectory);
        Info = new GitSessionInfo(missionId, attemptId, layout.Workspace, _policy.VirtualRemoteBase);
    }

    public GitSessionInfo Info { get; }
    public IPlayerFileSystem Files { get; }
    public ISandboxAuthoring Authoring => this;
    public CommandPolicy Policy => _policy;
    public string VirtualRemoteBase => _policy.VirtualRemoteBase;

    public string CurrentDirectory
    {
        get
        {
            var rel = Path.GetRelativePath(_layout.Workspace, _currentDirectory).Replace('\\', '/');
            return rel;
        }
    }

    public string? ChangeDirectory(string relativePath)
    {
        var target = string.IsNullOrWhiteSpace(relativePath) || relativePath is "~" or "/"
            ? _layout.Workspace
            : _layout.ResolveInWorkspace(_currentDirectory, relativePath);
        if (target is null)
            return "ทางนั้นอยู่นอกพื้นที่ของนาย — เดินได้เฉพาะในห้องของตัวเอง";
        if (!Directory.Exists(target))
            return $"ไม่มีห้องชื่อ `{relativePath}`";
        _currentDirectory = target;
        return null;
    }

    public async Task<GitCommandResult> ExecuteAsync(string commandLine, CancellationToken cancellationToken = default)
    {
        var decision = _policy.Evaluate(commandLine);
        if (!decision.Allowed)
            return GitCommandResult.Rejected(decision.Reason!, commandLine.Trim());

        if (!Directory.Exists(_currentDirectory))
            _currentDirectory = _layout.Workspace;

        return await _runner.RunAsync(decision.Arguments, _currentDirectory, forPlayer: true, cancellationToken);
    }

    public Task<GitRepositorySnapshot> InspectAsync(CancellationToken cancellationToken = default) =>
        _inspector.InspectAsync(_currentDirectory, cancellationToken);

    // ---- ISandboxAuthoring (trusted, used only by floor scripts) ----

    public Task<GitCommandResult> RunGitAsync(IReadOnlyList<string> arguments, string? npcWorkspace = null, CancellationToken cancellationToken = default)
    {
        var dir = npcWorkspace is null ? _currentDirectory : NpcDirectory(npcWorkspace);
        Directory.CreateDirectory(dir);
        return _runner.RunAsync(arguments, dir, forPlayer: false, cancellationToken);
    }

    public async Task<string> CreateBareRemoteAsync(string name, CancellationToken cancellationToken = default)
    {
        var safe = SafeName(name);
        var path = Path.Combine(_layout.Remotes, safe + ".git");
        if (!Directory.Exists(path))
        {
            var r = await _runner.RunAsync(["init", "--bare", "-q", path], _layout.Remotes, forPlayer: false, cancellationToken);
            if (!r.Success) throw new InvalidOperationException($"cannot create remote {name}: {r.Output}");
        }
        return $"{VirtualRemoteBase}{safe}.git";
    }

    public async Task WriteNpcFileAsync(string npcWorkspace, string relativePath, string content, CancellationToken cancellationToken = default)
    {
        var root = NpcDirectory(npcWorkspace);
        var full = Path.GetFullPath(Path.Combine(root, relativePath));
        if (!SandboxLayout.IsInside(root, full)) throw new UnauthorizedAccessException(relativePath);
        Directory.CreateDirectory(Path.GetDirectoryName(full)!);
        await File.WriteAllTextAsync(full, content, cancellationToken);
    }

    private string NpcDirectory(string name)
    {
        var dir = Path.Combine(_layout.Npc, SafeName(name));
        Directory.CreateDirectory(dir);
        return dir;
    }

    private static string SafeName(string name)
    {
        var cleaned = new string(name.Where(c => char.IsLetterOrDigit(c) || c is '-' or '_').ToArray());
        if (cleaned.Length == 0) throw new ArgumentException("invalid name", nameof(name));
        return cleaned;
    }

    public ValueTask DisposeAsync()
    {
        if (_deleteOnDispose)
        {
            try
            {
                // git marks objects read-only; clear attributes so cleanup succeeds on Windows too.
                foreach (var f in Directory.EnumerateFiles(_layout.Root, "*", SearchOption.AllDirectories))
                    File.SetAttributes(f, FileAttributes.Normal);
                Directory.Delete(_layout.Root, recursive: true);
            }
            catch (IOException) { }
            catch (UnauthorizedAccessException) { }
        }
        return ValueTask.CompletedTask;
    }
}

public sealed class RealGitSessionFactory : IGitGameSessionFactory
{
    private readonly string _baseDirectory;

    public RealGitSessionFactory(string? baseDirectory = null)
    {
        _baseDirectory = baseDirectory ?? Path.Combine(Path.GetTempPath(), "git-diwaa");
    }

    public Task<IGitGameSession> CreateAsync(string missionId, string attemptId, CancellationToken cancellationToken = default)
    {
        var root = Path.Combine(_baseDirectory, $"{Sanitize(missionId)}-{Sanitize(attemptId)}");
        if (Directory.Exists(root))
        {
            foreach (var f in Directory.EnumerateFiles(root, "*", SearchOption.AllDirectories))
                File.SetAttributes(f, FileAttributes.Normal);
            Directory.Delete(root, recursive: true);
        }
        IGitGameSession session = new RealGitSession(new SandboxLayout(root), missionId, attemptId);
        return Task.FromResult(session);
    }

    private static string Sanitize(string s) =>
        new(s.Where(c => char.IsLetterOrDigit(c) || c is '-' or '_').ToArray());
}
