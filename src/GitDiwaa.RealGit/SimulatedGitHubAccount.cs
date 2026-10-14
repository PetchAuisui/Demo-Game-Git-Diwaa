using GitDiwaa.Core;

namespace GitDiwaa.RealGit;

/// <summary>
/// บัญชีผู้เล่นบน GitHub จำลอง: repo แรก (ถ้ามี) มาจาก seed ของด่าน ผู้เล่นสร้าง repo ว่างเพิ่มได้เอง
/// แต่ละ repo มี bare repository และ <see cref="SimulatedGitHubHost"/> ของตัวเอง
/// </summary>
internal sealed class SimulatedGitHubAccount : IGitRemoteAccount
{
    private const int MaxNameLength = 64;

    private readonly GitSandbox _sandbox;
    private readonly GitWorkspaceManager _workspace;
    private readonly GitProcessRunner _runner;
    private readonly RemoteRegistry _registry;
    private readonly RemoteSeed _seed;
    private readonly List<SimulatedGitHubHost> _hosts = [];
    private readonly SemaphoreSlim _createLock = new(1, 1);

    public SimulatedGitHubAccount(
        GitSandbox sandbox,
        GitWorkspaceManager workspace,
        GitProcessRunner runner,
        RemoteRegistry registry,
        RemoteSeed seed,
        SimulatedGitHubHost? primary)
    {
        _sandbox = sandbox;
        _workspace = workspace;
        _runner = runner;
        _registry = registry;
        _seed = seed;
        if (primary is not null) _hosts.Add(primary);
    }

    public string Owner => _seed.Owner;

    public async Task<IReadOnlyList<RemoteRepositoryInfo>> ListRepositoriesAsync(CancellationToken cancellationToken = default)
    {
        var repos = new List<RemoteRepositoryInfo>();
        foreach (var host in _hosts.ToList()) repos.Add(await host.GetRepositoryAsync(cancellationToken));
        return repos;
    }

    public IGitRemoteHost? OpenRepository(string name) =>
        _hosts.FirstOrDefault(host => host.RepositoryName.Equals(name, StringComparison.OrdinalIgnoreCase));

    public async Task<RemoteRepositoryInfo> CreateRepositoryAsync(
        string name, string description, CancellationToken cancellationToken = default)
    {
        name = name.Trim();
        if (name.Length == 0) throw new InvalidOperationException("ต้องตั้งชื่อ repository");
        if (name.Length > MaxNameLength) throw new InvalidOperationException($"ชื่อ repository ยาวเกิน {MaxNameLength} ตัวอักษร");
        if (name.Any(character => !(char.IsAsciiLetterOrDigit(character) || character is '-' or '_')))
            throw new InvalidOperationException("ชื่อ repository ใช้ได้เฉพาะตัวอักษรอังกฤษ ตัวเลข - และ _");
        // กันสร้างชื่อเดียวกันซ้อนกัน (เช็กชื่อซ้ำกับสร้าง bare repo ต้องเป็นก้อนเดียว)
        await _createLock.WaitAsync(cancellationToken);
        SimulatedGitHubHost host;
        try
        {
            if (OpenRepository(name) is not null)
                throw new InvalidOperationException($"มี repository ชื่อ {name} อยู่แล้ว");

            var seed = RemoteSeed.Empty(Owner, name) with { Description = description.Trim() };
            seed = seed with { Rules = _seed.Rules };
            var remote = await _workspace.CreateBareRemoteAsync(
                _sandbox, _runner, $"repo-{name}", seed.CloneUrl, cancellationToken);
            _registry.Add(remote);
            host = new SimulatedGitHubHost(_sandbox, remote, _runner, seed);
            _hosts.Add(host);
        }
        finally
        {
            _createLock.Release();
        }

        return await host.GetRepositoryAsync(cancellationToken);
    }
}
